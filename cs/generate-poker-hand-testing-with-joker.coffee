# generate-poker-hand-testing-with-joker.coffee
#
# Generates additional test cases for the classifier that include a joker. Test cases are derived from the file
# data/poker-hand-testing.csv.
fs = require 'fs'
assert = require 'assert'
classifier = require './classifier'
rules = require './rules'
{ sortByRank } = require './common'
yargs = require 'yargs'

# Map ids to rules constants as described
idToRank = [
  rules.HIGH_CARD,        # 0
  rules.PAIR,             # 1
  rules.TWO_PAIR,         # 2
  rules.SET,              # 3
  rules.STRAIGHT,         # 4
  rules.FLUSH,            # 5
  rules.FULL_HOUSE,       # 6
  rules.QUADS,            # 7
  rules.STRAIGHT_FLUSH,   # 8
  rules.STRAIGHT_FLUSH,   # 9  (Royal flush is treated as a straight flush)
  rules.FIVE_OF_A_KIND    # 10
]

DEFAULT_INPUT_PATH = 'data/poker-hand-testing.csv'
DEFAULT_OUTPUT_PATH = 'data/poker-hand-testing-with-joker.csv'

# Parse command line arguments
args = yargs(process.argv.slice 2)
  .usage(
    '$0 [input] [--output <path>]',
    'Generates from the input test file additional test cases that include a joker',
    (yargs) ->
      yargs
        .positional 'input', {
          type: 'string'
          describe: 'Test cases input file'
          default: DEFAULT_INPUT_PATH
        }
  )
  .option 'output', {
    alias: 'o',
    describe: 'Output path for test cases with a joker',
    default: DEFAULT_OUTPUT_PATH
  }
  .argv

# Returns an array with all duplicate ranks removed.
# The cards are assumed to be sorted by rank
removeDuplicateRanks = (hand) ->
  deduped = []
  lastRank = null
  for card in hand
    rank = rules.rank card
    if rank != lastRank # If the rank is different from the last one, then add it to the deduped array
      deduped.push card
      lastRank = rank # Update the last rank
  return deduped

# Groups the hand by suit and returns an array of arrays, where each inner array contains cards of the same suit
# sorted by rank.
# The hand is assumed to be sorted by rank
collateSuits = (hand) ->
  # The hand is assumed to not contain a joker
  throw new Error('collateSuits() called with a joker.') if hand[0] == rules.JOKER

  suits = [[], [], [], []]
  for card in hand
    suit = rules.suit card
    suits[suit].push card # Add the card to the appropriate suit
  return suits

# Returns true if the hand is a flush (or straight flush) with a joker
# The hand is assumed to be sorted and contain a joker, so the joker is always the first card
isFlushWithJoker = (hand) ->
  # If the hand does not contain a joker, then error
  throw new Error('isFlushWithJoker() called with no joker.') if hand[0] != rules.JOKER

  # A flush must contain at least 5 cards
  return false if hand.length < 5

  # Group cards (except the joker) by suit
  suits = collateSuits hand[1...]

  # If any suits have 4 more more cards, then a flush can be made with the joker
  for s in suits
    return true if s.length >= 4

  return false

# Returns true if the hand is a straight (or straight flush) with a joker
# The hand is assumed to be sorted and contain a joker, so the joker is always the first card
isStraightWithJoker = (hand) ->
  # The hand is assumed to be sorted and contain a joker
  throw new Error 'isStraightWithJoker() called with no joker.' if hand[0] != rules.JOKER

  # Remove the joker and duplicated ranks from the hand
  deduped = removeDuplicateRanks hand[1...]

  # A straight must contain at least 5 cards
  return false if deduped.length < 5

  # Check for possible straights in the deduped hand
  for i in [0...deduped.length - 3]
    # If the difference in rank between cards i and i + 3 is less than 5, then those cards can make a straight
    # with a joker on the ends or in the middle
    return true if rules.rank(deduped[i]) - rules.rank(deduped[i + 3]) < 5

  # Check for a special case where the hand contains an ace, and any 3 of 2, 3, 4, 5
  if rules.rank(deduped[0]) == rules.ACE
      r0 = rules.rank deduped[deduped.length - 3] # First card in the possible straight
      return true if r0 == 4 or r0 == 5

  # If no straight possibilities were found, then return false
  return false

