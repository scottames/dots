import { afterEach, describe, expect, test } from "bun:test";

import { zellijStatusPlugin } from "./zellij-status.js";

const originalHome = process.env.HOME;

afterEach(() => {
  process.env.HOME = originalHome;
});

const createShell =
  (calls) =>
  async (strings, ...values) => {
    calls.push({ strings: [...strings], values });
  };

describe("zellijStatusPlugin", () => {
  test("notifies waiting when tui prompt append hook fires", async () => {
    process.env.HOME = "/tmp/test-home";
    const calls = [];
    const plugin = await zellijStatusPlugin({ $: createShell(calls) });

    await plugin["tui.prompt.append"]();

    expect(calls).toHaveLength(1);
    expect(calls[0].values).toEqual([
      "/tmp/test-home/.local/bin/zellij-status-notify",
      "waiting",
    ]);
  });

  test("notifies waiting when generic event receives tui prompt append", async () => {
    process.env.HOME = "/tmp/test-home";
    const calls = [];
    const plugin = await zellijStatusPlugin({ $: createShell(calls) });

    await plugin.event({ event: { type: "tui.prompt.append" } });

    expect(calls).toHaveLength(1);
    expect(calls[0].values).toEqual([
      "/tmp/test-home/.local/bin/zellij-status-notify",
      "waiting",
    ]);
  });
});
