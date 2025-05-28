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
# If a JOKER is returned then it should be treated as an ace
bestHighCard = (hand) ->
  return null if hand.length < 1 # At least one card is necessary for a high card
  hand[0...1] # Returns the first card in the hand, which is the highest card

# Finds the best pair in a hand sorted by rank, and returns those cards or null if no pair exists
# Assumes hand is sorted by descending rank
bestPair = (hand) ->
  return null if hand.length < 2 # At least two cards are necessary for a pair

  # Hand is sorted by rank, so we can just check adjacent cards for a pair
  # Joker can be an ace. If there is a joker (it must be the first card), then check if there is an ace (it must be
  # the next card)
  return hand[0...2] if hand[0] == rules.JOKER and rules.rank(hand[1]) == rules.ACE

  # Otherwise, the joker is not relevant
  start = findFirstPair(hand)
  return if start? then hand[start...start + 2] else null

# Finds the best two pair in a hand sorted by rank, and returns those cards or null if no two pair exists
# Assumes hand is sorted by descending rank
# The return cards are sorted by descending rank
bestTwoPair = (hand) ->
  return null if hand.length < 4 # At least four cards are necessary for a two-pair
  # Hand is sorted by rank, so we can just check adjacent cards for a pair twice
  # Joker can be an ace. If there is a joker (it must be the first card), then check if there is an ace (it must be
  # the next card). If so, then check the rest of the hand for another pair.
  if hand[0] == rules.JOKER and rules.rank(hand[1]) == rules.ACE
    firstPair = hand[0...2]
    s = findFirstPair(hand[2...])
    return if s? then firstPair.concat(hand[2 + s...2 + s + 2]) else null

  # Otherwise, the joker is not relevant
  f = findFirstPair(hand)
  return null if not f?
  s = findFirstPair(hand[f + 2...])
  return if s? then hand[f...f + 2].concat(hand[f + 2 + s...f + 2 + s + 2]) else null

# Finds the best set in a hand sorted by rank, and returns those cards or null if no set exists
# Assumes hand is sorted by descending rank
bestSet = (hand) ->
  return null if hand.length < 3 # At least three cards are necessary for a set
  # Hand is sorted by rank, so we can just check adjacent cards for a set of three
  # Joker can be an ace. If there is a joker (it must be the first card), then check if there are two aces (they must
  # be the next two cards)
  return hand[0...3] if hand[0] == rules.JOKER and rules.rank(hand[1]) == rules.ACE and rules.rank(hand[2]) == rules.ACE

  # Otherwise, the joker is not relevant, check for a set of three
  for i in [0...hand.length - 2]
    r = rules.rank(hand[i])
    return hand[i...i + 3] if r == rules.rank(hand[i + 1]) and r == rules.rank(hand[i + 2])
  
  # If no set is found, return null
  return null

# Finds the best straight in a hand sorted by rank, and returns those cards or null if no straight exists
# Assumes hand is sorted by descending rank
# The return cards are sorted by descending rank except for the special cases of a low-ace straight with the order
# 5, 4, 3, 2, A and/or the presence of a joker filling in the straight.
bestStraight = (hand) ->
  # We don't care about suits so duplicated ranks are removed to make it easier to find a straight
  deduped = removeDuplicatedRanks hand
#  console.log "Deduped hand: #{deduped.map(rules.cardSymbol).join(' ')}"
  # If the deduped hand is less than 5 cards, then it can't be a straight
  return null if deduped.length < 5
  
  # If there is a joker, then it gets very complicated. The joker can be used to fill in any missing rank in a straight.
  if deduped[0] == rules.JOKER
    # Remove the joker
    deduped.shift()
    # The joker can be used to fill in any missing rank in a straight, so we need to check for each rank from ace down
    # to 2 (or low ace) that is missing in the hand.
    # Note that the hand is sorted by descending rank, so the first straight found is the highest.
    for r in [rules.ACE..2] by -1
      # If this rank is not already in the hand
      unless deduped.some((card) -> rules.rank(card) == r or (r == rules.LOW_ACE and rules.rank(card) == rules.ACE))
        # Create a candidate hand with the missing rank inserted. Note the suit is irrelevant.
        handWithJoker = deduped.concat([ rules.index(r, rules.HEARTS) ])
        sortByRank handWithJoker
        # Try to find a normal straight in this hand
        start = findFirst5ConsecutiveCards handWithJoker
        if start?
          # Replace the stand-in card with the joker
          straight = handWithJoker[start...start + 5].map((card) ->
            if rules.rank(card) == r then rules.JOKER else card
          )
          return straight

        # If no normal straight is found, then check for a low-ace straight
        lowAceStraight = findLowAceStraight handWithJoker
        if lowAceStraight?
          # If a low-ace straight is found, replace the stand-in card with the joker
          straight = lowAceStraight.map((card) ->
            if rules.rank(card) == r then rules.JOKER else card
          )
          return straight

    # If no straight is found with the joker, return null
    return null

  else
    start = findFirst5ConsecutiveCards deduped
    return deduped[start...start + 5] if start?
    
    # If no normal straight has been found, check for a low-ace straight (5, 4, 3, 2, A)
    lowAceStraight = findLowAceStraight deduped
    return lowAceStraight if lowAceStraight?
  
    # If no straight is found, return null
    return null

