#!/bin/sh
# Installs claude-profile into ~/.local/bin (or $CLAUDE_PROFILES_BIN).
#   curl -fsSL https://raw.githubusercontent.com/agentic-tool-labs/claude-profiles/main/install.sh | sh
set -eu
src=${CLAUDE_PROFILE_SRC:-https://raw.githubusercontent.com/agentic-tool-labs/claude-profiles/main/claude-profile}
bin=${CLAUDE_PROFILES_BIN:-$HOME/.local/bin}

command -v curl >/dev/null 2>&1 || { echo "install: curl is required" >&2; exit 1; }
mkdir -p "$bin"
tmp=$(mktemp "$bin/.claude-profile.XXXXXX")
trap 'rm -f "$tmp"' EXIT
curl -fsSL "$src" -o "$tmp"
head -n 1 "$tmp" | grep -q '^#!/bin/sh' || { echo "install: download from $src is not the claude-profile script" >&2; exit 1; }
chmod 755 "$tmp"
mv "$tmp" "$bin/claude-profile"
trap - EXIT

echo "Installed $bin/claude-profile"
case ":$PATH:" in *":$bin:"*) ;; *) echo "Note: $bin is not on your PATH. Add it, then run: claude-profile add <name>" ;; esac
