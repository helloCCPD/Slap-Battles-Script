--[[  VENICE HUB  |  Slap Battles  |  Rayfield-style UI + Advanced Anti-Cheat  ]]

--==================================================================================--
-- 0. BOOTSTRAP
--==================================================================================--
if not game:IsLoaded() then game.Loaded:Wait() end
if not getgenv then getgenv = function() return _G end end
local function getContainer()
    local ok, hui = pcall(function() return gethui and gethui() end)
    if ok and hui then return hui end
    return game:GetService("CoreGui")
end
if getgenv().VeniceHubLoaded and getgenv().VeniceUnload then pcall(getgenv().VeniceUnload) end
getgenv().VeniceHubLoaded = true

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService   = game:GetService("TeleportService")
local VirtualUser       = game:GetService("VirtualUser")
local LocalPlayer       = Players.LocalPlayer
local Connections       = {}
local CONFIG = { BlackList = {"stevebody","rock","Counterd","Mirage","Reversed","Digging"}, TimeNotify = 5, Accent = Color3.fromRGB(138,92,246) }
local function hook(c) table.insert(Connections, c) end

--==================================================================================--
-- 1. UTILITY
--==================================================================================--
local function new(class, props, children)
    local o = Instance.new(class)
    if props then for k, v in pairs(props) do pcall(function() o[k] = v end) end end
    if children then for _, c in ipairs(children) do if typeof(c) == "Instance" then c.Parent = o end end end
    return o
end
local function getAttr(obj, name)
    if not (obj and obj.Parent) then return end
    name = name:lower()
    for k, v in pairs(obj:GetAttributes()) do if k:lower():find(name) then return v end end
end
pcall(function()
    if not fireclickdetector then
        local lib = loadstring(game:HttpGet("https://raw.githubusercontent.com/Articles-Hub/ROBLOXScript/refs/heads/main/SCRIPT/Fix.lua"))()
        fireclickdetector = fireclickdetector or lib.fireclickdetector
        fireproximityprompt = fireproximityprompt or lib.fireproximityprompt
    end
end)

function Notify(text, time)
    time = time or CONFIG.TimeNotify
    local UI = getgenv().VeniceUI
    if UI and UI.Notify then UI:Notify(tostring(text), time) else print("[Venice] " .. tostring(text)) end
end
function FoundPlr(q, n)
    local t; for _, v in ipairs(Players:GetPlayers()) do if v.Name:lower():find(q:lower()) then t = v break end end
    if n then Notify(t and ("Found: " .. t.Name) or "Not found") end
    return t
end
function CheckGlove() local ls = LocalPlayer:FindFirstChild("leaderstats"); return ls and ls:FindFirstChild("Glove") and ls.Glove.Value end
function CheckSlap() local ls = LocalPlayer:FindFirstChild("leaderstats"); return ls and ls:FindFirstChild("Slaps") and tonumber(ls.Slaps.Value) or 0 end
function notSlap(char, list)
    if not char then return false end
    for _, v in ipairs(char:GetChildren()) do local n = v.Name:lower(); for _, b in ipairs(list) do if n:find(b:lower()) then return false end end end
    return true
end
function TargetPlayers(skip)
    local t, tr, d = nil, nil, math.huge
    local mr = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart"); if not mr then return end
    for _, v in ipairs(Players:GetPlayers()) do
        if v ~= LocalPlayer and v.Character then
            local c = v.Character
            if c:FindFirstChild("entered") and c:FindFirstChild("HumanoidRootPart") and c.HumanoidRootPart.BrickColor ~= BrickColor.new("New Yeller") and notSlap(c, CONFIG.BlackList) and not c.Head:FindFirstChild("UnoReverseCard") then
                local dd = (mr.Position - c.HumanoidRootPart.Position).Magnitude
                if dd < d and (not skip or not LocalPlayer:IsFriendsWith(v.UserId)) then t, tr, d = c, c.HumanoidRootPart, dd end
            end
        end
    end
    return t, tr, d
end
function CreateFreezeBV(o)
    o = o or {}; local name = o.Name or "FreezeBV"
    local char = LocalPlayer.Character; local hrp = char and char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
    if o.Remove then local e = hrp:FindFirstChild(name); if e then e:Destroy() end return end
    local e = hrp:FindFirstChild(name)
    if not e then e = new("BodyVelocity", { Name = name, Parent = hrp, P = 10000, MaxForce = o.MaxForce or Vector3.new(1e9,1e9,1e9), Velocity = o.Velocity or Vector3.zero }) end
    return e
end

--==================================================================================--
-- 2. GLOVE MAPS
--==================================================================================--
local function sr(n) return ReplicatedStorage:FindFirstChild(n) end
gloveHits = { ["All"] = sr("GeneralHit"), ["Default"] = sr("b"), ["Extended"] = sr("b"), ["Brick"] = sr("BrickHit"),
    ["Snow"] = sr("SnowHit"), ["Fort"] = sr("Fort"), ["Bomb"] = sr("BombHit"), ["Replica"] = sr("ReplicaHit"),
    ["Phase"] = sr("PhaseH"), ["Shard"] = sr("ShardHIT"), ["bus"] = sr("hitbus"), ["Null"] = sr("NullHit"),
    ["Pusher"] = sr("PusherHit"), ["Golden"] = sr("GoldenHit"), ["Killstreak"] = sr("KSHit"), ["Error"] = sr("Errorhit") }
