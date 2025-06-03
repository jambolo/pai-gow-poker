# list-all-settings.coffee
#
# Given a list of 7 cards, list all paigow hand pairs that can be made.

yargs = require 'yargs'
rules = require './rules'
classifier = require './classifier'

RANK_SYMBOLS = '23456789TJQKA'
SUIT_SYMBOLS = 'CDHS'

# Checks if a card input is valid
isValidCard = (s) ->
  return false if not s or s.length > 2
  return false if s isnt 'X' and (not (s[0] in RANK_SYMBOLS) or not (s[1] in SUIT_SYMBOLS))
  return true

# Parse command line arguments
argv = yargs(process.argv.slice 2)
  .usage '$0 <cards...>', 'Lists all paigow settings that can be made from the given 7 cards.',
    (yargs) ->
      yargs
        .positional 'cards', {
          type: 'string'
          describe: '''
            List of 7 cards to set. Each is one of "23456789TJQKA" followed by one of "CDHS", or "X" for a joker.
            For example, 2H 3D 4C 5S 6H 7D X
          '''
        }
    ,
    (argv) ->
      if argv.cards.length != 7
        console.error "You must provide exactly 7 cards. Got #{argv.cards.length}."
        process.exit(1)
      argv.cards.forEach (card) ->
        if not isValidCard(card)
          console.error "Invalid card: '#{card}'"
          process.exit(1)
  .option 'all', {
    alias: 'a'
    type: 'boolean'
    default: false
    describe: 'Includes every hand, even the ones that are strictly worse than another hand.'
  }
  .option 'json', {
    alias: 'j'
    type: 'boolean'
    default: false
    describe: 'Output the results in JSON format.'
  }
  .argv

# Parses the cards from the command line
parseCard = (s) ->
  throw new Error "Invalid card symbol: #{s}" if not isValidCard(s)
  if s == 'X'
    return rules.JOKER
  rank = RANK_SYMBOLS.indexOf(s[0]) + 2 # +2 because '2' is the lowest rank
  suit = SUIT_SYMBOLS.indexOf s[1]
  return rules.index rank, suit

# Sorts a hand of cards by their rank in descending order
sortByRank = (hand) ->
  hand.sort (a, b) -> rules.rank(b) - rules.rank(a)
  return

# Analyzes a hand and returns the best hand rank, the cards in that hand, and its value
analyzeHand = (cards) ->
  result = classifier.bestHand cards
  remainder = cards.filter (c) -> not (c in result.cards)
  sortByRank remainder
  value = classifier.enumerateHand(result.rank, result.cards, remainder)
  return { rank: result.rank, hand: result.cards, value }

# Prints the settings in a human-readable format
printSettings = (settings) ->
  for setting, i in settings
    fiveSymbols = setting.five.hand.map(rules.cardSymbol).join(' ')
    twoSymbols = setting.two.hand.map(rules.cardSymbol).join(' ')
    console.log "#{i + 1}:",
      fiveSymbols, "=>", rules.handRankName(setting.five.rank), "(#{setting.five.value}),",
      twoSymbols, "=>", rules.handRankName(setting.two.rank), "(#{setting.two.value})"

cards = argv.cards.map parseCard

# Print the cards in a human-readable format
if not argv.json
  console.log "Cards:", cards.map(rules.cardSymbol).join(' ')

# Generate all settings
settings = []
for i in [0...cards.length - 1]
  for j in [i + 1...cards.length]
    two = [cards[i], cards[j]]
    sortByRank two
    twoInfo = analyzeHand two

    five = cards.filter (c) -> not (c in two)
    sortByRank five
    fiveInfo = analyzeHand five

    settings.push {
      five: { rank: fiveInfo.rank, hand: five, value: fiveInfo.value }
      two: { rank: twoInfo.rank, hand: two, value: twoInfo.value }
    }

# Sort the settings by descending value of the five-card hand, then the two-card hand
settings.sort (a, b) ->
  if a.five.value != b.five.value
    b.five.value - a.five.value
  else
    b.two.value - a.two.value

# If there are two settings and the values of the two hands in one are both the same or lower than the other, then
# there is no point in keeping it. So by default, it is filtered out.
if not argv.all
  # Filter out any hand that is strictly worse or the same as another hand
  maxTwoValue = -1
  settings = settings.filter (s) ->
    if s.two.value > maxTwoValue
      maxTwoValue = s.two.value
      true
    else
      false

# Print the results
if argv.json
  console.log JSON.stringify(settings)
else
  console.log "Found #{settings.length} settings:"
  printSettings settings
