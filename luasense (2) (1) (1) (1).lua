        local ffi = require "ffi"
        local bit = require "bit"
        local vector = require "vector"
        local aa = require "gamesense/antiaim_funcs" or error "https://gamesense.pub/forums/viewtopic.php?id=29665"
        local surface = require "gamesense/surface"
        local base64 = require "gamesense/base64" or error("Base64 library required")
        local clipboard_lib = require "gamesense/clipboard" or error("Clipboard library required")
        local json = require("json")
        local trace = require "gamesense/trace"
        local c_entity = require("gamesense/entity")
        local pui = require("gamesense/pui")
        local weapons = require("gamesense/csgo_weapons")
        local js = panorama.open()
        local menu = {}
        local notifications = {}
        local r_3dsky = cvar.r_3dsky
        local aa = {}
        local http = require("gamesense/http")
        username = js.MyPersonaAPI.GetName()
        local LOGO_URL = "https://raw.githubusercontent.com/icoblz/imagensss/refs/heads/main/loglo22-removebg-preview.png"
        local logo_tex, logo_w, logo_h, logo_loaded = nil, nil, nil, false
        local logo_state = nil
        local logo_start = 0
        local logo_alpha = 0.0
        local LOGO_FADE_IN = 0.5
        local LOGO_HOLD = 1.25
        local LOGO_FADE_OUT = 0.75
        local hitboxes = { 
        [0] = 'body', 
        [1] = 'head', 
        [2] = 'chest', 
        [3] = 'stomach', 
        [4] = 'left arm', 
        [5] = 'right arm', 
        [6] = 'left leg', 
        [7] = 'right leg', 
        [8] = 'neck', 
        [9] = 'body', 
        [10] = 'body' 
        }
        local localdb do
            local DATA_KEY = "w9QmFtYQx7V3b6HqzY2nP8uR+L0s5D1XkA2oTbFvcE="
            local DATA_FILE = ".\\luasense.dat"
            local BASE64_KEY = 'BqvbCHsU5NwhxAzGKjFgytIT0oXlurekOdS8ZiPVaEnR7219Q6mM3DfLW4YpcJ+/='

            local function blob_read(path, dbkey)
                if type(readfile) == "function" then
                    local ok, res = pcall(readfile, path)
                    if ok and type(res) == "string" then return res end
                end
                if type(database) == "table" and type(database.read) == "function" then
                    local ok, res = pcall(database.read, dbkey)
                    if ok and type(res) == "string" then return res end
                end
                return nil
            end

            local function blob_write(path, dbkey, contents)
                if type(writefile) == "function" then
                    local ok, err = pcall(writefile, path, contents)
                    if ok then return true end
                    client.error_log("writefile failed: " .. tostring(err))
                end
                if type(database) == "table" and type(database.write) == "function" then
                    local ok, err = pcall(database.write, dbkey, contents)
                    if ok then return true end
                    client.error_log("database.write failed: " .. tostring(err))
                end
                return false
            end

            local function encode_data(tbl)
                local ok, s = pcall(json.stringify, tbl)
                if not ok then return nil, s end
                local ok2, b64 = pcall(base64.encode, s, BASE64_KEY)
                if not ok2 then return nil, b64 end
                return b64
            end

            local function decode_data(s)
                local ok, json_s = pcall(base64.decode, s, BASE64_KEY)
                if not ok then return nil, json_s end
                local ok2, obj = pcall(json.parse, json_s)
                if not ok2 then return nil, obj end
                return obj
            end

            local store = {}

            local function load_store()
                local raw = blob_read(DATA_FILE, DATA_KEY)
                if not raw then
                    local enc = encode_data(store)
                    if enc then blob_write(DATA_FILE, DATA_KEY, enc) end
                    return {}
                end
                local ok, obj = decode_data(raw)
                if not ok then
                    local enc = encode_data({})
                    if enc then blob_write(DATA_FILE, DATA_KEY, enc) end
                    return {}
                end
                return obj
            end

            local function save_store(tbl)
                local enc = encode_data(tbl)
                if not enc then return false end
                return blob_write(DATA_FILE, DATA_KEY, enc)
            end

            store = load_store() or {}
            localdb = setmetatable({}, {
                __index = function(_, k) return store[k] end,
                __newindex = function(_, k, v) store[k] = v; save_store(store) end
            })
        end

        local config_file = {}

        do
            local CONFIG_FILE = ".\\luasense.cfg"
            
            -- Helper function to serialize any value type
            local function serialize_value(value)
                if type(value) == "table" then
                    local result = {}
                    for k, v in pairs(value) do
                        result[k] = serialize_value(v)
                    end
                    return result
                else
                    return value
                end
            end
            
            -- Capture ALL menu values recursively
            local function capture_all_menu_values()
                local captured = {}
                
                for category, items in pairs(menu) do
                    captured[category] = {}
                    
                    for key, ctrl in pairs(items) do
                        local ok, val = pcall(ui.get, ctrl)
                        if ok and val ~= nil then
                            captured[category][key] = serialize_value(val)
                        end
                    end
                end
                
                return captured
            end
            
            -- Capture ALL anti-aim builder values
            local function capture_all_aa_values()
                local captured = {}
                
                for state, teams in pairs(aa) do
                    captured[state] = {}
                    for team, sections in pairs(teams) do
                        captured[state][team] = {}
                        
                        for section_name, section in pairs(sections) do
                            if section_name == "button" then goto continue_section end
                            
                            if section_name == "type" then
                                local ok, val = pcall(ui.get, section)
                                captured[state][team][section_name] = ok and val or nil
                            elseif type(section) == "table" then
                                captured[state][team][section_name] = {}
                                for k, ctrl in pairs(section) do
                                    local ok, val = pcall(ui.get, ctrl)
                                    if ok and val ~= nil then
                                        captured[state][team][section_name][k] = serialize_value(val)
                                    end
                                end
                            end
                            
                            ::continue_section::
                        end
                    end
                end
                
                return captured
            end
            
            -- Read config file
            local function read_config_file()
                if type(readfile) ~= "function" then return {} end
                local ok, content = pcall(readfile, CONFIG_FILE)
                if not ok or not content then return {} end
                
                local ok2, data = pcall(json.parse, content)
                if not ok2 or type(data) ~= "table" then return {} end
                
                return data
            end
            
            -- Write config file
            local function write_config_file(data)
                if type(writefile) ~= "function" then return false end
                
                local ok, json_str = pcall(json.stringify, data)
                if not ok then return false end
                
                local ok2 = pcall(writefile, CONFIG_FILE, json_str)
                return ok2
            end
            
            -- SAVE: Capture everything and save to file
            function config_file.save(name)
                if not name or name == "" then return false end
                
                local all_configs = read_config_file()
                local username = js.MyPersonaAPI.GetName()
                
                -- Capture EVERYTHING
                local full_config = {
                    menu = capture_all_menu_values(),
                    aa = capture_all_aa_values(),
                    
                    -- Metadata
                    name = name,
                    author = username,
                    timestamp = client.system_time(),
                    date = username,
                    version = "luasense_v2"
                }
                
                all_configs[name] = full_config
                
                return write_config_file(all_configs)
            end
            
            -- LOAD: Restore everything from saved config
            function config_file.load(name)
                if not name or name == "" then return nil end
                
                local all_configs = read_config_file()
                local config = all_configs[name]
                
                if not config then return nil end
                
                -- Restore menu values
                if config.menu then
                    for category, items in pairs(config.menu) do
                        if menu[category] then
                            for key, value in pairs(items) do
                                if menu[category][key] then
                                    pcall(function()
                                        if type(value) == "table" then
                                            ui.set(menu[category][key], unpack(value))
                                        else
                                            ui.set(menu[category][key], value)
                                        end
                                    end)
                                end
                            end
                        end
                    end
                end
                
                -- Restore AA values
                if config.aa then
                    for state, teams in pairs(config.aa) do
                        if aa[state] then
                            for team, sections in pairs(teams) do
                                if aa[state][team] then
                                    for section_name, section in pairs(sections) do
                                        if section_name == "type" then
                                            pcall(ui.set, aa[state][team].type, section)
                                        elseif type(section) == "table" and aa[state][team][section_name] then
                                            for k, v in pairs(section) do
                                                local ctrl = aa[state][team][section_name][k]
                                                if ctrl then
                                                    pcall(function()
                                                        if type(v) == "table" then
                                                            ui.set(ctrl, unpack(v))
                                                        else
                                                            ui.set(ctrl, v)
                                                        end
                                                    end)
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
                
                return config
            end
            
            -- DELETE: Remove config from file
            function config_file.delete(name)
                if not name or name == "" then return false end
                
                local all_configs = read_config_file()
                all_configs[name] = nil
                
                return write_config_file(all_configs)
            end
            
            -- LIST: Get all saved configs
            function config_file.list()
                local all_configs = read_config_file()
                local names = {}
                
                for name, config in pairs(all_configs) do
                    table.insert(names, {
                        name = name,
                        author = config.author or "Unknown",
                        date = config.date or "Unknown",
                        timestamp = config.timestamp or 0
                    })
                end
                
                -- Sort by timestamp (newest first)
                table.sort(names, function(a, b)
                    return (a.timestamp or 0) > (b.timestamp or 0)
                end)
                
                return names
            end
            
            -- EXPORT: Convert config to base64 string for clipboard
            function config_file.export(name)
                local all_configs = read_config_file()
                local config = all_configs[name]
                
                if not config then return nil end
                
                local ok, json_str = pcall(json.stringify, config)
                if not ok then return nil end
                
                local ok2, encoded = pcall(base64.encode, json_str)
                if not ok2 then return nil end
                
                return encoded
            end
            
            -- IMPORT: Parse base64 string and return config data
            function config_file.import(encoded_data, import_name)
                local ok, json_str = pcall(base64.decode, encoded_data)
                if not ok then return nil, "Failed to decode" end
                
                local ok2, config = pcall(json.parse, json_str)
                if not ok2 then return nil, "Failed to parse JSON" end
                
                -- If import_name provided, save it immediately
                if import_name and import_name ~= "" then
                    local all_configs = read_config_file()
                    config.name = import_name
                    config.imported = true
                    config.import_date = tostring(client.system_time())
                    all_configs[import_name] = config
                    write_config_file(all_configs)
                end
                
                return config
            end
        end


        local function getbuild() return "beta" end
        local function rgba(r, g, b, a, ...) return ("\a%x%x%x%x"):format(r, g, b, a) .. ... end
        local menu_refs = {
            ["aimbot"] = ui.reference("RAGE", "Aimbot", "Enabled"),
            ["doubletap"] = { ui.reference("RAGE", "Aimbot", "Double tap") },
            ["hideshots"] = { ui.reference("AA", "Other", "On shot anti-aim") }
        }
        ffi.cdef [[
            typedef unsigned long dword;
            typedef unsigned int size_t;

            typedef struct {
                uint8_t r, g, b, a;
            } color_t;
        ]]
        local func = {
            fclamp = function(x, min, max)
                return math.max(min, math.min(x, max));
            end,
            frgba = function(hex)
                hex = hex:gsub("#", "");
            
                local r = tonumber(hex:sub(1, 2), 16);
                local g = tonumber(hex:sub(3, 4), 16);
                local b = tonumber(hex:sub(5, 6), 16);
                local a = tonumber(hex:sub(7, 8), 16) or 255;
            
                return r, g, b, a;
            end,
            render_text = function(x, y, ...)
                local x_Offset = 0
                
                local args = {...}
            
                for i, line in pairs(args) do
                    local r, g, b, a, text = unpack(line)
                    local size = vector(renderer.measure_text("-d", text))
                    renderer.text(x + x_Offset, y, r, g, b, a, "-d", 0, text)
                    x_Offset = x_Offset + size.x
                end
            end,
            easeInOut = function(t)
                return (t > 0.5) and 4*((t-1)^3)+1 or 4*t^3;
            end,
            rec = function(x, y, w, h, radius, color)
                radius = math.min(x/2, y/2, radius)
                local r, g, b, a = unpack(color)
                renderer.rectangle(x, y + radius, w, h - radius*2, r, g, b, a)
                renderer.rectangle(x + radius, y, w - radius*2, radius, r, g, b, a)
                renderer.rectangle(x + radius, y + h - radius, w - radius*2, radius, r, g, b, a)
                renderer.circle(x + radius, y + radius, r, g, b, a, radius, 180, 0.25)
                renderer.circle(x - radius + w, y + radius, r, g, b, a, radius, 90, 0.25)
                renderer.circle(x - radius + w, y - radius + h, r, g, b, a, radius, 0, 0.25)
                renderer.circle(x + radius, y - radius + h, r, g, b, a, radius, -90, 0.25)
            end,
            rec_outline = function(x, y, w, h, radius, thickness, color)
                radius = math.min(w/2, h/2, radius)
                local r, g, b, a = unpack(color)
                if radius == 1 then
                    renderer.rectangle(x, y, w, thickness, r, g, b, a)
                    renderer.rectangle(x, y + h - thickness, w , thickness, r, g, b, a)
                else
                    renderer.rectangle(x + radius, y, w - radius*2, thickness, r, g, b, a)
                    renderer.rectangle(x + radius, y + h - thickness, w - radius*2, thickness, r, g, b, a)
                    renderer.rectangle(x, y + radius, thickness, h - radius*2, r, g, b, a)
                    renderer.rectangle(x + w - thickness, y + radius, thickness, h - radius*2, r, g, b, a)
                    renderer.circle_outline(x + radius, y + radius, r, g, b, a, radius, 180, 0.25, thickness)
                    renderer.circle_outline(x + radius, y + h - radius, r, g, b, a, radius, 90, 0.25, thickness)
                    renderer.circle_outline(x + w - radius, y + radius, r, g, b, a, radius, -90, 0.25, thickness)
                    renderer.circle_outline(x + w - radius, y + h - radius, r, g, b, a, radius, 0, 0.25, thickness)
                end
            end,
            clamp = function(x, min, max)
                return x < min and min or x > max and max or x
            end,
            includes = function(tbl, value)
                for i = 1, #tbl do
                    if tbl[i] == value then
                        return true
                    end
                end
                return false
            end,
            setAATab = function(ref)
                ui.set_visible(refs.enabled, ref)
                ui.set_visible(refs.pitch[1], ref)
                ui.set_visible(refs.pitch[2], ref)
                ui.set_visible(refs.roll, ref)
                ui.set_visible(refs.yawBase, ref)
                ui.set_visible(refs.yaw[1], ref)
                ui.set_visible(refs.yaw[2], ref)
                ui.set_visible(refs.yawJitter[1], ref)
                ui.set_visible(refs.yawJitter[2], ref)
                ui.set_visible(refs.bodyYaw[1], ref)
                ui.set_visible(refs.bodyYaw[2], ref)
                ui.set_visible(refs.freeStand[1], ref)
                ui.set_visible(refs.freeStand[2], ref)
                ui.set_visible(refs.fsBodyYaw, ref)
                ui.set_visible(refs.edgeYaw, ref)
            end,
            findDist = function (x1, y1, z1, x2, y2, z2)
                return math.sqrt((x2 - x1)^2 + (y2 - y1)^2 + (z2 - z1)^2)
            end,
            resetAATab = function()
                ui.set(refs.enabled, false)
                ui.set(refs.pitch[1], "Off")
                ui.set(refs.pitch[2], 0)
                ui.set(refs.roll, 0)
                ui.set(refs.yawBase, "local view")
                ui.set(refs.yaw[1], "Off")
                ui.set(refs.yaw[2], 0)
                ui.set(refs.yawJitter[1], "Off")
                ui.set(refs.yawJitter[2], 0)
                ui.set(refs.bodyYaw[1], "Off")
                ui.set(refs.bodyYaw[2], 0)
                ui.set(refs.freeStand[1], false)
                ui.set(refs.freeStand[2], "On hotkey")
                ui.set(refs.fsBodyYaw, false)
                ui.set(refs.edgeYaw, false)
            end,
            type_from_string = function(input)
                if type(input) ~= "string" then return input end

                local value = input:lower()

                if value == "true" then
                    return true
                elseif value == "false" then
                    return false
                elseif tonumber(value) ~= nil then
                    return tonumber(value)
                else
                    return tostring(input)
                end
            end,
            lerp = function(start, vend, time)
                return start + (vend - start) * time
            end,
            vec_angles = function(angle_x, angle_y)
                local sy = math.sin(math.rad(angle_y))
                local cy = math.cos(math.rad(angle_y))
                local sp = math.sin(math.rad(angle_x))
                local cp = math.cos(math.rad(angle_x))
                return cp * cy, cp * sy, -sp
            end,
            hex = function(arg)
                local result = "\a"
                for key, value in next, arg do
                    local output = ""
                    while value > 0 do
                        local index = math.fmod(value, 16) + 1
                        value = math.floor(value / 16)
                        output = string.sub("0123456789ABCDEF", index, index) .. output 
                    end
                    if #output == 0 then 
                        output = "00" 
                    elseif #output == 1 then 
                        output = "0" .. output 
                    end 
                    result = result .. output
                end 
                return result .. "FF"
            end,
            split = function( inputstr, sep)
                if sep == nil then
                        sep = "%s"
                end
                local t={}
                for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
                        table.insert(t, str)
                end
                return t
            end,
            RGBAtoHEX = function(redArg, greenArg, blueArg, alphaArg)
                return string.format('%.2x%.2x%.2x%.2x', redArg, greenArg, blueArg, alphaArg)
            end,
            create_color_array = function(r, g, b, string)
                local colors = {}
                for i = 0, #string do
                    local color = {r, g, b, 255 * math.abs(1 * math.cos(2 * math.pi * globals.curtime() / 4 + i * 5 / 30))}
                    table.insert(colors, color)
                end
                return colors
            end,
            textArray = function(string)
                local result = {}
                for i=1, #string do
                    result[i] = string.sub(string, i, i)
                end
                return result
            end,
            gradient_text = function(r1, g1, b1, a1, r2, g2, b2, a2, text)
                local output = ''
            
                local len = #text-1
            
                local rinc = (r2 - r1) / len
                local ginc = (g2 - g1) / len
                local binc = (b2 - b1) / len
                local ainc = (a2 - a1) / len
            
                for i=1, len+1 do
                    output = output .. ('\a%02x%02x%02x%02x%s'):format(r1, g1, b1, a1, text:sub(i, i))
            
                    r1 = r1 + rinc
                    g1 = g1 + ginc
                    b1 = b1 + binc
                    a1 = a1 + ainc
                end
            
                return output
            end,    
            time_to_ticks = function(t)
                return math.floor(0.5 + (t / globals.tickinterval()))
            end,
            headVisible = function(enemy)
                local local_player = entity.get_local_player()
                if local_player == nil then return end
                local ex, ey, ez = entity.hitbox_position(enemy, 1)
            
                local hx, hy, hz = entity.hitbox_position(local_player, 1)
                local head_fraction, head_entindex_hit = client.trace_line(enemy, ex, ey, ez, hx, hy, hz)
                if head_entindex_hit == local_player or head_fraction == 1 then return true else return false end
            end,
            defensive = {
                cmd = 0,
                check = 0,
                defensive = 0,
            },
            aa_clamp = function(x) if x == nil then return 0 end x = (x % 360 + 360) % 360 return x > 180 and x - 360 or x end,
        }

        client.set_event_callback('level_init', function()
            timer = globals.tickcount()
        end)

        local draw_gamesense_ui = {}
        local hitmarker_queue = {}
        local hitmarkenable, r, g, b, a

        local notify = (function()
            local b = vector
            local c = function(d, b, c) return d + (b - d) * c end
            local e = function() return b(client.screen_size()) end
            local f = function(d, ...) local c = {...} local c = table.concat(c, "") return b(renderer.measure_text(d, c)) end
            local g = { notifications = { bottom = {} }, max = { bottom = 5 } }
            g.__index = g
            g.new_bottom = function(h, i, j, text, color_key)
                table.insert(g.notifications.bottom, {
                    started = false,
                    instance = setmetatable({ active = false, timeout = 7, color = { ["r"] = h, ["g"] = i, ["b"] = j, a = 0 }, x = e().x / 2, y = e().y, text = text, color_key = color_key }, g)
                })
                if #g.notifications.bottom > g.max.bottom then
                    table.remove(g.notifications.bottom, 1)
                end
            end
            function g:handler()
                local d = 0
                local b = 0
                for d, b in pairs(g.notifications.bottom) do
                    if not b.instance.active and b.started then
                        table.remove(g.notifications.bottom, d)
                    end
                end
                for d = 1, #g.notifications.bottom do
                    if g.notifications.bottom[d].instance.active then
                        b = b + 1
                    end
                end
                for c, e in pairs(g.notifications.bottom) do
                    if c > g.max.bottom then return end
                    if e.instance.active then
                        e.instance:render_bottom(d, b)
                        d = d + 1
                    end
                    if not e.started then
                        e.instance:start()
                        e.started = true
                    end
                end
            end
            function g:start()
                self.active = true
                self.delay = globals.realtime() + self.timeout
            end
            function g:get_text()
                local d = ""
                for b, b in pairs(self.text) do
                    local c = f("", b[1])
                    d = d .. b[1]
                end
                return d
            end
            local k = (function()
                local d = {}
                d.rec = function(d, b, c, e, f, g, k, l, m)
                    m = math.min(d / 2, b / 2, m)
                    renderer.rectangle(d, b + m, c, e - m * 2, f, g, k, l)
                    renderer.rectangle(d + m, b, c - m * 2, m, f, g, k, l)
                    renderer.rectangle(d + m, b + e - m, c - m * 2, m, f, g, k, l)
                    renderer.circle(d + m, b + m, f, g, k, l, m, 180, .25)
                    renderer.circle(d - m + c, b + m, f, g, k, l, m, 90, .25)
                    renderer.circle(d - m + c, b - m + e, f, g, k, l, m, 0, .25)
                    renderer.circle(d + m, b - m + e, f, g, k, l, m, -90, .25)
                end
                d.rec_outline = function(d, b, c, e, f, g, k, l, m, n)
                    m = math.min(c / 2, e / 2, m)
                    if m == 1 then
                        renderer.rectangle(d, b, c, n, f, g, k, l)
                        renderer.rectangle(d, b + e - n, c, n, f, g, k, l)
                    else
                        renderer.rectangle(d + m, b, c - m * 2, n, f, g, k, l)
                        renderer.rectangle(d + m, b + e - n, c - m * 2, n, f, g, k, l)
                        renderer.rectangle(d, b + m, n, e - m * 2, f, g, k, l)
                        renderer.rectangle(d + c - n, b + m, n, e - m * 2, f, g, k, l)
                        renderer.circle_outline(d + m, b + m, f, g, k, l, m, 180, .25, n)
                        renderer.circle_outline(d + m, b + e - m, f, g, k, l, m, 90, .25, n)
                        renderer.circle_outline(d + c - m, b + m, f, g, k, l, m, -90, .25, n)
                        renderer.circle_outline(d + c - m, b + e - m, f, g, k, l, m, 0, .25, n)
                    end
                end
                d.glow_module_notify = function(b, c, e, f, g, k, l, m, n, o, p, q, r, s, s)
                    local t = 1
                    local u = 1
                    local rounding = ui.get(menu["visuals & misc"]["visuals"]["notrounding"])
                    if s then
                        d.rec(b, c, e, f, l, m, n, o, rounding)
                    end
                    for l = 0, g do
                        local m = o / 2 * (l / g) ^ 3
                        d.rec_outline(b + (l - g - u) * t, c + (l - g - u) * t, e - (l - g - u) * t * 2, f - (l - g - u) * t * 2, p, q, r, m / 1.5, rounding, t)
                    end
                end
                return d
            end)()
            _G.k = k
            function g:render_bottom(g, l)
                local e = e()
                local m = 3.5
                local n = self:get_text()
                local text_size = f("", n)
                local o = 8
                local p = 7
                local marker = (self.text[1] and type(self.text[1]) == "table" and self.text[1][2] == "miss") and 
                    (ui.get(menu["visuals & misc"]["visuals"]["notmark2"]) == "custom" and ui.get(menu["visuals & misc"]["visuals"]["custom_notmark_miss"]) or ui.get(menu["visuals & misc"]["visuals"]["notmark2"])) or 
                    (ui.get(menu["visuals & misc"]["visuals"]["notmark"]) == "custom" and ui.get(menu["visuals & misc"]["visuals"]["custom_notmark_hit"]) or ui.get(menu["visuals & misc"]["visuals"]["notmark"]))
                local font_map = { normal = "c", small = "-", bold = "b" }
                local prefix_font = font_map[ui.get(menu["visuals & misc"]["visuals"]["notmarkfont"])] or "b"
                local prefix_text = marker
                local separator_enabled = ui.get(menu["visuals & misc"]["visuals"]["notmarkseparator"]) == "yes"
                local separator_text = separator_enabled and " | " or ""
                if ui.get(menu["visuals & misc"]["visuals"]["notmarkuppercase"]) == "yes" then
                    prefix_text = prefix_text:upper()
                else
                    prefix_text = prefix_text:lower()
                end
                local prefix_width = f(prefix_font, prefix_text).x
                local prefix_height = f(prefix_font, prefix_text).y
                local separator_width = f(prefix_font, separator_text).x
                local separator_height_text = f("b", separator_text).y
                local is_centered = true
                local marker_offset = is_centered and 0 or ui.get(menu["visuals & misc"]["visuals"]["notmarkoffset"])
                local marker_x_offset = is_centered and 0 or ui.get(menu["visuals & misc"]["visuals"]["notmarkxoffset"])
                local q = m + text_size.x + (prefix_text ~= "" and prefix_width + separator_width + marker_offset or 0) + 2
                local r = ui.get(menu["visuals & misc"]["visuals"]["notheight"])
                local q = q + p * 1.5
                local s, t = is_centered and (e.x / 2 - q / 2) or (self.x - q / 2), math.ceil(self.y - 40 + .4)
                local u = globals.frametime()
                if globals.realtime() < self.delay then
                    self.y = c(self.y, e.y - 45 - (l - g) * r * 1.4, u * 7)
                    self.color.a = c(self.color.a, 255, u * 2)
                else
                    self.y = c(self.y, self.y - 10, u * 15)
                    self.color.a = c(self.color.a, 0, u * 20)
                    if self.color.a <= 1 then
                        self.active = false
                    end
                end
                local c, e, g, l = self.color.r, self.color.g, self.color.b, self.color.a
                local color_key = self.color_key or "notcolor"
                local glow_r, glow_g, glow_b
                if self.text[1] and type(self.text[1]) == "table" and self.text[1][2] == "hit" then
                    glow_r, glow_g, glow_b = ui.get(menu["visuals & misc"]["visuals"]["notglow_hit_color"])
                elseif self.text[1] and type(self.text[1]) == "table" and self.text[1][2] == "miss" then
                    glow_r, glow_g, glow_b = ui.get(menu["visuals & misc"]["visuals"]["notglow_miss_color"])
                else
                    glow_r, glow_g, glow_b = ui.get(menu["visuals & misc"]["visuals"][color_key])
                end 
                local glow = ui.get(menu["visuals & misc"]["visuals"]["notglow"])
                if type(k) == "table" and type(k.glow_module_notify) == "function" then
                    local bg_r, bg_g, bg_b, bg_a = ui.get(menu["visuals & misc"]["visuals"]["notbackground_color"])
                    k.glow_module_notify(s, t, q, r, glow, o, bg_r, bg_g, bg_b, bg_a, glow_r, glow_g, glow_b, 255, true)
                else
                    client.log("Error: k.glow_module_notify is not callable, skipping glow effect")
                    local bg_r, bg_g, bg_b, bg_a = ui.get(menu["visuals & misc"]["visuals"]["notbackground_color"])
                    renderer.rectangle(s, t, q, r, bg_r, bg_g, bg_b, bg_a)
                end
                local k = p + 2
                k = k + m
                local marker_height = ui.get(menu["visuals & misc"]["visuals"]["notmarkheight"])
                local text_r, text_g, text_b = 255, 255, 255
                local marker_r, marker_g, marker_b
                if self.text[1] and type(self.text[1]) == "table" and self.text[1][2] == "hit" then
                    marker_r, marker_g, marker_b = ui.get(menu["visuals & misc"]["visuals"]["notmark_hit_prefix_color"])
                elseif self.text[1] and type(self.text[1]) == "table" and self.text[1][2] == "miss" then
                    marker_r, marker_g, marker_b = ui.get(menu["visuals & misc"]["visuals"]["notmark_miss_prefix_color"])
                else
                    marker_r, marker_g, marker_b = ui.get(menu["visuals & misc"]["visuals"][color_key])
                end
                local prefix_alpha = (self.text[1] and type(self.text[1]) == "table" and (self.text[1][2] == "hit" or self.text[1][2] == "miss" or self.text[1][2] == "shot" or self.text[1][2] == "reset")) and 255 or l
                if prefix_text ~= "" then
                    local prefix_y = is_centered and (t + r / 2 - prefix_height / 2) or (t + r / 2 - marker_height / 2)
                    local adjusted_marker_x_offset = separator_enabled and marker_x_offset or marker_x_offset - 4.4
                    renderer.text(s + k + adjusted_marker_x_offset, prefix_y, marker_r, marker_g, marker_b, prefix_alpha, prefix_font, nil, prefix_text)
                    k = k + prefix_width
                    if separator_text ~= "" then
                        local separator_height = ui.get(menu["visuals & misc"]["visuals"]["notmarkseparatorheight"])
                        local separator_y = is_centered and (t + r / 2 - separator_height_text / 2) or (t + r / 2 - separator_height / 2)
                        local separator_r, separator_g, separator_b
                        if self.text[1] and type(self.text[1]) == "table" then
                            if self.text[1][2] == "miss" then
                                separator_r, separator_g, separator_b = ui.get(menu["visuals & misc"]["visuals"]["notmark_miss_separator_color"])
                            else
                                separator_r, separator_g, separator_b = ui.get(menu["visuals & misc"]["visuals"]["notmark_hit_separator_color"])
                            end
                        else
                            separator_r, separator_g, separator_b = ui.get(menu["visuals & misc"]["visuals"]["notmark_hit_separator_color"])
                        end
                        renderer.text(s + k, separator_y, separator_r, separator_g, separator_b, prefix_alpha, "b", nil, separator_text)
                        k = k + separator_width
                    end
                    k = k + marker_offset
                end
                renderer.text(s + k, t + r / 2 - text_size.y / 2, text_r, text_g, text_b, l, "", nil, n)
            end
            client.set_event_callback("paint_ui", function() g:handler() end)
            return g
        end)()

        local w, h = client.screen_size()
        local js = panorama.open()
        local alpha = 69
        local toggled = false
        local second_notification_triggered = false
        local first_notification_time = nil
        local loading_notification_triggered = false

        local FADE_IN_DURATION = 0   
        local FADE_OUT_DURATION = 4.0  

        local function draw_debug_panel()
            if not ui.get(menu["visuals & misc"]["visuals"]["debug_panel"]) then return end
            local w, h = client.screen_size()
            local base_x = 47.5  
            local base_y = 440  
            local r, g, b, a = 255, 255, 255, 255 
            local font = "c"  
            local line_height = 12.2  

            
        local function get_exploit_charge()
            if not menu_refs or not menu_refs["doubletap"] or not menu_refs["hideshots"] then
                return "true"
            end
            local dt_enabled = ui.get(menu_refs["doubletap"][1]) and ui.get(menu_refs["doubletap"][2])
            local hs_enabled = ui.get(menu_refs["hideshots"][1]) and ui.get(menu_refs["hideshots"][2])
            local exploit_charged = dt_enabled or hs_enabled
            return exploit_charged and "true" or "false"
        end

            
            local debug_label = ui.get(menu["visuals & misc"]["visuals"]["debug_customp"]) and
            (ui.get(menu["visuals & misc"]["visuals"]["debug_custom"]) or "luasense") or "luasense"


            
            local debug_lines = {
                { label = debug_label, value = ui.get(menu["visuals & misc"]["visuals"]["useridls"]) or "user", label_x_offset = -11.5, value_x_offset = -11.5 },
                { 
                    label = "version", 
                    value = function()
                        local alpha = math.floor(math.abs(math.sin(globals.realtime() * 1)) * 255)
                        return string.format(" \aFFFFFF%02Xexclusive", alpha) 
                    end,
                    label_x_offset = -18.5, 
                    value_x_offset = 4 
                },        
                { label = "exploit charge", value = get_exploit_charge, label_x_offset = -0.75, value_x_offset = -23 },
                { label = "desync amount", value = function()
                    local myself = entity.get_local_player()
                    if myself and entity.is_alive(myself) then
                        local yaw_body = math.max(-60, math.min(60, math.floor((entity.get_prop(myself, "m_flPoseParameter", 11) or 0) * 120 - 60 + 0.5)))
                        return string.format("%.0f°", math.abs(yaw_body))
                    end
                    return "N/A"
                end, label_x_offset = 0, value_x_offset = -29 }
            }

            
        for i, line in ipairs(debug_lines) do
            local value = type(line.value) == "function" and line.value() or line.value
            local label_text
            if line.label == debug_label then
                label_text = line.label .. " - "
            else
                label_text = line.label .. ":"
            end
            local label_x = base_x + (line.label_x_offset or 0)
            local label_width = renderer.measure_text(font, label_text)
            local value_width = renderer.measure_text(font, value)
            local value_x = label_x + label_width + (line.value_x_offset or 0)
            local y = base_y + (i - 1) * line_height
            renderer.text(label_x, y, r, g, b, a, font, nil, label_text)
            renderer.text(value_x, y, r, g, b, a, font, nil, value)
        end
        end

        client.set_event_callback("paint_ui", function()
            if ui.get(menu["rage"]["resolver"]) == "yes" then
                local myself = entity.get_local_player()
                if myself and entity.is_alive(myself) then
                    local target = client.current_threat()
                    if target then
                        local target_entity = c_entity.new(target)
                        local target_name = target_entity:get_player_name() or "Unknown"
                        local r, g, b, a = ui.get(menu["rage"]["resolver_color"])
                        renderer.indicator(r, g, b, a, "Target: " .. target_name)
                    end
                end
            end
            draw_debug_panel()
            local dt = globals.frametime() or 0.016
            if alpha > 0 and toggled then
                alpha = math.max(0, alpha - (255 * dt) / FADE_OUT_DURATION)
            else
                if not toggled then
                    alpha = math.min(255, alpha + (255 * dt) / FADE_IN_DURATION)
                    if alpha >= 254 then
                        toggled = true
                        first_notification_time = globals.realtime()
                    end
                end
            end

            if not loading_notification_triggered and menu["visuals & misc"] then
                local r, g, b = ui.get(menu["visuals & misc"]["visuals"]["notcolor"])
                local a = 255
                local colored_luasense = ("\a%02x%02x%02x%02x%s"):format(r, g, b, a, "luasense")
                local white = "\aFFFFFFFF"
                notify.new_bottom(r, g, b, { { white .. "Loading " .. colored_luasense .. white .. "..." }, { "  ", true } })
                loading_notification_triggered = true
            end

        if first_notification_time and not second_notification_triggered then
            if globals.realtime() >= first_notification_time + 2 then 
                local r, g, b = ui.get(menu["visuals & misc"]["visuals"]["notcolor"])
                local a = 255
                local username = js.MyPersonaAPI.GetName()
                local colored_user = ("\a%02x%02x%02x%02x%s"):format(r, g, b, a, username)
                local white = "\aFFFFFFFF"
                notify.new_bottom(179, 255, 18, { { white .. "Welcome back, " .. colored_user .. "  ", true } })
                second_notification_triggered = true 
            end
        end

            if alpha > 1 then
                renderer.gradient(0, 0, w, h, 0, 0, 0, alpha, 0, 0, 0, alpha, false)
            end

            if menu["visuals & misc"] and menu["visuals & misc"]["visuals"] then
                local is_centered = ui.get(menu["visuals & misc"]["visuals"]["notmark_centered"])
                ui.set_visible(menu["visuals & misc"]["visuals"]["notmarkoffset"], not is_centered)
                ui.set_visible(menu["visuals & misc"]["visuals"]["notmarkxoffset"], not is_centered)
            end
        end)

        return (function(tbl)
            tbl.items = {
                enabled = tbl.ref("aa", "anti-aimbot angles", "enabled"),
                pitch = tbl.ref("aa", "anti-aimbot angles", "pitch"),
                base = tbl.ref("aa", "anti-aimbot angles", "yaw base"),
                jitter = tbl.ref("aa", "anti-aimbot angles", "yaw jitter"),
                yaw = tbl.ref("aa", "anti-aimbot angles", "yaw"),
                body = tbl.ref("aa", "anti-aimbot angles", "body yaw"),
                fsbody = tbl.ref("aa", "anti-aimbot angles", "freestanding body yaw"),
                edge = tbl.ref("aa", "anti-aimbot angles", "edge yaw"),
                roll = tbl.ref("aa", "anti-aimbot angles", "roll"),
                fs = tbl.ref("aa", "anti-aimbot angles", "freestanding")
            }
            local prefix = function(x, z) 
                return (z and ("\a32a852FFluasense \a698a6dFF~ \a414141FF(\ab5b5b5FF%s\a414141FF) \a89f596FF%s"):format(x, z) or ("\a32a852FFluasense \a698a6dFF~ \a89f596FF%s"):format(x)) 
            end
            local ffi = require("ffi")
            local clipboard_legacy = {
                ["ffi"] = ffi.cdef([[
                    typedef int(__thiscall* get_clipboard_text_count)(void*);
                    typedef void(__thiscall* set_clipboard_text)(void*, const char*, int);
                    typedef void(__thiscall* get_clipboard_text)(void*, int, const char*, int);
                ]]),
                ["export"] = function(arg)
                    local pointer = ffi.cast(ffi.typeof('void***'), client.create_interface('vgui2.dll', 'VGUI_System010'))
                    local func = ffi.cast('set_clipboard_text', pointer[0][9])
                    func(pointer, arg, #arg)
                end,
                ["import"] = function()
                    local pointer = ffi.cast(ffi.typeof('void***'), client.create_interface('vgui2.dll', 'VGUI_System010'))
                    local func = ffi.cast('get_clipboard_text_count', pointer[0][7])
                    local sizelen = func(pointer)
                    local output = ""
                    if sizelen > 0 then
                        local buffer = ffi.new("char[?]", sizelen)
                        local sizefix = sizelen * ffi.sizeof("char[?]", sizelen)
                        local extrafunc = ffi.cast('get_clipboard_text', pointer[0][11])
                        extrafunc(pointer, 0, buffer, sizefix)
                        output = ffi.string(buffer, sizelen-1)
                    end
                    return output
                end
            }
            local category = ui.new_combobox("aa", "anti-aimbot angles", prefix("category" .. rgba(69,169,155,255," " .. (getbuild() == "beta" and " (beta)" or ""))), {"rage", "anti aimbot", "visuals & misc", "config"})
            draw_gamesense_ui.alpha = function(color, alpha)
                color[4] = alpha
                return color
            end
            draw_gamesense_ui.colors = {
                main = {12, 12, 12},
                border_edge = {60, 60, 60},
                border_inner = {40, 40, 40},
                gradient = {
                    top = {
                        left = {55, 177, 218},
                        middle = {204, 70, 205},
                        right = {204, 227, 53}
                    },
                    bottom = {
                        left = {29, 94, 116},
                        middle = {109, 37, 109},
                        right = {109, 121, 28}
                    },
                    pixel_three = {6, 6, 6}
                },
                combine = function(color1, color2, ...)
                    local t = {unpack(color1)}
                    for i = 1, #color2 do
                        table.insert(t, color2[i])
                    end
                    local args = {...}
                    for i = 1, #args do
                        table.insert(t, args[i])
                    end
                    return t
                end
            }
            draw_gamesense_ui.border = function(x, y, width, height, alpha)
                local x = x - 7 - 1
                local y = y - 7 - 5
                local w = width + 14 + 2
                local h = height + 14 + 10
                renderer.rectangle(x, y, w, h, unpack(draw_gamesense_ui.alpha(draw_gamesense_ui.colors.main, alpha)))
                renderer.rectangle(x + 1, y + 1, w - 2, h - 2, unpack(draw_gamesense_ui.alpha(draw_gamesense_ui.colors.border_edge, alpha)))
                renderer.rectangle(x + 2, y + 2, w - 4, h - 4, unpack(draw_gamesense_ui.alpha(draw_gamesense_ui.colors.border_inner, alpha)))
                renderer.rectangle(x + 6, y + 6, w - 12, h - 12, unpack(draw_gamesense_ui.alpha(draw_gamesense_ui.colors.border_edge, alpha)))
            end
            draw_gamesense_ui.gradient = function(x, y, width, alpha)
                local full_width = width
                local width = math.floor(width / 2)
                local top_left = draw_gamesense_ui.alpha(draw_gamesense_ui.colors.gradient.top.left, alpha)
                local top_middle = draw_gamesense_ui.alpha(draw_gamesense_ui.colors.gradient.top.middle, alpha)
                local top_right = draw_gamesense_ui.alpha(draw_gamesense_ui.colors.gradient.top.right, alpha)
                local bottom_left = draw_gamesense_ui.alpha(draw_gamesense_ui.colors.gradient.bottom.left, alpha)
                local bottom_middle = draw_gamesense_ui.alpha(draw_gamesense_ui.colors.gradient.bottom.middle, alpha)
                local bottom_right = draw_gamesense_ui.alpha(draw_gamesense_ui.colors.gradient.bottom.right, alpha)
                top_left = draw_gamesense_ui.colors.combine(top_left, top_middle, true)
                top_right = draw_gamesense_ui.colors.combine(top_middle, top_right, true)
                bottom_left = draw_gamesense_ui.colors.combine(bottom_left, bottom_middle, true)
                bottom_right = draw_gamesense_ui.colors.combine(bottom_middle, bottom_right, true)
                local oddfix = math.ceil(full_width / 2)
                renderer.gradient(x, y - 4, width, 1, unpack(top_left))
                renderer.gradient(x + width, y - 4, oddfix, 1, unpack(top_right))
                renderer.gradient(x, y - 3, width, 1, unpack(bottom_left))
                renderer.gradient(x + width, y - 3, oddfix, 1, unpack(bottom_right))
                renderer.rectangle(x, y - 2, full_width, 1, unpack(draw_gamesense_ui.colors.gradient.pixel_three))
            end
            draw_gamesense_ui.draw = function(x, y, width, height, alpha)
                y = y - 7
                draw_gamesense_ui.border(x, y, width, height, alpha)
                renderer.rectangle(x - 1, y - 5, width + 2, height + 10, unpack(draw_gamesense_ui.alpha(draw_gamesense_ui.colors.main, alpha)))
                draw_gamesense_ui.gradient(x, y, width, alpha)
            end
            local function push_notify(text, color_flag)
                local color_key = color_flag == "hit" and "notcolor2" or color_flag == "miss" and "notcolor3" or "notcolor"
                local r, g, b = ui.get(menu["visuals & misc"]["visuals"][color_key])
                notify.new_bottom(r, g, b, { { text, color_flag or true } }, color_key)
            end
            local lerp = function(current, to_reach, t) return current + (to_reach - current) * t end
            client.set_event_callback("paint_ui", function()
                local width, height = client.screen_size()
                local frametime = globals.frametime()
                local timestamp = client.timestamp()
                for idx, notification in next, notifications do
                    if timestamp > notification.lifetime then
                        notification.alpha = lerp(255, 0, 1 - (notification.alpha / 255) + frametime * (1 / 7.5 * 10))
                    end
                    if notification.alpha <= 0 then
                        notifications[idx] = nil
                    else
                        notification.spacer = lerp(notification.spacer, idx * 40, frametime)
                        local text_width = renderer.measure_text("c", notification.text) + 10
                        draw_gamesense_ui.draw(width/2 - text_width / 2, height/2 + 300 + notification.spacer, text_width, 12, notification.alpha)
                        renderer.text(width/2, height/2 + 300 + notification.spacer, 255, 255, 255, notification.alpha, "c", 0, notification.text:gsub("\a%x%x%x%x%x%x%x%x", function(color)
                            return color:sub(1, #color - 2)..string.format("%02x", notification.alpha)
                        end):sub(1, -1))
                    end
                end
            end)
        local cloud_system = {
            api_url = "https://api.jsonbin.io/v3/b/69277aca43b1c97be9c73eb7",
            api_key = "$2a$10$UgQKKAFwi8hfxafmdlPgDO69xj9Eg8QMg7Kp7p1xv2V.uuvNAYZsi",
            
            configs = {},
            loading = false,
            last_refresh = 0,
            refresh_interval = 30,
            
            cache_file = ".\\luasense_cloud.cfg",
            username = "",
            liked_configs = {}
        }

        function cloud_system:like_selected(index)
            if index < 1 or index > #self.configs then
                push_notify("Invalid config selection")
                return false
            end
            
            local config = self.configs[index]
            local config_id = config.id or tostring(index)
            
            
            if not config.liked_by then
                config.liked_by = {}
            end
            
            
            local user_key = self.username or username or "Anonymous"
            if config.liked_by[user_key] then
                push_notify("You already liked this config! ")
                return false
            end
            
            
            config.likes = (config.likes or 0) + 1
            
            
            config.liked_by[user_key] = true
            
            
            self:save_cache()
            self:update_listbox()
            
            
            local ok, json_str = pcall(json.stringify, {configs = self.configs})
            if not ok then
                push_notify("Failed to encode data ")
                
                config.likes = (config.likes or 1) - 1
                config.liked_by[user_key] = nil
                return false
            end
            
            http.put(self.api_url, {
                headers = {
                    ["Content-Type"] = "application/json",
                    ["X-Master-Key"] = self.api_key,
                    ["X-Bin-Meta"] = "false"
                },
                body = json_str
            }, function(success, response)
                if success and response.status == 200 then
                    push_notify("Liked '" .. config.name .. "'!")
                    self:save_cache()
                else
                    
                    config.likes = (config.likes or 1) - 1
                    config.liked_by[user_key] = nil
                    self:update_listbox()
                    self:save_cache()
                    push_notify("Failed to like config ")
                end
            end)
            
            return true
        end


        local function generate_id()
            local chars = "0123456789abcdefghijklmnopqrstuvwxyz"
            local id = ""
            for i = 1, 16 do
                id = id .. chars:sub(math.random(1, #chars), math.random(1, #chars))
            end
            return id .. "_" .. client.system_time()
        end


        function cloud_system:save_cache()
            if type(writefile) ~= "function" then
                localdb.cloud_cache = {
                    configs = self.configs,
                    last_update = client.system_time(),
                    last_refresh = self.last_refresh,
                    liked_configs = self.liked_configs
                }
                return
            end
            
            local cache_data = {
                configs = self.configs,
                last_update = client.system_time(),
                last_refresh = self.last_refresh,
                username = self.username,
                liked_configs = self.liked_configs
            }
            
            local ok, json_str = pcall(json.stringify, cache_data)
            if not ok then
                client.error_log("Failed to encode cloud cache ")
                return
            end
            
            local ok2 = pcall(writefile, self.cache_file, json_str)
            if not ok2 then
                client.error_log("Failed to write cloud cache file ")
            end
        end



        function cloud_system:load_cache()
            
            if type(readfile) == "function" then
                local ok, content = pcall(readfile, self.cache_file)
                if ok and content then
                    local ok2, data = pcall(json.parse, content)
                    if ok2 and type(data) == "table" then
                        self.configs = data.configs or {}
                        self.last_refresh = data.last_refresh or 0
                        self.liked_configs = data.liked_configs or {}
                        
                        table.sort(self.configs, function(a, b)
                            return (a.timestamp or 0) > (b.timestamp or 0)
                        end)
                        
                        self:update_listbox()
                        
                        local age = client.system_time() - (data.last_update or 0)
                        if age > 300 then
                            client.delay_call(2, function()
                                self:refresh()
                            end)
                        end
                        return
                    end
                end
            end
            
            
            local cache = localdb.cloud_cache
            if type(cache) == "table" then
                self.configs = cache.configs or {}
                self.last_refresh = cache.last_refresh or 0
                self.liked_configs = cache.liked_configs or {}
                
                table.sort(self.configs, function(a, b)
                    return (a.timestamp or 0) > (b.timestamp or 0)
                end)
                
                self:update_listbox()
                
                local age = client.system_time() - (cache.last_update or 0)
                if age > 300 then
                    client.delay_call(2, function()
                        self:refresh()
                    end)
                end
            end
        end

        function cloud_system:upload(config_name, config_data)
            if self.loading then
                push_notify("Please wait, cloud is busy... ")
                return false
            end
            
            if not config_name or config_name == "" then
                push_notify("Config name required ")
                return false
            end
            
            self.loading = true
            
            local upload_entry = {
                id = generate_id(),
                name = config_name,
                author = (self.username or username or "Anonymous"),
                timestamp = client.system_time(),
                date = tostring(client.system_time()),
                downloads = 0,
                likes = 0,  
                liked_by = {},
                data = config_data
            }
            
            table.insert(self.configs, upload_entry)
            
            table.sort(self.configs, function(a, b)
                return (a.timestamp or 0) > (b.timestamp or 0)
            end)
            
            self:save_cache()
            
            local ok, json_str = pcall(json.stringify, {configs = self.configs})
            if not ok then
                self.loading = false
                push_notify("Failed to encode data ")
                table.remove(self.configs, #self.configs)
                return false
            end
            
            http.put(self.api_url, {
                headers = {
                    ["Content-Type"] = "application/json",
                    ["X-Master-Key"] = self.api_key,
                    ["X-Bin-Meta"] = "false"
                },
                body = json_str
            }, function(success, response)
                self.loading = false
                
                if not success then
                    push_notify("Upload failed: Connection error")
                    table.remove(self.configs, #self.configs)
                    self:save_cache()
                    return
                end
                
                if response.status ~= 200 then
                    push_notify("Upload failed: " .. (response.status or "Unknown"))
                    table.remove(self.configs, #self.configs)
                    self:save_cache()
                    
                    if response.body then
                        local ok_parse, body_data = pcall(json.parse, response.body)
                        if ok_parse and body_data and body_data.message then
                            push_notify("Error: " .. body_data.message)
                        end
                    end
                    return
                end
                
                push_notify("Config '" .. config_name .. "' uploaded to cloud! ")
                self:update_listbox()
                self:save_cache()
            end)
            
            return true
        end


        function cloud_system:refresh()
            local now = globals.realtime()
            if now - self.last_refresh < self.refresh_interval then
                local wait = math.ceil(self.refresh_interval - (now - self.last_refresh))
                push_notify("Please wait " .. wait .. " seconds before refreshing ")
                return false
            end
            
            if self.loading then
                push_notify("Already loading... ")
                return false
            end
            
            self.loading = true
            self.last_refresh = now
            
            http.get(self.api_url .. "/latest", {
                headers = {
                    ["X-Master-Key"] = self.api_key
                }
            }, function(success, response)
                self.loading = false
                
                if not success then
                    push_notify("Failed to connect to cloud ")
                    return
                end
                
                if response.status ~= 200 then
                    push_notify("Failed to load cloud configs: " .. response.status)
                    return
                end
                
                local ok, data = pcall(json.parse, response.body)
                if not ok or not data or not data.record then
                    push_notify("Invalid cloud data format ")
                    return
                end
                
                self.configs = data.record.configs or {}

                for i, cfg in ipairs(self.configs) do
                    if not cfg.liked_by then
                        cfg.liked_by = {}
                    end
                end
                
                
                table.sort(self.configs, function(a, b)
                    return (a.timestamp or 0) > (b.timestamp or 0)
                end)
                
                self:update_listbox()
                self:save_cache()
                
                push_notify("Loaded " .. #self.configs .. " cloud configs! ")
            end)
            
            return true
        end


        function cloud_system:load_selected(index)
            if index < 1 or index > #self.configs then
                push_notify("Invalid config selection ")
                return false
            end
            
            local config = self.configs[index]
            if not config or not config.data then
                push_notify("Config data missing ")
                return false
            end
            
            local cfg = config.data.LUASENSE
            if not cfg then
                push_notify("Invalid config format ")
                return false
            end
            
            
            if cfg.menu then
                for category, items in pairs(cfg.menu) do
                    for key, value in pairs(items) do
                        if menu[category] and menu[category][key] then
                            pcall(function()
                                if type(value) == "table" then
                                    ui.set(menu[category][key], unpack(value))
                                else
                                    ui.set(menu[category][key], value)
                                end
                            end)
                        end
                    end
                end
            end
            
            
            for state, teams in pairs(cfg) do
                if state == "menu" then goto skip_state end
                if not aa[state] then goto skip_state end
                for team, sections in pairs(teams or {}) do
                    if not aa[state][team] then goto skip_team end
                    for section_name, section in pairs(sections or {}) do
                        if section_name == "type" then
                            pcall(ui.set, aa[state][team].type, section)
                        elseif type(section) == "table" and aa[state][team][section_name] then
                            for k, v in pairs(section) do
                                local ctrl = aa[state][team][section_name][k]
                                if ctrl then
                                    pcall(function()
                                        if type(v) == "table" then
                                            ui.set(ctrl, unpack(v))
                                        else
                                            ui.set(ctrl, v)
                                        end
                                    end)
                                end
                            end
                        end
                    end
                    ::skip_team::
                end
                ::skip_state::
            end
            
            
            config.downloads = (config.downloads or 0) + 1
            self:save_cache()
            
            push_notify("Loaded '" .. config.name .. "' by " .. (config.author or "Unknown"))
            return true
        end


        function cloud_system:delete_selected(index)
            if index < 1 or index > #self.configs then
                push_notify("Invalid config selection ")
                return false
            end
            
            local config = self.configs[index]
            
            local function normalize(s) return tostring(s or ""):gsub("%s+", ""):lower() end
            if normalize(config.author) ~= normalize(self.username or username) then
                push_notify("You can only delete your own configs! ")
                return false
            end
            
            table.remove(self.configs, index)
            
            
            self:save_cache()
            self:update_listbox()
            
            
            local ok, json_str = pcall(json.stringify, {configs = self.configs})
            if not ok then
                push_notify("Failed to encode data ")
                return false
            end
            
            http.put(self.api_url, {
                headers = {
                    ["Content-Type"] = "application/json",
                    ["X-Master-Key"] = self.api_key,
                    ["X-Bin-Meta"] = "false"
                },
                body = json_str
            }, function(success, response)
                if success and response.status == 200 then
                    push_notify("Config deleted from cloud! ")
                else
                    push_notify("Failed to delete config from server ")
                end
            end)
            
            return true
        end


        function cloud_system:update_listbox()
            local items = {}
            for i, cfg in ipairs(self.configs) do
                local date = cfg.date or "Unknown"
                local author = cfg.author or "Unknown"
                local downloads = cfg.downloads or 0
                local likes = cfg.likes or 0
                local name = cfg.name or "Unnamed"
                
                local is_own = (author == self.username)
                local prefix = is_own and " " or ""

                table.insert(items, string.format("%s%s %s %d  %d",
                    prefix, name, author, downloads, likes, date))
            end
            
            ui.update(menu["config"]["cloud_list"], items)
        end



        cloud_system.username = js.MyPersonaAPI.GetName() or "Anonymous"


        client.delay_call(0.1, function()
            cloud_system:load_cache()
        end)


        client.set_event_callback("shutdown", function()
            cloud_system:save_cache()
        end)


        local last_cloud_save = 0
        client.set_event_callback("paint", function()
            local now = globals.realtime()
            if now - last_cloud_save >= 30 then
                cloud_system:save_cache()
                last_cloud_save = now
            end
        end)

            menu = {

                ["rage"] = {
                    remove_3d_sky = ui.new_checkbox("aa", "anti-aimbot angles", prefix("remove 3d sky"), true),
                    resolver = ui.new_combobox("aa", "anti-aimbot angles", prefix("target name indicator"), {"no", "yes"}),
                    resolver_color = ui.new_color_picker("aa", "anti-aimbot angles", prefix("target name indicator color"), 255, 255, 255, 200),
                    aaresolver = ui.new_checkbox("aa", "anti-aimbot angles", prefix("resolver"))
                },
                ["anti aimbot"] = {
                    submenu = ui.new_combobox("aa", "anti-aimbot angles", "\nmenu", {"builder", "keybinds", "features"}),
                    ["builder"] = {
                        builder = ui.new_combobox("aa", "anti-aimbot angles", prefix("builder"), tbl.states),
                        team = ui.new_combobox("aa", "anti-aimbot angles", "\nteam", {"ct", "t"}),
                        tickbaseoverride1 = ui.new_slider("aa", "anti-aimbot angles", prefix("tickbase"), 0, 64, 0, true, "t", 1, {
                            [0]  = "gamesense",
                            [16] = "neverlose"
                        }),
                        tbvariability = ui.new_slider("aa", "anti-aimbot angles", prefix("variability"), 0, 100, 0, true, "%"),
                    },
                    ["keybinds"] = {
                        keys = ui.new_multiselect("aa", "anti-aimbot angles", prefix("keys"), {"manual", "edge", "freestand"}),
                        left = ui.new_hotkey("aa", "anti-aimbot angles", prefix("left")),
                        right = ui.new_hotkey("aa", "anti-aimbot angles", prefix("right")),
                        forward = ui.new_hotkey("aa", "anti-aimbot angles", prefix("forward")),
                        backward = ui.new_hotkey("aa", "anti-aimbot angles", prefix("backward")),
                        type_manual = ui.new_combobox("aa", "anti-aimbot angles", prefix("manual"), {"default", "jitter", "static"}),
                        edge = ui.new_hotkey("aa", "anti-aimbot angles", prefix("edge")),
                        type_freestand = ui.new_combobox("aa", "anti-aimbot angles", prefix("freestand"), {"default", "jitter", "static"}),
                        freestand = ui.new_hotkey("aa", "anti-aimbot angles", "\nfreestand", true),
                        disablers = ui.new_multiselect("aa", "anti-aimbot angles", prefix("fs disablers"), {"air", "slow", "duck", "edge", "manual", "fake lag"})
                    },
                    ["features"] = {
                        legit = ui.new_combobox("aa", "anti-aimbot angles", prefix("legit"), {"off", "default", "luasense"}),
                        fix = ui.new_multiselect("aa", "anti-aimbot angles", "\nfix", {"generic", "bombsite"}),
                        defensive = ui.new_combobox("aa", "anti-aimbot angles", prefix("defensive"), {"off", "pitch", "spin", "random", "random pitch", "sideways down", "sideways up"}),
                        fixer = ui.new_combobox("aa", "anti-aimbot angles", "\nfixer", {"default", "luasense"}),
                        states = ui.new_multiselect("aa", "anti-aimbot angles", "\nstates\n", {"standing", "moving", "air", "air duck", "duck", "duck moving", "slow motion"}),
                        backstab = ui.new_combobox("aa", "anti-aimbot angles", prefix("backstab"), {"off", "forward", "random"}),
                        distance = ui.new_slider("aa", "anti-aimbot angles", "\nbackstab", 100, 500, 250),
                        roll = ui.new_slider("aa", "anti-aimbot angles", prefix("roll"), -45, 45, 0),
                        discharge = ui.new_checkbox("aa", "anti-aimbot angles", prefix("automatic exploit discharge")),
                        enableautohs = ui.new_checkbox("aa", "anti-aimbot angles", prefix("auto hide shots")),
                        autohs = ui.new_multiselect("aa", "anti-aimbot angles", prefix("guns"), {"pistols", "automatics", "scout", "awp","all"}),
                        autohscond = ui.new_multiselect("aa", "anti-aimbot angles", prefix("conditions"), {"standing", "duck", "duck moving"}),
                        safeheadonknife = ui.new_checkbox("aa", "anti-aimbot angles", prefix("safe head on knife")),
                    },
                },
                ["visuals & misc"] = {
                    submenu = ui.new_combobox("aa", "anti-aimbot angles", "\nvisuals & misc", {"visuals", "misc"}),
                    ["visuals"] = {
                        devPrint = ui.new_checkbox("aa", "anti-aimbot angles", prefix("old console logs")),
                        usernametip = ui.new_label("aa", "anti-aimbot angles", "username"),
                        useridls = ui.new_textbox("aa", "anti-aimbot angles", prefix("username"), "luasense"),
                        wtext = ui.new_combobox("aa", "anti-aimbot angles", prefix("watermark"), {" luasense ", "luasense beta", "luasync.max2", "luasync.max", " luasense", "luasense ", "luasense", "custom"}),
                        watermark = ui.new_combobox("aa", "anti-aimbot angles", prefix("always on", "watermark"), {"bottom", "right", "left", "custom"}),
                        notify_tip15 = ui.new_label("aa", "anti-aimbot angles", "watermark text"),
                        custom_wtext = ui.new_textbox("aa", "anti-aimbot angles", prefix("custom watermark text")),
                        watermark_color = ui.new_color_picker("aa", "anti-aimbot angles", "\nwatermark", 150, 200, 69, 255),
                        notify_tip16 = ui.new_label("aa", "anti-aimbot angles", "prefix text"),
                        custom_prefix = ui.new_textbox("aa", "anti-aimbot angles", prefix("custom prefix")),
                        custom_prefix_color = ui.new_color_picker("aa", "anti-aimbot angles", prefix("custom prefix color"), 185, 64, 63, 255),  
                        notify_tip22 = ui.new_label("aa", "anti-aimbot angles", "prefix 2 text"),
                        custom_prefix2 = ui.new_textbox("aa", "anti-aimbot angles", prefix("custom prefix")),
                        custom_prefix2_color = ui.new_color_picker("aa", "anti-aimbot angles", prefix("custom prefix color"), 255, 255, 255, 255),  
                        watermark_x_offset = ui.new_slider("aa", "anti-aimbot angles", prefix("wutermark x offset"), -1920, 1080, 0, true, "px"),
                        watermark_y_offset = ui.new_slider("aa", "anti-aimbot angles", prefix("wutermark y offset"), -1920, 1080, 0, true, "px"),
                        watermark_animation = ui.new_checkbox("aa", "anti-aimbot angles", prefix("enable watermark animation"), true),
                        prefix_animation = ui.new_checkbox("aa", "anti-aimbot angles", prefix("enable prefix animation"), true),
                        prefix2_animation = ui.new_checkbox("aa", "anti-aimbot angles", prefix("enable other prefix animation"), true),
                        wfont = ui.new_combobox("aa", "anti-aimbot angles", prefix("wutermark font"), {"normal", "small", "bold"}),
                        watermark_spaces = ui.new_combobox("aa", "anti-aimbot angles", prefix("remove spaces"), {"yes", "no"}),
                        uppercase = ui.new_combobox("aa", "anti-aimbot angles", prefix("uppercase watermark"), {"yes", "no"}),
                        hitmark_enable = ui.new_combobox("aa", "anti-aimbot angles", prefix("world hitmarker"), {"no", "yes"}),
                        notify_tip11 = ui.new_label("aa", "anti-aimbot angles", "world hitmarker color"),
                        hitmark_color = ui.new_color_picker("aa", "anti-aimbot angles", "world hitmarker color", 42, 202, 144, 255),
                        debug_panel = ui.new_checkbox("aa", "anti-aimbot angles", prefix("debug panel"), false),
                        debug_customp = ui.new_checkbox("aa", "anti-aimbot angles", prefix("custom debug panel"), true),
                        debugtip = ui.new_label("aa", "anti-aimbot angles", "debug panel prefix"),
                        debug_custom = ui.new_textbox("aa", "anti-aimbot angles", prefix("custom debug panel text"), "luasense"),
                        notmark_centered = ui.new_checkbox("aa", "anti-aimbot angles", prefix("center notification prefix"), true),
                        notify = ui.new_multiselect("aa", "anti-aimbot angles", prefix("notify"), {"hit", "miss", "shot", "reset"}),
                        logs = ui.new_multiselect("aa", "anti-aimbot angles", prefix("console logs"), {"hit", "miss","advanced", "dormant hit", "dormant miss", "buy"}),
                        notify_tip103 = ui.new_label("aa", "anti-aimbot angles", "notify background color"),
                        notbackground_color = ui.new_color_picker("aa", "anti-aimbot angles", prefix("notification background color"), 25, 25, 25, 255),
                        notify_tip2 = ui.new_label("aa", "anti-aimbot angles", "notification color (shot and reset)"),
                        notcolor = ui.new_color_picker("aa", "anti-aimbot angles", "notify color", 150, 200, 69, 255),
                        notify_tip104 = ui.new_label("aa", "anti-aimbot angles", "notify hit glow color"),
                        notglow_hit_color = ui.new_color_picker("aa", "anti-aimbot angles", prefix("notify hit glow color"), 150, 200, 69, 255),
                        notify_tip105 = ui.new_label("aa", "anti-aimbot angles", "notify miss glow color"),
                        notglow_miss_color = ui.new_color_picker("aa", "anti-aimbot angles", prefix("notify miss glow color"), 200, 69, 69, 255),
                        notify_tip3 = ui.new_label("aa", "anti-aimbot angles", "notify hit color"),
                        notcolor2 = ui.new_color_picker("aa", "anti-aimbot angles", "notify hit color", 150, 200, 69, 255),
                        notify_tip4 = ui.new_label("aa", "anti-aimbot angles", "notify miss color"),
                        notcolor3 = ui.new_color_picker("aa", "anti-aimbot angles", "notify miss color", 200, 69, 69, 255),
                        notify_tip18 = ui.new_label("aa", "anti-aimbot angles", "prefix hit color"),
                        notmark_hit_prefix_color = ui.new_color_picker("aa", "anti-aimbot angles", prefix("notify hit prefix color"), 150, 200, 69, 255),
                        notify_tip19 = ui.new_label("aa", "anti-aimbot angles", "prefix miss color"),
                        notmark_miss_prefix_color = ui.new_color_picker("aa", "anti-aimbot angles", prefix("notify miss prefix color"), 200, 69, 69, 255),
                        notify_tip101 = ui.new_label("aa", "anti-aimbot angles", "| hit color"),
                        notmark_hit_separator_color = ui.new_color_picker("aa", "anti-aimbot angles", prefix("notify hit separator color"), 150, 200, 69, 255),
                        notify_tip102 = ui.new_label("aa", "anti-aimbot angles", "| miss color"),
                        notmark_miss_separator_color = ui.new_color_picker("aa", "anti-aimbot angles", prefix("notify miss separator color"), 200, 69, 69, 255),
                        notheight = ui.new_slider("aa", "anti-aimbot angles", prefix("notify height"), -25, 25, 23, true, "px"),
                        notmarkheight = ui.new_slider("aa", "anti-aimbot angles", prefix("notify marker height"), -25.5, 25.5, 9.5, true, "px"),
                        notmarkseparatorheight = ui.new_slider("aa", "anti-aimbot angles", prefix("notify separator height"), -25, 25, 12, true, "px"),
                        notmarkoffset = ui.new_slider("aa", "anti-aimbot angles", prefix("notify marker offset"), -25, 25, 2, true, "px"),
                        notmarkxoffset = ui.new_slider("aa", "anti-aimbot angles", prefix("notify marker x offset"), -50, 50, 0, true, "px"),
                        notglow = ui.new_slider("aa", "anti-aimbot angles", prefix("notify glow"), 0, 25, 17, true, "px"),
                        notrounding = ui.new_slider("aa", "anti-aimbot angles", prefix("notify rounding"), 0, 25, 10, true, "px"),
                        notmark = ui.new_combobox("aa", "anti-aimbot angles", prefix("notify common letter"), {"L", "E", "W", "⚠", "", "", "", "", "", "", "luasense", "custom"}),
                        notmark2 = ui.new_combobox("aa", "anti-aimbot angles", prefix("notify miss letter"), { "L", "E", "W", "⚠", "", "", "", "", "", "", "luasense", "custom"}),
                        notmarkfont = ui.new_combobox("aa", "anti-aimbot angles", prefix("notify prefix font"), {"bold", "small", "normal"}),
                        notmarkseparator = ui.new_combobox("aa", "anti-aimbot angles", prefix("notify separator"), {"yes", "no"}),
                        notmarkuppercase = ui.new_combobox("aa", "anti-aimbot angles", prefix("notify prefix uppercase"), {"yes", "no"}),
                        notify_tip12 = ui.new_label("aa", "anti-aimbot angles", "custom hit prefix"),
                        custom_notmark_hit = ui.new_textbox("aa", "anti-aimbot angles", prefix("custom notify hit prefix")),
                        notify_tip13 = ui.new_label("aa", "anti-aimbot angles", "custom miss prefix"),
                        custom_notmark_miss = ui.new_textbox("aa", "anti-aimbot angles", prefix("custom notify miss prefix")),
                        slowdown_indicator = ui.new_checkbox("aa", "anti-aimbot angles", prefix("Slowdown indicator"), false),
                        slowdown_color = ui.new_color_picker("aa", "anti-aimbot angles", prefix("Slowdown indicator color"), 150, 200, 69, 255),
                        arrows = ui.new_combobox("aa", "anti-aimbot angles", prefix("arrows"), {"-", "simple", "body", "luasense"}),
                        arrows_color = ui.new_color_picker("aa", "anti-aimbot angles", "\narrows", 137, 245, 150, 255),
                        indicators = ui.new_combobox("aa", "anti-aimbot angles", prefix("indicators"), {"-", "default", "luasense", "custom"}),
                        indicators_color = ui.new_color_picker("aa", "anti-aimbot angles", "\nindicators", 137, 245, 150, 255),
                        custom_indicator_text = ui.new_textbox("aa", "anti-aimbot angles", prefix("custom indicator text")),
                    },
                    ["misc"] = {
                        features = ui.new_multiselect("aa", "anti-aimbot angles", prefix("features"), {"fix hideshot", "animations", "legs spammer", "dt_os_recharge_fix", "killsay", "spin on round end/warmup"}),
                        spammer = ui.new_slider("aa", "anti-aimbot angles", prefix("legs"), 1, 9, 1),
                        autobuy = ui.new_combobox("aa", "anti-aimbot angles", prefix("auto buy"), {"off", "awp", "scout"})
                    }
                    
                },
        ["config"] = {
            category_label = ui.new_label("aa", "anti-aimbot angles", prefix("config system")),
            category = ui.new_combobox("aa", "anti-aimbot angles", prefix("category"), {"local", "cloud"}),
            
            separator = ui.new_label("aa", "anti-aimbot angles", "\n "),
            
            -- LOCAL CONFIGS
            local_label = ui.new_label("aa", "anti-aimbot angles", prefix("local configs")),
            local_list = ui.new_listbox("aa", "anti-aimbot angles", "\nlocal configs", {}),
            local_name = ui.new_textbox("aa", "anti-aimbot angles", prefix("config name")),
            
            local_save = ui.new_button("aa", "anti-aimbot angles", "\a32a852FFsave", function()
                local cfg_name = ui.get(menu["config"]["local_name"])
                if not cfg_name or cfg_name == "" then
                    push_notify("Please enter a config name ")
                    return
                end
                
                local success = config_file.save(cfg_name)
                
                if success then
                    -- Update listbox
                    local items = {}
                    local list = config_file.list()
                    for i, entry in ipairs(list) do
                        table.insert(items, string.format("%s [%s]", entry.name, entry.date))
                    end
                    ui.update(menu["config"]["local_list"], items)
                    push_notify("Config '" .. cfg_name .. "' saved! ")
                else
                    push_notify("Failed to save config ")
                end
            end),
            
            local_load = ui.new_button("aa", "anti-aimbot angles", "\a89f596FFload", function()
                local list = config_file.list()
                local selected_idx = ui.get(menu["config"]["local_list"]) + 1
                
                if selected_idx <= 0 or selected_idx > #list then
                    push_notify("Please select a config to load ")
                    return
                end
                
                local cfg_name = list[selected_idx].name
                local config = config_file.load(cfg_name)
                
                if config then
                    push_notify("Config '" .. cfg_name .. "' loaded! ")
                else
                    push_notify("Failed to load config ")
                end
            end),
            
            local_delete = ui.new_button("aa", "anti-aimbot angles", "\aC84632FFdelete", function()
                local list = config_file.list()
                local selected_idx = ui.get(menu["config"]["local_list"]) + 1
                
                if selected_idx <= 0 or selected_idx > #list then
                    push_notify("Please select a config to delete ")
                    return
                end
                
                local cfg_name = list[selected_idx].name
                local success = config_file.delete(cfg_name)
                
                if success then
                    -- Update listbox
                    local items = {}
                    local new_list = config_file.list()
                    for i, entry in ipairs(new_list) do
                        table.insert(items, string.format("%s [%s]", entry.name, entry.date))
                    end
                    ui.update(menu["config"]["local_list"], items)
                    
                    -- Also delete from cloud if it exists
                    pcall(function()
                        for i = #cloud_system.configs, 1, -1 do
                            local cloud_cfg = cloud_system.configs[i]
                            if cloud_cfg.name == cfg_name then
                                local function normalize(s) return tostring(s or ""):gsub("%s+", ""):lower() end
                                if normalize(cloud_cfg.author) == normalize(cloud_system.username or username) then
                                    table.remove(cloud_system.configs, i)
                                    
                                    local ok, json_str = pcall(json.stringify, {configs = cloud_system.configs})
                                    if ok then
                                        http.put(cloud_system.api_url, {
                                            headers = {
                                                ["Content-Type"] = "application/json",
                                                ["X-Master-Key"] = cloud_system.api_key,
                                                ["X-Bin-Meta"] = "false"
                                            },
                                            body = json_str
                                        }, function(success, response)
                                            if success and response.status == 200 then
                                                cloud_system:update_listbox()
                                                cloud_system:save_cache()
                                            end
                                        end)
                                    end
                                end
                                break
                            end
                        end
                    end)
                    
                    push_notify("Config '" .. cfg_name .. "' deleted! ")
                else
                    push_notify("Failed to delete config ")
                end
            end),
            
            local_export = ui.new_button("aa", "anti-aimbot angles", "\a89f596FFexport", function()
                local list = config_file.list()
                local selected_idx = ui.get(menu["config"]["local_list"]) + 1
                
                if selected_idx <= 0 or selected_idx > #list then
                    push_notify("Please select a config to export ")
                    return
                end
                
                local cfg_name = list[selected_idx].name
                local encoded = config_file.export(cfg_name)
                
                if encoded then
                    clipboard_lib.set(encoded)
                    push_notify("Config '" .. cfg_name .. "' copied to clipboard! ")
                else
                    push_notify("Failed to export config ")
                end
            end),
            
            local_import = ui.new_button("aa", "anti-aimbot angles", "\a32a852FFimport", function()
                local clipboard_text = clipboard_lib.get()
                
                if not clipboard_text or clipboard_text == "" then
                    push_notify("Clipboard is empty ")
                    return
                end
                
                local cfg_name = ui.get(menu["config"]["local_name"])
                if not cfg_name or cfg_name == "" then
                    push_notify("Please enter a name for imported config ")
                    return
                end
                
                local config, err = config_file.import(clipboard_text, cfg_name)
                
                if config then
                    config_file.load(cfg_name)
                    
                    local items = {}
                    local list = config_file.list()
                    for i, entry in ipairs(list) do
                        table.insert(items, string.format("%s [%s]", entry.name, entry.date))
                    end
                    ui.update(menu["config"]["local_list"], items)
                    
                    push_notify("Config imported! ")
                else
                    push_notify("Failed to import: " .. (err or "unknown error") .. " ")
                end
            end),
            
            local_upload = ui.new_button("aa", "anti-aimbot angles", "\a32a852FFupload to cloud", function()
                local list = config_file.list()
                local selected_idx = ui.get(menu["config"]["local_list"]) + 1
                
                if selected_idx <= 0 or selected_idx > #list then
                    push_notify("Please select a config to upload ")
                    return
                end
                
                local cfg_name = list[selected_idx].name
                local config = config_file.load(cfg_name)
                
                if not config then
                    push_notify("Config data not found ")
                    return
                end
                
                cloud_system:upload(cfg_name, config)
            end),
            
            -- CLOUD CONFIGS
            cloud_label = ui.new_label("aa", "anti-aimbot angles", prefix("cloud configs")),
            cloud_list = ui.new_listbox("aa", "anti-aimbot angles", "\ncloud configs", {}),
            
            cloud_refresh = ui.new_button("aa", "anti-aimbot angles", "\a89f596FFrefresh", function()
                cloud_system:refresh()
            end),
            
            cloud_load = ui.new_button("aa", "anti-aimbot angles", "\a32a852FFload", function()
                local selected_idx = ui.get(menu["config"]["cloud_list"]) + 1
                cloud_system:load_selected(selected_idx)
            end),
            
            cloud_like = ui.new_button("aa", "anti-aimbot angles", "\a89CFF0FFlike", function()
                local selected_idx = ui.get(menu["config"]["cloud_list"]) + 1
                cloud_system:like_selected(selected_idx)
            end),
            
            cloud_delete = ui.new_button("aa", "anti-aimbot angles", "\aC84632FFdelete", function()
                local selected_idx = ui.get(menu["config"]["cloud_list"]) + 1
                cloud_system:delete_selected(selected_idx)
            end),
            }
        }

        -- Update listbox on selection change
        client.delay_call(0.2, function()
            ui.set_callback(menu["config"]["local_list"], function()
                local list = config_file.list()
                local selected_idx = ui.get(menu["config"]["local_list"]) + 1
                
                if selected_idx > 0 and selected_idx <= #list then
                    local cfg_name = list[selected_idx].name
                    ui.set(menu["config"]["local_name"], cfg_name)
                end
            end)
        end)

        -- Initialize listbox on startup
        client.delay_call(0.1, function()
            local items = {}
            local list = config_file.list()
            for i, entry in ipairs(list) do
                table.insert(items, string.format("%s [%s]", entry.name, entry.date))
            end
            ui.update(menu["config"]["local_list"], items)
        end)

            for i, v in next, tbl.states do
                aa[v] = {}
                for index, value in next, {"ct", "t"} do
                    aa[v][value] = {
                        ["type"] = ui.new_combobox("aa", "anti-aimbot angles", prefix(v .. " " .. value, "type"), (v == "global" and {"normal", "luasense", "advanced", "auto"} or {"disabled", "normal", "luasense", "advanced", "auto"})),
                        ["normal"] = {
                            mode = ui.new_multiselect("aa", "anti-aimbot angles", prefix(v .. " " .. value, "mode"), {"yaw", "left right"}),
                            yaw = ui.new_slider("aa", "anti-aimbot angles", prefix(v .. " " .. value, "yaw"), -180, 180, 0),
                            left = ui.new_slider("aa", "anti-aimbot angles", prefix(v .. " " .. value, "left"), -180, 180, 0),
                            right = ui.new_slider("aa", "anti-aimbot angles", prefix(v .. " " .. value, "right"), -180, 180, 0),
                            method = ui.new_combobox("aa", "anti-aimbot angles", prefix(v .. " " .. value, "method"), {"default", "luasense"}),
                            jitter = ui.new_combobox("aa", "anti-aimbot angles", prefix(v .. " " .. value, "jitter"), {"off", "offset", "center", "random", "skitter"}),
                            jitter_slider = ui.new_slider("aa", "anti-aimbot angles", "\njitter slider " .. v .. " " .. value, -180, 180, 0),
                            body = ui.new_combobox("aa", "anti-aimbot angles", prefix(v .. " " .. value, "body"), {"off", "luasense", "opposite", "static", "jitter"}),
                            body_slider = ui.new_slider("aa", "anti-aimbot angles", "\nbody slider " .. v .. " " .. value, -180, 180, 0),
                            custom_slider = ui.new_slider("aa", "anti-aimbot angles", "\ncustom slider " .. v .. " " .. value, 0, 60, 60),
                            defensive = ui.new_combobox("aa", "anti-aimbot angles", prefix(v .. " " .. value, "defensive"), {"off", "always on", "luasense"})
                        },
                        ["luasense"] = {
                            luasense_mode = ui.new_combobox("aa", "anti-aimbot angles", prefix(v .. " " .. value, "delay mode"), {"fixed", "random", "min/max"}),
                            luasense = ui.new_slider("aa", "anti-aimbot angles", prefix(v .. " " .. value, "delay"), 1, 22, 1),
                            luasense_random_max = ui.new_slider("aa", "anti-aimbot angles", prefix(v .. " " .. value, "random max"), 1, 22, 4),
                            luasense_min = ui.new_slider("aa", "anti-aimbot angles", prefix(v .. " " .. value, "min delay"), 1, 22, 1),
                            luasense_max = ui.new_slider("aa", "anti-aimbot angles", prefix(v .. " " .. value, "max delay"), 1, 22, 4),
                            mode = ui.new_multiselect("aa", "anti-aimbot angles", prefix(v .. " " .. value, "mode\n"), {"yaw", "left right"}),
                            yaw = ui.new_slider("aa", "anti-aimbot angles", prefix(v .. " " .. value, "yaw\n"), -180, 180, 0),
                            left = ui.new_slider("aa", "anti-aimbot angles", prefix(v .. " " .. value, "left\n"), -180, 180, 0),
                            right = ui.new_slider("aa", "anti-aimbot angles", prefix(v .. " " .. value, "right\n"), -180, 180, 0),
                            fake = ui.new_slider("aa", "anti-aimbot angles", prefix(v .. " " .. value, "fake"), 0, 60, 60),
                            defensive = ui.new_combobox("aa", "anti-aimbot angles", prefix(v .. " " .. value, "defensive\n"), {"off", "always on", "luasense"})

                        },
                        ["advanced"] = {
                            trigger = ui.new_combobox("aa", "anti-aimbot angles", prefix(v .. " " .. value, "trigger"), {"a: brandon", "b: best", "c: experimental", "automatic"}),
                            left = ui.new_slider("aa", "anti-aimbot angles", prefix(v .. " " .. value, "left\n\n"), -180, 180, 0),
                            right = ui.new_slider("aa", "anti-aimbot angles", prefix(v .. " " .. value, "right\n\n"), -180, 180, 0),
                            defensive = ui.new_combobox("aa", "anti-aimbot angles", prefix(v .. " " .. value, "defensive\n\n\n"), {"off", "always on", "luasense"})
                        },
                        ["auto"] = {
                            method = ui.new_combobox("aa", "anti-aimbot angles", prefix(v .. " " .. value, "method\n"), {"simple", "luasense"}),
                            left = ui.new_slider("aa", "anti-aimbot angles", prefix(v .. " " .. value, "left\n\n\n"), -180, 180, 0),
                            right = ui.new_slider("aa", "anti-aimbot angles", prefix(v .. " " .. value, "right\n\n\n"), -180, 180, 0),
                            enablerand = ui.new_checkbox("aa", "anti-aimbot angles", prefix(v .. " " .. value, "enable yaw randomization")),
                            randomization = ui.new_slider("aa", "anti-aimbot angles", prefix(v .. " " .. value, "randomization"), 0, 100, 0, true, "%"),
                            delay_mode = ui.new_combobox("aa", "anti-aimbot angles", prefix(v .. " " .. value, "delay mode\n"), {"fixed", "random", "min/max", "exponential", "experimental"}),
                            delay = ui.new_slider("aa", "anti-aimbot angles", prefix(v .. " " .. value, "delay\n"), 1, 22, 1, true, "t"),
                            random_max = ui.new_slider("aa", "anti-aimbot angles", prefix(v .. " " .. value, "random max\n"), 1, 22, 4, true, "t"),
                            min_delay = ui.new_slider("aa", "anti-aimbot angles", prefix(v .. " " .. value, "min delay\n"), 1, 22, 1, true, "t"),
                            max_delay = ui.new_slider("aa", "anti-aimbot angles", prefix(v .. " " .. value, "max delay\n"), 1, 22, 4, true, "t"),
                            delay_exponentialfunction = ui.new_slider("aa", "anti-aimbot angles", prefix(v .. " " .. value, "delay exponential"), 1, 22, 1, true, "t"),
                            delay_exponential_min = ui.new_slider("aa", "anti-aimbot angles", prefix(v .. " " .. value, "delay exponential min"), 1, 22, 1, true, "t"),
                            delay_exponential_max = ui.new_slider("aa", "anti-aimbot angles", prefix(v .. " " .. value, "delay exponential max"), 1, 22, 4, true, "t"),                    
                            body1 = ui.new_combobox("aa", "anti-aimbot angles", prefix(v .. " " .. value, "body"), {"off", "luasense", "opposite", "static", "jitter"}),
                            body_slider1 = ui.new_slider("aa", "anti-aimbot angles", "\nbody slider " .. v .. " " .. value, -180, 180, 0),
                            custom_slider1 = ui.new_slider("aa", "anti-aimbot angles", "\ncustom slider " .. v .. " " .. value, 0, 60, 60),
                            breaklc = ui.new_checkbox("aa", "anti-aimbot angles", prefix(v .. " " .. value, "break lagcompensation")),
                            antibf = ui.new_combobox("aa", "anti-aimbot angles", prefix(v .. " " .. value, "bruteforce"), {"no", "yes"}),
                            timertxt = ui.new_label("aa", "anti-aimbot angles", prefix"timer"),
                            timer = ui.new_slider("aa", "anti-aimbot angles", "\ntimer", 50, 1000, 150, true, "ms"),
                            defensive = ui.new_combobox("aa", "anti-aimbot angles", prefix(v .. " " .. value, "defensive\n\n"), {"off", "always on", "luasense"}),
                            forcedeffon = ui.new_multiselect("aa", "anti-aimbot angles", prefix(v .. " " .. value, "force defensive\n\n"), {"on realoding", "on weapon switch", "on shot"}),
                        }, 
                        
                        ["disabled"] = {},
                        ["button"] = ui.new_button("aa", "anti-aimbot angles", "\a32a852FFsend to \a89f596FF" .. (value == "t" and "ct" or "t"), function()
                            local state = ui.get(menu["anti aimbot"]["builder"]["builder"])
                            local team = ui.get(menu["anti aimbot"]["builder"]["team"])
                            local target = (team == "t" and "ct" or "t")
                            for i, v in next, aa[state][team] do
                                if i ~= "button" then
                                    if i == "type" then
                                        ui.set(aa[state][target][i], ui.get(v))
                                    else
                                        for index, value in next, v do
                                            ui.set(aa[state][target][i][index], ui.get(value))
                                        end
                                    end
                                end
                            end
                        end)
                    }
                end
            end

            local timer = globals.tickcount()
            local scriptleakstop = 14


            local ctx = (function()
                local ctx = {}
            
                ctx.recharge = {
                    run = function()
                        if not tbl.contains(ui.get(menu["visuals & misc"]["misc"]["features"]), "dt_os_recharge_fix") then
                            return
                        end
            
                        local lp = entity.get_local_player()
                
                        if not entity.is_alive(lp) then return end
                
                        local lp_weapon = entity.get_player_weapon(lp)
                        if not lp_weapon then return end
                        
                        local wp_class = entity.get_classname(lp_weapon) or ""
                        if wp_class == "CWeaponTaser" or wp_class == "CWeaponZeus" then
                            return
                        end
                        
                        scriptleakstop = weapons(lp_weapon).is_revolver and 17 or 14
                
                        if ui.get(menu_refs["doubletap"][2]) or ui.get(menu_refs["hideshots"][2]) then
                            if globals.tickcount() >= timer + scriptleakstop then
                                ui.set(menu_refs["aimbot"], true)
                            else
                                ui.set(menu_refs["aimbot"], false)
                            end
                        else
                            timer = globals.tickcount()
                            ui.set(menu_refs["aimbot"], true)
                        end
                    end
                }
            
                return ctx
            end)()
            
            client.set_event_callback('setup_command', function(cmd)
                ctx.recharge.run()
            end)
            
            tbl.refs = {
                slow = tbl.ref("aa", "other", "slow motion"),
                hide = tbl.ref("aa", "other", "on shot anti-aim"),
                dt = tbl.ref("rage", "aimbot", "double tap")
            }
            tbl.antiaim = {
                luasensefake = false,
                autocheck = false,
                current = false,
                active = false,
                count = false,
                ready = false,
                timer = 0,
                fs = 0,
                last = 0,
                log = {},
                log_max_entries = 64,
                learn_threshold = 2,
                luasense_delay_cache = {},
                luasense_prog_cache = {},
                temp = {},
                temp_ttl = 5,
                persist_ttl = 604800,
                manual = {
                    aa = 0,
                    tick = 0
                },
            discharge = {
                saved_dt_state = nil,   
                last_trigger_tick = 0,  
                cooldown_ticks = 14,     
                pending_reenable = false,
                reenable_tick = 0,
                break_ticks = 6,        
                active_until = 0,       
                _overrode_dt = false,
                debug_msg = nil,       
                debug_until = 0, 
                _used_tickbase = false
            },
            auto_rand_cache = {},
            autohs_active = false   
            }

        do
            tbl.tickbase_override = tbl.tickbase_override or {
                active = false,
                mode = "adaptive",
                value = nil,
                teams = "both",
                
                -- Server CVar integration
                sv_maxunlag = 0.5,
                sv_minupdaterate = 10,
                sv_maxupdaterate = 128,
                sv_client_min_interp_ratio = 1,
                sv_client_max_interp_ratio = 2,
                tickrate = 64,
                max_rewind_ticks = 12,
                
                -- Adaptive system
                adaptive = {
                    base_offset = 0,
                    variance_pool = {},
                    variance_history = {},
                    performance_map = {},
                    last_adjustment = 0,
                    learning_rate = 0.15,
                    exploration_rate = 0.25,
                    optimal_offset = 0
                },
                
                -- Context awareness
                context = {
                    enemy_distance = 500,
                    enemy_velocity = 0,
                    local_velocity = 0,
                    weapon_type = "rifle",
                    ping = 0,
                    loss = 0,
                    choke = 0,
                    tick_variance = 0
                },
                
                -- Runtime state
                runtime = {},
                builder_val = nil,
                until_tick = 0,
                end_time = 0,
                period = nil,
                persist_key = "tb_override_v2",
                
                -- Statistical tracking
                stats = {
                    total_shots = 0,
                    hits_per_offset = {},
                    misses_per_offset = {},
                    optimal_ranges = {},
                    weapon_profiles = {}
                }
            }
            
            local TB = tbl.tickbase_override
            
            -- Read server CVars for accurate tickbase calculations
            local function update_server_tickbase_info()
                local ok_unlag, maxunlag = pcall(function() return cvar.sv_maxunlag:get_float() end)
                local ok_minrate, minrate = pcall(function() return cvar.sv_minupdaterate:get_int() end)
                local ok_maxrate, maxrate = pcall(function() return cvar.sv_maxupdaterate:get_int() end)
                local ok_minratio, minratio = pcall(function() return cvar.sv_client_min_interp_ratio:get_float() end)
                local ok_maxratio, maxratio = pcall(function() return cvar.sv_client_max_interp_ratio:get_float() end)
                
                TB.sv_maxunlag = (ok_unlag and maxunlag) or 0.5
                TB.sv_minupdaterate = (ok_minrate and minrate) or 10
                TB.sv_maxupdaterate = (ok_maxrate and maxrate) or 128
                TB.sv_client_min_interp_ratio = (ok_minratio and minratio) or 1
                TB.sv_client_max_interp_ratio = (ok_maxratio and maxratio) or 2
                
                TB.tickrate = math.floor(1 / globals.tickinterval() + 0.5)
                TB.max_rewind_ticks = math.floor(TB.sv_maxunlag / globals.tickinterval())
            end
            
            -- Calculate client interpolation and lag compensation window
            local function get_lagcomp_window()
                local cl_interp = cvar.cl_interp:get_float()
                local cl_interp_ratio = cvar.cl_interp_ratio:get_float()
                
                -- Clamp interp_ratio to server limits
                cl_interp_ratio = math.max(TB.sv_client_min_interp_ratio, 
                                            math.min(TB.sv_client_max_interp_ratio, cl_interp_ratio))
                
                local interp_time = math.max(cl_interp, cl_interp_ratio / TB.tickrate)
                local interp_ticks = math.floor(interp_time / globals.tickinterval())
                
                -- Total lag compensation window
                local total_window = TB.max_rewind_ticks + interp_ticks
                
                return {
                    interp_ticks = interp_ticks,
                    backtrack_ticks = TB.max_rewind_ticks,
                    total_ticks = total_window,
                    tickrate = TB.tickrate
                }
            end
            
            -- Get network conditions
            local function get_network_context()
                local latency = client.latency()
                local lp = entity.get_local_player()
                if not lp then return TB.context end
                
                TB.context.ping = latency * 1000
                
                -- Estimate packet loss and choke (approximations)
                local net_channel = client.latency()
                TB.context.loss = 0 -- Would need more direct access
                TB.context.choke = 0
                
                -- Local velocity
                local vx, vy, vz = entity.get_prop(lp, "m_vecVelocity")
                if vx then
                    TB.context.local_velocity = math.sqrt(vx*vx + vy*vy)
                end
                
                -- Enemy context
                local enemy = client.current_threat()
                if enemy then
                    local ex, ey, ez = entity.get_prop(enemy, "m_vecOrigin")
                    local lx, ly, lz = entity.get_prop(lp, "m_vecOrigin")
                    if ex and lx then
                        TB.context.enemy_distance = math.sqrt((ex-lx)^2 + (ey-ly)^2 + (ez-lz)^2)
                    end
                    
                    local evx, evy, evz = entity.get_prop(enemy, "m_vecVelocity")
                    if evx then
                        TB.context.enemy_velocity = math.sqrt(evx*evx + evy*evy)
                    end
                end
                
                -- Weapon type
                local weapon = entity.get_player_weapon(lp)
                if weapon then
                    local classname = entity.get_classname(weapon) or ""
                    if classname:find("AWP") then
                        TB.context.weapon_type = "awp"
                    elseif classname:find("SSG08") then
                        TB.context.weapon_type = "scout"
                    elseif classname:find("Rifle") or classname:find("AK47") or classname:find("M4A") then
                        TB.context.weapon_type = "rifle"
                    elseif classname:find("Pistol") or classname:find("Deagle") or classname:find("Glock") then
                        TB.context.weapon_type = "pistol"
                    else
                        TB.context.weapon_type = "other"
                    end
                end
                
                return TB.context
            end
            
            -- Adaptive tickbase calculation based on context
            local function calculate_adaptive_offset(base_value, variability)
                local ctx = get_network_context()
                local lagcomp = get_lagcomp_window()
                
                -- Base offset from slider
                local base = math.max(0, math.min(22, math.floor(tonumber(base_value) or 0)))
                
                -- Variability percentage
                local var_pct = math.max(0, math.min(100, tonumber(variability) or 0)) / 100
                
                -- Context-based adjustments
                local adjustments = {
                    ping = 0,
                    distance = 0,
                    velocity = 0,
                    weapon = 0,
                    tickrate = 0
                }
                
                -- Ping compensation (higher ping = lower offset to avoid OOB)
                if ctx.ping > 80 then
                    adjustments.ping = -2
                elseif ctx.ping > 50 then
                    adjustments.ping = -1
                elseif ctx.ping < 20 then
                    adjustments.ping = 1
                end
                
                -- Distance-based (closer = higher offset for better peeking)
                if ctx.enemy_distance < 300 then
                    adjustments.distance = 2
                elseif ctx.enemy_distance > 800 then
                    adjustments.distance = -1
                end
                
                -- Velocity-based (moving enemy = lower offset for stability)
                if ctx.enemy_velocity > 200 then
                    adjustments.velocity = -1
                elseif ctx.enemy_velocity < 50 then
                    adjustments.velocity = 1
                end
                
                -- Weapon-specific profiles
                if ctx.weapon_type == "awp" then
                    adjustments.weapon = 3 -- AWP benefits from higher offset
                elseif ctx.weapon_type == "scout" then
                    adjustments.weapon = 2
                elseif ctx.weapon_type == "rifle" then
                    adjustments.weapon = 1
                end
                
                -- Tickrate adjustment (128tick = can use higher offsets safely)
                if lagcomp.tickrate == 128 then
                    adjustments.tickrate = 2
                end
                
                -- Sum adjustments
                local total_adjustment = 0
                for _, adj in pairs(adjustments) do
                    total_adjustment = total_adjustment + adj
                end
                
                -- Apply learning from past performance
                local perf_key = string.format("%s_%d", ctx.weapon_type, math.floor(ctx.enemy_distance / 100))
                local learned_offset = TB.adaptive.performance_map[perf_key] or 0
                total_adjustment = total_adjustment + learned_offset
                
                -- Calculate final offset with variability
                local adjusted_base = base + total_adjustment
                
                -- Apply variability with context awareness
                local variance_range = math.floor(adjusted_base * var_pct)
                
                -- Smart variance: use Gaussian-like distribution instead of uniform
                local variance = 0
                if variance_range > 0 then
                    -- Generate 3 random values and average (approximates normal distribution)
                    local r1 = client.random_int(-variance_range, variance_range)
                    local r2 = client.random_int(-variance_range, variance_range)
                    local r3 = client.random_int(-variance_range, variance_range)
                    variance = math.floor((r1 + r2 + r3) / 3)
                end
                
                local final_offset = adjusted_base + variance
                
                -- Clamp to safe limits based on lagcomp window
                -- Leave headroom for server processing
                local max_safe = math.min(22, lagcomp.backtrack_ticks - 2)
                final_offset = math.max(0, math.min(max_safe, final_offset))
                
                -- Store variance for analysis
                table.insert(TB.adaptive.variance_history, {
                    offset = final_offset,
                    base = base,
                    variance = variance,
                    context = ctx,
                    time = globals.realtime()
                })
                
                -- Limit history size
                while #TB.adaptive.variance_history > 100 do
                    table.remove(TB.adaptive.variance_history, 1)
                end
                
                return final_offset
            end
            
            -- Learn from shot outcomes
            function TB.learn_from_shot(offset, hit, context)
                local perf_key = string.format("%s_%d", context.weapon_type, math.floor(context.enemy_distance / 100))
                
                -- Update hit/miss statistics
                TB.stats.hits_per_offset[offset] = (TB.stats.hits_per_offset[offset] or 0) + (hit and 1 or 0)
                TB.stats.misses_per_offset[offset] = (TB.stats.misses_per_offset[offset] or 0) + (hit and 0 or 1)
                
                -- Calculate performance for this context
                local perf = TB.adaptive.performance_map[perf_key] or 0
                local adjustment = 0
                
                if hit then
                    -- Reinforce: slightly increase offset if hit
                    adjustment = TB.adaptive.learning_rate * 0.5
                else
                    -- Penalize: decrease offset if miss
                    adjustment = -TB.adaptive.learning_rate
                end
                
                -- Update with momentum
                TB.adaptive.performance_map[perf_key] = perf * 0.9 + adjustment
                
                -- Clamp learned adjustments
                TB.adaptive.performance_map[perf_key] = math.max(-5, math.min(5, TB.adaptive.performance_map[perf_key]))
            end
            
            -- Get optimal offset for current context
            function TB.get_optimal_offset(base, variability)
                -- Update server info periodically
                if globals.tickcount() % 64 == 0 then
                    update_server_tickbase_info()
                end
                
                return calculate_adaptive_offset(base, variability)
            end
            
            -- Check if should apply for command
            function TB.should_apply_for_command(arg, state, team)
                if not TB.active or not TB.value then
                    return false, nil
                end
                
                local base_tick = TB.value
                local variability = 0
                
                -- Get variability from menu
                local ok_v, global_var = pcall(ui.get, 
                    (menu and menu["anti aimbot"] and menu["anti aimbot"]["builder"] and 
                    menu["anti aimbot"]["builder"]["tbvariability"]) or nil)
                if ok_v and tonumber(global_var) then
                    variability = tonumber(global_var)
                end
                
                -- Calculate optimal offset
                local optimal_tick = TB.get_optimal_offset(base_tick, variability)
                
                -- Store for potential learning
                TB._last_offset = optimal_tick
                TB._last_context = get_network_context()
                
                return true, optimal_tick
            end
            
            -- Restore function
            function TB.restore()
                TB.active = false
                TB.runtime = {}
                TB.builder_val = nil
                TB.value = nil
                
                return true
            end
            
            -- Activate function
            function TB.activate(value, opts)
                opts = opts or {}
                
                TB.value = math.max(0, math.min(22, math.floor(value)))
                TB.teams = opts.teams or "both"
                TB.mode = opts.mode or "adaptive"
                TB.active = true
                
                -- Initial server info read
                update_server_tickbase_info()
                
                return true
            end
            
            -- Hook into aim_fire for learning
            client.set_event_callback("aim_fire", function(e)
                if TB.active and TB._last_offset and TB._last_context then
                    -- Store shot info for learning when we get hit/miss callback
                    TB._pending_shot = {
                        offset = TB._last_offset,
                        context = TB._last_context,
                        time = globals.realtime()
                    }
                end
            end)
            
            client.set_event_callback("aim_hit", function(e)
                if TB._pending_shot then
                    TB.learn_from_shot(TB._pending_shot.offset, true, TB._pending_shot.context)
                    TB._pending_shot = nil
                end
            end)
            
            client.set_event_callback("aim_miss", function(e)
                if TB._pending_shot then
                    TB.learn_from_shot(TB._pending_shot.offset, false, TB._pending_shot.context)
                    TB._pending_shot = nil
                end
            end)
            
            -- Initial setup
            update_server_tickbase_info()
        end

                local function enemy_visible(enemy)
                    if not enemy or not entity.is_alive(enemy) then return false end
                    local lp = entity.get_local_player()
                    if not lp or not entity.is_alive(lp) then return false end
                    
                    local ex, ey, ez = entity.hitbox_position(enemy, 0)
                    if not ex then return false end
                    
                    local lx, ly, lz = client.eye_position()
                    if not lx then return false end
                    
                    local fraction = client.trace_line(lp, lx, ly, lz, ex, ey, ez)
                    return fraction == 1
                end
            

            local ANTIBF_DB_KEY = 'bjW9MagJsut5xDz36Hvl74nC8Eoy0GIUVX2NLQepckFfrBYOhRZKAwmSqidP1T+/'

            
            tbl.antiaim.log = tbl.antiaim.log or {}
            tbl.antiaim.ab = tbl.antiaim.ab or {
                time = {},
                method = {},
                hit_count = {},
                last_hit = {},
                adjustments = {},
                locked = {}
            }
            tbl.antiaim.temp = tbl.antiaim.temp or {}
            tbl.antiaim.learn_threshold = 2
            tbl.antiaim.temp_ttl = 5

            
            local AB_CONFIG = {
                methods = { "decrease", "increase", "random" },
                window_seconds = 3.0,
                hits_to_cycle = 2,
                hits_to_lock = 3,
                cooldown_ticks = 8,
                hold_ticks = 32,
                persist_ttl = 604800,
                max_entries = 64,
                
                decrease = { yaw = 0.65, body = 0.55, jitter = 0.5, delay_add = -1 },
                increase = { yaw = 1.35, body = 1.45, jitter = 1.5, delay_add = 2 },
                random = {
                    yaw_range = { -180, 180 },
                    body_range = { -180, 180 },
                    jitter_range = { -45, 45 },
                    delay_range = { 1, 8 }
                }
            }

            
            
            

            local function ab_clamp(v, lo, hi)
                return math.max(lo or -180, math.min(hi or 180, math.floor(v + 0.5)))
            end

            local function safe_read(ctrl, default)
                if not ctrl then return default end
                local ok, val = pcall(ui.get, ctrl)
                return (ok and val) or default
            end

            local function entry_is_fresh(entry, now)
                now = now or globals.realtime()
                if not entry or type(entry.last) ~= "number" then return false end
                return (now - entry.last) <= 5.0
            end

            local function distance(x1, y1, z1, x2, y2, z2)
                return math.sqrt((x1 - x2) * (x1 - x2) + (y1 - y2) * (y1 - y2) + (z1 - z2) * (z1 - z2))
            end

            local function extrapolate(player, ticks, x, y, z)
                local xv, yv, zv = entity.get_prop(player, "m_vecVelocity")
                local new_x = x + globals.tickinterval() * xv * ticks
                local new_y = y + globals.tickinterval() * yv * ticks
                local new_z = z + globals.tickinterval() * zv * ticks
                return new_x, new_y, new_z
            end

            local function calcangle(localplayerxpos, localplayerypos, enemyxpos, enemyypos)
                local relativeyaw = math.atan((localplayerypos - enemyypos) / (localplayerxpos - enemyxpos))
                return relativeyaw * 180 / math.pi
            end

            local function angle_vector(angle_x, angle_y)
                local sy = math.sin(math.rad(angle_y))
                local cy = math.cos(math.rad(angle_y))
                local sp = math.sin(math.rad(angle_x))
                local cp = math.cos(math.rad(angle_x))
                return cp * cy, cp * sy, -sp
            end

            local function get_camera_pos(enemy)
                local e_x, e_y, e_z = entity.get_prop(enemy, "m_vecOrigin")
                if not e_x then return nil end
                local _, _, ofs = entity.get_prop(enemy, "m_vecViewOffset")
                e_z = e_z + (ofs - (entity.get_prop(enemy, "m_flDuckAmount") * 16))
                return e_x, e_y, e_z
            end

            local function fired_at(target, shooter, shot)
                if not entity.is_alive(target) or not entity.is_alive(shooter) then return false end
                if entity.is_dormant(target) or entity.is_dormant(shooter) then return false end
                
                local shooter_cam = { get_camera_pos(shooter) }
                if not shooter_cam[1] then return false end
                
                local player_head = { entity.hitbox_position(target, 0) }
                if not player_head[1] then return false end
                
                local sx, sy, sz = shooter_cam[1], shooter_cam[2], shooter_cam[3]
                local vx, vy, vz = shot[1] - sx, shot[2] - sy, shot[3] - sz
                local hx, hy, hz = player_head[1] - sx, player_head[2] - sy, player_head[3] - sz
                
                local len_v = math.sqrt(vx*vx + vy*vy + vz*vz)
                local len_h = math.sqrt(hx*hx + hy*hy + hz*hz)
                if len_v < 0.001 or len_h < 0.001 then return false end
                
                local t = ((hx*vx) + (hy*vy) + (hz*vz)) / (len_v * len_v)
                local closest_x, closest_y, closest_z = sx + vx * t, sy + vy * t, sz + vz * t
                local dx, dy, dz = player_head[1] - closest_x, player_head[2] - closest_y, player_head[3] - closest_z
                local perp_dist = math.sqrt(dx*dx + dy*dy + dz*dz)
                
                if perp_dist > 60 then return false end
                
                local dot = ((vx * hx) + (vy * hy) + (vz * hz)) / (len_v * len_h)
                if dot < 0.96 then return false end
                
                local frac_shot = client.trace_line(shooter, shot[1], shot[2], shot[3], player_head[1], player_head[2], player_head[3]) or 0
                local frac_final = client.trace_line(target, closest_x, closest_y, closest_z, player_head[1], player_head[2], player_head[3]) or 0
                
                return (frac_shot >= 0.995 or frac_final >= 0.995) and len_v > 16
            end

            
            
            

            local function get_local_state_and_team()
                local lp = entity.get_local_player()
                if not lp then return nil, nil end
                
                local flags = entity.get_prop(lp, "m_fFlags") or 0
                local air = bit.band(flags, 1) == 0
                local duck = (entity.get_prop(lp, "m_flDuckAmount") or 0) > 0.1
                local xv, yv, zv = entity.get_prop(lp, "m_vecVelocity")
                local speed = math.sqrt((xv or 0)^2 + (yv or 0)^2 + (zv or 0)^2)
                
                local state = tbl.getstate(air, duck, speed, false) or "global"
                local team = (entity.get_prop(lp, "m_iTeamNum") == 2) and "t" or "ct"
                
                return state, team
            end

            local function get_current_aa_values()
                local state, team = get_local_state_and_team()
                if not state or not team then return nil end
                
                local auto = aa[state] and aa[state][team] and aa[state][team]["auto"]
                local luasense = aa[state] and aa[state][team] and aa[state][team]["luasense"]
                local normal = aa[state] and aa[state][team] and aa[state][team]["normal"]
                
                return {
                    left = safe_read(auto and auto.left) or safe_read(luasense and luasense.left) or safe_read(normal and normal.left) or 0,
                    right = safe_read(auto and auto.right) or safe_read(luasense and luasense.right) or safe_read(normal and normal.right) or 0,
                    body = safe_read(auto and auto.fake) or safe_read(luasense and luasense.fake) or safe_read(normal and normal.fake) or 60,
                    jitter = safe_read(auto and auto.jitter_slider) or 0,
                    delay = safe_read(auto and auto.delay) or 1
                }
            end

            local function antibf_enabled_for_local()
                local state, team = get_local_state_and_team()
                if not state or not team then return false end
                
                local auto = aa[state] and aa[state][team] and aa[state][team]["auto"]
                if not auto or not auto["antibf"] then return false end
                
                return ui.get(auto["antibf"]) == "yes"
            end

            
            
            

            local function apply_method_adjustment(method, base)
                if not base or not method then return base end
                
                local cfg = AB_CONFIG[method]
                if not cfg then return base end
                
                local adjusted = {}
                
                if method == "decrease" or method == "increase" then
                    adjusted.left = ab_clamp(base.left * cfg.yaw, -180, 180)
                    adjusted.right = ab_clamp(base.right * cfg.yaw, -180, 180)
                    adjusted.body = ab_clamp(base.body * cfg.body, -180, 180)
                    adjusted.jitter = ab_clamp(base.jitter * cfg.jitter, -60, 60)
                    adjusted.delay = ab_clamp(base.delay + cfg.delay_add, 1, 22)
                elseif method == "random" then
                    adjusted.left = client.random_int(cfg.yaw_range[1], cfg.yaw_range[2])
                    adjusted.right = client.random_int(cfg.yaw_range[1], cfg.yaw_range[2])
                    adjusted.body = client.random_int(cfg.body_range[1], cfg.body_range[2])
                    adjusted.jitter = client.random_int(cfg.jitter_range[1], cfg.jitter_range[2])
                    adjusted.delay = client.random_int(cfg.delay_range[1], cfg.delay_range[2])
                end
                
                return adjusted
            end

            local function cycle_method(attacker_key)
                local methods = AB_CONFIG.methods
                local choice = methods[math.random(1, #methods)]
                tbl.antiaim.ab.method[attacker_key] = choice
                return choice
            end

            
            
            

            local function on_local_player_hit(attacker_ent)
                if not attacker_ent then return end
                
                local key = tostring(entity.get_steam64(attacker_ent) or attacker_ent)
                local now = globals.realtime()
                local tick = globals.tickcount()
                
                
                tbl.antiaim.ab.last_hit[key] = tbl.antiaim.ab.last_hit[key] or 0
                tbl.antiaim.ab.hit_count[key] = tbl.antiaim.ab.hit_count[key] or 0
                tbl.antiaim.ab.method[key] = tbl.antiaim.ab.method[key] or "decrease"
                
                
                if tick - tbl.antiaim.ab.last_hit[key] < AB_CONFIG.cooldown_ticks then return end
                
                
                if (now - (tbl.antiaim.ab.time[key] or 0)) > AB_CONFIG.window_seconds then
                    tbl.antiaim.ab.hit_count[key] = 1
                else
                    tbl.antiaim.ab.hit_count[key] = tbl.antiaim.ab.hit_count[key] + 1
                end
                
                tbl.antiaim.ab.last_hit[key] = tick
                tbl.antiaim.ab.time[key] = now
                
                
                if tbl.antiaim.ab.hit_count[key] >= AB_CONFIG.hits_to_cycle then
                    cycle_method(key)
                    tbl.antiaim.ab.hit_count[key] = 0
                end
                
                
                if tbl.antiaim.ab.hit_count[key] >= AB_CONFIG.hits_to_lock then
                    tbl.antiaim.ab.locked[key] = true
                end
                
                
                local base = get_current_aa_values()
                if not base then return end
                
                local method = tbl.antiaim.ab.method[key]
                local adjusted = apply_method_adjustment(method, base)
                
                tbl.antiaim.ab.adjustments[key] = {
                    values = adjusted,
                    method = method,
                    expires = tick + AB_CONFIG.hold_ticks,
                    base = base
                }
                
                
                tbl.antiaim.log[key] = tbl.antiaim.log[key] or {}
                tbl.antiaim.log[key].method = method
                tbl.antiaim.log[key].last = now
                tbl.antiaim.log[key].locked = tbl.antiaim.ab.locked[key] or false
            end

            
            
            

            local function apply_antibf_adjustments()
                local tick = globals.tickcount()
                local active_adj = nil
                
                
                for key, adj in pairs(tbl.antiaim.ab.adjustments) do
                    if tick <= adj.expires then
                        if not active_adj or adj.expires > active_adj.expires then
                            active_adj = adj
                        end
                    else
                        tbl.antiaim.ab.adjustments[key] = nil
                    end
                end
                
                
                if active_adj and active_adj.values then
                    local v = active_adj.values
                    local flip = tbl.antiaim.luasensefake ~= nil and tbl.antiaim.luasensefake or tbl.antiaim.current
                    
                    if flip then
                        pcall(ui.set, tbl.items.yaw[2], v.right or 0)
                    else
                        pcall(ui.set, tbl.items.yaw[2], v.left or 0)
                    end
                    
                    pcall(ui.set, tbl.items.body[2], v.body or 0)
                    pcall(ui.set, tbl.items.jitter[2], v.jitter or 0)
                    
                    return true
                end
                
                return false
            end


            local function save_antibf()
                local ok, err = pcall(function()
                    local data_to_save = {
                        log = tbl.antiaim.log or {},
                        ab = {
                            method = tbl.antiaim.ab.method or {},
                            locked = tbl.antiaim.ab.locked or {},
                            time = tbl.antiaim.ab.time or {}
                        }
                    }
                    
                    localdb.antibf_data = data_to_save
                end)
                
                if not ok then
                    client.error_log("Failed to save anti-bruteforce data: " .. tostring(err))
                end
            end

            local function load_antibf()
                local ok, err = pcall(function()
                    local data = localdb.antibf_data
                    
                    if type(data) == "table" then
                        if type(data.log) == "table" then 
                            tbl.antiaim.log = data.log 
                        end
                        if type(data.ab) == "table" then
                            tbl.antiaim.ab.method = data.ab.method or {}
                            tbl.antiaim.ab.locked = data.ab.locked or {}
                            tbl.antiaim.ab.time = data.ab.time or {}
                        end
                    end
                end)
                
                if not ok then
                    client.error_log("Failed to load anti-bruteforce data: " .. tostring(err))
                end
            end

            local function prune_antibf(now)
                now = now or globals.realtime()
                local ttl = AB_CONFIG.persist_ttl
                local max = AB_CONFIG.max_entries
                
                
                for key, entry in pairs(tbl.antiaim.log) do
                    if type(entry) == "table" and not entry.locked then
                        if (entry.last or 0) > 0 and (now - entry.last) > ttl then
                            tbl.antiaim.log[key] = nil
                            tbl.antiaim.ab.method[key] = nil
                            tbl.antiaim.ab.locked[key] = nil
                            tbl.antiaim.ab.time[key] = nil
                            tbl.antiaim.ab.hit_count[key] = nil
                        end
                    end
                end
                
                
                local total = 0
                for _ in pairs(tbl.antiaim.log) do total = total + 1 end
                
                if total > max then
                    local items = {}
                    for k, v in pairs(tbl.antiaim.log) do
                        table.insert(items, { k = k, last = (v.last or 0), locked = (v.locked and true or false) })
                    end
                    
                    table.sort(items, function(a, b)
                        if a.locked ~= b.locked then return a.locked end
                        return a.last < b.last
                    end)
                    
                    while total > max and #items > 0 do
                        local rem = table.remove(items, 1)
                        tbl.antiaim.log[rem.k] = nil
                        tbl.antiaim.ab.method[rem.k] = nil
                        tbl.antiaim.ab.locked[rem.k] = nil
                        tbl.antiaim.ab.time[rem.k] = nil
                        tbl.antiaim.ab.hit_count[rem.k] = nil
                        total = total - 1
                    end
                end
            end

            local function update_and_save_antibf()
                prune_antibf(globals.realtime())
                save_antibf()
            end

            local function antibf_reset()
                tbl.antiaim.log = {}
                tbl.antiaim.ab = { 
                    time = {}, 
                    method = {}, 
                    hit_count = {}, 
                    last_hit = {}, 
                    adjustments = {}, 
                    locked = {} 
                }
                save_antibf()
            end


            
            load_antibf()

            
            local last_maint = 0
            client.set_event_callback("paint", function()
                local now = globals.realtime()
                if now - last_maint >= 60 then
                    prune_antibf(now)
                    save_antibf()
                    last_maint = now
                end
            end)

            
            client.set_event_callback("shutdown", function()
                save_antibf()
            end)

            
            tbl.antiaim.ab_apply = apply_antibf_adjustments
            tbl.antiaim.ab_reset = antibf_reset
            tbl.antiaim.ab_save = save_antibf
            tbl.antiaim.ab_load = load_antibf

            local tickshot = 0

            client.set_event_callback("bullet_impact", function(event)
                local lp = entity.get_local_player()
                if not lp or not entity.is_alive(lp) then return end
                
                local enemy = client.userid_to_entindex(event.userid)
                if enemy == lp or not entity.is_enemy(enemy) then return end
                
                if fired_at(lp, enemy, {event.x, event.y, event.z}) then
                    if tickshot ~= globals.tickcount() then
                        tickshot = globals.tickcount()
                        
                        
                        if tbl.contains(ui.get(menu["visuals & misc"]["visuals"]["notify"]), "shot") then
                            local r, g, b, a = ui.get(menu["visuals & misc"]["visuals"]["notcolor"])
                            local player_name = entity.get_player_name(enemy)
                            local method_number = math.random(1, 3)
                            local colored_playername = ("\a%02x%02x%02x%02x%s"):format(r, g, b, a, player_name)
                            local colored_you = ("\a%02x%02x%02x%02x%s"):format(r, g, b, a, "you")
                            local colored_antiaim = ("\a%02x%02x%02x%02x%s"):format(r, g, b, a, "anti-aim")
                            local white = "\aFFFFFFFF"
                            
                            push_notify(white .. colored_playername .. white .. " shot at " .. colored_you .. white .. "!  ", "shot")
                            push_notify(white .. "Changed " .. colored_antiaim .. white .. " due to " .. colored_playername .. white .. "'s bullet! [method: " .. method_number .. "]  ", "bullet")
                        end
                        
                        
                        tbl.antiaim.count = true
                        tbl.antiaim.timer = 0
                        
                        if tbl.antiaim.active and antibf_enabled_for_local() then
                            local key = tostring(entity.get_steam64(enemy) or enemy)
                            local now = globals.realtime()
                            local current_flip = (tbl.antiaim.luasensefake ~= nil) and tbl.antiaim.luasensefake or tbl.antiaim.current
                            local safe_side = not current_flip
                            
                            
                            tbl.antiaim.log[key] = tbl.antiaim.log[key] or { value = safe_side, count = 0, last = now, locked = false }
                            local entry = tbl.antiaim.log[key]
                            
                            if entry.value == safe_side then
                                entry.count = (entry.count or 0) + 1
                            else
                                entry.value = safe_side
                                entry.count = 1
                                entry.locked = false
                            end
                            entry.last = now
                            
                            if entry.count >= tbl.antiaim.learn_threshold then
                                entry.locked = true
                            end
                            
                            
                            local ttl = tbl.antiaim.temp_ttl or 5
                            tbl.antiaim.temp[tostring(enemy)] = {
                                expires = now + ttl,
                                delay = math.random(2, 6),
                                jitter_off = math.random(-8, 8),
                                fake = client.random_int(10, 60),
                                should_swap = (math.random(0, 1) == 1)
                            }
                        end
                        
                        update_and_save_antibf()
                    end
                end
            end)

            
            
            

            client.set_event_callback("player_hurt", function(e)
                if not e then return end
                
                local victim = client.userid_to_entindex(e.userid)
                local attacker = client.userid_to_entindex(e.attacker)
                local lp = entity.get_local_player()
                
                if victim == lp and attacker and attacker ~= lp then
                    on_local_player_hit(attacker)
                end
            end)

            
            local last_maint = 0
            client.set_event_callback("paint", function()
                local now = globals.realtime()
                if now - last_maint >= 60 then
                    prune_antibf(now)
                    save_antibf()
                    last_maint = now
                end
            end)

            
            
            

            load_antibf()

            tbl.antiaim.ab_apply = apply_antibf_adjustments
            tbl.antiaim.ab_reset = antibf_reset
        
            client.set_event_callback('aim_miss', function(shot)
                if not tbl.contains(ui.get(menu["visuals & misc"]["visuals"]["notify"]), "miss") then return nil end
                local target = entity.get_player_name(shot.target):lower()
                local hitbox = hitboxes[shot.hitgroup] or "?"
                local r, g, b, a = ui.get(menu["visuals & misc"]["visuals"]["notcolor3"])
                local colored_target = ("\a%02x%02x%02x%02x%s"):format(r, g, b, a, target)
                local colored_hitbox = ("\a%02x%02x%02x%02x%s"):format(r, g, b, a, hitbox)
                local colored_reason = ("\a%02x%02x%02x%02x%s"):format(r, g, b, a, shot.reason)
                local white = "\aFFFFFFFF"
                push_notify(white .. "Missed " .. colored_target .. white .. "'s " .. colored_hitbox .. white .. " due to " .. colored_reason .. white .. "!  ", "miss")
            end)
            client.set_event_callback('aim_hit', function(shot)
                if not tbl.contains(ui.get(menu["visuals & misc"]["visuals"]["notify"]), "hit") then return nil end
                local target = entity.get_player_name(shot.target):lower()
                local hitbox = hitboxes[shot.hitgroup] or "?"
                local r, g, b, a = ui.get(menu["visuals & misc"]["visuals"]["notcolor2"])
                local colored_target = ("\a%02x%02x%02x%02x%s"):format(r, g, b, a, target)
                local colored_hitbox = ("\a%02x%02x%02x%02x%s"):format(r, g, b, a, hitbox)
                local colored_damage = ("\a%02x%02x%02x%02x%s"):format(r, g, b, a, shot.damage)
                local white = "\aFFFFFFFF"
                push_notify(white .. "Hit " .. colored_target .. white .. "'s " .. colored_hitbox .. white .. " for " .. colored_damage .. white .. "!  ", "hit")
            end)
            local z = {}
            z.defensive = {
                cmd = 0,
                check = 0,
                defensive = 0,
                run = function(arg)
                    z.defensive.cmd = arg.command_number
                    ladder = (entity.get_prop(z, "m_MoveType") == 9)
                end,
                predict = function(arg)
                    if arg.command_number == z.defensive.cmd then
                        local tickbase = entity.get_prop(entity.get_local_player(), "m_nTickBase")
                        z.defensive.defensive = math.abs(tickbase - z.defensive.check)
                        z.defensive.check = math.max(tickbase, z.defensive.check or 0)
                        z.defensive.cmd = 0
                    end
                end
            }
            client.set_event_callback("level_init", function()
                z.defensive.check, z.defensive.defensive = 0, 0
            end)
            local scope_fix = false
            local scope_int = 0
            local shift_int = 0
            local list_shift = (function()
                local index, max = { }, 16
                for i=1, max do
                    index[#index+1] = 0
                    if i == max then
                        return index
                    end
                end
            end)()
            z.dtshift = function()
                local local_player = entity.get_local_player()
                local sim_time = entity.get_prop(local_player, "m_flSimulationTime")
                if local_player == nil or sim_time == nil then
                    return
                end
                local tick_count = globals.tickcount()
                local shifted = math.max(unpack(list_shift))
                shift_int = shifted < 0 and math.abs(shifted) or 0
                list_shift[#list_shift+1] = sim_time/globals.tickinterval() - tick_count
                table.remove(list_shift, 1)
            end
            client.set_event_callback("net_update_start", z.dtshift)
            client.set_event_callback("run_command", z.defensive.run)
            client.set_event_callback("predict_command", z.defensive.predict)
            local animkeys = {
                dt = 0,
                duck = 0,
                hide = 0,
                safe = 0,
                baim = 0,
                fs = 0
            }
            local gradient = function(r1, g1, b1, a1, r2, g2, b2, a2, text)
                local output = ''
                local len = #text-1
                local rinc = (r2 - r1) / len
                local ginc = (g2 - g1) / len
                local binc = (b2 - b1) / len
                local ainc = (a2 - a1) / len
                for i=1, len+1 do
                    output = output .. ('\a%02x%02x%02x%02x%s'):format(r1, g1, b1, a1, text:sub(i, i))
                    r1 = r1 + rinc
                    g1 = g1 + ginc
                    b1 = b1 + binc
                    a1 = a1 + ainc
                end
                return output
            end
            z.items = {}
            z.items.keys = { 
                dt = {ui.reference("rage", "aimbot", "double tap")},
                hs = {ui.reference("aa", "other", "on shot anti-aim")},
                fd = {ui.reference("rage", "other", "duck peek assist")},
                sp = {ui.reference("rage", "aimbot", "force safe point")},
                fb = {ui.reference("rage", "aimbot", "force body aim")}
            }


            local limitfl = ui.reference("aa", "fake lag", "limit")
            local legs = ui.reference("aa", "other", "leg movement")
            local spammer = 0
            tbl.tick_aa = -2147483500
            tbl.list_aa = {}
            tbl.reset_aa = false
            tbl.defensive_aa = 1337
            tbl.callbacks = {
                recharge = function()
                    ctx.recharge.run()
                end,
                hitmarker_aim_fire = function(c)
                    if ui.get(menu["visuals & misc"]["visuals"]["hitmark_enable"]) == "yes" then
                        hitmarker_queue[globals.tickcount()] = {c.x, c.y, c.z, globals.curtime() + 4}
                    end        
                end,
                hitmarker_paint = function()
                    if ui.get(menu["visuals & misc"]["visuals"]["hitmark_enable"]) == "yes" then
                        local r, g, b, a = ui.get(menu["visuals & misc"]["visuals"]["hitmark_color"])
                        for tick, data in pairs(hitmarker_queue) do
                            if globals.curtime() <= data[4] then
                                local x1, y1 = renderer.world_to_screen(data[1], data[2], data[3])
                                if x1 and y1 then
                                    renderer.line(x1 - 5, y1, x1 + 5, y1, r, g, b, a)
                                    renderer.line(x1, y1 - 5, x1, y1 + 5, r, g, b, a)
                                end
                            else
                                hitmarker_queue[tick] = nil
                            end
                        end
                    end
                end,
                hitmarker_round_prestart = function()
                    hitmarker_queue = {}
                end,
                ["freestand"] = function()
                    local result = 0
                    local player = client.current_threat()
                    if player ~= nil and not enemy_visible(player) then
                        local lx, ly, lz = entity.get_prop(entity.get_local_player(), "m_vecOrigin")
                        local enemyx, enemyy, enemyz = entity.get_prop(player, "m_vecOrigin")
                        local yaw = calcangle(lx, ly, enemyx, enemyy)
                        local dir_x, dir_y = angle_vector(0, (yaw + 90))
                        local end_x = lx + dir_x * 55
                        local end_y = ly + dir_y * 55
                        local end_z = lz + 80
                        local index, damage = client.trace_bullet(player, enemyx, enemyy, enemyz + 70, end_x, end_y, end_z,true)
                        if damage > 0 then result = 1 end
                        dir_x, dir_y = angle_vector(0, (yaw + -90))
                        end_x = lx + dir_x * 55
                        end_y = ly + dir_y * 55
                        end_z = lz + 80
                        index, damage = client.trace_bullet(player, enemyx, enemyy, enemyz + 70, end_x, end_y, end_z,true)
                        if damage > 0 then 
                            if result == 1 then 
                                result = 0 
                            else 
                                result = -1 
                            end 
                        end
                    end
                    tbl.antiaim.fs = result
                end,
                ["command"] = function(arg)
                    do
                        local discharge = tbl.antiaim and tbl.antiaim.discharge
                        if not discharge then goto _after_discharge end

                        local enabled = pcall(ui.get, menu["anti aimbot"]["features"]["discharge"]) and ui.get(menu["anti aimbot"]["features"]["discharge"])

                        if enabled and discharge.saved_dt_state == nil then
                            local ok, cur = pcall(ui.get, tbl.refs.dt[1])
                            discharge.saved_dt_state = ok and cur or nil
                        end

                        if not enabled and discharge.saved_dt_state ~= nil then
                            pcall(ui.set, tbl.refs.dt[1], discharge.saved_dt_state)
                            discharge.saved_dt_state = nil
                        end

                        if not enabled then goto _after_discharge end

                        local lp = entity.get_local_player()
                        if not lp or not entity.is_alive(lp) then goto _after_discharge end

                        local wp = entity.get_player_weapon(lp)
                        local cname = wp and entity.get_classname(wp) or ""
                        if cname == "CC4" or cname == "CKnife" or cname == "CWeaponTaser" or (type(cname) == "string" and cname:lower():find("grenade")) then goto _after_discharge end

                        local enemies = entity.get_players(true)
                        local vis = false
                        for i = 1, #enemies do
                            local e = enemies[i]
                            if e and entity.is_alive(e) and not entity.is_dormant(e) then
                                local bx, by, bz = entity.hitbox_position(e, 1)
                                if bx and client.visible(bx, by, bz + 20) then
                                    vis = true
                                    break
                                end
                            end
                        end
                        if vis then
                            pcall(ui.set, tbl.refs.dt[1], false)
                            client.delay_call(0.01, function() pcall(ui.set, tbl.refs.dt[1], true) end)
                        end
                    end
                    ::_after_discharge::

                    local myself = entity.get_local_player()
                    local air = bit.band(entity.get_prop(myself, "m_fFlags"), 1) == 0
                    local xv, yv, zv = entity.get_prop(myself, "m_vecVelocity")
                    local duck = (entity.get_prop(myself, "m_flDuckAmount") > 0.1)
                    local team = (entity.get_prop(myself, "m_iTeamNum") == 2 and "t" or "ct")
                    local fakelag = not ((ui.get(tbl.refs.dt[1]) and ui.get(tbl.refs.dt[2])) or (ui.get(tbl.refs.hide[1]) and ui.get(tbl.refs.hide[2])))
                    local real_state = tbl.getstate(arg.in_jump == 1 or air, duck, math.sqrt(xv*xv + yv*yv + zv*zv), (ui.get(tbl.refs.slow[1]) and ui.get(tbl.refs.slow[2])))
                    local hideshot = ((ui.get(tbl.refs.hide[1]) and ui.get(tbl.refs.hide[2])) and not (ui.get(tbl.refs.dt[1]) and ui.get(tbl.refs.dt[2])))
                        do
                            local enabled = ui.get(menu["anti aimbot"]["features"]["enableautohs"])
                            if enabled then
                                local sel_guns = ui.get(menu["anti aimbot"]["features"]["autohs"]) or {}
                                local sel_cond = ui.get(menu["anti aimbot"]["features"]["autohscond"]) or {}
                                local wp = entity.get_player_weapon(myself)
                                local classname = wp and (entity.get_classname(wp) or "") or ""
                                local winfo = wp and weapons(wp) or {}

                                local gun_match = false
                                if tbl.contains(sel_guns, "all") then
                                    gun_match = true
                                else
                                    if tbl.contains(sel_guns, "pistols") then
                                        if winfo and winfo.type == "pistol" then
                                            gun_match = true
                                        end
                                    end
                                end

                                if tbl.contains(sel_guns, "awp") then
                                    if classname == "CWeaponAWP" then
                                        gun_match = true
                                    elseif winfo and winfo.name then
                                        local n = winfo.name:lower()
                                        if n:find("awp") then gun_match = true end
                                    end
                                end

                                if tbl.contains(sel_guns, "automatics") then
                                    if classname == "CWeaponG3SG1" or classname == "CWeaponSCAR20" then
                                        gun_match = true
                                    elseif winfo and winfo.name then
                                        local n = winfo.name:lower()
                                        if n:find("g3sg1") or n:find("scar20") or n:find("g3") then gun_match = true end
                                    end
                                end
                                if tbl.contains(sel_guns, "scout") then
                                    if classname == "CWeaponSSG08" then
                                        gun_match = true
                                    elseif winfo and winfo.name then
                                        local n = winfo.name:lower()
                                        if n:find("ssg08") or n:find("scout") then gun_match = true end
                                    end
                                end
                                local cond_match = (#sel_cond == 0) or tbl.contains(sel_cond, real_state)
                                local should_enable = gun_match and cond_match

                                pcall(ui.set, tbl.refs.hide[1], should_enable)
                                if tbl.refs.hide[2] then pcall(ui.set, tbl.refs.hide[2], should_enable) end
                                tbl.antiaim.autohs_active = should_enable
                            else
                                if tbl.antiaim.autohs_active then
                                    pcall(ui.set, tbl.refs.hide[1], false)
                                    if tbl.refs.hide[2] then pcall(ui.set, tbl.refs.hide[2], false) end
                                    tbl.antiaim.autohs_active = false
                                end
                            end
                        end
                    local state = real_state
                    do
                    local sc = tbl.shot_choke
                        if sc and sc.enabled and sc.active then
                            if sc.start_delay and sc.start_delay > 0 then
                                sc.start_delay = sc.start_delay - 1
                            elseif sc.remaining and sc.remaining > 0 then
                                local skip = (client.random_int(0, 100) < 7) 
                                if not skip then
                                    arg.allow_send_packet = false
                                    sc.remaining = sc.remaining - 1
                                end
                                if sc.remaining <= 0 then
                                    sc.active = false
                                    sc.remaining = 0
                                    sc.start_delay = 0
                                    sc._seed_target = nil
                                end
                            end
                        end
                    end

                    local s = tbl.tickbase_override
                    local tb_override_val = nil
                    if s and s.active then
                        local rt = s.runtime or {}
                        local srt = rt[state] and rt[state][team]
                        tb_override_val = (srt and srt.ticks) or (rt.builder and rt.builder) or nil
                    end

                    
                    local should_apply, resolved_val = false, nil
                    if tb_override_val and s then
                        should_apply, resolved_val = s.should_apply_for_command(arg, state, team)
                    end

                    
                    if s and s._applied and s._applied_until_tick then
                        local lp = entity.get_local_player()
                        if not lp or globals.tickcount() > s._applied_until_tick then
                            pcall(function()
                                if s._applied and lp and entity.is_alive(lp) then
                                    if s._applied.orig_tickbase then pcall(entity.set_prop, lp, "m_nTickBase", s._applied.orig_tickbase) end
                                    if s._applied.orig_simtime then pcall(entity.set_prop, lp, "m_flSimulationTime", s._applied.orig_simtime) end
                                end
                            end)
                            s._applied = nil
                            s._applied_until_tick = nil
                        end
                    end

                    
                    if should_apply and tonumber(resolved_val) and tonumber(resolved_val) > 0 then
                        pcall(function()
                            local lp = entity.get_local_player()
                            if not lp or not entity.is_alive(lp) then return end
                            local cur_tb = entity.get_prop(lp, "m_nTickBase") or globals.tickcount()
                            local cur_sim = entity.get_prop(lp, "m_flSimulationTime") or globals.curtime()

                            
                            s._applied = s._applied or {}
                            if not s._applied.orig_tickbase then
                                s._applied.orig_tickbase = cur_tb
                                s._applied.orig_simtime = cur_sim
                            end

                            
                            local add = math.max(0, math.floor(tonumber(resolved_val) or 0))
                            
                            local new_tb = math.max(1, cur_tb + add)
                            local new_sim = (cur_sim or globals.curtime()) + (new_tb - cur_tb) * globals.tickinterval()

                            
                            pcall(entity.set_prop, lp, "m_nTickBase", new_tb)
                            pcall(entity.set_prop, lp, "m_flSimulationTime", new_sim)

                            
                            s._applied_until_tick = globals.tickcount() + math.max(1, add)

                            
                            arg.force_defensive = true
                        end)
                    end

                    if fakelag and ui.get(aa["fake lag"][team]["type"]) ~= "disabled" then
                        state = "fake lag"
                    elseif hideshot and ui.get(aa["hide shot"][team]["type"]) ~= "disabled" then
                        state = "hide shot"
                    elseif ui.get(aa[state][team]["type"]) == "disabled" then
                        state = "global"
                    else end
                    local enemy = client.current_threat()
                    local menutbl = aa[state][team]
                    tbl.breaklc = tbl.breaklc or {
                        -- Core state
                        old_origin = nil,
                        old_simtime_ticks = nil,
                        max_tickbase = 0,
                        defensive_left = 0,
                        breaking = false,
                        shift_rewind = false,
                        active = false,
                        
                        -- Configuration
                        teleport_sq_threshold = 4096 * 4096,  -- 64 units squared
                        hold_ticks = 2,
                        offset = 6000,
                        
                        -- Server info
                        sv_maxunlag = 0.5,
                        sv_lagcompensation_teleport_dist = 64,
                        max_rewind_ticks = 12,
                        
                        -- Advanced detection
                        last_velocity = vector(0, 0, 0),
                        velocity_changes = {},
                        simtime_deltas = {},
                        exploitation_window = 0,
                        
                        -- Restoration
                        _applied = nil,
                        _restore_tick = nil,
                        _restore_cb = nil,
                        _run_cmd = nil
                    }

                    -- Read server CVars for accurate lagcomp detection
                    local function update_server_lagcomp_info()
                        local ok_unlag, maxunlag = pcall(function() return cvar.sv_maxunlag:get_float() end)
                        local ok_teleport, teleport_dist = pcall(function() return cvar.sv_lagcompensation_teleport_dist:get_float() end)
                        
                        tbl.breaklc.sv_maxunlag = (ok_unlag and maxunlag) or 0.5
                        tbl.breaklc.sv_lagcompensation_teleport_dist = (ok_teleport and teleport_dist) or 64
                        tbl.breaklc.max_rewind_ticks = math.floor(tbl.breaklc.sv_maxunlag / globals.tickinterval())
                    end

                    -- Enhanced origin-based detection using sv_lagcompensation_teleport_dist
                    local function _luasense_net_update()
                        local lp = entity.get_local_player()
                        if not lp then return end

                        local ox, oy, oz = entity.get_prop(lp, "m_vecOrigin")
                        if not ox then return end
                        local origin = vector(ox, oy, oz)

                        local simtime = entity.get_prop(lp, "m_flSimulationTime") or 0
                        local simticks = func.time_to_ticks(simtime)

                        local prev = tbl.breaklc.old_simtime_ticks
                        if prev ~= nil then
                            local delta = simticks - prev
                            tbl.breaklc.shift_rewind = delta < 0

                            -- Record simtime deltas for pattern analysis
                            table.insert(tbl.breaklc.simtime_deltas, {delta = delta, time = globals.realtime()})
                            if #tbl.breaklc.simtime_deltas > 20 then
                                table.remove(tbl.breaklc.simtime_deltas, 1)
                            end

                            -- Detect lagcomp break conditions
                            if delta < 0 or (delta >= 0 and delta <= tbl.breaklc.max_rewind_ticks) then
                                local prev_origin = tbl.breaklc.old_origin or origin
                                local displacement = (origin - prev_origin):length()
                                
                                -- Use server's teleport distance threshold
                                local teleport_threshold = tbl.breaklc.sv_lagcompensation_teleport_dist
                                local tele = displacement > teleport_threshold
                                
                                -- Advanced detection: velocity-based analysis
                                local vx, vy, vz = entity.get_prop(lp, "m_vecVelocity")
                                if vx then
                                    local velocity = vector(vx, vy, vz)
                                    local expected_displacement = tbl.breaklc.last_velocity:length() * globals.tickinterval() * math.abs(delta)
                                    
                                    -- If actual displacement significantly exceeds expected, likely teleport
                                    if displacement > expected_displacement * 2 and displacement > 32 then
                                        tele = true
                                    end
                                    
                                    tbl.breaklc.last_velocity = velocity
                                    
                                    -- Track velocity changes for exploit detection
                                    table.insert(tbl.breaklc.velocity_changes, {
                                        vel = velocity:length(),
                                        time = globals.realtime()
                                    })
                                    if #tbl.breaklc.velocity_changes > 15 then
                                        table.remove(tbl.breaklc.velocity_changes, 1)
                                    end
                                end
                                
                                -- Enhanced breaking detection
                                tbl.breaklc.breaking = tele or (delta < 0) or (delta > 0 and delta >= tbl.breaklc.max_rewind_ticks - 2)
                                
                                -- Calculate exploitation window (ticks available for defensive)
                                if tbl.breaklc.breaking and delta < 0 then
                                    tbl.breaklc.exploitation_window = math.min(14, math.abs(delta))
                                end
                            end
                        end

                        tbl.breaklc.old_origin = origin
                        tbl.breaklc.old_simtime_ticks = simticks
                    end

                    -- Improved tickbase-based defensive detection
                    local function _luasense_update_defensive(e_cmd)
                        local lp = entity.get_local_player()
                        if not lp then return end
                        local tb = entity.get_prop(lp, "m_nTickBase") or 0

                        -- Reset if tickbase jumped significantly (new round, respawn, etc)
                        if math.abs(tb - tbl.breaklc.max_tickbase) > 64 then
                            tbl.breaklc.max_tickbase = tb
                            tbl.breaklc.defensive_left = 0
                            tbl.breaklc.exploitation_window = 0
                            return
                        end

                        if tb > tbl.breaklc.max_tickbase then
                            tbl.breaklc.max_tickbase = tb
                            tbl.breaklc.defensive_left = 0
                            tbl.breaklc.exploitation_window = 0
                        elseif tbl.breaklc.max_tickbase > tb then
                            -- Defensive active: calculate remaining ticks
                            local rewind_amount = tbl.breaklc.max_tickbase - tb
                            
                            -- Clamp to realistic defensive values (max 14 ticks in CSGO)
                            local left = math.max(0, math.min(14, rewind_amount - 1))
                            tbl.breaklc.defensive_left = left
                            
                            -- Set exploitation window based on actual rewind
                            tbl.breaklc.exploitation_window = left
                            
                            -- Mark as breaking if we have usable defensive ticks
                            tbl.breaklc.breaking = left > 0
                            
                            -- Advanced: detect if DT/HS is causing the shift
                            local dt_enabled = ui.get(tbl.refs.dt[1]) and ui.get(tbl.refs.dt[2])
                            local hs_enabled = ui.get(tbl.refs.hide[1]) and ui.get(tbl.refs.hide[2])
                            
                            if not dt_enabled and not hs_enabled and left > 0 then
                                -- Pure defensive without exploit = natural lagcomp break
                                tbl.breaklc.active = true
                            end
                        end
                    end

                    -- Register callbacks
                    if not tbl._breaklc_cb_registered then
                        tbl._breaklc_cb_registered = true
                        
                        -- Update server info on round start
                        client.set_event_callback("round_start", update_server_lagcomp_info)
                        update_server_lagcomp_info()  -- Initial call
                        
                        client.set_event_callback("net_update_start", _luasense_net_update)
                        client.set_event_callback("run_command", function(ev) 
                            tbl.breaklc._run_cmd = ev.command_number 
                        end)
                        client.set_event_callback("predict_command", function(ev)
                            if tbl.breaklc._run_cmd and ev.command_number == tbl.breaklc._run_cmd then
                                _luasense_update_defensive(ev)
                                tbl.breaklc._run_cmd = nil
                            end
                        end)
                    end         
                    ui.set(tbl.items.enabled[1], true)
                    ui.set(tbl.items.base[1], "at targets")
                    ui.set(tbl.items.pitch[1], "default")
                    ui.set(tbl.items.yaw[1], "180")
                    ui.set(tbl.items.fsbody[1], false)
                    ui.set(tbl.items.edge[1], false)
                    ui.set(tbl.items.fs[1], false)
                    ui.set(tbl.items.fs[2], "always on")
                    ui.set(tbl.items.roll[1], 0)
                    arg.roll = ui.get(menu["anti aimbot"]["features"]["roll"])
                    local myweapon = entity.get_player_weapon(myself)         
                    if ui.get(menu["anti aimbot"]["features"]["legit"]) ~= "off" and arg.in_use == 1 and entity.get_classname(myweapon) ~= "CC4" then
                        if tbl.contains(ui.get(menu["anti aimbot"]["features"]["fix"]), "generic") then
                            if arg.chokedcommands ~= 1 then
                                arg.in_use = 0
                            end
                        else
                            arg.in_use = 0
                        end
                        if tbl.contains(ui.get(menu["anti aimbot"]["features"]["fix"]), "bombsite") then
                            local player_x, player_y, player_z = entity.get_prop(myself, "m_vecOrigin")
                            local distance_bomb = 100
                            local bomb = entity.get_all("CPlantedC4")[1]
                            local bomb_x, bomb_y, bomb_z = entity.get_prop(bomb, "m_vecOrigin")
                            if bomb_x ~= nil then
                                distance_bomb = distance(bomb_x, bomb_y, bomb_z, player_x, player_y, player_z)
                            end
                            local distance_hostage = 100
                            local hostage = entity.get_all("CPlantedC4")[1]
                            local hostage_x, hostage_y, hostage_z = entity.get_prop(bomb, "m_vecOrigin")
                            if hostage_x ~= nil then
                                distance_hostage = distance(hostage_x, hostage_y, hostage_z, player_x, player_y, player_z)
                            end
                            if (distance_bomb < 69) or (distance_hostage < 69) then
                                arg.in_use = 1
                            end
                        end
                        ui.set(tbl.items.base[1], "local view")
                        ui.set(tbl.items.pitch[1], "off")
                        ui.set(tbl.items.fsbody[1], true)
                        ui.set(tbl.items.yaw[2], 180)
                        ui.set(tbl.items.jitter[1], "off")
                        ui.set(tbl.items.jitter[2], 0)
                        if ui.get(menu["anti aimbot"]["features"]["legit"]) == "default" or tbl.antiaim.fs == 0 then
                            ui.set(tbl.items.body[1], ui.get(menu["anti aimbot"]["features"]["legit"]) == "default" and "opposite" or "jitter")
                            ui.set(tbl.items.body[2], 0)
                        else
                            ui.set(tbl.items.body[1], "static")
                            ui.set(tbl.items.body[2], tbl.antiaim.fs == 1 and -180 or 180)
                            if arg.chokedcommands == 0 then
                                arg.allow_send_packet = false
                            end
                        end
                        arg.force_defensive = true
                        return nil
                    end
                    if ui.get(menu["anti aimbot"]["features"]["backstab"]) ~= "off" and enemy ~= nil then
                        local weapon = entity.get_player_weapon(enemy)
                        if weapon ~= nil and entity.get_classname(weapon) == "CKnife" then
                            local ex,ey,ez = entity.get_origin(enemy)
                            local lx,ly,lz = entity.get_origin(myself)
                            if ex ~= nil and lx ~= nil then 
                                for ticks = 1,9 do
                                    local tex,tey,tez = extrapolate(myself,ticks,lx,ly,lz)
                                    local distance = distance(ex,ey,ez,tex,tey,tez)
                                    if math.abs(distance) < ui.get(menu["anti aimbot"]["features"]["distance"]) then
                                        ui.set(tbl.items.yaw[2], ui.get(menu["anti aimbot"]["features"]["backstab"]) == "forward" and 180 or client.random_int(-180, 180))
                                        ui.set(tbl.items.jitter[1], "off")
                                        ui.set(tbl.items.jitter[2], 0)
                                        ui.set(tbl.items.body[1], ui.get(menu["anti aimbot"]["features"]["backstab"]) == "random" and "jitter" or "opposite")
                                        ui.set(tbl.items.body[2], 0)
                                        arg.force_defensive = true
                                        return nil
                                    end
                                end
                            end
                        end
                    end
                    if ui.get(menu["anti aimbot"]["features"]["safeheadonknife"]) then
                        local myweapon = entity.get_player_weapon(myself)
                        if myweapon ~= nil and entity.get_classname(myweapon) == "CKnife" and state == "air duck" then
                            ui.set(tbl.items.pitch[1], "down")
                            ui.set(tbl.items.yaw[1], "180")
                            ui.set(tbl.items.yaw[2], 0)
                            ui.set(tbl.items.jitter[1], "off")
                            ui.set(tbl.items.jitter[2], 0)
                            ui.set(tbl.items.body[1], "static")
                            ui.set(tbl.items.body[2], 0)
                            arg.force_defensive = true
                            return nil
                        end
                    end

                    if ui.get(menutbl["type"]) == "normal" then
                        menutbl = menutbl[ui.get(menutbl["type"])]
                        local yaw = tbl.antiaim.manual.aa
                        if tbl.contains(ui.get(menutbl["mode"]), "yaw") then
                            yaw = tbl.antiaim.manual.aa + ui.get(menutbl["yaw"])
                        end
                        if tbl.contains(ui.get(menutbl["mode"]), "left right") then
                            local method = arg.chokedcommands == 0
                            if ui.get(menutbl["method"]) == "luasense" then
                                method = arg.chokedcommands ~= 0
                            end
                            if method and ui.get(menutbl["body"]) ~= "luasense" then
                                if math.max(-60, math.min(60, math.floor((entity.get_prop(myself,"m_flPoseParameter", 11) or 0)*120-60+0.5))) > 0 then
                                    ui.set(tbl.items.yaw[2], tbl.clamp(yaw + ui.get(menutbl["right"])))
                                else
                                    ui.set(tbl.items.yaw[2], tbl.clamp(yaw + ui.get(menutbl["left"])))
                                end
                            end
                        else
                            ui.set(tbl.items.yaw[2], tbl.clamp(yaw))
                        end
                        ui.set(tbl.items.jitter[1], ui.get(menutbl["jitter"]))
                        ui.set(tbl.items.jitter[2], ui.get(menutbl["jitter_slider"]))
                        if ui.get(menutbl["body"]) ~= "luasense" then
                            ui.set(tbl.items.body[1], ui.get(menutbl["body"]))
                            ui.set(tbl.items.body[2], ui.get(menutbl["body_slider"]))
                        else
                            ui.set(tbl.items.body[1], "static")
                            local fake = (ui.get(menutbl["custom_slider"])+1) * 2
                            local luasensefake = false
                            if arg.command_number % client.random_int(3,6) == 1 then
                                tbl.antiaim.ready = true
                            end
                            if tbl.antiaim.ready and arg.chokedcommands == 0 then
                                tbl.antiaim.ready = false
                                tbl.antiaim.luasensefake = not tbl.antiaim.luasensefake
                                ui.set(tbl.items.body[2], tbl.antiaim.luasensefake and -fake or fake)
                                luasensefake = true
                            end
                            if tbl.contains(ui.get(menutbl["mode"]), "left right") then
                                if luasensefake then
                                    if tbl.antiaim.luasensefake then
                                        ui.set(tbl.items.yaw[2], tbl.clamp(yaw + ui.get(menutbl["right"])))
                                    else
                                        ui.set(tbl.items.yaw[2], tbl.clamp(yaw + ui.get(menutbl["left"])))
                                    end
                                end
                            end
                        end
                        if ui.get(menutbl["defensive"]) == "luasense" then
                            arg.force_defensive = arg.command_number % 3 ~= 1 or arg.weaponselect ~= 0 or arg.quick_stop == 1
                        elseif ui.get(menutbl["defensive"]) == "always on" then
                            arg.force_defensive = true
                        else end
                    elseif ui.get(menutbl["type"]) == "luasense" then
                        menutbl = menutbl[ui.get(menutbl["type"])]
                        ui.set(tbl.items.jitter[1], "off")
                        ui.set(tbl.items.body[1], "static")

                        local key = tostring(state) .. "_" .. tostring(team)
                        local temp = nil
                        if enemy ~= nil then
                            local tkey = tostring(enemy)
                            temp = tbl.antiaim.temp[tkey]
                            if temp and temp.expires and globals.realtime() > temp.expires then
                                tbl.antiaim.temp[tkey] = nil
                                temp = nil
                            end
                        end
                        local mode = ui.get(menutbl["luasense_mode"]) or "fixed"
                        local delay = temp and temp.delay or ui.get(menutbl["luasense"]) or 1
                        if tb_should_apply and tonumber(tb_override_val) then
                            delay = math.max(1, math.floor(tonumber(tb_override_val)))
                        end
                        if mode == "random" then
                            local maxv = ui.get(menutbl["luasense_random_max"]) or 4
                            if not tbl.antiaim.luasense_delay_cache[key] then
                                tbl.antiaim.luasense_delay_cache[key] = math.random(1, math.max(1, maxv))
                            end
                            delay = tbl.antiaim.luasense_delay_cache[key]
                        elseif mode == "min/max" then
                            local minv = ui.get(menutbl["luasense_min"]) or 1
                            local maxv = ui.get(menutbl["luasense_max"]) or math.max(minv, 2)
                            if minv > maxv then minv, maxv = maxv, minv end
                            if not tbl.antiaim.luasense_delay_cache[key] then
                                tbl.antiaim.luasense_delay_cache[key] = math.random(minv, maxv)
                            end
                            delay = tbl.antiaim.luasense_delay_cache[key]
                        end
                            if arg.command_number % (delay + 1 + 1) == 1 then
                                tbl.antiaim.ready = true
                            end
                                if tbl.antiaim.ready and arg.chokedcommands == 0 then
                                    local fake = (ui.get(menutbl["fake"])+1) * 2
                                    if temp and temp.fake then fake = (temp.fake + 1) * 2 end
                                    tbl.antiaim.ready = false
                                    tbl.antiaim.luasensefake = not tbl.antiaim.luasensefake
                                    if temp and temp.should_swap and enemy ~= nil then
                                        local sid = tostring(entity.get_steam64(enemy) or enemy)
                                        local entry = tbl.antiaim.log[sid]
                                        if entry and entry.value ~= nil and entry_is_fresh(entry) then
                                            tbl.antiaim.luasensefake = entry.value
                                        else
                                            tbl.antiaim.luasensefake = not tbl.antiaim.luasensefake
                                        end
                                    end
                                    local jitter_adj = temp and (temp.jitter_off or 0) or 0

                                    if mode == "random" or mode == "min/max" then tbl.antiaim.luasense_delay_cache[key] = nil end
                                    ui.set(tbl.items.body[2], tbl.antiaim.luasensefake and -fake or fake)
                                    local yaw = tbl.antiaim.manual.aa
                                        if tbl.contains(ui.get(menutbl["mode"]), "yaw") then
                                            yaw = tbl.antiaim.manual.aa + ui.get(menutbl["yaw"])
                                        end
                                        if tbl.contains(ui.get(menutbl["mode"]), "left right") then
                                            if tbl.antiaim.luasensefake then
                                                ui.set(tbl.items.yaw[2], tbl.clamp(yaw + ui.get(menutbl["right"])))
                                            else
                                                ui.set(tbl.items.yaw[2], tbl.clamp(yaw + ui.get(menutbl["left"])))
                                            end
                                        else
                                            ui.set(tbl.items.yaw[2], tbl.clamp(yaw))
                                        end
                        end
                        if ui.get(menutbl["defensive"]) == "luasense" then
                            arg.force_defensive = arg.command_number % 3 ~= 1 or arg.weaponselect ~= 0 or arg.quick_stop == 1
                        elseif ui.get(menutbl["defensive"]) == "always on" then
                            arg.force_defensive = true
                        else end
                    elseif ui.get(menutbl["type"]) == "advanced" then
                        menutbl = menutbl[ui.get(menutbl["type"])]
                        ui.set(tbl.items.jitter[1], "off")
                        ui.set(tbl.items.body[1], "static")
                        local trigger = client.random_int(3,6)
                        if ui.get(menutbl["trigger"]) == "a: brandon" then
                            trigger = 5
                        end
                        if ui.get(menutbl["trigger"]) == "b: best" then
                            trigger = 6
                        end
                        if ui.get(menutbl["trigger"]) == "c: experimental" then
                            if trigger == 1 or trigger == 1+1 then
                                trigger = 9
                            else
                                trigger = trigger + 1
                            end
                        end
                        if arg.command_number % trigger == 1 then
                            tbl.auto = not tbl.auto
                            if tbl.auto then
                                ui.set(tbl.items.body[2], -123)
                                ui.set(tbl.items.yaw[2], tbl.clamp(ui.get(menutbl["right"]) + tbl.antiaim.manual.aa))
                            else
                                ui.set(tbl.items.body[2], 123)
                                ui.set(tbl.items.yaw[2], tbl.clamp(ui.get(menutbl["left"]) + tbl.antiaim.manual.aa))
                            end
                        end
                        if ui.get(menutbl["defensive"]) == "luasense" then
                            arg.force_defensive = arg.command_number % 3 ~= 1 or arg.weaponselect ~= 0 or arg.quick_stop == 1
                        elseif ui.get(menutbl["defensive"]) == "always on" then
                            arg.force_defensive = true
                        else end
                    elseif ui.get(menutbl["type"]) == "auto" then
                    local function compute_exponential_delay(key, slider_base, enemy, cache_table_name, env_min, env_max)
                        slider_base = math.max(1.01, tonumber(slider_base) or 1.01)
                        
                        
                        tbl.antiaim.exp_state = tbl.antiaim.exp_state or {}
                        local s = tbl.antiaim.exp_state[key] or {}
                        local now = globals.realtime()
                        
                        
                        if not s.seed then
                            s.seed = 0
                            for i = 1, #key do 
                                s.seed = (s.seed * 131 + key:byte(i)) % 1000003 
                            end
                            s.created = now
                            s.last_flip = now
                            s.phase_offset = (s.seed % 100) / 100 * math.pi * 2
                            s.chaos_state = 0.5
                            s.fibonacci = {1, 1}
                            s.wave_states = {
                                {freq = 1.0, phase = 0, amp = 1.0},
                                {freq = 2.718, phase = 0.33, amp = 0.7},
                                {freq = 1.618, phase = 0.66, amp = 0.5}
                            }
                        end
                        
                        
                        
                        
                        
                        local dist_m = 50
                        local velocity = 0
                        local hp_factor = 1.0
                        local threat_level = 0.5
                        
                        if enemy and entity.is_alive(enemy) then
                            local lp = entity.get_local_player()
                            if lp and entity.is_alive(lp) then
                                
                                local ex, ey, ez = entity.get_prop(enemy, "m_vecOrigin")
                                local lx, ly, lz = entity.get_prop(lp, "m_vecOrigin")
                                if ex and lx then
                                    local dx, dy, dz = ex - lx, ey - ly, (ez or 0) - (lz or 0)
                                    local meters = math.sqrt(dx*dx + dy*dy + dz*dz) / 52.493
                                    dist_m = math.max(1, meters)
                                end
                                
                                
                                local vx, vy, vz = entity.get_prop(enemy, "m_vecVelocity")
                                if vx then
                                    velocity = math.sqrt(vx*vx + vy*vy) / 250
                                    velocity = math.min(1, velocity)
                                end
                                
                                
                                local hp = entity.get_prop(enemy, "m_iHealth") or 100
                                hp_factor = func.fclamp(hp / 100, 0.3, 1.5)
                                
                                
                                local wp = entity.get_player_weapon(enemy)
                                if wp then
                                    local wclass = entity.get_classname(wp) or ""
                                    if wclass:find("AWP") or wclass:find("SSG08") then
                                        threat_level = 0.9
                                    elseif wclass:find("Rifle") or wclass:find("AK47") or wclass:find("M4A") then
                                        threat_level = 0.7
                                    else
                                        threat_level = 0.4
                                    end
                                end
                            end
                        end
                        
                        
                        
                        
                        
                        
                        local r_chaos = 3.9 + math.sin(now * 0.3) * 0.1
                        s.chaos_state = r_chaos * s.chaos_state * (1 - s.chaos_state)
                        
                        
                        local fib_next = s.fibonacci[1] + s.fibonacci[2]
                        s.fibonacci[1], s.fibonacci[2] = s.fibonacci[2], fib_next % 89
                        local fib_ratio = s.fibonacci[2] / math.max(1, s.fibonacci[1])
                        
                        
                        local wave_sum = 0
                        for i, w in ipairs(s.wave_states) do
                            local phase = w.phase + now * w.freq * 0.1
                            wave_sum = wave_sum + math.sin(phase * 2 * math.pi + s.phase_offset) * w.amp
                            w.phase = (w.phase + 0.001 * slider_base) % 1
                        end
                        wave_sum = (wave_sum + 2) / 4 
                        
                        local primes = {2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31}
                        local tick = globals.tickcount()
                        local prime_idx = (tick + s.seed) % #primes + 1
                        local prime_mod = primes[prime_idx] / 31
                        
                        local conf = 0
                        local pattern_bonus = 0
                        
                        if enemy then
                            local sid = tostring(entity.get_steam64(enemy) or enemy)
                            local entry = tbl.antiaim.log and tbl.antiaim.log[sid]
                            
                            if entry and type(entry.count) == "number" then
                                
                                conf = func.fclamp((entry.count or 0) / math.max(1, (tbl.antiaim.learn_threshold or 2)), 0, 2)
                                if entry.locked then 
                                    conf = conf + 0.5 
                                    pattern_bonus = 0.3 
                                end
                            end
                        end
                        
                        local since_flip = now - (s.last_flip or s.created or now)
                        
                        local base_period = 3.0 + (slider_base - 1) * 2.5
                        
                        local dist_factor = func.fclamp(25 / (dist_m + 1), 0.25, 2.5)
                        local velocity_factor = 1.0 + velocity * 0.4
                        local hp_modulation = 1.0 / hp_factor
                        local threat_modulation = 1.0 + (1.0 - threat_level) * 0.3
                        
                        local confidence_factor = 1.0 / (1 + 0.6 * conf)
                        
                        local period = base_period * dist_factor * confidence_factor * velocity_factor * hp_modulation * threat_modulation
                        period = math.max(0.4, period)
                        
                        local phase = func.fclamp((since_flip / period), 0, 10)
                        local shape = 1.5 + (slider_base - 1) * 0.6
                        shape = shape * (1 + s.chaos_state * 0.3) 
                        shape = shape * (1 + wave_sum * 0.2) 

                        local phase_shaped = math.pow(phase / (1 + phase), shape)
                        
                        local base = slider_base
                        local denom = base - 1 
                        local exp_component = denom > 1e-9 and ((base ^ phase_shaped - 1) / denom) or phase_shaped
                        
                        local spiral_component = (1 + fib_ratio) / 2.618

                        local wave_component = wave_sum

                        local frac = exp_component * 0.5 + spiral_component * 0.3 + wave_component * 0.2

                        local compress = 1 / (1 + (base - 1) * 0.05)
                        frac = math.pow(func.fclamp(frac, 0, 1), compress)

                        local max_delay = 22

                        local amplitude = 1.0
                        amplitude = amplitude + conf * 0.6 
                        amplitude = amplitude + (1.0 / (dist_m/20 + 1)) * 0.5 
                        amplitude = amplitude + pattern_bonus 
                        amplitude = amplitude * (1 + threat_level * 0.3) 
                        amplitude = func.fclamp(amplitude, 0.5, 2.5)

                        local mapped = 1 + (max_delay - 1) * frac * amplitude
                        
                        local chaos_jitter = (s.chaos_state - 0.5) * 2

                        local prime_jitter = (prime_mod - 0.5) * 2

                        local wave_jitter = (wave_sum - 0.5) * 2

                        local jitter_fade = 1.0 - math.sqrt(func.fclamp(phase, 0, 1))

                        local jitter_strength = (0.9 + (slider_base - 1) * 0.5) * jitter_fade

                        local total_jitter = (chaos_jitter * 0.4 + prime_jitter * 0.3 + wave_jitter * 0.3) * jitter_strength

                        local result = mapped + total_jitter

                        local min_limit = env_min and math.max(1, math.floor(env_min)) or 1
                        local max_limit = env_max and math.max(min_limit, math.floor(env_max)) or max_delay
                        
                        result = func.fclamp(result, min_limit, max_limit)
                        result = math.max(1, math.min(max_delay, math.floor(result + 0.5)))

                        if cache_table_name and tbl.antiaim[cache_table_name] then
                            tbl.antiaim[cache_table_name][key] = result
                        else
                            tbl.antiaim.luasense_prog_cache = tbl.antiaim.luasense_prog_cache or {}
                            tbl.antiaim.luasense_prog_cache[key] = result
                        end
                        
                        tbl.antiaim.exp_state[key] = s
                        
                        return result
                    end
                                    local experimental_delay = {
                                        
                                        quantum_state = {
                                            wave = 0,
                                            entanglement = 0,
                                            superposition = {0, 0, 0}
                                        },
                                        
                                        
                                        fractal = {
                                            octaves = 6,
                                            persistence = 0.5,
                                            lacunarity = 2.0,
                                            seed_offset = 0
                                        },
                                        
                                        
                                        primes = {2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61, 67, 71, 73, 79, 83, 89, 97},
                                        
                                        
                                        automata = {
                                            cells = {},
                                            generation = 0,
                                            rule = 30  
                                        },
                                        
                                        
                                        attractors = {
                                            rossler = {x = 0.1, y = 0, z = 0},
                                            henon = {x = 0, y = 0},
                                            duffing = {x = 0.1, v = 0}
                                        },
                                        
                                        
                                        waves = {
                                            {freq = 1.618, phase = 0, amp = 1},      
                                            {freq = 2.718, phase = 0.5, amp = 0.8},  
                                            {freq = 3.141, phase = 1, amp = 0.6}     
                                        },
                                        
                                        config = {
                                            min_delay = 1,
                                            max_delay = 22,
                                            complexity = 0.85  
                                        }
                                    }

                                    local function quantum_measure(state, time)
                                        
                                        local psi = 0
                                        for i = 1, 3 do
                                            psi = psi + math.sin(time * i * 1.618 + state.superposition[i]) * (1 / i)
                                        end

                                        state.entanglement = (state.entanglement + psi * 0.1) % (2 * math.pi)

                                        local collapsed = math.abs(psi + math.sin(state.entanglement))
                                        state.wave = collapsed
                                        
                                        for i = 1, 3 do
                                            state.superposition[i] = (state.superposition[i] + collapsed * 0.01 * i) % (2 * math.pi)
                                        end
                                    
                                        return collapsed
                                    end

                                    local function fbm_noise(x, y, octaves, persistence, lacunarity)
                                        local function hash(n)
                                            n = bit.bxor(n, bit.rshift(n, 15))
                                            n = n * 0x85ebca6b
                                            n = bit.bxor(n, bit.rshift(n, 13))
                                            n = n * 0xc2b2ae35
                                            n = bit.bxor(n, bit.rshift(n, 16))
                                            return n
                                        end
                                        
                                        local function noise2d(x, y)
                                            local xi = math.floor(x)
                                            local yi = math.floor(y)
                                            local xf = x - xi
                                            local yf = y - yi
                                            
                                            local function lerp(a, b, t)
                                                return a + (b - a) * t
                                            end
                                            
                                            local function fade(t)
                                                return t * t * t * (t * (t * 6 - 15) + 10)
                                            end
                                            
                                            local h00 = hash(xi + hash(yi))
                                            local h10 = hash(xi + 1 + hash(yi))
                                            local h01 = hash(xi + hash(yi + 1))
                                            local h11 = hash(xi + 1 + hash(yi + 1))
                                            
                                            local u = fade(xf)
                                            local v = fade(yf)
                                            
                                            local a = lerp((h00 % 65536) / 65536, (h10 % 65536) / 65536, u)
                                            local b = lerp((h01 % 65536) / 65536, (h11 % 65536) / 65536, u)
                                            
                                            return lerp(a, b, v)
                                        end
                                        
                                        local total = 0
                                        local amplitude = 1
                                        local frequency = 1
                                        local max_value = 0
                                        
                                        for i = 1, octaves do
                                            total = total + noise2d(x * frequency, y * frequency) * amplitude
                                            max_value = max_value + amplitude
                                            amplitude = amplitude * persistence
                                            frequency = frequency * lacunarity
                                        end
                                        
                                        return total / max_value
                                    end

                                    local function rossler_step(state, dt)
                                        local a, b, c = 0.2, 0.2, 5.7
                                        dt = dt or 0.01
                                        
                                        local dx = -(state.y + state.z) * dt
                                        local dy = (state.x + a * state.y) * dt
                                        local dz = (b + state.z * (state.x - c)) * dt
                                        
                                        return {
                                            x = state.x + dx,
                                            y = state.y + dy,
                                            z = state.z + dz
                                        }
                                    end

                                    local function henon_step(state)
                                        local a, b = 1.4, 0.3
                                        local x_new = 1 - a * state.x * state.x + state.y
                                        local y_new = b * state.x
                                        return {x = x_new, y = y_new}
                                    end

                                    local function automata_step(cells, rule)
                                        local new_cells = {}
                                        local size = #cells
                                        
                                        for i = 1, size do
                                            local left = cells[i == 1 and size or i - 1] or 0
                                            local center = cells[i] or 0
                                            local right = cells[i == size and 1 or i + 1] or 0
                                            
                                            local index = left * 4 + center * 2 + right
                                            new_cells[i] = bit.band(bit.rshift(rule, index), 1)
                                        end
                                        
                                        return new_cells
                                    end

                                    local function wave_interference(waves, time)
                                        local result = 0
                                        for i, wave in ipairs(waves) do
                                            local phase = wave.phase + time * wave.freq
                                            result = result + math.sin(phase * 2 * math.pi) * wave.amp
                                            
                                            
                                            wave.phase = (wave.phase + 0.001) % 1
                                        end
                                        return result
                                    end

                                    local function prime_chaos(primes, seed, index)
                                        local p1 = primes[(index % #primes) + 1]
                                        local p2 = primes[((index + 7) % #primes) + 1]
                                        local p3 = primes[((index + 13) % #primes) + 1]
                                        
                                        local value = (seed * p1 + p2 * p3) % (p1 * p2)
                                        return (value % 10000) / 10000
                                    end

                                    function experimental_delay.calculate(key, context)
                                        context = context or {}
                                        local time = globals.realtime()
                                        local tick = globals.tickcount()

                                        local quantum = quantum_measure(experimental_delay.quantum_state, time)

                                        experimental_delay.fractal.seed_offset = experimental_delay.fractal.seed_offset + 0.01
                                        local fbm = fbm_noise(
                                            time * 0.1 + experimental_delay.fractal.seed_offset,
                                            tick * 0.001,
                                            experimental_delay.fractal.octaves,
                                            experimental_delay.fractal.persistence,
                                            experimental_delay.fractal.lacunarity
                                        )

                                        experimental_delay.attractors.rossler = rossler_step(experimental_delay.attractors.rossler, 0.02)
                                        local rossler = (experimental_delay.attractors.rossler.x % 10) / 10

                                        experimental_delay.attractors.henon = henon_step(experimental_delay.attractors.henon)
                                        local henon = (experimental_delay.attractors.henon.x + 2) / 4  

                                        if #experimental_delay.automata.cells == 0 then
                                            for i = 1, 32 do
                                                experimental_delay.automata.cells[i] = math.random(0, 1)
                                            end
                                        end
                                        
                                        if experimental_delay.automata.generation % 3 == 0 then
                                            experimental_delay.automata.cells = automata_step(
                                                experimental_delay.automata.cells,
                                                experimental_delay.automata.rule
                                            )
                                        end
                                        experimental_delay.automata.generation = experimental_delay.automata.generation + 1
                                        
                                        local automata_value = 0
                                        for i, v in ipairs(experimental_delay.automata.cells) do
                                            automata_value = automata_value + v
                                        end
                                        automata_value = automata_value / #experimental_delay.automata.cells

                                        local wave = (wave_interference(experimental_delay.waves, time) + 3) / 6

                                        local key_hash = 0
                                        if key then
                                            for i = 1, #key do
                                                key_hash = key_hash + string.byte(key, i) * i
                                            end
                                        end
                                        local prime = prime_chaos(experimental_delay.primes, tick + key_hash, tick)

                                        local complexity = experimental_delay.config.complexity
                                        local combined = 
                                            quantum * 0.20 * complexity +
                                            fbm * 0.18 +
                                            rossler * 0.15 * complexity +
                                            henon * 0.12 * complexity +
                                            automata_value * 0.10 +
                                            wave * 0.15 +
                                            prime * 0.10

                                        if context.enemy_distance then
                                            local dist_factor = math.min(1, context.enemy_distance / 500)
                                            combined = combined * (0.7 + dist_factor * 0.6)
                                        end
                                        
                                        if context.velocity then
                                            local vel_factor = math.min(1, context.velocity / 250)
                                            combined = combined * (0.85 + vel_factor * 0.3)
                                        end

                                        local min_d = experimental_delay.config.min_delay
                                        local max_d = experimental_delay.config.max_delay
                                        local range = max_d - min_d

                                        local sigmoid = 1 / (1 + math.exp(-10 * (combined - 0.5)))
                                        local delay = min_d + range * sigmoid

                                        local perturbation = math.sin(time * 7.389) * math.cos(tick * 0.1337) * 0.5
                                        delay = delay + perturbation

                                        return math.max(min_d, math.min(max_d, math.floor(delay + 0.5)))
                                    end
            menutbl = menutbl[ui.get(menutbl["type"])]
            local parent_tbl = aa[state] and aa[state][team]
            local auto_ctrl = parent_tbl and parent_tbl["auto"]
            local function aget(k) if not auto_ctrl or not k then return nil end local ok, v = pcall(ui.get, auto_ctrl[k]); return ok and v end

            ui.set(tbl.items.jitter[1], "random")
            ui.set(tbl.items.yaw[2], tbl.antiaim.manual.aa)
            
            local check = arg.command_number % 10 > 5
            if tbl.antiaim.fs ~= 0 then
                check = tbl.antiaim.fs ~= 1
                tbl.antiaim.last = check
                tbl.antiaim.current = check
                tbl.antiaim.active = true
            end
            if ui.get(menutbl["method"]) == "simple" and tbl.antiaim.fs == 0 then
                check = not tbl.antiaim.last
                tbl.antiaim.current = check
                tbl.antiaim.active = true
            end
            
            
            if ui.get(menutbl["method"]) == "luasense" then
                if tbl.antiaim.count then
                    if tbl.antiaim.timer > ui.get(menutbl["timer"]) then
                        tbl.antiaim.timer = 0
                        tbl.antiaim.count = false
                        tbl.antiaim.log = {}
                        update_and_save_antibf()
                    else
                        tbl.antiaim.timer = tbl.antiaim.timer + 1
                    end
                end
                
                if tbl.antiaim.fs == 0 then
                    local key = tostring(state) .. "_" .. tostring(team)
                    local temp = nil
                    if enemy ~= nil then
                        local tkey = tostring(enemy)
                        temp = tbl.antiaim.temp[tkey]
                        if temp and temp.expires and globals.realtime() > temp.expires then
                            tbl.antiaim.temp[tkey] = nil
                            temp = nil
                        end
                    end
                    
                    local mode = ui.get(menutbl["delay_mode"]) or "fixed"
                    local delay = (temp and temp.delay) or ui.get(menutbl["delay"]) or 1
                    
                    if tb_should_apply and tonumber(tb_override_val) then
                        delay = math.max(1, math.floor(tonumber(tb_override_val)))
                    end
                    
                    
                    if mode == "random" then
                        local maxv = ui.get(menutbl["random_max"]) or 4
                        if not tbl.antiaim.luasense_delay_cache[key] then
                            tbl.antiaim.luasense_delay_cache[key] = math.random(1, math.max(1, math.floor(maxv)))
                        end
                        delay = tbl.antiaim.luasense_delay_cache[key]
                    elseif mode == "min/max" then
                        local minv = ui.get(menutbl["min_delay"]) or 1
                        local maxv = ui.get(menutbl["max_delay"]) or math.max(minv, 2)
                        if minv > maxv then minv, maxv = maxv, minv end
                        if not tbl.antiaim.luasense_delay_cache[key] then
                            tbl.antiaim.luasense_delay_cache[key] = math.random(math.floor(minv), math.floor(maxv))
                        end
                        delay = tbl.antiaim.luasense_delay_cache[key]
                    elseif mode == "exponential" then
                        local slider_val = ui.get(menutbl["delay_exponentialfunction"]) or 1
                        local ok_min, minv = pcall(ui.get, menutbl["delay_exponential_min"])
                        local ok_max, maxv = pcall(ui.get, menutbl["delay_exponential_max"])
                        delay = compute_exponential_delay(key, slider_val, enemy, "luasense_prog_cache", ok_min and tonumber(minv) or nil, ok_max and tonumber(maxv) or nil)
                    elseif mode == "experimental" then
                        local key_exp = string.format("%s_%s", state, team)
                        local context_exp = {}
                        local lp_exp = entity.get_local_player()
                        if lp_exp and entity.is_alive(lp_exp) then
                            local enemy_exp = client.current_threat()
                            if enemy_exp then
                                local lx_exp, ly_exp, lz_exp = entity.get_prop(lp_exp, "m_vecOrigin")
                                local ex_exp, ey_exp, ez_exp = entity.get_prop(enemy_exp, "m_vecOrigin")
                                if lx_exp and ex_exp then
                                    context_exp.enemy_distance = math.sqrt(
                                        (ex_exp - lx_exp)^2 + (ey_exp - ly_exp)^2 + (ez_exp - lz_exp)^2
                                    )
                                end
                            end
                            
                            local vx_exp, vy_exp, vz_exp = entity.get_prop(lp_exp, "m_vecVelocity")
                            if vx_exp then
                                context_exp.velocity = math.sqrt(vx_exp^2 + vy_exp^2)
                            end
                        end
                        delay = experimental_delay.calculate(key_exp, context_exp)
                    end
                    
                    delay = math.max(1, math.floor(tonumber(delay) or 1))
                    
                    
                    if arg.command_number % (delay + 2) == 1 then
                        tbl.antiaim.ready = true
                    end
                    
                    if tbl.antiaim.ready and arg.chokedcommands == 0 then
                        tbl.antiaim.ready = false
                        tbl.antiaim.luasensefake = not tbl.antiaim.luasensefake
                        
                        if temp and temp.should_swap and enemy ~= nil then
                            local sid = tostring(entity.get_steam64(enemy) or enemy)
                            local entry = tbl.antiaim.log[sid]
                            if entry and entry.value ~= nil and entry_is_fresh(entry) then
                                tbl.antiaim.luasensefake = entry.value
                            else
                                tbl.antiaim.luasensefake = not tbl.antiaim.luasensefake
                            end
                        end
                        
                        if mode ~= "fixed" then
                            tbl.antiaim.luasense_delay_cache[key] = nil
                        end
                    end
                    
                    local yaw = tbl.antiaim.manual.aa
                    check = tbl.antiaim.luasensefake
                    
                    
                    local enablerand = aget("enablerand")
                    local rand_max_base = math.max(0, tonumber(aget("randomization") or 0))
                    if not enablerand then
                        rand_max_base = 0
                        if tbl.antiaim.auto_rand_cache then tbl.antiaim.auto_rand_cache[key] = nil end
                    end
                    
                    local rand_max = rand_max_base
                    local left_rand, right_rand = 0, 0
                    if rand_max > 0 then
                        left_rand  = client.random_int(-math.floor(rand_max), math.floor(rand_max))
                        right_rand = client.random_int(-math.floor(rand_max), math.floor(rand_max))
                    end
                    
                    
                    local body_mode = aget("body1") or "off"
                    
                    if body_mode == "off" then
                        ui.set(tbl.items.body[1], "off")
                        ui.set(tbl.items.body[2], 0)
                        
                    elseif body_mode == "luasense" then
                        ui.set(tbl.items.body[1], "static")
                        local fake_custom = (aget("custom_slider1") or 60)
                        fake_custom = (fake_custom + 1) * 2
                        ui.set(tbl.items.body[2], tbl.antiaim.luasensefake and -fake_custom or fake_custom)
                        
                    elseif body_mode == "opposite" then
                        ui.set(tbl.items.body[1], "opposite")
                        ui.set(tbl.items.body[2], 0)
                        
                    elseif body_mode == "static" then
                        ui.set(tbl.items.body[1], "static")
                        ui.set(tbl.items.body[2], aget("body_slider1") or 0)
                        
                    elseif body_mode == "jitter" then
                        ui.set(tbl.items.body[1], "jitter")
                        ui.set(tbl.items.body[2], aget("body_slider1") or 0)
                    end
                    
                    
                    if tbl.antiaim.luasensefake then
                        ui.set(tbl.items.yaw[2], tbl.clamp(yaw + (aget("right") or 0) + right_rand))
                    else
                        ui.set(tbl.items.yaw[2], tbl.clamp(yaw + (aget("left") or 0) + left_rand))
                    end
                    
                    ui.set(tbl.items.jitter[2], 0)
                end
            end

            
            if ui.get(menutbl["antibf"]) == "yes" and enemy ~= nil then
                local sid = tostring(entity.get_steam64(enemy) or enemy)
                local entry = tbl.antiaim.log[sid]
                if entry then
                    local now = globals.realtime()
                    local fresh = entry_is_fresh(entry, now)
                    if (entry.locked or (entry.count and entry.count >= (tbl.antiaim.learn_threshold or 2))) and fresh then
                        check = entry.value
                    end
                end
            end

            ui.set(tbl.items.jitter[2], check and -3 or 3)

            if ui.get(menutbl["defensive"]) == "luasense" then
                arg.force_defensive = arg.command_number % 3 ~= 1 or arg.weaponselect ~= 0 or arg.quick_stop == 1
            elseif ui.get(menutbl["defensive"]) == "always on" then
                arg.force_defensive = true
            else end

                    if ui.get(menutbl["defensive"]) == "luasense" then
                        arg.force_defensive = arg.command_number % 3 ~= 1 or arg.weaponselect ~= 0 or arg.quick_stop == 1
                        elseif ui.get(menutbl["defensive"]) == "always on" then
                            arg.force_defensive = true
                        else end
                    else end
                ui.set(tbl.items.edge[1], ui.get(menu["anti aimbot"]["keybinds"]["edge"]))
                local freestand = ui.get(menu["anti aimbot"]["keybinds"]["freestand"])
                local disablers = ui.get(menu["anti aimbot"]["keybinds"]["disablers"])
                if tbl.contains(disablers, "air") and (arg.in_jump == 1 or air) then
                    freestand = false
                end
                if tbl.contains(disablers, "slow") and (ui.get(tbl.refs.slow[1]) and ui.get(tbl.refs.slow[2])) then
                    freestand = false
                end
                if tbl.contains(disablers, "duck") and (duck) then
                    freestand = false
                end
                if tbl.contains(disablers, "edge") and (ui.get(menu["anti aimbot"]["keybinds"]["edge"])) then
                    freestand = false
                end
                if tbl.contains(disablers, "manual") and (tbl.antiaim.manual.aa ~= 0) then
                    freestand = false
                end
                if tbl.contains(disablers, "fake lag") and (fakelag) then
                    freestand = false
                end
                if tbl.antiaim.manual.aa ~= 0 then
                    ui.set(tbl.items.base[1], "local view")
                    if ui.get(menu["anti aimbot"]["keybinds"]["type_manual"]) ~= "default" then
                        ui.set(tbl.items.yaw[2], tbl.antiaim.manual.aa)
                        ui.set(tbl.items.jitter[1], "off")
                        ui.set(tbl.items.jitter[2], 0)
                        ui.set(tbl.items.body[1], ui.get(menu["anti aimbot"]["keybinds"]["type_manual"]) == "jitter" and "jitter" or "opposite")
                        ui.set(tbl.items.body[2], 0)
                    end
                end
                if ui.get(menu["anti aimbot"]["keybinds"]["type_freestand"]) ~= "default" and freestand then
                    ui.set(tbl.items.yaw[2], 0)
                    ui.set(tbl.items.jitter[1], "off")
                    ui.set(tbl.items.jitter[2], 0)
                    ui.set(tbl.items.body[1], ui.get(menu["anti aimbot"]["keybinds"]["type_freestand"]) == "jitter" and "jitter" or "opposite")
                    ui.set(tbl.items.body[2], 0)
                    arg.force_defensive = true
                end
                ui.set(tbl.items.fs[1], freestand)
                local defensivecheck = (z.defensive.defensive > 3) and (z.defensive.defensive < 11)
                if fakelag or hideshot then
                    defensivecheck = false
                end
                local defensivemenu = ui.get(menu["anti aimbot"]["features"]["defensive"])
                tbl.normal_aa = true
                tbl.tick_aa = tbl.tick_aa + 1
                tbl.list_aa[tbl.tick_aa] = {
                    ["aa"] = ui.get(tbl.items.yaw[2]),
                }
                if defensivemenu ~= "off" and defensivecheck and not freestand and tbl.antiaim.manual.aa == 0 and tbl.contains(ui.get(menu["anti aimbot"]["features"]["states"]), real_state) then
                    tbl.normal_aa = false
                    if defensivemenu == "pitch" then
                        ui.set(tbl.items.pitch[1], "up")
                    elseif defensivemenu == "spin" then
                        ui.set(tbl.items.yaw[2], (((arg.command_number % 360) - 180) * 3) % 180)
                    elseif defensivemenu == "random" then
                        ui.set(tbl.items.yaw[2], client.random_int(-180,180))
                    elseif defensivemenu == "random pitch" then
                        ui.set(tbl.items.pitch[1], (arg.command_number % 4 > 2) and "up" or "down")
                        ui.set(tbl.items.yaw[2], client.random_int(-180,180))
                    elseif defensivemenu == "sideways up" then
                        ui.set(tbl.items.pitch[1], "up")
                        ui.set(tbl.items.yaw[2], (arg.command_number % 6 > 3) and 111 or -111)
                    elseif defensivemenu == "sideways down" then
                        ui.set(tbl.items.yaw[2], (arg.command_number % 6 > 3) and 111 or -111)
                    end
                    if defensivemenu ~= "pitch" then
                        tbl.reset_aa = true
                        tbl.defensive_aa = ui.get(tbl.items.yaw[2])
                    end
                end
                tbl.list_aa[tbl.tick_aa]["check"] = tbl.normal_aa
                if tbl.normal_aa and tbl.reset_aa and ui.get(menu["anti aimbot"]["features"]["fixer"]) == "luasense" then
                    tbl.reset_aa = false
                    for i = 1, 69 do
                        if tbl.list_aa[tbl.tick_aa-i] then
                            if tbl.list_aa[tbl.tick_aa-i]["check"] then
                                if tbl.defensive_aa ~= tbl.list_aa[tbl.tick_aa-i]["aa"] then
                                    ui.set(tbl.items.yaw[2], tbl.list_aa[tbl.tick_aa-i]["aa"])
                                    return nil
                                end
                            end
                        end
                    end
                end
            end,
            ["reset"] = function()
                if tbl.contains(ui.get(menu["visuals & misc"]["visuals"]["notify"]), "reset") then
                    local r, g, b, a = ui.get(menu["visuals & misc"]["visuals"]["notcolor"])
                    local colored_antiaim = ("\a%02x%02x%02x%02x%s"):format(r, g, b, a, "Anti-Aim")
                    local colored_newround = ("\a%02x%02x%02x%02x%s"):format(r, g, b, a, "new round")
                    local white = "\aFFFFFFFF"
                    push_notify(white .. colored_antiaim .. white .. " reseted due to " .. colored_newround .. white .. "!  ")
                end
                tbl.antiaim.manual.aa = 0
                tbl.antiaim.manual.tick = 0
                if ui.get(menu["visuals & misc"]["misc"]["autobuy"]) ~= "off" then
                    client.exec("buy " .. (ui.get(menu["visuals & misc"]["misc"]["autobuy"]) == "scout" and "ssg08" or "awp"))
                end
            end,
            ["menu"] = function()
                if ii == "custom_wtext" then
                    fix = ui.get(value["wtext"]) == "custom"
                end
                if ii == "custom_prefix" then
                    fix = ui.get(value["wtext"]) == "custom"
                end
                if ii == "custom_prefix2" then
                    fix = ui.get(value["wtext"]) == "custom"
                end
                ui.set(menu["anti aimbot"]["keybinds"]["left"], "on hotkey")
                ui.set(menu["anti aimbot"]["keybinds"]["right"], "on hotkey")
                ui.set(menu["anti aimbot"]["keybinds"]["forward"], "on hotkey")
                ui.set(menu["anti aimbot"]["keybinds"]["backward"], "on hotkey")
            
                local tick = globals.tickcount()
                if ui.get(menu["anti aimbot"]["keybinds"]["left"]) and (tbl.antiaim.manual.tick < tick - 11) then
                    tbl.antiaim.manual.aa = tbl.antiaim.manual.aa == -90 and 0 or -90
                    tbl.antiaim.manual.tick = tick
                end
                if ui.get(menu["anti aimbot"]["keybinds"]["right"]) and (tbl.antiaim.manual.tick < tick - 11) then
                    tbl.antiaim.manual.aa = tbl.antiaim.manual.aa == 90 and 0 or 90
                    tbl.antiaim.manual.tick = tick
                end
                if ui.get(menu["anti aimbot"]["keybinds"]["forward"]) and (tbl.antiaim.manual.tick < tick - 11) then
                    tbl.antiaim.manual.aa = tbl.antiaim.manual.aa == 180 and 0 or 180
                    tbl.antiaim.manual.tick = tick
                end
                if ui.get(menu["anti aimbot"]["keybinds"]["backward"]) and (tbl.antiaim.manual.tick < tick - 11) then
                    tbl.antiaim.manual.aa = tbl.antiaim.manual.aa == -1 and 0 or -1
                    tbl.antiaim.manual.tick = tick
                end
                if tbl.contains(ui.get(menu["visuals & misc"]["misc"]["features"]), "fix hideshot") then
                    ui.set(limitfl, (ui.get(tbl.refs.hide[1]) and ui.get(tbl.refs.hide[2])) and 1 or 14)
                end
                if tbl.contains(ui.get(menu["visuals & misc"]["misc"]["features"]), "legs spammer") then
                    ui.set(legs, globals.tickcount() % ui.get(menu["visuals & misc"]["misc"]["spammer"]) == 0 and "never slide" or "always slide")
                end
                if not ui.is_menu_open() then return nil end
            
                for i, v in next, tbl.items do
                    for index, value in next, v do
                        ui.set_visible(value, false)
                    end
                end
            
                local current = ui.get(category)
                local sub = ui.get(menu["anti aimbot"]["submenu"])
                local subextra = ui.get(menu["visuals & misc"]["submenu"])
                local fix = true
            
                for i, v in next, aa do
                    local section = ui.get(menu["anti aimbot"]["builder"]["builder"]) == i
                    for index, value in next, v do 
                        local selected = ui.get(menu["anti aimbot"]["builder"]["team"]) == index
                        for ii, vv in next, value do
                            if ii ~= "type" and ii ~= "button" then
                                local mode = ui.get(value["type"])
                                for iii, vvv in next, vv do
                                    fix = true
                                    if ii == "normal" then
                                        if iii == "jitter_slider" then
                                            fix = ui.get(vv["jitter"]) ~= "off"
                                        end
                                        if iii == "body_slider" then
                                            fix = ui.get(vv["body"]) ~= "off" and ui.get(vv["body"]) ~= "opposite" and ui.get(vv["body"]) ~= "luasense"
                                        end
                                        if iii == "custom_slider" then
                                            fix = ui.get(vv["body"]) == "luasense"
                                        end
                                        if iii == "yaw" then
                                            fix = tbl.contains(ui.get(vv["mode"]), iii)
                                        end
                                        if iii == "left" or iii == "right" or iii == "method" then
                                            fix = tbl.contains(ui.get(vv["mode"]), "left right")
                                        end
                                    end
                                    if ii == "luasense" then
                                        if iii == "yaw" then
                                            fix = tbl.contains(ui.get(vv["mode"]), iii)
                                        end
                                        if iii == "left" or iii == "right" then
                                            fix = tbl.contains(ui.get(vv["mode"]), "left right")
                                        end
                                        if iii == "luasense" then
                                            fix = ui.get(vv["luasense_mode"]) == "fixed"
                                        end
                                        if iii == "luasense_random_max" then
                                            fix = ui.get(vv["luasense_mode"]) == "random"
                                        end
                                            if iii == "luasense_min" or iii == "luasense_max" then
                                                fix = ui.get(vv["luasense_mode"]) == "min/max"
                                        end
                                    end
                                    if ii == "auto" then
                                        if iii == "timer" or iii == "timertxt" then
                                            fix = ui.get(vv["method"]) == "luasense" and ui.get(vv["antibf"]) == "yes"
                                        elseif iii == "left" or iii == "right" or iii == "delay_mode" then
                                            fix = ui.get(vv["method"]) == "luasense"
                                        elseif iii == "randomization" then
                                            fix = ui.get(vv["enablerand"]) == true
                                        elseif iii == "delay" then
                                            fix = ui.get(vv["method"]) == "luasense" and ui.get(vv["delay_mode"]) == "fixed"
                                        elseif iii == "random_max" then
                                            fix = ui.get(vv["method"]) == "luasense" and ui.get(vv["delay_mode"]) == "random"
                                        elseif iii == "min_delay" or iii == "max_delay" then
                                            fix = ui.get(vv["method"]) == "luasense" and ui.get(vv["delay_mode"]) == "min/max"
                                        elseif iii == "delay_exponentialfunction" or iii == "delay_exponential_min" or iii == "delay_exponential_max" then
                                            fix = ui.get(vv["method"]) == "luasense" and ui.get(vv["delay_mode"]) == "exponential"
                                        -- **NEW: Body yaw visibility controls**
                                        elseif iii == "body1" or iii == "body_slider1" or iii == "custom_slider1" then
                                            -- Show body yaw controls for auto type
                                            if iii == "body_slider1" then
                                                -- Show body slider when body mode is static or jitter
                                                fix = ui.get(vv["body1"]) == "static" or ui.get(vv["body1"]) == "jitter"
                                            elseif iii == "custom_slider1" then
                                                -- Show custom slider when body mode is luasense
                                                fix = ui.get(vv["body1"]) == "luasense"
                                            else
                                                -- Always show body1 (body mode selector)
                                                fix = true
                                            end
                                        end
                                    end
                                    ui.set_visible(vvv, section and selected and current == "anti aimbot" and sub == "builder" and mode == ii and fix)
                                end
                            else
                                ui.set_visible(vv, section and selected and current == "anti aimbot" and sub == "builder")
                            end
                        end
                    end
                end
    
    for i, v in next, menu do
        for index, value in next, v do
            if i == "anti aimbot" and index ~= "submenu" then
                for ii, vv in next, value do
                    fix = true
                    if index == "features" then
                        if ii == "distance" then
                            fix = ui.get(value["backstab"]) ~= "off"
                        end
                        if ii == "fix" then
                            fix = ui.get(value["legit"]) ~= "off"
                        end
                    if ii == "autohs" or ii == "autohscond" then
                        fix = ui.get(value["enableautohs"]) == true
                    end
                        if ii == "fixer" or ii == "states" then
                            fix = ui.get(value["defensive"]) ~= "off"
                        end
                    end
                    if index == "keybinds" then
                        if ii == "edge" then
                            fix = tbl.contains(ui.get(value["keys"]), ii)
                        end
                        if ii == "freestand" or ii == "type_freestand" or ii == "disablers" then
                            fix = tbl.contains(ui.get(value["keys"]), "freestand")
                        end
                        if ii == "left" or ii == "right" or ii == "forward" or ii == "backward" or ii == "type_manual" then
                            fix = tbl.contains(ui.get(value["keys"]), "manual")
                        end
                    end
                    ui.set_visible(vv, i == current and index == sub and fix)
                    
                end
            elseif i == "visuals & misc" and index ~= "submenu" then
                for ii, vv in next, value do
                    fix = true
                    if index == "misc" then
                        if ii == "spammer" then
                            fix = tbl.contains(ui.get(value["features"]), "legs spammer")
                        end
                    elseif index == "visuals" then
                        if ii == "arrows_color" then
                            fix = ui.get(value["arrows"]) ~= "-"
                        elseif ii == "indicators_color" then
                            fix = ui.get(value["indicators"]) ~= "-"
                        elseif ii == "custom_indicator_text" then
                            fix = ui.get(value["indicators"]) == "custom"
                        elseif ii == "custom_wtext" or ii == "notify_tip15" or ii == "notify_tip16" or ii == "notify_tip22" or ii == "custom_prefix" or ii == "custom_prefix_color" or ii == "custom_prefix2" or ii == "custom_prefix2_color" or ii == "prefix_animation" or ii == "prefix2_animation" then
                            fix = ui.get(value["wtext"]) == "custom"
                        elseif ii == "watermark_animation" or ii == "wfont" or ii == "watermark" or ii == "watermark_spaces" or ii == "uppercase" or ii == "watermark_color" then
                            fix = ui.get(value["wtext"]) ~= "off"
                        elseif ii == "watermark_x_offset" or ii == "watermark_y_offset" then
                            fix = ui.get(value["watermark"]) ~= "off" and ui.get(value["watermark"]) == "custom"
                        elseif ii == "notify_tip11" or ii == "hitmark_color" then
                            fix = ui.get(value["hitmark_enable"]) == "yes"
                        elseif ii == "notheight" or ii == "notmarkheight" or ii == "notmarkoffset" or ii == "notmark_centered" or ii == "notmarkxoffset" or ii == "notmarkseparatorheight" or ii == "notglow" or ii == "notify_tip103" or ii == "notmark" or ii == "notmark2" or ii == "notify_tip2" or ii == "notify_tip19" or ii == "notify_tip18" or ii == "notmark_miss_prefix_color" or ii == "notmark_hit_prefix_color" or ii == "notcolor" or ii == "notify_tip3" or ii == "notglow_miss_color" or ii == "notglow_hit_color" or ii == "notify_tip104" or ii == "notify_tip105" or ii == "notcolor2" or ii == "notbackground_color" or ii == "notify_tip4" or ii == "notcolor3" or ii == "notmarkfont" or ii == "notmarkuppercase" or ii == "notmarkseparator" or ii == "notrounding" then
                            fix = #ui.get(value["notify"]) > 0
                        elseif ii == "custom_notmark_hit" then
                            fix = #ui.get(value["notify"]) > 0 and ui.get(value["notmark"]) == "custom"
                        elseif ii == "custom_notmark_miss" then
                            fix = #ui.get(value["notify"]) > 0 and ui.get(value["notmark2"]) == "custom"
                        elseif ii == "notify_tip12" then
                            fix = #ui.get(value["notify"]) > 0 and ui.get(value["notmark"]) == "custom"
                        elseif ii == "notify_tip13" then
                            fix = #ui.get(value["notify"]) > 0 and ui.get(value["notmark2"]) == "custom"
                        elseif ii == "notmark_hit_separator_color" or ii == "notify_tip101" then
                            fix = #ui.get(value["notify"]) > 0 and ui.get(value["notmarkseparator"]) == "yes"
                        elseif ii == "notmark_miss_separator_color" or ii == "notify_tip102" then
                            fix = #ui.get(value["notify"]) > 0 and ui.get(value["notmarkseparator"]) == "yes"
                        elseif ii == "slowdown_color" then
                            fix = ui.get(value["slowdown_indicator"]) == true
                        elseif ii == "debug_ls" then
                            fix = ui.get(value["debug_panel"]) == true
                        elseif ii == "debug_custom" then
                            fix = ui.get(value["debug_customp"]) == true
                        elseif ii == "debug_customp" then
                            fix = ui.get(value["debug_panel"]) == true
                        elseif ii == "debugtip" then
                            fix = ui.get(value["debug_customp"]) == true
                        end
                    end
                    ui.set_visible(vv, i == current and index == subextra and fix)
                end
            else
                ui.set_visible(value, i == current)
            end
                if i == "config" and index ~= "category" and index ~= "category_label" and index ~= "separator" then
                    local config_cat = ui.get(menu["config"]["category"])
                    
                    if index == "local_label" or index == "local_list" or index == "local_name" or 
                    index == "local_save" or index == "local_load" or index == "local_delete" or 
                    index == "local_export" or index == "local_import" or index == "local_upload" then
                        ui.set_visible(value, i == current and config_cat == "local")
                    
                    elseif index == "cloud_label" or index == "cloud_list" or 
                        index == "cloud_refresh" or index == "cloud_load" or 
                        index == "cloud_like" or index == "cloud_delete" then
                        ui.set_visible(value, i == current and config_cat == "cloud")
                    
                    elseif index == "category_label" or index == "category" or index == "separator" then
                        ui.set_visible(value, i == current)
                    
                    else
                        ui.set_visible(value, false)
                    end
                end
            end
        end
    end,
                ["animations"] = function()
                    local myself = entity.get_local_player()
                    if tbl.contains(ui.get(menu["visuals & misc"]["misc"]["features"]), "animations") and myself ~= nil then
                        entity.set_prop(myself, "m_flPoseParameter", 1, bit.band(entity.get_prop(myself, "m_fFlags"), 1) == 0 and 6 or 0)
                    end
                end,
                ["spin_aa"] = function()
                    if tbl.contains(ui.get(menu["visuals & misc"]["misc"]["features"]), "spin on round end/warmup") then
                        local function is_round_warmup()
                            local gr = entity.get_game_rules()
                            if not gr then return false end
                            local ok, warmed = pcall(entity.get_prop, gr, "m_bWarmupPeriod")
                            return ok and warmed == 1
                        end

                        local function are_enemies_dead()
                            local me = entity.get_local_player()
                            if not me then return false end
                            local my_team = entity.get_prop(me, 'm_iTeamNum')
                            local pr = entity.get_player_resource()
                            if not pr then return false end
                            for i = 1, globals.maxplayers() do
                                local connected = entity.get_prop(pr, 'm_bConnected', i)
                                if connected ~= 1 then goto continue end
                                local player_team = entity.get_prop(pr, 'm_iTeam', i)
                                if player_team == my_team then goto continue end
                                local alive = entity.get_prop(pr, 'm_bAlive', i)
                                if alive == 1 then return false end
                                ::continue::
                            end
                            return true
                        end
                        local warmup = is_round_warmup()
                        local no_enemies = are_enemies_dead()
                        if warmup or no_enemies then
                                            ui.set(tbl.items.pitch[1], "off")
                                            ui.set(tbl.items.yaw[1], "Spin")
                                            ui.set(tbl.items.yaw[2], 50)
                                            ui.set(tbl.items.jitter[1], "off")
                                            ui.set(tbl.items.jitter[2], 0)
                                            ui.set(tbl.items.body[1], "static")
                                            ui.set(tbl.items.body[2], 0)
                                            return nil
                                end
                            end
                        end,     
                        
                ["arrows"] = function()
                    local myself = entity.get_local_player()
                    if myself ~= nil and entity.is_alive(myself) then
                        local width, height = client.screen_size()
                        local r2, g2, b2, a2 = 55, 55, 55, 255
                        local highlight_fraction = (globals.realtime() / 2 % 1.2 * 2) - 1.2
                        local text_to_draw = ui.get(menu["visuals & misc"]["visuals"]["wtext"])
                        if text_to_draw == "off" then
                            return
                        end
                        local output = ""
                        local font_map = { normal = "c", small = "-", bold = "b" }
                        local font_flag = font_map[ui.get(menu["visuals & misc"]["visuals"]["wfont"])] or "c"
                        local use_uppercase = ui.get(menu["visuals & misc"]["visuals"]["uppercase"]) == "yes"
                        local enable_animation = ui.get(menu["visuals & misc"]["visuals"]["watermark_animation"])
                        local highlight_fraction = enable_animation and (globals.realtime() / 2 % 1.2 * 2) - 1.2 or 0
                        local r2, g2, b2, a2 = 55, 55, 55, 255
                        if text_to_draw == "luasync.max" then
                            local lua_text = "luasync"
                            local max_text = ".max"
                            local r1, g1, b1, a1 = 255, 255, 255, 255
                            if ui.get(menu["visuals & misc"]["visuals"]["watermark_spaces"]) == "yes" then
                                lua_text = lua_text:gsub(" ", "")
                                max_text = max_text:gsub(" ", "")
                                text_to_draw = lua_text .. max_text
                            else
                                text_to_draw = lua_text .. max_text
                            end
                            if use_uppercase then
                                lua_text = lua_text:upper()
                                max_text = max_text:upper()
                                text_to_draw = text_to_draw:upper()
                            end
                            output = output .. ('\a%02x%02x%02x%02x%s'):format(r1, g1, b1, a1, lua_text)
                            for idx = 1, #max_text do
                                local character = max_text:sub(idx, idx)
                                local character_fraction = idx / #max_text
                                local r_s, g_s, b_s = ui.get(menu["visuals & misc"]["visuals"]["watermark_color"])
                                local highlight_delta = enable_animation and (character_fraction - highlight_fraction) or 0
                                if highlight_delta >= 0 and highlight_delta <= 1.4 then
                                    if highlight_delta > 0.7 then
                                        highlight_delta = 1.4 - highlight_delta
                                    end
                                    local r_fraction, g_fraction, b_fraction = r2 - r_s, g2 - g_s, b2 - b_s
                                    r_s = r_s + r_fraction * highlight_delta / 0.8
                                    g_s = g_s + g_fraction * highlight_delta / 0.8
                                    b_s = b_s + b_fraction * highlight_delta / 0.8
                                end
                                output = output .. ('\a%02x%02x%02x%02x%s'):format(r_s, g_s, b_s, a1, character)
                            end
                        elseif text_to_draw == "luasync.max2" then
                            local lua_text = "luasync"
                            local max_text = ".max"
                            local r1, g1, b1, a1 = 255, 255, 255, 255
                            if ui.get(menu["visuals & misc"]["visuals"]["watermark_spaces"]) == "yes" then
                                lua_text = lua_text:gsub(" ", "")
                                max_text = max_text:gsub(" ", "")
                                text_to_draw = lua_text .. max_text
                            else
                                text_to_draw = lua_text .. max_text
                            end
                            if use_uppercase then
                                lua_text = lua_text:upper()
                                max_text = max_text:upper()
                                text_to_draw = text_to_draw:upper()
                            end
                            for idx = 1, #lua_text do
                                local character = lua_text:sub(idx, idx)
                                local character_fraction = idx / #lua_text
                                local r_s, g_s, b_s = ui.get(menu["visuals & misc"]["visuals"]["watermark_color"])
                                local highlight_delta = enable_animation and (character_fraction - highlight_fraction) or 0
                                if highlight_delta >= 0 and highlight_delta <= 1.4 then
                                    if highlight_delta > 0.7 then
                                        highlight_delta = 1.4 - highlight_delta
                                    end
                                    local r_fraction, g_fraction, b_fraction = r2 - r_s, g2 - g_s, b2 - b_s
                                    r_s = r_s + r_fraction * highlight_delta / 0.8
                                    g_s = g_s + g_fraction * highlight_delta / 0.8
                                    b_s = b_s + b_fraction * highlight_delta / 0.8
                                end
                                output = output .. ('\a%02x%02x%02x%02x%s'):format(r_s, g_s, b_s, a1, character)
                            end
                            output = output .. ('\a%02x%02x%02x%02x%s'):format(r1, g1, b1, a1, max_text)

                        elseif text_to_draw == "luasense beta" then
                            local lua_text = "l u a"
                            local sense_text = "s e n s e"
                            local beta_text = "[beta]"
                            local r1, g1, b1, a1 = ui.get(menu["visuals & misc"]["visuals"]["watermark_color"])
                            a1 = 255
                            if ui.get(menu["visuals & misc"]["visuals"]["watermark_spaces"]) == "yes" then
                                lua_text = lua_text:gsub(" ", "")
                                sense_text = sense_text:gsub(" ", "")
                                text_to_draw = lua_text .. sense_text .. " " .. beta_text
                            else
                                text_to_draw = lua_text .. " " .. sense_text .. " " .. beta_text
                            end
                            if use_uppercase then
                                lua_text = lua_text:upper()
                                sense_text = sense_text:upper()
                                beta_text = beta_text:upper()
                                text_to_draw = text_to_draw:upper()
                            end
                            output = output .. ('\a%02x%02x%02x%02x%s'):format(r1, g1, b1, a1, lua_text)
                            if ui.get(menu["visuals & misc"]["visuals"]["watermark_spaces"]) == "yes" then
                                output = output
                            else
                                output = output .. " "
                            end
                            for idx = 1, #sense_text do
                                local character = sense_text:sub(idx, idx)
                                local character_fraction = idx / #sense_text
                                local r_s, g_s, b_s = 255, 255, 255
                                local highlight_delta = enable_animation and (character_fraction - highlight_fraction) or 0
                                if highlight_delta >= 0 and highlight_delta <= 1.4 then
                                    if highlight_delta > 0.7 then
                                        highlight_delta = 1.4 - highlight_delta
                                    end
                                    local r_fraction, g_fraction, b_fraction = r2 - r_s, g2 - g_s, b2 - b_s
                                    r_s = r_s + r_fraction * highlight_delta / 0.8
                                    g_s = g_s + g_fraction * highlight_delta / 0.8
                                    b_s = b_s + b_fraction * highlight_delta / 0.8
                                end
                                output = output .. ('\a%02x%02x%02x%02x%s'):format(r_s, g_s, b_s, a1, character)
                            end
                            output = output .. " "
                            output = output .. ('\a%02x%02x%02x%02x%s'):format(185, 64, 63, 255, beta_text)
                        elseif text_to_draw == "luasense" then
                            local lua_text = "l u a"
                            local sense_text = "s e n s e"
                            local r1, g1, b1, a1 = ui.get(menu["visuals & misc"]["visuals"]["watermark_color"])
                            a1 = 255
                            local r2, g2, b2 = r2, g2, b2
                            if ui.get(menu["visuals & misc"]["visuals"]["watermark_spaces"]) == "yes" then
                                lua_text = lua_text:gsub(" ", "")
                                sense_text = sense_text:gsub(" ", "")
                                text_to_draw = lua_text .. sense_text
                            else
                                text_to_draw = lua_text .. " " .. sense_text
                            end
                            if use_uppercase then
                                lua_text = lua_text:upper()
                                sense_text = sense_text:upper()
                                text_to_draw = text_to_draw:upper()
                            end
                            for idx = 1, #lua_text do
                                local character = lua_text:sub(idx, idx)
                                local r_s, g_s, b_s = r1, g1, b1
                                output = output .. ('\a%02x%02x%02x%02x%s'):format(r_s, g_s, b_s, a1, character)
                            end
                            if ui.get(menu["visuals & misc"]["visuals"]["watermark_spaces"]) == "yes" then
                                output = output
                            else
                                output = output .. " "
                            end
                            for idx = 1, #sense_text do
                                local character = sense_text:sub(idx, idx)
                                local r_s, g_s, b_s = 255, 255, 255
                                if idx % 2 == 1 or ui.get(menu["visuals & misc"]["visuals"]["watermark_spaces"]) == "yes" then
                                    local character_fraction = idx / #sense_text
                                    local highlight_delta = enable_animation and (character_fraction - highlight_fraction) or 0
                                    if highlight_delta >= 0 and highlight_delta <= 1.4 then
                                        if highlight_delta > 0.7 then
                                            highlight_delta = 1.4 - highlight_delta
                                        end
                                        local r_fraction, g_fraction, b_fraction = r2 - r_s, g2 - g_s, b2 - b_s
                                        r_s = r_s + r_fraction * highlight_delta / 0.8
                                        g_s = g_s + g_fraction * highlight_delta / 0.8
                                        b_s = b_s + b_fraction * highlight_delta / 0.8
                                    end
                                end
                                output = output .. ('\a%02x%02x%02x%02x%s'):format(r_s, g_s, b_s, a1, character)
                            end
                            if ui.get(menu["visuals & misc"]["visuals"]["watermark_spaces"]) == "yes" then
                                output = output
                            else
                                output = output .. " "
                            end
                            for idx = 1, #sense_text do
                                local character = sense_text:sub(idx, idx)
                                local r_s, g_s, b_s = 255, 255, 255
                                if idx % 2 == 1 or ui.get(menu["visuals & misc"]["visuals"]["watermark_spaces"]) == "yes" then
                                    local character_fraction = idx / #sense_text
                                    local highlight_delta = enable_animation and (character_fraction - highlight_fraction) or 0
                                    if highlight_delta >= 0 and highlight_delta <= 1.4 then
                                        if highlight_delta > 0.7 then
                                            highlight_delta = 1.4 - highlight_delta
                                        end
                                        local r_fraction, g_fraction, b_fraction = r2 - r_s, g2 - g_s, b2 - b_s
                                        r_s = r_s + r_fraction * highlight_delta / 0.8
                                        g_s = g_s + g_fraction * highlight_delta / 0.8
                                        b_s = b_s + b_fraction * highlight_delta / 0.8
                                    end
                                end
                                output = output .. ('\a%02x%02x%02x%02x%s'):format(r_s, g_s, b_s, a1, character)
                            end
                        elseif text_to_draw == "luasense " then
                            local star = ""
                            local lua_text = "l u a s e n s e"
                            local r1, g1, b1, a1 = 255, 255, 255, 255
                            if ui.get(menu["visuals & misc"]["visuals"]["watermark_spaces"]) == "yes" then
                                lua_text = lua_text:gsub(" ", "")
                                text_to_draw = lua_text .. " " .. star
                            else
                                text_to_draw = lua_text .. " " .. star
                            end
                            if use_uppercase then
                                lua_text = lua_text:upper()
                                text_to_draw = text_to_draw:upper()
                            end
                            output = output .. ('\a%02x%02x%02x%02x%s'):format(r1, g1, b1, a1, lua_text)
                            output = output .. " " 
                            local r_s, g_s, b_s = ui.get(menu["visuals & misc"]["visuals"]["watermark_color"])
                            local highlight_delta = enable_animation and (1 - highlight_fraction) or 0
                            if highlight_delta >= 0 and highlight_delta <= 1.4 then
                                if highlight_delta > 0.7 then
                                    highlight_delta = 1.4 - highlight_delta
                                end
                                local r_fraction, g_fraction, b_fraction = r2 - r_s, g2 - g_s, b2 - b_s
                                r_s = r_s + r_fraction * highlight_delta / 0.8
                                g_s = g_s + g_fraction * highlight_delta / 0.8
                                b_s = b_s + b_fraction * highlight_delta / 0.8
                            end
                            output = output .. ('\a%02x%02x%02x%02x%s'):format(r_s, g_s, b_s, a1, star)
                        elseif text_to_draw == " luasense" then
                            local star = ""
                            local lua_text = "l u a s e n s e"
                            local r1, g1, b1, a1 = 255, 255, 255, 255
                            if ui.get(menu["visuals & misc"]["visuals"]["watermark_spaces"]) == "yes" then
                                lua_text = lua_text:gsub(" ", "")
                                text_to_draw = star .. " " .. lua_text
                            else
                                text_to_draw = star .. " " .. lua_text
                            end
                            if use_uppercase then
                                lua_text = lua_text:upper()
                                text_to_draw = text_to_draw:upper()
                            end
                            local r_s, g_s, b_s = ui.get(menu["visuals & misc"]["visuals"]["watermark_color"])
                            local highlight_delta = enable_animation and (0 - highlight_fraction) or 0
                            if highlight_delta >= 0 and highlight_delta <= 1.4 then
                                if highlight_delta > 0.7 then
                                    highlight_delta = 1.4 - highlight_delta
                                end
                                local r_fraction, g_fraction, b_fraction = r2 - r_s, g2 - g_s, b2 - b_s
                                r_s = r_s + r_fraction * highlight_delta / 0.8
                                g_s = g_s + g_fraction * highlight_delta / 0.8
                                b_s = b_s + b_fraction * highlight_delta / 0.8
                            end
                            output = output .. ('\a%02x%02x%02x%02x%s'):format(r_s, g_s, b_s, a1, star)
                            output = output .. " "
                            output = output .. ('\a%02x%02x%02x%02x%s'):format(r1, g1, b1, a1, lua_text)
                        elseif text_to_draw == "luasense " then
                            local star = ""
                            local lua_text = "l u a s e n s e"
                            local r1, g1, b1, a1 = 255, 255, 255, 255
                            if ui.get(menu["visuals & misc"]["visuals"]["watermark_spaces"]) == "yes" then
                                lua_text = lua_text:gsub(" ", "")
                                text_to_draw = lua_text .. " " .. star
                            else
                                text_to_draw = lua_text .. " " .. star
                            end
                            if use_uppercase then
                                lua_text = lua_text:upper()
                                text_to_draw = text_to_draw:upper()
                            end
                            output = output .. ('\a%02x%02x%02x%02x%s'):format(r1, g1, b1, a1, lua_text)
                            output = output .. " "
                            local r_s, g_s, b_s = ui.get(menu["visuals & misc"]["visuals"]["watermark_color"])
                            local highlight_delta = enable_animation and (1 - highlight_fraction) or 0
                            if highlight_delta >= 0 and highlight_delta <= 1.4 then
                                if highlight_delta > 0.7 then
                                    highlight_delta = 1.4 - highlight_delta
                                end
                                local r_fraction, g_fraction, b_fraction = r2 - r_s, g2 - g_s, b2 - b_s
                                r_s = r_s + r_fraction * highlight_delta / 0.8
                                g_s = g_s + g_fraction * highlight_delta / 0.8
                                b_s = b_s + b_fraction * highlight_delta / 0.8
                            end
                            output = output .. ('\a%02x%02x%02x%02x%s'):format(r_s, g_s, b_s, a1, star)
                        elseif text_to_draw == " luasense " then
                            local star = ""
                            local lua_text = "l u a s e n s e"
                            local r1, g1, b1, a1 = 255, 255, 255, 255
                            if ui.get(menu["visuals & misc"]["visuals"]["watermark_spaces"]) == "yes" then
                                lua_text = lua_text:gsub(" ", "")
                                text_to_draw = star .. " " .. lua_text .. " " .. star
                            else
                                text_to_draw = star .. " " .. lua_text .. " " .. star
                            end
                            if use_uppercase then
                                lua_text = lua_text:upper()
                                text_to_draw = text_to_draw:upper()
                            end
                            local r_s, g_s, b_s = ui.get(menu["visuals & misc"]["visuals"]["watermark_color"])
                            local highlight_delta = enable_animation and (0 - highlight_fraction) or 0
                            if highlight_delta >= 0 and highlight_delta <= 1.4 then
                                if highlight_delta > 0.7 then
                                    highlight_delta = 1.4 - highlight_delta
                                end
                                local r_fraction, g_fraction, b_fraction = r2 - r_s, g2 - g_s, b2 - b_s
                                r_s = r_s + r_fraction * highlight_delta / 0.8
                                g_s = g_s + g_fraction * highlight_delta / 0.8
                                b_s = b_s + b_fraction * highlight_delta / 0.8
                            end
                            output = output .. ('\a%02x%02x%02x%02x%s'):format(r_s, g_s, b_s, a1, star)
                            output = output .. " "
                            output = output .. ('\a%02x%02x%02x%02x%s'):format(r1, g1, b1, a1, lua_text)
                            output = output .. " "
                            r_s, g_s, b_s = ui.get(menu["visuals & misc"]["visuals"]["watermark_color"])
                            highlight_delta = enable_animation and (1 - highlight_fraction) or 0
                            if highlight_delta >= 0 and highlight_delta <= 1.4 then
                                if highlight_delta > 0.7 then
                                    highlight_delta = 1.4 - highlight_delta
                                end
                                local r_fraction, g_fraction, b_fraction = r2 - r_s, g2 - g_s, b2 - b_s
                                r_s = r_s + r_fraction * highlight_delta / 0.8
                                g_s = g_s + g_fraction * highlight_delta / 0.8
                                b_s = b_s + b_fraction * highlight_delta / 0.8
                            end
                            output = output .. ('\a%02x%02x%02x%02x%s'):format(r_s, g_s, b_s, a1, star)
                        elseif text_to_draw == "custom" then
                            text_to_draw = ui.get(menu["visuals & misc"]["visuals"]["custom_wtext"]) or "custom"
                            local prefix_text = ui.get(menu["visuals & misc"]["visuals"]["custom_prefix"]) or ""
                            local prefix2_text = ui.get(menu["visuals & misc"]["visuals"]["custom_prefix2"]) or ""
                            if use_uppercase then
                                text_to_draw = text_to_draw:upper()
                                prefix_text = prefix_text:upper()
                                prefix2_text = prefix2_text:upper()
                            end
                            for idx = 1, #text_to_draw do
                                local character = text_to_draw:sub(idx, idx)
                                local character_fraction = idx / #text_to_draw
                                local r1, g1, b1, a1 = ui.get(menu["visuals & misc"]["visuals"]["watermark_color"])
                                a1 = 255
                                local highlight_delta = enable_animation and (character_fraction - highlight_fraction) or 0
                                if highlight_delta >= 0 and highlight_delta <= 1.4 then
                                    if highlight_delta > 0.7 then
                                        highlight_delta = 1.4 - highlight_delta
                                    end
                                    local r_fraction, g_fraction, b_fraction = r2 - r1, g2 - g1, b2 - b1
                                    r1 = r1 + r_fraction * highlight_delta / 0.8
                                    g1 = g1 + g_fraction * highlight_delta / 0.8
                                    b1 = b1 + b_fraction * highlight_delta / 0.8
                                end
                                output = output .. ('\a%02x%02x%02x%02x%s'):format(r1, g1, b1, a1, character)
                            end
                            if prefix_text ~= "" then
                                local r_p, g_p, b_p, a_p = ui.get(menu["visuals & misc"]["visuals"]["custom_prefix_color"])
                                a_p = 255
                                local prefix_highlight_fraction = ui.get(menu["visuals & misc"]["visuals"]["prefix_animation"]) and ((globals.realtime() / 2 % 1.2 * 2) - 1.2) or 0
                                for idx = 1, #prefix_text do
                                    local character = prefix_text:sub(idx, idx)
                                    local character_fraction = idx / #prefix_text
                                    local r_s, g_s, b_s = r_p, g_p, b_p
                                    local highlight_delta = ui.get(menu["visuals & misc"]["visuals"]["prefix_animation"]) and (character_fraction - prefix_highlight_fraction) or 0
                                    if highlight_delta >= 0 and highlight_delta <= 1.4 then
                                        if highlight_delta > 0.7 then
                                            highlight_delta = 1.4 - highlight_delta
                                        end
                                        local r_fraction, g_fraction, b_fraction = r2 - r_s, g2 - g_s, b2 - b_s
                                        r_s = r_s + r_fraction * highlight_delta / 0.8
                                        g_s = g_s + g_fraction * highlight_delta / 0.8
                                        b_s = b_s + b_fraction * highlight_delta / 0.8
                                    end
                                    output = output .. ('\a%02x%02x%02x%02x%s'):format(r_s, g_s, b_s, a_p, character)
                                end
                            end
                            if prefix2_text ~= "" then
                                local r_p2, g_p2, b_p2, a_p2 = ui.get(menu["visuals & misc"]["visuals"]["custom_prefix2_color"])
                                a_p2 = 255
                                local prefix2_highlight_fraction = ui.get(menu["visuals & misc"]["visuals"]["prefix2_animation"]) and ((globals.realtime() / 2 % 1.2 * 2) - 1.2) or 0
                                for idx = 1, #prefix2_text do
                                    local character = prefix2_text:sub(idx, idx)
                                    local character_fraction = idx / #prefix2_text
                                    local r_s, g_s, b_s = r_p2, g_p2, b_p2
                                    local highlight_delta = ui.get(menu["visuals & misc"]["visuals"]["prefix2_animation"]) and (character_fraction - prefix2_highlight_fraction) or 0
                                    if highlight_delta >= 0 and highlight_delta <= 1.4 then
                                        if highlight_delta > 0.7 then
                                            highlight_delta = 1.4 - highlight_delta
                                        end
                                        local r_fraction, g_fraction, b_fraction = r2 - r_s, g2 - g_s, b2 - b_s
                                        r_s = r_s + r_fraction * highlight_delta / 0.8
                                        g_s = g_s + g_fraction * highlight_delta / 0.8
                                        b_s = b_s + b_fraction * highlight_delta / 0.8
                                    end
                                    output = output .. ('\a%02x%02x%02x%02x%s'):format(r_s, g_s, b_s, a_p2, character)
                                end
                            end
                        else
                            if ui.get(menu["visuals & misc"]["visuals"]["watermark_spaces"]) == "yes" then
                                text_to_draw = text_to_draw:gsub(" ", "")
                            end
                            if use_uppercase then
                                text_to_draw = text_to_draw:upper()
                            end
                            for idx = 1, #text_to_draw do
                                local character = text_to_draw:sub(idx, idx)
                                local character_fraction = idx / #text_to_draw
                                local r1, g1, b1, a1 = ui.get(menu["visuals & misc"]["visuals"]["watermark_color"])
                                a1 = 255
                                local highlight_delta = enable_animation and (character_fraction - highlight_fraction) or 0
                                if highlight_delta >= 0 and highlight_delta <= 1.4 then
                                    if highlight_delta > 0.7 then
                                        highlight_delta = 1.4 - highlight_delta
                                    end
                                    local r_fraction, g_fraction, b_fraction = r2 - r1, g2 - g1, b2 - b1
                                    r1 = r1 + r_fraction * highlight_delta / 0.8
                                    g1 = g1 + g_fraction * highlight_delta / 0.8
                                    b1 = b1 + b_fraction * highlight_delta / 0.8
                                end
                                output = output .. ('\a%02x%02x%02x%02x%s'):format(r1, g1, b1, a1, character)
                            end
                        end
                        if getbuild() == "beta" then
                            output = output .. ("\a%x%x%x%x"):format(255, 255, 255, 255) .. ""
                        end
                        local r, g, b = ui.get(menu["visuals & misc"]["visuals"]["watermark_color"])
                        local x_offset = ui.get(menu["visuals & misc"]["visuals"]["watermark"]) == "custom" and ui.get(menu["visuals & misc"]["visuals"]["watermark_x_offset"]) or 0
                        local y_offset = ui.get(menu["visuals & misc"]["visuals"]["watermark"]) == "custom" and ui.get(menu["visuals & misc"]["visuals"]["watermark_y_offset"]) or 0
                        local font = ui.get(menu["visuals & misc"]["visuals"]["wfont"])
                        local positions = {
                            bottom = {
                                normal = { x = width/2 + x_offset, y = height - 8 + y_offset },
                                bold = { x = width/ 2.0760 + x_offset, y = height - 14 + y_offset },
                                small = { x = width/2.07 + x_offset, y = height - 12 + y_offset }
                            },
                            right = {
                                normal = { x = width - 60 + x_offset, y = height/1.977 + y_offset },
                                bold = { x = width - 117 + x_offset, y = height/2 + y_offset },
                                small = { x = width - 80 + x_offset, y = height/2 + y_offset }
                            },
                            left = {
                                normal = { x = 69 + x_offset, y = height/2 + y_offset },
                                bold = { x = 16 + x_offset, y = height/2.02 + y_offset },
                                small = { x = 17 + x_offset, y = height/2.0093 + y_offset }
                            },
                            custom = {
                                normal = { x = width/2 + x_offset, y = height/2 + y_offset },
                                bold = { x = width/2 + x_offset, y = height/2 + y_offset },
                                small = { x = width/2 + x_offset, y = height/2 + y_offset }
                            }
                        }
                        local watermark_pos = ui.get(menu["visuals & misc"]["visuals"]["watermark"])
                        local pos = positions[watermark_pos][font] or positions[watermark_pos].normal
                        renderer.text(pos.x, pos.y, r, g, b, 255, font_flag, 0, output)


                        local local_player = entity.get_local_player()
                        if local_player and entity.is_alive(local_player) then
                            local velocity_modifier = entity.get_prop(local_player, "m_flVelocityModifier")
                            if velocity_modifier and velocity_modifier < 1 and ui.get(menu["visuals & misc"]["visuals"]["slowdown_indicator"]) then
                                local screen_w, screen_h = client.screen_size()
                                local bar_x = screen_w / 2 - 90
                                local bar_y = screen_h - 850
                                local bar_width = 174
                                local bar_height = 8
                                local fill_height = 5.6
                                local fill_y = bar_y + (bar_height - fill_height) / 2
                                local fill_width = bar_width * velocity_modifier
                                local r, g, b, _ = ui.get(menu["visuals & misc"]["visuals"]["slowdown_color"])
                                local a = 255
                                local bg_r, bg_g, bg_b, bg_a = 25, 25, 25, 255
                                local rounding = 3
                                local glow_strength = 10


                                local fade_threshold = 0.9
                                local fade_alpha = 1.0
                                if velocity_modifier > fade_threshold then
                                    fade_alpha = (1.0 - velocity_modifier) / (1.0 - fade_threshold)
                                    fade_alpha = math.max(0, math.min(1, fade_alpha))
                                end
                                local final_a = math.floor(a * fade_alpha)
                                local final_bg_a = math.floor(bg_a * fade_alpha)
                        

                                k.rec(bar_x, bar_y, bar_width, bar_height, bg_r, bg_g, bg_b, final_bg_a, rounding)
                        

                                for i = 0, glow_strength do
                                    local alpha = final_bg_a / 2 * (i / glow_strength) ^ 3
                                    k.rec_outline(
                                        bar_x + (i - glow_strength) * 1,
                                        bar_y + (i - glow_strength) * 1,
                                        bar_width - (i - glow_strength) * 2,
                                        bar_height - (i - glow_strength) * 2,
                                        r, g, b,
                                        alpha / 1.5,
                                        rounding,
                                        1
                                    )
                                end
                        
                                if fill_width > 0 then
                                    k.rec(bar_x, fill_y, fill_width, fill_height, r, g, b, final_a, rounding)
                        
                                    for i = 0, glow_strength do
                                        local alpha = final_a / 2 * (i / glow_strength) ^ 3
                                        k.rec_outline(
                                            bar_x + (i - glow_strength) * 1,
                                            fill_y + (i - glow_strength) * 1,
                                            fill_width - (i - glow_strength) * 2,
                                            fill_height - (i - glow_strength) * 2,
                                            r, g, b,
                                            alpha / 1.5,
                                            rounding,
                                            1
                                        )
                                    end
                                end
                        
                                renderer.text(bar_x + bar_width / 2, bar_y - 10, 255, 255, 255, final_a, "c", 0, string.format("Max velocity reduced by %.0f%%", (1 - velocity_modifier) * 100))
                            end
                        end
                                    
                        
                        local r, g, b = ui.get(menu["visuals & misc"]["visuals"]["arrows_color"])
                        local leftkey = ui.get(menu["visuals & misc"]["visuals"]["arrows"]) == "simple" and "<" or "⯇"
                        local rightkey = ui.get(menu["visuals & misc"]["visuals"]["arrows"]) == "simple" and ">" or "⯈"
                        local w, h = client.screen_size()
                        w, h = w/2, h/2
                        local yaw_body = math.max(-60, math.min(60, math.floor((entity.get_prop(myself, "m_flPoseParameter", 11) or 0)*120-60+0.5)))
                        if yaw_body > 0 and yaw_body > 60 then yaw_body = 60 end
                        if yaw_body < 0 and yaw_body < -60 then yaw_body = -60 end
                        local alpha = 255
                        if ui.get(menu["visuals & misc"]["visuals"]["arrows"]) == "simple" then
                            renderer.text(w + 50, h, 111, 111, 111, 255, "c+", 0, rightkey)
                            if tbl.antiaim.manual.aa == 90 then
                                renderer.text(w + 50, h, r, g, b, alpha, "c+", 0, rightkey)
                            end
                            renderer.text(w - 50, h, 111, 111, 111, 255, "c+", 0, leftkey)
                            if tbl.antiaim.manual.aa == -90 then
                                renderer.text(w - 50, h, r, g, b, alpha, "c+", 0, leftkey)
                            end
                        elseif ui.get(menu["visuals & misc"]["visuals"]["arrows"]) == "body" then
                            renderer.line(w + -(40), h-8, w + -(40), h+8, r, g, b, yaw_body > 0 and 55 or 255)
                            renderer.line(w + (42), h-8, w + (42), h+8, r, g, b, yaw_body < 0 and 55 or 255)
                            h = h - 2.5
                            renderer.text(w + 50, h, 111, 111, 111, 255, "c+", 0, rightkey)
                            if tbl.antiaim.manual.aa == 90 then
                                renderer.text(w + 50, h, r, g, b, alpha, "c+", 0, rightkey)
                            end
                            renderer.text(w - 50, h, 111, 111, 111, 255, "c+", 0, leftkey)
                            if tbl.antiaim.manual.aa == -90 then
                                renderer.text(w - 50, h, r, g, b, alpha, "c+", 0, leftkey)
                            end
                        elseif ui.get(menu["visuals & misc"]["visuals"]["arrows"]) == "luasense" then
                            local xv, yv, zv = entity.get_prop(myself, "m_vecVelocity")
                            local speed = math.sqrt(xv*xv + yv*yv) / 10
                            if tbl.antiaim.fs == 1 then
                                renderer.line(w + -(36+speed), h-8, w + -(36+speed), h+8, 255, 255, 255, alpha)
                            end
                            if tbl.antiaim.fs == -1 then
                                renderer.line(w + (38+speed), h-8, w + (38+speed), h+8, 255, 255, 255, alpha)
                            end
                            renderer.line(w + -(40+speed), h-8, w + -(40+speed), h+8, r, g, b, yaw_body > 0 and 55 or 255)
                            renderer.line(w + (42+speed), h-8, w + (42+speed), h+8, r, g, b, yaw_body < 0 and 55 or 255)
                            h = h - 2.5
                            renderer.text(w + (50+speed), h, 111, 111, 111, 255, "c+", 0, rightkey)
                            if tbl.antiaim.manual.aa == 90 then
                                renderer.text(w + (50+speed), h, r, g, b, alpha, "c+", 0, rightkey)
                            end
                            renderer.text(w - (50+speed), h, 111, 111, 111, 255, "c+", 0, leftkey)
                            if tbl.antiaim.manual.aa == -90 then
                                renderer.text(w - (50+speed), h, r, g, b, alpha, "c+", 0, leftkey)
                            end
                        else end
                    end
                end,


                
                ["indicator"] = function()
                    local myself = entity.get_local_player()
                    if not entity.is_alive(myself) then return nil end
                    local w, h = client.screen_size()
                    w, h = w / 2, h / 2
                    local yaw_body = math.max(-60, math.min(60, math.floor((entity.get_prop(myself, "m_flPoseParameter", 11) or 0) * 120 - 60 + 0.5)))
                    if yaw_body > 0 and yaw_body > 60 then yaw_body = 60 end
                    if yaw_body < 0 and yaw_body < -60 then yaw_body = -60 end
                    scope_fix = entity.get_prop(myself, "m_bIsScoped") ~= 0
                    if scope_fix then 
                        if scope_int < 30 then
                            scope_int = scope_int + 2
                        end
                    else
                        if scope_int > 0 then
                            scope_int = scope_int - 2
                        end
                    end
                    local w_adjusted = w + scope_int - 0
                    local ind_height = 15
                    local r, g, b = ui.get(menu["visuals & misc"]["visuals"]["indicators_color"])
                    local r1, g1, b1, a1 = r, g, b, 255
                    local r2, g2, b2, a2 = 155, 155, 155, 255
                
                    local indicator_type = ui.get(menu["visuals & misc"]["visuals"]["indicators"])
                    
                    if indicator_type == "default" then
                        if yaw_body > 0 then
                            renderer.text(w_adjusted, h + ind_height, 255, 255, 255, 255, "cb", nil, gradient(r2, g2, b2, a2, r1, g1, b1, a1, "luasense"))
                        else
                            renderer.text(w_adjusted, h + ind_height, 255, 255, 255, 255, "cb", nil, gradient(r1, g1, b1, a1, r2, g2, b2, a2, "luasense"))
                        end
                    elseif indicator_type == "luasense" then
                        local text_to_draw = "L U A S E N S E"
                        local text_width = renderer.measure_text("-", text_to_draw)
                        local x_pos = w + scope_int - text_width / 2
                        local y_pos = 551
                        local output = ""
                        local highlight_fraction = (globals.realtime() / 2 % 1.2 * 2) - 1.2
                        for idx = 1, #text_to_draw do
                            local character = text_to_draw:sub(idx, idx)
                            local character_fraction = idx / #text_to_draw
                            local r_s, g_s, b_s = r1, g1, b1
                            local highlight_delta = (character_fraction - highlight_fraction)
                            if highlight_delta >= 0 and highlight_delta <= 1.4 then
                                if highlight_delta > 0.7 then
                                    highlight_delta = 1.4 - highlight_delta
                                end
                                local r_fraction, g_fraction, b_fraction = r2 - r_s, g2 - g_s, b2 - b_s
                                r_s = r_s + r_fraction * highlight_delta / 0.8
                                g_s = g_s + g_fraction * highlight_delta / 0.8
                                b_s = b_s + b_fraction * highlight_delta / 0.8
                            end
                            output = output .. ('\a%02x%02x%02x%02x%s'):format(r_s, g_s, b_s, a1, character)
                        end
                        renderer.text(x_pos, y_pos, 255, 255, 255, 255, "-", nil, output)
                    elseif indicator_type == "custom" then
                        local custom_text = ui.get(menu["visuals & misc"]["visuals"]["custom_indicator_text"]) or "CUSTOM"
                        local text_width = renderer.measure_text("-", custom_text)
                        local x_pos = w + scope_int - text_width / 1.79
                        local y_pos = 551
                        local output = ""
                        local highlight_fraction = (globals.realtime() / 2 % 1.2 * 2) - 1.2
                        for idx = 1, #custom_text do
                            local character = custom_text:sub(idx, idx)
                            local character_fraction = idx / #custom_text
                            local r_s, g_s, b_s = r1, g1, b1
                            local highlight_delta = (character_fraction - highlight_fraction)
                            if highlight_delta >= 0 and highlight_delta <= 1.4 then
                                if highlight_delta > 0.7 then
                                    highlight_delta = 1.4 - highlight_delta
                                end
                                local r_fraction, g_fraction, b_fraction = r2 - r_s, g2 - g_s, b2 - b_s
                                r_s = r_s + r_fraction * highlight_delta / 0.8
                                g_s = g_s + g_fraction * highlight_delta / 0.8
                                b_s = b_s + b_fraction * highlight_delta / 0.8
                            end
                            output = output .. ('\a%02x%02x%02x%02x%s'):format(r_s, g_s, b_s, a1, character)
                        end
                        renderer.text(x_pos, y_pos, 255, 255, 255, 255, "-", nil, output)
                    end
                
                    if indicator_type ~= "-" then
                        local dt_on = (ui.get(z.items.keys.dt[1]) and ui.get(z.items.keys.dt[2]))
                        local hs_on = (ui.get(z.items.keys.hs[1]) and ui.get(z.items.keys.hs[2]))
                        if ui.get(z.items.keys.fd[1]) then
                            ind_height = ind_height + 8
                            renderer.text(w_adjusted, h + ind_height, r2, g2, b2, a2, "c-", nil, "DUCK")
                            if entity.get_prop(myself, "m_flDuckAmount") > 0.1 then
                                if animkeys.duck < 255 then
                                    animkeys.duck = animkeys.duck + 2.5
                                end
                                renderer.text(w_adjusted, h + ind_height, r1, g1, b1, animkeys.duck, "c-", nil, "DUCK")
                            else
                                animkeys.duck = 0
                            end
                        else
                            animkeys.duck = 0
                        end
                        if ui.get(z.items.keys.sp[1]) then
                            ind_height = ind_height + 8
                            if animkeys.safe < 255 then
                                animkeys.safe = animkeys.safe + 2.5
                            end
                            renderer.text(w_adjusted, h + ind_height, r1, g1, b1, animkeys.safe, "c-", nil, "SAFE")
                        else
                            animkeys.safe = 0
                        end
                        if ui.get(z.items.keys.fb[1]) then
                            ind_height = ind_height + 8
                            if animkeys.baim < 255 then
                                animkeys.baim = animkeys.baim + 2.5
                            end
                            renderer.text(w_adjusted, h + ind_height, r1, g1, b1, animkeys.baim, "c-", nil, "BAIM")
                        else
                            animkeys.baim = 0
                        end
                        if dt_on then
                            ind_height = ind_height + 8
                            renderer.text(w_adjusted, h + ind_height, r2, g2, b2, a2, "c-", nil, "DT")
                            if (shift_int > 0) or (z.defensive.defensive > 1) then
                                if animkeys.dt < 255 then
                                    animkeys.dt = animkeys.dt + 2.5
                                end
                                renderer.text(w_adjusted, h + ind_height, r1, g1, b1, animkeys.dt, "c-", nil, "DT")
                            else
                                animkeys.dt = 0
                            end
                        else
                            animkeys.dt = 0
                        end
                        if hs_on then
                            ind_height = ind_height + 8
                            renderer.text(w_adjusted, h + ind_height, r2, g2, b2, a2, "c-", nil, "HS")
                            if not (dt_on) then
                                if animkeys.hide < 255 then
                                    animkeys.hide = animkeys.hide + 2.5
                                end
                                renderer.text(w_adjusted, h + ind_height, r1, g1, b1, animkeys.hide, "c-", nil, "HS")
                            else
                                animkeys.hide = 0
                            end
                        else
                            animkeys.hide = 0
                        end
                        if ui.get(menu["anti aimbot"]["keybinds"]["freestand"]) then
                            ind_height = ind_height + 8
                            if animkeys.fs < 255 then
                                animkeys.fs = animkeys.fs + 2.5
                            end
                            renderer.text(w_adjusted, h + ind_height, r1, g1, b1, animkeys.fs, "c-", nil, "FS")
                        else
                            animkeys.fs = 0
                        end
                    end
                end,
                
            


                ["shutdown"] = function()
                    for i, v in next, tbl.items do
                        for index, value in next, v do
                            ui.set_visible(value, true)
                        end
                    end
                    ui.set(tbl.items.enabled[1], true)
                    ui.set(tbl.items.base[1], "at targets")
                    ui.set(tbl.items.pitch[1], "default")
                    ui.set(tbl.items.yaw[1], "180")
                    ui.set(tbl.items.yaw[2], 0)
                    ui.set(tbl.items.jitter[1], "off")
                    ui.set(tbl.items.jitter[2], 0)
                    ui.set(tbl.items.body[1], "opposite")
                    ui.set(tbl.items.body[2], 0)
                    ui.set(tbl.items.fsbody[1], true)
                    ui.set(tbl.items.edge[1], false)
                    ui.set(tbl.items.fs[1], false)
                    ui.set(tbl.items.fs[2], "always on")
                    ui.set(tbl.items.roll[1], 0)
                    ui.set_visible(tbl.items.jitter[2], false)
                    ui.set_visible(tbl.items.body[2], false)
                end
            }

        local u8, device, localize, surface, notify = {}, {}, {}, {}, {}

        do 
            function u8:len(s)
                return #s:gsub("[\128-\191]", "");
            end

            local string_mod; do
                local float = 0;
                local to_alpha = 1 / 255;

                local function fn(rgb, alpha)
                    return string.format("%s%02x", rgb, float * tonumber(alpha, 16));
                end

                function string_mod(s, alpha)
                    float = alpha * to_alpha;
                    return s:gsub("(\a%x%x%x%x%x%x)(%x%x)", fn);
                end
            end

            function device:on_update()
                local new_rect = vector(client.screen_size());

                if new_rect ~= self.rect then
                    self.rect = new_rect;
                end
            end

            function device:draw_text(x, y, r, g, b, a, flags, max_width, ...)
                local text = table.concat {...};
                text = string.mod(text, a);

                renderer.text(x, y, r, g, b, a, flags, max_width, text);
            end

            local native_ConvertAnsiToUnicode = vtable_bind("localize.dll", "Localize_001", 15, "int(__thiscall*)(void* thisptr, const char *ansi, wchar_t *unicode, int buffer_size)")
            local native_ConvertUnicodeToAnsi = vtable_bind("localize.dll", "Localize_001", 16, "int(__thiscall*)(void* thisptr, wchar_t *unicode, char *ansi, int buffer_size)")

            function localize:ansi_to_unicode(ansi, unicode, buffer_size)
                return native_ConvertAnsiToUnicode(ansi, unicode, buffer_size);
            end

            function localize:unicode_to_ansi(ansi, unicode, buffer_size)
                return native_ConvertUnicodeToAnsi(ansi, unicode, buffer_size);
            end

            local native_SetTextFont = vtable_bind("vguimatsurface.dll", "VGUI_Surface031", 23, "void*(__thiscall*)(void *thisptr, dword font_id)");
            local native_SetTextColor = vtable_bind("vguimatsurface.dll", "VGUI_Surface031", 25, "void*(__thiscall*)(void *thisptr, int r, int g, int b, int a)");
            local native_SetTextPos = vtable_bind("vguimatsurface.dll", "VGUI_Surface031", 26, "void*(__thiscall*)(void *thisptr, int x, int y)");
            local native_DrawPrintText = vtable_bind("vguimatsurface.dll", "VGUI_Surface031", 28, "void*(__thiscall*)(void *thisptr, const wchar_t *text, int maxlen, int draw_type)");

            local native_GetTextSize = vtable_bind("vguimatsurface.dll", "VGUI_Surface031", 79, "void(__thiscall*)(void *thisptr, size_t font, const wchar_t *text, int &wide, int &tall)");

            local native_GetFontName = vtable_bind("vguimatsurface.dll", "VGUI_Surface031", 134, "const char*(__thiscall*)(void *thisptr, size_t font)");

            local buffer = ffi.new("wchar_t[65535]");
            local wide, tall = ffi.new("int[1]"), ffi.new("int[1]");

            local to_alpha = 1 / 255;

            function surface:get_font_name(font_id)
                return ffi.string(native_GetFontName(font_id));
            end

            function surface:text(font, x, y, r, g, b, a, ...)
                local text = table.concat {...};
                localize:ansi_to_unicode(text, buffer, 65535);

                native_GetTextSize(font, buffer, wide, tall);

                native_SetTextFont(font);
                native_SetTextPos(x, y);
                native_SetTextColor(r, g, b, a);

                native_DrawPrintText(buffer, u8:len(text), 0);

                return wide[0], tall[0];
            end

            function surface:color_text(font, x, y, r, g, b, a, ...)
                local text = table.concat {...};
                local i, j = text:find "\a";

                if i ~= nil then
                    x = x + self:text(font, x, y, r, g, b, a, text:sub(1, i - 1))

                    while i ~= nil do
                        local new_r, new_g, new_b, new_a = r, g, b, a;

                        if text:sub(i, j + 7) == "\adefault" then
                            text = text:sub(1 + j + 7);
                        else
                            local hex = text:sub(i + 1, j + 8);
                            text = text:sub(1 + j + 8);

                            new_r, new_g, new_b, new_a = func.frgba(hex);
                            new_a = new_a * (a * to_alpha);
                        end

                        i, j = text:find "\a";

                        local new_text = text;

                        if i ~= nil then
                            new_text = text:sub(1, i - 1);
                        end

                        x = x + self:text(font, x, y, new_r, new_g, new_b, new_a, new_text);
                    end

                    return;
                end

                self:text(font, x, y, r, g, b, a, text);
            end

            local native_ConsoleIsVisible = vtable_bind("engine.dll", "VEngineClient014", 11, "bool(__thiscall*)(void*)");
            local native_ColorPrint = vtable_bind("vstdlib.dll", "VEngineCvar007", 25, "void(__cdecl*)(void*, const color_t&, const char*, ...)");

            local queue = {};
            local current;

            local times = 6;
            local duration = 8;

            local buffer = ffi.new("color_t");
            local to_alpha = 1 / 255;

            local function color_print(r, g, b, a, ...)
                buffer.r, buffer.g, buffer.b, buffer.a = r, g, b, a;
                native_ColorPrint(buffer, ...);
            end

            function notify:color_log(r, g, b, a, ...)
                local text = table.concat {...};
                local i, j = text:find "\a";

                if i ~= nil then
                    color_print(r, g, b, a, text:sub(1, i - 1));

                    while i ~= nil do
                        local new_r, new_g, new_b, new_a = r, g, b, a;

                        if text:sub(i, j + 7) == "\adefault" then
                            text = text:sub(1 + j + 7);
                        else
                            local hex = text:sub(i + 1, j + 8);
                            text = text:sub(1 + j + 8);

                            new_r, new_g, new_b, new_a = rgba(hex);
                            new_a = new_a * a * to_alpha;
                        end

                        i, j = text:find "\a";

                        local new_text = text;

                        if i ~= nil then
                            new_text = text:sub(1, i - 1);
                        end

                        color_print(new_r, new_g, new_b, new_a, new_text);
                    end

                    color_print(0, 0, 0, 0, "\n");
                    return;
                end

                color_print(r, g, b, a, text .. "\n");
            end

            function notify:add_to_queue(r, g, b, a, ...)
                local text = table.concat {...};

                local this =
                {
                    text = text,
                    colour = {r, g, b, a},
                    colored = true,
                    liferemaining = duration
                };

                queue[#queue + 1] = this;

                while #queue > times do
                    table.remove(queue, 1);
                end

                return this;
            end

            function notify:should_draw()
                local is_visible = false;
                local host_frametime = globals.frametime();

                if not native_ConsoleIsVisible() then
                    for i = #queue, 1, -1 do
                        local v = queue[i];
                        v.liferemaining = v.liferemaining - host_frametime;

                        if v.liferemaining <= 0 then
                            table.remove(queue, i);
                            goto continue;
                        end

                        is_visible = true;
                        ::continue::
                    end
                end

                return is_visible;
            end

            function notify:on_paint_ui()
                local x, y = 8, 5;
                local flags = "d";

                for i = 1, #queue do
                    local v = queue[i];

                    local colour = v.colour;
                    local r, g, b, a = colour[1], colour[2], colour[3], colour[4];

                    local text = v.text:gsub("\n", "");
                    local measure = vector(renderer.measure_text(flags, text));

                    local tall = measure.y + 1;

                    if v.liferemaining < .5 then
                        local f = func.fclamp(v.liferemaining, 0, .5) / .5;
                        a = a * f;

                        if i == 1 and f < .2 then
                            y = y - tall * (1 - f / .2);
                        end
                    end

                    if v.colored then
                        surface:color_text(63, x, y, r, g, b, a, text);
                    else
                        surface:text(63, x, y, r, g, b, a, text);
                    end

                    y = y + tall;
                end
            end

            function notify:on_output(e)
                local text = string.format("\a%02x%02x%02x%02x%s", e.r, e.g, e.b, e.a, e.text);
                local i = text:find "\0";

                if i ~= nil then
                    text = text:sub(1, i - 1);
                end

                if current ~= nil then
                    current.text = current.text .. text;

                    if i == nil then
                        current = nil;
                    end

                    return current;
                end

                local this = self:add_to_queue(e.r, e.g, e.b, e.a, text);
                this.colored = text:find "\a" ~= nil;

                if i ~= nil then
                    current = this;
                end

                return this;
            end

            function notify:on_console_input(e)
                if e:find("clear") == 1 then
                    for i = 1, #queue do
                        queue[i] = nil;
                    end
                end
            end
        end

        device:on_update()


        client.set_event_callback("paint_ui", function()
            if not ui.get(menu["visuals & misc"]["visuals"]["devPrint"]) then return end
            device:on_update()
            notify:should_draw()
            notify:on_paint_ui()
        end)

        client.set_event_callback("output", function(e)
            notify:on_output(e)
        end)

        client.set_event_callback("console_input", function(e)
            if not ui.get(menu["visuals & misc"]["visuals"]["devPrint"]) then return end
            notify:on_console_input(e)
        end)

        ui.set_callback(menu["visuals & misc"]["visuals"]["devPrint"], function() 
            local callback = ui.get(menu["visuals & misc"]["visuals"]["devPrint"]) and client.set_event_callback or client.unset_event_callback
            callback("output", function(e) notify:on_output(e) end)
        end)



            local killsay_messages = {
        "noobini", "la noobini", "fi do noobini", "noobini", "mx gay boyceta", "noobini", "joao namorado do muriloso", "joao namorado do muriloso", "joao namorado do muriloso"
        }
            
            local kill_queue = {}
            local is_processing = false
            
            local function get_two_random_phrases()
                if #killsay_messages < 2 then return killsay_messages[1], killsay_messages[1] end
                local first, second
                repeat
                    first = math.random(#killsay_messages)
                    second = math.random(#killsay_messages)
                until first ~= second
                return killsay_messages[first], killsay_messages[second]
            end
            
            local function process_kill_queue()
                if #kill_queue == 0 then
                    is_processing = false
                    return
                end
            
                local pair = table.remove(kill_queue, 1)
                client.exec("say " .. pair[1])
                client.exec("say " .. pair[2])
            
                client.delay_call(1.0, process_kill_queue)
            end
            
            
            tbl.callbacks["killsay"] = function(e)
                if not tbl.contains(ui.get(menu["visuals & misc"]["misc"]["features"]), "killsay") then return end
            
                local local_player = entity.get_local_player()
                if not local_player then return end
            
                local attacker = client.userid_to_entindex(e.attacker)
                local victim = client.userid_to_entindex(e.userid)
            
                if attacker == local_player or victim == local_player then
                    local msg1, msg2 = get_two_random_phrases()
                    table.insert(kill_queue, {msg1, msg2})
            
                    if not is_processing then
                        is_processing = true
                        process_kill_queue()
                    end
                end
            end

            client.set_event_callback("shutdown", function()
                r_3dsky:set_raw_int(1)
            end)

            ui.set_callback(menu.rage.remove_3d_sky, function(var)
                local state = ui.get(var)
                r_3dsky:set_raw_int(state and 0 or 1)
            end)

            client.set_event_callback("shutdown", function()
                local enemies = entity.get_players(true)
            end)
            tbl.events = {
                paint_ui = { "menu", "arrows", "indicator", "hitmarker_paint" },
                aim_fire = { "hitmarker_aim_fire" },
                setup_command = { "command", "freestand", "recharge", "spin_aa" },
                shutdown = { "shutdown" },
                round_prestart = { "reset", "hitmarker_round_prestart" },
                pre_render = { "animations" },
                player_death = { "killsay" },
            }
            for index, value in next, tbl.events do 
                for i, v in next, value do client.set_event_callback(index, tbl.callbacks[v]) end
            end

        local function get_server_cvars()
            local cvars = {
                maxunlag = cvar.sv_maxunlag:get_float(),
                interp = cvar.cl_interp:get_float(),
                interp_ratio = cvar.cl_interp_ratio:get_float(),
                tickrate = 1 / globals.tickinterval()
            }
            
            cvars.max_backtrack_ticks = math.floor(cvars.maxunlag / globals.tickinterval())
            
            return cvars
        end

        local server_info = get_server_cvars()

        local resolver = {
            enabled = false,
            players = {},
            
            config = {
                history_size = 100,
                min_shots = 2,
                confidence_threshold = 0.55,
                expire_time = 30.0,
                brute_phases = 12,
                learning_rate = 0.25,
                lock_duration = 4.0,
                pattern_window = 15,
                velocity_smoothing = 0.3,
                angle_tolerance = 8
            },
            
            stats = {
                total_shots = 0,
                total_hits = 0,
                total_misses = 0,
                accuracy = 0,
                best_method = "none",
                method_stats = {}
            },
            
            
            global_patterns = {
                common_desync_angles = {},
                effective_counters = {},
                time_patterns = {}
            }
        }

        local function create_player_data()
            return {
                shots = {},
                hits = 0,
                misses = 0,
                last_shot_time = 0,
                last_update = 0,
                threat_level = 0,  
                
                
                brute = {
                    phase = 1,
                    custom_phases = {},
                    base_phases = {0, 58, -58, 45, -45, 30, -30, 15, -15, 90, -90, 25, -25, 35, -35, 50, -50},
                    weights = {},  
                    locked = false,
                    lock_side = 0,
                    lock_confidence = 0,
                    consecutive_hits = 0,
                    consecutive_misses = 0,
                    last_switch = 0,
                    cycle_speed = 0.5,  
                    exhausted_phases = {}  
                },
                
                
                body = {
                    history = {},
                    current = 0,
                    last = 0,
                    delta_pattern = {},
                    flip_frequency = 0,
                    last_flip = 0,
                    static_ticks = 0,
                    predicted_next = 0,
                    oscillation_period = 0,
                    variance = 0
                },
                
                
                movement = {
                    velocity_history = {},
                    strafe_direction = 0,
                    strafe_detected = false,
                    acceleration = 0,
                    stop_detected = false,
                    jitter_detected = false,
                    last_direction = 0,
                    direction_changes = 0,
                    speed_variance = 0
                },
                
                
                angles = {
                    yaw_history = {},
                    yaw_deltas = {},
                    flip_pattern = {},
                    flip_detected = false,
                    flip_interval = 0,
                    micro_adjustments = 0,
                    dominant_frequency = 0,
                    phase_offset = 0,
                    jitter_amplitude = 0
                },
                
                
                patterns = {
                    hit_sequence = {},
                    miss_sequence = {},
                    time_based = {},
                    conditional = {},
                    markov_chain = {},
                    confidence_map = {},
                    state_transitions = {},
                    temporal_weights = {},
                    context_memory = {}  
                },
                
                
                weapon = {
                    last_weapon = "",
                    weapon_patterns = {},
                    scoped = false,
                    accuracy_factor = 1.0
                },
                
                
                distance = {
                    last_distance = 0,
                    distance_history = {},
                    optimal_distance = 0,
                    close_range_side = 0,
                    long_range_side = 0
                },
                
                
                override = {
                    value = 0,
                    confidence = 0,
                    time = 0,
                    source = "none",
                    lock_until = 0,
                    fusion_weights = {},
                    prediction_history = {}
                },
                
                
                aa_type = {
                    detected = "unknown",
                    confidence = 0,
                    characteristics = {}
                }
            }
        end

        local function get_player_data(ent)
            local idx = tostring(entity.get_steam64(ent) or ent)
            if not resolver.players[idx] then
                resolver.players[idx] = create_player_data()
                
                for i, _ in ipairs(resolver.players[idx].brute.base_phases) do
                    resolver.players[idx].brute.weights[i] = 1.0
                end
            end
            return resolver.players[idx]
        end

        local function cleanup_resolver_data()
            local now = globals.realtime()
            for idx, data in pairs(resolver.players) do
                if now - data.last_update > resolver.config.expire_time then
                    resolver.players[idx] = nil
                end
            end
        end



        local function get_distance_to_player(ent)
            local lp = entity.get_local_player()
            if not lp then return 500 end
            
            local lx, ly, lz = entity.get_prop(lp, "m_vecOrigin")
            local ex, ey, ez = entity.get_prop(ent, "m_vecOrigin")
            
            if not lx or not ex then return 500 end
            return math.sqrt((ex-lx)^2 + (ey-ly)^2 + (ez-lz)^2)
        end

        local function softmax(values)
            local exp_values = {}
            local sum = 0
            
            for i, v in ipairs(values) do
                exp_values[i] = math.exp(v)
                sum = sum + exp_values[i]
            end
            
            for i, v in ipairs(exp_values) do
                exp_values[i] = v / sum
            end
            
            return exp_values
        end

        local function weighted_random_select(items, weights)
            local total = 0
            for _, w in ipairs(weights) do
                total = total + w
            end
            
            local rand = math.random() * total
            local cumulative = 0
            
            for i, w in ipairs(weights) do
                cumulative = cumulative + w
                if rand <= cumulative then
                    return items[i], i
                end
            end
            
            return items[#items], #items
        end

        local function calculate_variance(values)
            if #values < 2 then return 0 end
            
            local sum = 0
            for _, v in ipairs(values) do
                sum = sum + v
            end
            local mean = sum / #values
            
            local variance = 0
            for _, v in ipairs(values) do
                variance = variance + (v - mean)^2
            end
            
            return variance / (#values - 1)
        end




        local function adaptive_bruteforce(ent, data)
            local now = globals.realtime()
            
            -- Check AA type first
            if data.aa_type.detected == "jitter" and data.aa_type.confidence > 0.5 then
                -- For jitter AA: use faster cycling and counter-prediction
                local body_sign = data.body.current > 0 and 1 or -1
                local tick_phase = globals.tickcount() % 4
                
                -- Rapid switching for jitter
                if now - data.brute.last_switch > 0.15 then
                    data.brute.last_switch = now
                    
                    -- Counter the body yaw with some randomization
                    local base_prediction = body_sign > 0 and -58 or 58
                    local jitter_offset = client.random_int(-10, 10)
                    
                    return func.fclamp(base_prediction + jitter_offset, -60, 60), 0.65
                end
                
                return data.override.value, 0.55
            end
            
            -- Lock behavior for non-jitter
            if data.brute.locked and data.brute.consecutive_hits >= 2 and data.brute.lock_confidence > 0.75 then
                return data.brute.lock_side, math.min(0.95, data.brute.lock_confidence + 0.1)
            end
            
            -- Standard bruteforce for other AA types
            local all_phases = {}
            local all_weights = {}
            
            for i, phase in ipairs(data.brute.base_phases) do
                if not data.brute.exhausted_phases[phase] then
                    table.insert(all_phases, phase)
                    table.insert(all_weights, data.brute.weights[i] or 1.0)
                end
            end
            
            for _, phase in ipairs(data.brute.custom_phases) do
                table.insert(all_phases, phase)
                table.insert(all_weights, 1.5)
            end
            
            if #all_phases == 0 then
                data.brute.exhausted_phases = {}
                all_phases = data.brute.base_phases
                for i = 1, #all_phases do
                    all_weights[i] = 1.0
                end
            end
            
            -- Faster cycling on misses
            local cycle_delay = data.brute.cycle_speed
            if data.brute.consecutive_misses >= 2 then
                cycle_delay = math.max(0.1, cycle_delay * 0.4)
            elseif data.brute.consecutive_hits >= 1 then
                cycle_delay = math.min(1.5, cycle_delay * 1.5)
            end
            
            if now - data.brute.last_switch > cycle_delay then
                local normalized_weights = softmax(all_weights)
                local selected_phase, selected_idx = weighted_random_select(all_phases, normalized_weights)
                
                data.brute.phase = selected_idx
                data.brute.last_switch = now
                
                return selected_phase, 0.40 + (normalized_weights[selected_idx] or 0) * 0.3
            end
            
            local current_phase = all_phases[data.brute.phase] or all_phases[1] or 0
            return current_phase, 0.35
        end


        local function body_delta_method(ent, data)
            local pose = entity.get_prop(ent, "m_flPoseParameter", 11)
            if not pose then return 0, 0 end
            
            local body_yaw = (pose * 120) - 60
            local cl_interp = cvar.cl_interp:get_float()
            local cl_interp_ratio = cvar.cl_interp_ratio:get_float()
            local tickrate = 1 / globals.tickinterval()
            local interp_time = math.max(cl_interp, cl_interp_ratio / tickrate)
            if #data.body.history >= 3 then
                    local velocity = 0
                    for i = 2, #data.body.history do
                        local dt = data.body.history[i].time - data.body.history[i-1].time
                        if dt > 0 then
                            velocity = velocity + (data.body.history[i].yaw - data.body.history[i-1].yaw) / dt
                        end
                    end
                    velocity = velocity / (#data.body.history - 1)
                    
                    -- Extrapolate body yaw forward by interp_time
                    local predicted_yaw = body_yaw + (velocity * interp_time)
                    predicted_yaw = func.fclamp(predicted_yaw, -60, 60)
                    
                    return predicted_yaw > 0 and 58 or -58, 0.75
                end    
            data.body.last = data.body.current
            data.body.current = body_yaw
            
            
            table.insert(data.body.history, {yaw = body_yaw, time = globals.realtime()})
            if #data.body.history > 50 then
                table.remove(data.body.history, 1)
            end
            
            if #data.body.history < 12 then return 0, 0 end
            
            
            local deltas = {}
            local sign_changes = 0
            local last_sign = 0
            
            for i = 2, #data.body.history do
                local delta = data.body.history[i].yaw - data.body.history[i-1].yaw
                table.insert(deltas, delta)
                
                local current_sign = delta > 0 and 1 or (delta < 0 and -1 or 0)
                if current_sign ~= 0 and last_sign ~= 0 and current_sign ~= last_sign then
                    sign_changes = sign_changes + 1
                end
                if current_sign ~= 0 then
                    last_sign = current_sign
                end
            end
            
            
            data.body.variance = calculate_variance(deltas)
            
            
            if sign_changes >= 4 then
                local time_span = data.body.history[#data.body.history].time - data.body.history[1].time
                data.body.oscillation_period = time_span / sign_changes * 2
                
                
                local phase = (globals.realtime() % data.body.oscillation_period) / data.body.oscillation_period
                data.body.predicted_next = phase < 0.5 and 58 or -58
                
                return data.body.predicted_next, 0.72
            end
            
            
            local avg_abs_delta = 0
            for _, d in ipairs(deltas) do
                avg_abs_delta = avg_abs_delta + math.abs(d)
            end
            avg_abs_delta = avg_abs_delta / #deltas
            
            if avg_abs_delta < 5 then
                data.body.static_ticks = data.body.static_ticks + 1
                local confidence = math.min(data.body.static_ticks / 15, 0.85)
                return body_yaw > 0 and 58 or -58, confidence
            end
            
            
            if sign_changes > #deltas * 0.6 then
                data.body.flip_frequency = sign_changes / #deltas
                
                return body_yaw > 0 and -58 or 58, 0.68
            end
            
            data.body.static_ticks = 0
            return 0, 0
        end


        local function strafe_prediction(ent, data)
            local vx, vy, vz = entity.get_prop(ent, "m_vecVelocity")
            if not vx then return 0, 0 end
            
            local speed = math.sqrt(vx*vx + vy*vy)
            local eye_yaw = select(2, entity.get_prop(ent, "m_angEyeAngles"))
            if not eye_yaw then return 0, 0 end
            
            
            local smoothed_speed = speed
            if #data.movement.velocity_history > 0 then
                local last = data.movement.velocity_history[#data.movement.velocity_history]
                smoothed_speed = last.speed * (1 - resolver.config.velocity_smoothing) + speed * resolver.config.velocity_smoothing
            end
            
            table.insert(data.movement.velocity_history, {
                speed = smoothed_speed, 
                vx = vx, 
                vy = vy,
                time = globals.realtime()
            })
            if #data.movement.velocity_history > 25 then
                table.remove(data.movement.velocity_history, 1)
            end
            
            
            if speed < 5 then
                data.movement.stop_detected = true
                
                
                if #data.patterns.hit_sequence >= 3 then
                    local last_hit_side = data.patterns.hit_sequence[#data.patterns.hit_sequence]
                    return last_hit_side > 0 and 58 or -58, 0.55
                end
                return 0, 0
            end
            data.movement.stop_detected = false
            
            
            local move_yaw = math.deg(math.atan2(vy, vx))
            local move_delta = func.aa_clamp(move_yaw - eye_yaw)
            
            
            local direction_change = false
            if data.movement.last_direction ~= 0 then
                if (move_delta > 0) ~= (data.movement.last_direction > 0) then
                    direction_change = true
                    data.movement.direction_changes = data.movement.direction_changes + 1
                end
            end
            data.movement.last_direction = move_delta
            
            
            if #data.movement.velocity_history >= 2 then
                local prev = data.movement.velocity_history[#data.movement.velocity_history - 1]
                local curr = data.movement.velocity_history[#data.movement.velocity_history]
                local dt = curr.time - prev.time
                if dt > 0 then
                    data.movement.acceleration = (curr.speed - prev.speed) / dt
                end
            end
            
            
            if data.movement.direction_changes > 5 then
                data.movement.jitter_detected = true
                
                local tick_phase = globals.tickcount() % 6
                local prediction = tick_phase < 3 and 58 or -58
                return prediction, 0.70
            end
            
            
            local speeds = {}
            for _, v in ipairs(data.movement.velocity_history) do
                table.insert(speeds, v.speed)
            end
            data.movement.speed_variance = calculate_variance(speeds)
            
            
            if math.abs(move_delta) > 25 then
                data.movement.strafe_detected = true
                data.movement.strafe_direction = move_delta
                
                
                local accel_factor = 1.0
                if data.movement.acceleration > 100 then
                    accel_factor = 1.2  
                elseif data.movement.acceleration < -100 then
                    accel_factor = 0.8  
                end
                
                local prediction = move_delta > 0 and -55 or 55
                local confidence = math.min(speed / 200, 1) * 0.65 * accel_factor
                
                return prediction, confidence
            end
            
            data.movement.strafe_detected = false
            return 0, 0
        end


        local function flip_pattern_detection(ent, data)
            local eye_yaw = select(2, entity.get_prop(ent, "m_angEyeAngles"))
            if not eye_yaw then return 0, 0 end
            
            
            table.insert(data.angles.yaw_history, {yaw = eye_yaw, time = globals.realtime()})
            if #data.angles.yaw_history > 40 then
                table.remove(data.angles.yaw_history, 1)
            end
            
            if #data.angles.yaw_history < 15 then return 0, 0 end
            
            
            local large_changes = 0
            local small_changes = 0
            local change_times = {}
            
            for i = 2, #data.angles.yaw_history do
                local delta = math.abs(func.aa_clamp(data.angles.yaw_history[i].yaw - data.angles.yaw_history[i-1].yaw))
                table.insert(data.angles.yaw_deltas, delta)
                
                if delta > 40 then
                    large_changes = large_changes + 1
                    table.insert(change_times, data.angles.yaw_history[i].time)
                elseif delta > 5 and delta <= 40 then
                    small_changes = small_changes + 1
                    data.angles.micro_adjustments = data.angles.micro_adjustments + 1
                end
            end
            
            if #data.angles.yaw_deltas > 40 then
                table.remove(data.angles.yaw_deltas, 1)
            end
            
            
            if #data.angles.yaw_deltas > 5 then
                local sum = 0
                for _, d in ipairs(data.angles.yaw_deltas) do
                    sum = sum + d
                end
                data.angles.jitter_amplitude = sum / #data.angles.yaw_deltas
            end
            
            
            if #change_times >= 3 then
                local intervals = {}
                for i = 2, #change_times do
                    table.insert(intervals, change_times[i] - change_times[i-1])
                end
                
                local avg_interval = 0
                for _, int in ipairs(intervals) do
                    avg_interval = avg_interval + int
                end
                avg_interval = avg_interval / #intervals
                
                data.angles.flip_interval = avg_interval
                data.angles.dominant_frequency = 1 / avg_interval
                
                
                if avg_interval > 0.05 and avg_interval < 1.0 then
                    data.angles.flip_detected = true
                    
                    
                    local time_since_last = globals.realtime() - change_times[#change_times]
                    local phase = (time_since_last / avg_interval) % 1
                    
                    
                    local prediction
                    if phase < 0.5 then
                        prediction = data.angles.yaw_history[#data.angles.yaw_history].yaw > 0 and 58 or -58
                    else
                        prediction = data.angles.yaw_history[#data.angles.yaw_history].yaw > 0 and -58 or 58
                    end
                    
                    local confidence = 0.75 - calculate_variance(intervals) * 0.5
                    return prediction, math.max(0.45, confidence)
                end
            end
            
            
            if data.angles.micro_adjustments > 10 and large_changes < 3 then
                
                local pose = entity.get_prop(ent, "m_flPoseParameter", 11)
                if pose then
                    local body_yaw = (pose * 120) - 60
                    return body_yaw > 0 and -58 or 58, 0.60
                end
            end
            
            data.angles.flip_detected = false
            return 0, 0
        end


        local function markov_learning(ent, data)
            if #data.shots < resolver.config.min_shots then
                return 0, 0
            end
            
            local now = globals.realtime()
            
            
            for i = 2, #data.shots do
                local prev = data.shots[i-1]
                local curr = data.shots[i]
                
                if prev.hit ~= nil and curr.hit ~= nil then
                    local key = string.format("%d_%d", prev.predicted_side > 0 and 1 or 0, curr.predicted_side > 0 and 1 or 0)
                    local time_weight = math.exp(-(now - curr.time) * 0.1)  
                    
                    data.patterns.markov_chain[key] = (data.patterns.markov_chain[key] or 0) + (curr.hit and time_weight or 0)
                    data.patterns.temporal_weights[key] = (data.patterns.temporal_weights[key] or 0) + time_weight
                end
            end
            
            
            local window = resolver.config.pattern_window
            local start_idx = math.max(1, #data.shots - window)
            
            local left_hits, right_hits = 0, 0
            local left_total, right_total = 0, 0
            local left_recent, right_recent = 0, 0
            
            for i = start_idx, #data.shots do
                local shot = data.shots[i]
                if shot.hit ~= nil then
                    local recency_weight = 1 + (i - start_idx) / window  
                    
                    if shot.predicted_side > 0 then
                        right_total = right_total + recency_weight
                        if shot.hit then 
                            right_hits = right_hits + recency_weight
                            if i > #data.shots - 3 then right_recent = right_recent + 1 end
                        end
                    else
                        left_total = left_total + recency_weight
                        if shot.hit then 
                            left_hits = left_hits + recency_weight
                            if i > #data.shots - 3 then left_recent = left_recent + 1 end
                        end
                    end
                end
            end
            
            
            local left_rate = left_total > 0 and (left_hits / left_total) or 0
            local right_rate = right_total > 0 and (right_hits / right_total) or 0
            
            
            left_rate = left_rate + left_recent * 0.15
            right_rate = right_rate + right_recent * 0.15
            
            local max_rate = math.max(left_rate, right_rate)
            
            if max_rate < resolver.config.confidence_threshold then
                return 0, 0
            end
            
            
            local prediction = left_rate > right_rate and -58 or 58
            local confidence = math.min(max_rate, 0.90)
            
            
            local distance = get_distance_to_player(ent)
            local context_key = string.format("dist_%d", math.floor(distance / 100))
            data.patterns.context_memory[context_key] = {side = prediction, confidence = confidence}
            
            return prediction, confidence
        end


        local function distance_resolver(ent, data)
            local distance = get_distance_to_player(ent)
            data.distance.last_distance = distance
            
            table.insert(data.distance.distance_history, {dist = distance, time = globals.realtime()})
            if #data.distance.distance_history > 30 then
                table.remove(data.distance.distance_history, 1)
            end
            
            
            local context_key = string.format("dist_%d", math.floor(distance / 100))
            local context = data.patterns.context_memory[context_key]
            
            if context and context.confidence > 0.6 then
                return context.side, context.confidence * 0.8
            end
            
            
            local close_hits, close_total = 0, 0
            local far_hits, far_total = 0, 0
            
            for _, shot in ipairs(data.shots) do
                if shot.distance then
                    if shot.distance < 300 then
                        close_total = close_total + 1
                        if shot.hit then close_hits = close_hits + 1 end
                    else
                        far_total = far_total + 1
                        if shot.hit then far_hits = far_hits + 1 end
                    end
                end
            end
            
            
            if distance < 300 and close_total >= 3 then
                local close_rate = close_hits / close_total
                if close_rate > 0.6 then
                    return data.distance.close_range_side ~= 0 and data.distance.close_range_side or 58, close_rate
                end
            elseif distance >= 300 and far_total >= 3 then
                local far_rate = far_hits / far_total
                if far_rate > 0.6 then
                    return data.distance.long_range_side ~= 0 and data.distance.long_range_side or -58, far_rate
                end
            end
            
            return 0, 0
        end

        local function analyze_jitter_pattern(data)
            local result = {
                predictable = false,
                next_side = 0,
                pattern_type = "random",
                confidence = 0
            }
            
            if #data.body.history < 10 then
                return result
            end
            
            -- Analyze sign changes
            local signs = {}
            for i = 1, #data.body.history do
                table.insert(signs, data.body.history[i].yaw > 0 and 1 or -1)
            end
            
            -- Check for alternating pattern (most common jitter)
            local alternating_count = 0
            for i = 2, #signs do
                if signs[i] ~= signs[i-1] then
                    alternating_count = alternating_count + 1
                end
            end
            
            local alternating_ratio = alternating_count / (#signs - 1)
            
            if alternating_ratio > 0.7 then
                -- Highly alternating = predict opposite of current
                result.predictable = true
                result.pattern_type = "alternating"
                result.next_side = signs[#signs] > 0 and -58 or 58
                result.confidence = alternating_ratio
                return result
            end
            
            -- Check for 2-tick pattern (left-left-right-right)
            local two_tick_matches = 0
            local two_tick_total = 0
            
            for i = 3, #signs do
                two_tick_total = two_tick_total + 1
                if signs[i] == signs[i-1] and signs[i] ~= signs[i-2] then
                    two_tick_matches = two_tick_matches + 1
                end
            end
            
            if two_tick_total > 5 and two_tick_matches / two_tick_total > 0.6 then
                result.predictable = true
                result.pattern_type = "two_tick"
                
                -- Predict based on whether we're in first or second tick of pattern
                if signs[#signs] == signs[#signs - 1] then
                    result.next_side = signs[#signs] > 0 and -58 or 58
                else
                    result.next_side = signs[#signs] > 0 and 58 or -58
                end
                result.confidence = two_tick_matches / two_tick_total
                return result
            end
            
            -- Check for random jitter (just counter body yaw)
            result.pattern_type = "random"
            result.next_side = signs[#signs] > 0 and -58 or 58
            result.confidence = 0.55
            
            return result
        end

        local function detect_aa_type(ent, data)
            local characteristics = {}
            
            -- Calculate jitter metrics more accurately
            local jitter_score = 0
            local static_score = 0
            local flip_score = 0
            local oscillation_score = 0
            
            -- Enhanced jitter detection from yaw deltas
            if #data.angles.yaw_deltas >= 5 then
                local rapid_changes = 0
                local small_jitters = 0
                local large_flips = 0
                
                for i, delta in ipairs(data.angles.yaw_deltas) do
                    if delta > 5 and delta < 25 then
                        small_jitters = small_jitters + 1
                    elseif delta >= 25 and delta < 60 then
                        rapid_changes = rapid_changes + 1
                    elseif delta >= 60 then
                        large_flips = large_flips + 1
                    end
                end
                
                local total = #data.angles.yaw_deltas
                jitter_score = (small_jitters + rapid_changes * 1.5) / total
                flip_score = large_flips / total
            end
            
            -- Body yaw analysis for jitter
            if #data.body.history >= 8 then
                local body_changes = 0
                local body_jitter_sum = 0
                
                for i = 2, #data.body.history do
                    local delta = math.abs(data.body.history[i].yaw - data.body.history[i-1].yaw)
                    if delta > 3 then
                        body_changes = body_changes + 1
                        body_jitter_sum = body_jitter_sum + delta
                    end
                end
                
                local avg_body_jitter = body_jitter_sum / math.max(1, body_changes)
                
                -- High frequency small changes = jitter
                if body_changes > #data.body.history * 0.5 and avg_body_jitter < 40 then
                    jitter_score = math.max(jitter_score, 0.8)
                end
            end
            
            -- Static detection
            static_score = math.min(1, data.body.static_ticks / 20)
            
            -- Oscillation detection
            oscillation_score = data.body.oscillation_period > 0 and 
                math.min(1, 0.5 / data.body.oscillation_period) or 0
            
            -- Movement-based jitter detection
            if data.movement.jitter_detected then
                jitter_score = math.max(jitter_score, 0.75)
            end
            
            characteristics.static = static_score
            characteristics.flip = flip_score
            characteristics.jitter = jitter_score
            characteristics.oscillation = oscillation_score
            
            data.aa_type.characteristics = characteristics
            
            -- Determine AA type with priority for jitter
            local max_score = 0
            local detected_type = "unknown"
            
            -- Jitter has priority if score is high enough
            if jitter_score > 0.5 then
                max_score = jitter_score
                detected_type = "jitter"
            elseif static_score > max_score then
                max_score = static_score
                detected_type = "static"
            end
            
            if flip_score > max_score and flip_score > 0.4 then
                max_score = flip_score
                detected_type = "desync_flip"
            end
            
            if oscillation_score > max_score then
                max_score = oscillation_score
                detected_type = "oscillation"
            end
            
            data.aa_type.detected = detected_type
            data.aa_type.confidence = max_score
            
            -- Return prediction based on AA type
            if detected_type == "jitter" then
                -- For jitter: use tick-based prediction with body yaw consideration
                local tick = globals.tickcount()
                local body_sign = data.body.current > 0 and 1 or -1
                
                -- Analyze jitter pattern
                local jitter_pattern = analyze_jitter_pattern(data)
                
                if jitter_pattern.predictable then
                    return jitter_pattern.next_side, 0.75
                else
                    -- Use weighted random based on recent success
                    local left_weight = 1.0
                    local right_weight = 1.0
                    
                    for i = math.max(1, #data.shots - 5), #data.shots do
                        local shot = data.shots[i]
                        if shot and shot.hit then
                            if shot.predicted_side > 0 then
                                right_weight = right_weight + 0.3
                            else
                                left_weight = left_weight + 0.3
                            end
                        end
                    end
                    
                    -- Counter the body yaw for jitter
                    local prediction = body_sign > 0 and -58 or 58
                    local confidence = 0.60 + (jitter_score * 0.15)
                    
                    return prediction, confidence
                end
                
            elseif detected_type == "static" then
                return data.body.current > 0 and 58 or -58, 0.80
                
            elseif detected_type == "desync_flip" then
                return data.body.current > 0 and -58 or 58, 0.72
                
            elseif detected_type == "oscillation" then
                return data.body.predicted_next, 0.70
            end
            
            return 0, 0
        end


        local function resolve_player(ent)
            if not entity.is_alive(ent) or entity.is_dormant(ent) then
                return
            end
            
            local data = get_player_data(ent)
            data.last_update = globals.realtime()
            
            local TB = tbl.tickbase_override
            local function get_lagcomp_window()
                local cl_interp = cvar.cl_interp:get_float()
                local cl_interp_ratio = cvar.cl_interp_ratio:get_float()
                
                cl_interp_ratio = math.max(TB.sv_client_min_interp_ratio, 
                                            math.min(TB.sv_client_max_interp_ratio, cl_interp_ratio))
                
                local interp_time = math.max(cl_interp, cl_interp_ratio / TB.tickrate)
                local interp_ticks = math.floor(interp_time / globals.tickinterval())
                
                local total_window = TB.max_rewind_ticks + interp_ticks
                
                return {
                    interp_ticks = interp_ticks,
                    backtrack_ticks = TB.max_rewind_ticks,
                    total_ticks = total_window,
                    tickrate = TB.tickrate
                }
            end    
            
            local lagcomp = get_lagcomp_window()
            local interp_delay = lagcomp.interp_ticks
            
            -- Enhanced lock behavior with confidence decay
            if data.override.lock_until > 0 and globals.realtime() < data.override.lock_until then
                local lock_age = globals.realtime() - (data.override.lock_start or data.override.time)
                local decay_factor = math.max(0.7, 1.0 - (lock_age / resolver.config.lock_duration) * 0.3)
                
                local decayed_confidence = data.override.confidence * decay_factor
                
                if decayed_confidence < 0.5 then
                    data.override.lock_until = 0
                    data.brute.locked = false
                else
                    plist.set(ent, "Override resolver", data.override.value / 60)
                    plist.set(ent, "Correction active", true)
                    return
                end
            end
            
            -- Collect predictions with enhanced weighting
            local methods = {
                {name = "adaptive_brute", func = adaptive_bruteforce, base_weight = 1.0},
                {name = "body_delta", func = body_delta_method, base_weight = 1.2},
                {name = "strafe", func = strafe_prediction, base_weight = 1.0},
                {name = "flip_pattern", func = flip_pattern_detection, base_weight = 1.1},
                {name = "markov", func = markov_learning, base_weight = 1.5},
                {name = "distance", func = distance_resolver, base_weight = 0.9},
                {name = "aa_type", func = detect_aa_type, base_weight = 1.3}
            }
            
            -- **FIX: Initialize predictions table BEFORE loop**
            local predictions = {}
            local max_confidence = 0
            local best_prediction = 0
            local best_source = "none"
            
            -- Enhanced prediction collection with historical performance
            for _, method in ipairs(methods) do
                local prediction, confidence = method.func(ent, data)
                
                -- Get method statistics
                local method_stats = resolver.stats.method_stats[method.name] or {hits = 0, total = 0}
                local method_accuracy = method_stats.total > 0 and (method_stats.hits / method_stats.total) or 0.5
                
                -- Apply performance-based weight adjustment
                local performance_multiplier = 0.7 + (method_accuracy * 0.6)
                local adjusted_weight = method.base_weight * performance_multiplier
                
                if prediction ~= 0 and confidence > 0 then
                    -- Apply recency boost for recently successful methods
                    local recency_bonus = 1.0
                    if data.override.source == method.name and data.hits > data.misses then
                        recency_bonus = 1.15
                    end
                    
                    local final_confidence = confidence * adjusted_weight * recency_bonus
                    
                    table.insert(predictions, {
                        value = prediction,
                        confidence = final_confidence,
                        raw_confidence = confidence,
                        source = method.name,
                        method_accuracy = method_accuracy
                    })
                    
                    if final_confidence > max_confidence then
                        max_confidence = final_confidence
                        best_prediction = prediction
                        best_source = method.name
                    end
                end
            end
            
            -- **FIX: Apply interpolation compensation with nil check**
            local function apply_interp_compensation(prediction, confidence)
                local tick_offset = math.floor(interp_delay * 0.7)
                
                if data.angles.flip_detected and data.angles.flip_interval > 0 then
                    local future_time = globals.realtime() + (tick_offset * globals.tickinterval())
                    local phase = (future_time / data.angles.flip_interval) % 1
                    
                    if phase < 0.5 then
                        prediction = -prediction
                    end
                end
                
                local interp_factor = 1.0 - (interp_delay / 20) * 0.3
                confidence = confidence * math.max(0.5, interp_factor)
                
                return prediction, confidence
            end
            
            -- Apply to all predictions (now safe because predictions is initialized)
            for i, pred in ipairs(predictions) do
                pred.value, pred.confidence = apply_interp_compensation(pred.value, pred.confidence)
            end
            
            -- Advanced confidence fusion with consensus weighting
            local final_yaw = 0
            local final_confidence = 0
            
            if #predictions >= 2 then
                -- Calculate consensus
                local left_predictions = {}
                local right_predictions = {}
                local left_weight_sum = 0
                local right_weight_sum = 0
                
                for _, pred in ipairs(predictions) do
                    if pred.value < 0 then
                        table.insert(left_predictions, pred)
                        left_weight_sum = left_weight_sum + pred.confidence
                    else
                        table.insert(right_predictions, pred)
                        right_weight_sum = right_weight_sum + pred.confidence
                    end
                end
                
                local total_predictions = #predictions
                local consensus_side = #left_predictions > #right_predictions and "left" or "right"
                local consensus_strength = math.abs(#left_predictions - #right_predictions) / total_predictions
                
                -- Enhanced weighted fusion
                local weighted_sum = 0
                local total_weight = 0
                local confidence_sum = 0
                
                for _, pred in ipairs(predictions) do
                    local is_consensus = (pred.value < 0 and consensus_side == "left") or 
                                    (pred.value >= 0 and consensus_side == "right")
                    
                    local consensus_bonus = is_consensus and (1.0 + consensus_strength * 0.3) or 0.8
                    
                    local combined_weight = pred.confidence * consensus_bonus * (0.5 + pred.method_accuracy * 0.5)
                    
                    weighted_sum = weighted_sum + pred.value * combined_weight
                    total_weight = total_weight + combined_weight
                    confidence_sum = confidence_sum + pred.raw_confidence
                end
                
                if total_weight > 0 then
                    final_yaw = weighted_sum / total_weight
                    
                    local avg_confidence = confidence_sum / #predictions
                    local consensus_boost = consensus_strength * 0.2
                    final_confidence = math.min(0.95, avg_confidence + consensus_boost)
                else
                    final_yaw = best_prediction
                    final_confidence = max_confidence
                end
                
            elseif #predictions == 1 then
                final_yaw = predictions[1].value
                final_confidence = predictions[1].raw_confidence
            else
                -- Fallback to bruteforce
                final_yaw = best_prediction
                final_confidence = 0.3
            end
            
            -- Clamp to valid range
            final_yaw = func.fclamp(final_yaw, -60, 60)
            
            -- Snap to common angles with tolerance
            local common_angles = {-58, -45, -30, -15, 0, 15, 30, 45, 58}
            local snap_tolerance = resolver.config.angle_tolerance
            
            for _, angle in ipairs(common_angles) do
                if math.abs(final_yaw - angle) < snap_tolerance then
                    final_yaw = angle
                    break
                end
            end
            
            -- Store prediction history
            table.insert(data.override.prediction_history, {
                value = final_yaw,
                confidence = final_confidence,
                source = best_source,
                time = globals.realtime(),
                consensus_predictions = #predictions
            })
            
            if #data.override.prediction_history > 50 then
                table.remove(data.override.prediction_history, 1)
            end
            
            -- Update override data
            data.override.value = final_yaw
            data.override.confidence = final_confidence
            data.override.source = best_source
            data.override.time = globals.realtime()
            data.override.fusion_weights = predictions
            
            -- Apply resolver override
            plist.set(ent, "Override resolver", final_yaw / 60)
            plist.set(ent, "Correction active", true)
        end

        -- Improved aim_hit callback with enhanced locking
        local function on_resolver_aim_hit(shot)
            if not resolver.enabled then return end
            local ent = shot.target
            if not ent then return end
            
            local data = get_player_data(ent)
            
            if #data.shots > 0 then
                local last_shot = data.shots[#data.shots]
                last_shot.hit = true
                
                -- Record hit sequence
                table.insert(data.patterns.hit_sequence, last_shot.predicted_side)
                if #data.patterns.hit_sequence > 30 then
                    table.remove(data.patterns.hit_sequence, 1)
                end
                
                -- Update bruteforce weights
                for i, phase in ipairs(data.brute.base_phases) do
                    if math.abs(phase - last_shot.predicted_side) < 10 then
                        data.brute.weights[i] = (data.brute.weights[i] or 1.0) * 1.4
                        data.brute.weights[i] = math.min(data.brute.weights[i], 8.0)
                    end
                end
                
                -- Enhanced hit tracking
                data.brute.consecutive_hits = data.brute.consecutive_hits + 1
                data.brute.consecutive_misses = 0
                
                -- Calculate lock confidence based on hit streak and pattern consistency
                local pattern_consistency = 0
                if #data.patterns.hit_sequence >= 3 then
                    local recent_hits = {}
                    for i = math.max(1, #data.patterns.hit_sequence - 5), #data.patterns.hit_sequence do
                        table.insert(recent_hits, data.patterns.hit_sequence[i])
                    end
                    
                    local same_side_count = 0
                    local first_side = recent_hits[1]
                    for _, side in ipairs(recent_hits) do
                        if (side > 0) == (first_side > 0) then
                            same_side_count = same_side_count + 1
                        end
                    end
                    pattern_consistency = same_side_count / #recent_hits
                end
                
                -- Dynamic lock threshold based on confidence and consistency
                local lock_threshold = 2
                if last_shot.confidence and last_shot.confidence > 0.8 then
                    lock_threshold = 1 -- Lock faster with high confidence
                end
                
                if data.brute.consecutive_hits >= lock_threshold then
                    data.brute.locked = true
                    data.brute.lock_side = last_shot.predicted_side
                    
                    -- Enhanced confidence calculation
                    local hit_streak_bonus = math.min(0.25, data.brute.consecutive_hits * 0.08)
                    local consistency_bonus = pattern_consistency * 0.15
                    local base_confidence = 0.65
                    
                    data.brute.lock_confidence = math.min(0.98, 
                        base_confidence + hit_streak_bonus + consistency_bonus)
                    
                    -- Adaptive lock duration based on confidence
                    local duration_multiplier = 1.0 + (data.brute.lock_confidence - 0.65) * 2
                    data.override.lock_until = globals.realtime() + 
                        (resolver.config.lock_duration * duration_multiplier)
                    data.override.lock_start = globals.realtime()
                end
                
                -- Update distance-based patterns
                if last_shot.distance then
                    if last_shot.distance < 300 then
                        data.distance.close_range_side = last_shot.predicted_side
                    else
                        data.distance.long_range_side = last_shot.predicted_side
                    end
                end
                
                -- Update method statistics
                if last_shot.source then
                    local stats = resolver.stats.method_stats[last_shot.source] or {hits = 0, total = 0}
                    stats.hits = stats.hits + 1
                    stats.total = stats.total + 1
                    resolver.stats.method_stats[last_shot.source] = stats
                end
            end
            
            data.hits = data.hits + 1
            data.misses = 0
            
            -- Update global stats
            resolver.stats.total_hits = resolver.stats.total_hits + 1
            resolver.stats.accuracy = resolver.stats.total_hits / math.max(1, resolver.stats.total_shots)
        end

        -- Improved aim_miss callback with adaptive recovery
        local function on_resolver_aim_miss(shot)
            if not resolver.enabled then return end
            local ent = shot.target
            if not ent then return end
            
            local data = get_player_data(ent)
            
            if #data.shots > 0 then
                local last_shot = data.shots[#data.shots]
                last_shot.hit = false
                
                -- Record miss sequence
                table.insert(data.patterns.miss_sequence, last_shot.predicted_side)
                if #data.patterns.miss_sequence > 30 then
                    table.remove(data.patterns.miss_sequence, 1)
                end
                
                -- Intelligent phase learning
                local missed_side = last_shot.predicted_side
                
                -- Calculate likely correct side based on recent misses
                local opposite_candidates = {}
                table.insert(opposite_candidates, -missed_side) -- Direct opposite
                table.insert(opposite_candidates, -missed_side + 15) -- Slight offsets
                table.insert(opposite_candidates, -missed_side - 15)
                
                for _, candidate in ipairs(opposite_candidates) do
                    local already_exists = false
                    for _, phase in ipairs(data.brute.custom_phases) do
                        if math.abs(phase - candidate) < 5 then
                            already_exists = true
                            break
                        end
                    end
                    
                    if not already_exists then
                        table.insert(data.brute.custom_phases, candidate)
                    end
                end
                
                -- Limit custom phases
                while #data.brute.custom_phases > 12 do
                    table.remove(data.brute.custom_phases, 1)
                end
                
                -- Penalize failed weights more heavily on consecutive misses
                local penalty_multiplier = 1.0 + (data.brute.consecutive_misses * 0.2)
                for i, phase in ipairs(data.brute.base_phases) do
                    if math.abs(phase - missed_side) < 10 then
                        data.brute.weights[i] = (data.brute.weights[i] or 1.0) * (0.5 / penalty_multiplier)
                        data.brute.weights[i] = math.max(data.brute.weights[i], 0.05)
                        
                        -- Mark as exhausted if weight too low
                        if data.brute.weights[i] < 0.2 then
                            data.brute.exhausted_phases[phase] = true
                        end
                    end
                end
                
                -- Update method statistics
                if last_shot.source then
                    local stats = resolver.stats.method_stats[last_shot.source] or {hits = 0, total = 0}
                    stats.total = stats.total + 1
                    resolver.stats.method_stats[last_shot.source] = stats
                end
            end
            
            -- Update miss tracking
            data.misses = data.misses + 1
            data.brute.consecutive_hits = 0
            data.brute.consecutive_misses = data.brute.consecutive_misses + 1
            
            -- Unlock and reset
            data.brute.locked = false
            data.override.lock_until = 0
            
            -- Adaptive cycle speed - speed up on consecutive misses
            local speed_multiplier = math.max(0.5, 1.0 - (data.brute.consecutive_misses * 0.15))
            data.brute.cycle_speed = math.max(0.15, data.brute.cycle_speed * speed_multiplier)
            
            -- Immediate flip with confidence reduction
            data.override.value = -(data.override.value or 0)
            data.override.confidence = math.max(0.2, data.override.confidence * 0.6)
            data.override.time = globals.realtime()
            data.brute.last_switch = globals.realtime()
            
            -- Update global stats
            resolver.stats.total_misses = resolver.stats.total_misses + 1
            resolver.stats.accuracy = resolver.stats.total_hits / math.max(1, resolver.stats.total_shots)
        end


        local function on_resolver_aim_fire(shot)
            if not resolver.enabled then return end
            local ent = shot.target
            if not ent then return end
            
            local data = get_player_data(ent)
            local pose = entity.get_prop(ent, "m_flPoseParameter", 11)
            local body_yaw = pose and ((pose * 120) - 60) or 0
            local distance = get_distance_to_player(ent)
            
            table.insert(data.shots, {
                time = globals.realtime(),
                predicted_side = data.override.value,
                actual_side = body_yaw,
                hit = nil,
                confidence = data.override.confidence,
                source = data.override.source,
                distance = distance
            })
            
            
            if #data.shots > resolver.config.history_size then
                table.remove(data.shots, 1)
            end
            
            data.last_shot_time = globals.realtime()
            resolver.stats.total_shots = resolver.stats.total_shots + 1
        end

        local function on_resolver_aim_hit(shot)
            if not resolver.enabled then return end
            local ent = shot.target
            if not ent then return end
            
            local data = get_player_data(ent)
            
            if #data.shots > 0 then
                local last_shot = data.shots[#data.shots]
                last_shot.hit = true
                
                
                table.insert(data.patterns.hit_sequence, last_shot.predicted_side)
                if #data.patterns.hit_sequence > 20 then
                    table.remove(data.patterns.hit_sequence, 1)
                end
                
                
                for i, phase in ipairs(data.brute.base_phases) do
                    if math.abs(phase - last_shot.predicted_side) < 10 then
                        data.brute.weights[i] = (data.brute.weights[i] or 1.0) * 1.3
                        data.brute.weights[i] = math.min(data.brute.weights[i], 5.0)
                    end
                end
                
                
                data.brute.consecutive_hits = data.brute.consecutive_hits + 1
                data.brute.consecutive_misses = 0
                
                if data.brute.consecutive_hits >= 2 then
                    data.brute.locked = true
                    data.brute.lock_side = last_shot.predicted_side
                    data.brute.lock_confidence = math.min(0.95, 0.65 + data.brute.consecutive_hits * 0.1)
                    data.override.lock_until = globals.realtime() + resolver.config.lock_duration
                end
                
                
                if last_shot.distance then
                    if last_shot.distance < 300 then
                        data.distance.close_range_side = last_shot.predicted_side
                    else
                        data.distance.long_range_side = last_shot.predicted_side
                    end
                end
                
                
                if last_shot.source then
                    resolver.stats.method_stats[last_shot.source] = resolver.stats.method_stats[last_shot.source] or {hits = 0, total = 0}
                    resolver.stats.method_stats[last_shot.source].hits = resolver.stats.method_stats[last_shot.source].hits + 1
                    resolver.stats.method_stats[last_shot.source].total = resolver.stats.method_stats[last_shot.source].total + 1
                end
            end
            
            data.hits = data.hits + 1
            data.misses = 0
            
            resolver.stats.total_hits = resolver.stats.total_hits + 1
            resolver.stats.accuracy = resolver.stats.total_hits / math.max(1, resolver.stats.total_shots)
        end

        local function on_resolver_aim_miss(shot)
            if not resolver.enabled then return end
            local ent = shot.target
            if not ent then return end
            
            local data = get_player_data(ent)
            
            if #data.shots > 0 then
                local last_shot = data.shots[#data.shots]
                last_shot.hit = false
                
                
                table.insert(data.patterns.miss_sequence, last_shot.predicted_side)
                if #data.patterns.miss_sequence > 20 then
                    table.remove(data.patterns.miss_sequence, 1)
                end
                
                
                local missed_side = last_shot.predicted_side
                local opposite = -missed_side
                
                local already_exists = false
                for _, phase in ipairs(data.brute.custom_phases) do
                    if math.abs(phase - opposite) < 10 then
                        already_exists = true
                        break
                    end
                end
                
                if not already_exists then
                    table.insert(data.brute.custom_phases, opposite)
                    if #data.brute.custom_phases > 10 then
                        table.remove(data.brute.custom_phases, 1)
                    end
                end
                
                
                for i, phase in ipairs(data.brute.base_phases) do
                    if math.abs(phase - missed_side) < 10 then
                        data.brute.weights[i] = (data.brute.weights[i] or 1.0) * 0.6
                        data.brute.weights[i] = math.max(data.brute.weights[i], 0.1)
                        
                        
                        if data.brute.weights[i] < 0.3 then
                            data.brute.exhausted_phases[phase] = true
                        end
                    end
                end
                
                
                if last_shot.source then
                    resolver.stats.method_stats[last_shot.source] = resolver.stats.method_stats[last_shot.source] or {hits = 0, total = 0}
                    resolver.stats.method_stats[last_shot.source].total = resolver.stats.method_stats[last_shot.source].total + 1
                end
            end
            
            data.misses = data.misses + 1
            data.brute.consecutive_hits = 0
            data.brute.consecutive_misses = data.brute.consecutive_misses + 1
            data.brute.locked = false
            data.brute.cycle_speed = math.max(0.2, data.brute.cycle_speed * 0.7)  
            data.override.lock_until = 0
            
            
            data.override.value = -(data.override.value or 0)
            data.override.time = globals.realtime()
            data.brute.last_switch = globals.realtime()
            
            resolver.stats.total_misses = resolver.stats.total_misses + 1
            resolver.stats.accuracy = resolver.stats.total_hits / math.max(1, resolver.stats.total_shots)
        end


        local function setup_resolver()
            client.set_event_callback("aim_fire", on_resolver_aim_fire)
            client.set_event_callback("aim_hit", on_resolver_aim_hit)
            client.set_event_callback("aim_miss", on_resolver_aim_miss)
            
            client.set_event_callback("paint", function()
                if not resolver.enabled then
                    resolver.players = {}
                    return
                end
                
                cleanup_resolver_data()
                
                local enemies = entity.get_players(true)
                for _, ent in ipairs(enemies) do
                    resolve_player(ent)
                end
            end)
            
            
            client.set_event_callback("round_prestart", function()
                
                for idx, data in pairs(resolver.players) do
                    data.brute.consecutive_hits = 0
                    data.brute.consecutive_misses = 0
                    data.brute.locked = false
                    data.override.lock_until = 0
                    data.brute.cycle_speed = 0.5
                end
            end)

            local function init_resolver_cvars()
                -- Read server settings
                local max_unlag = cvar.sv_maxunlag:get_float()
                local tickrate = 1 / globals.tickinterval()
                
                resolver.config.max_backtrack = math.floor(max_unlag / globals.tickinterval())
                resolver.config.tickrate = tickrate
                
                -- Client interpolation
                local interp = cvar.cl_interp:get_float()
                local interp_ratio = cvar.cl_interp_ratio:get_float()
                resolver.config.lerp_time = interp + (interp_ratio * globals.tickinterval())
                
                -- Update resolver based on server settings
                if tickrate == 128 then
                    resolver.config.brute_phases = 14  -- More phases on 128 tick
                else
                    resolver.config.brute_phases = 10  -- Fewer on 64 tick
                end
            end

            client.set_event_callback("round_start", function()
                init_resolver_cvars()
            end)
                
            ui.set_callback(menu["rage"]["aaresolver"], function()
                resolver.enabled = ui.get(menu["rage"]["aaresolver"])
                
                if not resolver.enabled then
                    local enemies = entity.get_players(true)
                    for _, ent in ipairs(enemies) do
                        pcall(function()
                            plist.set(ent, "Correction active", false)
                        end)
                    end
                    resolver.players = {}
                    resolver.stats = {
                        total_shots = 0,
                        total_hits = 0,
                        total_misses = 0,
                        accuracy = 0,
                        best_method = "none",
                        method_stats = {}
                    }
                end
            end)
        end

        setup_resolver()

            if not __luasense_console_handlers_registered then
                __luasense_console_handlers_registered = true

                local function console_print_segments(...)
                    for _, seg in pairs({...}) do
                        local r, g, b, txt = 255, 255, 255, seg
                        if type(seg) == "table" then
                            r, g, b, txt = seg[1], seg[2], seg[3], seg[4]
                        end
                        client.color_log(r or 255, g or 255, b or 255, tostring(txt or "") .. "\x00")
                    end
                    client.color_log(255, 255, 255, " ")
                end

                local function logs_enabled(name)
                    local sel = ui.get(menu["visuals & misc"]["visuals"]["logs"]) or {}
                    for _, v in ipairs(sel) do
                        if type(v) == "string" and v:lower() == name:lower() then
                            return true
                        end
                    end
                    return false
                end
                
            client.set_event_callback("item_purchase", function(e)
                if not logs_enabled("buy") then return end
                local idx = client.userid_to_entindex(e.userid)
                if not idx then return end
                local player = c_entity.new(idx)
                local name = player:get_player_name() or "?"
                local weapon = (e.weapon or ""):lower()

                local br, bg, bb = 255, 255, 255
                local gr, gg, gb = ui.get(menu["visuals & misc"]["visuals"]["watermark_color"])
                local sr, sg, sb = 255, 255, 255
                local buyr, buyg, buyb = 255,255,255

                local parts = {}
                table.insert(parts, {br, bg, bb, "["})
                table.insert(parts, {gr, gg, gb, "Lua"})
                table.insert(parts, {sr, sg, sb, "Sense"})
                table.insert(parts, {br, bg, bb, "] "})
                table.insert(parts, {buyr, buyg, buyb, name .. " bought "})
                table.insert(parts, {255,255,255, weapon})
                console_print_segments(unpack(parts))
            end)
            
            local fired_shots = {}
            local bullet_impacts = {}

            local function totime(ticks)
                return string.format("%.2fs", (ticks or 0) * globals.tickinterval())
            end

            client.set_event_callback("aim_fire", function(shot)
                local now_tick = globals.tickcount()
                local shot_tick = shot.tick or now_tick
                shot.backtrack = math.max(0, now_tick - shot_tick)
                shot.backtrack = math.floor(shot.backtrack + 0.5)
                fired_shots[shot.id] = { fired = shot, spread = 0 }
            end)

            client.set_event_callback("bullet_impact", function(e)
                local idx = client.userid_to_entindex(e.userid)
                if idx == entity.get_local_player() then
                    local now_tick = globals.tickcount()
                    if #bullet_impacts > 150 and bullet_impacts[#bullet_impacts].tick ~= now_tick then
                        bullet_impacts = {}
                    end
                    bullet_impacts[#bullet_impacts + 1] = {
                        tick = now_tick,
                        origin = vector(client.eye_position()),
                        shot = vector(e.x, e.y, e.z)
                    }
                end
            end)

            client.set_event_callback("aim_hit", function(shot)
                if not logs_enabled("hit") then return end
                local target_name = entity.get_player_name(shot.target) or "?"
                local target_hp = entity.get_prop(shot.target, "m_iHealth") or "?"
                local hitgroup_name = hitboxes[shot.hitgroup] or "?"
                local wanted_hitgroup = hitboxes[(shot.aim_hitbox or shot.hitgroup)] or "?"
                local dmg = shot.damage or 0
                local wanted_dmg = shot.damage or 0
                local spread = ("%.1f"):format(shot.spread or 0)
                local fired_entry = fired_shots[shot.id]
                local last_imp = bullet_impacts[#bullet_impacts]
                local fired = fired_entry and fired_entry.fired
                local now_tick = globals.tickcount()

                if last_imp and fired and last_imp.tick == now_tick then
                    local a1 = (last_imp.origin - vector(fired.x, fired.y, fired.z)):angles()
                    local a2 = (last_imp.origin - last_imp.shot):angles()
                    fired_entry.spread = vector(a1 - a2):length2d()
                end

                local bt_tick = fired and fired.backtrack or 0
                bt_tick = math.floor(bt_tick + 0.5)
                local bt_time = totime(bt_tick)

                local br, bg, bb = 255, 255, 255
                local gr, gg, gb = ui.get(menu["visuals & misc"]["visuals"]["watermark_color"])
                local sr, sg, sb = 255, 255, 255

                local advanced = logs_enabled("advanced")

                local parts = {}
                table.insert(parts, {br, bg, bb, "["})
                table.insert(parts, {gr, gg, gb, "Lua"})
                table.insert(parts, {sr, sg, sb, "Sense"})
                table.insert(parts, {br, bg, bb, "] "})
                table.insert(parts, {hr, hg, hb, "Registered"})
                table.insert(parts, {255,255,255, " shot at "})
                table.insert(parts, {hr, hg, hb, target_name})
                table.insert(parts, {255,255,255, "'s "})
                table.insert(parts, {hr, hg, hb, hitgroup_name})
                table.insert(parts, {255,255,255, " for "})
                table.insert(parts, {hr, hg, hb, tostring(dmg) .. "(" .. tostring(wanted_dmg) .. ")"})
                table.insert(parts, {255,255,255, " "})
                table.insert(parts, {255,255,255, "(hp: "})
                table.insert(parts, {hr, hg, hb, tostring(target_hp)})
                table.insert(parts, {255,255,255, ")"})
                table.insert(parts, {255,255,255, " (aimed: "})
                table.insert(parts, {hr, hg, hb, wanted_hitgroup})
                table.insert(parts, {255,255,255, ")"})
                table.insert(parts, {255,255,255, " (bt: "})
                table.insert(parts, {hr, hg, hb, bt_tick})
                table.insert(parts, {255,255,255, ")"})
                if advanced and tonumber(spread) and tonumber(spread) > 0 then
                    table.insert(parts, {255,255,255, " (spread: "})
                    table.insert(parts, {hr, hg, hb, spread .. "°"})
                    table.insert(parts, {255,255,255, ")"})
                end

                console_print_segments(unpack(parts))
                pcall(function()
                    local key_base = tostring(tbl.getstate(false, false, 0, false)) -- fallback
                    -- find any stats with a recent last_choice for active states
                    for key, s in pairs(localdb.auto_rand_stats or {}) do
                        if s._last_choice_at and (globals.realtime() - s._last_choice_at) <= 3.0 then
                            ar_record_result(key, s._last_choice or 0, true)
                        end
                    end
                end)
            end)

            client.set_event_callback("aim_miss", function(shot)
                if not logs_enabled("miss") then return end
                local target_name = entity.get_player_name(shot.target) or "?"
                local hitgroup_name = hitboxes[shot.hitgroup] or "?"
                local wanted_hitgroup = hitboxes[(shot.aim_hitbox or shot.hitgroup)] or "?"
                local wanted_dmg = shot.damage or 0
                local reason = shot.reason or "?"
                local hit_chance = ("%.0f"):format(shot.hit_chance or 0)
                local spread = ("%.1f"):format(shot.spread or 0)

                local fired_entry = fired_shots[shot.id]
                local last_imp = bullet_impacts[#bullet_impacts]
                local fired = fired_entry and fired_entry.fired
                local now_tick = globals.tickcount()

                if last_imp and fired and last_imp.tick == now_tick then
                    local a1 = (last_imp.origin - vector(fired.x, fired.y, fired.z)):angles()
                    local a2 = (last_imp.origin - last_imp.shot):angles()
                    fired_entry.spread = vector(a1 - a2):length2d()
                end

                local bt_tick = fired and fired.backtrack or 0
                bt_tick = math.floor(bt_tick + 0.5)
                local bt_time = totime(bt_tick)

                local mr, mg, mb = 255, 255, 255
                local br, bg, bb = 255, 255, 255
                local gr, gg, gb = ui.get(menu["visuals & misc"]["visuals"]["watermark_color"])
                local sr, sg, sb = 255, 255, 255
                local use_hit_clr = false
                local advanced = logs_enabled("advanced")

                local parts = {}
                table.insert(parts, {br, bg, bb, "["})
                table.insert(parts, {gr, gg, gb, "Lua"})
                table.insert(parts, {sr, sg, sb, "Sense"})
                table.insert(parts, {br, bg, bb, "] "})

                table.insert(parts, { use_hit_clr and hr or mr, use_hit_clr and hg or mg, use_hit_clr and hb or mb, "Missed" })
                table.insert(parts, {255,255,255, " shot at "})
                table.insert(parts, { use_hit_clr and hr or mr, use_hit_clr and hg or mg, use_hit_clr and hb or mb, target_name })
                table.insert(parts, {255,255,255, "'s "})
                table.insert(parts, { use_hit_clr and hr or mr, use_hit_clr and hg or mg, use_hit_clr and hb or mb, hitgroup_name })
                table.insert(parts, {255,255,255, " due to "})
                table.insert(parts, { use_hit_clr and hr or mr, use_hit_clr and hg or mg, use_hit_clr and hb or mb, reason })
                table.insert(parts, {255,255,255, " "})
                table.insert(parts, {255,255,255, "(hc: "})
                table.insert(parts, { use_hit_clr and hr or mr, use_hit_clr and hg or mg, use_hit_clr and hb or mb, hit_chance .. "%" })
                table.insert(parts, {255,255,255, ")"})
                table.insert(parts, {255,255,255, " (damage: "})
                table.insert(parts, { use_hit_clr and hr or mr, use_hit_clr and hg or mg, use_hit_clr and hb or mb, tostring(wanted_dmg)})
                table.insert(parts, {255,255,255, ")"})
                table.insert(parts, {255,255,255, " (bt: "})
                table.insert(parts, { use_hit_clr and hr or mr, use_hit_clr and hg or mg, use_hit_clr and hb or mb, bt_tick })
                table.insert(parts, {255,255,255, ")"})
                if advanced and tonumber(spread) and tonumber(spread) > 0 then
                    table.insert(parts, {255,255,255, " (spread: "})
                    table.insert(parts, { use_hit_clr and hr or mr, use_hit_clr and hg or mg, use_hit_clr and hb or mb, spread .. "°"})
                    table.insert(parts, {255,255,255, ")"})
                end

                console_print_segments(unpack(parts))
            end)

            client.set_event_callback("player_hurt", function(e)
                    local victim = client.userid_to_entindex(e.userid)
                    local local_player = entity.get_local_player()
                    if victim ~= local_player then return end
                    pcall(function()
                        for key, s in pairs(localdb.auto_rand_stats or {}) do
                            if s._last_choice_at and (globals.realtime() - s._last_choice_at) <= 3.0 then
                                ar_record_result(key, s._last_choice or 0, false)
                            end
                        end
                    end)
                end)
            end     

        end)({
            ref = function(a,b,c) return { ui.reference(a,b,c) } end,
            clamp = function(x) if x == nil then return 0 end x = (x % 360 + 360) % 360 return x > 180 and x - 360 or x end,
            contains = function(z,x) for i, v in next, z do if v == x then return true end end return false end,
            states = { "global", "standing", "moving", "air", "air duck", "duck", "duck moving", "slow motion", "fake lag", "hide shot" },
            getstate = function(air, duck, speed, slowcheck)
                local state = "global"
                if air and duck then state = "air duck" end
                if air and not duck then state = "air" end
                if duck and not air and speed < 1.1 then state = "duck" end
                if duck and not air and speed > 1.1 then state = "duck moving" end
                if speed < 1.1 and not air and not duck then state = "standing" end
                if speed > 1.1 and not air and not duck then state = "moving" end
                if slowcheck and not air and not duck and speed > 1.1 then state = "slow motion" end
                return state
            end
            
        })


