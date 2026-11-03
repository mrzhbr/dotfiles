-- Run with Lua 5.1+ or LuaJIT; no Rex server or personal config is touched.
local root = assert(arg[1], "pass the repository root")
local original_open, original_loadfile, original_getenv = io.open, loadfile, os.getenv

local function runtime(preferences)
    local state = { bindings = {}, actions = {}, modes = {}, hosts = {}, queued = {}, created = 0 }
    local local_sessions = { { session_id = "local-a" }, { session_id = "local-b" } }
    local remote_sessions = { { session_id = "remote-a" }, { session_id = "remote-b" } }
    state.local_sessions, state.remote_sessions = local_sessions, remote_sessions
    local function exec(argv, options)
        assert(argv[1] == (preferences and preferences.cli_bin or "rex"))
        assert(argv[2] == "--autostart=false" and argv[3] == "--timeout=5s")
        assert(options.timeout == 10)
        for _, name in ipairs({ "REX_SERVER", "REX_SESSION", "REX_BLOCK", "REX_CLIENT" }) do
            assert(options.env[name] == false, "must clear inherited context: " .. name)
        end
        local remote, offset = false, 4
        if argv[4] == "-S" then
            assert(argv[5] == "Remote Host")
            remote, offset = true, 6
        end
        assert(argv[offset + 1] == "--json" and #argv == offset + 1,
            "must not forward a local cwd, shell text, or inherited IDs")
        if state.spawn_error then return nil, "rex executable unavailable" end
        if state.offline and remote then return { ok = false, stderr = "remote unavailable" } end
        if argv[offset] == "ls" then
            if state.bad_list then return { ok = true, stdout = {} } end
            return { ok = true, stdout = { sessions = remote and state.remote_sessions or state.local_sessions } }
        end
        assert(argv[offset] == "new")
        if state.create_error then return { ok = false, stderr = "cannot create session" } end
        if state.bad_create then return { ok = true, stdout = {} } end
        state.created = state.created + 1
        local id = (remote and "remote-new-" or "local-new-") .. state.created
        table.insert(remote and state.remote_sessions or state.local_sessions, { session_id = id })
        return { ok = true, stdout = { session_id = id } }
    end
    rex = {
        bind = function(key, action, args)
            assert(not state.bindings[key], "duplicate key: " .. key)
            state.bindings[key] = { action = action, args = args }
        end,
        action = function(action) state.actions[action.name] = action end,
        mode = function(name, options) state.modes[name] = options end,
        host = function(host) table.insert(state.hosts, host) end,
        exec = exec,
        json = { decode = function(value)
            if state.decode_error then return nil, "invalid JSON" end
            return value
        end },
        client = { queue = function(action, args)
            assert(action == "session.select")
            table.insert(state.queued, args.session_id)
        end },
    }
    os.getenv = function(name)
        if name == "REX_CONFIG" then return "/rex-test/init.lua" end
        return original_getenv(name)
    end
    io.open = function(path, ...)
        if path == "/rex-test/local.lua" then
            if preferences then return { close = function() end } end
            return nil
        end
        return original_open(path, ...)
    end
    loadfile = function(path)
        if path == "/rex-test/local.lua" then return function() return preferences end end
        return original_loadfile(path)
    end
    local ok, err = pcall(dofile, root .. "/dotfiles/rex/init.lua")
    io.open, loadfile, os.getenv = original_open, original_loadfile, original_getenv
    assert(ok, err)
    function state.run(name, current, client)
        return state.actions[name].run({ client_id = client or "app-a", session_id = current })
    end
    return state
end

local state = runtime({ workstation = "self", remote = "Remote Host", hosts = { { label = "Remote Host" } } })
local expected = {
    ["w"] = "session.switch", ["s"] = "session.switch", ["g"] = "session.switch", ["q"] = "session.switch",
    ["n"] = "session.next", ["b"] = "session.previous", ["shift+w"] = "session.rename",
    ["shift+4"] = "session.rename", ["shift+="] = "session.new", ["enter"] = "session.new",
    ["shift+s"] = "client.settings", ["r"] = "client.config.reload", ["shift+/"] = "client.palette.toggle",
    ["d"] = "client.window.close", ["ctrl+s"] = "pane.send_key", ["c"] = "client.tab.new",
    [","] = "client.tab.rename", ["p"] = "client.tab.previous", ["shift+n"] = "client.tab.next",
    ["shift+7"] = "client.tab.close", ["h"] = "pane.split", ["v"] = "pane.split",
    ["o"] = "pane.focus_next", ["x"] = "pane.close", ["z"] = "pane.zoom",
    ["shift+b"] = "client.sidebar.toggle", ["shift+r"] = "client.mode.enter",
    ["shift+o"] = "client.sidebar.activity.toggle", ["tab"] = "client.host.switch",
    ["l"] = "go_workstation", ["f"] = "go_remote", ["shift+l"] = "new_workstation", ["shift+f"] = "new_remote",
}
for key, action in pairs(expected) do
    assert(state.bindings["ctrl+s>" .. key].action == action, key)
