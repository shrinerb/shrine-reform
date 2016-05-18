require "reform"

class Shrine
  module Plugins
    module Reform
      module AttachmentMethods
        def included(form)
          super

          return unless form < ::Reform::Form

          properties = [
            :"#{@name}",
            :"#{@name}_remote_url",
            :"#{@name}_data_uri",
            :"remove_#{@name}",
            :"cached_#{@name}_data",
          ]

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
            def self.create_accessors(name, definition)
              super unless #{properties}.include?(name)
            end

            attr_accessor :#{@name}_data

            validate do
              #{@name}_attacher.errors.each do |message|
                errors.add :#{@name}, message
              end
            end
          RUBY

          (properties & instance_methods).each do |name|
            form.send(:property, name, virtual: true)
          end
        end
      end
    end

    register_plugin(:reform, Reform)
  end
end
