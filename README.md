# 🟩 VIM‑STYLE MAC NAVIGATION SYSTEM  
### Powered by Hammerspoon  
#### Designed by **Artur Grochau** [](https://github.com/arturpedrotti)

[![Download](https://img.shields.io/badge/⬇️%20Download-v1.3.1-green?style=for-the-badge)](https://github.com/arturpedrotti/macos-vim-navigation/releases/latest/download/macos-vim-navigation.zip)

A minimal, responsive, and Vim‑inspired mouse/navigation controller for macOS.

---

## ✨ What is this?

This is a **Vim‑style keyboard navigation system for macOS**, powered by [Hammerspoon](https://www.hammerspoon.org).  
It lets you **control your mouse, inputs, screens, and window focus** without ever reaching for your trackpad or mouse.

This config includes:

- 🖱️ One‑tap screen switching with `⌥` (Option) or `⌃` (Control) – **outside nav mode**
- 🧭 A full **NAV MODE** for mouse movement, input clicking, scrolling, screen‑edge jumping, and app textbox navigation
- 🖥️ Support for multi‑monitor setups
- ⚡ Lightweight, pragmatic, and easy to edit
- 🧠 Inspired by Vim and modal editors

**Tip:** `⌥` and `⌃` actions are triggered on **key release**, so they don't interfere with regular macOS shortcuts.

---

## ⚙️ Configurable Engine (new)

This config is refactored into a **config-driven engine** plus a minimal **SwiftUI preset editor**,
so features can be toggled and keys rebound from a GUI instead of hand-editing Lua. With no config
file present it behaves exactly like this README describes; drop in a JSON preset to change it.

- Engine + install + config docs: [`engine/README.md`](engine/README.md)
- SwiftUI preset editor (KeyDeck): [`app/README.md`](app/README.md)
- Ready-made presets (`default` / `developer` / `minimal`): [`config/presets/`](config/presets)
- Full config contract: [`config/config.schema.json`](config/config.schema.json)

---

## 📺 Visual Mode Indicators 

When navigation mode is active, you'll see helpful overlays in the bottom-right corner of your screen:

![Mode Indicators](indicators.png)

The overlays provide instant feedback about your current navigation state:
- **-- NORMAL --** appears when you enter navigation mode
- **-- VISUAL MODE --** appears below when you activate visual selection mode
- Both overlays automatically disappear when you exit navigation mode

---

This config includes:

- 🖱️ One‑tap screen switching with `⌥` (Option) or `⌃` (Control) – **outside nav mode**
- 🧭 A full **NAV MODE** for mouse movement, input clicking, scrolling, screen‑edge jumping, and app textbox navigation
- 🖥️ Support for multi‑monitor setups
- ⚡ Lightweight, pragmatic, and easy to edit
- 🧠 Inspired by Vim and modal editors

**Tip:** `⌥` and `⌃` actions are triggered on **key release**, so they don’t interfere with regular macOS shortcuts.

---

## 🧠 Commands Summary

### 📦 Global (Works Anytime)

| Key     | Action                                                                   |
| ------- | ------------------------------------------------------------------------ |
| `⌥ tap` | Move mouse to center of next connected screen                            |
| `⌃ tap` | Smart click: VSCode Copilot chat area if VSCode open, else bottom-middle |
| `⌥ + r` | Reload Hammerspoon config                                                |

### 🚀 Entering and Exiting NAV MODE

| Key Combo                     | Action                                        |
| ----------------------------- | --------------------------------------------- |
| `⌃⌥⌘ + space` / `F12` / `⌃ =` | Enter NAV MODE (overlay shows `-- NORMAL --`) |
| `⎋` or `⌃ + c`                | Exit NAV MODE                                 |

### 🧭 NAV MODE (Modal Vim‑style Movement & Controls)

| Key & combo           | Action                                                                              |
| --------------------- | ----------------------------------------------------------------------------------- |
| `h / j / k / l`       | Move mouse (← ↓ ↑ →) in small steps (1/8th of the screen)                           |
| `H / J / K / L`       | Move mouse in large steps (1/2 of the screen)                                       |
| `↑` / `↓`             | Arrow keys: scroll up/down (same as `u / d`)                                        |
| `↑ ↑` / `↓ ↓`         | Double-tap arrows: medium scroll (same as `Ctrl+U / Ctrl+D`)                        |
| `↑ ↑ ↑` / `↓ ↓ ↓`     | Triple-tap arrows: large scroll (same as `Shift+U / Shift+D`)                       |
| `↑ ↑ ↑ ↑` / `↓ ↓ ↓ ↓` | Quad-tap arrows: scroll to top/bottom (same as `gg / G`)                            |
| `← / →`               | Arrow keys: move cursor left/right (same as `h / l`)                                |
| `d`                   | Scroll down; hold to scroll smoothly                                                |
| `u`                   | Scroll up; hold to scroll smoothly                                                  |
| `⌃ + d`               | Scroll down medium amount (3× normal), repeatable while held                        |
| `⌃ + u`               | Scroll up medium amount (3× normal), repeatable while held                          |
| `w`                   | Scroll left; hold to scroll smoothly                                                |
| `b`                   | Scroll right; hold to scroll smoothly                                               |
| `i`                   | Triple left click (e.g., to highlight the entire line)                              |
| `a`                   | Right click                                                                         |
| `c`                   | Open or focus the ChatGPT app and click the input box                               |
| `C` (Shift + c)       | Open or focus VSCode/your IDE (customizable in config)                              |
| `g` then `g` (gg)     | Scroll to the very top of the current scrollable content (double‑press `g` quickly) |
| `Shift + g` (`G`)     | Scroll to the very bottom of the current scrollable content                         |
| `o`                   | Open the first available browser (Arc, Chrome, Firefox, Safari, etc.)               |
| `Shift + A`           | Focus the next visible window (cycle forward)                                       |
| `Shift + I`           | Focus the previous visible window (cycle backward)                                  |
| `Shift + M`           | Move mouse to the center of the screen                                              |
| `Shift + U`           | Scroll up significantly (8× scrollStep), repeatable while held                      |
| `Shift + D`           | Scroll down significantly (8× scrollStep), repeatable while held                    |
| `Shift + W`           | Scroll left significantly (8× scrollStep), repeatable while held                    |
| `Shift + B`           | Scroll right significantly (8× scrollStep), repeatable while held                   |
| `y`                   | Yank: copy selected text (Cmd+C) in any mode                                        |

---

## 🖍️ Visual Mode (Selection Mode)

| Key / Combo       | Action                                                          |
| ----------------- | --------------------------------------------------------------- |
| `v`               | Enter visual selection mode (shows `-- VISUAL MODE --` overlay) |
| `Shift + v`       | Enter visual mode with triple-click block selection             |
| `V` / `SHIFT + V` | EXIT VISUAL MODE (FINALIZES SELECTION WITH A CLICK)             |
| `y`               | Yank selected content (performs Cmd+C)                          |
| `p` / `Shift + p` | Paste over selection or paste at mouse (performs Cmd+V)         |

### 🔀 Moving and Selecting (while in Visual Mode)

In visual mode, selection is extended as the mouse moves or scrolls. Keys behave with different granularities:

| Key / Combo       | Action                                                                 |
| ----------------- | ---------------------------------------------------------------------- |
| `h / j / k / l`   | Move mouse in small steps (1/8th of screen width/height)               |
| `H / J / K / L`   | Move mouse in large steps (1/2 of screen width/height)                 |
| `↑ / ↓`           | Arrow keys: scroll up/down (extend selection while scrolling)          |
| `← / →`           | Arrow keys: move cursor left/right (extend selection while moving)     |
| `u / d`           | Move cursor vertically in moderate steps (while extending selection)   |
| `w / b`           | Move cursor horizontally in moderate steps (while extending selection) |
| `Shift + U/D/W/B` | Scroll significantly (8× step) in the corresponding direction          |

### 📌 Notes

- `-- VISUAL MODE --` overlay appears when active
- Triple-click block selection starts with `Shift + v`
- Exiting visual mode clicks to finalize the selection
- Visual mode auto-exits when leaving nav mode
- Works seamlessly with copy (`y`) and paste (`p`) operations
- `Shift + U/D/W/B` extend selection while scrolling, but may not activate until the cursor has moved—use `h/j/k/l` once first to ensure highlighting starts

## 🛠 Setup Instructions

### 1. 📦 Download the latest version

[**Download here**](https://github.com/arturpedrotti/macos-vim-navigation/releases/latest/download/macos-vim-navigation.zip)

Unzip it and move into the directory:

```bash
unzip macos-vim-navigation.zip
cd macos-vim-navigation</file>
