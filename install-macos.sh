#!/usr/bin/env bash

set -u

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="${REPO_ROOT}/install-macos.log"

OPTIONS=("ghostty" "hermes" "hunk" "kitty" "nvim" "oh-my-posh" "opencode" "tmux")
SELECTED=(0 0 0 0 0 0 0 0)

log() {
  local level="$1"
  local message="$2"
  local line
  line="[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $message"
  printf '%s\n' "$line"
  printf '%s\n' "$line" >> "$LOG_FILE"
}

render_menu() {
  local cursor="$1"
  local i

  clear
  printf 'Select what to install (Space: toggle, Enter: confirm, q: quit)\n\n'
  for i in "${!OPTIONS[@]}"; do
    local pointer=" "
    local check="[ ]"
    if [ "${SELECTED[$i]}" -eq 1 ]; then
      check="[x]"
    fi
    if [ "$i" -eq "$cursor" ]; then
      pointer=">"
    fi
    printf '%s %s %s\n' "$pointer" "$check" "${OPTIONS[$i]}"
  done
}

menu_select() {
  local cursor=0
  local key=""

  while true; do
    render_menu "$cursor"
    IFS= read -rsn1 key

    if [ "$key" = "" ]; then
      break
    fi

    if [ "$key" = "q" ]; then
      printf '\nCancelled.\n'
      exit 0
    fi

    if [ "$key" = " " ]; then
      if [ "${SELECTED[$cursor]}" -eq 1 ]; then
        SELECTED[$cursor]=0
      else
        SELECTED[$cursor]=1
      fi
      continue
    fi

    if [ "$key" = $'\x1b' ]; then
      IFS= read -rsn1 key
      if [ "$key" = "[" ]; then
        IFS= read -rsn1 key
        case "$key" in
          A)
            cursor=$((cursor - 1))
            if [ "$cursor" -lt 0 ]; then
              cursor=$((${#OPTIONS[@]} - 1))
            fi
            ;;
          B)
            cursor=$((cursor + 1))
            if [ "$cursor" -ge "${#OPTIONS[@]}" ]; then
              cursor=0
            fi
            ;;
        esac
      fi
      continue
    fi

    case "$key" in
      k)
        cursor=$((cursor - 1))
        if [ "$cursor" -lt 0 ]; then
          cursor=$((${#OPTIONS[@]} - 1))
        fi
        ;;
      j)
        cursor=$((cursor + 1))
        if [ "$cursor" -ge "${#OPTIONS[@]}" ]; then
          cursor=0
        fi
        ;;
    esac
  done
}

ensure_homebrew() {
  if command -v brew >/dev/null 2>&1; then
    return 0
  fi

  log INFO "Homebrew not found. Installing from vendor script..."
  if ! /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; then
    log ERROR "Homebrew installation failed."
    return 1
  fi

  if [ -x /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [ -x /usr/local/bin/brew ]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi

  command -v brew >/dev/null 2>&1
}

is_installed_ghostty() {
  command -v ghostty >/dev/null 2>&1 || [ -d /Applications/Ghostty.app ] || [ -d "$HOME/Applications/Ghostty.app" ]
}

is_installed_kitty() {
  command -v kitty >/dev/null 2>&1 || [ -d /Applications/kitty.app ] || [ -d "$HOME/Applications/kitty.app" ]
}

is_installed_hermes() {
  command -v hermes >/dev/null 2>&1
}

is_installed_hunk() {
  command -v hunk >/dev/null 2>&1
}

is_installed_nvim() {
  command -v nvim >/dev/null 2>&1
}

is_installed_oh_my_posh() {
  command -v oh-my-posh >/dev/null 2>&1
}

is_installed_opencode() {
  command -v opencode >/dev/null 2>&1
}

is_installed_tmux() {
  command -v tmux >/dev/null 2>&1
}

brew_install() {
  local kind="$1"
  local name="$2"

  if [ "$kind" = "cask" ]; then
    brew install --cask "$name"
  else
    brew install "$name"
  fi
}

install_vendor_ghostty() {
  log WARN "No automated vendor installer configured for ghostty."
  log WARN "Install manually from https://ghostty.org/download"
  return 1
}

install_vendor_kitty() {
  curl -fsSL https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin
}

install_vendor_hermes() {
  curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash
}

install_vendor_hunk() {
  if command -v npm >/dev/null 2>&1; then
    npm install -g hunkdiff
    return $?
  fi

  if ensure_homebrew && brew_install formula node; then
    npm install -g hunkdiff
    return $?
  fi

  log WARN "No npm found for hunk installation."
  return 1
}

install_vendor_nvim() {
  local arch
  local tar_name
  local url
  local tmp_dir
  local extract_dir

  arch="$(uname -m)"
  if [ "$arch" = "arm64" ]; then
    tar_name="nvim-macos-arm64.tar.gz"
  else
    tar_name="nvim-macos-x86_64.tar.gz"
  fi

  url="https://github.com/neovim/neovim/releases/latest/download/${tar_name}"
  tmp_dir="$(mktemp -d)"

  if ! curl -fsSL "$url" -o "${tmp_dir}/nvim.tar.gz"; then
    rm -rf "$tmp_dir"
    return 1
  fi

  if ! tar -xzf "${tmp_dir}/nvim.tar.gz" -C "$tmp_dir"; then
    rm -rf "$tmp_dir"
    return 1
  fi

  extract_dir="$(find "$tmp_dir" -maxdepth 1 -type d -name 'nvim-macos-*' | head -n 1)"
  if [ -z "$extract_dir" ]; then
    rm -rf "$tmp_dir"
    return 1
  fi

  mkdir -p "$HOME/.local/opt" "$HOME/.local/bin"
  rm -rf "$HOME/.local/opt/nvim"
  mv "$extract_dir" "$HOME/.local/opt/nvim"
  ln -sf "$HOME/.local/opt/nvim/bin/nvim" "$HOME/.local/bin/nvim"
  rm -rf "$tmp_dir"
  return 0
}

install_vendor_oh_my_posh() {
  mkdir -p "$HOME/.local/bin"
  curl -fsSL https://ohmyposh.dev/install.sh | bash -s -- -d "$HOME/.local/bin"
}

install_vendor_opencode() {
  if command -v bun >/dev/null 2>&1; then
    bun add -g opencode
    return $?
  fi

  if command -v npm >/dev/null 2>&1; then
    npm install -g opencode
    return $?
  fi

  log WARN "No bun/npm found for opencode vendor fallback."
  return 1
}

install_vendor_tmux() {
  log WARN "No automated vendor installer configured for tmux."
  log WARN "Install manually from https://github.com/tmux/tmux/wiki/Installing"
  return 1
}

install_or_skip() {
  local label="$1"
  local check_func="$2"
  local brew_kind="$3"
  local brew_name="$4"
  local vendor_func="$5"

  if "$check_func"; then
    log INFO "$label is already installed. Skipping installation."
    return 0
  fi

  if ensure_homebrew && brew_install "$brew_kind" "$brew_name"; then
    log INFO "$label installed via Homebrew."
    return 0
  fi

  log WARN "Homebrew install failed for $label, trying vendor installer..."
  if "$vendor_func"; then
    log INFO "$label installed via vendor installer."
    return 0
  fi

  log ERROR "Failed to install $label."
  return 1
}

replace_dir_config() {
  local src="$1"
  local dst="$2"

  mkdir -p "$(dirname "$dst")"
  rm -rf "$dst"
  cp -R "$src" "$dst"
  log INFO "Config replaced: $dst"
}

replace_file_config() {
  local src="$1"
  local dst="$2"

  mkdir -p "$(dirname "$dst")"
  cp "$src" "$dst"
  log INFO "Config replaced: $dst"
}

apply_hermes_config() {
  local src="$REPO_ROOT/hermes/assistant"
  local profile_dst="$HOME/.hermes/profiles/assistant"

  mkdir -p "$HOME/.hermes" "$profile_dst"
  cp "$src/SOUL.md" "$HOME/.hermes/SOUL.md"
  log INFO "Hermes SOUL.md installed: $HOME/.hermes/SOUL.md"

  if [ -d "$src" ]; then
    mkdir -p "$profile_dst"
    cp -R "$src/". "$profile_dst/"
    log INFO "Hermes assistant profile synced: $profile_dst"
  fi
}

apply_config() {
  local item="$1"
  case "$item" in
    ghostty)
      replace_file_config "$REPO_ROOT/ghostty/config" "$HOME/.config/ghostty/config"
      ;;
    hermes)
      apply_hermes_config
      ;;
    kitty)
      replace_dir_config "$REPO_ROOT/kitty" "$HOME/.config/kitty"
      ;;
    nvim)
      replace_dir_config "$REPO_ROOT/nvim" "$HOME/.config/nvim"
      ;;
    oh-my-posh)
      replace_file_config "$REPO_ROOT/ohmyposh/lovexbytes.omp.json" "$HOME/.config/ohmyposh/lovexbytes.omp.json"
      ;;
    opencode)
      mkdir -p "$HOME/.config/opencode"
      replace_file_config "$REPO_ROOT/opencode/opencode.json" "$HOME/.config/opencode/opencode.json"
      replace_file_config "$REPO_ROOT/opencode/tui.json" "$HOME/.config/opencode/tui.json"
      ;;
    tmux)
      replace_file_config "$REPO_ROOT/tmux/tmux.conf" "$HOME/.tmux.conf"
      ;;
  esac
}

