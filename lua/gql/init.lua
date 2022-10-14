local async = require("gql.async")
local query = require("gql.query")

local api, fn = vim.api, vim.fn

local bufname = "grapqhl://results"

local M = {}

M.run = async.void(function()
  local input_win = api.nvim_get_current_win()

  local input = api.nvim_buf_get_lines(0, 0, -1, false)
  local body = {
    query = table.concat(input, "\n"),
  }

  local out = query.post(M.url, body)
  local res = query.format(out)
  async.scheduler()

  local output = vim.split(res, "\n")

  local buf = fn.bufnr(bufname)
  if buf == -1 then
    vim.cmd("vsplit")
    local win = api.nvim_get_current_win()
    buf = api.nvim_create_buf(true, true)

    api.nvim_win_set_buf(win, buf)
    api.nvim_buf_set_lines(buf, 0, -1, false, output)
    api.nvim_buf_set_name(buf, bufname)
    api.nvim_buf_set_option(buf, "filetype", "json")
    api.nvim_buf_set_option(buf, "bufhidden", "wipe")
    api.nvim_buf_set_option(buf, "modifiable", false)
  else
    api.nvim_buf_set_option(buf, "modifiable", true)
    api.nvim_buf_set_lines(buf, 0, -1, false, output)
    api.nvim_buf_set_option(buf, "modifiable", false)
  end

  api.nvim_set_current_win(input_win)
end)

M.connect = function(url)
  M.url = url
end

api.nvim_create_user_command("Gql", function()
  M.connect("https://countries.trevorblades.com")
  M.run()
end, {})

return M
