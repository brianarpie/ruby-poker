class Player
  attr_accessor :position, :hole_cards,
                :is_bot, :is_thinking, :chips, :name, :is_ready, :button

  def initialize(button:)
    @chips = 1500
    @score = 0
    @is_bot = bot
    @is_thinking = false
    @is_ready = false
    @button = button
  end

  def post_blind
    @button ? Table.small_blind : Table.big_blind
  end

  def sit_down
    @is_ready = true
  end

  def bot?
    @is_bot
  end

  def thinking?
    @is_thinking
  end

end
