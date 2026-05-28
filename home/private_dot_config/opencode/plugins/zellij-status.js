export const zellijStatusPlugin = async ({ $ }) => {
  const notifier = `${process.env.HOME}/.local/bin/zellij-status-notify`;

  const notify = async (state) => {
    try {
      await $`${notifier} ${state}`;
    } catch {}
  };

  const handleEventType = async (type) => {
    if (
      type === "permission.asked" ||
      type === "permission.updated" ||
      type === "question.asked" ||
      type === "tui.prompt.append"
    ) {
      await notify("waiting");
    }

    if (
      type === "permission.replied" ||
      type === "question.replied" ||
      type === "question.rejected"
    ) {
      await notify("clear");
    }

    if (type === "session.idle") {
      await notify("completed");
    }
  };

  const statusType = (input) => {
    const status =
      input?.properties?.status ??
      input?.status ??
      input?.session?.status ??
      input?.event?.properties?.status ??
      input?.event?.data?.status ??
      input?.event?.status;

    if (typeof status === "string") {
      return status;
    }

    if (status && typeof status === "object") {
      return status.type;
    }

    return undefined;
  };

  const statusIndicatesIdle = (input) => {
    return statusType(input) === "idle";
  };

  return {
    "permission.asked": async () => {
      await notify("waiting");
    },
    "permission.updated": async () => {
      await notify("waiting");
    },
    "permission.replied": async () => {
      await notify("clear");
    },
    "question.asked": async () => {
      await notify("waiting");
    },
    "question.replied": async () => {
      await notify("clear");
    },
    "question.rejected": async () => {
      await notify("clear");
    },
    "tui.prompt.append": async () => {
      await notify("waiting");
    },
    "session.idle": async () => {
      await notify("completed");
    },
    "session.status": async (input) => {
      if (statusIndicatesIdle(input)) {
        await notify("completed");
      }
    },
    event: async ({ event } = {}) => {
      await handleEventType(event?.type);

      if (event?.type === "session.status" && statusIndicatesIdle(event)) {
        await notify("completed");
      }
    },
  };
};
