local Commands = {}
Commands.__index = Commands

function Commands.new(app_manager)
  local self = setmetatable({}, Commands)
  self.app_manager = app_manager
  return self
end

function Commands:register()
  vim.api.nvim_create_user_command("NeoSqlConnect", function(opts)
    local connection_string = opts.args
    if connection_string == "" then
      connection_string = vim.fn.input("Connection string: ", "", "file")
      if connection_string == "" then
        vim.notify("Connection cancelled", vim.log.levels.WARN)
        return
      end
    end

    local ok, err = self.app_manager:connect(connection_string)
    if not ok then
      vim.notify("Failed to connect: " .. tostring(err), vim.log.levels.ERROR)
      return
    end

    vim.notify("Connected successfully", vim.log.levels.INFO)
    self.app_manager:open()
  end, {
    nargs = "?",
    desc = "Connect to PostgreSQL database using connection string and open views",
    complete = "file",
  })

  vim.api.nvim_create_user_command("NeoSqlOpen", function()
    if not self.app_manager:is_connected() then
      vim.notify("Not connected to database. Use :NeoSqlConnect first", vim.log.levels.ERROR)
      return
    end

    self.app_manager:open()
  end, {
    desc = "Open neosql views (table list, query, result)",
  })

  vim.api.nvim_create_user_command("NeoSqlClose", function()
    self.app_manager:close()
    vim.notify("Neosql views closed", vim.log.levels.INFO)
  end, {
    desc = "Close neosql views",
  })

  vim.api.nvim_create_user_command("NeoSqlDisconnect", function()
    self.app_manager:disconnect()
    vim.notify("Disconnected from database", vim.log.levels.INFO)
  end, {
    desc = "Disconnect from PostgreSQL database",
  })

  vim.api.nvim_create_user_command("NeoSqlProjectSave", function(opts)
    local name = opts.args
    if name == "" then
      name = vim.fn.input("Project name: ", "")
      if name == "" then
        vim.notify("Project name is required", vim.log.levels.ERROR)
        return
      end
    end

    local connection_string = vim.fn.input("Connection string: ", "", "file")
    if connection_string == "" then
      vim.notify("Connection string is required", vim.log.levels.ERROR)
      return
    end

    local ok, err = self.app_manager.project_manager:save_project(name, connection_string)
    if not ok then
      vim.notify("Failed to save project: " .. tostring(err), vim.log.levels.ERROR)
      return
    end

    vim.notify("Project '" .. name .. "' saved successfully", vim.log.levels.INFO)
  end, {
    nargs = "?",
    desc = "Save a connection string as a named project",
  })

  vim.api.nvim_create_user_command("NeoSqlProjectLoad", function(opts)
    local name = opts.args
    if name == "" then
      local projects = self.app_manager.project_manager:list_projects()
      if #projects == 0 then
        vim.notify("No projects saved. Use :NeoSqlProjectSave to save one first.", vim.log.levels.WARN)
        return
      end
      
      name = vim.fn.input("Project name: ", "")
      if name == "" then
        vim.notify("Project name is required", vim.log.levels.ERROR)
        return
      end
    end

    local connection_string, err = self.app_manager.project_manager:get_project(name)
    if err then
      vim.notify("Failed to load project: " .. tostring(err), vim.log.levels.ERROR)
      return
    end

    local ok, connect_err = self.app_manager:connect(connection_string)
    if not ok then
      vim.notify("Failed to connect: " .. tostring(connect_err), vim.log.levels.ERROR)
      return
    end

    vim.notify("Connected to project '" .. name .. "' successfully", vim.log.levels.INFO)
    self.app_manager:open()
  end, {
    nargs = "?",
    desc = "Load and connect to a saved project by name",
    complete = function(arg_lead, cmd_line, cursor_pos)
      local projects = self.app_manager.project_manager:list_projects()
      local matches = {}
      for _, name in ipairs(projects) do
        if name:match("^" .. vim.pesc(arg_lead)) then
          table.insert(matches, name)
        end
      end
      return matches
    end,
  })

  vim.api.nvim_create_user_command("NeoSqlProjectList", function()
    local projects = self.app_manager.project_manager:list_projects()
    if #projects == 0 then
      vim.notify("No projects saved. Use :NeoSqlProjectSave to save one.", vim.log.levels.INFO)
      return
    end

    local message = "Saved projects:\n"
    for _, name in ipairs(projects) do
      message = message .. "  - " .. name .. "\n"
    end
    vim.notify(message, vim.log.levels.INFO)
  end, {
    desc = "List all saved projects",
  })

  vim.api.nvim_create_user_command("NeoSqlProjectDelete", function(opts)
    local name = opts.args
    if name == "" then
      name = vim.fn.input("Project name to delete: ", "")
      if name == "" then
        vim.notify("Project name is required", vim.log.levels.ERROR)
        return
      end
    end

    local ok, err = self.app_manager.project_manager:delete_project(name)
    if not ok then
      vim.notify("Failed to delete project: " .. tostring(err), vim.log.levels.ERROR)
      return
    end

    vim.notify("Project '" .. name .. "' deleted successfully", vim.log.levels.INFO)
  end, {
    nargs = "?",
    desc = "Delete a saved project",
    complete = function(arg_lead, cmd_line, cursor_pos)
      local projects = self.app_manager.project_manager:list_projects()
      local matches = {}
      for _, name in ipairs(projects) do
        if name:match("^" .. vim.pesc(arg_lead)) then
          table.insert(matches, name)
        end
      end
      return matches
    end,
  })
end

return Commands


