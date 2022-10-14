local api = vim.api

api.nvim_create_user_command("Gql", function()
  require("gql").connect("https://countries.trevorblades.com")
  require("gql").run()
end, {})
