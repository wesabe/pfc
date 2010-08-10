module ActiveRecord
  module Acts #:nodoc:
    module Taggable #:nodoc:
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        def acts_as_taggable(options = {})
          write_inheritable_attribute(:acts_as_taggable_options, {
            :taggable_type => self.base_class.name.to_s,
            :from => options[:from]
          })

          class_inheritable_reader :acts_as_taggable_options

          has_many :taggings, :as => :taggable, :dependent => :destroy
          has_many :tags, :through => :taggings, :source => :tag, :select => 'tags.*, taggings.name as user_name'

          include ActiveRecord::Acts::Taggable::InstanceMethods
          extend ActiveRecord::Acts::Taggable::SingletonMethods
        end
      end

      module SingletonMethods
        def find_tagged_with(tag_list, options = {})
          tag_list = Tag.parse_to_tags(tag_list) if tag_list.kind_of?(String)
          return [] unless tag_list && tag_list.any?
          find(:all,
               :select => "#{table_name}.*",
               :from => "#{table_name}, taggings",
               :conditions => [
                 "#{table_name}.#{primary_key} = taggings.taggable_id " +
                 "AND taggings.taggable_type = ? " +
                 "AND taggings.tag_id in (?)",
                  acts_as_taggable_options[:taggable_type], tag_list.map(&:id)],
               :limit => options[:limit],
               :order => options[:order])
        end
      end

      module InstanceMethods
        def tags=(tags)
          self.tag_with(tags) if tags.is_a?(String)
        end

        def tag_append(list)
          return unless list
          tags = []
          if list.is_a?(String)
            TagParser.parse(list).each do |name|
              tags << Tag.find_or_create_by_name(name)
            end
          elsif list.is_a?(Tag)
            tags = [list]
          else
            tags = list
          end

          tags.each do |tag|
            Tag.transaction do
              next if self.tags.include?(tag)
              tag.on(self)
            end
          end
          self.reload
        end

        # append a single tag name; this is called from tag_with_splits to make sure we don't
        # reparse a tag that has multiple words
        def tag_append_one(name)
          tag = Tag.find_or_create_by_name(name)
          tag.on(self) unless tags.include? tag
        end

        def tag_with(list)
          Tag.transaction do
            taggings.destroy_all
            self.reload
            self.tag_append(list)
          end
        end

        def taggings_to_string(taggings = self.taggings)
          taggings.to_a.map(&:display_name).join(" ")
        end

      end
    end
  end
end

ActiveRecord::Base.send(:include, ActiveRecord::Acts::Taggable)
