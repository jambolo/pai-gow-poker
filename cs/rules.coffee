# rules.coffee
#
# Rules and facts for the game

# Enumeration of card ranks
LOW_ACE = 1 # Ace can be low in a straight (A-2-3-4-5)
# Note: 2-10 are represented by their integer values
JACK = 11
QUEEN = 12
KING = 13
ACE = 14
NUMBER_OF_RANKS = 13

# Joker is a special card. Both its rank and index are JOKER. Its suit is undefined.
JOKER = 52

CARD_RANK_NAMES = [
  "undefined" # 0 is not a valid rank
  "Ace"
  "2"
  "3"
  "4"
  "5"
  "6"
  "7"
  "8"
  "9"
  "10"
  "Jack"
  "Queen"
  "King"
  "Ace"
]

CARD_RANK_SYMBOLS = [
  "undefined" # 0 is not a valid rank
  "A"
  "2"
  "3"
  "4"
  "5"
  "6"
  "7"
  "8"
  "9"
  "10"
  "J"
  "Q"
  "K"
  "A" # Ace can be high or low, so it appears twice
]

# The name and symbol for the joker
JOKER_NAME = "Joker"
JOKER_SYMBOL = "?"

# Enumeration of card suits (in order of increasing value)
CLUBS = 0
DIAMONDS = 1
HEARTS = 2
SPADES = 3

SUIT_NAMES = [
  "Clubs"
  "Diamonds"
  "Hearts"
  "Spades"
]

SUIT_SYMBOLS = [
  "♣"
  "♦"
  "♥"
  "♠"
]

# Enumeration of hand ranks in order from lowest to highest
HIGH_CARD = 0
PAIR = 1
TWO_PAIR = 2
SET = 3
STRAIGHT = 4
FLUSH = 5
FULL_HOUSE = 6
QUADS = 7
STRAIGHT_FLUSH = 8
ROYAL_FLUSH = 9 # Royal Flush is here because everyone considers it a separate hand rank, but I don't use it.
FIVE_OF_A_KIND = 10

NUMBER_OF_HANDS = 11 # Number of different hand ranks

# Names of hand ranks
HAND_RANK_NAMES = [
  "High Card"
  "Pair"
  "Two Pair"
  "Set"
  "Straight"
  "Flush"
  "Full House"
  "Quads"
  "Straight Flush"
  "Royal Flush"
  "Five of a Kind"
]

# Returns the name of a suit
suitName = (suit) ->
  throw new Error "Invalid suit #{suit}" if not (CLUBS <= suit <= SPADES)
  SUIT_NAMES[suit]

# Returns the symbol of a suit
suitSymbol = (suit) ->
  throw new Error "Invalid suit #{suit}" if not (CLUBS <= suit <= SPADES)
  SUIT_SYMBOLS[suit]

# Returns the name of a rank
rankName = (rank) ->
  throw new Error "Invalid rank #{rank}" if not (LOW_ACE <= rank <= ACE) and rank isnt JOKER
  if rank is JOKER then JOKER_NAME else CARD_RANK_NAMES[rank - LOW_ACE] # -1 because LOW_ACE is 1

# Returns the symbol of a rank
rankSymbol = (rank) ->
  throw new Error "Invalid rank #{rank}" if not (LOW_ACE <= rank <= ACE) and rank isnt JOKER
  if rank is JOKER then JOKER_SYMBOL else CARD_RANK_SYMBOLS[rank]
# Returns the name of a card
cardName = (index) ->
  throw new Error "Invalid card #{index}" if not (0 <= index <= JOKER)
  if index is JOKER then JOKER_NAME else "#{rankName(rank(index))} of #{suitName(suit(index))}"

# Returns the name of a card
cardSymbol = (index) ->
  throw new Error "Invalid card #{index}" if not (0 <= index <= JOKER)
  if index is JOKER then JOKER_SYMBOL else "#{rankSymbol(rank(index))}#{suitSymbol(suit(index))}"

# Returns the name of a hand rank
handRankName = (rank) ->
  throw new Error "Invalid hand rank #{rank}" if not (HIGH_CARD <= rank <= FIVE_OF_A_KIND)
  HAND_RANK_NAMES[rank]

# Convert card rank and suit to a single index
index = (rank, suit) ->
  throw new Error "Invalid rank #{rank}" if not (LOW_ACE <= rank <= ACE) and rank isnt JOKER
  throw new Error "Invalid suit #{suit}" if not (CLUBS <= suit <= SPADES)
  if rank == LOW_ACE
    rank = ACE # Treat low ace as high ace for index calculation
  if rank is JOKER then JOKER else (rank - 2) * 4 + suit

# Convert card to rank and suit
rankSuit = (index) ->
  throw new Error "Invalid card #{index}" if not (0 <= index <= JOKER)
  [rank(index), suit(index)]

# Returns the rank of a card
rank = (index) ->
  throw new Error "Invalid card #{index}" if not (0 <= index <= JOKER)
  if index is JOKER then JOKER else Math.floor(index / 4) + 2 # + 2 because ranks start from 2 (2-10, J, Q, K, A)

# Returns the suit of a card
suit = (index) ->
  throw new Error "Invalid card #{index}" if not (0 <= index <= JOKER)
  index % 4

module.exports = {
  LOW_ACE
  JACK
  QUEEN
  KING
  ACE
  JOKER
  CLUBS
  DIAMONDS
  HEARTS
  SPADES
  HIGH_CARD
  PAIR
  TWO_PAIR
  SET
  STRAIGHT
  FLUSH
  FULL_HOUSE
  QUADS
  STRAIGHT_FLUSH
  FIVE_OF_A_KIND
  NUMBER_OF_HANDS
  CARD_RANK_NAMES
  JOKER_NAME
  JOKER_SYMBOL
  SUIT_NAMES
  HAND_RANK_NAMES
  suitName
  suitSymbol
  rankName
  rankSymbol
  cardName
  cardSymbol
  handRankName
  index
  rankSuit
  rank
  suit
}
