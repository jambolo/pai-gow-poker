class Deck
  constructor: ->
    @cards = [0...JOKER]
    @index = 0
    @shuffle()

  # Shuffles the deck using the Fisher-Yates algorithm
  shuffle: ->
    for i in [@cards.length - 1..0]
      j = Math.floor Math.random() * (i + 1)
      [@cards[i], @cards[j]] = [@cards[j], @cards[i]]

  # Returns the number of cards left in the deck
  remaining: ->
    @cards.length - @index

  # Returns n cards from the deck. If n is not provided, one card is returned. The cards are removed from the deck.
  draw: (n = 1) ->
    if @index + n > @cards.length
      throw new Error "Not enough cards left in the deck"
    drawn = @cards[@index...@index + n]
    @index += n
    return drawn

module.exports = Deck