local function equipGloveRemote(name)
    local net = ReplicatedStorage:FindFirstChild("BACKEND"); net = net and net:FindFirstChild("Lib") and net.Lib:FindFirstChild("Network")
    local mod = net and require(net); if mod and mod.fireServer then mod.fireServer("SelectGlove", name) end
end
function equipglove(name)
    if CheckGlove() and CheckGlove():lower() == name:lower() then return end
    equipGloveRemote(name)
    local t = tick(); repeat task.wait() until tick() - t > 0.8 or (CheckGlove() and CheckGlove():lower() == name:lower())
end
function slapglove(obj)
    if not obj then return end
    local cur = CheckGlove(); if not cur then return end
    local hit = gloveHits[cur] or gloveHits["All"]; if not hit then return end
    pcall(function()
        if cur:lower() == "stalker" then hit:FireServer(obj, false, 45)
        elseif cur:lower() == "glovel" or cur:lower() == "mutation" then hit:FireServer(obj, true)
        elseif cur:lower() == "mace" then hit:FireServer(obj, 100)
        else hit:FireServer(obj) end
    end)
end

--==================================================================================--
-- 3. ANTI-CHEAT
--==================================================================================--
local allowedPlaces = { [6403373529]=true,[136802962479827]=true,[127174121130060]=true,[11520107397]=true,[124596094333302]=true,[2380077519]=true,[9015014224]=true }
local isSlapBattles = allowedPlaces[game.PlaceId] or getAttr(workspace,"no_one_shot") or getAttr(workspace,"killstreak")
local bypassOK = false
if isSlapBattles then
    bypassOK = pcall(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/NewNexer/NexerHub/refs/heads/main/SB/Modules/CleanClientAntiCheat.luau"))("Slap Battles") end)
end
getgenv().GloveMethod = getgenv().GloveMethod or "Default"
getgenv().AntiSpam = getgenv().AntiSpam or false
getgenv().AntiPiano = getgenv().AntiPiano or false
getgenv().AntiConfuse = getgenv().AntiConfuse or false
getgenv().AntiNight = getgenv().AntiNight or false
local ReplicaCount = 0
local function wantsHook() return getgenv().GloveMethod ~= "Default" or getgenv().AntiSpam or getgenv().AntiPiano or getgenv().AntiConfuse or getgenv().AntiNight end
local function patchArgs(self, args)
    local rn = tostring(self); local g = tostring(getgenv().GloveMethod):lower(); if g == "default" then return false end
    if rn == "GoldenHit" and g:find("golden") then args[2] = true; return true end
    if rn == "GeneralHit" then
        if g:find("glovel") or g:find("mutation") then args[2] = true; return true end
        if g:find("mace") then args[2] = 200; return true end
        if g:find("charge") or g:find("stalker") then args[3] = 48; return true end
    end
    if rn == "GeneralAbility" and g:find("frostbite") and not tonumber(args[2]) then args[1] = 3; args[2] = 2; return true end
    return false
end
local function installHook()
    if not (hookmetamethod and getnamecallmethod) then return false end
    if getgenv().VeniceHook then return true end
    local orig
    local function guarded(self, ...)
        if getgenv().VeniceHookDisabled then return orig(self, ...) end
        local args = { ... }; local m = getnamecallmethod()
        if m == "FireServer" then
            if patchArgs(self, args) then return orig(self, unpack(args)) end
            local rn = tostring(self)
            if rn == "GeneralAbility" and args[1] == "antispam" and getgenv().AntiSpam then return end
            if rn == "Piano" and getgenv().AntiPiano then return end
            if rn == "Duplicate" and args[1] == true then ReplicaCount += 1 end
        elseif m == "InvokeServer" then
            if tostring(self) == "Psychokinesis" and type(args[1]) == "table" and type(args[1].throwbackAlpha) == "number" then args[1].throwbackAlpha = math.huge; return orig(self, unpack(args)) end
        elseif m == "FireClient" or m == "FireAllClients" then
            local rn = tostring(self)
            if rn == "Confuse" and getgenv().AntiConfuse then return end
            if rn == "VFX" and args[1] == "NightmareEffect" and getgenv().AntiNight then return end
        end
        return orig(self, ...)
    end
    if newcclosure then guarded = newcclosure(guarded) end
    orig = hookmetamethod(game, "__namecall", guarded)
    getgenv().VeniceHook = orig; getgenv().VeniceHookDisabled = not wantsHook(); return true
end
local function refreshHook()
    if wantsHook() then
        if not installHook() then getgenv().GloveMethod="Default"; getgenv().AntiSpam=false; getgenv().AntiPiano=false; getgenv().AntiConfuse=false; getgenv().AntiNight=false; return false end
        getgenv().VeniceHookDisabled = false
    elseif getgenv().VeniceHook then getgenv().VeniceHookDisabled = true end
    return true
end
refreshHook()
task.spawn(function()
    while getgenv().VeniceHubLoaded do
        task.wait(4)
        pcall(function()
            if wantsHook() and not getgenv().VeniceHook then installHook() end
            if isSlapBattles and bypassOK and getAttr(workspace,"no_one_shot")==nil and getAttr(workspace,"killstreak")==nil then
                loadstring(game:HttpGet("https://raw.githubusercontent.com/NewNexer/NexerHub/refs/heads/main/SB/Modules/CleanClientAntiCheat.luau"))("Slap Battles")
            end
        end)
    end
end)
function setAntiAfk(on)
    if getconnections then for _, c in ipairs(getconnections(LocalPlayer.Idled)) do if on then c:Disable() else c:Enable() end end end
end

--==================================================================================--
-- 4. UI LIBRARY  (deterministic layout — no AutomaticSize in content path)
--==================================================================================--
local Ven = {}
Ven.__index = Ven
Ven.Toggles = {}
Ven.Keybinds = {}
Ven.Accent = CONFIG.Accent
Ven.Window = nil
local function tween(i, t, p, s, d) local x = TweenService:Create(i, TweenInfo.new(t or 0.2, s or Enum.EasingStyle.Quad, d or Enum.EasingDirection.Out), p); x:Play(); return x end

function Ven:MakeDraggable(frame, handle)
    handle = handle or frame
    local drag, ds, sp
    handle.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            drag, ds, sp = true, i.Position, frame.Position
            i.Changed:Connect(function() if i.UserInputState == Enum.UserInputState.End then drag = false end end)
        end
    end)
    handle.InputChanged:Connect(function(i)
        if drag and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            local d = i.Position - ds
            frame.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X, sp.Y.Scale, sp.Y.Offset + d.Y)
        end
    end)
