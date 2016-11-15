require_relative 'hand_eval'
require_relative 'dealer'
require_relative 'deck'
require_relative 'player'
require_relative 'brain'

require 'pry'

@@hand_eval = HandEvaluator.new

@@card_lut = ["2c", "2d", "2h", "2s", "3c", "3d", "3h", "3s", "4c", "4d", "4h", "4s",
              "5c", "5d", "5h", "5s", "6c", "6d", "6h", "6s", "7c", "7d", "7h", "7s",
              "8c", "8d", "8h", "8s", "9c", "9d", "9h", "9s", "Tc", "Td", "Th", "Ts",
              "Jc", "Jd", "Jh", "Js", "Qc", "Qd", "Qh", "Qs", "Kc", "Kd", "Kh", "Ks",
              "Ac", "Ad", "Ah", "As"]

poker = Poker.new(@@card_lut)

class Poker
  attr_accessor :lookup_table
  def initialize(lookup_table)
    @lookup_table = lookup_table
  end
end

# keep track of the state of the player
class Streets
  def self.flop

  end
  def self.turn

  end
  def self.river

  end
end

# game should be in charge of keeping track of the game state.
class Game
  attr_accessor :pot, :players, :active_player, :small_blind, :big_blind,
                :active_street

  def move_dealer_button players
    players.each do |player|
      player.position = player.position != 0 ? player.position - 1 : 1
    end
  end

  def deal_cards players, deck
    players.sort_by(&:position).reverse! # terse and confusing: TODO: fix.
    players.each { |p| p.first_hole_card = deck.pop() }
    players.each { |p| p.second_hole_card = deck.pop() }
  end

  # TODO: remove dependencies to instance variables here.
  def pass_action
    @players.find{ |p| p.is_thinking === false}.is_thinking = true
    @active_player.is_thinking = false
  end

  def change_streets
    @players.each{|p| p.is_thinking = false}
  end

  def verify_legal_bet(pot, bet, player)
    # here are the ways a bet is not legal:
    # 1. bet puts player all in (in which case we divert to an all-in mode)
    # 2. bet is < big blind
    # 3. raise is < previous bet (if previous bet exists)
  end

  def raise_pot amount
    # check if a legal bet
    @pot += amount
    @active_player.chips -= amount
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

  def call_bet amount, next_street
    @pot += @current_bet
    @active_player.chips -= amount
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

    villain = Player.new(bot: true)
    villain.name = "Villain"
    villain.position = 1

    dealer = Dealer.new

    @small_blind, @big_blind = [10, 20]

    @street = "preflop"
    @players = [villain, hero]

    while hero.chips > 0 && villain.chips > 0 do
      puts "Hero: #{hero.chips} #{hero.position == 0 ? "BB" : "Button"}"
      puts "Villain: #{villain.chips} #{villain.position == 0 ? "BB" : "Button"}"
      while @street != "end" do
        puts "-------------START--------------"
        deck = Deck.new
        # move the dealer button
        move_dealer_button(@players)
        # shuffle the deck
        deck.shuffle()

        # post the blinds
        small_blind = @players.find { |player| player.position === 0 }
        small_blind.chips = small_blind.chips - @small_blind

        big_blind = (@players - [small_blind]).first
        big_blind.chips = big_blind.chips - @big_blind

        @pot = @small_blind + @big_blind

        # deal the cards
        deal_cards(@players, deck)

        @street = "preflop"

        first_hole_card = @@card_lut[hero.first_hole_card[0]]
        second_hole_card = @@card_lut[hero.second_hole_card[0]]

        puts "Your Cards: #{first_hole_card}#{second_hole_card}"
        puts "Blinds: #{@small_blind}/#{@big_blind}"

        @preflop_checks = 0
        @flop_checks = 0
        @turn_checks = 0
        @river_checks = 0

        while @street == "preflop" do
          @active_player = @players.find { |p| p.is_thinking == true }
          if @active_player.nil?
            @active_player = small_blind
            @active_player.is_thinking = true
          end

          @current_bet ||= @big_blind - @small_blind
          puts "#{@current_bet} to call."

          if @active_player.is_bot
            move = Brain.decide(@current_bet, @pot)
          else
            puts "Hero: #{hero.chips}, Villain: #{villain.chips}, Pot: #{@pot}"
            puts "Hero's Move:"
            move = gets.chomp
          end

          bet = move.scan(/\d/).join('').to_i # extract the bet amount if any.
          # bet = @current_bet if bet === 0

          case move
          when /^r/
            raise_pot(bet)
          when /^c$/
            # use cases:

            # 1. first to act (call the small blind / limp)
            if @pot == @small_blind + @big_blind
              @pot += @small_blind
              @active_player.chips -= @small_blind
              @current_bet = 0

            # 2. second+ to act (call a raise) => ends action
            elsif @current_bet > 0
              call_bet(outstanding_raise, next_street="flop") # ends the action

            # 3. second+ to act (check a limp)
            else
              @street = 'flop'
            end
          when /^f$/
            fold_hand()
          else
            throw :invalidInput
          end

          pass_action()
        end


        change_streets()
        if @street == "end" then break end


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
            move = Brain.decide(@current_bet, @pot)
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
              call_bet(bet, next_street="turn")
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
            move = Brain.decide(@current_bet, @pot)
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
              call_bet(bet, next_street="river")
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
            move = Brain.decide(@current_bet, @pot)
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
              call_bet(bet, next_street="showdown")
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
        hero_hs = @@hand_eval.define_hand([hero.first_hole_card, hero.second_hole_card, board].flatten)
        villain_hs = @@hand_eval.define_hand([villain.first_hole_card, villain.second_hole_card, board].flatten)

        puts "Showdown."
        puts "Board: #{flop[0]}#{flop[1]}#{flop[2]}#{turn}#{river}"
        puts "Hero: #{@@card_lut[hero.first_hole_card[0]]}#{@@card_lut[hero.second_hole_card[0]]}"
        puts "Villain: #{@@card_lut[villain.first_hole_card[0]]}#{@@card_lut[villain.second_hole_card[0]]}"
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
