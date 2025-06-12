# common.coffee
#
# Common functions for the project

rules = require './rules'

# Returns true if the hand is sorted by descending rank
isSortedByRank = (hand) -> hand.every((c, i) -> i == 0 or rules.rank(c) <= rules.rank(hand[i - 1]))

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

# Returns true if two arrays are equal
arraysEqual = (a, b) ->
  return false if a.length != b.length
  for i in [0...a.length]
    return false if a[i] != b[i]
  return true

# Exports
module.exports = {
  isSortedByRank
  sortByRankThenSuit
  sortBySuitThenRank
  sortByRank
  removeDuplicatedRanks
  arraysEqual
  }