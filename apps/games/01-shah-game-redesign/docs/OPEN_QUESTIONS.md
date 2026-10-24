# Open rule questions

Places where GAME_RULES.md is silent or ambiguous. Each has a current engine decision so the
game is playable; change the decision, then update the matching test.

| # | Question | Current decision | Where |
|---|----------|------------------|-------|
| 1 | Can 2s be led onto an empty pile? | **Decided by Waqas (2026-10-22): a 2 is always a reset and never stays on the table.** On an empty table (new round, or straight after another reset) any set of 2s is a reset: the same player keeps going, and if it was their last card they are out and the next player leads anything. Against a pile the table in 12.1 applies. | `PlayRules`, `test_scenario_one...`, `test_scenario_two...` |
| 2 | Does a 2 ever beat a pile by rank (e.g. double 2 on double A)? | **No.** Only the reset table (12.1) applies. | `test_a_two_never_beats_by_rank` |
| 3 | Rule 12.2/12.3: after a reset, must the player play again, or may they pass? | **Must lead.** Passing on an empty table is not allowed at all. | `Game.pass_turn`, `test_after_a_reset_the_player_must_lead_not_pass` |
| 4 | A reset empties the player's hand: do they finish, and who leads? | They finish; the **next active player in the direction of play** leads. | `test_reset_that_empties_the_hand...` |
| 5 | A round's winner has already gone out (emptied hand) before everyone passes. Who leads the next round? | The **next active player after them** in the direction of play. Note rules 15.2 ("passes == active players - 1") would be wrong here, so the engine instead ends a round when every active player except the pile owner has passed or been skipped. | `test_round_winner_who_finished...` |
| 6 | What happens to a skipped player when the round is about to end? | **Decided by Waqas (2026-10-22):** a skipped player who has not had a turn since is **offered a turn** before the round can be won (they may play something that beats the pile, or pass). **Only one player is marked skipped at a time:** a new skip replaces the old mark, so only the most recently skipped player gets the last chance. | `test_example_one...`, `test_example_two...` |
| 11 | A 2 played right after a reset. | Same rule as #1: it is another reset. You can chain 2s, then play anything, or reset again first. | `test_scenario_one...` |
| 12 | Time limit per turn. | Normal 20s, Fast 10s, Slow 60s. On timeout you pass, or if you must lead your lowest set is played. | `TableController`, `SessionConfig` |
| 7 | "2nd place on the winner's right / left" (6.3): which side is "right" when looking at the table, and what about a seat directly opposite? | "Right" = the **clockwise half** of the table as seen from above, so 2nd place there -> clockwise. Directly opposite (even player counts) -> clockwise. **Please confirm the side**; it may be the opposite of what you play at a real table. | `Direction`, `dealer_test.gd` |
| 8 | First game direction (no previous 2nd place). | Clockwise. | `ShahMatch` |
| 9 | Exchange ties: which of two equal-rank cards is "worst/best"? | Lower suit order first: clubs, diamonds, hearts, spades. Rarely matters. | `Exchange` |
| 13 | How is a match won, and how many games does it have? | **Decided by Waqas (2026-10-24): a match is 10 or 20 games** (default 10). The scoring itself was **my proposal, please confirm**: each game gives place points (1st = players-1, last = 0); most points after the last game wins, ties broken by most game wins, then seat number. | `ShahMatch`, `match_test.gd` |
| 14 | Can a 2 be exchanged? | **No (Waqas, 2026-10-24).** The 2 is the losers' only way back, so exchanges only move 3..A cards: the best card anyone gives is an Ace. Replaces the earlier "2 is the best exchange card". | `Exchange`, `exchange_test.gd` |
| 10 | Exchange with 3 players: is the 2nd-place swap skipped? | **Yes**, only 1st and last swap (second-last would be 2nd place themselves). | `test_three_players_only_swap...` |
