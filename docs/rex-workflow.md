# Rex trial: Herdr keys, direct host jumps

**Experimental and opt-in:** Rex is being tested, not replacing the stable
Ghostty + Herdr setup. Their app/tool ownership, bootstrap entries and dotfiles
remain in place; switching back requires no uninstall or configuration rewrite.
No default-terminal setting, app restart or remote session is changed by these
repository checks.

Open the Rex app directly, rather than nesting Herdr/tmux in a Rex terminal.
A Herdr workspace maps to a Rex session; tabs and panes retain their meaning.
Herdr and tmux remain available and their configurations are unchanged.

## Fast local/remote workflow

| Shortcut | Action |
| --- | --- |
| Cmd-Option-1 | Go to local work |
| Cmd-Option-2 | Go to remote work |
| Cmd-Option-Shift-1 / 2 | Create and open a new local / remote session |
| Ctrl-S, L / F | Same local / remote jumps using the familiar prefix |
| Ctrl-S, Shift-L / Shift-F | New local / remote session |
| Ctrl-S, Tab | Rex's native host switcher |
| Ctrl-S, W or S | Rex's native session picker |
| Ctrl-S, Enter | New session on the host currently selected in Rex |

The direct jumps use live session IDs, not hardcoded session names. They prefer
an existing session from that app client's shortcut history, then the first
session on the chosen server. They create a shell only when that server has no
sessions. The explicit New shortcuts always create one new session. A failed
remote connection is an error, never a fallback to local work.

History is in memory and resets on config reload. It records the session you
leave when invoking a direct jump, not every mouse click or native picker
selection. New remote shells start with the remote server's default directory;
a path from the workstation is never passed to the remote host.

Both hosts must already be reachable and added to Rex for native cross-host
`session.select` to work. On the current beta the GUI host list and CLI list
may differ; verify the host in the app as well as with `rex hosts`. A successful
CLI session creation alone does not show the session in the app.

## Familiar keys

Press Ctrl-S, release, then the following key:

| Key | Action |
| --- | --- |
| H / V | Split right / down |
| C | New tab |
| P / Shift-N | Previous / next tab |
| 1–9 | Select tab |
| comma | Rename tab |
| & | Close tab and its panes |
| N / B | Next / previous session |
| W / S / G / Q | Session picker (G/Q are not Herdr's pane-level goto) |
| + or Enter | New session on the selected host |
| Shift-W or $ | Rename session |
| arrows | Focus an adjacent pane |
| O | Next pane |
| Shift-K / Shift-J, or { / } | Move pane up / down (not an exact Herdr swap) |
| X | Close pane |
| Z | Zoom pane |
| Shift-R | Resize mode: arrows or H/J/K/L; Shift takes larger steps |
| Shift-B | Toggle sidebar |
| Shift-S | Settings |
| R | Reload config |
| ? | Rex command palette, not Herdr's keybinding help |
| D | Close the app window/viewer; do not close the session |
| Ctrl-S | Send a literal Ctrl-S to the terminal |

In resize mode, `=` balances splits; Enter or Escape leaves the mode. Unbound
keys are blocked so they cannot accidentally type into a terminal.

Symbol shortcuts above use their US-layout unshifted spelling in Lua (`+` is
`shift+=`, `?` is `shift+/`). Use letter/Enter alternatives on other layouts or
adjust those few bindings. Rex's native Cmd shortcuts are not removed.

## Rex extras

| Prefix key | Action |
| --- | --- |
| Shift-O | Toggle Rex's activity sidebar view |
| E | Browse directories / go to directory |
| Shift-P | Browse and insert a path |
| Shift-Z | Float/dock a pane |

There is no invented equivalent for Herdr's Ctrl-S `[` copy mode or Ctrl-S `;`
last-used pane. Use native selection/copy/scrollback and pane navigation.
Activity view is not Herdr's jump-to-notification action or priority-sorted
agent dashboard. Keep those distinctions in mind when testing a real project.

The command palette (Cmd-Shift-P) retains access to the rest of Rex: themes,
web sessions, device pairing, host management, and other native actions.
Agent setup is separate: preview with `rex skill setup --dry-run`, then use
`rex skill setup` on each host where you want agent integration. This can
modify agent settings/hooks, so it is not run by public bootstrap.

## Configuration and personal host targets

The public layer manages only `~/.config/rex/init.lua`, not the whole directory.
It optionally loads `local.lua` beside the configured main file. With no private
file, ordinary keybindings work. Direct local jumps also need `rex` on the
server's PATH (or `cli_bin` configured below); remote jumps require a target.

On the workstation, a personal `~/.config/rex/local.lua` can contain:

```lua
return {
    cli_bin = os.getenv("HOME") .. "/Library/Application Support/"
        .. "com.superlogical.rex/RexServer/Versions/Current/Rex Server.app/Contents/MacOS/rex",
    workstation = "self",
    remote = "https://remote.example.ts.net",
}
```

`cli_bin` uses the macOS app's stable `Current` symlink, not a versioned path.
Set it to the installed Rex executable on other platforms. Prefer explicit
endpoints for direct jumps so renaming a saved host cannot break the shortcut.
`self` means the server local to the machine executing this configuration, not
the host currently selected in the GUI. An explicit local Unix socket endpoint
also works and removes any ambiguity when multiple Rex servers are installed.

On the remote machine the same public config can reverse the targets:

```lua
return {
    -- Set cli_bin as above if rex is not on this server's PATH.
    workstation = "https://workstation.example.ts.net",
    remote = "self",
}
```

An optional `hosts` list is passed to `rex.host` to declare saved hosts; when
reusing one, retain its existing ID/label to avoid duplicate entries. A stored
host can override a declaration with the same ID. Direct endpoint jumps do not
depend on those labels.

Keep real endpoint names and machine-specific host IDs out of this public
repository. Private files contain no credentials. Existing Tailscale login
state stays with Rex/Tailscale; do not use anonymous HTTP listeners.

The public dotfile is symlinked on the workstation. A machine without this
checkout can use a copy of `init.lua`; future changes must be copied there too.

Validate and reload **on the machine that owns the config**, without restarting
its server:

```sh
rex config check
rex config reload
```

Custom shortcut actions invoked by a person in Rex queue the native
`session.select` action. To invoke/test them from an agent or CLI, enable
**Rex Settings → Rex Server → Remote Control**, then choose the app client:

```sh
rex client ls
rex -C CLIENT do go_remote
rex -C CLIENT do go_workstation
```

Direct actions call the installed CLI with an explicit target and clear its
inherited `REX_SERVER`, `REX_SESSION`, `REX_BLOCK`, and `REX_CLIENT`. This avoids
Rex's request-scoped server aliases and prevents a focused remote session from
changing what the Local shortcut means. No shell interprets the arguments.

A CLI request normally uses its terminal's inherited session context, not
necessarily the session currently visible in the app. For shortcut-history
tests, use `-s` with a session belonging to the CLI's target server. Native key
invocations supply their actual UI context.

## Verification

`tests/rex-config-contract.lua` exercises key mappings, per-client history,
closed-session fallback, empty-host creation, explicit New, reversed targets,
and connection/create failures with a mocked Rex runtime. It never touches a
real Rex server or reads personal host configuration. `rex config check` and a
live keymap check against the app's action schemas complement the unit tests.

Documentation: [keys](https://www.superlogical.com/rex/docs/customize/key-sequences),
[modes](https://www.superlogical.com/rex/docs/customize/key-modes),
[actions](https://www.superlogical.com/rex/docs/customize/actions), and
[Lua API](https://www.superlogical.com/rex/docs/reference/lua).
