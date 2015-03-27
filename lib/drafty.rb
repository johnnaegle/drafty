module Drafty
  module Model
    def self.included(base)
      base.send :extend, ClassMethods
    end

    module ClassMethods
      # Options
      # :draft_attributes       the attributes that will be considered draft attributes until the draft flag is set to false
      # :associated            Has-one or belongs to associations that should also be finalized.
      def behaves_like_drafty(options = {})
        send :include, InstanceMethods

        attr_accessor :perform_final_validations

        class_attribute :drafty_attributes
        self.drafty_attributes = (options[:draft_attributes] || []).map(&:to_s)

        class_attribute :drafty_associated
        self.drafty_associated = options[:associated] || []

        class_attribute :drafty_options
        self.drafty_options = options.dup

        scope :drafts, lambda {where(:draft => true)}
        scope :finalized, lambda {where(:draft => false)}

        after_find do
          if draft?
            restore_draft_attributes
          end
        end

        before_save do
          if draft?
            changed_keys = changed_attributes.keys & drafty_attributes
            self.draft_changes = self.attributes.slice(*changed_keys)
            restore_attributes(changed_keys)
          end
        end
      end
    end

    module InstanceMethods
      def closed?
        !draft
      end

      def restore_draft_attributes
        self.attributes = draft_changes || {}
        self.draft_changes = {}
      end

      def save_draft
        ActiveRecord::Base.transaction do
          changed_keys = changed_attributes.keys & drafty_attributes

          success = update_columns(:draft_changes => self.attributes.slice(*changed_keys)).tap do
            restore_attributes(changed_keys)
          end

          success &&= _drafty_associated(:save_draft)

          raise ActiveRecord::Rollback unless success
          success
        end
      end

      # When a model is reverted, what should the draft column become
      def draft_state_for_revert
        false
      end

      # Remove from drafty? - user papertrail?
      def revert!
        ActiveRecord::Base.transaction do
          restore_attributes
          # There is a problem here: if the previous version was a draft, we're basically finalizaing it when we revert
          update_columns(:draft => draft_state_for_revert, :draft_changes => {})
          _drafty_associated(:revert!)
        end
      end

      def reopen!
        ActiveRecord::Base.transaction do
          update_columns(:draft => true)
          _drafty_associated(:reopen!)
        end
      end

      def finalize!
        ActiveRecord::Base.transaction do
          restore_draft_attributes unless changed?
          self.draft = false
          self.perform_final_validations = true
          _drafty_associated(:finalize!)
          self.save!
        end
      end
    end

  end
end

ActiveSupport.on_load(:active_record) do
  include Drafty::Model
end
