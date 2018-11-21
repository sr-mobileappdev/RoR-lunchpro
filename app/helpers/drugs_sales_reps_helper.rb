module DrugsSalesRepsHelper

  def format_drugs(drugs)
    if drugs.count == 1
      drugs.first.drug.brand
    elsif drugs.count == 2
      drugs.first.drug.brand + " and " + drugs.second.drug.brand
    elsif drugs.count > 2
      string = ""
      drugs.each_with_index do |drug, index|
        next if !drug.drug
        if index == drugs.count - 2
           string += drug.drug.brand
           string += ", and "
        elsif index == drugs.count - 1
           string += drug.drug.brand
        else
          string += drug.drug.brand
          string += ", "
        end      
      end
      string
    else
      "No Drugs Selected"
    end
  end
end
