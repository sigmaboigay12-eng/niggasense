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
            local fps_boost = {
                active = false,
                original_values = {},
                
                
                cvars = {
                    
                    { name = "mat_queue_mode", value = 2 },           
                    { name = "r_dynamic", value = 0 },                
                    { name = "r_eyegloss", value = 0 },               
                    { name = "r_eyemove", value = 0 },                
                    { name = "r_eyeshift_x", value = 0 },
                    { name = "r_eyeshift_y", value = 0 },
                    { name = "r_eyeshift_z", value = 0 },
                    { name = "r_eyesize", value = 0 },
                    
                    
                    { name = "muzzleflash_light", value = 0 },        
                    { name = "cl_show_splashes", value = 0 },         
                    { name = "cl_disable_ragdolls", value = 1 },      
                    { name = "cl_phys_props_max", value = 0 },        
                    { name = "props_break_max_pieces", value = 0 },   
                    { name = "r_drawmodeldecals", value = 0 },        
                    { name = "r_drawtracers_firstperson", value = 0 }, 
                    
                    
                    { name = "cl_new_impact_effects", value = 0 },    
                    { name = "r_drawparticles", value = 0 },          
                    { name = "func_break_max_pieces", value = 0 },    
                    
                    
                    { name = "r_shadowrendertotexture", value = 0 },  
                    { name = "cl_csm_enabled", value = 0 },           
                    
                    
                    { name = "mat_postprocess_enable", value = 0 },   
                    { name = "mat_hdr_level", value = 0 },            
                    
                    
                    { name = "r_drawdetailprops", value = 0 },        
                    { name = "cl_detail_max_sway", value = 0 },       
                    { name = "cl_detail_multiplier", value = 0 },     
                    
                    
                    { name = "r_ropetranslucent", value = 0 },        
                    { name = "rope_smooth", value = 0 },              
                    { name = "rope_wind_dist", value = 0 },           
                    
                    
                    { name = "cl_forcepreload", value = 1 },          
                    { name = "mat_vsync", value = 0 },                
                    { name = "fps_max", value = 0 },                  
                    { name = "fps_max_menu", value = 120 },           
                }
            }

            
            local function save_original_cvars()
                for i, cvar_data in ipairs(fps_boost.cvars) do
                    local ok, cvar_obj = pcall(function() return cvar[cvar_data.name] end)
                    if ok and cvar_obj then
                        local ok_get, original = pcall(function() 
                            
                            local val = cvar_obj:get_int()
                            if val == nil then
                                val = cvar_obj:get_float()
                            end
                            if val == nil then
                                val = cvar_obj:get_string()
                            end
                            return val
                        end)
                        
                        if ok_get and original ~= nil then
                            fps_boost.original_values[cvar_data.name] = original
                        end
                    end
                end
            end

            
            local function apply_fps_boost()
                for i, cvar_data in ipairs(fps_boost.cvars) do
                    local ok, cvar_obj = pcall(function() return cvar[cvar_data.name] end)
                    if ok and cvar_obj then
                        pcall(function()
                            if type(cvar_data.value) == "number" then
                                
                                local ok_int = pcall(cvar_obj.set_int, cvar_obj, cvar_data.value)
                                if not ok_int then
                                    
                                    pcall(cvar_obj.set_float, cvar_obj, cvar_data.value)
                                end
                            else
                                
                                pcall(cvar_obj.set_string, cvar_obj, tostring(cvar_data.value))
                            end
                        end)
                    end
                end
                
                fps_boost.active = true
            end

            
            local function restore_original_cvars()
                for name, value in pairs(fps_boost.original_values) do
                    local ok, cvar_obj = pcall(function() return cvar[name] end)
                    if ok and cvar_obj then
                        pcall(function()
                            if type(value) == "number" then
                                local ok_int = pcall(cvar_obj.set_int, cvar_obj, value)
                                if not ok_int then
                                    pcall(cvar_obj.set_float, cvar_obj, value)
                                end
                            else
                                pcall(cvar_obj.set_string, cvar_obj, tostring(value))
                            end
                        end)
                    end
                end
                
                fps_boost.active = false
            end
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
                
                
                local function read_config_file()
                    if type(readfile) ~= "function" then return {} end
                    local ok, content = pcall(readfile, CONFIG_FILE)
                    if not ok or not content then return {} end
                    
                    local ok2, data = pcall(json.parse, content)
                    if not ok2 or type(data) ~= "table" then return {} end
                    
                    return data
                end
                
                
                local function write_config_file(data)
                    if type(writefile) ~= "function" then return false end
                    
                    local ok, json_str = pcall(json.stringify, data)
                    if not ok then return false end
                    
                    local ok2 = pcall(writefile, CONFIG_FILE, json_str)
                    return ok2
                end
                
                
                function config_file.save(name)
                    if not name or name == "" then return false end
                    
                    local all_configs = read_config_file()
                    local username = js.MyPersonaAPI.GetName()
                    
                    
                    local full_config = {
                        menu = capture_all_menu_values(),
                        aa = capture_all_aa_values(),
                        
                        
                        name = name,
                        author = username,
                        timestamp = client.system_time(),
                        date = username,
                        version = "luasense_v2"
                    }
                    
                    all_configs[name] = full_config
                    
                    return write_config_file(all_configs)
                end
                
                
                function config_file.load(name)
                    if not name or name == "" then return nil end
                    
                    local all_configs = read_config_file()
                    local config = all_configs[name]
                    
                    if not config then return nil end
                    
                    
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
                
                
                function config_file.delete(name)
                    if not name or name == "" then return false end
                    
                    local all_configs = read_config_file()
                    all_configs[name] = nil
                    
                    return write_config_file(all_configs)
                end
                
                
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
                    
                    
                    table.sort(names, function(a, b)
                        return (a.timestamp or 0) > (b.timestamp or 0)
                    end)
                    
                    return names
                end
                
                
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
                
                
                function config_file.import(encoded_data, import_name)
                    local ok, json_str = pcall(base64.decode, encoded_data)
                    if not ok then return nil, "Failed to decode" end
                    
                    local ok2, config = pcall(json.parse, json_str)
                    if not ok2 then return nil, "Failed to parse JSON" end
                    
                    
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
                            features = ui.new_multiselect("aa", "anti-aimbot angles", prefix("features"), {"fix hideshot", "animations", "legs spammer", "dt_os_recharge_fix", "killsay", "spin on no enemies alive/warmup"}),
                            spammer = ui.new_slider("aa", "anti-aimbot angles", prefix("legs"), 1, 9, 1),
                            autobuy = ui.new_combobox("aa", "anti-aimbot angles", prefix("auto buy"), {"off", "awp", "scout"}),
                            fpsboostoptimizecvars = ui.new_checkbox("aa", "anti-aimbot angles", prefix("fps boost"), false),
                        }
                        
                    },
            ["config"] = {
                category_label = ui.new_label("aa", "anti-aimbot angles", prefix("config system")),
                category = ui.new_combobox("aa", "anti-aimbot angles", prefix("category"), {"local", "cloud"}),
                
                separator = ui.new_label("aa", "anti-aimbot angles", "\n "),
                
                
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
                        
                        local items = {}
                        local new_list = config_file.list()
                        for i, entry in ipairs(new_list) do
                            table.insert(items, string.format("%s [%s]", entry.name, entry.date))
                        end
                        ui.update(menu["config"]["local_list"], items)
                        
                        
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

            
            client.delay_call(0.1, function()
                local items = {}
                local list = config_file.list()
                for i, entry in ipairs(list) do
                    table.insert(items, string.format("%s [%s]", entry.name, entry.date))
                end
                ui.update(menu["config"]["local_list"], items)
            end)

            client.delay_call(0.1, function()
                ui.set_callback(menu["visuals & misc"]["misc"]["fpsboostoptimizecvars"], function()
                    local enabled = ui.get(menu["visuals & misc"]["misc"]["fpsboostoptimizecvars"])
                    
                    if enabled and not fps_boost.active then
                        
                        if not next(fps_boost.original_values) then
                            save_original_cvars()
                        end
                        apply_fps_boost()
                    elseif not enabled and fps_boost.active then
                        restore_original_cvars()
                    end
                end)
            end)

            
            client.set_event_callback("shutdown", function()
                if fps_boost.active then
                    restore_original_cvars()
                end
            end)

            
            client.delay_call(0.2, function()
                local enabled = ui.get(menu["visuals & misc"]["misc"]["fpsboostoptimizecvars"])
                if enabled then
                    save_original_cvars()
                    apply_fps_boost()
                end
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
tbl.jitter_system = {
    
    sync = {
        last_desync_side = 0,
        last_jitter_phase = 0,
        sync_offset = 0,
        transition_tick = 0
    },
    
    
    adaptive = {
        base_amplitude = 0,
        current_amplitude = 0,
        distance_factor = 1.0,
        weapon_factor = 1.0,
        threat_factor = 1.0
    },
    
    
    phase = {
        current_phase = 0,
        phase_offset = 0,
        last_randomize = 0,
        randomize_interval = 0.15,
        entropy_pool = {}
    },
    
    
    speed = {
        base_speed = 1.0,
        current_speed = 1.0,
        threat_multiplier = 1.0,
        last_update = 0
    }
}


local function sync_jitter_with_desync(cmd, data, current_desync_side)
    local js = tbl.jitter_system
    local tick = globals.tickcount()
    
    
    local desync_changed = (current_desync_side > 0) ~= (js.sync.last_desync_side > 0)
    
    if desync_changed then
        
        js.sync.transition_tick = tick
        
        
        if current_desync_side > 0 then
            js.sync.sync_offset = client.random_int(0, 3)
        else
            js.sync.sync_offset = client.random_int(2, 5)
        end
        
        
        js.sync.last_jitter_phase = 1 - js.sync.last_jitter_phase
    end
    
    js.sync.last_desync_side = current_desync_side
    
    
    local ticks_since_transition = tick - js.sync.transition_tick
    local sync_phase = (ticks_since_transition + js.sync.sync_offset) % 8
    
    return sync_phase, desync_changed
end


local function calculate_adaptive_jitter_range(ent, base_jitter)
    local js = tbl.jitter_system
    local lp = entity.get_local_player()
    if not lp then return base_jitter end
    
    
    local distance = 500
    local ex, ey, ez = entity.get_prop(ent or lp, "m_vecOrigin")
    local lx, ly, lz = entity.get_prop(lp, "m_vecOrigin")
    
    if ex and lx then
        distance = math.sqrt((ex-lx)^2 + (ey-ly)^2 + (ez-lz)^2)
    end
    
    
    local dist_factor = 1.0
    if distance < 300 then
        
        dist_factor = 0.65 + (distance / 300) * 0.35
    elseif distance > 800 then
        
        dist_factor = 1.0 + math.min(0.4, (distance - 800) / 1000)
    end
    
    
    local weapon_factor = 1.0
    local enemy = ent or client.current_threat()
    
    if enemy then
        local enemy_weapon = entity.get_player_weapon(enemy)
        if enemy_weapon then
            local classname = entity.get_classname(enemy_weapon) or ""
            classname = classname:lower()
            
            if classname:find("awp") then
                
                weapon_factor = 1.35
            elseif classname:find("ssg08") then
                
                weapon_factor = 1.25
            elseif classname:find("deagle") then
                
                weapon_factor = 1.15
            elseif classname:find("knife") then
                
                weapon_factor = 0.5
            elseif classname:find("pistol") or classname:find("glock") or 
                   classname:find("usp") or classname:find("p250") then
                
                weapon_factor = 1.0
            elseif classname:find("rifle") or classname:find("ak47") or 
                   classname:find("m4a") then
                
                weapon_factor = 1.10
            end
        end
    end
    
    
    js.adaptive.distance_factor = dist_factor
    js.adaptive.weapon_factor = weapon_factor
    js.adaptive.base_amplitude = base_jitter
    
    
    local adaptive_amplitude = base_jitter * dist_factor * weapon_factor
    
    
    adaptive_amplitude = func.fclamp(adaptive_amplitude, base_jitter * 0.5, base_jitter * 1.5)
    
    js.adaptive.current_amplitude = adaptive_amplitude
    
    return adaptive_amplitude
end


local function randomize_jitter_phase(cmd)
    local js = tbl.jitter_system
    local now = globals.realtime()
    local tick = cmd.command_number
    
    
    if now - js.phase.last_randomize >= js.phase.randomize_interval then
        js.phase.last_randomize = now
        
        
        table.insert(js.phase.entropy_pool, {
            time = now,
            tick = tick % 256,
            rand = client.random_int(0, 255),
            latency = math.floor(client.latency() * 1000) % 100
        })
        
        
        while #js.phase.entropy_pool > 8 do
            table.remove(js.phase.entropy_pool, 1)
        end
        
        
        local entropy_sum = 0
        for _, e in ipairs(js.phase.entropy_pool) do
            entropy_sum = entropy_sum + e.rand + e.tick + e.latency
        end
        
        
        js.phase.randomize_interval = 0.1 + (entropy_sum % 150) / 1000
        
        
        js.phase.phase_offset = entropy_sum % 8
    end
    
    
    local randomized_phase = (tick + js.phase.phase_offset) % 16
    
    
    local micro_offset = 0
    if tick % 7 == 0 then
        micro_offset = client.random_int(-1, 1)
    end
    
    js.phase.current_phase = (randomized_phase + micro_offset) % 16
    
    return js.phase.current_phase
end


local function modulate_jitter_speed(base_delay)
    local js = tbl.jitter_system
    local now = globals.realtime()
    
    
    local threat_level = 0.5  
    local enemy = client.current_threat()
    
    if enemy and entity.is_alive(enemy) then
        local lp = entity.get_local_player()
        if lp then
            
            local ex, ey, ez = entity.get_prop(enemy, "m_vecOrigin")
            local lx, ly, lz = entity.get_prop(lp, "m_vecOrigin")
            
            if ex and lx then
                local distance = math.sqrt((ex-lx)^2 + (ey-ly)^2 + (ez-lz)^2)
                
                
                if distance < 300 then
                    threat_level = 0.9
                elseif distance < 500 then
                    threat_level = 0.7
                elseif distance < 800 then
                    threat_level = 0.5
                else
                    threat_level = 0.3
                end
            end
            
            
            local vx, vy = entity.get_prop(enemy, "m_vecVelocity")
            if vx then
                local velocity = math.sqrt(vx*vx + vy*vy)
                if velocity > 200 then
                    threat_level = threat_level * 0.8
                elseif velocity < 20 then
                    threat_level = threat_level * 1.15
                end
            end
            
            
            local enemy_weapon = entity.get_player_weapon(enemy)
            if enemy_weapon then
                local classname = entity.get_classname(enemy_weapon) or ""
                if classname:lower():find("awp") then
                    threat_level = math.min(1.0, threat_level * 1.3)
                elseif classname:lower():find("knife") then
                    threat_level = threat_level * 0.5
                end
            end
            
            
            local is_scoped = (entity.get_prop(enemy, "m_bIsScoped") or 0) ~= 0
            if is_scoped then
                threat_level = math.min(1.0, threat_level * 1.25)
            end
        end
    end
    
    
    local alpha = 0.15
    js.speed.threat_multiplier = js.speed.threat_multiplier * (1 - alpha) + threat_level * alpha
    
    
    
    local speed_modifier = 1.0
    
    if js.speed.threat_multiplier > 0.7 then
        
        speed_modifier = 0.6 + (1.0 - js.speed.threat_multiplier) * 0.67
    elseif js.speed.threat_multiplier < 0.4 then
        
        speed_modifier = 1.1 + (0.4 - js.speed.threat_multiplier) * 0.5
    end
    
    
    local variation = 1.0 + (client.random_int(-10, 10) / 100)
    speed_modifier = speed_modifier * variation
    
    
    speed_modifier = func.fclamp(speed_modifier, 0.5, 1.5)
    
    js.speed.current_speed = speed_modifier
    js.speed.last_update = now
    
    
    local modulated_delay = math.max(1, math.floor(base_delay * speed_modifier + 0.5))
    
    return modulated_delay, js.speed.threat_multiplier
end



local function apply_enhanced_jitter(cmd, data, base_jitter_value, current_desync_side)
    local js = tbl.jitter_system
    local enemy = client.current_threat()
    
    
    local sync_phase, desync_changed = sync_jitter_with_desync(cmd, data, current_desync_side)
    
    
    local adaptive_amplitude = calculate_adaptive_jitter_range(enemy, base_jitter_value)
    
    
    local random_phase = randomize_jitter_phase(cmd)
    
    
    local speed_modifier, threat_level = modulate_jitter_speed(1)
    
    
    local combined_phase = (sync_phase + random_phase) % 16
    
    
    local jitter_direction = (combined_phase % 2 == 0) and 1 or -1
    
    
    local threat_amplitude_scale = 0.85 + threat_level * 0.3
    local final_amplitude = adaptive_amplitude * threat_amplitude_scale
    
    
    if desync_changed and client.random_int(1, 100) > 60 then
        jitter_direction = -jitter_direction
    end
    
    local final_jitter = final_amplitude * jitter_direction
    
    
    js.last_result = {
        base = base_jitter_value,
        adaptive = adaptive_amplitude,
        final = final_jitter,
        sync_phase = sync_phase,
        random_phase = random_phase,
        threat = threat_level,
        speed_mod = speed_modifier,
        desync_changed = desync_changed
    }
    
    return final_jitter, speed_modifier
end


tbl.apply_enhanced_jitter = apply_enhanced_jitter
tbl.sync_jitter_with_desync = sync_jitter_with_desync
tbl.calculate_adaptive_jitter_range = calculate_adaptive_jitter_range
tbl.randomize_jitter_phase = randomize_jitter_phase
tbl.modulate_jitter_speed = modulate_jitter_speed

tbl.desync_system = {
    
    variation = {
        base_desync = 60,
        current_desync = 60,
        variation_range = 15,
        variation_speed = 0.08,
        last_variation_time = 0,
        variation_phase = 0,
        pattern = "smooth" 
    },
    
    
    on_shot = {
        enabled = true,
        last_shot_tick = 0,
        pre_shot_side = 0,
        flip_duration_ticks = 8,
        should_flip = false,
        flip_until_tick = 0
    },
    
    
    velocity = {
        current_speed = 0,
        max_speed = 250,
        min_desync_mult = 0.65,
        max_desync_mult = 1.0,
        smoothed_mult = 1.0,
        standing_bonus = 1.15,
        air_penalty = 0.80
    },
    
    
    lean = {
        current_lean = 0,
        lean_threshold = 0.15,
        lean_desync_offset = 0,
        lean_history = {},
        lean_prediction = 0
    },
    
    
    output = {
        final_desync = 60,
        final_side = 1,
        confidence = 1.0
    }
}


local function calculate_desync_variation(base_desync)
    local ds = tbl.desync_system
    local now = globals.realtime()
    local tick = globals.tickcount()
    
    
    local dt = now - ds.variation.last_variation_time
    ds.variation.last_variation_time = now
    
    
    ds.variation.variation_phase = ds.variation.variation_phase + dt * ds.variation.variation_speed * 10
    
    local variation_amount = 0
    
    if ds.variation.pattern == "smooth" then
        
        variation_amount = math.sin(ds.variation.variation_phase) * ds.variation.variation_range
        
        
        variation_amount = variation_amount + math.sin(ds.variation.variation_phase * 1.7) * (ds.variation.variation_range * 0.3)
        
    elseif ds.variation.pattern == "stepped" then
        
        local step_phase = math.floor(ds.variation.variation_phase) % 4
        local step_values = {0, ds.variation.variation_range * 0.5, ds.variation.variation_range, ds.variation.variation_range * 0.5}
        variation_amount = step_values[step_phase + 1] or 0
        
        
        local step_progress = ds.variation.variation_phase % 1
        local next_step = (step_phase + 1) % 4
        local next_value = step_values[next_step + 1] or 0
        variation_amount = variation_amount * (1 - step_progress) + next_value * step_progress
        
    elseif ds.variation.pattern == "random" then
        
        if tick % 8 == 0 then
            ds.variation._target_variation = (client.random_int(0, 100) / 100) * ds.variation.variation_range
        end
        
        local target = ds.variation._target_variation or 0
        local alpha = 0.15
        ds.variation._smoothed_variation = (ds.variation._smoothed_variation or 0) * (1 - alpha) + target * alpha
        variation_amount = ds.variation._smoothed_variation
    end
    
    
    local varied_desync = base_desync - math.abs(variation_amount)
    
    
    varied_desync = func.fclamp(varied_desync, 30, 60)
    
    ds.variation.current_desync = varied_desync
    
    return varied_desync
end


local function handle_on_shot_desync(cmd, current_side)
    local ds = tbl.desync_system
    local tick = cmd.command_number
    
    
    local is_attacking = bit.band(cmd.in_attack, 1) == 1
    
    
    local dt_active = ui.get(menu_refs["doubletap"][1]) and ui.get(menu_refs["doubletap"][2])
    local hs_active = ui.get(menu_refs["hideshots"][1]) and ui.get(menu_refs["hideshots"][2])
    
    
    if is_attacking and tick > ds.on_shot.last_shot_tick + 4 then
        
        ds.on_shot.last_shot_tick = tick
        ds.on_shot.pre_shot_side = current_side
        ds.on_shot.should_flip = true
        ds.on_shot.flip_until_tick = tick + ds.on_shot.flip_duration_ticks
        
        
        if dt_active or hs_active then
            ds.on_shot.flip_until_tick = tick + ds.on_shot.flip_duration_ticks + 4
        end
    end
    
    
    if ds.on_shot.should_flip then
        if tick > ds.on_shot.flip_until_tick then
            ds.on_shot.should_flip = false
        else
            
            return -ds.on_shot.pre_shot_side
        end
    end
    
    return current_side
end


local function calculate_velocity_desync_scale(lp)
    local ds = tbl.desync_system
    
    if not lp then return 1.0 end
    
    
    local vx, vy, vz = entity.get_prop(lp, "m_vecVelocity")
    if not vx then return 1.0 end
    
    local speed = math.sqrt(vx*vx + vy*vy)
    ds.velocity.current_speed = speed
    
    
    local flags = entity.get_prop(lp, "m_fFlags") or 0
    local on_ground = bit.band(flags, 1) == 1
    
    
    local speed_ratio = speed / ds.velocity.max_speed
    speed_ratio = func.fclamp(speed_ratio, 0, 1)
    
    
    
    local base_mult = ds.velocity.max_desync_mult - speed_ratio * (ds.velocity.max_desync_mult - ds.velocity.min_desync_mult)
    
    
    if speed < 5 then
        base_mult = base_mult * ds.velocity.standing_bonus
    end
    
    
    if not on_ground then
        base_mult = base_mult * ds.velocity.air_penalty
    end
    
    
    local alpha = 0.2
    ds.velocity.smoothed_mult = ds.velocity.smoothed_mult * (1 - alpha) + base_mult * alpha
    
    return func.fclamp(ds.velocity.smoothed_mult, ds.velocity.min_desync_mult, ds.velocity.max_desync_mult * ds.velocity.standing_bonus)
end


local function calculate_lean_desync_offset(lp)
    local ds = tbl.desync_system
    
    if not lp then return 0 end
    
    
    local lean_pose = entity.get_prop(lp, "m_flPoseParameter", 12)
    if not lean_pose then return 0 end
    
    
    local lean_amount = (lean_pose - 0.5) * 2
    ds.lean.current_lean = lean_amount
    
    
    table.insert(ds.lean.lean_history, {
        lean = lean_amount,
        time = globals.realtime()
    })
    
    
    while #ds.lean.lean_history > 15 do
        table.remove(ds.lean.lean_history, 1)
    end
    
    
    if #ds.lean.lean_history >= 3 then
        local recent = ds.lean.lean_history[#ds.lean.lean_history]
        local older = ds.lean.lean_history[#ds.lean.lean_history - 2]
        
        if recent and older then
            local lean_velocity = (recent.lean - older.lean) / math.max(0.001, recent.time - older.time)
            ds.lean.lean_prediction = lean_velocity
        end
    end
    
    
    local offset = 0
    
    if math.abs(lean_amount) > ds.lean.lean_threshold then
        
        
        
        
        if lean_amount > 0 then
            
            offset = -lean_amount * 10
        else
            
            offset = -lean_amount * 10
        end
        
        
        offset = offset + ds.lean.lean_prediction * 2
    end
    
    ds.lean.lean_desync_offset = offset
    
    return func.fclamp(offset, -15, 15)
end


local function apply_enhanced_desync(cmd, data, base_desync, current_side)
    local ds = tbl.desync_system
    local lp = entity.get_local_player()
    
    if not lp then return base_desync, current_side end
    
    
    local varied_desync = calculate_desync_variation(base_desync)
    
    
    local velocity_scale = calculate_velocity_desync_scale(lp)
    varied_desync = varied_desync * velocity_scale
    
    
    local lean_offset = calculate_lean_desync_offset(lp)
    
    
    
    if lean_offset ~= 0 then
        
        varied_desync = varied_desync + lean_offset * 0.3
    end
    
    
    local final_side = current_side
    if ds.on_shot.enabled then
        final_side = handle_on_shot_desync(cmd, current_side)
    end
    
    
    varied_desync = func.fclamp(varied_desync, 20, 60)
    
    
    ds.output.final_desync = varied_desync
    ds.output.final_side = final_side
    ds.output.confidence = velocity_scale
    
    return varied_desync, final_side
end


local function set_desync_variation_pattern(pattern)
    if pattern == "smooth" or pattern == "stepped" or pattern == "random" then
        tbl.desync_system.variation.pattern = pattern
    end
end

local function set_desync_variation_range(range)
    tbl.desync_system.variation.variation_range = func.fclamp(range, 0, 25)
end

local function set_on_shot_desync(enabled)
    tbl.desync_system.on_shot.enabled = enabled
end

local function set_velocity_desync_limits(min_mult, max_mult)
    tbl.desync_system.velocity.min_desync_mult = func.fclamp(min_mult, 0.3, 1.0)
    tbl.desync_system.velocity.max_desync_mult = func.fclamp(max_mult, 0.5, 1.0)
end


tbl.apply_enhanced_desync = apply_enhanced_desync
tbl.set_desync_variation_pattern = set_desync_variation_pattern
tbl.set_desync_variation_range = set_desync_variation_range
tbl.set_on_shot_desync = set_on_shot_desync
tbl.set_velocity_desync_limits = set_velocity_desync_limits

tbl.fakelag_system = {
    
    choke_sync = {
        last_choke_count = 0,
        choke_release_detected = false,
        release_tick = 0,
        pre_release_side = 0,
        flip_on_release = true,
        flip_duration_ticks = 4,
        release_history = {},
        avg_choke_length = 0
    },
    
    
    pattern = {
        current_pattern = "default",
        pattern_index = 0,
        pattern_tick = 0,
        last_pattern_change = 0,
        pattern_change_interval = 2.0,
        variation_seed = 0,
        
        
        patterns = {
            default = {14, 14, 14, 14},
            alternating = {14, 7, 14, 7, 14, 7},
            decreasing = {14, 12, 10, 8, 14, 12, 10},
            burst = {14, 14, 3, 3, 14, 14, 3},
            random_low = {8, 10, 12, 9, 11, 13},
            random_high = {12, 14, 13, 14, 12, 14},
            stutter = {14, 2, 14, 2, 14, 14, 2},
            wave = {8, 10, 12, 14, 12, 10, 8}
        },
        
        
        pattern_weights = {
            default = 1.0,
            alternating = 1.2,
            decreasing = 1.1,
            burst = 1.15,
            random_low = 0.9,
            random_high = 1.0,
            stutter = 1.25,
            wave = 1.1
        }
    },
    
    
    exploit = {
        dt_active = false,
        hs_active = false,
        defensive_active = false,
        exploit_detected_tick = 0,
        
        
        dt_fakelag = {
            pre_shot_choke = 1,
            post_shot_choke = 0,
            recharge_choke = 14
        },
        hs_fakelag = {
            pre_shot_choke = 14,
            post_shot_choke = 1,
            during_hide_choke = 0
        },
        
        
        last_shot_tick = 0,
        exploit_phase = "idle", 
        phase_start_tick = 0
    },
    
    
    output = {
        recommended_choke = 14,
        should_flip_desync = false,
        pattern_name = "default",
        exploit_override = false
    }
}


local function handle_choke_sync_desync(cmd, current_desync_side)
    local fs = tbl.fakelag_system
    local tick = cmd.command_number
    local current_choke = cmd.chokedcommands or 0
    
    
    local choke_dropped = fs.choke_sync.last_choke_count >= 6 and current_choke <= 1
    
    if choke_dropped then
        
        fs.choke_sync.choke_release_detected = true
        fs.choke_sync.release_tick = tick
        fs.choke_sync.pre_release_side = current_desync_side
        
        
        table.insert(fs.choke_sync.release_history, {
            tick = tick,
            choke_length = fs.choke_sync.last_choke_count,
            side = current_desync_side
        })
        
        
        while #fs.choke_sync.release_history > 20 do
            table.remove(fs.choke_sync.release_history, 1)
        end
        
        
        if #fs.choke_sync.release_history >= 3 then
            local sum = 0
            for _, entry in ipairs(fs.choke_sync.release_history) do
                sum = sum + entry.choke_length
            end
            fs.choke_sync.avg_choke_length = sum / #fs.choke_sync.release_history
        end
    end
    
    fs.choke_sync.last_choke_count = current_choke
    
    
    local should_flip = false
    local new_side = current_desync_side
    
    if fs.choke_sync.flip_on_release then
        
        local ticks_since_release = tick - fs.choke_sync.release_tick
        
        if ticks_since_release >= 0 and ticks_since_release < fs.choke_sync.flip_duration_ticks then
            
            should_flip = true
            new_side = -fs.choke_sync.pre_release_side
        elseif ticks_since_release >= fs.choke_sync.flip_duration_ticks then
            
            fs.choke_sync.choke_release_detected = false
        end
    end
    
    
    if #fs.choke_sync.release_history >= 3 and fs.choke_sync.avg_choke_length > 0 then
        local expected_release_in = fs.choke_sync.avg_choke_length - current_choke
        
        
        if expected_release_in > 0 and expected_release_in <= 2 then
            fs.output.should_flip_desync = true
        end
    end
    
    fs.output.should_flip_desync = should_flip
    
    return new_side, should_flip
end


local function calculate_fakelag_pattern(cmd)
    local fs = tbl.fakelag_system
    local now = globals.realtime()
    local tick = cmd.command_number
    
    
    local time_since_change = now - fs.pattern.last_pattern_change
    
    if time_since_change >= fs.pattern.pattern_change_interval then
        fs.pattern.last_pattern_change = now
        
        
        local pattern_names = {}
        local weights = {}
        local total_weight = 0
        
        for name, weight in pairs(fs.pattern.pattern_weights) do
            table.insert(pattern_names, name)
            table.insert(weights, weight)
            total_weight = total_weight + weight
        end
        
        
        local rand = math.random() * total_weight
        local cumulative = 0
        local selected = "default"
        
        for i, name in ipairs(pattern_names) do
            cumulative = cumulative + weights[i]
            if rand <= cumulative then
                selected = name
                break
            end
        end
        
        
        if selected == fs.pattern.current_pattern and #pattern_names > 1 then
            local idx = math.random(1, #pattern_names)
            selected = pattern_names[idx]
        end
        
        fs.pattern.current_pattern = selected
        fs.pattern.pattern_index = 0
        fs.pattern.pattern_tick = tick
        
        
        fs.pattern.pattern_change_interval = 1.5 + math.random() * 2.0
        
        
        fs.pattern.variation_seed = math.random(1, 100)
    end
    
    
    local pattern = fs.pattern.patterns[fs.pattern.current_pattern]
    if not pattern then
        pattern = fs.pattern.patterns.default
    end
    
    
    local ticks_in_pattern = tick - fs.pattern.pattern_tick
    fs.pattern.pattern_index = (ticks_in_pattern % #pattern) + 1
    
    local base_choke = pattern[fs.pattern.pattern_index]
    
    
    local micro_variation = 0
    
    
    if tick % 7 == 0 then
        micro_variation = client.random_int(-1, 1)
    end
    
    
    if fs.pattern.variation_seed > 70 then
        
        if tick % 11 == 0 then
            micro_variation = micro_variation + 1
        end
    elseif fs.pattern.variation_seed < 30 then
        
        if tick % 13 == 0 then
            micro_variation = micro_variation - 1
        end
    end
    
    local final_choke = func.fclamp(base_choke + micro_variation, 1, 14)
    
    fs.output.pattern_name = fs.pattern.current_pattern
    
    return final_choke
end


local function calculate_exploit_aware_fakelag(cmd, base_choke)
    local fs = tbl.fakelag_system
    local tick = cmd.command_number
    
    
    local dt_enabled = ui.get(menu_refs["doubletap"][1]) and ui.get(menu_refs["doubletap"][2])
    local hs_enabled = ui.get(menu_refs["hideshots"][1]) and ui.get(menu_refs["hideshots"][2])
    
    fs.exploit.dt_active = dt_enabled
    fs.exploit.hs_active = hs_enabled
    
    
    local is_attacking = bit.band(cmd.in_attack or 0, 1) == 1
    
    
    if is_attacking and tick > fs.exploit.last_shot_tick + 2 then
        fs.exploit.last_shot_tick = tick
        fs.exploit.exploit_phase = "shooting"
        fs.exploit.phase_start_tick = tick
    end
    
    
    local ticks_since_shot = tick - fs.exploit.last_shot_tick
    local ticks_in_phase = tick - fs.exploit.phase_start_tick
    
    if fs.exploit.exploit_phase == "shooting" then
        if ticks_since_shot > 2 then
            fs.exploit.exploit_phase = "post_shot"
            fs.exploit.phase_start_tick = tick
        end
    elseif fs.exploit.exploit_phase == "post_shot" then
        if dt_enabled then
            
            if ticks_in_phase > 4 then
                fs.exploit.exploit_phase = "recharging"
                fs.exploit.phase_start_tick = tick
            end
        elseif hs_enabled then
            
            if ticks_in_phase > 8 then
                fs.exploit.exploit_phase = "idle"
                fs.exploit.phase_start_tick = tick
            end
        else
            if ticks_in_phase > 3 then
                fs.exploit.exploit_phase = "idle"
                fs.exploit.phase_start_tick = tick
            end
        end
    elseif fs.exploit.exploit_phase == "recharging" then
        
        if ticks_in_phase > 16 then
            fs.exploit.exploit_phase = "idle"
            fs.exploit.phase_start_tick = tick
        end
    end
    
    
    local recommended_choke = base_choke
    local exploit_override = false
    
    if dt_enabled then
        
        if fs.exploit.exploit_phase == "shooting" then
            
            recommended_choke = fs.exploit.dt_fakelag.post_shot_choke
            exploit_override = true
        elseif fs.exploit.exploit_phase == "post_shot" then
            
            recommended_choke = math.min(base_choke, 4)
            exploit_override = true
        elseif fs.exploit.exploit_phase == "recharging" then
            
            recommended_choke = fs.exploit.dt_fakelag.recharge_choke
            exploit_override = true
        else
            
            recommended_choke = math.max(base_choke, 8)
        end
        
    elseif hs_enabled then
        
        if fs.exploit.exploit_phase == "shooting" or fs.exploit.exploit_phase == "post_shot" then
            
            recommended_choke = fs.exploit.hs_fakelag.post_shot_choke
            exploit_override = true
        else
            
            recommended_choke = fs.exploit.hs_fakelag.pre_shot_choke
            exploit_override = true
        end
    end
    
    
    if tbl.breaklc and tbl.breaklc.breaking then
        fs.exploit.defensive_active = true
        
        recommended_choke = 14
        exploit_override = true
    else
        fs.exploit.defensive_active = false
    end
    
    fs.output.recommended_choke = recommended_choke
    fs.output.exploit_override = exploit_override
    
    return recommended_choke, exploit_override
end


local function apply_fakelag_integration(cmd, current_desync_side)
    local fs = tbl.fakelag_system
    
    
    local pattern_choke = calculate_fakelag_pattern(cmd)
    
    
    local exploit_choke, exploit_override = calculate_exploit_aware_fakelag(cmd, pattern_choke)
    
    
    local new_desync_side, should_flip = handle_choke_sync_desync(cmd, current_desync_side)
    
    
    local final_choke = exploit_override and exploit_choke or pattern_choke
    
    
    final_choke = func.fclamp(final_choke, 0, 14)
    
    
    fs.output.recommended_choke = final_choke
    fs.output.should_flip_desync = should_flip
    
    return final_choke, new_desync_side, should_flip
end


local function set_choke_sync_enabled(enabled)
    tbl.fakelag_system.choke_sync.flip_on_release = enabled
end

local function set_fakelag_pattern(pattern_name)
    if tbl.fakelag_system.pattern.patterns[pattern_name] then
        tbl.fakelag_system.pattern.current_pattern = pattern_name
        tbl.fakelag_system.pattern.last_pattern_change = globals.realtime()
    end
end

local function add_custom_fakelag_pattern(name, choke_values)
    if type(choke_values) == "table" and #choke_values > 0 then
        tbl.fakelag_system.pattern.patterns[name] = choke_values
        tbl.fakelag_system.pattern.pattern_weights[name] = 1.0
    end
end

local function set_pattern_change_interval(min_interval, max_interval)
    
    tbl.fakelag_system.pattern.pattern_change_interval = min_interval + math.random() * (max_interval - min_interval)
end


tbl.apply_fakelag_integration = apply_fakelag_integration
tbl.set_choke_sync_enabled = set_choke_sync_enabled
tbl.set_fakelag_pattern = set_fakelag_pattern
tbl.add_custom_fakelag_pattern = add_custom_fakelag_pattern
tbl.set_pattern_change_interval = set_pattern_change_interval
tbl.handle_choke_sync_desync = handle_choke_sync_desync
tbl.calculate_fakelag_pattern = calculate_fakelag_pattern
tbl.calculate_exploit_aware_fakelag = calculate_exploit_aware_fakelag

tbl.exploit_aa_system = {
    
    dt_sync = {
        enabled = true,
        last_dt_shot_tick = 0,
        pre_dt_side = 0,
        post_dt_side = 0,
        flip_on_dt = true,
        dt_flip_duration = 6,
        dt_detected = false,
        dt_charge_level = 0,
        shot_count_this_burst = 0,
        last_charge_check = 0
    },
    
    
    hideshot = {
        enabled = true,
        hs_active = false,
        hs_start_tick = 0,
        pre_hs_side = 0,
        hs_flip_mode = "opposite", 
        hs_desync_mult = 1.15, 
        choke_buildup = 0,
        last_hs_state = false
    },
    
    
    defensive = {
        enabled = true,
        is_recharging = false,
        recharge_start_tick = 0,
        recharge_ticks_remaining = 0,
        max_recharge_ticks = 14,
        
        
        recharge_aa_mode = "protective", 
        recharge_desync_mult = 1.20, 
        recharge_jitter_mult = 0.7, 
        
        
        optimal_shoot_window = false,
        ticks_until_charged = 0,
        last_exploit_use = 0,
        
        
        exploit_type = "none", 
        was_charged = false,
        charge_history = {}
    },
    
    
    output = {
        should_flip = false,
        desync_multiplier = 1.0,
        jitter_multiplier = 1.0,
        recommended_side = 0,
        exploit_state = "idle",
        priority_override = false
    }
}


local function handle_dt_sync_aa(cmd, current_side)
    local es = tbl.exploit_aa_system
    local dt = es.dt_sync
    local tick = cmd.command_number
    
    
    local dt_enabled = ui.get(menu_refs["doubletap"][1]) and ui.get(menu_refs["doubletap"][2])
    
    if not dt_enabled then
        dt.dt_detected = false
        dt.shot_count_this_burst = 0
        return current_side, false
    end
    
    
    local is_attacking = bit.band(cmd.in_attack or 0, 1) == 1
    
    
    if is_attacking then
        local ticks_since_last = tick - dt.last_dt_shot_tick
        
        if ticks_since_last <= 2 then
            
            dt.shot_count_this_burst = dt.shot_count_this_burst + 1
            dt.dt_detected = true
        else
            
            dt.shot_count_this_burst = 1
            dt.pre_dt_side = current_side
        end
        
        dt.last_dt_shot_tick = tick
        
        
        if dt.flip_on_dt and dt.dt_detected then
            dt.post_dt_side = -dt.pre_dt_side
            
            return dt.post_dt_side, true
        end
    end
    
    
    local ticks_since_dt = tick - dt.last_dt_shot_tick
    
    if dt.dt_detected and ticks_since_dt > 0 and ticks_since_dt < dt.dt_flip_duration then
        
        return dt.post_dt_side, true
    elseif ticks_since_dt >= dt.dt_flip_duration then
        
        dt.dt_detected = false
        dt.shot_count_this_burst = 0
    end
    
    return current_side, false
end


local function handle_hideshot_desync(cmd, current_side, current_desync)
    local es = tbl.exploit_aa_system
    local hs = es.hideshot
    local tick = cmd.command_number
    
    
    local hs_enabled = ui.get(menu_refs["hideshots"][1]) and ui.get(menu_refs["hideshots"][2])
    
    
    local hs_state_changed = hs_enabled ~= hs.last_hs_state
    hs.last_hs_state = hs_enabled
    
    if not hs_enabled then
        hs.hs_active = false
        hs.choke_buildup = 0
        return current_side, current_desync, false
    end
    
    
    local current_choke = cmd.chokedcommands or 0
    
    
    if current_choke > hs.choke_buildup then
        if not hs.hs_active then
            
            hs.hs_active = true
            hs.hs_start_tick = tick
            hs.pre_hs_side = current_side
        end
        hs.choke_buildup = current_choke
    elseif current_choke < hs.choke_buildup and hs.choke_buildup >= 8 then
        
        hs.hs_active = false
        hs.choke_buildup = 0
    end
    
    local new_side = current_side
    local new_desync = current_desync
    local modified = false
    
    if hs.hs_active and hs.enabled then
        modified = true
        
        
        if hs.hs_flip_mode == "opposite" then
            
            new_side = -hs.pre_hs_side
            
        elseif hs.hs_flip_mode == "random" then
            
            if tick % 4 == 0 then
                new_side = client.random_int(0, 1) == 0 and 1 or -1
            end
            
        elseif hs.hs_flip_mode == "jitter" then
            
            new_side = (tick % 2 == 0) and 1 or -1
        end
        
        
        new_desync = current_desync * hs.hs_desync_mult
        new_desync = func.fclamp(new_desync, 20, 60)
    end
    
    return new_side, new_desync, modified
end


local function handle_defensive_recharge(cmd, current_side, current_desync, current_jitter)
    local es = tbl.exploit_aa_system
    local def = es.defensive
    local tick = cmd.command_number
    local now = globals.realtime()
    
    
    local dt_enabled = ui.get(menu_refs["doubletap"][1]) and ui.get(menu_refs["doubletap"][2])
    local hs_enabled = ui.get(menu_refs["hideshots"][1]) and ui.get(menu_refs["hideshots"][2])
    
    
    if dt_enabled then
        def.exploit_type = "dt"
    elseif hs_enabled then
        def.exploit_type = "hs"
    else
        def.exploit_type = "none"
        def.is_recharging = false
        def.optimal_shoot_window = true
        return current_side, current_desync, current_jitter, false
    end
    
    
    local is_attacking = bit.band(cmd.in_attack or 0, 1) == 1
    
    if is_attacking then
        def.last_exploit_use = tick
        def.was_charged = false
        def.is_recharging = true
        def.recharge_start_tick = tick
        def.recharge_ticks_remaining = def.max_recharge_ticks
        
        
        table.insert(def.charge_history, {
            tick = tick,
            exploit_type = def.exploit_type,
            time = now
        })
        
        
        while #def.charge_history > 20 do
            table.remove(def.charge_history, 1)
        end
    end
    
    
    if def.is_recharging then
        local ticks_since_shot = tick - def.recharge_start_tick
        def.recharge_ticks_remaining = math.max(0, def.max_recharge_ticks - ticks_since_shot)
        def.ticks_until_charged = def.recharge_ticks_remaining
        
        if def.recharge_ticks_remaining <= 0 then
            def.is_recharging = false
            def.was_charged = true
            def.optimal_shoot_window = true
        else
            def.optimal_shoot_window = false
        end
    else
        def.ticks_until_charged = 0
        def.optimal_shoot_window = true
    end
    
    
    local new_side = current_side
    local new_desync = current_desync
    local new_jitter = current_jitter
    local modified = false
    
    if def.is_recharging and def.enabled then
        modified = true
        
        
        local recharge_progress = 1 - (def.recharge_ticks_remaining / def.max_recharge_ticks)
        
        if def.recharge_aa_mode == "protective" then
            
            
            new_desync = current_desync * def.recharge_desync_mult
            new_jitter = current_jitter * def.recharge_jitter_mult
            
            
            
            if def.recharge_ticks_remaining > def.max_recharge_ticks * 0.7 then
                
                new_side = -current_side
            end
            
        elseif def.recharge_aa_mode == "aggressive" then
            
            
            new_jitter = current_jitter * (1.2 + recharge_progress * 0.3)
            
            
            if tick % 6 == 0 then
                new_side = -current_side
            end
            
            
            local desync_variation = math.sin(recharge_progress * math.pi * 2) * 10
            new_desync = current_desync + desync_variation
            
        elseif def.recharge_aa_mode == "random" then
            
            if tick % 4 == 0 then
                new_side = client.random_int(0, 1) == 0 and 1 or -1
            end
            
            new_desync = current_desync * (0.8 + math.random() * 0.4)
            new_jitter = current_jitter * (0.7 + math.random() * 0.6)
        end
        
        
        new_desync = func.fclamp(new_desync, 20, 60)
        new_jitter = func.fclamp(new_jitter, -60, 60)
        
        
        if def.recharge_ticks_remaining <= 3 then
            
            
            new_jitter = current_jitter * 0.5
            new_desync = 60
        end
    end
    
    return new_side, new_desync, new_jitter, modified
end


local function apply_exploit_aa_integration(cmd, current_side, current_desync, current_jitter)
    local es = tbl.exploit_aa_system
    
    local final_side = current_side
    local final_desync = current_desync
    local final_jitter = current_jitter
    local any_modified = false
    
    
    local dt_side, dt_modified = handle_dt_sync_aa(cmd, final_side)
    if dt_modified then
        final_side = dt_side
        any_modified = true
        es.output.exploit_state = "dt_active"
        es.output.priority_override = true
    end
    
    
    if not dt_modified then
        local hs_side, hs_desync, hs_modified = handle_hideshot_desync(cmd, final_side, final_desync)
        if hs_modified then
            final_side = hs_side
            final_desync = hs_desync
            any_modified = true
            es.output.exploit_state = "hs_active"
        end
    end
    
    
    local def_side, def_desync, def_jitter, def_modified = handle_defensive_recharge(
        cmd, final_side, final_desync, final_jitter
    )
    if def_modified then
        
        if not dt_modified then
            final_side = def_side
        end
        final_desync = def_desync
        final_jitter = def_jitter
        any_modified = true
        
        if es.output.exploit_state == "idle" then
            es.output.exploit_state = "recharging"
        end
    end
    
    
    es.output.should_flip = any_modified
    es.output.desync_multiplier = final_desync / math.max(1, current_desync)
    es.output.jitter_multiplier = math.abs(final_jitter) / math.max(1, math.abs(current_jitter))
    es.output.recommended_side = final_side
    
    if not any_modified then
        es.output.exploit_state = "idle"
        es.output.priority_override = false
    end
    
    return final_side, final_desync, final_jitter, any_modified
end


local function set_dt_sync_enabled(enabled)
    tbl.exploit_aa_system.dt_sync.enabled = enabled
end

local function set_dt_flip_duration(ticks)
    tbl.exploit_aa_system.dt_sync.dt_flip_duration = func.fclamp(ticks, 2, 14)
end

local function set_hideshot_flip_mode(mode)
    if mode == "opposite" or mode == "random" or mode == "jitter" then
        tbl.exploit_aa_system.hideshot.hs_flip_mode = mode
    end
end

local function set_hideshot_desync_mult(mult)
    tbl.exploit_aa_system.hideshot.hs_desync_mult = func.fclamp(mult, 1.0, 1.5)
end

local function set_defensive_recharge_mode(mode)
    if mode == "protective" or mode == "aggressive" or mode == "random" then
        tbl.exploit_aa_system.defensive.recharge_aa_mode = mode
    end
end

local function set_defensive_desync_mult(mult)
    tbl.exploit_aa_system.defensive.recharge_desync_mult = func.fclamp(mult, 1.0, 1.5)
end

local function is_exploit_charged()
    return tbl.exploit_aa_system.defensive.optimal_shoot_window
end

local function get_ticks_until_charged()
    return tbl.exploit_aa_system.defensive.ticks_until_charged
end


tbl.apply_exploit_aa_integration = apply_exploit_aa_integration
tbl.set_dt_sync_enabled = set_dt_sync_enabled
tbl.set_dt_flip_duration = set_dt_flip_duration
tbl.set_hideshot_flip_mode = set_hideshot_flip_mode
tbl.set_hideshot_desync_mult = set_hideshot_desync_mult
tbl.set_defensive_recharge_mode = set_defensive_recharge_mode
tbl.set_defensive_desync_mult = set_defensive_desync_mult
tbl.is_exploit_charged = is_exploit_charged
tbl.get_ticks_until_charged = get_ticks_until_charged
tbl.handle_dt_sync_aa = handle_dt_sync_aa
tbl.handle_hideshot_desync = handle_hideshot_desync
tbl.handle_defensive_recharge = handle_defensive_recharge

tbl.landing_aa_system = {
    
    detection = {
        was_in_air = false,
        landing_tick = 0,
        landing_velocity = 0,
        landing_detected = false,
        landing_type = "normal", 
        pre_land_state = "global"
    },
    
    
    behavior = {
        active_until_tick = 0,
        duration_ticks = 12,  
        
        
        landing_desync_mult = 1.25,  
        landing_jitter_mult = 0.6,   
        landing_yaw_offset = 0,
        
        
        hard_landing = {
            desync_mult = 1.35,
            jitter_mult = 0.4,
            duration = 16,
            velocity_threshold = -400
        },
        normal_landing = {
            desync_mult = 1.25,
            jitter_mult = 0.6,
            duration = 12,
            velocity_threshold = -250
        },
        soft_landing = {
            desync_mult = 1.15,
            jitter_mult = 0.75,
            duration = 8,
            velocity_threshold = -150
        }
    },
    
    
    prediction = {
        will_land_soon = false,
        ticks_until_land = 0,
        predicted_impact_velocity = 0,
        pre_land_adjustment = false
    },
    
    
    velocity_history = {},
    
    
    output = {
        is_landing = false,
        landing_type = "normal",
        desync_multiplier = 1.0,
        jitter_multiplier = 1.0,
        yaw_offset = 0,
        confidence = 1.0
    }
}


local function detect_landing(cmd, lp)
    local ls = tbl.landing_aa_system
    local tick = cmd.command_number
    
    if not lp then return false end
    
    
    local flags = entity.get_prop(lp, "m_fFlags") or 0
    local on_ground = bit.band(flags, 1) == 1
    local vx, vy, vz = entity.get_prop(lp, "m_vecVelocity")
    
    if not vx then return false end
    
    local vertical_velocity = vz or 0
    
    
    table.insert(ls.velocity_history, {
        tick = tick,
        vz = vertical_velocity,
        on_ground = on_ground
    })
    
    
    while #ls.velocity_history > 30 do
        table.remove(ls.velocity_history, 1)
    end
    
    
    local landing_detected = false
    local landing_type = "normal"
    
    if ls.detection.was_in_air and on_ground then
        
        landing_detected = true
        ls.detection.landing_tick = tick
        ls.detection.landing_velocity = vertical_velocity
        
        
        if vertical_velocity < ls.behavior.hard_landing.velocity_threshold then
            landing_type = "hard"
        elseif vertical_velocity < ls.behavior.normal_landing.velocity_threshold then
            landing_type = "normal"
        else
            landing_type = "soft"
        end
        
        ls.detection.landing_type = landing_type
        ls.detection.landing_detected = true
        
        
        local config = ls.behavior[landing_type .. "_landing"]
        ls.behavior.active_until_tick = tick + config.duration
        
    elseif not on_ground then
        
        ls.detection.landing_detected = false
    end
    
    
    ls.detection.was_in_air = not on_ground
    
    return landing_detected
end


local function predict_landing(lp)
    local ls = tbl.landing_aa_system
    
    if not lp then return false end
    
    local flags = entity.get_prop(lp, "m_fFlags") or 0
    local on_ground = bit.band(flags, 1) == 1
    
    
    if on_ground then
        ls.prediction.will_land_soon = false
        ls.prediction.ticks_until_land = 0
        return false
    end
    
    local vx, vy, vz = entity.get_prop(lp, "m_vecVelocity")
    if not vz then return false end
    
    local ox, oy, oz = entity.get_prop(lp, "m_vecOrigin")
    if not oz then return false end
    
    
    
    local gravity = 800
    local tickinterval = globals.tickinterval()
    
    
    
    local predicted_ticks = 0
    local predicted_vz = vz
    local predicted_oz = oz
    
    
    local ground_z = oz - 100  
    local trace_fraction, trace_entity = client.trace_line(
        lp, ox, oy, oz, ox, oy, oz - 1000
    )
    
    if trace_fraction then
        ground_z = oz - (1000 * trace_fraction)
    end
    
    
    local max_ticks = 50
    for i = 1, max_ticks do
        predicted_vz = predicted_vz - gravity * tickinterval
        predicted_oz = predicted_oz + predicted_vz * tickinterval
        
        if predicted_oz <= ground_z then
            predicted_ticks = i
            ls.prediction.predicted_impact_velocity = predicted_vz
            break
        end
    end
    
    ls.prediction.ticks_until_land = predicted_ticks
    
    
    if predicted_ticks > 0 and predicted_ticks <= 8 then
        ls.prediction.will_land_soon = true
        
        
        if ls.prediction.predicted_impact_velocity < -300 then
            ls.prediction.pre_land_adjustment = true
        else
            ls.prediction.pre_land_adjustment = false
        end
        
        return true
    end
    
    ls.prediction.will_land_soon = false
    ls.prediction.pre_land_adjustment = false
    return false
end


local function calculate_landing_aa(cmd, current_side, current_desync, current_jitter)
    local ls = tbl.landing_aa_system
    local tick = cmd.command_number
    
    local lp = entity.get_local_player()
    if not lp then return current_side, current_desync, current_jitter, false end
    
    
    local landing_now = detect_landing(cmd, lp)
    
    
    local landing_soon = predict_landing(lp)
    
    
    local landing_active = tick < ls.behavior.active_until_tick
    
    if not landing_active and not landing_soon then
        ls.output.is_landing = false
        return current_side, current_desync, current_jitter, false
    end
    
    local modified = false
    local new_side = current_side
    local new_desync = current_desync
    local new_jitter = current_jitter
    
    
    if landing_active then
        modified = true
        
        local landing_type = ls.detection.landing_type
        local config = ls.behavior[landing_type .. "_landing"]
        
        
        local ticks_since_land = tick - ls.detection.landing_tick
        local progress = ticks_since_land / config.duration
        
        
        local fade_factor = 1.0 - progress
        fade_factor = func.fclamp(fade_factor, 0, 1)
        
        
        local desync_mult = 1.0 + (config.desync_mult - 1.0) * fade_factor
        new_desync = current_desync * desync_mult
        
        
        local jitter_mult = 1.0 - (1.0 - config.jitter_mult) * fade_factor
        new_jitter = current_jitter * jitter_mult
        
        
        if landing_type == "hard" then
            
            if ticks_since_land < 8 then
                new_side = -current_side
            end
            
            
            ls.behavior.landing_yaw_offset = math.sin(ticks_since_land * 0.5) * 8
            
        elseif landing_type == "normal" then
            
            if ticks_since_land < 4 then
                new_side = -current_side
            end
            
            ls.behavior.landing_yaw_offset = 0
            
        elseif landing_type == "soft" then
            
            ls.behavior.landing_yaw_offset = 0
        end
        
        
        new_desync = func.fclamp(new_desync, 20, 60)
        new_jitter = func.fclamp(new_jitter, -60, 60)
        
        ls.output.is_landing = true
        ls.output.landing_type = landing_type
        ls.output.confidence = fade_factor
        
    elseif landing_soon and ls.prediction.pre_land_adjustment then
        
        modified = true
        
        
        local pre_land_mult = 1.0 + (ls.prediction.ticks_until_land / 8) * 0.15
        new_desync = current_desync * pre_land_mult
        
        
        new_jitter = current_jitter * 0.85
        
        new_desync = func.fclamp(new_desync, 20, 60)
        new_jitter = func.fclamp(new_jitter, -60, 60)
        
        ls.output.is_landing = false
        ls.output.confidence = 0.5
    end
    
    ls.output.desync_multiplier = new_desync / math.max(1, current_desync)
    ls.output.jitter_multiplier = math.abs(new_jitter) / math.max(1, math.abs(current_jitter))
    ls.output.yaw_offset = ls.behavior.landing_yaw_offset
    
    return new_side, new_desync, new_jitter, modified
end


local function set_landing_duration(landing_type, ticks)
    local key = landing_type .. "_landing"
    if tbl.landing_aa_system.behavior[key] then
        tbl.landing_aa_system.behavior[key].duration = func.fclamp(ticks, 4, 24)
    end
end

local function set_landing_desync_mult(landing_type, mult)
    local key = landing_type .. "_landing"
    if tbl.landing_aa_system.behavior[key] then
        tbl.landing_aa_system.behavior[key].desync_mult = func.fclamp(mult, 1.0, 2.0)
    end
end

local function set_landing_jitter_mult(landing_type, mult)
    local key = landing_type .. "_landing"
    if tbl.landing_aa_system.behavior[key] then
        tbl.landing_aa_system.behavior[key].jitter_mult = func.fclamp(mult, 0.3, 1.0)
    end
end


tbl.calculate_landing_aa = calculate_landing_aa
tbl.set_landing_duration = set_landing_duration
tbl.set_landing_desync_mult = set_landing_desync_mult
tbl.set_landing_jitter_mult = set_landing_jitter_mult
tbl.detect_landing = detect_landing
tbl.predict_landing = predict_landing
            do
                tbl.tickbase_override = tbl.tickbase_override or {
                    active = false,
                    mode = "adaptive",
                    value = nil,
                    teams = "both",
                    
                    
                    sv_maxunlag = 0.5,
                    sv_minupdaterate = 10,
                    sv_maxupdaterate = 128,
                    sv_client_min_interp_ratio = 1,
                    sv_client_max_interp_ratio = 2,
                    tickrate = 64,
                    max_rewind_ticks = 12,
                    
                    
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
                    
                    
                    runtime = {},
                    builder_val = nil,
                    until_tick = 0,
                    end_time = 0,
                    period = nil,
                    persist_key = "tb_override_v2",
                    
                    
                    stats = {
                        total_shots = 0,
                        hits_per_offset = {},
                        misses_per_offset = {},
                        optimal_ranges = {},
                        weapon_profiles = {}
                    }
                }
                
                local TB = tbl.tickbase_override
                
                
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
                
                
                local function get_network_context()
                    local latency = client.latency()
                    local lp = entity.get_local_player()
                    if not lp then return TB.context end
                    
                    TB.context.ping = latency * 1000
                    
                    
                    local net_channel = client.latency()
                    TB.context.loss = 0 
                    TB.context.choke = 0
                    
                    
                    local vx, vy, vz = entity.get_prop(lp, "m_vecVelocity")
                    if vx then
                        TB.context.local_velocity = math.sqrt(vx*vx + vy*vy)
                    end
                    
                    
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
                
                
                local function calculate_adaptive_offset(base_value, variability)
                    local ctx = get_network_context()
                    local lagcomp = get_lagcomp_window()
                    
                    
                    local base = math.max(0, math.min(22, math.floor(tonumber(base_value) or 0)))
                    
                    
                    local var_pct = math.max(0, math.min(100, tonumber(variability) or 0)) / 100
                    
                    
                    local adjustments = {
                        ping = 0,
                        distance = 0,
                        velocity = 0,
                        weapon = 0,
                        tickrate = 0
                    }
                    
                    
                    if ctx.ping > 80 then
                        adjustments.ping = -2
                    elseif ctx.ping > 50 then
                        adjustments.ping = -1
                    elseif ctx.ping < 20 then
                        adjustments.ping = 1
                    end
                    
                    
                    if ctx.enemy_distance < 300 then
                        adjustments.distance = 2
                    elseif ctx.enemy_distance > 800 then
                        adjustments.distance = -1
                    end
                    
                    
                    if ctx.enemy_velocity > 200 then
                        adjustments.velocity = -1
                    elseif ctx.enemy_velocity < 50 then
                        adjustments.velocity = 1
                    end
                    
                    
                    if ctx.weapon_type == "awp" then
                        adjustments.weapon = 3 
                    elseif ctx.weapon_type == "scout" then
                        adjustments.weapon = 2
                    elseif ctx.weapon_type == "rifle" then
                        adjustments.weapon = 1
                    end
                    
                    
                    if lagcomp.tickrate == 128 then
                        adjustments.tickrate = 2
                    end
                    
                    
                    local total_adjustment = 0
                    for _, adj in pairs(adjustments) do
                        total_adjustment = total_adjustment + adj
                    end
                    
                    
                    local perf_key = string.format("%s_%d", ctx.weapon_type, math.floor(ctx.enemy_distance / 100))
                    local learned_offset = TB.adaptive.performance_map[perf_key] or 0
                    total_adjustment = total_adjustment + learned_offset
                    
                    
                    local adjusted_base = base + total_adjustment
                    
                    
                    local variance_range = math.floor(adjusted_base * var_pct)
                    
                    
                    local variance = 0
                    if variance_range > 0 then
                        
                        local r1 = client.random_int(-variance_range, variance_range)
                        local r2 = client.random_int(-variance_range, variance_range)
                        local r3 = client.random_int(-variance_range, variance_range)
                        variance = math.floor((r1 + r2 + r3) / 3)
                    end
                    
                    local final_offset = adjusted_base + variance
                    
                    
                    
                    local max_safe = math.min(22, lagcomp.backtrack_ticks - 2)
                    final_offset = math.max(0, math.min(max_safe, final_offset))
                    
                    
                    table.insert(TB.adaptive.variance_history, {
                        offset = final_offset,
                        base = base,
                        variance = variance,
                        context = ctx,
                        time = globals.realtime()
                    })
                    
                    
                    while #TB.adaptive.variance_history > 100 do
                        table.remove(TB.adaptive.variance_history, 1)
                    end
                    
                    return final_offset
                end
                
                
                function TB.learn_from_shot(offset, hit, context)
                    local perf_key = string.format("%s_%d", context.weapon_type, math.floor(context.enemy_distance / 100))
                    
                    
                    TB.stats.hits_per_offset[offset] = (TB.stats.hits_per_offset[offset] or 0) + (hit and 1 or 0)
                    TB.stats.misses_per_offset[offset] = (TB.stats.misses_per_offset[offset] or 0) + (hit and 0 or 1)
                    
                    
                    local perf = TB.adaptive.performance_map[perf_key] or 0
                    local adjustment = 0
                    
                    if hit then
                        
                        adjustment = TB.adaptive.learning_rate * 0.5
                    else
                        
                        adjustment = -TB.adaptive.learning_rate
                    end
                    
                    
                    TB.adaptive.performance_map[perf_key] = perf * 0.9 + adjustment
                    
                    
                    TB.adaptive.performance_map[perf_key] = math.max(-5, math.min(5, TB.adaptive.performance_map[perf_key]))
                end
                
                
                function TB.get_optimal_offset(base, variability)
                    
                    if globals.tickcount() % 64 == 0 then
                        update_server_tickbase_info()
                    end
                    
                    return calculate_adaptive_offset(base, variability)
                end
                
                
                function TB.should_apply_for_command(arg, state, team)
                    if not TB.active or not TB.value then
                        return false, nil
                    end
                    
                    local base_tick = TB.value
                    local variability = 0
                    
                    
                    local ok_v, global_var = pcall(ui.get, 
                        (menu and menu["anti aimbot"] and menu["anti aimbot"]["builder"] and 
                        menu["anti aimbot"]["builder"]["tbvariability"]) or nil)
                    if ok_v and tonumber(global_var) then
                        variability = tonumber(global_var)
                    end
                    
                    
                    local optimal_tick = TB.get_optimal_offset(base_tick, variability)
                    
                    
                    TB._last_offset = optimal_tick
                    TB._last_context = get_network_context()
                    
                    return true, optimal_tick
                end
                
                
                function TB.restore()
                    TB.active = false
                    TB.runtime = {}
                    TB.builder_val = nil
                    TB.value = nil
                    
                    return true
                end
                
                
                function TB.activate(value, opts)
                    opts = opts or {}
                    
                    TB.value = math.max(0, math.min(22, math.floor(value)))
                    TB.teams = opts.teams or "both"
                    TB.mode = opts.mode or "adaptive"
                    TB.active = true
                    
                    
                    update_server_tickbase_info()
                    
                    return true
                end
                
                
                client.set_event_callback("aim_fire", function(e)
                    if TB.active and TB._last_offset and TB._last_context then
                        
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
                    
                    
                    timing = {
                        min_interval = 0.15,
                        max_interval = 0.65,
                        jitter_factor = 0.25,
                        pattern_variance = 0.35,
                        hit_acceleration = 0.85,
                        miss_deceleration = 1.20,
                        confidence_decay_rate = 0.015,
                        lock_max_duration = 4.0,
                        unlock_threshold = 0.45,
                        use_entropy_pool = true,
                        entropy_sources = {"time", "velocity", "distance", "latency"},
                        micro_jitter = true,
                        micro_jitter_range = 0.05
                    },
                    
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

                
                
                

local function calculate_randomized_interval(base_interval, ab_data, context)
    local config = AB_CONFIG.timing
    local interval = base_interval or 0.3
    
    
    local variance = config.jitter_factor * interval
    local primary_random = (math.random() - 0.5) * 2 * variance
    interval = interval + primary_random
    
    
    if math.random() < config.pattern_variance then
        local pattern_shift = math.random() < 0.5 and 0.7 or 1.4
        interval = interval * pattern_shift
    end
    
    
    if config.use_entropy_pool then
        local entropy = 0
        local entropy_count = 0
        
        for _, source in ipairs(config.entropy_sources) do
            if source == "time" then
                local rt = globals.realtime()
                entropy = entropy + (rt - math.floor(rt)) * 1000
                entropy_count = entropy_count + 1
            elseif source == "latency" then
                local latency = client.latency() * 1000
                entropy = entropy + (latency % 25)
                entropy_count = entropy_count + 1
            end
        end
        
        if entropy_count > 0 then
            entropy = (entropy / entropy_count) % 1.0
            local entropy_shift = (entropy - 0.5) * config.jitter_factor * 2
            interval = interval * (1 + entropy_shift)
        end
    end
    
    
    if config.micro_jitter then
        local micro = (math.random() - 0.5) * 2 * config.micro_jitter_range
        interval = interval + micro
    end
    
    interval = func.fclamp(interval, config.min_interval, config.max_interval)
    return interval
end


local function apply_confidence_decay(ab_data)
    if not ab_data or not ab_data.locked then return end
    
    local config = AB_CONFIG.timing
    local now = globals.realtime()
    
    if not ab_data.decay then
        ab_data.decay = {
            start_time = now,
            start_confidence = ab_data.confidence or 1.0,
            last_update = now,
            decay_curve = "exponential"
        }
    end
    
    local decay = ab_data.decay
    local time_locked = now - decay.start_time
    local dt = now - decay.last_update
    
    
    local base_decay = config.confidence_decay_rate * dt
    local exp_factor = 1 + (time_locked / config.lock_max_duration)
    local decay_amount = base_decay * exp_factor
    
    ab_data.confidence = math.max(0, (ab_data.confidence or 1.0) - decay_amount)
    
    
    if ab_data.confidence < config.unlock_threshold or time_locked > config.lock_max_duration then
        ab_data.locked = false
        ab_data.decay = nil
    end
    
    decay.last_update = now
end


local function on_local_player_hit(attacker_ent)
    if not attacker_ent then return end
    
    local key = tostring(entity.get_steam64(attacker_ent) or attacker_ent)
    local now = globals.realtime()
    local tick = globals.tickcount()
    
    tbl.antiaim.ab.last_hit[key] = tbl.antiaim.ab.last_hit[key] or 0
    tbl.antiaim.ab.hit_count[key] = tbl.antiaim.ab.hit_count[key] or 0
    tbl.antiaim.ab.method[key] = tbl.antiaim.ab.method[key] or "decrease"
    
    
    local ab_data = tbl.antiaim.ab
    local randomized_cooldown = calculate_randomized_interval(
        AB_CONFIG.cooldown_ticks * globals.tickinterval(),
        ab_data,
        {}
    )
    local cooldown_ticks = math.floor(randomized_cooldown / globals.tickinterval())
    
    if tick - ab_data.last_hit[key] < cooldown_ticks then return end
    
    
    if (now - (ab_data.time[key] or 0)) > AB_CONFIG.window_seconds then
        ab_data.hit_count[key] = 1
    else
        ab_data.hit_count[key] = ab_data.hit_count[key] + 1
    end
    
    ab_data.last_hit[key] = tick
    ab_data.time[key] = now
    
    
    if ab_data.hit_count[key] >= AB_CONFIG.hits_to_cycle then
        ab_data.method[key] = cycle_method(key)
        ab_data.hit_count[key] = 0
    end
    
    
    if ab_data.hit_count[key] >= AB_CONFIG.hits_to_lock then
        ab_data.locked[key] = true
        ab_data.confidence = 0.95
    end
    
    local base = get_current_aa_values()
    if not base then return end
    
    local method = ab_data.method[key]
    local adjusted = apply_method_adjustment(method, base)
    
    ab_data.adjustments[key] = {
        values = adjusted,
        method = method,
        expires = tick + AB_CONFIG.hold_ticks,
        base = base,
        confidence = ab_data.confidence or 0.85
    }
    
    tbl.antiaim.log[key] = tbl.antiaim.log[key] or {}
    tbl.antiaim.log[key].method = method
    tbl.antiaim.log[key].last = now
    tbl.antiaim.log[key].locked = ab_data.locked[key] or false
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
                    
                    for key, ab_data in pairs(tbl.antiaim.ab.adjustments or {}) do
                        if ab_data.locked and ab_data.confidence then
                            apply_confidence_decay(ab_data)
                        end
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
                            
                            old_origin = nil,
                            old_simtime_ticks = nil,
                            max_tickbase = 0,
                            defensive_left = 0,
                            breaking = false,
                            shift_rewind = false,
                            active = false,
                            
                            
                            teleport_sq_threshold = 4096 * 4096,  
                            hold_ticks = 2,
                            offset = 6000,
                            
                            
                            sv_maxunlag = 0.5,
                            sv_lagcompensation_teleport_dist = 64,
                            max_rewind_ticks = 12,
                            
                            
                            last_velocity = vector(0, 0, 0),
                            velocity_changes = {},
                            simtime_deltas = {},
                            exploitation_window = 0,
                            
                            
                            _applied = nil,
                            _restore_tick = nil,
                            _restore_cb = nil,
                            _run_cmd = nil
                        }

                        
                        local function update_server_lagcomp_info()
                            local ok_unlag, maxunlag = pcall(function() return cvar.sv_maxunlag:get_float() end)
                            local ok_teleport, teleport_dist = pcall(function() return cvar.sv_lagcompensation_teleport_dist:get_float() end)
                            
                            tbl.breaklc.sv_maxunlag = (ok_unlag and maxunlag) or 0.5
                            tbl.breaklc.sv_lagcompensation_teleport_dist = (ok_teleport and teleport_dist) or 64
                            tbl.breaklc.max_rewind_ticks = math.floor(tbl.breaklc.sv_maxunlag / globals.tickinterval())
                        end

                        
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

                                
                                table.insert(tbl.breaklc.simtime_deltas, {delta = delta, time = globals.realtime()})
                                if #tbl.breaklc.simtime_deltas > 20 then
                                    table.remove(tbl.breaklc.simtime_deltas, 1)
                                end

                                
                                if delta < 0 or (delta >= 0 and delta <= tbl.breaklc.max_rewind_ticks) then
                                    local prev_origin = tbl.breaklc.old_origin or origin
                                    local displacement = (origin - prev_origin):length()
                                    
                                    
                                    local teleport_threshold = tbl.breaklc.sv_lagcompensation_teleport_dist
                                    local tele = displacement > teleport_threshold
                                    
                                    
                                    local vx, vy, vz = entity.get_prop(lp, "m_vecVelocity")
                                    if vx then
                                        local velocity = vector(vx, vy, vz)
                                        local expected_displacement = tbl.breaklc.last_velocity:length() * globals.tickinterval() * math.abs(delta)
                                        
                                        
                                        if displacement > expected_displacement * 2 and displacement > 32 then
                                            tele = true
                                        end
                                        
                                        tbl.breaklc.last_velocity = velocity
                                        
                                        
                                        table.insert(tbl.breaklc.velocity_changes, {
                                            vel = velocity:length(),
                                            time = globals.realtime()
                                        })
                                        if #tbl.breaklc.velocity_changes > 15 then
                                            table.remove(tbl.breaklc.velocity_changes, 1)
                                        end
                                    end
                                    
                                    
                                    tbl.breaklc.breaking = tele or (delta < 0) or (delta > 0 and delta >= tbl.breaklc.max_rewind_ticks - 2)
                                    
                                    
                                    if tbl.breaklc.breaking and delta < 0 then
                                        tbl.breaklc.exploitation_window = math.min(14, math.abs(delta))
                                    end
                                end
                            end

                            tbl.breaklc.old_origin = origin
                            tbl.breaklc.old_simtime_ticks = simticks
                        end

                        
                        local function _luasense_update_defensive(e_cmd)
                            local lp = entity.get_local_player()
                            if not lp then return end
                            local tb = entity.get_prop(lp, "m_nTickBase") or 0

                            
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
                                
                                local rewind_amount = tbl.breaklc.max_tickbase - tb
                                
                                
                                local left = math.max(0, math.min(14, rewind_amount - 1))
                                tbl.breaklc.defensive_left = left
                                
                                
                                tbl.breaklc.exploitation_window = left
                                
                                
                                tbl.breaklc.breaking = left > 0
                                
                                
                                local dt_enabled = ui.get(tbl.refs.dt[1]) and ui.get(tbl.refs.dt[2])
                                local hs_enabled = ui.get(tbl.refs.hide[1]) and ui.get(tbl.refs.hide[2])
                                
                                if not dt_enabled and not hs_enabled and left > 0 then
                                    
                                    tbl.breaklc.active = true
                                end
                            end
                        end

                        
                        if not tbl._breaklc_cb_registered then
                            tbl._breaklc_cb_registered = true
                            
                            
                            client.set_event_callback("round_start", update_server_lagcomp_info)
                            update_server_lagcomp_info()  
                            
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
                                    ui.set(tbl.items.body[2], -60)
                                    ui.set(tbl.items.yaw[2], tbl.clamp(ui.get(menutbl["right"]) + tbl.antiaim.manual.aa))
                                else
                                    ui.set(tbl.items.body[2], 60)
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

local base_desync_value = 60
if menutbl and menutbl["custom_slider"] then
    local ok, val = pcall(ui.get, menutbl["custom_slider"])
    if ok and val then
        base_desync_value = val
    end
elseif menutbl and menutbl["fake"] then
    local ok, val = pcall(ui.get, menutbl["fake"])
    if ok and val then
        base_desync_value = val
    end
end


local current_desync_side = check and 1 or -1


if tbl.apply_enhanced_desync then
    local desync_data = {
        state = state,
        team = team,
        is_defensive = arg.force_defensive
    }
    
    local ok, enhanced_desync, enhanced_side = pcall(
        tbl.apply_enhanced_desync, 
        arg, 
        desync_data, 
        base_desync_value, 
        current_desync_side
    )
    
    if ok and enhanced_desync then
        
        base_desync_value = enhanced_desync
        
        
        if enhanced_side then
            check = enhanced_side > 0
        end
    end
end

local current_fl_desync_side = check and 1 or -1


if tbl.apply_fakelag_integration then
    local fl_data = {
        state = state,
        team = team,
        fakelag_active = fakelag,
        hideshot_active = hideshot
    }
    
    local ok, recommended_choke, new_desync_side, should_flip = pcall(
        tbl.apply_fakelag_integration,
        arg,
        current_fl_desync_side
    )
    
    if ok then
        
        if should_flip and new_desync_side then
            check = new_desync_side > 0
        end
        
        
        if fakelag and recommended_choke then
            
            local dt_on = ui.get(menu_refs["doubletap"][1]) and ui.get(menu_refs["doubletap"][2])
            local hs_on = ui.get(menu_refs["hideshots"][1]) and ui.get(menu_refs["hideshots"][2])
            
            if not dt_on and not hs_on then
                
                pcall(function()
                    ui.set(limitfl, recommended_choke)
                end)
            end
        end
    end
end
client.set_event_callback("round_prestart", function()
    
    if tbl.fakelag_system then
        tbl.fakelag_system.pattern.last_pattern_change = 0
        tbl.fakelag_system.choke_sync.release_history = {}
        tbl.fakelag_system.exploit.exploit_phase = "idle"
        tbl.fakelag_system.exploit.last_shot_tick = 0
    end
end)

local current_exploit_side = check and 1 or -1
local current_exploit_desync = base_desync_value
local current_exploit_jitter = base_jitter_value


if tbl.apply_exploit_aa_integration then
    local exploit_data = {
        state = state,
        team = team,
        is_defensive = arg.force_defensive
    }
    
    local ok, exploit_side, exploit_desync, exploit_jitter, exploit_modified = pcall(
        tbl.apply_exploit_aa_integration,
        arg,
        current_exploit_side,
        current_exploit_desync,
        current_exploit_jitter
    )
    
    if ok and exploit_modified then
        
        if exploit_side then
            check = exploit_side > 0
        end
        
        if exploit_desync then
            base_desync_value = exploit_desync
        end
        
        if exploit_jitter then
            base_jitter_value = exploit_jitter
        end
        
        
        if tbl.exploit_aa_system and tbl.exploit_aa_system.output.priority_override then
            
        end
    end
end

local current_landing_side = check and 1 or -1
local current_landing_desync = base_desync_value
local current_landing_jitter = base_jitter_value

if tbl.calculate_landing_aa then
    local ok, landing_side, landing_desync, landing_jitter, landing_modified = pcall(
        tbl.calculate_landing_aa,
        arg,
        current_landing_side,
        current_landing_desync,
        current_landing_jitter
    )
    
    if ok and landing_modified then
        
        if landing_side then
            check = landing_side > 0
        end
        
        if landing_desync then
            base_desync_value = landing_desync
        end
        
        if landing_jitter then
            base_jitter_value = landing_jitter
        end
        
        
        if tbl.landing_aa_system and tbl.landing_aa_system.output.yaw_offset then
            local current_yaw = ui.get(tbl.items.yaw[2]) or 0
            pcall(function()
                ui.set(tbl.items.yaw[2], current_yaw + tbl.landing_aa_system.output.yaw_offset)
            end)
        end
    end
end
client.set_event_callback("round_prestart", function()
    
    if tbl.landing_aa_system then
        local ls = tbl.landing_aa_system
        
        
        ls.detection.was_in_air = false
        ls.detection.landing_tick = 0
        ls.detection.landing_detected = false
        
        
        ls.behavior.active_until_tick = 0
        ls.behavior.landing_yaw_offset = 0
        
        
        ls.prediction.will_land_soon = false
        ls.prediction.ticks_until_land = 0
        ls.prediction.pre_land_adjustment = false
        
        
        ls.velocity_history = {}
        
        
        ls.output.is_landing = false
        ls.output.confidence = 1.0
    end
end)

                    local current_desync = ui.set(tbl.items.body[2], check and base_desync_value or -base_desync_value)

                    
                    local base_jitter_value = 3
                    if menutbl and menutbl["jitter_slider"] then
                        local ok, val = pcall(ui.get, menutbl["jitter_slider"])
                        if ok and val then
                            base_jitter_value = val
                        end
                    end

                    
                    if tbl.apply_enhanced_jitter and base_jitter_value ~= 0 then
                        
                        local jitter_data = {
                            body = { current = current_desync },
                            movement = { strafe_direction = 0 }
                        }
                        
                        local ok, enhanced_jitter, speed_mod = pcall(tbl.apply_enhanced_jitter, arg, jitter_data, base_jitter_value, current_desync)
                        if ok and enhanced_jitter then
                            ui.set(tbl.items.jitter[2], enhanced_jitter)
                        else
                            
                            local fallback_check = arg.command_number % 2 == 0
                            ui.set(tbl.items.jitter[2], fallback_check and -base_jitter_value or base_jitter_value)
                        end
                    else
                        
                        local fallback_check = arg.command_number % 2 == 0
                        ui.set(tbl.items.jitter[2], fallback_check and -base_jitter_value or base_jitter_value)
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
                                            
                                            elseif iii == "body1" or iii == "body_slider1" or iii == "custom_slider1" then
                                                
                                                if iii == "body_slider1" then
                                                    
                                                    fix = ui.get(vv["body1"]) == "static" or ui.get(vv["body1"]) == "jitter"
                                                elseif iii == "custom_slider1" then
                                                    
                                                    fix = ui.get(vv["body1"]) == "luasense"
                                                else
                                                    
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
                        if tbl.contains(ui.get(menu["visuals & misc"]["misc"]["features"]), "spin on no enemies alive/warmup") then
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

            local server_cvars = {
                maxunlag = 0.5,
                lagcomp_teleport_dist = 64,
                tickrate = 64,
                max_rewind_ticks = 12,
                interp_min_ratio = 1,
                interp_max_ratio = 2
            }        
    local adaptive_aimbot = {
        hitchance = {
            base_values = {},
            adjustments = {},
            learning_rate = 0.15,
            decay_rate = 0.95,
            min_samples = 8
        },
        
        multipoint = {
            
            hitbox_config = {
                [0] = {
                    name = "head",
                    base_scale = 0.75,
                    min_scale = 0.55,
                    max_scale = 0.95,
                    priority = 1.0,
                    size_factor = 0.6,      
                    movement_sensitivity = 1.5,  
                    distance_curve = "exponential",  
                    optimal_distance = 400
                },
                [1] = {
                    name = "neck",
                    base_scale = 0.70,
                    min_scale = 0.50,
                    max_scale = 0.90,
                    priority = 0.7,
                    size_factor = 0.4,
                    movement_sensitivity = 1.3,
                    distance_curve = "linear",
                    optimal_distance = 350
                },
                [2] = {
                    name = "chest",
                    base_scale = 0.80,
                    min_scale = 0.60,
                    max_scale = 0.98,
                    priority = 0.95,
                    size_factor = 1.0,
                    movement_sensitivity = 0.8,
                    distance_curve = "logarithmic",
                    optimal_distance = 500
                },
                [3] = {
                    name = "stomach",
                    base_scale = 0.78,
                    min_scale = 0.58,
                    max_scale = 0.96,
                    priority = 0.90,
                    size_factor = 1.1,
                    movement_sensitivity = 0.7,
                    distance_curve = "logarithmic",
                    optimal_distance = 450
                },
                [4] = {
                    name = "pelvis",
                    base_scale = 0.75,
                    min_scale = 0.55,
                    max_scale = 0.94,
                    priority = 0.85,
                    size_factor = 1.0,
                    movement_sensitivity = 0.6,
                    distance_curve = "linear",
                    optimal_distance = 400
                },
                [5] = {
                    name = "left_arm",
                    base_scale = 0.65,
                    min_scale = 0.45,
                    max_scale = 0.85,
                    priority = 0.4,
                    size_factor = 0.5,
                    movement_sensitivity = 1.8,
                    distance_curve = "exponential",
                    optimal_distance = 300
                },
                [6] = {
                    name = "right_arm",
                    base_scale = 0.65,
                    min_scale = 0.45,
                    max_scale = 0.85,
                    priority = 0.4,
                    size_factor = 0.5,
                    movement_sensitivity = 1.8,
                    distance_curve = "exponential",
                    optimal_distance = 300
                },
                [7] = {
                    name = "left_leg",
                    base_scale = 0.72,
                    min_scale = 0.52,
                    max_scale = 0.92,
                    priority = 0.6,
                    size_factor = 0.7,
                    movement_sensitivity = 1.0,
                    distance_curve = "linear",
                    optimal_distance = 350
                },
                [8] = {
                    name = "right_leg",
                    base_scale = 0.72,
                    min_scale = 0.52,
                    max_scale = 0.92,
                    priority = 0.6,
                    size_factor = 0.7,
                    movement_sensitivity = 1.0,
                    distance_curve = "linear",
                    optimal_distance = 350
                }
            },
            
            
            stats = {},
            
            
            context_memory = {},
            
            
            temporal_data = {},
            
            
            weapon_profiles = {
                awp = {
                    head_mult = 0.85,
                    body_mult = 1.15,
                    prefer_center = true,
                    distance_bonus = 0.1
                },
                scout = {
                    head_mult = 0.90,
                    body_mult = 1.10,
                    prefer_center = true,
                    distance_bonus = 0.08
                },
                deagle = {
                    head_mult = 0.75,
                    body_mult = 1.25,
                    prefer_center = false,
                    inaccuracy_penalty = 0.15
                },
                pistol = {
                    head_mult = 0.70,
                    body_mult = 1.30,
                    prefer_center = false,
                    inaccuracy_penalty = 0.20
                },
                rifle = {
                    head_mult = 0.95,
                    body_mult = 1.0,
                    prefer_center = true,
                    spray_adjustment = true
                },
                smg = {
                    head_mult = 0.85,
                    body_mult = 1.10,
                    prefer_center = false,
                    spray_adjustment = true
                }
            },
            
            
            aa_profiles = {
                jitter = {
                    head_penalty = 0.15,
                    body_bonus = 0.10,
                    expand_multipoint = true
                },
                static = {
                    head_bonus = 0.10,
                    body_penalty = 0.05,
                    expand_multipoint = false
                },
                defensive = {
                    head_penalty = 0.20,
                    body_bonus = 0.15,
                    use_safe_points = true
                },
                minimal_jitter = {
                    head_penalty = 0.12,
                    body_bonus = 0.08,
                    timing_based = true
                }
            },
            
            
            learning = {
                rate = 0.12,
                decay = 0.92,
                min_samples = 4,
                max_history = 100,
                confidence_threshold = 0.6,
                exploration_rate = 0.15
            }
        }
    }


    local function apply_distance_curve(distance, optimal_distance, curve_type, hitbox_config)
        local ratio = distance / optimal_distance
        local modifier = 1.0
        
        if curve_type == "exponential" then
            
            if ratio > 1.0 then
                modifier = math.exp(-0.5 * (ratio - 1.0)^2)
            else
                modifier = 1.0 + (1.0 - ratio) * 0.15
            end
        elseif curve_type == "logarithmic" then
            
            if ratio > 1.0 then
                modifier = 1.0 / (1.0 + math.log(ratio) * 0.3)
            else
                modifier = 1.0 + math.log(2.0 - ratio) * 0.1
            end
        elseif curve_type == "linear" then
            
            if ratio > 1.0 then
                modifier = math.max(0.6, 1.0 - (ratio - 1.0) * 0.2)
            else
                modifier = 1.0 + (1.0 - ratio) * 0.1
            end
        end
        
        return func.fclamp(modifier, 0.5, 1.5)
    end


    local function calculate_movement_impact(enemy, hitbox_config)
        local vx, vy, vz = entity.get_prop(enemy, "m_vecVelocity")
        if not vx then return 1.0, 0, "standing" end
        
        local speed = math.sqrt(vx*vx + vy*vy)
        local vertical_speed = math.abs(vz or 0)
        
        
        local movement_state = "standing"
        if speed > 200 then
            movement_state = "sprinting"
        elseif speed > 100 then
            movement_state = "running"
        elseif speed > 30 then
            movement_state = "walking"
        elseif vertical_speed > 100 then
            movement_state = "jumping"
        end
        
        
        local move_yaw = math.deg(math.atan2(vy, vx))
        
        
        local movement_modifier = 1.0
        local sensitivity = hitbox_config.movement_sensitivity or 1.0
        
        if movement_state == "sprinting" then
            
            movement_modifier = 1.0 + (speed / 250) * 0.35 * sensitivity
        elseif movement_state == "running" then
            movement_modifier = 1.0 + (speed / 250) * 0.25 * sensitivity
        elseif movement_state == "walking" then
            movement_modifier = 1.0 + (speed / 250) * 0.10 * sensitivity
        elseif movement_state == "jumping" then
            
            movement_modifier = 1.0 + 0.30 * sensitivity
        end
        
        return movement_modifier, speed, movement_state
    end


    local function analyze_enemy_pose(enemy)
        local result = {
            ducking = false,
            duck_amount = 0,
            leaning = false,
            lean_direction = 0,
            scoped = false,
            defusing = false,
            planting = false
        }
        
        
        result.duck_amount = entity.get_prop(enemy, "m_flDuckAmount") or 0
        result.ducking = result.duck_amount > 0.4
        
        
        result.scoped = (entity.get_prop(enemy, "m_bIsScoped") or 0) ~= 0
        
        
        result.defusing = (entity.get_prop(enemy, "m_bIsDefusing") or 0) ~= 0
        
        
        local lean_pose = entity.get_prop(enemy, "m_flPoseParameter", 12) or 0.5
        result.lean_direction = (lean_pose - 0.5) * 2  
        result.leaning = math.abs(result.lean_direction) > 0.2
        
        return result
    end


    local function get_weapon_multipoint_profile(lp)
        local weapon = entity.get_player_weapon(lp)
        if not weapon then return adaptive_aimbot.multipoint.weapon_profiles.rifle end
        
        local classname = entity.get_classname(weapon) or ""
        classname = classname:lower()
        
        if classname:find("awp") then
            return adaptive_aimbot.multipoint.weapon_profiles.awp, "awp"
        elseif classname:find("ssg08") then
            return adaptive_aimbot.multipoint.weapon_profiles.scout, "scout"
        elseif classname:find("deagle") then
            return adaptive_aimbot.multipoint.weapon_profiles.deagle, "deagle"
        elseif classname:find("glock") or classname:find("p250") or classname:find("elite") or
            classname:find("fiveseven") or classname:find("tec9") or classname:find("usp") or
            classname:find("hkp2000") or classname:find("cz75") then
            return adaptive_aimbot.multipoint.weapon_profiles.pistol, "pistol"
        elseif classname:find("mac10") or classname:find("mp9") or classname:find("mp7") or
            classname:find("ump45") or classname:find("p90") or classname:find("bizon") then
            return adaptive_aimbot.multipoint.weapon_profiles.smg, "smg"
        else
            return adaptive_aimbot.multipoint.weapon_profiles.rifle, "rifle"
        end
    end


    local function get_aa_multipoint_profile(data)
        if not data or not data.aa_type then
            return nil, "unknown"
        end
        
        local aa_type = data.aa_type.detected or "unknown"
        local profile = adaptive_aimbot.multipoint.aa_profiles[aa_type]
        
        return profile, aa_type
    end


    local function analyze_temporal_pattern(hitbox_key, stats)
        if not stats or not stats.history then return 1.0 end
        
        local history = stats.history
        if #history < 5 then return 1.0 end
        
        
        local recent_hits = 0
        local recent_total = 0
        local trend = 0
        
        for i = math.max(1, #history - 10), #history do
            local entry = history[i]
            if entry then
                recent_total = recent_total + 1
                if entry.hit then
                    recent_hits = recent_hits + 1
                    trend = trend + (i / #history)  
                end
            end
        end
        
        if recent_total < 3 then return 1.0 end
        
        local hit_rate = recent_hits / recent_total
        local trend_factor = trend / recent_total
        
        
        if hit_rate > 0.7 and trend_factor > 0.5 then
            return 0.90  
        
        elseif hit_rate < 0.4 then
            return 1.15  
        end
        
        return 1.0
    end


    local function calculate_adaptive_multipoint(enemy, hitbox_id, weapon_type)
        local lp = entity.get_local_player()
        if not lp or not enemy then return 0.75, nil end
        
        local config = adaptive_aimbot.multipoint.hitbox_config[hitbox_id]
        if not config then return 0.75, nil end
        
        
        local distance = get_distance_to_player(enemy)
        local vx, vy = entity.get_prop(enemy, "m_vecVelocity")
        local velocity = vx and math.sqrt(vx*vx + vy*vy) or 0
        
        local dist_bucket = math.floor(distance / 150)
        local vel_bucket = velocity > 200 and "fast" or velocity > 100 and "medium" or "slow"
        local context = string.format("%s_d%d_%s", weapon_type, dist_bucket, vel_bucket)
        local hitbox_key = string.format("%s_hb%d", context, hitbox_id)
        
        
        if not adaptive_aimbot.multipoint.stats[hitbox_key] then
            adaptive_aimbot.multipoint.stats[hitbox_key] = {
                hits = 0,
                total = 0,
                scale_adjustment = 0,
                last_scale = config.base_scale,
                history = {},
                streak = {hits = 0, misses = 0},
                confidence = 0.5
            }
        end
        
        local stats = adaptive_aimbot.multipoint.stats[hitbox_key]
        
        
        local data = nil
        pcall(function()
            data = get_player_data(enemy)
        end)
        
        
        
        
        local base_scale = config.base_scale
        
        
        
        
        local performance_scale = 1.0
        
        if stats.total >= adaptive_aimbot.multipoint.learning.min_samples then
            local success_rate = stats.hits / stats.total
            local target_rate = 0.65
            local error = target_rate - success_rate
            
            
            local delta = error * adaptive_aimbot.multipoint.learning.rate
            stats.scale_adjustment = func.fclamp(
                stats.scale_adjustment + delta,
                config.min_scale - config.base_scale,
                config.max_scale - config.base_scale
            )
            
            
            local sample_confidence = math.min(1.0, stats.total / 20)
            local consistency = 1.0 - math.abs(success_rate - target_rate)
            stats.confidence = sample_confidence * consistency
            
            performance_scale = 1.0 + stats.scale_adjustment / config.base_scale
        end
        
        
        
        
        local temporal_scale = analyze_temporal_pattern(hitbox_key, stats)
        
        
        
        
        local distance_scale = apply_distance_curve(
            distance,
            config.optimal_distance,
            config.distance_curve,
            config
        )
        
        
        if distance > 800 then
            distance_scale = distance_scale * 0.88
        elseif distance < 250 then
            distance_scale = distance_scale * 1.12
        end
        
        
        
        
        local movement_scale, speed, movement_state = calculate_movement_impact(enemy, config)
        
        
        if hitbox_id == 0 then  
            if movement_state == "sprinting" then
                movement_scale = movement_scale * 1.15  
            elseif movement_state == "standing" then
                movement_scale = movement_scale * 0.92  
            end
        elseif hitbox_id == 2 or hitbox_id == 3 or hitbox_id == 4 then  
            if movement_state == "sprinting" then
                movement_scale = movement_scale * 1.25  
            end
        end
        
        
        
        
        local pose_scale = 1.0
        local pose = analyze_enemy_pose(enemy)
        
        if pose.ducking then
            if hitbox_id == 0 then  
                pose_scale = 0.88  
            elseif hitbox_id == 2 or hitbox_id == 3 then  
                pose_scale = 1.08  
            end
        end
        
        if pose.scoped then
            
            pose_scale = pose_scale * 0.95
        end
        
        if pose.defusing then
            
            pose_scale = pose_scale * 0.90
        end
        
        if pose.leaning then
            
            pose_scale = pose_scale * (1.0 + math.abs(pose.lean_direction) * 0.08)
        end
        
        
        
        
        local weapon_scale = 1.0
        local weapon_profile, weapon_name = get_weapon_multipoint_profile(lp)
        
        if weapon_profile then
            
            if hitbox_id == 0 then  
                weapon_scale = weapon_profile.head_mult or 1.0
            elseif hitbox_id >= 2 and hitbox_id <= 4 then  
                weapon_scale = weapon_profile.body_mult or 1.0
            end
            
            
            if weapon_profile.prefer_center then
                weapon_scale = weapon_scale * 0.95
            end
            
            
            if weapon_profile.inaccuracy_penalty and distance > 400 then
                weapon_scale = weapon_scale * (1.0 + weapon_profile.inaccuracy_penalty)
            end
            
            
            if weapon_profile.distance_bonus and distance > 600 then
                weapon_scale = weapon_scale * (1.0 - weapon_profile.distance_bonus)
            end
        end
        
        
        
        
        local aa_scale = 1.0
        local aa_profile, aa_type = get_aa_multipoint_profile(data)
        
        if aa_profile then
            if hitbox_id == 0 then  
                aa_scale = 1.0 + (aa_profile.head_penalty or 0) - (aa_profile.head_bonus or 0)
            elseif hitbox_id >= 2 and hitbox_id <= 4 then  
                aa_scale = 1.0 + (aa_profile.body_bonus or 0) - (aa_profile.body_penalty or 0)
            end
            
            
            if aa_profile.expand_multipoint then
                aa_scale = aa_scale * 1.10
            end
            
            
            if aa_profile.use_safe_points then
                aa_scale = aa_scale * 1.05
            end
        end
        
        
        
        
        local jitter_scale = 1.0
        
        if data and data._current_jitter_analysis then
            local jitter = data._current_jitter_analysis
            
            if jitter.predictable then
                
                jitter_scale = 1.0 - (jitter.confidence * 0.12)
            else
                
                jitter_scale = 1.0 + (jitter.entropy or 0.5) * 0.15
            end
            
            
            if jitter.stability and jitter.stability > 0.7 then
                jitter_scale = jitter_scale * 0.95
            end
        end
        
        
        
        
        local streak_scale = 1.0
        
        if stats.streak then
            if stats.streak.hits >= 3 then
                
                streak_scale = 0.95
            elseif stats.streak.misses >= 2 then
                
                streak_scale = 1.10 + (stats.streak.misses * 0.03)
            end
        end
        
        
        
        
        local tickrate_scale = 1.0
        local tickrate = 1 / globals.tickinterval()
        
        if tickrate >= 128 then
            
            tickrate_scale = 0.96
        else
            
            tickrate_scale = 1.04
        end
        
        
        
        
        local latency_scale = 1.0
        local latency = client.latency() * 1000  
        
        if latency > 80 then
            
            latency_scale = 1.0 + math.min(0.15, (latency - 80) / 500)
        elseif latency < 30 then
            
            latency_scale = 0.98
        end
        
        
        
        
        local combined_scale = base_scale
        
        
        combined_scale = combined_scale * performance_scale      
        combined_scale = combined_scale * temporal_scale         
        combined_scale = combined_scale * distance_scale         
        combined_scale = combined_scale * movement_scale         
        combined_scale = combined_scale * pose_scale             
        combined_scale = combined_scale * weapon_scale           
        combined_scale = combined_scale * aa_scale               
        combined_scale = combined_scale * jitter_scale           
        combined_scale = combined_scale * streak_scale           
        combined_scale = combined_scale * tickrate_scale         
        combined_scale = combined_scale * latency_scale          
        
        
        
        
        if math.random() < adaptive_aimbot.multipoint.learning.exploration_rate then
            local exploration_delta = (math.random() - 0.5) * 0.15
            combined_scale = combined_scale * (1.0 + exploration_delta)
        end
        
        
        
        
        local final_scale = func.fclamp(combined_scale, config.min_scale, config.max_scale)
        
        
        stats.last_scale = final_scale
        
        
        local debug_info = {
            hitbox = config.name,
            context = context,
            base = base_scale,
            final = final_scale,
            modifiers = {
                performance = performance_scale,
                temporal = temporal_scale,
                distance = distance_scale,
                movement = movement_scale,
                pose = pose_scale,
                weapon = weapon_scale,
                aa = aa_scale,
                jitter = jitter_scale,
                streak = streak_scale
            }
        }
        
        return final_scale, hitbox_key, debug_info
    end
            local function get_distance_to_player(ent)
                local lp = entity.get_local_player()
                if not lp then return 500 end
                
                local lx, ly, lz = entity.get_prop(lp, "m_vecOrigin")
                local ex, ey, ez = entity.get_prop(ent, "m_vecOrigin")
                
                if not lx or not ex then return 500 end
                return math.sqrt((ex-lx)^2 + (ey-ly)^2 + (ez-lz)^2)
            end

    local function update_multipoint_stats(shot, hit)
        local enemy = shot.target
        if not enemy then return end
        
        local lp = entity.get_local_player()
        if not lp then return end
        
        local weapon = entity.get_player_weapon(lp)
        local weapon_type = "rifle"
        if weapon then
            local classname = entity.get_classname(weapon) or ""
            classname = classname:lower()
            if classname:find("awp") then weapon_type = "awp"
            elseif classname:find("ssg08") then weapon_type = "scout"
            elseif classname:find("deagle") then weapon_type = "deagle"
            elseif classname:find("pistol") or classname:find("glock") or classname:find("p250") then
                weapon_type = "pistol"
            end
        end
        
        local hitbox = shot.hitgroup or 0
        local distance = get_distance_to_player(enemy)
        local vx, vy = entity.get_prop(enemy, "m_vecVelocity")
        local velocity = vx and math.sqrt(vx*vx + vy*vy) or 0
        
        local dist_bucket = math.floor(distance / 150)
        local vel_bucket = velocity > 200 and "fast" or velocity > 100 and "medium" or "slow"
        local context = string.format("%s_d%d_%s", weapon_type, dist_bucket, vel_bucket)
        local hitbox_key = string.format("%s_hb%d", context, hitbox)
        
        if not adaptive_aimbot.multipoint.stats[hitbox_key] then
            local config = adaptive_aimbot.multipoint.hitbox_config[hitbox] or 
                        adaptive_aimbot.multipoint.hitbox_config[0]
            adaptive_aimbot.multipoint.stats[hitbox_key] = {
                hits = 0,
                total = 0,
                scale_adjustment = 0,
                last_scale = config.base_scale,
                history = {},
                streak = {hits = 0, misses = 0},
                confidence = 0.5
            }
        end
        
        local stats = adaptive_aimbot.multipoint.stats[hitbox_key]
        
        
        stats.total = stats.total + 1
        if hit then
            stats.hits = stats.hits + 1
            stats.streak.hits = stats.streak.hits + 1
            stats.streak.misses = 0
        else
            stats.streak.misses = stats.streak.misses + 1
            stats.streak.hits = 0
        end
        
        
        table.insert(stats.history, {
            hit = hit,
            scale = stats.last_scale,
            distance = distance,
            velocity = velocity,
            time = globals.realtime()
        })
        
        
        while #stats.history > adaptive_aimbot.multipoint.learning.max_history do
            table.remove(stats.history, 1)
        end
        
        
        if stats.total > 50 then
            local ratio = stats.hits / stats.total
            stats.hits = math.floor(ratio * 35)
            stats.total = 35
        end
    end


    local function decay_multipoint_stats()
        local decay = adaptive_aimbot.multipoint.learning.decay
        
        for key, stats in pairs(adaptive_aimbot.multipoint.stats) do
            stats.scale_adjustment = stats.scale_adjustment * decay
            stats.hits = math.floor(stats.hits * 0.9)
            stats.total = math.floor(stats.total * 0.9)
            
            
            if stats.streak then
                stats.streak.hits = math.max(0, stats.streak.hits - 1)
                stats.streak.misses = math.max(0, stats.streak.misses - 1)
            end
        end
    end


    _G.calculate_adaptive_multipoint = calculate_adaptive_multipoint
    _G.update_multipoint_stats = update_multipoint_stats
    _G.decay_multipoint_stats = decay_multipoint_stats
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
    local tickbase_detector = {
        players = {},
        config = {
            sample_window = 64,        
            shift_threshold = 6,       
            recharge_threshold = 12,   
            confidence_decay = 0.92,
            detection_cooldown = 0.5   
        }
    }

    local function create_tickbase_data()
        return {
            
            simtime_history = {},
            tickbase_history = {},
            
            
            shift_detected = false,
            shift_amount = 0,
            shift_direction = 0,  
            
            
            recharge_start = 0,
            recharge_ticks = 0,
            is_recharging = false,
            
            
            defensive_active = false,
            defensive_start = 0,
            defensive_duration = 0,
            
            
            dt_detected = false,
            dt_last_fire = 0,
            dt_interval_history = {},
            
            
            hs_detected = false,
            hs_choke_pattern = {},
            
            
            stats = {
                total_shifts = 0,
                avg_shift_amount = 0,
                shift_frequency = 0,
                last_shift_time = 0,
                confidence = 0
            },
            
            
            prediction = {
                next_shift_time = 0,
                shift_probability = 0,
                optimal_shoot_window = {0, 0}
            },
            
            last_update = 0
        }
    end

    local function get_tickbase_data(ent)
        local idx = tostring(entity.get_steam64(ent) or ent)
        if not tickbase_detector.players[idx] then
            tickbase_detector.players[idx] = create_tickbase_data()
        end
        return tickbase_detector.players[idx]
    end

    local function detect_tickbase_exploitation(ent)
        local tb_data = get_tickbase_data(ent)
        local now = globals.realtime()
        local tick = globals.tickcount()
        
        
        local simtime = entity.get_prop(ent, "m_flSimulationTime")
        if not simtime then return tb_data end
        
        local simtime_ticks = math.floor(simtime / globals.tickinterval() + 0.5)
        
        
        table.insert(tb_data.simtime_history, {
            simtime = simtime,
            simtime_ticks = simtime_ticks,
            tick = tick,
            time = now
        })
        
        
        while #tb_data.simtime_history > tickbase_detector.config.sample_window do
            table.remove(tb_data.simtime_history, 1)
        end
        
        if #tb_data.simtime_history < 10 then
            return tb_data
        end
        
        
        
        
        local function analyze_simtime_deltas()
            local deltas = {}
            local anomalies = {}
            
            for i = 2, #tb_data.simtime_history do
                local curr = tb_data.simtime_history[i]
                local prev = tb_data.simtime_history[i-1]
                
                local expected_delta = curr.tick - prev.tick
                local actual_delta = curr.simtime_ticks - prev.simtime_ticks
                local discrepancy = actual_delta - expected_delta
                
                table.insert(deltas, {
                    expected = expected_delta,
                    actual = actual_delta,
                    discrepancy = discrepancy,
                    time = curr.time
                })
                
                
                if math.abs(discrepancy) >= tickbase_detector.config.shift_threshold then
                    table.insert(anomalies, {
                        amount = discrepancy,
                        time = curr.time,
                        tick = curr.tick
                    })
                end
            end
            
            return deltas, anomalies
        end
        
        local deltas, anomalies = analyze_simtime_deltas()
        
        
        
        
        if #anomalies > 0 then
            local recent_anomaly = anomalies[#anomalies]
            
            if now - recent_anomaly.time < tickbase_detector.config.detection_cooldown then
                tb_data.shift_detected = true
                tb_data.shift_amount = math.abs(recent_anomaly.amount)
                tb_data.shift_direction = recent_anomaly.amount > 0 and 1 or -1
                
                tb_data.stats.total_shifts = tb_data.stats.total_shifts + 1
                tb_data.stats.last_shift_time = recent_anomaly.time
                
                
                local alpha = 0.3
                tb_data.stats.avg_shift_amount = tb_data.stats.avg_shift_amount * (1 - alpha) + 
                                                tb_data.shift_amount * alpha
                
                
                if tb_data.shift_direction > 0 then
                    
                    tb_data.is_recharging = true
                    tb_data.recharge_ticks = tb_data.recharge_ticks + tb_data.shift_amount
                    
                    if tb_data.recharge_start == 0 then
                        tb_data.recharge_start = now
                    end
                else
                    
                    tb_data.is_recharging = false
                    
                    
                    if tb_data.dt_last_fire > 0 then
                        local interval = now - tb_data.dt_last_fire
                        table.insert(tb_data.dt_interval_history, interval)
                        
                        while #tb_data.dt_interval_history > 10 do
                            table.remove(tb_data.dt_interval_history, 1)
                        end
                        
                        
                        if interval < 0.1 and tb_data.shift_amount >= 12 then
                            tb_data.dt_detected = true
                        end
                    end
                    
                    tb_data.dt_last_fire = now
                    tb_data.recharge_ticks = 0
                    tb_data.recharge_start = 0
                end
            else
                
                tb_data.shift_detected = false
                tb_data.shift_amount = tb_data.shift_amount * tickbase_detector.config.confidence_decay
            end
        end
        
        
        
        
        local function detect_defensive_aa()
            
            
            
            
            
            local consecutive_recharge = 0
            local total_recharge = 0
            
            for i = #deltas, math.max(1, #deltas - 15), -1 do
                local delta = deltas[i]
                if delta.discrepancy > 0 and delta.discrepancy <= 2 then
                    consecutive_recharge = consecutive_recharge + 1
                    total_recharge = total_recharge + delta.discrepancy
                else
                    break
                end
            end
            
            
            local vx, vy, vz = entity.get_prop(ent, "m_vecVelocity")
            local velocity = vx and math.sqrt(vx*vx + vy*vy) or 0
            
            
            local is_stationary = velocity < 10
            
            if consecutive_recharge >= 8 and is_stationary then
                tb_data.defensive_active = true
                tb_data.defensive_duration = consecutive_recharge * globals.tickinterval()
                
                if tb_data.defensive_start == 0 then
                    tb_data.defensive_start = now
                end
            else
                tb_data.defensive_active = false
                tb_data.defensive_start = 0
            end
            
            return tb_data.defensive_active
        end
        
        detect_defensive_aa()
        
        
        
        
        local function detect_hideshot()
            
            
            
            
            local choke_pattern = {}
            for i = 2, math.min(20, #deltas) do
                local delta = deltas[#deltas - i + 1]
                if delta.actual == 0 then
                    table.insert(choke_pattern, 1)  
                else
                    table.insert(choke_pattern, 0)  
                end
            end
            
            tb_data.hs_choke_pattern = choke_pattern
            
            
            local consecutive_chokes = 0
            local max_chokes = 0
            
            for _, choked in ipairs(choke_pattern) do
                if choked == 1 then
                    consecutive_chokes = consecutive_chokes + 1
                    max_chokes = math.max(max_chokes, consecutive_chokes)
                else
                    consecutive_chokes = 0
                end
            end
            
            
            if max_chokes >= 10 and max_chokes <= 16 then
                tb_data.hs_detected = true
            else
                tb_data.hs_detected = false
            end
        end
        
        detect_hideshot()
        
        
        
        
        local function predict_optimal_window()
            
            
            
            if tb_data.stats.total_shifts < 3 then
                
                tb_data.prediction.shift_probability = 0.5
                tb_data.prediction.optimal_shoot_window = {0, 999}
                return
            end
            
            
            local time_span = now - (tb_data.simtime_history[1].time or now)
            if time_span > 0 then
                tb_data.stats.shift_frequency = tb_data.stats.total_shifts / time_span
            end
            
            
            local time_since_last = now - tb_data.stats.last_shift_time
            local avg_interval = tb_data.stats.shift_frequency > 0 and 
                                (1 / tb_data.stats.shift_frequency) or 2.0
            
            tb_data.prediction.next_shift_time = tb_data.stats.last_shift_time + avg_interval
            
            
            local time_to_shift = tb_data.prediction.next_shift_time - now
            local probability = 0.5
            
            if time_to_shift < 0 then
                
                probability = math.min(0.9, 0.5 + math.abs(time_to_shift) * 0.2)
            else
                
                probability = math.max(0.2, 0.5 - time_to_shift * 0.1)
            end
            
            tb_data.prediction.shift_probability = probability
            
            
            local window_start = tb_data.stats.last_shift_time
            local window_end = window_start + 0.3  
            
            tb_data.prediction.optimal_shoot_window = {window_start, window_end}
        end
        
        predict_optimal_window()
        
        
        
        
        local confidence = 0.3  
        
        if tb_data.shift_detected then
            confidence = confidence + 0.3
        end
        
        if tb_data.stats.total_shifts >= 3 then
            confidence = confidence + 0.2
        end
        
        if tb_data.defensive_active or tb_data.dt_detected or tb_data.hs_detected then
            confidence = confidence + 0.2
        end
        
        tb_data.stats.confidence = func.fclamp(confidence, 0, 1)
        tb_data.last_update = now
        
        return tb_data
    end




    local fakeduck_detector = {
        players = {},
        config = {
            duck_threshold = 0.35,     
            cycle_window = 32,         
            min_cycles = 2,            
            prediction_lookahead = 8   
        }
    }

    local function create_fakeduck_data()
        return {
            
            duck_history = {},
            
            
            is_fakeducking = false,
            fd_confidence = 0,
            
            
            cycle_peaks = {},      
            cycle_valleys = {},    
            cycle_period = 0,      
            cycle_phase = 0,       
            
            
            head_z_history = {},
            head_z_variance = 0,
            optimal_z_offset = 0,
            
            
            last_peak_time = 0,
            last_valley_time = 0,
            
            
            anim_cycle_history = {},
            
            last_update = 0
        }
    end

    local function get_fakeduck_data(ent)
        local idx = tostring(entity.get_steam64(ent) or ent)
        if not fakeduck_detector.players[idx] then
            fakeduck_detector.players[idx] = create_fakeduck_data()
        end
        return fakeduck_detector.players[idx]
    end

    local function detect_fakeduck(ent)
        local fd_data = get_fakeduck_data(ent)
        local now = globals.realtime()
        local tick = globals.tickcount()
        
        
        local duck_amount = entity.get_prop(ent, "m_flDuckAmount") or 0
        local flags = entity.get_prop(ent, "m_fFlags") or 0
        local on_ground = bit.band(flags, 1) == 1
        
        
        local head_x, head_y, head_z = entity.hitbox_position(ent, 0)
        
        
        table.insert(fd_data.duck_history, {
            amount = duck_amount,
            time = now,
            tick = tick,
            on_ground = on_ground
        })
        
        
        if head_z then
            table.insert(fd_data.head_z_history, {
                z = head_z,
                time = now
            })
        end
        
        
        while #fd_data.duck_history > fakeduck_detector.config.cycle_window * 2 do
            table.remove(fd_data.duck_history, 1)
        end
        while #fd_data.head_z_history > 50 do
            table.remove(fd_data.head_z_history, 1)
        end
        
        if #fd_data.duck_history < 20 then
            return fd_data
        end
        
        
        
        
        local function detect_duck_cycles()
            local history = fd_data.duck_history
            local peaks = {}
            local valleys = {}
            
            
            for i = 2, #history - 1 do
                local prev = history[i-1].amount
                local curr = history[i].amount
                local next_val = history[i+1].amount
                
                
                if curr > prev and curr > next_val and curr > fakeduck_detector.config.duck_threshold then
                    table.insert(peaks, {
                        amount = curr,
                        time = history[i].time,
                        tick = history[i].tick,
                        index = i
                    })
                end
                
                
                if curr < prev and curr < next_val and curr < 0.5 then
                    table.insert(valleys, {
                        amount = curr,
                        time = history[i].time,
                        tick = history[i].tick,
                        index = i
                    })
                end
            end
            
            fd_data.cycle_peaks = peaks
            fd_data.cycle_valleys = valleys
            
            
            if #peaks >= 2 then
                local intervals = {}
                for i = 2, #peaks do
                    table.insert(intervals, peaks[i].tick - peaks[i-1].tick)
                end
                
                local sum = 0
                for _, int in ipairs(intervals) do
                    sum = sum + int
                end
                
                if #intervals > 0 then
                    fd_data.cycle_period = sum / #intervals
                end
                
                fd_data.last_peak_time = peaks[#peaks].time
            end
            
            if #valleys >= 2 then
                fd_data.last_valley_time = valleys[#valleys].time
            end
            
            return #peaks >= fakeduck_detector.config.min_cycles
        end
        
        local has_cycles = detect_duck_cycles()
        
        
        
        
        local function confirm_fakeduck()
            if not has_cycles then return false, 0 end
            
            local confidence = 0.3
            
            
            if fd_data.cycle_period > 0 and fd_data.cycle_period < 20 then
                confidence = confidence + 0.25
            end
            
            
            local recent = fd_data.duck_history[#fd_data.duck_history]
            if recent and recent.on_ground then
                confidence = confidence + 0.15
            end
            
            
            if #fd_data.head_z_history >= 10 then
                local sum_z = 0
                for _, entry in ipairs(fd_data.head_z_history) do
                    sum_z = sum_z + entry.z
                end
                local mean_z = sum_z / #fd_data.head_z_history
                
                local var_sum = 0
                for _, entry in ipairs(fd_data.head_z_history) do
                    var_sum = var_sum + (entry.z - mean_z)^2
                end
                fd_data.head_z_variance = var_sum / #fd_data.head_z_history
                
                
                if fd_data.head_z_variance > 50 then
                    confidence = confidence + 0.20
                end
            end
            
            
            local vx, vy = entity.get_prop(ent, "m_vecVelocity")
            local velocity = vx and math.sqrt(vx*vx + vy*vy) or 0
            
            if velocity < 30 then
                confidence = confidence + 0.10
            end
            
            return confidence > 0.6, confidence
        end
        
        local is_fd, fd_conf = confirm_fakeduck()
        fd_data.is_fakeducking = is_fd
        fd_data.fd_confidence = fd_conf
        
        
        
        
        if fd_data.is_fakeducking and fd_data.cycle_period > 0 then
            
            local time_since_peak = now - fd_data.last_peak_time
            local ticks_since_peak = time_since_peak / globals.tickinterval()
            
            fd_data.cycle_phase = (ticks_since_peak % fd_data.cycle_period) / fd_data.cycle_period
        end
        
        
        
        
        local function calculate_optimal_z_offset()
            if not fd_data.is_fakeducking then
                fd_data.optimal_z_offset = 0
                return
            end
            
            
            local latency = client.latency()
            local cl_interp = cvar.cl_interp:get_float()
            local total_delay = latency + cl_interp
            local delay_ticks = math.floor(total_delay / globals.tickinterval())
            
            
            local predicted_phase = fd_data.cycle_phase + 
                                    (delay_ticks / math.max(1, fd_data.cycle_period))
            predicted_phase = predicted_phase % 1.0
            
            
            local predicted_duck = 0.5 + 0.5 * math.sin(predicted_phase * 2 * math.pi)
            
            
            local duck_z_range = 18
            fd_data.optimal_z_offset = predicted_duck * duck_z_range
        end
        
        calculate_optimal_z_offset()
        
        fd_data.last_update = now
        return fd_data
    end




    local resolver_state_machine = {
        players = {},
        
        
        states = {
            UNKNOWN = "unknown",
            STATIC = "static",
            JITTER = "jitter",
            FLIP = "flip",
            SPIN = "spin",
            DEFENSIVE = "defensive",
            FAKELAG = "fakelag",
            DESYNC_LEFT = "desync_left",
            DESYNC_RIGHT = "desync_right",
            MICRO_MOVEMENT = "micro_movement",
            VELOCITY_LINKED = "velocity_linked"
        },
        
        
        transitions = {},
        
        config = {
            min_state_duration = 0.15,   
            max_state_duration = 3.0,    
            transition_threshold = 0.65,  
            history_size = 50
        }
    }

    local function create_state_machine_data()
        return {
            
            current_state = "unknown",
            state_enter_time = 0,
            state_confidence = 0,
            
            
            state_history = {},
            
            
            transition_matrix = {},  
            last_transitions = {},
            
            
            state_features = {},
            
            
            predicted_next_state = "unknown",
            transition_probability = 0,
            time_to_transition = 0,
            
            
            state_data = {
                static = {duration = 0, side = 0},
                jitter = {frequency = 0, amplitude = 0, pattern = ""},
                flip = {interval = 0, last_flip = 0, count = 0},
                defensive = {ticks_charged = 0, exploit_type = ""},
                velocity_linked = {correlation = 0, last_direction = 0}
            },
            
            last_update = 0
        }
    end

    local function get_state_machine_data(ent)
        local idx = tostring(entity.get_steam64(ent) or ent)
        if not resolver_state_machine.players[idx] then
            resolver_state_machine.players[idx] = create_state_machine_data()
        end
        return resolver_state_machine.players[idx]
    end

    local function update_resolver_state_machine(ent, resolver_data)
        local sm_data = get_state_machine_data(ent)
        local now = globals.realtime()
        
        
        local aa_type = resolver_data.aa_type or {}
        local jitter_analysis = resolver_data._current_jitter_analysis or {}
        local tb_data = detect_tickbase_exploitation(ent)
        local fd_data = detect_fakeduck(ent)
        
        
        
        
        local function extract_features()
            local features = {
                
                body_variance = 0,
                body_flip_rate = 0,
                body_current = 0,
                
                
                jitter_entropy = jitter_analysis.entropy or 0.5,
                jitter_predictable = jitter_analysis.predictable and 1 or 0,
                jitter_period = jitter_analysis.delay_ticks or 0,
                
                
                velocity = 0,
                strafe_detected = 0,
                
                
                defensive_active = tb_data.defensive_active and 1 or 0,
                shift_detected = tb_data.shift_detected and 1 or 0,
                fakeduck = fd_data.is_fakeducking and 1 or 0,
                
                
                aa_scores = aa_type.characteristics or {}
            }
            
            
            local pose = entity.get_prop(ent, "m_flPoseParameter", 11)
            if pose then
                features.body_current = (pose * 120) - 60
            end
            
            
            local vx, vy = entity.get_prop(ent, "m_vecVelocity")
            if vx then
                features.velocity = math.sqrt(vx*vx + vy*vy)
            end
            
            
            if resolver_data.body and resolver_data.body.history then
                local history = resolver_data.body.history
                if #history >= 5 then
                    local sum = 0
                    local count = 0
                    local last_sign = nil
                    local flips = 0
                    
                    for _, entry in ipairs(history) do
                        sum = sum + entry.yaw
                        count = count + 1
                        
                        local sign = entry.yaw > 0 and 1 or -1
                        if last_sign and sign ~= last_sign then
                            flips = flips + 1
                        end
                        last_sign = sign
                    end
                    
                    local mean = sum / count
                    local var_sum = 0
                    for _, entry in ipairs(history) do
                        var_sum = var_sum + (entry.yaw - mean)^2
                    end
                    
                    features.body_variance = var_sum / count
                    features.body_flip_rate = flips / count
                end
            end
            
            
            if resolver_data.movement and resolver_data.movement.strafe_detected then
                features.strafe_detected = 1
            end
            
            return features
        end
        
        local features = extract_features()
        
        
        
        
        local function classify_state(features)
            local scores = {}
            local states = resolver_state_machine.states
            
            
            for _, state in pairs(states) do
                scores[state] = 0
            end
            
            
            scores[states.UNKNOWN] = 0.1
            
            
            if features.body_variance < 100 and features.body_flip_rate < 0.1 then
                scores[states.STATIC] = 0.6 + (1 - features.body_flip_rate) * 0.3
            end
            
            
            if features.jitter_entropy > 0.6 and features.body_variance > 500 then
                scores[states.JITTER] = 0.5 + features.jitter_entropy * 0.4
            end
            
            
            if features.jitter_predictable > 0 and features.jitter_period > 0 then
                scores[states.FLIP] = 0.5 + features.jitter_predictable * 0.4
            end
            
            
            if features.defensive_active > 0 then
                scores[states.DEFENSIVE] = 0.7 + features.shift_detected * 0.2
            end
            
            
            if features.strafe_detected > 0 and features.velocity > 100 then
                scores[states.VELOCITY_LINKED] = 0.5 + (features.velocity / 250) * 0.3
            end
            
            
            if features.body_variance < 300 then
                if features.body_current > 20 then
                    scores[states.DESYNC_RIGHT] = 0.4 + math.abs(features.body_current) / 60 * 0.4
                elseif features.body_current < -20 then
                    scores[states.DESYNC_LEFT] = 0.4 + math.abs(features.body_current) / 60 * 0.4
                end
            end
            
            
            if features.body_variance > 50 and features.body_variance < 400 and
            features.body_flip_rate > 0.3 then
                scores[states.MICRO_MOVEMENT] = 0.5 + features.body_flip_rate * 0.3
            end
            
            
            if features.aa_scores then
                if features.aa_scores.jitter and features.aa_scores.jitter > 0.5 then
                    scores[states.JITTER] = math.max(scores[states.JITTER], 
                                                    features.aa_scores.jitter)
                end
                if features.aa_scores.static and features.aa_scores.static > 0.5 then
                    scores[states.STATIC] = math.max(scores[states.STATIC],
                                                    features.aa_scores.static)
                end
            end
            
            
            local best_state = states.UNKNOWN
            local best_score = 0
            
            for state, score in pairs(scores) do
                if score > best_score then
                    best_score = score
                    best_state = state
                end
            end
            
            return best_state, best_score, scores
        end
        
        local detected_state, state_confidence, all_scores = classify_state(features)
        
        
        
        
        local function should_transition(new_state, new_confidence)
            local current = sm_data.current_state
            local time_in_state = now - sm_data.state_enter_time
            
            
            if time_in_state < resolver_state_machine.config.min_state_duration then
                return false
            end
            
            
            if time_in_state > resolver_state_machine.config.max_state_duration then
                return true
            end
            
            
            if new_state == current then
                return false
            end
            
            
            if new_confidence > resolver_state_machine.config.transition_threshold then
                
                local trans_prob = 0.5  
                
                if sm_data.transition_matrix[current] and 
                sm_data.transition_matrix[current][new_state] then
                    local trans_data = sm_data.transition_matrix[current][new_state]
                    local total_from = 0
                    
                    for _, count in pairs(sm_data.transition_matrix[current]) do
                        total_from = total_from + count
                    end
                    
                    if total_from > 0 then
                        trans_prob = trans_data / total_from
                    end
                end
                
                
                local adjusted_threshold = resolver_state_machine.config.transition_threshold * 
                                        (1 - trans_prob * 0.3)
                
                return new_confidence > adjusted_threshold
            end
            
            return false
        end
        
        
        
        
        local function update_state(new_state, new_confidence)
            local old_state = sm_data.current_state
            
            
            if old_state ~= new_state then
                
                if not sm_data.transition_matrix[old_state] then
                    sm_data.transition_matrix[old_state] = {}
                end
                
                sm_data.transition_matrix[old_state][new_state] = 
                    (sm_data.transition_matrix[old_state][new_state] or 0) + 1
                
                
                table.insert(sm_data.state_history, {
                    from = old_state,
                    to = new_state,
                    time = now,
                    confidence = new_confidence
                })
                
                
                while #sm_data.state_history > resolver_state_machine.config.history_size do
                    table.remove(sm_data.state_history, 1)
                end
                
                
                table.insert(sm_data.last_transitions, {
                    from = old_state,
                    to = new_state,
                    time = now
                })
                
                while #sm_data.last_transitions > 10 do
                    table.remove(sm_data.last_transitions, 1)
                end
                
                sm_data.state_enter_time = now
            end
            
            sm_data.current_state = new_state
            sm_data.state_confidence = new_confidence
            sm_data.state_features[new_state] = features
        end
        
        
        
        
        local function predict_next_transition()
            local current = sm_data.current_state
            
            if not sm_data.transition_matrix[current] then
                sm_data.predicted_next_state = "unknown"
                sm_data.transition_probability = 0.5
                sm_data.time_to_transition = 1.0
                return
            end
            
            
            local best_next = "unknown"
            local best_prob = 0
            local total = 0
            
            for state, count in pairs(sm_data.transition_matrix[current]) do
                total = total + count
            end
            
            if total > 0 then
                for state, count in pairs(sm_data.transition_matrix[current]) do
                    local prob = count / total
                    if prob > best_prob then
                        best_prob = prob
                        best_next = state
                    end
                end
            end
            
            sm_data.predicted_next_state = best_next
            sm_data.transition_probability = best_prob
            
            
            local avg_duration = 0.5
            local state_count = 0
            
            for _, entry in ipairs(sm_data.state_history) do
                if entry.from == current then
                    state_count = state_count + 1
                end
            end
            
            if state_count >= 2 then
                local durations = {}
                for i = 2, #sm_data.state_history do
                    if sm_data.state_history[i].from == current then
                        local duration = sm_data.state_history[i].time - 
                                        sm_data.state_history[i-1].time
                        if duration > 0 and duration < 10 then
                            table.insert(durations, duration)
                        end
                    end
                end
                
                if #durations > 0 then
                    local sum = 0
                    for _, d in ipairs(durations) do
                        sum = sum + d
                    end
                    avg_duration = sum / #durations
                end
            end
            
            local time_in_state = now - sm_data.state_enter_time
            sm_data.time_to_transition = math.max(0, avg_duration - time_in_state)
        end
        
        
        
        
        local function update_state_data()
            local state = sm_data.current_state
            local states = resolver_state_machine.states
            
            if state == states.STATIC then
                sm_data.state_data.static.duration = now - sm_data.state_enter_time
                sm_data.state_data.static.side = features.body_current > 0 and 1 or -1
                
            elseif state == states.JITTER then
                sm_data.state_data.jitter.frequency = 1 / math.max(1, features.jitter_period) * 64
                sm_data.state_data.jitter.amplitude = math.sqrt(features.body_variance)
                
            elseif state == states.FLIP then
                if features.jitter_period > 0 then
                    sm_data.state_data.flip.interval = features.jitter_period * globals.tickinterval()
                end
                
            elseif state == states.DEFENSIVE then
                sm_data.state_data.defensive.ticks_charged = tb_data.recharge_ticks
                if tb_data.dt_detected then
                    sm_data.state_data.defensive.exploit_type = "dt"
                elseif tb_data.hs_detected then
                    sm_data.state_data.defensive.exploit_type = "hs"
                else
                    sm_data.state_data.defensive.exploit_type = "defensive"
                end
                
            elseif state == states.VELOCITY_LINKED then
                if resolver_data.movement then
                    sm_data.state_data.velocity_linked.last_direction = 
                        resolver_data.movement.strafe_direction or 0
                end
            end
        end
        
        
        
        
        if should_transition(detected_state, state_confidence) then
            update_state(detected_state, state_confidence)
        else
            
            sm_data.state_confidence = sm_data.state_confidence * 0.7 + state_confidence * 0.3
        end
        
        update_state_data()
        predict_next_transition()
        
        sm_data.last_update = now
        
        return sm_data
    end




    local ping_compensator = {
        
        stats = {
            samples = {},
            rtt_mean = 0,
            rtt_variance = 0,
            rtt_jitter = 0,
            loss_rate = 0,
            choke_rate = 0
        },
        
        
        prediction = {
            optimal_leadtime = 0,
            confidence_interval = {0, 0},
            compensation_ticks = 0
        },
        
        config = {
            sample_window = 60,        
            max_samples = 200,
            jitter_percentile = 0.95,  
            update_interval = 0.5      
        },
        
        last_update = 0
    }

    local function update_ping_compensation()
        local now = globals.realtime()
        
        
        if now - ping_compensator.last_update < ping_compensator.config.update_interval then
            return ping_compensator.prediction
        end
        
        ping_compensator.last_update = now
        
        
        
        
        local latency = client.latency() * 1000  
        
        table.insert(ping_compensator.stats.samples, {
            rtt = latency,
            time = now
        })
        
        
        while #ping_compensator.stats.samples > 0 and
            (now - ping_compensator.stats.samples[1].time > ping_compensator.config.sample_window or
            #ping_compensator.stats.samples > ping_compensator.config.max_samples) do
            table.remove(ping_compensator.stats.samples, 1)
        end
        
        if #ping_compensator.stats.samples < 10 then
            return ping_compensator.prediction
        end
        
        
        
        
        local samples = ping_compensator.stats.samples
        
        
        local sum = 0
        for _, s in ipairs(samples) do
            sum = sum + s.rtt
        end
        ping_compensator.stats.rtt_mean = sum / #samples
        
        
        local var_sum = 0
        local jitter_samples = {}
        
        for i, s in ipairs(samples) do
            var_sum = var_sum + (s.rtt - ping_compensator.stats.rtt_mean)^2
            
            if i > 1 then
                table.insert(jitter_samples, math.abs(s.rtt - samples[i-1].rtt))
            end
        end
        
        ping_compensator.stats.rtt_variance = var_sum / #samples
        
        if #jitter_samples > 0 then
            local jitter_sum = 0
            for _, j in ipairs(jitter_samples) do
                jitter_sum = jitter_sum + j
            end
            ping_compensator.stats.rtt_jitter = jitter_sum / #jitter_samples
        end
        
        
        
        
        
        local sorted_rtt = {}
        for _, s in ipairs(samples) do
            table.insert(sorted_rtt, s.rtt)
        end
        table.sort(sorted_rtt)
        
        
        local p05_idx = math.max(1, math.floor(#sorted_rtt * 0.05))
        local p95_idx = math.min(#sorted_rtt, math.ceil(#sorted_rtt * 0.95))
        
        local rtt_p05 = sorted_rtt[p05_idx]
        local rtt_p95 = sorted_rtt[p95_idx]
        
        ping_compensator.prediction.confidence_interval = {rtt_p05, rtt_p95}
        
        
        
        
        
        local optimal_rtt = ping_compensator.stats.rtt_mean + 
                            ping_compensator.stats.rtt_jitter * 1.5
        
        
        local cl_interp = cvar.cl_interp:get_float() * 1000  
        local cl_interp_ratio = cvar.cl_interp_ratio:get_float()
        local tickrate = 1 / globals.tickinterval()
        local interp_ms = math.max(cl_interp, cl_interp_ratio / tickrate * 1000)
        
        ping_compensator.prediction.optimal_leadtime = optimal_rtt + interp_ms
        
        
        local tickinterval_ms = globals.tickinterval() * 1000
        ping_compensator.prediction.compensation_ticks = 
            math.ceil(ping_compensator.prediction.optimal_leadtime / tickinterval_ms)
        
        return ping_compensator.prediction
    end

    local function get_ping_adjusted_prediction(base_prediction, prediction_ticks)
        local compensation = update_ping_compensation()
        
        
        local total_ticks = prediction_ticks + compensation.compensation_ticks
        
        
        local stability = 1.0
        if ping_compensator.stats.rtt_variance > 0 then
            local cv = math.sqrt(ping_compensator.stats.rtt_variance) / 
                    math.max(1, ping_compensator.stats.rtt_mean)
            stability = 1.0 / (1.0 + cv)
        end
        
        
        local ping_factor = 1.0 - math.min(0.3, ping_compensator.stats.rtt_mean / 300)
        
        return {
            adjusted_ticks = total_ticks,
            stability = stability,
            ping_factor = ping_factor,
            optimal_leadtime = compensation.optimal_leadtime,
            compensation_ticks = compensation.compensation_ticks
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

            local function update_server_cvars()
                
                local ok_unlag, maxunlag = pcall(function() return cvar.sv_maxunlag:get_float() end)
                local ok_teleport, teleport_dist = pcall(function() return cvar.sv_lagcompensation_teleport_dist:get_float() end)
                
                server_cvars.maxunlag = (ok_unlag and maxunlag) or 0.5
                server_cvars.lagcomp_teleport_dist = (ok_teleport and teleport_dist) or 64
                server_cvars.tickrate = math.floor(1 / globals.tickinterval() + 0.5)
                server_cvars.max_rewind_ticks = math.floor(server_cvars.maxunlag / globals.tickinterval())
                
                
                local ok_min, min_ratio = pcall(function() return cvar.sv_client_min_interp_ratio:get_float() end)
                local ok_max, max_ratio = pcall(function() return cvar.sv_client_max_interp_ratio:get_float() end)
                
                server_cvars.interp_min_ratio = (ok_min and min_ratio) or 1
                server_cvars.interp_max_ratio = (ok_max and max_ratio) or 2
            end        

    local function analyze_jitter_pattern(data)
        local result = {
            predictable = false,
            next_side = 0,
            pattern_type = "random",
            confidence = 0,
            delay_ticks = 0,
            entropy = 0,
            periodicity = 0,
            phase_lock = 0,
            autocorrelation = 0,
            stability = 0,
            timing_precision = 0,
            dominant_frequency = 0,
            phase_estimate = 0,
            fft_confidence = 0
        }
        
        if not data or not data.body or not data.body.history or #data.body.history < 8 then
            return result
        end
        
        local tickinterval = 1 / server_cvars.tickrate
        
        
        
        
        local signs = {}
        local sign_times = {}
        local velocities = {}
        local angles = {}
        local raw_yaws = {}
        
        for i = 1, #data.body.history do
            local yaw = data.body.history[i].yaw
            local sign = yaw > 0 and 1 or -1
            table.insert(signs, sign)
            table.insert(angles, yaw)
            table.insert(raw_yaws, yaw)
            table.insert(sign_times, data.body.history[i].time)
            
            if data.movement and data.movement.velocity_history and data.movement.velocity_history[i] then
                table.insert(velocities, data.movement.velocity_history[i].speed)
            end
        end
        
        
        
        
        local function calculate_adaptive_window()
            
            local base_window = math.min(32, #signs)
            
            
            local initial_flip_count = 0
            local check_size = math.min(16, #signs)
            
            for i = 2, check_size do
                if signs[i] ~= signs[i-1] then
                    initial_flip_count = initial_flip_count + 1
                end
            end
            
            local flip_rate = initial_flip_count / (check_size - 1)
            
            
            
            local adaptive_window
            
            if flip_rate > 0.7 then
                
                adaptive_window = math.max(8, math.floor(base_window * 0.5))
            elseif flip_rate > 0.4 then
                
                adaptive_window = math.max(12, math.floor(base_window * 0.75))
            elseif flip_rate > 0.2 then
                
                adaptive_window = base_window
            else
                
                adaptive_window = math.min(#signs, math.floor(base_window * 1.5))
            end
            
            
            if #sign_times >= 4 then
                local intervals = {}
                for i = 2, math.min(8, #sign_times) do
                    if signs[i] ~= signs[i-1] then
                        table.insert(intervals, sign_times[i] - sign_times[i-1])
                    end
                end
                
                if #intervals >= 2 then
                    local avg_interval = 0
                    for _, int in ipairs(intervals) do
                        avg_interval = avg_interval + int
                    end
                    avg_interval = avg_interval / #intervals
                    
                    
                    local samples_per_cycle = math.max(1, avg_interval / tickinterval)
                    local optimal_for_cycles = math.floor(samples_per_cycle * 3)
                    
                    
                    adaptive_window = math.floor((adaptive_window + optimal_for_cycles) / 2)
                end
            end
            
            return math.max(8, math.min(#signs, adaptive_window))
        end
        
        local window_size = calculate_adaptive_window()
        
        
        local windowed_signs = {}
        local windowed_angles = {}
        local windowed_times = {}
        local start_idx = math.max(1, #signs - window_size + 1)
        
        for i = start_idx, #signs do
            table.insert(windowed_signs, signs[i])
            table.insert(windowed_angles, angles[i])
            table.insert(windowed_times, sign_times[i])
        end
        
        
        
        
    local function compute_fft(signal)
        local n = #signal
        if n < 4 then return {}, 0, 0, {}, {} end
        
        
        local padded_n = 1
        while padded_n < n do
            padded_n = padded_n * 2
        end
        
        
        local real = {}
        local imag = {}
        
        
        for i = 1, padded_n do
            if i <= n then
                local window = 0.5 * (1 - math.cos(2 * math.pi * (i - 1) / math.max(1, n - 1)))
                real[i] = signal[i] * window
            else
                real[i] = 0
            end
            imag[i] = 0
        end
        
        
        local function bit_reverse(x, bits)
            local result = 0
            for i = 0, bits - 1 do
                if bit.band(x, bit.lshift(1, i)) ~= 0 then
                    result = bit.bor(result, bit.lshift(1, bits - 1 - i))
                end
            end
            return result
        end
        
        local bits = math.floor(math.log(padded_n) / math.log(2) + 0.5)
        
        
        local real_temp = {}
        local imag_temp = {}
        for i = 0, padded_n - 1 do
            local j = bit_reverse(i, bits)
            real_temp[i + 1] = real[j + 1] or 0
            imag_temp[i + 1] = imag[j + 1] or 0
        end
        real = real_temp
        imag = imag_temp
        
        
        local m = 1
        while m < padded_n do
            local wm_real = math.cos(-math.pi / m)
            local wm_imag = math.sin(-math.pi / m)
            
            for k = 0, padded_n - 1, m * 2 do
                local w_real = 1
                local w_imag = 0
                
                for j = 0, m - 1 do
                    local idx1 = k + j + 1
                    local idx2 = k + j + m + 1
                    
                    
                    if idx1 <= padded_n and idx2 <= padded_n and real[idx1] and real[idx2] and imag[idx1] and imag[idx2] then
                        local t_real = w_real * real[idx2] - w_imag * imag[idx2]
                        local t_imag = w_real * imag[idx2] + w_imag * real[idx2]
                        
                        local u_real = real[idx1]
                        local u_imag = imag[idx1]
                        
                        real[idx1] = u_real + t_real
                        imag[idx1] = u_imag + t_imag
                        real[idx2] = u_real - t_real
                        imag[idx2] = u_imag - t_imag
                    end
                    
                    
                    local new_w_real = w_real * wm_real - w_imag * wm_imag
                    local new_w_imag = w_real * wm_imag + w_imag * wm_real
                    w_real = new_w_real
                    w_imag = new_w_imag
                end
            end
            m = m * 2
        end
        
        
        local magnitudes = {}
        local max_mag = 0
        local max_idx = 1
        
        
        local half_n = math.floor(padded_n / 2)
        for i = 1, half_n do
            local r = real[i] or 0
            local im = imag[i] or 0
            local mag = math.sqrt(r^2 + im^2)
            magnitudes[i] = mag
            
            
            if i > 1 and mag > max_mag then
                max_mag = mag
                max_idx = i
            end
        end
        
        
        local tickinterval = globals.tickinterval() or (1/64)
        local sample_rate = 1 / tickinterval
        local freq_resolution = sample_rate / padded_n
        local dominant_freq = (max_idx - 1) * freq_resolution
        
        
        local total_power = 0
        local peak_power = 0
        
        for i = 2, half_n do
            local m = magnitudes[i] or 0
            total_power = total_power + m^2
        end
        
        
        for i = math.max(2, max_idx - 2), math.min(half_n, max_idx + 2) do
            local m = magnitudes[i] or 0
            peak_power = peak_power + m^2
        end
        
        local spectral_purity = total_power > 0 and (peak_power / total_power) or 0
        
        return magnitudes, dominant_freq, spectral_purity, real, imag
    end
        
        
        local fft_mags, dominant_freq, spectral_purity, fft_real, fft_imag = compute_fft(windowed_signs)
        
        result.dominant_frequency = dominant_freq
        result.fft_confidence = spectral_purity
        
        
        if dominant_freq > 0 and spectral_purity > 0.3 then
            result.delay_ticks = math.floor(1 / (dominant_freq * tickinterval) + 0.5)
            result.periodicity = dominant_freq
            
            if spectral_purity > 0.5 then
                result.predictable = true
                result.pattern_type = "fft_periodic"
            end
        end
        
        
        
        
        local function hilbert_transform(signal)
            local n = #signal
            if n < 4 then return signal, 0 end
            
            
            local mags, freq, purity, fft_r, fft_i = compute_fft(signal)
            
            if not fft_r or #fft_r < 4 then
                return signal, 0
            end
            
            local padded_n = #fft_r
            
            
            
            local analytic_real = {}
            local analytic_imag = {}
            
            for i = 1, padded_n do
                if i == 1 then
                    
                    analytic_real[i] = fft_r[i]
                    analytic_imag[i] = fft_i[i]
                elseif i <= math.floor(padded_n / 2) then
                    
                    analytic_real[i] = fft_r[i] * 2
                    analytic_imag[i] = fft_i[i] * 2
                elseif i == math.floor(padded_n / 2) + 1 and padded_n % 2 == 0 then
                    
                    analytic_real[i] = fft_r[i]
                    analytic_imag[i] = fft_i[i]
                else
                    
                    analytic_real[i] = 0
                    analytic_imag[i] = 0
                end
            end
            
            
            local function ifft(re, im)
                local n = #re
                if n < 2 then return re, im end
                
                
                for i = 1, n do
                    im[i] = -(im[i] or 0)
                end
                
                
                local bits = math.floor(math.log(n) / math.log(2) + 0.5)
                local function bit_reverse(x, b)
                    local r = 0
                    for i = 0, b - 1 do
                        if bit.band(x, bit.lshift(1, i)) ~= 0 then
                            r = bit.bor(r, bit.lshift(1, b - 1 - i))
                        end
                    end
                    return r
                end
                
                local re_t, im_t = {}, {}
                for i = 0, n - 1 do
                    local j = bit_reverse(i, bits)
                    re_t[i + 1] = re[j + 1] or 0
                    im_t[i + 1] = im[j + 1] or 0
                end
                re, im = re_t, im_t
                
                
                local m = 1
                while m < n do
                    local wm_r = math.cos(-math.pi / m)
                    local wm_i = math.sin(-math.pi / m)
                    
                    for k = 0, n - 1, m * 2 do
                        local w_r, w_i = 1, 0
                        for j = 0, m - 1 do
                            local i1, i2 = k + j + 1, k + j + m + 1
                            
                            
                            if i1 <= n and i2 <= n and re[i1] and re[i2] and im[i1] and im[i2] then
                                local t_r = w_r * re[i2] - w_i * im[i2]
                                local t_i = w_r * im[i2] + w_i * re[i2]
                                
                                re[i2] = re[i1] - t_r
                                im[i2] = im[i1] - t_i
                                re[i1] = re[i1] + t_r
                                im[i1] = im[i1] + t_i
                            end
                            
                            local nw_r = w_r * wm_r - w_i * wm_i
                            w_i = w_r * wm_i + w_i * wm_r
                            w_r = nw_r
                        end
                    end
                    m = m * 2
                end
                
                
                for i = 1, n do
                    re[i] = (re[i] or 0) / n
                    im[i] = -(im[i] or 0) / n
                end
                
                return re, im
            end
            
            local signal_real, signal_imag = ifft(analytic_real, analytic_imag)
            
            
            local phases = {}
            for i = 1, math.min(n, #signal_real) do
                local phase = math.atan2(signal_imag[i], signal_real[i])
                table.insert(phases, phase)
            end
            
            
            local unwrapped = {phases[1]}
            for i = 2, #phases do
                local diff = phases[i] - phases[i-1]
                while diff > math.pi do diff = diff - 2 * math.pi end
                while diff < -math.pi do diff = diff + 2 * math.pi end
                unwrapped[i] = unwrapped[i-1] + diff
            end
            
            
            local current_phase = unwrapped[#unwrapped] or 0
            
            
            local phase_velocity = 0
            if #unwrapped >= 2 then
                local sum_vel = 0
                local count = 0
                for i = math.max(2, #unwrapped - 5), #unwrapped do
                    sum_vel = sum_vel + (unwrapped[i] - unwrapped[i-1])
                    count = count + 1
                end
                phase_velocity = count > 0 and (sum_vel / count) or 0
            end
            
            return unwrapped, current_phase, phase_velocity
        end
        
        local phase_history, current_phase, phase_velocity = hilbert_transform(windowed_signs)
        
        result.phase_estimate = current_phase
        
        
        if result.predictable and result.delay_ticks > 0 then
            
            local interp_ticks = server_cvars.max_rewind_ticks or 12
            local phase_advance = phase_velocity * interp_ticks
            local predicted_phase = current_phase + phase_advance
            
            
            while predicted_phase > math.pi do predicted_phase = predicted_phase - 2 * math.pi end
            while predicted_phase < -math.pi do predicted_phase = predicted_phase + 2 * math.pi end
            
            
            result.next_side = predicted_phase > 0 and 58 or -58
            result.phase_lock = math.abs(math.cos(current_phase))  
        end
        
        
        
        
        local function enhanced_autocorrelation(seq)
            local n = #seq
            if n < 4 then return {}, 0, 0 end
            
            
            local mean = 0
            for _, v in ipairs(seq) do mean = mean + v end
            mean = mean / n
            
            local variance = 0
            for _, v in ipairs(seq) do variance = variance + (v - mean)^2 end
            variance = variance / n
            
            if variance < 0.001 then return {}, 0, 0 end
            
            
            local correlations = {}
            local best_lag = 0
            local best_corr = 0
            
            for lag = 1, math.floor(n / 2) do
                local sum = 0
                for i = 1, n - lag do
                    sum = sum + (seq[i] - mean) * (seq[i + lag] - mean)
                end
                local corr = sum / ((n - lag) * variance)
                correlations[lag] = corr
                
                if math.abs(corr) > math.abs(best_corr) then
                    best_corr = corr
                    best_lag = lag
                end
            end
            
            return correlations, best_lag, best_corr
        end
        
        local corr_map, best_lag, best_corr = enhanced_autocorrelation(windowed_signs)
        result.autocorrelation = best_corr
        
        
        if best_lag > 0 and result.delay_ticks > 0 then
            local lag_agreement = math.abs(best_lag - result.delay_ticks) <= 1
            if lag_agreement and math.abs(best_corr) > 0.5 then
                result.confidence = result.confidence + 0.15
                result.predictable = true
            end
        end
        
        
        
        
        local function calculate_entropy(sequence)
            if #sequence < 2 then return 1.0 end
            local counts = {}
            for _, v in ipairs(sequence) do
                counts[v] = (counts[v] or 0) + 1
            end
            
            local entropy = 0
            local total = #sequence
            local unique_values = 0
            
            for _, count in pairs(counts) do
                unique_values = unique_values + 1
                local p = count / total
                if p > 0 then
                    entropy = entropy - (p * math.log(p) / math.log(2))
                end
            end
            
            local max_entropy = unique_values > 1 and math.log(unique_values) / math.log(2) or 1
            return max_entropy > 0 and (entropy / max_entropy) or 0
        end
        
        result.entropy = calculate_entropy(windowed_signs)
        
        if result.entropy < 0.4 then
            result.predictable = true
        end
        
        
        
        
        local intervals = {}
        local flip_count = 0
        
        for i = 2, #windowed_signs do
            if windowed_signs[i] ~= windowed_signs[i-1] then
                flip_count = flip_count + 1
                if windowed_times[i] and windowed_times[i-1] then
                    table.insert(intervals, windowed_times[i] - windowed_times[i-1])
                end
            end
        end
        
        if #intervals >= 4 then
            local avg_interval = 0
            for _, int in ipairs(intervals) do
                avg_interval = avg_interval + int
            end
            avg_interval = avg_interval / #intervals
            
            local variance = 0
            for _, int in ipairs(intervals) do
                variance = variance + (int - avg_interval)^2
            end
            variance = variance / #intervals
            
            local std_dev = math.sqrt(variance)
            local cv = avg_interval > 0 and (std_dev / avg_interval) or 1
            
            result.stability = 1.0 - math.min(1.0, cv)
            result.timing_precision = 1.0 / (1.0 + cv)
            
            
            if cv < 0.18 and result.predictable then
                result.pattern_type = "fixed_fast_jitter"
                
                
                local timing_delay = math.floor(avg_interval / tickinterval + 0.5)
                
                
                if result.delay_ticks > 0 then
                    if math.abs(result.delay_ticks - timing_delay) <= 2 then
                        result.delay_ticks = math.floor((result.delay_ticks + timing_delay) / 2 + 0.5)
                    end
                else
                    result.delay_ticks = timing_delay
                end
            end
        end
        
        
        
        
        if result.predictable and result.delay_ticks > 0 then
            local current_sign = windowed_signs[#windowed_signs]
            local last_time = windowed_times[#windowed_times] or globals.realtime()
            
            
            if result.phase_estimate ~= 0 and phase_velocity ~= 0 then
                
                local cl_interp = cvar.cl_interp:get_float()
                local cl_interp_ratio = cvar.cl_interp_ratio:get_float()
                cl_interp_ratio = math.max(server_cvars.interp_min_ratio or 1, 
                                            math.min(server_cvars.interp_max_ratio or 2, cl_interp_ratio))
                local interp_time = math.max(cl_interp, cl_interp_ratio / server_cvars.tickrate)
                local interp_ticks = math.floor(interp_time / tickinterval)
                
                local lagcomp_offset = math.floor((server_cvars.max_rewind_ticks or 12) * 0.25)
                local total_offset = interp_ticks + lagcomp_offset
                
                local predicted_phase = result.phase_estimate + phase_velocity * total_offset
                
                
                while predicted_phase > math.pi do predicted_phase = predicted_phase - 2 * math.pi end
                while predicted_phase < -math.pi do predicted_phase = predicted_phase + 2 * math.pi end
                
                
                local phase_magnitude = math.abs(predicted_phase)
                local near_transition = phase_magnitude < 0.3 or phase_magnitude > (math.pi - 0.3)
                
                if near_transition then
                    
                    result.next_side = current_sign > 0 and -58 or 58
                else
                    
                    result.next_side = predicted_phase > 0 and 58 or -58
                end
                
                result.phase_lock = result.stability * result.timing_precision
                
            else
                
                local time_since_last = globals.realtime() - last_time
                local ticks_since = math.floor(time_since_last / tickinterval)
                local phase_in_cycle = ticks_since % (result.delay_ticks * 2)
                
                if phase_in_cycle < result.delay_ticks then
                    result.next_side = current_sign > 0 and 58 or -58
                else
                    result.next_side = current_sign > 0 and -58 or 58
                end
            end
            
            
            local base_confidence = 0.65
            
            
            if result.fft_confidence > 0.5 then
                base_confidence = base_confidence + result.fft_confidence * 0.15
            end
            
            
            local entropy_bonus = (1.0 - result.entropy) * 0.12
            base_confidence = base_confidence + entropy_bonus
            
            
            base_confidence = base_confidence + result.stability * 0.10
            
            
            if result.phase_lock > 0.7 then
                base_confidence = base_confidence + 0.08
            end
            
            
            if server_cvars.tickrate >= 128 then
                base_confidence = base_confidence + 0.05
            end
            
            result.confidence = func.fclamp(base_confidence, 0.5, 0.96)
            
        else
            
            result.pattern_type = "counter"
            result.next_side = windowed_signs[#windowed_signs] > 0 and -58 or 58
            result.confidence = 0.48 + (1.0 - result.entropy) * 0.12
        end
        
        return result
    end

    local function body_shot_resolver(ent, data)
        local pose = entity.get_prop(ent, "m_flPoseParameter", 11)
        if not pose then return 0, 0 end
        
        local body_yaw = (pose * 120) - 60
        
        local lp = entity.get_local_player()
        if not lp then return body_yaw > 0 and -58 or 58, 0.60 end
        
        local weapon = entity.get_player_weapon(lp)
        local weapon_class = weapon and entity.get_classname(weapon) or ""
        
        
        local ox, oy, oz = entity.get_prop(ent, "m_vecOrigin")
        local lx, ly, lz = entity.get_prop(lp, "m_vecOrigin")
        
        if not ox or not lx then
            return body_yaw > 0 and -58 or 58, 0.60
        end
        
        
        local distance = math.sqrt((ox-lx)^2 + (oy-ly)^2 + (oz-lz)^2)
        
        
        local vx, vy, vz = entity.get_prop(ent, "m_vecVelocity")
        local velocity = vx and math.sqrt(vx*vx + vy*vy) or 0
        
        
        
        
        local weapon_profiles = {
            deagle = {
                inaccuracy = 2.0,
                lead = 1.3,
                optimal_distance = 400,
                moving_penalty = 0.70,
                standing_bonus = 1.15,
                preferred_hitbox = "stomach"
            },
            pistol = {
                inaccuracy = 1.6,
                lead = 1.25,
                optimal_distance = 300,
                moving_penalty = 0.75,
                standing_bonus = 1.10,
                preferred_hitbox = "stomach"
            },
            scout = {
                inaccuracy = 1.15,
                lead = 1.2,
                optimal_distance = 800,
                moving_penalty = 0.92,
                standing_bonus = 1.12,
                preferred_hitbox = "chest"
            },
            awp = {
                inaccuracy = 1.0,
                lead = 1.1,
                optimal_distance = 1000,
                moving_penalty = 0.85,
                standing_bonus = 1.20,
                preferred_hitbox = "chest"
            },
            rifle = {
                inaccuracy = 1.2,
                lead = 1.15,
                optimal_distance = 600,
                moving_penalty = 0.88,
                standing_bonus = 1.08,
                preferred_hitbox = "chest"
            }
        }
        
        local function get_weapon_profile()
            local cl = weapon_class:lower()
            if cl:find("deagle") then return weapon_profiles.deagle, "deagle"
            elseif cl:find("ssg08") then return weapon_profiles.scout, "scout"
            elseif cl:find("awp") then return weapon_profiles.awp, "awp"
            elseif cl:find("glock") or cl:find("p250") or cl:find("elite") or 
                cl:find("fiveseven") or cl:find("tec9") or cl:find("usp") or 
                cl:find("hkp2000") or cl:find("cz75") then
                return weapon_profiles.pistol, "pistol"
            else
                return weapon_profiles.rifle, "rifle"
            end
        end
        
        local profile, weapon_type = get_weapon_profile()
        
        
        
        
        local function calculate_acceleration_prediction()
            if not data.body or not data.body.history then
                return 0, 0, 0
            end
            
            
            if not data._velocity_samples then
                data._velocity_samples = {}
            end
            
            
            table.insert(data._velocity_samples, {
                vx = vx or 0,
                vy = vy or 0,
                speed = velocity,
                time = globals.realtime()
            })
            
            
            while #data._velocity_samples > 20 do
                table.remove(data._velocity_samples, 1)
            end
            
            if #data._velocity_samples < 4 then
                return 0, 0, 0
            end
            
            
            local accel_samples = {}
            for i = 2, #data._velocity_samples do
                local curr = data._velocity_samples[i]
                local prev = data._velocity_samples[i-1]
                local dt = curr.time - prev.time
                
                if dt > 0.001 then
                    local ax = (curr.vx - prev.vx) / dt
                    local ay = (curr.vy - prev.vy) / dt
                    local a_mag = math.sqrt(ax*ax + ay*ay)
                    
                    table.insert(accel_samples, {
                        ax = ax,
                        ay = ay,
                        magnitude = a_mag,
                        direction = math.deg(math.atan2(ay, ax)),
                        time = curr.time
                    })
                end
            end
            
            if #accel_samples < 2 then
                return 0, 0, 0
            end
            
            
            local weighted_ax = 0
            local weighted_ay = 0
            local total_weight = 0
            local now = globals.realtime()
            
            for i, sample in ipairs(accel_samples) do
                
                local age = now - sample.time
                local weight = math.exp(-age * 5)  
                
                weighted_ax = weighted_ax + sample.ax * weight
                weighted_ay = weighted_ay + sample.ay * weight
                total_weight = total_weight + weight
            end
            
            if total_weight > 0 then
                weighted_ax = weighted_ax / total_weight
                weighted_ay = weighted_ay / total_weight
            end
            
            local avg_accel = math.sqrt(weighted_ax*weighted_ax + weighted_ay*weighted_ay)
            local accel_direction = math.deg(math.atan2(weighted_ay, weighted_ax))
            
            
            local accel_pattern = "none"
            local accel_confidence = 0
            
            if avg_accel > 500 then
                
                accel_pattern = "changing"
                accel_confidence = math.min(1.0, avg_accel / 2000)
            elseif avg_accel < 50 and velocity > 100 then
                
                accel_pattern = "constant"
                accel_confidence = 0.8
            elseif avg_accel > 200 and velocity < 50 then
                
                accel_pattern = "starting"
                accel_confidence = 0.7
            elseif avg_accel > 200 and velocity > 150 then
                
                accel_pattern = "stopping"
                accel_confidence = 0.75
            end
            
            
            local jerk = 0
            if #accel_samples >= 3 then
                local recent_accels = {}
                for i = math.max(1, #accel_samples - 4), #accel_samples do
                    table.insert(recent_accels, accel_samples[i].magnitude)
                end
                
                if #recent_accels >= 2 then
                    local accel_deltas = {}
                    for i = 2, #recent_accels do
                        table.insert(accel_deltas, recent_accels[i] - recent_accels[i-1])
                    end
                    
                    for _, d in ipairs(accel_deltas) do
                        jerk = jerk + math.abs(d)
                    end
                    jerk = jerk / #accel_deltas
                end
            end
            
            
            data._acceleration = {
                ax = weighted_ax,
                ay = weighted_ay,
                magnitude = avg_accel,
                direction = accel_direction,
                pattern = accel_pattern,
                confidence = accel_confidence,
                jerk = jerk
            }
            
            return weighted_ax, weighted_ay, avg_accel
        end
        
        local accel_x, accel_y, accel_mag = calculate_acceleration_prediction()
        
        
        
        
        local function analyze_animation_layers()
            local result = {
                lean_amount = 0,
                lean_direction = 0,  
                pose_type = "standing",
                animation_speed = 1.0,
                upper_body_yaw = 0,
                is_transitioning = false,
                confidence = 0.5
            }
            
            
            
            local lean_pose = entity.get_prop(ent, "m_flPoseParameter", 12)
            if lean_pose then
                
                result.lean_amount = (lean_pose - 0.5) * 2
                result.lean_direction = result.lean_amount > 0.1 and 1 or (result.lean_amount < -0.1 and -1 or 0)
            end
            
            
            local body_pitch = entity.get_prop(ent, "m_flPoseParameter", 0)
            if body_pitch then
                
                local pitch_offset = (body_pitch - 0.5) * 180
                if math.abs(pitch_offset) > 45 then
                    result.is_transitioning = true
                end
            end
            
            
            local move_yaw_pose = entity.get_prop(ent, "m_flPoseParameter", 6)
            if move_yaw_pose then
                result.upper_body_yaw = (move_yaw_pose - 0.5) * 360
            end
            
            
            local duck_amount = entity.get_prop(ent, "m_flDuckAmount") or 0
            if duck_amount > 0.5 then
                result.pose_type = "crouching"
                result.confidence = result.confidence + 0.1
            elseif duck_amount > 0.1 then
                result.pose_type = "transitioning"
                result.is_transitioning = true
            end
            
            
            local is_scoped = (entity.get_prop(ent, "m_bIsScoped") or 0) ~= 0
            if is_scoped then
                result.pose_type = "scoped"
                result.animation_speed = 0.7  
                result.confidence = result.confidence + 0.15
            end
            
            
            local is_defusing = (entity.get_prop(ent, "m_bIsDefusing") or 0) ~= 0
            if is_defusing then
                result.pose_type = "defusing"
                result.animation_speed = 0
                result.confidence = 0.95
            end
            
            
            local cycle = entity.get_prop(ent, "m_flCycle")
            if cycle then
                
                result.animation_phase = cycle
                
                
                if not data._last_cycle then
                    data._last_cycle = cycle
                    data._cycle_changes = 0
                else
                    local cycle_delta = math.abs(cycle - data._last_cycle)
                    if cycle_delta > 0.3 and cycle_delta < 0.7 then
                        data._cycle_changes = (data._cycle_changes or 0) + 1
                    end
                    data._last_cycle = cycle
                end
                
                if data._cycle_changes and data._cycle_changes > 5 then
                    result.is_transitioning = true
                    result.confidence = result.confidence * 0.8
                end
            end
            
            
            local sequence = entity.get_prop(ent, "m_nSequence")
            if sequence then
                
                if not data._sequence_history then
                    data._sequence_history = {}
                end
                
                table.insert(data._sequence_history, {
                    seq = sequence,
                    time = globals.realtime()
                })
                
                while #data._sequence_history > 30 do
                    table.remove(data._sequence_history, 1)
                end
                
                
                if #data._sequence_history >= 5 then
                    local unique_sequences = {}
                    for i = #data._sequence_history - 4, #data._sequence_history do
                        if data._sequence_history[i] then
                            unique_sequences[data._sequence_history[i].seq] = true
                        end
                    end
                    
                    local unique_count = 0
                    for _ in pairs(unique_sequences) do
                        unique_count = unique_count + 1
                    end
                    
                    if unique_count >= 4 then
                        result.is_transitioning = true
                        result.confidence = result.confidence * 0.7
                    end
                end
            end
            
            return result
        end
        
        local anim_data = analyze_animation_layers()
        
        
        
        
        local function calculate_hitbox_scores()
            local hitbox_scores = {
                chest = { base = 1.0, offset_z = 48, size = 1.0, hitbox_id = 2 },
                stomach = { base = 0.95, offset_z = 32, size = 1.25, hitbox_id = 3 },
                pelvis = { base = 0.85, offset_z = 16, size = 1.15, hitbox_id = 4 }
            }
            
            local scores = {}
            
            for name, hb in pairs(hitbox_scores) do
                local score = hb.base
                
                
                if velocity > 200 then
                    score = score * hb.size * 1.3
                elseif velocity > 100 then
                    score = score * hb.size * 1.15
                elseif velocity < 20 then
                    score = score * 1.1
                end
                
                
                if data._acceleration then
                    local accel = data._acceleration
                    
                    if accel.pattern == "changing" then
                        
                        score = score * hb.size * 1.2
                    elseif accel.pattern == "stopping" then
                        
                        score = score * 1.15
                    elseif accel.pattern == "starting" then
                        
                        if name == "stomach" then
                            score = score * 1.1
                        end
                    end
                    
                    
                    if accel.jerk > 500 then
                        score = score * hb.size * 1.15
                    end
                end
                
                
                if anim_data.lean_direction ~= 0 then
                    
                    if name == "chest" then
                        score = score * 0.9  
                    elseif name == "pelvis" then
                        score = score * 1.1  
                    end
                end
                
                if anim_data.pose_type == "crouching" then
                    
                    if name == "stomach" then
                        score = score * 1.2  
                    elseif name == "chest" then
                        score = score * 0.95  
                    end
                end
                
                if anim_data.is_transitioning then
                    
                    score = score * hb.size * 1.1
                end
                
                
                local dist_ratio = distance / profile.optimal_distance
                if dist_ratio > 1.5 then
                    score = score * hb.size * 0.9
                elseif dist_ratio < 0.5 then
                    score = score * 1.2
                end
                
                
                if name == profile.preferred_hitbox then
                    score = score * 1.25
                end
                
                
                local px, py, pz = ox, oy, oz + hb.offset_z
                local ex, ey, ez = client.eye_position()
                if ex then
                    local frac = client.trace_line(lp, ex, ey, ez, px, py, pz)
                    if frac and frac > 0.9 then
                        score = score * (0.5 + frac * 0.5)
                    else
                        score = score * 0.3
                    end
                end
                
                scores[name] = { score = score, hitbox_id = hb.hitbox_id }
            end
            
            return scores
        end
        
        local hitbox_result = calculate_hitbox_scores()
        local best_hitbox = "chest"
        local best_score = 0
        for name, data_score in pairs(hitbox_result) do
            if data_score.score > best_score then
                best_score = data_score.score
                best_hitbox = name
            end
        end
        
        
        data.body.optimal_hitbox = hitbox_result[best_hitbox].hitbox_id
        
        
        
        
        local function predict_body_yaw()
            if not data.body.history or #data.body.history < 4 then
                return body_yaw, 0.50
            end
            
            
            local recent_count = math.min(8, #data.body.history)
            local recent_sum = 0
            local recent_deltas = {}
            local weights_sum = 0
            
            for i = #data.body.history - recent_count + 1, #data.body.history do
                local idx = i - (#data.body.history - recent_count)
                local weight = idx / recent_count
                recent_sum = recent_sum + data.body.history[i].yaw * weight
                weights_sum = weights_sum + weight
                
                if i > #data.body.history - recent_count + 1 then
                    local delta = data.body.history[i].yaw - data.body.history[i-1].yaw
                    table.insert(recent_deltas, delta)
                end
            end
            
            local weighted_avg = weights_sum > 0 and (recent_sum / weights_sum) or body_yaw
            
            
            local delta_sum = 0
            for _, d in ipairs(recent_deltas) do
                delta_sum = delta_sum + d
            end
            local avg_delta = #recent_deltas > 0 and (delta_sum / #recent_deltas) or 0
            
            
            local variance = 0
            for _, d in ipairs(recent_deltas) do
                variance = variance + (d - avg_delta)^2
            end
            variance = #recent_deltas > 0 and (variance / #recent_deltas) or 0
            local stability = 1.0 / (1.0 + math.sqrt(variance) * 0.1)
            
            
            local move_prediction = 0
            if vx and velocity > 50 then
                local move_yaw = math.deg(math.atan2(vy, vx))
                local eye_yaw = select(2, entity.get_prop(ent, "m_angEyeAngles")) or 0
                local move_delta = func.aa_clamp(move_yaw - eye_yaw)
                
                local alignment = velocity / 250
                move_prediction = -move_delta * alignment * 0.4
                
                
                if data._acceleration and data._acceleration.magnitude > 100 then
                    local accel = data._acceleration
                    
                    
                    local future_vx = (vx or 0) + accel.ax * 0.1  
                    local future_vy = (vy or 0) + accel.ay * 0.1
                    local future_move_yaw = math.deg(math.atan2(future_vy, future_vx))
                    local future_delta = func.aa_clamp(future_move_yaw - eye_yaw)
                    
                    
                    local accel_weight = math.min(0.5, accel.magnitude / 1000)
                    move_prediction = move_prediction * (1 - accel_weight) + 
                                    (-future_delta * alignment * 0.4) * accel_weight
                end
            end
            
            
            local lean_adjustment = 0
            if anim_data.lean_direction ~= 0 then
                
                lean_adjustment = anim_data.lean_amount * 8  
            end
            
            
            local anim_adjustment = 0
            if anim_data.is_transitioning then
                
                anim_adjustment = (math.random() - 0.5) * 5  
            end
            
            
            local tickrate = server_cvars.tickrate or 64
            local cl_interp = cvar.cl_interp:get_float()
            local cl_interp_ratio = cvar.cl_interp_ratio:get_float()
            cl_interp_ratio = math.max(server_cvars.interp_min_ratio or 1, 
                                        math.min(server_cvars.interp_max_ratio or 2, cl_interp_ratio))
            local interp_time = math.max(cl_interp, cl_interp_ratio / tickrate)
            
            local timing_mult = profile.lead or 1.0
            local prediction_time = interp_time * timing_mult
            
            
            local predicted_yaw = weighted_avg + 
                                (avg_delta * prediction_time * 12) + 
                                move_prediction + 
                                lean_adjustment + 
                                anim_adjustment
            
            predicted_yaw = func.fclamp(predicted_yaw, -60, 60)
            
            
            local base_confidence = 0.60
            
            
            base_confidence = base_confidence + stability * 0.15
            
            
            if #data.body.history >= 10 then
                base_confidence = base_confidence + 0.08
            end
            
            
            if velocity > 150 then
                base_confidence = base_confidence * profile.moving_penalty
            elseif velocity < 20 then
                base_confidence = base_confidence * profile.standing_bonus
            end
            
            
            if data._acceleration then
                if data._acceleration.pattern == "constant" then
                    base_confidence = base_confidence + 0.08
                elseif data._acceleration.pattern == "changing" then
                    base_confidence = base_confidence * 0.85
                end
                
                
                if data._acceleration.jerk > 500 then
                    base_confidence = base_confidence * 0.90
                end
            end
            
            
            base_confidence = base_confidence * anim_data.confidence
            
            if anim_data.is_transitioning then
                base_confidence = base_confidence * 0.88
            end
            
            
            local dist_factor = 1.0 - math.abs(distance - profile.optimal_distance) / profile.optimal_distance * 0.3
            dist_factor = math.max(0.6, math.min(1.2, dist_factor))
            base_confidence = base_confidence * dist_factor
            
            
            if best_score > 0.8 then
                base_confidence = base_confidence + 0.08
            end
            
            return predicted_yaw, func.fclamp(base_confidence, 0.45, 0.92)
        end
        
        
        if not data.body.history then
            data.body.history = {}
        end
        
        table.insert(data.body.history, { yaw = body_yaw, time = globals.realtime() })
        while #data.body.history > 50 do
            table.remove(data.body.history, 1)
        end
        
        
        local predicted_yaw, confidence = predict_body_yaw()
        
        
        local resolver_side = predicted_yaw > 0 and 58 or -58
        
        
        local magnitude = math.abs(predicted_yaw)
        if magnitude < 20 then
            confidence = confidence * 0.85
            resolver_side = resolver_side * 0.7
        elseif magnitude > 50 then
            confidence = confidence * 1.08
        end
        
        
        local common_sides = {-58, -45, -30, 30, 45, 58}
        local closest_side = resolver_side
        local min_diff = 999
        for _, side in ipairs(common_sides) do
            local diff = math.abs(resolver_side - side)
            if diff < min_diff then
                min_diff = diff
                closest_side = side
            end
        end
        
        if min_diff < 10 then
            resolver_side = closest_side
        end
        
        return resolver_side, confidence
    end


            local function body_delta_method(ent, data)
                local pose = entity.get_prop(ent, "m_flPoseParameter", 11)
                if not pose then return 0, 0 end
                
                local body_yaw = (pose * 120) - 60
                local cl_interp = cvar.cl_interp:get_float()
                local cl_interp_ratio = cvar.cl_interp_ratio:get_float()
                local tickrate = 1 / globals.tickinterval()
                local interp_time = math.max(cl_interp, cl_interp_ratio / tickrate)
                
                
                local vx, vy, vz = entity.get_prop(ent, "m_vecVelocity")
                local velocity = vx and math.sqrt(vx*vx + vy*vy) or 0
                
                if #data.body.history >= 3 then
                    local velocity_factor = 0
                    for i = 2, #data.body.history do
                        local dt = data.body.history[i].time - data.body.history[i-1].time
                        if dt > 0 then
                            velocity_factor = velocity_factor + (data.body.history[i].yaw - data.body.history[i-1].yaw) / dt
                        end
                    end
                    velocity_factor = velocity_factor / (#data.body.history - 1)
                    
                    
                    if vx and velocity > 50 then
                        local move_yaw = math.deg(math.atan2(vy, vx))
                        local eye_yaw = select(2, entity.get_prop(ent, "m_angEyeAngles")) or 0
                        local move_delta = func.aa_clamp(move_yaw - eye_yaw)
                        
                        
                        local alignment_speed = velocity / 250  
                        velocity_factor = velocity_factor + (move_delta * alignment_speed * 0.5)
                    end
                    
                    
                    local predicted_yaw = body_yaw + (velocity_factor * interp_time)
                    predicted_yaw = func.fclamp(predicted_yaw, -60, 60)
                    
                    
                    local confidence = 0.75
                    if velocity > 100 then
                        confidence = 0.82  
                    elseif velocity < 5 then
                        confidence = 0.68  
                    end
                    
                    return predicted_yaw > 0 and 58 or -58, confidence
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
                
                
                table.insert(data.movement.velocity_history, {
                    x = vx,
                    y = vy,
                    z = vz,
                    speed = speed,
                    time = globals.realtime()
                })
                
                if #data.movement.velocity_history > 30 then
                    table.remove(data.movement.velocity_history, 1)
                end
                
                
                if #data.movement.velocity_history < 5 then
                    return 0, 0
                end
                
                
                if speed < 5 then
                    data.movement.strafe_detected = false
                    return 0, 0
                end
                
                local move_yaw = math.deg(math.atan2(vy, vx))
                
                
                local eye_yaw = select(2, entity.get_prop(ent, "m_angEyeAngles"))
                if not eye_yaw then return 0, 0 end
                
                
                local delta = func.aa_clamp(move_yaw - eye_yaw)
                
                
                local strafe_threshold = 25
                if math.abs(delta) > strafe_threshold then
                    data.movement.strafe_detected = true
                    data.movement.strafe_direction = delta > 0 and 1 or -1
                    
                    
                    if data.movement.last_direction ~= 0 and 
                    data.movement.last_direction ~= data.movement.strafe_direction then
                        data.movement.direction_changes = data.movement.direction_changes + 1
                    end
                    
                    data.movement.last_direction = data.movement.strafe_direction
                else
                    data.movement.strafe_detected = false
                    data.movement.strafe_direction = 0
                end
                
                
                if #data.movement.velocity_history >= 10 then
                    local speeds = {}
                    for _, v in ipairs(data.movement.velocity_history) do
                        table.insert(speeds, v.speed)
                    end
                    
                    data.movement.speed_variance = calculate_variance(speeds)
                    
                    
                    if data.movement.speed_variance > 10000 then
                        data.movement.jitter_detected = true
                    end
                end
                
                
                if #data.movement.velocity_history >= 2 then
                    local current = data.movement.velocity_history[#data.movement.velocity_history]
                    local previous = data.movement.velocity_history[#data.movement.velocity_history - 1]
                    
                    local dt = current.time - previous.time
                    if dt > 0 then
                        data.movement.acceleration = (current.speed - previous.speed) / dt
                        
                        
                        if current.speed < 10 and previous.speed > 100 then
                            data.movement.stop_detected = true
                        else
                            data.movement.stop_detected = false
                        end
                    end
                end
                
                
                if not data.movement.strafe_detected then
                    return 0, 0
                end
                
                
                local body_yaw = 0
                local pose = entity.get_prop(ent, "m_flPoseParameter", 11)
                if pose then
                    body_yaw = (pose * 120) - 60
                end
                
                
                local prediction = 0
                local confidence = 0
                
                if speed > 100 then
                    
                    if data.movement.strafe_direction > 0 then
                        
                        prediction = -58
                    else
                        
                        prediction = 58
                    end
                    
                    confidence = 0.70
                    
                    
                    if (prediction > 0 and body_yaw < 0) or (prediction < 0 and body_yaw > 0) then
                        confidence = 0.75
                    end
                    
                    
                    if data.movement.direction_changes > 5 then
                        confidence = confidence * 0.7
                    end
                    
                elseif speed > 50 then
                    
                    prediction = data.movement.strafe_direction > 0 and -45 or 45
                    confidence = 0.55
                else
                    return 0, 0
                end
                
                return prediction, confidence
            end        

    local function flip_pattern_detection(ent, data)
        local eye_yaw = select(2, entity.get_prop(ent, "m_angEyeAngles"))
        if not eye_yaw then return 0, 0 end
        
        local now = globals.realtime()
        local tickinterval = globals.tickinterval()
        
        
        
        
        if not data._flip_advanced then
            data._flip_advanced = {
                
                network = {
                    latency_samples = {},
                    jitter_estimate = 0,
                    jitter_variance = 0,
                    loss_detected = false,
                    last_update = 0,
                    smoothed_latency = 0,
                    packet_intervals = {},
                    interpolation_amount = 0
                },
                
                
                harmonics = {
                    fundamental_freq = 0,
                    harmonics_detected = {},
                    spectral_peaks = {},
                    phase_coherence = 0,
                    dominant_harmonic = 0,
                    harmonic_ratios = {},
                    last_analysis = 0
                },
                
                
                phase = {
                    current = 0,
                    velocity = 0,
                    acceleration = 0,
                    uncertainty = 1.0,
                    kalman_gain = 0.5,
                    process_noise = 0.1,
                    measurement_noise = 0.3,
                    estimate_covariance = 1.0
                },
                
                
                patterns = {
                    detected_sequences = {},
                    sequence_confidence = {},
                    transition_matrix = {},
                    state_history = {},
                    prediction_errors = {}
                },
                
                
                timing = {
                    flip_timestamps = {},
                    interval_histogram = {},
                    modal_interval = 0,
                    interval_stability = 0,
                    burst_detected = false,
                    burst_phase = 0
                }
            }
        end
        
        local adv = data._flip_advanced
        
        
        
        
        local function update_network_jitter()
            local latency = client.latency()
            local latency_ms = latency * 1000
            
            
            table.insert(adv.network.latency_samples, {
                latency = latency_ms,
                time = now
            })
            
            
            while #adv.network.latency_samples > 0 and 
                (now - adv.network.latency_samples[1].time) > 2.0 do
                table.remove(adv.network.latency_samples, 1)
            end
            
            if #adv.network.latency_samples < 5 then
                return 0, 0
            end
            
            
            local sum = 0
            for _, sample in ipairs(adv.network.latency_samples) do
                sum = sum + sample.latency
            end
            local mean_latency = sum / #adv.network.latency_samples
            
            
            local variance_sum = 0
            for _, sample in ipairs(adv.network.latency_samples) do
                variance_sum = variance_sum + (sample.latency - mean_latency)^2
            end
            local variance = variance_sum / #adv.network.latency_samples
            local jitter = math.sqrt(variance)
            
            
            local ipj_sum = 0
            local ipj_count = 0
            for i = 2, #adv.network.latency_samples do
                local diff = math.abs(adv.network.latency_samples[i].latency - 
                                    adv.network.latency_samples[i-1].latency)
                ipj_sum = ipj_sum + diff
                ipj_count = ipj_count + 1
            end
            local inter_packet_jitter = ipj_count > 0 and (ipj_sum / ipj_count) or 0
            
            
            local alpha = 0.2
            adv.network.jitter_estimate = adv.network.jitter_estimate * (1 - alpha) + jitter * alpha
            adv.network.jitter_variance = variance
            adv.network.smoothed_latency = adv.network.smoothed_latency * (1 - alpha) + mean_latency * alpha
            
            
            local recent = adv.network.latency_samples[#adv.network.latency_samples]
            if recent and recent.latency > mean_latency + 3 * jitter then
                adv.network.loss_detected = true
            else
                adv.network.loss_detected = false
            end
            
            
            local cl_interp = cvar.cl_interp:get_float()
            local cl_interp_ratio = cvar.cl_interp_ratio:get_float()
            local tickrate = 1 / tickinterval
            local interp_time = math.max(cl_interp, cl_interp_ratio / tickrate)
            adv.network.interpolation_amount = interp_time
            
            adv.network.last_update = now
            
            return jitter, inter_packet_jitter
        end
        
        local jitter_ms, ipj_ms = update_network_jitter()
        
        
        local jitter_ticks = (jitter_ms / 1000) / tickinterval
        
        
        
        
        table.insert(data.angles.yaw_history, {yaw = eye_yaw, time = now})
        if #data.angles.yaw_history > 60 then
            table.remove(data.angles.yaw_history, 1)
        end
        
        if #data.angles.yaw_history < 15 then return 0, 0 end
        
        
        
        
        local large_changes = 0
        local small_changes = 0
        local flip_events = {}
        
        for i = 2, #data.angles.yaw_history do
            local curr = data.angles.yaw_history[i]
            local prev = data.angles.yaw_history[i-1]
            local delta = math.abs(func.aa_clamp(curr.yaw - prev.yaw))
            
            table.insert(data.angles.yaw_deltas, delta)
            
            if delta > 40 then
                large_changes = large_changes + 1
                table.insert(flip_events, {
                    time = curr.time,
                    delta = delta,
                    direction = curr.yaw > prev.yaw and 1 or -1,
                    from_yaw = prev.yaw,
                    to_yaw = curr.yaw
                })
                
                
                table.insert(adv.timing.flip_timestamps, curr.time)
            elseif delta > 5 and delta <= 40 then
                small_changes = small_changes + 1
                data.angles.micro_adjustments = data.angles.micro_adjustments + 1
            end
        end
        
        if #data.angles.yaw_deltas > 60 then
            table.remove(data.angles.yaw_deltas, 1)
        end
        
        
        while #adv.timing.flip_timestamps > 0 and 
            (now - adv.timing.flip_timestamps[1]) > 5.0 do
            table.remove(adv.timing.flip_timestamps, 1)
        end
        
        
        if #data.angles.yaw_deltas > 5 then
            local sum = 0
            for _, d in ipairs(data.angles.yaw_deltas) do
                sum = sum + d
            end
            data.angles.jitter_amplitude = sum / #data.angles.yaw_deltas
        end
        
        
        
        
        local function analyze_intervals()
            if #adv.timing.flip_timestamps < 3 then
                return nil, 0
            end
            
            local intervals = {}
            for i = 2, #adv.timing.flip_timestamps do
                local interval = adv.timing.flip_timestamps[i] - adv.timing.flip_timestamps[i-1]
                if interval > 0.01 and interval < 2.0 then
                    table.insert(intervals, interval)
                end
            end
            
            if #intervals < 2 then
                return nil, 0
            end
            
            
            local histogram = {}
            local bin_size = 0.02  
            
            for _, interval in ipairs(intervals) do
                local bin = math.floor(interval / bin_size)
                histogram[bin] = (histogram[bin] or 0) + 1
            end
            
            
            local max_count = 0
            local modal_bin = 0
            for bin, count in pairs(histogram) do
                if count > max_count then
                    max_count = count
                    modal_bin = bin
                end
            end
            
            local modal_interval = (modal_bin + 0.5) * bin_size
            adv.timing.modal_interval = modal_interval
            
            
            local within_tolerance = 0
            local tolerance = bin_size * 2  
            
            for _, interval in ipairs(intervals) do
                if math.abs(interval - modal_interval) < tolerance then
                    within_tolerance = within_tolerance + 1
                end
            end
            
            local stability = within_tolerance / #intervals
            adv.timing.interval_stability = stability
            
            
            local burst_threshold = modal_interval * 0.3
            local burst_count = 0
            
            for i = 2, #intervals do
                if intervals[i] < burst_threshold and intervals[i-1] < burst_threshold then
                    burst_count = burst_count + 1
                end
            end
            
            adv.timing.burst_detected = burst_count > 2
            
            return modal_interval, stability
        end
        
        local modal_interval, interval_stability = analyze_intervals()
        
        
        
        
        local function perform_harmonic_analysis()
            if #data.angles.yaw_history < 20 then
                return
            end
            
            
            if now - adv.harmonics.last_analysis < 0.5 then
                return
            end
            adv.harmonics.last_analysis = now
            
            
            local signal = {}
            local mean_yaw = 0
            
            for _, entry in ipairs(data.angles.yaw_history) do
                mean_yaw = mean_yaw + entry.yaw
            end
            mean_yaw = mean_yaw / #data.angles.yaw_history
            
            for _, entry in ipairs(data.angles.yaw_history) do
                table.insert(signal, entry.yaw - mean_yaw)
            end
            
            local n = #signal
            local sample_rate = 1 / tickinterval  
            
            
            local function compute_dft_bin(freq)
                local real_sum = 0
                local imag_sum = 0
                
                for i = 1, n do
                    local angle = -2 * math.pi * freq * (i - 1) / sample_rate
                    real_sum = real_sum + signal[i] * math.cos(angle)
                    imag_sum = imag_sum + signal[i] * math.sin(angle)
                end
                
                local magnitude = math.sqrt(real_sum^2 + imag_sum^2) / n
                local phase = math.atan2(imag_sum, real_sum)
                
                return magnitude, phase
            end
            
            
            local freq_candidates = {}
            
            
            if modal_interval and modal_interval > 0 then
                local fundamental = 1 / (modal_interval * 2)  
                
                
                for harmonic = 1, 5 do
                    local freq = fundamental * harmonic
                    if freq < sample_rate / 2 then  
                        local mag, phase = compute_dft_bin(freq)
                        table.insert(freq_candidates, {
                            frequency = freq,
                            harmonic_number = harmonic,
                            magnitude = mag,
                            phase = phase
                        })
                    end
                end
            else
                
                for freq = 1, 20, 0.5 do
                    local mag, phase = compute_dft_bin(freq)
                    if mag > 5 then  
                        table.insert(freq_candidates, {
                            frequency = freq,
                            harmonic_number = 0,  
                            magnitude = mag,
                            phase = phase
                        })
                    end
                end
            end
            
            
            table.sort(freq_candidates, function(a, b) 
                return a.magnitude > b.magnitude 
            end)
            
            
            adv.harmonics.spectral_peaks = {}
            for i = 1, math.min(5, #freq_candidates) do
                table.insert(adv.harmonics.spectral_peaks, freq_candidates[i])
            end
            
            
            if #freq_candidates > 0 then
                adv.harmonics.fundamental_freq = freq_candidates[1].frequency
                adv.harmonics.dominant_harmonic = freq_candidates[1].harmonic_number
                
                
                if #freq_candidates >= 2 then
                    local phase_diffs = {}
                    for i = 2, math.min(4, #freq_candidates) do
                        local expected_phase = freq_candidates[1].phase * freq_candidates[i].harmonic_number
                        local actual_phase = freq_candidates[i].phase
                        local diff = math.abs(actual_phase - expected_phase)
                        while diff > math.pi do diff = diff - 2 * math.pi end
                        table.insert(phase_diffs, math.abs(diff))
                    end
                    
                    local coherence = 0
                    for _, diff in ipairs(phase_diffs) do
                        coherence = coherence + (1 - diff / math.pi)
                    end
                    adv.harmonics.phase_coherence = #phase_diffs > 0 and (coherence / #phase_diffs) or 0
                end
                
                
                adv.harmonics.harmonic_ratios = {}
                if freq_candidates[1].magnitude > 0 then
                    for i = 2, math.min(5, #freq_candidates) do
                        adv.harmonics.harmonic_ratios[i-1] = freq_candidates[i].magnitude / freq_candidates[1].magnitude
                    end
                end
            end
        end
        
        perform_harmonic_analysis()
        
        
        
        
        local function kalman_phase_update(measured_phase)
            local phase = adv.phase
            
            
            local jitter_factor = 1 + (jitter_ticks * 0.1)
            local adjusted_process_noise = phase.process_noise * jitter_factor
            
            
            local predicted_phase = phase.current + phase.velocity * tickinterval
            local predicted_velocity = phase.velocity + phase.acceleration * tickinterval
            local predicted_covariance = phase.estimate_covariance + adjusted_process_noise
            
            
            local adjusted_measurement_noise = phase.measurement_noise
            if adv.network.loss_detected then
                adjusted_measurement_noise = adjusted_measurement_noise * 3
            end
            adjusted_measurement_noise = adjusted_measurement_noise * (1 + jitter_ticks * 0.05)
            
            
            local innovation = measured_phase - predicted_phase
            
            
            while innovation > math.pi do innovation = innovation - 2 * math.pi end
            while innovation < -math.pi do innovation = innovation + 2 * math.pi end
            
            local kalman_gain = predicted_covariance / (predicted_covariance + adjusted_measurement_noise)
            
            phase.current = predicted_phase + kalman_gain * innovation
            phase.estimate_covariance = (1 - kalman_gain) * predicted_covariance
            phase.kalman_gain = kalman_gain
            
            
            local velocity_innovation = innovation / tickinterval
            phase.velocity = predicted_velocity + kalman_gain * 0.3 * velocity_innovation
            
            
            phase.uncertainty = math.sqrt(phase.estimate_covariance + adjusted_measurement_noise)
            
            
            table.insert(adv.patterns.prediction_errors, {
                error = math.abs(innovation),
                time = now
            })
            
            while #adv.patterns.prediction_errors > 50 do
                table.remove(adv.patterns.prediction_errors, 1)
            end
            
            return phase.current, phase.uncertainty
        end
        
        
        
        
        local function classify_flip_pattern()
            local pattern = {
                type = "unknown",
                confidence = 0,
                period = 0,
                phase = 0,
                is_harmonic = false,
                harmonic_order = 1
            }
            
            
            if not modal_interval or modal_interval <= 0 then
                return pattern
            end
            
            
            if interval_stability > 0.6 then
                pattern.type = "periodic"
                pattern.period = modal_interval * 2  
                pattern.confidence = interval_stability
                
                
                if adv.harmonics.phase_coherence > 0.5 then
                    pattern.is_harmonic = true
                    pattern.harmonic_order = adv.harmonics.dominant_harmonic
                    pattern.confidence = pattern.confidence * (0.8 + adv.harmonics.phase_coherence * 0.2)
                end
            elseif interval_stability > 0.35 then
                pattern.type = "quasi-periodic"
                pattern.period = modal_interval * 2
                pattern.confidence = interval_stability * 0.8
            elseif adv.timing.burst_detected then
                pattern.type = "burst"
                pattern.confidence = 0.55
            else
                pattern.type = "random"
                pattern.confidence = 0.3
            end
            
            
            local network_penalty = math.min(0.25, jitter_ticks * 0.02)
            pattern.confidence = pattern.confidence * (1 - network_penalty)
            
            if adv.network.loss_detected then
                pattern.confidence = pattern.confidence * 0.7
            end
            
            return pattern
        end
        
        local flip_pattern = classify_flip_pattern()
        
        
        
        
        local function predict_next_state()
            local prediction = {
                side = 0,
                confidence = 0,
                phase = 0,
                uncertainty = 1.0
            }
            
            if flip_pattern.type == "unknown" or flip_pattern.confidence < 0.3 then
                
                local pose = entity.get_prop(ent, "m_flPoseParameter", 11)
                if pose then
                    local body_yaw = (pose * 120) - 60
                    prediction.side = body_yaw > 0 and -58 or 58
                    prediction.confidence = 0.45
                end
                return prediction
            end
            
            
            local current_yaw = data.angles.yaw_history[#data.angles.yaw_history].yaw
            local current_sign = current_yaw > 0 and 1 or -1
            
            
            local time_since_flip = 0
            if #adv.timing.flip_timestamps > 0 then
                time_since_flip = now - adv.timing.flip_timestamps[#adv.timing.flip_timestamps]
            end
            
            
            local cycle_phase = 0
            if flip_pattern.period > 0 then
                cycle_phase = (time_since_flip / flip_pattern.period) % 1.0
            end
            
            
            local measured_phase = cycle_phase * 2 * math.pi
            local filtered_phase, phase_uncertainty = kalman_phase_update(measured_phase)
            
            
            local total_delay = adv.network.smoothed_latency / 1000  
            total_delay = total_delay + adv.network.interpolation_amount
            total_delay = total_delay + jitter_ms / 1000 * 1.5  
            
            local prediction_ticks = math.floor(total_delay / tickinterval)
            
            
            local phase_advance = 0
            if flip_pattern.period > 0 then
                phase_advance = (prediction_ticks * tickinterval / flip_pattern.period) * 2 * math.pi
            end
            
            local predicted_phase = filtered_phase + phase_advance
            
            
            predicted_phase = predicted_phase % (2 * math.pi)
            
            
            
            if predicted_phase < math.pi then
                prediction.side = current_sign > 0 and 58 or -58
            else
                prediction.side = current_sign > 0 and -58 or 58
            end
            
            
            if flip_pattern.is_harmonic and flip_pattern.harmonic_order > 1 then
                
                local harmonic_phase = (predicted_phase * flip_pattern.harmonic_order) % (2 * math.pi)
                
                
                local harmonic_weight = math.min(0.4, adv.harmonics.phase_coherence * 0.5)
                
                if harmonic_phase < math.pi then
                    
                    prediction.confidence = prediction.confidence + harmonic_weight * 0.15
                else
                    
                    prediction.confidence = prediction.confidence * (1 - harmonic_weight * 0.3)
                end
            end
            
            
            prediction.confidence = flip_pattern.confidence
            
            
            local uncertainty_factor = 1.0 / (1.0 + phase_uncertainty * 2)
            prediction.confidence = prediction.confidence * uncertainty_factor
            
            
            local horizon_factor = 1.0 / (1.0 + prediction_ticks * 0.02)
            prediction.confidence = prediction.confidence * horizon_factor
            
            
            local phase_distance_to_transition = math.min(
                predicted_phase,
                math.abs(predicted_phase - math.pi),
                2 * math.pi - predicted_phase
            )
            
            if phase_distance_to_transition < 0.3 then
                
                local transition_penalty = 1.0 - (0.3 - phase_distance_to_transition) / 0.3 * 0.3
                prediction.confidence = prediction.confidence * transition_penalty
            end
            
            
            if #adv.patterns.prediction_errors >= 5 then
                local recent_errors = {}
                for i = math.max(1, #adv.patterns.prediction_errors - 10), #adv.patterns.prediction_errors do
                    table.insert(recent_errors, adv.patterns.prediction_errors[i].error)
                end
                
                local avg_error = 0
                for _, err in ipairs(recent_errors) do
                    avg_error = avg_error + err
                end
                avg_error = avg_error / #recent_errors
                
                
                local error_penalty = math.max(0.7, 1.0 - avg_error * 0.2)
                prediction.confidence = prediction.confidence * error_penalty
            end
            
            prediction.phase = predicted_phase
            prediction.uncertainty = phase_uncertainty
            
            return prediction
        end
        
        local state_prediction = predict_next_state()
        
        
        
        
        if flip_pattern.type ~= "unknown" and flip_pattern.period > 0 then
            data.angles.flip_detected = true
            data.angles.flip_interval = flip_pattern.period / 2  
            data.angles.dominant_frequency = 1 / flip_pattern.period
            data.angles.phase_offset = state_prediction.phase
        else
            data.angles.flip_detected = false
        end
        
        
        
        
        if data.angles.micro_adjustments > 10 and large_changes < 3 then
            
            local pose = entity.get_prop(ent, "m_flPoseParameter", 11)
            if pose then
                local body_yaw = (pose * 120) - 60
                
                
                local counter_side = body_yaw > 0 and -58 or 58
                local micro_confidence = 0.55 + math.min(0.15, data.angles.micro_adjustments * 0.005)
                
                
                if adv.network.loss_detected then
                    micro_confidence = micro_confidence * 0.8
                end
                
                return counter_side, micro_confidence
            end
        end
        
        
        
        
        if state_prediction.confidence > 0.4 then
            return state_prediction.side, func.fclamp(state_prediction.confidence, 0.40, 0.88)
        end
        
        
        data.angles.flip_detected = false
        return 0, 0
    end


    local function markov_learning(ent, data)
        if #data.shots < resolver.config.min_shots then
            return 0, 0
        end
        
        local now = globals.realtime()
        
        
        
        
        if not data.patterns.markov_extended then
            data.patterns.markov_extended = {
                
                ngrams = {
                    [2] = {},  
                    [3] = {},  
                    [4] = {},  
                    [5] = {}   
                },
                
                
                angle_transitions = {},
                
                
                temporal_transitions = {},
                
                
                angle_sequence = {},
                
                
                stats = {
                    total_transitions = 0,
                    last_decay = now,
                    decay_interval = 30,  
                    decay_factor = 0.92
                }
            }
        end
        
        local ext = data.patterns.markov_extended
        
        
        
        
        local function angle_to_bucket(angle)
            
            if angle <= -45 then return "L3"      
            elseif angle <= -30 then return "L2"  
            elseif angle <= -15 then return "L1"  
            elseif angle <= 15 then return "C"    
            elseif angle <= 30 then return "R1"   
            elseif angle <= 45 then return "R2"   
            else return "R3" end                   
        end
        
        local function bucket_to_angle(bucket)
            local mapping = {
                L3 = -58, L2 = -38, L1 = -22, C = 0,
                R1 = 22, R2 = 38, R3 = 58
            }
            return mapping[bucket] or 0
        end
        
        
        
        
        local function sequence_to_key(seq)
            local parts = {}
            for _, s in ipairs(seq) do
                table.insert(parts, s)
            end
            return table.concat(parts, ">")
        end
        
        
        
        
        local function apply_temporal_decay()
            local stats = ext.stats
            
            if now - stats.last_decay < stats.decay_interval then
                return
            end
            
            stats.last_decay = now
            local decay = stats.decay_factor
            
            
            for n, ngram_table in pairs(ext.ngrams) do
                for key, transitions in pairs(ngram_table) do
                    for next_state, weight in pairs(transitions) do
                        ngram_table[key][next_state] = weight * decay
                        
                        
                        if ngram_table[key][next_state] < 0.01 then
                            ngram_table[key][next_state] = nil
                        end
                    end
                    
                    
                    local has_transitions = false
                    for _ in pairs(transitions) do
                        has_transitions = true
                        break
                    end
                    if not has_transitions then
                        ngram_table[key] = nil
                    end
                end
            end
            
            
            for from_angle, transitions in pairs(ext.angle_transitions) do
                for to_angle, entry in pairs(transitions) do
                    entry.weight = entry.weight * decay
                    entry.hits = entry.hits * decay
                    entry.total = entry.total * decay
                    
                    if entry.weight < 0.01 then
                        ext.angle_transitions[from_angle][to_angle] = nil
                    end
                end
            end
            
            
            for key, entry in pairs(ext.temporal_transitions) do
                entry.weight = entry.weight * decay
                
                if entry.weight < 0.01 then
                    ext.temporal_transitions[key] = nil
                end
            end
            
            
            for key, weight in pairs(data.patterns.markov_chain) do
                data.patterns.markov_chain[key] = weight * decay
                if data.patterns.markov_chain[key] < 0.01 then
                    data.patterns.markov_chain[key] = nil
                end
            end
            
            for key, weight in pairs(data.patterns.temporal_weights) do
                data.patterns.temporal_weights[key] = weight * decay
                if data.patterns.temporal_weights[key] < 0.01 then
                    data.patterns.temporal_weights[key] = nil
                end
            end
        end
        
        apply_temporal_decay()
        
        
        
        
        local function update_angle_sequence()
            
            local new_sequence = {}
            local max_sequence_len = 20
            
            for i = math.max(1, #data.shots - max_sequence_len + 1), #data.shots do
                local shot = data.shots[i]
                if shot.actual_side then
                    local bucket = angle_to_bucket(shot.actual_side)
                    table.insert(new_sequence, {
                        bucket = bucket,
                        angle = shot.actual_side,
                        hit = shot.hit,
                        time = shot.time,
                        predicted = shot.predicted_side
                    })
                end
            end
            
            ext.angle_sequence = new_sequence
        end
        
        update_angle_sequence()
        
        
        
        
        local function update_ngram_transitions()
            local seq = ext.angle_sequence
            if #seq < 3 then return end
            
            
            for n = 2, 5 do
                if #seq >= n then
                    
                    for i = 1, #seq - n do
                        
                        local context = {}
                        for j = i, i + n - 2 do
                            table.insert(context, seq[j].bucket)
                        end
                        
                        local context_key = sequence_to_key(context)
                        local next_state = seq[i + n - 1].bucket
                        local was_hit = seq[i + n - 1].hit
                        
                        
                        local age = now - (seq[i + n - 1].time or now)
                        local time_weight = math.exp(-age * 0.05)  
                        
                        
                        if not ext.ngrams[n][context_key] then
                            ext.ngrams[n][context_key] = {}
                        end
                        
                        local current = ext.ngrams[n][context_key][next_state] or 0
                        
                        
                        local update_weight = time_weight
                        if was_hit then
                            update_weight = update_weight * 1.5  
                        end
                        
                        ext.ngrams[n][context_key][next_state] = current + update_weight
                        ext.stats.total_transitions = ext.stats.total_transitions + 1
                    end
                end
            end
        end
        
        update_ngram_transitions()
        
        
        
        
        local function update_angle_transitions()
            local seq = ext.angle_sequence
            if #seq < 2 then return end
            
            for i = 2, #seq do
                local prev = seq[i-1]
                local curr = seq[i]
                
                local from_bucket = prev.bucket
                local to_bucket = curr.bucket
                
                
                local age = now - (curr.time or now)
                local time_weight = math.exp(-age * 0.03)  
                
                
                if not ext.angle_transitions[from_bucket] then
                    ext.angle_transitions[from_bucket] = {}
                end
                
                if not ext.angle_transitions[from_bucket][to_bucket] then
                    ext.angle_transitions[from_bucket][to_bucket] = {
                        weight = 0,
                        hits = 0,
                        total = 0,
                        avg_angle = 0
                    }
                end
                
                local entry = ext.angle_transitions[from_bucket][to_bucket]
                entry.weight = entry.weight + time_weight
                entry.total = entry.total + time_weight
                
                if curr.hit then
                    entry.hits = entry.hits + time_weight
                end
                
                
                local alpha = 0.3
                entry.avg_angle = entry.avg_angle * (1 - alpha) + curr.angle * alpha
            end
        end
        
        update_angle_transitions()
        
        
        
        
        local function update_temporal_transitions()
            local seq = ext.angle_sequence
            if #seq < 3 then return end
            
            
            for i = 3, #seq do
                local t1 = seq[i-2].time or 0
                local t2 = seq[i-1].time or 0
                local t3 = seq[i].time or 0
                
                if t1 > 0 and t2 > 0 and t3 > 0 then
                    local dt1 = t2 - t1
                    local dt2 = t3 - t2
                    
                    
                    local dt1_bucket = math.floor(dt1 * 10)  
                    local dt2_bucket = math.floor(dt2 * 10)
                    
                    local time_pattern_key = string.format("t%d>t%d", dt1_bucket, dt2_bucket)
                    local next_bucket = seq[i].bucket
                    
                    local age = now - t3
                    local time_weight = math.exp(-age * 0.05)
                    
                    if not ext.temporal_transitions[time_pattern_key] then
                        ext.temporal_transitions[time_pattern_key] = {
                            weight = 0,
                            predictions = {}
                        }
                    end
                    
                    local entry = ext.temporal_transitions[time_pattern_key]
                    entry.weight = entry.weight + time_weight
                    entry.predictions[next_bucket] = (entry.predictions[next_bucket] or 0) + time_weight
                end
            end
        end
        
        update_temporal_transitions()
        
        
        
        
        local function predict_from_ngrams()
            local seq = ext.angle_sequence
            if #seq < 2 then return nil, 0 end
            
            local best_prediction = nil
            local best_confidence = 0
            local best_n = 0
            
            
            for n = 5, 2, -1 do
                if #seq >= n - 1 then
                    
                    local context = {}
                    for i = #seq - (n - 2), #seq do
                        table.insert(context, seq[i].bucket)
                    end
                    
                    local context_key = sequence_to_key(context)
                    local transitions = ext.ngrams[n][context_key]
                    
                    if transitions then
                        
                        local total = 0
                        local max_weight = 0
                        local max_state = nil
                        
                        for state, weight in pairs(transitions) do
                            total = total + weight
                            if weight > max_weight then
                                max_weight = weight
                                max_state = state
                            end
                        end
                        
                        if total > 0 and max_state then
                            local probability = max_weight / total
                            
                            
                            local sample_bonus = math.min(0.2, total / 20)
                            local n_bonus = (n - 2) * 0.05  
                            
                            local confidence = probability * 0.6 + sample_bonus + n_bonus
                            
                            if confidence > best_confidence then
                                best_confidence = confidence
                                best_prediction = bucket_to_angle(max_state)
                                best_n = n
                            end
                        end
                    end
                end
            end
            
            return best_prediction, best_confidence, best_n
        end
        
        
        
        
        local function predict_from_angle_transitions()
            local seq = ext.angle_sequence
            if #seq < 1 then return nil, 0 end
            
            local current_bucket = seq[#seq].bucket
            local transitions = ext.angle_transitions[current_bucket]
            
            if not transitions then return nil, 0 end
            
            local total_weight = 0
            local best_transition = nil
            local best_score = 0
            
            for to_bucket, entry in pairs(transitions) do
                total_weight = total_weight + entry.weight
                
                
                local hit_rate = entry.total > 0 and (entry.hits / entry.total) or 0.5
                local score = entry.weight * (0.5 + hit_rate * 0.5)
                
                if score > best_score then
                    best_score = score
                    best_transition = entry
                end
            end
            
            if not best_transition or total_weight < 1 then
                return nil, 0
            end
            
            local probability = best_score / total_weight
            local confidence = probability * 0.5 + math.min(0.3, total_weight / 30)
            
            return best_transition.avg_angle, confidence
        end
        
        
        
        
        local function predict_from_temporal()
            local seq = ext.angle_sequence
            if #seq < 2 then return nil, 0 end
            
            local t1 = seq[#seq - 1].time or 0
            local t2 = seq[#seq].time or 0
            
            if t1 == 0 or t2 == 0 then return nil, 0 end
            
            local dt = t2 - t1
            local dt_bucket = math.floor(dt * 10)
            
            
            local best_prediction = nil
            local best_confidence = 0
            
            for key, entry in pairs(ext.temporal_transitions) do
                if key:find("t%d+>t" .. dt_bucket) then
                    local total = 0
                    local max_weight = 0
                    local max_bucket = nil
                    
                    for bucket, weight in pairs(entry.predictions) do
                        total = total + weight
                        if weight > max_weight then
                            max_weight = weight
                            max_bucket = bucket
                        end
                    end
                    
                    if total > 0 and max_bucket then
                        local confidence = (max_weight / total) * 0.4 + math.min(0.2, entry.weight / 20)
                        
                        if confidence > best_confidence then
                            best_confidence = confidence
                            best_prediction = bucket_to_angle(max_bucket)
                        end
                    end
                end
            end
            
            return best_prediction, best_confidence
        end
        
        
        
        
        local function predict_from_hit_patterns()
            local window = resolver.config.pattern_window
            local start_idx = math.max(1, #data.shots - window)
            
            local left_hits, right_hits = 0, 0
            local left_total, right_total = 0, 0
            local left_recent, right_recent = 0, 0
            
            for i = start_idx, #data.shots do
                local shot = data.shots[i]
                if shot.hit ~= nil then
                    
                    local age = now - (shot.time or now)
                    local recency_weight = math.exp(-age * 0.1)
                    
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
            
            
            left_rate = left_rate + left_recent * 0.12
            right_rate = right_rate + right_recent * 0.12
            
            local max_rate = math.max(left_rate, right_rate)
            
            if max_rate < 0.4 then
                return nil, 0
            end
            
            local prediction = left_rate > right_rate and -58 or 58
            local confidence = math.min(max_rate * 0.8, 0.75)
            
            return prediction, confidence
        end
        
        
        
        
        local ngram_pred, ngram_conf, ngram_n = predict_from_ngrams()
        local angle_pred, angle_conf = predict_from_angle_transitions()
        local temporal_pred, temporal_conf = predict_from_temporal()
        local hit_pred, hit_conf = predict_from_hit_patterns()
        
        
        local predictions = {}
        
        if ngram_pred and ngram_conf > 0.2 then
            table.insert(predictions, {
                value = ngram_pred,
                confidence = ngram_conf,
                source = "ngram_" .. (ngram_n or 0),
                weight = 1.3  
            })
        end
        
        if angle_pred and angle_conf > 0.2 then
            table.insert(predictions, {
                value = angle_pred,
                confidence = angle_conf,
                source = "angle_transition",
                weight = 1.1
            })
        end
        
        if temporal_pred and temporal_conf > 0.15 then
            table.insert(predictions, {
                value = temporal_pred,
                confidence = temporal_conf,
                source = "temporal",
                weight = 0.9
            })
        end
        
        if hit_pred and hit_conf > 0.3 then
            table.insert(predictions, {
                value = hit_pred,
                confidence = hit_conf,
                source = "hit_pattern",
                weight = 1.0
            })
        end
        
        if #predictions == 0 then
            return 0, 0
        end
        
        
        local weighted_sum = 0
        local weight_sum = 0
        local agreement_count = 0
        local first_sign = nil
        
        for _, pred in ipairs(predictions) do
            local w = pred.confidence * pred.weight
            weighted_sum = weighted_sum + pred.value * w
            weight_sum = weight_sum + w
            
            
            local sign = pred.value > 0 and 1 or -1
            if first_sign == nil then
                first_sign = sign
            elseif sign == first_sign then
                agreement_count = agreement_count + 1
            end
        end
        
        if weight_sum == 0 then
            return 0, 0
        end
        
        local final_prediction = weighted_sum / weight_sum
        
        
        local avg_confidence = 0
        for _, pred in ipairs(predictions) do
            avg_confidence = avg_confidence + pred.confidence
        end
        avg_confidence = avg_confidence / #predictions
        
        
        local agreement_bonus = 0
        if #predictions >= 2 then
            agreement_bonus = (agreement_count / (#predictions - 1)) * 0.15
        end
        
        
        local source_bonus = math.min(0.1, (#predictions - 1) * 0.03)
        
        local final_confidence = math.min(0.92, avg_confidence + agreement_bonus + source_bonus)
        
        
        local snapped = final_prediction
        if math.abs(final_prediction) > 50 then
            snapped = final_prediction > 0 and 58 or -58
        elseif math.abs(final_prediction) > 35 then
            snapped = final_prediction > 0 and 45 or -45
        elseif math.abs(final_prediction) > 20 then
            snapped = final_prediction > 0 and 30 or -30
        elseif math.abs(final_prediction) > 10 then
            snapped = final_prediction > 0 and 15 or -15
        else
            snapped = 0
        end
        
        
        local distance = get_distance_to_player(ent)
        local context_key = string.format("dist_%d", math.floor(distance / 100))
        data.patterns.context_memory[context_key] = {
            side = snapped, 
            confidence = final_confidence,
            time = now
        }
        
        return snapped, final_confidence
    end


    local function detect_aa_type(ent, data)
        local characteristics = {}
        
        
        
        
        if not data._neural_aa then
            data._neural_aa = {
                
                feature_history = {},
                
                
                weights = {
                    jitter = {body_var = 0.3, yaw_delta = 0.25, flip_rate = 0.2, entropy = 0.15, timing = 0.1},
                    static = {body_var = -0.4, yaw_delta = -0.3, consistency = 0.4, duration = 0.2},
                    defensive = {tickbase = 0.5, rewind = 0.3, exploitation = 0.2},
                    micro_desync = {small_delta = 0.4, high_freq = 0.3, pose_jitter = 0.2, anim_noise = 0.1},
                    velocity_linked = {speed_corr = 0.4, strafe_sync = 0.3, accel_pattern = 0.2, direction_change = 0.1}
                },
                
                
                activations = {
                    jitter = {},
                    static = {},
                    defensive = {},
                    micro_desync = {},
                    velocity_linked = {},
                    flip = {},
                    minimal_jitter = {}
                },
                
                
                micro = {
                    pose_samples = {},
                    lean_samples = {},
                    body_micro_deltas = {},
                    high_freq_components = {},
                    last_analysis = 0
                },
                
                
                velocity_correlation = {
                    samples = {},
                    correlation_coefficient = 0,
                    lag_correlations = {},
                    adaptive_threshold = 0.35,
                    threshold_history = {}
                },
                
                
                combinations = {
                    detected = {},
                    confidence = 0,
                    primary = "unknown",
                    secondary = "none"
                }
            }
        end
        
        local neural = data._neural_aa
        local now = globals.realtime()
        
        
        
        
        local function extract_features()
            local features = {
                
                body_variance = 0,
                body_mean = 0,
                body_range = 0,
                body_flip_rate = 0,
                
                
                yaw_delta_mean = 0,
                yaw_delta_variance = 0,
                yaw_delta_max = 0,
                
                
                flip_interval_mean = 0,
                flip_interval_variance = 0,
                timing_consistency = 0,
                
                
                entropy = 0,
                complexity = 0,
                predictability = 0,
                
                
                micro_delta_mean = 0,
                micro_delta_variance = 0,
                high_freq_power = 0,
                pose_jitter_amount = 0,
                
                
                velocity_body_correlation = 0,
                strafe_sync_score = 0,
                accel_body_correlation = 0,
                
                
                tickbase_anomaly = 0,
                rewind_detected = 0,
                exploitation_score = 0
            }
            
            
            if data.body and data.body.history and #data.body.history >= 5 then
                local yaws = {}
                local deltas = {}
                local flip_times = {}
                local last_sign = nil
                
                for i, entry in ipairs(data.body.history) do
                    table.insert(yaws, entry.yaw)
                    
                    if i > 1 then
                        local delta = entry.yaw - data.body.history[i-1].yaw
                        table.insert(deltas, delta)
                        
                        
                        local sign = entry.yaw > 0 and 1 or -1
                        if last_sign and sign ~= last_sign then
                            table.insert(flip_times, entry.time)
                        end
                        last_sign = sign
                    end
                end
                
                
                local sum = 0
                local min_yaw, max_yaw = 999, -999
                for _, y in ipairs(yaws) do
                    sum = sum + y
                    min_yaw = math.min(min_yaw, y)
                    max_yaw = math.max(max_yaw, y)
                end
                features.body_mean = sum / #yaws
                features.body_range = max_yaw - min_yaw
                
                
                local var_sum = 0
                for _, y in ipairs(yaws) do
                    var_sum = var_sum + (y - features.body_mean)^2
                end
                features.body_variance = var_sum / #yaws
                
                
                features.body_flip_rate = #flip_times / math.max(1, #yaws - 1)
                
                
                if #deltas > 0 then
                    local delta_sum = 0
                    local delta_max = 0
                    for _, d in ipairs(deltas) do
                        delta_sum = delta_sum + math.abs(d)
                        delta_max = math.max(delta_max, math.abs(d))
                    end
                    features.yaw_delta_mean = delta_sum / #deltas
                    features.yaw_delta_max = delta_max
                    
                    local delta_var = 0
                    for _, d in ipairs(deltas) do
                        delta_var = delta_var + (math.abs(d) - features.yaw_delta_mean)^2
                    end
                    features.yaw_delta_variance = delta_var / #deltas
                end
                
                
                if #flip_times >= 2 then
                    local intervals = {}
                    for i = 2, #flip_times do
                        table.insert(intervals, flip_times[i] - flip_times[i-1])
                    end
                    
                    local int_sum = 0
                    for _, int in ipairs(intervals) do
                        int_sum = int_sum + int
                    end
                    features.flip_interval_mean = int_sum / #intervals
                    
                    local int_var = 0
                    for _, int in ipairs(intervals) do
                        int_var = int_var + (int - features.flip_interval_mean)^2
                    end
                    features.flip_interval_variance = int_var / #intervals
                    
                    
                    features.timing_consistency = 1.0 / (1.0 + math.sqrt(features.flip_interval_variance) * 5)
                end
            end
            
            
            if data.angles and data.angles.yaw_deltas and #data.angles.yaw_deltas >= 5 then
                
                local buckets = {}
                for _, delta in ipairs(data.angles.yaw_deltas) do
                    local bucket = math.floor(delta / 10)
                    buckets[bucket] = (buckets[bucket] or 0) + 1
                end
                
                local total = #data.angles.yaw_deltas
                local entropy = 0
                local unique_buckets = 0
                
                for _, count in pairs(buckets) do
                    unique_buckets = unique_buckets + 1
                    local p = count / total
                    if p > 0 then
                        entropy = entropy - p * math.log(p) / math.log(2)
                    end
                end
                
                local max_entropy = unique_buckets > 1 and math.log(unique_buckets) / math.log(2) or 1
                features.entropy = max_entropy > 0 and (entropy / max_entropy) or 0
                features.complexity = unique_buckets / 10
                features.predictability = 1.0 - features.entropy
            end
            
            return features
        end
        
        
        
        
        local function detect_micro_desync()
            local result = {
                detected = false,
                confidence = 0,
                type = "none",
                frequency = 0,
                amplitude = 0
            }
            
            
            local pose = entity.get_prop(ent, "m_flPoseParameter", 11)
            local lean_pose = entity.get_prop(ent, "m_flPoseParameter", 12)
            
            if pose then
                local body_yaw = (pose * 120) - 60
                
                table.insert(neural.micro.pose_samples, {
                    yaw = body_yaw,
                    lean = lean_pose or 0.5,
                    time = now
                })
                
                
                while #neural.micro.pose_samples > 60 do
                    table.remove(neural.micro.pose_samples, 1)
                end
            end
            
            if #neural.micro.pose_samples < 15 then
                return result
            end
            
            
            local micro_deltas = {}
            local high_freq_count = 0
            local micro_jitter_count = 0
            
            for i = 2, #neural.micro.pose_samples do
                local curr = neural.micro.pose_samples[i]
                local prev = neural.micro.pose_samples[i-1]
                local dt = curr.time - prev.time
                
                if dt > 0 and dt < 0.1 then  
                    local delta = math.abs(curr.yaw - prev.yaw)
                    local rate = delta / dt  
                    
                    table.insert(micro_deltas, {
                        delta = delta,
                        rate = rate,
                        time = curr.time
                    })
                    
                    
                    if delta > 0.5 and delta < 8 then
                        micro_jitter_count = micro_jitter_count + 1
                    end
                    
                    
                    if rate > 100 and delta < 15 then
                        high_freq_count = high_freq_count + 1
                    end
                end
            end
            
            if #micro_deltas < 5 then
                return result
            end
            
            
            neural.micro.body_micro_deltas = micro_deltas
            
            
            local delta_sum = 0
            local rate_sum = 0
            for _, md in ipairs(micro_deltas) do
                delta_sum = delta_sum + md.delta
                rate_sum = rate_sum + md.rate
            end
            local mean_delta = delta_sum / #micro_deltas
            local mean_rate = rate_sum / #micro_deltas
            
            
            local var_sum = 0
            for _, md in ipairs(micro_deltas) do
                var_sum = var_sum + (md.delta - mean_delta)^2
            end
            local delta_variance = var_sum / #micro_deltas
            
            
            local function estimate_high_freq_power()
                if #micro_deltas < 8 then return 0 end
                
                
                local second_derivs = {}
                for i = 3, #micro_deltas do
                    local d1 = micro_deltas[i].delta - micro_deltas[i-1].delta
                    local d2 = micro_deltas[i-1].delta - micro_deltas[i-2].delta
                    table.insert(second_derivs, math.abs(d1 - d2))
                end
                
                local power = 0
                for _, d in ipairs(second_derivs) do
                    power = power + d^2
                end
                
                return math.sqrt(power / math.max(1, #second_derivs))
            end
            
            local high_freq_power = estimate_high_freq_power()
            neural.micro.high_freq_components = {power = high_freq_power}
            
            
            local micro_jitter_ratio = micro_jitter_count / #micro_deltas
            local high_freq_ratio = high_freq_count / #micro_deltas
            
            
            if micro_jitter_ratio > 0.4 and mean_delta < 5 then
                result.type = "subtle_jitter"
                result.detected = true
                result.confidence = 0.65 + micro_jitter_ratio * 0.25
                result.frequency = mean_rate
                result.amplitude = mean_delta
                
            elseif high_freq_ratio > 0.3 and high_freq_power > 10 then
                result.type = "high_frequency"
                result.detected = true
                result.confidence = 0.60 + high_freq_ratio * 0.30
                result.frequency = mean_rate
                result.amplitude = mean_delta
                
            elseif delta_variance < 4 and mean_delta > 1 and mean_delta < 6 then
                result.type = "consistent_micro"
                result.detected = true
                result.confidence = 0.70
                result.frequency = mean_rate
                result.amplitude = mean_delta
                
            elseif micro_jitter_ratio > 0.25 and high_freq_power > 5 then
                result.type = "mixed_micro"
                result.detected = true
                result.confidence = 0.55 + (micro_jitter_ratio + high_freq_ratio) * 0.2
                result.frequency = mean_rate
                result.amplitude = mean_delta
            end
            
            return result
        end
        
        
        
        
        local function detect_velocity_linked_adaptive()
            local result = {
                detected = false,
                confidence = 0,
                correlation = 0,
                pattern_type = "none",
                adaptive_threshold = neural.velocity_correlation.adaptive_threshold
            }
            
            
            local vx, vy, vz = entity.get_prop(ent, "m_vecVelocity")
            if not vx then return result end
            
            local speed = math.sqrt(vx*vx + vy*vy)
            local move_yaw = math.deg(math.atan2(vy, vx))
            
            
            local pose = entity.get_prop(ent, "m_flPoseParameter", 11)
            if not pose then return result end
            local body_yaw = (pose * 120) - 60
            
            
            table.insert(neural.velocity_correlation.samples, {
                speed = speed,
                move_yaw = move_yaw,
                body_yaw = body_yaw,
                vx = vx,
                vy = vy,
                time = now
            })
            
            
            while #neural.velocity_correlation.samples > 50 do
                table.remove(neural.velocity_correlation.samples, 1)
            end
            
            local samples = neural.velocity_correlation.samples
            if #samples < 10 then return result end
            
            
            local function pearson_correlation(x_values, y_values)
                local n = math.min(#x_values, #y_values)
                if n < 3 then return 0 end
                
                local sum_x, sum_y = 0, 0
                for i = 1, n do
                    sum_x = sum_x + x_values[i]
                    sum_y = sum_y + y_values[i]
                end
                local mean_x = sum_x / n
                local mean_y = sum_y / n
                
                local cov = 0
                local var_x, var_y = 0, 0
                for i = 1, n do
                    local dx = x_values[i] - mean_x
                    local dy = y_values[i] - mean_y
                    cov = cov + dx * dy
                    var_x = var_x + dx * dx
                    var_y = var_y + dy * dy
                end
                
                local denom = math.sqrt(var_x * var_y)
                if denom < 0.001 then return 0 end
                
                return cov / denom
            end
            
            
            local speeds = {}
            local body_yaws = {}
            local move_yaws = {}
            
            for _, s in ipairs(samples) do
                table.insert(speeds, s.speed)
                table.insert(body_yaws, math.abs(s.body_yaw))  
                table.insert(move_yaws, s.move_yaw)
            end
            
            
            local speed_body_corr = math.abs(pearson_correlation(speeds, body_yaws))
            result.correlation = speed_body_corr
            
            
            local lag_correlations = {}
            for lag = 0, 5 do
                if #speeds > lag + 5 then
                    local lagged_speeds = {}
                    local lagged_bodies = {}
                    for i = 1, #speeds - lag do
                        table.insert(lagged_speeds, speeds[i])
                        table.insert(lagged_bodies, body_yaws[i + lag])
                    end
                    lag_correlations[lag] = math.abs(pearson_correlation(lagged_speeds, lagged_bodies))
                end
            end
            neural.velocity_correlation.lag_correlations = lag_correlations
            
            
            local best_lag = 0
            local best_lag_corr = speed_body_corr
            for lag, corr in pairs(lag_correlations) do
                if corr > best_lag_corr then
                    best_lag_corr = corr
                    best_lag = lag
                end
            end
            
            
            local strafe_sync_count = 0
            local direction_change_count = 0
            local last_direction = nil
            
            for i = 2, #samples do
                local curr = samples[i]
                local prev = samples[i-1]
                
                
                local strafe_dir = curr.move_yaw - prev.move_yaw
                local body_dir = curr.body_yaw - prev.body_yaw
                
                
                if (strafe_dir > 5 and body_dir > 2) or (strafe_dir < -5 and body_dir < -2) then
                    strafe_sync_count = strafe_sync_count + 1
                end
                
                
                local curr_dir = curr.speed > 50 and (curr.move_yaw > 0 and 1 or -1) or 0
                if last_direction and curr_dir ~= 0 and last_direction ~= curr_dir then
                    direction_change_count = direction_change_count + 1
                end
                if curr_dir ~= 0 then
                    last_direction = curr_dir
                end
            end
            
            local strafe_sync_ratio = strafe_sync_count / (#samples - 1)
            
            
            local accel_body_corr = 0
            if #samples >= 5 then
                local accels = {}
                local body_changes = {}
                
                for i = 3, #samples do
                    local accel = (samples[i].speed - samples[i-2].speed) / 
                                math.max(0.001, samples[i].time - samples[i-2].time)
                    local body_change = math.abs(samples[i].body_yaw - samples[i-2].body_yaw)
                    
                    table.insert(accels, math.abs(accel))
                    table.insert(body_changes, body_change)
                end
                
                accel_body_corr = math.abs(pearson_correlation(accels, body_changes))
            end
            
            
            
            
            local function update_adaptive_threshold()
                local current_threshold = neural.velocity_correlation.adaptive_threshold
                
                
                table.insert(neural.velocity_correlation.threshold_history, best_lag_corr)
                while #neural.velocity_correlation.threshold_history > 30 do
                    table.remove(neural.velocity_correlation.threshold_history, 1)
                end
                
                local history = neural.velocity_correlation.threshold_history
                if #history < 10 then return current_threshold end
                
                
                local sum = 0
                for _, c in ipairs(history) do
                    sum = sum + c
                end
                local mean = sum / #history
                
                local var_sum = 0
                for _, c in ipairs(history) do
                    var_sum = var_sum + (c - mean)^2
                end
                local std = math.sqrt(var_sum / #history)
                
                
                
                local new_threshold = mean + std * 0.5
                new_threshold = func.fclamp(new_threshold, 0.20, 0.55)
                
                
                local alpha = 0.15
                current_threshold = current_threshold * (1 - alpha) + new_threshold * alpha
                
                neural.velocity_correlation.adaptive_threshold = current_threshold
                return current_threshold
            end
            
            local adaptive_threshold = update_adaptive_threshold()
            result.adaptive_threshold = adaptive_threshold
            
            
            
            
            local detection_score = 0
            
            
            if best_lag_corr > adaptive_threshold then
                detection_score = detection_score + (best_lag_corr - adaptive_threshold) * 2
                
                if best_lag == 0 then
                    result.pattern_type = "instant_sync"
                else
                    result.pattern_type = "lagged_sync_" .. best_lag
                end
            end
            
            
            if strafe_sync_ratio > 0.35 then
                detection_score = detection_score + strafe_sync_ratio * 0.8
                if result.pattern_type == "none" then
                    result.pattern_type = "strafe_sync"
                end
            end
            
            
            if accel_body_corr > 0.30 then
                detection_score = detection_score + accel_body_corr * 0.6
                if result.pattern_type == "none" then
                    result.pattern_type = "accel_linked"
                end
            end
            
            
            local dir_change_ratio = direction_change_count / math.max(1, #samples - 1)
            if dir_change_ratio > 0.15 and best_lag_corr > 0.25 then
                detection_score = detection_score + 0.3
                result.pattern_type = result.pattern_type .. "_with_direction_changes"
            end
            
            
            if detection_score > 0.5 then
                result.detected = true
                result.confidence = func.fclamp(0.50 + detection_score * 0.3, 0.50, 0.92)
            end
            
            return result
        end
        
        
        
        
        local function neural_classify(features, micro_result, velocity_result)
            local activations = {}
            
            
            
            
            local jitter_input = 
                features.body_variance * neural.weights.jitter.body_var +
                features.yaw_delta_mean * neural.weights.jitter.yaw_delta * 0.02 +
                features.body_flip_rate * neural.weights.jitter.flip_rate +
                features.entropy * neural.weights.jitter.entropy +
                features.timing_consistency * neural.weights.jitter.timing
            activations.jitter = 1 / (1 + math.exp(-jitter_input * 3))  
            
            
            local static_input =
                -features.body_variance * neural.weights.static.body_var * 0.01 +
                -features.yaw_delta_mean * neural.weights.static.yaw_delta * 0.02 +
                features.predictability * neural.weights.static.consistency +
                (1 - features.body_flip_rate) * neural.weights.static.duration
            activations.static = 1 / (1 + math.exp(-static_input * 3))
            
            
            local defensive_input = 0
            if tbl.breaklc and tbl.breaklc.breaking then
                defensive_input = defensive_input + neural.weights.defensive.tickbase
            end
            if tbl.breaklc and tbl.breaklc.shift_rewind then
                defensive_input = defensive_input + neural.weights.defensive.rewind
            end
            if tbl.breaklc and tbl.breaklc.exploitation_window and tbl.breaklc.exploitation_window > 0 then
                defensive_input = defensive_input + neural.weights.defensive.exploitation * 
                                (tbl.breaklc.exploitation_window / 14)
            end
            activations.defensive = 1 / (1 + math.exp(-defensive_input * 4))
            
            
            local micro_input = 0
            if micro_result.detected then
                local amp_factor = func.fclamp(micro_result.amplitude / 5, 0, 1)
                local freq_factor = func.fclamp(micro_result.frequency / 200, 0, 1)
                
                micro_input = 
                    amp_factor * neural.weights.micro_desync.small_delta +
                    freq_factor * neural.weights.micro_desync.high_freq +
                    (micro_result.type == "subtle_jitter" and 0.3 or 0) +
                    micro_result.confidence * neural.weights.micro_desync.pose_jitter
            end
            activations.micro_desync = 1 / (1 + math.exp(-micro_input * 3))
            
            
            local velocity_input = 0
            if velocity_result.detected then
                velocity_input = 
                    velocity_result.correlation * neural.weights.velocity_linked.speed_corr +
                    (velocity_result.pattern_type:find("strafe") and 0.3 or 0) +
                    (velocity_result.pattern_type:find("accel") and 0.2 or 0) +
                    velocity_result.confidence * neural.weights.velocity_linked.direction_change
            end
            activations.velocity_linked = 1 / (1 + math.exp(-velocity_input * 3))
            
            
            local flip_input = 0
            if features.body_flip_rate > 0.3 and features.yaw_delta_max > 50 then
                flip_input = features.body_flip_rate * 0.5 + (features.yaw_delta_max / 180) * 0.5
            end
            activations.flip = 1 / (1 + math.exp(-flip_input * 3))
            
            
            local minimal_input = 0
            if features.body_variance > 50 and features.body_variance < 400 and
            features.yaw_delta_mean > 3 and features.yaw_delta_mean < 20 then
                minimal_input = 0.5 + features.timing_consistency * 0.5
            end
            activations.minimal_jitter = 1 / (1 + math.exp(-minimal_input * 3))
            
            
            for type_name, activation in pairs(activations) do
                table.insert(neural.activations[type_name], activation)
                while #neural.activations[type_name] > 15 do
                    table.remove(neural.activations[type_name], 1)
                end
            end
            
            
            local smoothed = {}
            for type_name, history in pairs(neural.activations) do
                if #history > 0 then
                    local sum = 0
                    local weight_sum = 0
                    for i, val in ipairs(history) do
                        local weight = i / #history  
                        sum = sum + val * weight
                        weight_sum = weight_sum + weight
                    end
                    smoothed[type_name] = sum / weight_sum
                else
                    smoothed[type_name] = 0
                end
            end
            
            return smoothed
        end
        
        
        
        
        local function detect_combinations(activations, micro_result, velocity_result)
            local combinations = {}
            
            
            if activations.jitter > 0.5 and activations.micro_desync > 0.4 then
                table.insert(combinations, {
                    name = "enhanced_jitter",
                    confidence = (activations.jitter + activations.micro_desync) / 2,
                    components = {"jitter", "micro_desync"}
                })
            end
            
            
            if activations.static > 0.5 and activations.micro_desync > 0.3 then
                table.insert(combinations, {
                    name = "fake_static",
                    confidence = (activations.static * 0.6 + activations.micro_desync * 0.4),
                    components = {"static", "micro_desync"}
                })
            end
            
            
            if activations.velocity_linked > 0.4 and activations.jitter > 0.4 then
                table.insert(combinations, {
                    name = "dynamic_jitter",
                    confidence = (activations.velocity_linked + activations.jitter) / 2,
                    components = {"velocity_linked", "jitter"}
                })
            end
            
            
            if activations.defensive > 0.5 then
                for type_name, act in pairs(activations) do
                    if type_name ~= "defensive" and act > 0.4 then
                        table.insert(combinations, {
                            name = "exploit_" .. type_name,
                            confidence = (activations.defensive * 0.6 + act * 0.4),
                            components = {"defensive", type_name}
                        })
                        break
                    end
                end
            end
            
            
            if activations.minimal_jitter > 0.4 and activations.velocity_linked > 0.3 then
                table.insert(combinations, {
                    name = "movement_synced_micro",
                    confidence = (activations.minimal_jitter + activations.velocity_linked) / 2,
                    components = {"minimal_jitter", "velocity_linked"}
                })
            end
            
            
            table.sort(combinations, function(a, b) return a.confidence > b.confidence end)
            
            return combinations
        end
        
        
        
        
        
        
        local features = extract_features()
        
        
        table.insert(neural.feature_history, {features = features, time = now})
        while #neural.feature_history > 30 do
            table.remove(neural.feature_history, 1)
        end
        
        
        local micro_result = detect_micro_desync()
        local velocity_result = detect_velocity_linked_adaptive()
        
        
        local jitter_analysis = analyze_jitter_pattern(data)
        
        
        local activations = neural_classify(features, micro_result, velocity_result)
        
        
        local combinations = detect_combinations(activations, micro_result, velocity_result)
        neural.combinations.detected = combinations
        
        
        
        
        
        
        local scores = {
            jitter = activations.jitter,
            static = activations.static,
            flip = activations.flip,
            minimal_jitter = activations.minimal_jitter,
            velocity_linked = activations.velocity_linked,
            defensive = activations.defensive,
            micro_desync = activations.micro_desync
        }
        
        
        if jitter_analysis.predictable then
            scores.jitter = math.max(scores.jitter, jitter_analysis.confidence)
            if jitter_analysis.pattern_type == "fixed_fast_jitter" then
                scores.minimal_jitter = math.max(scores.minimal_jitter, 0.85)
            end
        end
        
        if micro_result.detected then
            scores.micro_desync = math.max(scores.micro_desync, micro_result.confidence)
        end
        
        if velocity_result.detected then
            scores.velocity_linked = math.max(scores.velocity_linked, velocity_result.confidence)
        end
        
        
        characteristics.jitter_pattern = jitter_analysis.pattern_type
        characteristics.jitter_entropy = jitter_analysis.entropy
        characteristics.jitter_periodicity = jitter_analysis.periodicity
        characteristics.phase_lock = jitter_analysis.phase_lock
        characteristics.autocorrelation = jitter_analysis.autocorrelation
        characteristics.delay_ticks = jitter_analysis.delay_ticks
        
        characteristics.micro_type = micro_result.type
        characteristics.micro_amplitude = micro_result.amplitude
        characteristics.micro_frequency = micro_result.frequency
        
        characteristics.velocity_correlation = velocity_result.correlation
        characteristics.velocity_pattern = velocity_result.pattern_type
        characteristics.adaptive_threshold = velocity_result.adaptive_threshold
        
        characteristics.neural_activations = activations
        characteristics.combinations = combinations
        
        for type_name, score in pairs(scores) do
            characteristics[type_name] = score
        end
        
        data.aa_type.characteristics = characteristics
        
        
        
        
        local detected_type = "unknown"
        local confidence = 0
        local secondary_type = "none"
        
        
        if #combinations > 0 and combinations[1].confidence > 0.55 then
            detected_type = combinations[1].name
            confidence = combinations[1].confidence
            
            if #combinations > 1 and combinations[2].confidence > 0.45 then
                secondary_type = combinations[2].name
            end
            
            neural.combinations.primary = detected_type
            neural.combinations.secondary = secondary_type
            neural.combinations.confidence = confidence
        else
            
            local best_type = "unknown"
            local best_score = 0
            local second_best_type = "none"
            local second_best_score = 0
            
            for type_name, score in pairs(scores) do
                if score > best_score then
                    second_best_type = best_type
                    second_best_score = best_score
                    best_type = type_name
                    best_score = score
                elseif score > second_best_score then
                    second_best_type = type_name
                    second_best_score = score
                end
            end
            
            if best_score > 0.50 then
                detected_type = best_type
                confidence = best_score
                
                if second_best_score > 0.40 then
                    secondary_type = second_best_type
                end
            end
        end
        
        data.aa_type.detected = detected_type
        data.aa_type.confidence = confidence
        data.aa_type.secondary = secondary_type
        
        
        
        
        
        
        if detected_type:find("enhanced_jitter") or detected_type == "jitter" then
            if jitter_analysis.predictable then
                return jitter_analysis.next_side, jitter_analysis.confidence
            end
            
            
            local body_sign = data.body.current > 0 and 1 or -1
            return body_sign > 0 and -58 or 58, 0.68
            
        elseif detected_type:find("fake_static") then
            
            
            return data.body.current > 0 and -58 or 58, 0.72
            
        elseif detected_type:find("dynamic_jitter") or detected_type == "velocity_linked" then
            if velocity_result.detected and data.movement.strafe_direction ~= 0 then
                return data.movement.strafe_direction > 0 and -58 or 58, velocity_result.confidence
            end
            
            
            return data.body.current > 0 and -58 or 58, 0.60
            
        elseif detected_type:find("exploit") or detected_type == "defensive" then
            
            return data.body.current > 0 and 58 or -58, 0.65
            
        elseif detected_type == "minimal_jitter" or detected_type:find("micro") then
            
            if jitter_analysis.predictable and jitter_analysis.delay_ticks > 0 then
                return jitter_analysis.next_side, jitter_analysis.confidence * 0.9
            end
            
            local tick = globals.tickcount()
            local phase = tick % 6
            return phase < 3 and 58 or -58, 0.65
            
        elseif detected_type == "static" then
            return data.body.current > 0 and 58 or -58, 0.85
            
        elseif detected_type == "flip" then
            if data.angles.flip_detected and data.angles.flip_interval > 0 then
                local time_since = now - (data.angles.yaw_history[#data.angles.yaw_history].time or now)
                local phase = (time_since / data.angles.flip_interval) % 1
                local current_side = data.angles.yaw_history[#data.angles.yaw_history].yaw > 0 and 58 or -58
                
                return phase < 0.4 and current_side or -current_side, 0.78
            end
            
            return data.body.current > 0 and -58 or 58, 0.70
        end
        
        return 0, 0
    end

    local function adaptive_bruteforce(ent, data)
        if not data or not data.brute then return 0, 0 end
        
        local now = globals.realtime()
        local brute = data.brute
        
        
        
        
        if not brute.thompson then
            brute.thompson = {}  
            brute.ucb = {}       
            brute.contextual = {} 
            brute.exploration_rate = 0.20  
            brute.total_plays = 0
            
            
            for i, phase in ipairs(brute.base_phases) do
                brute.thompson[i] = {
                    alpha = 1.0,  
                    beta = 1.0   
                }
                brute.ucb[i] = {
                    plays = 0,
                    rewards = 0,
                    value = 0
                }
            end
        end
        
        
        
        
        local function get_context_key()
            local lp = entity.get_local_player()
            if not lp then return "default" end
            
            
            local distance = get_distance_to_player(ent)
            local dist_bucket = "medium"
            if distance < 300 then
                dist_bucket = "close"
            elseif distance > 700 then
                dist_bucket = "far"
            end
            
            
            local weapon = entity.get_player_weapon(lp)
            local weapon_type = "rifle"
            if weapon then
                local classname = entity.get_classname(weapon) or ""
                classname = classname:lower()
                if classname:find("awp") then
                    weapon_type = "awp"
                elseif classname:find("ssg08") then
                    weapon_type = "scout"
                elseif classname:find("deagle") then
                    weapon_type = "deagle"
                elseif classname:find("pistol") or classname:find("glock") or 
                    classname:find("p250") or classname:find("usp") then
                    weapon_type = "pistol"
                end
            end
            
            
            local vx, vy = entity.get_prop(ent, "m_vecVelocity")
            local velocity = vx and math.sqrt(vx*vx + vy*vy) or 0
            local vel_bucket = velocity > 150 and "moving" or "stationary"
            
            
            local aa_type = data.aa_type and data.aa_type.detected or "unknown"
            
            return string.format("%s_%s_%s_%s", dist_bucket, weapon_type, vel_bucket, aa_type)
        end
        
        local context_key = get_context_key()
        
        
        if not brute.contextual[context_key] then
            brute.contextual[context_key] = {
                thompson = {},
                ucb = {},
                total_plays = 0,
                best_phase_idx = nil,
                last_update = now
            }
            
            
            for i = 1, #brute.base_phases do
                brute.contextual[context_key].thompson[i] = {
                    alpha = 1.0 + math.random() * 0.5,
                    beta = 1.0 + math.random() * 0.5
                }
                brute.contextual[context_key].ucb[i] = {
                    plays = 0,
                    rewards = 0,
                    value = 0
                }
            end
        end
        
        local ctx = brute.contextual[context_key]
        
        
        
        
        if brute.locked and brute.lock_side ~= 0 then
            
            local lock_age = now - (brute.lock_time or now)
            local decay = math.max(0.7, 1.0 - lock_age * 0.05)
            return brute.lock_side, (brute.lock_confidence or 0.85) * decay
        end
        
        
        
        
        local function sample_beta(alpha, beta)
            
            
            local function sample_gamma(shape)
                if shape < 1 then
                    return sample_gamma(shape + 1) * math.pow(math.random(), 1.0 / shape)
                end
                
                local d = shape - 1.0 / 3.0
                local c = 1.0 / math.sqrt(9.0 * d)
                
                while true do
                    local x, v
                    repeat
                        x = math.random() * 2 - 1
                        local u = math.random()
                        v = 1.0 + c * x
                    until v > 0
                    
                    v = v * v * v
                    local u = math.random()
                    
                    if u < 1.0 - 0.0331 * x * x * x * x then
                        return d * v
                    end
                    
                    if math.log(u) < 0.5 * x * x + d * (1.0 - v + math.log(v)) then
                        return d * v
                    end
                end
            end
            
            
            alpha = math.max(0.1, alpha)
            beta = math.max(0.1, beta)
            
            local x = sample_gamma(alpha)
            local y = sample_gamma(beta)
            
            if x + y > 0 then
                return x / (x + y)
            else
                return 0.5
            end
        end
        
        
        
        
        local function calculate_ucb(phase_idx, use_context)
            local ucb_data = use_context and ctx.ucb[phase_idx] or brute.ucb[phase_idx]
            local total = use_context and ctx.total_plays or brute.total_plays
            
            if not ucb_data then return 1.0 end  
            
            if ucb_data.plays == 0 then
                return 2.0  
            end
            
            local avg_reward = ucb_data.rewards / ucb_data.plays
            
            
            local exploration_bonus = math.sqrt(2.0 * math.log(math.max(1, total)) / ucb_data.plays)
            
            
            exploration_bonus = exploration_bonus * brute.exploration_rate * 2
            
            return avg_reward + exploration_bonus
        end
        
        
        
        
        local all_phases = {}
        local phase_scores = {}
        
        
        for i, phase in ipairs(brute.base_phases) do
            if not brute.exhausted_phases[phase] then
                table.insert(all_phases, {
                    value = phase,
                    idx = i,
                    is_custom = false
                })
            end
        end
        
        
        for _, phase in ipairs(brute.custom_phases or {}) do
            local already_exists = false
            for _, existing in ipairs(all_phases) do
                if math.abs(existing.value - phase) < 5 then
                    already_exists = true
                    break
                end
            end
            
            if not already_exists then
                table.insert(all_phases, {
                    value = phase,
                    idx = #brute.base_phases + 1,  
                    is_custom = true
                })
            end
        end
        
        
        if #all_phases == 0 then
            brute.exhausted_phases = {}
            for i, phase in ipairs(brute.base_phases) do
                table.insert(all_phases, {value = phase, idx = i, is_custom = false})
                brute.weights[i] = 1.0
                brute.thompson[i] = {alpha = 1.0, beta = 1.0}
                brute.ucb[i] = {plays = 0, rewards = 0, value = 0}
            end
        end
        
        
        
        
        for _, phase_data in ipairs(all_phases) do
            local idx = phase_data.idx
            local score = 0
            
            
            local thompson_ctx = ctx.thompson[idx] or {alpha = 1.0, beta = 1.0}
            local thompson_global = brute.thompson[idx] or {alpha = 1.0, beta = 1.0}
            
            
            local ctx_weight = math.min(1.0, ctx.total_plays / 10)  
            local blended_alpha = thompson_ctx.alpha * ctx_weight + thompson_global.alpha * (1 - ctx_weight)
            local blended_beta = thompson_ctx.beta * ctx_weight + thompson_global.beta * (1 - ctx_weight)
            
            
            local thompson_score = sample_beta(blended_alpha, blended_beta)
            
            
            local ucb_score = calculate_ucb(idx, true)
            local ucb_global = calculate_ucb(idx, false)
            local blended_ucb = ucb_score * ctx_weight + ucb_global * (1 - ctx_weight)
            
            
            local weight_score = (brute.weights[idx] or 1.0) / 5.0
            
            
            
            local exploration_mode = brute.consecutive_misses > 1 or ctx.total_plays < 5
            
            if exploration_mode then
                
                score = thompson_score * 0.3 + blended_ucb * 0.5 + weight_score * 0.2
            else
                
                score = thompson_score * 0.5 + blended_ucb * 0.3 + weight_score * 0.2
            end
            
            
            if phase_data.is_custom then
                score = score * 1.3
            end
            
            
            if brute.exhausted_phases[phase_data.value] then
                score = score * 0.1
            end
            
            
            local distance = get_distance_to_player(ent)
            if distance < 300 then
                
                if math.abs(phase_data.value) >= 45 then
                    score = score * 1.15
                end
            elseif distance > 700 then
                
                if math.abs(phase_data.value) >= 30 and math.abs(phase_data.value) <= 60 then
                    score = score * 1.10
                end
            end
            
            phase_scores[phase_data] = score
        end
        
        
        
        
        local selected_phase = nil
        local selected_data = nil
        local max_score = -1
        
        
        local total_score = 0
        for _, score in pairs(phase_scores) do
            total_score = total_score + math.max(0.01, score)
        end
        
        local rand = math.random() * total_score
        local cumulative = 0
        
        for phase_data, score in pairs(phase_scores) do
            cumulative = cumulative + math.max(0.01, score)
            if rand <= cumulative then
                selected_phase = phase_data.value
                selected_data = phase_data
                break
            end
            
            
            if score > max_score then
                max_score = score
                selected_phase = phase_data.value
                selected_data = phase_data
            end
        end
        
        
        if not selected_phase then
            selected_phase = all_phases[1].value
            selected_data = all_phases[1]
        end
        
        
        brute.phase = selected_data.idx
        brute.last_switch = now
        brute.total_plays = brute.total_plays + 1
        ctx.total_plays = ctx.total_plays + 1
        
        
        if brute.ucb[selected_data.idx] then
            brute.ucb[selected_data.idx].plays = brute.ucb[selected_data.idx].plays + 1
        end
        if ctx.ucb[selected_data.idx] then
            ctx.ucb[selected_data.idx].plays = ctx.ucb[selected_data.idx].plays + 1
        end
        
        
        brute._last_selected_idx = selected_data.idx
        brute._last_context = context_key
        brute._last_phase = selected_phase
        
        
        
        
        local base_confidence = 0.50
        
        
        local thompson_data = ctx.thompson[selected_data.idx] or brute.thompson[selected_data.idx]
        if thompson_data then
            local expected_value = thompson_data.alpha / (thompson_data.alpha + thompson_data.beta)
            base_confidence = base_confidence + expected_value * 0.25
        end
        
        
        local ucb_data = ctx.ucb[selected_data.idx] or brute.ucb[selected_data.idx]
        if ucb_data and ucb_data.plays > 3 then
            local avg_reward = ucb_data.rewards / ucb_data.plays
            base_confidence = base_confidence + avg_reward * 0.15
        end
        
        
        local weight = brute.weights[selected_data.idx] or 1.0
        if weight > 2.0 then
            base_confidence = base_confidence + 0.10
        end
        
        
        if brute.consecutive_misses > 0 then
            base_confidence = base_confidence * math.max(0.5, 1.0 - brute.consecutive_misses * 0.08)
        end
        
        
        if brute.consecutive_hits > 0 then
            base_confidence = base_confidence + math.min(0.15, brute.consecutive_hits * 0.05)
        end
        
        return selected_phase, func.fclamp(base_confidence, 0.35, 0.90)
    end






    local function update_bruteforce_hit(data)
        if not data or not data.brute then return end
        local brute = data.brute
        
        local idx = brute._last_selected_idx
        local context_key = brute._last_context
        
        if not idx then return end
        
        
        if brute.thompson[idx] then
            
            brute.thompson[idx].alpha = brute.thompson[idx].alpha + 1.0
            
            
            brute.thompson[idx].beta = brute.thompson[idx].beta * 0.98
            brute.thompson[idx].beta = math.max(0.5, brute.thompson[idx].beta)
        end
        
        
        if brute.ucb[idx] then
            brute.ucb[idx].rewards = brute.ucb[idx].rewards + 1.0
        end
        
        
        if context_key and brute.contextual[context_key] then
            local ctx = brute.contextual[context_key]
            
            if ctx.thompson[idx] then
                ctx.thompson[idx].alpha = ctx.thompson[idx].alpha + 1.0
                ctx.thompson[idx].beta = ctx.thompson[idx].beta * 0.98
                ctx.thompson[idx].beta = math.max(0.5, ctx.thompson[idx].beta)
            end
            
            if ctx.ucb[idx] then
                ctx.ucb[idx].rewards = ctx.ucb[idx].rewards + 1.0
            end
            
            
            ctx.best_phase_idx = idx
            ctx.last_update = globals.realtime()
        end
        
        
        if brute.weights[idx] then
            brute.weights[idx] = brute.weights[idx] * 1.25
            brute.weights[idx] = math.min(brute.weights[idx], 6.0)
        end
        
        
        brute.consecutive_hits = (brute.consecutive_hits or 0) + 1
        brute.consecutive_misses = 0
        
        
        brute.exploration_rate = math.max(0.08, (brute.exploration_rate or 0.20) * 0.92)
    end


    local function update_bruteforce_miss(data)
        if not data or not data.brute then return end
        local brute = data.brute
        
        local idx = brute._last_selected_idx
        local context_key = brute._last_context
        local missed_phase = brute._last_phase
        
        if not idx then return end
        
        
        if brute.thompson[idx] then
            
            local miss_penalty = 0.8  
            
            
            if brute.consecutive_misses > 2 then
                miss_penalty = 1.0  
            end
            
            brute.thompson[idx].beta = brute.thompson[idx].beta + miss_penalty
            
            
            brute.thompson[idx].alpha = brute.thompson[idx].alpha * 0.95
            brute.thompson[idx].alpha = math.max(0.3, brute.thompson[idx].alpha)
        end
        
        
        
        
        
        if context_key and brute.contextual[context_key] then
            local ctx = brute.contextual[context_key]
            
            if ctx.thompson[idx] then
                
                local ctx_penalty = 1.0
                ctx.thompson[idx].beta = ctx.thompson[idx].beta + ctx_penalty
                ctx.thompson[idx].alpha = ctx.thompson[idx].alpha * 0.92
                ctx.thompson[idx].alpha = math.max(0.3, ctx.thompson[idx].alpha)
            end
            
            ctx.last_update = globals.realtime()
        end
        
        
        if brute.weights[idx] then
            
            local decay_factor = 0.75  
            
            
            if brute.consecutive_misses >= 2 then
                decay_factor = 0.65
            elseif brute.consecutive_misses >= 3 then
                decay_factor = 0.55
            end
            
            brute.weights[idx] = brute.weights[idx] * decay_factor
            brute.weights[idx] = math.max(brute.weights[idx], 0.15)  
            
            
            if brute.weights[idx] < 0.25 and brute.consecutive_misses >= 2 then
                brute.exhausted_phases[missed_phase] = true
            end
        end
        
        
        if missed_phase then
            local opposite = -missed_phase
            local nearby_found = false
            
            for _, existing in ipairs(brute.custom_phases or {}) do
                if math.abs(existing - opposite) < 8 then
                    nearby_found = true
                    break
                end
            end
            
            if not nearby_found then
                brute.custom_phases = brute.custom_phases or {}
                table.insert(brute.custom_phases, opposite)
                
                
                if math.abs(opposite) < 50 then
                    table.insert(brute.custom_phases, opposite + 10)
                    table.insert(brute.custom_phases, opposite - 10)
                end
                
                
                while #brute.custom_phases > 15 do
                    table.remove(brute.custom_phases, 1)
                end
            end
        end
        
        
        brute.consecutive_misses = (brute.consecutive_misses or 0) + 1
        brute.consecutive_hits = 0
        
        
        brute.locked = false
        
        
        brute.exploration_rate = math.min(0.35, (brute.exploration_rate or 0.20) * 1.15)
        
        
        brute.cycle_speed = math.max(0.25, (brute.cycle_speed or 0.5) * 0.85)
    end

    local function distance_resolver(ent, data)
        local lp = entity.get_local_player()
        if not lp then return 0, 0 end
        
        local distance = get_distance_to_player(ent)
        
        
        if not data.distance.distance_history then
            data.distance.distance_history = {}
        end
        
        table.insert(data.distance.distance_history, {
            distance = distance,
            time = globals.realtime()
        })
        
        
        while #data.distance.distance_history > 30 do
            table.remove(data.distance.distance_history, 1)
        end
        
        data.distance.last_distance = distance
        
        
        local prediction = 0
        local confidence = 0
        
        
        if distance < 300 then
            if data.distance.close_range_side ~= 0 then
                prediction = data.distance.close_range_side
                confidence = 0.70
            else
                
                local body_yaw = 0
                local pose = entity.get_prop(ent, "m_flPoseParameter", 11)
                if pose then
                    body_yaw = (pose * 120) - 60
                end
                prediction = body_yaw > 0 and 58 or -58
                confidence = 0.55
            end
        
        elseif distance > 700 then
            if data.distance.long_range_side ~= 0 then
                prediction = data.distance.long_range_side
                confidence = 0.72
            else
                
                local body_yaw = 0
                local pose = entity.get_prop(ent, "m_flPoseParameter", 11)
                if pose then
                    body_yaw = (pose * 120) - 60
                end
                prediction = body_yaw > 0 and 45 or -45
                confidence = 0.50
            end
        
        else
            
            if data.distance.close_range_side ~= 0 and data.distance.long_range_side ~= 0 then
                
                local close_weight = 0.5
                local long_weight = 0.5
                
                
                local range_ratio = (distance - 300) / 400  
                close_weight = 1.0 - range_ratio
                long_weight = range_ratio
                
                
                if close_weight > long_weight then
                    prediction = data.distance.close_range_side
                else
                    prediction = data.distance.long_range_side
                end
                confidence = 0.60
            elseif data.distance.close_range_side ~= 0 then
                prediction = data.distance.close_range_side
                confidence = 0.55
            elseif data.distance.long_range_side ~= 0 then
                prediction = data.distance.long_range_side
                confidence = 0.55
            else
                
                local body_yaw = 0
                local pose = entity.get_prop(ent, "m_flPoseParameter", 11)
                if pose then
                    body_yaw = (pose * 120) - 60
                end
                prediction = body_yaw > 0 and 50 or -50
                confidence = 0.45
            end
        end
        
        
        local context_key = string.format("dist_%d", math.floor(distance / 100))
        local context_data = data.patterns.context_memory[context_key]
        
        if context_data and (globals.realtime() - context_data.time) < 15 then
            
            local context_weight = math.min(0.4, context_data.confidence * 0.5)
            local current_weight = 1.0 - context_weight
            
            
            if (prediction > 0) == (context_data.side > 0) then
                confidence = confidence + 0.10
            else
                
                if context_data.confidence > confidence then
                    prediction = context_data.side
                    confidence = context_data.confidence * 0.8
                end
            end
        end
        
        
        local vx, vy = entity.get_prop(ent, "m_vecVelocity")
        if vx then
            local velocity = math.sqrt(vx*vx + vy*vy)
            
            
            if velocity > 150 and distance > 500 then
                confidence = confidence * 0.85
            end
            
            
            if velocity < 20 and distance < 250 then
                confidence = confidence * 1.15
            end
        end
        
        
        confidence = func.fclamp(confidence, 0.35, 0.85)
        
        return prediction, confidence
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
            
            cl_interp_ratio = math.max(TB.sv_client_min_interp_ratio or 1, 
                                        math.min(TB.sv_client_max_interp_ratio or 2, cl_interp_ratio))
            
            local tickrate = TB.tickrate or 64
            local interp_time = math.max(cl_interp, cl_interp_ratio / tickrate)
            local interp_ticks = math.floor(interp_time / globals.tickinterval())
            
            local max_rewind = TB.max_rewind_ticks or 12
            local total_window = max_rewind + interp_ticks
            
            return {
                interp_ticks = interp_ticks,
                backtrack_ticks = max_rewind,
                total_ticks = total_window,
                tickrate = tickrate
            }
        end    
        
        local lagcomp = get_lagcomp_window()
        local interp_delay = lagcomp.interp_ticks
        
        
        
        
        if not data._calibration then
            data._calibration = {
                
                method_calibration = {},
                
                
                confidence_buckets = {},
                
                
                side_priors = {
                    left = 0.5,
                    right = 0.5
                },
                
                
                method_correlations = {},
                
                
                prediction_history = {},
                
                
                stats = {
                    total_predictions = 0,
                    calibration_error = 0,
                    last_calibration = 0
                }
            }
        end
        
        local calibration = data._calibration
        
        
        
        
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
        
        
        
        
        local jitter_analysis = analyze_jitter_pattern(data)
        data._current_jitter_analysis = jitter_analysis
        
        
        
        
        local function calibrate_confidence(raw_confidence, method_name)
            
            if not calibration.method_calibration[method_name] then
                calibration.method_calibration[method_name] = {
                    
                    A = 0,  
                    B = 0,  
                    
                    
                    buckets = {},
                    
                    
                    history = {},
                    
                    
                    reliability = {
                        predicted = {},
                        actual = {}
                    }
                }
            end
            
            local cal = calibration.method_calibration[method_name]
            
            
            local platt_calibrated = 1.0 / (1.0 + math.exp(cal.A * raw_confidence + cal.B))
            
            
            local bucket_idx = math.floor(raw_confidence * 10) + 1
            bucket_idx = math.max(1, math.min(10, bucket_idx))
            
            local isotonic_calibrated = raw_confidence
            if cal.buckets[bucket_idx] and cal.buckets[bucket_idx].count >= 3 then
                isotonic_calibrated = cal.buckets[bucket_idx].actual_rate
            end
            
            
            local total_samples = 0
            for _, bucket in pairs(cal.buckets) do
                total_samples = total_samples + (bucket.count or 0)
            end
            
            local isotonic_weight = math.min(0.7, total_samples / 50)
            local calibrated = platt_calibrated * (1 - isotonic_weight) + isotonic_calibrated * isotonic_weight
            
            
            local method_samples = #cal.history
            local shrinkage = math.max(0.1, 1.0 - (method_samples / 30))
            calibrated = calibrated * (1 - shrinkage) + 0.5 * shrinkage
            
            
            calibrated = func.fclamp(calibrated, 0.1, 0.95)
            
            return calibrated
        end
        
        
        
        
        local function update_calibration()
            local now = globals.realtime()
            
            
            if now - calibration.stats.last_calibration < 5.0 then
                return
            end
            calibration.stats.last_calibration = now
            
            
            for method_name, cal in pairs(calibration.method_calibration) do
                if #cal.history >= 5 then
                    
                    for i = 1, 10 do
                        cal.buckets[i] = cal.buckets[i] or {count = 0, hits = 0, actual_rate = 0.5}
                    end
                    
                    for _, entry in ipairs(cal.history) do
                        local bucket_idx = math.floor(entry.predicted * 10) + 1
                        bucket_idx = math.max(1, math.min(10, bucket_idx))
                        
                        cal.buckets[bucket_idx].count = cal.buckets[bucket_idx].count + 1
                        if entry.actual then
                            cal.buckets[bucket_idx].hits = cal.buckets[bucket_idx].hits + 1
                        end
                    end
                    
                    
                    for i = 1, 10 do
                        if cal.buckets[i].count > 0 then
                            cal.buckets[i].actual_rate = cal.buckets[i].hits / cal.buckets[i].count
                        end
                    end
                    
                    
                    local function platt_loss(A, B)
                        local loss = 0
                        for _, entry in ipairs(cal.history) do
                            local p = 1.0 / (1.0 + math.exp(A * entry.predicted + B))
                            local target = entry.actual and 1 or 0
                            loss = loss + (p - target)^2
                        end
                        return loss / #cal.history
                    end
                    
                    
                    local best_A, best_B = 0, 0
                    local best_loss = platt_loss(0, 0)
                    
                    for a = -3, 3, 0.5 do
                        for b = -2, 2, 0.5 do
                            local loss = platt_loss(a, b)
                            if loss < best_loss then
                                best_loss = loss
                                best_A, best_B = a, b
                            end
                        end
                    end
                    
                    
                    cal.A = cal.A * 0.7 + best_A * 0.3
                    cal.B = cal.B * 0.7 + best_B * 0.3
                end
            end
            
            
            local left_correct = 0
            local right_correct = 0
            local left_total = 0
            local right_total = 0
            
            for _, entry in ipairs(calibration.prediction_history) do
                if entry.predicted_side < 0 then
                    left_total = left_total + 1
                    if entry.hit then left_correct = left_correct + 1 end
                else
                    right_total = right_total + 1
                    if entry.hit then right_correct = right_correct + 1 end
                end
            end
            
            
            local alpha_left = 1 + left_correct
            local beta_left = 1 + (left_total - left_correct)
            local alpha_right = 1 + right_correct
            local beta_right = 1 + (right_total - right_correct)
            
            calibration.side_priors.left = alpha_left / (alpha_left + beta_left)
            calibration.side_priors.right = alpha_right / (alpha_right + beta_right)
        end
        
        update_calibration()
        
        
        
        
        local methods = {
            {name = "adaptive_brute", func = adaptive_bruteforce, base_weight = 1.0},
            {name = "body_delta", func = body_delta_method, base_weight = 1.2},
            {name = "body_shot", func = body_shot_resolver, base_weight = 1.4},
            {name = "strafe", func = strafe_prediction, base_weight = 1.0},
            {name = "flip_pattern", func = flip_pattern_detection, base_weight = 1.1},
            {name = "markov", func = markov_learning, base_weight = 1.5},
            {name = "distance", func = distance_resolver, base_weight = 0.9},
            {name = "aa_type", func = detect_aa_type, base_weight = 1.3}
        }
        
        local raw_predictions = {}
        
        
        if jitter_analysis.predictable and jitter_analysis.confidence > 0.70 then
            table.insert(raw_predictions, {
                value = jitter_analysis.next_side,
                raw_confidence = jitter_analysis.confidence,
                source = "jitter_pattern",
                side = jitter_analysis.next_side > 0 and "right" or "left"
            })
        end
        
        
        for _, method in ipairs(methods) do
            local prediction, confidence = method.func(ent, data)
            
            if prediction ~= 0 and confidence > 0.15 then
                
                local method_stats = resolver.stats.method_stats[method.name] or {hits = 0, total = 0}
                local method_accuracy = method_stats.total >= 3 and (method_stats.hits / method_stats.total) or 0.5
                
                table.insert(raw_predictions, {
                    value = prediction,
                    raw_confidence = confidence,
                    source = method.name,
                    base_weight = method.base_weight,
                    method_accuracy = method_accuracy,
                    side = prediction > 0 and "right" or "left"
                })
            end
        end
        
        if #raw_predictions == 0 then
            
            local pose = entity.get_prop(ent, "m_flPoseParameter", 11)
            if pose then
                local body_yaw = (pose * 120) - 60
                data.override.value = body_yaw > 0 and 58 or -58
                data.override.confidence = 0.35
                data.override.source = "fallback"
                plist.set(ent, "Override resolver", data.override.value / 60)
                plist.set(ent, "Correction active", true)
                return
            end
        end
        
        
        
        
        local calibrated_predictions = {}
        
        for _, pred in ipairs(raw_predictions) do
            local calibrated_conf = calibrate_confidence(pred.raw_confidence, pred.source)
            
            table.insert(calibrated_predictions, {
                value = pred.value,
                raw_confidence = pred.raw_confidence,
                calibrated_confidence = calibrated_conf,
                source = pred.source,
                base_weight = pred.base_weight or 1.0,
                method_accuracy = pred.method_accuracy or 0.5,
                side = pred.side
            })
        end
        
        
        
        
        local function bayesian_fusion(predictions)
            
            local left_predictions = {}
            local right_predictions = {}
            
            for _, pred in ipairs(predictions) do
                if pred.side == "left" then
                    table.insert(left_predictions, pred)
                else
                    table.insert(right_predictions, pred)
                end
            end
            
            
            
            
            local function calculate_side_posterior(side_predictions, other_predictions, prior)
                if #side_predictions == 0 then
                    return prior * 0.3  
                end
                
                
                local log_odds = math.log(prior / (1 - prior + 1e-9))
                
                
                
                local source_groups = {
                    body = {"body_delta", "body_shot"},
                    pattern = {"flip_pattern", "markov", "jitter_pattern"},
                    movement = {"strafe", "distance"},
                    detection = {"aa_type", "adaptive_brute"}
                }
                
                local group_contributions = {}
                
                for _, pred in ipairs(side_predictions) do
                    
                    local method_group = "independent"
                    for group_name, methods_in_group in pairs(source_groups) do
                        for _, method in ipairs(methods_in_group) do
                            if pred.source == method then
                                method_group = group_name
                                break
                            end
                        end
                    end
                    
                    
                    
                    local true_positive_rate = pred.calibrated_confidence
                    local false_positive_rate = 1 - pred.calibrated_confidence
                    
                    
                    true_positive_rate = true_positive_rate * (0.5 + pred.method_accuracy * 0.5)
                    false_positive_rate = false_positive_rate * (1.5 - pred.method_accuracy * 0.5)
                    
                    local likelihood_ratio = true_positive_rate / (false_positive_rate + 1e-9)
                    local log_lr = math.log(math.max(0.1, math.min(10, likelihood_ratio)))
                    
                    
                    if not group_contributions[method_group] then
                        group_contributions[method_group] = {
                            count = 0,
                            max_log_lr = 0,
                            sum_log_lr = 0
                        }
                    end
                    
                    local gc = group_contributions[method_group]
                    gc.count = gc.count + 1
                    gc.max_log_lr = math.max(gc.max_log_lr, log_lr)
                    gc.sum_log_lr = gc.sum_log_lr + log_lr
                end
                
                
                for group_name, gc in pairs(group_contributions) do
                    if gc.count == 1 then
                        
                        log_odds = log_odds + gc.sum_log_lr
                    else
                        
                        
                        local discount = 0.5 + 0.5 / gc.count  
                        local effective_contribution = gc.max_log_lr + (gc.sum_log_lr - gc.max_log_lr) * discount
                        log_odds = log_odds + effective_contribution
                    end
                end
                
                
                for _, pred in ipairs(other_predictions) do
                    
                    local penalty = pred.calibrated_confidence * 0.3
                    log_odds = log_odds - penalty
                end
                
                
                local posterior = 1.0 / (1.0 + math.exp(-log_odds))
                
                return posterior
            end
            
            local left_posterior = calculate_side_posterior(
                left_predictions, 
                right_predictions, 
                calibration.side_priors.left
            )
            
            local right_posterior = calculate_side_posterior(
                right_predictions, 
                left_predictions, 
                calibration.side_priors.right
            )
            
            
            local total = left_posterior + right_posterior
            if total > 0 then
                left_posterior = left_posterior / total
                right_posterior = right_posterior / total
            else
                left_posterior = 0.5
                right_posterior = 0.5
            end
            
            return left_posterior, right_posterior, left_predictions, right_predictions
        end
        
        local left_prob, right_prob, left_preds, right_preds = bayesian_fusion(calibrated_predictions)
        
        
        
        
        local winning_side = left_prob > right_prob and "left" or "right"
        local winning_prob = math.max(left_prob, right_prob)
        local winning_predictions = winning_side == "left" and left_preds or right_preds
        
        
        
        
        local final_yaw = 0
        
        if #winning_predictions > 0 then
            
            
            
            local weighted_sum = 0
            local weight_sum = 0
            
            for _, pred in ipairs(winning_predictions) do
                
                local weight = pred.calibrated_confidence * 
                            (0.5 + pred.method_accuracy * 0.5) * 
                            (pred.base_weight or 1.0)
                
                weighted_sum = weighted_sum + pred.value * weight
                weight_sum = weight_sum + weight
            end
            
            if weight_sum > 0 then
                final_yaw = weighted_sum / weight_sum
            else
                
                local best_conf = 0
                for _, pred in ipairs(winning_predictions) do
                    if pred.calibrated_confidence > best_conf then
                        best_conf = pred.calibrated_confidence
                        final_yaw = pred.value
                    end
                end
            end
        else
            
            final_yaw = winning_side == "left" and -58 or 58
        end
        
        
        
        
        local common_angles = {-58, -45, -30, -15, 15, 30, 45, 58}
        local snap_tolerance = resolver.config.angle_tolerance or 8
        
        for _, angle in ipairs(common_angles) do
            if math.abs(final_yaw - angle) < snap_tolerance then
                final_yaw = angle
                break
            end
        end
        
        
        if winning_side == "left" and final_yaw > 0 then
            final_yaw = -math.abs(final_yaw)
        elseif winning_side == "right" and final_yaw < 0 then
            final_yaw = math.abs(final_yaw)
        end
        
        final_yaw = func.fclamp(final_yaw, -60, 60)
        
        
        
        
        local final_confidence = winning_prob
        
        
        local agreement_bonus = 0
        if #winning_predictions >= 2 then
            
            local angle_variance = 0
            local mean_angle = final_yaw
            
            for _, pred in ipairs(winning_predictions) do
                angle_variance = angle_variance + (pred.value - mean_angle)^2
            end
            angle_variance = angle_variance / #winning_predictions
            
            
            local agreement_factor = 1.0 / (1.0 + math.sqrt(angle_variance) * 0.05)
            agreement_bonus = (agreement_factor - 0.5) * 0.15
        end
        
        
        local source_bonus = math.min(0.10, (#winning_predictions - 1) * 0.025)
        
        
        local avg_accuracy = 0
        for _, pred in ipairs(winning_predictions) do
            avg_accuracy = avg_accuracy + (pred.method_accuracy or 0.5)
        end
        avg_accuracy = avg_accuracy / math.max(1, #winning_predictions)
        local accuracy_bonus = (avg_accuracy - 0.5) * 0.15
        
        final_confidence = final_confidence + agreement_bonus + source_bonus + accuracy_bonus
        
        
        local interp_penalty = interp_delay * 0.008
        final_confidence = final_confidence - interp_penalty
        
        
        final_confidence = func.fclamp(final_confidence, 0.25, 0.95)
        
        
        
        
        local function apply_interp_compensation(prediction, confidence)
            local tick_offset = math.floor(interp_delay * 0.7)
            
            
            if jitter_analysis.predictable and jitter_analysis.delay_ticks > 0 then
                local future_ticks = tick_offset + jitter_analysis.delay_ticks
                local phase = (future_ticks % (jitter_analysis.delay_ticks * 2)) / (jitter_analysis.delay_ticks * 2)
                
                if phase > 0.5 then
                    
                    prediction = -prediction
                end
            elseif data.angles.flip_detected and data.angles.flip_interval > 0 then
                local future_time = globals.realtime() + (tick_offset * globals.tickinterval())
                local phase = (future_time / data.angles.flip_interval) % 1
                
                if phase > 0.5 then
                    prediction = -prediction
                end
            end
            
            return prediction, confidence
        end
        
        final_yaw, final_confidence = apply_interp_compensation(final_yaw, final_confidence)
        
        
        
        
        table.insert(calibration.prediction_history, {
            predicted_side = final_yaw,
            confidence = final_confidence,
            side = final_yaw > 0 and "right" or "left",
            time = globals.realtime(),
            hit = nil,  
            sources = {}
        })
        
        
        for _, pred in ipairs(calibrated_predictions) do
            local cal = calibration.method_calibration[pred.source]
            if cal then
                table.insert(cal.history, {
                    predicted = pred.raw_confidence,
                    actual = nil,  
                    time = globals.realtime()
                })
                
                
                while #cal.history > 100 do
                    table.remove(cal.history, 1)
                end
            end
        end
        
        
        while #calibration.prediction_history > 100 do
            table.remove(calibration.prediction_history, 1)
        end
        
        
        
        
        data.override.value = final_yaw
        data.override.confidence = final_confidence
        data.override.source = #winning_predictions > 0 and winning_predictions[1].source or "bayesian_fusion"
        data.override.time = globals.realtime()
        data.override.fusion_weights = calibrated_predictions
        data.override.bayesian_result = {
            left_prob = left_prob,
            right_prob = right_prob,
            winning_side = winning_side,
            prediction_count = #calibrated_predictions
        }
        
        
        table.insert(data.override.prediction_history, {
            value = final_yaw,
            confidence = final_confidence,
            source = data.override.source,
            time = globals.realtime(),
            bayesian = {left = left_prob, right = right_prob}
        })
        
        if #data.override.prediction_history > 50 then
            table.remove(data.override.prediction_history, 1)
        end
        
        
        plist.set(ent, "Override resolver", final_yaw / 60)
        plist.set(ent, "Correction active", true)


        _G.detect_tickbase_exploitation = detect_tickbase_exploitation
        _G.detect_fakeduck = detect_fakeduck
        _G.update_resolver_state_machine = update_resolver_state_machine
        _G.update_ping_compensation = update_ping_compensation
        _G.get_ping_adjusted_prediction = get_ping_adjusted_prediction
    local function cleanup_detection_data()
        local now = globals.realtime()
        local expire_time = 30  
        
        
        for idx, data in pairs(tickbase_detector.players) do
            if now - data.last_update > expire_time then
                tickbase_detector.players[idx] = nil
            end
        end
        
        
        for idx, data in pairs(fakeduck_detector.players) do
            if now - data.last_update > expire_time then
                fakeduck_detector.players[idx] = nil
            end
        end
        
        
        for idx, data in pairs(resolver_state_machine.players) do
            if now - data.last_update > expire_time then
                resolver_state_machine.players[idx] = nil
            end
        end
    end


    local last_cleanup = 0
    client.set_event_callback("paint", function()
        local now = globals.realtime()
        if now - last_cleanup > 10 then  
            cleanup_detection_data()
            last_cleanup = now
        end
    end)


    client.set_event_callback("round_prestart", function()
        
        for idx, data in pairs(tickbase_detector.players) do
            data.shift_detected = false
            data.defensive_active = false
            data.is_recharging = false
            data.recharge_ticks = 0
        end
        
        for idx, data in pairs(fakeduck_detector.players) do
            data.is_fakeducking = false
            data.cycle_phase = 0
        end
        
        for idx, data in pairs(resolver_state_machine.players) do
            data.current_state = "unknown"
            data.state_enter_time = 0
            data.state_confidence = 0
        end
    end)


    client.set_event_callback("net_update_end", function()
        update_ping_compensation()
    end)
    end

            local function update_calibration_on_hit(data, predicted_side)
        if not data or not data._calibration then return end
        
        local calibration = data._calibration
        
        
        for i = #calibration.prediction_history, math.max(1, #calibration.prediction_history - 5), -1 do
            local entry = calibration.prediction_history[i]
            if entry and entry.hit == nil then
                
                local same_side = (entry.predicted_side > 0) == (predicted_side > 0)
                entry.hit = same_side
                break
            end
        end
        
        
        for method_name, cal in pairs(calibration.method_calibration) do
            for i = #cal.history, math.max(1, #cal.history - 5), -1 do
                local entry = cal.history[i]
                if entry and entry.actual == nil then
                    entry.actual = true
                    break
                end
            end
        end
        
        
        local side = predicted_side > 0 and "right" or "left"
        
        if side == "left" then
            calibration.side_priors.left = calibration.side_priors.left * 1.05
            calibration.side_priors.right = calibration.side_priors.right * 0.98
        else
            calibration.side_priors.right = calibration.side_priors.right * 1.05
            calibration.side_priors.left = calibration.side_priors.left * 0.98
        end
        
        
        local total = calibration.side_priors.left + calibration.side_priors.right
        calibration.side_priors.left = calibration.side_priors.left / total
        calibration.side_priors.right = calibration.side_priors.right / total
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
                    if #data.patterns.hit_sequence > 30 then
                        table.remove(data.patterns.hit_sequence, 1)
                    end
                    
                    
                    for i, phase in ipairs(data.brute.base_phases) do
                        if math.abs(phase - last_shot.predicted_side) < 10 then
                            data.brute.weights[i] = (data.brute.weights[i] or 1.0) * 1.4
                            data.brute.weights[i] = math.min(data.brute.weights[i], 8.0)
                        end
                    end
                    
                    
                    data.brute.consecutive_hits = data.brute.consecutive_hits + 1
                    data.brute.consecutive_misses = 0
                    
                    
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
                    
                    
                    local lock_threshold = 2
                    if last_shot.confidence and last_shot.confidence > 0.8 then
                        lock_threshold = 1 
                    end
                    
                    if data.brute.consecutive_hits >= lock_threshold then
                        data.brute.locked = true
                        data.brute.lock_side = last_shot.predicted_side
                        
                        
                        local hit_streak_bonus = math.min(0.25, data.brute.consecutive_hits * 0.08)
                        local consistency_bonus = pattern_consistency * 0.15
                        local base_confidence = 0.65
                        
                        data.brute.lock_confidence = math.min(0.98, 
                            base_confidence + hit_streak_bonus + consistency_bonus)
                        
                        
                        local duration_multiplier = 1.0 + (data.brute.lock_confidence - 0.65) * 2
                        data.override.lock_until = globals.realtime() + 
                            (resolver.config.lock_duration * duration_multiplier)
                        data.override.lock_start = globals.realtime()
                    end
                    
                    
                    if last_shot.distance then
                        if last_shot.distance < 300 then
                            data.distance.close_range_side = last_shot.predicted_side
                        else
                            data.distance.long_range_side = last_shot.predicted_side
                        end
                    end
                    update_calibration_on_hit(data, last_shot.predicted_side)
                    
                    if last_shot.source then
                        local stats = resolver.stats.method_stats[last_shot.source] or {hits = 0, total = 0}
                        stats.hits = stats.hits + 1
                        stats.total = stats.total + 1
                        resolver.stats.method_stats[last_shot.source] = stats
                    end
                end
                
                data.hits = data.hits + 1
                data.misses = 0
                
                
                resolver.stats.total_hits = resolver.stats.total_hits + 1
                resolver.stats.accuracy = resolver.stats.total_hits / math.max(1, resolver.stats.total_shots)
            end

    local function update_calibration_on_miss(data, predicted_side)
        if not data or not data._calibration then return end
        
        local calibration = data._calibration
        
        
        for i = #calibration.prediction_history, math.max(1, #calibration.prediction_history - 5), -1 do
            local entry = calibration.prediction_history[i]
            if entry and entry.hit == nil then
                entry.hit = false
                break
            end
        end
        
        
        for method_name, cal in pairs(calibration.method_calibration) do
            for i = #cal.history, math.max(1, #cal.history - 5), -1 do
                local entry = cal.history[i]
                if entry and entry.actual == nil then
                    entry.actual = false
                    break
                end
            end
        end
        
        
        local side = predicted_side > 0 and "right" or "left"
        if side == "left" then
            calibration.side_priors.left = calibration.side_priors.left * 0.92
            calibration.side_priors.right = calibration.side_priors.right * 1.04
        else
            calibration.side_priors.right = calibration.side_priors.right * 0.92
            calibration.side_priors.left = calibration.side_priors.left * 1.04
        end
        
        
        local total = calibration.side_priors.left + calibration.side_priors.right
        calibration.side_priors.left = calibration.side_priors.left / total
        calibration.side_priors.right = calibration.side_priors.right / total
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
                    if #data.patterns.miss_sequence > 30 then
                        table.remove(data.patterns.miss_sequence, 1)
                    end
                    
                    
                    local missed_side = last_shot.predicted_side
                    
                    update_calibration_on_miss(data, last_shot.predicted_side)
                    local opposite_candidates = {}
                    table.insert(opposite_candidates, -missed_side) 
                    table.insert(opposite_candidates, -missed_side + 15) 
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
                    
                    
                    while #data.brute.custom_phases > 12 do
                        table.remove(data.brute.custom_phases, 1)
                    end
                    
                    
                    local penalty_multiplier = 1.0 + (data.brute.consecutive_misses * 0.2)
                    for i, phase in ipairs(data.brute.base_phases) do
                        if math.abs(phase - missed_side) < 10 then
                            data.brute.weights[i] = (data.brute.weights[i] or 1.0) * (0.5 / penalty_multiplier)
                            data.brute.weights[i] = math.max(data.brute.weights[i], 0.05)
                            
                            
                            if data.brute.weights[i] < 0.2 then
                                data.brute.exhausted_phases[phase] = true
                            end
                        end
                    end
                    
                    
                    if last_shot.source then
                        local stats = resolver.stats.method_stats[last_shot.source] or {hits = 0, total = 0}
                        stats.total = stats.total + 1
                        resolver.stats.method_stats[last_shot.source] = stats
                    end
                end
                
                
                data.misses = data.misses + 1
                data.brute.consecutive_hits = 0
                data.brute.consecutive_misses = data.brute.consecutive_misses + 1
                
                
                data.brute.locked = false
                data.override.lock_until = 0
                
                
                local speed_multiplier = math.max(0.5, 1.0 - (data.brute.consecutive_misses * 0.15))
                data.brute.cycle_speed = math.max(0.15, data.brute.cycle_speed * speed_multiplier)
                
                
                data.override.value = -(data.override.value or 0)
                data.override.confidence = math.max(0.2, data.override.confidence * 0.6)
                data.override.time = globals.realtime()
                data.brute.last_switch = globals.realtime()
                
                
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
                local _original_on_resolver_aim_hit = on_resolver_aim_hit
                local function enhanced_on_resolver_aim_hit(shot)
                    if _original_on_resolver_aim_hit then
                        _original_on_resolver_aim_hit(shot)
                    end
                    
                    local ent = shot.target
                    if not ent then return end
                    
                    local data = get_player_data(ent)
                    update_bruteforce_hit(data)
                end

                
                local _original_on_resolver_aim_miss = on_resolver_aim_miss
                local function enhanced_on_resolver_aim_miss(shot)
                    if _original_on_resolver_aim_miss then
                        _original_on_resolver_aim_miss(shot)
                    end
                    
                    local ent = shot.target
                    if not ent then return end
                    
                    local data = get_player_data(ent)
                    update_bruteforce_miss(data)
                end
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
                    
                    local max_unlag = cvar.sv_maxunlag:get_float()
                    local tickrate = 1 / globals.tickinterval()
                    
                    resolver.config.max_backtrack = math.floor(max_unlag / globals.tickinterval())
                    resolver.config.tickrate = tickrate
                    
                    
                    local interp = cvar.cl_interp:get_float()
                    local interp_ratio = cvar.cl_interp_ratio:get_float()
                    resolver.config.lerp_time = interp + (interp_ratio * globals.tickinterval())
                    
                    
                    if tickrate == 128 then
                        resolver.config.brute_phases = 14  
                    else
                        resolver.config.brute_phases = 10  
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
                client.set_event_callback("round_start", function()
                    update_server_cvars()
                end)

                
                client.delay_call(0.1, function()
                    update_server_cvars()
                end)

    client.set_event_callback("setup_command", function(cmd)
        if not resolver.enabled then return end
        
        local lp = entity.get_local_player()
        if not lp or not entity.is_alive(lp) then return end
        
        local target = client.current_threat()
        if not target then return end
        
        local data = get_player_data(target)
        if not data then return end
        
        local enemy_hp = entity.get_prop(target, "m_iHealth") or 100
        
        
        local weapon = entity.get_player_weapon(lp)
        local weapon_type = "rifle"
        if weapon then
            local classname = entity.get_classname(weapon) or ""
            if classname:find("AWP") then
                weapon_type = "awp"
            elseif classname:find("SSG08") then
                weapon_type = "scout"
            elseif classname:find("Pistol") or classname:find("Deagle") then
                weapon_type = "pistol"
            end
        end
        
        pcall(function()
            local hitchance_ref = ui.reference("RAGE", "Aimbot", "Minimum hit chance")
            if hitchance_ref then
                if not data._original_hitchance then
                    data._original_hitchance = ui.get(hitchance_ref)
                end
                
                local base_hc = data._original_hitchance or 60
                
                
                if base_hc >= 80 then
                    
                    return
                end
                
                local adaptive_hc, context = calculate_adaptive_hitchance(target, weapon_type, base_hc)
                
                
                adaptive_hc = math.max(adaptive_hc, base_hc - 10)
                
                
                if weapon_type == "awp" or weapon_type == "scout" then
                    adaptive_hc = math.max(adaptive_hc, 55)
                else
                    adaptive_hc = math.max(adaptive_hc, 45)
                end
                
                
                data._last_hc_context = context
                
                ui.set(hitchance_ref, adaptive_hc)
            end
        end)
        
        
        pcall(function()
            local mp_refs = {
                head = ui.reference("RAGE", "Aimbot", "Head multipoint scale"),
                body = ui.reference("RAGE", "Aimbot", "Body multipoint scale")
            }
            
            
            if not data._original_mp then
                data._original_mp = {}
                for name, ref in pairs(mp_refs) do
                    if ref then
                        data._original_mp[name] = ui.get(ref)
                    end
                end
            end
            
            
            local head_scale = calculate_adaptive_multipoint(target, 0, weapon_type)  
            local body_scale = calculate_adaptive_multipoint(target, 2, weapon_type)  
            
            
            if mp_refs.head then
                ui.set(mp_refs.head, head_scale)
            end
            if mp_refs.body then
                ui.set(mp_refs.body, body_scale)
            end
        end)
        
        
        if data.override.confidence then
            pcall(function()
                local safe_point_ref = ui.reference("RAGE", "Aimbot", "Force safe point")
                if safe_point_ref then
                    local should_safe = (enemy_hp < 50) or (data.override.confidence < 0.65)
                    
                    if not data._original_safe_point then
                        data._original_safe_point = ui.get(safe_point_ref)
                    end
                    
                    ui.set(safe_point_ref, should_safe)
                end
            end)
        end
        
        
        local vx, vy, vz = entity.get_prop(target, "m_vecVelocity")
        if vx then
            local velocity = math.sqrt(vx*vx + vy*vy)
            
            if not data.movement.velocity_history then
                data.movement.velocity_history = {}
            end
            
            table.insert(data.movement.velocity_history, {
                speed = velocity,
                x = vx,
                y = vy,
                z = vz,
                time = globals.realtime()
            })
            
            if #data.movement.velocity_history > 30 then
                table.remove(data.movement.velocity_history, 1)
            end
            
            if velocity > 200 then
                pcall(function()
                    local max_unlag_ref = ui.reference("RAGE", "Other", "Maximum lag compensation")
                    if max_unlag_ref then
                        if not data._original_max_unlag then
                            data._original_max_unlag = ui.get(max_unlag_ref)
                        end
                        ui.set(max_unlag_ref, 200)
                    end
                end)
            else
                pcall(function()
                    if data._original_max_unlag then
                        local max_unlag_ref = ui.reference("RAGE", "Other", "Maximum lag compensation")
                        if max_unlag_ref then
                            ui.set(max_unlag_ref, data._original_max_unlag)
                            data._original_max_unlag = nil
                        end
                    end
                end)
            end
        end
        
        
        if data.aa_type.detected then
            local aa_type = data.aa_type.detected
            
            if aa_type == "defensive" and tbl.breaklc and tbl.breaklc.breaking then
                pcall(function()
                    if ui.get(menu_refs["doubletap"][1]) and ui.get(menu_refs["doubletap"][2]) then
                        if not data._dt_disabled_for_defensive then
                            ui.set(menu_refs["doubletap"][2], false)
                            data._dt_disabled_for_defensive = true
                        end
                    end
                end)
            else
                pcall(function()
                    if data._dt_disabled_for_defensive then
                        ui.set(menu_refs["doubletap"][2], true)
                        data._dt_disabled_for_defensive = nil
                    end
                end)
            end
        end
    end)


    local function get_context_key(enemy, weapon_type)
        local distance = get_distance_to_player(enemy)
        local vx, vy = entity.get_prop(enemy, "m_vecVelocity")
        local velocity = vx and math.sqrt(vx*vx + vy*vy) or 0
        
        local dist_bucket = math.floor(distance / 150)
        local vel_bucket = velocity > 200 and "fast" or velocity > 100 and "medium" or "slow"
        
        return string.format("%s_d%d_%s", weapon_type, dist_bucket, vel_bucket)
    end

    local function calculate_adaptive_hitchance(enemy, weapon_type, base_hc)
        local context = get_context_key(enemy, weapon_type)
        
        
        if not adaptive_aimbot.hitchance.adjustments[context] then
            adaptive_aimbot.hitchance.adjustments[context] = {
                hits = 0,
                total = 0,
                adjustment = 0,
                last_update = 0
            }
        end
        
        local stats = adaptive_aimbot.hitchance.adjustments[context]
        
        
        local min_samples = 8
        
        
        local success_rate = 0.7  
        if stats.total >= min_samples then
            success_rate = stats.hits / stats.total
        end
        
        
        local now = globals.realtime()
        local time_since_update = now - stats.last_update
        if time_since_update > 60 then
            stats.adjustment = stats.adjustment * 0.9
        end
        
        
        local adjustment = 0
        
        if stats.total >= min_samples then
            if success_rate < 0.50 then
                adjustment = math.min(8, (0.50 - success_rate) * 15)
            elseif success_rate > 0.85 then
                adjustment = math.max(-5, (0.85 - success_rate) * 10)
            end
        end
        
        stats.adjustment = func.fclamp(stats.adjustment + adjustment * 0.1, -10, 15)
        
        
        local distance = get_distance_to_player(enemy)
        local vx, vy = entity.get_prop(enemy, "m_vecVelocity")
        local velocity = vx and math.sqrt(vx*vx + vy*vy) or 0
        
        
        local distance_modifier = 0
        if distance > 1000 then
            distance_modifier = -3
        elseif distance > 600 then
            distance_modifier = -1
        elseif distance < 200 then
            distance_modifier = 2
        end
        
        
        local velocity_modifier = 0
        if velocity > 250 then
            velocity_modifier = -3
        elseif velocity > 150 then
            velocity_modifier = -1
        end
        
        
        local weapon_modifier = 0
        if weapon_type == "awp" then
            weapon_modifier = 3
        elseif weapon_type == "scout" then
            weapon_modifier = 2
        elseif weapon_type == "pistol" then
            weapon_modifier = -2
        end
        
        
        local final_hc = base_hc + stats.adjustment + distance_modifier + velocity_modifier + weapon_modifier
        
        
        local min_hitchance = 50
        local max_hitchance = 90
        
        if weapon_type == "awp" or weapon_type == "scout" then
            min_hitchance = 60
        elseif weapon_type == "pistol" then
            min_hitchance = 45
        end
        
        
        local max_deviation = 15
        if math.abs(final_hc - base_hc) > max_deviation then
            final_hc = base_hc + (final_hc > base_hc and max_deviation or -max_deviation)
        end
        
        final_hc = func.fclamp(final_hc, min_hitchance, max_hitchance)
        final_hc = math.max(final_hc, base_hc - 10)
        
        return math.floor(final_hc), context
    end

    local function update_adaptive_stats(shot, hit)
        local enemy = shot.target
        if not enemy then return end
        
        local lp = entity.get_local_player()
        if not lp then return end
        
        local weapon = entity.get_player_weapon(lp)
        if not weapon then return end
        
        local classname = entity.get_classname(weapon) or ""
        local weapon_type = "rifle"
        
        if classname:find("AWP") then
            weapon_type = "awp"
        elseif classname:find("SSG08") then
            weapon_type = "scout"
        elseif classname:find("Deagle") or classname:find("Glock") or 
            classname:find("P250") or classname:find("Elite") or
            classname:find("FiveSeven") or classname:find("Tec9") or
            classname:find("USP") or classname:find("HKP2000") then
            weapon_type = "pistol"
        end
        
        
        local reason = shot.reason or ""
        local is_hitchance_relevant = true
        
        if not hit then
            if reason == "spread" or reason == "occlusion" or 
            reason == "prediction error" or reason == "death" then
                is_hitchance_relevant = false
            end
        end
        
        
        if is_hitchance_relevant then
            local hc_context = get_context_key(enemy, weapon_type)
            if not adaptive_aimbot.hitchance.adjustments[hc_context] then
                adaptive_aimbot.hitchance.adjustments[hc_context] = {
                    hits = 0,
                    total = 0,
                    adjustment = 0,
                    last_update = 0
                }
            end
            
            local stats = adaptive_aimbot.hitchance.adjustments[hc_context]
            stats.total = stats.total + 1
            if hit then
                stats.hits = stats.hits + 1
            end
            stats.last_update = globals.realtime()
            
            
            if stats.total > 50 then
                local ratio = stats.hits / stats.total
                stats.hits = math.floor(ratio * 30)
                stats.total = 30
            end
        end
    end
    client.set_event_callback("aim_hit", function(shot)
        update_adaptive_stats(shot, true)
        update_multipoint_stats(shot, true)  
    end)
    client.set_event_callback("aim_miss", function(shot)
        update_adaptive_stats(shot, false)
        update_multipoint_stats(shot, false)  
    end)


    client.set_event_callback("round_prestart", function()
        
        for context, stats in pairs(adaptive_aimbot.hitchance.adjustments) do
            stats.adjustment = stats.adjustment * 0.7
            stats.hits = math.floor(stats.hits * 0.8)
            stats.total = math.floor(stats.total * 0.8)
        end
        
        
        decay_multipoint_stats()
    end)

local resolver_optimization = {
    max_players_per_frame = 2,  
}


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
        
        cl_interp_ratio = math.max(TB.sv_client_min_interp_ratio or 1, 
                                    math.min(TB.sv_client_max_interp_ratio or 2, cl_interp_ratio))
        
        local tickrate = TB.tickrate or 64
        local interp_time = math.max(cl_interp, cl_interp_ratio / tickrate)
        local interp_ticks = math.floor(interp_time / globals.tickinterval())
        
        local max_rewind = TB.max_rewind_ticks or 12
        local total_window = max_rewind + interp_ticks
        
        return {
            interp_ticks = interp_ticks,
            backtrack_ticks = max_rewind,
            total_ticks = total_window,
            tickrate = tickrate
        }
    end    
    
    local lagcomp = get_lagcomp_window()
    local interp_delay = lagcomp.interp_ticks
    
    
    if not data._calibration then
        data._calibration = {
            method_calibration = {},
            prediction_history = {},
            side_priors = {left = 0.5, right = 0.5},
            stats = {
                last_calibration = 0,
                total_predictions = 0
            }
        }
    end
    
    local calibration = data._calibration
    
    
    if data.override.lock_until > 0 and globals.realtime() < data.override.lock_until then
        local lock_age = globals.realtime() - (data.override.lock_start or data.override.time)
        local decay_factor = math.max(0.7, 1.0 - (lock_age / resolver.config.lock_duration) * 0.3)
        
        local decayed_confidence = data.override.confidence * decay_factor
        
        if decayed_confidence < 0.5 then
            data.override.lock_until = 0
            data.brute.locked = false
        else
            return
        end
    end
    
    
    local jitter_analysis = analyze_jitter_pattern(data)
    data._current_jitter_analysis = jitter_analysis
    
    
    local function calibrate_confidence(raw_confidence, method_name)
        if not calibration.method_calibration[method_name] then
            calibration.method_calibration[method_name] = {
                A = 0, B = 0,
                buckets = {},
                history = {}
            }
            for i = 1, 10 do
                calibration.method_calibration[method_name].buckets[i] = {
                    count = 0,
                    hits = 0,
                    actual_rate = 0.5
                }
            end
        end
        
        return func.fclamp(raw_confidence, 0.1, 0.95)
    end
    
    
    local methods = {
        {name = "adaptive_brute", func = adaptive_bruteforce, base_weight = 1.0},
        {name = "body_delta", func = body_delta_method, base_weight = 1.2},
        {name = "body_shot", func = body_shot_resolver, base_weight = 1.4},
        {name = "strafe", func = strafe_prediction, base_weight = 1.0},
        {name = "flip_pattern", func = flip_pattern_detection, base_weight = 1.1},
        {name = "markov", func = markov_learning, base_weight = 1.5},
        {name = "distance", func = distance_resolver, base_weight = 0.9},
        {name = "aa_type", func = detect_aa_type, base_weight = 1.3}
    }
    
    local raw_predictions = {}
    
    
    if jitter_analysis.predictable and jitter_analysis.confidence > 0.70 then
        table.insert(raw_predictions, {
            value = jitter_analysis.next_side,
            raw_confidence = jitter_analysis.confidence,
            source = "jitter_pattern",
            weight = 1.2,
            method_accuracy = 0.7,
            side = jitter_analysis.next_side > 0 and "right" or "left"
        })
    end
    
    
    for _, method in ipairs(methods) do
        local prediction, confidence = method.func(ent, data)
        
        if prediction ~= 0 and confidence > 0.15 then
            table.insert(raw_predictions, {
                value = prediction,
                raw_confidence = confidence,
                source = method.name,
                weight = method.base_weight,
                method_accuracy = 0.5,
                side = prediction > 0 and "right" or "left"
            })
        end
    end
    
    if #raw_predictions == 0 then
        local pose = entity.get_prop(ent, "m_flPoseParameter", 11)
        if pose then
            local body_yaw = (pose * 120) - 60
            data.override.value = body_yaw > 0 and 58 or -58
            data.override.confidence = 0.45
            data.override.time = globals.realtime()
            plist.set(ent, "Override resolver", data.override.value / 60)
            plist.set(ent, "Correction active", true)
        end
        return
    end
    
    
    local calibrated_predictions = {}
    
    for _, pred in ipairs(raw_predictions) do
        local calibrated_conf = calibrate_confidence(pred.raw_confidence, pred.source)
        
        table.insert(calibrated_predictions, {
            value = pred.value,
            confidence = calibrated_conf,
            source = pred.source,
            weight = pred.weight,
            method_accuracy = pred.method_accuracy,
            side = pred.side
        })
    end
    
    
    local function bayesian_fusion(predictions)
        local left_predictions = {}
        local right_predictions = {}
        
        for _, pred in ipairs(predictions) do
            if pred.side == "left" then
                table.insert(left_predictions, pred)
            else
                table.insert(right_predictions, pred)
            end
        end
        
        local function calculate_side_posterior(side_predictions, other_predictions, prior)
            local likelihood = 1.0
            for _, pred in ipairs(side_predictions) do
                likelihood = likelihood * pred.confidence
            end
            
            local anti_likelihood = 1.0
            for _, pred in ipairs(other_predictions) do
                anti_likelihood = anti_likelihood * (1 - pred.confidence)
            end
            
            local posterior = (likelihood * prior) / math.max(0.001, likelihood * prior + anti_likelihood * (1 - prior))
            return posterior
        end
        
        local left_posterior = calculate_side_posterior(
            left_predictions, 
            right_predictions, 
            calibration.side_priors.left
        )
        
        local right_posterior = calculate_side_posterior(
            right_predictions, 
            left_predictions, 
            calibration.side_priors.right
        )
        
        local total = left_posterior + right_posterior
        if total > 0 then
            left_posterior = left_posterior / total
            right_posterior = right_posterior / total
        else
            left_posterior = 0.5
            right_posterior = 0.5
        end
        
        return left_posterior, right_posterior, left_predictions, right_predictions
    end
    
    local left_prob, right_prob, left_preds, right_preds = bayesian_fusion(calibrated_predictions)
    
    
    local winning_side = left_prob > right_prob and "left" or "right"
    local winning_prob = math.max(left_prob, right_prob)
    local winning_predictions = winning_side == "left" and left_preds or right_preds
    
    
    local final_yaw = 0
    
    if #winning_predictions > 0 then
        local weighted_sum = 0
        local weight_sum = 0
        
        for _, pred in ipairs(winning_predictions) do
            local weight = pred.confidence * pred.weight
            weighted_sum = weighted_sum + pred.value * weight
            weight_sum = weight_sum + weight
        end
        
        if weight_sum > 0 then
            final_yaw = weighted_sum / weight_sum
        else
            final_yaw = winning_side == "left" and -58 or 58
        end
    else
        final_yaw = winning_side == "left" and -58 or 58
    end
    
    
    local common_angles = {-58, -45, -30, -15, 15, 30, 45, 58}
    local snap_tolerance = resolver.config.angle_tolerance or 8
    
    for _, angle in ipairs(common_angles) do
        if math.abs(final_yaw - angle) < snap_tolerance then
            final_yaw = angle
            break
        end
    end
    
    
    if winning_side == "left" and final_yaw > 0 then
        final_yaw = -math.abs(final_yaw)
    elseif winning_side == "right" and final_yaw < 0 then
        final_yaw = math.abs(final_yaw)
    end
    
    final_yaw = func.fclamp(final_yaw, -60, 60)
    
    
    local final_confidence = winning_prob
    
    
    local agreement_bonus = 0
    if #winning_predictions >= 2 then
        local angle_variance = 0
        local mean_angle = final_yaw
        
        for _, pred in ipairs(winning_predictions) do
            angle_variance = angle_variance + (pred.value - mean_angle)^2
        end
        angle_variance = angle_variance / #winning_predictions
        
        local agreement_factor = 1.0 / (1.0 + math.sqrt(angle_variance) * 0.05)
        agreement_bonus = (agreement_factor - 0.5) * 0.15
    end
    
    
    local source_bonus = math.min(0.10, (#winning_predictions - 1) * 0.025)
    
    
    local avg_accuracy = 0
    for _, pred in ipairs(winning_predictions) do
        avg_accuracy = avg_accuracy + (pred.method_accuracy or 0.5)
    end
    avg_accuracy = avg_accuracy / math.max(1, #winning_predictions)
    local accuracy_bonus = (avg_accuracy - 0.5) * 0.15
    
    final_confidence = final_confidence + agreement_bonus + source_bonus + accuracy_bonus
    
    
    local interp_penalty = interp_delay * 0.008
    final_confidence = final_confidence - interp_penalty
    
    final_confidence = func.fclamp(final_confidence, 0.25, 0.95)
    
    
    table.insert(calibration.prediction_history, {
        predicted_side = final_yaw,
        confidence = final_confidence,
        side = final_yaw > 0 and "right" or "left",
        time = globals.realtime(),
        hit = nil,
        sources = {}
    })
    
    for _, pred in ipairs(calibrated_predictions) do
        local cal = calibration.method_calibration[pred.source]
        if cal then
            table.insert(cal.history, {
                confidence = pred.confidence,
                hit = nil,
                time = globals.realtime()
            })
        end
    end
    
    while #calibration.prediction_history > 100 do
        table.remove(calibration.prediction_history, 1)
    end
    
    
    data.override.value = final_yaw
    data.override.confidence = final_confidence
    data.override.source = #winning_predictions > 0 and winning_predictions[1].source or "bayesian_fusion"
    data.override.time = globals.realtime()
    data.override.fusion_weights = calibrated_predictions
    data.override.bayesian_result = {
        left_prob = left_prob,
        right_prob = right_prob,
        winning_side = winning_side,
        prediction_count = #calibrated_predictions
    }
    
    table.insert(data.override.prediction_history, {
        value = final_yaw,
        confidence = final_confidence,
        source = data.override.source,
        time = globals.realtime(),
        bayesian = {left = left_prob, right = right_prob}
    })
    
    if #data.override.prediction_history > 50 then
        table.remove(data.override.prediction_history, 1)
    end
    
    
    plist.set(ent, "Override resolver", final_yaw / 60)
    plist.set(ent, "Correction active", true)
end

local function resolver_paint()
    if not resolver.enabled then
        return
    end
    
    local enemies = entity.get_players(true)
    if #enemies == 0 then return end
    
    
    local threat = client.current_threat()
    local resolved_count = 0
    
    
    if threat and entity.is_alive(threat) and not entity.is_dormant(threat) then
        resolve_player(threat)
        resolved_count = resolved_count + 1
    end
    
    
    for _, ent in ipairs(enemies) do
        if resolved_count >= resolver_optimization.max_players_per_frame then
            break
        end
        
        if ent == threat then
            goto continue
        end
        
        if entity.is_alive(ent) and not entity.is_dormant(ent) then
            resolve_player(ent)
            resolved_count = resolved_count + 1
        end
        
        ::continue::
    end
end


local original_analyze_jitter_pattern = analyze_jitter_pattern

local function optimized_analyze_jitter_pattern(data)
    if not data then return {predictable = false, next_side = 0, confidence = 0} end
    
    
    if data._jitter_cache then
        local cache = data._jitter_cache
        local now = globals.realtime()
        
        
        if (now - cache.time) < 0.03 then
            return cache.result
        end
    end
    
    
    local result = original_analyze_jitter_pattern(data)
    
    
    data._jitter_cache = {
        result = result,
        time = globals.realtime()
    }
    
    return result
end

analyze_jitter_pattern = optimized_analyze_jitter_pattern


local original_detect_aa_type = detect_aa_type

local function optimized_detect_aa_type(ent, data)
    if not data then return 0, 0 end
    
    local now = globals.realtime()
    
    
    if data._aa_type_cache then
        local cache = data._aa_type_cache
        
        
        if (now - cache.time) < 0.05 then
            return cache.side, cache.confidence
        end
    end
    
    
    local side, confidence = original_detect_aa_type(ent, data)
    
    
    data._aa_type_cache = {
        side = side,
        confidence = confidence,
        time = now
    }
    
    return side, confidence
end

detect_aa_type = optimized_detect_aa_type


local original_markov_learning = markov_learning

local function optimized_markov_learning(ent, data)
    if not data then return 0, 0 end
    
    local now = globals.realtime()
    
    
    if data._markov_cache then
        local cache = data._markov_cache
        
        
        if (now - cache.time) < 0.08 then
            return cache.side, cache.confidence
        end
    end
    
    
    local side, confidence = original_markov_learning(ent, data)
    
    
    data._markov_cache = {
        side = side,
        confidence = confidence,
        time = now
    }
    
    return side, confidence
end

markov_learning = optimized_markov_learning


local original_setup_resolver = setup_resolver

setup_resolver = function()
    client.set_event_callback("aim_fire", on_resolver_aim_fire)
    client.set_event_callback("aim_hit", on_resolver_aim_hit)
    client.set_event_callback("aim_miss", on_resolver_aim_miss)
    
    
    client.set_event_callback("paint", resolver_paint)
    
    client.set_event_callback("round_prestart", function()
        for idx, data in pairs(resolver.players) do
            if data.brute then
                data.brute.cycle_speed = 0.5
            end
        end
    end)
    
    client.set_event_callback("round_start", function()
        update_server_cvars()
    end)
    
    client.delay_call(0.1, function()
        update_server_cvars()
    end)
    
    ui.set_callback(menu["rage"]["aaresolver"], function()
        resolver.enabled = ui.get(menu["rage"]["aaresolver"])
    end)
end


client.set_event_callback("player_death", function(e)
    local victim = client.userid_to_entindex(e.userid)
    if victim and resolver.players then
        local idx = tostring(entity.get_steam64(victim) or victim)
        resolver.players[idx] = nil
    end
end)

client.set_event_callback("player_disconnect", function(e)
    local idx = client.userid_to_entindex(e.userid)
    if idx and resolver.players then
        local key = tostring(entity.get_steam64(idx) or idx)
        resolver.players[key] = nil
    end
end)
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
                    
                    
                    local name = entity.get_player_name(idx) or "?"
                    local weapon = (e.weapon or ""):lower()

                    local br, bg, bb = 255, 255, 255
                    local gr, gg, gb = ui.get(menu["visuals & misc"]["visuals"]["watermark_color"])
                    local sr, sg, sb = 255, 255, 255
                    local buyr, buyg, buyb = 255, 255, 255

                    local parts = {}
                    table.insert(parts, {br, bg, bb, "["})
                    table.insert(parts, {gr, gg, gb, "Lua"})
                    table.insert(parts, {sr, sg, sb, "Sense"})
                    table.insert(parts, {br, bg, bb, "] "})
                    table.insert(parts, {buyr, buyg, buyb, name .. " bought "})
                    table.insert(parts, {255, 255, 255, weapon})
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
                        local key_base = tostring(tbl.getstate(false, false, 0, false)) 
                        
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



