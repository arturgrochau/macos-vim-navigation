# 🟩 VIM-STYLE MAC NAVIGATION SYSTEM  
### Powered by Hammerspoon  
#### Designed by **Artur Grochau**

---

## ✨ What is this?

This is a **Vim-style keyboard navigation system for macOS**, built using Hammerspoon.  
It helps you control screens, apps, inputs, and the mouse — all without lifting your hands off the keyboard.

This config includes:

- 🖱️ One-tap screen switching with `⌥` or `⌃`
- 🧭 Modal **NAV MODE** for full mouse, scroll, and UI movement
- 🔎 Auto-jump to text boxes
- 🖥️ Works across multi-monitor setups
- 🧼 Minimal, fast, and customizable

---

## 🧠 Commands Summary

| Key                                | Action                                                                 |
|-----------------------------------|------------------------------------------------------------------------|
| `⌥ tap`                           | Move mouse to center of next screen                                   |
| `⌃ tap`                           | Click near bottom-middle of next screen                               |
| `⌃⌥⌘ + space` / `F12` / `⌃ =`     | Enter **NAV MODE** (shows `-- NORMAL --` overlay)                     |
| `⎋` or `⌃ + c`                    | Exit NAV MODE                                                         |
| `h / j / k / l`                   | Move mouse (← ↓ ↑ →), holdable                                        |
| `H / J / K / L`                   | Move mouse faster (×4 speed)                                          |
| `d / u / w / b`                   | Scroll down / up / right / left, holdable                             |
| `i`                               | Left click                                                            |
| `a`                               | Right click                                                           |
| `Shift + A` / `Shift + I`         | Jump to nearest textbox (→ / ←), click + **exit NAV MODE**            |
| `0` or `Shift + 6` (`^`)          | Move mouse to leftmost textbox (no click, stay in NAV MODE)           |
| `Shift + 4` (`$`)                 | Move mouse to rightmost textbox (no click, stay in NAV MODE)          |
| `Shift + M`                       | Move mouse to center of current screen                                |
| `Shift + W / B / U / D`           | Move mouse near screen edge (→ ← ↑ ↓)                                 |
| `⌥ + r`                           | Reload Hammerspoon config                                             |

---

## 🛠 Setup Instructions

### 1. 🔁 Clone this config

```bash
git clone https://github.com/yourname/vim-nav-hs.git
cd vim-nav-hs
```

### 2. 🧱 Install Hammerspoon

Download it: 👉 [https://www.hammerspoon.org](https://www.hammerspoon.org)

Then:

- Open Hammerspoon once
- Go to `System Settings → Privacy & Security → Accessibility`
- Enable **Hammerspoon**
- Grant Automation if prompted

---

### 3. 🔗 Install the Config

```bash
cp init.lua ~/.hammerspoon/init.lua
```

Then either:

- Click the Hammerspoon menu bar icon → "Reload Config"  
- Or press `⌥ + r` to reload manually

---

## 🧪 Test It Works

1. Tap `⌥` → mouse moves to center of next screen  
2. Tap `⌃` → mouse clicks near bottom of next screen  
3. Press `⌃⌥⌘ + Space` or `F12` or `⌃ =` → "NORMAL" appears  
4. Use `h/j/k/l`, scroll with `d/u/w/b`, try jumps like `Shift+A`, `0`, `$`

---

## 🧩 Customization

### Change App Focuses (if used in your build)

Inside your `init.lua`, you can replace `Arc`, `ChatGPT`, `Visual Studio Code`, etc., with your preferred app names:

```lua
hs.application.launchOrFocus("Google Chrome")
hs.application.launchOrFocus("iTerm")
```

To discover the current app name:

```lua
hs.application.frontmostApplication():name()
```

Paste this into Hammerspoon’s console (`⌘ + 4` from the menu icon).

---

## 📁 Project Structure

```bash
vim-nav-hs/
├── README.md       # This file
└── init.lua        # Hammerspoon config
```

---

## 👨‍💻 Contributing

Fork it. Hack it. Extend it.  
Open issues or ideas anytime.

---

## 📜 License

MIT License  
Made by **Artur Grochau**
