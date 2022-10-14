local job = require("gql.job")
local async = require("gql.async")

local json = vim.json
local uv = vim.loop

local M = {}

M.post = async.void(function(url, body)
  local obj = {
    cmd = "curl",
    args = {
      "-X",
      "POST",
      "-H",
      "Accept: application/json",
      "-H",
      "Content-Type: application/json",
      "-d",
      json.encode(body),
      url,
    },
  }
  local exit, stdout, stderr = job.start(obj)
  return stdout
end)

M.format = async.void(function(s)
  local obj = {
    cmd = "jq",
    args = { "." },
    writer = s,
  }
  local exit, stdout, stderr = job.start(obj)
  return stdout
end)

local test = async.void(function()
  local body = { query = [[
    query {
      countries {
        name
      }
    }
    ]] }
  local url = "https://countries.trevorblades.com"
  local out = M.post(url, body)
  local res = M.format(out)
end)

return M
