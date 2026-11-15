# Headless Session Bridge

This addon lets a separate Godot headless process discover and send a small,
authenticated set of commands to the already-running graphical editor for this
project. The headless process never starts, replaces, or captures a second
editor instance.

## Enablement

The addon is enabled in `project.godot` under `[editor_plugins]`.

When the graphical editor opens, the addon:

1. Starts a TCP listener bound only to `127.0.0.1`.
2. Creates a per-editor random token and writes a discovery record to
   `user://headless_bridge.json`.
3. Publishes the project fingerprint, protocol version, port and editor PID.
4. Removes its own discovery record when the plugin exits.

The record is intentionally local to the machine. It is not a network
rendezvous service; remote machines require a separately designed secure
transport and explicit network policy.

## One-shot operator

From the project directory:

```sh
godot --headless --path . --script res://tools/headless_bridge/bridge_probe.gd -- ping
godot --headless --path . --script res://tools/headless_bridge/bridge_probe.gd -- show_test_marker
godot --headless --path . --script res://tools/headless_bridge/bridge_probe.gd -- clear_test_marker
```

Only the allowlisted commands `ping`, `show_test_marker` and
`clear_test_marker` are accepted. Requests are JSON lines containing the
protocol version, project fingerprint and random session token. No arbitrary
GDScript, shell commands or eval payloads are accepted.

## Persistent discovery and reconnect

Run a separate process:

```sh
godot --headless --path . --script res://tools/headless_bridge/session_watcher.gd
```

The watcher polls the project's discovery record, authenticates with the
current editor session, sends a heartbeat every second, and returns to
discovery when the editor disappears or stops responding. If the editor is
reopened, it reads the new session token and reconnects. Stop the watcher with
Ctrl+C or by terminating its process.

The current plugin intentionally supports one active TCP peer at a time. Use
the persistent watcher as the session owner; do not run it simultaneously with
the one-shot probe while it holds the connection. A future command broker can
multiplex interactive commands over that same authenticated connection.

## Boundaries

- Localhost only; no public listener.
- Project fingerprint and random token are both checked.
- Protocol is newline-delimited JSON with a version field.
- No arbitrary code execution.
- Idle peer connections are closed after five seconds without traffic.
- Current proof commands change only a temporary editor dock label; they do
  not edit or save game scenes or resources.
- The bridge is an experimental QA/operator interface, not a production
  remote-control or multi-user service.
