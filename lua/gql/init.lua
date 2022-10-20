local async = require("gql.async")
local commands = require("gql.commands")

local curl = commands.curl
local jq = commands.jq

local api, fn = vim.api, vim.fn
local json = vim.json

local bufname = "grapqhl://results"

local M = {}

local function get_current_buffer()
  local lines = api.nvim_buf_get_lines(0, 0, -1, false)
  return table.concat(lines, "\n")
end

local function show_result(result)
  local output = vim.split(result, "\n")

  local input_win = api.nvim_get_current_win()
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
end

local run = async.void(function(input)
  local body = {
    query = input,
  }

  local out = curl.post(M.url, body)
  local res = jq.format(out)
  return res
end)

M.connect = function(url)
  M.url = url
end

api.nvim_create_user_command(
  "Gql",
  async.void(function()
    M.connect("https://countries.trevorblades.com")
    local contents = get_current_buffer()
    local result = run(contents)
    show_result(result)
  end),
  {}
)

api.nvim_create_user_command(
  "Schema",
  async.void(function()
    M.connect("https://countries.trevorblades.com")
    local contents = [[
  query IntrospectionQuery {
  __schema {
    queryType {
      name
    }
    mutationType {
      name
    }
    subscriptionType {
      name
    }
    types {
      ...FullType
    }
    directives {
      name
      description
      locations
      args {
        ...InputValue
      }
    }
  }
}

fragment FullType on __Type {
  kind
  name
  description
  fields(includeDeprecated: true) {
    name
    description
    args {
      ...InputValue
    }
    type {
      ...TypeRef
    }
    isDeprecated
    deprecationReason
  }
  inputFields {
    ...InputValue
  }
  interfaces {
    ...TypeRef
  }
  enumValues(includeDeprecated: true) {
    name
    description
    isDeprecated
    deprecationReason
  }
  possibleTypes {
    ...TypeRef
  }
}
fragment InputValue on __InputValue {
  name
  description
  type {
    ...TypeRef
  }
  defaultValue
}
fragment TypeRef on __Type {
  kind
  name
  ofType {
    kind
    name
    ofType {
      kind
      name
      ofType {
        kind
        name
        ofType {
          kind
          name
          ofType {
            kind
            name
            ofType {
              kind
              name
              ofType {
                kind
                name
              }
            }
          }
        }
      }
    }
  }
}
  ]]
    local result = run(contents)
    local out = json.decode(result)
    -- print("ceva")
    -- print(out.error)
    -- if out.error or out.data == vim.NIL or #out.data == 0 then
    --   print("error getting schema")
    -- end
    -- vim.pretty_print(out.data["__schema"].types)
    -- show_result(result)
  end),
  {}
)

return M