# Returns true if the hand is a straight flush with a joker
isStraightFlushWithJoker = (hand) ->

  # The hand is assumed to be sorted and contain a joker
  throw new Error('isStraightFlushWithJoker() called with no joker.') if hand[0] != rules.JOKER

  # A straight flush must contain at least 5 cards
  return false if hand.length < 5

  # Group cards (except the joker) by suit
  suits = collateSuits hand[1...]

  # Check any suits with 4 more more cards, the minimum need for a straight with a joker
  for s in suits when s.length >= 4
    # Check for possible straights in the deduped hand
    for i in [0...s.length - 3]
      # If the difference in rank between cards i and i + 3 is less than 5, then those cards can make a straight
      # with a joker on the ends or in the middle
      return true if rules.rank(s[i]) - rules.rank(s[i + 3]) < 5

    # Check for a special case where the hand contains an ace, and any 3 of 2, 3, 4, 5
    if rules.rank(s[0]) == rules.ACE
      r0 = rules.rank s[s.length - 3] # First card in the possible straight
      return true if r0 == 4 or r0 == 5

  # If no straight possibilities were found, then return false
  return false

# Returns true if the hand is five of a kind with a joker
isFiveOfAKindWithJoker = (hand) ->
  # The hand is assumed to be sorted and contain a joker
  throw new Error('isFiveOfAKindWithJoker() called with no joker.') if hand[0] != rules.JOKER

  # A five-of-a-kind must contain at least 5 cards
  return false if hand.length < 5

 # If the last card is an ace, then it is a five of a kind with a joker
  return rules.rank(hand[4]) == rules.ACE

# Replaces an ace with a Joker if it exists in the hand and returns the modified hand, or null if no ace is found
# The returned hand is not sorted
replaceAceWithJoker = (hand) ->
  # If the hand does not contain an ace, then skip it
  i = hand.findIndex (card) -> rules.rank(card) == rules.ACE
  return null if i < 0

  # Replace the ace with a joker
  replaced = hand.slice() # Make a copy of the hand so we can modify it
  replaced[i] = rules.JOKER
  return replaced

# Replaces an ace with a joker in a straight and returns the modified hand, or null if there is no ace or if the joker
# makes it a flush (or straight flush)
# The returned hand is not sorted
replaceStraightWithJoker = (hand) ->
  # Replace an ace with a joker
  # Replacing only an ace prevents the joker from improving the hand to a full house or quads
  replaced = replaceAceWithJoker hand
  return null unless replaced?

  # Return the modified hand unless it makes a flush with a joker
  sorted = replaced.slice()
  sortByRank sorted
  return if not isFlushWithJoker(sorted) then replaced else null

# Replaces an ace with a joker in a flush and returns the modified hand, or null if there is no ace or if the joker
# makes it a straight flush
# The returned hand is not sorted
replaceFlushWithJoker = (hand) ->
  # Replace an ace with a joker
  # Replacing only an ace prevents the joker from improving the hand to a full house or quads
  replaced = replaceAceWithJoker hand
  return null unless replaced?

  # Return the modified hand unless it makes a straight flush with a joker
  sorted = replaced.slice()
  sortByRank sorted
  return if not isStraightFlushWithJoker(sorted) then replaced else null

# Replaces an ace with a Joker in a quads hand and returns the modified hand, or null if there is no ace or the joker
# makes it a straight or flush. If the hand is quad aces, then the non-ace card is replaced with a joker.
# The returned hand is not sorted
replaceQuadsWithJoker = (hand) ->
  # Replace any ace with a joker. If the hand does not contain an ace, then skip it
  # Replacing only an ace prevents the joker from improving the hand, except for making a straight or flush
  replaced = replaceAceWithJoker hand
  return null unless replaced?

  # Sort the hand by rank
  sorted = replaced.slice()
  sortByRank sorted

  # If the hand is a straight flush with a joker, then skip it
  return null if isStraightFlushWithJoker(sorted)

  # If the hand is not a flush or straight with a joker, then return the modified hand
  return replaced

