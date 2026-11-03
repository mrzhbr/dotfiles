-- Herdr muscle memory, with Rex's native Cmd shortcuts left intact.
-- Personal host addresses belong in local.lua beside this file, not in git.
local config_file = os.getenv("REX_CONFIG")
    or ((os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")) .. "/rex/init.lua")
local private_path = (config_file:match("^(.*)/") or ".") .. "/local.lua"
local preferences = { workstation = "self" }
local private_file = io.open(private_path, "r")
if private_file then
    private_file:close()
    preferences = assert(loadfile(private_path))()
    assert(type(preferences) == "table", "Rex local.lua must return a table")
end

for _, host in ipairs(preferences.hosts or {}) do
    rex.host(host)
end

local function bind(key, action, args)
    rex.bind("ctrl+s>" .. key, action, args)
end

-- Workspace -> session. N/B are sessions; P/Shift-N are tabs, as in Herdr.
bind("w", "session.switch")
bind("s", "session.switch")
bind("g", "session.switch")
bind("q", "session.switch")
bind("n", "session.next")
bind("b", "session.previous")
bind("shift+w", "session.rename")
bind("shift+4", "session.rename")
bind("shift+=", "session.new")
bind("enter", "session.new") -- layout-independent alternative to +
bind("shift+s", "client.settings")
bind("r", "client.config.reload")
bind("shift+/", "client.palette.toggle")
bind("d", "client.window.close") -- close the viewer, not a pane/session
bind("ctrl+s", "pane.send_key", { key = "ctrl+s" })

bind("c", "client.tab.new")
bind(",", "client.tab.rename")
bind("p", "client.tab.previous")
bind("shift+n", "client.tab.next")
bind("shift+7", "client.tab.close")
for index = 1, 9 do
    bind(tostring(index), "client.tab.goto", { index = index })
end

bind("h", "pane.split", { direction = "right" })
bind("v", "pane.split", { direction = "down" })
for _, direction in ipairs({ "left", "down", "up", "right" }) do
    bind(direction, "pane.focus", { direction = direction })
end
bind("o", "pane.focus_next")
bind("x", "pane.close")
bind("z", "pane.zoom")
bind("shift+k", "pane.move", { direction = "up" })
bind("shift+[", "pane.move", { direction = "up" })
bind("shift+j", "pane.move", { direction = "down" })
bind("shift+]", "pane.move", { direction = "down" })
bind("shift+b", "client.sidebar.toggle")

-- Rex additions. Activity is a view, not Herdr's jump-to-notification action.
bind("shift+o", "client.sidebar.activity.toggle")
bind("tab", "client.host.switch")
bind("e", "pane.go_to_directory")
bind("shift+p", "pane.insert_path")
bind("shift+z", "pane.float")
-- No pretend equivalents for Herdr's copy mode ([) or last-used pane (;).

rex.mode("resize", { exclusive = true })
bind("shift+r", "client.mode.enter", { name = "resize" })
for key, direction in pairs({ left = "left", down = "down", up = "up", right = "right",
    h = "left", j = "down", k = "up", l = "right" }) do
    rex.bind("resize/" .. key, "pane.resize", { direction = direction })
    rex.bind("resize/shift+" .. key, "pane.resize", { direction = direction, amount = 15 })
end
rex.bind("resize/=", "pane.balance")
rex.bind("resize/enter", "client.mode.exit")
rex.bind("resize/escape", "client.mode.exit")

-- Direct host jumps: list live sessions, prefer the current/recent one, and
-- create a shell only when the chosen host has no sessions (or New was asked).
-- History is per app client, in memory, and resets on config reload.
local histories = {}

local function checked(result, err)
    if not result then
        error(err or "Rex returned no result", 0)
    end
    return result
end

-- Explicit CLI targets avoid Rex's request-scoped rex.server names and the
-- active remote session changing what an unqualified rex.call considers local.
local function call_target(target, command)
    local endpoint = preferences[target]
    if not endpoint then
        error("Configure the '" .. target .. "' host in Rex's local.lua first", 0)
    end
    local argv = { preferences.cli_bin or "rex", "--autostart=false", "--timeout=5s" }
    if endpoint ~= "self" then
        table.insert(argv, "-S")
        table.insert(argv, endpoint)
    end
    for _, value in ipairs(command) do
        table.insert(argv, value)
    end
    local result = checked(rex.exec(argv, {
        timeout = 10,
        env = { REX_SERVER = false, REX_SESSION = false, REX_BLOCK = false, REX_CLIENT = false },
    }))
    if not result.ok then
        error(result.stderr ~= "" and result.stderr or "Cannot reach the '" .. target .. "' Rex server", 0)
    end
    return checked(rex.json.decode(result.stdout))
end

local function remember(ctx)
    local history = histories[ctx.client_id] or {}
    histories[ctx.client_id] = history
    if ctx.session_id then
        for index = #history, 1, -1 do
            if history[index] == ctx.session_id then
                table.remove(history, index)
            end
        end
        table.insert(history, 1, ctx.session_id)
        history[33] = nil
    end
    return history
end

local function recent_session(sessions, history)
    local available, count = {}, 0
    for index, session in pairs(sessions) do
        if type(index) ~= "number" or index < 1 or index % 1 ~= 0
            or type(session) ~= "table" or type(session.session_id) ~= "string"
            or session.session_id == "" then
            error("Rex returned an invalid session list", 0)
        end
        count = count + 1
        available[session.session_id] = true
    end
    for index = 1, count do
        if sessions[index] == nil then
            error("Rex returned an invalid session list", 0)
        end
    end
    for _, id in ipairs(history) do
        if available[id] then
            return id
        end
    end
    return sessions[1] and sessions[1].session_id
end

local function navigate(target, ctx, fresh)
    if not ctx.client_id then
        error("Use this shortcut in Rex, or select the Rex app with rex -C CLIENT", 0)
    end
    local history = remember(ctx)
    local id
    if not fresh then
        local result = call_target(target, { "ls", "--json" })
        if type(result) ~= "table" or type(result.sessions) ~= "table" then
            error("Rex returned an invalid session list", 0)
        end
        id = recent_session(result.sessions, history)
    end
    if not id then
        local result = call_target(target, { "new", "--json" })
        id = type(result) == "table" and result.session_id or nil
    end
    if type(id) ~= "string" or id == "" then
        error("Rex returned an invalid session ID", 0)
    end
    rex.client.queue("session.select", { session_id = id })
    return { session_id = id, target = target }
end

for _, target in ipairs({ "workstation", "remote" }) do
    local scope = target
    rex.action{
        name = "go_" .. scope,
        title = scope == "workstation" and "Go to Local Work" or "Go to Remote Work",
        category = "Workflow",
        run = function(ctx) return navigate(scope, ctx, false) end,
    }
    rex.action{
        name = "new_" .. scope,
        title = scope == "workstation" and "New Local Session" or "New Remote Session",
        category = "Workflow",
        run = function(ctx) return navigate(scope, ctx, true) end,
    }
end

bind("l", "go_workstation")
bind("f", "go_remote")
bind("shift+l", "new_workstation")
bind("shift+f", "new_remote")
rex.bind("cmd+alt+1", "go_workstation")
rex.bind("cmd+alt+2", "go_remote")
rex.bind("cmd+alt+shift+1", "new_workstation")
rex.bind("cmd+alt+shift+2", "new_remote")
