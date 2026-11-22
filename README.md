# claude-profile

Run more than one Claude Code login on the same machine at the same time, for example a personal
account in one terminal and a work account in another, with everything else shared.

```sh
claude-profile add work     # creates the claude-work command
claude-work                 # then type /login and sign in with the other account
claude-profile doctor work  # checks the two logins really are separate
```

After that, `claude` is your main account and `claude-work` is the other one. Both use the same
`~/.claude` and `~/.claude.json`, so settings, plugins, skills, `CLAUDE.md`, MCP servers, project
trust and history are shared and live: a change made in one shows up in the other. Usage limits,
billing and Remote Control go to whichever account each command is logged in as.

## Legal use only

Use claude-profile only with Claude accounts you own or are authorized to use, and only in ways
your Anthropic plan's terms allow. It does not share, pool or resell access, and it must not be used
to let other people use your account or to get around usage limits or other protections. You are
responsible for how you use it. claude-profile is not affiliated with or endorsed by Anthropic, and
it is provided as is, without warranty (see [LICENSE](LICENSE)).

## How it works

`claude-work` is a three-line wrapper that runs your normal `claude` with
`CLAUDE_SECURESTORAGE_CONFIG_DIR` set to `~/.claude-profiles/work`. That variable changes only where
Claude Code keeps the login:

- macOS: a separate Keychain entry, `Claude Code-credentials-<first 8 hex digits of the SHA-256 of
  that folder>`.
- Linux and Windows: `~/.claude-profiles/work/.credentials.json` instead of
  `~/.claude/.credentials.json`.

The documented `CLAUDE_CONFIG_DIR` also gives a separate login, but it moves settings, plugins and
history too, so the two accounts stop sharing a setup.

## Caveats

- **`CLAUDE_SECURESTORAGE_CONFIG_DIR` is internal to Claude Code and not documented.** A release
  could rename or drop it. If that happened, `/login` in a profile would replace your main login.
  `add` refuses a Claude Code build that doesn't contain the variable, and undoes itself if the new
  command already reports a login before you've signed in to it. `doctor` repeats that check and
  confirms the profile and `claude` are signed in as different accounts. Run `doctor` after
  Claude Code updates.
- **Tested on macOS with Claude Code 2.1.330.** Linux and Windows support is read from Claude
  Code's source, not run. The wrapper is a POSIX shell script, so on Windows it needs WSL or Git
  Bash.
- **Anything that reads the cached account shows the wrong one.** `/status`, and the account email
  Claude Code passes to the model, come from `oauthAccount` in the shared `~/.claude.json`, which
  names whichever account logged in last. Inference, usage limits and Remote Control use each
  command's own login and are not affected. If you use claude-tui-line, its `email` and `organization`
  status-line items show each session's real account.
- **Check your plan's terms.** Anthropic's consumer terms forbid sharing a login with someone else.
  Holding a personal and a work account yourself is not addressed there.

## Commands

| Command | What it does |
|---|---|
| `add <name>` | Create `claude-<name>` in `~/.local/bin` and a private folder for its login. Never overwrites a command it didn't create; `profile` is reserved. |
| `list` | Show the profiles this tool created. |
| `doctor <name>` | Check the Claude Code version, that the variable is supported, that the profile has its own stored login, and that it belongs to a different account from `claude`. |
| `remove [-y] <name>` | Delete `claude-<name>` and the login stored for that profile only. Your main login is never touched. |

`doctor` sends each login's access token to `api.anthropic.com/api/oauth/profile` to learn its
email. The token is passed to `curl` on stdin, not on the command line.

Set `CLAUDE_PROFILES_HOME` or `CLAUDE_PROFILES_BIN` to change where profiles and commands go.

## Documentation

A one-page guide is in [docs/index.html](docs/index.html).

## Install

```sh
cp claude-profile ~/.local/bin/ && chmod +x ~/.local/bin/claude-profile
```

## Tests

```sh
sh tests/run.sh
```

The tests use a fake `claude` and a throwaway `HOME`; they make no network calls and touch no real
logins.
