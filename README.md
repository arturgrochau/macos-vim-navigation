# 🟩 VIM-STYLE MAC NAVIGATION SYSTEM  
### Powered by Hammerspoon  
#### Designed by **Artur Grochau** ([@arturpedrotti](https://github.com/arturpedrotti))

[![Download](https://img.shields.io/badge/⬇️%20Download-v1.1.0-green?style=for-the-badge)](https://github.com/arturpedrotti/macos-vim-navigation/releases/latest/download/macos-vim-navigation.zip)

A minimal, responsive, and Vim-inspired mouse/navigation controller for macOS.

---

## ✨ What is this?

This is a **Vim-style keyboard navigation system for macOS**, powered by [Hammerspoon](https://www.hammerspoon.org).  
It lets you **control your mouse, inputs, screens, and window focus** without ever reaching for your trackpad or mouse.

This config includes:

- 🖱️ One-tap screen switching with `⌥` (Option) or `⌃` (Control) – **outside nav mode**
- 🧭 A full **NAV MODE** for mouse movement, input clicking, screen edge jumping, and app textbox navigation
- 🖥️ Support for multi-monitor setups
- ⚡ Lightweight, pragmatic, and easy to edit
- 🧠 Inspired by Vim and modal editors

**Tip:** `⌥` and `⌃` actions are triggered on **key release**, so they don’t interfere with regular macOS shortcuts.

---

## 🧠 Commands Summary

### 📦 Global (Works Anytime)

| Key     | Action                                            |
| ------- | ------------------------------------------------- |
| `⌥ tap` | Move mouse to center of next connected screen     |
| `⌃ tap` | Click near bottom-middle of next connected screen |
| `⌥ + r` | Reload Hammerspoon config                         |

### 🚀 Entering and Exiting NAV MODE

| Key Combo                     | Action                                        |
| ----------------------------- | --------------------------------------------- |
| `⌃⌥⌘ + space` / `F12` / `⌃ =` | Enter NAV MODE (overlay shows `-- NORMAL --`) |
| `⎋` or `⌃ + c`                | Exit NAV MODE                                 |

### 🧭 NAV MODE (Modal Vim-style Movement & Controls)

| Key             | Action                                     |
| --------------- | ------------------------------------------ |
| `h / j / k / l` | Move mouse (← ↓ ↑ →) (1/8th screen step)   |
| `H / J / K / L` | Move mouse faster (1/2 screen step)        |
| `d`             | Scroll down                                |
| `g`             | Focus ChatGPT app and click into input box |
| `u`             | Scroll up                                  |
| `w`             | Scroll right                               |
| `b`             | Scroll left                                |
| `i`             | Left click                                 |
| `a`             | Right click                                |
| `Shift + A`     | Focus next app textbox to the right        |
| `Shift + I`     | Focus previous app textbox to the left     |
| `Shift + M`     | Move mouse to center of screen             |
| `Shift + W`     | Move to screen edge (→)                    |
| `Shift + B`     | Move to screen edge (←)                    |
| `Shift + U`     | Move to screen edge (↑)                    |
| `Shift + D`     | Move to screen edge (↓)                    |

---

## 🛠 Setup Instructions

### 1. 📦 Download the latest version

[**Download here**](https://github.com/arturpedrotti/macos-vim-navigation/releases/latest/download/macos-vim-navigation.zip)

Unzip it and move into the directory:

```bash
unzip macos-vim-navigation.zip
cd macos-vim-navigation
```

### 2. 🔧 Install Hammerspoon

Go to [https://www.hammerspoon.org](https://www.hammerspoon.org) and download the app.  
After installation, open it and **grant Accessibility and Automation permissions** in System Settings.

### 3. 🧠 Load the config

Place `init.lua` inside `~/.hammerspoon/`. You can do this by:

```bash
cp init.lua ~/.hammerspoon/
```

Then either restart Hammerspoon or click its tray icon and select **"Reload Config"**.

### 4. ✅ Try it out

- Tap `⌥` to jump the mouse to the center of the next screen
- Tap `⌃` to simulate a click near the bottom-middle of the next screen
- Press `⌃⌥⌘ + space` to enter **NAV MODE** and use Vim-style mouse navigation

That’s it!

---

## ✏️ Customizing

This config is highly tweakable. You can open `init.lua` in your favorite text editor and:

- Adjust movement speeds (`mouseStep`)
- Change screen index cycling behavior
- Add new modal bindings using `modal:bind(...)`
- Remove or change NAV MODE keys or triggers
