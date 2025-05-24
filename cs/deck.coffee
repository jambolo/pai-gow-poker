class Deck
  constructor: ->
    @cards = [0...JOKER]
    @shuffle()

  # Shuffles the deck using the Fisher-Yates algorithm
  shuffle: ->
    for i in [@cards.length - 1..0]
      j = Math.floor(Math.random() * (i + 1))
      [@cards[i], @cards[j]] = [@cards[j], @cards[i]]

  # Returns the number of cards left in the deck
  remaining: ->
    @cards.length

  # Returns n cards from the deck. If n is not provided, one card is returned. The cards are removed from the deck.
  draw: (n = 1) ->
    @cards.splice(-n, n)

module.exports = Deck