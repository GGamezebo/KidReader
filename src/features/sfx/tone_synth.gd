class_name ToneSynth
extends RefCounted

## Procedural soft tones for phonemes / UI (no external audio assets required).


static func make_tone(freq_hz: float, duration_sec: float = 0.18, volume: float = 0.35) -> AudioStreamWAV:
	var sample_rate := 22050
	var sample_count := int(sample_rate * duration_sec)
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	for i in sample_count:
		var t := float(i) / float(sample_rate)
		var env := 1.0
		var attack := 0.02
		var release := 0.06
		if t < attack:
			env = t / attack
		elif t > duration_sec - release:
			env = maxf(0.0, (duration_sec - t) / release)
		var sample := sin(TAU * freq_hz * t) * volume * env
		# Soft triangle blend for less harshness
		sample = sample * 0.7 + _tri(freq_hz, t) * 0.3 * volume * env
		var s16 := int(clampf(sample, -1.0, 1.0) * 32767.0)
		data[i * 2] = s16 & 0xFF
		data[i * 2 + 1] = (s16 >> 8) & 0xFF
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = data
	return stream


static func make_boing() -> AudioStreamWAV:
	## Soft falling "spring" — not a scary fail sound.
	var sample_rate := 22050
	var duration_sec := 0.22
	var sample_count := int(sample_rate * duration_sec)
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	for i in sample_count:
		var t := float(i) / float(sample_rate)
		var freq := lerpf(420.0, 180.0, t / duration_sec)
		var env := exp(-t * 8.0) * 0.28
		var sample := sin(TAU * freq * t) * env
		var s16 := int(clampf(sample, -1.0, 1.0) * 32767.0)
		data[i * 2] = s16 & 0xFF
		data[i * 2 + 1] = (s16 >> 8) & 0xFF
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = data
	return stream


static func make_sparkle() -> AudioStreamWAV:
	var sample_rate := 22050
	var duration_sec := 0.16
	var sample_count := int(sample_rate * duration_sec)
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	var freqs := [880.0, 1174.66, 1396.91]
	for i in sample_count:
		var t := float(i) / float(sample_rate)
		var env := exp(-t * 14.0) * 0.3
		var sample := 0.0
		for f in freqs:
			sample += sin(TAU * f * t) * env / float(freqs.size())
		var s16 := int(clampf(sample, -1.0, 1.0) * 32767.0)
		data[i * 2] = s16 & 0xFF
		data[i * 2 + 1] = (s16 >> 8) & 0xFF
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = data
	return stream


static func make_word_fanfare(word: String) -> AudioStreamWAV:
	## Short rising phrase keyed by word — stand-in for "КОРОВА!".
	var sample_rate := 22050
	var duration_sec := 0.55
	var sample_count := int(sample_rate * duration_sec)
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	var base := phoneme_freq(word)
	var notes := [base, base * 1.25, base * 1.5, base * 1.25]
	var note_len := duration_sec / float(notes.size())
	for i in sample_count:
		var t := float(i) / float(sample_rate)
		var note_i := mini(int(t / note_len), notes.size() - 1)
		var local_t := t - note_i * note_len
		var freq: float = notes[note_i]
		var env := sin(PI * clampf(local_t / note_len, 0.0, 1.0)) * 0.32
		var sample := sin(TAU * freq * t) * env
		var s16 := int(clampf(sample, -1.0, 1.0) * 32767.0)
		data[i * 2] = s16 & 0xFF
		data[i * 2 + 1] = (s16 >> 8) & 0xFF
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = data
	return stream


static func make_crack() -> AudioStreamWAV:
	var sample_rate := 22050
	var duration_sec := 0.28
	var sample_count := int(sample_rate * duration_sec)
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	for i in sample_count:
		var t := float(i) / float(sample_rate)
		var env := exp(-t * 12.0)
		var noise := rng.randf_range(-1.0, 1.0)
		var crack := sin(TAU * (400.0 + t * 900.0) * t) * 0.5
		var sample := (noise * 0.35 + crack) * env * 0.4
		var s16 := int(clampf(sample, -1.0, 1.0) * 32767.0)
		data[i * 2] = s16 & 0xFF
		data[i * 2 + 1] = (s16 >> 8) & 0xFF
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = data
	return stream


static func make_music_loop() -> AudioStreamWAV:
	## Soft looping pentatonic arpeggio for background.
	var sample_rate := 22050
	var duration_sec := 4.0
	var sample_count := int(sample_rate * duration_sec)
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	var notes := [261.63, 293.66, 329.63, 392.00, 440.00, 392.00, 329.63, 293.66]
	var note_len := duration_sec / float(notes.size())
	for i in sample_count:
		var t := float(i) / float(sample_rate)
		var note_i := mini(int(t / note_len), notes.size() - 1)
		var local_t := t - note_i * note_len
		var freq: float = notes[note_i]
		var env := sin(PI * clampf(local_t / note_len, 0.0, 1.0)) * 0.12
		var sample := (sin(TAU * freq * t) * 0.6 + sin(TAU * freq * 2.0 * t) * 0.2) * env
		var s16 := int(clampf(sample, -1.0, 1.0) * 32767.0)
		data[i * 2] = s16 & 0xFF
		data[i * 2 + 1] = (s16 >> 8) & 0xFF
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = sample_count
	stream.data = data
	return stream


static func phoneme_freq(part: String) -> float:
	## Map Cyrillic / Latin parts to distinct soft frequencies.
	var key := part.to_upper()
	var hash_v := 0
	for i in key.length():
		hash_v = (hash_v * 31 + key.unicode_at(i)) % 1000
	return 280.0 + float(hash_v % 420)


static func _tri(freq: float, t: float) -> float:
	var phase := fmod(freq * t, 1.0)
	return 2.0 * absf(2.0 * phase - 1.0) - 1.0
