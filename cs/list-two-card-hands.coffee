# list-two-card-hands.coffee
#
# Generates and sorts all possible two-card hands (ignoring suit) in Pai Gow Poker by value

JACK = 11
QUEEN = 12
KING = 13
ACE = 14
JOKER = 15

# Returns the symbol of the card based on its value
symbol = (i) ->
  if i == JACK then "J"
  else if i == QUEEN then "Q"
  else if i == KING then "K"
  else if i == ACE then "A"
  else if i == JOKER then "*"
  else i.toString()

# Define the <=> operator
compare = (a, b) -> if a < b then -1 else if a > b then 1 else 0

hands = []
for i in [2..ACE]
  for j in [i..ACE]
    hands.push [j, i] # Ensure that the first card is always >= the second card

hands.sort (a, b) ->
  if a[0] == a[1]
    if b[0] == b[1] then compare(a[0], b[0]) else 1
  else if b[0] == b[1] then -1
  else if a[0] > b[0] then 1
  else if a[0] < b[0] then -1
  else compare(a[1], b[1])

hands.forEach ([a, b], i) -> console.log "#{i + 1}: " + symbol(a) + " " + symbol(b)
