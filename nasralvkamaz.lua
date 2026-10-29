------------------------------------------------------------
-- miSSEnSE HACK
------------------------------------------------------------
do
    local cleanupFn
    if type(getgenv) == "function" then
        local ok, env = pcall(getgenv)
        if ok and type(env) == "table" then cleanupFn = env.MS_CLEANUP end
    end
    if type(cleanupFn) == "function" then pcall(cleanupFn) end
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

------------------------------------------------------------
-- photo setts
------------------------------------------------------------
local PHOTO = "https://raw.githubusercontent.com/aap27781-commits/hhhh/main/fell%20the%20MissSense.png"
local PHOTO_SIZE = UDim2.new(1.16, -1, 3, 210)

local function getContainers()
	local t = {CoreGui, LocalPlayer:WaitForChild("PlayerGui")}
	if gethui then table.insert(t, gethui()) end
	return t
end

------------------------------------------------------------
-- tRICK
------------------------------------------------------------

local esp_container = Instance.new("Folder")
esp_container.Name = "MissSenseESP"
local espParent = CoreGui:FindFirstChild("RobloxGui") or CoreGui
esp_container.Parent = espParent

local esp = {}
esp.create_obj = function(new, args, tbl)
    local obj = Instance.new(new)
    for i, v in pairs(args) do obj[i] = v end
    if tbl then table.insert(tbl, obj) end
    return obj
end

-- ESP FONT SYSTEM (TTF/OTF -> generated .font family descriptors)
-- Put custom .ttf/.otf files or a valid Roblox .font JSON family descriptor
-- into workspace-MissSense. TTF/OTF files are wrapped in a .font descriptor
-- before Font.new is called, as required by Roblox's Font family API.
local ESP_FONT_NAME = "Minecraftia"
local ESP_FONT_SIZE = 12
local ESP_FLAGS_FONT_NAME = "Minecraftia"
local ESP_FLAGS_FONT_SIZE = 9
local ESP_FONT_FACE
local ESP_FLAGS_FONT_FACE
local ESP_FONT_FALLBACK = Font.fromEnum(Enum.Font.GothamBold)
local ESP_FONT_CACHE = {}
local ESP_FONT_OPTIONS = {
    ["Tahoma"] = { file = "tahoma.ttf", url = "https://raw.githubusercontent.com/i77lhm/storage/main/fonts/fs-tahoma-8px.ttf" },
    ["Windows XP Tahoma"] = { file = "windows-xp-tahoma.ttf", url = "https://github.com/sametexe001/luas/raw/refs/heads/main/fonts/TAHOMA-8PT-BOLD-WINDOWS-XP.TTF" },
    ["Tahoma 8pt Bold XP"] = { file = "TAHOMA-8PT-BOLD-WINDOWS-XP.TTF", url = "https://github.com/sametexe001/luas/raw/refs/heads/main/fonts/TAHOMA-8PT-BOLD-WINDOWS-XP.TTF" },
    ["Smallest Pixel"] = { file = "smallest_pixel-7.ttf", url = "https://raw.githubusercontent.com/i77lhm/storage/main/fonts/smallest_pixel-7.ttf" },
    ["ProggyClean"] = { file = "ProggyClean.ttf", url = "https://github.com/ocornut/imgui/raw/refs/heads/master/misc/fonts/ProggyClean.ttf" },
    ["Pixearg"] = { file = "PIXEARG_.TTF", url = "https://github.com/KingVonOBlockJoyce/vaderpaste.luau/raw/refs/heads/main/Pixel.ttf" },
    ["Outfit Medium"] = { file = "Outfit-Medium.ttf", url = "https://github.com/sametexe001/luas/raw/refs/heads/main/fonts/Outfit-Medium.ttf" },
    ["Minecraftia"] = { file = "Minecraftia-Regular.ttf", url = "https://github.com/i77lhm/storage/raw/refs/heads/main/fonts/Minecraftia-Regular.ttf" },
}
local ESP_FONT_FOLDER = "workspace-MissSense"
local ESP_PREVIEW_LABELS, ESP_EDGE_LABELS = {}, {}
local ESP_FONT_WARNED = {}

local function espFontLog(level, name, message)
    local line = string.format("[ESP FONT][%s][%s] %s", tostring(level), tostring(name or "font"), tostring(message))
    if level == "ERROR" or level == "WARN" then warn(line) else print(line) end
end

local function validEspFontData(data)
    if type(data) ~= "string" or #data < 1024 then return false, "file missing/too small" end
    local sig = data:sub(1, 4)
    if sig ~= "\0\1\0\0" and sig ~= "OTTO" and sig ~= "true" and sig ~= "ttcf" then
        return false, "invalid TTF/OTF signature " .. string.format("%q", sig)
    end
    return true
end

local function ensureEspFontFolder()
    if type(isfolder) == "function" then
        local ok, exists = pcall(isfolder, ESP_FONT_FOLDER)
        if ok and exists then return true end
    end
    if type(makefolder) == "function" then
        local ok = pcall(makefolder, ESP_FONT_FOLDER)
        if ok then return true end
    end
    -- Some executors omit isfolder; file APIs may still work if the folder exists.
    return type(isfile) == "function"
end

local function resolveEspFont(name)
    if type(name) ~= "string" or name == "" then return nil, nil, "empty selection" end
    local bundled = ESP_FONT_OPTIONS[name]
    if bundled then return bundled.file, bundled.url, nil end
    -- Custom files supported in workspace-MissSense: raw TTF/OTF files and
    -- Roblox font-family descriptors (.font JSON files).
    local safe = name:gsub("^.*[/\\]", "")
    local lower = safe:lower()
    if not (lower:match("%.ttf$") or lower:match("%.otf$") or lower:match("%.font$")) then
        return nil, nil, "unsupported extension (use .ttf, .otf, or .font)"
    end
    return safe, nil, nil
end

local function validEspFontFamilyData(data)
    if type(data) ~= "string" or #data < 2 then return false, "family file is empty" end
    local httpService = game:GetService("HttpService")
    local ok, decoded = pcall(function() return httpService:JSONDecode(data) end)
    if not ok or type(decoded) ~= "table" then return false, "invalid .font JSON" end
    if type(decoded.name) ~= "string" or type(decoded.faces) ~= "table" or type(decoded.faces[1]) ~= "table" then
        return false, "missing name/faces in .font JSON"
    end
    if type(decoded.faces[1].assetId) ~= "string" or decoded.faces[1].assetId == "" then
        return false, "missing faces[1].assetId in .font JSON"
    end
    return true
end

local function loadEspFont(name)
    if type(name) ~= "string" or name == "" then
        if not ESP_FONT_WARNED.empty then
            ESP_FONT_WARNED.empty = true
            espFontLog("WARN", "nil", "empty dropdown value ignored; current font stays active")
        end
        return nil, false
    end
    local cacheKey = name:lower()
    if ESP_FONT_CACHE[cacheKey] then return ESP_FONT_CACHE[cacheKey], true end

    local fileName, url, resolveError = resolveEspFont(name)
    if not fileName then
        if not ESP_FONT_WARNED[name] then
            ESP_FONT_WARNED[name] = true
            espFontLog("WARN", name, resolveError or "unsupported font")
        end
        return nil, false
    end
    local assetFn = type(getcustomasset) == "function" and getcustomasset or getsynasset
    if type(isfile) ~= "function" or type(readfile) ~= "function" or type(assetFn) ~= "function" then
        espFontLog("ERROR", name, "executor needs isfile, readfile and getcustomasset/getsynasset")
        return nil, false
    end
    if not ensureEspFontFolder() then
        espFontLog("ERROR", name, "cannot access/create " .. ESP_FONT_FOLDER)
        return nil, false
    end

    local path = ESP_FONT_FOLDER .. "/" .. fileName
    local lowerName = fileName:lower()
    local isFamilyFile = lowerName:match("%.font$") ~= nil
    espFontLog("INFO", name, "loading " .. path)

    -- A .font file is a JSON font-family descriptor, not a TTF binary.
    -- Executors can expose that descriptor as an asset and Font.new consumes it.
    if isFamilyFile then
        local existsOk, exists = pcall(isfile, path)
        if not existsOk or not exists then
            espFontLog("ERROR", name, "family descriptor not found: " .. path)
            return nil, false
        end
        local readOk, familyData = pcall(readfile, path)
        if not readOk then
            espFontLog("ERROR", name, "cannot read .font descriptor: " .. tostring(familyData))
            return nil, false
        end
        local valid, why = validEspFontFamilyData(familyData)
        if not valid then
            espFontLog("ERROR", name, "invalid .font descriptor: " .. tostring(why))
            return nil, false
        end
        local assetOk, familyAsset = pcall(assetFn, path)
        if not assetOk or type(familyAsset) ~= "string" or familyAsset == "" then
            espFontLog("ERROR", name, "could not register .font descriptor asset: " .. tostring(familyAsset))
            return nil, false
        end
        local faceOk, face = pcall(function()
            return Font.new(familyAsset, Enum.FontWeight.Regular, Enum.FontStyle.Normal)
        end)
        if not faceOk then
            espFontLog("ERROR", name, "Font.new(.font) failed: " .. tostring(face))
            return nil, false
        end
        ESP_FONT_CACHE[cacheKey] = face
        espFontLog("SUCCESS", name, "custom .font family ready and cached")
        return face, true
    end

    -- Raw TTF/OTF path: load/validate the binary, expose it as an asset, then
    -- write the JSON .font family descriptor Roblox expects and pass THAT asset
    -- to Font.new. Passing the TTF asset directly to Font.new is not sufficient.
    local data
    local existsOk, exists = pcall(isfile, path)
    if existsOk and exists then
        local readOk, content = pcall(readfile, path)
        if readOk then
            local valid = validEspFontData(content)
            if valid then data = content else espFontLog("WARN", name, "cached font file invalid; trying download") end
        end
    end

    if not data and url then
        local body, downloadError
        local requestFn
        if type(syn) == "table" and type(syn.request) == "function" then requestFn = syn.request
        elseif type(http) == "table" and type(http.request) == "function" then requestFn = http.request
        elseif type(request) == "function" then requestFn = request
        elseif type(http_request) == "function" then requestFn = http_request end
        if requestFn then
            local ok, response = pcall(requestFn, {Url = url, Method = "GET"})
            if ok and type(response) == "table" then
                local status = tonumber(response.StatusCode or response.Status or 0) or 0
                if status == 0 or (status >= 200 and status < 300) then body = response.Body or response.body
                else downloadError = "HTTP " .. tostring(status) end
            else downloadError = tostring(response) end
        end
        if type(body) ~= "string" then
            local ok, result = pcall(function() return game:HttpGet(url) end)
            if ok then body = result else downloadError = tostring(result) end
        end
        local valid, why = validEspFontData(body)
        if valid then
            data = body
            if type(writefile) == "function" then
                local writeOk, writeErr = pcall(writefile, path, body)
                if not writeOk then espFontLog("WARN", name, "downloaded but cache write failed: " .. tostring(writeErr)) end
            end
        else
            espFontLog("ERROR", name, "download failed: " .. tostring(downloadError or why or "invalid response"))
            return nil, false
        end
    elseif not data and not url then
        espFontLog("ERROR", name, "custom font file not found/invalid: " .. path .. "; put a valid .ttf/.otf or .font file there")
        return nil, false
    end

    local fontAssetOk, fontAsset = pcall(assetFn, path)
    if not fontAssetOk or type(fontAsset) ~= "string" or fontAsset == "" then
        espFontLog("ERROR", name, "TTF/OTF asset creation failed: " .. tostring(fontAsset))
        return nil, false
    end

    local familyName = fileName:gsub("%.[^%.]+$", ""):gsub("[^%w_%-]", "_")
    if familyName == "" then familyName = "MissSenseCustomFont" end
    local familyPath = ESP_FONT_FOLDER .. "/__MissSense_" .. familyName .. ".font"
    local httpService = game:GetService("HttpService")
    local familyDescriptor = {
        name = "MissSense_" .. familyName,
        faces = {{
            name = "Regular",
            weight = 400,
            style = "normal",
            assetId = fontAsset,
        }},
    }
    local encodeOk, familyJson = pcall(function() return httpService:JSONEncode(familyDescriptor) end)
    if not encodeOk or type(familyJson) ~= "string" then
        espFontLog("ERROR", name, "could not encode .font family descriptor: " .. tostring(familyJson))
        return nil, false
    end
    if type(writefile) ~= "function" then
        espFontLog("ERROR", name, "executor lacks writefile; cannot create .font family descriptor")
        return nil, false
    end
    local writeOk, writeErr = pcall(writefile, familyPath, familyJson)
    if not writeOk then
        espFontLog("ERROR", name, "could not write .font descriptor: " .. tostring(writeErr))
        return nil, false
    end

    local familyAssetOk, familyAsset = pcall(assetFn, familyPath)
    if not familyAssetOk or type(familyAsset) ~= "string" or familyAsset == "" then
        espFontLog("ERROR", name, "could not register generated .font descriptor: " .. tostring(familyAsset))
        return nil, false
    end
    local faceOk, face = pcall(function()
        return Font.new(familyAsset, Enum.FontWeight.Regular, Enum.FontStyle.Normal)
    end)
    if not faceOk then
        espFontLog("ERROR", name, "Font.new(generated .font) failed: " .. tostring(face))
        return nil, false
    end
    ESP_FONT_CACHE[cacheKey] = face
    espFontLog("SUCCESS", name, "TTF/OTF loaded through generated .font family and cached")
    return face, true
end

local function isEspTextObject(obj)
    return obj and (obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox"))
end
local function isEspFlagLabel(obj)
    local parent = obj and obj.Parent
    while parent and parent ~= esp_container do
        if parent.Name == "flag_holder" or parent.Name == "body_status_holder" then return true end
        parent = parent.Parent
    end
    return false
end
local function applyOneEspFont(obj, isFlag)
    if not isEspTextObject(obj) or not obj.Parent then return end
    pcall(function()
        obj.FontFace = (isFlag and ESP_FLAGS_FONT_FACE) or ESP_FONT_FACE or ESP_FONT_FALLBACK
        obj.TextSize = isFlag and ESP_FLAGS_FONT_SIZE or ESP_FONT_SIZE
    end)
end
local function applyEspFontSettings()
    if esp_container then
        for _, obj in ipairs(esp_container:GetDescendants()) do
            if isEspTextObject(obj) then applyOneEspFont(obj, isEspFlagLabel(obj)) end
        end
    end
    for i = #ESP_PREVIEW_LABELS, 1, -1 do
        local obj = ESP_PREVIEW_LABELS[i]
        if not obj or not obj.Parent then table.remove(ESP_PREVIEW_LABELS, i)
        else applyOneEspFont(obj, false) end
    end
    for i = #ESP_EDGE_LABELS, 1, -1 do
        local obj = ESP_EDGE_LABELS[i]
        if not obj or not obj.Parent then table.remove(ESP_EDGE_LABELS, i)
        else applyOneEspFont(obj, false) end
    end
end

local function getEspFontItems()
    local items, seen = {}, {}
    local function add(name)
        if type(name) ~= "string" or name == "" then return end
        local lower = name:lower()
        if seen[lower] then return end
        seen[lower] = true
        table.insert(items, name)
    end

    for name in pairs(ESP_FONT_OPTIONS) do add(name) end

    -- listfiles may throw, return nil, or return non-string entries depending on executor.
    if type(listfiles) == "function" then
        local ok, files = pcall(listfiles, ESP_FONT_FOLDER)
        if ok and type(files) == "table" then
            for _, fullPath in ipairs(files) do
                if type(fullPath) == "string" then
                    local fileName = fullPath:match("([^/\\]+)$")
                    local lower = fileName and fileName:lower()
                    local internalGeneratedFamily = fileName and lower:match("^__misssense_.*%.font$")
                    if fileName and not internalGeneratedFamily and
                        (lower:match("%.ttf$") or lower:match("%.otf$") or lower:match("%.font$")) then
                        add(fileName)
                    end
                end
            end
        elseif not ok then
            espFontLog("WARN", "custom fonts", "listfiles failed: " .. tostring(files))
        end
    end

    table.sort(items, function(a, b) return a:lower() < b:lower() end)
    return items
end

ESP_FONT_FACE = select(1, loadEspFont(ESP_FONT_NAME)) or ESP_FONT_FALLBACK
ESP_FLAGS_FONT_FACE = select(1, loadEspFont(ESP_FLAGS_FONT_NAME)) or ESP_FONT_FACE
if esp_container then
    esp_container.DescendantAdded:Connect(function(obj)
        if isEspTextObject(obj) then
            task.defer(function()
                if obj and obj.Parent then pcall(applyOneEspFont, obj, isEspFlagLabel(obj)) end
            end)
        end
    end)
end
task.defer(applyEspFontSettings)
------------------------------------------------------------
-- ESP MODULE
------------------------------------------------------------
do
    local _CFramenew              = CFrame.new
    local _Vector2new             = Vector2.new
    local _Vector3new             = Vector3.new
    local _FindFirstChild         = game.FindFirstChild
    local _FindFirstChildOfClass  = game.FindFirstChildOfClass
    local _Vector3zeromin         = Vector3.zero.Min
    local _Vector2zeromin         = Vector2.zero.Min
    local _Vector3zeromax         = Vector3.zero.Max
    local _Vector2zeromax         = Vector2.zero.Max
    local _VectorToObjectSpace    = CFrame.new().VectorToObjectSpace
    local _IsA                    = game.IsA
    local unpack                  = table.unpack
    local tablecreate             = table.create
    local mathround               = math.round
    local mathfloor               = math.floor

    local esp_workspace = game:GetService("Workspace")
    local esp_plrs      = game:GetService("Players")
    local esp_lplr      = esp_plrs.LocalPlayer

    
    local function getCamera()   return esp_workspace.CurrentCamera end
    local function getGuiInset() return game:GetService("GuiService"):GetGuiInset() end

    esp_table  = {}
    loaded_plrs = {}

    esp_table.get_character = function(player) return player.Character end
    esp_table.get_root      = function(player, character) return _FindFirstChild(character, "HumanoidRootPart") end
    esp_table.get_humanoid  = function(player, character) return _FindFirstChildOfClass(character, "Humanoid") end
    esp_table.get_health = function(player, character, humanoid)
    local blood = character:GetAttribute("IBlood")
    if blood then
        return blood, 5000
    end
    return humanoid.Health, humanoid.MaxHealth
end
    esp_table.get_team      = function(player) return esp_lplr.Team and player.Team and esp_lplr.Team == player.Team end
    esp_table.get_gun = function(player, character, humanoid)
    if not character then return nil end
    local held = character:GetAttribute("IHeld")
    if held and held ~= "" then return held end
    local tool = game.FindFirstChildOfClass(character, "Tool")
    return tool and tool.Name or nil
end

    esp_table.registered_flags = {}
    esp_table.settings = {
        enemy = {
            main_settings = {
                fade_time = 1, team_check = false, dead_check = true, dist_check = true,
                max_distance = 1500, skeleton_rate = 0.05,
                gradient_rotate = 0, gradient_rotate_enabled = false, gradient_spin = false, gradient_speed = 0,
                holder_spin = false, holder_speed = 360,
            },
            enabled = false,
            box = false, box_fill = false, box_glow = false,
            health_bar = false, name = false,
            health_text = false, distance = false, weapon = false,
            skeleton = false, flags = false, chams = false,
            box_color         = { Color3.new(1,1,1), Color3.new(1,1,1), 0 },
            box_fill_color    = { Color3.fromRGB(80,170,255), Color3.fromRGB(180,80,255), 0.72, 0.82 },
            box_glow_color    = { Color3.fromRGB(80,170,255), Color3.fromRGB(180,80,255), 0.25, 0.25 },
            health_bar_color  = { Color3.fromRGB(0,255,0), Color3.fromRGB(255,0,0) },
            name_color        = { Color3.new(1,1,1), 0 },
            health_text_color = { Color3.new(1,1,1), 0 },
            distance_color    = { Color3.new(1,1,1), 0 },
            weapon_color      = { Color3.new(1,1,1), 0 },
            skeleton_color    = { Color3.new(1,1,1), 0 },
            flags_color       = { Color3.new(1,1,1), 0 },
            box_rotation      = 0,
            chams_color       = { Color3.new(1,1,1), 0 },
            chams_glow_factor = 2,
        }
    }

    local VERTICES = {
        _Vector3new(-1,-1,-1), _Vector3new(-1,1,-1), _Vector3new(-1,1,1), _Vector3new(-1,-1,1),
        _Vector3new(1,-1,-1),  _Vector3new(1,1,-1),  _Vector3new(1,1,1),  _Vector3new(1,-1,1),
    }
    local skeleton_order = {
        LeftFoot="LeftLowerLeg", LeftLowerLeg="LeftUpperLeg", LeftUpperLeg="LowerTorso",
        RightFoot="RightLowerLeg", RightLowerLeg="RightUpperLeg", RightUpperLeg="LowerTorso",
        LeftHand="LeftLowerArm", LeftLowerArm="LeftUpperArm", LeftUpperArm="UpperTorso",
        RightHand="RightLowerArm", RightLowerArm="RightUpperArm", RightUpperArm="UpperTorso",
        LowerTorso="UpperTorso", UpperTorso="Head",
    }

    local function isBodyPart(name)
        return name=="Head" or name:find("Torso") or name:find("Leg")
            or name:find("Arm") or name:find("Hand") or name:find("Foot")
    end

    local function getBoundingBox(parts)
        local min, max
        for _, part in pairs(parts) do
            local cf, sz = part[1], part[2]
            min = _Vector3zeromin(min or cf.Position, (cf - sz*0.5).Position)
            max = _Vector3zeromax(max or cf.Position, (cf + sz*0.5).Position)
        end
        if not min or not max then return _CFramenew(), _Vector3new() end
        local center = (min+max)*0.5
        return _CFramenew(center, _Vector3new(center.X, center.Y, max.Z)), max-min
    end

    
    local function worldToScreen(world)
        local cam = getCamera()
        local s, b = cam:WorldToViewportPoint(world)
        return _Vector2new(s.X, s.Y), b, s.Z
    end

    local function calculateCorners(cframe, size)
        local cam = getCamera()
        if not cam then
            return { topLeft=Vector2.zero, topRight=Vector2.zero,
                     bottomLeft=Vector2.zero, bottomRight=Vector2.zero, corners={} }
        end
        local corners = tablecreate(#VERTICES)
        for i, v in ipairs(VERTICES) do
            local s = cam:WorldToViewportPoint((cframe + size*0.5*v).Position)
            corners[i] = _Vector2new(s.X, s.Y)
        end
        if #corners == 0 then
            return { topLeft=Vector2.zero, topRight=Vector2.zero,
                     bottomLeft=Vector2.zero, bottomRight=Vector2.zero, corners={} }
        end
        local mn = _Vector2zeromin(cam.ViewportSize, unpack(corners))
        local mx = _Vector2zeromax(Vector2.zero,     unpack(corners))
        return {
            corners     = corners,
            topLeft     = _Vector2new(mn.X, mn.Y),
            topRight    = _Vector2new(mx.X, mn.Y),
            bottomLeft  = _Vector2new(mn.X, mx.Y),
            bottomRight = _Vector2new(mx.X, mx.Y),
        }
    end

    local create_esp, destroy_esp

    create_esp = function(plr_instance)
        if not plr_instance or plr_instance == esp_lplr or loaded_plrs[plr_instance] then return end

        loaded_plrs[plr_instance] = { obj={}, connections={} }

        local flags_table      = {}
        local chams_table      = {}
        local registered_flags = esp_table.registered_flags
        local plr              = loaded_plrs[plr_instance]
        local obj              = plr.obj

        local main_holder = esp.create_obj("Frame", {
            Parent=esp_container, ZIndex=2, BorderSizePixel=0,
            Size=UDim2.fromScale(0,0), Position=UDim2.fromScale(0,0),
            BackgroundTransparency=1, Visible=false,
        }, obj)
        local box_glow = esp.create_obj("ImageLabel", {
            Parent=main_holder, ZIndex=0, BorderSizePixel=0,
            BackgroundTransparency=1, Image="rbxassetid://5028857084",
            ImageTransparency=0.25, ScaleType=Enum.ScaleType.Slice,
            SliceCenter=Rect.new(24,24,276,276),
            Position=UDim2.new(0,-12,0,-12), Size=UDim2.new(1,24,1,24),
            Visible=false,
        }, obj)
        local box_glow_gradient = esp.create_obj("UIGradient", {
            Parent=box_glow, Rotation=0,
            Color=ColorSequence.new(Color3.fromRGB(80,170,255), Color3.fromRGB(180,80,255)),
        }, obj)
        local box_fill = esp.create_obj("Frame", {
            Parent=main_holder, ZIndex=0, BorderSizePixel=0,
            Position=UDim2.new(0,1,0,1), Size=UDim2.new(1,-2,1,-2),
            BackgroundColor3=Color3.fromRGB(80,170,255),
            BackgroundTransparency=0, Visible=false,
        }, obj)
        local box_fill_gradient = esp.create_obj("UIGradient", {
            Parent=box_fill, Rotation=90,
            Color=ColorSequence.new(Color3.fromRGB(80,170,255), Color3.fromRGB(180,80,255)),
            Transparency=NumberSequence.new(0,0),
        }, obj)
        local box_holder = esp.create_obj("Frame", {
            Parent=main_holder, ZIndex=1, BorderSizePixel=0,
            Size=UDim2.new(1,-2,1,-2), Position=UDim2.new(0,1,0,1),
            BackgroundTransparency=1,
        }, obj)
        local box_outline_holder = esp.create_obj("Frame", {
            Parent=main_holder, ZIndex=-1, BorderSizePixel=0,
            BackgroundColor3=Color3.new(1,1,1),
            Size=UDim2.new(1,-4,1,-4), Position=UDim2.new(0,2,0,2),
            BackgroundTransparency=1,
        }, obj)
        local main_box = esp.create_obj("UIStroke", {
            Parent=box_holder, ApplyStrokeMode=Enum.ApplyStrokeMode.Border,
            LineJoinMode=Enum.LineJoinMode.Miter, Color=Color3.new(1,1,1),
        }, obj)
        local main_box_color = esp.create_obj("UIGradient", {
            Parent=main_box,
            Color=ColorSequence.new{
                ColorSequenceKeypoint.new(0, Color3.new(1,1,1)),
                ColorSequenceKeypoint.new(1, Color3.new(1,1,1)),
            },
        }, obj)
        local main_box_outline_1 = esp.create_obj("UIStroke", {
            Parent=main_holder, ApplyStrokeMode=Enum.ApplyStrokeMode.Border,
            LineJoinMode=Enum.LineJoinMode.Miter, Color=Color3.new(),
        }, obj)
        local main_box_outline_2 = esp.create_obj("UIStroke", {
            Parent=box_outline_holder, ApplyStrokeMode=Enum.ApplyStrokeMode.Border,
            LineJoinMode=Enum.LineJoinMode.Miter, Color=Color3.new(),
        }, obj)
        local main_name = esp.create_obj("TextLabel", {
            Parent=main_holder, TextStrokeTransparency=0, BorderSizePixel=0,
            TextSize=ESP_FONT_SIZE, FontFace = ESP_FONT_FACE or Font.fromEnum(Enum.Font.Code), TextColor3=Color3.new(1,1,1),
            BackgroundTransparency=1, AnchorPoint=Vector2.new(0.5,0),
            Size=UDim2.new(0,10000,0,13), Text=plr_instance.Name,
            Position=UDim2.new(0.5,0,0,-17),
        }, obj)
        local main_distance = esp.create_obj("TextLabel", {
            Parent=main_holder, TextStrokeTransparency=0, BorderSizePixel=0,
            TextSize=ESP_FONT_SIZE, FontFace=ESP_FONT_FACE or ESP_FONT_FALLBACK, TextColor3=Color3.new(1,1,1),
            BackgroundTransparency=1, AnchorPoint=Vector2.new(0.5,0),
            Size=UDim2.new(0,10000,0,13), Text="0m",
            Position=UDim2.new(0.5,0,1,1),
        }, obj)
        local main_weapon = esp.create_obj("TextLabel", {
            Parent=main_holder, TextStrokeTransparency=0, BorderSizePixel=0,
            TextSize=ESP_FONT_SIZE, FontFace=ESP_FONT_FACE or ESP_FONT_FALLBACK, TextColor3=Color3.new(1,1,1),
            BackgroundTransparency=1, AnchorPoint=Vector2.new(0.5,0),
            Size=UDim2.new(0,10000,0,13), Text="",
            Position=UDim2.new(0.5,0,1,14),
        }, obj)
        local health_bar_holder = esp.create_obj("Frame", {
            Parent=main_holder, BackgroundColor3=Color3.new(0,0,0),
            Size=UDim2.new(0, math.clamp(esp_table.settings.enemy.health_bar_thickness or 3, 1, 3), 1, 0), Position=UDim2.new(0, -(math.clamp(esp_table.settings.enemy.health_bar_thickness or 3, 1, 3) + 4), 0, 0), BorderSizePixel=0,
        }, obj)
        esp.create_obj("UIStroke", {
            Parent=health_bar_holder, ApplyStrokeMode=Enum.ApplyStrokeMode.Border,
            LineJoinMode=Enum.LineJoinMode.Miter, Color=Color3.new(),
        }, obj)
        local main_health_bar = esp.create_obj("Frame", {
            Parent=health_bar_holder, ZIndex=2, BorderSizePixel=0,
            BackgroundColor3=Color3.new(0,0,0), Size=UDim2.new(1,0,0,0),
        }, obj)
        local main_health_text = esp.create_obj("TextLabel", {
            Parent=main_health_bar, TextStrokeTransparency=0, BorderSizePixel=0,
            TextSize=ESP_FONT_SIZE, TextXAlignment=Enum.TextXAlignment.Right, FontFace=ESP_FONT_FACE or ESP_FONT_FALLBACK,
            TextColor3=Color3.new(1,1,1), BackgroundTransparency=1,
            AnchorPoint=Vector2.new(1,0), Size=UDim2.new(50,0,0,6),
            Text="100", Position=UDim2.new(-2,0,1,0),
        }, obj)
        local health_bar_thing = esp.create_obj("Frame", {
            Parent=health_bar_holder, BorderSizePixel=0, BackgroundColor3=Color3.new(1,1,1),
            AnchorPoint=Vector2.new(0,1), Size=UDim2.new(1,0,1,0), Position=UDim2.new(0,0,1,0),
        }, obj)
        local main_health_bar_color = esp.create_obj("UIGradient", {
            Parent=health_bar_thing, Rotation=90,
            Color=ColorSequence.new{
                ColorSequenceKeypoint.new(0, Color3.new(1,1,1)),
                ColorSequenceKeypoint.new(1, Color3.new(1,1,1)),
            },
        }, obj)
        local flag_holder = esp.create_obj("Frame", {
            Parent=main_holder, BorderSizePixel=0,
            Size=UDim2.new(1,0,1,0), Position=UDim2.new(1,3,0,-4),
            BackgroundTransparency=1,
        }, obj)
        esp.create_obj("UIListLayout", {
            Parent=flag_holder, SortOrder=Enum.SortOrder.LayoutOrder,
        }, obj)

        for i, v in ipairs(registered_flags) do
            table.insert(obj, esp.create_obj("TextLabel", {
                Parent=flag_holder, TextStrokeTransparency=0, BorderSizePixel=0,
                TextSize=ESP_FLAGS_FONT_SIZE, TextXAlignment=Enum.TextXAlignment.Left, FontFace=ESP_FLAGS_FONT_FACE or Font.fromEnum(Enum.Font.Code),
                TextColor3=Color3.fromRGB(255,255,255), BackgroundTransparency=1,
                Size=UDim2.new(1,0,0,10), Text=v[1], Position=UDim2.new(0,0,0,-1),
            }, flags_table))
        end

        		-- body status labels
		local body_status_holder = esp.create_obj("Frame", {
			Parent = main_holder, BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, 0),
			Position = UDim2.new(1, 3, 0, 0),
			BackgroundTransparency = 1,
			AutomaticSize = Enum.AutomaticSize.Y,
		}, obj)

		esp.create_obj("UIListLayout", {
			Parent = body_status_holder,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 1)
		}, obj)

		local BODY_FLAGS = {
			{ attr = "IFake",      label = "FAKE",      color = Color3.fromRGB(255, 100, 100) },
			{ attr = "IBleed",     label = "BLEED",     color = Color3.fromRGB(255, 50,  50)  },
			{ attr = "IConscious", label = "KO",        color = Color3.fromRGB(100, 100, 255) },
			{ attr = "IPain",      label = "PAIN",      color = Color3.fromRGB(255, 200, 50)  },
			{ attr = "IPulse",     label = "NO PULSE",  color = Color3.fromRGB(255, 0,   0)   },
			{ attr = "IShock",     label = "SHOCK",     color = Color3.fromRGB(200, 100, 255) },
			{ attr = "IAlarm",     label = "ALARM",     color = Color3.fromRGB(255, 50,  200) },
		}

		local body_flag_labels = {}
		for i, flagDef in ipairs(BODY_FLAGS) do
			local lbl = esp.create_obj("TextLabel", {
				Parent = body_status_holder,
				TextStrokeTransparency = 0,
				TextStrokeColor3 = Color3.new(0, 0, 0),
				BorderSizePixel = 0,
				TextXAlignment = Enum.TextXAlignment.Left,
				FontFace = ESP_FLAGS_FONT_FACE or Font.fromEnum(Enum.Font.Code),
				TextSize = ESP_FLAGS_FONT_SIZE,
				TextColor3 = flagDef.color,
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 10),
				Text = flagDef.label,
				Visible = false,
				LayoutOrder = i,
			}, obj)
			body_flag_labels[flagDef.attr] = { label = lbl, def = flagDef }
		end

        local main_wireframe = esp.create_obj("WireframeHandleAdornment", {
            Parent=esp_container, Color3=Color3.new(1,1,1), Transparency=0,
            AlwaysOnTop=true, CFrame=CFrame.new(), Scale=Vector3.one,
            Thickness=1, AdornCullingMode=Enum.AdornCullingMode.Automatic,
        }, obj)

        local settings      = esp_table.settings.enemy
        local main_settings = settings.main_settings

        local team_check    = main_settings.team_check
        local dead_check    = main_settings.dead_check
        local dist_check    = main_settings.dist_check
        local skeleton_rate = main_settings.skeleton_rate <= 0 and 1e-10 or main_settings.skeleton_rate
        local max_distance  = main_settings.max_distance
        local update_skeleton = settings.skeleton
        local weapon_enabled  = settings.weapon
        local box_rotation    = settings.box_rotation
        local gradient_rotate = main_settings.gradient_rotate or 0
        local gradient_spin   = main_settings.gradient_spin
        local gradient_speed  = main_settings.gradient_speed or 0
        local holder_spin     = main_settings.holder_spin
        local holder_speed    = main_settings.holder_speed

        local get_character = esp_table.get_character
        local get_root      = esp_table.get_root
        local get_humanoid  = esp_table.get_humanoid
        local get_health    = esp_table.get_health
        local get_team      = esp_table.get_team
        local get_gun       = esp_table.get_gun

        local setvis_cache  = false
        local skeleton_tick = 0

        function plr:forceupdate()
            team_check    = main_settings.team_check
            dead_check    = main_settings.dead_check
            dist_check    = main_settings.dist_check
            skeleton_rate = main_settings.skeleton_rate <= 0 and 1e-10 or main_settings.skeleton_rate
            max_distance  = main_settings.max_distance
            update_skeleton = settings.skeleton
            weapon_enabled  = settings.weapon
            box_rotation    = settings.box_rotation
            gradient_rotate = main_settings.gradient_rotate or 0
            gradient_spin   = main_settings.gradient_spin
            gradient_speed  = main_settings.gradient_speed or 0
            holder_spin     = main_settings.holder_spin
            holder_speed    = main_settings.holder_speed

            main_box.Enabled          = settings.box
            main_box_outline_1.Enabled = settings.box
            main_box_outline_2.Enabled = settings.box
            main_box.Transparency          = settings.box_color[3]
            main_box_outline_1.Transparency = settings.box_color[3]
            main_box_outline_2.Transparency = settings.box_color[3]
            main_box_color.Rotation = (main_settings.gradient_rotate_enabled and (main_settings.gradient_rotate or 0) or 0)
            main_box_color.Color = ColorSequence.new{
                ColorSequenceKeypoint.new(0, settings.box_color[1]),
                ColorSequenceKeypoint.new(1, settings.box_color[2]),
            }
            box_fill.Visible = settings.box and settings.box_fill
            box_fill.BackgroundColor3 = settings.box_fill_color[1]
            box_fill.BackgroundTransparency = 0
            box_fill_gradient.Color = ColorSequence.new{
                ColorSequenceKeypoint.new(0, settings.box_fill_color[1]),
                ColorSequenceKeypoint.new(1, settings.box_fill_color[2]),
            }
            box_fill_gradient.Transparency = NumberSequence.new(
                settings.box_fill_color[3] or 0.72,
                settings.box_fill_color[4] or 0.82
            )
            box_fill_gradient.Rotation = (main_settings.gradient_rotate_enabled and (main_settings.gradient_rotate or 0) or 0)
            box_glow.Visible = settings.box and settings.box_glow
            box_glow.ImageColor3 = settings.box_glow_color[1]
            box_glow.ImageTransparency = settings.box_glow_color[3] or 0.25
            box_glow_gradient.Color = ColorSequence.new{
                ColorSequenceKeypoint.new(0, settings.box_glow_color[1]),
                ColorSequenceKeypoint.new(1, settings.box_glow_color[2]),
            }
            box_glow_gradient.Rotation = (main_settings.gradient_rotate_enabled and (main_settings.gradient_rotate or 0) or 0)
            local hpThickness = math.clamp(settings.health_bar_thickness or 3, 1, 3)
            health_bar_holder.Size = UDim2.new(0, hpThickness, 1, 0)
            health_bar_holder.Position = UDim2.new(0, -(hpThickness + 4), 0, 0)
            health_bar_holder.Visible   = settings.health_bar
            main_health_bar_color.Color = ColorSequence.new{
                ColorSequenceKeypoint.new(0, settings.health_bar_color[1]),
                ColorSequenceKeypoint.new(1, settings.health_bar_color[2]),
            }
            main_health_text.Visible          = settings.health_text
            main_health_text.FontFace         = ESP_FONT_FACE or ESP_FONT_FALLBACK
            main_health_text.TextSize         = ESP_FONT_SIZE
            main_health_text.TextColor3       = settings.health_text_color[1]
            main_health_text.TextTransparency = settings.health_text_color[2]
            main_name.Visible          = settings.name
            main_name.TextColor3       = settings.name_color[1]
            main_name.TextTransparency = settings.name_color[2]
            main_distance.Visible          = settings.distance
            main_distance.FontFace         = ESP_FONT_FACE or ESP_FONT_FALLBACK
            main_distance.TextSize         = ESP_FONT_SIZE
            main_distance.TextColor3       = settings.distance_color[1]
            main_distance.TextTransparency = settings.distance_color[2]
            main_weapon.Visible          = settings.weapon
            main_weapon.FontFace         = ESP_FONT_FACE or ESP_FONT_FALLBACK
            main_weapon.TextSize         = ESP_FONT_SIZE
            main_weapon.TextColor3       = settings.weapon_color[1]
            main_weapon.TextTransparency = settings.weapon_color[2]
            main_wireframe.Visible      = settings.skeleton
            main_wireframe.Color3       = settings.skeleton_color[1]
            main_wireframe.Transparency = settings.skeleton_color[2]
            flag_holder.Visible = settings.flags
            for _, flag in ipairs(flags_table) do
                flag.TextColor3       = settings.flags_color[1]
                flag.TextTransparency = settings.flags_color[2]
                flag.FontFace = ESP_FLAGS_FONT_FACE or ESP_FONT_FALLBACK
                flag.TextSize = ESP_FLAGS_FONT_SIZE
                flag.Size = UDim2.new(1, 0, 0, ESP_FLAGS_FONT_SIZE + 3)
            end
            for part, cham in pairs(chams_table) do
                cham.cham.Adornee = setvis_cache and settings.chams and part or nil
                local c = settings.chams_color[1]
                local g = settings.chams_glow_factor
                cham.cham.Color3 = Color3.new(c.R*g, c.G*g, c.B*g)
            end
        end

        local function destroy_cham_object(part)
            if not chams_table[part] then return end
            chams_table[part].connection:Disconnect()
            chams_table[part].cham:Destroy()
            chams_table[part] = nil
        end

        local function create_cham_object(part)
            if not (_IsA(part,"BasePart") and isBodyPart(part.Name)) then return end
            if chams_table[part] then destroy_cham_object(part) end
            local c = settings.chams_color[1]
            local g = settings.chams_glow_factor
            local cham = esp.create_obj("BoxHandleAdornment", {
                Parent=esp_container, Size=part.Size*0.95,
                Adornee=setvis_cache and settings.chams and part or nil,
                Color3=Color3.new(c.R*g, c.G*g, c.B*g),
                Transparency=-1, Shading=Enum.AdornShading.XRayShaded,
                ZIndex=-1, AlwaysOnTop=false,
            }, obj)
            chams_table[part] = {
                cham=cham,
                connection=part:GetPropertyChangedSignal("Size"):Connect(function()
                    if not (cham and part) then return end
                    cham.Size = part.Size*0.95
                end)
            }
        end

        function plr:togglevis(bool)
            if setvis_cache == bool then return end
            setvis_cache = bool
            main_holder.Visible = bool
            for part, cham in pairs(chams_table) do
                cham.cham.Adornee = bool and settings.chams and part or nil
            end
        end

        local function character_added(char)
            for _, part in ipairs(char:GetChildren()) do create_cham_object(part) end
            plr.connections["cc_add"] = char.ChildAdded:Connect(create_cham_object)
            plr.connections["cc_rem"] = char.ChildRemoved:Connect(destroy_cham_object)
        end
        local function character_removing()
            if plr.connections["cc_add"] then plr.connections["cc_add"]:Disconnect() end
            if plr.connections["cc_rem"] then plr.connections["cc_rem"]:Disconnect() end
            for part in pairs(chams_table) do destroy_cham_object(part) end
        end

        if plr_instance.Character then character_added(plr_instance.Character) end
        plr.connections["char_add"] = plr_instance.CharacterAdded:Connect(character_added)
        plr.connections["char_rem"] = plr_instance.CharacterRemoving:Connect(character_removing)

        plr.connections["render"] = game:GetService("RunService").RenderStepped:Connect(function(delta)
            skeleton_tick += delta
            if skeleton_tick > skeleton_rate then main_wireframe:Clear() end

            if not settings.enabled then plr:togglevis(false) return end

            local character = get_character(plr_instance)
            if not character then plr:togglevis(false) return end

            local root     = get_root(plr_instance, character)
            local humanoid = get_humanoid(plr_instance, character)
            if not root then plr:togglevis(false) return end

            local humanoid_health, humanoid_max_health
            if humanoid then
                humanoid_health, humanoid_max_health = get_health(plr_instance, character, humanoid)
            end

            local _cam = getCamera()
            if not _cam then plr:togglevis(false) return end
            local _inset = getGuiInset()

            local humanoid_distance = (_cam.CFrame.Position - root.Position).Magnitude

            if team_check and get_team(plr_instance, character, humanoid) then plr:togglevis(false) return end
            if dead_check and humanoid_health and humanoid_health <= 0          then plr:togglevis(false) return end
            if dist_check and humanoid_distance > max_distance                   then plr:togglevis(false) return end

            local _, onScreen = _cam:WorldToViewportPoint(root.Position)
            if not onScreen then plr:togglevis(false) return end

            local cache, count = {}, 0
            for _, part in ipairs(character:GetChildren()) do
                if _IsA(part,"BasePart") and isBodyPart(part.Name) then
                    cache[part.Name] = { part.CFrame, part.Size }
                    count += 1
                end
            end
            if count <= 0 then plr:togglevis(false) return end

            local boundsCFrame, boundsSize = getBoundingBox(cache)
            local corners = calculateCorners(boundsCFrame, boundsSize)
            plr:togglevis(true)

            local pos  = corners.topLeft
            local size = corners.bottomRight - corners.topLeft
            main_holder.Position = UDim2.fromOffset(pos.X - _inset.X, pos.Y - _inset.Y)
            main_holder.Size     = UDim2.fromOffset(size.X, size.Y)
            main_holder.Rotation = holder_spin and tick() * holder_speed % 360 or 0
            -- Gradient rotate sets a static angle; Gradient spin adds animation independently.
            local baseGradientAngle = main_settings.gradient_rotate_enabled and (main_settings.gradient_rotate or 0) or 0
            local spinOffset = main_settings.gradient_spin and ((tick() * (main_settings.gradient_speed or 0)) % 360) or 0
            local gradientAngle = (baseGradientAngle + spinOffset) % 360
            main_box_color.Rotation = gradientAngle
            box_fill_gradient.Rotation = gradientAngle
            box_glow_gradient.Rotation = gradientAngle

            main_distance.Text = mathround(humanoid_distance) .. "m"

            if weapon_enabled then
                local gun = get_gun(plr_instance, character, humanoid)
                if gun then
                    main_weapon.Text     = gun
                    main_weapon.Position = main_distance.Visible
                        and UDim2.new(0.5,0,1,14) or UDim2.new(0.5,0,1,1)
                    main_weapon.Visible  = true
                else
                    main_weapon.Visible = false
                end
            end

            main_health_text.Text = humanoid_health and tostring(mathfloor(humanoid_health)) or "???"
            main_health_bar.Size  = UDim2.fromScale(1,
                humanoid_health and (1 - humanoid_health / humanoid_max_health) or 1)

            for i, v in ipairs(registered_flags) do
                local show_flag, flag_text = v[2](plr_instance, character, humanoid)
                local flag = flags_table[i]
                if not show_flag then flag.Visible = false; continue end
                flag.Visible = true
                if flag_text then flag.Text = flag_text end
            end

			do
				local selected_flags = settings.body_flags or {}
				local any_visible = false

				
				local flag_count = 0
				for _, v in ipairs(registered_flags) do
					local show = v[2](plr_instance, character, humanoid)
					if show then flag_count += 1 end
				end
				body_status_holder.Position = UDim2.new(1, 3, 0, flag_count * (ESP_FLAGS_FONT_SIZE + 4))

				for attr, entry in pairs(body_flag_labels) do
                    entry.label.FontFace = ESP_FLAGS_FONT_FACE or ESP_FONT_FALLBACK
                    entry.label.TextSize = ESP_FLAGS_FONT_SIZE
                    entry.label.Size = UDim2.new(1, 0, 0, ESP_FLAGS_FONT_SIZE + 3)
					-- проверяем включён ли этот флаг в dropdown
					local is_selected = false
					for _, sel in ipairs(selected_flags) do
						if sel == attr then is_selected = true break end
					end

					if not is_selected or not settings.flags then
						entry.label.Visible = false
						continue
					end

					local val = character:GetAttribute(attr)

					local show = false
					if attr == "IFake" then
						show = val == true
					elseif attr == "IBleed" then
						show = type(val) == "number" and val > 0
						if show then entry.label.Text = "BLEED " .. math.floor(val) end
					elseif attr == "IConscious" then
						show = val == false
					elseif attr == "IPain" then
						show = type(val) == "number" and val > 0
						if show then entry.label.Text = "PAIN " .. math.floor(val) end
					elseif attr == "IPulse" then
						show = (type(val) == "number" and val <= 0) or val == false
					elseif attr == "IShock" then
						show = type(val) == "number" and val > 0
						if show then entry.label.Text = "SHOCK " .. math.floor(val) end
					elseif attr == "IAlarm" then
						show = val == true
					end

					entry.label.Visible = show
					if show then any_visible = true end
				end

				body_status_holder.Visible = any_visible
			end

            if update_skeleton and skeleton_tick > skeleton_rate then
                skeleton_tick = skeleton_tick % skeleton_rate
                local root_pos = root.CFrame
                main_wireframe.Adornee = root
                local points, counter = {}, 0
                for part_name, info in pairs(cache) do
                    local parent_part = skeleton_order[part_name]
                    local parent_info = parent_part and cache[parent_part]
                    if not parent_info then continue end
                    points[counter+1] = _VectorToObjectSpace(root_pos, info[1].Position - root_pos.Position)
                    points[counter+2] = _VectorToObjectSpace(root_pos, parent_info[1].Position - root_pos.Position)
                    counter += 2
                end
                main_wireframe:AddLines(points)
            end
        end)

        plr:forceupdate()
    end
    

    destroy_esp = function(player)
        if not loaded_plrs[player] then return end
        for _, v in pairs(loaded_plrs[player].connections) do pcall(function() v:Disconnect() end) end
        for _, v in pairs(loaded_plrs[player].obj)         do pcall(function() v:Destroy()    end) end
        loaded_plrs[player] = nil
    end

    esp_table.destroy_all = function()
        for player in pairs(loaded_plrs) do
            destroy_esp(player)
        end
        esp_table.__loaded = false
    end

    esp_table.load = function()
        if esp_table.__loaded then return end
        esp_table.__loaded = true
        for _, player in ipairs(esp_plrs:GetPlayers()) do
            if player ~= esp_lplr then task.spawn(pcall, create_esp, player) end
        end
        esp_table.__player_added = esp_plrs.PlayerAdded:Connect(create_esp)
        esp_table.__player_removing = esp_plrs.PlayerRemoving:Connect(destroy_esp)
    end

    esp_table.icaca = function()
        for _, v in pairs(loaded_plrs) do
            if type(v) == "table" and type(v.forceupdate) == "function" then
                task.spawn(function()
                    if type(v.forceupdate) == "function" then pcall(v.forceupdate, v) end
                end)
            end
        end
    end

    
    

    esp_table.register_flag = function(flag, func)
        local rf = esp_table.registered_flags
        rf[#rf+1] = { flag, func }
    end
end


------------------------------------------------------------
-- ARROWS
------------------------------------------------------------
local arrow_settings = {
    enabled            = false,
    color              = Color3.new(1,1,1),
    outline_color      = Color3.new(0,0,0),
    show_distance      = true,
    size               = 12,
    distance_from_edge = 120,
    team_check         = false,
}
esp_table.arrow_settings = arrow_settings

local arrow_pool    = {}
local arrow_Players = game:GetService("Players")
local arrow_lplr    = arrow_Players.LocalPlayer

local function createArrow()
    local gui = Instance.new("ScreenGui")
    gui.Name           = "ESP_Arrow"
    gui.IgnoreGuiInset = true
    gui.ResetOnSpawn   = false
    gui.DisplayOrder   = 998
    gui.Parent         = game:GetService("CoreGui")

    local frame = Instance.new("Frame")
    frame.BackgroundTransparency = 1
    frame.Size        = UDim2.fromOffset(36, 36)
    frame.AnchorPoint = Vector2.new(0.5, 0.5)
    frame.BorderSizePixel = 0
    frame.Visible     = false
    frame.Parent      = gui

    local triangle = Instance.new("ImageLabel")
    triangle.BackgroundTransparency = 1
    triangle.Size        = UDim2.new(1,0,1,0)
    triangle.Image       = "rbxassetid://4666593606"
    triangle.ImageColor3 = Color3.new(1,1,1)
    triangle.AnchorPoint = Vector2.new(0.5,0.5)
    triangle.Position    = UDim2.fromScale(0.5,0.5)
    triangle.Parent      = frame

    local outline = Instance.new("ImageLabel")
    outline.BackgroundTransparency = 1
    outline.Size        = UDim2.new(1,4,1,4)
    outline.Image       = "rbxassetid://4666593606"
    outline.ImageColor3 = Color3.new(0,0,0)
    outline.AnchorPoint = Vector2.new(0.5,0.5)
    outline.Position    = UDim2.fromScale(0.5,0.5)
    outline.ZIndex      = frame.ZIndex - 1
    outline.Parent      = frame

    local dist = Instance.new("TextLabel")
    dist.BackgroundTransparency  = 1
    dist.TextStrokeTransparency  = 0
    dist.TextStrokeColor3        = Color3.new(0,0,0)
    dist.BorderSizePixel         = 0
    dist.TextSize                = ESP_FONT_SIZE
    dist.FontFace                = ESP_FONT_FACE or ESP_FONT_FALLBACK
    table.insert(ESP_EDGE_LABELS, dist)
    dist.TextColor3              = Color3.new(1,1,1)
    dist.AnchorPoint             = Vector2.new(0.5,0)
    dist.Size                    = UDim2.fromOffset(80,14)
    dist.Position                = UDim2.new(0.5,0,1,2)
    dist.Text                    = ""
    dist.Parent                  = frame

    return { gui=gui, frame=frame, triangle=triangle, outline=outline, dist=dist }
end

local function getArrow(player)
    if not arrow_pool[player] then arrow_pool[player] = createArrow() end
    return arrow_pool[player]
end

local function removeArrow(player)
    if arrow_pool[player] then
        arrow_pool[player].gui:Destroy()
        arrow_pool[player] = nil
    end
end

local function updateArrows()
    -- ✅ свежая камера
    local cam = workspace.CurrentCamera
    if not cam then return end

    if not arrow_settings.enabled then
        for _, arrow in pairs(arrow_pool) do arrow.frame.Visible = false end
        return
    end

    local vp        = cam.ViewportSize
    local center    = vp / 2
    local edge_dist = arrow_settings.distance_from_edge

    for _, player in ipairs(arrow_Players:GetPlayers()) do
        if player == arrow_lplr then continue end

        local arrow     = getArrow(player)
        local character = esp_table.get_character(player)
        if not character then arrow.frame.Visible = false; continue end

        local root = esp_table.get_root(player, character)
        if not root then arrow.frame.Visible = false; continue end

        if arrow_settings.team_check then
            if arrow_lplr.Team and player.Team and arrow_lplr.Team == player.Team then
                arrow.frame.Visible = false; continue
            end
        end

        local rootPos             = root.Position
        local screenPos, onScreen = cam:WorldToViewportPoint(rootPos)

        if onScreen and screenPos.Z > 0 then arrow.frame.Visible = false; continue end

        arrow.frame.Visible = true

        local dir
        if screenPos.Z < 0 then
            dir = (Vector2.new(-screenPos.X, -screenPos.Y) - center).Unit
        else
            dir = (Vector2.new(screenPos.X,  screenPos.Y)  - center).Unit
        end

        local pad      = arrow_settings.size * 2
        local arrowPos = center + dir * edge_dist
        arrowPos = Vector2.new(
            math.clamp(arrowPos.X, pad, vp.X - pad),
            math.clamp(arrowPos.Y, pad, vp.Y - pad)
        )

        local sz = arrow_settings.size * 3
        arrow.frame.Position    = UDim2.fromOffset(arrowPos.X, arrowPos.Y)
        arrow.frame.Size        = UDim2.fromOffset(sz, sz)
        arrow.frame.Rotation    = math.deg(math.atan2(dir.Y, dir.X)) + 90
        arrow.triangle.ImageColor3 = arrow_settings.color
        arrow.outline.ImageColor3  = arrow_settings.outline_color

        if arrow_settings.show_distance then
            arrow.dist.Text       = math.round((cam.CFrame.Position - rootPos).Magnitude) .. "m"
            arrow.dist.TextColor3 = arrow_settings.color
            arrow.dist.Visible    = true
        else
            arrow.dist.Visible = false
        end
    end

    for player in pairs(arrow_pool) do
        if not player.Parent then removeArrow(player) end
    end
end

game:GetService("RunService").RenderStepped:Connect(updateArrows)
arrow_Players.PlayerRemoving:Connect(removeArrow)

esp_table.arrow_pool = arrow_pool

------------------------------------------------------------
-- NPC ESP
------------------------------------------------------------
local npc_loaded = {}

local function isBodyPartNpc(name)
    return name=="Head" or name:find("Torso") or name:find("Leg")
        or name:find("Arm") or name:find("Hand") or name:find("Foot")
end

local function createNpcESP(npc)
    if not npc or not npc:IsA("Model") or npc_loaded[npc] then return end

    local root     = npc:FindFirstChild("HumanoidRootPart")
    local humanoid = npc:FindFirstChildOfClass("Humanoid")
    if not root or not humanoid then return end

    npc_loaded[npc] = { obj={}, connections={} }
    local entry = npc_loaded[npc]
    local obj   = entry.obj

    local main_holder = esp.create_obj("Frame", {
        Parent=esp_container, ZIndex=2, BorderSizePixel=0,
        Size=UDim2.fromScale(0,0), Position=UDim2.fromScale(0,0),
        BackgroundTransparency=1, Visible=false,
    }, obj)
    local box_holder = esp.create_obj("Frame", {
        Parent=main_holder, ZIndex=-1, BorderSizePixel=0,
        Size=UDim2.new(1,-2,1,-2), Position=UDim2.new(0,1,0,1),
        BackgroundTransparency=1,
    }, obj)
    local box_outline_holder = esp.create_obj("Frame", {
        Parent=main_holder, ZIndex=-1, BorderSizePixel=0,
        BackgroundColor3=Color3.new(1,1,1),
        Size=UDim2.new(1,-4,1,-4), Position=UDim2.new(0,2,0,2),
        BackgroundTransparency=1,
    }, obj)
    local main_box = esp.create_obj("UIStroke", {
        Parent=box_holder, ApplyStrokeMode=Enum.ApplyStrokeMode.Border,
        LineJoinMode=Enum.LineJoinMode.Miter, Color=Color3.new(1,0.5,0),
    }, obj)
    local main_box_color = esp.create_obj("UIGradient", {
        Parent=main_box,
        Color=ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.new(1,0.5,0)),
            ColorSequenceKeypoint.new(1, Color3.new(1,0.5,0)),
        },
    }, obj)
    esp.create_obj("UIStroke", {
        Parent=main_holder, ApplyStrokeMode=Enum.ApplyStrokeMode.Border,
        LineJoinMode=Enum.LineJoinMode.Miter, Color=Color3.new(),
    }, obj)
    esp.create_obj("UIStroke", {
        Parent=box_outline_holder, ApplyStrokeMode=Enum.ApplyStrokeMode.Border,
        LineJoinMode=Enum.LineJoinMode.Miter, Color=Color3.new(),
    }, obj)

    local main_name = esp.create_obj("TextLabel", {
        Parent=main_holder, TextStrokeTransparency=0, BorderSizePixel=0,
        TextSize=ESP_FONT_SIZE, FontFace=ESP_FONT_FACE or ESP_FONT_FALLBACK, TextColor3=Color3.new(1,0.5,0),
        BackgroundTransparency=1, AnchorPoint=Vector2.new(0.5,0),
        Size=UDim2.new(0,10000,0,13), Text=npc.Name,
        Position=UDim2.new(0.5,0,0,-17),
    }, obj)
    local main_distance = esp.create_obj("TextLabel", {
        Parent=main_holder, TextStrokeTransparency=0, BorderSizePixel=0,
        TextSize=ESP_FONT_SIZE, FontFace=ESP_FONT_FACE or ESP_FONT_FALLBACK, TextColor3=Color3.new(1,0.5,0),
        BackgroundTransparency=1, AnchorPoint=Vector2.new(0.5,0),
        Size=UDim2.new(0,10000,0,13), Text="0m",
        Position=UDim2.new(0.5,0,1,1),
    }, obj)

    local health_bar_holder = esp.create_obj("Frame", {
        Parent=main_holder, BackgroundColor3=Color3.new(0,0,0),
        Size=UDim2.new(0,1,1,0), Position=UDim2.new(0,-5,0,0), BorderSizePixel=0,
    }, obj)
    esp.create_obj("UIStroke", {
        Parent=health_bar_holder, ApplyStrokeMode=Enum.ApplyStrokeMode.Border,
        LineJoinMode=Enum.LineJoinMode.Miter, Color=Color3.new(),
    }, obj)
    local main_health_bar = esp.create_obj("Frame", {
        Parent=health_bar_holder, ZIndex=2, BorderSizePixel=0,
        BackgroundColor3=Color3.new(0,0,0), Size=UDim2.new(1,0,0,0),
    }, obj)
    local health_bar_thing = esp.create_obj("Frame", {
        Parent=health_bar_holder, BorderSizePixel=0,
        BackgroundColor3=Color3.new(1,0.5,0),
        AnchorPoint=Vector2.new(0,1), Size=UDim2.new(1,0,1,0), Position=UDim2.new(0,0,1,0),
    }, obj)

    local setvis_cache = false
    local function togglevis(bool)
        if setvis_cache == bool then return end
        setvis_cache = bool
        main_holder.Visible = bool
    end

    local settings = esp_table.npc_settings

    entry.connections["render"] = game:GetService("RunService").RenderStepped:Connect(function()
        if not settings.enabled then togglevis(false) return end
        if not npc.Parent       then togglevis(false) return end

        local r = npc:FindFirstChild("HumanoidRootPart")
        local h = npc:FindFirstChildOfClass("Humanoid")
        if not r or not h then togglevis(false) return end

        -- ✅ свежая камера и inset
        local _cam   = workspace.CurrentCamera
        local _inset = game:GetService("GuiService"):GetGuiInset()

        local dist = (_cam.CFrame.Position - r.Position).Magnitude
        if settings.dist_check and dist > settings.max_distance then togglevis(false) return end
        if settings.dead_check and h.Health <= 0                 then togglevis(false) return end

        local _, onScreen = _cam:WorldToViewportPoint(r.Position)
        if not onScreen then togglevis(false) return end

        local cache, count = {}, 0
        for _, part in ipairs(npc:GetChildren()) do
            if part:IsA("BasePart") and isBodyPartNpc(part.Name) then
                cache[part.Name] = { part.CFrame, part.Size }
                count += 1
            end
        end
        if count <= 0 then togglevis(false) return end

        -- переиспользуем глобальный calculateCorners (он тоже использует getCamera())
        local function localCorners(cf, sz)
            local cam = workspace.CurrentCamera
            if not cam then return { topLeft=Vector2.zero, topRight=Vector2.zero,
                bottomLeft=Vector2.zero, bottomRight=Vector2.zero } end
            local verts = {
                Vector3.new(-1,-1,-1), Vector3.new(-1,1,-1), Vector3.new(-1,1,1), Vector3.new(-1,-1,1),
                Vector3.new(1,-1,-1),  Vector3.new(1,1,-1),  Vector3.new(1,1,1),  Vector3.new(1,-1,1),
            }
            local pts = {}
            for i, v in ipairs(verts) do
                local s = cam:WorldToViewportPoint((cf + sz*0.5*v).Position)
                pts[i] = Vector2.new(s.X, s.Y)
            end
            local mn = Vector2.zero.Min(cam.ViewportSize, table.unpack(pts))
            local mx = Vector2.zero.Max(Vector2.zero,     table.unpack(pts))
            return { topLeft=Vector2.new(mn.X,mn.Y), topRight=Vector2.new(mx.X,mn.Y),
                     bottomLeft=Vector2.new(mn.X,mx.Y), bottomRight=Vector2.new(mx.X,mx.Y) }
        end

        local bb_cf, bb_sz = (function()
            local mn, mx
            for _, p in pairs(cache) do
                local cf2, sz2 = p[1], p[2]
                mn = Vector3.zero.Min(mn or cf2.Position, (cf2 - sz2*0.5).Position)
                mx = Vector3.zero.Max(mx or cf2.Position, (cf2 + sz2*0.5).Position)
            end
            if not mn or not mx then return CFrame.new(), Vector3.new() end
            local c = (mn+mx)*0.5
            return CFrame.new(c, Vector3.new(c.X,c.Y,mx.Z)), mx-mn
        end)()

        local corners = localCorners(bb_cf, bb_sz)
        togglevis(true)

        local pos  = corners.topLeft
        local size = corners.bottomRight - corners.topLeft
        main_holder.Position = UDim2.fromOffset(pos.X - _inset.X, pos.Y - _inset.Y)
        main_holder.Size     = UDim2.fromOffset(size.X, size.Y)

        main_box.Color = settings.box_color
        main_box_color.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, settings.box_color),
            ColorSequenceKeypoint.new(1, settings.box_color2),
        }
        main_box.Enabled = settings.box

        main_name.Visible    = settings.name
        main_name.Text       = npc.Name
        main_name.TextColor3 = settings.name_color

        main_distance.Visible    = settings.distance
        main_distance.FontFace   = ESP_FONT_FACE or ESP_FONT_FALLBACK
        main_distance.TextSize   = ESP_FONT_SIZE
        main_distance.Text       = math.round(dist) .. "m"
        main_distance.TextColor3 = settings.dist_color

        health_bar_holder.Visible = settings.health_bar
        if settings.health_bar then
            local ratio = math.clamp(h.Health / math.max(h.MaxHealth,1), 0, 1)
            main_health_bar.Size            = UDim2.fromScale(1, 1 - ratio)
            health_bar_thing.Size           = UDim2.new(1,0, ratio, 0)
            health_bar_thing.BackgroundColor3 = settings.hp_color
        end
    end)
end

local function destroyNpcESP(npc)
    if not npc_loaded[npc] then return end
    for _, v in pairs(npc_loaded[npc].connections) do pcall(function() v:Disconnect() end) end
    for _, v in pairs(npc_loaded[npc].obj)         do pcall(function() v:Destroy()    end) end
    npc_loaded[npc] = nil
end

esp_table.npc_settings = {
    enabled      = false,
    box          = true,
    name         = true,
    distance     = true,
    health_bar   = true,
    dead_check   = true,
    dist_check   = true,
    max_distance = 1500,
    box_color    = Color3.fromRGB(255,128,0),
    box_color2   = Color3.fromRGB(255,200,0),
    name_color   = Color3.fromRGB(255,128,0),
    dist_color   = Color3.fromRGB(255,200,200),
    hp_color     = Color3.fromRGB(255,128,0),
}

esp_table.npc_load = function()
    if esp_table.__npc_loaded then return end
    esp_table.__npc_loaded = true

    local function tryGetCitizens()
        local citizens = workspace:FindFirstChild("ICitizens")
        if not citizens then
            workspace.ChildAdded:Connect(function(child)
                if child.Name ~= "ICitizens" then return end
                for _, npc in ipairs(child:GetChildren()) do task.spawn(createNpcESP, npc) end
                child.ChildAdded:Connect(function(npc) task.spawn(createNpcESP, npc) end)
                child.ChildRemoved:Connect(destroyNpcESP)
            end)
            return
        end
        for _, npc in ipairs(citizens:GetChildren()) do task.spawn(createNpcESP, npc) end
        citizens.ChildAdded:Connect(function(npc) task.spawn(createNpcESP, npc) end)
        citizens.ChildRemoved:Connect(destroyNpcESP)
    end

    tryGetCitizens()
end

esp_table.npc_load()

------------------------------------------------------------
-- GetService
------------------------------------------------------------

if getgenv then
	getgenv().MS_CLEANUP = function()
		for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
		if ThirdPerson.Enabled then pcall(function() ThirdPerson:SetEnabled(false) end) end
		if FovChanger.Enabled then pcall(function() FovChanger:SetEnabled(false) end) end
		if Spectate.Target then pcall(function() Spectate:Stop() end) end
		-- name spoof restore
		pcall(function()
			if getgenv().MS_NAMESPOOF_CLEANUP then getgenv().MS_NAMESPOOF_CLEANUP() end
		end)
		if esp_table then
			if esp_table.__player_added then pcall(function() esp_table.__player_added:Disconnect() end); esp_table.__player_added = nil end
			if esp_table.__player_removing then pcall(function() esp_table.__player_removing:Disconnect() end); esp_table.__player_removing = nil end
			if esp_table.destroy_all then pcall(esp_table.destroy_all) end
		end
		pcall(function() if esp_container then esp_container:Destroy() end end)
		for _, root in ipairs(getContainers()) do
			for _, g in ipairs(root:GetChildren()) do
				if g:IsA("ScreenGui") and not guisBefore[g] then g:Destroy() end
			end
		end
	end
end

local UIS = game:GetService("UserInputService")
local CAS = game:GetService("ContextActionService")

local Freecam = {
	Enabled = false,
	Armed = false,
	Speed = 1,
	FastMult = 3,
	Sens = 0.25,
	Smooth = true,
    LockMouse = true,
	Yaw = 0,
	Pitch = 0,
	Pos = Vector3.zero,
	Saved = nil,
}

local MOVE_KEYS = {
	Enum.KeyCode.W, Enum.KeyCode.A, Enum.KeyCode.S, Enum.KeyCode.D,
	Enum.KeyCode.Q, Enum.KeyCode.E, Enum.KeyCode.Space, Enum.KeyCode.LeftShift,
}

function Freecam:SetEnabled(v)
	if v == self.Enabled then return end
	local cam = workspace.CurrentCamera
	self.Enabled = v

	pcall(function() RunService:UnbindFromRenderStep("FreecamStep") end)
	pcall(function() CAS:UnbindAction("FreecamSink") end)

	if v then
		self.Saved = {
			Type = cam.CameraType,
			CFrame = cam.CFrame,
			Mouse = UIS.MouseBehavior,
		}
		local rx, ry = cam.CFrame:ToOrientation()
		self.Pitch, self.Yaw = math.deg(rx), math.deg(ry)
		self.Pos = cam.CFrame.Position
		self.Vel = Vector3.zero

		CAS:BindActionAtPriority("FreecamSink", function()
			return Enum.ContextActionResult.Sink
		end, false, Enum.ContextActionPriority.High.Value, unpack(MOVE_KEYS))

		cam.CameraType = Enum.CameraType.Scriptable

		RunService:BindToRenderStep("FreecamStep", Enum.RenderPriority.Camera.Value + 2, function(dt)
			local c = workspace.CurrentCamera
			c.CameraType = Enum.CameraType.Scriptable

			UIS.MouseBehavior = Enum.MouseBehavior.LockCenter
			local d = UIS:GetMouseDelta()
			self.Yaw = self.Yaw - d.X * self.Sens
			self.Pitch = math.clamp(self.Pitch - d.Y * self.Sens, -89, 89)

			local rot = CFrame.fromOrientation(math.rad(self.Pitch), math.rad(self.Yaw), 0)

			local dir = Vector3.zero
			if UIS:IsKeyDown(Enum.KeyCode.W) then dir += rot.LookVector end
			if UIS:IsKeyDown(Enum.KeyCode.S) then dir -= rot.LookVector end
			if UIS:IsKeyDown(Enum.KeyCode.D) then dir += rot.RightVector end
			if UIS:IsKeyDown(Enum.KeyCode.A) then dir -= rot.RightVector end
			if UIS:IsKeyDown(Enum.KeyCode.E) or UIS:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.yAxis end
			if UIS:IsKeyDown(Enum.KeyCode.Q) then dir -= Vector3.yAxis end

			local speed = self.Speed * 30
			if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then speed *= self.FastMult end

			local target = dir.Magnitude > 0 and dir.Unit * speed or Vector3.zero
			if self.Smooth then
				self.Vel = self.Vel:Lerp(target, math.clamp(dt * 10, 0, 1))
			else
				self.Vel = target
			end
			self.Pos += self.Vel * dt

			c.CFrame = CFrame.new(self.Pos) * rot
		end)
	else
		local s = self.Saved
		UIS.MouseBehavior = Enum.MouseBehavior.Default
		cam.CameraType = Enum.CameraType.Custom
		local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
		if hum then cam.CameraSubject = hum end
		if s then cam.CFrame = s.CFrame end
		self.Saved = nil
	end
end

local guisBefore = {}
for _, c in ipairs(getContainers()) do
	for _, g in ipairs(c:GetChildren()) do guisBefore[g] = true end
end

local conns = {}
local function bind(signal, fn)
	local c = signal:Connect(fn)
	table.insert(conns, c)
	return c
end

local function findLabel(token)
	for _, root in ipairs(getContainers()) do
		for _, g in ipairs(root:GetChildren()) do
			if g:IsA("ScreenGui") and not guisBefore[g] then
				for _, d in ipairs(g:GetDescendants()) do
					if d:IsA("TextLabel") and d.Text == token then return d end
				end
			end
		end
	end
end

local function waitLabel(token, tries)
	for _ = 1, tries do
		task.wait(0.1)
		local l = findLabel(token)
		if l then return l end
	end
end

-- Simple fixed-center FOV geometry. The same radius drives both the visible
-- FOV frame and target selection, so Circle and Box selection match the shape.
local function getFovRadiusPx(cam, angle)
    if not cam then return 0 end
    local viewportHeight = cam.ViewportSize.Y
    local fieldOfView = math.clamp(tonumber(cam.FieldOfView) or 70, 1, 179)
    local angleValue = math.clamp(tonumber(angle) or 22, 1, 179)
    local denominator = math.max(math.tan(math.rad(fieldOfView / 2)), 0.001)
    local radius = (viewportHeight / 2) * math.tan(math.rad(angleValue / 2)) / denominator
    return math.clamp(radius, 1, math.max(cam.ViewportSize.X, viewportHeight) * 2)
end

local function isPointInsideFov(cam, fov, point, center)
    local delta = point - center
    local distance = delta.Magnitude
    if not fov or not fov.Enabled then
        return true, distance
    end

    local radius = getFovRadiusPx(cam, fov.Angle)
    if fov.Shape == "Box" then
        -- A square box uses independent horizontal/vertical half-extents.
        return math.abs(delta.X) <= radius and math.abs(delta.Y) <= radius, distance
    end

    -- Circle uses radial distance, not the square's independent axis limits.
    return delta:Dot(delta) <= radius * radius, distance
end

local function createFov(name)
	local gui = Instance.new("ScreenGui")
	gui.Name = name
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 999
	gui.Parent = (gethui and gethui()) or CoreGui

	local THICKNESS = 1
	local OUTLINE_THICKNESS = 1

	local function makeRing(color, thickness, zindex)
		local frame = Instance.new("Frame")
		frame.AnchorPoint = Vector2.new(0.5, 0.5)
		frame.Position = UDim2.fromScale(0.5, 0.5)
		frame.BackgroundTransparency = 1
		frame.BorderSizePixel = 0
		frame.Visible = false
		frame.ZIndex = zindex
		frame.Parent = gui

		local stroke = Instance.new("UIStroke")
		stroke.Thickness = thickness
		stroke.Color = color
		stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		stroke.Parent = frame

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0.5, 0)
		corner.Parent = frame

		return frame, stroke, corner
	end

	local main, mainStroke, mainCorner = makeRing(Color3.new(1, 1, 1), THICKNESS, 2)
	local outer, outerStroke, outerCorner = makeRing(Color3.new(0, 0, 0), OUTLINE_THICKNESS, 1)
	local inner, innerStroke, innerCorner = makeRing(Color3.new(0, 0, 0), OUTLINE_THICKNESS, 1)

	local fov = {
		Enabled = false,
		Outline = false,
		Shape = "Circle",
		Angle = 22,
		Color = Color3.new(1, 1, 1),
		OutlineColor = Color3.new(0, 0, 0),
	}

	local function refreshVisibility()
		main.Visible = fov.Enabled
		outer.Visible = fov.Enabled and fov.Outline
		inner.Visible = fov.Enabled and fov.Outline
	end

	function fov:SetEnabled(v) self.Enabled = v refreshVisibility() end
	function fov:SetOutline(v) self.Outline = v refreshVisibility() end

	function fov:SetColor(c)
		self.Color = c
		mainStroke.Color = c
	end

	function fov:SetOutlineColor(c)
		self.OutlineColor = c
		outerStroke.Color = c
		innerStroke.Color = c
	end

	function fov:SetAngle(a) self.Angle = math.clamp(a, 1, 179) end
	function fov:SetShape(s)
		self.Shape = s
		local radius = s == "Circle" and UDim.new(0.5, 0) or UDim.new(0, 0)
		local join = s == "Circle" and Enum.LineJoinMode.Round or Enum.LineJoinMode.Miter
		for _, c in ipairs({mainCorner, outerCorner, innerCorner}) do
			c.CornerRadius = radius
		end
		for _, st in ipairs({mainStroke, outerStroke, innerStroke}) do
			st.LineJoinMode = join
		end
	end

	bind(RunService.RenderStepped, function()
		if not fov.Enabled then return end
		local cam = workspace.CurrentCamera
        if not cam then return end
        local r = getFovRadiusPx(cam, fov.Angle)
        local d = math.max(r * 2, 4)
        -- Fixed center mode: ScreenGui.IgnoreGuiInset=true, so viewport center
        -- is used directly with no additional GUI inset correction.
        local center = cam.ViewportSize / 2
        local ringPosition = UDim2.fromOffset(center.X, center.Y)
        main.Position = ringPosition
        outer.Position = ringPosition
        inner.Position = ringPosition

		main.Size = UDim2.fromOffset(d, d)
		if fov.Outline then
			local o = d + THICKNESS * 2
			local i = math.max(d - OUTLINE_THICKNESS * 2, 2)
			outer.Size = UDim2.fromOffset(o, o)
			inner.Size = UDim2.fromOffset(i, i)
		end
	end)

	return fov
end

local AimbotFov = createFov("AimbotFov")
local SilentFov = createFov("SilentFov")

local FovChanger = {
	Enabled = false,
	Value = 70,
	Smooth = true,
	Original = workspace.CurrentCamera.FieldOfView,
}

bind(RunService.RenderStepped, function(dt)
    if not FovChanger.Enabled then return end
    local cam = workspace.CurrentCamera
    if not cam then return end
    local prev = cam.FieldOfView
    if FovChanger.Smooth then
        cam.FieldOfView = prev + (FovChanger.Value - prev) * math.clamp(dt * 12, 0, 1)
    else
        cam.FieldOfView = FovChanger.Value
    end
end)

function FovChanger:SetEnabled(v)
	self.Enabled = v
	if v then
		self.Original = workspace.CurrentCamera.FieldOfView
	else
		workspace.CurrentCamera.FieldOfView = self.Original
	end
end

local ThirdPerson = {
	Enabled = false,
	Back = 8,
	Side = 0,
	Height = 1,
	Armed = false, 
	Original = nil,
}

function ThirdPerson:SetEnabled(v)
	local lp = LocalPlayer
	if v and not self.Original then
		self.Original = {
			Mode = lp.CameraMode,
			Min = lp.CameraMinZoomDistance,
			Max = lp.CameraMaxZoomDistance,
		}
	end
	self.Enabled = v

	pcall(function() RunService:UnbindFromRenderStep("ThirdPersonOffset") end)

	if v then
		RunService:BindToRenderStep("ThirdPersonOffset", Enum.RenderPriority.Camera.Value + 1, function()
			local cam = workspace.CurrentCamera
			local char = lp.Character
			if not char then return end

			lp.CameraMode = Enum.CameraMode.LockFirstPerson

			for _, p in ipairs(char:GetDescendants()) do
				if p:IsA("BasePart") then
					p.LocalTransparencyModifier = 0
				end
			end

			local cf = cam.CFrame
			local origin = cf.Position
			local offset = cf.RightVector * ThirdPerson.Side
				+ Vector3.new(0, ThirdPerson.Height, 0)
				- cf.LookVector * ThirdPerson.Back

			local params = RaycastParams.new()
			params.FilterType = Enum.RaycastFilterType.Exclude
			params.FilterDescendantsInstances = {char}
			local hit = workspace:Raycast(origin, offset, params)

			local pos = origin + offset
			if hit then
				pos = hit.Position - offset.Unit * 0.3
			end

			cam.CFrame = CFrame.new(pos) * (cf - cf.Position)
		end)
	elseif self.Original then
		lp.CameraMode = self.Original.Mode
		lp.CameraMinZoomDistance = self.Original.Min
		lp.CameraMaxZoomDistance = self.Original.Max
		self.Original = nil
	end
end

local PlayerData = {Priority = {}, Whitelist = {}}
function PlayerData:Has(tag, plr) return self[tag][plr.UserId] == true end
function PlayerData:Toggle(tag, plr)
	self[tag][plr.UserId] = not self[tag][plr.UserId] or nil
	return self[tag][plr.UserId] == true
end

local Spectate = {Target = nil}
function Spectate:Stop()
	self.Target = nil
	local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
	if hum then workspace.CurrentCamera.CameraSubject = hum end
end

bind(RunService.RenderStepped, function()
	local t = Spectate.Target
	if not t then return end
	if not t.Parent then Spectate:Stop() return end
	local hum = t.Character and t.Character:FindFirstChildOfClass("Humanoid")
	if hum and workspace.CurrentCamera.CameraSubject ~= hum then
		workspace.CurrentCamera.CameraSubject = hum
	end
end)

if getgenv then
	getgenv().MS_CLEANUP = function()
		for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
		if ThirdPerson.Enabled then pcall(function() ThirdPerson:SetEnabled(false) end) end
		if FovChanger.Enabled then pcall(function() FovChanger:SetEnabled(false) end) end
		if Spectate.Target then pcall(function() Spectate:Stop() end) end
		if esp_table then
			if esp_table.__player_added then pcall(function() esp_table.__player_added:Disconnect() end); esp_table.__player_added = nil end
			if esp_table.__player_removing then pcall(function() esp_table.__player_removing:Disconnect() end); esp_table.__player_removing = nil end
			if esp_table.destroy_all then pcall(esp_table.destroy_all) end
		end
		pcall(function() if esp_container then esp_container:Destroy() end end)
		for _, root in ipairs(getContainers()) do
			for _, g in ipairs(root:GetChildren()) do
				if g:IsA("ScreenGui") and not guisBefore[g] then g:Destroy() end
			end
		end
	end
end

------------------------------------------------------------
-- UI LIB -- lua starts
------------------------------------------------------------

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/aap27781-commits/hhhh/refs/heads/main/juanitahaxx%20ui%20lib.lua"))()

local Window = Library:Window({Name = "MissSEnseHACK"})
local Watermark = Window:Watermark({Name = "MissSense"})
local KeybindList = Window:KeybindList()

local CombatPage = Window:Page({Name = "combat"})
local MiscPage = Window:Page({Name = "misc"})
local VisualsPage = Window:Page({Name = "visuals"})
local WorldPage = Window:Page({Name = "world"})
local MovementPage = Window:Page({Name = "movement"})
local PlayersPage = Window:Page({Name = "players"})
local CreditsPage = Window:Page({Name = "credits"})
local LuaPage = Window:Page({Name = "lua"})

CreditsPage:Turn("credits")

------------------------------------------------------------
-- AIMBOT CORE (uses the existing Combat controls and AimbotFov)
------------------------------------------------------------
local AimbotState = {
    Enabled = false,
    KeyActive = false,
    Target = "Head",
    Smooth = 25,
    Predict = 12,
    Type = "Camera",
    WallCheck = false,
}


-- Game-specific silent aim and client-side weapon modifications for IWBF.
local SilentAimState = {
    Enabled = false,
    KeyActive = false,
    Target = "Head",
    HitChance = 100,
    Prediction = 0,
    WallCheck = true,
    Debug = true,
    TargetLine = false,
    TargetLineMode = "Line Center", -- "Line Center" or "Line Crosshair"
    TargetLineColor = Color3.fromRGB(255, 80, 80),
    TargetLineThickness = 2,
    TargetLineOutline = true,
    TargetLineOutlineColor = Color3.fromRGB(0, 0, 0),
    TargetLineOutlineThickness = 2,
    _lastDiagAt = 0,
}
local WeaponModificationState = {
    NoRecoil = false,
    NoSpread = false,
    InstantEquip = false,
    InstantScope = false,
    NoGunSway = false,
    FastReload = false,
    InfiniteAmmo = false,
    RapidFire = false,
}
local WeaponModModules = {}
local WeaponModBackups = {
    Recoil = {}, Spread = {}, Deploy = {}, Ergonomics = {},
    FastReload = {}, RapidFire = {}, InfiniteAmmo = {},
}
local InfiniteAmmoHeldBackup = setmetatable({}, { __mode = "k" })
local WeaponModOriginalFns = { GunPoseRecoil = nil, GunSwayPreLerp = nil }
local WeaponModApplied = {}

local function getAimPart(character, requestedChoice)
    if not character then return nil end
    local choice = requestedChoice or AimbotState.Target
    if choice == "Head" then
        return character:FindFirstChild("Head")
    elseif choice == "Torso" then
        return character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso") or character:FindFirstChild("HumanoidRootPart")
    elseif choice == "Arms" then
        return character:FindFirstChild("RightHand") or character:FindFirstChild("LeftHand") or character:FindFirstChild("Right Arm") or character:FindFirstChild("Left Arm")
    elseif choice == "Legs" then
        return character:FindFirstChild("RightFoot") or character:FindFirstChild("LeftFoot") or character:FindFirstChild("Right Leg") or character:FindFirstChild("Left Leg")
    elseif choice == "Random" then
        local candidates = {}
        for _, name in ipairs({"Head", "UpperTorso", "Torso", "HumanoidRootPart", "LeftHand", "RightHand", "LeftFoot", "RightFoot"}) do
            local part = character:FindFirstChild(name)
            if part and part:IsA("BasePart") then table.insert(candidates, part) end
        end
        return #candidates > 0 and candidates[math.random(1, #candidates)] or nil
    end
    -- “Closet” is the label already present in this UI; treat it as Closest.
    local cam = workspace.CurrentCamera
    local best, bestDistance
    if cam then
        local center = cam.ViewportSize / 2
        for _, part in ipairs(character:GetChildren()) do
            if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                local pos, onScreen = cam:WorldToViewportPoint(part.Position)
                if onScreen then
                    local d = (Vector2.new(pos.X, pos.Y) - center).Magnitude
                    if not bestDistance or d < bestDistance then best, bestDistance = part, d end
                end
            end
        end
    end
    return best or character:FindFirstChild("Head") or character:FindFirstChild("HumanoidRootPart")
end

local function aimTargetVisible(cam, targetPart, character)
    if not AimbotState.WallCheck then return true end
    local origin = cam.CFrame.Position
    local direction = targetPart.Position - origin
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {LocalPlayer.Character, cam}
    params.IgnoreWater = true
    local result = workspace:Raycast(origin, direction, params)
    return result ~= nil and result.Instance ~= nil and result.Instance:IsDescendantOf(character)
end

local function findAimbotTarget()
    local cam = workspace.CurrentCamera
    if not cam then return nil end
    local center = cam.ViewportSize / 2
    local bestPart, bestDistance

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local character = player.Character
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")
            if character and humanoid and humanoid.Health > 0 then
                local part = getAimPart(character)
                if part and part:IsA("BasePart") then
                    local screen, onScreen = cam:WorldToViewportPoint(part.Position)
                    if onScreen then
                        local insideFov, distance = isPointInsideFov(
                            cam, AimbotFov, Vector2.new(screen.X, screen.Y), center
                        )
                        if insideFov and (not bestDistance or distance < bestDistance)
                            and aimTargetVisible(cam, part, character) then
                            bestPart, bestDistance = part, distance
                        end
                    end
                end
            end
        end
    end
    return bestPart
end


local function findSilentAimTarget()
    local cam = workspace.CurrentCamera
    if not cam then return nil end
    local center = cam.ViewportSize / 2
    local bestPart, bestDistance

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local character = player.Character
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")
            if character and humanoid and humanoid.Health > 0 then
                local part = getAimPart(character, SilentAimState.Target)
                if part and part:IsA("BasePart") then
                    local screen, onScreen = cam:WorldToViewportPoint(part.Position)
                    if onScreen then
                        local insideFov, distance = isPointInsideFov(
                            cam, SilentFov, Vector2.new(screen.X, screen.Y), center
                        )
                        local visible = true
                        if SilentAimState.WallCheck then
                            local origin = cam.CFrame.Position
                            local delta = part.Position - origin
                            local params = RaycastParams.new()
                            params.FilterType = Enum.RaycastFilterType.Exclude
                            params.FilterDescendantsInstances = {LocalPlayer.Character, cam}
                            params.IgnoreWater = true
                            local hit = workspace:Raycast(origin, delta, params)
                            visible = hit ~= nil and hit.Instance ~= nil and hit.Instance:IsDescendantOf(character)
                        end
                        if insideFov and visible and (not bestDistance or distance < bestDistance) then
                            bestPart, bestDistance = part, distance
                        end
                    end
                end
            end
        end
    end
    return bestPart
end

-- Shared custom-crosshair screen position for Target Line origin modes.
-- Coordinates are viewport pixels because MS_Crosshair uses IgnoreGuiInset=true.
local MS_CrosshairScreenPosition = nil
local MS_CrosshairScreenPositionVisible = false

-- Silent Aim target line. Main line + separately configurable outline.
local SilentAimTargetLineDrawing = nil
local SilentAimTargetLineOutlineDrawing = nil
local SilentAimTargetLineGui = nil
local SilentAimTargetLineFrame = nil
local SilentAimTargetLineOutlineFrame = nil
local function hideSilentAimTargetLine()
    for _, object in ipairs({SilentAimTargetLineDrawing, SilentAimTargetLineOutlineDrawing,
        SilentAimTargetLineFrame, SilentAimTargetLineOutlineFrame}) do
        if object then pcall(function() object.Visible = false end) end
    end
end

local function createSilentAimTargetLine()
    if SilentAimTargetLineDrawing or SilentAimTargetLineFrame then return end
    if Drawing and type(Drawing.new) == "function" then
        local outlineOk, outline = pcall(function() return Drawing.new("Line") end)
        if outlineOk and outline then
            SilentAimTargetLineOutlineDrawing = outline
            pcall(function()
                outline.Visible = false
                outline.Thickness = SilentAimState.TargetLineThickness + SilentAimState.TargetLineOutlineThickness * 2
                outline.Transparency = 1
                outline.Color = SilentAimState.TargetLineOutlineColor
            end)
        end
        local mainOk, main = pcall(function() return Drawing.new("Line") end)
        if mainOk and main then
            SilentAimTargetLineDrawing = main
            pcall(function()
                main.Visible = false
                main.Thickness = SilentAimState.TargetLineThickness
                main.Transparency = 1
                main.Color = SilentAimState.TargetLineColor
            end)
            return
        end
        if SilentAimTargetLineOutlineDrawing then
            pcall(function() SilentAimTargetLineOutlineDrawing:Remove() end)
            SilentAimTargetLineOutlineDrawing = nil
        end
    end

    -- Fallback for executors without Drawing API.
    local ok, gui = pcall(function()
        local screenGui = Instance.new("ScreenGui")
        screenGui.Name = "MissSenseSilentAimTargetLine"
        screenGui.IgnoreGuiInset = true
        screenGui.ResetOnSpawn = false
        screenGui.DisplayOrder = 9999
        local outline = Instance.new("Frame")
        outline.Name = "TargetLineOutline"
        outline.AnchorPoint = Vector2.new(0, 0.5)
        outline.Position = UDim2.fromOffset(0, 0)
        outline.Size = UDim2.fromOffset(1, SilentAimState.TargetLineThickness + SilentAimState.TargetLineOutlineThickness * 2)
        outline.BorderSizePixel = 0
        outline.BackgroundColor3 = SilentAimState.TargetLineOutlineColor
        outline.Visible = false
        outline.ZIndex = 9998
        outline.Parent = screenGui
        local frame = Instance.new("Frame")
        frame.Name = "TargetLine"
        frame.AnchorPoint = Vector2.new(0, 0.5)
        frame.Position = UDim2.fromOffset(0, 0)
        frame.Size = UDim2.fromOffset(1, SilentAimState.TargetLineThickness)
        frame.BorderSizePixel = 0
        frame.BackgroundColor3 = SilentAimState.TargetLineColor
        frame.Visible = false
        frame.ZIndex = 9999
        frame.Parent = screenGui
        local parented = pcall(function() screenGui.Parent = CoreGui end)
        if not parented then screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end
        return screenGui
    end)
    if ok and gui then
        SilentAimTargetLineGui = gui
        SilentAimTargetLineFrame = gui:FindFirstChild("TargetLine")
        SilentAimTargetLineOutlineFrame = gui:FindFirstChild("TargetLineOutline")
    end
end

createSilentAimTargetLine()
if type(getgenv) == "function" then
    pcall(function()
        local env = getgenv()
        local previousCleanup = env.MS_CLEANUP
        env.MS_CLEANUP = function(...)
            hideSilentAimTargetLine()
            if SilentAimTargetLineDrawing then
                pcall(function() SilentAimTargetLineDrawing:Remove() end)
                SilentAimTargetLineDrawing = nil
            end
            if SilentAimTargetLineOutlineDrawing then
                pcall(function() SilentAimTargetLineOutlineDrawing:Remove() end)
                SilentAimTargetLineOutlineDrawing = nil
            end
            if SilentAimTargetLineGui then
                pcall(function() SilentAimTargetLineGui:Destroy() end)
                SilentAimTargetLineGui = nil
                SilentAimTargetLineFrame = nil
                SilentAimTargetLineOutlineFrame = nil
            end
            if type(previousCleanup) == "function" then return previousCleanup(...) end
        end
    end)
end
bind(RunService.RenderStepped, function()
    if not SilentAimState.Enabled or not SilentAimState.TargetLine then
        hideSilentAimTargetLine()
        return
    end
    local cam = workspace.CurrentCamera
    if not cam then hideSilentAimTargetLine(); return end

    local ok, target = pcall(findSilentAimTarget)
    if not ok or not target or not target.Parent then
        hideSilentAimTargetLine()
        return
    end

    local targetPosition = target.Position
    local prediction = math.clamp(tonumber(SilentAimState.Prediction) or 0, 0, 100) / 100
    if prediction > 0 then targetPosition += target.AssemblyLinearVelocity * (prediction * 0.12) end
    local screen, onScreen = cam:WorldToViewportPoint(targetPosition)
    if not onScreen or screen.Z <= 0 then hideSilentAimTargetLine(); return end

    local center = cam.ViewportSize / 2
    if SilentAimState.TargetLineMode == "Line Crosshair"
        and MS_CrosshairScreenPositionVisible
        and MS_CrosshairScreenPosition then
        center = MS_CrosshairScreenPosition
    end
    local endpoint = Vector2.new(screen.X, screen.Y)
    local color = SilentAimState.TargetLineColor or Color3.fromRGB(255, 80, 80)
    local outlineColor = SilentAimState.TargetLineOutlineColor or Color3.fromRGB(0, 0, 0)
    local thickness = math.clamp(tonumber(SilentAimState.TargetLineThickness) or 2, 1, 8)
    local outlineThickness = math.clamp(tonumber(SilentAimState.TargetLineOutlineThickness) or 2, 1, 8)
    local outlineEnabled = SilentAimState.TargetLineOutline == true

    if SilentAimTargetLineDrawing then
        pcall(function()
            if SilentAimTargetLineOutlineDrawing then
                SilentAimTargetLineOutlineDrawing.From = center
                SilentAimTargetLineOutlineDrawing.To = endpoint
                SilentAimTargetLineOutlineDrawing.Color = outlineColor
                SilentAimTargetLineOutlineDrawing.Thickness = thickness + (outlineEnabled and outlineThickness * 2 or 0)
                SilentAimTargetLineOutlineDrawing.Transparency = 1
                SilentAimTargetLineOutlineDrawing.Visible = outlineEnabled
            end
            SilentAimTargetLineDrawing.From = center
            SilentAimTargetLineDrawing.To = endpoint
            SilentAimTargetLineDrawing.Color = color
            SilentAimTargetLineDrawing.Thickness = thickness
            SilentAimTargetLineDrawing.Transparency = 1
            SilentAimTargetLineDrawing.Visible = true
        end)
    elseif SilentAimTargetLineFrame then
        local delta = endpoint - center
        pcall(function()
            if SilentAimTargetLineOutlineFrame then
                SilentAimTargetLineOutlineFrame.BackgroundColor3 = outlineColor
                SilentAimTargetLineOutlineFrame.Position = UDim2.fromOffset(center.X, center.Y)
                SilentAimTargetLineOutlineFrame.Size = UDim2.fromOffset(math.max(delta.Magnitude, 1), thickness + (outlineEnabled and outlineThickness * 2 or 0))
                SilentAimTargetLineOutlineFrame.Rotation = math.deg(math.atan2(delta.Y, delta.X))
                SilentAimTargetLineOutlineFrame.Visible = outlineEnabled
            end
            SilentAimTargetLineFrame.BackgroundColor3 = color
            SilentAimTargetLineFrame.Position = UDim2.fromOffset(center.X, center.Y)
            SilentAimTargetLineFrame.Size = UDim2.fromOffset(math.max(delta.Magnitude, 1), thickness)
            SilentAimTargetLineFrame.Rotation = math.deg(math.atan2(delta.Y, delta.X))
            SilentAimTargetLineFrame.Visible = true
        end)
    end
end)

local function getWeaponModModules()
    if WeaponModModules.Config and WeaponModModules.Bus then return true end
    local ok, result = pcall(function()
        local replicatedStorage = game:GetService("ReplicatedStorage")
        local iwbf = replicatedStorage:FindFirstChild("IWBF") or replicatedStorage:WaitForChild("IWBF", 5)
        assert(iwbf, "ReplicatedStorage.IWBF not found")
        local shared = iwbf:FindFirstChild("Shared") or iwbf:WaitForChild("Shared", 5)
        assert(shared, "IWBF.Shared not found")
        WeaponModModules.Config = require(shared:WaitForChild("Config"))
        WeaponModModules.Bus = require(shared:WaitForChild("Bus"))
        WeaponModModules.GunPose = require(shared:WaitForChild("GunPose"))
        WeaponModModules.GunSway = require(shared:WaitForChild("GunSway"))
        WeaponModModules.ItemDB = require(shared:WaitForChild("ItemDB"))
    end)
    if not ok then
        warn("[MISSENSE WeaponMods] module load failed: " .. tostring(result))
        return false
    end
    return true
end

local function saveAndSet(bucket, object, key, value)
    local fields = bucket[object]
    if not fields then fields = {}; bucket[object] = fields end
    if fields[key] == nil then fields[key] = { value = object[key] } end
    object[key] = value
end

local function restoreBucket(bucket)
    for object, fields in pairs(bucket) do
        for key, record in pairs(fields) do
            object[key] = record.value
        end
    end
    table.clear(bucket)
end

local function eachWeaponSpec(callback)
    local config = WeaponModModules.Config
    if not config or type(config.Firearms) ~= "table" then return end
    for _, spec in pairs(config.Firearms) do
        if type(spec) == "table" and type(spec.Interval) == "number" then
            callback(spec)
        end
    end
end

local function installNoRecoilBusHook()
    if not getgenv or type(hookfunction) ~= "function" then return false end
    local env = getgenv()
    if env.__MS_WEAPONMOD_BUS_HOOKED then return true end
    local bus = WeaponModModules.Bus
    if not bus or type(bus.Call) ~= "function" then return false end
    local wrap = newcclosure or function(fn) return fn end
    local original
    local ok, result = pcall(function()
        original = hookfunction(bus.Call, wrap(function(name, ...)
            local globalState
            pcall(function() globalState = getgenv().__MS_WEAPONMOD_STATE end)
            if globalState and globalState.NoRecoil then
                if name == "Camera.Punch" or name == "Camera.Kick" then return nil end
                if name == "Camera.PunchAngles" then return Vector3.zero end
            end
            local originalCall
            pcall(function() originalCall = getgenv().__MS_WEAPONMOD_ORIGINAL_BUS_CALL end)
            if type(originalCall) == "function" then return originalCall(name, ...) end
            if type(original) == "function" then return original(name, ...) end
            return nil
        end))
    end)
    if ok and type(original) == "function" then
        env.__MS_WEAPONMOD_ORIGINAL_BUS_CALL = original
        env.__MS_WEAPONMOD_BUS_HOOKED = true
        return true
    end
    warn("[MISSENSE WeaponMods] couldn't hook Camera.Punch/Kick: " .. tostring(result))
    return false
end

local function applyNoRecoil(enabled)
    WeaponModificationState.NoRecoil = enabled == true
    if not getWeaponModModules() then return end
    local config = WeaponModModules.Config
    if enabled then
        installNoRecoilBusHook()
        eachWeaponSpec(function(spec)
            saveAndSet(WeaponModBackups.Recoil, spec, "AddSprayMul", 0)
            saveAndSet(WeaponModBackups.Recoil, spec, "CameraShakeMul", 0)
            saveAndSet(WeaponModBackups.Recoil, spec, "PrimaryForce", 0)
            saveAndSet(WeaponModBackups.Recoil, spec, "Spray", {Base = 0, Pitch = 0, Yaw = 0, Mul = 0, Count = 1000000})
            saveAndSet(WeaponModBackups.Recoil, spec, "SprayRand", {Vector2.zero, Vector2.zero})
        end)
        if WeaponModModules.GunPose then
            if not WeaponModOriginalFns.GunPoseRecoil then WeaponModOriginalFns.GunPoseRecoil = WeaponModModules.GunPose.Recoil end
            WeaponModModules.GunPose.Recoil = function() return CFrame.identity end
        end
    else
        restoreBucket(WeaponModBackups.Recoil)
        if WeaponModModules.GunPose and WeaponModOriginalFns.GunPoseRecoil then
            WeaponModModules.GunPose.Recoil = WeaponModOriginalFns.GunPoseRecoil
        end
    end
end

local function applyNoSpread(enabled)
    WeaponModificationState.NoSpread = enabled == true
    if not getWeaponModModules() then return end
    local config = WeaponModModules.Config
    if enabled then
        eachWeaponSpec(function(spec) saveAndSet(WeaponModBackups.Spread, spec, "Spread", 0) end)
        if type(config.Ammo) == "table" then
            for _, ammo in pairs(config.Ammo) do
                if type(ammo) == "table" then saveAndSet(WeaponModBackups.Spread, ammo, "Spread", 0) end
            end
        end
    else
        restoreBucket(WeaponModBackups.Spread)
    end
end

local function applyInstantEquip(enabled)
    WeaponModificationState.InstantEquip = enabled == true
    if not getWeaponModModules() then return end
    if enabled then
        eachWeaponSpec(function(spec) saveAndSet(WeaponModBackups.Deploy, spec, "Deploy", 0.01) end)
    else
        restoreBucket(WeaponModBackups.Deploy)
    end
end

local function applyInstantScope(enabled)
    WeaponModificationState.InstantScope = enabled == true
    if not getWeaponModModules() then return end
    local itemDB = WeaponModModules.ItemDB
    if enabled then
        local ok, items = pcall(function() return itemDB.All() end)
        if ok and type(items) == "table" then
            for _, item in ipairs(items) do
                if type(item) == "table" and item.Kind == "firearm" then
                    saveAndSet(WeaponModBackups.Ergonomics, item, "Ergonomics", 100)
                end
            end
        end
    else
        restoreBucket(WeaponModBackups.Ergonomics)
    end
end

local function applyNoGunSway(enabled)
    WeaponModificationState.NoGunSway = enabled == true
    if not getWeaponModModules() then return end
    local gunSway = WeaponModModules.GunSway
    if enabled then
        if not WeaponModOriginalFns.GunSwayPreLerp then WeaponModOriginalFns.GunSwayPreLerp = gunSway.PreLerp end
        gunSway.PreLerp = function() return Vector3.zero, Vector3.zero, 0, 0 end
    elseif WeaponModOriginalFns.GunSwayPreLerp then
        gunSway.PreLerp = WeaponModOriginalFns.GunSwayPreLerp
    end
end

-- Fast reload: reduces client-side timing/config values only. The server may
-- still enforce the real reload duration and acknowledgement.
local function applyFastReload(enabled)
    WeaponModificationState.FastReload = enabled == true
    if not getWeaponModModules() then return end
    local firearms = WeaponModModules.Config and WeaponModModules.Config.Firearms
    if type(firearms) ~= "table" then return end

    if enabled then
        eachWeaponSpec(function(spec)
            saveAndSet(WeaponModBackups.FastReload, spec, "ReloadTime", 0.12)
            saveAndSet(WeaponModBackups.FastReload, spec, "CycleTime", 0.06)
            saveAndSet(WeaponModBackups.FastReload, spec, "StartTime", 0.06)
            saveAndSet(WeaponModBackups.FastReload, spec, "InsertTime", 0.06)
        end)
        saveAndSet(WeaponModBackups.FastReload, firearms, "ReloadAfterShot", 0.01)
        saveAndSet(WeaponModBackups.FastReload, firearms, "ReloadGrace", 0.1)
        warn("[MISSENSE WeaponMods] Fast Reload applied to client config; server-side reload limits may remain")
    else
        restoreBucket(WeaponModBackups.FastReload)
    end
end

-- Rapid fire lowers the local FirearmClient gate. A server-side cadence limit
-- can still reject shots faster than its own weapon configuration permits.
local function applyRapidFire(enabled)
    WeaponModificationState.RapidFire = enabled == true
    if not getWeaponModModules() then return end
    local firearms = WeaponModModules.Config and WeaponModModules.Config.Firearms
    if type(firearms) ~= "table" then return end

    if enabled then
        eachWeaponSpec(function(spec)
            saveAndSet(WeaponModBackups.RapidFire, spec, "Interval", 0.035)
        end)
        saveAndSet(WeaponModBackups.RapidFire, firearms, "ClientShotSpacing", 0.05)
        saveAndSet(WeaponModBackups.RapidFire, firearms, "ClientShotBurst", 12)
        saveAndSet(WeaponModBackups.RapidFire, firearms, "ShotSpacing", 0.035)
        saveAndSet(WeaponModBackups.RapidFire, firearms, "ShotBurst", 12)
        warn("[MISSENSE WeaponMods] Rapid Fire changed local timing; server cadence checks may reject extra shots")
    else
        restoreBucket(WeaponModBackups.RapidFire)
    end
end

local function backupHeldAmmo(held)
    if not held or InfiniteAmmoHeldBackup[held] then return end
    InfiniteAmmoHeldBackup[held] = {
        IClip = held:GetAttribute("IClip"),
        IClipLocal = held:GetAttribute("IClipLocal"),
        IChamber = held:GetAttribute("IChamber"),
        ISpent = held:GetAttribute("ISpent"),
    }
end

local function restoreHeldAmmo()
    for held, attrs in pairs(InfiniteAmmoHeldBackup) do
        if held and held.Parent then
            pcall(function()
                held:SetAttribute("IClip", attrs.IClip)
                held:SetAttribute("IClipLocal", attrs.IClipLocal)
                held:SetAttribute("IChamber", attrs.IChamber)
                held:SetAttribute("ISpent", attrs.ISpent)
            end)
        end
        InfiniteAmmoHeldBackup[held] = nil
    end
end

local function applyInfiniteAmmo(enabled)
    WeaponModificationState.InfiniteAmmo = enabled == true
    if not getWeaponModModules() then return end
    local firearms = WeaponModModules.Config and WeaponModModules.Config.Firearms
    if type(firearms) == "table" then
        if enabled then
            -- Shorter local reconciliation allows the client-side clip state
            -- to recover quickly after local attribute updates.
            saveAndSet(WeaponModBackups.InfiniteAmmo, firearms, "ReconcileDelay", 0.05)
        else
            restoreBucket(WeaponModBackups.InfiniteAmmo)
            restoreHeldAmmo()
        end
    end
    if enabled then
        warn("[MISSENSE WeaponMods] Infinite Ammo is a client-side clip spoof; server-authoritative ammo may still run out")
    end
end

-- Keep only the local held firearm's displayed/predicted clip populated while
-- the option is enabled. It does not change server inventory or server ammo.
bind(RunService.Heartbeat, function()
    if not WeaponModificationState.InfiniteAmmo then return end
    local character = LocalPlayer and LocalPlayer.Character
    local held = character and character:FindFirstChild("IHeld")
    if not held then return end

    local itemDB = WeaponModModules.ItemDB
    if not itemDB then return end
    local ok, item = pcall(function()
        return itemDB.Get(held:GetAttribute("IItemId"))
    end)
    if not ok or type(item) ~= "table" or item.Kind ~= "firearm" then return end

    backupHeldAmmo(held)
    pcall(function()
        if held:GetAttribute("IClip") ~= 9999 then held:SetAttribute("IClip", 9999) end
        if held:GetAttribute("IClipLocal") ~= 9999 then held:SetAttribute("IClipLocal", 9999) end
        if held:GetAttribute("IChamber") ~= true then held:SetAttribute("IChamber", true) end
        if held:GetAttribute("ISpent") ~= false then held:SetAttribute("ISpent", false) end
    end)
end)

local function silentAimDiag(message, interval)
    if not SilentAimState.Debug then return end
    local now = os.clock()
    interval = interval or 0.65
    if now - (SilentAimState._lastDiagAt or 0) < interval then return end
    SilentAimState._lastDiagAt = now
    warn("[MISSENSE SilentAim][DIAG] " .. tostring(message))
end

local function installSilentAimHook()
    if type(getgenv) ~= "function" then
        warn("[MISSENSE SilentAim][DIAG] getgenv unavailable; proxy hook not installed")
        return false
    end

    local env = getgenv()
    local netModule, gunProxy
    local okNet, netErr = pcall(function()
        local replicatedStorage = game:GetService("ReplicatedStorage")
        local iwbf = replicatedStorage:WaitForChild("IWBF", 10)
        assert(iwbf, "ReplicatedStorage.IWBF missing")
        local shared = iwbf:WaitForChild("Shared", 10)
        assert(shared, "ReplicatedStorage.IWBF.Shared missing")
        local netScript = shared:WaitForChild("Net", 10)
        assert(netScript, "ReplicatedStorage.IWBF.Shared.Net missing")
        netModule = require(netScript)
        assert(type(netModule.Event) == "function", "Net.Event is not a function")
        gunProxy = netModule.Event("IGun")
        assert(gunProxy ~= nil, "Net.Event('IGun') returned nil")
        assert(type(gunProxy.FireServer) == "function", "IGun FireServer method unavailable")
    end)

    if not okNet or not netModule or not gunProxy then
        warn("[MISSENSE SilentAim][DIAG] couldn't resolve IWBF Net proxy: " .. tostring(netErr))
        return false
    end

    -- Remove this script's earlier per-proxy override if the script was re-executed.
    local previousProxy = env.__MS_SILENT_AIM_PROXY_INSTANCE
    if type(previousProxy) == "table" then
        pcall(function() rawset(previousProxy, "FireServer", nil) end)
    end
    env.__MS_SILENT_AIM_PROXY_INSTANCE = nil
    env.__MS_SILENT_AIM_PROXY_METHOD_ORIGINAL = nil

    -- Older builds hooked the shared t19.FireServer function globally. Restore it before
    -- attaching to this single IGun proxy so unrelated IWBF events are never intercepted.
    if env.__MS_SILENT_AIM_PROXY_HOOKED and type(env.__MS_SILENT_AIM_PROXY_ORIGINAL) == "function" then
        if type(hookfunction) ~= "function" then
            env.__MS_SILENT_AIM_STATE = nil
            warn("[MISSENSE SilentAim][DIAG] legacy global hook detected but hookfunction is unavailable; restart executor once to clear it")
            return false
        end
        local exposedMethod = rawget(gunProxy, "FireServer") or gunProxy.FireServer
        local restored, restoreErr = pcall(function()
            hookfunction(exposedMethod, env.__MS_SILENT_AIM_PROXY_ORIGINAL)
        end)
        if not restored then
            env.__MS_SILENT_AIM_STATE = nil
            warn("[MISSENSE SilentAim][DIAG] couldn't restore legacy global FireServer hook: " .. tostring(restoreErr) .. "; restart executor once before testing")
            return false
        end
        env.__MS_SILENT_AIM_PROXY_HOOKED = nil
        env.__MS_SILENT_AIM_PROXY_ORIGINAL = nil
        env.__MS_SILENT_AIM_PROXY_LAST_LOG = nil
        warn("[MISSENSE SilentAim][DIAG] restored previous global IWBF hook")
    end

    local originalFireServer = gunProxy.FireServer
    if type(originalFireServer) ~= "function" then
        warn("[MISSENSE SilentAim][DIAG] IGun.FireServer method unavailable after restoring legacy hook")
        return false
    end

    -- Important: assign only to the cached IGun proxy table. The IWBF module's
    -- shared FireServer function is left untouched for all other network channels.
    local wrapperOk, wrapperErr = pcall(function()
        gunProxy.FireServer = function(self, ...)
            if self ~= gunProxy or select(1, ...) ~= "shoot" then
                return originalFireServer(self, ...)
            end

            local args = table.pack(...)
            if not SilentAimState.Enabled then
                return originalFireServer(self, table.unpack(args, 1, args.n))
            end
            if not SilentAimState.KeyActive then
                silentAimDiag("shoot observed but Keybind is inactive", 0.4)
                return originalFireServer(self, table.unpack(args, 1, args.n))
            end

            local origin = args[3]
            local directionArg = args[4]
            if typeof(origin) ~= "Vector3" or typeof(directionArg) ~= "Vector3" then
                silentAimDiag("unexpected shoot args: args[3]=" .. typeof(origin) .. ", args[4]=" .. typeof(directionArg), 0.4)
                return originalFireServer(self, table.unpack(args, 1, args.n))
            end

            local chance = math.clamp(tonumber(SilentAimState.HitChance) or 100, 0, 100)
            if chance < 100 and math.random(1, 100) > chance then
                silentAimDiag("not redirected: Hit Chance roll failed (" .. tostring(chance) .. "%)", 0.4)
                return originalFireServer(self, table.unpack(args, 1, args.n))
            end

            local target
            local targetOk, targetErr = pcall(function()
                target = SilentAimState.GetTarget and SilentAimState.GetTarget()
            end)
            if not targetOk then
                silentAimDiag("target selector errored: " .. tostring(targetErr or "unknown error"), 0.4)
                return originalFireServer(self, table.unpack(args, 1, args.n))
            end
            if not target or not target.Parent or not target:IsA("BasePart") then
                silentAimDiag("no target selected; check FOV, character parts and Wall Check", 0.4)
                return originalFireServer(self, table.unpack(args, 1, args.n))
            end

            local position = target.Position
            local prediction = math.clamp(tonumber(SilentAimState.Prediction) or 0, 0, 100) / 100
            if prediction > 0 then
                position += target.AssemblyLinearVelocity * (prediction * 0.12)
            end
            local direction = position - origin
            if direction.Magnitude <= 0.001 then
                silentAimDiag("target direction too small; direction unchanged", 0.4)
                return originalFireServer(self, table.unpack(args, 1, args.n))
            end

            args[4] = direction.Unit
            silentAimDiag("REDIRECTED through IGun proxy -> " .. target:GetFullName(), 0.25)
            return originalFireServer(self, table.unpack(args, 1, args.n))
        end
    end)

    if not wrapperOk then
        warn("[MISSENSE SilentAim][DIAG] couldn't attach IGun-only proxy wrapper: " .. tostring(wrapperErr))
        return false
    end

    env.__MS_SILENT_AIM_PROXY_INSTANCE = gunProxy
    env.__MS_SILENT_AIM_PROXY_METHOD_ORIGINAL = originalFireServer
    env.__MS_SILENT_AIM_STATE = nil -- this build uses its local state; avoid reactivating legacy global hooks
    warn("[MISSENSE SilentAim][DIAG] isolated IGun proxy wrapper installed (other IWBF events untouched)")
    return true
end

SilentAimState.GetTarget = findSilentAimTarget
pcall(installSilentAimHook)
if getgenv then
    pcall(function() getgenv().__MS_WEAPONMOD_STATE = WeaponModificationState end)
end

local function cleanupWeaponMods()
    SilentAimState.Enabled = false
    SilentAimState.KeyActive = false
    WeaponModificationState.NoRecoil = false
    WeaponModificationState.NoSpread = false
    WeaponModificationState.InstantEquip = false
    WeaponModificationState.InstantScope = false
    WeaponModificationState.NoGunSway = false
    WeaponModificationState.FastReload = false
    WeaponModificationState.InfiniteAmmo = false
    WeaponModificationState.RapidFire = false
    if getgenv then
        pcall(function()
            local env = getgenv()
            env.__MS_SILENT_AIM_STATE = nil
            env.__MS_WEAPONMOD_STATE = nil
            local proxy = env.__MS_SILENT_AIM_PROXY_INSTANCE
            if type(proxy) == "table" then rawset(proxy, "FireServer", nil) end
            env.__MS_SILENT_AIM_PROXY_INSTANCE = nil
            env.__MS_SILENT_AIM_PROXY_METHOD_ORIGINAL = nil
        end)
    end
    restoreBucket(WeaponModBackups.Recoil)
    restoreBucket(WeaponModBackups.Spread)
    restoreBucket(WeaponModBackups.Deploy)
    restoreBucket(WeaponModBackups.Ergonomics)
    restoreBucket(WeaponModBackups.FastReload)
    restoreBucket(WeaponModBackups.RapidFire)
    restoreBucket(WeaponModBackups.InfiniteAmmo)
    restoreHeldAmmo()
    if WeaponModModules.GunPose and WeaponModOriginalFns.GunPoseRecoil then
        pcall(function() WeaponModModules.GunPose.Recoil = WeaponModOriginalFns.GunPoseRecoil end)
    end
    if WeaponModModules.GunSway and WeaponModOriginalFns.GunSwayPreLerp then
        pcall(function() WeaponModModules.GunSway.PreLerp = WeaponModOriginalFns.GunSwayPreLerp end)
    end
end

bind(RunService.RenderStepped, function()
    if not AimbotState.Enabled or not AimbotState.KeyActive then return end
    local cam = workspace.CurrentCamera
    if not cam then return end
    local target = findAimbotTarget()
    if not target then return end

    local predictScale = math.clamp(AimbotState.Predict / 100, 0, 1)
    local aimPosition = target.Position + target.AssemblyLinearVelocity * (predictScale * 0.12)
    if AimbotState.Type == "Mouse" then
        if type(mousemoverel) == "function" then
            local screen, onScreen = cam:WorldToViewportPoint(aimPosition)
            if onScreen then
                local delta = Vector2.new(screen.X, screen.Y) - cam.ViewportSize / 2
                local alpha = math.clamp(AimbotState.Smooth / 100, 0.01, 1)
                pcall(mousemoverel, delta.X * alpha, delta.Y * alpha)
            end
        end
    else
        local goal = CFrame.lookAt(cam.CFrame.Position, aimPosition)
        local alpha = math.clamp(1 - AimbotState.Smooth / 100, 0.01, 1)
        cam.CFrame = cam.CFrame:Lerp(goal, alpha)
    end
end)

------------------------------------------------------------
-- CombatPage
------------------------------------------------------------
do
	local LeftSection = CombatPage:Section({Name = "aimbot", Side = 1})
    local fov1Section = CombatPage:Section({Name = "aim fov", Side = 1})
    local LowerSection = CombatPage:Section({Name = "triggerbot", Side = 1})
	local RightSection = CombatPage:Section({Name = "silent aim", Side = 2})
    local fov2Section = CombatPage:Section({Name = "silent fov", Side = 2})

--Combat LeftSection

	LeftSection:Toggle({
		Name = "Aimbot",
		Flag = "Aimbot",
		Default = false,
		Callback = function(v)
            AimbotState.Enabled = v
            if not v then AimbotState.KeyActive = false end
        end
	})


	LeftSection:Label({Name = "bind"}):Keybind({
		Name = "Aimbot Keybind",
		Flag = "Aimbotkeybind",
		Default = Enum.KeyCode.V,
		Mode = "Toggle",
		Callback = function(value)
            if not AimbotState.Enabled then AimbotState.KeyActive = false; return end
            if type(value) == "boolean" then
                AimbotState.KeyActive = value
            else
                AimbotState.KeyActive = not AimbotState.KeyActive
            end
        end
	})

	LeftSection:Dropdown({
		Name = "Aim Target",
		Flag = "Aimtarget",
		Items = {"Head", "Torso", "Arms", "Legs", "Random", "Closet"},
		Default = "Head",
		Multi = false,
		Callback = function(value) AimbotState.Target = value end
	})

	LeftSection:Slider({
		Name = "Smooth",
		Flag = "Smooth",
		Min = 0, Max = 100, Default = 25, Decimals = 1, Suffix = "%",
		Callback = function(value) AimbotState.Smooth = value end
	})

	LeftSection:Slider({
		Name = "Predict",
		Flag = "Predict",
		Min = 0, Max = 100, Default = 12, Decimals = 1, Suffix = "%",
		Callback = function(value) AimbotState.Predict = value end
	})

        	LeftSection:Dropdown({
		Name = "Aim Type",
		Flag = "AimType",
		Items = {"Camera", "Mouse"},
		Default = "Camera",
		Multi = false,
		Callback = function(value) AimbotState.Type = value end
	})

    LeftSection:Toggle({
        Name = "Wall Check",
        Flag = "AimbotWallCheck",
        Default = false,
        Callback = function(v) AimbotState.WallCheck = v end
    })

	fov1Section:Toggle({
		Name = "Fov",
		Flag = "AimbotFov",
		Default = false,
		Callback = function(v) AimbotFov:SetEnabled(v) end
	})

	fov1Section:Label({Name = "fov color"}):Colorpicker({
		Name = "fov color",
		Flag = "AimbotFovColor",
		Default = Color3.fromRGB(255, 255, 255),
		Callback = function(value, alpha) AimbotFov:SetColor(value) end
	})

	fov1Section:Slider({
		Name = "Fov amount",
		Flag = "AimbotFovAmount",
		Min = 1, Max = 100, Default = 22, Decimals = 1, Suffix = "°",
		Callback = function(value) AimbotFov:SetAngle(value) end
	})

	fov1Section:Dropdown({
		Name = "fov form",
		Flag = "AimbotFovForm",
		Items = {"Circle", "Box"},
		Default = "Circle",
		Multi = false,
		Callback = function(value) AimbotFov:SetShape(value) end
	})

	fov1Section:Toggle({
		Name = "Fov outline",
		Flag = "AimbotFovOutline",
		Default = false,
		Callback = function(v) AimbotFov:SetOutline(v) end
	})

	fov1Section:Label({Name = "outline color"}):Colorpicker({
		Name = "outline color",
		Flag = "AimbotFovOutlineColor",
		Default = Color3.fromRGB(0, 0, 0),
		Callback = function(value, alpha) AimbotFov:SetOutlineColor(value) end
	})

-- Combat left LowerSection

	LowerSection:Toggle({
		Name = "Triggerbot",
		Flag = "Triggerbot",
		Default = false,
		Callback = function(v) end
	})

	LowerSection:Label({Name = "bind"}):Keybind({
		Name = "Triggerbot Keybind",
		Flag = "TriggerbotKeybind",
		Default = Enum.KeyCode.LeftAlt,
		Mode = "Toggle",
		Callback = function(value) end
	})

	LowerSection:Dropdown({
		Name = "Trigger target",
		Flag = "Triggertarget",
		Items = {"Head", "Torso", "Arms", "Legs"},
		Default = "Head",
		Multi = true,
		Callback = function(value) end
	})

	LowerSection:Slider({
		Name = "Trigger fov",
		Flag = "TriggerFov",
		Min = 0, Max = 460, Default = 40, Decimals = 1, Suffix = "%",
		Callback = function(value) end
	})

	LowerSection:Slider({
		Name = "Reaction time",
		Flag = "reaction",
		Min = 0, Max = 460, Default = 50, Decimals = 1, Suffix = " ms",
		Callback = function(value) end
	})

	-- Combat Right Section

	    RightSection:Toggle({
        Name = "Silent Aim",
        Flag = "SilentAim",
        Default = false,
        Callback = function(v)
            SilentAimState.Enabled = v == true
            SilentAimState.KeyActive = SilentAimState.Enabled
            if SilentAimState.Enabled then
                warn("[MISSENSE SilentAim][DIAG] enabled directly by toggle; this confirms UI state only")
            end
        end
    })

    RightSection:Label({Name = "bind"}):Keybind({
        Name = "Silent Aim Keybind",
        Flag = "SilentaimKeybind",
        Default = Enum.KeyCode.T,
        Mode = "Toggle",
        Callback = function(value)
            if not SilentAimState.Enabled then SilentAimState.KeyActive = false; return end
            if type(value) == "boolean" then SilentAimState.KeyActive = value
            else SilentAimState.KeyActive = not SilentAimState.KeyActive end
        end
    })

    RightSection:Dropdown({
        Name = "Silent Aim Target",
        Flag = "silenttarget",
        Items = {"Head", "Torso", "Arms", "Legs", "Random", "Closet"},
        Default = "Head",
        Multi = false,
        Callback = function(value) if type(value) == "string" then SilentAimState.Target = value end end
    })

    RightSection:Slider({
        Name = "Hit Chance",
        Flag = "HitChance",
        Min = 0, Max = 100, Default = 100, Decimals = 1, Suffix = "%",
        Callback = function(value) SilentAimState.HitChance = math.clamp(tonumber(value) or 70, 0, 100) end
    })

    RightSection:Slider({
        Name = "Prediction",
        Flag = "SilentAimPrediction",
        Min = 0, Max = 100, Default = 0, Decimals = 1, Suffix = "%",
        Callback = function(value) SilentAimState.Prediction = math.clamp(tonumber(value) or 0, 0, 100) end
    })

    RightSection:Toggle({
        Name = "Wall Check",
        Flag = "SilentAimWallCheck",
        Default = true,
        Callback = function(value) SilentAimState.WallCheck = value == true end
    })
	fov2Section:Toggle({
		Name = "Fov",
		Flag = "SilentFov",
		Default = false,
		Callback = function(v) SilentFov:SetEnabled(v) end
	})

	fov2Section:Label({Name = "fov color"}):Colorpicker({
		Name = "fov color",
		Flag = "SilentFovColor",
		Default = Color3.fromRGB(255, 255, 255),
		Callback = function(value, alpha) SilentFov:SetColor(value) end
	})

	fov2Section:Slider({
		Name = "Fov amount",
		Flag = "SilentFovAmount",
		Min = 1, Max = 180, Default = 22, Decimals = 1, Suffix = "°",
		Callback = function(value) SilentFov:SetAngle(value) end
	})

	fov2Section:Dropdown({
		Name = "fov form",
		Flag = "SilentFovForm",
		Items = {"Circle", "Box"},
		Default = "Circle",
		Multi = false,
		Callback = function(value) SilentFov:SetShape(value) end
	})

	fov2Section:Toggle({
		Name = "Fov outline",
		Flag = "SilentFovOutline",
		Default = false,
		Callback = function(v) SilentFov:SetOutline(v) end
	})

	fov2Section:Label({Name = "outline color"}):Colorpicker({
		Name = "outline color",
		Flag = "SilentFovOutlineColor",
		Default = Color3.fromRGB(0, 0, 0),
		Callback = function(value, alpha) SilentFov:SetOutlineColor(value) end
	})

    fov2Section:Toggle({
        Name = "Target line",
        Flag = "SilentAimTargetLine",
        Default = false,
        Callback = function(value) SilentAimState.TargetLine = value == true end
    })

    fov2Section:Dropdown({
        Name = "Target line mode",
        Flag = "SilentAimTargetLineMode",
        Items = {"Line Center", "Line Crosshair"},
        Default = "Line Center",
        Multi = false,
        Callback = function(value)
            if value == "Line Center" or value == "Line Crosshair" then
                SilentAimState.TargetLineMode = value
            end
        end
    })

    fov2Section:Label({Name = "target line color"}):Colorpicker({
        Name = "target line color",
        Flag = "SilentAimTargetLineColor",
        Default = Color3.fromRGB(255, 80, 80),
        Callback = function(value)
            if typeof(value) == "Color3" then SilentAimState.TargetLineColor = value end
        end
    })

    fov2Section:Slider({
        Name = "target line thickness",
        Flag = "SilentAimTargetLineThickness",
        Min = 1, Max = 8, Default = 2, Decimals = 1,
        Callback = function(value) SilentAimState.TargetLineThickness = math.clamp(tonumber(value) or 2, 1, 8) end
    })

    fov2Section:Toggle({
        Name = "target line outline",
        Flag = "SilentAimTargetLineOutline",
        Default = true,
        Callback = function(value) SilentAimState.TargetLineOutline = value == true end
    })

    fov2Section:Label({Name = "target line outline color"}):Colorpicker({
        Name = "target line outline color",
        Flag = "SilentAimTargetLineOutlineColor",
        Default = Color3.fromRGB(0, 0, 0),
        Callback = function(value)
            if typeof(value) == "Color3" then SilentAimState.TargetLineOutlineColor = value end
        end
    })

    fov2Section:Slider({
        Name = "target line outline thickness",
        Flag = "SilentAimTargetLineOutlineThickness",
        Min = 1, Max = 8, Default = 2, Decimals = 1,
        Callback = function(value) SilentAimState.TargetLineOutlineThickness = math.clamp(tonumber(value) or 2, 1, 8) end
    })
end

------------------------------------------------------------
-- MiscPage
------------------------------------------------------------

do
-- camera

	local MiscSection = MiscPage:Section({Name = "camera", Side = 1})
    local FreecamSection = MiscPage:Section({Name = "freecam", Side = 2})

-- freecam section

	FreecamSection:Toggle({
		Name = "Freecam",
		Flag = "Freecam",
		Default = false,
		Callback = function(v)
			Freecam.Armed = v
			if not v then Freecam:SetEnabled(false) end
		end
	})

	FreecamSection:Label({Name = "bind"}):Keybind({
		Name = "Freecam keybind",
		Flag = "FreecamKeybind",
		Default = Enum.KeyCode.P,
		Mode = "Toggle",
		Callback = function(value)
			if not Freecam.Armed then return end
			if type(value) == "boolean" then
				Freecam:SetEnabled(value)
			else
				Freecam:SetEnabled(not Freecam.Enabled)
			end
		end
	})

	FreecamSection:Slider({
		Name = "Speed",
		Flag = "FreecamSpeed",
		Min = 0.1, Max = 10, Default = 1, Decimals = 1, Suffix = "x",
		Callback = function(value) Freecam.Speed = value end
	})

	FreecamSection:Slider({
		Name = "Fast multiplier (Shift)",
		Flag = "FreecamFast",
		Min = 1, Max = 10, Default = 3, Decimals = 1, Suffix = "x",
		Callback = function(value) Freecam.FastMult = value end
	})

	FreecamSection:Slider({
		Name = "Sensitivity",
		Flag = "FreecamSens",
		Min = 0, Max = 4, Default = 0.80, Decimals = 0.01, Suffix = "",
		Callback = function(value) Freecam.Sens = value end
	})
    
            	FreecamSection:Toggle({
		Name = "Smooth movement",
		Flag = "FreecamSmooth",
		Default = true,
		Callback = function(v) Freecam.Smooth = v end
	})

-- MIsc Section

	MiscSection:Toggle({
		Name = "Fov changer",
		Flag = "FovChanger",
		Default = false,
		Callback = function(v) FovChanger:SetEnabled(v) end
	})

	MiscSection:Slider({
		Name = "Field of view",
		Flag = "FovChangerValue",
		Min = 5, Max = 120, Default = 70, Decimals = 1, Suffix = "°",
		Callback = function(value) FovChanger.Value = value end
	})

	MiscSection:Toggle({
		Name = "Smooth transition (buggy)",
		Flag = "FovChangerSmooth",
		Default = false,
		Callback = function(v) FovChanger.Smooth = v end
	})

	MiscSection:Toggle({
		Name = "Third person",
		Flag = "ThirdPerson",
		Default = false,
		Callback = function(v)
			ThirdPerson.Armed = v
			if not v then ThirdPerson:SetEnabled(false) end
		end
	})

	MiscSection:Label({Name = "bind"}):Keybind({
		Name = "Third person keybind",
		Flag = "ThirdPersonKeybind",
		Default = Enum.KeyCode.Z,
		Mode = "Toggle",
		Callback = function(value)
			if not ThirdPerson.Armed then return end
			if type(value) == "boolean" then
				ThirdPerson:SetEnabled(value)
			else
				ThirdPerson:SetEnabled(not ThirdPerson.Enabled)
			end
		end
	})

	MiscSection:Slider({
		Name = "Back",
		Flag = "ThirdPersonBack",
		Min = 0, Max = 30, Default = 5, Decimals = 1, Suffix = " st",
		Callback = function(value) ThirdPerson.Back = value end
	})

	MiscSection:Slider({
		Name = "Side",
		Flag = "ThirdPersonSide",
		Min = -10, Max = 10, Default = 0, Decimals = 1, Suffix = " st",
		Callback = function(value) ThirdPerson.Side = value end
	})

	MiscSection:Slider({
		Name = "Height",
		Flag = "ThirdPersonHeight",
		Min = -5, Max = 10, Default = 0, Decimals = 1, Suffix = " st",
		Callback = function(value) ThirdPerson.Height = value end
	})
end

-- Name Spoof section
	local NameSpoofSection = MiscPage:Section({Name = "name spoof", Side = 2})

	local NameSpoof = {
		Enabled = false,
		SpoofUser = "",
		SpoofNick = "",
		RealName = LocalPlayer.Name,
		RealDisplay = LocalPlayer.DisplayName,
		Connections = {}, 
		Touched = {},       
		DescConns = {},
	}


	local function spoofResolve(text)
		if text == NameSpoof.RealName and NameSpoof.SpoofUser ~= "" then
			return NameSpoof.SpoofUser
		end
		if text == NameSpoof.RealDisplay and NameSpoof.SpoofNick ~= "" then
			return NameSpoof.SpoofNick
		end
		return nil
	end

	local function spoofRefresh(v)
		if not (v:IsA("TextLabel") or v:IsA("TextButton")) then return end
		local target = spoofResolve(v.Text)
		if target then
			v.Text = target
			NameSpoof.Touched[v] = true
		end
		if not NameSpoof.Connections[v] then
			NameSpoof.Connections[v] = v:GetPropertyChangedSignal("Text"):Connect(function()
				local t = spoofResolve(v.Text)
				if t and v.Text ~= t then
					v.Text = t
				elseif not NameSpoof.Touched[v] then
					local t2 = spoofResolve(v.Text)
					if t2 then v.Text = t2 end
				end
			end)
		end
	end

	local function spoofOn(v)
		if not v then return end
		if v:IsA("TextLabel") or v:IsA("TextButton") then
			spoofRefresh(v)
		end
		for _, d in ipairs(v:GetDescendants()) do
			spoofRefresh(d)
		end
	end

	local function spoofCleanup()
		for _, c in pairs(NameSpoof.Connections) do pcall(function() c:Disconnect() end) end
		for _, c in pairs(NameSpoof.DescConns) do pcall(function() c:Disconnect() end) end
		NameSpoof.Connections, NameSpoof.DescConns, NameSpoof.Touched = {}, {}, {}
		pcall(function() LocalPlayer.Name = NameSpoof.RealName end)
		pcall(function() LocalPlayer.DisplayName = NameSpoof.RealDisplay end)
	end

	local function spoofApply()
		pcall(function()
			if NameSpoof.SpoofUser ~= "" then LocalPlayer.Name = NameSpoof.SpoofUser end
		end)
		pcall(function()
			if NameSpoof.SpoofNick ~= "" then LocalPlayer.DisplayName = NameSpoof.SpoofNick end
		end)

		local containers = {CoreGui, LocalPlayer:WaitForChild("PlayerGui")}
		if gethui then table.insert(containers, gethui()) end

		for _, root in ipairs(containers) do
			for _, d in ipairs(root:GetDescendants()) do
				spoofRefresh(d)
			end
			table.insert(NameSpoof.DescConns, root.DescendantAdded:Connect(spoofOn))
			table.insert(NameSpoof.DescConns, root.DescendantRemoving:Connect(function(v)
				if NameSpoof.Connections[v] then
					pcall(function() NameSpoof.Connections[v]:Disconnect() end)
					NameSpoof.Connections[v] = nil
				end
				NameSpoof.Touched[v] = nil
			end))
		end
	end

    	NameSpoofSection:Toggle({
		Name = "name spoof (type user first)",
		Flag = "NameSpoof",
		Default = false,
		Callback = function(v)
			NameSpoof.Enabled = v
			if v then
				if NameSpoof.SpoofUser == "" and NameSpoof.SpoofNick == "" then
					Library:Notification("Set username or nickname first", 3, Color3.fromRGB(255, 80, 80))
					NameSpoof.Enabled = false
					return
				end
				applyFromToggle()
			else
				spoofCleanup()
			end
		end
	})

	NameSpoofSection:Textbox({
		Name = "Username",
		Flag = "SpoofUsername",
		Placeholder = "@username",
		Default = "",
		Callback = function(text)
			NameSpoof.SpoofUser = text or ""
		end
	})

	NameSpoofSection:Textbox({
		Name = "Nickname",
		Flag = "SpoofNickname",
		Placeholder = "Display name",
		Default = "",
		Callback = function(text)
			NameSpoof.SpoofNick = text or ""
		end
	})

	local function applyFromToggle()
		spoofCleanup()
		spoofApply()
	end


	NameSpoofSection:Button({
		Name = "Apply changes",
		Callback = function()
			if not NameSpoof.Enabled then
				Library:Notification("Enable spoof first", 3, Color3.fromRGB(255, 80, 80))
				return
			end
			if NameSpoof.SpoofUser == "" and NameSpoof.SpoofNick == "" then
				Library:Notification("Set username or nickname first", 3, Color3.fromRGB(255, 80, 80))
				return
			end
			applyFromToggle()
			Library:Notification("Name spoof applied")
		end
	})

    NameSpoofSection:Label({Name = "visual spoof (reopen Esc for refesh user)"})
    NameSpoofSection:Label({Name = "if you dont apply, u will change your watermark username"})

	if getgenv then
		getgenv().MS_NAMESPOOF_CLEANUP = function()
			spoofCleanup()
		end
	end

-- MISC: lean

do
	local LeanSection = MiscPage:Section({Name = "lean", Side = 1})

	local Lean = {
		Attr = "ILean",       
		Armed = false,        
		Left = false,         
		Right = false,        
		LeftValue = -37,      
		RightValue = 37,      
		Speed = 12,           
		Current = 0,
		Warned = false,
	}

	local function getTarget()
		if not Lean.Armed then return 0 end
		local t = 0
		if Lean.Left then t = t + Lean.LeftValue end
		if Lean.Right then t = t + Lean.RightValue end
		return t
	end

	bind(RunService.RenderStepped, function(dt)
		local target = getTarget()
		local delta = target - Lean.Current

		if target == 0 and math.abs(Lean.Current) < 0.01 then
			if Lean.Current ~= 0 then
				Lean.Current = 0
				local c0 = LocalPlayer.Character
				if c0 then pcall(function() c0:SetAttribute(Lean.Attr, 0) end) end
			end
			return
		end

		Lean.Current = Lean.Current + delta * math.clamp(dt * Lean.Speed, 0, 1)

		local char = LocalPlayer.Character
		if not char then return end

		if char:GetAttribute(Lean.Attr) == nil and not Lean.Warned then
			Lean.Warned = true
		end
		char:SetAttribute(Lean.Attr, Lean.Current)
	end)

	-- lean menu
	LeanSection:Toggle({
		Name = "Custom Lean",
		Flag = "LeanEnabled",
		Default = false,
		Callback = function(v)
			Lean.Armed = v
			if not v then
				Lean.Left, Lean.Right = false, false
			end
		end
	})

	LeanSection:Label({Name = "left lean"}):Keybind({
		Name = "Left lean keybind",
		Flag = "LeanLeftKeybind",
		Default = Enum.KeyCode.Q,
		Mode = "Toggle",
		Callback = function(value)
			if not Lean.Armed then return end
			if type(value) == "boolean" then
				Lean.Left = value
			else
				Lean.Left = not Lean.Left
			end
		end
	})

	LeanSection:Label({Name = "right lean"}):Keybind({
		Name = "Right lean keybind",
		Flag = "LeanRightKeybind",
		Default = Enum.KeyCode.E,
		Mode = "Toggle",
		Callback = function(value)
			if not Lean.Armed then return end
			if type(value) == "boolean" then
				Lean.Right = value
			else
				Lean.Right = not Lean.Right
			end
		end
	})

	LeanSection:Slider({
		Name = "Left lean",
		Flag = "LeanLeftValue",
		Min = -37, Max = 0, Default = -17, Decimals = 1, Suffix = "",
		Callback = function(v) Lean.LeftValue = v end
	})

	LeanSection:Slider({
		Name = "Right lean",
		Flag = "LeanRightValue",
		Min = 0, Max = 37, Default = 17, Decimals = 1, Suffix = "",
		Callback = function(v) Lean.RightValue = v end
	})
end

-- Weapon Modifications (IWBF client-side settings)
local WeaponModification = MiscPage:Section({Name = "Weapon Modifications", Side = 1})

WeaponModification:Toggle({
    Name = "No recoil",
    Flag = "NoRecoil",
    Default = false,
    Callback = function(v) applyNoRecoil(v) end
})

WeaponModification:Toggle({
    Name = "No spread",
    Flag = "Nospread",
    Default = false,
    Callback = function(v) applyNoSpread(v) end
})

WeaponModification:Toggle({
    Name = "Instant Equip",
    Flag = "instantEquip",
    Default = false,
    Callback = function(v) applyInstantEquip(v) end
})

WeaponModification:Toggle({
    Name = "Instant scope",
    Flag = "instantscope",
    Default = false,
    Callback = function(v) applyInstantScope(v) end
})

WeaponModification:Toggle({
    Name = "No gun sway",
    Flag = "NoGunSway",
    Default = false,
    Callback = function(v) applyNoGunSway(v) end
})

WeaponModification:Toggle({
    Name = "Fast Reload",
    Flag = "FastReload",
    Default = false,
    Callback = function(v) applyFastReload(v) end
})

WeaponModification:Toggle({
    Name = "Infinite Ammo",
    Flag = "InfiniteAmmo",
    Default = false,
    Callback = function(v) applyInfiniteAmmo(v) end
})

WeaponModification:Toggle({
    Name = "Rapid Fire",
    Flag = "RapidFire",
    Default = false,
    Callback = function(v) applyRapidFire(v) end
})

------------------------------------------------------------
-- PlayersPage
------------------------------------------------------------

do
	local ListSection = PlayersPage:Section({Name = "player list", Side = 1})
	local ActionSection = PlayersPage:Section({Name = "actions", Side = 2})
    local ActionSection2 = PlayersPage:Section({Name = "sets", Side = 2})

	local TOKEN = "__list_" .. math.random(100000000, 900000000) .. "__"
	local LIST_HEIGHT, ROW_HEIGHT = 280, 34
	local ACCENT = (Library.Theme and Library.Theme.Accent) or Color3.fromRGB(170, 150, 230)

	local C = {
		bg = Color3.fromRGB(12, 12, 12),
		row = Color3.fromRGB(22, 22, 22),
		hover = Color3.fromRGB(30, 30, 30),
		sel = Color3.fromRGB(34, 34, 34),
		line = Color3.fromRGB(38, 38, 38),
		text = Color3.fromRGB(215, 215, 215),
		dim = Color3.fromRGB(115, 115, 115),
	}
	local uiFont = {Face = nil, Size = 12} 

	local TAGS = {
		{key = "Priority",  text = "p", color = Color3.fromRGB(255, 0, 0)},
		{key = "Whitelist", text = "w", color = Color3.fromRGB(15, 131, 255)},
	}

	local Selected, Query = nil, ""
	local scroll, SelectedLabel
	local refresh

	local function notify(text, color)
		Library:Notification(text, 3, color or ACCENT)
	end

	local function styleText(l, size, color)
		if uiFont.Face then l.FontFace = uiFont.Face else l.Font = Enum.Font.Code end
		l.TextSize = size or uiFont.Size
		l.TextColor3 = color or C.text
	end

	local function tagString(plr)
		local t = {}
		for _, tg in ipairs(TAGS) do
			if PlayerData:Has(tg.key, plr) then table.insert(t, tg.text) end
		end
		return #t > 0 and (" [" .. table.concat(t, "") .. "]") or ""
	end

	function refresh()
		if SelectedLabel then
			if Selected and not Selected.Parent then Selected = nil end
			SelectedLabel:SetText(Selected and ("selected: " .. Selected.Name .. tagString(Selected)) or "selected: none")
		end
		if not scroll then return end

		for _, c in ipairs(scroll:GetChildren()) do
			if c:IsA("GuiObject") then c:Destroy() end
		end

		local list, q = {}, Query:lower()
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= LocalPlayer then
				if q == "" or p.Name:lower():find(q, 1, true) or p.DisplayName:lower():find(q, 1, true) then
					table.insert(list, p)
				end
			end
		end
		table.sort(list, function(a, b)
			local pa, pb = PlayerData:Has("Priority", a), PlayerData:Has("Priority", b)
			if pa ~= pb then return pa end
			return a.Name:lower() < b.Name:lower()
		end)

		if #list == 0 then
			local empty = Instance.new("TextLabel")
			empty.Size = UDim2.new(1, 0, 0, 30)
			empty.BackgroundTransparency = 1
			empty.Text = "no players"
			styleText(empty, nil, C.dim)
			empty.Parent = scroll
			return
		end

		for i, plr in ipairs(list) do
			local isSel = (plr == Selected)
			local base = isSel and C.sel or C.row

			local row = Instance.new("Frame")
			row.Size = UDim2.new(1, -6, 0, ROW_HEIGHT)
			row.BackgroundColor3 = base
			row.BorderSizePixel = 0
			row.LayoutOrder = i
			row.Parent = scroll
			local rs = Instance.new("UIStroke", row)
			rs.Color = C.line
			rs.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

			if isSel then
				local bar = Instance.new("Frame")
				bar.Size = UDim2.new(0, 2, 1, 0)
				bar.BackgroundColor3 = ACCENT
				bar.BorderSizePixel = 0
				bar.Parent = row
			end

			local av = Instance.new("ImageLabel")
			av.Size = UDim2.fromOffset(24, 24)
			av.Position = UDim2.fromOffset(8, 5)
			av.BackgroundColor3 = C.bg
			av.BorderSizePixel = 0
			av.Image = "rbxthumb://type=AvatarHeadShot&id=" .. plr.UserId .. "&w=48&h=48"
			av.Parent = row
			local avs = Instance.new("UIStroke", av)
			avs.Color = C.line
			avs.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

			local name = Instance.new("TextLabel")
			name.Size = UDim2.new(1, -120, 0, 14)
			name.Position = UDim2.fromOffset(40, 3)
			name.BackgroundTransparency = 1
			name.Text = plr.DisplayName
			name.TextXAlignment = Enum.TextXAlignment.Left
			name.TextTruncate = Enum.TextTruncate.AtEnd
			styleText(name, uiFont.Size, C.text)
			name.Parent = row

			local sub = Instance.new("TextLabel")
			sub.Size = UDim2.new(1, -120, 0, 12)
			sub.Position = UDim2.fromOffset(40, 18)
			sub.BackgroundTransparency = 1
			sub.Text = "@" .. plr.Name
			sub.TextXAlignment = Enum.TextXAlignment.Left
			sub.TextTruncate = Enum.TextTruncate.AtEnd
			styleText(sub, math.max(uiFont.Size - 2, 9), C.dim)
			sub.Parent = row

			local x = -8
			if Spectate.Target == plr then
				local spec = Instance.new("TextLabel")
				spec.Size = UDim2.fromOffset(30, 18)
				spec.Position = UDim2.new(1, x - 30, 0.5, -9)
				spec.BackgroundTransparency = 1
				spec.Text = "SPEC"
				styleText(spec, math.max(uiFont.Size - 3, 8), ACCENT)
				spec.Parent = row
				x = x - 34
			end
			for k = #TAGS, 1, -1 do
				local tg = TAGS[k]
				if PlayerData:Has(tg.key, plr) then
					local chip = Instance.new("TextLabel")
					chip.Size = UDim2.fromOffset(18, 18)
					chip.Position = UDim2.new(1, x - 18, 0.5, -9)
					chip.BackgroundColor3 = C.bg
					chip.BorderSizePixel = 0
					chip.Text = tg.text
					styleText(chip, uiFont.Size, tg.color)
					chip.Parent = row
					local cs = Instance.new("UIStroke", chip)
					cs.Color = tg.color
					cs.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
					x = x - 22
				end
			end

			local btn = Instance.new("TextButton")
			btn.Size = UDim2.fromScale(1, 1)
			btn.BackgroundTransparency = 1
			btn.Text = ""
			btn.Parent = row
			btn.MouseEnter:Connect(function()
				if plr ~= Selected then row.BackgroundColor3 = C.hover end
			end)
			btn.MouseLeave:Connect(function() row.BackgroundColor3 = base end)
			btn.MouseButton1Click:Connect(function()
				Selected = (Selected == plr) and nil or plr
				refresh()
			end)
		end
	end

	ListSection:Textbox({
		Name = "Search",
		Flag = "PlayerSearch",
		Placeholder = "name or display name",
		Default = "",
		Callback = function(text)
			Query = text or ""
			refresh()
		end
	})

	SelectedLabel = ListSection:Label({Name = "selected: none"})
	ListSection:Label({Name = TOKEN})

	local function need()
		if not Selected or not Selected.Parent then
			notify("Select a player first", Color3.fromRGB(255, 80, 80))
			return false
		end
		return true
	end

	ActionSection:Button({
		Name = "Spectate / stop",
		Callback = function()
			if Spectate.Target then
				Spectate:Stop()
				notify("Stopped spectating")
			elseif need() then
				Spectate.Target = Selected
				notify("Spectating " .. Selected.Name)
			end
			refresh()
		end
	})

	for _, t in ipairs({
		{"Toggle priority",  "Priority",  Color3.fromRGB(255, 0, 0)},
		{"Toggle whitelist", "Whitelist", Color3.fromRGB(15, 131, 255)},
	}) do
		ActionSection:Button({
			Name = t[1],
			Callback = function()
				if not need() then return end
				local on = PlayerData:Toggle(t[2], Selected)
				notify(Selected.Name .. ": " .. t[2] .. (on and " ON" or " OFF"), t[3])
				refresh()
			end
		})
	end

	ActionSection:Button({
		Name = "Clear all tags",
		Callback = function()
			PlayerData.Priority, PlayerData.Whitelist, PlayerData = {}, {},
			notify("All tags cleared")
			refresh()
		end
	})

        	ActionSection2:Label({Name = "Whitelist color"}):Colorpicker({
		Name = "Whitelist color",
		Flag = "whitelistcolor",
		Default = Color3.fromRGB(15, 131, 255),
		Callback = function(v) end
	})

        ActionSection2:Label({Name = "Priority color"}):Colorpicker({
		Name = "Priority color",
		Flag = "prioritycolor",
		Default = Color3.fromRGB(255, 0, 0),
		Callback = function(v) end
	})

	task.spawn(function()
		local d = waitLabel(TOKEN, 30)
		if not d then
			return
		end

		uiFont.Face = d.FontFace
		uiFont.Size = d.TextSize > 0 and d.TextSize or 12

		local container, hide = d.Parent, d
		if not container:FindFirstChildWhichIsA("UIListLayout") and container.Parent then
			hide = container
			container = container.Parent
		end

		local holder = Instance.new("Frame")
		holder.Name = "PlayerListHolder"
		holder.Size = UDim2.new(1, -10, 0, LIST_HEIGHT)
		holder.BackgroundColor3 = C.bg
		holder.BorderSizePixel = 0
		holder.LayoutOrder = hide.LayoutOrder
		holder.ZIndex = hide.ZIndex
		holder.Parent = container
		local hs = Instance.new("UIStroke", holder)
		hs.Color = C.line
		hs.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

		scroll = Instance.new("ScrollingFrame")
		scroll.Size = UDim2.new(1, -8, 1, -8)
		scroll.Position = UDim2.fromOffset(4, 4)
		scroll.BackgroundTransparency = 1
		scroll.BorderSizePixel = 0
		scroll.ScrollBarThickness = 2
		scroll.ScrollBarImageColor3 = ACCENT
		scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
		scroll.CanvasSize = UDim2.new()
		scroll.Parent = holder
		local lay = Instance.new("UIListLayout", scroll)
		lay.Padding = UDim.new(0, 3)
		lay.SortOrder = Enum.SortOrder.LayoutOrder

		hide.Visible = false
		refresh()
	end)

	bind(Players.PlayerAdded, function() task.defer(refresh) end)
	bind(Players.PlayerRemoving, function(p)
		if Selected == p then Selected = nil end
		task.defer(refresh)
	end)
end

------------------------------------------------------------
-- ESP
------------------------------------------------------------
do
	local EspSection = VisualsPage:Section({Name = "esp", Side = 2})
	local EspSettingsSection = VisualsPage:Section({Name = "esp settings", Side = 2})
	local PreviewSection = VisualsPage:Section({Name = "preview", Side = 1})

	-- настройки esp_table подключаем напрямую к UI
	local enemy_sets = esp_table.settings.enemy
	local enemy_main = esp_table.settings.enemy.main_settings

	local function icaca()
		for _, v in pairs(loaded_plrs) do
			if type(v) == "table" and type(v.forceupdate) == "function" then
				task.spawn(function()
						if type(v.forceupdate) == "function" then pcall(v.forceupdate, v) end
				end)
			end
		end
	end

	-- ENABLED
	EspSection:Toggle({
		Name = "Enabled", Flag = "EspEnabled", Default = false,
		Callback = function(v)
			enemy_sets.enabled = v
			icaca()
		end
	})

	-- BOX
	do
		local toggle = EspSection:Toggle({
			Name = "Box", Flag = "EspBox", Default = false,
			Callback = function(v) enemy_sets.box = v icaca() end
		})
		toggle:Colorpicker({
			Name = "Box color left", Flag = "EspBoxColorLeft",
			Default = Color3.fromRGB(255, 255, 255),
			Callback = function(c, a)
				enemy_sets.box_color[1] = c
				enemy_sets.box_color[3] = a or 0
				icaca()
			end
		})
		toggle:Colorpicker({
			Name = "Box color right", Flag = "EspBoxColorRight",
			Default = Color3.fromRGB(255, 255, 255),
			Callback = function(c)
				enemy_sets.box_color[2] = c
				icaca()
			end
		})
	end

    -- BOX FILL (two-color gradient)
    do
        local toggle = EspSection:Toggle({
            Name = "Box fill", Flag = "EspBoxFill", Default = false,
            Callback = function(v) enemy_sets.box_fill = v icaca() end
        })
        toggle:Colorpicker({
            Name = "Fill color left", Flag = "EspBoxFillColorLeft",
            Default = enemy_sets.box_fill_color[1],
            Callback = function(c, a)
                enemy_sets.box_fill_color[1] = c
                enemy_sets.box_fill_color[3] = a or 0.72
                icaca()
            end
        })
        toggle:Colorpicker({
            Name = "Fill color right", Flag = "EspBoxFillColorRight",
            Default = enemy_sets.box_fill_color[2],
            Callback = function(c, a)
                enemy_sets.box_fill_color[2] = c
                enemy_sets.box_fill_color[4] = a or 0.82
                icaca()
            end
        })
    end

    -- BOX GLOW (two-color gradient)
    do
        local toggle = EspSection:Toggle({
            Name = "Box glow", Flag = "EspBoxGlow", Default = false,
            Callback = function(v) enemy_sets.box_glow = v icaca() end
        })
        toggle:Colorpicker({
            Name = "Glow color left", Flag = "EspBoxGlowColorLeft",
            Default = enemy_sets.box_glow_color[1],
            Callback = function(c, a)
                enemy_sets.box_glow_color[1] = c
                enemy_sets.box_glow_color[3] = a or 0.25
                icaca()
            end
        })
        toggle:Colorpicker({
            Name = "Glow color right", Flag = "EspBoxGlowColorRight",
            Default = enemy_sets.box_glow_color[2],
            Callback = function(c, a)
                enemy_sets.box_glow_color[2] = c
                enemy_sets.box_glow_color[4] = a or 0.25
                icaca()
            end
        })
    end

	-- HEALTH BAR
	do
		local toggle = EspSection:Toggle({
			Name = "Health bar", Flag = "EspHealthBar", Default = false,
			Callback = function(v) enemy_sets.health_bar = v icaca() end
		})
		toggle:Colorpicker({
			Name = "Bar top", Flag = "EspHpTop",
			Default = Color3.fromRGB(0, 255, 0),
			Callback = function(c) enemy_sets.health_bar_color[1] = c icaca() end
		})
		toggle:Colorpicker({
			Name = "Bar bottom", Flag = "EspHpBot",
			Default = Color3.fromRGB(255, 0, 0),
			Callback = function(c) enemy_sets.health_bar_color[2] = c icaca() end
		})
	end

    EspSettingsSection:Slider({
        Name = "HP bar thickness", Flag = "EspHpThickness",
        Min = 1, Max = 3, Default = 3, Decimals = 1, Suffix = "px",
        Callback = function(v)
            enemy_sets.health_bar_thickness = math.clamp(v, 1, 3)
            icaca()
        end
    })

	-- NAME
	do
		local toggle = EspSection:Toggle({
			Name = "Name", Flag = "EspName", Default = false,
			Callback = function(v) enemy_sets.name = v icaca() end
		})
		toggle:Colorpicker({
			Name = "Name color", Flag = "EspNameColor",
			Default = Color3.new(1, 1, 1),
			Callback = function(c, a)
				enemy_sets.name_color = {c, a or 0}
				icaca()
			end
		})
	end

	-- DISTANCE
	do
		local toggle = EspSection:Toggle({
			Name = "Distance", Flag = "EspDist", Default = false,
			Callback = function(v) enemy_sets.distance = v icaca() end
		})
		toggle:Colorpicker({
			Name = "Distance color", Flag = "EspDistColor",
			Default = Color3.new(1, 1, 1),
			Callback = function(c, a)
				enemy_sets.distance_color = {c, a or 0}
				icaca()
			end
		})
	end

	-- WEAPON
	do
		local toggle = EspSection:Toggle({
			Name = "Weapon", Flag = "EspWeapon", Default = false,
			Callback = function(v) enemy_sets.weapon = v icaca() end
		})
		toggle:Colorpicker({
			Name = "Weapon color", Flag = "EspWeaponColor",
			Default = Color3.new(1, 1, 1),
			Callback = function(c, a)
				enemy_sets.weapon_color = {c, a or 0}
				icaca()
			end
		})
	end

	-- HEALTH TEXT
	do
		local toggle = EspSection:Toggle({
			Name = "Health text", Flag = "EspHpText", Default = false,
			Callback = function(v) enemy_sets.health_text = v icaca() end
		})
		toggle:Colorpicker({
			Name = "Hp text color", Flag = "EspHpTextColor",
			Default = Color3.new(1, 1, 1),
			Callback = function(c, a)
				enemy_sets.health_text_color = {c, a or 0}
				icaca()
			end
		})
	end

	-- SKELETON
	do
		local toggle = EspSection:Toggle({
			Name = "Skeleton", Flag = "EspSkeleton", Default = false,
			Callback = function(v) enemy_sets.skeleton = v icaca() end
		})
		toggle:Colorpicker({
			Name = "Skeleton color", Flag = "EspSkeletonColor",
			Default = Color3.new(1, 1, 1),
			Callback = function(c, a)
				enemy_sets.skeleton_color = {c, a or 0}
				icaca()
			end
		})
	end

	EspSettingsSection:Slider({
		Name = "Skeleton update rate", Flag = "EspSkeletonRate",
		Min = 0, Max = 1, Default = 0.05, Decimals = 0.01, Suffix = " s",
		Callback = function(v)
			enemy_main.skeleton_rate = v <= 0 and 1e-10 or v
			icaca()
		end
	})

    -- FONT SETTINGS (callbacks ignore transient nil values and preserve last valid font)
    local fontItems = getEspFontItems()
    EspSettingsSection:Dropdown({
        Name = "Custom font", Flag = "EspCustomFont",
        Items = fontItems, Default = "Minecraftia",
        Callback = function(v)
            if type(v) ~= "string" or v == "" then return end
            local newFace, ok = loadEspFont(v)
            if not ok or not newFace then
                espFontLog("WARN", v, "primary font unchanged; load failed")
                return
            end
            ESP_FONT_NAME, ESP_FONT_FACE = v, newFace
            applyEspFontSettings()
            pcall(icaca)
        end
    })
    EspSettingsSection:Slider({
        Name = "Font size", Flag = "EspFontSize",
        Min = 8, Max = 24, Default = 12, Decimals = 1, Suffix = " px",
        Callback = function(v)
            if type(v) ~= "number" or v ~= v then return end
            ESP_FONT_SIZE = math.clamp(v, 8, 24)
            applyEspFontSettings()
            pcall(icaca)
        end
    })
    EspSettingsSection:Dropdown({
        Name = "Flags font", Flag = "EspFlagsFont",
        Items = fontItems, Default = "Minecraftia",
        Callback = function(v)
            if type(v) ~= "string" or v == "" then return end
            local newFace, ok = loadEspFont(v)
            if not ok or not newFace then
                espFontLog("WARN", v, "flags font unchanged; load failed")
                return
            end
            ESP_FLAGS_FONT_NAME, ESP_FLAGS_FONT_FACE = v, newFace
            applyEspFontSettings()
            pcall(icaca)
        end
    })
    EspSettingsSection:Slider({
        Name = "Flags font size", Flag = "EspFlagsFontSize",
        Min = 6, Max = 18, Default = 9, Decimals = 1, Suffix = " px",
        Callback = function(v)
            if type(v) ~= "number" or v ~= v then return end
            ESP_FLAGS_FONT_SIZE = math.clamp(v, 6, 18)
            applyEspFontSettings()
            pcall(icaca)
        end
    })

	-- CHAMS
	do
		EspSection:Toggle({
			Name = "Chams", Flag = "EspChams", Default = false,
			Callback = function(v) enemy_sets.chams = v icaca() end
		})
		EspSection:Label({Name = "Chams color"}):Colorpicker({
			Name = "Chams color", Flag = "EspChamsColor",
			Default = Color3.new(1, 1, 1),
			Callback = function(c, a)
				enemy_sets.chams_color = {c, a or 0}
				icaca()
			end
		})
		EspSection:Slider({
			Name = "Chams glow", Flag = "EspChamsGlow",
			Min = 0, Max = 10, Default = 2, Decimals = 0.1, Suffix = "x",
			Callback = function(v) enemy_sets.chams_glow_factor = v icaca() end
		})
	end

	-- FLAGS
	do
		EspSection:Toggle({
			Name = "Flags", Flag = "EspFlags", Default = false,
			Callback = function(v) enemy_sets.flags = v icaca() end
		})
		EspSection:Label({Name = "Flags color"}):Colorpicker({
			Name = "Flags color", Flag = "EspFlagsColor",
			Default = Color3.new(1, 1, 1),
			Callback = function(c, a)
				enemy_sets.flags_color = {c, a or 0}
				icaca()
			end
		})
		EspSection:Dropdown({
			Name = "Body flags", Flag = "EspBodyFlags",
			Items = {"IFake", "IBleed", "IConscious", "IPain", "IPulse", "IShock", "IAlarm"},
			Default = {},
			Multi = true,
			Callback = function(tbl)
				enemy_sets.body_flags = tbl
			end
		})
	end

	-- CHECKS
	EspSettingsSection:Dropdown({
		Name = "Checks", Flag = "EspChecks",
		Items = {"Team check", "Dead check", "Distance check"},
		Default = {"Dead check", "Distance check"},
		Multi = true,
		Callback = function(tbl)
			local map = {
				["Team check"] = "team_check",
				["Dead check"] = "dead_check",
				["Distance check"] = "dist_check",
			}
			for _, key in pairs(map) do enemy_main[key] = false end
			for _, name in pairs(tbl) do
				if map[name] then enemy_main[map[name]] = true end
			end
			icaca()
		end
	})

	EspSettingsSection:Slider({
		Name = "Max distance", Flag = "EspMaxDist",
		Min = 0, Max = 5000, Default = 1500, Decimals = 100, Suffix = " st",
		Callback = function(v) enemy_main.max_distance = v icaca() end
	})

	-- GRADIENT ROTATE: static gradient angle, controlled by its own slider
	EspSettingsSection:Toggle({
		Name = "Gradient rotate", Flag = "EspGradRotate", Default = false,
		Callback = function(v) enemy_main.gradient_rotate_enabled = v icaca() end
	})
	EspSettingsSection:Slider({
		Name = "Gradient rotate", Flag = "EspGradRotateAngle",
		Min = -180, Max = 180, Default = 0, Decimals = 1, Suffix = "°",
		Callback = function(v) enemy_main.gradient_rotate = v icaca() end
	})

	-- GRADIENT SPIN: animation toggle plus independent speed slider
	EspSettingsSection:Toggle({
		Name = "Gradient spin", Flag = "EspGradSpin", Default = false,
		Callback = function(v) enemy_main.gradient_spin = v icaca() end
	})
	EspSettingsSection:Slider({
		Name = "Gradient spin", Flag = "EspGradSpeed",
		Min = -180, Max = 180, Default = 0, Decimals = 1, Suffix = "°/s",
		Callback = function(v) enemy_main.gradient_speed = v icaca() end
	})
	-- HOLDER SPIN
	EspSettingsSection:Toggle({
		Name = "Holder spin", Flag = "EspHolderSpin", Default = false,
		Callback = function(v) enemy_main.holder_spin = v icaca() end
	})
	EspSettingsSection:Slider({
		Name = "Holder speed", Flag = "EspHolderSpeed",
		Min = -20, Max = 20, Default = 0, Decimals = 0.1, Suffix = "x",
		Callback = function(v) enemy_main.holder_speed = v * 18 icaca() end
	})

    	-- ARROWS UI
	local ArrowSection = VisualsPage:Section({Name = "arrows", Side = 2})

	ArrowSection:Toggle({
		Name = "Arrows", Flag = "EspArrows", Default = false,
		Callback = function(v)
			esp_table.arrow_settings.enabled = v
		end
	})

	ArrowSection:Label({Name = "arrow color"}):Colorpicker({
		Name = "Arrow color", Flag = "EspArrowColor",
		Default = Color3.new(1, 1, 1),
		Callback = function(c)
			esp_table.arrow_settings.color = c
		end
	})

	ArrowSection:Label({Name = "outline color"}):Colorpicker({
		Name = "Arrow outline", Flag = "EspArrowOutline",
		Default = Color3.new(0, 0, 0),
		Callback = function(c)
			esp_table.arrow_settings.outline_color = c
		end
	})

	ArrowSection:Toggle({
		Name = "Show distance", Flag = "EspArrowDist", Default = true,
		Callback = function(v)
			esp_table.arrow_settings.show_distance = v
		end
	})

	ArrowSection:Slider({
		Name = "Arrow size", Flag = "EspArrowSize",
		Min = 6, Max = 30, Default = 12, Decimals = 1, Suffix = "px",
		Callback = function(v)
			esp_table.arrow_settings.size = v
		end
	})

	ArrowSection:Slider({
		Name = "Edge distance", Flag = "EspArrowEdge",
		Min = 50, Max = 400, Default = 120, Decimals = 1, Suffix = "px",
		Callback = function(v)
			esp_table.arrow_settings.distance_from_edge = v
		end
	})

	ArrowSection:Toggle({
		Name = "Team check", Flag = "EspArrowTeam", Default = false,
		Callback = function(v)
			esp_table.arrow_settings.team_check = v
		end
	})

    	-- NPC ESP UI
	local NpcSection = VisualsPage:Section({Name = "npc esp", Side = 2})

	NpcSection:Toggle({
		Name = "Enabled", Flag = "NpcEspEnabled", Default = false,
		Callback = function(v) esp_table.npc_settings.enabled = v end
	})
	NpcSection:Toggle({
		Name = "Box", Flag = "NpcEspBox", Default = true,
		Callback = function(v) esp_table.npc_settings.box = v end
	})
	NpcSection:Label({Name = "box color"}):Colorpicker({
		Name = "Box color", Flag = "NpcEspBoxColor",
		Default = Color3.fromRGB(255, 128, 0),
		Callback = function(c) esp_table.npc_settings.box_color = c end
	})
	NpcSection:Label({Name = "box color 2"}):Colorpicker({
		Name = "Box color 2", Flag = "NpcEspBoxColor2",
		Default = Color3.fromRGB(255, 200, 0),
		Callback = function(c) esp_table.npc_settings.box_color2 = c end
	})
	NpcSection:Toggle({
		Name = "Name", Flag = "NpcEspName", Default = true,
		Callback = function(v) esp_table.npc_settings.name = v end
	})
	NpcSection:Label({Name = "name color"}):Colorpicker({
		Name = "Name color", Flag = "NpcEspNameColor",
		Default = Color3.fromRGB(255, 128, 0),
		Callback = function(c) esp_table.npc_settings.name_color = c end
	})
	NpcSection:Toggle({
		Name = "Distance", Flag = "NpcEspDist", Default = true,
		Callback = function(v) esp_table.npc_settings.distance = v end
	})
	NpcSection:Toggle({
		Name = "Health bar", Flag = "NpcEspHp", Default = true,
		Callback = function(v) esp_table.npc_settings.health_bar = v end
	})
	NpcSection:Label({Name = "hp color"}):Colorpicker({
		Name = "HP color", Flag = "NpcEspHpColor",
		Default = Color3.fromRGB(255, 128, 0),
		Callback = function(c) esp_table.npc_settings.hp_color = c end
	})
	NpcSection:Toggle({
		Name = "Dead check", Flag = "NpcEspDead", Default = true,
		Callback = function(v) esp_table.npc_settings.dead_check = v end
	})
	NpcSection:Toggle({
		Name = "Distance check", Flag = "NpcEspDistCheck", Default = true,
		Callback = function(v) esp_table.npc_settings.dist_check = v end
	})
	NpcSection:Slider({
		Name = "Max distance", Flag = "NpcEspMaxDist",
		Min = 0, Max = 5000, Default = 1500, Decimals = 100, Suffix = " st",
		Callback = function(v) esp_table.npc_settings.max_distance = v end
	})

	------------------------------------------------------------
	-- PREVIEW
	------------------------------------------------------------

    PreviewSection:Label({Name = "no model issue? (wait your spawn)"})

	local TOKEN = "__esp_preview_" .. math.random(1e8, 9e8) .. "__"
	PreviewSection:Label({Name = TOKEN})

	local PREVIEW_H = 340
	local LINE = Color3.fromRGB(38, 38, 38)
	local BG   = Color3.fromRGB(12, 12, 12)

	task.spawn(function()
		local d = waitLabel(TOKEN, 30)
		if not d then warn("[esp preview] label not found") return end

		local fontFace = ESP_FONT_FACE or d.FontFace or ESP_FONT_FALLBACK
		local fontSize = ESP_FONT_SIZE or (d.TextSize > 0 and d.TextSize or 12)

		local cont, hide = d.Parent, d
		if not cont:FindFirstChildWhichIsA("UIListLayout") and cont.Parent then
			hide = cont
			cont = cont.Parent
		end

		-- внешний holder
		local holder = Instance.new("Frame")
		holder.Size = UDim2.new(1, -10, 0, PREVIEW_H)
		holder.BackgroundColor3 = BG
		holder.BorderSizePixel = 0
		holder.LayoutOrder = hide.LayoutOrder
		holder.ZIndex = hide.ZIndex
		holder.Parent = cont
		local hs = Instance.new("UIStroke", holder)
		hs.Color = LINE
		hs.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

		-- ViewportFrame для рендера клона персонажа
		local vp = Instance.new("ViewportFrame")
		vp.Size = UDim2.new(1, -8, 1, -8)
		vp.Position = UDim2.fromOffset(4, 4)
		vp.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
		vp.BorderSizePixel = 0
		vp.Ambient = Color3.fromRGB(190, 190, 190)
		vp.LightColor = Color3.new(1, 1, 1)
		vp.LightDirection = Vector3.new(0.3, -0.6, 0.7)
		vp.Parent = holder

		local vpCam = Instance.new("Camera")
		vpCam.FieldOfView = 35
		vpCam.Parent = vp
		vp.CurrentCamera = vpCam

		-- оверлей для ESP поверх ViewportFrame
		local overlay = Instance.new("Frame")
		overlay.Size = UDim2.fromScale(1, 1)
		overlay.BackgroundTransparency = 1
		overlay.ClipsDescendants = true
		overlay.ZIndex = vp.ZIndex + 1
		overlay.Parent = holder

		----------------------------------------------------
		-- вспомогательные функции проекции в overlay
		----------------------------------------------------
		local function projectToOverlay(worldPos)
			local W = vp.AbsoluteSize.X
			local H = vp.AbsoluteSize.Y
			local l = vpCam.CFrame:PointToObjectSpace(worldPos)
			if l.Z >= -0.01 then return nil end
			local t = math.tan(math.rad(vpCam.FieldOfView / 2))
			local x = l.X / (-l.Z) / (t * (W / H))
			local y = l.Y / (-l.Z) / t
			return Vector2.new((x * 0.5 + 0.5) * W, (0.5 - y * 0.5) * H)
		end

		local function mkLabel(anchorX, anchorY)
			local t = Instance.new("TextLabel")
			t.BackgroundTransparency = 1
			t.FontFace = fontFace
			t.TextSize = fontSize
			t.TextStrokeTransparency = 0.4
			t.AutomaticSize = Enum.AutomaticSize.XY
			t.Size = UDim2.fromOffset(0, 0)
			t.AnchorPoint = Vector2.new(anchorX or 0.5, anchorY or 0)
			t.ZIndex = overlay.ZIndex + 1
			t.Parent = overlay
            table.insert(ESP_PREVIEW_LABELS, t)
			return t
		end

		----------------------------------------------------
		-- ESP-элементы оверлея
		----------------------------------------------------

		-- рамка (outline + inline)
		local boxOutlineFrame = Instance.new("Frame")
		boxOutlineFrame.BackgroundTransparency = 1
		boxOutlineFrame.ZIndex = overlay.ZIndex
		boxOutlineFrame.Parent = overlay
		local boxOutlineStroke = Instance.new("UIStroke", boxOutlineFrame)
		boxOutlineStroke.Color = Color3.new(0, 0, 0)
		boxOutlineStroke.Thickness = 3
		boxOutlineStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		boxOutlineStroke.LineJoinMode = Enum.LineJoinMode.Miter

		local boxFrame = Instance.new("Frame")
		boxFrame.BackgroundTransparency = 1
		boxFrame.ZIndex = overlay.ZIndex + 1
		boxFrame.Parent = overlay

		local boxGrad = Instance.new("UIGradient", boxFrame)

		local boxStroke = Instance.new("UIStroke", boxFrame)
		boxStroke.Thickness = 1
		boxStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		boxStroke.LineJoinMode = Enum.LineJoinMode.Miter

		-- текстовые метки
		local nameLabel   = mkLabel(0.5, 1)  -- над рамкой
		local distLabel   = mkLabel(0.5, 0)  -- под рамкой
		local weapLabel   = mkLabel(0.5, 0)  -- под distLabel

		-- HP bar
		local hpBack = Instance.new("Frame")
		hpBack.BackgroundColor3 = Color3.new(0, 0, 0)
		hpBack.BorderSizePixel = 0
		hpBack.ZIndex = overlay.ZIndex + 1
		hpBack.Parent = overlay

		local hpOutStroke = Instance.new("UIStroke", hpBack)
		hpOutStroke.Color = Color3.new(0, 0, 0)
		hpOutStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

		local hpFill = Instance.new("Frame")
		hpFill.AnchorPoint = Vector2.new(0, 1)
		hpFill.Position = UDim2.new(0, 0, 1, 0)
		hpFill.BorderSizePixel = 0
		hpFill.ZIndex = overlay.ZIndex + 2
		hpFill.Parent = hpBack

		local hpGrad = Instance.new("UIGradient", hpFill)
		hpGrad.Rotation = 90

		-- HP text
		local hpText = mkLabel(1, 0)
		hpText.TextXAlignment = Enum.TextXAlignment.Right

		----------------------------------------------------
		-- клон персонажа
		----------------------------------------------------
		local model, parts, angle = nil, {}, 0

		local function buildModel()
			if model then model:Destroy() model = nil end
			parts = {}
			local char = LocalPlayer.Character
			if not char then return end
			pcall(function() char.Archivable = true end)
			local c = char:Clone()
			if not c then return end
			for _, x in ipairs(c:GetDescendants()) do
				if x:IsA("BaseScript") then x:Destroy()
				elseif x:IsA("BasePart") then
					x.LocalTransparencyModifier = 0
					x.Anchored = true
				end
			end
			local hum = c:FindFirstChildOfClass("Humanoid")
			if hum then hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None end
			c.Parent = vp
			c:PivotTo(CFrame.new(0, 0, 0))

			for _, x in ipairs(c:GetDescendants()) do
				if x:IsA("BasePart") and x.Transparency < 0.99 and not x:FindFirstAncestorOfClass("Tool") then
					table.insert(parts, x)
				end
			end

			local cf, sz = c:GetBoundingBox()
			local dist = (sz.Y / 2) / math.tan(math.rad(vpCam.FieldOfView / 2)) * 1.4 + sz.Z / 2
			vpCam.CFrame = CFrame.lookAt(cf.Position + Vector3.new(0, 0, -dist), cf.Position)
			model = c
		end

		task.spawn(function()
			if not LocalPlayer.Character then LocalPlayer.CharacterAdded:Wait() end
			task.wait(0.5)
			buildModel()
		end)
		bind(LocalPlayer.CharacterAdded, function()
			task.wait(1)
			buildModel()
		end)

		----------------------------------------------------
		-- рендер ESP поверх ViewportFrame
		----------------------------------------------------
		bind(RunService.RenderStepped, function(dt)
			local sg = holder:FindFirstAncestorWhichIsA("ScreenGui")
			if not model or not sg or not sg.Enabled then return end

			local W = vp.AbsoluteSize.X
			local H = vp.AbsoluteSize.Y
			if W <= 0 or H <= 0 then return end

			-- вращение
			angle = angle + dt * 0.8
			model:PivotTo(CFrame.new(0, 0, 0) * CFrame.Angles(0, angle, 0))

			-- bounding box через части
			local minX, minY, maxX, maxY = math.huge, math.huge, -math.huge, -math.huge
			for _, part in ipairs(parts) do
				if part.Parent then
					local cf = part.CFrame
					local s = part.Size / 2
					for sx = -1, 1, 2 do
						for sy = -1, 1, 2 do
							for sz = -1, 1, 2 do
								local p = projectToOverlay(cf * Vector3.new(s.X*sx, s.Y*sy, s.Z*sz))
								if p then
									minX = math.min(minX, p.X)
									minY = math.min(minY, p.Y)
									maxX = math.max(maxX, p.X)
									maxY = math.max(maxY, p.Y)
								end
							end
						end
					end
				end
			end
			if minX == math.huge then return end

			local pad = 3
			local bx  = minX - pad
			local by  = minY - pad
			local bw  = maxX - minX + pad * 2
			local bh  = maxY - minY + pad * 2

			local sets = enemy_sets

			--------------------------------------------
			-- рамка
			--------------------------------------------
			local showBox = sets.box
			boxFrame.Visible = showBox
			boxOutlineFrame.Visible = showBox
			if showBox then
				boxFrame.Position    = UDim2.fromOffset(bx, by)
				boxFrame.Size        = UDim2.fromOffset(bw, bh)
				boxOutlineFrame.Position = UDim2.fromOffset(bx, by)
				boxOutlineFrame.Size     = UDim2.fromOffset(bw, bh)

				boxGrad.Color = ColorSequence.new{
					ColorSequenceKeypoint.new(0, sets.box_color[1]),
					ColorSequenceKeypoint.new(1, sets.box_color[2])
				}
				-- Box rotate sets a static gradient angle; it does not animate.
				boxGrad.Rotation = sets.box_rotation
				boxStroke.Transparency = sets.box_color[3] or 0
				boxOutlineStroke.Transparency = sets.box_color[3] or 0
			end

			--------------------------------------------
			-- имя над рамкой
			--------------------------------------------
			nameLabel.Visible = sets.name
			if sets.name then
				nameLabel.Text = LocalPlayer.Name
				nameLabel.TextColor3 = sets.name_color[1]
				nameLabel.TextTransparency = sets.name_color[2] or 0
				nameLabel.Position = UDim2.fromOffset(bx + bw / 2, by - 2)
			end

			--------------------------------------------
			-- дистанция под рамкой
			--------------------------------------------
			distLabel.Visible = sets.distance
			local belowY = by + bh + 2
			if sets.distance then
				distLabel.Text = "25m"
				distLabel.TextColor3 = (sets.distance_color or {Color3.new(1,1,1)})[1]
				distLabel.TextTransparency = (sets.distance_color or {Color3.new(1,1,1), 0})[2] or 0
				distLabel.Position = UDim2.fromOffset(bx + bw / 2, belowY)
				belowY = belowY + fontSize + 2
			end

			--------------------------------------------
			-- оружие
			--------------------------------------------
			weapLabel.Visible = sets.weapon
			if sets.weapon then
				local char = LocalPlayer.Character
				local tool = char and char:FindFirstChildOfClass("Tool")
				weapLabel.Text = tool and tool.Name or "none"
				weapLabel.TextColor3 = (sets.weapon_color or {Color3.new(1,1,1)})[1]
				weapLabel.TextTransparency = (sets.weapon_color or {Color3.new(1,1,1), 0})[2] or 0
				weapLabel.Position = UDim2.fromOffset(bx + bw / 2, belowY)
			end

			--------------------------------------------
			-- HP bar слева
			--------------------------------------------
			hpBack.Visible = sets.health_bar
			if sets.health_bar then
				local char = LocalPlayer.Character
				local hum  = char and char:FindFirstChildOfClass("Humanoid")
				local ratio = hum and math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1) or 1

				local hpThickness = math.clamp(sets.health_bar_thickness or 3, 1, 3)
				hpBack.Position = UDim2.fromOffset(bx - hpThickness - 2, by)
				hpBack.Size     = UDim2.fromOffset(hpThickness, bh)
				hpFill.Size     = UDim2.new(1, 0, ratio, 0)

				hpGrad.Color = ColorSequence.new{
					ColorSequenceKeypoint.new(0, sets.health_bar_color[1]),
					ColorSequenceKeypoint.new(1, sets.health_bar_color[2])
				}

				-- HP текст
				hpText.Visible = sets.health_text
				if sets.health_text then
					hpText.Text = hum and tostring(math.floor(hum.Health)) or "???"
					hpText.TextColor3 = (sets.health_text_color or {Color3.new(1,1,1)})[1]
					hpText.TextTransparency = (sets.health_text_color or {Color3.new(1,1,1), 0})[2] or 0
					hpText.Position = UDim2.fromOffset(bx - 8, by + bh * (1 - ratio) - fontSize)
				end
			else
				hpBack.Visible = false
				hpText.Visible = false
			end
		end)

		hide.Visible = false
	end)

	-- запускаем сам ESP
	esp_table.load()
end

------------------------------------------------------------
-- VISUALS : viewmodel
------------------------------------------------------------
do
	local VmSection = VisualsPage:Section({Name = "viewmodel", Side = 1})

	local MATERIALS = {"ForceField", "Neon", "Glass", "SmoothPlastic", "Plastic"}

	local VM = {
		Offset = false, X = 0, Y = 0, Z = 0,
		ArmsChams = false, ArmsColor = Color3.fromRGB(255, 255, 255), ArmsMat = "ForceField",
		GunChams = false,  GunColor  = Color3.fromRGB(255, 255, 255), GunMat  = "ForceField",
	}

	local weak = {__mode = "k"}
	local armSA = setmetatable({}, weak)   -- [SurfaceAppearance] = part (клоны рук)
	local gunCache = setmetatable({}, weak) -- [part] = {Color, Material, TextureID}
	local gunSA = setmetatable({}, weak)   -- [SurfaceAppearance] = parent (оружие)
	local armsWasOn = false

	local function isSkin(i)
		return i:IsA("SurfaceAppearance") or i:IsA("Decal") or i:IsA("Texture")
	end

	-- вернуть руки как были (берём свойства с настоящих частей)
	local function restoreArms(model)
		local char = LocalPlayer.Character
		if model and char then
			for _, p in ipairs(model:GetChildren()) do
				if p:IsA("BasePart") then
					local real = char:FindFirstChild(p.Name, true)
					if real and real:IsA("BasePart") then
						p.Material = real.Material
						if p:IsA("MeshPart") and real:IsA("MeshPart") then
							p.TextureID = real.TextureID
						end
					end
				end
			end
		end
		for sa, part in pairs(armSA) do
			pcall(function() if part and part.Parent then sa.Parent = part end end)
			armSA[sa] = nil
		end
	end

	local function restoreGun()
		for part, o in pairs(gunCache) do
			pcall(function()
				part.Color = o.Color
				part.Material = o.Material
				if o.TextureID then part.TextureID = o.TextureID end
			end)
			gunCache[part] = nil
		end
		for sa, parent in pairs(gunSA) do
			pcall(function() if parent and parent.Parent then sa.Parent = parent end end)
			gunSA[sa] = nil
		end
	end

	local function step()
		local cam = workspace.CurrentCamera
		if not cam then return end

		-- руки
		local model = cam:FindFirstChild("IViewmodelArms")
		if model then
			local shift
			if VM.Offset then
				shift = cam.CFrame:VectorToWorldSpace(Vector3.new(VM.X, VM.Y, VM.Z))
			end
			local mat = Enum.Material[VM.ArmsMat]

			for _, p in ipairs(model:GetChildren()) do
				if p:IsA("BasePart") then
					if shift then p.CFrame += shift end
					if VM.ArmsChams then
						p.Color = VM.ArmsColor
						p.Material = mat
						if p:IsA("MeshPart") and p.TextureID ~= "" then p.TextureID = "" end
						for _, c in ipairs(p:GetChildren()) do
							if isSkin(c) then
								if c:IsA("SurfaceAppearance") then armSA[c] = p end
								c.Parent = nil
							end
						end
					end
				elseif p:IsA("Shirt") and VM.ArmsChams then
					if p.ShirtTemplate ~= "" then p.ShirtTemplate = "" end
				end
			end

			if armsWasOn and not VM.ArmsChams then restoreArms(model) end
		end
		armsWasOn = VM.ArmsChams

		if VM.GunChams then
			local char = LocalPlayer.Character
			local held = char and char:FindFirstChild("IHeld")
			if held then
				local gmat = Enum.Material[VM.GunMat]
				for _, d in ipairs(held:GetDescendants()) do
					if d:IsA("BasePart") then
						if not gunCache[d] then
							gunCache[d] = {
								Color = d.Color, Material = d.Material,
								TextureID = d:IsA("MeshPart") and d.TextureID or nil,
							}
						end
						d.Color = VM.GunColor
						d.Material = gmat
						if d:IsA("MeshPart") and d.TextureID ~= "" then d.TextureID = "" end
					elseif d:IsA("SurfaceAppearance") then
						gunSA[d] = d.Parent
						d.Parent = nil
					end
				end
			end
		end
	end

	RunService:BindToRenderStep("MSViewmodel", Enum.RenderPriority.Camera.Value + 10, step)

	------------------------------------------------------------
	-- UI
	------------------------------------------------------------
	VmSection:Toggle({
		Name = "Hand position", Flag = "viewmodel", Default = false,
		Callback = function(v) VM.Offset = v end
	})

	VmSection:Slider({
		Name = "Offset X", Flag = "viewmodel_offset_x",
		Min = -3, Max = 3, Default = 0, Decimals = 0.1, Suffix = " st",
		Callback = function(v) VM.X = v end
	})

	VmSection:Slider({
		Name = "Offset Y", Flag = "viewmodel_offset_y",
		Min = -3, Max = 3, Default = 0, Decimals = 0.1, Suffix = " st",
		Callback = function(v) VM.Y = v end
	})

	VmSection:Slider({
		Name = "Offset Z", Flag = "viewmodel_offset_z",
		Min = -3, Max = 3, Default = 0, Decimals = 0.1, Suffix = " st",
		Callback = function(v) VM.Z = v end
	})

	VmSection:Toggle({
		Name = "Arms chams", Flag = "armschams", Default = false,
		Callback = function(v) VM.ArmsChams = v end
	})

	VmSection:Label({Name = "arms color"}):Colorpicker({
		Name = "Arms color", Flag = "armscolor",
		Default = VM.ArmsColor,
		Callback = function(c) VM.ArmsColor = c end
	})

	VmSection:Dropdown({
		Name = "Arms material", Flag = "armsmaterial",
		Items = MATERIALS, Default = "ForceField", Multi = false,
		Callback = function(v) VM.ArmsMat = v end
	})

	VmSection:Toggle({
		Name = "Weapon chams", Flag = "chams", Default = false,
		Callback = function(v)
			VM.GunChams = v
			if not v then restoreGun() end
		end
	})

	VmSection:Label({Name = "Weapon color"}):Colorpicker({
		Name = "Weapon", Flag = "guncolor",
		Default = VM.GunColor,
		Callback = function(c) VM.GunColor = c end
	})

	VmSection:Dropdown({
		Name = "Weapon material", Flag = "Weaponmaterial",
		Items = MATERIALS, Default = "ForceField", Multi = false,
		Callback = function(v) VM.GunMat = v end
	})

	if getgenv then
		local old = getgenv().MS_CLEANUP
		getgenv().MS_CLEANUP = function()
			pcall(function() RunService:UnbindFromRenderStep("MSViewmodel") end)
			pcall(restoreGun)
			pcall(restoreArms, workspace.CurrentCamera and workspace.CurrentCamera:FindFirstChild("IViewmodelArms"))
			if old then pcall(old) end
		end
	end
end



------------------------------------------------------------
-- VISUALS hit log
------------------------------------------------------------
do
	local HitSection = VisualsPage:Section({Name = "hit log", Side = 1})

	local DEFAULT_FORMAT = "hit {user} {hp} hp in {part}"

	local Hit = {
		Enabled = false,
		Debug = false,
		Format = DEFAULT_FORMAT,
		TextColor = Color3.fromRGB(255, 255, 255),
		ValueColor = Color3.fromRGB(176, 176, 209),
		Highlight = true,
		OnlyAimed = true,
		Fov = 10,
		ShowFov = false,
		Size = 14,
		Duration = 4,
		MaxLines = 8,
		X = 10,
		Y = 44,
		Window = 0.8,
	}

	-- GUI
	local gui = Instance.new("ScreenGui")
	gui.Name = "HitLog"
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 998
	gui.Parent = (gethui and gethui()) or CoreGui

	local list = Instance.new("Frame")
	list.BackgroundTransparency = 1
	list.AutomaticSize = Enum.AutomaticSize.XY
	list.Size = UDim2.fromOffset(0, 0)
	list.Position = UDim2.fromOffset(Hit.X, Hit.Y)
	list.Parent = gui
	local layout = Instance.new("UIListLayout", list)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 2)

	local function setFont(l)
		if Library.Font then l.FontFace = Library.Font else l.Font = Enum.Font.Code end
	end

	local circle = Instance.new("Frame")
	circle.AnchorPoint = Vector2.new(0.5, 0.5)
	circle.Position = UDim2.fromScale(0.5, 0.5)
	circle.BackgroundTransparency = 1
	circle.Visible = false
	circle.Parent = gui
	Instance.new("UICorner", circle).CornerRadius = UDim.new(0.5, 0)
	local circleStroke = Instance.new("UIStroke", circle)
	circleStroke.Thickness = 1
	circleStroke.Color = Color3.fromRGB(255, 255, 255)
	circleStroke.Transparency = 0.4

	local liveLabel = Instance.new("TextLabel")
	liveLabel.BackgroundTransparency = 1
	liveLabel.AnchorPoint = Vector2.new(0.5, 0)
	liveLabel.Position = UDim2.new(0.5, 0, 0.5, 26)
	liveLabel.AutomaticSize = Enum.AutomaticSize.XY
	liveLabel.Size = UDim2.fromOffset(0, 0)
	liveLabel.TextSize = 14
	liveLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	liveLabel.TextStrokeTransparency = 0.3
	liveLabel.Visible = false
	setFont(liveLabel)
	liveLabel.Parent = gui

	local order = 0

	local function hex(c)
		return string.format("#%02x%02x%02x", math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5))
	end

	local function esc(s)
		return (tostring(s):gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"))
	end

	-- {user} {display} {hp} {left} {part} {raw}
	local function build(fmt, vals)
		return (esc(fmt):gsub("{(%w+)}", function(k)
			local v = vals[k:lower()]
			if v == nil then return nil end
			v = esc(v)
			if Hit.Highlight then
				return '<font color="' .. hex(Hit.ValueColor) .. '">' .. v .. "</font>"
			end
			return v
		end))
	end

	local function addLine(vals)
		order = order + 1

		local t = Instance.new("TextLabel")
		t.BackgroundTransparency = 1
		t.AutomaticSize = Enum.AutomaticSize.XY
		t.Size = UDim2.fromOffset(0, 0)
		t.LayoutOrder = order
		t.RichText = true
		t.TextXAlignment = Enum.TextXAlignment.Left
		t.TextColor3 = Hit.TextColor
		t.TextSize = Hit.Size
		t.TextStrokeColor3 = Color3.new(0, 0, 0)
		t.TextStrokeTransparency = 0.3
		setFont(t)
		t.Text = build(Hit.Format, vals)
		t.Parent = list

		local lines = {}
		for _, c in ipairs(list:GetChildren()) do
			if c:IsA("TextLabel") then table.insert(lines, c) end
		end
		table.sort(lines, function(a, b) return a.LayoutOrder < b.LayoutOrder end)
		while #lines > Hit.MaxLines do
			table.remove(lines, 1):Destroy()
		end

		task.delay(Hit.Duration, function()
			if t.Parent then t:Destroy() end
		end)
	end

	-- test fov check
	local lastShot = 0
	local aimedPlayer, aimedPart, aimedRaw = nil, nil, nil

	local function partName(n)
		n = n:lower()
		if n:find("head") then return "head" end
		if n:find("leg") or n:find("foot") then return "leg" end
		if n:find("arm") or n:find("hand") then return "arm" end
		return "torso"
	end

	local function fovRadiusPx()
		local cam = workspace.CurrentCamera
		return (cam.ViewportSize.Y / 2)
			* math.tan(math.rad(Hit.Fov / 2))
			/ math.tan(math.rad(cam.FieldOfView / 2))
	end

	local function castCrosshair()
		local cam = workspace.CurrentCamera
		local center = cam.ViewportSize / 2
		local bestPlr, bestRaw
		local bestDist = fovRadiusPx()

		for _, plr in ipairs(Players:GetPlayers()) do
			if plr ~= LocalPlayer and plr.Character then
				for _, part in ipairs(plr.Character:GetChildren()) do
					if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
						local sp, on = cam:WorldToViewportPoint(part.Position)
						if on then
							local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
							if d < bestDist then
								bestPlr, bestRaw, bestDist = plr, part.Name, d
							end
						end
					end
				end
			end
		end

		return bestPlr, bestRaw
	end

	local function sampleCrosshair()
		local plr, raw = castCrosshair()
		if plr then
			aimedPlayer, aimedPart, aimedRaw = plr, partName(raw), raw
		else
			aimedPlayer, aimedPart, aimedRaw = nil, nil, nil
		end
	end

	bind(UIS.InputBegan, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			lastShot = tick()
			sampleCrosshair()
		end
	end)

	bind(RunService.RenderStepped, function()
		if Hit.Enabled and tick() - lastShot < Hit.Window then
			local pl, pt, pr = aimedPlayer, aimedPart, aimedRaw
			sampleCrosshair()
			if not aimedPlayer then aimedPlayer, aimedPart, aimedRaw = pl, pt, pr end
		end
	end)

	bind(RunService.RenderStepped, function()
		circle.Visible = Hit.ShowFov
		if Hit.ShowFov then
			local d = fovRadiusPx() * 2
			circle.Size = UDim2.fromOffset(d, d)
		end

		liveLabel.Visible = Hit.Debug
		if Hit.Debug then
			local plr, raw = castCrosshair()
			liveLabel.Text = plr and (plr.Name .. " > " .. raw) or "no target"
		end
	end)

	local function watch(plr)
		if plr == LocalPlayer then return end

		local function hook(char)
			local hum = char:WaitForChild("Humanoid", 5)
			if not hum then return end
			local last = hum.Health

			hum.HealthChanged:Connect(function(new)
				local dmg = last - new
				last = new
				if not Hit.Enabled or dmg < 0.5 then return end
				if tick() - lastShot > Hit.Window then return end
				if Hit.OnlyAimed and aimedPlayer ~= plr then return end

				local raw = (aimedPlayer == plr and aimedRaw) or "unknown"
				local part = (aimedPlayer == plr and aimedPart) or "body"

				addLine({
					user = plr.Name,
					display = plr.DisplayName,
					hp = math.floor(dmg + 0.5),
					left = math.max(0, math.floor(new + 0.5)),
					part = Hit.Debug and raw or part,
					bodypart = part,
					raw = raw,
				})
			end)
		end

		if plr.Character then task.spawn(hook, plr.Character) end
		bind(plr.CharacterAdded, hook)
	end

	for _, p in ipairs(Players:GetPlayers()) do watch(p) end
	bind(Players.PlayerAdded, watch)

	HitSection:Toggle({
		Name = "Hit log",
		Flag = "HitLog",
		Default = false,
		Callback = function(v) Hit.Enabled = v end
	})

	HitSection:Toggle({
		Name = "Debug mode",
		Flag = "HitLogDebug",
		Default = false,
		Callback = function(v) Hit.Debug = v end
	})

	HitSection:Slider({
		Name = "Hit fov",
		Flag = "HitLogFov",
		Min = 1, Max = 60, Default = 10, Decimals = 1, Suffix = "°",
		Callback = function(v) Hit.Fov = v end
	})

	HitSection:Toggle({
		Name = "Show hit fov",
		Flag = "HitLogShowFov",
		Default = false,
		Callback = function(v) Hit.ShowFov = v end
	})

	HitSection:Textbox({
		Name = "Format",
		Flag = "HitLogFormat",
		Placeholder = DEFAULT_FORMAT,
		Default = DEFAULT_FORMAT,
		Callback = function(text)
			Hit.Format = (text and text ~= "") and text or DEFAULT_FORMAT
		end
	})

	HitSection:Label({Name = "{user} {display} {hp} {left} {part} {raw}"})

	HitSection:Label({Name = "text color"}):Colorpicker({
		Name = "text color",
		Flag = "HitLogTextColor",
		Default = Hit.TextColor,
		Callback = function(c) Hit.TextColor = c end
	})

	HitSection:Toggle({
		Name = "Highlight values",
		Flag = "HitLogHighlight",
		Default = true,
		Callback = function(v) Hit.Highlight = v end
	})

	HitSection:Label({Name = "value color"}):Colorpicker({
		Name = "value color",
		Flag = "HitLogValueColor",
		Default = Hit.ValueColor,
		Callback = function(c) Hit.ValueColor = c end
	})

	HitSection:Toggle({
		Name = "Only aimed player",
		Flag = "HitLogOnlyAimed",
		Default = true,
		Callback = function(v) Hit.OnlyAimed = v end
	})

	HitSection:Slider({
		Name = "Text size",
		Flag = "HitLogSize",
		Min = 10, Max = 24, Default = 14, Decimals = 1, Suffix = " px",
		Callback = function(v) Hit.Size = v end
	})

	HitSection:Slider({
		Name = "Duration",
		Flag = "HitLogDuration",
		Min = 1, Max = 10, Default = 4, Decimals = 0.5, Suffix = " s",
		Callback = function(v) Hit.Duration = v end
	})

	HitSection:Slider({
		Name = "Max lines",
		Flag = "HitLogMax",
		Min = 1, Max = 15, Default = 8, Decimals = 1, Suffix = "",
		Callback = function(v) Hit.MaxLines = math.floor(v) end
	})

	HitSection:Slider({
		Name = "Offset X",
		Flag = "HitLogX",
		Min = 0, Max = 600, Default = 10, Decimals = 1, Suffix = " px",
		Callback = function(v) Hit.X = v list.Position = UDim2.fromOffset(Hit.X, Hit.Y) end
	})

	HitSection:Slider({
		Name = "Offset Y",
		Flag = "HitLogY",
		Min = 0, Max = 600, Default = 44, Decimals = 1, Suffix = " px",
		Callback = function(v) Hit.Y = v list.Position = UDim2.fromOffset(Hit.X, Hit.Y) end
	})

	HitSection:Button({
		Name = "Test line",
		Callback = function()
			addLine({
				user = "noob", display = "Noob", hp = 20, left = 80,
				part = Hit.Debug and "UpperTorso" or "torso",
				bodypart = "torso", raw = "UpperTorso",
			})
		end
	})
end


------------------------------------------------------------
-- CROSSHAIR: MUZZLE + DISTANCE
------------------------------------------------------------
do
    local CrossSection = VisualsPage:Section({
        Name = "crosshair",
        Side = 1
    })

    local Crosshair = {
        Enabled = false,
        Mode = "Dot",
        UseWeapon = true,
        Size = 3,
        Thickness = 1,
        Gap = 4,
        Length = 6,
        CircleRadius = 10,
        Color = Color3.fromRGB(255, 255, 255),
        OutlineColor = Color3.fromRGB(0, 0, 0),
        OutlineThickness = 1,
        Opacity = 1,
        Shape = "Circle",
        Dynamic = true,
        MaxDistance = 5000
    }

    local chGui = Instance.new("ScreenGui")
    chGui.Name = "MS_Crosshair"
    chGui.IgnoreGuiInset = true
    chGui.ResetOnSpawn = false
    chGui.DisplayOrder = 999999
    chGui.Parent = (gethui and gethui()) or CoreGui

    local chHolder = Instance.new("Frame")
    chHolder.Name = "Holder"
    chHolder.BackgroundTransparency = 1
    chHolder.BorderSizePixel = 0
    chHolder.AnchorPoint = Vector2.new(0.5, 0.5)
    chHolder.Size = UDim2.fromOffset(200, 200)
    chHolder.Position = UDim2.fromScale(0.5, 0.5)
    chHolder.Visible = false
    chHolder.Parent = chGui

    -- DOT
    local dotFrame = Instance.new("Frame")
    dotFrame.Name = "Dot"
    dotFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    dotFrame.Position = UDim2.fromScale(0.5, 0.5)
    dotFrame.BorderSizePixel = 0
    dotFrame.Parent = chHolder

    local dotCorner = Instance.new("UICorner")
    dotCorner.Parent = dotFrame

    local dotStroke = Instance.new("UIStroke")
    dotStroke.Parent = dotFrame

    -- CROSS
    local crossLines = {}
    local crossDirs = {
        {ap = Vector2.new(0.5, 0), pos = Vector2.new(0, -1)},
        {ap = Vector2.new(0.5, 1), pos = Vector2.new(0, 1)},
        {ap = Vector2.new(0, 0.5), pos = Vector2.new(-1, 0)},
        {ap = Vector2.new(1, 0.5), pos = Vector2.new(1, 0)}
    }

    for i, dir in ipairs(crossDirs) do
        local line = Instance.new("Frame")
        line.Name = "Line" .. i
        line.BorderSizePixel = 0
        line.AnchorPoint = dir.ap
        line.Parent = chHolder

        local stroke = Instance.new("UIStroke")
        stroke.Parent = line

        crossLines[i] = {
            frame = line,
            stroke = stroke,
            dir = dir
        }
    end

    -- CIRCLE
    local circleFrame = Instance.new("Frame")
    circleFrame.Name = "Circle"
    circleFrame.BackgroundTransparency = 1
    circleFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    circleFrame.Position = UDim2.fromScale(0.5, 0.5)
    circleFrame.BorderSizePixel = 0
    circleFrame.Parent = chHolder

    local circleCorner = Instance.new("UICorner")
    circleCorner.CornerRadius = UDim.new(1, 0)
    circleCorner.Parent = circleFrame

    local circleStroke = Instance.new("UIStroke")
    circleStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    circleStroke.Parent = circleFrame

    -- CENTER DOT
    local centerDot = Instance.new("Frame")
    centerDot.Name = "CenterDot"
    centerDot.AnchorPoint = Vector2.new(0.5, 0.5)
    centerDot.Position = UDim2.fromScale(0.5, 0.5)
    centerDot.BorderSizePixel = 0
    centerDot.Parent = chHolder

    local centerCorner = Instance.new("UICorner")
    centerCorner.CornerRadius = UDim.new(1, 0)
    centerCorner.Parent = centerDot

    ------------------------------------------------------------
    -- FIND ACTIVE MUZZLE
    ------------------------------------------------------------
    local function findMuzzle()
        local character = LocalPlayer.Character
        local camera = workspace.CurrentCamera

        -- Prefer the weapon held by the player
        local containers = {
            character,
            camera
        }

        for _, container in ipairs(containers) do
            if container then
                for _, obj in ipairs(container:GetDescendants()) do
                    if obj.Name == "Muzzle" then
                        if obj:IsA("Attachment") then
                            local handle = obj.Parent
                            if handle and handle:IsA("BasePart") then
                                return obj, handle
                            end
                        elseif obj:IsA("BasePart") then
                            return obj, obj
                        end
                    end
                end
            end
        end

        -- Fallback to the supplied IWBF path
        local weaponRoot =
            workspace:FindFirstChild("RickyShAdEs")

        local held =
            weaponRoot and weaponRoot:FindFirstChild("IHeld")

        local handle =
            held and held:FindFirstChild("Handle")

        local muzzle =
            handle and handle:FindFirstChild("Muzzle")

        if muzzle and handle and handle:IsA("BasePart") then
            if muzzle:IsA("Attachment") or muzzle:IsA("BasePart") then
                return muzzle, handle
            end
        end

        return nil, nil
    end

    ------------------------------------------------------------
    -- MUZZLE RAY + DISTANCE PROJECTION
    ------------------------------------------------------------
    local function getAimScreenPosition(cam)
        local muzzle, handle = findMuzzle()
        if not muzzle or not handle then
            return nil
        end

        local origin
        if muzzle:IsA("Attachment") then
            origin = muzzle.WorldPosition
        else
            origin = muzzle.Position
        end

        -- Matches the direction used by the supplied FirearmClient.
        local direction = handle.CFrame.LookVector

        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.IgnoreWater = true

        local exclusions = {}
        if LocalPlayer.Character then
            table.insert(exclusions, LocalPlayer.Character)
        end

        -- Exclude the weapon itself
        local weaponModel = handle:FindFirstAncestorOfClass("Model")
        if weaponModel then
            table.insert(exclusions, weaponModel)
        else
            table.insert(exclusions, handle)
        end

        params.FilterDescendantsInstances = exclusions

        local result = workspace:Raycast(
            origin,
            direction * Crosshair.MaxDistance,
            params
        )

        -- The raycast supplies the distance to the first surface.
        local aimPoint
        if result then
            aimPoint = result.Position
        else
            aimPoint = origin + direction * Crosshair.MaxDistance
        end

        local screenPos, onScreen =
            cam:WorldToViewportPoint(aimPoint)

        if screenPos.Z <= 0 then
            return nil
        end

        -- Allow points outside the viewport to clamp to its edges.
        return Vector2.new(screenPos.X, screenPos.Y)
    end

    ------------------------------------------------------------
    -- VISUAL SETTINGS
    ------------------------------------------------------------
    local function updateVisuals()
        local col = Crosshair.Color
        local outCol = Crosshair.OutlineColor
        local alpha = 1 - math.clamp(Crosshair.Opacity, 0, 1)

        dotFrame.Size = UDim2.fromOffset(
            Crosshair.Size,
            Crosshair.Size
        )
        dotFrame.BackgroundColor3 = col
        dotFrame.BackgroundTransparency = alpha
        dotCorner.CornerRadius =
            Crosshair.Shape == "Circle"
            and UDim.new(1, 0)
            or UDim.new(0, 0)

        dotStroke.Color = outCol
        dotStroke.Thickness = Crosshair.OutlineThickness

        local gap = Crosshair.Gap
        local len = Crosshair.Length
        local thick = Crosshair.Thickness

        for _, item in ipairs(crossLines) do
            local horizontal = item.dir.pos.X ~= 0

            item.frame.Size = UDim2.fromOffset(
                horizontal and len or thick,
                horizontal and thick or len
            )

            item.frame.Position = UDim2.fromOffset(
                100 + item.dir.pos.X * (gap + len / 2),
                100 + item.dir.pos.Y * (gap + len / 2)
            )

            item.frame.BackgroundColor3 = col
            item.frame.BackgroundTransparency = alpha
            item.stroke.Color = outCol
            item.stroke.Thickness = Crosshair.OutlineThickness
        end

        circleFrame.Size = UDim2.fromOffset(
            Crosshair.CircleRadius * 2,
            Crosshair.CircleRadius * 2
        )
        circleStroke.Color = col
        circleStroke.Thickness = Crosshair.Thickness

        centerDot.Size = UDim2.fromOffset(
            Crosshair.Size,
            Crosshair.Size
        )
        centerDot.BackgroundColor3 = col
        centerDot.BackgroundTransparency = alpha
    end

    ------------------------------------------------------------
    -- UPDATE
    ------------------------------------------------------------
    bind(RunService.RenderStepped, function()
        if not Crosshair.Enabled then
            chHolder.Visible = false
            MS_CrosshairScreenPositionVisible = false
            return
        end

        local cam = workspace.CurrentCamera
        if not cam then
            chHolder.Visible = false
            MS_CrosshairScreenPositionVisible = false
            return
        end

        local viewport = cam.ViewportSize
        local cx, cy = viewport.X / 2, viewport.Y / 2

        if Crosshair.Dynamic and Crosshair.UseWeapon then
            local screenPosition = getAimScreenPosition(cam)

            if screenPosition then
                cx = math.clamp(screenPosition.X, 5, viewport.X - 5)
                cy = math.clamp(screenPosition.Y, 5, viewport.Y - 5)
            end
        end

        chHolder.Position = UDim2.fromOffset(cx, cy)
        chHolder.Visible = true
        MS_CrosshairScreenPosition = Vector2.new(cx, cy)
        MS_CrosshairScreenPositionVisible = true

        local isDot = Crosshair.Mode == "Dot"
        local isCross = Crosshair.Mode == "Cross"
        local isCircle = Crosshair.Mode == "Circle"

        dotFrame.Visible = isDot
        centerDot.Visible = isCircle
        circleFrame.Visible = isCircle

        for _, item in ipairs(crossLines) do
            item.frame.Visible = isCross
        end

        updateVisuals()
    end)

    ------------------------------------------------------------
    -- UI
    ------------------------------------------------------------
    CrossSection:Toggle({
        Name = "Crosshair",
        Flag = "ChEnabled",
        Default = false,
        Callback = function(v)
            Crosshair.Enabled = v
        end
    })

    CrossSection:Dropdown({
        Name = "Mode",
        Flag = "ChMode",
        Items = {"Dot", "Cross", "Circle"},
        Default = "Dot",
        Multi = false,
        Callback = function(v)
            Crosshair.Mode = v
        end
    })

    CrossSection:Toggle({
        Name = "Dynamic (follow barrel)",
        Flag = "ChDynamic",
        Default = true,
        Callback = function(v)
            Crosshair.Dynamic = v
        end
    })

    CrossSection:Label({Name = "color"}):Colorpicker({
        Name = "Crosshair color",
        Flag = "ChColor",
        Default = Color3.fromRGB(255, 255, 255),
        Callback = function(c, a)
            Crosshair.Color = c
            Crosshair.Opacity = 1 - (a or 0)
        end
    })

    CrossSection:Label({Name = "outline color"}):Colorpicker({
        Name = "Outline color",
        Flag = "ChOutline",
        Default = Color3.fromRGB(0, 0, 0),
        Callback = function(c)
            Crosshair.OutlineColor = c
        end
    })

    CrossSection:Slider({
        Name = "Outline thickness",
        Flag = "ChOutlineThick",
        Min = 0,
        Max = 4,
        Default = 1,
        Decimals = 0.5,
        Suffix = "px",
        Callback = function(v)
            Crosshair.OutlineThickness = v
        end
    })

    CrossSection:Slider({
        Name = "Size (dot)",
        Flag = "ChSize",
        Min = 1,
        Max = 20,
        Default = 3,
        Decimals = 1,
        Suffix = "px",
        Callback = function(v)
            Crosshair.Size = v
        end
    })

    CrossSection:Dropdown({
        Name = "Dot shape",
        Flag = "ChShape",
        Items = {"Circle", "Square"},
        Default = "Circle",
        Multi = false,
        Callback = function(v)
            Crosshair.Shape = v
        end
    })

    CrossSection:Slider({
        Name = "Thickness (cross/circle)",
        Flag = "ChThickness",
        Min = 1,
        Max = 8,
        Default = 1,
        Decimals = 0.5,
        Suffix = "px",
        Callback = function(v)
            Crosshair.Thickness = v
        end
    })

    CrossSection:Slider({
        Name = "Gap (cross)",
        Flag = "ChGap",
        Min = 0,
        Max = 20,
        Default = 4,
        Decimals = 1,
        Suffix = "px",
        Callback = function(v)
            Crosshair.Gap = v
        end
    })

    CrossSection:Slider({
        Name = "Length (cross)",
        Flag = "ChLength",
        Min = 2,
        Max = 30,
        Default = 6,
        Decimals = 1,
        Suffix = "px",
        Callback = function(v)
            Crosshair.Length = v
        end
    })

    CrossSection:Slider({
        Name = "Radius (circle)",
        Flag = "ChRadius",
        Min = 3,
        Max = 60,
        Default = 10,
        Decimals = 1,
        Suffix = "px",
        Callback = function(v)
            Crosshair.CircleRadius = v
        end
    })

    if getgenv then
        local oldCleanup = getgenv().MS_CLEANUP

        getgenv().MS_CLEANUP = function()
            pcall(function()
                RunService:UnbindFromRenderStep("MS_Crosshair_Update")
                chGui:Destroy()
            end)

            if oldCleanup then
                pcall(oldCleanup)
            end
        end
    end
end

------------------------------------------------------------
-- BULLET TRACER
------------------------------------------------------------
do
    local TracerSection = VisualsPage:Section({Name = "bullet tracer", Side = 2})
    local TweenService = game:GetService("TweenService")
    local UserInputService = game:GetService("UserInputService")
    local Camera = workspace.CurrentCamera

    local TracerConfig = {
        Enabled = false,
        Style = "Line",
        Animation = "Fade",
        Color = Color3.fromRGB(255, 70, 70),
        Thickness = 0.07,
        Lifetime = 0.18,
        MaxDistance = 1500,
        IgnoreWalls = false
    }

local TracerTextureStyles = {
            Obelus = {
                Texture = "rbxassetid://2382169232",
                Brightness = 1.5, Transparency = NumberSequence.new(0.45),
                Segments = 1, TextureLength = 5,
                TextureMode = Enum.TextureMode.Stretch, TextureSpeed = 0,
                WidthScale = 1,
            },
            Lightning = {
                Texture = "rbxassetid://7151778302",
                Brightness = 1.5, Transparency = NumberSequence.new(0.45),
                Segments = 10, TextureLength = 1,
                TextureMode = Enum.TextureMode.Stretch, TextureSpeed = 1,
                WidthScale = 1.2,
            },
            DNA = {
                Texture = "rbxassetid://7071778278",
                Brightness = 1.5, Transparency = NumberSequence.new(0.45),
                Segments = 1, TextureLength = 12,
                TextureMode = Enum.TextureMode.Wrap, TextureSpeed = 1,
                WidthScale = 0.6,
            },
        }

    local tracerLastShot = 0
    local tracerFolder = Instance.new("Folder")
    tracerFolder.Name = "MS_BulletTracers"
    tracerFolder.Parent = workspace

    local function findTracerWeapon()
        local character = LocalPlayer.Character
        local held = character and character:FindFirstChild("IHeld")
        if not held then
            local root = workspace:FindFirstChild("RickyShAdEs")
            held = root and root:FindFirstChild("IHeld")
        end
        if not held then return nil, nil, nil, nil end

        local handle = held:FindFirstChild("Handle")
        local muzzle = handle and handle:FindFirstChild("Muzzle")
        if not handle or not handle:IsA("BasePart") or not muzzle then
            return nil, nil, nil, held
        end

        local origin
        if muzzle:IsA("Attachment") then origin = muzzle.WorldPosition
        elseif muzzle:IsA("BasePart") then origin = muzzle.Position end
        if not origin then return nil, nil, nil, held end
        return origin, handle.CFrame.LookVector, handle, held
    end

    -- Prevent tracers when the local weapon's known clip count is zero.
    -- IClipLocal is the clip attribute used by this game's firearm code.
    local function weaponHasAmmo(held)
        if not held then return false end
        local clip = held:GetAttribute("IClipLocal")
        if typeof(clip) == "number" then return clip > 0 end
        local fallback = held:GetAttribute("IClip")
        if typeof(fallback) == "number" then return fallback > 0 end
        -- If the game has not replicated a clip attribute yet, fail closed
        -- rather than drawing false tracers while empty.
        return false
    end

    local function makePart(name, fromPos, toPos, width, color)
        local delta = toPos - fromPos
        local length = delta.Magnitude
        if length < 0.05 then return nil end
        local part = Instance.new("Part")
        part.Name = name
        part.Anchored = true
        part.CanCollide = false
        part.CanTouch = false
        part.CanQuery = false
        part.CastShadow = false
        part.Material = Enum.Material.Neon
        part.Color = color or TracerConfig.Color
        part.Size = Vector3.new(width or TracerConfig.Thickness, width or TracerConfig.Thickness, length)
        part.CFrame = CFrame.lookAt((fromPos + toPos) / 2, toPos)
        part.Parent = tracerFolder
        return part
    end

    local function fadeAndRemove(parts, lifetime)
        for _, part in ipairs(parts) do
            if part and part.Parent then
                if TracerConfig.Animation == "Fade" then
                    TweenService:Create(part, TweenInfo.new(lifetime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Transparency = 1}):Play()
                end
            end
        end
        task.delay(lifetime, function()
            for _, part in ipairs(parts) do
                if part and part.Parent then part:Destroy() end
            end
        end)
    end

    local function drawDrawingLine(origin, endpoint)
        if not Drawing or not Drawing.new then return false end
        Camera = workspace.CurrentCamera
        if not Camera then return false end
        local p1, on1 = Camera:WorldToViewportPoint(origin)
        local p2, on2 = Camera:WorldToViewportPoint(endpoint)
        if not on1 and not on2 then return false end
        local ok, line = pcall(function() return Drawing.new("Line") end)
        if not ok or not line then return false end
        line.From = Vector2.new(p1.X, p1.Y)
        line.To = Vector2.new(p2.X, p2.Y)
        line.Color = TracerConfig.Color
        line.Thickness = math.max(1, TracerConfig.Thickness * 20)
        line.Transparency = 1
        line.Visible = true
        task.delay(TracerConfig.Lifetime, function()
            pcall(function() line:Remove() end)
        end)
        return true
    end

    local function drawBulletTracer()
        if not TracerConfig.Enabled then return end
        local origin, direction, handle, held = findTracerWeapon()
        if not origin or not direction or not handle or not weaponHasAmmo(held) then return end
        if direction.Magnitude <= 0 then return end
        direction = direction.Unit

        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.IgnoreWater = true
        local excluded = {}
        if LocalPlayer.Character then table.insert(excluded, LocalPlayer.Character) end
        local weaponModel = handle:FindFirstAncestorOfClass("Model")
        table.insert(excluded, weaponModel or handle)
        params.FilterDescendantsInstances = excluded

        local rayResult = workspace:Raycast(origin, direction * TracerConfig.MaxDistance, params)
        local endpoint = origin + direction * TracerConfig.MaxDistance
        if rayResult and not TracerConfig.IgnoreWalls then endpoint = rayResult.Position end
        if (endpoint - origin).Magnitude < 0.05 then return end

        if TracerConfig.Style == "Drawing" then
            if drawDrawingLine(origin, endpoint) then return end
            -- Drawing API unavailable: gracefully fall back to a 3D line.
        end

        local parts = {}
        local beams = {}
        local distance = (endpoint - origin).Magnitude
        if TracerConfig.Style == "Electric" then
            local points = {origin}
            local segments = 8
            local side = direction:Cross(Vector3.new(0, 1, 0))
            if side.Magnitude < 0.01 then side = direction:Cross(Vector3.new(1, 0, 0)) end
            side = side.Unit
            local up = direction:Cross(side).Unit
            for i = 1, segments - 1 do
                local t = i / segments
                local offset = (side * math.random(-100, 100) + up * math.random(-70, 70)) * math.min(0.16, distance * 0.00015)
                table.insert(points, origin:Lerp(endpoint, t) + offset)
            end
            table.insert(points, endpoint)
            for i = 1, #points - 1 do
                local part = makePart("TracerLightning", points[i], points[i + 1], TracerConfig.Thickness * 0.8)
                if part then table.insert(parts, part) end
            end
        elseif TracerConfig.Style == "Pulse" then
            local pulseLength = math.min(12, distance)
            local part = makePart("TracerPulse", origin, origin + direction * pulseLength, TracerConfig.Thickness * 1.8)
            if part then
                table.insert(parts, part)
                local target = CFrame.lookAt(origin + direction * (distance - pulseLength / 2), endpoint)
                TweenService:Create(part, TweenInfo.new(TracerConfig.Lifetime, Enum.EasingStyle.Linear), {CFrame = target}):Play()
            end
        elseif TracerConfig.Style == "Beam"
            or TracerConfig.Style == "Obelus"
            or TracerConfig.Style == "Lightning"
            or TracerConfig.Style == "DNA" then
            local a0 = Instance.new("Attachment")
            local a1 = Instance.new("Attachment")
            local anchor0 = Instance.new("Part")
            local anchor1 = Instance.new("Part")
            for _, anchor in ipairs({anchor0, anchor1}) do
                anchor.Anchored = true
                anchor.Transparency = 1
                anchor.Size = Vector3.new(0.05, 0.05, 0.05)
                anchor.CanCollide = false
                anchor.CanQuery = false
                anchor.CanTouch = false
                anchor.Parent = tracerFolder
            end
            anchor0.Position, anchor1.Position = origin, endpoint
            a0.Parent, a1.Parent = anchor0, anchor1
            local beam = Instance.new("Beam")
            beam.Attachment0, beam.Attachment1 = a0, a1
            beam.Width0, beam.Width1 = TracerConfig.Thickness, TracerConfig.Thickness
            beam.Color = ColorSequence.new(TracerConfig.Color)
            beam.LightEmission = 1
            beam.LightInfluence = 0
            beam.FaceCamera = true

            -- Apply the selected texture preset when this is a textured Beam style.
            local textureStyle = TracerTextureStyles[TracerConfig.Style]
            if textureStyle then
                beam.Texture = textureStyle.Texture
                beam.Brightness = textureStyle.Brightness
                beam.Transparency = textureStyle.Transparency
                beam.Segments = textureStyle.Segments
                beam.TextureLength = textureStyle.TextureLength
                beam.TextureMode = textureStyle.TextureMode
                beam.TextureSpeed = textureStyle.TextureSpeed
                beam.Width0 = TracerConfig.Thickness * textureStyle.WidthScale
                beam.Width1 = TracerConfig.Thickness * textureStyle.WidthScale
            end
            beam.Parent = anchor0
            table.insert(beams, beam)
            table.insert(parts, anchor0)
            table.insert(parts, anchor1)
        else -- Line
            local part = makePart("BulletTracer", origin, endpoint, TracerConfig.Thickness)
            if part then table.insert(parts, part) end
        end

        local animation = TracerConfig.Animation
        local lifetime = TracerConfig.Lifetime

        if animation == "Fade" then
            for _, beam in ipairs(beams) do
                beam.Transparency = NumberSequence.new(0.1)
                task.delay(lifetime * 0.65, function()
                    if beam and beam.Parent then beam.Transparency = NumberSequence.new(1) end
                end)
            end
            fadeAndRemove(parts, lifetime)
        elseif animation == "Pulse" then
            for _, part in ipairs(parts) do
                if part:IsA("BasePart") and part.Transparency < 1 then
                    TweenService:Create(part, TweenInfo.new(lifetime / 2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Transparency = 0.65}):Play()
                end
            end
            for _, beam in ipairs(beams) do
                local baseWidth = TracerConfig.Thickness
                TweenService:Create(beam, TweenInfo.new(math.max(0.08, lifetime / 2), Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Width0 = baseWidth * 1.8, Width1 = baseWidth * 1.8}):Play()
            end
            task.delay(lifetime, function()
                for _, part in ipairs(parts) do if part and part.Parent then part:Destroy() end end
            end)
        elseif animation == "Flash" then
            for _, part in ipairs(parts) do
                if part:IsA("BasePart") and part.Transparency < 1 then
                    part.Transparency = 0.05
                    TweenService:Create(part, TweenInfo.new(math.min(0.12, lifetime), Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Transparency = 1}):Play()
                end
            end
            for _, beam in ipairs(beams) do
                beam.Transparency = NumberSequence.new(0)
                task.delay(math.min(0.12, lifetime), function()
                    if beam and beam.Parent then beam.Transparency = NumberSequence.new(1) end
                end)
            end
            task.delay(lifetime, function() for _, part in ipairs(parts) do if part and part.Parent then part:Destroy() end end end)
        elseif animation == "Grow" or animation == "Shrink" or animation == "Heartbeat" then
            for _, beam in ipairs(beams) do
                local width = TracerConfig.Thickness
                if animation == "Grow" then
                    beam.Width0, beam.Width1 = 0.005, 0.005
                    TweenService:Create(beam, TweenInfo.new(math.min(0.18, lifetime), Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Width0 = width, Width1 = width}):Play()
                elseif animation == "Shrink" then
                    TweenService:Create(beam, TweenInfo.new(lifetime, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Width0 = 0.001, Width1 = 0.001}):Play()
                else
                    TweenService:Create(beam, TweenInfo.new(math.max(0.1, lifetime / 3), Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Width0 = width * 1.9, Width1 = width * 1.9}):Play()
                end
            end
            for _, part in ipairs(parts) do
                if part:IsA("BasePart") and part.Transparency < 1 then
                    if animation == "Grow" then
                        local size = part.Size
                        part.Size = Vector3.new(size.X * 0.15, size.Y * 0.15, size.Z)
                        TweenService:Create(part, TweenInfo.new(math.min(0.18, lifetime), Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = size}):Play()
                    elseif animation == "Shrink" then
                        local size = part.Size
                        TweenService:Create(part, TweenInfo.new(lifetime, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Size = Vector3.new(size.X * 0.01, size.Y * 0.01, size.Z)}):Play()
                    else
                        local size = part.Size
                        TweenService:Create(part, TweenInfo.new(math.max(0.1, lifetime / 3), Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Size = Vector3.new(size.X * 1.8, size.Y * 1.8, size.Z)}):Play()
                    end
                end
            end
            task.delay(lifetime, function() for _, part in ipairs(parts) do if part and part.Parent then part:Destroy() end end end)
        elseif animation == "Travel" or animation == "Wave" then
            for _, beam in ipairs(beams) do
                beam.TextureSpeed = animation == "Travel" and 5 or 2
                beam.TextureMode = Enum.TextureMode.Wrap
                if animation == "Wave" then
                    local width = TracerConfig.Thickness
                    TweenService:Create(beam, TweenInfo.new(math.max(0.12, lifetime / 2), Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Width0 = width * 1.5, Width1 = width * 0.6}):Play()
                end
            end
            if animation == "Travel" then
                for _, part in ipairs(parts) do
                    if part:IsA("BasePart") and part.Transparency < 1 then
                        TweenService:Create(part, TweenInfo.new(lifetime, Enum.EasingStyle.Linear), {Transparency = 0.35}):Play()
                    end
                end
            end
            task.delay(lifetime, function() for _, part in ipairs(parts) do if part and part.Parent then part:Destroy() end end end)
        elseif animation == "Flicker" then
            for _, beam in ipairs(beams) do
                beam.Transparency = NumberSequence.new(0.7)
                task.delay(0.06, function() if beam and beam.Parent then beam.Transparency = NumberSequence.new(0.05) end end)
                task.delay(0.13, function() if beam and beam.Parent then beam.Transparency = NumberSequence.new(0.8) end end)
                task.delay(0.2, function() if beam and beam.Parent then beam.Transparency = NumberSequence.new(0.05) end end)
            end
            for _, part in ipairs(parts) do
                if part:IsA("BasePart") and part.Transparency < 1 then
                    task.spawn(function()
                        local deadline = os.clock() + lifetime
                        while part.Parent and os.clock() < deadline do
                            part.Transparency = math.random() > 0.5 and 0.05 or 0.8
                            task.wait(0.035)
                        end
                    end)
                end
            end
            task.delay(lifetime, function() for _, part in ipairs(parts) do if part and part.Parent then part:Destroy() end end end)
        else -- None
            task.delay(lifetime, function() for _, part in ipairs(parts) do if part and part.Parent then part:Destroy() end end end)
        end
    end

    -- Input-based trigger is guarded by the current weapon's local clip count.
    UserInputService.InputBegan:Connect(function(input, processed)
        if processed or not TracerConfig.Enabled then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local now = os.clock()
            if now - tracerLastShot >= 0.035 then
                tracerLastShot = now
                drawBulletTracer()
            end
        end
    end)

    TracerSection:Toggle({
        Name = "Bullet tracer", Flag = "BulletTracerEnabled", Default = false,
        Callback = function(v) TracerConfig.Enabled = v end
    })
    TracerSection:Dropdown({
        Name = "Tracer style", Flag = "BulletTracerStyle",
        Items = {"Line", "Drawing", "Beam", "Pulse", "Electric", "Obelus", "Lightning", "DNA"},
        Default = "Line", Multi = false,
        Callback = function(v) TracerConfig.Style = v end
    })
    TracerSection:Dropdown({
        Name = "Animation", Flag = "BulletTracerAnimation",
        Items = {"None", "Fade", "Pulse", "Flash", "Grow", "Shrink", "Travel", "Wave", "Flicker", "Heartbeat"},
        Default = "Fade", Multi = false,
        Callback = function(v) TracerConfig.Animation = v end
    })
    TracerSection:Label({Name = "Tracer color"}):Colorpicker({
        Name = "Color", Flag = "BulletTracerColor", Default = TracerConfig.Color,
        Callback = function(c) TracerConfig.Color = c end
    })
    TracerSection:Slider({
        Name = "Thickness", Flag = "BulletTracerThickness", Min = 0.02, Max = 0.3,
        Default = 0.07, Decimals = 0.01, Callback = function(v) TracerConfig.Thickness = v end
    })
    TracerSection:Slider({
        Name = "Lifetime", Flag = "BulletTracerLifetime", Min = 0.05, Max = 7,
        Default = 1.25, Decimals = 0.05, Suffix = "s",
        Callback = function(v) TracerConfig.Lifetime = v end
    })
    TracerSection:Slider({
        Name = "Max distance", Flag = "BulletTracerDistance", Min = 100, Max = 3000,
        Default = 1500, Decimals = 100, Suffix = " studs",
        Callback = function(v) TracerConfig.MaxDistance = v end
    })
    TracerSection:Toggle({
        Name = "Ignore walls", Flag = "BulletTracerIgnoreWalls", Default = false,
        Callback = function(v) TracerConfig.IgnoreWalls = v end
    })

    if getgenv then
        local oldCleanup = getgenv().MS_CLEANUP
        getgenv().MS_CLEANUP = function()
            pcall(function() tracerFolder:Destroy() end)
            if oldCleanup then pcall(oldCleanup) end
        end
    end
end

------------------------------------------------------------
-- CREDITSPAGE
------------------------------------------------------------
do
	local CreditsSection = CreditsPage:Section({Name = "STANDOFF2", Side = 1})
    local Credits3Section = CreditsPage:Section({Name = "AvidasGang", Side = 2})
	CreditsSection:Label({Name = "made by AvidasGang◣_◢"})
    CreditsSection:Label({Name = "Ui made by sametexe001"})
    CreditsSection:Label({Name = "discord.gg/Mpnq5xwgW2"})
    CreditsSection:Label({Name = "https://bigrat.monster/"})
    Credits3Section:Label({Name = "🕋☪️👌| no nigga allowed👨🏿‍🦲"})
    Credits3Section:Label({Name = "EBAL BARANOV V ROT🐑"})
    Credits3Section:Label({Name = "666 iq ПОПО ЩОЩО + ПАТАПИМ АРТЕМ◣_◢"})
    Credits3Section:Label({Name = "Missed shot due to ЖИР"})
    CreditsSection:Label({Name = "__photo__"})
    
end

------------------------------------------------------------
-- Wolrd page
------------------------------------------------------------

do
    local Lighting = game:GetService("Lighting")

    ------------------------------------------------------------
    -- WORLD ITEM ESP (placed first on the World page)
    ------------------------------------------------------------
    local WorldEspSection = WorldPage:Section({Name = "World ESP", Side = 1, Size = 360})
    local WorldItemState = {
        Enabled = false,
        Box = true,
        Name = true,
        Distance = true,
        MaxDistance = 1500,
        DistanceFade = true,
        FadeDistance = 100,
        BoxColor = Color3.fromRGB(255, 170, 55),
        TextColor = Color3.fromRGB(255, 255, 255),
    }

    local WorldItemGuiParent = CoreGui
    local OldWorldItemGui = WorldItemGuiParent:FindFirstChild("MissSense_WorldItemESP")
    if OldWorldItemGui then pcall(function() OldWorldItemGui:Destroy() end) end
    local WorldItemGui = Instance.new("ScreenGui")
    WorldItemGui.Name = "MissSense_WorldItemESP"
    WorldItemGui.ResetOnSpawn = false
    WorldItemGui.IgnoreGuiInset = true
    WorldItemGui.DisplayOrder = 999
    WorldItemGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    WorldItemGui.Parent = WorldItemGuiParent

    local WorldItemEntries = {}
    local WorldItemRefreshAt = 0
    local WorldItemScanInterval = 0.35

    -- This ESP is intentionally scoped to workspace.IItems. Items in that
    -- container do not need a matching name/keyword to be drawn.
    local function worldItemGetContainer()
        local ok, container = pcall(function()
            return workspace:FindFirstChild("IItems")
        end)
        if ok and container and container.Parent == workspace then
            return container
        end
        return nil
    end

    local function worldItemHasBasePart(inst)
        if not inst then return false end
        if inst:IsA("BasePart") then return true end
        local ok, descendants = pcall(function() return inst:GetDescendants() end)
        if not ok or not descendants then return false end
        for _, descendant in ipairs(descendants) do
            if descendant:IsA("BasePart") then return true end
        end
        return false
    end

    local function worldItemHasModelOrTool(inst)
        if not inst then return false end
        local ok, descendants = pcall(function() return inst:GetDescendants() end)
        if not ok or not descendants then return false end
        for _, descendant in ipairs(descendants) do
            if descendant:IsA("Model") or descendant:IsA("Tool") then
                return true
            end
        end
        return false
    end

    local function worldItemIsPlayerCharacter(inst)
        local current = inst
        while current and current ~= workspace do
            if current:IsA("Model") then
                local ok, player = pcall(function() return Players:GetPlayerFromCharacter(current) end)
                if ok and player then return true end
            end
            current = current.Parent
        end
        return false
    end

    -- Return logical item roots rather than every descendant part; otherwise
    -- models create a separate ESP box for each limb/mesh and the boxes overlap.
    local function worldItemCollectRoots(container)
        local roots = {}
        local function walk(node, isContainerRoot)
            if not node then return end
            if node:IsA("Model") or node:IsA("Tool") or node:IsA("BasePart") then
                if worldItemHasBasePart(node) and not worldItemIsPlayerCharacter(node) then
                    roots[#roots + 1] = node
                end
                return
            end

            -- Some games wrap an item as a Folder. If it contains only parts,
            -- treat the folder as one item; if it contains Models/Tools, walk
            -- down and register those as separate item roots.
            if not isContainerRoot and node:IsA("Folder")
                and worldItemHasBasePart(node) and not worldItemHasModelOrTool(node) then
                roots[#roots + 1] = node
                return
            end

            local ok, children = pcall(function() return node:GetChildren() end)
            if ok and children then
                for _, child in ipairs(children) do
                    walk(child, false)
                end
            end
        end

        if not container then return roots end
        local ok, children = pcall(function() return container:GetChildren() end)
        if ok and children then
            for _, child in ipairs(children) do
                walk(child, false)
            end
        end
        return roots
    end

    local function worldItemCreateEntry(inst)
        -- Match Player ESP's box construction: transparent holder, inner UIStroke,
        -- and two black outline strokes. Avoid the separate four-edge approximation.
        local box = Instance.new("Frame")
        box.Name = "ItemBox"
        box.BackgroundTransparency = 1
        box.BorderSizePixel = 0
        box.Visible = false
        box.ZIndex = 20
        box.ClipsDescendants = false
        box.Parent = WorldItemGui

        local boxHolder = Instance.new("Frame")
        boxHolder.Name = "BoxHolder"
        boxHolder.BackgroundTransparency = 1
        boxHolder.BorderSizePixel = 0
        boxHolder.Position = UDim2.new(0, 1, 0, 1)
        boxHolder.Size = UDim2.new(1, -2, 1, -2)
        boxHolder.ZIndex = 19
        boxHolder.Parent = box

        local boxOutlineHolder = Instance.new("Frame")
        boxOutlineHolder.Name = "BoxOutlineHolder"
        boxOutlineHolder.BackgroundTransparency = 1
        boxOutlineHolder.BorderSizePixel = 0
        boxOutlineHolder.Position = UDim2.new(0, 2, 0, 2)
        boxOutlineHolder.Size = UDim2.new(1, -4, 1, -4)
        boxOutlineHolder.ZIndex = 17
        boxOutlineHolder.Parent = box

        local mainBox = Instance.new("UIStroke")
        mainBox.Name = "MainBoxStroke"
        mainBox.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        mainBox.LineJoinMode = Enum.LineJoinMode.Miter
        mainBox.Color = WorldItemState.BoxColor
        mainBox.Thickness = 1
        mainBox.Transparency = 0
        mainBox.Enabled = false
        mainBox.Parent = boxHolder

        local mainBoxColor = Instance.new("UIGradient")
        mainBoxColor.Name = "MainBoxGradient"
        mainBoxColor.Rotation = 0
        mainBoxColor.Color = ColorSequence.new(WorldItemState.BoxColor, WorldItemState.BoxColor)
        mainBoxColor.Parent = mainBox

        local outline1 = Instance.new("UIStroke")
        outline1.Name = "OuterBlackOutline"
        outline1.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        outline1.LineJoinMode = Enum.LineJoinMode.Miter
        outline1.Color = Color3.new(0, 0, 0)
        outline1.Thickness = 1
        outline1.Transparency = 0
        outline1.Enabled = false
        outline1.Parent = box

        local outline2 = Instance.new("UIStroke")
        outline2.Name = "InnerBlackOutline"
        outline2.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        outline2.LineJoinMode = Enum.LineJoinMode.Miter
        outline2.Color = Color3.new(0, 0, 0)
        outline2.Thickness = 1
        outline2.Transparency = 0
        outline2.Enabled = false
        outline2.Parent = boxOutlineHolder

        local nameLabel = Instance.new("TextLabel")
        nameLabel.Name = "ItemName"
        nameLabel.BackgroundTransparency = 1
        nameLabel.BorderSizePixel = 0
        nameLabel.AnchorPoint = Vector2.new(0.5, 1)
        nameLabel.Size = UDim2.fromOffset(240, 16)
        nameLabel.FontFace = ESP_FONT_FACE or ESP_FONT_FALLBACK
        nameLabel.TextSize = 12
        nameLabel.TextColor3 = WorldItemState.TextColor
        nameLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
        nameLabel.TextStrokeTransparency = 0
        nameLabel.TextXAlignment = Enum.TextXAlignment.Center
        nameLabel.TextYAlignment = Enum.TextYAlignment.Center
        nameLabel.Visible = false
        nameLabel.ZIndex = 22
        nameLabel.Parent = WorldItemGui

        local distanceLabel = Instance.new("TextLabel")
        distanceLabel.Name = "ItemDistance"
        distanceLabel.BackgroundTransparency = 1
        distanceLabel.BorderSizePixel = 0
        distanceLabel.AnchorPoint = Vector2.new(0.5, 0)
        distanceLabel.Size = UDim2.fromOffset(160, 16)
        distanceLabel.FontFace = ESP_FONT_FACE or ESP_FONT_FALLBACK
        distanceLabel.TextSize = 11
        distanceLabel.TextColor3 = WorldItemState.TextColor
        distanceLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
        distanceLabel.TextStrokeTransparency = 0
        distanceLabel.TextXAlignment = Enum.TextXAlignment.Center
        distanceLabel.TextYAlignment = Enum.TextYAlignment.Center
        distanceLabel.Visible = false
        distanceLabel.ZIndex = 22
        distanceLabel.Parent = WorldItemGui

        local entry = {
            box = box,
            boxHolder = boxHolder,
            boxOutlineHolder = boxOutlineHolder,
            mainBox = mainBox,
            mainBoxColor = mainBoxColor,
            outline1 = outline1,
            outline2 = outline2,
            name = nameLabel,
            distance = distanceLabel,
        }
        WorldItemEntries[inst] = entry
        return entry
    end

    local function worldItemRemoveEntry(inst)
        local entry = WorldItemEntries[inst]
        if not entry then return end
        for _, object in pairs(entry) do
            pcall(function() object:Destroy() end)
        end
        WorldItemEntries[inst] = nil
    end

    local function worldItemBounds(inst)
        if not inst or not inst.Parent then return nil, nil end
        if inst:IsA("BasePart") then return inst.CFrame, inst.Size end
        if inst:IsA("Model") then
            local ok, cf, size = pcall(function() return inst:GetBoundingBox() end)
            if ok and cf and size then return cf, size end
        end
        -- Tools and other pickup instances may not implement GetBoundingBox;
        -- approximate a world-aligned box from their BasePart descendants.
        local minV, maxV, partCount = nil, nil, 0
        local descendants = {}
        if inst:IsA("BasePart") then
            descendants[1] = inst
        else
            local ok, result = pcall(function() return inst:GetDescendants() end)
            if ok and result then descendants = result end
        end
        for _, part in ipairs(descendants) do
            if part:IsA("BasePart") then
                partCount += 1
                local half = part.Size * 0.5
                for _, sx in ipairs({-1, 1}) do
                    for _, sy in ipairs({-1, 1}) do
                        for _, sz in ipairs({-1, 1}) do
                            local point = part.CFrame:PointToWorldSpace(Vector3.new(half.X * sx, half.Y * sy, half.Z * sz))
                            minV = minV and Vector3.new(math.min(minV.X, point.X), math.min(minV.Y, point.Y), math.min(minV.Z, point.Z)) or point
                            maxV = maxV and Vector3.new(math.max(maxV.X, point.X), math.max(maxV.Y, point.Y), math.max(maxV.Z, point.Z)) or point
                        end
                    end
                end
            end
        end
        if partCount == 0 or not minV or not maxV then return nil, nil end
        local center = (minV + maxV) * 0.5
        return CFrame.new(center), maxV - minV
    end

    local function worldItemProject(inst, camera)
        local cf, size = worldItemBounds(inst)
        if not cf or not size then return nil end
        local minX, minY, maxX, maxY = math.huge, math.huge, -math.huge, -math.huge
        local frontCount = 0
        for _, sx in ipairs({-1, 1}) do
            for _, sy in ipairs({-1, 1}) do
                for _, sz in ipairs({-1, 1}) do
                    local worldPoint = (cf * CFrame.new(size.X * 0.5 * sx, size.Y * 0.5 * sy, size.Z * 0.5 * sz)).Position
                    local point, onScreen = camera:WorldToViewportPoint(worldPoint)
                    if point.Z > 0 then
                        frontCount += 1
                        minX, minY = math.min(minX, point.X), math.min(minY, point.Y)
                        maxX, maxY = math.max(maxX, point.X), math.max(maxY, point.Y)
                    end
                end
            end
        end
        if frontCount == 0 then return nil end
        if minX == math.huge or minY == math.huge or maxX == -math.huge or maxY == -math.huge then
            return nil
        end
        local viewport = camera.ViewportSize
        if maxX < 0 or maxY < 0 or minX > viewport.X or minY > viewport.Y then return nil end
        minX, minY = math.clamp(minX, 0, viewport.X), math.clamp(minY, 0, viewport.Y)
        maxX, maxY = math.clamp(maxX, 0, viewport.X), math.clamp(maxY, 0, viewport.Y)
        if maxX - minX < 2 then maxX = math.min(viewport.X, minX + 2) end
        if maxY - minY < 2 then maxY = math.min(viewport.Y, minY + 2) end
        return minX, minY, maxX - minX, maxY - minY, cf.Position
    end

    WorldEspSection:Toggle({
        Name = "Enabled", Flag = "WorldItemESPEnabled", Default = false,
        Callback = function(v) WorldItemState.Enabled = v end
    })
    local itemBoxToggle = WorldEspSection:Toggle({
        Name = "Box", Flag = "WorldItemESPBox", Default = true,
        Callback = function(v) WorldItemState.Box = v end
    })
    itemBoxToggle:Colorpicker({
        Name = "Box color", Flag = "WorldItemESPBoxColor",
        Default = WorldItemState.BoxColor,
        Callback = function(c) if typeof(c) == "Color3" then WorldItemState.BoxColor = c end end
    })
    local itemNameToggle = WorldEspSection:Toggle({
        Name = "Name", Flag = "WorldItemESPName", Default = true,
        Callback = function(v) WorldItemState.Name = v end
    })
    itemNameToggle:Colorpicker({
        Name = "Text color", Flag = "WorldItemESPTextColor",
        Default = WorldItemState.TextColor,
        Callback = function(c) if typeof(c) == "Color3" then WorldItemState.TextColor = c end end
    })
    WorldEspSection:Toggle({
        Name = "Distance", Flag = "WorldItemESPDistance", Default = true,
        Callback = function(v) WorldItemState.Distance = v end
    })
    WorldEspSection:Slider({
        Name = "Max distance", Flag = "WorldItemESPMaxDistance",
        Min = 100, Max = 5000, Default = 1500, Decimals = 1, Suffix = " studs",
        Callback = function(v) if type(v) == "number" then WorldItemState.MaxDistance = math.clamp(v, 100, 5000) end end
    })
    WorldEspSection:Toggle({
        Name = "Distance fade", Flag = "WorldItemESPDistanceFade", Default = true,
        Callback = function(v) WorldItemState.DistanceFade = v end
    })
    WorldEspSection:Slider({
        Name = "Fade start distance", Flag = "WorldItemESPFadeDistance",
        Min = 10, Max = 3000, Default = 100, Decimals = 1, Suffix = " studs",
        Callback = function(v) if type(v) == "number" then WorldItemState.FadeDistance = math.clamp(v, 10, 3000) end end
    })

    bind(RunService.RenderStepped, function()
        if not WorldItemGui or not WorldItemGui.Parent then return end
        if not WorldItemState.Enabled then
            for _, entry in pairs(WorldItemEntries) do
                entry.box.Visible = false
                entry.name.Visible = false
                entry.distance.Visible = false
            end
            return
        end

        local now = os.clock()
        if now >= WorldItemRefreshAt then
            WorldItemRefreshAt = now + WorldItemScanInterval
            local seen = {}
            local itemContainer = worldItemGetContainer()
            if itemContainer then
                for _, inst in ipairs(worldItemCollectRoots(itemContainer)) do
                    if inst and inst.Parent and inst:IsDescendantOf(itemContainer) then
                        seen[inst] = true
                        if not WorldItemEntries[inst] then
                            worldItemCreateEntry(inst)
                        end
                    end
                end
            end
            -- Remove stale entries when items despawn or IItems disappears.
            for inst in pairs(WorldItemEntries) do
                local stillInside = false
                if itemContainer and inst and inst.Parent then
                    local ok, inside = pcall(function() return inst:IsDescendantOf(itemContainer) end)
                    stillInside = ok and inside
                end
                if not seen[inst] or not stillInside then
                    worldItemRemoveEntry(inst)
                end
            end
        end

        local camera = workspace.CurrentCamera
        local character = LocalPlayer and LocalPlayer.Character
        local playerPosition = nil

        -- Prefer the character root while alive. During death/respawn Character
        -- or HumanoidRootPart can be nil, so use the current camera as fallback.
        if character then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            local characterAlive = not humanoid or humanoid.Health > 0
            if characterAlive then
                local characterRoot = character:FindFirstChild("HumanoidRootPart")
                    or character:FindFirstChildWhichIsA("BasePart")
                if characterRoot and characterRoot:IsA("BasePart") then
                    playerPosition = characterRoot.Position
                end
            end
        end
        -- On death use the camera position even if a dead character model/root
        -- still exists; that is what the player is actually viewing from.
        if not playerPosition and camera then
            playerPosition = camera.CFrame.Position
        end

        if not camera or not playerPosition then
            for _, entry in pairs(WorldItemEntries) do
                entry.box.Visible = false; entry.name.Visible = false; entry.distance.Visible = false
            end
            return
        end

        for inst, entry in pairs(WorldItemEntries) do
            local success, minX, minY, width, height, worldPosition = pcall(worldItemProject, inst, camera)
            if success and minX and worldPosition then
                local distance = (playerPosition - worldPosition).Magnitude
                local inRange = distance <= WorldItemState.MaxDistance
                local visible = inRange and width > 1 and height > 1
                -- Distance fade: keep nearby items fully visible, fade only near MaxDistance.
                local fadeTransparency = 0
                if WorldItemState.DistanceFade then
                    local maxDistance = math.max(WorldItemState.MaxDistance or 1500, 1)
                    -- Fade start is a world distance. Nearby ESP stays opaque,
                    -- and becomes gradually more transparent as distance grows.
                    local fadeStart = math.clamp(WorldItemState.FadeDistance or 100, 0, math.max(maxDistance - 1, 0))
                    local t = math.clamp((distance - fadeStart) / math.max(maxDistance - fadeStart, 1), 0, 1)
                    fadeTransparency = t * t * (3 - 2 * t) -- opaque nearby -> transparent farther away
                end
                entry.box.Visible = visible and WorldItemState.Box
                if entry.mainBox then entry.mainBox.Enabled = entry.box.Visible end
                if entry.outline1 then entry.outline1.Enabled = entry.box.Visible end
                if entry.outline2 then entry.outline2.Enabled = entry.box.Visible end
                if entry.box.Visible then
                    entry.box.Position = UDim2.fromOffset(minX, minY)
                    entry.box.Size = UDim2.fromOffset(width, height)
                    -- Same three-stroke/outline scheme used by Player ESP.
                    if entry.mainBox then
                        entry.mainBox.Color = WorldItemState.BoxColor
                        entry.mainBox.Enabled = true
                    end
                    if entry.mainBoxColor then
                        entry.mainBoxColor.Color = ColorSequence.new(WorldItemState.BoxColor, WorldItemState.BoxColor)
                    end
                    if entry.outline1 then
                        entry.outline1.Enabled = true
                        entry.outline1.Transparency = fadeTransparency
                    end
                    if entry.outline2 then
                        entry.outline2.Enabled = true
                        entry.outline2.Transparency = fadeTransparency
                    end
                    if entry.mainBox then entry.mainBox.Transparency = fadeTransparency end
                end
                if entry.mainBox then entry.mainBox.Transparency = fadeTransparency end
                if entry.outline1 then entry.outline1.Transparency = fadeTransparency end
                if entry.outline2 then entry.outline2.Transparency = fadeTransparency end

                entry.name.Visible = visible and WorldItemState.Name
                if entry.name.Visible then
                    local labelName = tostring(inst.Name):gsub("_", " ")
                    entry.name.Text = labelName
                    entry.name.FontFace = ESP_FONT_FACE or ESP_FONT_FALLBACK
                    entry.name.TextSize = math.clamp(ESP_FONT_SIZE or 12, 8, 24)
                    entry.name.TextColor3 = WorldItemState.TextColor
                    entry.name.TextTransparency = fadeTransparency
                    entry.name.TextStrokeTransparency = fadeTransparency
                    entry.name.Position = UDim2.fromOffset(minX + width * 0.5, minY - 2)
                    entry.name.Size = UDim2.fromOffset(math.clamp(width + 100, 100, 300), 16)
                end

                entry.distance.Visible = visible and WorldItemState.Distance
                if entry.distance.Visible then
                    entry.distance.Text = string.format("[%dm]", math.floor(distance + 0.5))
                    entry.distance.FontFace = ESP_FONT_FACE or ESP_FONT_FALLBACK
                    entry.distance.TextSize = math.clamp((ESP_FONT_SIZE or 12) - 1, 8, 23)
                    entry.distance.TextColor3 = WorldItemState.TextColor
                    entry.distance.TextTransparency = fadeTransparency
                    entry.distance.TextStrokeTransparency = fadeTransparency
                    entry.distance.Position = UDim2.fromOffset(minX + width * 0.5, minY + height + 1)
                end
            else
                entry.box.Visible = false; entry.name.Visible = false; entry.distance.Visible = false
            end
        end
    end)


    ------------------------------------------------------------
    -- CONTAINERS ESP (workspace.ILootContainers)
    ------------------------------------------------------------
    do
    local ContainersEspSection = WorldPage:Section({Name = "Containers ESP", Side = 2, Size = 360})
    local ContainersESPState = {
        Enabled = false,
        Box = true,
        Name = true,
        Distance = true,
        MaxDistance = 1500,
        DistanceFade = true,
        FadeDistance = 100,
        BoxColor = Color3.fromRGB(70, 220, 170),
        TextColor = Color3.fromRGB(255, 255, 255),
    }

    local ContainersGuiParent = CoreGui
    local OldContainersGui = ContainersGuiParent:FindFirstChild("MissSense_ContainersESP")
    if OldContainersGui then pcall(function() OldContainersGui:Destroy() end) end
    local ContainersGui = Instance.new("ScreenGui")
    ContainersGui.Name = "MissSense_ContainersESP"
    ContainersGui.ResetOnSpawn = false
    ContainersGui.IgnoreGuiInset = true
    ContainersGui.DisplayOrder = 999
    ContainersGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ContainersGui.Parent = ContainersGuiParent

    local ContainersEntries = {}
    local ContainersRefreshAt = 0
    local ContainersScanInterval = 0.35

    -- This ESP is intentionally scoped to workspace.ILootContainers. Containers
    -- do not need a matching name/keyword to be drawn.
    local function containersESPGetContainer()
        local ok, container = pcall(function()
            return workspace:FindFirstChild("ILootContainers")
        end)
        if ok and container and container.Parent == workspace then
            return container
        end
        return nil
    end

    local function containersESPHasBasePart(inst)
        if not inst then return false end
        if inst:IsA("BasePart") then return true end
        local ok, descendants = pcall(function() return inst:GetDescendants() end)
        if not ok or not descendants then return false end
        for _, descendant in ipairs(descendants) do
            if descendant:IsA("BasePart") then return true end
        end
        return false
    end

    local function containersESPHasModelOrTool(inst)
        if not inst then return false end
        local ok, descendants = pcall(function() return inst:GetDescendants() end)
        if not ok or not descendants then return false end
        for _, descendant in ipairs(descendants) do
            if descendant:IsA("Model") or descendant:IsA("Tool") then
                return true
            end
        end
        return false
    end

    local function containersESPIsPlayerCharacter(inst)
        local current = inst
        while current and current ~= workspace do
            if current:IsA("Model") then
                local ok, player = pcall(function() return Players:GetPlayerFromCharacter(current) end)
                if ok and player then return true end
            end
            current = current.Parent
        end
        return false
    end

    -- Return logical container roots rather than every descendant part; otherwise
    -- models create a separate ESP box for each mesh/part and the boxes overlap.
    local function containersESPCollectRoots(container)
        local roots = {}
        local function walk(node, isContainerRoot)
            if not node then return end
            if node:IsA("Model") or node:IsA("Tool") or node:IsA("BasePart") then
                if containersESPHasBasePart(node) and not containersESPIsPlayerCharacter(node) then
                    roots[#roots + 1] = node
                end
                return
            end

            -- Some games wrap a container as a Folder. If it contains only parts,
            -- treat the folder as one container; if it contains Models/Tools, walk
            -- down and register those as separate item roots.
            if not isContainerRoot and node:IsA("Folder")
                and containersESPHasBasePart(node) and not containersESPHasModelOrTool(node) then
                roots[#roots + 1] = node
                return
            end

            local ok, children = pcall(function() return node:GetChildren() end)
            if ok and children then
                for _, child in ipairs(children) do
                    walk(child, false)
                end
            end
        end

        if not container then return roots end
        local ok, children = pcall(function() return container:GetChildren() end)
        if ok and children then
            for _, child in ipairs(children) do
                walk(child, false)
            end
        end
        return roots
    end

    local function containersESPCreateEntry(inst)
        -- Match Player ESP's box construction: transparent holder, inner UIStroke,
        -- and two black outline strokes. Avoid the separate four-edge approximation.
        local box = Instance.new("Frame")
        box.Name = "ContainerBox"
        box.BackgroundTransparency = 1
        box.BorderSizePixel = 0
        box.Visible = false
        box.ZIndex = 20
        box.ClipsDescendants = false
        box.Parent = ContainersGui

        local boxHolder = Instance.new("Frame")
        boxHolder.Name = "BoxHolder"
        boxHolder.BackgroundTransparency = 1
        boxHolder.BorderSizePixel = 0
        boxHolder.Position = UDim2.new(0, 1, 0, 1)
        boxHolder.Size = UDim2.new(1, -2, 1, -2)
        boxHolder.ZIndex = 19
        boxHolder.Parent = box

        local boxOutlineHolder = Instance.new("Frame")
        boxOutlineHolder.Name = "BoxOutlineHolder"
        boxOutlineHolder.BackgroundTransparency = 1
        boxOutlineHolder.BorderSizePixel = 0
        boxOutlineHolder.Position = UDim2.new(0, 2, 0, 2)
        boxOutlineHolder.Size = UDim2.new(1, -4, 1, -4)
        boxOutlineHolder.ZIndex = 17
        boxOutlineHolder.Parent = box

        local mainBox = Instance.new("UIStroke")
        mainBox.Name = "MainBoxStroke"
        mainBox.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        mainBox.LineJoinMode = Enum.LineJoinMode.Miter
        mainBox.Color = ContainersESPState.BoxColor
        mainBox.Thickness = 1
        mainBox.Transparency = 0
        mainBox.Enabled = false
        mainBox.Parent = boxHolder

        local mainBoxColor = Instance.new("UIGradient")
        mainBoxColor.Name = "MainBoxGradient"
        mainBoxColor.Rotation = 0
        mainBoxColor.Color = ColorSequence.new(ContainersESPState.BoxColor, ContainersESPState.BoxColor)
        mainBoxColor.Parent = mainBox

        local outline1 = Instance.new("UIStroke")
        outline1.Name = "OuterBlackOutline"
        outline1.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        outline1.LineJoinMode = Enum.LineJoinMode.Miter
        outline1.Color = Color3.new(0, 0, 0)
        outline1.Thickness = 1
        outline1.Transparency = 0
        outline1.Enabled = false
        outline1.Parent = box

        local outline2 = Instance.new("UIStroke")
        outline2.Name = "InnerBlackOutline"
        outline2.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        outline2.LineJoinMode = Enum.LineJoinMode.Miter
        outline2.Color = Color3.new(0, 0, 0)
        outline2.Thickness = 1
        outline2.Transparency = 0
        outline2.Enabled = false
        outline2.Parent = boxOutlineHolder

        local nameLabel = Instance.new("TextLabel")
        nameLabel.Name = "ContainerName"
        nameLabel.BackgroundTransparency = 1
        nameLabel.BorderSizePixel = 0
        nameLabel.AnchorPoint = Vector2.new(0.5, 1)
        nameLabel.Size = UDim2.fromOffset(240, 16)
        nameLabel.FontFace = ESP_FONT_FACE or ESP_FONT_FALLBACK
        nameLabel.TextSize = 12
        nameLabel.TextColor3 = ContainersESPState.TextColor
        nameLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
        nameLabel.TextStrokeTransparency = 0
        nameLabel.TextXAlignment = Enum.TextXAlignment.Center
        nameLabel.TextYAlignment = Enum.TextYAlignment.Center
        nameLabel.Visible = false
        nameLabel.ZIndex = 22
        nameLabel.Parent = ContainersGui

        local distanceLabel = Instance.new("TextLabel")
        distanceLabel.Name = "ContainerDistance"
        distanceLabel.BackgroundTransparency = 1
        distanceLabel.BorderSizePixel = 0
        distanceLabel.AnchorPoint = Vector2.new(0.5, 0)
        distanceLabel.Size = UDim2.fromOffset(160, 16)
        distanceLabel.FontFace = ESP_FONT_FACE or ESP_FONT_FALLBACK
        distanceLabel.TextSize = 11
        distanceLabel.TextColor3 = ContainersESPState.TextColor
        distanceLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
        distanceLabel.TextStrokeTransparency = 0
        distanceLabel.TextXAlignment = Enum.TextXAlignment.Center
        distanceLabel.TextYAlignment = Enum.TextYAlignment.Center
        distanceLabel.Visible = false
        distanceLabel.ZIndex = 22
        distanceLabel.Parent = ContainersGui

        local entry = {
            box = box,
            boxHolder = boxHolder,
            boxOutlineHolder = boxOutlineHolder,
            mainBox = mainBox,
            mainBoxColor = mainBoxColor,
            outline1 = outline1,
            outline2 = outline2,
            name = nameLabel,
            distance = distanceLabel,
        }
        ContainersEntries[inst] = entry
        return entry
    end

    local function containersESPRemoveEntry(inst)
        local entry = ContainersEntries[inst]
        if not entry then return end
        for _, object in pairs(entry) do
            pcall(function() object:Destroy() end)
        end
        ContainersEntries[inst] = nil
    end

    local function containersESPBounds(inst)
        if not inst or not inst.Parent then return nil, nil end
        if inst:IsA("BasePart") then return inst.CFrame, inst.Size end
        if inst:IsA("Model") then
            local ok, cf, size = pcall(function() return inst:GetBoundingBox() end)
            if ok and cf and size then return cf, size end
        end
        -- Tools and other pickup instances may not implement GetBoundingBox;
        -- approximate a world-aligned box from their BasePart descendants.
        local minV, maxV, partCount = nil, nil, 0
        local descendants = {}
        if inst:IsA("BasePart") then
            descendants[1] = inst
        else
            local ok, result = pcall(function() return inst:GetDescendants() end)
            if ok and result then descendants = result end
        end
        for _, part in ipairs(descendants) do
            if part:IsA("BasePart") then
                partCount += 1
                local half = part.Size * 0.5
                for _, sx in ipairs({-1, 1}) do
                    for _, sy in ipairs({-1, 1}) do
                        for _, sz in ipairs({-1, 1}) do
                            local point = part.CFrame:PointToWorldSpace(Vector3.new(half.X * sx, half.Y * sy, half.Z * sz))
                            minV = minV and Vector3.new(math.min(minV.X, point.X), math.min(minV.Y, point.Y), math.min(minV.Z, point.Z)) or point
                            maxV = maxV and Vector3.new(math.max(maxV.X, point.X), math.max(maxV.Y, point.Y), math.max(maxV.Z, point.Z)) or point
                        end
                    end
                end
            end
        end
        if partCount == 0 or not minV or not maxV then return nil, nil end
        local center = (minV + maxV) * 0.5
        return CFrame.new(center), maxV - minV
    end

    local function containersESPProject(inst, camera)
        local cf, size = containersESPBounds(inst)
        if not cf or not size then return nil end
        local minX, minY, maxX, maxY = math.huge, math.huge, -math.huge, -math.huge
        local frontCount = 0
        for _, sx in ipairs({-1, 1}) do
            for _, sy in ipairs({-1, 1}) do
                for _, sz in ipairs({-1, 1}) do
                    local worldPoint = (cf * CFrame.new(size.X * 0.5 * sx, size.Y * 0.5 * sy, size.Z * 0.5 * sz)).Position
                    local point, onScreen = camera:WorldToViewportPoint(worldPoint)
                    if point.Z > 0 then
                        frontCount += 1
                        minX, minY = math.min(minX, point.X), math.min(minY, point.Y)
                        maxX, maxY = math.max(maxX, point.X), math.max(maxY, point.Y)
                    end
                end
            end
        end
        if frontCount == 0 then return nil end
        if minX == math.huge or minY == math.huge or maxX == -math.huge or maxY == -math.huge then
            return nil
        end
        local viewport = camera.ViewportSize
        if maxX < 0 or maxY < 0 or minX > viewport.X or minY > viewport.Y then return nil end
        minX, minY = math.clamp(minX, 0, viewport.X), math.clamp(minY, 0, viewport.Y)
        maxX, maxY = math.clamp(maxX, 0, viewport.X), math.clamp(maxY, 0, viewport.Y)
        if maxX - minX < 2 then maxX = math.min(viewport.X, minX + 2) end
        if maxY - minY < 2 then maxY = math.min(viewport.Y, minY + 2) end
        return minX, minY, maxX - minX, maxY - minY, cf.Position
    end

    ContainersEspSection:Toggle({
        Name = "Enabled", Flag = "ContainerESPEnabled", Default = false,
        Callback = function(v) ContainersESPState.Enabled = v end
    })
    local containerBoxToggle = ContainersEspSection:Toggle({
        Name = "Box", Flag = "ContainerESPBox", Default = true,
        Callback = function(v) ContainersESPState.Box = v end
    })
    containerBoxToggle:Colorpicker({
        Name = "Box color", Flag = "ContainerESPBoxColor",
        Default = ContainersESPState.BoxColor,
        Callback = function(c) if typeof(c) == "Color3" then ContainersESPState.BoxColor = c end end
    })
    local containerNameToggle = ContainersEspSection:Toggle({
        Name = "Name", Flag = "ContainerESPName", Default = true,
        Callback = function(v) ContainersESPState.Name = v end
    })
    containerNameToggle:Colorpicker({
        Name = "Text color", Flag = "ContainerESPTextColor",
        Default = ContainersESPState.TextColor,
        Callback = function(c) if typeof(c) == "Color3" then ContainersESPState.TextColor = c end end
    })
    ContainersEspSection:Toggle({
        Name = "Distance", Flag = "ContainerESPDistance", Default = true,
        Callback = function(v) ContainersESPState.Distance = v end
    })
    ContainersEspSection:Slider({
        Name = "Max distance", Flag = "ContainerESPMaxDistance",
        Min = 100, Max = 5000, Default = 1500, Decimals = 1, Suffix = " studs",
        Callback = function(v) if type(v) == "number" then ContainersESPState.MaxDistance = math.clamp(v, 100, 5000) end end
    })
    ContainersEspSection:Toggle({
        Name = "Distance fade", Flag = "ContainerESPDistanceFade", Default = true,
        Callback = function(v) ContainersESPState.DistanceFade = v end
    })
    ContainersEspSection:Slider({
        Name = "Fade start distance", Flag = "ContainerESPFadeDistance",
        Min = 10, Max = 3000, Default = 100, Decimals = 1, Suffix = " studs",
        Callback = function(v) if type(v) == "number" then ContainersESPState.FadeDistance = math.clamp(v, 10, 3000) end end
    })

    bind(RunService.RenderStepped, function()
        if not ContainersGui or not ContainersGui.Parent then return end
        if not ContainersESPState.Enabled then
            for _, entry in pairs(ContainersEntries) do
                entry.box.Visible = false
                entry.name.Visible = false
                entry.distance.Visible = false
            end
            return
        end

        local now = os.clock()
        if now >= ContainersRefreshAt then
            ContainersRefreshAt = now + ContainersScanInterval
            local seen = {}
            local containerFolder = containersESPGetContainer()
            if containerFolder then
                for _, inst in ipairs(containersESPCollectRoots(containerFolder)) do
                    if inst and inst.Parent and inst:IsDescendantOf(containerFolder) then
                        seen[inst] = true
                        if not ContainersEntries[inst] then
                            containersESPCreateEntry(inst)
                        end
                    end
                end
            end
            -- Remove stale entries when containers despawn or ILootContainers disappears.
            for inst in pairs(ContainersEntries) do
                local stillInside = false
                if containerFolder and inst and inst.Parent then
                    local ok, inside = pcall(function() return inst:IsDescendantOf(containerFolder) end)
                    stillInside = ok and inside
                end
                if not seen[inst] or not stillInside then
                    containersESPRemoveEntry(inst)
                end
            end
        end

        local camera = workspace.CurrentCamera
        local character = LocalPlayer and LocalPlayer.Character
        local playerPosition = nil

        -- Prefer the character root while alive. During death/respawn Character
        -- or HumanoidRootPart can be nil, so use the current camera as fallback.
        if character then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            local characterAlive = not humanoid or humanoid.Health > 0
            if characterAlive then
                local characterRoot = character:FindFirstChild("HumanoidRootPart")
                    or character:FindFirstChildWhichIsA("BasePart")
                if characterRoot and characterRoot:IsA("BasePart") then
                    playerPosition = characterRoot.Position
                end
            end
        end
        -- On death use the camera position even if a dead character model/root
        -- still exists; that is what the player is actually viewing from.
        if not playerPosition and camera then
            playerPosition = camera.CFrame.Position
        end

        if not camera or not playerPosition then
            for _, entry in pairs(ContainersEntries) do
                entry.box.Visible = false; entry.name.Visible = false; entry.distance.Visible = false
            end
            return
        end

        for inst, entry in pairs(ContainersEntries) do
            local success, minX, minY, width, height, worldPosition = pcall(containersESPProject, inst, camera)
            if success and minX and worldPosition then
                local distance = (playerPosition - worldPosition).Magnitude
                local inRange = distance <= ContainersESPState.MaxDistance
                local visible = inRange and width > 1 and height > 1
                -- Distance fade: keep nearby containers fully visible, fade only near MaxDistance.
                local fadeTransparency = 0
                if ContainersESPState.DistanceFade then
                    local maxDistance = math.max(ContainersESPState.MaxDistance or 1500, 1)
                    -- Fade start is a world distance. Nearby ESP stays opaque,
                    -- and becomes gradually more transparent as distance grows.
                    local fadeStart = math.clamp(ContainersESPState.FadeDistance or 100, 0, math.max(maxDistance - 1, 0))
                    local t = math.clamp((distance - fadeStart) / math.max(maxDistance - fadeStart, 1), 0, 1)
                    fadeTransparency = t * t * (3 - 2 * t) -- opaque nearby -> transparent farther away
                end
                entry.box.Visible = visible and ContainersESPState.Box
                if entry.mainBox then entry.mainBox.Enabled = entry.box.Visible end
                if entry.outline1 then entry.outline1.Enabled = entry.box.Visible end
                if entry.outline2 then entry.outline2.Enabled = entry.box.Visible end
                if entry.box.Visible then
                    entry.box.Position = UDim2.fromOffset(minX, minY)
                    entry.box.Size = UDim2.fromOffset(width, height)
                    -- Same three-stroke/outline scheme used by Player ESP.
                    if entry.mainBox then
                        entry.mainBox.Color = ContainersESPState.BoxColor
                        entry.mainBox.Enabled = true
                    end
                    if entry.mainBoxColor then
                        entry.mainBoxColor.Color = ColorSequence.new(ContainersESPState.BoxColor, ContainersESPState.BoxColor)
                    end
                    if entry.outline1 then
                        entry.outline1.Enabled = true
                        entry.outline1.Transparency = fadeTransparency
                    end
                    if entry.outline2 then
                        entry.outline2.Enabled = true
                        entry.outline2.Transparency = fadeTransparency
                    end
                    if entry.mainBox then entry.mainBox.Transparency = fadeTransparency end
                end
                if entry.mainBox then entry.mainBox.Transparency = fadeTransparency end
                if entry.outline1 then entry.outline1.Transparency = fadeTransparency end
                if entry.outline2 then entry.outline2.Transparency = fadeTransparency end

                entry.name.Visible = visible and ContainersESPState.Name
                if entry.name.Visible then
                    local labelName = tostring(inst.Name):gsub("_", " ")
                    entry.name.Text = labelName
                    entry.name.FontFace = ESP_FONT_FACE or ESP_FONT_FALLBACK
                    entry.name.TextSize = math.clamp(ESP_FONT_SIZE or 12, 8, 24)
                    entry.name.TextColor3 = ContainersESPState.TextColor
                    entry.name.TextTransparency = fadeTransparency
                    entry.name.TextStrokeTransparency = fadeTransparency
                    entry.name.Position = UDim2.fromOffset(minX + width * 0.5, minY - 2)
                    entry.name.Size = UDim2.fromOffset(math.clamp(width + 100, 100, 300), 16)
                end

                entry.distance.Visible = visible and ContainersESPState.Distance
                if entry.distance.Visible then
                    entry.distance.Text = string.format("[%dm]", math.floor(distance + 0.5))
                    entry.distance.FontFace = ESP_FONT_FACE or ESP_FONT_FALLBACK
                    entry.distance.TextSize = math.clamp((ESP_FONT_SIZE or 12) - 1, 8, 23)
                    entry.distance.TextColor3 = ContainersESPState.TextColor
                    entry.distance.TextTransparency = fadeTransparency
                    entry.distance.TextStrokeTransparency = fadeTransparency
                    entry.distance.Position = UDim2.fromOffset(minX + width * 0.5, minY + height + 1)
                end
            else
                entry.box.Visible = false; entry.name.Visible = false; entry.distance.Visible = false
            end
        end
    end)

    end

    local WorldLeft = WorldPage:Section({Name = "world modulation", Side = 1, Size = 900})
    local WorldRight = WorldPage:Section({Name = "world visuals", Side = 2, Size = 900})

    local WorldState = {
        Ambience = false, Ambience1 = Color3.fromRGB(117, 76, 236), Ambience2 = Color3.fromRGB(117, 76, 236),
        Colorshift = false, ShiftTop = Color3.fromRGB(255, 0, 0), ShiftBottom = Color3.fromRGB(255, 0, 0),
        Exposure = false, ExposureAmount = 0, Time = false, TimeValue = 12,
        Shadows = true, Bloom = false, BloomIntensity = 15, BloomSize = 15, BloomThreshold = 100,
        Modulation = false, Saturation = 0, Contrast = 0, Brightness = 0, Tint = Color3.fromRGB(255, 255, 255),
        Atmosphere = false, Density = 0.3, Haze = 0, Glare = 0,
        Skybox = "None", CustomSkybox = {SkyboxBk = "", SkyboxDn = "", SkyboxFt = "", SkyboxLf = "", SkyboxRt = "", SkyboxUp = ""},
        Weather = "Clear", Fog = false, FogStartValue = 0, FogEndValue = 1000, FogColorValue = Color3.fromRGB(190, 205, 220),
        Clouds = false, CloudCover = 0.5, CloudDensity = 0.5, CloudColor = Color3.fromRGB(255, 255, 255),
        SunRays = false, SunRaysIntensity = 0.1, SunRaysSpread = 0.8,
        DepthOfField = false, DOFFar = 1000, DOFNear = 0, DOFIntensity = 0.2
    }

    local WorldCache = {
        Ambient = Lighting.Ambient, OutdoorAmbient = Lighting.OutdoorAmbient,
        Exposure = Lighting.ExposureCompensation, ColorShiftTop = Lighting.ColorShift_Top,
        ColorShiftBottom = Lighting.ColorShift_Bottom, ClockTime = Lighting.ClockTime,
        GlobalShadows = Lighting.GlobalShadows, Brightness = Lighting.Brightness,
        FogColor = Lighting.FogColor, FogStart = Lighting.FogStart, FogEnd = Lighting.FogEnd,
        Technology = nil, LightingStyle = nil,
        SunRays = nil, DOF = nil, Clouds = nil,
        FogColor = Lighting.FogColor, FogStart = Lighting.FogStart, FogEnd = Lighting.FogEnd
    }
    pcall(function() WorldCache.Technology = Lighting.Technology end)
    pcall(function() WorldCache.LightingStyle = Lighting.LightingStyle end)

    local WorldBloom = Lighting:FindFirstChild("MissSense_WorldBloom")
    if not WorldBloom then
        WorldBloom = Instance.new("BloomEffect")
        WorldBloom.Name = "MissSense_WorldBloom"
        WorldBloom.Enabled = false
        WorldBloom.Parent = Lighting
    end
    local WorldCorrection = Lighting:FindFirstChild("MissSense_WorldModulation")
    if not WorldCorrection then
        WorldCorrection = Instance.new("ColorCorrectionEffect")
        WorldCorrection.Name = "MissSense_WorldModulation"
        WorldCorrection.Enabled = false
        WorldCorrection.Parent = Lighting
    end
    local WorldAtmosphere = Lighting:FindFirstChild("MissSense_WorldAtmosphere")
    if not WorldAtmosphere then
        WorldAtmosphere = Instance.new("Atmosphere")
        WorldAtmosphere.Name = "MissSense_WorldAtmosphere"
        WorldAtmosphere.Parent = Lighting
    end

    local WorldSunRays = Lighting:FindFirstChild("MissSense_WorldSunRays")
    if not WorldSunRays then
        WorldSunRays = Instance.new("SunRaysEffect")
        WorldSunRays.Name = "MissSense_WorldSunRays"
        WorldSunRays.Enabled = false
        WorldSunRays.Parent = Lighting
    end
    local WorldDOF = Lighting:FindFirstChild("MissSense_WorldDOF")
    if not WorldDOF then
        WorldDOF = Instance.new("DepthOfFieldEffect")
        WorldDOF.Name = "MissSense_WorldDOF"
        WorldDOF.Enabled = false
        WorldDOF.Parent = Lighting
    end
    local Terrain = workspace:FindFirstChildOfClass("Terrain")
    local WorldClouds = Terrain and Terrain:FindFirstChildOfClass("Clouds")
    local CloudsCreated = false
    if not WorldClouds and Terrain then
        WorldClouds = Instance.new("Clouds")
        WorldClouds.Name = "MissSense_WorldClouds"
        WorldClouds.Enabled = false
        WorldClouds.Parent = Terrain
        CloudsCreated = true
    end
    local CloudCache = {}
    if WorldClouds then
        pcall(function() CloudCache.Cover = WorldClouds.Cover; CloudCache.Density = WorldClouds.Density; CloudCache.Color = WorldClouds.Color end)
    end
    local SunRaysCache = {Enabled = WorldSunRays.Enabled, Intensity = WorldSunRays.Intensity, Spread = WorldSunRays.Spread}
    local DOFCache = {Enabled = WorldDOF.Enabled, FarIntensity = WorldDOF.FarIntensity, NearIntensity = WorldDOF.NearIntensity, FocusDistance = WorldDOF.FocusDistance, InFocusRadius = WorldDOF.InFocusRadius}

    local SkyPresets = {
        ["Default"] = {
            SkyboxLf = "rbxassetid://148943339", SkyboxBk = "rbxassetid://148943390", SkyboxDn = "rbxassetid://148943362",
            SkyboxFt = "rbxassetid://148943404", SkyboxRt = "rbxassetid://148943379", SkyboxUp = "rbxassetid://148943410"
        },
        ["Nebula"] = {
            SkyboxLf = "rbxassetid://159454286", SkyboxBk = "rbxassetid://159454299", SkyboxDn = "rbxassetid://159454296",
            SkyboxFt = "rbxassetid://159454293", SkyboxRt = "rbxassetid://159454300", SkyboxUp = "rbxassetid://159454288"
        },
        ["Blue Nebula"] = {
            SkyboxBk = "rbxassetid://79187608916257", SkyboxDn = "rbxassetid://79187608916257", SkyboxFt = "rbxassetid://135345543970829",
            SkyboxLf = "rbxassetid://130684897818024", SkyboxRt = "rbxassetid://134117814265945", SkyboxUp = "rbxassetid://128019898265074"
        },
        ["Setting Hills"] = {
            SkyboxLf = "rbxassetid://264909758", SkyboxBk = "rbxassetid://264908339", SkyboxDn = "rbxassetid://264907909",
            SkyboxFt = "rbxassetid://264909420", SkyboxRt = "rbxassetid://264908886", SkyboxUp = "rbxassetid://264907379"
        },
        ["Blue Aurora"] = {
            SkyboxBk = "rbxassetid://12064107", SkyboxDn = "rbxassetid://12064152", SkyboxFt = "rbxassetid://12064121",
            SkyboxLf = "rbxassetid://12063984", SkyboxRt = "rbxassetid://12064115", SkyboxUp = "rbxassetid://12064131"
        },
        ["Red Aurora"] = {
            SkyboxBk = "rbxassetid://401664839", SkyboxDn = "rbxassetid://401664862", SkyboxFt = "rbxassetid://401664960",
            SkyboxLf = "rbxassetid://401664881", SkyboxRt = "rbxassetid://401664901", SkyboxUp = "rbxassetid://401664936"
        },
        ["Pink Vision"] = {
            SkyboxBk = "rbxassetid://6593929026", SkyboxDn = "rbxassetid://6593930140", SkyboxFt = "rbxassetid://6593931249",
            SkyboxLf = "rbxassetid://6593932587", SkyboxRt = "rbxassetid://6593933789", SkyboxUp = "rbxassetid://6593935319"
        },
        ["Twillight"] = {
            SkyboxBk = "rbxassetid://570557514", SkyboxDn = "rbxassetid://570557775", SkyboxFt = "rbxassetid://570557559",
            SkyboxLf = "rbxassetid://570557620", SkyboxRt = "rbxassetid://570557672", SkyboxUp = "rbxassetid://570557727"
        },
        ["Distopia"] = {
            SkyboxBk = "rbxassetid://2240134413", SkyboxDn = "rbxassetid://2240136039", SkyboxFt = "rbxassetid://2240130790",
            SkyboxLf = "rbxassetid://2240133550", SkyboxRt = "rbxassetid://2240132643", SkyboxUp = "rbxassetid://2240135222"
        },
        ["Peaceful"] = {
            SkyboxBk = "rbxassetid://73252679982122", SkyboxDn = "rbxassetid://101074061181553", SkyboxFt = "rbxassetid://112572775732134",
            SkyboxLf = "rbxassetid://126931573973019", SkyboxRt = "rbxassetid://135908172504233", SkyboxUp = "rbxassetid://124514468649717"
        }
    }
    -- Correct the literal above without relying on a game-specific sky object.
    SkyPresets.Twillight.SkyboxFt = "rbxassetid://570557559"

    local SkyObject = Lighting:FindFirstChildOfClass("Sky")
    local SkyCreated = false
    local SkyCache = {}
    local SkyCacheCaptured = false
    local function captureOriginalSky(sky)
        if not sky or SkyCacheCaptured then return end
        for property in pairs(SkyPresets.Default) do
            pcall(function() SkyCache[property] = sky[property] end)
        end
        SkyCacheCaptured = true
    end
    -- Capture the original sky now when possible; if the game creates its Sky
    -- after this script starts, capture it lazily before changing any properties.
    if SkyObject then captureOriginalSky(SkyObject) end

    local function applyWorld()
        pcall(function()
            Lighting.Ambient = WorldState.Ambience and WorldState.Ambience1 or WorldCache.Ambient
            Lighting.OutdoorAmbient = WorldState.Ambience and WorldState.Ambience2 or WorldCache.OutdoorAmbient
            Lighting.ExposureCompensation = WorldState.Exposure and WorldState.ExposureAmount or WorldCache.Exposure
            Lighting.ColorShift_Top = WorldState.Colorshift and WorldState.ShiftTop or WorldCache.ColorShiftTop
            Lighting.ColorShift_Bottom = WorldState.Colorshift and WorldState.ShiftBottom or WorldCache.ColorShiftBottom
            Lighting.ClockTime = WorldState.Time and WorldState.TimeValue or WorldCache.ClockTime
            Lighting.GlobalShadows = WorldState.Shadows
        end)
        WorldBloom.Enabled = WorldState.Bloom
        WorldBloom.Intensity = WorldState.BloomIntensity * 0.01
        WorldBloom.Size = WorldState.BloomSize * 0.56
        WorldBloom.Threshold = WorldState.BloomThreshold * 0.0025

        WorldCorrection.Enabled = WorldState.Modulation
        WorldCorrection.Saturation = WorldState.Saturation
        WorldCorrection.Contrast = WorldState.Contrast
        WorldCorrection.Brightness = WorldState.Brightness
        WorldCorrection.TintColor = WorldState.Tint

        -- Legacy Lighting fog is ignored/weak with some modern lighting setups,
        -- so drive the local Atmosphere as well. Preserve atmosphere modulation
        -- when it is enabled and restore the original fog when Custom Fog is off.
        local fogEnabled = WorldState.Fog == true
        local fogRange = math.max(1, WorldState.FogEndValue - WorldState.FogStartValue)
        local fogDensity = fogEnabled and math.clamp(0.45 - (fogRange / 5000) * 0.35, 0.08, 0.42) or 0
        WorldAtmosphere.Density = math.max(WorldState.Atmosphere and WorldState.Density or 0, fogDensity)
        WorldAtmosphere.Haze = math.max(WorldState.Atmosphere and WorldState.Haze or 0, fogEnabled and 1.5 or 0)
        WorldAtmosphere.Glare = math.max(WorldState.Atmosphere and WorldState.Glare or 0, fogEnabled and 0 or 0)
        if fogEnabled then
            WorldAtmosphere.Color = WorldState.FogColorValue
            WorldAtmosphere.Decay = WorldState.FogColorValue
        end
        pcall(function()
            Lighting.FogColor = fogEnabled and WorldState.FogColorValue or WorldCache.FogColor
            Lighting.FogStart = fogEnabled and WorldState.FogStartValue or WorldCache.FogStart
            Lighting.FogEnd = fogEnabled and math.max(WorldState.FogStartValue + 1, WorldState.FogEndValue) or WorldCache.FogEnd
        end)
        if WorldClouds then
            pcall(function()
                WorldClouds.Enabled = WorldState.Clouds
                WorldClouds.Cover = WorldState.CloudCover
                WorldClouds.Density = WorldState.CloudDensity
                WorldClouds.Color = WorldState.CloudColor
            end)
        end
        WorldSunRays.Enabled = WorldState.SunRays
        WorldSunRays.Intensity = WorldState.SunRaysIntensity
        WorldSunRays.Spread = WorldState.SunRaysSpread
        WorldDOF.Enabled = WorldState.DepthOfField
        WorldDOF.FarIntensity = WorldState.DOFFar
        WorldDOF.NearIntensity = WorldState.DOFNear
    end

    local function applySkybox()
        -- "None" means do not force any preset: restore the game's original sky.
        if WorldState.Skybox == "None" then
            if SkyObject and SkyObject.Parent then
                if SkyCreated then
                    -- This Sky was created by MissSense because the game had no
                    -- Sky object at the time; remove it when returning to None.
                    SkyObject:Destroy()
                    SkyObject = nil
                    SkyCreated = false
                elseif SkyCacheCaptured then
                    -- Restore the actual game sky, not a hard-coded Stock preset.
                    for property, value in pairs(SkyCache) do
                        pcall(function() SkyObject[property] = value end)
                    end
                end
            else
                -- The game's Sky may have been recreated while a preset was active.
                local currentSky = Lighting:FindFirstChildOfClass("Sky")
                if currentSky and not SkyCreated then
                    SkyObject = currentSky
                    captureOriginalSky(SkyObject)
                    for property, value in pairs(SkyCache) do
                        pcall(function() SkyObject[property] = value end)
                    end
                end
            end
            return
        end

        local preset = WorldState.Skybox == "Custom" and WorldState.CustomSkybox or SkyPresets[WorldState.Skybox]
        if not preset then return end
        if not SkyObject or not SkyObject.Parent then
            SkyObject = Lighting:FindFirstChildOfClass("Sky")
            if SkyObject then
                if not SkyCreated then captureOriginalSky(SkyObject) end
            else
                SkyObject = Instance.new("Sky")
                SkyObject.Name = "MissSense_CustomSky"
                SkyObject.Parent = Lighting
                SkyCreated = true
            end
        elseif not SkyCreated then
            captureOriginalSky(SkyObject)
        end
        for property, value in pairs(preset) do
            pcall(function() SkyObject[property] = value end)
        end
    end

    -- Local weather particles: visual-only effects around the local camera.
    local RunService = game:GetService("RunService")
    local WeatherState = {Mode = "None", Part = nil, Attachment = nil, Emitter = nil, Follow = nil}
    local function clearWeather()
        if WeatherState.Follow then WeatherState.Follow:Disconnect(); WeatherState.Follow = nil end
        if WeatherState.Part then pcall(function() WeatherState.Part:Destroy() end); WeatherState.Part = nil end
        WeatherState.Attachment = nil
        WeatherState.Emitter = nil
    end
    local function setWeather(mode)
        WeatherState.Mode = mode
        clearWeather()
        if mode == "None" then return end
        local camera = workspace.CurrentCamera
        if not camera then return end
        local part = Instance.new("Part")
        part.Name = "MissSense_LocalWeather"
        part.Anchored = true
        part.CanCollide = false
        part.CanQuery = false
        part.CanTouch = false
        part.Transparency = 1
        part.Size = Vector3.new(1, 1, 1)
        part.CFrame = camera.CFrame
        part.Parent = workspace
        local attachment = Instance.new("Attachment")
        attachment.Parent = part
        local emitter = Instance.new("ParticleEmitter")
        emitter.Name = "MissSense_WeatherParticles"
        emitter.Enabled = true
        emitter.LockedToPart = false
        emitter.EmissionDirection = Enum.NormalId.Bottom
        emitter.SpreadAngle = Vector2.new(7, 7)
        emitter.Acceleration = Vector3.new(0, -18, 0)
        emitter.Rate = mode == "Light Rain" and 90 or (mode == "Rain" and 260 or 65)
        emitter.Lifetime = mode == "Snow" and NumberRange.new(3, 5) or NumberRange.new(1.1, 1.8)
        emitter.Speed = mode == "Snow" and NumberRange.new(5, 9) or (mode == "Light Rain" and NumberRange.new(75, 95) or NumberRange.new(105, 130))
        emitter.Size = mode == "Snow" and NumberSequence.new(0.18, 0.28) or NumberSequence.new(0.045, 0.07)
        emitter.Transparency = mode == "Snow" and NumberSequence.new(0.1, 0.25) or NumberSequence.new(0.15, 0.35)
        emitter.Color = ColorSequence.new(mode == "Snow" and Color3.fromRGB(235, 245, 255) or Color3.fromRGB(175, 205, 235))
        emitter.Texture = mode == "Snow" and "rbxasset://textures/particles/sparkles_main.dds" or "rbxassetid://241876013"
        emitter.Rotation = NumberRange.new(0, 360)
        emitter.RotSpeed = mode == "Snow" and NumberRange.new(-35, 35) or NumberRange.new(0, 0)
        emitter.Parent = attachment
        WeatherState.Part = part
        WeatherState.Attachment = attachment
        WeatherState.Emitter = emitter
        WeatherState.Follow = RunService.RenderStepped:Connect(function()
            if WeatherState.Part and workspace.CurrentCamera then
                WeatherState.Part.CFrame = workspace.CurrentCamera.CFrame * CFrame.new(0, mode == "Snow" and 16 or 20, 0)
            end
        end)
    end
    WorldLeft:Dropdown({Name = "Weather", Flag = "World_Weather", Items = {"None", "Light Rain", "Rain", "Snow"}, Default = "None", Multi = false, Callback = setWeather})
    WorldLeft:Toggle({Name = "Custom Fog", Flag = "World_Fog", Default = false, Callback = function(v) WorldState.Fog = v; applyWorld() end})
    WorldLeft:Label({Name = "Fog color"}):Colorpicker({Name = "Fog color", Flag = "World_FogColor", Default = WorldState.FogColorValue, Callback = function(v) WorldState.FogColorValue = v; applyWorld() end})
    WorldLeft:Slider({Name = "Fog start", Flag = "World_FogStart", Min = 0, Max = 1000, Default = 0, Decimals = 1, Callback = function(v) WorldState.FogStartValue = v; applyWorld() end})
    WorldLeft:Slider({Name = "Fog end", Flag = "World_FogEnd", Min = 50, Max = 5000, Default = 1000, Decimals = 1, Callback = function(v) WorldState.FogEndValue = v; applyWorld() end})
    WorldLeft:Toggle({Name = "Volumetric clouds", Flag = "World_Clouds", Default = false, Callback = function(v) WorldState.Clouds = v; applyWorld() end})
    WorldLeft:Slider({Name = "Cloud cover", Flag = "World_CloudCover", Min = 0, Max = 1, Default = 0.5, Decimals = 0.01, Callback = function(v) WorldState.CloudCover = v; applyWorld() end})
    WorldLeft:Slider({Name = "Cloud density", Flag = "World_CloudDensity", Min = 0, Max = 1, Default = 0.5, Decimals = 0.01, Callback = function(v) WorldState.CloudDensity = v; applyWorld() end})
    WorldLeft:Label({Name = "Cloud color"}):Colorpicker({Name = "Cloud color", Flag = "World_CloudColor", Default = WorldState.CloudColor, Callback = function(v) WorldState.CloudColor = v; applyWorld() end})
    WorldLeft:Toggle({Name = "Sun rays", Flag = "World_SunRays", Default = false, Callback = function(v) WorldState.SunRays = v; applyWorld() end})
    WorldLeft:Slider({Name = "Sun rays intensity", Flag = "World_SunRaysIntensity", Min = 0, Max = 1, Default = 0.1, Decimals = 0.01, Callback = function(v) WorldState.SunRaysIntensity = v; applyWorld() end})
    WorldLeft:Slider({Name = "Sun rays spread", Flag = "World_SunRaysSpread", Min = 0, Max = 1, Default = 0.8, Decimals = 0.01, Callback = function(v) WorldState.SunRaysSpread = v; applyWorld() end})

    WorldRight:Toggle({Name = "Depth of field", Flag = "World_DOF", Default = false, Callback = function(v) WorldState.DepthOfField = v; applyWorld() end})
    WorldRight:Slider({Name = "DOF far intensity", Flag = "World_DOFFar", Min = 0, Max = 1, Default = 0.2, Decimals = 0.01, Callback = function(v) WorldState.DOFFar = v; applyWorld() end})
    WorldRight:Slider({Name = "DOF near intensity", Flag = "World_DOFNear", Min = 0, Max = 1, Default = 0, Decimals = 0.01, Callback = function(v) WorldState.DOFNear = v; applyWorld() end})

    WorldLeft:Toggle({Name = "Custom Ambience", Flag = "World_Ambience", Default = false, Callback = function(v) WorldState.Ambience = v; applyWorld() end})
    WorldLeft:Label({Name = "Ambience color 1"}):Colorpicker({Name = "Ambience color 1", Flag = "World_Ambience1", Default = WorldState.Ambience1, Callback = function(v) WorldState.Ambience1 = v; applyWorld() end})
    WorldLeft:Label({Name = "Ambience color 2"}):Colorpicker({Name = "Ambience color 2", Flag = "World_Ambience2", Default = WorldState.Ambience2, Callback = function(v) WorldState.Ambience2 = v; applyWorld() end})
    WorldLeft:Toggle({Name = "Custom Colorshift", Flag = "World_Colorshift", Default = false, Callback = function(v) WorldState.Colorshift = v; applyWorld() end})
    WorldLeft:Label({Name = "Colorshift top"}):Colorpicker({Name = "Colorshift top", Flag = "World_ShiftTop", Default = WorldState.ShiftTop, Callback = function(v) WorldState.ShiftTop = v; applyWorld() end})
    WorldLeft:Label({Name = "Colorshift bottom"}):Colorpicker({Name = "Colorshift bottom", Flag = "World_ShiftBottom", Default = WorldState.ShiftBottom, Callback = function(v) WorldState.ShiftBottom = v; applyWorld() end})
    WorldLeft:Toggle({Name = "Custom Exposure", Flag = "World_Exposure", Default = false, Callback = function(v) WorldState.Exposure = v; applyWorld() end})
    WorldLeft:Slider({Name = "Exposure amount", Flag = "World_ExposureAmount", Min = -2, Max = 3, Default = 0, Decimals = 0.01, Suffix = "", Callback = function(v) WorldState.ExposureAmount = v; applyWorld() end})
    WorldLeft:Toggle({Name = "Custom Time", Flag = "World_Time", Default = false, Callback = function(v) WorldState.Time = v; applyWorld() end})
    WorldLeft:Slider({Name = "Time of day", Flag = "World_TimeValue", Min = 0, Max = 24, Default = 12, Decimals = 0.1, Suffix = "h", Callback = function(v) WorldState.TimeValue = v; applyWorld() end})
    WorldLeft:Toggle({Name = "Global shadows", Flag = "World_Shadows", Default = true, Callback = function(v) WorldState.Shadows = v; applyWorld() end})

    WorldRight:Toggle({Name = "Bloom", Flag = "World_Bloom", Default = false, Callback = function(v) WorldState.Bloom = v; applyWorld() end})
    WorldRight:Slider({Name = "Bloom intensity", Flag = "World_BloomIntensity", Min = 0, Max = 100, Default = 15, Decimals = 0.1, Callback = function(v) WorldState.BloomIntensity = v; applyWorld() end})
    WorldRight:Slider({Name = "Bloom size", Flag = "World_BloomSize", Min = 0, Max = 100, Default = 15, Decimals = 0.1, Callback = function(v) WorldState.BloomSize = v; applyWorld() end})
    WorldRight:Slider({Name = "Bloom threshold", Flag = "World_BloomThreshold", Min = 0, Max = 100, Default = 100, Decimals = 0.1, Callback = function(v) WorldState.BloomThreshold = v; applyWorld() end})
    -- Skybox presets copied from constantpf.lua; None restores the game's original sky.
    -- Keep this dropdown in the custom-sky section so it is visible next to the custom controls.
    local CustomSkySection = WorldPage:Section({Name = "custom skybox", Side = 2, Size = 340})
    CustomSkySection:Dropdown({Name = "Skybox", Flag = "World_Skybox", Items = {"None", "Nebula", "Blue Nebula", "Setting Hills", "Blue Aurora", "Red Aurora", "Pink Vision", "Twillight", "Distopia", "Peaceful"}, Default = "None", Multi = false, Callback = function(v)
        WorldState.Skybox = v
        WorldState.CustomSkyboxEnabled = false
        applySkybox()
    end})

    -- Custom skybox editor: Roblox Sky uses a separate image asset for each face.
    local CustomSkyboxInputCreated = false
    local SkyFaceFields = {
        {key = "SkyboxBk", label = "Back"}, {key = "SkyboxDn", label = "Down"},
        {key = "SkyboxFt", label = "Front"}, {key = "SkyboxLf", label = "Left"},
        {key = "SkyboxRt", label = "Right"}, {key = "SkyboxUp", label = "Up"}
    }
    local function setCustomSkyFace(face, value)
        value = tostring(value or ""):gsub("%s+", "")
        if value ~= "" and not value:match("^rbxassetid://%d+$") and not value:match("^%d+$") then return end
        if value:match("^%d+$") then value = "rbxassetid://" .. value end
        WorldState.CustomSkybox[face] = value
        local complete = true
        for _, field in ipairs(SkyFaceFields) do
            if not WorldState.CustomSkybox[field.key] or WorldState.CustomSkybox[field.key] == "" then complete = false; break end
        end
        if complete and WorldState.CustomSkyboxEnabled then
            WorldState.Skybox = "Custom"
            applySkybox()
        end
    end
    CustomSkySection:Toggle({Name = "Custom Skybox", Flag = "World_CustomSkyboxEnabled", Default = false, Callback = function(v)
        WorldState.CustomSkyboxEnabled = v
        if v then
            WorldState.Skybox = "Custom"
            if not CustomSkyboxInputCreated then
                CustomSkyboxInputCreated = true
                for _, field in ipairs(SkyFaceFields) do
                    local faceKey = field.key
                    CustomSkySection:Textbox({Name = field.label .. " asset ID", Flag = "World_CustomSkybox_" .. faceKey, Placeholder = "image asset id", Default = WorldState.CustomSkybox[faceKey] or "", Callback = function(value)
                        setCustomSkyFace(faceKey, value)
                    end})
                end
            end
            local complete = true
            for _, field in ipairs(SkyFaceFields) do if not WorldState.CustomSkybox[field.key] or WorldState.CustomSkybox[field.key] == "" then complete = false; break end end
            if complete then applySkybox() end
        else
            WorldState.Skybox = "None"
            applySkybox()
        end
    end})

    WorldRight:Dropdown({Name = "Lighting technology", Flag = "World_Technology", Items = {"Legacy", "Voxel", "Compatibility", "ShadowMap", "Future", "Unified"}, Default = "Future", Multi = false, Callback = function(v) pcall(function() sethiddenproperty(Lighting, "Technology", Enum.Technology[v]) end) end})
    WorldRight:Dropdown({Name = "Lighting style", Flag = "World_LightingStyle", Items = {"Soft", "Realistic"}, Default = "Soft", Multi = false, Callback = function(v) pcall(function() Lighting.LightingStyle = Enum.LightingStyle[v] end) end})
    WorldRight:Toggle({Name = "World Modulation", Flag = "World_Modulation", Default = false, Callback = function(v) WorldState.Modulation = v; applyWorld() end})
    WorldRight:Slider({Name = "Saturation", Flag = "World_Saturation", Min = -1, Max = 1, Default = 0, Decimals = 0.01, Callback = function(v) WorldState.Saturation = v; applyWorld() end})
    WorldRight:Slider({Name = "Contrast", Flag = "World_Contrast", Min = -1, Max = 1, Default = 0, Decimals = 0.01, Callback = function(v) WorldState.Contrast = v; applyWorld() end})
    WorldRight:Slider({Name = "Brightness", Flag = "World_Brightness", Min = -1, Max = 1, Default = 0, Decimals = 0.01, Callback = function(v) WorldState.Brightness = v; applyWorld() end})
    WorldRight:Label({Name = "Modulation tint"}):Colorpicker({Name = "Modulation tint", Flag = "World_Tint", Default = WorldState.Tint, Callback = function(v) WorldState.Tint = v; applyWorld() end})
    WorldRight:Toggle({Name = "Atmosphere modulation", Flag = "World_Atmosphere", Default = false, Callback = function(v) WorldState.Atmosphere = v; applyWorld() end})
    WorldRight:Slider({Name = "Atmosphere density", Flag = "World_Density", Min = 0, Max = 1, Default = 0.3, Decimals = 0.01, Callback = function(v) WorldState.Density = v; applyWorld() end})
    WorldRight:Slider({Name = "Atmosphere haze", Flag = "World_Haze", Min = 0, Max = 10, Default = 0, Decimals = 0.1, Callback = function(v) WorldState.Haze = v; applyWorld() end})
    WorldRight:Slider({Name = "Atmosphere glare", Flag = "World_Glare", Min = 0, Max = 10, Default = 0, Decimals = 0.1, Callback = function(v) WorldState.Glare = v; applyWorld() end})

    -- Expose restoration so the final cleanup wrapper can call it after all other modules.
    local function restoreWorldVisuals()
            pcall(clearWeather)
            pcall(function()
                Lighting.Ambient = WorldCache.Ambient
                Lighting.OutdoorAmbient = WorldCache.OutdoorAmbient
                Lighting.ExposureCompensation = WorldCache.Exposure
                Lighting.ColorShift_Top = WorldCache.ColorShiftTop
                Lighting.ColorShift_Bottom = WorldCache.ColorShiftBottom
                Lighting.ClockTime = WorldCache.ClockTime
                Lighting.GlobalShadows = WorldCache.GlobalShadows
                Lighting.Brightness = WorldCache.Brightness
                Lighting.FogColor = WorldCache.FogColor
                Lighting.FogStart = WorldCache.FogStart
                Lighting.FogEnd = WorldCache.FogEnd
                if WorldCache.Technology then pcall(function() Lighting.Technology = WorldCache.Technology end) end
                if WorldCache.LightingStyle then pcall(function() Lighting.LightingStyle = WorldCache.LightingStyle end) end
                if SkyObject and SkyObject.Parent then
                    if SkyCreated then
                        SkyObject:Destroy()
                    else
                        for property, value in pairs(SkyCache) do pcall(function() SkyObject[property] = value end) end
                    end
                end
                WorldBloom:Destroy()
                WorldCorrection:Destroy()
                WorldAtmosphere:Destroy()
                if WorldSunRays then WorldSunRays:Destroy() end
                if WorldDOF then WorldDOF:Destroy() end
                if WorldClouds then
                    if CloudsCreated then WorldClouds:Destroy() else
                        pcall(function() WorldClouds.Cover = CloudCache.Cover; WorldClouds.Density = CloudCache.Density; WorldClouds.Color = CloudCache.Color end)
                    end
                end
            end)
    end
    if getgenv then getgenv().MS_WORLD_VISUALS_CLEANUP = restoreWorldVisuals end
end

------------------------------------------------------------
-- MovementPage
------------------------------------------------------------

do

--flysec

    local FlySection = MovementPage:Section({Name = "fly", Side = 1})
    local UIS = game:GetService("UserInputService")

    local FlyState = { Armed = false, Active = false, Speed = 50, VertSpeed = 30 }
    local bv, bg, flyConn

    local function stopFly()
        FlyState.Active = false
        if flyConn then flyConn:Disconnect() flyConn = nil end
        if bv then bv:Destroy() bv = nil end
        if bg then bg:Destroy() bg = nil end
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.PlatformStand = false end
    end

    local function startFly()
        if FlyState.Active then return end

        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not (root and hum) then return end

        FlyState.Active = true
        hum.PlatformStand = true

        bv = Instance.new("BodyVelocity")
        bv.MaxForce = Vector3.new(1e9, 1e9, 1e9)
        bv.Velocity = Vector3.zero
        bv.Parent = root

        bg = Instance.new("BodyGyro")
        bg.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
        bg.P, bg.D = 1e4, 500
        bg.CFrame = root.CFrame
        bg.Parent = root

        flyConn = RunService.Heartbeat:Connect(function()
            if not root.Parent then stopFly() return end

            local cam = workspace.CurrentCamera
            local dir = Vector3.zero
            local vertDir = 0

            if not UIS:GetFocusedTextBox() then
                if UIS:IsKeyDown(Enum.KeyCode.W) then dir += cam.CFrame.LookVector end
                if UIS:IsKeyDown(Enum.KeyCode.S) then dir -= cam.CFrame.LookVector end
                if UIS:IsKeyDown(Enum.KeyCode.A) then dir -= cam.CFrame.RightVector end
                if UIS:IsKeyDown(Enum.KeyCode.D) then dir += cam.CFrame.RightVector end
                if UIS:IsKeyDown(Enum.KeyCode.Space) then vertDir += 1 end
                if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then vertDir -= 1 end
            end

            local flatDir = Vector3.new(dir.X, 0, dir.Z)
            local finalVel = Vector3.zero
            if flatDir.Magnitude > 0 then finalVel += flatDir.Unit * FlyState.Speed end
            if vertDir ~= 0 then finalVel += Vector3.new(0, vertDir * FlyState.VertSpeed, 0) end

            bv.Velocity = finalVel
            bg.CFrame = CFrame.new(root.Position) * cam.CFrame.Rotation
        end)
    end

    FlySection:Toggle({
        Name = "Fly", Flag = "Fl_En", Default = false,
        Callback = function(v)
            FlyState.Armed = v
            if not v and FlyState.Active then stopFly() end
        end
    })

    FlySection:Label({Name = "bind"}):Keybind({
        Name = "Fly Keybind", Flag = "Fl_Kb", Default = Enum.KeyCode.F, Mode = "Toggle",
        Callback = function(value)
            if not FlyState.Armed then return end

            if type(value) == "boolean" then
                if value then startFly() else stopFly() end
            else
                if FlyState.Active then stopFly() else startFly() end
            end

            Library:Notification("Fly: " .. (FlyState.Active and "ON" or "OFF"), 2,
                FlyState.Active and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0))
        end
    })

    FlySection:Slider({
        Name = "Fly Speed", Flag = "Fl_Sp", Min = 10, Max = 300, Default = 50, Decimals = 1, Suffix = " st",
        Callback = function(val) FlyState.Speed = val end
    })

    FlySection:Slider({
        Name = "Vertical Speed", Flag = "Fl_Vs", Min = 10, Max = 300, Default = 30, Decimals = 1, Suffix = " st",
        Callback = function(val) FlyState.VertSpeed = val end
    })

    bind(LocalPlayer.CharacterAdded, function()
        if FlyState.Active then stopFly() end
    end)

    if getgenv then
        local old = getgenv().MS_CLEANUP
        getgenv().MS_CLEANUP = function()
            pcall(stopFly)
            if old then pcall(old) end
        end
    end
end

    ------------------------------------------------------------
    -- Crouch Speed
    ------------------------------------------------------------
    local mv = config and config.Movement
    local crouchOriginal = mv and mv.CrouchSpeed

    if crouchOriginal ~= nil then
        local crouch = {On = false, Mult = 1}
        local restarting, pending = false, false

        local function restartMovement()
            if restarting then pending = true return end
            restarting = true
            task.spawn(function()
                repeat
                    pending = false
                    local ok2, mov = pcall(function() return require(RS.IWBF.Client.Movement) end)
                    if ok2 and mov and mov.Stop then
                        pcall(function() mov.Stop() end)
                        task.wait(0.1)
                        pcall(function() mov.Start() end)
                    end
                until not pending
                restarting = false
            end)
        end

        local function applyCrouch()
            mv.CrouchSpeed = crouch.On and (crouchOriginal * crouch.Mult) or crouchOriginal
            restartMovement()
        end

        NoFallSection:Toggle({
            Name = "Crouch Speed", Flag = "CrouchSpd_En", Default = false,
            Callback = function(v) crouch.On = v applyCrouch() end
        })

        NoFallSection:Slider({
            Name = "Crouch Mult", Flag = "CrouchSpd_Ml", Min = 1, Max = 5, Default = 1, Decimals = 1, Suffix = "x",
            Callback = function(val)
                crouch.Mult = val
                if crouch.On then applyCrouch() end
            end
        })
    end

------------------------------------------------------------
-- MovementPage Exploits
------------------------------------------------------------
do
	local NoFallSection = MovementPage:Section({Name = "Exploits", Side = 2})
	local RS = game:GetService("ReplicatedStorage")
	local sharedFolder = RS:FindFirstChild("IWBF") and RS.IWBF:FindFirstChild("Shared")

	local config, bus, mv
	local originalSpeedFactor
	local originalCall
	local noFallEnabled = false

	if sharedFolder then
		local ok, cfg = pcall(function() return require(sharedFolder.Config) end)
		if ok and cfg then
			config = cfg
			mv = config.Movement
			if config.Injury then
				originalSpeedFactor = config.Injury.SpeedFactor
			end
		end

		local ok2, b = pcall(function() return require(sharedFolder.Bus) end)
		if ok2 and b then bus = b end
	end

	if not config and not bus then
		NoFallSection:Label({Name = "Error: IWBF not found"})
	end

	local wrap = newcclosure or function(f) return f end

	------------------------------------------------------------
	-- Общий перезапуск Movement (без наложения вызовов)
	------------------------------------------------------------
	local restarting, pending = false, false
	local function restartMovement()
		if restarting then pending = true return end
		restarting = true
		task.spawn(function()
			repeat
				pending = false
				local ok2, mov = pcall(function() return require(RS.IWBF.Client.Movement) end)
				if ok2 and mov and mov.Stop then
					pcall(function() mov.Stop() end)
					task.wait(0.1)
					pcall(function() mov.Start() end)
				end
			until not pending
			restarting = false
		end)
	end

	------------------------------------------------------------
	-- No Injury / No Fall Damage
	------------------------------------------------------------
	local function installHook()
		if originalCall or not bus then return end
		originalCall = bus.Call

		bus.Call = wrap(function(a, b, ...)
			local res = originalCall(a, b, ...)
			if not noFallEnabled then return res end

			local name = type(a) == "string" and a or b
			if name == "Org.Local" and type(res) == "table" then
				res.lleg = 0
				res.rleg = 0
				res.llegdislocation = nil
				res.rlegdislocation = nil
				res.pelvis = 0
				res.pain = 0
				res.shock = 0
				if res.blood and res.blood < 5000 then
					res.blood = 5000
				end
			end
			return res
		end)
	end

	local function removeHook()
		if originalCall and bus then
			bus.Call = originalCall
			originalCall = nil
		end
	end

	NoFallSection:Toggle({
		Name = "No Injury (Speed Factor)",
		Flag = "NoInjury",
		Default = false,
		Callback = function(v)
			if not config or not config.Injury then return end
			if v then
				config.Injury.SpeedFactor = false
				Library:Notification("Injury speed debuff disabled", 2, Color3.fromRGB(0, 255, 0))
			else
				config.Injury.SpeedFactor = originalSpeedFactor
				Library:Notification("Injury speed debuff enabled", 2, Color3.fromRGB(255, 0, 0))
			end
		end
	})

	NoFallSection:Toggle({
		Name = "No Fall Damage",
		Flag = "NoFallDamage",
		Default = false,
		Callback = function(v)
			if not bus then return end
			noFallEnabled = v
			if v then
				installHook()
				Library:Notification("Fall damage disabled", 2, Color3.fromRGB(0, 255, 0))
			else
				Library:Notification("Fall damage enabled", 2, Color3.fromRGB(255, 0, 0))
			end
		end
	})

	------------------------------------------------------------
	-- Crouch Speed
	------------------------------------------------------------
	local crouchOriginal = mv and mv.CrouchSpeed

	if crouchOriginal ~= nil then
		local crouch = {On = false, Mult = 1}

		local function applyCrouch()
			mv.CrouchSpeed = crouch.On and (crouchOriginal * crouch.Mult) or crouchOriginal
			restartMovement()
		end

		NoFallSection:Toggle({
			Name = "Crouch Speed", Flag = "CrouchSpd_En", Default = false,
			Callback = function(v) crouch.On = v applyCrouch() end
		})

		NoFallSection:Slider({
			Name = "Crouch Mult", Flag = "CrouchSpd_Ml", Min = 1, Max = 5, Default = 1, Decimals = 1, Suffix = "x",
			Callback = function(val)
				crouch.Mult = val
				if crouch.On then applyCrouch() end
			end
		})
	end

	------------------------------------------------------------
	-- Max Weight
	------------------------------------------------------------
	local weightOriginal = mv and mv.MaxWeight

	if weightOriginal ~= nil then
		local weight = {On = false, Value = weightOriginal}

		local function applyWeight()
			mv.MaxWeight = weight.On and weight.Value or weightOriginal
			restartMovement()
		end

		NoFallSection:Toggle({
			Name = "Weight bypass", Flag = "MaxWgt_En", Default = false,
			Callback = function(v) weight.On = v applyWeight() end
		})

		NoFallSection:Slider({
			Name = "Weight", Flag = "MaxWgt_Ml", Min = 50, Max = 10000,
			Default = math.clamp(weightOriginal, 50, 10000), Decimals = 1, Suffix = " kg",
			Callback = function(val)
				weight.Value = val
				if weight.On then applyWeight() end
			end
		})
	end

	------------------------------------------------------------
	-- Возврат оригиналов при перезапуске скрипта
	------------------------------------------------------------
	if getgenv then
		local old = getgenv().MS_CLEANUP
		getgenv().MS_CLEANUP = function()
			noFallEnabled = false
			pcall(removeHook)
			if mv and crouchOriginal ~= nil then pcall(function() mv.CrouchSpeed = crouchOriginal end) end
			if mv and weightOriginal ~= nil then pcall(function() mv.MaxWeight = weightOriginal end) end
			if config and config.Injury then
				pcall(function() config.Injury.SpeedFactor = originalSpeedFactor end)
			end
			if old then pcall(old) end
		end
	end
end

------------------------------------------------------------
-- MovementPage : Jump Boost (kept from the movement add-on)
------------------------------------------------------------
do
    local JumpSection = MovementPage:Section({Name = "jump boost", Side = 2})
    local RSJump = game:GetService("ReplicatedStorage")
    local sharedJump = RSJump:FindFirstChild("IWBF") and RSJump.IWBF:FindFirstChild("Shared")

    local movementConfig
    local originalJumpPower
    local originalSourceJumpPower
    local JumpState = {Enabled = false, Multiplier = 2}
    local BhopState = {Enabled = false}
    local JumpSpamState = {Enabled = false}
    local JumpLoopConnection
    local UserInputJump = game:GetService("UserInputService")
    local jumpInterval = 0.06
    local nextAutoJumpAt = 0
    local restarting, pendingRestart = false, false

    if sharedJump then
        local ok, cfg = pcall(function()
            return require(sharedJump:WaitForChild("Config"))
        end)
        if ok and cfg and cfg.Movement then
            movementConfig = cfg.Movement
            originalJumpPower = movementConfig.JumpPower
            if type(movementConfig.Source) == "table" then
                originalSourceJumpPower = movementConfig.Source.JumpPower
            end
        end
    end

    local function restartJumpMovement()
        if restarting then
            pendingRestart = true
            return
        end
        restarting = true
        task.spawn(function()
            repeat
                pendingRestart = false
                local iwbf = RSJump:FindFirstChild("IWBF")
                local clientFolder = iwbf and iwbf:FindFirstChild("Client")
                local movementModule = clientFolder and clientFolder:FindFirstChild("Movement")
                if movementModule then
                    local ok, movement = pcall(require, movementModule)
                    if ok and movement and movement.Stop and movement.Start then
                        pcall(function() movement.Stop() end)
                        task.wait(0.1)
                        pcall(function() movement.Start() end)
                    end
                end
            until not pendingRestart
            restarting = false
        end)
    end

    local function applyJumpBoost()
        if not movementConfig then return end
        local multiplier = JumpState.Enabled and JumpState.Multiplier or 1
        if originalJumpPower ~= nil then
            movementConfig.JumpPower = originalJumpPower * multiplier
        end
        if type(movementConfig.Source) == "table" and originalSourceJumpPower ~= nil then
            movementConfig.Source.JumpPower = originalSourceJumpPower * multiplier
        end
        restartJumpMovement()
    end

    if not movementConfig then
        JumpSection:Label({Name = "IWBF movement config not found"})
    end

    JumpSection:Toggle({
        Name = "Jump Boost", Flag = "JumpBoost_Enabled", Default = false,
        Callback = function(value)
            JumpState.Enabled = value == true
            applyJumpBoost()
        end
    })

    JumpSection:Slider({
        Name = "Jump Multiplier", Flag = "JumpBoost_Multiplier",
        Min = 1, Max = 5, Default = 2, Decimals = 0.1, Suffix = "x",
        Callback = function(value)
            JumpState.Multiplier = tonumber(value) or 2
            if JumpState.Enabled then applyJumpBoost() end
        end
    })

    -- Bhop: repeat a jump only when Space is held and the player is grounded.
    JumpSection:Toggle({
        Name = "Bhop (hold Space)", Flag = "Bhop_Enabled", Default = false,
        Callback = function(value)
            BhopState.Enabled = value == true
        end
    })

    -- Jump Spam: automatically attempt the next jump whenever grounded.
    JumpSection:Toggle({
        Name = "Jump Spam", Flag = "JumpSpam_Enabled", Default = false,
        Callback = function(value)
            JumpSpamState.Enabled = value == true
        end
    })

    JumpSection:Slider({
        Name = "Auto Jump Interval", Flag = "AutoJump_Interval",
        Min = 0.02, Max = 0.20, Default = 0.06, Decimals = 0.01, Suffix = "s",
        Callback = function(value)
            jumpInterval = math.clamp(tonumber(value) or 0.06, 0.02, 0.20)
        end
    })

    -- One lightweight Heartbeat loop serves both options and survives respawns.
    JumpLoopConnection = RunService.Heartbeat:Connect(function()
        if not BhopState.Enabled and not JumpSpamState.Enabled then return end
        if UserInputJump:GetFocusedTextBox() then return end

        local shouldJump = JumpSpamState.Enabled
        if not shouldJump and BhopState.Enabled then
            local ok, down = pcall(function()
                return UserInputJump:IsKeyDown(Enum.KeyCode.Space)
            end)
            shouldJump = ok and down == true
        end
        if not shouldJump then return end

        local character = LocalPlayer.Character
        if not character then return end
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if not humanoid or humanoid.Health <= 0 then return end

        -- Only issue a jump when grounded; never force the state mid-air.
        if humanoid.FloorMaterial == Enum.Material.Air then return end
        local now = os.clock()
        if now < nextAutoJumpAt then return end
        nextAutoJumpAt = now + jumpInterval

        pcall(function()
            humanoid.Jump = true
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end)
    end)

    if getgenv then
        local previousCleanup = getgenv().MS_CLEANUP
        getgenv().MS_CLEANUP = function()
            JumpState.Enabled = false
            BhopState.Enabled = false
            JumpSpamState.Enabled = false
            if JumpLoopConnection then
                pcall(function() JumpLoopConnection:Disconnect() end)
                JumpLoopConnection = nil
            end
            if movementConfig then
                if originalJumpPower ~= nil then
                    pcall(function() movementConfig.JumpPower = originalJumpPower end)
                end
                if type(movementConfig.Source) == "table" and originalSourceJumpPower ~= nil then
                    pcall(function() movementConfig.Source.JumpPower = originalSourceJumpPower end)
                end
                pcall(restartJumpMovement)
            end
            if previousCleanup then pcall(previousCleanup) end
        end
    end
end

------------------------------------------------------------
-- MovementPage : Super Climb
------------------------------------------------------------
do
	local ClimbSection = MovementPage:Section({Name = "super climb", Side = 1})
	local RS = game:GetService("ReplicatedStorage")
	local sharedFolder = RS:FindFirstChild("IWBF") and RS.IWBF:FindFirstChild("Shared")

	local C
	local ok, cfg = pcall(function() return require(sharedFolder.Config) end)
	if ok and cfg and cfg.Climbing then
		C = cfg.Climbing
	else
		ClimbSection:Label({Name = "Climbing config not found"})
		return
	end

	-- сохраняем оригиналы, чтобы вернуть при выключении
	local KEYS = {
		"MaxHeight", "ReachScale", "ReachBonus",
		"StepTime", "PullTime", "TopTime",
		"MaxApproach", "MinHeight", "Cooldown", "HoldToClimb",
	}
	local Original = {}
	for _, k in ipairs(KEYS) do Original[k] = C[k] end

	-- значения, которые применяются при включении
	local State = {
		Enabled = false,
		Values = {
			MaxHeight = 59999,
			ReachScale = 2999,
			ReachBonus = 599,
			StepTime = 0.6,
			PullTime = 0.3,
			TopTime = 0.3,
			MaxApproach = 180,
			MinHeight = 0.1,
			Cooldown = 0,
			HoldToClimb = true,
		},
	}

	local function apply()
		for _, k in ipairs(KEYS) do
			if Original[k] ~= nil then
				if State.Enabled then
					C[k] = State.Values[k]
				else
					C[k] = Original[k]
				end
			end
		end
	end

	local function slider(name, flag, key, min, max, decimals, suffix)
		if Original[key] == nil then return end
		ClimbSection:Slider({
			Name = name, Flag = flag,
			Min = min, Max = max,
			Default = math.clamp(State.Values[key], min, max),
			Decimals = decimals, Suffix = suffix or "",
			Callback = function(val)
				State.Values[key] = val
				if State.Enabled then apply() end
			end
		})
	end

	ClimbSection:Toggle({
		Name = "Super Climb", Flag = "Climb_En", Default = false,
		Callback = function(v)
			State.Enabled = v
			apply()
			Library:Notification("Super Climb: " .. (v and "ON" or "OFF"), 2,
				v and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0))
		end
	})

	slider("Max Height",   "Climb_MaxH",   "MaxHeight",   1, 60000, 1, " st")
	slider("Reach Scale",  "Climb_RScale", "ReachScale",  1, 3000,  1, "x")
	slider("Reach Bonus",  "Climb_RBonus", "ReachBonus",  0, 600,   1, " st")
	slider("Step Time",    "Climb_Step",   "StepTime",    0, 2,     2, " s")
	slider("Pull Time",    "Climb_Pull",   "PullTime",    0, 2,     2, " s")
	slider("Top Time",     "Climb_Top",    "TopTime",     0, 2,     2, " s")
	slider("Max Approach", "Climb_Appr",   "MaxApproach", 1, 360,   1, "°")
	slider("Min Height",   "Climb_MinH",   "MinHeight",   0, 5,     2, " st")
	slider("Cooldown",     "Climb_Cd",     "Cooldown",    0, 5,     2, " s")

	if Original.HoldToClimb ~= nil then
		ClimbSection:Toggle({
			Name = "Hold to climb", Flag = "Climb_Hold", Default = true,
			Callback = function(v)
				State.Values.HoldToClimb = v
				if State.Enabled then apply() end
			end
		})
	end

	-- возвращаем оригиналы при перезапуске скрипта
	if getgenv then
		local old = getgenv().MS_CLEANUP
		getgenv().MS_CLEANUP = function()
			State.Enabled = false
			pcall(apply)
			if old then pcall(old) end
		end
	end
end

------------------------------------------------------------
-- MovementPage : Speedhack (Bind + Slider)
------------------------------------------------------------
do
	local SpeedSection = MovementPage:Section({Name = "speedhack", Side = 1})

	local RS = game:GetService("ReplicatedStorage")
	local sharedFolder = RS:FindFirstChild("IWBF") and RS.IWBF:FindFirstChild("Shared")

	local config
	local originalWalk, originalRun

	local ok, cfg = pcall(function() return require(sharedFolder.Config) end)
	if ok and cfg and cfg.Movement then
		config = cfg
		originalWalk = config.Movement.WalkSpeed
		originalRun = config.Movement.RunSpeed
	else
		SpeedSection:Label({Name = "Ошибка: IWBF Config не найден!"})
	end

	local SpeedState = {
		Armed = false,
		Active = false,
		Multiplier = 3,
		Restarting = false,
		Pending = false,
	}

	-- Перезапуск скрипта движения (без наложения вызовов)
	local function restartMovement()
		if SpeedState.Restarting then
			SpeedState.Pending = true -- применим ещё раз после текущего перезапуска
			return
		end
		SpeedState.Restarting = true

		task.spawn(function()
			repeat
				SpeedState.Pending = false
				local ok2, mov = pcall(function() return require(RS.IWBF.Client.Movement) end)
				if ok2 and mov and mov.Stop then
					pcall(function() mov.Stop() end)
					task.wait(0.1)
					pcall(function() mov.Start() end)
				end
			until not SpeedState.Pending
			SpeedState.Restarting = false
		end)
	end

	local function applySpeed()
		if not config then return end

		if SpeedState.Active then
			config.Movement.WalkSpeed = originalWalk * SpeedState.Multiplier
			config.Movement.RunSpeed = originalRun * SpeedState.Multiplier
		else
			config.Movement.WalkSpeed = originalWalk
			config.Movement.RunSpeed = originalRun
		end
		restartMovement()
	end

	SpeedSection:Toggle({
		Name = "Speedhack",
		Flag = "Speedhack_Enabled",
		Default = false,
		Callback = function(v)
			SpeedState.Armed = v
			if not v and SpeedState.Active then
				SpeedState.Active = false
				applySpeed()
			end
		end
	})

	SpeedSection:Label({Name = "bind"}):Keybind({
		Name = "Speedhack Keybind",
		Flag = "Speedhack_Keybind",
		Default = Enum.KeyCode.C, -- было X, конфликтовало с freecam
		Mode = "Toggle",
		Callback = function(value)
			if not SpeedState.Armed then return end
			if type(value) == "boolean" then
				SpeedState.Active = value
			else
				SpeedState.Active = not SpeedState.Active
			end
			applySpeed()
		end
	})

	SpeedSection:Slider({
		Name = "Speed Multiplier",
		Flag = "Speedhack_Mult",
		Min = 1, Max = 10, Default = 3, Decimals = 1, Suffix = "x",
		Callback = function(value)
			SpeedState.Multiplier = value
			if SpeedState.Armed and SpeedState.Active then
				applySpeed()
			end
		end
	})

	-- возвращаем оригинальную скорость при перезапуске скрипта
	if getgenv then
		local old = getgenv().MS_CLEANUP
		getgenv().MS_CLEANUP = function()
			SpeedState.Active = false
			pcall(applySpeed)
			if old then pcall(old) end
		end
	end
end




------------------------------------------------------------
-- Auto Watermark Refresh (Name Spoof)
------------------------------------------------------------
task.spawn(function()
	while task.wait(0.5) do
		if NameSpoofWatermark and NameSpoof then
			local displayName = LocalPlayer.Name 	
			if NameSpoof.Enabled then
				if NameSpoof.SpoofUser ~= "" then
					displayName = NameSpoof.SpoofUser
				elseif NameSpoof.SpoofNick ~= "" then
					displayName = NameSpoof.SpoofNick
				end
			end
			pcall(function()
				NameSpoofWatermark:SetText(" " .. displayName)
			end)
		end
	end
end)

------------------------------------------------------------
-- Watermark
------------------------------------------------------------
do
	local UsernameText = Watermark:Add(" " .. LocalPlayer.Name)
    NameSpoofWatermark = UsernameText
	local FpsText = Watermark:Add("FPS: ")
	local DateTimeText = Watermark:Add("")
    local huiText = Watermark:Add("IWBF")

	local FrameCount, Elapsed = 0, 0

	Library:Connect(RunService.RenderStepped, function(DeltaT)
		FrameCount = FrameCount + 1
		Elapsed = Elapsed + DeltaT

		if Elapsed >= 1 then
			FpsText:SetText("FPS: " .. math.floor(FrameCount / Elapsed))
			FrameCount = 0
			Elapsed = 0
		end

		DateTimeText:SetText(os.date("%H:%M:%S %d/%m/%Y"))
	end)
end

------------------------------------------------------------
-- LUA PAGE
------------------------------------------------------------
do
	local CfgSection = LuaPage:Section({Name = "LUA", Side = 1})
    local LuaSection = LuaPage:Section({Name = "LUA", Side = 2})

	local TOKEN = "__cfg_" .. math.random(100000000, 900000000) .. "__"
	local LIST_HEIGHT, ROW_HEIGHT = 190, 24
	local ACCENT = (Library.Theme and Library.Theme.Accent) or Color3.fromRGB(176, 176, 209)

	local C = {
		bg = Color3.fromRGB(12, 12, 12),
		row = Color3.fromRGB(22, 22, 22),
		hover = Color3.fromRGB(30, 30, 30),
		sel = Color3.fromRGB(34, 34, 34),
		line = Color3.fromRGB(38, 38, 38),
		text = Color3.fromRGB(215, 215, 215),
		dim = Color3.fromRGB(115, 115, 115),
	}
	local uiFont = {Face = nil, Size = 12}

	local Selected, Query, NewName = nil, "", ""
	local scroll
	local refresh

	local function notify(text, color)
		Library:Notification(text, 3, color or ACCENT)
	end

	local function cfgPath(name)
		return Library.Directory .. Library.Folders.Configs .. "/" .. name .. ".json"
	end

	local function clean(s)
		s = tostring(s or ""):gsub("[^%w _%-]", "")
		return (s:gsub("^%s+", ""):gsub("%s+$", ""))
	end

	local function listConfigs()
		local out = {}
		pcall(function()
			Library:GetConfigsList({Refresh = function(_, list) out = list end})
		end)
		table.sort(out, function(a, b) return a:lower() < b:lower() end)
		return out
	end

	local function styleText(l, size, color)
		if uiFont.Face then l.FontFace = uiFont.Face else l.Font = Enum.Font.Code end
		l.TextSize = size or uiFont.Size
		l.TextColor3 = color or C.text
	end

	function refresh()
		if not scroll then return end
		for _, c in ipairs(scroll:GetChildren()) do
			if c:IsA("GuiObject") then c:Destroy() end
		end

		local names, q = listConfigs(), Query:lower()
		local shown = 0

		for _, name in ipairs(names) do
			if q == "" or name:lower():find(q, 1, true) then
				shown = shown + 1
				local isSel = (name == Selected)
				local base = isSel and C.sel or C.row

				local row = Instance.new("Frame")
				row.Size = UDim2.new(1, -6, 0, ROW_HEIGHT)
				row.BackgroundColor3 = base
				row.BorderSizePixel = 0
				row.LayoutOrder = shown
				row.Parent = scroll
				local rs = Instance.new("UIStroke", row)
				rs.Color = C.line
				rs.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

				if isSel then
					local bar = Instance.new("Frame")
					bar.Size = UDim2.new(0, 2, 1, 0)
					bar.BackgroundColor3 = ACCENT
					bar.BorderSizePixel = 0
					bar.Parent = row
				end

				local label = Instance.new("TextLabel")
				label.Size = UDim2.new(1, -16, 1, 0)
				label.Position = UDim2.fromOffset(10, 0)
				label.BackgroundTransparency = 1
				label.Text = name
				label.TextXAlignment = Enum.TextXAlignment.Left
				label.TextTruncate = Enum.TextTruncate.AtEnd
				styleText(label, uiFont.Size, isSel and ACCENT or C.text)
				label.Parent = row

				local btn = Instance.new("TextButton")
				btn.Size = UDim2.fromScale(1, 1)
				btn.BackgroundTransparency = 1
				btn.Text = ""
				btn.Parent = row
				btn.MouseEnter:Connect(function()
					if name ~= Selected then row.BackgroundColor3 = C.hover end
				end)
				btn.MouseLeave:Connect(function() row.BackgroundColor3 = base end)
				btn.MouseButton1Click:Connect(function()
					Selected = (Selected == name) and nil or name
					refresh()
				end)
			end
		end

		if shown == 0 then
			local empty = Instance.new("TextLabel")
			empty.Size = UDim2.new(1, 0, 0, 24)
			empty.BackgroundTransparency = 1
			empty.Text = "no luas"
			styleText(empty, nil, C.dim)
			empty.Parent = scroll
		end
	end

	CfgSection:Textbox({
		Name = "Search",
		Flag = "CfgSearch",
		Placeholder = "Search..",
		Default = "",
		Callback = function(text)
			Query = text or ""
			refresh()
		end
	})

	CfgSection:Label({Name = TOKEN})

	local function need()
		if not Selected then
			notify("Select a lua first", Color3.fromRGB(255, 110, 110))
			return false
		end
		return true
	end

	CfgSection:Button({
		Name = "Load",
		Callback = function()
			if not need() then return end
			local ok, data = pcall(readfile, cfgPath(Selected))
			if not ok then notify("Cannot read config", Color3.fromRGB(255, 80, 80)) return end
			local success = Library:LoadConfig(data)
			if success then notify("Loaded: " .. Selected) else notify("Failed to load", Color3.fromRGB(255, 80, 80)) end
		end
	})

	CfgSection:Button({
		Name = "Delete",
		Callback = function()
			if not need() then return end
			pcall(delfile, cfgPath(Selected))
			notify("Deleted: " .. Selected)
			Selected = nil
			refresh()
		end
	})

    	LuaSection:Button({
		Name = "Dex++",
		Callback = function()
			task.spawn(function()
				loadstring(game:HttpGet("https://rawscripts.net/raw/Universal-Script-Dex-PlusPlus-Decompiler-Fix-206651"))()
			end)
		end
	})

	LuaSection:Button({
		Name = "Infinite Yield",
		Callback = function()
			task.spawn(function()
				loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))()
			end)
		end
	})

	LuaSection:Button({
		Name = "VEX Explorer",
		Callback = function()
			task.spawn(function()
				loadstring(game:HttpGet("https://raw.githubusercontent.com/Vezise/2026/main/Vez/VexExplorer/VEXExplorer.lua"))()
			end)
		end
	})

	LuaSection:Button({
		Name = "Rejoin",
		Callback = function()
			local TeleportService = game:GetService("TeleportService")
			local Players = game:GetService("Players")
			local player = Players.LocalPlayer
			local placeId = game.PlaceId
			TeleportService:Teleport(placeId, player)
		end
	})

	task.spawn(function()
		local d = waitLabel(TOKEN, 30)
		if not d then
			return
		end

		uiFont.Face = d.FontFace
		uiFont.Size = d.TextSize > 0 and d.TextSize or 12

		local container, hide = d.Parent, d
		if not container:FindFirstChildWhichIsA("UIListLayout") and container.Parent then
			hide = container
			container = container.Parent
		end

		local holder = Instance.new("Frame")
		holder.Size = UDim2.new(1, -10, 0, LIST_HEIGHT)
		holder.BackgroundColor3 = C.bg
		holder.BorderSizePixel = 0
		holder.LayoutOrder = hide.LayoutOrder
		holder.ZIndex = hide.ZIndex
		holder.Parent = container
		local hs = Instance.new("UIStroke", holder)
		hs.Color = C.line
		hs.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

		scroll = Instance.new("ScrollingFrame")
		scroll.Size = UDim2.new(1, -8, 1, -8)
		scroll.Position = UDim2.fromOffset(4, 4)
		scroll.BackgroundTransparency = 1
		scroll.BorderSizePixel = 0
		scroll.ScrollBarThickness = 2
		scroll.ScrollBarImageColor3 = ACCENT
		scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
		scroll.CanvasSize = UDim2.new()
		scroll.Parent = holder
		local lay = Instance.new("UIListLayout", scroll)
		lay.Padding = UDim.new(0, 3)
		lay.SortOrder = Enum.SortOrder.LayoutOrder

		hide.Visible = false
		refresh()
	end)
end


Window:Init()



------------------------------------------------------------
-- opening credits page
------------------------------------------------------------

task.spawn(function()
	local label
	for _ = 1, 20 do
		task.wait(0.25)
		for _, root in ipairs(getContainers()) do
			for _, g in ipairs(root:GetChildren()) do
				if g:IsA("ScreenGui") and not guisBefore[g] then
					for _, d in ipairs(g:GetDescendants()) do
						if (d:IsA("TextLabel") or d:IsA("TextButton")) and d.Text:lower() == "credits" then
							label = d
							break
						end
					end
				end
				if label then break end
			end
			if label then break end
		end
		if label then break end
	end
	if not label then warn("[tabs] не нашёл кнопку credits") return end

	local o = label
	while o and o.Parent and not o.Parent:FindFirstChildWhichIsA("UIListLayout") do
		if o:IsA("GuiButton") then
			for _, sig in ipairs({"MouseButton1Down", "MouseButton1Click", "Activated"}) do
				pcall(function()
					for _, c in ipairs(getconnections(o[sig])) do c:Fire() end
				end)
			end
		end
		o = o.Parent
	end
	if o and o:IsA("GuiButton") then
		for _, sig in ipairs({"MouseButton1Down", "MouseButton1Click", "Activated"}) do
			pcall(function()
				for _, c in ipairs(getconnections(o[sig])) do c:Fire() end
			end)
		end
	end
end)
------------------------------------------------------------
-- переставляем вкладку credits после settings
------------------------------------------------------------

task.spawn(function()
	local function candidates(txt)
		local out = {}
		for _, root in ipairs(getContainers()) do
			for _, g in ipairs(root:GetChildren()) do
				if g:IsA("ScreenGui") and not guisBefore[g] then
					for _, d in ipairs(g:GetDescendants()) do
						if (d:IsA("TextLabel") or d:IsA("TextButton")) and d.Text:lower() == txt then
							table.insert(out, d)
						end
					end
				end
			end
		end
		return out
	end

	local function tabItem(d)
		local item = d
		while item.Parent and not item.Parent:FindFirstChildWhichIsA("UIListLayout") do
			item = item.Parent
		end
		if item.Parent and item:IsA("GuiObject") then return item end
	end

	for _ = 1, 20 do
		task.wait(0.25)
		for _, c in ipairs(candidates("credits")) do
			local credits = tabItem(c)
			if credits then
				local bar = credits.Parent
				local settings
				for _, s in ipairs(candidates("settings")) do
					local it = tabItem(s)
					if it and it.Parent == bar then settings = it break end
				end

				if settings then
					local layout = bar:FindFirstChildWhichIsA("UIListLayout")
					local kids = {}
					for i, ch in ipairs(bar:GetChildren()) do
						if ch:IsA("GuiObject") then table.insert(kids, {obj = ch, idx = i}) end
					end
					table.sort(kids, function(a, b)
						if a.obj.LayoutOrder ~= b.obj.LayoutOrder then
							return a.obj.LayoutOrder < b.obj.LayoutOrder
						end
						return a.idx < b.idx
					end)

					local ordered = {}
					for _, k in ipairs(kids) do
						if k.obj ~= credits then table.insert(ordered, k.obj) end
					end
					for i, obj in ipairs(ordered) do
						if obj == settings then table.insert(ordered, i + 1, credits) break end
					end

					layout.SortOrder = Enum.SortOrder.LayoutOrder
					for i, obj in ipairs(ordered) do obj.LayoutOrder = i end
					return
				end
			end
		end
	end
	warn("[tabs] не нашёл вкладки credits/settings")
end)

------------------------------------------------------------
-- Photo 
------------------------------------------------------------
task.spawn(function()
	local ok, asset = pcall(function()
		writefile("credits_photo.png", game:HttpGet(PHOTO))
		return getcustomasset("credits_photo.png")
	end)
	if not ok then
		return
	end

	local d = waitLabel("__photo__", 20)
	if not d then
		warn("dont find photo")
		return
	end

	local img = Instance.new("ImageLabel")
	img.BackgroundTransparency = 1
	img.Size = PHOTO_SIZE
	img.ScaleType = Enum.ScaleType.Fit
	img.LayoutOrder = d.LayoutOrder
	img.ZIndex = d.ZIndex
	img.Image = asset
	img.Parent = d.Parent
	d.Visible = false
end)

-- Chain world-visual restoration after the script's final cleanup handler is registered.
do
    if getgenv then
        local priorCleanup = getgenv().MS_CLEANUP
        local worldCleanup = getgenv().MS_WORLD_VISUALS_CLEANUP
        getgenv().MS_CLEANUP = function(...)
            if priorCleanup then pcall(priorCleanup, ...) end
            pcall(cleanupWeaponMods)
            if worldCleanup then pcall(worldCleanup) end
        end
    end
end
