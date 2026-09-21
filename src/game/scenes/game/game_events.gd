class_name GameEvents
extends Resource

@warning_ignore("unused_signal") signal ev_tile_picked(part: String)
@warning_ignore("unused_signal") signal ev_tile_correct(part: String, slot_index: int)
@warning_ignore("unused_signal") signal ev_tile_wrong(part: String)
@warning_ignore("unused_signal") signal ev_word_complete(word: String)
@warning_ignore("unused_signal") signal ev_ice_cracked(progress: float)
@warning_ignore("unused_signal") signal ev_animal_freed
@warning_ignore("unused_signal") signal ev_victory(stars: int)
@warning_ignore("unused_signal") signal ev_hint_needed
@warning_ignore("unused_signal") signal ev_play_phoneme(part: String)
@warning_ignore("unused_signal") signal ev_play_word(word: String)
