local async = require("gql.async")

local uv = vim.loop

local M = {}

local function close_pipes(...)
  for _, pipe in ipairs({ ... }) do
    if not pipe:is_closing() then
      pipe:close()
    end
  end
end

local function read_stop_pipes(...)
  for _, pipe in ipairs({ ... }) do
    pipe:read_stop()
  end
end

local spawn = function(obj, cb)
  local stdout = uv.new_pipe()
  local stderr = uv.new_pipe()
  local stdin = nil
  if obj.writer then
    stdin = uv.new_pipe()
  end

  local stdout_data, stderr_data = {}, {}

  M.handle, _ = uv.spawn(obj.cmd, {
    args = obj.args,
    stdio = { stdin, stdout, stderr },
  }, function(code, _)
    M.handle:close()

    read_stop_pipes(stdout, stderr)
    close_pipes(stdout, stderr)

    local stdout_result = table.concat(stdout_data)
    local stderr_result = table.concat(stderr_data)

    cb(code, stdout_result, stderr_result)
  end)

  if not M.handle then
    close_pipes(stdout, stderr)
    error(("Failed to start the process: %s"):format(table.concat({ obj.cmd, unpack(obj.args) }, " ")))
  end

  stdout:read_start(function(_, data)
    table.insert(stdout_data, data)
  end)
  stderr:read_start(function(_, data)
    table.insert(stderr_data, data)
  end)
  if obj.writer then
    stdin:write(obj.writer, function()
      close_pipes(stdin)
    end)
  end
end

M.start = async.wrap(spawn, 2)

return M
