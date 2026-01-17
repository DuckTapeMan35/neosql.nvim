local ProjectManager = {}
ProjectManager.__index = ProjectManager

function ProjectManager.new()
  local self = setmetatable({}, ProjectManager)
  self.data_dir = vim.fn.stdpath("data") .. "/neosql"
  self.projects_file = self.data_dir .. "/projects.json"
  self.projects = {}
  self:_ensure_data_dir()
  self:_load_projects()
  return self
end

function ProjectManager:_ensure_data_dir()
  if vim.fn.isdirectory(self.data_dir) == 0 then
    vim.fn.mkdir(self.data_dir, "p")
  end
end

function ProjectManager:_load_projects()
  local file = io.open(self.projects_file, "r")
  if file then
    local content = file:read("*a")
    file:close()
    if content and content ~= "" then
      local ok, parsed = pcall(vim.json.decode, content)
      if ok and parsed then
        self.projects = parsed
      end
    end
  end
end

function ProjectManager:_save_projects()
  local file = io.open(self.projects_file, "w")
  if not file then
    return false, "Failed to open projects file for writing"
  end
  
  local json_content = vim.json.encode(self.projects)
  file:write(json_content)
  file:close()
  return true, nil
end

function ProjectManager:save_project(name, connection_string)
  if not name or name == "" then
    return false, "Project name is required"
  end
  
  if not connection_string or connection_string == "" then
    return false, "Connection string is required"
  end
  
  self.projects[name] = connection_string
  local ok, err = self:_save_projects()
  if not ok then
    return false, err
  end
  
  return true, nil
end

function ProjectManager:get_project(name)
  if not name or name == "" then
    return nil, "Project name is required"
  end
  
  local connection_string = self.projects[name]
  if not connection_string then
    return nil, "Project '" .. name .. "' not found"
  end
  
  return connection_string, nil
end

function ProjectManager:list_projects()
  local project_names = {}
  for name, _ in pairs(self.projects) do
    table.insert(project_names, name)
  end
  table.sort(project_names)
  return project_names
end

function ProjectManager:delete_project(name)
  if not name or name == "" then
    return false, "Project name is required"
  end
  
  if not self.projects[name] then
    return false, "Project '" .. name .. "' not found"
  end
  
  self.projects[name] = nil
  local ok, err = self:_save_projects()
  if not ok then
    return false, err
  end
  
  return true, nil
end

return ProjectManager
