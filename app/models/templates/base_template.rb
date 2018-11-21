class Templates::BaseTemplate
  include ActionView::Helpers::NumberHelper

  attr_reader :data_tree
  attr_reader :data_tree_tags

  def initialize(obj = nil)

  end

  def display_tags

  end

  def render(template_content, base_object)
    unless @object_type && base_object.kind_of?(@object_type)
      raise "Attempting to call template render with wrong object type in base object"
    end
    
    template_content = "" if !template_content
    @@notification_event_id = base_object.notification_event.category_cid if base_object && base_object.notification_event
    @@options = base_object[:related_objects]
    @data_tree_tags = tags
    @data_tree = OpenStruct.new
    @data_tree = load_data_for_tags(@data_tree, base_object)

    begin
      Tilt['handlebars'].new{ template_content }.render(@data_tree) if @data_tree
    rescue Exception => ex
      Rollbar.warning(ex, 'Email template could not be rendered due to a handlebars render exception. Probably bad user data.', object_type: @object_type)
    end
  end

  def load_data_for_tags(data_tree, object)
    tags.each do |k, v|
      next unless v
      if v.kind_of?(String)
        # Straight request for an object's parameter
        begin
          data_tree[k] = (self.respond_to?("__#{v}")) ? self.send("__#{v}") : object.send(v)
        rescue NoMethodError => ex
          data_tree[k] = ""
        end

        begin
          if v.to_s.include?("_cents") && data_tree[k].present?
            data_tree[k] = (data_tree[k] / 100.00)
            data_tree["#{k}_currency"] = number_to_currency(data_tree[k])
          end
        rescue Exception => ex
          data_tree["#{k}_currency"] = ""
        end
      elsif v.kind_of?(Hash)
        v.each do |sub_key, sub_val|
          if sub_val.kind_of?(Array)
            next unless object.respond_to?(sub_key)
            sub_objects = object.send(sub_key)
            data_tree[k] = []
            sub_objects.each do |o|
              data_tree[k] << sub_val.first.new(o).load_data_for_tags(OpenStruct.new, o)
            end
          else
            next unless object.respond_to?(sub_key)
            sub_object = object.send(sub_key)
            data_tree[k] = sub_val.new(sub_object).load_data_for_tags(OpenStruct.new, sub_object)
          end
        end
      else

      end
    end

    data_tree
  end

end
