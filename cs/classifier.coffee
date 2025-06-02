rules = require './rules'

# Returns the best hand from a given set of cards along with its rank
bestHand = (hand) ->
  tests = [
    { detector: bestFiveOfAKind,   rank: rules.FIVE_OF_A_KIND }
    { detector: bestStraightFlush, rank: rules.STRAIGHT_FLUSH }
    { detector: bestQuads,         rank: rules.QUADS }
    { detector: bestFullHouse,     rank: rules.FULL_HOUSE }
    { detector: bestFlush,         rank: rules.FLUSH }
    { detector: bestStraight,      rank: rules.STRAIGHT }
    { detector: bestSet,           rank: rules.SET }
    { detector: bestTwoPair,       rank: rules.TWO_PAIR }
    { detector: bestPair,          rank: rules.PAIR }
    { detector: bestHighCard,      rank: rules.HIGH_CARD }
  ]

  for { detector, rank } in tests
    cards = detector hand
    if cards?
      return { rank, cards }

  throw new Error "No ranking found"

# Returns the best high card (as an array) or null if no high card exists
# Assumes hand is sorted by descending rank
bestHighCard = (hand) ->
  return null if hand.length < 1
  # Return the first card, which is the highest card.
  [hand[0]]

# Finds the best pair, and returns those cards or null if no pair exists
# Assumes hand is sorted by descending rank
bestPair = (hand) ->
  return null if hand.length < 2

  # Hand is sorted by rank, so we can just check adjacent cards for a pair
  # Joker can be an ace. If there is a joker (it must be the first card), then check if there is an ace (it must be
  # the next card)
  return hand[0...2] if hand[0] == rules.JOKER and rules.rank(hand[1]) == rules.ACE

  # Otherwise, the joker is not relevant
  i = findNOfAKind hand, 2
  return hand[i...i + 2] if i >= 0

  return null

# Finds the best two pair and returns those cards or null if no two pair exists
# Assumes hand is sorted by descending rank
# The return cards are sorted by descending rank
bestTwoPair = (hand) ->
  return null if hand.length < 4 # At least four cards are necessary for a two-pair

  # Hand is sorted by rank, so we can just check adjacent cards for a pair twice
  # Joker can be an ace. If there is a joker (it must be the first card), then check if there is an ace (it must be
  # the next card). If so, then check the rest of the hand for another pair.
  if hand[0] == rules.JOKER and rules.rank(hand[1]) == rules.ACE
    i = findNOfAKind hand[2...], 2
    return if i >= 0 then hand[0...2].concat(hand[2 + i...2 + i + 2]) else null

  # Otherwise, the joker is not relevant
  i = findNOfAKind hand, 2
  if i >= 0
    j = findNOfAKind hand[i + 2...], 2
    if j >= 0
      return hand[i...i + 2].concat hand[i + 2 + j...i + 2 + j + 2]

  return null

# Finds the best set and returns those cards or null if no set exists
# Assumes hand is sorted by descending rank
bestSet = (hand) ->
  return null if hand.length < 3

  # Hand is sorted by rank, so we can just check adjacent cards for a set of three
  # Joker can be an ace. If there is a joker (it must be the first card), then check if there are two aces (they must
  # be the next two cards)
  return hand[0...3] if hand[0] == rules.JOKER and rules.rank(hand[2]) == rules.ACE

  # Otherwise, the joker is not relevant
  i = findNOfAKind hand, 3
  return hand[i...i + 3] if i >= 0

  return null

# Finds the best straight and returns those cards or null if no straight exists
# Assumes hand is sorted by descending rank
# The returned cards are sorted by descending rank except for the special cases of a low-ace straight with the order
# 5, 4, 3, 2, A and/or the presence of a joker completing in the straight.
bestStraight = (hand) ->
  # We don't care about suits so duplicated ranks are removed to make it easier to find a straight
  deduped = removeDuplicatedRanks hand
  return null if deduped.length < 5

  # The joker can be used to fill in any missing rank in a straight.
  if deduped[0] == rules.JOKER
    # Remove the joker
    deduped.shift()
    for r in [rules.ACE..2] by -1
      # If this rank is not already in the hand
      unless deduped.some((card) -> rules.rank(card) == r or (r == rules.LOW_ACE and rules.rank(card) == rules.ACE))
        # Create a candidate hand with the stand-in inserted. Note the suit is irrelevant.
        replaced = deduped.concat [rules.index(r, 0)]
        sortByRank replaced
        # If the hand contains a straight then replace the stand-in card with the joker and return it
        i = findStraight replaced
        return replaceRankWithJoker replaced[i...i + 5], r if i >= 0
        lowAceStraight = extractLowAceStraight replaced
        return replaceRankWithJoker lowAceStraight, r if lowAceStraight?

    # If no straight is found with the joker, return null
    return null

  # Otherwise, the joker is not relevant
  i = findStraight deduped
  return deduped[start...start + 5] if i >= 0

  # If no normal straight has been found, check for a low-ace straight (5, 4, 3, 2, A)
  start = extractLowAceStraight deduped
  return deduped[start...start + 5] if start?

  return null

