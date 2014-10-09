class Hash
  def shuffle
    Hash[self.to_a.shuffle]
  end

  def shuffle!
    self.replace(self.shuffle)
  end
end
