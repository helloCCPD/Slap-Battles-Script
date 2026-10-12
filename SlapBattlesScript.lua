--[[  VENICE HUB v2  |  Slap Battles  |  Rayfield-style UI + Massive Anti-Cheat / Anti / Mastery / Badges  ]]
--  Merged & upgraded from Venice Hub + Articles-Hub + community protection scripts.

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
local HttpService       = game:GetService("HttpService")
local VirtualUser       = game:GetService("VirtualUser")
local Lighting          = game:GetService("Lighting")
local LocalPlayer       = Players.LocalPlayer
local Connections       = {}
local CONFIG = { BlackList = {"stevebody","rock","Counterd","Mirage","Reversed","Digging"}, TimeNotify = 5, Accent = Color3.fromRGB(138,92,246) }
local function hook(c) table.insert(Connections, c) end
local function safe(g) return ReplicatedStorage:FindFirstChild(g) end

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
    if not fireclickdetector or not firetouchinterest or not fireproximityprompt then
        local lib = loadstring(game:HttpGet("https://raw.githubusercontent.com/Articles-Hub/ROBLOXScript/refs/heads/main/SCRIPT/Fix.lua"))()
        fireclickdetector = fireclickdetector or lib.fireclickdetector
        fireproximityprompt = fireproximityprompt or lib.fireproximityprompt
        firetouchinterest = firetouchinterest or lib.firetouchinterest
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
function CheckUnlockGlove(v) return LocalPlayer:FindFirstChild("_unlockedGloves") and LocalPlayer._unlockedGloves:FindFirstChild(v) end
function CheckBadge(id) local ok, has = pcall(function() return game:GetService("BadgeService"):UserHasBadgeAsync(LocalPlayer.UserId, id) end); return ok and has or false end
function notSlap(char, list)
    if not char then return false end
    for _, v in ipairs(char:GetChildren()) do local n = v.Name:lower(); for _, b in ipairs(list) do if n:find(b:lower()) then return false end end end
    return true
end
function InsideBox(pos, box)
    local rel = box.CFrame:PointToObjectSpace(pos.Position)
    local size = box.Size / 2
    return math.abs(rel.X) <= size.X + 1.2 and math.abs(rel.Y) <= size.Y and math.abs(rel.Z) <= size.Z + 1.2
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
function VectorTween(T)
    T = T or {}; T.Speed = T.Speed or 80
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hrp = char:WaitForChild("HumanoidRootPart")
    local movePart = T.Part or hrp
    local bv = movePart:FindFirstChild("FreezeBV")
    if not bv then bv = new("BodyVelocity", { Name = "FreezeBV", P = 10000, MaxForce = Vector3.new(1e9,1e9,1e9), Velocity = Vector3.zero, Parent = movePart }) end
    repeat task.wait()
        local dir = T.Place - movePart.Position
        bv.Velocity = dir.Magnitude > 0 and dir.Unit * T.Speed or Vector3.zero
    until (movePart.Position - T.Place).Magnitude < 5
    bv.Velocity = Vector3.zero; bv:Destroy()
end
function IsNetworkOwner(part) return part.ReceiveAge == 0 end
function TimeCountdown(duration, cb)
    local start = os.time(); local conn
    conn = RunService.Heartbeat:Connect(function()
        local rem = math.max(0, duration - (os.time() - start))
        local h, m, s = math.floor(rem/3600), math.floor((rem%3600)/60), math.floor(rem%60)
        if cb then cb(string.format("%02d:%02d:%02d", h, m, s), rem) end
        if rem <= 0 then conn:Disconnect() end
    end)
    return conn
end

--==================================================================================--
-- 2. SAFE PARTS (Anti-Void / Safespots)
--==================================================================================--
local function weldChildren(part)
    for _, v in ipairs(part:GetChildren()) do
        if v:IsA("BasePart") then
            new("WeldConstraint", { Part0 = part, Part1 = v, Name = v.Name.." (Weld)", Parent = part })
            v.Anchored = false
        end
    end
end
if not workspace:FindFirstChild("SafeBoxSpace") then
    new("Part", { Name="SafeBoxSpace", Anchored=true, CanCollide=true, Transparency=0.5, Position=Vector3.new(0,15000,0), Size=Vector3.new(150,5,150), Parent=workspace })
end
if not workspace:FindFirstChild("SafeBox") then
    local sb = new("Part", { Name="SafeBox", Anchored=true, CanCollide=true, Transparency=0.5, Position=Vector3.new(-5500,-5000,-5000), Size=Vector3.new(21,5,21), Parent=workspace }, {
        new("Part", { Name="S1", Anchored=true, Transparency=0.5, Position=Vector3.new(-5499.91,-4991.5,-4989.09), Size=Vector3.new(20,13,2) }),
        new("Part", { Name="S2", Anchored=true, Transparency=0.5, Size=Vector3.new(21,14,2), CFrame=CFrame.new(-5510.28,-4991.5,-5000.09)*CFrame.Angles(0,math.rad(-90),0) }),
        new("Part", { Name="S3", Anchored=true, Transparency=0.5, Position=Vector3.new(-5499.3,-4991.5,-5011.12), Size=Vector3.new(21,13,2) }),
        new("Part", { Name="S4", Anchored=true, Transparency=0.5, Size=Vector3.new(22,13,2), CFrame=CFrame.new(-5489.98,-4991.5,-4999.53)*CFrame.Angles(0,math.rad(-90),0) }),
        new("Part", { Name="S5", Anchored=true, Transparency=0.5, Position=Vector3.new(-5499.39,-4984,-5000.07), Size=Vector3.new(24,3,24) }),
    })
    weldChildren(sb)
end
if not workspace:FindFirstChild("Safespot") then
    local sp = new("Part", { Name="Safespot", Position=Vector3.new(10000,-50,10000), Size=Vector3.new(500,10,500), Anchored=true, CanCollide=true, Transparency=0.5, Parent=workspace }, {
        new("Part", { Name="DefendPart4", Anchored=true, Transparency=0.5, Position=Vector3.new(10001.1,76,9999.66), Size=Vector3.new(491,10,491) }),
    })
    weldChildren(sp)
end
if not workspace:FindFirstChild("Bed") then
    local bed = new("Part", { Name="Bed", Anchored=true, CanCollide=false, Transparency=1, Position=Vector3.new(-100019.5,104,-1500), Size=Vector3.new(0.01,0.01,0.01), Parent=workspace }, {
        new("Part", { Name="Bed3", Anchored=true, Position=Vector3.new(-100019,104,-1500), Size=Vector3.new(11,1,7), BrickColor=BrickColor.new("Crimson") }),
    })
    weldChildren(bed)
