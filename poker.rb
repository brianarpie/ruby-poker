require_relative 'hand_eval' # hand_eval.rb
require 'pry'

@@hand_eval = HandEvaluator.new

@@card_lut = ["2c", "2d", "2h", "2s", "3c", "3d", "3h", "3s", "4c", "4d", "4h", "4s",
              "5c", "5d", "5h", "5s", "6c", "6d", "6h", "6s", "7c", "7d", "7h", "7s",
              "8c", "8d", "8h", "8s", "9c", "9d", "9h", "9s", "Tc", "Td", "Th", "Ts",
              "Jc", "Jd", "Jh", "Js", "Qc", "Qd", "Qh", "Qs", "Kc", "Kd", "Kh", "Ks",
              "Ac", "Ad", "Ah", "As"]

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
  attr_accessor :position, :card1, :card2, :score, :is_bot, :is_thinking, :chips, :name
  # attr_writer :chips
  def initialize
    @chips = 1500
    @score = 0
    @is_bot = false
    @is_thinking = false
  end

  # def chips
  #   @chips || 1500
  # end


end

class Dealer
  attr_accessor :flop, :turn, :river
end

class Game
  attr_accessor :pot, :players, :active_player
  attr_writer :small_blind, :big_blind

  def small_blind
    @small_blind || 10
  end

  def big_blind
    @big_blind || 20
  end

  def make_move current_bet, pot
    moves = current_bet > 0 ? ["c", "r", "f"] : ["c", "r"]

    decision = moves.sample
    if decision == "r"
      if current_bet > 0
        min_raise = current_bet * 2
      else
        min_raise = @big_blind
      end
      decision = "r" + (rand(min_raise..pot)).to_s
    end
    return decision
  end

  def move_dealer_button *players
    players.each { |p|
      if p.position == 0
        p.position = 1
      else
        p.position = p.position - 1
      end
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

  def pass_action
    @players.find{|p| p.is_thinking == false}.is_thinking = true
    @active_player.is_thinking = false
  end

  def change_streets
    @players.each{|p| p.is_thinking = false}
  end

  def raise_pot amount
    @pot = @pot + amount
    @active_player.chips = @active_player.chips - amount
    if @current_bet > 0
      puts "#{@active_player.name} reraises to #{amount+@current_bet}"
    else
      puts "#{@active_player.name} raises #{amount}"
    end
    @current_bet = amount
  end

  def check check_count, next_street
    puts "#{@active_player.name} checks"
    if check_count == @players.count
      @street = next_street
    end
  end

  def call amount, next_street
    @pot = @pot + @current_bet
    @active_player.chips = @active_player.chips - amount
    @current_bet = 0
    @street = next_street
    puts "#{@active_player.name} calls #{amount}"
  end

  def fold_hand
    puts "#{@active_player.name} folds."
    winner = @players.find { |p| p.is_thinking == false }
    winner.chips = winner.chips + @pot
    puts "#{winner.name} wins #{@pot}"
    @street = "end"
  end

  def start
    # create @players
    hero = Player.new
    hero.name = "Hero"
    hero.is_bot = false
    hero.position = 0
    villain = Player.new
    villain.name = "Villain"
    villain.is_bot = true
    villain.position = 1
    dealer = Dealer.new

    @small_blind = 10
    @big_blind = 20
    @street = "preflop"
    @players = [villain, hero]

    while hero.chips > 0 && villain.chips > 0 do
      puts "Hero: #{hero.chips} #{hero.position == 0 ? "BB" : "Button"}"
      puts "Villain: #{villain.chips} #{villain.position == 0 ? "BB" : "Button"}"
      while @street != "end" do
        puts "-------------START--------------"
        deck = Deck.new
        # move the dealer button
        move_dealer_button(hero, villain)
        # shuffle the deck
        deck.shuffle()
        # post the blinds
        if hero.position == 0
          hero.chips = hero.chips - @big_blind
          villain.chips = villain.chips - @small_blind
        else
          villain.chips = villain.chips - @big_blind
          hero.chips = hero.chips - @small_blind
        end
        @pot = @small_blind + @big_blind

        # deal the cards
        deal_cards(@players, deck)
        @current_bet = 0
        @street = "preflop"

        # binding.pry
        card1 = @@card_lut[hero.card1[0]]
        card2 = @@card_lut[hero.card2[0]]
        puts "Your Cards: #{card1}#{card2}"
        puts "Pot Size: #{@pot}"

        @preflop_checks = 0
        @flop_checks = 0
        @turn_checks = 0
        @river_checks = 0

        while @street == "preflop" do
          @active_player = @players.find { |p| p.is_thinking == true }
          if @active_player == nil
            @active_player = @players.find{|p| p.position == 0}
            @active_player.is_thinking = true
          end

          if @current_bet > 0
            puts "#{@current_bet} to call."
          end
          if @active_player.is_bot
            move = make_move(@current_bet, @pot)
          else
            puts "Hero: #{hero.chips}, Villain: #{villain.chips}, Pot: #{@pot}"
            puts "Hero's Move:"
            move = gets.chomp
          end
          bet = move.scan(/\d/).join('').to_i
          if bet == 0 then bet = @current_bet end

          case move
          when /^r/
            raise_pot(bet)
          when "c"
            if @current_bet > 0
              call(bet, next_street="flop")
            else
              #special case pre flop
              if @preflop_checks == 0
                # this is preflop limp
                @pot = @pot + @small_blind
                @active_player.chips = @active_player.chips - @small_blind
                puts "#{@active_player.name} calls."
                @preflop_checks = 1
              else
                @street = "flop"
                puts "#{@active_player.name} checks."
              end
            end
          when "f"
            fold_hand()
          else
            throw :invalidInput
          end

          pass_action()
        end

        change_streets()
        if @street == "end" then break end

        # if @street == "end" then break end
        dealer.flop = deck.pop(3)
        # binding.pry
        flop = [@@card_lut[dealer.flop[0]],@@card_lut[dealer.flop[1]], @@card_lut[dealer.flop[2]]]
        puts "Flop: #{flop[0]}#{flop[1]}#{flop[2]}"

        while @street == "flop" do
          @active_player = @players.find { |p| p.is_thinking == true }
          if @active_player == nil
            @active_player = @players.find{|p| p.position == 1}
            @active_player.is_thinking = true
          end

          if @active_player.is_bot
            move = make_move(@current_bet, @pot)
          else
            puts "Hero: #{hero.chips}, Villain: #{villain.chips}, Pot: #{@pot}"
            puts "Hero's Move:"
            move = gets.chomp
          end
          bet = move.scan(/\d/).join('').to_i
          if bet == 0 then bet = @current_bet end

          case move
          when /^r/
            raise_pot(bet)
          when "c"
            if @current_bet > 0
              call(bet, next_street="turn")
            else
              @flop_checks = @flop_checks + 1
              check(check_count=@flop_checks, next_street="turn")
            end
          when "f"
            fold_hand()
          else
            throw :invalidInput
          end

          pass_action()
        end

        change_streets()
        if @street == "end" then break end

        dealer.turn = deck.pop(1)
        # binding.pry
        turn = @@card_lut[dealer.turn[0]]
        puts "Turn: #{turn}"

        while @street == "turn" do
          @active_player = @players.find { |p| p.is_thinking == true }
          if @active_player == nil
            @active_player = @players.find{|p| p.position == 1}
            @active_player.is_thinking = true
          end

          if @active_player.is_bot
            move = make_move(@current_bet, @pot)
          else
            puts "Hero: #{hero.chips}, Villain: #{villain.chips}, Pot: #{@pot}"
            puts "Hero's Move:"
            move = gets.chomp
          end
          bet = move.scan(/\d/).join('').to_i
          if bet == 0 then bet = @current_bet end

          case move
          when /^r/
            raise_pot(bet)
          when "c"
            if @current_bet > 0
              call(bet, next_street="river")
            else
              @turn_checks = @turn_checks + 1
              check(check_count=@turn_checks, next_street="river")
            end
          when "f"
            fold_hand()
          else
            throw :invalidInput
          end

          pass_action()
        end

        change_streets()
        if @street == "end" then break end

        dealer.river = deck.pop(1)
        river = @@card_lut[dealer.river[0]]
        puts "River: #{river}"

        while @street == "river" do
          @active_player = @players.find { |p| p.is_thinking == true }
          if @active_player == nil
            @active_player = @players.find{|p| p.position == 1}
            @active_player.is_thinking = true
          end

          if @active_player.is_bot
            move = make_move(@current_bet, @pot)
          else
            puts "Hero: #{hero.chips}, Villain: #{villain.chips}, Pot: #{@pot}"
            puts "Hero's Move:"
            move = gets.chomp
          end
          bet = move.scan(/\d/).join('').to_i
          if bet == 0 then bet = @current_bet end

          case move
          when /^r/
            raise_pot(bet)
          when "c"
            if @current_bet > 0
              call(bet, next_street="showdown")
            else
              @river_checks = @river_checks + 1
              check(check_count=@river_checks, next_street="showdown")
            end
          when "f"
            fold_hand()
          else
            throw :invalidInput
          end

          pass_action()
        end


        change_streets()
        if @street == "end" then break end
        # find the winner
        board = [dealer.flop, dealer.turn, dealer.river]
        hero_hs = @@hand_eval.define_hand([hero.card1, hero.card2, board].flatten)
        villain_hs = @@hand_eval.define_hand([villain.card1, villain.card2, board].flatten)

        puts "Showdown."
        puts "Board: #{flop[0]}#{flop[1]}#{flop[2]}#{turn}#{river}"
        puts "Hero: #{@@card_lut[hero.card1[0]]}#{@@card_lut[hero.card2[0]]}"
        puts "Villain: #{@@card_lut[villain.card1[0]]}#{@@card_lut[villain.card2[0]]}"
        puts "Hero HS: #{hero_hs}"
        puts "Villain HS: #{villain_hs}"

        if hero_hs > villain_hs
          hero.chips = hero.chips + @pot
          puts "Hero wins #{@pot}"
        elsif hero_hs < villain_hs
          villain.chips = villain.chips + @pot
          puts "Villain wins #{@pot}"
        else
          hero.chips = hero.chips + @pot/2
          villain.chips = villain.chips + @pot/2
          puts "Hero & Villain tie. each win #{@pot/2}"
        end


      end
      @street = "preflop"
      puts "------------END---------------"
    end

  end
end


first_game = Game.new
first_game.start()