end

function Ven:Notify(text, time)
    if not self.Window then return end
    local toast = new("Frame", { Parent = self.Window.NotifyHolder, Size = UDim2.new(0,240,0,52), BackgroundColor3 = Color3.fromRGB(24,24,32), BorderSizePixel = 0, Position = UDim2.new(0,260,0,0), ClipsDescendants = true })
    new("UICorner", { CornerRadius = UDim.new(0,8), Parent = toast })
    new("Frame", { Size = UDim2.new(0,3,1,0), BackgroundColor3 = self.Accent, BorderSizePixel = 0, Parent = toast })
    new("TextLabel", { Parent = toast, Size = UDim2.new(1,-20,1,0), Position = UDim2.new(0,14,0,0), BackgroundTransparency = 1, Text = text, TextColor3 = Color3.fromRGB(235,235,245), Font = Enum.Font.GothamMedium, TextSize = 13, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left })
    tween(toast, 0.25, { Position = UDim2.new(0,8,0,0) }, Enum.EasingStyle.Back)
    task.delay(time or 5, function() tween(toast, 0.25, { Position = UDim2.new(0,260,0,0), BackgroundTransparency = 1 }); task.wait(0.3); toast:Destroy() end)
end

function Ven:CreateWindow(opts)
    opts = opts or {}
    local gui = new("ScreenGui", { Name = "VeniceHub", ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 999 })
    gui.Parent = getContainer()
    local main = new("Frame", { Parent = gui, Size = opts.Size or UDim2.new(0,620,0,420), Position = UDim2.new(0.5,-310,0.5,-210), BackgroundColor3 = Color3.fromRGB(18,18,24), BorderSizePixel = 0 })
    new("UICorner", { CornerRadius = UDim.new(0,12), Parent = main })
    new("UIStroke", { Color = Color3.fromRGB(45,45,60), Thickness = 1.4, Parent = main })
    local bar = new("Frame", { Parent = main, Size = UDim2.new(1,0,0,40), BackgroundTransparency = 1 })
    new("TextLabel", { Parent = bar, Position = UDim2.new(0,16,0,0), Size = UDim2.new(0.6,0,1,0), BackgroundTransparency = 1, Text = opts.Title or "Venice Hub", Font = Enum.Font.GothamBold, TextSize = 15, TextColor3 = Color3.fromRGB(240,240,250), TextXAlignment = Enum.TextXAlignment.Left })
    local close = new("TextButton", { Parent = bar, Size = UDim2.new(0,30,0,30), Position = UDim2.new(1,-38,0,5), BackgroundColor3 = Color3.fromRGB(30,30,40), BorderSizePixel = 0, Text = "–", TextColor3 = Color3.fromRGB(200,200,210), Font = Enum.Font.GothamBold, TextSize = 16 })
    new("UICorner", { CornerRadius = UDim.new(0,6), Parent = close })
    local min = new("TextButton", { Parent = bar, Size = UDim2.new(0,30,0,30), Position = UDim2.new(1,-74,0,5), BackgroundColor3 = Color3.fromRGB(30,30,40), BorderSizePixel = 0, Text = "×", TextColor3 = Color3.fromRGB(200,200,210), Font = Enum.Font.GothamBold, TextSize = 16 })
    new("UICorner", { CornerRadius = UDim.new(0,6), Parent = min })
    min.MouseButton1Click:Connect(function() main.Visible = not main.Visible end)
    close.MouseButton1Click:Connect(function() main.Visible = false end)
    self:MakeDraggable(main, bar)
    local side = new("Frame", { Parent = main, Size = UDim2.new(0,156,1,-52), Position = UDim2.new(0,8,0,44), BackgroundColor3 = Color3.fromRGB(22,22,30), BorderSizePixel = 0 })
    new("UICorner", { CornerRadius = UDim.new(0,10), Parent = side })
    local sideList = new("ScrollingFrame", { Parent = side, Size = UDim2.new(1,-12,1,-16), Position = UDim2.new(0,6,0,8), BackgroundTransparency = 1, ScrollBarThickness = 2, BorderSizePixel = 0, CanvasSize = UDim2.new(0,0,0,0), AutomaticCanvasSize = Enum.AutomaticSize.Y })
    new("UIListLayout", { Parent = sideList, Padding = UDim.new(0,4), SortOrder = Enum.SortOrder.LayoutOrder })
    local content = new("Frame", { Parent = main, Size = UDim2.new(1,-180,1,-52), Position = UDim2.new(0,172,0,44), BackgroundTransparency = 1 })
    local nh = new("Frame", { Parent = gui, Size = UDim2.new(0,250,1,0), Position = UDim2.new(1,-260,0,20), BackgroundTransparency = 1 })
    new("UIListLayout", { Parent = nh, Padding = UDim.new(0,8), VerticalAlignment = Enum.VerticalAlignment.Top })
    self.Window = { Gui = gui, Main = main, Sidebar = sideList, Content = content, NotifyHolder = nh }
    self.Tabs = {}
    return self
