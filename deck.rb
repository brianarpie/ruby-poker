class Deck
  # TODO: this needs more context. why are we filling an array from [0..51]
  def build
    [*0..51]
  end

  def deal!(n_cards = 1)
    self.pop(n_cards)
  end

  def shuffle!
    self.shuffle!
  end
end
