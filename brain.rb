class Brain
  # attr_accessor manipulation of weighting vars...

  def self.decide(current_bet, pot)
    moves = current_bet > 0 ? ["c", "r", "f"] : ["c", "r"]

    decision = moves.sample # this is the dumb brain of a random bot
    if decision == "r"
      if current_bet > 0
        min_raise = current_bet * 2
      else
        min_raise = @big_blind
      end
      decision = "r" + (rand(min_raise..pot)).to_s
    end

    decision
  end
end
