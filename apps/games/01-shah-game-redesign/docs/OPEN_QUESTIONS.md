# Open rule questions

Places where GAME_RULES.md is silent or ambiguous. Each has a current engine decision so the
game is playable; change the decision, then update the matching test.

| # | Question | Current decision | Where |
|---|----------|------------------|-------|
| 1 | Can 2s be led onto an empty pile? Rules 8 says "any valid play" but section 3.2 says 2 is "used only for reset". | **Yes (confirmed by Waqas, 2026-10-19).** Otherwise a player left holding only 2s could never go out. A led 2 outranks A, and ordinary cards cannot beat it. Against a pile, 2s only ever reset. | `PlayRules`, `test_twos_may_be_led...` |
| 2 | Does a 2 ever beat a pile by rank (e.g. double 2 on double A)? | **No.** Only the reset table (12.1) applies. | `test_a_two_never_beats_by_rank` |
| 3 | Rule 12.2: does the player have to play again after a reset? | Not decided yet (game flow, next step). Turn is extended; passing is the open point. | - |
| 4 | Reset leaves the player with zero cards: do they finish, and who leads next? | Not decided yet (game flow). | - |
