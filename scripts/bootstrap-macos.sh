#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DRY_RUN=0
SKIP_BREW=0

usage() {
  cat <<'EOF'
Usage: ./scripts/bootstrap-macos.sh [--dry-run] [--skip-brew]

Install the Homebrew packages and VS Code extensions declared by this repo.
Link this repo's VS Code user settings into the current macOS account.
Run from any directory; the script always uses this checkout's Brewfile.
EOF
}

while (($#)); do
  case "$1" in
    --dry-run) DRY_RUN=1 ;;
    --skip-brew) SKIP_BREW=1 ;;
    -h|--help) usage; exit 0 ;;
    *) printf 'Unknown option: %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

if [[ "$(uname -s)" != "Darwin" ]]; then
  printf 'This bootstrap is for macOS.\n' >&2
  exit 1
fi

if ! command -v brew >/dev/null 2>&1; then
  printf 'Homebrew is required. Install it from https://brew.sh, then rerun this script.\n' >&2
  exit 1
fi

run() {
  if ((DRY_RUN)); then
    printf '+'
    printf ' %q' "$@"
    printf '\n'
  else
    "$@"
  fi
}

if ((!SKIP_BREW)); then
  run brew bundle --file "$ROOT_DIR/Brewfile"
fi

USER_SETTINGS_DIR="$HOME/Library/Application Support/Code/User"
USER_SETTINGS_FILE="$USER_SETTINGS_DIR/settings.json"
REPO_SETTINGS_FILE="$ROOT_DIR/config/vscode/settings.json"

if [[ -L "$USER_SETTINGS_FILE" ]] && [[ "$(readlink "$USER_SETTINGS_FILE")" == "$REPO_SETTINGS_FILE" ]]; then
  printf 'VS Code user settings already point to this checkout.\n'
else
  if ((DRY_RUN)); then
    run mkdir -p "$USER_SETTINGS_DIR"
    if [[ -e "$USER_SETTINGS_FILE" || -L "$USER_SETTINGS_FILE" ]]; then
      printf '+ mv %q %q/settings.json.backup-TIMESTAMP\n' "$USER_SETTINGS_FILE" "$USER_SETTINGS_DIR"
    fi
    run ln -s "$REPO_SETTINGS_FILE" "$USER_SETTINGS_FILE"
  else
    mkdir -p "$USER_SETTINGS_DIR"
    if [[ -e "$USER_SETTINGS_FILE" || -L "$USER_SETTINGS_FILE" ]]; then
      BACKUP_FILE="$USER_SETTINGS_FILE.backup-$(date +%Y%m%d-%H%M%S)"
      mv "$USER_SETTINGS_FILE" "$BACKUP_FILE"
      printf 'Existing settings backed up to: %s\n' "$BACKUP_FILE"
    fi
    ln -s "$REPO_SETTINGS_FILE" "$USER_SETTINGS_FILE"
    printf 'Linked VS Code user settings to this checkout.\n'
  fi
fi

CODE_BIN=""
if [[ -x "/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code" ]]; then
  CODE_BIN="/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"
elif [[ -x "$HOME/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code" ]]; then
  CODE_BIN="$HOME/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"
fi

if [[ -z "$CODE_BIN" ]] && ((DRY_RUN)); then
  CODE_BIN="/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"
fi

if [[ -z "$CODE_BIN" ]]; then
  printf 'Visual Studio Code app was not found. Install it with Homebrew or move it to /Applications, then rerun this script.\n' >&2
  exit 1
fi

while IFS= read -r extension; do
  [[ -n "$extension" ]] || continue
  run "$CODE_BIN" --install-extension "$extension" --force
done < <(grep -Eo '"[A-Za-z0-9._-]+\.[A-Za-z0-9._-]+"' "$ROOT_DIR/.vscode/extensions.json" | tr -d '"')

printf '\nBootstrap complete. Open this folder in VS Code with: code "%s"\n' "$ROOT_DIR"
