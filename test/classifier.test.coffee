# test-classifier.coffee
#
# Mocha tests for the classifier with poker hand data from testing data

fs = require 'fs'
assert = require 'assert'
classifier = require '../cs/classifier'
rules = require '../cs/rules'
{ sortByRank } = require '../cs/common'


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

test_enumerateHand = ->
  tests = [
    { input: [rules.FIVE_OF_A_KIND, [49, 50, 48, 51, 52], []], expected: 11464430 }
    { input: [rules.HIGH_CARD, [20, 13, 10,  7 , 0], []], expected: 480306 }
    { input: [rules.PAIR, [50, 51], []], expected: 2023424 }
    { input: [rules.HIGH_CARD, [ 5,  3], []], expected: 204800 }
  ]
  it 'enumerateHand', ->
    for test in tests
      result = classifier.enumerateHand(test.input[0], test.input[1], test.input[2])
      assert.strictEqual(result, test.expected,
        "enumerateHand failed for input: #{JSON.stringify(test.input)}. Expected: #{test.expected}, got: #{result}"
      )

test_bestHand = ->
  inputName = process.env.CLASSIFIER_TEST_FILE or 'data/poker-hand-testing.csv'
  data = null

  before (done) ->
    fs.readFile inputName, 'utf8', (err, fileData) ->
      return done(err) if err
      data = fileData
      done()

  it 'bestHand', ->
    lines = data.trim().split '\n'
    for line, idx in lines
      [hand, expected] = read_line line
      sortByRank hand
      symbols = hand.map rules.cardSymbol
      result = classifier.bestHand hand
      resultSymbols = result.cards.map rules.cardSymbol

      # Verify the rank
      assert.strictEqual(
        result.rank,
        expected,
        [
          "Failed at line #{idx+1}:",
          symbols.join(' '),
          "expected: #{rules.handRankName(expected)},",
          "got: (#{resultSymbols.join(' ')}) as #{rules.handRankName(result.rank)}"
        ].join(' ')
      )

      # Verify that returned hand is correct by repeating the test with it and making sure it returns the same result
      hand2 = result.cards.slice()
      sortByRank hand2
      again = classifier.bestHand hand2
      againSymbols = again.cards.map rules.cardSymbol

      assert.strictEqual(
        again.rank,
        expected,
        [
          "Failed at line #{idx+1}:",
          "#{resultSymbols.join(' ')} (from #{symbols.join(' ')})",
          "expected: #{rules.handRankName(expected)},",
          "got: (#{againSymbols.join(' ')}) as #{rules.handRankName(again.rank)}"
        ].join(' ')
      )

      assert.deepStrictEqual(
        result.cards,
        again.cards,
        [
          "Failed at line #{idx+1}:",
          "#{resultSymbols.join(' ')} (from #{symbols.join(' ')})",
          "expected reclassification to return the same cards,",
          "but got: #{againSymbols.join(' ')},",
        ].join(' ')
      )

describe 'classifier module', ->
  test_enumerateHand()
  test_bestHand()

