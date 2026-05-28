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

  test("notifies waiting when question asked hook fires", async () => {
    process.env.HOME = "/tmp/test-home";
    const calls = [];
    const plugin = await zellijStatusPlugin({ $: createShell(calls) });

    await plugin["question.asked"]();

    expect(calls).toHaveLength(1);
    expect(calls[0].values).toEqual([
      "/tmp/test-home/.local/bin/zellij-status-notify",
      "waiting",
    ]);
  });

  test("notifies waiting when generic event receives question asked", async () => {
    process.env.HOME = "/tmp/test-home";
    const calls = [];
    const plugin = await zellijStatusPlugin({ $: createShell(calls) });

    await plugin.event({ event: { type: "question.asked" } });

    expect(calls).toHaveLength(1);
    expect(calls[0].values).toEqual([
      "/tmp/test-home/.local/bin/zellij-status-notify",
      "waiting",
    ]);
  });

  test("notifies waiting when generic event receives permission updated", async () => {
    process.env.HOME = "/tmp/test-home";
    const calls = [];
    const plugin = await zellijStatusPlugin({ $: createShell(calls) });

    await plugin.event({ event: { type: "permission.updated" } });

    expect(calls).toHaveLength(1);
    expect(calls[0].values).toEqual([
      "/tmp/test-home/.local/bin/zellij-status-notify",
      "waiting",
    ]);
  });

  test.each(["permission.replied", "question.replied", "question.rejected"])(
    "notifies clear when %s hook fires",
    async (eventType) => {
      process.env.HOME = "/tmp/test-home";
      const calls = [];
      const plugin = await zellijStatusPlugin({ $: createShell(calls) });

      await plugin[eventType]();

      expect(calls).toHaveLength(1);
      expect(calls[0].values).toEqual([
        "/tmp/test-home/.local/bin/zellij-status-notify",
        "clear",
      ]);
    },
  );

  test.each(["permission.replied", "question.replied", "question.rejected"])(
    "notifies clear when generic event receives %s",
    async (eventType) => {
      process.env.HOME = "/tmp/test-home";
      const calls = [];
      const plugin = await zellijStatusPlugin({ $: createShell(calls) });

      await plugin.event({ event: { type: eventType } });

      expect(calls).toHaveLength(1);
      expect(calls[0].values).toEqual([
        "/tmp/test-home/.local/bin/zellij-status-notify",
        "clear",
      ]);
    },
  );

  test("notifies completed when session idle hook fires", async () => {
    process.env.HOME = "/tmp/test-home";
    const calls = [];
    const plugin = await zellijStatusPlugin({ $: createShell(calls) });

    await plugin["session.idle"]();

    expect(calls).toHaveLength(1);
    expect(calls[0].values).toEqual([
      "/tmp/test-home/.local/bin/zellij-status-notify",
      "completed",
    ]);
  });

  test("notifies completed when session status is idle", async () => {
    process.env.HOME = "/tmp/test-home";
    const calls = [];
    const plugin = await zellijStatusPlugin({ $: createShell(calls) });

    await plugin["session.status"]({
      properties: { status: { type: "idle" } },
    });

    expect(calls).toHaveLength(1);
    expect(calls[0].values).toEqual([
      "/tmp/test-home/.local/bin/zellij-status-notify",
      "completed",
    ]);
  });

  test.each(["busy", "retry"])(
    "does not notify when session status is %s",
    async (statusType) => {
      process.env.HOME = "/tmp/test-home";
      const calls = [];
      const plugin = await zellijStatusPlugin({ $: createShell(calls) });

      await plugin["session.status"]({
        properties: { status: { type: statusType } },
      });

      expect(calls).toHaveLength(0);
    },
  );

  test("does not notify when session status payload is malformed", async () => {
    process.env.HOME = "/tmp/test-home";
    const calls = [];
    const plugin = await zellijStatusPlugin({ $: createShell(calls) });

    await plugin["session.status"]({ properties: {} });

    expect(calls).toHaveLength(0);
  });

  test("does not notify when generic event payload is missing", async () => {
    process.env.HOME = "/tmp/test-home";
    const calls = [];
    const plugin = await zellijStatusPlugin({ $: createShell(calls) });

    await plugin.event();

    expect(calls).toHaveLength(0);
  });

  test("generic session status uses SDK-shaped idle detection", async () => {
    process.env.HOME = "/tmp/test-home";
    const calls = [];
    const plugin = await zellijStatusPlugin({ $: createShell(calls) });

    await plugin.event({
      event: {
        type: "session.status",
        properties: { status: { type: "idle" } },
      },
    });

    expect(calls).toHaveLength(1);
    expect(calls[0].values).toEqual([
      "/tmp/test-home/.local/bin/zellij-status-notify",
      "completed",
    ]);
  });
});
