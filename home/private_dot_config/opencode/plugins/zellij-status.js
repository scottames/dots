export const zellijStatusPlugin = async ({ $ }) => {
  const notifier = `${process.env.HOME}/.local/bin/zellij-status-notify`;

  const notify = async (state) => {
    try {
      await $`${notifier} ${state}`;
    } catch {}
  };

  const handleEventType = async (type) => {
    if (type === "permission.asked") {
      await notify("waiting");
    }

    if (type === "session.idle" || type === "permission.replied") {
      await notify("completed");
    }
  };

  const statusIndicatesIdle = (input) => {
    const status =
      input?.status ??
      input?.session?.status ??
      input?.event?.data?.status ??
      input?.event?.status;

    return status === "idle";
  };

  return {
    "permission.asked": async () => {
      await notify("waiting");
    },
    "permission.updated": async () => {
      await notify("waiting");
    },
    "permission.replied": async () => {
      await notify("completed");
    },
    "session.idle": async () => {
      await notify("completed");
    },
    "session.status": async (input) => {
      if (statusIndicatesIdle(input)) {
        await notify("completed");
      }
    },
    event: async ({ event }) => {
      await handleEventType(event.type);

      if (event.type === "session.status" && statusIndicatesIdle(event)) {
        await notify("completed");
      }
    },
  };
};
