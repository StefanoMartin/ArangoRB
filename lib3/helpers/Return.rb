module Helper_Return
  def return_directly?(result)
    return @client.async != false || @client.return_direct_result
    return result == true
  end

  def return_element(result)
    return result if @client.async != false
    assign_attributes(result)
    return return_directly?(result) ? result : self
  end
end
