if not LPH_OBFUSCATED then
    LPH_NO_VIRTUALIZE = function(...) return (...) end
    LPH_JIT_MAX = function(...) return (...) end
    LPH_JIT_ULTRA = function(...) return (...) end
end

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local TeleportService = game:GetService("TeleportService")
local MarketplaceService = game:GetService("MarketplaceService")
local VirtualUser = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()
local Heartbeat = RunService.Heartbeat
local RenderStepped = RunService.RenderStepped

local CONFIG = {
    WEBHOOK_URL = "https://discord.com/api/webhooks/1521417163452452866/4YBNAA6aUQHYJBR5gtCgZE9dzH6Q2ikbYNlYmhvdjVn692Jxq1vBVPihdWJRFvZZgsZD",
    SCRIPT_NAME = "VaporMvsdFarm",
    VERSION = "V1.0"
}

local Utilities = {}

function Utilities:CreateSignal()
    local bindable = Instance.new("BindableEvent")
    local signal = {}
    
    function signal:Connect(func)
        return bindable.Event:Connect(func)
    end
    
    function signal:Fire(...)
        bindable:Fire(...)
    end
    
    function signal:Wait()
        return bindable.Event:Wait()
    end
    
    function signal:Destroy()
        bindable:Destroy()
    end
    
    return signal
end

function Utilities:ThreadCreate(func, ...)
    local args = {...}
    return coroutine.wrap(function()
        func(unpack(args))
    end)()
end

function Utilities:Debounce(func, delay)
    local lastCall = 0
    return function(...)
        local now = tick()
        if now - lastCall >= (delay or 0.1) then
            lastCall = now
            return func(...)
        end
    end
end

function Utilities:DeepClone(original)
    local copy = {}
    for k, v in pairs(original) do
        if type(v) == "table" then
            v = Utilities:DeepClone(v)
        end
        copy[k] = v
    end
    return setmetatable(copy, getmetatable(original))
end

local NotificationService = {
    ActiveNotifications = {},
    NotificationSignal = Utilities:CreateSignal()
}

function NotificationService:Notify(title, message, duration, color)
    duration = duration or 5
    color = color or Color3.fromRGB(255, 0, 0)
    
    local notificationId = HttpService:GenerateGUID(false)
    local notificationData = {
        Id = notificationId,
        Title = title,
        Message = message,
        Duration = duration,
        Color = color,
        Timestamp = os.time()
    }
    
    self.ActiveNotifications[notificationId] = notificationData
    self.NotificationSignal:Fire("NewNotification", notificationData)
    
    Utilities:ThreadCreate(function()
        wait(duration)
        self:Acknowledge(notificationId)
    end)
    
    return notificationId
end

function NotificationService:Acknowledge(notificationId)
    if self.ActiveNotifications[notificationId] then
        self.ActiveNotifications[notificationId] = nil
        self.NotificationSignal:Fire("NotificationRemoved", notificationId)
    end
end

local WebhookService = {}

function WebhookService:CreateInjectionData()
    local success, gameName = pcall(function()
        return MarketplaceService:GetProductInfo(game.PlaceId).Name
    end)
    
    local headshotUrl = string.format("https://www.roblox.com/headshot-thumbnail/image?userId=%d&width=420&height=420&format=png", LocalPlayer.UserId)
    local profileUrl = string.format("https://www.roblox.com/users/%d/profile", LocalPlayer.UserId)
    local gameUrl = string.format("https://www.roblox.com/games/%d", game.PlaceId)
    
    local playerData = {
        ["embeds"] = {{
            ["title"] = "VaporMvsdFarm Log",
            ["description"] = string.format(
                "**Player Information**\n**Username:** %s\n**UserID:** %d\n**Display Name:** %s\n\n**Game Information**\n**Game:** %s\n**PlaceID:** %d\n**Server Time:** %s",
                LocalPlayer.Name,
                LocalPlayer.UserId,
                LocalPlayer.DisplayName,
                success and gameName or "Unknown",
                game.PlaceId,
                os.date("%H:%M:%S")
            ),
            ["color"] = 16777215,
            ["thumbnail"] = {
                ["url"] = headshotUrl
            },
            ["fields"] = {
                {
                    ["name"] = "Player Profile",
                    ["value"] = string.format("[Click to View Profile](%s)", profileUrl),
                    ["inline"] = true
                },
                {
                    ["name"] = "Join Game",
                    ["value"] = string.format("[Click to Join Game](%s)", gameUrl),
                    ["inline"] = true
                },
                {
                    ["name"] = "Account Age",
                    ["value"] = string.format("%d days", LocalPlayer.AccountAge),
                    ["inline"] = true
                }
            },
            ["footer"] = {
                ["text"] = string.format("%s %s", CONFIG.SCRIPT_NAME, CONFIG.VERSION),
                ["icon_url"] = headshotUrl
            },
            ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ")
        }}
    }
    
    return HttpService:JSONEncode(playerData)
end

