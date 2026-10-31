--[[
    UILib - Example
    Shows every element type of the library.

    1) Put UILib.lua in your executor's workspace folder.
    2) Run this file.

    If you host UILib somewhere, replace the first line with:
        local Library = loadstring(game:HttpGet("https://your.host/UILib.lua"))()
]]

local Library = loadstring(readfile("UILib.lua"))()
local Menu    = Library.Menu
local Flags   = Library.Flags

local RunService = game:GetService("RunService")
local Stats      = game:GetService("Stats")


-- // Main window (opens/closes with RightShift)
local Window = Library:Window({
    Name = "Example Hub",
    Bind = Enum.KeyCode.RightShift,
    Visible = true,
    HasTabs = true
})


-- // Tab 1: elements
local Main = Window:Tab({ Name = "Main", Opened = true })

local General = Main:Section({ Name = "General", Side = "Left", Size = 300 })
do
    -- Toggle with a keybind attached
    General:Toggle({
        Name = "Enabled",
        Flag = "Example Enabled",
        Callback = function(Value)
            print("Enabled:", Value)
        end
    }):Keybind({
        Name = "Example",
        Flag = "Example Keybind",
        Mode = "Toggle",                 -- "Always On", "Toggle", "Held", "Off Hold"
        Default = Enum.KeyCode.E,
        Changed = function(Key, Active)
            print("Keybind:", Key, Active)
        end
    })

    -- Toggle with a colorpicker attached
    General:Toggle({
        Name = "Highlight",
        Flag = "Example Highlight",
        Default = true
    }):Colorpicker({
        Flag = "Example Highlight Color",
        Color = Color3.fromRGB(110, 140, 255)
    })

    -- Slider (Decimals = step size, Prefix = unit text)
    General:Slider({
        Name = "Speed",
        Flag = "Example Speed",
        Min = 0, Max = 100, Default = 25,
        Decimals = 1,
        Prefix = "%"
    })

    General:Slider({
        Name = "Delay",
        Flag = "Example Delay",
        Min = 0, Max = 2, Default = 0.25,
        Decimals = 0.05,
        Prefix = "s"
    })

    -- Single select dropdown
    General:Dropdown({
        Name = "Mode",
        Flag = "Example Mode",
        Options = { "Fast", "Normal", "Slow" },
        Default = "Normal",
        Callback = function(Value)
            print("Mode:", Value)
        end
    })

    -- Multi select dropdown (Default is a table)
    General:Dropdown({
        Name = "Targets",
        Flag = "Example Targets",
        Options = { "Players", "Bots", "Animals", "Vehicles" },
        Default = { "Players" },
        Min = 1,
        Size = 100
    })
end

local Other = Main:Section({ Name = "Other", Side = "Right", Size = 300 })
do
    Other:Label({ Text = "Labels support plain text." })

    Other:TextBox({
        Name = "Name",
        Flag = "Example Text",
        Placeholder = "Type something...",
        Default = "",
        Callback = function(String)
            print("Text:", String)
        end
    })

    Other:Button({
        Name = "Notify",
        CallbackText = "Sent!",
        Callback = function()
            Library:Notify({ Text = "Hello from UILib", Time = 3 })
        end
    })

    Other:Button({
        Name = "Print flags",
        Callback = function()
            print("Enabled:", Flags["Example Enabled"].Value)
            print("Speed:", Flags["Example Speed"].Value)
            print("Mode:", Flags["Example Mode"].Value)
        end
    })

    Other:Button({
        Name = "Unload UI",
        Confirm = true,                  -- asks to click twice
        Callback = function()
            Menu.Unload()
        end
    })
end


-- // Tab 2: config manager (uses the library's own save/load system)
local Settings = Window:Tab({ Name = "Settings" })

local Configs = Settings:Section({ Name = "Configurations", Side = "Left", Size = 300 })
do
    local Options = Menu.Config("List")

    local ConfigList = Configs:Dropdown({
        Name = "Config",
        Flag = "Config List",
        Exclude = true,                  -- not saved inside the config itself
        Options = Options,
        Default = Options[1],
        Size = 100
    })

    local ConfigName = Configs:TextBox({ Placeholder = "Config name", Default = "" })

    Configs:Button({
        Name = "Create",
        CallbackText = "Created!",
        Callback = function()
            local Name = ConfigName.Get()

            if Name and Name ~= "" then
                Menu.Config("New", Name)

                local List = Menu.Config("List")
                ConfigList.Options = List
                ConfigList.Set(List[1])
            end
        end
    })

    Configs:Button({
        Name = "Save",
        CallbackText = "Saved!",
        Callback = function()
            local Name = ConfigList.Get()
            if Name then Menu.Config("Save", Name) end
        end
    })

    Configs:Button({
        Name = "Load",
        CallbackText = "Loaded!",
        Callback = function()
            local Name = ConfigList.Get()

            if Name then
                Menu.Config("Load", Name)
                Library:Notify({ Text = "Loaded config: " .. Name, Time = 3 })
            end
        end
    })
end


-- // Extra widgets
local Watermark = Window:Watermark({ Text = "Example Hub", Enabled = true })
Window:KeybindsList({ Enabled = true })

local Heartbeat = Stats.Workspace["Heartbeat"]

RunService.RenderStepped:Connect(function()
    if Watermark.IsVisible then
        Watermark.SetText(string.format("Example Hub | %d fps", math.round(Heartbeat:GetValue())))
    end
end)

Library:Notify({ Text = "UILib loaded - press RightShift to toggle", Time = 4 })
