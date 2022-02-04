--- Return all characters of the string as an list-like table
---@private
local function split(str, pattern)
    local t = {}
    for v in string.gmatch(str, pattern) do
        t[#t + 1] = v
    end
    return t
end

--- Create a simple patter using arglead and then filter the options table/array against the pattern
---@private
local function simple_completion(arglead, _, _, options)
    local pattern = table.concat(split(arglead, "."), ".*")
    pattern = pattern:lower()
    return vim.tbl_filter(function(opt)
        return opt:lower():match(pattern) ~= nil
    end, options) or {}
end

--- Get a template for a particular filetype
---@param filetype string
---@return neogen.TemplateConfig|nil
local function get_template(filetype)
    if not neogen.configuration.languages[filetype] then
        return
    end

    if not neogen.configuration.languages[filetype].template then
        return
    end

    return neogen.configuration.languages[filetype].template
end

--- Builtin notify wrapper
---@param msg string
---@param log_level string or number
local function notify(msg, log_level)
    vim.notify(msg, log_level, { title = "Neogen" })
end

return {
    notify = notify,
    get_template = get_template,

    --- Generates a list of possible types in the current language
    ---@private
    match_commands = function(arglead, cmdline, cursorpos)
        if vim.bo.filetype == "" then
            return {}
        end

        local language = neogen.configuration.languages[vim.bo.filetype]

        if not language or not language.parent then
            return {}
        end

        return simple_completion(arglead, cmdline, cursorpos, vim.tbl_keys(language.parent))
    end,

    switch_language = function()
        local filetype = vim.bo.filetype
        local ok, ft_configuration = pcall(require, "neogen.configurations." .. filetype)

        if not ok then
            return
        end

        neogen.configuration.languages[filetype] = vim.tbl_deep_extend(
            "keep",
            neogen.user_configuration.languages and neogen.user_configuration.languages[filetype] or {},
            ft_configuration
        )
    end,

    --- Returns all matching available ft conventions
    ---@param arglead string
    ---@param cmdline string
    ---@param cursorpos string
    ---@return table convention name candidates
    get_convention_names = function(arglead, cmdline, cursorpos)
        local templates = get_template(vim.bo.filetype)
        if not templates then
            return {}
        end

        local defaults = {
            add_annotation = true,
            add_default_annotation = true,
            annotation_convention = true,
            append = true,
            config = true,
            position = true,
            use_default_comment = true,
        }

        local template_list = {}

        for template, _ in pairs(templates) do
            if not defaults[template] then
                table.insert(template_list, template)
            end
        end

        return simple_completion(arglead, cmdline, cursorpos, template_list)
    end,

    --- Change de current ft doc convention
    ---@param convention string
    set_ft_convention = function(convention)
        local templates = get_template(vim.bo.filetype)
        if not templates then
            return
        end

        if not templates[convention] then
            notify(('Invalid template: "%s"'):format(convention), vim.lsp.log_levels.ERROR)
            return
        end

        templates.annotation_convention = convention
    end,
}