# Finds the best flush in a hand, and returns those cards or null if no flush exists
# Assumes hand is sorted by descending rank and contains at most 9 cards
bestFlush = (hand) ->
  return null if hand.length < 5 # At least five cards are necessary for a flush

  throw new Error("Hand is too large for flush check") if hand.length > 9

  # if the hand has a joker, remove it and then add it to all suits
  if hand[0] == rules.JOKER
    removed = hand[1...]
    suits = collateBySuit removed
    s.unshift(rules.JOKER) for s in suits # Add the joker to each suit
  else
    suits = collateBySuit hand

  # There is a flush if any suit has 5 or more cards
  for s in suits
    return s[0...5] if s.length >= 5
  
  # If no flush is found, return null
  return null

# Finds the best full house in a hand sorted by rank, and returns those cards or null if no full house exists
# Assumes hand is sorted by descending rank
bestFullHouse = (hand) ->
  return null if hand.length < 5 # At least five cards are necessary for a full house

  set = bestSet hand
  return null if not set? # Return null if no set is found

  remainingCards = hand.filter((card) -> not set.includes(card))
  pair = bestPair(remainingCards)
  return set.concat(pair) if pair?
  
  # If no full house is found, return null
  return null

# Finds the best quads in a hand sorted by rank, and returns those cards or null if no quads exist
# Assumes hand is sorted by descending rank
bestQuads = (hand) ->
  return null if hand.length < 4 # At least five cards are necessary for quads

  # Hand is sorted by rank, so we can just check adjacent cards for a set of four
  # Joker can be an ace. If there is a joker (it must be the first card), then check if there are three aces (they must
  # be the next three cards)
  return hand[0...4] if (
    hand[0] == rules.JOKER and
    rules.rank(hand[1]) == rules.ACE and
    rules.rank(hand[2]) == rules.ACE and
    rules.rank(hand[3]) == rules.ACE
  )

  # Otherwise, the joker is not relevant, check for a set of four
  for i in [0...hand.length - 3]
    r = rules.rank hand[i]
    return hand[i...i + 4] if (
      r == rules.rank(hand[i + 1]) and
      r == rules.rank(hand[i + 2]) and
      r == rules.rank(hand[i + 3])
    )

  # If no quads are found, return null
  return null

# Finds the best straight flush in a hand sorted by rank, and returns those cards or null if no straight flush exists
# Assumes hand is sorted by descending rank and contains at most 9 cards
bestStraightFlush = (hand) ->
  return null if hand.length < 5 # At least five cards are necessary for a straight flush
  throw new Error("Hand is too large for straight flush check") if hand.length > 9

  if hand[0] == rules.JOKER
    removed = hand[1...]
    suits = collateBySuit removed
    s.unshift(rules.JOKER) for s in suits # Add the joker to each suit
  else
    suits = collateBySuit hand

  for s in suits
    straight = bestStraight s
    return straight if straight?

  # If no straight flush is found, return null
  return null

# Sorts the hand by descending rank then by ascending suit
sortByRankThenSuit = (hand) ->
  hand.sort((a, b) ->
    rankA = rules.rank a
    rankB = rules.rank b
    if rankA == rankB
      return rules.suit(a) - rules.suit(b)
    else
      return rankB - rankA
  )
  return

# Sorts the hand by ascending suit then by descending rank
sortBySuitThenRank = (hand) ->
  hand.sort((a, b) ->
    suitA = rules.suit a
    suitB = rules.suit b
    if suitA == suitB
      return rules.rank(b) - rules.rank(a)
    else
      return suitA - suitB
  )
  return

# Sorts the hand by descending rank only
sortByRank = (hand) ->
  hand.sort((a, b) -> rules.rank(b) - rules.rank(a))
  return

# Removes cards with duplicate ranks from a hand
# Assumes hand is sorted by descending rank
removeDuplicatedRanks = (hand) ->
  deduped = []
  lastRank = null

  for card in hand
    rank = rules.rank(card)
    if rank != lastRank # Only add the card if its rank is different from the last added card
      deduped.push card
      lastRank = rank

  return deduped

# Returns the index of the first of 5 consecutive cards by rank (a straight), or null if none is found.
# Assumes hand is deduplicated and sorted by descending rank
findFirst5ConsecutiveCards = (hand) ->
#  console.log "findFirst5ConsecutiveCards: #{hand}"
  for i in [0...hand.length - 4]
#    console.log "Checking cards #{i} (#{rules.cardSymbol hand[i]}) and #{i + 4} (#{rules.cardSymbol hand[i + 4]})"
    if rules.rank(hand[i + 4]) == rules.rank(hand[i]) - 4 # Clever
      return i
  return null

# Returns the first pair found or null if no pair exists
findFirstPair = (hand) ->
  # The hand is sorted by rank, so we can just check adjacent cards for a pair
  for i in [0...hand.length - 1]
    return i if rules.rank(hand[i]) == rules.rank(hand[i + 1])
  return null

# Returns the cards in a low-ace straight, (5, 4, 3, 2, A), or null if the straight does not exist.
findLowAceStraight = (hand) ->
  return null if rules.rank(hand[0]) != rules.ACE
  lastFour = hand[-4...]
  lastFourRanks = lastFour.map(rules.rank)
  return lastFour.concat([hand[0]]) if arraysEqual(lastFourRanks, [5, 4, 3, 2])

  # If no low-ace straight is found, return null
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