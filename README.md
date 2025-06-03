# pai-gow-poker
Various tools to analyze the game of Pai Gow Poker

### list-two-card-hands.coffee
Generates and sorts all possible two-card hands (ignoring suit) in Pai Gow Poker by value

### generate-poker-hand-testing-with-joker.coffee
Generates testing data that includes a joker. The data is derived from `data/poker-hand-testing.csv` and is written to `data/poker-hand-testing-with-joker.csv`.

### list-all-settings.coffee
`list-all-settings.coffee` will list all possible settings from a given seven-card hand. All 21 different settings can be listed, but only the ones that are not strictly worse are listed by default.
