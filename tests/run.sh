#!/bin/sh
# Self-contained checks: a fake `claude` on PATH, a throwaway HOME, no network, no real logins.
set -eu
here=$(cd "$(dirname "$0")/.." && pwd)
tool="$here/claude-profile"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
fails=0

check() { # description, then a command that must succeed
	desc=$1; shift
	if "$@" >/dev/null 2>&1; then printf 'ok    %s\n' "$desc"; else printf 'FAIL  %s\n' "$desc"; fails=$((fails + 1)); fi
}
fails_with() { # description, then a command that must fail
	desc=$1; shift
	if "$@" >/dev/null 2>&1; then printf 'FAIL  %s\n' "$desc"; fails=$((fails + 1)); else printf 'ok    %s\n' "$desc"; fi
}

mkdir -p "$tmp/fakebin" "$tmp/bin" "$tmp/home"
# The fake claude mentions the variable (as a real build does) and reports what it was given.
cat >"$tmp/fakebin/claude" <<'EOF'
#!/bin/sh
# knows CLAUDE_SECURESTORAGE_CONFIG_DIR
printf 'store=%s profile=%s args=%s\n' "${CLAUDE_SECURESTORAGE_CONFIG_DIR:-}" "${CLAUDE_PROFILE:-}" "$*"
EOF
chmod +x "$tmp/fakebin/claude"

export HOME="$tmp/home" CLAUDE_PROFILES_BIN="$tmp/bin" CLAUDE_PROFILES_HOME="$tmp/home/.claude-profiles"
export PATH="$tmp/bin:$tmp/fakebin:/usr/bin:/bin"

check "add creates the wrapper" "$tool" add work
check "wrapper is executable" test -x "$tmp/bin/claude-work"
out=$("$tmp/bin/claude-work" --resume "a b")
check "wrapper sets the per-profile store" test "$out" = "store=$CLAUDE_PROFILES_HOME/work profile=work args=--resume a b"
check "store folder is private" sh -c "ls -ld '$CLAUDE_PROFILES_HOME/work' | grep -q '^drwx------'"
check "add is repeatable for its own wrapper" "$tool" add work
check "list shows the profile" sh -c "'$tool' list | grep -q '^claude-work'"

fails_with "rejects names with odd characters" "$tool" add 'Work!'
fails_with "rejects names starting with -" "$tool" add -x
printf '#!/bin/sh\necho mine\n' >"$tmp/bin/claude-mine"
fails_with "refuses to overwrite a command it didn't make" "$tool" add mine
check "...and leaves that command alone" grep -q mine "$tmp/bin/claude-mine"

fails_with "remove refuses a command it didn't make" "$tool" remove -y mine
check "remove -y deletes the wrapper" "$tool" remove -y work
check "...and the wrapper is gone" test ! -e "$tmp/bin/claude-work"

cp "$tool" "$tmp/bin/claude-profile"
check "list ignores the tool itself" sh -c "! '$tool' list | grep -q '^claude-profile'"
fails_with "refuses the reserved name 'profile'" "$tool" add profile
check "...and the tool is untouched" cmp -s "$tool" "$tmp/bin/claude-profile"
fails_with "remove won't delete the tool" "$tool" remove -y profile

# A build that knows the name but ignores it: reports a login even though the store is empty.
cat >"$tmp/fakebin/claude" <<'EOS'
#!/bin/sh
# knows CLAUDE_SECURESTORAGE_CONFIG_DIR
[ "$1 $2" = "auth status" ] && echo '{ "loggedIn": true }'
EOS
fails_with "add catches a build that ignores the variable" "$tool" add ignored
check "...and leaves no wrapper behind" test ! -e "$tmp/bin/claude-ignored"

printf '#!/bin/sh\necho old\n' >"$tmp/fakebin/claude"
fails_with "add refuses a Claude Code build without the variable" "$tool" add other
check "...and creates nothing" test ! -e "$tmp/bin/claude-other"

[ "$fails" = 0 ] && echo "all passed" || { echo "$fails failed"; exit 1; }
