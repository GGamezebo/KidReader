# Art Direction — KidReader

Kids reading game inspired by «Учимся Читать, Спасаем Зверей» / letter-scatter photo style.

## Level look (critical)

- **Animal** = realistic photo, full-bleed background
- Photo starts **heavily blurred / frosted**; clears when the word is complete
- Ambient white sparkles over the photo
- **Letters only** (not syllables); only letters of the target word (no distractors)
- Letters scatter randomly with rotation + soft float
- Letter tiles: translucent blue glass, **bold red** glyph
- Slots at bottom: grey glass with ghost outlines; yellow glow when magnetizing
- Placed tiles turn green; next CTA is a round play button on the right

## Interaction

1. Grab → straighten vertical + phoneme
2. Near correct slot → highlight; release → snap + phoneme
3. Miss / too low → fly upward (repel)
4. Tap placed letter → phoneme again
5. All letters → speak full word → unblur photo

## Palette

| Token | Hex | Use |
|-------|-----|-----|
| glass | `#8CC7F2` @ 55% | Free letter tiles |
| leaf | `#73C76B` | Placed tiles |
| letter | `#E53935` | Glyph color |
| gold | `#FFC94A` | Magnet / stars |
| ink | `#3D2C29` | UI text |

## Typography

Nunito Bold, large (56–72 for letters).

## Never

- Syllable distractors on the playfield
- Cartoon emoji animals in the level scene (menu cards OK)
- Harsh fail SFX
