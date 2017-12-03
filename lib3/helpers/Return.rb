module Helper_Return
  def return_directly?(result)
    return @client.async != false || @client.return_direct_result
    return result if result == true
  end
end
