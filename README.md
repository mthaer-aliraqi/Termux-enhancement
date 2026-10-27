# Termux-enhancement
# Termux Guide for Beginners

A practical guide and an automatic setup script that turn Termux into a colored, easy-to-use terminal with zsh, autosuggestions, syntax highlighting, icons, a snippet menu (Alt+S), and common developer tools.

## Contents

| File | Purpose |
|------|---------|
| `index.html` | The full guide as a single web page. Open it in any browser, or publish it with GitHub Pages. |
| `setup-termux-v5.sh` | Automatic setup script. It installs and checks every dependency, then configures zsh. |
| `README.md` | This file. |

## Quick start: run the setup script in Termux

1. Install **Termux** and **Termux:API** from F-Droid.
2. Open Termux and run:

```bash
pkg update -y && pkg upgrade -y
pkg install -y curl
curl -L -o setup-termux.sh https://raw.githubusercontent.com/M7mdThaer/termux-guide/main/setup-termux-v5.sh
bash setup-termux.sh
```

The repository is `M7mdThaer/termux-guide`. If you rename it, update the links below.

3. When asked, allow storage access.
4. When the script finishes, close Termux and open it again.

The script retries failed steps up to 3 times. If a required step still fails, it prints a red error and stops. Fix the problem it names, then run the script again. It is safe to run more than once.

## What the script sets up

- **Tools:** zsh, git, fzf, eza, bat, tealdeer (`tldr`), htop, micro, nano, Python, Java (OpenJDK 17), Node.js, and the Termux:API commands.
- **zsh:** a colored prompt, a completion menu you browse with the arrow keys, history search with the arrow keys, grey suggestions while you type, and colored command highlighting.
- **Better commands:** `ls`, `ll`, `tree`, `cat`, and `top` use eza, bat, and htop.
- **Snippets:** saved commands you pick from a list with **Alt+S**. Use `snipadd "name" "command"` to add one and `snipls` to list them.
- **Icon font:** JetBrains Mono Nerd Font, so icons display in `ll`.
- **Default shell:** zsh.

## Everyday use

| Task | Command or key |
|------|----------------|
| Open the snippet menu | Alt+S (press ALT on the extra-keys row, then S) |
| Add a snippet | `snipadd "update" "pkg update -y"` |
| List snippets | `snipls` |
| Files with icons | `ll` |
| Explain a command | `tldr ls` |
| Update packages | `pkg update -y && pkg upgrade -y` |
| Paste text | Press and hold the screen, then choose Paste (Ctrl+V does not paste in Termux) |

## Publishing the guide with GitHub Pages

1. Go to **Settings** > **Pages**.
2. Under **Build and deployment**, choose **Deploy from a branch**.
3. Select the `main` branch and the `/ (root)` folder, then click **Save**.
4. Your guide will be available at `https://m7mdthaer.github.io/termux-guide/`.

## Troubleshooting

- **A package is not found:** run `pkg update -y` and try again. If it still fails, run `pkg search NAME` to find the correct package name.
- **Storage is not connected:** run `termux-setup-storage` and allow access.
- **The default shell did not change:** run `chsh -s zsh` manually, then restart Termux.
- **Icons show as boxes:** make sure the font step finished, then close and reopen Termux.

## License

Free to use, copy, and share.