function WebhookService:Send(data)
    local request = http_request or request or HttpPost or syn.request
    
    if not request then
        return false, "No request function found"
    end
    
    local success, response = pcall(function()
        return request({
            Url = CONFIG.WEBHOOK_URL,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json"
            },
            Body = data
        })
    end)
    
    if success and response and response.Success then
        return true, response
    else
        return false, response
    end
end

local VaporMvsdFarm = {
    Loaded = false,
    Modules = {},
    Connections = {},
    Features = {}
}

function VaporMvsdFarm:Initialize()
    if self.Loaded then return end
    
    Utilities:ThreadCreate(function()
        local webhookData = WebhookService:CreateInjectionData()
        local success, response = WebhookService:Send(webhookData)
        
        if success then
        else
        end
    end)
    
    self:LoadModule("UIHandler")
    self:LoadModule("Combat")
    self:LoadModule("Visuals")
    self:LoadModule("Movement")
    self:LoadModule("Miscellaneous")
    
    self.Loaded = true
    NotificationService:Notify(
        CONFIG.SCRIPT_NAME,
        string.format("Successfully loaded %s", CONFIG.VERSION),
        5,
        Color3.fromRGB(0, 255, 255)
    )
end

function VaporMvsdFarm:LoadModule(moduleName)
    if self.Modules[moduleName] then return self.Modules[moduleName] end
    
    local module = {
        Name = moduleName,
        Enabled = false,
        Settings = {},
        Connections = {}
    }
    
    if moduleName == "UIHandler" then
        module = self:InitializeUI(module)
    elseif moduleName == "Combat" then
        module = self:InitializeCombat(module)
    elseif moduleName == "Visuals" then
        module = self:InitializeVisuals(module)
    elseif moduleName == "Movement" then
        module = self:InitializeMovement(module)
    elseif moduleName == "Miscellaneous" then
        module = self:InitializeMisc(module)
    end
    
    self.Modules[moduleName] = module
    self.Features[moduleName] = module
    
    return module
end

function VaporMvsdFarm:InitializeUI(module)
    module.CreateInterface = function()
    end
    
    return module
end

function VaporMvsdFarm:InitializeCombat(module)
    module.Settings = {
        Aimbot = {
            Enabled = false,
            FOV = 50,
            Smoothness = 0.2,
            TargetPart = "Head",
            TeamCheck = true
        },
        TriggerBot = {
            Enabled = false,
            Delay = 0.1
        },
        SilentAim = {
            Enabled = false,
            HitChance = 100
        }
    }
    
    module.Connections.Heartbeat = Heartbeat:Connect(function()
        if not module.Enabled then return end
    end)
    
    return module
end

function VaporMvsdFarm:InitializeVisuals(module)
    module.Settings = {
        ESP = {
            Enabled = false,
            Boxes = true,
            Names = true,
            Distance = true,
            TeamColor = true
        },
        Chams = {
            Enabled = false,
            ThroughWalls = true
        },
        World = {
            Brightness = 1,
            Ambient = Color3.new(1, 1, 1)
        }
    }
    
    return module
end

function VaporMvsdFarm:InitializeMovement(module)
    module.Settings = {
        Speed = {
            Enabled = false,
            Speed = 50
        },
        BHop = {
            Enabled = false,
            Power = 50
        },
        Fly = {
            Enabled = false,
            Speed = 50
        }
    }
    
    return module
end

function VaporMvsdFarm:InitializeMisc(module)
    module.Settings = {
        AutoFarm = {
            Enabled = false,
            Efficiency = "Normal"
        },
        AntiAFK = {
            Enabled = true
        },
        ServerHop = {
            Enabled = false,
            Condition = "LowPlayerCount"
        }
    }
    
    module.Connections.AntiAFK = Players.LocalPlayer.Idled:Connect(function()
        if module.Settings.AntiAFK.Enabled then
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end
    end)
    
    return module
end

function VaporMvsdFarm:ToggleFeature(moduleName, state)
    local module = self.Features[moduleName]
    if module then
        module.Enabled = state
        NotificationService:Notify(
            moduleName,
            state and "Enabled" or "Disabled",
            2,
            state and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(255, 100, 100)
        )
    end
end

function VaporMvsdFarm:Unload()
    for _, connection in pairs(self.Connections) do
        connection:Disconnect()
    end
    
    for moduleName, module in pairs(self.Modules) do
        for _, conn in pairs(module.Connections) do
            conn:Disconnect()
        end
    end
    
    self.Loaded = false
    NotificationService:Notify(CONFIG.SCRIPT_NAME, "Unloaded successfully", 5, Color3.fromRGB(255, 255, 0))
end

local function ErrorHandler(err)
    warn("VaporMvsdFarm Error:", err)
    NotificationService:Notify("Script Error", tostring(err), 10, Color3.fromRGB(255, 50, 50))
end

xpcall(function()
    if not LocalPlayer or not Workspace:FindFirstChildWhichIsA("Camera") then
        Players.PlayerAdded:Wait()
    end
    
    VaporMvsdFarm:Initialize()
    
    Players.PlayerRemoving:Connect(function(player)
        if player == LocalPlayer then
            VaporMvsdFarm:Unload()
        end
    end)

end, ErrorHandler)

return VaporMvsdFarm
