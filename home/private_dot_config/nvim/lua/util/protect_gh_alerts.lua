#!/usr/bin/env lua
-- protect_gh_alerts.lua
--
-- Protect GitHub-style alert blocks from Prettier reformatting by wrapping
-- them in <!-- prettier-ignore-start --> / <!-- prettier-ignore-end --> comments.
--
-- This script is designed to be used as a stdin/stdout formatter with conform.nvim.
--
-- GitHub Alert Syntax:
--   > [!NOTE]
--   > Content here
--
-- Supported alert types: NOTE, TIP, IMPORTANT, WARNING, CAUTION
--
-- Reference: https://github.com/prettier/prettier/issues/15479

-- Configuration
local MAX_LINES = 10000
local ALERT_TYPES = { "NOTE", "TIP", "IMPORTANT", "WARNING", "CAUTION" }

-- Read all input
local content = io.read("*all")
if not content or content == "" then
  return
end

local lines = {}
for line in content:gmatch("([^\n]*)\n?") do
  table.insert(lines, line)
end

-- Remove trailing empty string from gmatch if present
if #lines > 0 and lines[#lines] == "" then
  table.remove(lines)
end

-- Performance check
if #lines > MAX_LINES then
  io.stderr:write(
    string.format("[protect_gh_alerts] Skipping large file (%d lines > %d threshold)\n", #lines, MAX_LINES)
  )
  io.write(content)
  return
end

-- Helper: check if line is alert start
local function is_alert_start(line)
  for _, alert_type in ipairs(ALERT_TYPES) do
    if line:match("^%s*>%s*%[!" .. alert_type .. "%]") then
      return true, alert_type
    end
  end
  return false, nil
end

-- Helper: check if already protected (look back up to 2 lines for prettier-ignore-start or prettier-ignore)
local function is_protected(output)
  local check_count = math.min(2, #output)
  for offset = 0, check_count - 1 do
    local idx = #output - offset
    if idx > 0 then
      local prev_line = output[idx]
      -- Match both prettier-ignore-start and prettier-ignore (for backwards compatibility)
      if
        prev_line:match("prettier%-ignore%-start")
        or prev_line:match("prettier%-ignore[^%-]")
        or prev_line:match("prettier%-ignore$")
      then
        return true
      end
      -- Stop at non-empty, non-whitespace line that isn't a blank line
      if prev_line:match("%S") and not prev_line:match("^%s*$") then
        break
      end
    end
  end
  return false
end

-- Process lines
local output = {}
local i = 1
local protected_count = 0

while i <= #lines do
  local line = lines[i]
  local is_alert, alert_type = is_alert_start(line)

  if is_alert then
    -- Check if already protected
    if is_protected(output) then
      -- Already protected, just copy lines
      table.insert(output, line)
      i = i + 1

      -- Copy remaining alert lines
      while i <= #lines and lines[i]:match("^%s*>") do
        table.insert(output, lines[i])
        i = i + 1
      end
    else
      -- Protect this alert block
      local indent = line:match("^(%s*)") or ""

      -- Insert ignore-start comment
      table.insert(output, indent .. "<!-- prettier-ignore-start -->")

      -- Copy alert start
      table.insert(output, line)
      local alert_start_line = i
      i = i + 1

      -- Copy all consecutive blockquote lines (including empty >)
      local last_alert_line = alert_start_line
      while i <= #lines and lines[i]:match("^%s*>") do
        table.insert(output, lines[i])
        last_alert_line = i
        i = i + 1
      end

      -- Insert end comment after the alert block
      table.insert(output, indent .. "<!-- prettier-ignore-end -->")

      -- Log protection
      protected_count = protected_count + 1
      io.stderr:write(
        string.format(
          "[protect_gh_alerts] Protected %s alert at line %d-%d\n",
          alert_type,
          alert_start_line,
          last_alert_line
        )
      )
    end
  else
    -- Regular line, just copy
    table.insert(output, line)
    i = i + 1
  end
end

-- Write output
io.write(table.concat(output, "\n"))

-- Ensure file ends with newline
if #output > 0 then
  io.write("\n")
end

-- Summary log
if protected_count > 0 then
  io.stderr:write(string.format("[protect_gh_alerts] Protected %d alert block(s)\n", protected_count))
end
