rules = require './rules'

# Returns the best hand from a given set of cards along with its rank
bestHand = (hand) ->
  tests = [
    { rank: rules.STRAIGHT_FLUSH, func: bestStraightFlush }
    { rank: rules.QUADS, func: bestQuads }
    { rank: rules.FULL_HOUSE, func: bestFullHouse }
    { rank: rules.FLUSH, func: bestFlush }
    { rank: rules.STRAIGHT, func: bestStraight }
    { rank: rules.SET, func: bestSet }
    { rank: rules.TWO_PAIR, func: bestTwoPair }
    { rank: rules.PAIR, func: bestPair }
    { rank: rules.HIGH_CARD, func: bestHighCard }
  ]

  for test in tests
#    console.log "Testing for #{rules.handRankName test.rank}"
    cards = test.func hand
    if cards?
      return { rank: test.rank, cards }

  throw new Error "No ranking found"
  
# Returns the best high card in a hand sorted by rank as an array of cards
# Assumes hand is sorted by descending rank
bestHighCard = (hand) ->
  hand[0...1]

# Finds the best pair in a hand sorted by rank, and returns those cards or null if no pair exists
# Assumes hand is sorted by descending rank
bestPair = (hand) ->
  # Hand is sorted by rank, so we can just check adjacent cards for a pair
  for i in [0...hand.length - 1]
    if rules.rank(hand[i]) == rules.rank(hand[i + 1])
      return hand[i...i + 2]
  return null

# Finds the best two pair in a hand sorted by rank, and returns those cards or null if no two pair exists
# Assumes hand is sorted by descending rank
# The return cards are sorted by descending rank
bestTwoPair = (hand) ->
  # Hand is sorted by rank, so we can just check adjacent cards for a pair twice
  for i in [0...hand.length - 1]
    if rules.rank(hand[i]) == rules.rank(hand[i + 1])
      for j in [i + 2...hand.length - 1]
        if rules.rank(hand[j]) == rules.rank(hand[j + 1])
          return hand[i...i + 2].concat hand[j...j + 2]
      return null # If we get here, we have at one pair but no two pair
  return null

# Finds the best set in a hand sorted by rank, and returns those cards or null if no set exists
# Assumes hand is sorted by descending rank
bestSet = (hand) ->
  # Hand is sorted by rank, so we can just check adjacent cards for a set of three
  for i in [0...hand.length - 2]
    r = rules.rank(hand[i])
    if r == rules.rank(hand[i + 1]) and r == rules.rank(hand[i + 2])
      return hand[i...i + 3]
  return null

# Finds the best straight in a hand sorted by rank, and returns those cards or null if no straight exists
# Assumes hand is sorted by descending rank
# The return cards are sorted by descending rank except for the special cases of a low ace straight with the order
# 5, 4, 3, 2, A.
bestStraight = (hand) ->
  # We don't care about suits so duplicated ranks are removed to make it easier to find a straight
  deduped = removeDuplicatedRanks hand
#  console.log "Deduped hand: #{deduped.map(rules.cardSymbol).join(' ')}"
  # If the resulting hand is less than 5 cards, then it can't be a straight
  if deduped.length < 5
    return null
  
  start = findFirst5ConsecutiveCards deduped
  if start?
#      console.log "Found straight at #{start} in deduped hand: #{deduped.map(rules.cardSymbol).join(' ')}"
    return deduped[start...start + 5]
  
  # If no straight has been found and the hand contains an ace, then check for the special case of a low ace straight
  # (5, 4, 3, 2, A). The cards are sorted, so 5, 4, 3, 2 must be the last four cards.
  if rules.rank(deduped[0]) == rules.ACE
    lastFour = deduped[-4...]
#      console.log "first card: #{rules.rank(deduped[0])} Last four cards: #{lastFour.map(rules.rank)}"
    lastFourRanks = lastFour.map(rules.rank)
    if arraysEqual(lastFourRanks, [5, 4, 3, 2])
      return lastFour.concat [deduped[0]] # Note that this is not sorted by rank

  return null
  
