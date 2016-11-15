require_relative 'dealer'
require_relative 'player'
require_relative 'robot'
require_relative 'table'

dealer = Dealer.new
table = Table.new

# give someone the button! (TODO: randomly in future)
player = Player.new(button: true)
robot = Robot.new(button: false)

players = [player, robot]

# button is positioned
move_button

# dealer deals cards
deal_hole_cards

# players post blinds
player.post_blind
robot.post_blind

# do play-by-play stuff => 1
table.flop = dealer.deal!('flop')
# do play-by-play stuff => 2
table.turn = dealer.deal!('turn')
# do play-by-play stuff => 3
table.river = dealer.deal!('river')
# do play-by-play stuff => 4

# start again if applicable

def move_button
  player.button = !player.button
  robot.button = !robot.button
end

def deal_hole_cards(players)
  small_blind = players.find { |player| player.button }
  big_blind = players.find { |player| !player.button }

  (1..2).each do
    small_blind.hole_cards.push(dealer.deck.deal!)
    big_blind.hole_cards.push(dealer.deck.deal!)
  end
end