end

function Ven:Tab(name)
    local btn = new("TextButton", { Parent = self.Window.Sidebar, Size = UDim2.new(1,0,0,32), BackgroundColor3 = Color3.fromRGB(30,30,40), BackgroundTransparency = 1, BorderSizePixel = 0, Text = "", AutoButtonColor = false })
    new("UICorner", { CornerRadius = UDim.new(0,7), Parent = btn })
    local ind = new("Frame", { Parent = btn, Size = UDim2.new(0,3,0.6,0), Position = UDim2.new(0,0,0.2,0), BackgroundColor3 = self.Accent, BorderSizePixel = 0 })
    new("UICorner", { CornerRadius = UDim.new(0,3), Parent = ind })
    new("TextLabel", { Parent = btn, Size = UDim2.new(1,-16,1,0), Position = UDim2.new(0,14,0,0), BackgroundTransparency = 1, Text = name, Font = Enum.Font.GothamMedium, TextSize = 13, TextColor3 = Color3.fromRGB(170,170,185), TextXAlignment = Enum.TextXAlignment.Left })
    local page = new("ScrollingFrame", { Parent = self.Window.Content, Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1, ScrollBarThickness = 3, BorderSizePixel = 0, Visible = false, CanvasSize = UDim2.new(0,0,0,0) })
    local tab = { Button = btn, Page = page, Indicator = ind, Owner = self, Sections = {} }
    function tab:Select()
        for _, t in pairs(self.Owner.Tabs) do
            t.Page.Visible = false; tween(t.Button, 0.15, { BackgroundTransparency = 1 }); t.Indicator.BackgroundTransparency = 1
            for _, c in ipairs(t.Button:GetChildren()) do if c:IsA("TextLabel") then c.TextColor3 = Color3.fromRGB(170,170,185) end end
        end
        page.Visible = true; tween(btn, 0.15, { BackgroundTransparency = 0 }); ind.BackgroundTransparency = 0
        for _, c in ipairs(btn:GetChildren()) do if c:IsA("TextLabel") then c.TextColor3 = Color3.fromRGB(240,240,250) end end
    end
    btn.MouseButton1Click:Connect(function() tab:Select() end)
    table.insert(self.Tabs, tab)
    if #self.Tabs == 1 then tab:Select() end
    return tab
end

-- Section with manual, deterministic height
function Ven:Section(tab, title)
    local frame = new("Frame", { Parent = tab.Page, Size = UDim2.new(1,-6,0,32), BackgroundColor3 = Color3.fromRGB(24,24,32), BorderSizePixel = 0 })
    new("UICorner", { CornerRadius = UDim.new(0,9), Parent = frame })
    new("UIStroke", { Color = Color3.fromRGB(40,40,55), Thickness = 1, Parent = frame })
    new("TextLabel", { Parent = frame, Size = UDim2.new(1,-20,0,16), Position = UDim2.new(0,10,0,8), BackgroundTransparency = 1, Text = title, Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = self.Accent, TextXAlignment = Enum.TextXAlignment.Left })
    local sec = { Frame = frame, Cursor = 32, Owner = self, Tab = tab }
    function sec:Reflow()
        local y = 0
        for _, s in ipairs(tab.Sections) do s.Frame.Position = UDim2.new(0,0,0,y); y = y + s.Frame.Size.Y.Offset + 8 end
        tab.Page.CanvasSize = UDim2.new(0,0,0,y + 20)
    end
    function sec:Row(inst, h)
        inst.Size = UDim2.new(1,-20,0,h)
        inst.Position = UDim2.new(0,10,0,sec.Cursor)
        inst.Parent = frame
        sec.Cursor = sec.Cursor + h + 6
        frame.Size = UDim2.new(1,-6,0,sec.Cursor + 6)
        sec:Reflow()
    end
    table.insert(tab.Sections, sec)
    sec:Reflow()
    return sec
