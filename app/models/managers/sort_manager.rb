class Managers::SortManager
  attr_writer :items
  attr_writer :sort_by_value
  attr_writer :model

  ## Usage for this Manager is to take a list of **active_record** records and sort by whatever sort_by_value is passed in, will expect 'price asc', 'name asc', etc.
  #virtual attrs are handled using a ^, ex: 'average_overall_rating^asc'
  def initialize(object, items, sort_by_value, rep = nil)
    @model = object || ""
    @items = items
    @sort_by_value = sort_by_value
    @rep = rep
  end

  def results
    case @model.to_s
      when "Restaurant"
        restaurant_results
      else
        raise "Searching against a model not set up in search_manager"
    end
  end

  def restaurant_results
    #return if sort_by_value is not part of the expected sort_by_values for restaurants, prevent naughty people sending naughty things to our service
    raise "Invalid sort by value" if !Restaurant.sort_by_values.pluck(:value).include?(@sort_by_value)
    raise "Must supply Sales Rep" if !@rep && @sort_by_value == "relevance"

    #relevance is a special case because it requires an argument, and doesnt fit into this paradigm
    if @sort_by_value == 'relevance' 
      results = restaurant_relevance_results 
    else 
      results = sort_items 
    end

    return results
  end

  private

  #method that sorts items
  def sort_items
    sort_by_value = handle_sort_by_value

    if sort_by_value.kind_of?(Array)
      operator = sort_by_value[1] # + or -
      attribute = sort_by_value[0]  #attribute name, virtual

      #cool ruby way to input a string operator and convert it to a mathematic operator, 
      #prevents use of if else statements, also inputs a string attribute and evals it as a model attribute
      results = @items.sort_by {|item| 0.send(operator,item.instance_eval(attribute))}
    else
      #standard ol order query
      results = @items.order(sort_by_value)
    end
    results
  end

  #method to split sort_by_value if includes ^ char
  def handle_sort_by_value
    begin
      values = @sort_by_value.split('^')
      if values.size == 2
      #retrive operator, + or -
      values[1] = sort_operators.select {|op| op[:direction] == values[1]}.first[:operator]
      return values
      else
        return values.first
      end
    rescue Exception => ex
      raise ex
    end    
  end

  def restaurant_relevance_results
    @items.sort_by {|item| - item.relevance(@rep)}
  end

  def sort_operators
    [
      {direction: 'asc', operator: '+'}, 
      {direction: 'desc', operator: '-'}
    ]
  end

end