# Replaces an ace with a joker in a straight flush and returns the modified hand, or null if there is no ace
# The returned hand is not sorted
replaceStraightFlushWithJoker = (hand) ->
  # Since a straight flush cannot be improved, any card can be replaced with a joker
  replaced = hand.slice() # Make a copy of the hand so we can modify it
  replaced[Math.floor(Math.random() * replaced.length)] = rules.JOKER
  return replaced

# Replaces an ace with a Joker in a hand and returns the modified hand, or null if there is no ace or the joker
# makes it a straight or flush
# The returned hand is not sorted
replaceAllOthersWithJoker = (hand) ->
  # Replace any ace with a joker. If the hand does not contain an ace, then skip it
  # Replacing only an ace prevents the joker from improving the hand, except for making a straight or flush
  replaced = replaceAceWithJoker hand
  return null unless replaced?

  # Sort the hand by rank
  sorted = replaced.slice()
  sortByRank sorted

  # If the hand is a flush or straight with a joker, then skip it
  return null if isFlushWithJoker(sorted) or isStraightWithJoker(sorted)

  # If the hand is not a flush or straight with a joker, then return the modified hand
  return replaced

read_line = (line) ->
  parts = line.split(',').map Number
  # Each line: s1,r1,s2,r2,s3,r3,s4,r4,s5,r5,handId
  hand = []
  for i in [0...5]
    suit = parts[i * 2] - 1 # Suits are 1-based in the data. Also, the actual suit is irrelevant for the test
    rank = parts[i * 2 + 1]
    if rank == 1 then rank = rules.ACE
    hand.push rules.index(rank, suit)
  expected = idToRank[parts[10]]
  return [hand, expected]

# Flattens an array of arrays into a single array
flatten = (aOfA) -> [].concat.apply [], aOfA

console.log 'Generating test cases with a joker from', args.input

# Main starts here

# Read the file and process each line
fs.readFile args.input, 'utf8', (err, data) ->
  throw err if err
  output = []
  lines = data.trim().split '\n'
  for line, idx in lines
    [hand, expected] = read_line line
    switch expected
      when rules.STRAIGHT
        hand = replaceStraightWithJoker hand
        output.push { hand, expected } if hand? # If the hand was modified, then add it to the output
      when rules.FLUSH
        hand = replaceFlushWithJoker hand
        output.push { hand, expected } if hand? # If the hand was modified, then add it to the output
      when rules.STRAIGHT_FLUSH
        hand = replaceStraightFlushWithJoker hand
        output.push { hand, expected } if hand? # If the hand was modified, then add it to the output
      when rules.QUADS
        # If the hand is a quad aces, then also create a five-of-a-kind test case (only 4 aces and a joker)
        numberOfAces = hand.reduce ((count, card) -> count + (rules.rank(card) == rules.ACE)), 0
        if numberOfAces == 4
          fiveAces = hand.slice() # Make a copy of the hand so we can modify it
          i = fiveAces.findIndex (card) -> rules.rank(card) != rules.ACE
          fiveAces[i] = rules.JOKER
          output.push { hand: fiveAces, expected: rules.FIVE_OF_A_KIND }
        hand = replaceQuadsWithJoker hand
        output.push { hand, expected } if hand? # If the hand was modified, then add it to the output
      else
        hand = replaceAllOthersWithJoker hand
        output.push { hand, expected } if hand? # If the hand was modified, then add it to the output

  console.log "Found #{output.length} test cases"

  # For each element in output, massage rank values and convert to an array of integers
  # Note that the royal flush expected values have been changed to straight flush and that's ok

  outputLines = output.map (o) ->
    hand = o.hand.map (card) ->
      [r, s] = rules.rankSuit card # Get rank and suit
      if r is rules.ACE then r = 1 # Convert high ace to 1
      s += 1 # Convert suit to 1-based index
      return [s, r] # Return suit and rank as an array
    flatten(hand).concat [o.expected] # Flatten the hand and append expected

  # Write the output to a file in the same format as the input
  fs.writeFile(
    args.output,
    outputLines.map((o) -> o.join(',')).join('\n'),
    (err) -> throw err if err
  )
  console.log "Generated #{output.length} test cases written to", args.output
