class String
  def abbreviated
    shortened = ""

    parts = self.split(" ")

    if (1 < parts.size)
      parts.each do |p|
        shortened = "#{shortened}#{p.first}"
      end
    else
      shortened = self[0..2]
    end

    return shortened
  end
end
