# KidReader

Образовательная игра для детей: собирай буквы и слоги, растапливай лёд и спасай зверей.

Клон механик «Учимся Читать, Спасаем Зверей» (Cleverbit). Архитектура и Cursor-правила — по образцу проекта Quizmatik (HFSM, feature isolation, scene isolation, RootEvents).

## Запуск

1. Открой папку в **Godot 4.7+**
2. Запусти `main.tscn` (F5)

## Управление

- Мышь или касание: перетащи карточку буквы/слога в слот
- 🏠 — в меню
- 🎵 — музыка
- ⚙️ — настройки (parental gate: удержать 3 сек или решить пример)

## Структура

| Путь | Назначение |
|------|------------|
| `core/` | HFSM, FSM, EventListener, ResourceUtils |
| `src/features/` | letter_tile, word_slot, animal, ice, celebration, sfx, music |
| `src/game/scenes/` | app_root, menu, game |
| `src/levels/` | 12 уровней |
| `.cursor/rules/` | правила для Cursor |
| `concepts/` | только AI-референс стиля |

## Сохранение

Прогресс: `user://save/progress.json` (звёзды, разблокировка уровней).
