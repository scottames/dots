local M = {}

local uv = vim.uv or vim.loop

local function join(...)
  return table.concat({ ... }, "/")
end

local function is_dir(path)
  local stat = uv.fs_stat(path)
  return stat and stat.type == "directory"
end

local function mtime(path)
  local stat = uv.fs_stat(path)
  return stat and stat.mtime and stat.mtime.sec or 0
end

local function add_if_dir(roots, root, name)
  if is_dir(join(root, "thoughts", name)) then
    roots[#roots + 1] = join("thoughts", name)
  end
end

function M.roots(root, user)
  local thoughts = join(root, "thoughts")
  if not is_dir(thoughts) then
    return {}
  end

  if user and user ~= "" then
    local roots = {}
    add_if_dir(roots, root, user)
    add_if_dir(roots, root, "shared")
    add_if_dir(roots, root, "global")
    return roots
  end

  local users = {}
  local scan = uv.fs_scandir(thoughts)
  if not scan then
    return {}
  end

  while true do
    local name = uv.fs_scandir_next(scan)
    if not name then
      break
    end
    if name ~= "shared" and name ~= "global" and name ~= "searchable" and not vim.startswith(name, ".") then
      if is_dir(join(thoughts, name)) then
        users[#users + 1] = name
      end
    end
  end

  table.sort(users)

  local roots = {}
  for _, name in ipairs(users) do
    roots[#roots + 1] = join("thoughts", name)
  end
  add_if_dir(roots, root, "shared")
  add_if_dir(roots, root, "global")
  return roots
end

function M.open()
  local root = LazyVim.root.get({ normalize = true })
  local roots = M.roots(root)
  if #roots == 0 then
    vim.notify("No thts editable roots found", vim.log.levels.WARN, { title = "Thoughts" })
    return
  end

  Snacks.picker.files({
    cwd = root,
    dirs = roots,
    hidden = true,
    ignored = true,
    matcher = { sort_empty = true },
    sort = { fields = { "score:desc", "mtime:desc", "idx" } },
    title = "Thoughts",
    transform = function(item)
      item.mtime = mtime(join(root, item.file or item.text))
    end,
  })
end

return M
