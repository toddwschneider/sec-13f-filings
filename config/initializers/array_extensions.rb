class Array
  def median
    return if blank?

    sorted = self.sort
    len = sorted.length

    (sorted[(len - 1) / 2] + sorted[len / 2]) / 2.0
  end
end