end

function Ven:Toggle(sec, text, default, callback)
    local row = new("Frame", { BackgroundTransparency = 1 })
    new("TextLabel", { Parent = row, Size = UDim2.new(1,-50,1,0), BackgroundTransparency = 1, Text = text, Font = Enum.Font.GothamMedium, TextSize = 13, TextColor3 = Color3.fromRGB(215,215,228), TextXAlignment = Enum.TextXAlignment.Left })
    local pill = new("TextButton", { Parent = row, Size = UDim2.new(0,38,0,20), Position = UDim2.new(1,-38,0.5,-10), BackgroundColor3 = Color3.fromRGB(45,45,60), BorderSizePixel = 0, Text = "" })
    new("UICorner", { CornerRadius = UDim.new(1,0), Parent = pill })
    local dot = new("Frame", { Parent = pill, Size = UDim2.new(0,14,0,14), Position = UDim2.new(0,3,0.5,-7), BackgroundColor3 = Color3.fromRGB(200,200,210), BorderSizePixel = 0 })
    new("UICorner", { CornerRadius = UDim.new(1,0), Parent = dot })
    local state = false
    local obj = { Owner = self, Text = text }
    function obj:Set(v, fire)
        state = v
        tween(pill, 0.15, { BackgroundColor3 = v and self.Owner.Accent or Color3.fromRGB(45,45,60) })
        tween(dot, 0.15, { Position = v and UDim2.new(1,-17,0.5,-7) or UDim2.new(0,3,0.5,-7), BackgroundColor3 = v and Color3.new(1,1,1) or Color3.fromRGB(200,200,210) })
        if fire ~= false and callback then task.spawn(callback, v) end
    end
    function obj:Get() return state end
    pill.MouseButton1Click:Connect(function() obj:Set(not state) end)
    sec:Row(row, 28)
    obj:Set(default or false, false)
    table.insert(Ven.Toggles, obj)
    return obj
end

function Ven:Button(sec, text, callback)
    local btn = new("TextButton", { BackgroundColor3 = Color3.fromRGB(34,34,46), BorderSizePixel = 0, Text = text, Font = Enum.Font.GothamMedium, TextSize = 13, TextColor3 = Color3.fromRGB(220,220,232), AutoButtonColor = false })
    new("UICorner", { CornerRadius = UDim.new(0,7), Parent = btn })
    btn.MouseEnter:Connect(function() tween(btn, 0.12, { BackgroundColor3 = Color3.fromRGB(44,44,60) }) end)
    btn.MouseLeave:Connect(function() tween(btn, 0.12, { BackgroundColor3 = Color3.fromRGB(34,34,46) }) end)
    btn.MouseButton1Click:Connect(function() task.spawn(callback) end)
    sec:Row(btn, 28)
    return btn
end

function Ven:Label(sec, text)
    local l = new("TextLabel", { BackgroundTransparency = 1, Text = text, Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = Color3.fromRGB(180,180,195), TextXAlignment = Enum.TextXAlignment.Left })
    sec:Row(l, 20)
    return l
end

function Ven:Slider(sec, text, min, max, default, callback)
    local row = new("Frame", { BackgroundTransparency = 1 })
    new("TextLabel", { Parent = row, Size = UDim2.new(1,-60,0,16), BackgroundTransparency = 1, Text = text, Font = Enum.Font.GothamMedium, TextSize = 12, TextColor3 = Color3.fromRGB(210,210,224), TextXAlignment = Enum.TextXAlignment.Left })
    local val = new("TextLabel", { Parent = row, Size = UDim2.new(0,50,0,16), Position = UDim2.new(1,-50,0,0), BackgroundTransparency = 1, Text = tostring(default), Font = Enum.Font.GothamMedium, TextSize = 12, TextColor3 = self.Accent, TextXAlignment = Enum.TextXAlignment.Right })
    local track = new("Frame", { Parent = row, Size = UDim2.new(1,0,0,6), Position = UDim2.new(0,0,0,26), BackgroundColor3 = Color3.fromRGB(45,45,60), BorderSizePixel = 0 })
    new("UICorner", { CornerRadius = UDim.new(1,0), Parent = track })
    local fill = new("Frame", { Parent = track, Size = UDim2.new((default-min)/(max-min),0,1,0), BackgroundColor3 = self.Accent, BorderSizePixel = 0 })
    new("UICorner", { CornerRadius = UDim.new(1,0), Parent = fill })
    local knob = new("Frame", { Parent = track, Size = UDim2.new(0,12,0,12), Position = UDim2.new((default-min)/(max-min),-6,0.5,-6), BackgroundColor3 = Color3.new(1,1,1), BorderSizePixel = 0 })
    new("UICorner", { CornerRadius = UDim.new(1,0), Parent = knob })
    local dragging = false
    local function setFromX(x)
        local rel = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        local n = math.floor(min + rel * (max - min) + 0.5)
        fill.Size = UDim2.new(rel,0,1,0); knob.Position = UDim2.new(rel,-6,0.5,-6); val.Text = tostring(n)
        if callback then task.spawn(callback, n) end
    end
    track.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = true; setFromX(i.Position.X) end end)
    UserInputService.InputChanged:Connect(function(i) if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then setFromX(i.Position.X) end end)
    UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = false end end)
    sec:Row(row, 40)
