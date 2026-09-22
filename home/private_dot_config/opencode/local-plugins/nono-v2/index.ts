import type { Plugin } from "@opencode/plugin";
import { readFile } from "node:fs/promises";

// Temporary V2 integration: https://github.com/nolabs-ai/nono-packs/issues/31
// The pack still owns its profile/skill and V1 plugin symlink. Its V1 load warning
// is expected until upstream ships V2 support; remove this plugin/config then.

type Caps = {
  fs: Array<{ path: string; resolved?: string; access: string }>;
  net_blocked: boolean;
  allowed_domains?: string[];
  deny_paths?: string[];
  credentials?: Record<string, unknown>;
  session_id?: string;
};

async function readCaps(): Promise<Caps | undefined> {
  const file = process.env.NONO_CAP_FILE;
  if (!file) return;
  try {
    const caps: Caps = JSON.parse(await readFile(file, "utf8"));
    if (
      !Array.isArray(caps.fs) ||
      caps.fs.some(
        (entry) =>
          typeof entry.path !== "string" ||
          typeof entry.access !== "string" ||
          (entry.resolved !== undefined && typeof entry.resolved !== "string"),
      ) ||
      typeof caps.net_blocked !== "boolean"
    )
      return;
    for (const paths of [caps.allowed_domains, caps.deny_paths]) {
      if (
        paths !== undefined &&
        (!Array.isArray(paths) ||
          paths.some((path) => typeof path !== "string"))
      )
        return;
    }
    if (
      caps.credentials !== undefined &&
      (!caps.credentials ||
        typeof caps.credentials !== "object" ||
        Array.isArray(caps.credentials))
    )
      return;
    if (caps.session_id !== undefined && typeof caps.session_id !== "string")
      return;
    return caps;
  } catch {
    return;
  }
}

function network(caps: Caps): string {
  if (caps.net_blocked) return "outbound blocked";
  if (caps.allowed_domains?.length)
    return `host allowlist: ${caps.allowed_domains.join(", ")}`;
  return "no host restrictions reported";
}

const unavailable =
  "Nono capability state unavailable: NONO_CAP_FILE is missing, unreadable, or invalid. Do not infer grants or diagnose a denial from it.";

async function status(): Promise<string> {
  const caps = await readCaps();
  if (!caps) return unavailable;
  const routes = caps.credentials && Object.keys(caps.credentials);
  return [
    "Nono reported configuration (not independent verification of enforcement):",
    `Session: ${caps.session_id ?? process.env.NONO_SESSION_ID ?? "not reported"}`,
    `Network: ${network(caps)}`,
    "Filesystem grants:",
    ...caps.fs.map(
      (entry) => `  ${entry.resolved ?? entry.path} (${entry.access})`,
    ),
    ...(caps.fs.length ? [] : ["  (none reported)"]),
    "Filesystem denies:",
    ...(caps.deny_paths?.length
      ? caps.deny_paths.map((path) => `  ${path}`)
      : ["  (none reported)"]),
    `Credential route names: ${routes ? routes.join(", ") || "none reported" : "not reported"}`,
    "Credential values and injection health are not inspected.",
    "For path-specific decisions, load the nono-sandbox skill and use nono why.",
  ].join("\n");
}

export default {
  id: "local.nono",
  async setup(ctx) {
    if (!process.env.NONO_CAP_FILE) return;

    await ctx.session.hook("context", async (event) => {
      const caps = await readCaps();
      event.system.push({
        type: "text",
        text: [
          "# Nono sandbox context",
          "NONO_CAP_FILE is set for this server. Nono supplies the OS-level sandbox; this plugin reports configuration only.",
          caps ? `Reported network policy: ${network(caps)}.` : unavailable,
          "Use nono_status for reported grants and session information. Load the nono-sandbox skill before diagnosing permission or network failures.",
          "Generic EPERM/EACCES or permission-denied text does not confirm a nono denial. Use nono why --self with the concrete path and required operation; a failed diagnostic is not a DENIED result.",
          "Do not attempt to bypass a confirmed sandbox boundary. Follow the skill for diagnosis and user-approved remediation, preserving the actual launch profile.",
        ].join("\n"),
      });
    });

    await ctx.tool.transform((editor) => {
      editor.add({
        name: "nono_status",
        description:
          "Read nono's reported filesystem/network configuration and session ID. Does not verify enforcement or credential injection.",
        options: { codemode: false },
        input: { type: "object", properties: {}, additionalProperties: false },
        async execute() {
          return { content: await status() };
        },
      });
    });
  },
} satisfies Plugin.Plugin;