end

--==================================================================================--
-- 3. GLOVE MAPS (expanded)
--==================================================================================--
gloveHits = {
    ["All"] = safe("GeneralHit"), ["Default"] = safe("b"), ["Extended"] = safe("b"), ["Brick"] = safe("BrickHit"),
    ["Snow"] = safe("SnowHit"), ["Fort"] = safe("Fort"), ["Bomb"] = safe("BombHit"), ["Replica"] = safe("ReplicaHit"),
    ["Phase"] = safe("PhaseH"), ["Shard"] = safe("ShardHIT"), ["bus"] = safe("hitbus"), ["Null"] = safe("NullHit"),
    ["Pusher"] = safe("PusherHit"), ["Golden"] = safe("GoldenHit"), ["Killstreak"] = safe("KSHit"), ["Error"] = safe("Errorhit"),
    ["Ghost"] = safe("GhostHit"), ["Stun"] = safe("HtStun"), ["Za Hando"] = safe("zhramt"), ["Magnet"] = safe("MagnetHIT"),
    ["Anchor"] = safe("hitAnchor"), ["Space"] = safe("HtSpace"), ["Boomerang"] = safe("BoomerangH"), ["Mail"] = safe("MailHit"),
    ["MR"] = safe("MisterHit"), ["Reaper"] = safe("ReaperHit"), ["Defense"] = safe("DefenseHit"), ["Reverse"] = safe("ReverseHit"),
    ["Shukuchi"] = safe("ShukuchiHit"), ["Duelist"] = safe("DuelistHit"), ["woah"] = safe("woahHit"), ["Ice"] = safe("IceHit"),
    ["Adios"] = safe("hitAdios"), ["Engineer"] = safe("engiehit"), ["Rocky"] = safe("RockyHit"), ["Conveyor"] = safe("ConvHit"),
    ["STOP"] = safe("STOP"), ["Phantom"] = safe("PhantomHit"), ["Wormhole"] = safe("WormHit"), ["Acrobat"] = safe("AcHit"),
    ["Plague"] = safe("PlagueHit"), ["[REDACTED]"] = safe("ReHit"), ["Warp"] = safe("WarpHt"), ["Bubble"] = safe("BubbleHit"),
    ["Jet"] = safe("JetHit"), ["potato"] = safe("potatohit"), ["bob"] = safe("bobhit"), ["Spy"] = safe("SpyHit"),
    ["Detonator"] = safe("DetonatorHit"), ["Rage"] = safe("GRRRR"), ["Trap"] = safe("traphi"), ["Orbit"] = safe("Orbihit"),
    ["Slapple"] = safe("SlappleHit"), ["Disarm"] = safe("DisarmH"), ["Dominance"] = safe("DominanceHit"), ["Link"] = safe("LinkHit"),
    ["Rojo"] = safe("RojoHit"), ["rob"] = safe("robhit"), ["Rhythm"] = safe("rhythmhit"), ["Nightmare"] = safe("nightmarehit"),
    ["Hitman"] = safe("HitmanHit"), ["Thor"] = safe("ThorHit"), ["Retro"] = safe("RetroHit"), ["Cloud"] = safe("CloudHit"),
    ["spin"] = safe("spinhit"), ["Pylon"] = safe("PylonHit"), ["Diamond"] = safe("DiamondHit"), ["Megarock"] = safe("DiamondHit"),
    ["Moon"] = safe("CelestialHit"), ["Jupiter"] = safe("CelestialHit"), ["Mitten"] = safe("MittenHit"), ["Hallow Jack"] = safe("HallowHIT"),
    ["OVERKILL"] = safe("Overkillhit"), ["God's Hand"] = safe("Godshand"), ["Kinetic"] = safe("HtStun"),
}
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
        local lc = cur:lower()
        if lc == "stalker" then hit:FireServer(obj, false, 45)
        elseif lc == "glovel" or lc == "mutation" then hit:FireServer(obj, true)
        elseif lc == "mace" then hit:FireServer(obj, 100)
        else hit:FireServer(obj) end
    end)
end

