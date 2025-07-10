# 🟩 VIM-STYLE MAC NAVIGATION SYSTEM  
### Powered by Hammerspoon  
#### Designed by **Artur Grochau**

---

## ✨ What is this?

This is a **Vim-style keyboard-only control system for macOS**, powered by [Hammerspoon](https://www.hammerspoon.org/).  
It transforms your Mac into a modal keyboard-controlled environment: jump between windows, focus screens, scroll without a mouse, launch your editor, browse the web, and use ChatGPT — all from your keyboard.

---

## 🧠 Core Features

| Key                                  | Action                                                                 |
|-------------------------------------|------------------------------------------------------------------------|
| `⌃⌥⌘ + Space`                       | Enter **NAV MODE** (activates modal commands)                         |
| `h / j / k / l`                     | Move window focus (left/down/up/right), across displays               |
| `d / u`                             | Scroll down / up (like mouse wheel)                                   |
| `gg / G`                            | Scroll to top / bottom                                                |
| `c`                                 | Focus or launch ChatGPT and auto-click the text input                 |
| `o`                                 | Open Arc browser and create a new tab                                 |
| `v`                                 | Open or focus VS Code and move mouse into center of editor            |
| `w / b`                             | Switch to next / previous browser tab (Chrome/Arc/Safari)             |
| `⎋ Escape`                          | Exit NAV MODE                                                         |
| `⌥ Option (hold → release)`         | Move mouse cursor to next **real** screen (multi-monitor setup)       |
| `⌥ + r`                             | Reload Hammerspoon config (manual trigger)                            |

---

## 🪟 NAV MODE Indicator

When active, a floating **"NAV MODE"** HUD appears at the bottom-right of your current screen.

---

## 🛠 Installation & Setup

### 1. Clone this project

```bash
git clone git@github.com:arturpedrotti/vim-nav-hs.git
cd vim-nav-hs
```

### 2. Install Hammerspoon

Download and install it from:

https://www.hammerspoon.org/

After launching it once, go to:

- **System Settings → Privacy & Security → Accessibility**
- Enable permissions for **Hammerspoon**
- Also enable **Automation** if prompted (allow control of other apps)

---

### 3. Link the configuration

Copy the Lua config file into your Hammerspoon directory:

```bash
cp init.lua ~/.hammerspoon/init.lua
```

Then reload Hammerspoon to activate the config:

- Click **"Reload Config"** from the Hammerspoon menu bar icon  
- Or press `⌥ + r` (already built into this config)

---

## 🧪 Usage Guide

Once installed:

1. Press `⌃⌥⌘ + Space` to activate **NAV MODE**
2. You’ll see a floating HUD saying “NAV MODE”
3. Use the following commands:

   - `h / j / k / l` → move window focus (like Vim)
   - `d / u` → scroll down / up slightly
   - `gg / G` → scroll to top / bottom of a scrollable view
   - `c` → jump to ChatGPT and auto-click input
   - `v` → open or focus VS Code
   - `o` → open Arc and open new tab
   - `w / b` → switch to next / previous tab
   - `⎋` → exit modal

4. Outside NAV MODE:
   - Hold + release `⌥` → move mouse between screens
   - Press `⌥ + r` → reload config manually

---

## ⚙️ Customization Tips

### 💻 Use another browser?

Change this line inside `init.lua` if you use Chrome or Safari:

```lua
hs.application.launchOrFocus("Arc")
```

Examples:

```lua
hs.application.launchOrFocus("Google Chrome")
```

or

```lua
hs.application.launchOrFocus("Safari")
```

---

### 🧠 VS Code variants

If you're using a different version of VS Code, such as **Insiders**, update the line:

```lua
hs.application.launchOrFocus("Visual Studio Code")
```

to

```lua
hs.application.launchOrFocus("Visual Studio Code - Insiders")
```

To check your exact app name, run this in the Hammerspoon console:

```lua
hs.application.frontmostApplication():name()
```

---

## 📁 Recommended Project Structure

```
vim-nav-hs/
├── README.md        # This documentation file  
└── init.lua         # The full Hammerspoon config  
```

Place both files at the root of your project repository.

Install with:

```bash
cp init.lua ~/.hammerspoon/init.lua
```

---

## 🧑‍💻 Contributing

Feel free to fork this project or open an issue if you have ideas, improvements, or need help customizing it further.

---

## 📜 License

MIT License.  
Created and maintained by **Artur Grochau**.
