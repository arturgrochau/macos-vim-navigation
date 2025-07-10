# 🟩 VIM-STYLE MAC NAVIGATION SYSTEM  
### powered by Hammerspoon  
#### Designed by **Artur Grochau**

---

## ✨ What is this?

This is a **modal, Vim-style control system** for macOS using [Hammerspoon](https://www.hammerspoon.org/).  
It lets you **navigate, scroll, switch screens, jump between browser tabs, and click into ChatGPT** — all using **keyboard only**, in a blazing-fast Vim-style workflow.

---

## 🧠 Core Features

| Shortcut                            | Action                                                                 |
|-------------------------------------|------------------------------------------------------------------------|
| `⌃⌥⌘ + Space`                       | Enters **NAV MODE** (activates all other keys)                        |
| `h / j / k / l`                     | Move window focus (left/down/up/right) — across monitors              |
| `d / u`                             | Scroll down / up slightly (like mouse wheel)                          |
| `gg / Shift+g` (`G`)                | Scroll to top / bottom                                                |
| `c`                                 | Focus ChatGPT and click the input box automatically                   |
| `o`                                 | Open Arc browser and create a new tab                                 |
| `w / b`                             | Switch to next / previous browser tab                                 |
| `Escape`                            | Exit NAV MODE                                                         |
| `⌥ + r`                             | Manual reload of Hammerspoon                                          |
| `⌥` hold + release (no keypress)    | Cycle through screens (moves mouse to next physical display)         |

---

## 🖥 Floating HUD

When NAV MODE is active, a transparent **“NAV MODE”** label floats at the bottom-right of your screen to let you know you're in command mode.

---

## 📦 Requirements

- macOS (M1/M2/M3+ supported)
- [Hammerspoon](https://www.hammerspoon.org/)
- Arc Browser (or modify to use Chrome/Safari in the script)
- Optional: Setup ChatGPT window with `"ChatGPT"` in the title

---

## 👤 Author

Designed and configured by **Artur Grochau**, tailored for ultimate productivity on macOS using keyboard-first control.

---

## 🛠 Installation

1. Install [Hammerspoon](https://www.hammerspoon.org/)
2. Copy the `init.lua` contents into your `~/.hammerspoon/init.lua`
3. Reload via the menu bar or press `⌥ + r`

---

> “Vim isn’t just an editor — it’s a mindset.”  
— Now, your whole Mac works that way.
