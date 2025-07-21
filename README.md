# 🟩 VIM-STYLE MAC NAVIGATION SYSTEM  
### Powered by Hammerspoon  
#### Customized by **Artur Grochau**

---

## ✨ What is this?

This is a **Vim-style keyboard navigation system for macOS**, built on Hammerspoon.  
It gives you ultra-fast control over:

- Switching screens
- Clicking into text inputs
- Scrolling and mouse movement
- Navigating apps
- Without touching your mouse

---

## 🧠 Quick Commands

| Mode / Key(s)                      | Action                                                                 |
|-----------------------------------|------------------------------------------------------------------------|
| `⌥` (tap)                         | Move mouse to center of next screen                                    |
| `⌃` (tap)                         | Click near bottom of next screen (where input fields usually are)      |
| `⌃⌥⌘ + Space` / `F12` / `⌃ =`     | Enter **-- NORMAL --** mode                                            |
| `Esc` or `⌃ + c`                  | Exit NORMAL mode                                                       |

### While in NORMAL Mode

| Key(s)                            | Action                                                                 |
|----------------------------------|------------------------------------------------------------------------|
| `h / j / k / l`                  | Move mouse left / down / up / right (hold to repeat)                   |
| `H / J / K / L`                  | Move mouse 4× faster in same direction                                 |
| `d / u`                          | Scroll down / up (holdable)                                            |
| `w / b`                          | Scroll right / left (holdable)                                         |
| `W / B / U / D`                  | Move mouse to right / left / top / bottom edge                         |
| `i / a`                          | Left click / right click at cursor                                     |
| `I / A`                          | Jump to & click nearest textbox on left / right (tries next app too)  |
| `0` or `^`                       | Move mouse to leftmost textbox                                         |
| `$`                              | Move mouse to rightmost textbox                                      |
| `M`                              | Center mouse on current screen                                         |

---

## 🧱 Setup Instructions

### 1. Install Hammerspoon

Download: https://www.hammerspoon.org/  
Then open it and grant **Accessibility + Automation** in:

> System Settings → Privacy & Security → Accessibility

---

### 2. Install the Config

Clone and copy the `init.lua` file:

```bash
git clone https://github.com/yourname/vim-nav-hs.git
cp vim-nav-hs/init.lua ~/.hammerspoon/init.lua
```

Then either:

- Click the Hammerspoon menu icon → "Reload Config"
- Or press `⌥ + r` (it's built in)

---

## 🚀 Feature Overview

### 🔁 Screen Switching

- Tap `⌥` to move the mouse to the center of the next screen.
- Tap `⌃` to click near the bottom of the next screen (usually near input boxes).

You can cycle through screens infinitely.

---

### 🧭 NORMAL Mode

Enter with:

- `⌃⌥⌘ + Space`
- `F12`
- `⌃ =`

You'll see a small overlay: `-- NORMAL --`

While in this mode:

#### 🖱 Mouse Movement

- `h/j/k/l`: Move mouse in respective direction (hold to repeat)
- `H/J/K/L`: Same as above but 4× faster
- `M`: Jump mouse to center of screen
- `W/B/U/D`: Jump mouse near edge (right, left, top, bottom)

#### ⬇️ Scrolling

- `d/u`: Scroll down/up
- `w/b`: Scroll right/left  
All scrolls repeat if held.

#### 🖱 Clicking

- `i`: Left click
- `a`: Right click

#### ✍️ Textbox Navigation

- `A`: Jump to textbox to the right (tries focused app first, then fallback)
- `I`: Jump to textbox to the left (same logic)
- `$`: Jump near right edge of screen
- `0` / `^`: Jump to leftmost visible textbox

#### 🔚 Exit

- `Esc` or `Ctrl + c`: Exits NORMAL mode

---

## 🔁 Reloading

You can manually reload the config with:

- `⌥ + r`  
- Or click the menu bar → "Reload Config"

---

## 👨‍💻 Customization

Change default apps, text detection filters, or modifier keys by editing `~/.hammerspoon/init.lua`.

To inspect any app name:

```lua
hs.application.frontmostApplication():name()
```

Paste in Hammerspoon's console (⌘ + 4).

---

## 📁 File Structure

```
vim-nav-hs/
├── README.md
└── init.lua
```

Install by copying `init.lua` to `~/.hammerspoon/`.

---

## 📜 License

MIT License  
Created & customized by **Artur Grochau**