end
for i = 1, 9 do
    local binding = state.bindings["ctrl+s>" .. i]
    assert(binding.action == "client.tab.goto" and binding.args.index == i)
end
assert(state.bindings["ctrl+s>h"].args.direction == "right")
assert(state.bindings["ctrl+s>v"].args.direction == "down")
assert(state.bindings["ctrl+s>ctrl+s"].args.key == "ctrl+s")
assert(state.modes.resize.exclusive)
for _, direction in ipairs({ "left", "right", "up", "down" }) do
    assert(state.bindings["ctrl+s>" .. direction].args.direction == direction)
    assert(state.bindings["resize/shift+" .. direction].args.amount == 15)
end
assert(state.bindings["cmd+alt+1"].action == "go_workstation")
assert(state.bindings["cmd+alt+2"].action == "go_remote")
assert(state.bindings["cmd+alt+shift+1"].action == "new_workstation")
assert(state.bindings["cmd+alt+shift+2"].action == "new_remote")
assert(not state.bindings["ctrl+s>["] and not state.bindings["ctrl+s>;"])
for key in pairs(state.bindings) do
    assert(key:match("^ctrl%+s>") or key:match("^resize/") or key:match("^cmd%+alt%+"),
        "must preserve native Rex shortcuts: " .. key)
end

-- Jumping doesn't create sessions unnecessarily and preserves each client's MRU.
assert(state.run("go_remote", "local-b").session_id == "remote-a")
assert(state.run("go_workstation", "remote-b").session_id == "local-b")
assert(state.run("go_remote", "local-b").session_id == "remote-b")
assert(state.run("go_workstation", "remote-b", "app-b").session_id == "local-a")
assert(state.created == 0)
-- Closed sessions are ignored, rather than reviving stale IDs.
state.remote_sessions = { { session_id = "remote-a" } }
assert(state.run("go_remote", "local-b").session_id == "remote-a")
-- Empty hosts and explicit New each create exactly one shell on that host.
state.remote_sessions = {}
assert(state.run("go_remote", "local-b").session_id == "remote-new-1")
assert(state.run("new_remote", "local-b").session_id == "remote-new-2")
assert(state.run("new_workstation", "remote-new-2").session_id == "local-new-3")
-- Connection/create failures never create on the wrong host or queue a jump.
local queued, created = #state.queued, state.created
state.offline = true
local ok, err = pcall(state.run, "go_remote", "local-b")
assert(not ok and tostring(err):find("remote unavailable", 1, true))
assert(#state.queued == queued and state.created == created)
state.offline, state.create_error = false, true
ok, err = pcall(state.run, "new_remote", "local-b")
assert(not ok and tostring(err):find("cannot create session", 1, true))
assert(#state.queued == queued and state.created == created)
state.create_error, state.spawn_error = false, true
ok, err = pcall(state.run, "go_remote", "local-b")
assert(not ok and tostring(err):find("rex executable unavailable", 1, true))
assert(#state.queued == queued and state.created == created)
state.spawn_error, state.decode_error = false, true
ok, err = pcall(state.run, "go_remote", "local-b")
assert(not ok and tostring(err):find("invalid JSON", 1, true))
assert(#state.queued == queued and state.created == created)
state.decode_error = false
state.bad_list = true
ok, err = pcall(state.run, "go_remote", "local-b")
assert(not ok and tostring(err):find("invalid session list", 1, true))
assert(#state.queued == queued and state.created == created)
state.bad_list, state.bad_create = false, true
ok, err = pcall(state.run, "new_remote", "local-b")
assert(not ok and tostring(err):find("invalid session ID", 1, true))
assert(#state.queued == queued and state.created == created)
state.bad_create = false
local saved_sessions = state.remote_sessions
state.remote_sessions = { { session_id = "" } }
ok, err = pcall(state.run, "go_remote", "local-b")
assert(not ok and tostring(err):find("invalid session list", 1, true))
assert(#state.queued == queued and state.created == created)
for _, malformed in ipairs({
    { unexpected = true },
    { [2] = { session_id = "remote-a" } },
    { ["1"] = { session_id = "remote-a" } },
}) do
    state.remote_sessions = malformed
    ok, err = pcall(state.run, "go_remote", "local-b")
    assert(not ok and tostring(err):find("invalid session list", 1, true))
    assert(#state.queued == queued and state.created == created)
end
state.remote_sessions = saved_sessions
ok, err = pcall(state.actions.go_remote.run, {})
assert(not ok and tostring(err):find("rex -C", 1, true))

-- A clean installation works locally, but never silently substitutes local for remote.
state = runtime(nil)
assert(state.run("go_workstation", "local-b").session_id == "local-b")
ok, err = pcall(state.run, "go_remote", "local-b")
assert(not ok and tostring(err):find("local.lua", 1, true))
assert(state.created == 0)
-- On a remote machine the same config can point workstation away and remote to self.
state = runtime({ workstation = "Remote Host", remote = "self" })
assert(state.run("go_remote", "local-b").session_id == "local-b")
assert(state.run("go_workstation", "local-b").session_id == "remote-a")
print("Rex Herdr-keymap/navigation contract passed.")
