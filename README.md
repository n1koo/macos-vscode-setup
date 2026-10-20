# macOS development editor setup

This repository keeps a portable Visual Studio Code setup for macOS development. The tracked settings file is the source of truth for your VS Code user settings; the bootstrap links it into VS Code's user settings location. It also includes extension recommendations and Homebrew packages for Rust, Go, Ruby, Python, Bash, YAML, Kubernetes, containers, GitHub, and Codex/Claude workflows.

## Bootstrap a Mac

Prerequisites: a current macOS release and Homebrew.

```sh
git clone https://github.com/OWNER/REPOSITORY.git ~/Developer/vscode-setup
cd ~/Developer/vscode-setup
./scripts/bootstrap-macos.sh
```

Replace `OWNER/REPOSITORY` with the location where you publish this setup.

The bootstrap uses Homebrew Bundle to install VS Code, GitHub CLI, and ShellCheck. It then links `config/vscode/settings.json` to VS Code's user settings file and installs the extensions listed in `.vscode/extensions.json`. If a settings file already exists, the script moves it to a timestamped backup before creating the link. Git is expected from the macOS Command Line Tools. Re-running it is safe; extensions are installed or updated in place.

Options:

```sh
./scripts/bootstrap-macos.sh --dry-run  # Show commands without running them
./scripts/bootstrap-macos.sh --skip-brew # Only install VS Code extensions
```

After setup, authenticate GitHub CLI with `gh auth login` if you want to use it in the terminal. Sign into GitHub in VS Code for pull request features. Codex and Claude Code use their own provider sign-in and subscription; they do not require GitHub Copilot for their official extensions.

## Keep machines in sync

On each Mac, clone this repository and run the bootstrap once. Then use `git pull` in the checkout to update the linked settings file; restart VS Code if a change does not take effect immediately. Keep this checkout at a stable path because the symlink points into it.

Because Git is the source of truth for settings, turn off VS Code Settings Sync for **Settings** to avoid competing edits. You may leave other Sync categories on if desired. The extension manifest is an install list: rerun the bootstrap after pulling to install newly listed extensions. It does not uninstall extensions removed from the list.

Project-specific settings belong in each project's `.vscode/settings.json`; those can override these user defaults while that project is open. Keep credentials, tokens, machine-specific paths, and work-specific configuration out of this public repository.

Some language features need project toolchains in addition to the editor extensions, such as `rustup`, `gopls`, a Ruby installation, Python environments, or `kubectl`. Install and manage those per your project or team conventions.

## Refresh extension recommendations

Edit `.vscode/extensions.json` and the bootstrap script will install the same list on the next run. The list intentionally avoids GitHub Copilot so you can use the Codex and Claude integrations independently.
