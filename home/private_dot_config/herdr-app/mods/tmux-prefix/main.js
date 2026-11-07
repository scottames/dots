// Adapted from herdrdev/herdr-layout-examples/tmux-prefix.
// Ctrl+B, then the old Herdr binding. Only navigation repeats.
import { View, div } from "gpui-kit";
import { v_flex, h_flex } from "gpui-base";
import {
  agents,
  closeOverlay,
  focused,
  hc,
  nextCommand,
  openOverlay,
  props,
  run,
  setShared,
  shared,
  theme,
} from "herdr";

const REPEAT_MS = 500;
const BINDINGS = [
  [",", "Settings", "app.settings"],
  ["q", "Minimize (terminals keep running)", "window.minimize"],
  ["g", "Command palette", "app.palette"],
  ["b", "Toggle sidebar", "layout.toggle", { id: "sidebar" }],
  ["z", "Zoom pane", "pane.zoom"],
  ["f", "Zoom pane", "pane.zoom"],
  ["shift+d", "Close space", "space.close"],
  ["shift+n", "New space", "space.new"],
  ["shift+w", "Rename space", "space.rename"],
  ["w", "Space picker", "mod.open", { name: "picker" }],
  ["shift+g", "New worktree", "@worktree", { action: "new" }],
  ["shift+o", "Open worktree", "@worktree", { action: "open" }],
  ["c", "New tab", "tab.new"],
  ["shift+t", "Rename tab", "tab.rename"],
  ["shift+x", "Close tab", "tab.close"],
  ["x", "Close pane", "pane.close"],
  ["\\", "Split right", "pane.split", { direction: "right" }],
  ["-", "Split down", "pane.split", { direction: "down" }],
  [
    "alt+g",
    "Git tab",
    "terminal.open",
    { argv: ["lazygit"], place: "tab", name: "git" },
  ],
  [
    "alt+r",
    "Review current change",
    "terminal.open",
    { argv: ["fish", "-lc", "tuicr-current auto"], place: "right" },
  ],
  ...[
    ["h", "left"],
    ["j", "down"],
    ["k", "up"],
    ["l", "right"],
  ].flatMap(([key, direction]) =>
    [key, direction].map((key) => [
      key,
      `Focus ${direction}`,
      "pane.go",
      { direction },
      true,
    ]),
  ),
  ...Array.from({ length: 9 }, (_, i) => [
    String(i + 1),
    `Tab ${i + 1}`,
    "tab.select",
    { index: i + 1 },
  ]),
  ...Array.from({ length: 9 }, (_, i) => [
    `shift+${i + 1}`,
    `Space ${i + 1}`,
    "space.select",
    { index: i + 1 },
  ]),
  ...Array.from({ length: 9 }, (_, i) => [
    `alt+${i + 1}`,
    `Agent ${i + 1} (space order)`,
    "@agent",
    { index: i + 1 },
  ]),
];

// Match physical Shift+digits as well as shifted text. Option can supply
// key_char characters on macOS; modified shortcuts use the base key instead.
function bindingKey(e) {
  const m = e.modifiers;
  if (!m.control && !m.alt && !m.platform && e.key_char === "?") return "?";
  let key = e.key.toLowerCase();
  key = { backslash: "\\", minus: "-", comma: "," }[key] ?? key;
  const digit = "!@#$%^&*(".indexOf(key);
  if (m.shift && digit >= 0 && key.length === 1) key = String(digit + 1);
  return `${m.control ? "ctrl+" : ""}${m.alt ? "alt+" : ""}${m.platform ? "cmd+" : ""}${m.shift ? "shift+" : ""}${key}`;
}

function forwardKey(e) {
  const m = e.modifiers;
  if (m.control || m.alt || m.platform) return null;
  const key = e.key_char ?? e.key;
  if (key === " ") return "space";
  if (/^[A-Z]$/.test(key)) return `shift+${key.toLowerCase()}`;
  if (
    key.length === 1 &&
    "abcdefghijklmnopqrstuvwxyz0123456789`\\[],=-.';/".includes(key)
  )
    return key === "\\" ? "backslash" : key;
  if (
    !m.shift &&
    [
      "enter",
      "tab",
      "backspace",
      "left",
      "right",
      "up",
      "down",
      "space",
    ].includes(e.key)
  )
    return e.key;
  return null;
}

