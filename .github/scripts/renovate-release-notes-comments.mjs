export const markerPrefix = "renovate-release-notes-comment:v1";
export const defaultMaxCommentChars = 60000;
export const defaultMaxComments = 50;

export function buildCommentBodies(sections, options = {}) {
  const maxCommentChars = options.maxCommentChars ?? defaultMaxCommentChars;
  const maxComments = options.maxComments ?? defaultMaxComments;
  const chunkLimit = maxCommentContentChars(maxCommentChars, maxComments);
  const chunks = [];
  let current = "";

  for (const section of sections) {
    if (section.length > chunkLimit) {
      throw new Error("section exceeds GitHub comment size limit");
    }
    const next = current ? `${current}\n\n${section}` : section;
    if (current && next.length > chunkLimit) {
      chunks.push(current);
      current = section;
    } else {
      current = next;
    }
  }

  if (current) {
    chunks.push(current);
  }

  if (chunks.length > maxComments) {
    throw new Error(
      `release notes require ${chunks.length} comments, limit is ${maxComments}`,
    );
  }

  const total = chunks.length || 1;
  return (chunks.length ? chunks : ["No release notes were generated."]).map(
    (chunk, index) => {
      const marker = commentMarker(index + 1, total);
      const body = `${marker}\n${chunk}`;
      if (body.length > maxCommentChars) {
        throw new Error("comment exceeds GitHub comment size limit");
      }
      return body;
    },
  );
}

export function maxCommentContentChars(
  maxCommentChars = defaultMaxCommentChars,
  maxComments = defaultMaxComments,
) {
  const markerReserve = commentMarker(maxComments, maxComments).length + 1;
  return Math.max(1, maxCommentChars - markerReserve);
}

export async function upsertCommentBodies(
  api,
  issueNumber,
  bodies,
  options = {},
) {
  const maxMutations = options.maxMutations ?? defaultMaxComments;
  const managedAuthors = options.managedAuthors ?? ["github-actions[bot]"];
  const existing = await listReleaseNotesComments(
    api,
    issueNumber,
    managedAuthors,
  );
  const existingByPart = new Map(
    existing.map((comment) => [comment.part, comment]),
  );
  const mutations = [];

  for (let index = 0; index < bodies.length; index += 1) {
    const part = index + 1;
    const existingComment = existingByPart.get(part);
    if (existingComment) {
      if (existingComment.body !== bodies[index]) {
        mutations.push([
          "patch",
          `/issues/comments/${existingComment.id}`,
          { body: bodies[index] },
        ]);
      }
    } else {
      mutations.push([
        "post",
        `/issues/${issueNumber}/comments`,
        { body: bodies[index] },
      ]);
    }
  }

  for (const comment of existing) {
    if (comment.part > bodies.length) {
      mutations.push(["delete", `/issues/comments/${comment.id}`]);
    }
  }

  if (mutations.length > maxMutations) {
    throw new Error(
      `comment update requires ${mutations.length} mutations, limit is ${maxMutations}`,
    );
  }

  for (const [method, path, body] of mutations) {
    await api[method](path, body);
  }
}

function commentMarker(part, total) {
  return `<!-- ${markerPrefix} part=${part} total=${total} -->`;
}

async function listReleaseNotesComments(api, issueNumber, managedAuthors) {
  const comments = await api.getAll(`/issues/${issueNumber}/comments`, {
    per_page: 100,
  });
  const markerRegex = new RegExp(
    `<!-- ${markerPrefix} part=(\\d+) total=(\\d+) -->`,
  );
  return comments
    .map((comment) => {
      const match = markerRegex.exec(comment.body || "");
      if (!match) {
        return null;
      }
      if (!managedAuthors.includes(comment.user?.login)) {
        return null;
      }
      return { ...comment, part: Number(match[1]), total: Number(match[2]) };
    })
    .filter(Boolean);
}