# Finds the best flush in a hand, and returns those cards or null if no flush exists
# Assumes hand is sorted by descending rank and contains at most 9 cards
bestFlush = (hand) ->
  throw new Error("Hand is too large for flush check") if hand.length > 9
  return null if hand.length < 5

  # if the hand has a joker, remove it and then add it to all suits
  if hand[0] == rules.JOKER
    suited = collateBySuit hand[1...]
    # Add the joker to each suit in the highest possible position
    for s in suited
      i = findMissingRank s
      if i < s.length
        s.splice i, 0, rules.JOKER # Insert the joker at the first missing rank position
      else
        s.push rules.JOKER # If no missing rank, add the joker to the end of the suited cards
  else
    suited = collateBySuit hand

  # There is a flush if any suit has 5 or more cards
  for s in suited
    return s[0...5] if s.length >= 5

  return null

# Finds the best full house and returns those cards or null if no full house exists
# Assumes hand is sorted by descending rank
bestFullHouse = (hand) ->
  return null if hand.length < 5 # At least five cards are necessary for a full house

  set = bestSet hand
  return null unless set?

  remainingCards = hand.filter (card) -> not set.includes card
  pair = bestPair remainingCards
  return set.concat(pair) if pair?

  return null

# Finds the best quads in a hand sorted by rank, and returns those cards or null if no quads exist
# Assumes hand is sorted by descending rank
bestQuads = (hand) ->
  return null if hand.length < 4 # At least five cards are necessary for quads

  # Hand is sorted by rank, so we can just check adjacent cards for a set of four
  # Joker can be an ace. If there is a joker (it must be the first card), then check if there are three aces (they must
  # be the next three cards)
  return hand[0...4] if hand[0] == rules.JOKER and rules.rank(hand[3]) == rules.ACE

  # Otherwise, the joker is not relevant
  i = findNOfAKind hand, 4
  return hand[i...i + 4] if i >= 0

  return null

# Finds the best straight flush and returns those cards or null if no straight flush exists
# Assumes hand is sorted by descending rank and contains at most 9 cards
bestStraightFlush = (hand) ->
  throw new Error("Hand is too large for straight flush check") if hand.length > 9
  return null if hand.length < 5 # At least five cards are necessary for a straight flush

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

# Finds the best five of a kind and returns those cards or null if no five of a kind exists
# Assumes hand is sorted by descending rank
bestFiveOfAKind = (hand) ->
  return null if hand.length < 5 # At least five cards are necessary for five of a kind

  # This hand is only possible if there is a joker and the hand contains 5 aces.
  return hand[0...5] if hand[0] == rules.JOKER and rules.rank(hand[4]) == rules.ACE

  return null

# Sorts the hand by descending rank then by ascending suit
sortByRankThenSuit = (hand) ->
  hand.sort (a, b) ->
    rankA = rules.rank a
    rankB = rules.rank b
    return if rankA == rankB then rules.suit(a) - rules.suit(b) else rankB - rankA
  return

# Sorts the hand by ascending suit then by descending rank
sortBySuitThenRank = (hand) ->
  hand.sort (a, b) ->
    suitA = rules.suit a
    suitB = rules.suit b
    return if suitA == suitB then rules.rank(b) - rules.rank(a) else suitA - suitB
  return

# Sorts the hand by descending rank only
sortByRank = (hand) ->
  hand.sort (a, b) -> rules.rank(b) - rules.rank(a)
  return

# Removes cards with duplicate ranks from a hand
# Assumes hand is sorted by descending rank
removeDuplicatedRanks = (hand) ->
  deduped = []
  lastRank = null
  for card in hand
    rank = rules.rank card
    if rank != lastRank # Only add the card if its rank is different from the last added card
      deduped.push card
      lastRank = rank

  return deduped

# Returns the index of the first of n cards of the same rank (i.e. pair, set, quads, etc.), or -1 if not found.
# Assumes hand is sorted by descending rank
findNOfAKind = (hand, n) ->
  return -1 if hand.length < n
  for i in [0...hand.length - n + 1]
    return i if rules.rank(hand[i]) == rules.rank(hand[i + n - 1]) # Clever

  return -1

# Returns the index of the first 5 consecutive cards by rank, or -1 if none is found.
# Assumes hand is deduplicated and sorted by descending rank
findStraight = (hand) ->
  return -1 if hand.length < 5
  for i in [0...hand.length - 4]
    if rules.rank(hand[i + 4]) == rules.rank(hand[i]) - 4 # Clever
      return i
  return -1

# Finds the highest rank not in the hand and returns the index where that rank would be inserted.
# Assumes the hand is deduplicated and sorted by descending rank.
findMissingRank = (hand) ->
  missing = rules.ACE
  for i in [0...hand.length]
    return i if rules.rank(hand[i]) < missing
    missing -= 1
  return hand.length

# Returns the cards in a low-ace straight, (5, 4, 3, 2, A), or null if the straight does not exist.
extractLowAceStraight = (hand) ->
  return null if hand.length < 5
  return null if rules.rank(hand[0]) != rules.ACE
  lastFour = hand[-4...]
  lastFourRanks = lastFour.map rules.rank
  return lastFour.concat([hand[0]]) if arraysEqual(lastFourRanks, [5, 4, 3, 2])

  return null

# Collates a hand into an array of hands, one for suit sorted by descending rank and returns the result
# Assumes hand is sorted by descending rank
collateBySuit = (hand) ->
  collated = [[], [], [], []]
  for card in hand
    suit = rules.suit card
    collated[suit].push card
  return collated

# Returns true if two arrays are equal
arraysEqual = (a, b) ->
  return false if a.length != b.length
  for i in [0...a.length]
    return false if a[i] != b[i]
  return true

# Returns a hand with the card of a given rank replaced with a joker
replaceRankWithJoker = (hand, r) -> hand.slice().map (card) -> if rules.rank(card) == r then rules.JOKER else card

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