# Finds the best flush in a hand, and returns those cards or null if no flush exists
# Assumes hand is sorted by descending rank and contains at most 9 cards
bestFlush = (hand) ->
  if hand.length > 9
    throw new Error "Hand is too large for flush check"

  suits = collateBySuit hand
  for s in suits
    if s.length >= 5
      return s[0...5] # Assumes collateBySuit returns cards sorted by descending rank
  return null

# Finds the best full house in a hand sorted by rank, and returns those cards or null if no full house exists
# Assumes hand is sorted by descending rank
bestFullHouse = (hand) ->
  three = bestSet hand
  if three?
    remainingCards = hand.filter((card) ->
      rules.rank(card) isnt rules.rank(three[0])
    )
    pair = bestPair remainingCards
    if pair?
      return three.concat pair
  return null

# Finds the best quads in a hand sorted by rank, and returns those cards or null if no quads exist
# Assumes hand is sorted by descending rank
bestQuads = (hand) ->
  for i in [0...hand.length - 3]
    r = rules.rank hand[i]
    if r == rules.rank(hand[i + 1]) and r == rules.rank(hand[i + 2]) and r == rules.rank(hand[i + 3])
      return hand[i...i + 4]
  return null

# Finds the best straight flush in a hand sorted by rank, and returns those cards or null if no straight flush exists
# Assumes hand is sorted by descending rank and contains at most 9 cards
bestStraightFlush = (hand) ->
  if hand.length > 9
    throw new Error "Hand is too large for straight flush check"
  suits = collateBySuit hand
  for s in suits
    straight = bestStraight s
    if straight?
      return straight
  return null

# Returns a hand sorted by descending rank then by ascending suit
sortByRankThenSuit = (hand) ->
  hand.sort((a, b) ->
    rankA = rules.rank a
    rankB = rules.rank b
    if rankA == rankB
      return rules.suit(a) - rules.suit(b)
    else
      return rankB - rankA
  )

# Returns a hand sorted by ascending suit then by descending rank
sortBySuitThenRank = (hand) ->
  hand.sort((a, b) ->
    suitA = rules.suit a
    suitB = rules.suit b
    if suitA == suitB
      return rules.rank(b) - rules.rank(a)
    else
      return suitA - suitB
  )

# Returns a hand sorted by descending rank only
sortByRank = (hand) ->
  hand.sort((a, b) -> rules.rank(b) - rules.rank(a))

# Removes cards with duplicate ranks from a hand
removeDuplicatedRanks = (hand) ->
  seenRanks = new Set()
  hand.filter((card) ->
    rank = rules.rank card
    if seenRanks.has rank
      false
    else
      seenRanks.add rank
      true
  )

# Returns the index of the first of 5 consecutive cards by rank (a straight), or null if none is found.
# Assumes hand is deduplicated and sorted by descending rank
findFirst5ConsecutiveCards = (hand) ->
#  console.log "findFirst5ConsecutiveCards: #{hand}"
  for i in [0...hand.length - 4]
#    console.log "Checking cards #{i} (#{rules.cardSymbol hand[i]}) and #{i + 4} (#{rules.cardSymbol hand[i + 4]})"
    if rules.rank(hand[i + 4]) == rules.rank(hand[i]) - 4 # Clever
      return i
  return null

# Collates a hand into an array of hands, one for suit sorted by descending rank and returns the result
# Assumes hand is sorted by descending rank
collateBySuit = (hand) ->
#  console.log "collateBySuit: #{hand}"
  collated = [[], [], [], []]
  for card in hand
    suit = rules.suit card
    collated[suit].push card
  return collated

arraysEqual = (a, b) ->
  return false if a.length != b.length
  for i in [0...a.length]
    return false if a[i] != b[i]
  return true

module.exports = {
  bestHand
  bestHighCard
  bestPair
  bestTwoPair
  bestSet
  bestStraight
  bestFlush
  bestFullHouse
  bestQuads
  bestStraightFlush
}