require_relative 'deck'

class Dealer
  attr_accessor :deck

  # NOTE: the dealer is the only person who can change the state of the cards
  # on the table. he is the delegate for any card or chip related change to the board.
  # he is also the keeper of whose turn it is

  def initialize
    setup_deck
  end

  def distribute_chips(players, chips=1500)
    players.each { |player| player.chips = chips }
  end

  def move_button!

  end

  def deal!(street)
    burn_card

    case street
    when 'flop'
      @deck.deal!(3)
    when 'turn'
    when 'river'
      @deck.deal!(1)
  end


  def next_hand
    # start from scratch
  end


  private


  def burn_card
    @deck.deal!(1)
  end

  def setup_deck
    @deck = Deck.new.build
    @deck.shuffle!
  end

  #
  # def shuffle_deck
  #   @deck.shuffle!
  # end
  #
  # def deal_cards(num_of_cards)
  #   @deck.pop(num_of_cards)
  # end



end