install_item() {
  local item="$1"
  case "$item" in
    ghostty)
      install_or_skip "ghostty" is_installed_ghostty cask ghostty install_vendor_ghostty
      ;;
    hermes)
      if is_installed_hermes; then
        log INFO "hermes is already installed. Skipping installation."
      else
        log INFO "hermes not found. Installing from vendor script..."
        install_vendor_hermes
      fi
      ;;
    hunk)
      if is_installed_hunk; then
        log INFO "hunk is already installed. Skipping installation."
      else
        log INFO "hunk not found. Installing hunkdiff from npm..."
        install_vendor_hunk
      fi
      ;;
    kitty)
      install_or_skip "kitty" is_installed_kitty cask kitty install_vendor_kitty
      ;;
    nvim)
      install_or_skip "nvim" is_installed_nvim formula neovim install_vendor_nvim
      ;;
    oh-my-posh)
      install_or_skip "oh-my-posh" is_installed_oh_my_posh formula oh-my-posh install_vendor_oh_my_posh
      ;;
    opencode)
      install_or_skip "opencode" is_installed_opencode formula opencode install_vendor_opencode
      ;;
    tmux)
      install_or_skip "tmux" is_installed_tmux formula tmux install_vendor_tmux
      ;;
  esac
}

main() {
  local i
  local any_selected=0

  : > "$LOG_FILE"
  menu_select

  for i in "${!OPTIONS[@]}"; do
    if [ "${SELECTED[$i]}" -eq 1 ]; then
      any_selected=1
      log INFO "--- Processing ${OPTIONS[$i]} ---"
      install_item "${OPTIONS[$i]}"
      apply_config "${OPTIONS[$i]}"
    fi
  done

  if [ "$any_selected" -eq 0 ]; then
    log INFO "No items selected. Nothing to do."
    return 0
  fi

  log INFO "Done. Full log: $LOG_FILE"
}

main "$@"