--==================================================================================--
-- 4. ANTI-CHEAT (bypass + namecall hook, expanded)
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
-- 5. UI LIBRARY
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
    local main = new("Frame", { Parent = gui, Size = opts.Size or UDim2.new(0,660,0,440), Position = UDim2.new(0.5,-330,0.5,-220), BackgroundColor3 = Color3.fromRGB(18,18,24), BorderSizePixel = 0 })
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
    local btn = new("TextButton", { Parent = self.Window.Sidebar, Size = UDim2.new(1,0,0,30), BackgroundColor3 = Color3.fromRGB(30,30,40), BackgroundTransparency = 1, BorderSizePixel = 0, Text = "", AutoButtonColor = false })
    new("UICorner", { CornerRadius = UDim.new(0,7), Parent = btn })
    local ind = new("Frame", { Parent = btn, Size = UDim2.new(0,3,0.6,0), Position = UDim2.new(0,0,0.2,0), BackgroundColor3 = self.Accent, BorderSizePixel = 0 })
    new("UICorner", { CornerRadius = UDim.new(0,3), Parent = ind })
    new("TextLabel", { Parent = btn, Size = UDim2.new(1,-16,1,0), Position = UDim2.new(0,14,0,0), BackgroundTransparency = 1, Text = name, Font = Enum.Font.GothamMedium, TextSize = 12, TextColor3 = Color3.fromRGB(170,170,185), TextXAlignment = Enum.TextXAlignment.Left })
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
        inst.Size = UDim2.new(1,-20,0,h); inst.Position = UDim2.new(0,10,0,sec.Cursor); inst.Parent = frame
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
    local l = new("TextLabel", { BackgroundTransparency = 1, Text = text, Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = Color3.fromRGB(180,180,195), TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true })
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
    local list = new("Frame", { Parent = sec.Frame, Size = UDim2.new(1,-20,0,math.min(#values,8)*26+8), Position = UDim2.new(0,10,0,rowTop + 52), BackgroundColor3 = Color3.fromRGB(28,28,38), BorderSizePixel = 0, Visible = false, ZIndex = 50 })
    new("UICorner", { CornerRadius = UDim.new(0,7), Parent = list })
    local scroll = new("ScrollingFrame", { Parent = list, Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1, ScrollBarThickness = 3, CanvasSize = UDim2.new(0,0,0,#values*26+8) })
    local ly = 4
    for _, v in ipairs(values) do
        local opt = new("TextButton", { Parent = scroll, Size = UDim2.new(1,-8,0,24), Position = UDim2.new(0,4,0,ly), BackgroundColor3 = Color3.fromRGB(34,34,46), BorderSizePixel = 0, Text = "", AutoButtonColor = false, ZIndex = 51 })
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
-- 6. BUILD + FEATURES
--==================================================================================--
local UI
local ok, err = xpcall(function()
    UI = Ven:CreateWindow({ Title = "Venice Hub v2  •  Slap Battles", Size = UDim2.new(0,680,0,460) })
    getgenv().VeniceUI = UI
    local Tabs = { Info=UI:Tab("Info"), Combat=UI:Tab("Combat"), Anti=UI:Tab("Anti"), Protect=UI:Tab("Protect"),
        Local=UI:Tab("Local"), Farm=UI:Tab("Farm"), Mastery=UI:Tab("Mastery"), Badges=UI:Tab("Badges"),
        Gloves=UI:Tab("Gloves"), Misc=UI:Tab("Misc"), Settings=UI:Tab("Settings") }

    -- generic anti-loop helper
    local function LoopToggle(sec, name, default, fn, key)
        local tog
        tog = UI:Toggle(sec, name, default, function(v)
            if v then task.spawn(function() while tog:Get() do pcall(fn); task.wait() end end) end
        end)
        if key then UI:KeyPicker(tog, key) end
        return tog
    end

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

        local hb = UI:Section(Tabs.Combat, "Hitbox / Extend")
        UI:Slider(hb, "Hitbox Reach", 4, 30, 10, function(v) getgenv().HitboxReach = v end)
        LoopToggle(hb, "Hitbox Player", false, function()
            for _, v in ipairs(Players:GetPlayers()) do
                if v ~= LocalPlayer and v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
                    v.Character.HumanoidRootPart.Size = Vector3.new(getgenv().HitboxReach, getgenv().HitboxReach, getgenv().HitboxReach)
                    v.Character.HumanoidRootPart.Transparency = 0.75
                end
            end
        end, "Z")
        UI:Slider(hb, "Extend Reach", 2, 20, 5, function(v) getgenv().ExtendReach = v end)
        UI:Dropdown(hb, "Extend Mode", {"Growth","Meat Stick","Pancake","Wall","Slight"}, false, "Growth", function(v) getgenv().ExtendMode = v end)
        LoopToggle(hb, "Extend Glove", false, function()
            local r = getgenv().ExtendReach
            local mode = getgenv().ExtendMode
            local target = mode == "Meat Stick" and Vector3.new(0,r,2) or mode == "Pancake" and Vector3.new(0,r,r) or mode == "Wall" and Vector3.new(r,0,r) or mode == "Slight" and Vector3.new(r,r,r+0.7) or Vector3.new(r,r,r)
            for _, container in ipairs({LocalPlayer.Character, LocalPlayer.Backpack}) do
                for _, t in ipairs(container:GetChildren()) do
                    if t:IsA("Tool") and t:FindFirstChild("Glove") then t.Glove.Size = target end
                end
            end
        end)

        local ab = UI:Section(Tabs.Combat, "Aimbot")
        UI:Toggle(ab, "Aimbot (camera)", false, function(v) getgenv().Aimbot = v end)
        UI:Slider(ab, "Prediction", 0, 10, 2, function(v) getgenv().AimbotPred = v end)
        hook(RunService.Heartbeat:Connect(function()
            if not getgenv().Aimbot then return end
            local _, tr = TargetPlayers(true)
            if tr then workspace.CurrentCamera.CFrame = CFrame.lookAt(workspace.CurrentCamera.CFrame.Position, tr.Position + tr.Velocity * (getgenv().AimbotPred or 0)) end
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

    do -- ANTI (huge protection suite ported from Articles-Hub)
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
    end

    do -- PROTECT (the merged protection suite)
        local A = Tabs.Protect
        local g1 = UI:Section(A, "Anti Void / Movement")
        UI:Dropdown(g1, "Anti Void Mode", {"Normal","Retro","Water","Psycho","Bob","Fall"}, false, "Normal", function(v) getgenv().AntiVoidChoose = v end)
        LoopToggle(g1, "Anti Void", false, function()
            local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if hrp and hrp.Position.Y < -30 then
                if getgenv().AntiVoidChoose == "Fall" then
                    hrp.CFrame = (workspace:FindFirstChild("Origo") and workspace.Origo.CFrame * CFrame.new(0,-5,0)) or hrp.CFrame
                else
                    local sb = workspace:FindFirstChild("SafeBox"); if sb then hrp.CFrame = sb.CFrame * CFrame.new(0,5,0) end
                end
            end
            for _, v in ipairs(workspace:GetChildren()) do
                if v.Name == "BobWalk1" and v:IsA("BasePart") then v.CanCollide = getgenv().AntiVoidChoose == "Bob" end
                if v.Name == "Psycho" and v:IsA("BasePart") then v.CanCollide = getgenv().AntiVoidChoose == "Psycho" end
                if v.Name == "VoidPart" then v.CanCollide = getgenv().AntiVoidChoose == "Normal" end
            end
        end)
        LoopToggle(g1, "Anti Ragdoll", false, function()
            local c = LocalPlayer.Character; local r = c and c:FindFirstChild("Ragdolled")
            if r and r.Value then
                for _, v in ipairs(c:GetDescendants()) do
                    if v:IsA("BallSocketConstraint") or v:IsA("HingeConstraint") then v.Enabled = false
                    elseif v:IsA("Motor6D") then v.Enabled = true end
                end
                local h = c:FindFirstChildOfClass("Humanoid"); if h then h:ChangeState(Enum.HumanoidStateType.Running) end
            end
        end)
        LoopToggle(g1, "Anti Time Stop", false, function()
            local c = LocalPlayer.Character; if not c then return end
            for _, v in ipairs(c:GetChildren()) do if v.ClassName == "Part" then v.Anchored = false end end
        end)
        LoopToggle(g1, "Anti Stun", false, function()
            local c = LocalPlayer.Character
            if c and c:FindFirstChild("Humanoid") and workspace:FindFirstChild("Shockwave") and c.Ragdolled.Value == false then c.Humanoid.PlatformStand = false end
        end)

        local g2 = UI:Section(A, "Anti Hazards")
        LoopToggle(g2, "Anti Portal", function()
            local l = workspace:FindFirstChild("Lobby"); if l then for _, n in ipairs({"Teleport2","Teleport3","Teleport4","Teleport6"}) do local p = l:FindFirstChild(n); if p then p.CanTouch = false end end end
        end)
        LoopToggle(g2, "Anti COD", function()
            local cod = workspace:FindFirstChild("the cube of death(i heard it kills)", true); if cod then cod.CanTouch = false; local pt = cod:FindFirstChild("Part"); if pt then pt.CanTouch = false end end
        end)
        LoopToggle(g2, "Anti Snowball", function() for _, v in ipairs(workspace:GetChildren()) do if v.Name == "Snowball" then v:Destroy() end end end)
        LoopToggle(g2, "Anti Trap", function() for _, v in ipairs(workspace:GetChildren()) do if v.Name == "BearTrap" then local h = v:FindFirstChild("HitBox"); if h then h.CanTouch = false end end end end)
        LoopToggle(g2, "Anti Lava/Obby", function() for _, v in ipairs(workspace:GetChildren()) do if string.find(v.Name, "Lava") then v.CanTouch = false end end end)
        LoopToggle(g2, "Anti Megarock", function() for _, v in ipairs(Players:GetPlayers()) do if v.Character and v.Character:FindFirstChild("rock") then v.Character.rock.CanTouch = false; v.Character.rock.CanQuery = false end end end)
        LoopToggle(g2, "Anti Cherry", function()
            if workspace:FindFirstChild("cherry_storage") then
                for _, v in ipairs(workspace.cherry_storage:GetChildren()) do
                    if not v.Name:match(LocalPlayer.Name) and v:FindFirstChild("clone_remote") and v:FindFirstChild("HumanoidRootPart") then slapglove(v.HumanoidRootPart) end
                end
            end
        end)
        LoopToggle(g2, "Anti Ball Baller", function() for _, v in ipairs(workspace:GetChildren()) do if v.Name == "ClonedBall" then v:Destroy() end end end)
        LoopToggle(g2, "Anti Ice (is_ice)", function() for _, v in ipairs(workspace:GetChildren()) do if v.Name == "is_ice" then v.CanTouch = false end end end)
        LoopToggle(g2, "Anti Icecube", function()
            local c = LocalPlayer.Character; if not c then return end
            for _, v in ipairs(c:GetChildren()) do
                if v.Name == "Icecube" then v:Destroy(); if c:FindFirstChild("Humanoid") then c.Humanoid.PlatformStand = false; c.Humanoid.AutoRotate = true end end
            end
        end)
        LoopToggle(g2, "Anti Paint Splash", function() for _, v in ipairs(workspace:GetChildren()) do if string.find(v.Name:lower(), "paint") then v.CanTouch = false; v.CanQuery = false end end end)
        LoopToggle(g2, "Anti Lure", function()
            local lure; local c = LocalPlayer.Character; if not c then return end
            for _, v in ipairs(c:GetChildren()) do if v.Name:lower():find("lure") then lure = v end end
            for _, v in ipairs(workspace:GetChildren()) do
                if string.find(v.Name, "_lure") and v:FindFirstChild("Root") and v:FindFirstChild("watercircle") and lure then
                    local old = c.HumanoidRootPart.CFrame
                    c.HumanoidRootPart.CFrame = v.Root.CFrame; task.wait(0.3)
                    c.HumanoidRootPart.CFrame = old
                end
            end
        end)
        LoopToggle(g2, "Anti Water", function() if workspace:FindFirstChild("puddles") then for _, v in ipairs(workspace.puddles:GetChildren()) do if v.Name == "puddle" then v.CanTouch = false end end end end)
        LoopToggle(g2, "Anti Jail", function() for _, v in ipairs(workspace:GetChildren()) do if v.Name == "jail" then for _, h in ipairs(v:GetChildren()) do if h:IsA("BasePart") then h.CanCollide = false end end end end end)
        LoopToggle(g2, "Anti Pie", function() if LocalPlayer.PlayerGui:FindFirstChild("PieSplash") then LocalPlayer.PlayerGui.PieSplash:Destroy() end end)
        LoopToggle(g2, "Anti Conveyor", function() local p = LocalPlayer.PlayerScripts:FindFirstChild("LegacyClient"); if p and p:FindFirstChild("ConveyorVictimized") then p.ConveyorVictimized.Disabled = true end end)
        LoopToggle(g2, "Anti Mitten Blind", function() if LocalPlayer.PlayerGui:FindFirstChild("MittenBlind") then LocalPlayer.PlayerGui.MittenBlind:Destroy() end end)
        LoopToggle(g2, "Anti Squid Ink", function() if LocalPlayer.PlayerGui:FindFirstChild("SquidInk") then LocalPlayer.PlayerGui.SquidInk.Enabled = false end end)
        LoopToggle(g2, "Anti Lamp Blind", function()
            for _, v in ipairs(LocalPlayer.PlayerGui:GetChildren()) do if v.Name:find("whiteframe") then v.Enabled = false end end
            for _, v in ipairs(Lighting:GetChildren()) do if v.Name:find("lampcc") then v.Enabled = false end end
        end)
        LoopToggle(g2, "Anti Boss Guide", function() if workspace:FindFirstChild("BountyHunterRoom") then for _, v in ipairs(workspace.BountyHunterRoom.Build:GetChildren()) do if v.Name == "Model" and v:FindFirstChild("Meshes/boxshadow_Cube.005") and v["Meshes/boxshadow_Cube.005"]:FindFirstChild("Hitbox") then v["Meshes/boxshadow_Cube.005"].Hitbox.CanTouch = false end end end end)
        LoopToggle(g2, "Anti Death Barrier", function()
            for _, n in ipairs({"DEATHBARRIER","DEATHBARRIER2","dedBarrier","ArenaBarrier","AntiDefaultArena"}) do
                local b = workspace:FindFirstChild(n); if b then b.CanTouch = false end
            end
        end)
        LoopToggle(g2, "Anti Mouse Trap", function() for _, v in ipairs(workspace:GetChildren()) do if v.Name:lower() == "mouse trap" and v:FindFirstChild("Hitbox") then v.Hitbox.CanTouch = false end end end)
        LoopToggle(g2, "Anti Fort Wall", function() for _, v in ipairs(workspace:GetChildren()) do if v.Name == "Part" and v:FindFirstChild("brownsmoke") and v:FindFirstChild("Sound") then v.CanCollide = false end end end)
        LoopToggle(g2, "Anti Pusher Wall", function() for _, v in ipairs(workspace:GetChildren()) do if v.Name == "wall" then v.CanCollide = false end end end)
        LoopToggle(g2, "Anti Defend Barrier", function() for _, v in ipairs(workspace:GetChildren()) do if string.find(v.Name, "ÅBarrier") then v.CanCollide = false end end end)
        LoopToggle(g2, "Anti Bubble", function() for _, v in ipairs(workspace:GetChildren()) do if v.Name == "BubbleObject" and v:FindFirstChildOfClass("Weld") then v:FindFirstChildOfClass("Weld"):Destroy() end end end)
        LoopToggle(g2, "Anti Pylon", function() for _, v in ipairs(workspace:GetChildren()) do if v.Name == "Pylon" and v:FindFirstChild("OwningPlayer") and v.OwningPlayer.Value ~= LocalPlayer.Name and v:FindFirstChild("Hitbox") then v.Hitbox:Destroy() end end end)
        LoopToggle(g2, "Anti Pile", function() for _, v in ipairs(workspace:GetChildren()) do if v.Name:find("Pile") and v.CanTouch then v.CanTouch = false end end end)
        LoopToggle(g2, "Anti Iceskate", function() if workspace:FindFirstChild("IceBin") then for _, v in ipairs(workspace.IceBin:GetChildren()) do if v:IsA("BasePart") then v:Destroy() end end end end)
        LoopToggle(g2, "Anti Za Hando", function() for _, v in ipairs(workspace:GetChildren()) do if v.Name == "Part" and not (v:FindFirstChild("brownsmoke") and v:FindFirstChild("Sound")) then v:Destroy() end end end)
        LoopToggle(g2, "Anti Brazil", function() local b = workspace.Lobby:FindFirstChild("brazil"); if b then for _, v in ipairs(b:GetChildren()) do if v:IsA("BasePart") then v.CanTouch = false end end end end)
        LoopToggle(g2, "Anti Booster", function() local c = LocalPlayer.Character; if not c then return end; for _, v in ipairs(c:GetDescendants()) do if v.Name == "BoosterObject" then v:Destroy() end end end)
        LoopToggle(g2, "Anti Null Imp", function() for _, v in ipairs(workspace:GetChildren()) do if v.Name == "Imp" and v:FindFirstChild("Body") then slapglove(v.Body) end end end)
        LoopToggle(g2, "Anti Ghost Player", function() for _, v in ipairs(Players:GetChildren()) do if v ~= LocalPlayer and workspace:FindFirstChild(v.Name.."_Body") and workspace[v.Name.."_Body"]:FindFirstChild("Part") then slapglove(workspace[v.Name.."_Body"].Part) end end end)

        local g3 = UI:Section(A, "Safespots")
        UI:Dropdown(g3, "Teleport Safe", {"SafeBox","Safespot","Bed"}, false, "SafeBox", function(v)
            local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart"); if not hrp then return end
            if v == "SafeBox" and workspace:FindFirstChild("SafeBox") then hrp.CFrame = workspace.SafeBox.CFrame * CFrame.new(0,5,0)
            elseif v == "Safespot" and workspace:FindFirstChild("Safespot") then hrp.CFrame = workspace.Safespot.CFrame * CFrame.new(0,10,0)
            elseif v == "Bed" and workspace:FindFirstChild("Bed") then hrp.CFrame = workspace.Bed.Bed3.CFrame end
        end)
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
            end)
        end)
        UI:KeyPicker(ft, "R")
    end

    do -- FARM
        local s = UI:Section(Tabs.Farm, "Auto Farm Slap")
        UI:Dropdown(s, "Mode", {"Teleport","Tween"}, false, "Teleport", function(v) getgenv().FarmMode = v end)
        local farm = UI:Toggle(s, "Auto Farm Slap", false, function(v)
            getgenv().FarmSlap = v
            if v then task.spawn(function() while getgenv().FarmSlap do
                local char = LocalPlayer.Character; local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    if not char:FindFirstChild("entered") then
                        local tp = workspace:FindFirstChild("Lobby") and workspace.Lobby:FindFirstChild("Teleport1")
                        if tp then char:FindFirstChildOfClass("Humanoid"):MoveTo(tp.Position) end
                    else
                        local _, tr = TargetPlayers(true)
                        if tr then
                            if getgenv().FarmMode == "Teleport" then hrp.CFrame = tr.CFrame * CFrame.new(0,3,0); task.wait(0.1); slapglove(tr); task.wait(0.4)
                            else
                                CreateFreezeBV({ Name = "FarmTween" }); local bv = hrp:FindFirstChild("FarmTween")
                                if bv then local dir = (tr.Position + Vector3.new(0,4,0)) - hrp.Position; bv.Velocity = dir.Magnitude > 5 and dir.Unit * 90 or Vector3.zero; if dir.Magnitude <= 6 then slapglove(tr); task.wait(0.5) end end
                            end
                        end
                    end
                end
                task.wait(getgenv().FarmMode == "Teleport" and 0.1 or 0)
            end end) end
        end)
        UI:KeyPicker(farm, "F")

        local m = UI:Section(Tabs.Farm, "Auto Ability (expanded)")
        UI:Toggle(m, "Spam Ability", false, function(v)
            getgenv().SpamAbility = v
            if v then task.spawn(function() while getgenv().SpamAbility do
                local g = CheckGlove()
                pcall(function()
                    if g == "Fort" then ReplicatedStorage.Fortlol:FireServer()
                    elseif g == "bus" then ReplicatedStorage.busmoment:FireServer()
                    elseif g == "Replica" then ReplicatedStorage.Duplicate:FireServer(true)
                    elseif g == "Bomb" then ReplicatedStorage.BombThrow:FireServer()
                    elseif g == "Shard" then ReplicatedStorage.Shards:FireServer()
                    elseif g == "Bubble" then ReplicatedStorage.BubbleThrow:FireServer()
                    elseif g == "Phase" then ReplicatedStorage.PhaseA:FireServer()
                    elseif g == "Pusher" then ReplicatedStorage.PusherWall:FireServer()
                    elseif g == "Null" then ReplicatedStorage.NullAbility:FireServer()
                    elseif g == "rob" then ReplicatedStorage.rob:FireServer()
                    elseif g == "Brick" then ReplicatedStorage.lbrick:FireServer()
                    elseif g == "BONK" then ReplicatedStorage.BONK:FireServer()
                    elseif g == "Tableflip" then ReplicatedStorage.GeneralAbility:FireServer()
                    elseif g == "Shield" then ReplicatedStorage.GeneralAbility:FireServer()
                    elseif g == "STOP" then ReplicatedStorage.STOP:FireServer(true)
                    elseif g == "Mail" then ReplicatedStorage.MailSend:FireServer()
                    elseif g == "Gravity" then ReplicatedStorage.GeneralAbility:FireServer()
                    elseif g == "Lamp" then ReplicatedStorage.GeneralAbility:FireServer()
                    elseif g == "Meteor" then ReplicatedStorage.GeneralAbility:FireServer()
                    elseif g == "Whirlwind" then ReplicatedStorage.GeneralAbility:FireServer()
                    elseif g == "Parry" then ReplicatedStorage.GeneralAbility:FireServer() end
                end)
                task.wait(0.1)
            end end) end
        end)
    end

    do -- MASTERY (ported engine + toggles)
        local function MasteryPlayers(glove, ghost)
            local char = LocalPlayer.Character
            if not char or not char:FindFirstChild("HumanoidRootPart") then return end
            local function enter(tp)
                if not char then return end
                if not char:FindFirstChild("entered") then
                    local portal = workspace.Lobby[tp].TouchInterest.Parent
                    repeat task.wait()
                        if firetouchinterest then firetouchinterest(char.Head, portal, 0); firetouchinterest(char.Head, portal, 1)
                        else char.HumanoidRootPart.CFrame = portal.CFrame end
                    until char:FindFirstChild("entered")
                end
            end
            char.HumanoidRootPart.CFrame = workspace["SafeBox"].CFrame * CFrame.new(0,5,0); task.wait(0.4)
            if ghost and char:FindFirstChild("entered") == nil and CheckSlap() >= 666 then
                equipglove("Ghost"); repeat task.wait() until CheckGlove():lower() == "ghost"
                ReplicatedStorage.Ghostinvisibilityactivated:FireServer(); equipglove(glove); task.wait(1)
                for _, v in ipairs(char:GetChildren()) do if v:IsA("BasePart") and v.Name ~= "HumanoidRootPart" then v.Transparency = 0 end end
            end
            enter("Teleport1"); task.wait(0.35)
            char.HumanoidRootPart.CFrame = workspace["SafeBox"].CFrame * CFrame.new(0,5,0); task.wait(0.3)
            if char:FindFirstChild("entered") then
                local pl = {}
                for _, v in ipairs(Players:GetPlayers()) do
                    if v ~= LocalPlayer and v.Character and v.Character:FindFirstChild("HumanoidRootPart") and v.Character.HumanoidRootPart.BrickColor ~= BrickColor.new("New Yeller") and v.Character:FindFirstChild("Ragdolled") and not v.Character.HumanoidRootPart:FindFirstChild("BlockedShield") and v.Character.Ragdolled.Value == false and v.Character.isInArena.Value == true and notSlap(v.Character, CONFIG.BlackList) then table.insert(pl, v) end
                end
                if #pl ~= 0 then return pl[math.random(#pl)] end
            end
        end
        local function MasteryLoop(gloveName, sec, name, fn)
            local tog
            tog = UI:Toggle(sec, name, false, function(v)
                if CheckGlove() ~= gloveName then Notify("You don't have "..gloveName.." equipped"); if v then task.wait(0.05); tog:Set(false) end; return end
                if v then task.spawn(function() while tog:Get() do pcall(fn); task.wait() end end) end
            end)
            return tog
        end

        local s = UI:Section(Tabs.Mastery, "Mastery Helpers")
        UI:Label(s, "Auto-farms mastery challenges for equipped glove.")
        local common = UI:Section(Tabs.Mastery, "Common Gloves")
        MasteryLoop("Replica", common, "Auto Replica Mastery", function()
            local p = MasteryPlayers("Replica", true); if p and p.Character then
                CreateFreezeBV()
                p.Character:SetPrimaryPartCFrame(p.Character:FindFirstChild("Head").CFrame * CFrame.new(0,7,0))
                task.wait(0.3)
                for _=1,3 do slapglove(p.Character:FindFirstChild("Head")); task.wait(0.2) end
                LocalPlayer.Character.HumanoidRootPart.CFrame = workspace.SafeBox.CFrame * CFrame.new(0,5,0); task.wait(4)
            end
        end)
        MasteryLoop("Acrobat", common, "Auto Acrobat Mastery", function()
            local p = MasteryPlayers("Acrobat", true); if p and p.Character then
                CreateFreezeBV()
                ReplicatedStorage.Roll:FireServer(); task.wait(0.6)
                p.Character:SetPrimaryPartCFrame(p.Character:FindFirstChild("Head").CFrame * CFrame.new(0,7,0))
                task.wait(0.3)
                for _=1,3 do slapglove(p.Character:FindFirstChild("Head")); task.wait(0.2) end
                LocalPlayer.Character.HumanoidRootPart.CFrame = workspace.SafeBox.CFrame * CFrame.new(0,5,0); task.wait(4)
            end
        end)
        MasteryLoop("Spring", common, "Auto Spring Mastery", function()
            local p = MasteryPlayers("Spring", true); if p and p.Character then
                CreateFreezeBV()
                ReplicatedStorage.SpringJump:FireServer(); task.wait(1.4)
                p.Character:SetPrimaryPartCFrame(p.Character:FindFirstChild("Head").CFrame * CFrame.new(0,7,0))
                task.wait(0.3)
                for _=1,3 do slapglove(p.Character:FindFirstChild("Head")); task.wait(0.2) end
                LocalPlayer.Character.HumanoidRootPart.CFrame = workspace.SafeBox.CFrame * CFrame.new(0,5,0); task.wait(4.6)
            end
        end)
        MasteryLoop("Stalker", common, "Auto Stalker Mastery", function()
            local p = MasteryPlayers("Stalker", true); if p and p.Character then
                CreateFreezeBV()
                p.Character:SetPrimaryPartCFrame(p.Character:FindFirstChild("Head").CFrame * CFrame.new(0,7,0))
                task.wait(0.3)
                for _=1,3 do slapglove(p.Character:FindFirstChild("Head")); task.wait(0.2) end
                LocalPlayer.Character.HumanoidRootPart.CFrame = workspace.SafeBox.CFrame * CFrame.new(0,5,0); task.wait(4)
            end
        end)
        MasteryLoop("bob", common, "Auto Bob Farm", function()
            local char = LocalPlayer.Character; if not char then return end
            if not char:FindFirstChild("entered") then char.Humanoid:MoveTo(workspace.Lobby.Teleport1.Position)
            else
                CreateFreezeBV(); task.wait(0.2)
                ReplicatedStorage.Duplicate:FireServer(true); task.wait(0.2)
                LocalPlayer:FindFirstChildOfClass("PlayerGui"); Player.Reset:FireServer()
                repeat task.wait() until LocalPlayer.Character and not LocalPlayer.Character:FindFirstChild("entered"); task.wait(0.5)
            end
        end)
        MasteryLoop("Killstreak", common, "Auto Killstreak Mastery", function()
            local p = MasteryPlayers("Killstreak", true); if p and p.Character then
                CreateFreezeBV()
                p.Character:SetPrimaryPartCFrame(p.Character:FindFirstChild("Head").CFrame * CFrame.new(0,7,0))
                task.wait(0.3)
                for _=1,3 do slapglove(p.Character:FindFirstChild("Head")); task.wait(0.2) end
                LocalPlayer.Character.HumanoidRootPart.CFrame = workspace.SafeBox.CFrame * CFrame.new(0,5,0); task.wait(4)
            end
        end)
        MasteryLoop("Brick", common, "Auto Big Brick", function()
            for _, v in ipairs(workspace:GetChildren()) do if v.Name == "Union" then v.Size = Vector3.new(20,1,20) end end
        end)
        MasteryLoop("Phase", common, "Auto Phase Mastery", function()
            local p = MasteryPlayers("Phase", true); if p and p.Character then
                CreateFreezeBV()
                p.Character:SetPrimaryPartCFrame(p.Character:FindFirstChild("HumanoidRootPart").CFrame)
                task.wait(0.3)
                slapglove(p.Character:FindFirstChild("Head"))
                ReplicatedStorage.PhaseA:FireServer()
                LocalPlayer.Character.HumanoidRootPart.CFrame = workspace.SafeBox.CFrame * CFrame.new(0,5,0); task.wait(3)
            end
        end)
        MasteryLoop("Shard", common, "Auto Shard Mastery", function()
            local p = MasteryPlayers("Shard", true); if p and p.Character then
                CreateFreezeBV()
                p.Character:SetPrimaryPartCFrame(p.Character:FindFirstChild("Head").CFrame * CFrame.new(0,7,0))
                task.wait(0.3)
                slapglove(p.Character:FindFirstChild("Head"))
                LocalPlayer.Character.HumanoidRootPart.CFrame = workspace.SafeBox.CFrame * CFrame.new(0,5,0); task.wait(4)
            end
        end)
        MasteryLoop("Null", common, "Auto Null Mastery", function()
            if workspace:FindFirstChild("Imp") and workspace.Imp:FindFirstChild("Body") then slapglove(workspace.Imp.Body) end
        end)
        MasteryLoop("Bomb", common, "Auto Bomb Mastery", function()
            for _=1,500 do ReplicatedStorage.BombThrow:FireServer("Ebutton") end
        end)
        MasteryLoop("Glovel", common, "Auto Glovel Dip", function()
            LocalPlayer.Character.HumanoidRootPart.CFrame = workspace.SafeBox.CFrame * CFrame.new(0,5,0); task.wait(0.3)
            for _=1,400 do task.spawn(function() ReplicatedStorage.GlovelFunc:InvokeServer() end); task.wait(0.05) end
            task.wait(0.4); ReplicatedStorage.GlovelCancel:FireServer(); task.wait(0.8)
        end)
        MasteryLoop("Fort", common, "Auto Fort Build", function()
            if LocalPlayer.Character:FindFirstChild("entered") then ReplicatedStorage.Fortlol:FireServer() end
            task.wait(3.4)
        end)
        MasteryLoop("Rage", common, "Auto Rage Mastery", function()
            local p = MasteryPlayers("Rage", true); if p and p.Character then
                CreateFreezeBV()
                for _=1,20 do slapglove(p.Character:FindFirstChild("HumanoidRootPart")); task.wait() end
                if (LocalPlayer.Character:GetAttribute("rage_percent") or 0) >= 53 then ReplicatedStorage.GRRRRR:FireServer("frenzy") end
                task.wait(2)
            end
        end)
        MasteryLoop("Rob", common, "Auto Rob Mastery", function()
            if LocalPlayer.Character:FindFirstChild("entered") then ReplicatedStorage.rob:FireServer() end
            task.wait(3)
        end)
    end

    do -- BADGES
        local s = UI:Section(Tabs.Badges, "Quick Badges")
        UI:Button(s, "Get Duck + Orange + Knife", function() pcall(function()
            fireclickdetector(workspace.Lobby.Scene.knofe.ClickDetector)
            fireclickdetector(workspace.Arena.island5.Orange.ClickDetector)
            fireclickdetector(workspace.Arena["default island"]["Rubber Ducky"].ClickDetector)
        end) end)
        UI:Button(s, "Get Free Ice Skate", function() pcall(function() ReplicatedStorage.IceSkate:FireServer("Freeze") end) end)
        UI:Button(s, "Get Free Lamp (ZZZZZZZ)", function() for _=1,5 do pcall(function() ReplicatedStorage.nightmare:FireServer("LightBroken") end) end end)
        UI:Button(s, "Get Answer Recall", function()
            local rm = workspace:FindFirstChild("RepressedMemories"); local npc = rm and rm:FindFirstChild("RepressedMemoriesNPC"); local head = npc and npc:FindFirstChild("Head"); local dialog = head and head:FindFirstChild("Dialog")
            if dialog then
                for _, v in ipairs(dialog:GetDescendants()) do
                    if v:IsA("DialogChoice") then
                        if v:FindFirstChild("RightChoice") then v.UserDialog = "Uhhh, idk" end
                        if v:FindFirstChild("FailChoice") then v:Destroy() end
                    end
                end
            else Notify("Enter Limbo first") end
        end)
        UI:Button(s, "Get Join Retro", function()
            if CheckGlove() == "Retro" and workspace.Arena:FindFirstChild("CannonIsland") then
                for _, v in ipairs(workspace.Arena.CannonIsland:FindFirstChild("Cannon Island [OLD]"):GetChildren()) do
                    if v.Name == "Model" and v:FindFirstChild("Towers") then
                        repeat task.wait()
                            if v.Towers:FindFirstChild("RevealHitbox") then LocalPlayer.Character.HumanoidRootPart.CFrame = v.Towers.RevealHitbox.CFrame * CFrame.new(3,0,0) end
                            pcall(function() ReplicatedStorage.RetroAbility:FireServer("Ban Hammer") end)
                        until v.Towers:FindFirstChild("Ring of Fire")
                        LocalPlayer.Character.HumanoidRootPart.CFrame = v.Towers["Ring of Fire"].CFrame
                    end
                end
            else Notify("Equip Retro") end
        end)
    end

    do -- GLOVES
        local s = UI:Section(Tabs.Gloves, "Utility")
        UI:Input(s, "Player", "", function(v) getgenv().PlayerSel = FoundPlr(v, true) end)
        UI:Button(s, "Teleport To Player", function()
            local p = getgenv().PlayerSel
            if p and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character then LocalPlayer.Character.HumanoidRootPart.CFrame = p.Character.HumanoidRootPart.CFrame end
        end)
        UI:Dropdown(s, "Equip Glove", {"Default","Extended","Brick","Snow","Fort","Bomb","Replica","Phase","Shard","Bubble","Pusher","Null","bus","Ghost","Stun","Rob","Rage","Killstreak"}, false, nil, function(v) equipglove(v) end)

        local g = UI:Section(Tabs.Gloves, "Instant Glove Actions")
        UI:Button(g, "Infinite Invisibility", function()
            if not LocalPlayer.Character:FindFirstChild("entered") and CheckSlap() >= 666 then
                local og = CheckGlove()
                fireclickdetector(workspace.Lobby.Ghost.ClickDetector); ReplicatedStorage.Ghostinvisibilityactivated:FireServer()
                fireclickdetector(workspace.Lobby[og].ClickDetector); task.wait(1)
                for _, v in ipairs(LocalPlayer.Character:GetChildren()) do if v:IsA("BasePart") and v.Name ~= "HumanoidRootPart" then v.Transparency = 0 end end
            else Notify("Need lobby + 666 slaps") end
        end)
        UI:Button(g, "Auto Win Kraken", function()
            if workspace:FindFirstChild("Abyss") then
                repeat task.wait()
                    if workspace.Abyss:FindFirstChild("Ship") and workspace.Abyss.Ship:FindFirstChild("Ghost_Ship") and workspace.Abyss.Ship.Ghost_Ship:FindFirstChild("Wall") then
                        LocalPlayer.Character.HumanoidRootPart.CFrame = workspace.Abyss.Ship.Ghost_Ship.Wall.CFrame * CFrame.new(0,10,0)
                    else break end
                    for _, v in ipairs(workspace:GetChildren()) do if v.Name == "kraken_hurtbox" then v.CFrame = LocalPlayer.Character.HumanoidRootPart.CFrame end end
                until workspace:FindFirstChild("Abyss") == nil
            else Notify("Enter Abyss map first") end
        end)
    end

    do -- MISC
        local s = UI:Section(Tabs.Misc, "Glove Cosmetics")
        LoopToggle(s, "Big Glove", false, function()
            local c = LocalPlayer.Character; if not c then return end
            local t = c:FindFirstChildOfClass("Tool"); if t and t:FindFirstChild("Glove") then t.Glove.Size = Vector3.new(8,8,8); t.Glove.Transparency = 0.3 end
        end)
        local e = UI:Section(Tabs.Misc, "ESP")
        UI:Toggle(e, "Player ESP", false, function(v)
            getgenv().ESP = v
            if not v then for _, p in ipairs(Players:GetPlayers()) do if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Head") then local h = p.Character.Head:FindFirstChild("VeniceESP"); if h then h:Destroy() end end end end
        end)
        hook(RunService.Heartbeat:Connect(function()
            if not getgenv().ESP then return end
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Head") then
                    local head = p.Character.Head; local bb = head:FindFirstChild("VeniceESP")
                    if not bb then
                        bb = new("BillboardGui", { Name = "VeniceESP", Parent = head, Size = UDim2.new(0,100,0,30), StudsOffset = Vector3.new(0,3,0), AlwaysOnTop = true })
                        new("TextLabel", { Parent = bb, Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1, Text = "", TextColor3 = Color3.new(1,1,1), Font = Enum.Font.GothamBold, TextSize = 13, TextStrokeTransparency = 0.3 })
                    end
                    local ls = p:FindFirstChild("leaderstats"); local hum = p.Character:FindFirstChildOfClass("Humanoid")
                    bb.TextLabel.Text = (ls and ls:FindFirstChild("Glove") and ls.Glove.Value or "?") .. " | " .. math.floor(hum and hum.Health or 0)
                end
            end
        end))
    end

    do -- SETTINGS
        local s = UI:Section(Tabs.Settings, "UI")
        UI:Slider(s, "Notify Duration", 1, 15, 5, function(v) CONFIG.TimeNotify = v end)
        UI:Button(s, "Unload", function() if getgenv().VeniceUnload then getgenv().VeniceUnload() end end)
    end
end, function(e) return tostring(e) .. "\n" .. debug.traceback() end)
if not ok then warn("[Venice Hub] BUILD ERROR: " .. tostring(err)) end

--==================================================================================--
-- 7. UNLOAD + PERSIST
--==================================================================================--
getgenv().VeniceUnload = function()
    getgenv().VeniceHubLoaded = false
    for _, c in ipairs(Connections) do pcall(function() c:Disconnect() end) end
    Connections = {}
    if getgenv().VeniceHook then pcall(function() hookmetamethod(game, "__namecall", getgenv().VeniceHook) end) end
    if UI and UI.Window and UI.Window.Gui then pcall(function() UI.Window.Gui:Destroy() end) end
    print("[Venice Hub] Unloaded.")
end
hook(LocalPlayer.OnTeleport:Connect(function()
    if not getgenv().VeniceHubLoaded then return end
    local q = queueonteleport or queue_on_teleport
    if q then q([[if not game:IsLoaded() then game.Loaded:Wait() end
repeat task.wait() until game.Players.LocalPlayer
loadstring(game:HttpGet("https://raw.githubusercontent.com/helloCCPD/Slap-Battles-Script/main/SlapBattlesScript.lua"))()]]) end
end))
Notify("Venice Hub v2 loaded" .. (bypassOK and " • bypass OK" or ""))
print("[Venice Hub] Ready • PlaceId " .. game.PlaceId)
