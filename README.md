# 🟩 VIM‑STYLE MAC NAVIGATION SYSTEM  
### Powered by Hammerspoon  
#### Designed by **Artur Grochau** [](https://github.com/arturpedrotti)

[![Download](https://img.shields.io/badge/⬇️%20Download-v1.2.0-green?style=for-the-badge)](https://github.com/arturpedrotti/macos-vim-navigation/releases/latest/download/macos-vim-navigation.zip)

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

**Tip:** `⌥` and `⌃` actions are triggered on **key release**, so they don’t interfere with regular macOS shortcuts.

---

## 🧠 Commands Summary

### 📦 Global (Works Anytime)

| Key     | Action                                            |
| ------- | ------------------------------------------------- |
| `⌥ tap` | Move mouse to center of next connected screen     |
| `⌃ tap` | Click near bottom‑middle of current screen        |
| `⌥ + r` | Reload Hammerspoon config                         |

### 🚀 Entering and Exiting NAV MODE

| Key Combo                     | Action                                        |
| ----------------------------- | --------------------------------------------- |
| `⌃⌥⌘ + space` / `F12` / `⌃ =` | Enter NAV MODE (overlay shows `-- NORMAL --`) |
| `⎋` or `⌃ + c`                | Exit NAV MODE                                 |

### 🧭 NAV MODE (Modal Vim‑style Movement & Controls)

| Key & combo       | Action                                                                              |
| ----------------- | ----------------------------------------------------------------------------------- |
| `h / j / k / l`   | Move mouse (← ↓ ↑ →) in small steps (1/8th of the screen)                           |
| `H / J / K / L`   | Move mouse in large steps (1/2 of the screen)                                       |
| `d`               | Scroll down; hold to scroll smoothly                                                |
| `u`               | Scroll up; hold to scroll smoothly                                                  |
| `w`               | Scroll left; hold to scroll smoothly                                                |
| `b`               | Scroll right; hold to scroll smoothly                                               |
| `i`               | Double left click (e.g., to highlight words)                                        |
| `a`               | Right click                                                                         |
| `c`               | Open or focus the ChatGPT app and click the input box                               |
| `g` then `g` (gg) | Scroll to the very top of the current scrollable content (double‑press `g` quickly) |
| `Shift + g` (`G`) | Scroll to the very bottom of the current scrollable content                         |
| `o`               | Open the first available browser (Arc, Chrome, Firefox, Safari, etc.)               |
| `Shift + A`       | Focus the next visible window (cycle forward)                                       |
| `Shift + I`       | Focus the previous visible window (cycle backward)                                  |
| `Shift + M`       | Move mouse to the center of the screen                                              |
| `Shift + W`       | Jump mouse to the right edge of the screen                                          |
| `Shift + B`       | Jump mouse to the left edge of the screen                                           |
| `Shift + U`       | Jump mouse to the top edge of the screen                                            |
| `Shift + D`       | Jump mouse to the bottom edge of the screen                                         |

---

## 🛠 Setup Instructions

### 1. 📦 Download the latest version

[**Download here**](https://github.com/arturpedrotti/macos-vim-navigation/releases/latest/download/macos-vim-navigation.zip)

Unzip it and move into the directory:

```bash
unzip macos-vim-navigation.zip
cd macos-vim-navigation
