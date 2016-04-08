require_relative 'hand_eval' # hand_eval.rb

@@hand_eval = HandEvaluator.new

class Deck
  attr_accessor :deck
  def initialize
    @deck = Array.new(52)
    for i in 0..51
      @deck[i] = i # rebuild deck
    end
  end
  def shuffle
    @deck.shuffle!
  end
  def pop amt=1
    @deck.pop(amt)
  end
end

class Player
  attr_accessor :position, :card1, :card2
  attr_writer :score
  def score
    @score || 0
  end
end

class Game
  def move_dealer_button *players
    players.each { |p|
      unless p.position == 0 then p.position = 1 else p.position -= 1 end
    }
  end

  def deal_cards players, deck
    players.sort_by(&:position).reverse!
    players.each { |p|
      p.card1 = deck.pop()
    }
    players.each { |p|
      p.card2 = deck.pop()
    }
  end

  def start num_of_games=1
    # create players
    hero = Player.new
    villain = Player.new

    num_of_games.times do
      deck = Deck.new
      # move the dealer button
      move_dealer_button(hero, villain)
      # shuffle the deck
      deck.shuffle()
      # deal the cards
      deal_cards([hero, villain], deck)
      # cheap way to get next 5 cards. of course we need to burn etc.
      board = deck.pop(5)

      # find the winner
      hero_hs = @@hand_eval.define_hand([hero.card1, hero.card2, board].flatten)
      villain_hs = @@hand_eval.define_hand([villain.card1, villain.card2, board].flatten)

      if hero_hs > villain_hs
        hero.score += 1
      elsif hero_hs < villain_hs
        villain.score += 1
      else
        hero.score += 0.5
        villain.score += 0.5
      end

    end

    puts "final score: hero: #{hero.score}, villain:#{villain.score}"
  end
end


first_game = Game.new
first_game.start(50)
