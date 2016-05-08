require "reform"

class Shrine
  module Plugins
    module Reform
      module AttachmentMethods
        def initialize(*)
          super
        end

        def prepended(form)
          super

          return unless form < ::Reform::Form

          module_eval <<-RUBY, __FILE__, __LINE__ + 1
            def prepopulate!(*)
              super
              @#{@name}_data = model.#{@name}_data
            end

            def sync(*)
              super
              model.#{@name} = @#{@name}_data if defined?(@#{@name}_data)
            end
          RUBY

          form.class_eval <<-RUBY, __FILE__, __LINE__ + 1
            property :#{@name}, virtual: true
            attr_accessor :#{@name}_data

            validate do
              #{@name}_attacher.errors.each do |message|
                errors.add :#{@name}, message
              end
            end
          RUBY

          form.send(:property, :"#{@name}_remote_url", virtual: true) if instance_methods.include?(:"#{@name}_remote_url")
          form.send(:property, :"#{@name}_data_uri", virtual: true) if instance_methods.include?(:"#{@name}_data_uri")
          form.send(:property, :"remove_#{@name}", virtual: true) if instance_methods.include?(:"remove_#{@name}")
          form.send(:property, :"cached_#{@name}_data", virtual: true) if instance_methods.include?(:"cached_#{@name}_data")
        end

        def included(form)
          super
          raise Error, "Reform attachment modules have to be prepended instead of included" if form < ::Reform::Form
        end
      end
    end

    register_plugin(:reform, Reform)
  end
end
