# 🟩 VIM-STYLE MAC NAVIGATION SYSTEM  
### Powered by Hammerspoon  
#### Designed by **Artur Grochau**

---

## ✨ What is this?

This is a **Vim-style navigation system for macOS**, built for pure keyboard control.  
It's designed to help you focus, work faster, and switch between screens, apps, and inputs — without touching your mouse.

This config includes:

- 🖱️ One-tap switching between screens with `⌥` and `⌃`
- 🧭 NAV MODE (modal key layer) to move windows, scroll like Vim, jump to apps
- 💻 Launch apps like VS Code, Arc, or ChatGPT
- 🧹 Works in any workspace setup — even multi-monitor

---

## 🧠 Quick Commands Summary

| Key                                | Action                                                                 |
|-----------------------------------|------------------------------------------------------------------------|
| `⌥ tap`                           | Move mouse to center of next physical screen                          |
| `⌃ tap`                           | Click bottom-middle of next screen (where input fields usually are)   |
| `⌃⌥⌘ + space` / `F12` / `⌃ =`     | Activate **NAV MODE**                                                 |
| `h / j / k / l`                   | Move window focus (← ↓ ↑ →)                                           |
| `d / u`                           | Scroll down / up slightly (like `Ctrl-d`, `Ctrl-u` in Vim)            |
| `gg / G`                          | Scroll to top / bottom                                                |
| `c`                               | Focus ChatGPT and click text input                                    |
| `v`                               | Focus or open VS Code                                                 |
| `o`                               | Open Arc and new tab, then exit NAV MODE                              |
| `a`                               | Focus or open Arc (stay in NAV MODE)                                  |
| `w / b`                           | Next / previous browser tab                                           |
| `⎋` or `⌃ + c`                    | Exit NAV MODE                                                         |
| `⌥ + r`                           | Reload config manually                                                |

---

## 🛠 Installation & Setup

### 1. 🔁 Clone this repo

```bash
git clone git@github.com:arturpedrotti/vim-nav-hs.git
cd vim-nav-hs
```

### 2. 🧱 Install Hammerspoon

Download and install:

👉 https://www.hammerspoon.org/

Then:

- Open Hammerspoon once
- Go to `System Settings → Privacy & Security → Accessibility`
- Enable access for **Hammerspoon**
- Also allow **Automation** if prompted

---

### 3. 🔗 Link the configuration

Copy the file to Hammerspoon’s expected config location:

```bash
cp init.lua ~/.hammerspoon/init.lua
```

Then either:

- Click the Hammerspoon menu bar icon → "Reload Config"  
- Or press `⌥ + r` (already built into this config)

---

## 🚀 How to Use

### Tap-Based Mouse Navigation (⚡ Works anywhere)

| Action                          | How it works                                  |
|--------------------------------|-----------------------------------------------|
| `⌥ tap` (just press/release)   | Mouse jumps to center of next screen          |
| `⌃ tap`                         | Mouse clicks bottom of next screen            |

You can cycle through screens infinitely, no need to hold keys.

---

### Enter NAV MODE (modal layer for keyboard commands)

Press any of the following:

- `⌃⌥⌘ + Space`
- `F12`
- `⌃ =`

You’ll see a floating "NAV MODE" popup in the corner. This means it's active.

---

### While in NAV MODE

| Keys         | What it does                              |
|--------------|--------------------------------------------|
| `h / j / k / l` | Focus next window in direction (like Vim) |
| `d / u`         | Scroll slightly down / up                |
| `g g`           | Scroll to top                            |
| `G`             | Scroll to bottom                         |
| `c`             | Focus ChatGPT and click into input       |
| `v`             | Open or focus VS Code                    |
| `o`             | Open Arc and new tab → exit NAV MODE     |
| `a`             | Open Arc (stay in NAV MODE)              |
| `w / b`         | Browser tab next / previous              |
| `⎋` or `⌃ + c`  | Exit NAV MODE                            |

---

## ⚙️ Customization (For You)

You can change app names inside `init.lua`:

```lua
-- Replace "Arc" with your browser
hs.application.launchOrFocus("Arc")
-- or
hs.application.launchOrFocus("Google Chrome")
```

Same with VS Code:

```lua
hs.application.launchOrFocus("Visual Studio Code")
-- Or:
hs.application.launchOrFocus("Visual Studio Code - Insiders")
```

To find exact app names:

```lua
hs.application.frontmostApplication():name()
```

Paste the above in Hammerspoon's console (⌘ + 4 from menu icon).

---

## 🧪 To Test It Works

1. Launch Hammerspoon (menu icon should be visible)
2. Tap `⌥` → mouse should jump screen center  
3. Tap `⌃` → mouse should click bottom of screen  
4. Press `⌃⌥⌘ + space` or `f12` or `ctrl =`  
   → "NAV MODE" should appear  
5. Use Vim keys (`h/j/k/l`) to move window focus  
6. Try `v`, `c`, `o`, `a` to test apps  

---

## 📁 Project Structure

vim-nav-hs/  
├── README.md        # This file  
└── init.lua         # Main Hammerspoon config

Install with:

```bash
cp init.lua ~/.hammerspoon/init.lua
```

---

## 👨‍💻 Contributing

Fork it. Hack it. Use it.  
Open issues if you want help with extending or fixing behavior.

---

## 📜 License

MIT License  
Created and maintained by **Artur Grochau**
```
