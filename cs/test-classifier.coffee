# test-classifier.coffee
#
# Tests the classifier with poker hand data from testing data

fs = require 'fs'
assert = require 'assert'
classifier = require './classifier'
rules = require './rules'

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
  rules.STRAIGHT_FLUSH    # 9
  rules.FIVE_OF_A_KIND   # 10
]

# Sorts the hand by descending rank only
sortByRank = (hand) ->
  hand.sort((a, b) -> rules.rank(b) - rules.rank(a))
  return

read_line = (line) ->
  parts = line.split(',').map Number
  # Each line: s1,r1,s2,r2,s3,r3,s4,r4,s5,r5,handId
  hand = []
  for i in [0...5]
    suit = parts[i * 2] - 1 # Suits are 1-based in the data. Also, the actual suit is irrelevant for the test
    rank = parts[i * 2 + 1] # Data uses 1 for ace and that is ok
    hand.push rules.index(rank, suit)
  expected = idToRank[parts[10]]
  return [hand, expected]

# Get the file name from the command line arguments, default to 'data/poker-hand-testing.csv' if not provided
inputName = process.argv[2] or 'data/poker-hand-testing.csv'
console.log "Testing classifier with", inputName

# Read the file and test the classifier for each line
fs.readFile inputName, 'utf8', (err, data) ->
  throw err if err
  numberOfFailures = 0
  lines = data.trim().split '\n'
  for line, idx in lines
    [hand, expected] = read_line line
    sortByRank hand
    symbols = hand.map rules.cardSymbol
    result = classifier.bestHand hand

    assert.strictEqual(
      result.rank,
      expected,
      [
        "Failed at line #{idx+1}:",
        symbols.join(' '),
        "expected: #{rules.handRankName(expected)},",
        "got: #{rules.handRankName(result.rank)}"
      ].join(' ')
    )
#    if result.rank != expected
#      numberOfFailures += 1
#      console.error "Failed at line #{idx+1}:",
#        symbols.join(' '),
#        "expected: #{rules.handRankName(expected)},",
#        "got: #{rules.handRankName(result.rank)}"
#
#  if numberOfFailures > 0
#    console.error "#{numberOfFailures} tests failed"
#  else
#    console.log "All tests passed"

  console.log "All tests passed"