end

function Ven:Input(sec, text, default, callback)
    local box = new("TextButton", { BackgroundColor3 = Color3.fromRGB(28,28,38), BorderSizePixel = 0, Text = "", AutoButtonColor = false })
    new("UICorner", { CornerRadius = UDim.new(0,7), Parent = box })
    new("UIStroke", { Color = Color3.fromRGB(45,45,60), Thickness = 1, Parent = box })
    new("TextLabel", { Parent = box, Size = UDim2.new(0,90,1,0), Position = UDim2.new(0,10,0,0), BackgroundTransparency = 1, Text = text, Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = Color3.fromRGB(150,150,165), TextXAlignment = Enum.TextXAlignment.Left })
    local tb = new("TextBox", { Parent = box, Size = UDim2.new(1,-105,1,0), Position = UDim2.new(0,100,0,0), BackgroundTransparency = 1, Text = default or "", Font = Enum.Font.GothamMedium, TextSize = 12, TextColor3 = Color3.fromRGB(225,225,238), PlaceholderText = "type...", TextXAlignment = Enum.TextXAlignment.Left })
    tb.FocusLost:Connect(function() if callback then task.spawn(callback, tb.Text) end end)
    sec:Row(box, 28)
    return tb
end

function Ven:Dropdown(sec, text, values, multi, default, callback)
    local selected = {}
    local row = new("Frame", { BackgroundTransparency = 1 })
    new("TextLabel", { Parent = row, Size = UDim2.new(1,0,0,18), BackgroundTransparency = 1, Text = text, Font = Enum.Font.GothamMedium, TextSize = 12, TextColor3 = Color3.fromRGB(210,210,224), TextXAlignment = Enum.TextXAlignment.Left })
    local box = new("TextButton", { Parent = row, Size = UDim2.new(1,0,0,28), Position = UDim2.new(0,0,0,22), BackgroundColor3 = Color3.fromRGB(28,28,38), BorderSizePixel = 0, Text = "Select...", Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = Color3.fromRGB(170,170,185), AutoButtonColor = false })
    new("UICorner", { CornerRadius = UDim.new(0,7), Parent = box })
    new("UIStroke", { Color = Color3.fromRGB(45,45,60), Thickness = 1, Parent = box })
    local rowTop = sec.Cursor
    sec:Row(row, 56)
    local list = new("Frame", { Parent = sec.Frame, Size = UDim2.new(1,-20,0,#values*26+8), Position = UDim2.new(0,10,0,rowTop + 52), BackgroundColor3 = Color3.fromRGB(28,28,38), BorderSizePixel = 0, Visible = false, ZIndex = 50 })
    new("UICorner", { CornerRadius = UDim.new(0,7), Parent = list })
    local ly = 4
    for _, v in ipairs(values) do
        local opt = new("TextButton", { Parent = list, Size = UDim2.new(1,-8,0,24), Position = UDim2.new(0,4,0,ly), BackgroundColor3 = Color3.fromRGB(34,34,46), BorderSizePixel = 0, Text = "", AutoButtonColor = false, ZIndex = 51 })
        new("UICorner", { CornerRadius = UDim.new(0,5), Parent = opt })
        new("TextLabel", { Parent = opt, Size = UDim2.new(1,-8,1,0), Position = UDim2.new(0,8,0,0), BackgroundTransparency = 1, Text = v, Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = Color3.fromRGB(210,210,224), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 52 })
        opt.MouseButton1Click:Connect(function()
            if multi then selected[v] = not selected[v] and true or nil
            else selected = { [v] = true }; list.Visible = false end
            local arr = {}; for k in pairs(selected) do table.insert(arr, k) end
            box.Text = #arr > 0 and table.concat(arr, ", ") or "Select..."
            if callback then task.spawn(callback, multi and selected or v) end
        end)
        ly = ly + 26
    end
    box.MouseButton1Click:Connect(function() list.Visible = not list.Visible end)
    if default then
        if type(default) == "table" then for _, v in ipairs(default) do selected[v] = true end else selected[default] = true end
        local arr = {}; for k in pairs(selected) do table.insert(arr, k) end
        box.Text = table.concat(arr, ", ")
    end
end

function Ven:KeyPicker(obj, key, mode, callback)
    table.insert(Ven.Keybinds, { Key = key or "RightShift", Mode = mode or "Toggle", Callback = callback, Obj = obj })
end
UserInputService.InputBegan:Connect(function(i, gp)
    if gp then return end
    for _, kb in ipairs(Ven.Keybinds) do
        if i.KeyCode == Enum.KeyCode[kb.Key] then
            if kb.Mode == "Toggle" and kb.Obj and kb.Obj.Set then kb.Obj:Set(not kb.Obj:Get())
            elseif kb.Callback then task.spawn(kb.Callback) end
        end
    end
end)

--==================================================================================--
-- 5. BUILD + FEATURES
--==================================================================================--
local UI
local ok, err = xpcall(function()
    UI = Ven:CreateWindow({ Title = "Venice Hub  •  Slap Battles", Size = UDim2.new(0,640,0,440) })
    getgenv().VeniceUI = UI
    local Tabs = { Info=UI:Tab("Info"), Combat=UI:Tab("Combat"), Anti=UI:Tab("Anti-Cheat"), Local=UI:Tab("Local"),
        Farm=UI:Tab("Farm"), Gloves=UI:Tab("Gloves"), Misc=UI:Tab("Misc"), Settings=UI:Tab("Settings") }

    do -- INFO
        local s = UI:Section(Tabs.Info, "Server / You")
        local fps = UI:Label(s, "FPS: ..."); local ping = UI:Label(s, "Ping: ...")
        local plr = UI:Label(s, "Players: ..."); local glv = UI:Label(s, "Glove: ..."); local slp = UI:Label(s, "Slaps: ...")
        UI:Toggle(s, "Live Update", false, function(v) getgenv().InfoLive = v end)
        UI:Button(s, "Copy Position", function()
            local p = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if p and setclipboard then setclipboard(tostring(p.Position)); Notify("Position copied") end
        end)
        hook(RunService.Heartbeat:Connect(function()
            if not getgenv().InfoLive then return end
            pcall(function()
                fps.Text = "FPS: " .. math.floor(workspace:GetRealPhysicsFPS())
                ping.Text = "Ping: " .. math.floor(game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue())
                plr.Text = "Players: " .. #Players:GetPlayers() .. "/" .. Players.MaxPlayers
                glv.Text = "Glove: " .. tostring(CheckGlove()); slp.Text = "Slaps: " .. tostring(CheckSlap())
            end)
        end))
    end

    do -- COMBAT
        local s = UI:Section(Tabs.Combat, "Slap Aura")
        UI:Slider(s, "Reach", 10, 50, 25, function(v) getgenv().AuraReach = v end)
        UI:Slider(s, "Delay", 0.05, 1, 0.35, function(v) getgenv().AuraDelay = v end)
        local aura = UI:Toggle(s, "Slap Aura", false, function(v)
            getgenv().Aura = v
            if v then task.spawn(function() while getgenv().Aura do local t = TargetPlayers(true); if t then slapglove(t:FindFirstChild("HumanoidRootPart")) end; task.wait(getgenv().AuraDelay or 0.35) end end) end
        end)
        UI:KeyPicker(aura, "H")
        local ab = UI:Section(Tabs.Combat, "Aimbot")
        UI:Toggle(ab, "Aimbot (camera)", false, function(v) getgenv().Aimbot = v end)
        hook(RunService.Heartbeat:Connect(function()
            if not getgenv().Aimbot then return end
            local _, tr = TargetPlayers(true)
            if tr then workspace.CurrentCamera.CFrame = CFrame.lookAt(workspace.CurrentCamera.CFrame.Position, tr.Position + tr.Velocity * 0.15) end
        end))
        local pb = UI:Section(Tabs.Combat, "Auto Parry / Counter")
        UI:Slider(pb, "Range", 10, 35, 16, function(v) getgenv().ParryRange = v end)
        UI:Toggle(pb, "Auto Parry", false, function(v) getgenv().AutoParry = v end)
        UI:Toggle(pb, "Auto Counter", false, function(v) getgenv().AutoCounter = v end)
        hook(RunService.Heartbeat:Connect(function()
            if not (getgenv().AutoParry or getgenv().AutoCounter) then return end
            local g = CheckGlove(); if g ~= "Parry" and g ~= "Counter" then return end
            local mr = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart"); if not mr then return end
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character then
                    local tr = p.Character:FindFirstChild("HumanoidRootPart")
                    if tr and p.Character:FindFirstChild("entered") and (mr.Position - tr.Position).Magnitude <= (getgenv().ParryRange or 16) then
                        pcall(function() if g == "Parry" then ReplicatedStorage.GeneralAbility:FireServer() end; if g == "Counter" then ReplicatedStorage.Counter:FireServer() end end)
                        break
                    end
                end
            end
        end))
    end

    do -- ANTI
        local s = UI:Section(Tabs.Anti, "Advanced Guard")
        UI:Label(s, bypassOK and "Bypass: LOADED" or "Bypass: not found")
        UI:Label(s, getgenv().VeniceHook and "Namecall hook: ACTIVE" or "Namecall hook: off")
        UI:Toggle(s, "Anti Kick (rejoin)", false, function(v)
            getgenv().AntiKick = v
            if v then task.spawn(function() while getgenv().AntiKick do pcall(function()
                local pg = game:GetService("CoreGui").RobloxPromptGui.promptOverlay
                if pg then for _, x in ipairs(pg:GetDescendants()) do if x.Name == "ErrorPrompt" then TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer); break end end end
            end); task.wait(0.5) end end) end
        end)
        UI:Toggle(s, "Anti AFK", false, function(v) getgenv().AntiAfk = v; setAntiAfk(v) end)
        local m = UI:Section(Tabs.Anti, "Remote Patches")
        UI:Dropdown(m, "Method Glove", {"Default","Glovel","Mace","Golden","Charge","Stalker","Frostbite"}, false, "Default", function(v) getgenv().GloveMethod = v; refreshHook() end)
        UI:Toggle(m, "Anti Spam", false, function(v) getgenv().AntiSpam = v; refreshHook() end)
        UI:Toggle(m, "Anti Piano", false, function(v) getgenv().AntiPiano = v; refreshHook() end)
        UI:Toggle(m, "Anti Confuse", false, function(v) getgenv().AntiConfuse = v; refreshHook() end)
        UI:Toggle(m, "Anti Nightmare FX", false, function(v) getgenv().AntiNight = v; refreshHook() end)
        local g = UI:Section(Tabs.Anti, "In-Game Anti")
        local function loop(name, fn)
            local tog = UI:Toggle(g, name, false, function(v) if v then task.spawn(function() while tog:Get() do fn(); task.wait() end end) end end)
        end
        loop("Anti Void", function()
            local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if hrp and hrp.Position.Y < -30 then local o = workspace:FindFirstChild("Origo") or workspace:FindFirstChild("SafeBox"); if o then hrp.CFrame = o.CFrame * CFrame.new(0,5,0) end end
        end)
        loop("Anti Ragdoll", function()
            local c = LocalPlayer.Character; local r = c and c:FindFirstChild("Ragdolled")
            if r and r.Value then
                for _, v in ipairs(c:GetDescendants()) do if v:IsA("BallSocketConstraint") or v:IsA("HingeConstraint") then v.Enabled = false elseif v:IsA("Motor6D") then v.Enabled = true end end
                local h = c:FindFirstChildOfClass("Humanoid"); if h then h:ChangeState(Enum.HumanoidStateType.Running) end
            end
        end)
        loop("Anti Portal", function() local l = workspace:FindFirstChild("Lobby"); if l then for _, n in ipairs({"Teleport2","Teleport3","Teleport4","Teleport6"}) do local p = l:FindFirstChild(n); if p then p.CanTouch = false end end end end)
        loop("Anti COD", function() local cod = workspace:FindFirstChild("the cube of death(i heard it kills)", true); if cod then cod.CanTouch = false; local pt = cod:FindFirstChild("Part"); if pt then pt.CanTouch = false end end end)
        loop("Anti Snowball", function() for _, v in ipairs(workspace:GetChildren()) do if v.Name == "Snowball" then v:Destroy() end end end)
        loop("Anti Trap", function() for _, v in ipairs(workspace:GetChildren()) do if v.Name == "BearTrap" then local h = v:FindFirstChild("HitBox"); if h then h.CanTouch = false end end end end)
    end

    do -- LOCAL
        local s = UI:Section(Tabs.Local, "Movement")
        UI:Slider(s, "WalkSpeed", 16, 500, 20, function(v) getgenv().WS = v; local h = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid"); if h then h.WalkSpeed = v end end)
        UI:Toggle(s, "Lock Speed", false, function(v)
            getgenv().LockWS = v
            if v then task.spawn(function() while getgenv().LockWS do local h = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid"); if h and h.WalkSpeed ~= getgenv().WS then h.WalkSpeed = getgenv().WS end; task.wait() end end) end
        end)
        UI:Slider(s, "JumpPower", 50, 500, 50, function(v) getgenv().JP = v; local h = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid"); if h then h.UseJumpPower = true; h.JumpPower = v end end)
        UI:Slider(s, "Gravity", 0, 200, workspace.Gravity, function(v) workspace.Gravity = v end)
        local f = UI:Section(Tabs.Local, "Fly")
        UI:Slider(f, "Fly Speed", 10, 500, 80, function(v) getgenv().FlySpeed = v end)
        local ft = UI:Toggle(f, "Fly (WASD/Space/Ctrl)", false, function(v)
            getgenv().Flying = v
            local char = LocalPlayer.Character
            if not v then
                if char then
                    local hrp = char:FindFirstChild("HumanoidRootPart")
                    if hrp then for _, n in ipairs({"VeniceFlyBV","VeniceFlyGyro"}) do local e = hrp:FindFirstChild(n); if e then e:Destroy() end end end
                    local h = char:FindFirstChildOfClass("Humanoid"); if h then h.PlatformStand = false end
                end
                return
            end
            task.spawn(function()
                local c = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
                local hrp = c:WaitForChild("HumanoidRootPart"); local h = c:FindFirstChildOfClass("Humanoid")
                local bv = new("BodyVelocity", { Name = "VeniceFlyBV", Parent = hrp, MaxForce = Vector3.new(1e9,1e9,1e9), Velocity = Vector3.zero })
                new("BodyGyro", { Name = "VeniceFlyGyro", Parent = hrp, MaxTorque = Vector3.new(1e9,1e9,1e9), P = 1000, D = 50 })
                h.PlatformStand = true
                while getgenv().Flying do
                    local dir = Vector3.zero; local cam = workspace.CurrentCamera
                    if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir += cam.CFrame.LookVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir -= cam.CFrame.LookVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir -= cam.CFrame.RightVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir += cam.CFrame.RightVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.new(0,1,0) end
                    if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir -= Vector3.new(0,1,0) end
                    bv.Velocity = dir.Magnitude > 0 and dir.Unit * (getgenv().FlySpeed or 80) or Vector3.zero
                    task.wait()
                end
            end
