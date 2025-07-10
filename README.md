# 🟩 VIM-STYLE NAVIGATION SYSTEM FOR MAC  
### Powered by Hammerspoon  
#### Designed by Artur Grochau

---

## ✨ What is this?

A **modal, Vim-inspired keyboard navigation system** for macOS built on [Hammerspoon](https://www.hammerspoon.org/).  
Designed for productivity, especially for data scientists and keyboard enthusiasts, it enables seamless window management, multi-monitor navigation, scrolling, app launching, and automation — all from your keyboard.

---

## 🧠 Core Features

| Shortcut                              | Action                                                                                 |
|-------------------------------------|----------------------------------------------------------------------------------------|
| Tap `Option` (Alt)                   | Moves mouse cursor to the center of the next physical monitor                          |
| Tap `Control`                        | Moves mouse cursor to the bottom-center of the next physical monitor and clicks there |
| `⌃⌥⌘ + Space` or `F12`               | Enter NAV MODE (modal Vim-like navigation & commands)                                 |
| `Ctrl + C` or `Escape`               | Exit NAV MODE                                                                         |
| `h / j / k / l`                      | Move window focus left/down/up/right (Vim style, across monitors)                     |
| `d / u`                              | Scroll down / up slightly (like mouse wheel)                                          |
| `gg` / `G`                            | Scroll to top / bottom                                                                |
| `c`                                  | Focus or launch ChatGPT and auto-click input box                                      |
| `o`                                  | Open Arc browser and open a new tab                                                   |
| `v`                                  | Open or focus VS Code and move mouse cursor to editor center                          |
| `w / b`                              | Switch to next / previous browser tab (Chrome/Arc/Safari)                             |
| `⌥ + r`                              | Reload Hammerspoon config manually                                                    |

---

## 🪟 NAV MODE Indicator

While NAV MODE is active, a floating translucent **"NAV MODE"** label appears at the bottom-right corner of your current screen.

---

## 🛠 Installation & Setup

1. Install [Hammerspoon](https://www.hammerspoon.org/) and grant **Accessibility** and **Automation** permissions.

2. Clone or download this project.

3. Copy `init.lua` to your Hammerspoon config directory:

<pre>
cp init.lua ~/.hammerspoon/init.lua
</pre>

4. Reload Hammerspoon via menu bar or press `⌥ + r`.

---

## 🧪 How to Use

- Tap `Option` to cycle mouse through monitor centers.
- Tap `Control` to cycle mouse and click near bottom-center on monitors.
- Press `⌃⌥⌘ + Space` or `F12` to enter NAV MODE.
- Use `h/j/k/l` to move window focus.
- Use `d/u` to scroll down/up.
- Double press `g` for scroll top, Shift + `g` for scroll bottom.
- Press `c` to jump to ChatGPT input.
- Press `o` to open Arc browser and new tab.
- Press `v` to open/focus VS Code.
- Press `w/b` to switch browser tabs.
- Press `Escape` or `Ctrl + C` to exit NAV MODE.
- Press `⌥ + r` to reload config manually.

---

## ⚙️ Customization Tips

- Change app names in `init.lua` if you use different browsers or code editors.
- Add new keybindings inside the `modal` block.
- To debug screen names: use `hs.screen.allScreens()` in Hammerspoon Console.

---

## 📁 Recommended Structure

vim-nav-hs/  
├── README.md  
└── init.lua  

---

## 🧑‍💻 Contributing

Open an issue or fork this repo with your own additions. Tailor it for your specific workflows.

---

## 📜 License

MIT License  
Created and maintained by **Artur Grochau**
