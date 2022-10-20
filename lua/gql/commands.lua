local job = require("gql.job")
local async = require("gql.async")

local json = vim.json

local M = {
  curl = {},
  jq = {},
}

M.curl.post = async.void(function(url, body)
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

M.jq.format = async.void(function(s)
  local obj = {
    cmd = "jq",
    args = { "." },
    writer = s,
  }
  local exit, stdout, stderr = job.start(obj)
  return stdout
end)

return M