function dispatch(command, args) {
  if (command === "@worktree") {
    const target = focused();
    openOverlay({
      mod: "worktree",
      props: { space: target?.space, ...args },
      kind: "dialog",
      width: 640,
      height: args.action === "open" ? 480 : 260,
    });
  } else if (command === "@agent") {
    const agent = agents()[args.index - 1];
    if (agent) run("agent.focus", { terminal: agent.address });
  } else {
    run(command, args);
  }
}

export default class TmuxPrefix extends View {
  init(_props, cx) {
    // Seed the old grouped view once; later choices in the app stay in effect.
    if (shared("agents.sort") == null) setShared("agents.sort", "grouped");
    this.handle = cx.focus_handle();
    this.handle.focus();
    this.repeat = false;
    this.generation = 0;
    this.all = false;
    cx.spawn(async (cx) => {
      for (;;) {
        const command = await nextCommand();
        if (command === "send-prefix") this.send("ctrl+b", cx);
      }
    });
  }

  dismiss() {
    closeOverlay(props().overlay);
  }

  send(key, cx) {
    this.generation++;
    const terminal = focused()?.terminal;
    if (!terminal) return this.dismiss();
    // Start hc before closing cancels this view's tasks (upstream pattern).
    const pending = hc(["keys", terminal, key]);
    cx.spawn(async () => {
      const result = await pending;
      if (result.code !== 0) console.log(`tmux-prefix: ${result.stderr}`);
    });
    this.dismiss();
  }

  key(e, cx) {
    cx.stop_propagation();
    if (e.key === "escape") return this.dismiss();
    const key = bindingKey(e);
    if (key === "ctrl+b") return this.send("ctrl+b", cx);
    if (key === "?") {
      this.all = !this.all;
      this.repeat = false;
      this.generation++;
      cx.notify();
      return;
    }
    const binding = BINDINGS.find((b) => b[0] === key);
    if (!binding) {
      const forwarded = this.repeat && forwardKey(e);
      if (forwarded) return this.send(forwarded, cx);
      return this.dismiss();
    }
    const [, , command, args = {}, repeatable = false] = binding;
    if (!repeatable) this.dismiss();
    dispatch(command, args);
    if (repeatable) {
      this.repeat = true;
      const generation = ++this.generation;
      cx.timer.after(REPEAT_MS, () => {
        if (this.generation === generation) this.dismiss();
      });
      cx.notify();
    }
  }

  render() {
    const t = theme();
    const rows = this.all
      ? BINDINGS
      : BINDINGS.filter(
          ([key]) =>
            !["left", "right", "up", "down"].includes(key) &&
            !/^(shift\+|alt\+)?\d$/.test(key),
        );
    return v_flex()
      .id("tmux-prefix")
      .track_focus(this.handle)
      .on_key_down((e, cx) => this.key(e, cx))
      .p(14)
      .gap(8)
      .bg(t.popover)
      .text_color(t.foreground)
      .text_size(12)
      .child(
        h_flex()
          .justify_between()
          .child(
            div()
              .font_semibold()
              .child(
                this.repeat
                  ? `Repeat · ${REPEAT_MS} ms`
                  : "Ctrl+B · waiting for a key",
              ),
          )
          .child(
            div().text_color(t.muted).child("Esc cancel · ^B send prefix"),
          ),
      )
      .child(
        v_flex()
          .h(280)
          .min_h(0)
          .overflow_y_scrollbar()
          .children(
            rows.map(([key, label, , , repeatable]) =>
              h_flex()
                .h(20)
                .flex_none()
                .items_center()
                .gap(12)
                .child(div().w(90).text_color(t.accent).child(key))
                .child(div().flex_1().child(label))
                .child(
                  div()
                    .text_color(t.dim)
                    .child(repeatable ? "repeat" : ""),
                ),
            ),
          ),
      )
      .child(
        div()
          .text_color(t.muted)
          .child(
            "1–9 tabs · Shift+1–9 spaces · Alt+1–9 agents · ? all bindings",
          ),
      );
  }
}
