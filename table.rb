class Table
  BLINDS = [10, 20]

  attr_accessor :pot_size, :small_blind, :big_blind,
                :flop, :turn, :river

  # NOTE: the "poker" table is where the state of cards & chips is maintained.
  # any change in chips or cards happen here.

  # Responsibilities
  # -
  def self.small_blind
    BLINDS.first
  end

  def self.big_blind
    BLINDS.last
  end

end
