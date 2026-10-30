--[[
    NOOB WARFARE // 4080
    Mobile-first Roblox executor suite for "Noob Warfare" (PlaceId 5890235330)
    Executor requirements: Drawing, hookfunction/hookmetamethod, gethui
    Tested API surface: sUNC-style executor (Delta, Arceus X, Fluxus, similar)
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local unpackFn = table.unpack or unpack

local GAME = {
    Name = "Noob Warfare",
    PlaceId = 5890235330,
    UniverseId = 2107154564,
}

local function clamp(value, minValue, maxValue)
    if value < minValue then return minValue end
    if value > maxValue then return maxValue end
    return value
end

local function round(value, step)
    step = step or 1
    if step <= 0 then return value end
    return math.floor(value / step + 0.5) * step
end

local function detectExecutor()
    local ok, name = pcall(function()
        if type(identifyexecutor) == "function" then
            return identifyexecutor()
        end
        if type(getexecutorname) == "function" then
            return getexecutorname()
        end
        if type(syn) == "table" then return "Synapse X" end
        if type(fluxus) == "table" then return "Fluxus" end
        if type(Krnl) == "table" then return "KRNL" end
        if type(secure_load) == "function" then return "Secure" end
        return "Unknown"
    end)
    if ok and type(name) == "string" then return name end
    return "Unknown"
end

local Cap = {
    Drawing = type(Drawing) == "table" and type(Drawing.new) == "function",
    HookFunction = type(hookfunction) == "function",
    HookMetamethod = type(hookmetamethod) == "function",
    RawMeta = type(getrawmetatable) == "function" and type(setreadonly) == "function",
    GetHui = type(gethui) == "function",
    Namecall = type(getnamecallmethod) == "function",
    NewCClosure = type(newcclosure) == "function",
}

local function wrapCallback(fn)
    if Cap.NewCClosure then
        local ok, wrapped = pcall(newcclosure, fn)
        if ok and type(wrapped) == "function" then return wrapped end
    end
    return fn
end

local function hookMetaMethod(object, method, callback)
    if Cap.HookMetamethod then
        local ok, old = pcall(hookmetamethod, object, method, callback)
        if ok and old ~= nil then return old end
    end
    if Cap.RawMeta then
        local ok, mt = pcall(getrawmetatable, object)
        if ok and mt then
            local old = mt[method]
            pcall(setreadonly, mt, false)
            local assigned = pcall(function() mt[method] = callback end)
            pcall(setreadonly, mt, true)
            if assigned then return old end
        end
    end
    return nil
end

local function defaultConfig()
    return {
        Aimbot = {
            Enabled = false,
            FOV = 140,
            Smoothness = 35,
            Speed = 12,
            Part = "Head",
            TeamCheck = true,
            MaxDistance = 500,
            VisibleOnly = true,
            Wallbang = false,
            Priority = "Crosshair",
        },
        Silent = {
            Enabled = false,
            FOV = 160,
            Part = "Head",
            TeamCheck = true,
            MaxDistance = 600,
            Wallbang = false,
            ShowTarget = true,
            MouseHook = false,
        },
        ESP = {
            Enabled = false,
            BoxStyle = "Corner",
            Fill = true,
            Outline = true,
            Name = true,
            Health = true,
            HealthText = false,
            Distance = true,
            Weapon = false,
            HeadDot = false,
            Skeleton = false,
            Tracers = false,
            TracerOrigin = "Bottom",
            Arrows = true,
            ArrowRadius = 200,
            Chams = false,
            ChamsFill = 55,
            VisibilityColors = true,
            TeamCheck = true,
            ShowAllies = true,
            MaxDistance = 1000,
            MaxTargets = 16,
            UpdateRate = 30,
            Opacity = 100,
            TextSize = 14,
            EnemyColor = Color3.fromRGB(255, 60, 60),
            EnemyColorName = "Red",
            VisibleColor = Color3.fromRGB(60, 255, 120),
            VisibleColorName = "Green",
            AllyColor = Color3.fromRGB(60, 160, 255),
            AllyColorName = "Blue",
            SkeletonThickness = 1.5,
        },
        Movement = {
            SpeedEnabled = false,
            Speed = 32,
            JumpEnabled = false,
            JumpPower = 80,
            FlyEnabled = false,
            FlySpeed = 60,
            Noclip = false,
            Wallshot = false,
            SpeedMode = "Velocity",
            Bhop = false,
            BhopMode = "Hold Jump",
            BhopGain = 2,
            BhopMax = 45,
        },
        Trigger = {
            Enabled = false,
            Mode = "Click",
            Delay = 0,
            Interval = 90,
            MaxDistance = 600,
            HeadOnly = false,
            UseSilent = true,
            Method = "Auto",
            Radius = 14,
        },
        Sounds = {
            KillEnabled = false,
            Preset = "Neverlose",
            Volume = 3,
            Mode = "Auto",
            Custom = "",
        },
        AntiAim = {
            Enabled = false,
            OffsetMode = "Off",
            OffsetStuds = 2.5,
            OffsetRate = 10,
            Type = "Spin",
            Speed = 720,
            Angle = 90,
            Rate = 12,
            Offset = 0,
            Pitch = "Off",
            PitchAngle = 75,
        },
        Knife = {
            Enabled = false,
            Knife = "Butterfly",
            Skin = "Steel",
            AutoInspect = true,
            InspectEvery = 8,
            HideTools = true,
            Scale = 1,
            HoldAngle = 0,
            AssetRoll = 0,
            AssetFlip = false,
        },
        Optimize = {
            Explosions = true,
            DebrisCleaner = false,
            Effects = false,
            PostFX = false,
            Shadows = false,
            LowQuality = false,
            Materials = false,
            Textures = false,
        },
        Settings = {
            GUIScale = 0.8,
            ShowFOV = true,
            TeamSource = "Auto",
            Deathmatch = false,
        },
    }
end

local Config = defaultConfig()
local State = {
    unloaded = false,
    connections = {},
    esp = {},
    refreshers = {},
    hookStatus = { Raycast = false, Namecall = false, Index = false },
    hookHits = { Raycast = 0, Namecall = 0, Mouse = 0 },
    rawRaycast = nil,
    silentTarget = nil,
    silentTargetPlayer = nil,
    silentScreen = nil,
    inSilentHook = false,
    flyVelocity = nil,
    flyUp = false,
    flyDown = false,
    defaultWalkSpeed = 16,
    defaultJumpPower = 50,
    defaultJumpHeight = 0,
    defaultUseJumpPower = true,
    speedApplied = false,
    jumpApplied = false,
    noclipWasOn = false,
    noclipOriginal = {},
    noclipAccum = 0,
    movementAccum = 0,
    espAccum = 0,
    aimAccum = 0,
    silentAccum = 0,
    teamCache = {},
    teamRefreshAccum = 0,
    characterCache = {},
    rayParams = nil,
    rayFilter = nil,
    silentVisible = false,
    silentLOS = false,
    frameId = 0,
    proj = { frame = -1 },
    partCache = setmetatable({}, { __mode = "k" }),
    partCacheTime = 0,
    engaged = setmetatable({}, { __mode = "k" }),
    damagedAt = setmetatable({}, { __mode = "k" }),
    jumpHeldUntil = 0,
    speedBoosting = false,
    bhopSpeed = nil,
    triggerHolding = false,
    triggerSince = nil,
    triggerLastShot = 0,
    probe = { on = false, entries = {}, order = {} },
    inProbe = false,
    rayChar = nil,
    hookLive = { Raycast = false, Namecall = false, Index = false },
    hookInstalled = {},
    guiCenter = nil,
    fullCenter = nil,
    miniCenter = nil,
    refreshGuiLayout = nil,
    lastViewport = nil,
    fpsAccum = 0,
    fpsFrames = 0,
    fps = 0,
    runtimeLabels = {},
    lastNotify = nil,
    fovDrawing = nil,
    fovRing = nil,
    silentMarker = nil,
    gui = nil,
    main = nil,
    content = nil,
    pages = {},
    tabs = {},
    minimized = false,
    activeTab = "Aimbot",
    executor = "Unknown",
    guiScale = nil,
    silentStatusLabel = nil,
    hooksInstalled = false,
    restoreRaycast = nil,
    restoreNamecall = nil,
    restoreIndex = nil,
    aimWallbangSet = nil,
    silentWallbangSet = nil,
    wallshotSet = nil,
}

State.executor = detectExecutor()

local Theme = {
    bg = Color3.fromRGB(10, 10, 10),
    panel = Color3.fromRGB(20, 20, 20),
    row = Color3.fromRGB(23, 23, 23),
    accent = Color3.fromRGB(147, 162, 255),
    accent2 = Color3.fromRGB(112, 122, 196),
    text = Color3.fromRGB(236, 236, 238),
    muted = Color3.fromRGB(125, 125, 130),
    danger = Color3.fromRGB(255, 99, 99),
    switchOff = Color3.fromRGB(54, 54, 58),
    track = Color3.fromRGB(48, 48, 52),
    border = Color3.fromRGB(38, 38, 38),
    popup = Color3.fromRGB(35, 35, 35),
    tabActive = Color3.fromRGB(58, 58, 58),
}

local COLOR_PRESETS = {
    { name = "Red", color = Color3.fromRGB(255, 60, 60) },
    { name = "Orange", color = Color3.fromRGB(255, 150, 40) },
    { name = "Yellow", color = Color3.fromRGB(255, 220, 60) },
    { name = "Green", color = Color3.fromRGB(60, 255, 120) },
    { name = "Cyan", color = Color3.fromRGB(60, 230, 255) },
    { name = "Blue", color = Color3.fromRGB(60, 160, 255) },
    { name = "Purple", color = Color3.fromRGB(190, 100, 255) },
    { name = "Pink", color = Color3.fromRGB(255, 100, 200) },
    { name = "White", color = Color3.fromRGB(255, 255, 255) },
}

local R15_BONES = {
    { "Head", "UpperTorso" },
    { "UpperTorso", "LowerTorso" },
    { "UpperTorso", "LeftUpperArm" },
    { "LeftUpperArm", "LeftLowerArm" },
    { "LeftLowerArm", "LeftHand" },
    { "UpperTorso", "RightUpperArm" },
    { "RightUpperArm", "RightLowerArm" },
    { "RightLowerArm", "RightHand" },
    { "LowerTorso", "LeftUpperLeg" },
    { "LeftUpperLeg", "LeftLowerLeg" },
    { "LeftLowerLeg", "LeftFoot" },
    { "LowerTorso", "RightUpperLeg" },
    { "RightUpperLeg", "RightLowerLeg" },
    { "RightLowerLeg", "RightFoot" },
}

local R6_BONES = {
    { "Head", "Torso" },
    { "Torso", "Left Arm" },
    { "Torso", "Right Arm" },
    { "Torso", "Left Leg" },
    { "Torso", "Right Leg" },
}

local function connect(signal, callback)
    local connection = signal:Connect(callback)
    State.connections[#State.connections + 1] = connection
    return connection
end

local function getCharacter(player)
    player = player or LocalPlayer
    local cached = State.characterCache[player]
    if cached then
        local character, humanoid = cached[1], cached[2]
        if character and character.Parent and humanoid and humanoid.Parent then
            if humanoid.Health > 0 then return character, humanoid end
            return nil, nil
        end
        State.characterCache[player] = nil
    end
    local character = player.Character
    if not character or not character.Parent then return nil, nil end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return nil, nil end
    State.characterCache[player] = { character, humanoid }
    return character, humanoid
end

-- FindFirstChild is a namecall (slow, and it goes through our hooks), so parts are cached per character.
local function getPart(character, name)
    local cache = State.partCache[character]
    if not cache then
        cache = {}
        State.partCache[character] = cache
    end
    local part = cache[name]
    if part == nil or (part and part.Parent == nil) then
        part = character:FindFirstChild(name) or false
        cache[name] = part
    end
    return part or nil
end

local function getRoot(character)
    return getPart(character, "HumanoidRootPart") or character.PrimaryPart
end

local TEAM_ATTRIBUTE_NAMES = {
    "Team", "TeamId", "team", "teamId",
    "TeamName", "teamName", "Faction", "faction",
}
local TEAM_VALUE_NAMES = { "Team", "TeamId", "TeamName", "Faction" }
local TEAM_ATTRIBUTE_SET = {}
for _, name in ipairs(TEAM_ATTRIBUTE_NAMES) do TEAM_ATTRIBUTE_SET[name] = true end
local TEAM_VALUE_SET = {}
for _, name in ipairs(TEAM_VALUE_NAMES) do TEAM_VALUE_SET[name] = true end
local TEAM_LIKE_PATTERNS = { "team", "faction", "army" }
-- names that look team-ish but are really stats (TeamKills etc.) - they would break the comparison
local TEAM_STAT_PATTERNS = {
    "kill", "death", "score", "point", "rank", "level", "win", "damage", "stat", "count", "chat",
}

local function looksLikeTeamName(name)
    if type(name) ~= "string" then return false end
    local lower = string.lower(name)
    for _, pattern in ipairs(TEAM_STAT_PATTERNS) do
        if string.find(lower, pattern, 1, true) then return false end
    end
    for _, pattern in ipairs(TEAM_LIKE_PATTERNS) do
        if string.find(lower, pattern, 1, true) then return true end
    end
    return false
end

local TEAM_SOURCE_PRIORITY = {
    team = 100,
    ["attr:Team"] = 98,
    ["attr:team"] = 97,
    ["charAttr:Team"] = 96,
    ["charAttr:team"] = 95,
    ["attr:TeamName"] = 94,
    ["attr:teamName"] = 93,
    ["attr:TeamId"] = 92,
    ["attr:teamId"] = 91,
    ["attr:Faction"] = 90,
    ["attr:faction"] = 89,
    playerValue = 80,
    charValue = 79,
    leaderstats = 78,
    teamColor = 10,
}
local TEAM_CACHE_TTL = 30
local NEUTRAL_TEAM_COLORS = {
    White = true,
    ["Institutional white"] = true,
    ["Medium stone grey"] = true,
    ["Light stone grey"] = true,
    ["Dark stone grey"] = true,
    Neutral = true,
}

local function teamSourcePriority(source)
    local known = TEAM_SOURCE_PRIORITY[source]
    if known then return known end
    -- dynamically discovered team-like attributes / values
    if string.sub(source, 1, 3) == "dyn" then return 60 end
    return 50
end

local function readValueBase(container, names)
    for _, name in ipairs(names) do
        local child = container:FindFirstChild(name)
        if child and child:IsA("ValueBase") then
            local ok, value = pcall(function() return child.Value end)
            if ok and value ~= nil then return tostring(value) end
        end
    end
    return nil
end

local function scanTeamLike(instance, prefix, add)
    if not instance then return end
    local attrOk, attrs = pcall(function() return instance:GetAttributes() end)
    if attrOk and type(attrs) == "table" then
        for name, value in pairs(attrs) do
            if looksLikeTeamName(name) and not TEAM_ATTRIBUTE_SET[name] then
                local kind = typeof(value)
                if kind == "string" or kind == "number" or kind == "boolean"
                    or kind == "BrickColor" or kind == "Color3" then
                    add(prefix .. "Attr:" .. name, value)
                end
            end
        end
    end
    local childOk, children = pcall(function() return instance:GetChildren() end)
    if childOk and children then
        for _, child in ipairs(children) do
            if child:IsA("ValueBase") and looksLikeTeamName(child.Name) and not TEAM_VALUE_SET[child.Name] then
                local ok, value = pcall(function() return child.Value end)
                if ok and value ~= nil then
                    add(prefix .. "Value:" .. child.Name, tostring(value))
                end
            end
        end
    end
end

local function getTeamCandidates(player)
    local candidates = {}
    local seen = {}
    local function add(source, value)
        if value == nil then return end
        local text = tostring(value)
        if text == "" or text == "nil" then return end
        local key = source .. "=" .. text
        if seen[key] then return end
        seen[key] = true
        candidates[#candidates + 1] = { source = source, value = text }
    end

    local team = player.Team
    if team then add("team", team.Name) end

    local neutral = false
    local neutralOk, neutralValue = pcall(function() return player.Neutral end)
    if neutralOk and neutralValue == true then neutral = true end

    local colorOk, color = pcall(function() return player.TeamColor end)
    if colorOk and color ~= nil and not neutral then
        local colorName = nil
        pcall(function() colorName = color.Name end)
        if not colorName then colorName = tostring(color) end
        if colorName and not NEUTRAL_TEAM_COLORS[colorName] then
            add("teamColor", colorName)
        end
    end

    local character = player.Character
    for _, name in ipairs(TEAM_ATTRIBUTE_NAMES) do
        local ok, value = pcall(function() return player:GetAttribute(name) end)
        if ok then add("attr:" .. name, value) end
        if character then
            local charOk, charValue = pcall(function() return character:GetAttribute(name) end)
            if charOk then add("charAttr:" .. name, charValue) end
        end
    end

    local playerValue = readValueBase(player, TEAM_VALUE_NAMES)
    if playerValue ~= nil then add("playerValue", playerValue) end

    local leaderstats = player:FindFirstChild("leaderstats")
    if leaderstats then
        local leaderValue = readValueBase(leaderstats, TEAM_VALUE_NAMES)
        if leaderValue ~= nil then add("leaderstats", leaderValue) end
    end

    if character then
        local charValue = readValueBase(character, TEAM_VALUE_NAMES)
        if charValue ~= nil then add("charValue", charValue) end
    end

    -- fallback: any attribute / value whose name contains team / faction / army
    scanTeamLike(player, "dynPlayer", add)
    scanTeamLike(character, "dynChar", add)
    scanTeamLike(leaderstats, "dynLeader", add)

    return candidates
end

local function getCachedTeamCandidates(player)
    local now = os.clock()
    local cached = State.teamCache[player]
    if cached and cached.candidates and (now - cached.time) < TEAM_CACHE_TTL then
        return cached.candidates
    end
    local candidates = getTeamCandidates(player)
    State.teamCache[player] = { time = now, candidates = candidates }
    return candidates
end

local function resolveTeam(player)
    local now = os.clock()
    local cached = State.teamCache[player]
    if cached and cached.resolved and (now - cached.time) < TEAM_CACHE_TTL then
        return cached.ally, cached.source
    end
    local mine = getCachedTeamCandidates(LocalPlayer)
    local theirs = getCachedTeamCandidates(player)
    local forced = Config.Settings.TeamSource
    if forced == "Auto" then forced = nil end
    local bestPriority, bestAlly, bestSource = nil, nil, nil
    for _, a in ipairs(mine) do
        for _, b in ipairs(theirs) do
            if a.source == b.source and (not forced or a.source == forced) then
                local priority = teamSourcePriority(a.source)
                if not bestPriority or priority > bestPriority then
                    bestPriority = priority
                    bestAlly = a.value == b.value
                    bestSource = a.source
                end
            end
        end
    end
    local targetCache = State.teamCache[player]
    if not targetCache then
        targetCache = { time = now, candidates = theirs }
        State.teamCache[player] = targetCache
    end
    if bestPriority then
        targetCache.ally = bestAlly
        targetCache.source = bestSource
        targetCache.resolved = true
        return bestAlly, bestSource
    end
    targetCache.ally = nil
    targetCache.source = nil
    targetCache.resolved = true
    return nil, nil
end

local function passesTeam(player, teamCheck)
    if player == LocalPlayer then return false end
    if not teamCheck then return true end
    local ally = resolveTeam(player)
    if ally == nil then return true end
    return not ally
end

local function invalidateTeamCache()
    State.teamCache = {}
end

local function clearCharacterCache(player)
    State.characterCache[player] = nil
end

local trackPlayerHumanoid -- assigned in the kill-sound section

local function watchPlayer(player)
    pcall(function()
        connect(player:GetPropertyChangedSignal("Team"), invalidateTeamCache)
    end)
    pcall(function()
        connect(player:GetPropertyChangedSignal("TeamColor"), invalidateTeamCache)
    end)
    pcall(function()
        connect(player:GetPropertyChangedSignal("Neutral"), invalidateTeamCache)
    end)
    pcall(function()
        connect(player.AttributeChanged, function(name)
            if TEAM_ATTRIBUTE_SET[name] then invalidateTeamCache() end
        end)
    end)
    pcall(function()
        connect(player.CharacterAdded, function(character)
            clearCharacterCache(player)
            invalidateTeamCache()
            if character and trackPlayerHumanoid then task.spawn(trackPlayerHumanoid, player, character) end
            if character then
                pcall(function()
                    connect(character.AttributeChanged, function(name)
                        if TEAM_ATTRIBUTE_SET[name] then invalidateTeamCache() end
                    end)
                end)
            end
        end)
    end)
    pcall(function()
        connect(player.CharacterRemoving, function()
            clearCharacterCache(player)
        end)
    end)
    if player.Character and trackPlayerHumanoid then
        task.spawn(trackPlayerHumanoid, player, player.Character)
    end
end

-- Same result as Camera:WorldToViewportPoint, but pure math: no namecall, and the camera data is read once per frame.
local function projectPoint(position)
    local camera = Camera
    if not camera then return nil end
    local proj = State.proj
    if proj.frame ~= State.frameId then
        local viewport = camera.ViewportSize
        proj.frame = State.frameId
        proj.cframe = camera.CFrame
        proj.viewport = viewport
        proj.tan = math.tan(math.rad(camera.FieldOfView) * 0.5)
        proj.aspect = viewport.X / math.max(viewport.Y, 1)
    end
    local relative = proj.cframe:PointToObjectSpace(position)
    local depth = -relative.Z
    if depth <= 0 then return nil end
    local ndcX = relative.X / (depth * proj.tan * proj.aspect)
    local ndcY = relative.Y / (depth * proj.tan)
    local x = (ndcX * 0.5 + 0.5) * proj.viewport.X
    local y = (0.5 - ndcY * 0.5) * proj.viewport.Y
    return Vector2.new(x, y), (math.abs(ndcX) <= 1 and math.abs(ndcY) <= 1)
end

local function makeRayParams()
    local character = LocalPlayer.Character
    if not State.rayParams then
        local params = RaycastParams.new()
        local ok, filter = pcall(function() return Enum.RaycastFilterType.Exclude end)
        params.FilterType = ok and filter or Enum.RaycastFilterType.Blacklist
        params.IgnoreWater = true
        State.rayParams = params
        State.rayFilter = {}
    end
    -- assigning FilterDescendantsInstances copies the table; do it only when the character changed
    local marker = character or false
    if State.rayChar ~= marker then
        State.rayChar = marker
        State.rayFilter[1] = character
        State.rayParams.FilterDescendantsInstances = State.rayFilter
    end
    return State.rayParams
end

local function rawRaycast(origin, direction, params)
    if State.rawRaycast then
        local ok, result = pcall(State.rawRaycast, Workspace, origin, direction, params)
        if ok then return result end
    end
    local ok, result = pcall(function()
        return Workspace:Raycast(origin, direction, params)
    end)
    if ok then return result end
    return nil
end

local function hasLineOfSight(character, part, origin)
    if not character or not part or not part.Parent then return false end
    origin = origin or (Camera and Camera.CFrame.Position)
    if not origin then return false end
    local direction = part.Position - origin
    if direction.Magnitude < 0.01 then return true end
    local result = rawRaycast(origin, direction, makeRayParams())
    if not result then return true end
    return result.Instance:IsDescendantOf(character)
end

local NEAREST_PART_NAMES = { "Head", "UpperTorso", "Torso", "HumanoidRootPart" }

local function getPartForMode(character, mode, center)
    if mode == "Nearest" then
        local bestPart, bestScreen, bestDistance = nil, nil, nil
        for _, name in ipairs(NEAREST_PART_NAMES) do
            local part = getPart(character, name)
            if part and part:IsA("BasePart") then
                local screen, onScreen = projectPoint(part.Position)
                if screen and onScreen then
                    local distance = (screen - center).Magnitude
                    if not bestDistance or distance < bestDistance then
                        bestPart, bestScreen, bestDistance = part, screen, distance
                    end
                end
            end
        end
        if bestPart then return bestPart, bestScreen, true end
        local root = getRoot(character)
        if root then
            local screen, onScreen = projectPoint(root.Position)
            return root, screen, onScreen
        end
        return nil
    end
    local part = getPart(character, mode)
    if not part and mode == "UpperTorso" then
        part = getPart(character, "Torso")
    end
    if not part then
        part = getRoot(character)
    end
    if part then
        local screen, onScreen = projectPoint(part.Position)
        return part, screen, onScreen
    end
    return nil
end

local function getBestTarget(fov, maxDistance, teamCheck, partMode, visibleOnly, priority)
    if not Camera then return nil end
    local center = Camera.ViewportSize * 0.5
    local cameraCFrame = Camera.CFrame
    local cameraPosition = cameraCFrame.Position
    local look = cameraCFrame.LookVector
    local bestPlayer, bestPart, bestScreen, bestDistance, bestScore = nil, nil, nil, nil, nil
    for _, player in ipairs(Players:GetPlayers()) do
        if passesTeam(player, teamCheck) then
            local character = getCharacter(player)
            if character then
                local root = getRoot(character)
                if root then
                    local offset = root.Position - cameraPosition
                    local distance = offset.Magnitude
                    local dot = offset.X * look.X + offset.Y * look.Y + offset.Z * look.Z
                    if distance <= maxDistance and dot > 0 then
                        local part, screen, onScreen = getPartForMode(character, partMode, center)
                        if part and screen and onScreen then
                            local screenDistance = (screen - center).Magnitude
                            if screenDistance <= fov then
                                if (not visibleOnly) or hasLineOfSight(character, part, cameraPosition) then
                                    local score = (priority == "Distance") and distance or screenDistance
                                    if not bestScore or score < bestScore then
                                        bestPlayer, bestPart, bestScreen, bestDistance, bestScore = player, part, screen, distance, score
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    return bestPlayer, bestPart, bestScreen, bestDistance
end

-- Rays shorter than this are not shots (camera occlusion, ground checks...) and are never redirected.
local MIN_SHOT_RAY = 40

-- ===== Shot probe (diagnostic): records HOW the game shoots (ray methods + remotes), never values =====
local PROBE_RAY_METHODS = {
    Raycast = true, Spherecast = true, Blockcast = true,
    FindPartOnRay = true, FindPartOnRayWithIgnoreList = true, FindPartOnRayWithWhitelist = true,
    ViewportPointToRay = true, ScreenPointToRay = true,
}

local function probeScriptName()
    if type(getcallingscript) ~= "function" then return "?" end
    local ok, caller = pcall(getcallingscript)
    if ok and caller then
        local okName, name = pcall(function()
            local parent = caller.Parent
            return caller.Name .. (parent and ("<" .. parent.Name) or "")
        end)
        if okName and name then return name end
    end
    return "?"
end

local function probeAdd(key)
    local probe = State.probe
    local entry = probe.entries[key]
    if entry then
        entry.count = entry.count + 1
    elseif #probe.order < 80 then
        probe.entries[key] = { count = 1 }
        probe.order[#probe.order + 1] = key
    end
end

-- no namecalls in here: it runs inside the __namecall hook
local function probeRecord(self, method, ...)
    if typeof(self) ~= "Instance" then return end
    if (self == Workspace or self == Camera) and PROBE_RAY_METHODS[method] then
        local extra = ""
        if method == "Raycast" then
            local _, direction = ...
            if typeof(direction) == "Vector3" then
                extra = direction.Magnitude >= MIN_SHOT_RAY and " long" or " short"
            end
        end
        probeAdd(method .. extra .. " | " .. probeScriptName())
    elseif method == "FireServer" or method == "InvokeServer" then
        local count = select("#", ...)
        local types = {}
        for index = 1, math.min(count, 8) do
            local value = select(index, ...)
            local kind = typeof(value)
            if kind == "Instance" then kind = "Instance:" .. value.ClassName end
            types[#types + 1] = kind
        end
        probeAdd(method .. " " .. self.Name .. " (" .. table.concat(types, ",") .. ") | " .. probeScriptName())
    end
end

-- Called from inside the hooks: it must stay cheap (no raycasts, no namecalls).
-- Line of sight is computed at 30 Hz by updateSilentTarget and read from State.silentLOS.
-- RaycastParams that only "see" the target's character: a ray with these passes through walls and hits the target.
local function getWallbangParams(character, gameParams)
    local params = State.wallParams
    if not params then
        params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Include
        params.IgnoreWater = true
        State.wallParams = params
        State.wallChar = nil
    end
    if State.wallChar ~= character then
        State.wallChar = character
        params.FilterDescendantsInstances = { character }
    end
    -- the game's rays often use a collision group; characters may sit in a group that does not collide
    -- with "Default", so copy the settings from the game's own params or the ray would miss the target
    if typeof(gameParams) == "RaycastParams" then
        pcall(function() params.CollisionGroup = gameParams.CollisionGroup end)
        pcall(function() params.RespectCanCollide = gameParams.RespectCanCollide end)
        pcall(function() params.IgnoreWater = gameParams.IgnoreWater end)
        pcall(function() params.BruteForceAllSlow = gameParams.BruteForceAllSlow end)
    end
    return params
end

-- returns: direction, wallbangParams (or nil), targetCharacter
local function getRedirectDirection(origin, rayLength, gameParams)
    local part = State.silentTarget
    if not part or not part.Parent then return nil end
    if rayLength and rayLength < MIN_SHOT_RAY then return nil end
    local blocked = not State.silentLOS
    if blocked and not Config.Silent.Wallbang then return nil end
    local direction = part.Position - origin
    if direction.Magnitude < 0.01 then return nil end
    if blocked then
        -- a wall is in the way: pointing the ray at the target is not enough, the game's own raycast
        -- would still stop at the wall, so hand it params that only include the target
        local character = State.silentTargetPlayer and State.silentTargetPlayer.Character
        if character then
            return direction, getWallbangParams(character, gameParams), character
        end
    end
    return direction
end

local function installRaycastHook()
    local installed = State.hookInstalled.Raycast
    if installed then
        -- already hooked once: just switch it back on (never stack another hook on top)
        State.hookLive.Raycast = true
        State.rawRaycast = installed.original
        State.hookStatus.Raycast = true
        State.restoreRaycast = function() State.hookLive.Raycast = false end
        return true
    end
    if not Cap.HookFunction or type(Workspace.Raycast) ~= "function" then return false end
    local target = Workspace.Raycast
    local safeCopy = nil
    if type(clonefunction) == "function" then
        local okClone, cloned = pcall(clonefunction, target)
        if okClone and type(cloned) == "function" then safeCopy = cloned end
    end
    local info = { original = nil }
    local callback = wrapCallback(function(self, a, b, c)
        local origin, direction, params
        if self == Workspace then
            origin, direction, params = a, b, c
        else
            origin, direction, params = self, a, b
        end
        if State.probe.on and not State.inProbe and typeof(direction) == "Vector3" then
            State.inProbe = true
            pcall(probeAdd, "Raycast(fn)" .. (direction.Magnitude >= MIN_SHOT_RAY and " long" or " short") .. " | " .. probeScriptName())
            State.inProbe = false
        end
        if State.hookLive.Raycast and Config.Silent.Enabled and State.silentTarget and not State.inSilentHook
            and typeof(origin) == "Vector3" and typeof(direction) == "Vector3" then
            State.inSilentHook = true
            local ok, redirected, wallParams = pcall(getRedirectDirection, origin, direction.Magnitude, params)
            State.inSilentHook = false
            if ok and redirected then
                direction = redirected
                if wallParams then params = wallParams end
                State.hookHits.Raycast = State.hookHits.Raycast + 1
                State.lastFireAt = os.clock()
            end
        end
        return info.original(Workspace, origin, direction, params)
    end)
    local ok, old = pcall(hookfunction, target, callback)
    if not ok then return false end
    -- the ORIGINAL must be what hookfunction returned: Workspace.Raycast itself now points at our callback,
    -- calling it from inside the callback would recurse forever (this was the FPS-to-zero bug)
    local original = nil
    if type(old) == "function" then
        original = old
    elseif safeCopy then
        original = safeCopy
    end
    if not original then
        if type(restorefunction) == "function" then pcall(restorefunction, target) end
        return false
    end
    info.original = original
    State.hookInstalled.Raycast = info
    State.rawRaycast = original
    State.hookLive.Raycast = true
    State.hookStatus.Raycast = true
    State.restoreRaycast = function() State.hookLive.Raycast = false end
    return true
end

local function installNamecallHook()
    local installed = State.hookInstalled.Namecall
    if installed then
        State.hookLive.Namecall = true
        State.hookStatus.Namecall = true
        State.restoreNamecall = function() State.hookLive.Namecall = false end
        return true
    end
    if not Cap.Namecall then return false end
    local oldNamecall
    local function redirectFor(origin, length, gameParams)
        State.inSilentHook = true
        local ok, redirected, wallParams, wallChar = pcall(getRedirectDirection, origin, length, gameParams)
        State.inSilentHook = false
        if ok and redirected then return redirected, wallParams, wallChar end
        return nil
    end
    local canSetMethod = type(setnamecallmethod) == "function"
    local callback = wrapCallback(function(self, ...)
        if State.probe.on and not State.inProbe and State.hookLive.Namecall then
            local probeMethod = getnamecallmethod()
            if probeMethod then
                State.inProbe = true
                pcall(probeRecord, self, probeMethod, ...)
                State.inProbe = false
                if canSetMethod then setnamecallmethod(probeMethod) end
            end
        end
        if not State.hookLive.Namecall or not Config.Silent.Enabled or not State.silentTarget or State.inSilentHook then
            return oldNamecall(self, ...)
        end
        if self ~= Workspace and self ~= Camera then
            return oldNamecall(self, ...)
        end
        local method = getnamecallmethod()
        if not method then return oldNamecall(self, ...) end

        if self == Workspace then
            if method == "Raycast" then
                local origin, direction, params = ...
                if typeof(origin) == "Vector3" and typeof(direction) == "Vector3" then
                    local redirected, wallParams = redirectFor(origin, direction.Magnitude, params)
                    if redirected then
                        State.hookHits.Namecall = State.hookHits.Namecall + 1
                State.lastFireAt = os.clock()
                        if canSetMethod then setnamecallmethod(method) end
                        return oldNamecall(self, origin, redirected, wallParams or params)
                    end
                end
            elseif method == "Spherecast" then
                local origin, radius, direction, params = ...
                if typeof(origin) == "Vector3" and typeof(direction) == "Vector3" then
                    local redirected, wallParams = redirectFor(origin, direction.Magnitude, params)
                    if redirected then
                        State.hookHits.Namecall = State.hookHits.Namecall + 1
                State.lastFireAt = os.clock()
                        if canSetMethod then setnamecallmethod(method) end
                        return oldNamecall(self, origin, radius, redirected, wallParams or params)
                    end
                end
            elseif method == "FindPartOnRay" or method == "FindPartOnRayWithIgnoreList" or method == "FindPartOnRayWithWhitelist" then
                local ray = ...
                if typeof(ray) == "Ray" then
                    local redirected, wallParams, wallChar = redirectFor(ray.Origin, ray.Direction.Magnitude)
                    if redirected and wallParams and wallChar and canSetMethod then
                        -- old API through a wall: switch to the whitelist variant so only the target is hit
                        State.hookHits.Namecall = State.hookHits.Namecall + 1
                State.lastFireAt = os.clock()
                        setnamecallmethod("FindPartOnRayWithWhitelist")
                        return oldNamecall(self, Ray.new(ray.Origin, redirected), { wallChar })
                    end
                    if redirected then
                        State.hookHits.Namecall = State.hookHits.Namecall + 1
                State.lastFireAt = os.clock()
                        local args = { ... }
                        args[1] = Ray.new(ray.Origin, redirected)
                        if canSetMethod then setnamecallmethod(method) end
                        return oldNamecall(self, unpackFn(args))
                    end
                end
            end
        elseif self == Camera and (method == "ViewportPointToRay" or method == "ScreenPointToRay") then
            local ray = oldNamecall(self, ...)
            if ray and State.silentTarget then
                local redirected = redirectFor(ray.Origin, nil)
                if redirected then
                    State.hookHits.Namecall = State.hookHits.Namecall + 1
                State.lastFireAt = os.clock()
                    return Ray.new(ray.Origin, redirected.Unit)
                end
            end
            return ray
        end

        if canSetMethod then setnamecallmethod(method) end
        return oldNamecall(self, ...)
    end)
    oldNamecall = hookMetaMethod(game, "__namecall", callback)
    if not oldNamecall then return false end
    State.hookInstalled.Namecall = { original = oldNamecall }
    State.hookLive.Namecall = true
    State.hookStatus.Namecall = true
    State.restoreNamecall = function() State.hookLive.Namecall = false end
    return true
end

local function installIndexHook()
    if not Config.Silent.Enabled then return false end
    if State.restoreIndex then return true end
    local installed = State.hookInstalled.Index
    if installed then
        State.hookLive.Index = true
        State.hookStatus.Index = true
        State.restoreIndex = function() State.hookLive.Index = false end
        return true
    end
    if not Cap.HookMetamethod and not Cap.RawMeta then return false end
    local oldIndex
    local callback = wrapCallback(function(self, key)
        if State.hookLive.Index and Config.Silent.Enabled and State.silentTarget and not State.inSilentHook
            and (key == "Hit" or key == "UnitRay" or key == "Target") then
            State.inSilentHook = true
            local ok, result = pcall(function()
                local className = oldIndex(self, "ClassName")
                if className ~= "Mouse" then return nil end
                local part = State.silentTarget
                if not part then return nil end
                if not Config.Silent.Wallbang and not State.silentLOS then return nil end
                if key == "Hit" then return CFrame.new(part.Position) end
                if key == "UnitRay" then
                    local origin = Camera.CFrame.Position
                    return Ray.new(origin, (part.Position - origin).Unit)
                end
                return part
            end)
            State.inSilentHook = false
            if ok and result ~= nil then
                State.hookHits.Mouse = State.hookHits.Mouse + 1
                State.lastFireAt = os.clock()
                return result
            end
        end
        return oldIndex(self, key)
    end)
    oldIndex = hookMetaMethod(game, "__index", callback)
    if not oldIndex then return false end
    State.hookInstalled.Index = { original = oldIndex }
    State.hookLive.Index = true
    State.hookStatus.Index = true
    State.restoreIndex = function() State.hookLive.Index = false end
    return true
end

local function updateHookStatus()
    local list = {}
    if State.hookStatus.Raycast then list[#list + 1] = "Raycast" end
    if State.hookStatus.Namecall then list[#list + 1] = "Namecall" end
    if State.hookStatus.Index then list[#list + 1] = "Mouse" end
    local text, color
    if #list == 0 then
        if Config.Silent.Enabled then
            text = "Hooks: NONE - silent aim unavailable"
            color = Theme.danger
        else
            text = "Hooks: idle (not installed)"
            color = Theme.muted
        end
    else
        text = "Hooks: " .. table.concat(list, " + ")
        color = Theme.accent
    end
    if State.silentStatusLabel then
        State.silentStatusLabel.Text = text
        State.silentStatusLabel.TextColor3 = color
    end
    if State.runtimeLabels.hooks then
        State.runtimeLabels.hooks.Text = text
        State.runtimeLabels.hooks.TextColor3 = color
    end
end

local function restoreIndexHook()
    if State.restoreIndex then pcall(State.restoreIndex) end
    State.restoreIndex = nil
    State.hookLive.Index = false
    State.hookStatus.Index = false
    updateHookStatus()
end

-- Turning silent aim off only switches the hooks into pass-through mode.
-- Re-hooking to "restore" is what stacked hooks on top of each other and tanked the FPS.
local function restoreHooks()
    if State.restoreRaycast then pcall(State.restoreRaycast) end
    if State.restoreNamecall then pcall(State.restoreNamecall) end
    if State.restoreIndex then pcall(State.restoreIndex) end
    State.restoreRaycast = nil
    State.restoreNamecall = nil
    State.restoreIndex = nil
    State.hookLive.Raycast = false
    State.hookLive.Namecall = State.probe.on and State.hookInstalled.Namecall ~= nil
    State.hookLive.Index = false
    if not State.hookInstalled.Raycast then State.rawRaycast = nil end
    State.hooksInstalled = false
    State.hookStatus = { Raycast = false, Namecall = false, Index = false }
    State.hookHits = { Raycast = 0, Namecall = 0, Mouse = 0 }
    updateHookStatus()
end

-- Only used on unload: really remove the Raycast hook when the executor can do it.
local function fullUnhook()
    local installed = State.hookInstalled.Raycast
    if installed and type(restorefunction) == "function" then
        local ok = pcall(restorefunction, Workspace.Raycast)
        if ok then
            State.hookInstalled.Raycast = nil
            State.rawRaycast = nil
        end
    end
end

local function newDrawing(class)
    if not Cap.Drawing then return nil end
    local ok, object = pcall(Drawing.new, class)
    if ok and object then return object end
    return nil
end

local function removeDrawing(object)
    if not object then return end
    pcall(function() object:Remove() end)
end

-- Every Drawing property write is a call into the executor (slow, especially on mobile),
-- so remember the last value written and skip identical writes.
local drawingCache = setmetatable({}, { __mode = "k" })
local function setDraw(object, property, value)
    local cache = drawingCache[object]
    if not cache then
        cache = {}
        drawingCache[object] = cache
    end
    if cache[property] ~= value then
        cache[property] = value
        object[property] = value
    end
end

-- ===================== ESP =====================
-- Drawing.Transparency means OPACITY (1 = solid). The old ESP passed a "10 %" transparency straight into it,
-- which made everything almost invisible; the new ESP has a proper Opacity setting.
local ESPDraw = {}
local BOX_STYLES = { "Corner", "Full", "Off" }
local TRACER_ORIGINS = { "Bottom", "Center", "Top" }
ESPDraw.black = Color3.fromRGB(0, 0, 0)
ESPDraw.white = Color3.fromRGB(255, 255, 255)
ESPDraw.gray = Color3.fromRGB(205, 205, 212)
ESPDraw.green = Color3.fromRGB(52, 230, 110)
ESPDraw.yellow = Color3.fromRGB(255, 214, 10)
ESPDraw.red = Color3.fromRGB(255, 59, 48)

function ESPDraw.healthColor(ratio)
    if ratio > 0.5 then
        return ESPDraw.yellow:Lerp(ESPDraw.green, (ratio - 0.5) * 2)
    end
    return ESPDraw.red:Lerp(ESPDraw.yellow, ratio * 2)
end

-- drawing objects are created lazily, once per feature that is really used
function ESPDraw.object(data, key, class, init)
    local object = data.map[key]
    if object then return object end
    object = newDrawing(class)
    if not object then return nil end
    data.map[key] = object
    data.objects[#data.objects + 1] = object
    if init then pcall(init, object) end
    setDraw(object, "Visible", false)
    return object
end

function ESPDraw.show(data, object)
    data.seen[object] = data.stamp
    setDraw(object, "Visible", true)
end

function ESPDraw.line(data, key, from, to, color, thickness, opacity, z)
    local object = ESPDraw.object(data, key, "Line", function(o) o.ZIndex = z or 2 end)
    if not object then return end
    setDraw(object, "From", from)
    setDraw(object, "To", to)
    setDraw(object, "Color", color)
    setDraw(object, "Thickness", thickness)
    setDraw(object, "Transparency", opacity)
    ESPDraw.show(data, object)
end

function ESPDraw.rect(data, key, position, size, color, thickness, filled, opacity, z)
    local object = ESPDraw.object(data, key, "Square", function(o) o.ZIndex = z or 2 end)
    if not object then return end
    setDraw(object, "Position", position)
    setDraw(object, "Size", size)
    setDraw(object, "Color", color)
    setDraw(object, "Thickness", thickness)
    setDraw(object, "Filled", filled)
    setDraw(object, "Transparency", opacity)
    ESPDraw.show(data, object)
end

function ESPDraw.text(data, key, text, position, color, size, opacity)
    local object = ESPDraw.object(data, key, "Text", function(o)
        o.Center = true
        o.Outline = true
        o.OutlineColor = ESPDraw.black
        o.Font = 2
        o.ZIndex = 4
    end)
    if not object then return end
    setDraw(object, "Text", text)
    setDraw(object, "Position", position)
    setDraw(object, "Color", color)
    setDraw(object, "Size", size)
    setDraw(object, "Transparency", opacity)
    ESPDraw.show(data, object)
end

function ESPDraw.circle(data, key, position, radius, color, thickness, opacity)
    local object = ESPDraw.object(data, key, "Circle", function(o)
        o.NumSides = 24
        o.Filled = false
        o.ZIndex = 3
    end)
    if not object then return end
    setDraw(object, "Position", position)
    setDraw(object, "Radius", radius)
    setDraw(object, "Color", color)
    setDraw(object, "Thickness", thickness)
    setDraw(object, "Transparency", opacity)
    ESPDraw.show(data, object)
end

function ESPDraw.triangle(data, key, a, b, c, color, thickness, filled, opacity, z)
    local object = ESPDraw.object(data, key, "Triangle", function(o) o.ZIndex = z or 2 end)
    if not object then return end
    setDraw(object, "PointA", a)
    setDraw(object, "PointB", b)
    setDraw(object, "PointC", c)
    setDraw(object, "Color", color)
    setDraw(object, "Thickness", thickness)
    setDraw(object, "Filled", filled)
    setDraw(object, "Transparency", opacity)
    ESPDraw.show(data, object)
end

-- hides every drawing that was not used during this update
function ESPDraw.finish(data)
    for _, object in ipairs(data.objects) do
        if data.seen[object] ~= data.stamp then
            setDraw(object, "Visible", false)
        end
    end
end

-- Corner-style box: 4 L-shaped corners, each with a dark underlay for contrast
function ESPDraw.corners(data, minX, minY, maxX, maxY, color, opacity, outline)
    local width, height = maxX - minX, maxY - minY
    local lengthX = math.min(math.max(width * 0.3, 4), width * 0.5)
    local lengthY = math.min(math.max(height * 0.2, 4), height * 0.5)
    local corners = {
        { Vector2.new(minX, minY), 1, 1 },
        { Vector2.new(maxX, minY), -1, 1 },
        { Vector2.new(minX, maxY), 1, -1 },
        { Vector2.new(maxX, maxY), -1, -1 },
    }
    for index, corner in ipairs(corners) do
        local origin, dx, dy = corner[1], corner[2], corner[3]
        local horizontal = origin + Vector2.new(lengthX * dx, 0)
        local vertical = origin + Vector2.new(0, lengthY * dy)
        if outline then
            ESPDraw.line(data, "co" .. index .. "h", origin - Vector2.new(dx, 0), horizontal, ESPDraw.black, 3.5, opacity * 0.85, 1)
            ESPDraw.line(data, "co" .. index .. "v", origin - Vector2.new(0, dy), vertical, ESPDraw.black, 3.5, opacity * 0.85, 1)
        end
        ESPDraw.line(data, "c" .. index .. "h", origin, horizontal, color, 1.6, opacity, 2)
        ESPDraw.line(data, "c" .. index .. "v", origin, vertical, color, 1.6, opacity, 2)
    end
end

function ESPDraw.chams(data, character, color, visible)
    local cfg = Config.ESP
    local highlight = data.highlight
    if not cfg.Chams then
        if highlight then highlight.Enabled = false end
        return
    end
    if not highlight then
        highlight = Instance.new("Highlight")
        highlight.Name = "4080_Chams"
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.OutlineTransparency = 0.1
        highlight.Parent = (State.gui and State.gui.Parent) or Workspace.CurrentCamera
        data.highlight = highlight
    end
    if highlight.Adornee ~= character then highlight.Adornee = character end
    if data.chamsColor ~= color then
        data.chamsColor = color
        highlight.FillColor = color
        highlight.OutlineColor = color:Lerp(ESPDraw.white, 0.45)
    end
    local fill = clamp(cfg.ChamsFill / 100, 0, 1)
    if highlight.FillTransparency ~= fill then highlight.FillTransparency = fill end
    highlight.Enabled = true
end

-- screen-edge arrow pointing at an enemy that is outside the view
function ESPDraw.arrow(data, position, color, opacity)
    local proj = State.proj
    if not proj.cframe or not proj.viewport then return end
    local relative = proj.cframe:PointToObjectSpace(position)
    local direction = Vector2.new(relative.X, relative.Z)
    if direction.Magnitude < 0.001 then return end
    direction = direction.Unit
    local center = Vector2.new(proj.viewport.X * 0.5, proj.viewport.Y * 0.5)
    local radius = math.min(Config.ESP.ArrowRadius, math.min(center.X, center.Y) - 20)
    local anchor = center + direction * radius
    local side = Vector2.new(-direction.Y, direction.X)
    local tip = anchor + direction * 15
    local left = anchor - direction * 6 + side * 10
    local right = anchor - direction * 6 - side * 10
    ESPDraw.triangle(data, "arrowOutline", tip, left, right, ESPDraw.black, 3, false, opacity * 0.9, 1)
    ESPDraw.triangle(data, "arrow", tip, left, right, color, 1, true, opacity, 2)
end

local function hideESP(data)
    if not data or data.hidden then return end
    data.hidden = true
    for _, object in ipairs(data.objects) do
        setDraw(object, "Visible", false)
    end
    if data.highlight then data.highlight.Enabled = false end
    if data.billboard then data.billboard.Enabled = false end
end

-- used only when the executor has no Drawing library: a glow + a text label above the head
function ESPDraw.createFallback(player, data)
    local highlight = Instance.new("Highlight")
    highlight.Name = "4080_ESP"
    highlight.FillTransparency = 0.6
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Adornee = player.Character
    highlight.Parent = (State.gui and State.gui.Parent) or Workspace.CurrentCamera
    data.highlight = highlight

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "4080_ESP"
    billboard.Size = UDim2.fromOffset(220, 56)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop = true
    billboard.Adornee = player.Character and (player.Character:FindFirstChild("Head") or player.Character:FindFirstChild("HumanoidRootPart"))
    billboard.Parent = (State.gui and State.gui.Parent) or Workspace.CurrentCamera

    local text = Instance.new("TextLabel")
    text.BackgroundTransparency = 1
    text.Size = UDim2.fromScale(1, 1)
    text.Font = Enum.Font.GothamBold
    text.TextSize = 14
    text.TextColor3 = Config.ESP.EnemyColor
    text.TextStrokeTransparency = 0.4
    text.TextWrapped = true
    text.Parent = billboard

    data.billboard = billboard
    data.fallbackText = text
    data.fallback = true
end

local function createESP(player)
    local data = {
        map = {},
        objects = {},
        seen = {},
        stamp = 0,
        hidden = true,
        fallback = false,
        sizeAt = -1,
        visAt = -1,
        toolAt = -1,
    }
    if not Cap.Drawing then
        ESPDraw.createFallback(player, data)
    end
    State.esp[player] = data
    return data
end

local function destroyESP(player)
    local data = State.esp[player]
    if not data then return end
    for _, object in ipairs(data.objects) do removeDrawing(object) end
    if data.highlight then pcall(function() data.highlight:Destroy() end) end
    if data.billboard then pcall(function() data.billboard:Destroy() end) end
    State.esp[player] = nil
end

local function updateESPFor(player, data, context)
    local cfg = Config.ESP
    local character, humanoid, root, distance
    if context then
        character, humanoid, root, distance = context.character, context.humanoid, context.root, context.distance
    else
        character, humanoid = getCharacter(player)
        if not character or not humanoid then hideESP(data); return end
        root = getRoot(character)
        if not root then hideESP(data); return end
        distance = (root.Position - Camera.CFrame.Position).Magnitude
    end
    if distance > cfg.MaxDistance then hideESP(data); return end

    -- Team check is always on for ESP (the only way to turn it off is Config.ESP.TeamCheck = false in the code).
    -- Deathmatch mode: everybody counts as an enemy.
    local allyValue = false
    if not Config.Settings.Deathmatch then
        allyValue = resolveTeam(player) == true
    end
    if allyValue and cfg.TeamCheck then hideESP(data); return end

    data.hidden = false
    data.stamp = data.stamp + 1
    local clock = os.clock()
    local opacity = clamp(cfg.Opacity / 100, 0.05, 1)

    -- visible / behind a wall (checked a few times per second, one raycast)
    local visible = true
    if cfg.VisibilityColors or cfg.Chams then
        if clock - data.visAt > 0.12 then
            data.visAt = clock
            data.visible = hasLineOfSight(character, getPart(character, "Head") or root)
        end
        visible = data.visible ~= false
    end
    local color = allyValue and cfg.AllyColor or cfg.EnemyColor
    if cfg.VisibilityColors and visible and not allyValue then color = cfg.VisibleColor end

    ESPDraw.chams(data, character, color, visible)

    if data.fallback or not Cap.Drawing then
        if data.billboard then
            data.billboard.Adornee = getPart(character, "Head") or root
            data.billboard.Enabled = true
        end
        if data.highlight then
            data.highlight.Adornee = character
            data.highlight.FillColor = color
            data.highlight.OutlineColor = color
            data.highlight.Enabled = true
        end
        if data.fallbackText then
            local lines = {}
            if cfg.Name then lines[#lines + 1] = player.DisplayName or player.Name end
            if cfg.Health then
                lines[#lines + 1] = string.format("%d HP", math.floor(humanoid.Health + 0.5))
            end
            if cfg.Distance then lines[#lines + 1] = string.format("%dm", math.floor(distance + 0.5)) end
            data.fallbackText.Text = table.concat(lines, "  |  ")
            data.fallbackText.TextColor3 = color
        end
        return
    end

    -- body height / offset from the root part, measured a few times per second (GetBoundingBox is a slow call)
    if clock - data.sizeAt > 0.4 then
        data.sizeAt = clock
        local ok, boxCFrame, boxSize = pcall(function() return character:GetBoundingBox() end)
        if ok and boxCFrame and boxSize then
            data.height = clamp(boxSize.Y, 2, 12)
            data.offsetBottom = root.Position.Y - (boxCFrame.Position.Y - boxSize.Y * 0.5)
        end
    end
    local height3d = data.height or 5.5
    local bottomPoint = root.Position - Vector3.new(0, data.offsetBottom or 3, 0)
    local topPoint = bottomPoint + Vector3.new(0, height3d, 0)
    local topScreen = projectPoint(topPoint)
    local bottomScreen = projectPoint(bottomPoint)
    local viewport = State.proj.viewport or Camera.ViewportSize

    local inView = false
    local minX, minY, maxX, maxY, centerX = 0, 0, 0, 0, 0
    if topScreen and bottomScreen then
        local height = math.abs(bottomScreen.Y - topScreen.Y)
        if height >= 1 then
            local width = height * 0.5
            centerX = math.floor((topScreen.X + bottomScreen.X) * 0.5 + 0.5)
            minX = math.floor(centerX - width * 0.5 + 0.5)
            maxX = math.floor(centerX + width * 0.5 + 0.5)
            minY = math.floor(math.min(topScreen.Y, bottomScreen.Y) + 0.5)
            maxY = math.floor(math.max(topScreen.Y, bottomScreen.Y) + 0.5)
            inView = maxX > 0 and minX < viewport.X and maxY > 0 and minY < viewport.Y
        end
    end

    if not inView then
        if cfg.Arrows then ESPDraw.arrow(data, root.Position, color, opacity) end
        ESPDraw.finish(data)
        return
    end

    local width, height = maxX - minX, maxY - minY
    local outline = cfg.Outline

    -- box
    if cfg.BoxStyle ~= "Off" then
        if cfg.Fill then
            ESPDraw.rect(data, "fill", Vector2.new(minX, minY), Vector2.new(width, height), color, 1, true, opacity * 0.14, 0)
        end
        if cfg.BoxStyle == "Full" then
            if outline then
                ESPDraw.rect(data, "boxOutline", Vector2.new(minX, minY), Vector2.new(width, height), ESPDraw.black, 3.5, false, opacity * 0.85, 1)
            end
            ESPDraw.rect(data, "box", Vector2.new(minX, minY), Vector2.new(width, height), color, 1.6, false, opacity, 2)
        else
            ESPDraw.corners(data, minX, minY, maxX, maxY, color, opacity, outline)
        end
    end

    -- health bar with a green -> yellow -> red gradient
    if cfg.Health then
        local ratio = clamp(humanoid.Health / math.max(humanoid.MaxHealth, 1), 0, 1)
        local barX = minX - 7
        ESPDraw.rect(data, "hpBg", Vector2.new(barX - 1, minY - 1), Vector2.new(5, height + 2), ESPDraw.black, 1, true, opacity * 0.7, 1)
        ESPDraw.rect(data, "hpFill", Vector2.new(barX, minY + height * (1 - ratio)), Vector2.new(3, math.max(height * ratio, 1)), ESPDraw.healthColor(ratio), 1, true, opacity, 2)
        if cfg.HealthText then
            local labelY = clamp(minY + height * (1 - ratio) - 6, minY - 2, maxY - 12)
            ESPDraw.text(data, "hpText", tostring(math.floor(humanoid.Health + 0.5)), Vector2.new(barX - 11, labelY), ESPDraw.white, 11, opacity)
        end
    end

    -- name above the box
    if cfg.Name then
        ESPDraw.text(data, "name", player.DisplayName or player.Name, Vector2.new(centerX, minY - cfg.TextSize - 4), ESPDraw.white, cfg.TextSize, opacity)
    end

    -- distance and weapon below the box
    local belowY = maxY + 3
    if cfg.Distance then
        ESPDraw.text(data, "dist", string.format("%dm", math.floor(distance + 0.5)), Vector2.new(centerX, belowY), ESPDraw.gray, cfg.TextSize - 2, opacity)
        belowY = belowY + cfg.TextSize
    end
    if cfg.Weapon then
        if clock - data.toolAt > 0.5 then
            data.toolAt = clock
            local tool = character:FindFirstChildOfClass("Tool")
            data.toolName = tool and tool.Name or nil
        end
        if data.toolName then
            ESPDraw.text(data, "weapon", data.toolName, Vector2.new(centerX, belowY), color, cfg.TextSize - 3, opacity)
        end
    end

    -- head circle
    if cfg.HeadDot then
        local head = getPart(character, "Head")
        local headScreen = head and projectPoint(head.Position)
        if headScreen then
            ESPDraw.circle(data, "head", headScreen, clamp(height * 0.07, 2.5, 10), color, 1.5, opacity)
        end
    end

    -- tracer to the feet
    if cfg.Tracers then
        local originY = viewport.Y
        if cfg.TracerOrigin == "Center" then originY = viewport.Y * 0.5
        elseif cfg.TracerOrigin == "Top" then originY = 0 end
        ESPDraw.line(data, "tracer", Vector2.new(viewport.X * 0.5, originY), Vector2.new(centerX, maxY), color, 1.2, opacity * 0.75, 2)
    end

    -- skeleton
    if cfg.Skeleton then
        local bones = getPart(character, "UpperTorso") and R15_BONES or R6_BONES
        local screens = {}
        local function boneScreen(partName)
            local cached = screens[partName]
            if cached ~= nil then return cached or nil end
            local part = getPart(character, partName)
            local screen = part and part:IsA("BasePart") and projectPoint(part.Position) or nil
            screens[partName] = screen or false
            return screen
        end
        for index, bone in ipairs(bones) do
            local from, to = boneScreen(bone[1]), boneScreen(bone[2])
            if from and to then
                ESPDraw.line(data, "b" .. index, from, to, color, cfg.SkeletonThickness, opacity, 2)
            end
        end
    end

    ESPDraw.finish(data)
end

local function updateESP()
    if not Config.ESP.Enabled then
        for _, data in pairs(State.esp) do hideESP(data) end
        return
    end

    local candidates = {}
    local cameraPosition = Camera.CFrame.Position
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local character, humanoid = getCharacter(player)
            local root = character and getRoot(character)
            if character and humanoid and root then
                local distance = (root.Position - cameraPosition).Magnitude
                if distance <= Config.ESP.MaxDistance then
                    candidates[#candidates + 1] = {
                        player = player,
                        character = character,
                        humanoid = humanoid,
                        root = root,
                        distance = distance,
                    }
                end
            end
        end
    end
    table.sort(candidates, function(a, b) return a.distance < b.distance end)
    local limit = math.min(#candidates, math.max(Config.ESP.MaxTargets or 16, 1))
    local shown = {}
    for index = 1, limit do
        local candidate = candidates[index]
        local player = candidate.player
        local data = State.esp[player]
        if not data then
            local ok, created = pcall(createESP, player)
            if ok then data = created end
        end
        if data then
            pcall(updateESPFor, player, data, candidate)
            shown[player] = true
        end
    end
    for player, data in pairs(State.esp) do
        if not shown[player] then hideESP(data) end
    end
end

local function getActiveFOV()
    if Config.Aimbot.Enabled then return Config.Aimbot.FOV end
    if Config.Silent.Enabled then return Config.Silent.FOV end
    return Config.Aimbot.FOV
end

local function updateFOV()
    local show = Config.Settings.ShowFOV and (Config.Aimbot.Enabled or Config.Silent.Enabled)
    local radius = getActiveFOV()
    local center = Camera.ViewportSize * 0.5
    if State.fovLastShow == show and State.fovLastRadius == radius
        and State.fovLastCenterX == center.X and State.fovLastCenterY == center.Y then
        return
    end
    State.fovLastShow = show
    State.fovLastRadius = radius
    State.fovLastCenterX = center.X
    State.fovLastCenterY = center.Y
    if State.fovDrawing then
        State.fovDrawing.Visible = show
        if show then
            State.fovDrawing.Position = center
            State.fovDrawing.Radius = radius
            State.fovDrawing.Color = Theme.accent
            State.fovDrawing.Thickness = 1
            State.fovDrawing.Transparency = 0.45
            State.fovDrawing.Filled = false
        end
    elseif State.fovRing then
        State.fovRing.Visible = show
        if show then
            State.fovRing.Size = UDim2.fromOffset(radius * 2, radius * 2)
            State.fovRing.Position = UDim2.fromOffset(center.X, center.Y)
        end
    end
end

local function updateAimbot(dt)
    if not Config.Aimbot.Enabled or not Camera then return end
    local visibleOnly = Config.Aimbot.VisibleOnly and not Config.Aimbot.Wallbang
    local aimPlayer, part = getBestTarget(Config.Aimbot.FOV, Config.Aimbot.MaxDistance, Config.Aimbot.TeamCheck, Config.Aimbot.Part, visibleOnly, Config.Aimbot.Priority)
    if not part or not part.Parent then return end
    if aimPlayer then State.engaged[aimPlayer] = os.clock() end
    local cameraPosition = Camera.CFrame.Position
    local direction = part.Position - cameraPosition
    if direction.Magnitude < 0.01 then return end
    local desired = direction.Unit
    local current = Camera.CFrame.LookVector
    local smooth = 1 - (Config.Aimbot.Smoothness / 100) * 0.95
    local alpha = 1 - math.exp(-Config.Aimbot.Speed * smooth * dt * 2)
    alpha = clamp(alpha, 0.005, 1)
    local newLook = current:Lerp(desired, alpha)
    if newLook.Magnitude < 0.001 then return end
    Camera.CFrame = CFrame.lookAt(cameraPosition, cameraPosition + newLook.Unit)
end

local function updateSilentTarget()
    if not Config.Silent.Enabled then
        State.silentTarget = nil
        State.silentTargetPlayer = nil
        State.silentScreen = nil
        State.silentVisible = false
        State.silentLOS = false
        return
    end
    local player, part, screen = getBestTarget(Config.Silent.FOV, Config.Silent.MaxDistance, Config.Silent.TeamCheck and not Config.Settings.Deathmatch, Config.Silent.Part, false, "Crosshair")
    State.silentTargetPlayer = player
    State.silentTarget = part
    if player then State.engaged[player] = os.clock() end
    State.silentScreen = screen
    State.silentVisible = true
    State.silentLOS = false
    if player and part then
        if Config.Silent.Wallbang then
            State.silentLOS = true
        else
            local character = player.Character
            State.silentLOS = character ~= nil and hasLineOfSight(character, part)
            if Config.Silent.ShowTarget then State.silentVisible = State.silentLOS end
        end
    end
end

local function updateSilentMarker()
    if not State.silentMarker then return end
    local show = Config.Silent.Enabled and Config.Silent.ShowTarget and State.silentScreen ~= nil and State.silentVisible
    State.silentMarker.Visible = show
    if show then
        State.silentMarker.Position = State.silentScreen
        State.silentMarker.Radius = 7
        State.silentMarker.Color = Color3.fromRGB(255, 220, 80)
        State.silentMarker.Thickness = 1.5
        State.silentMarker.Transparency = 0.2
        State.silentMarker.Filled = false
    end
end

local function captureDefaults()
    local _, humanoid = getCharacter(LocalPlayer)
    if humanoid then
        if humanoid.WalkSpeed > 0 then State.defaultWalkSpeed = humanoid.WalkSpeed end
        if humanoid.JumpPower > 0 then State.defaultJumpPower = humanoid.JumpPower end
        if humanoid.JumpHeight > 0 then State.defaultJumpHeight = humanoid.JumpHeight end
        State.defaultUseJumpPower = humanoid.UseJumpPower
    end
end

local function applyMovementSettings()
    local _, humanoid = getCharacter(LocalPlayer)
    if not humanoid then return end
    if Config.Movement.JumpEnabled then
        humanoid.UseJumpPower = true
        if math.abs(humanoid.JumpPower - Config.Movement.JumpPower) > 0.01 then
            humanoid.JumpPower = Config.Movement.JumpPower
        end
        State.jumpApplied = true
    elseif State.jumpApplied then
        humanoid.UseJumpPower = State.defaultUseJumpPower
        if State.defaultUseJumpPower then
            humanoid.JumpPower = State.defaultJumpPower
        else
            humanoid.JumpHeight = State.defaultJumpHeight
        end
        State.jumpApplied = false
    end
end

local function setNoclip(enabled)
    local character = getCharacter(LocalPlayer)
    if enabled then
        State.noclipWasOn = true
        if character then
            for _, part in ipairs(character:GetDescendants()) do
                if part:IsA("BasePart") then
                    local original = part.CanCollide
                    if State.noclipOriginal[part] == nil then
                        State.noclipOriginal[part] = original
                    end
                    if original then
                        part.CanCollide = false
                    end
                end
            end
        end
    else
        State.noclipWasOn = false
        if character then
            for _, part in ipairs(character:GetDescendants()) do
                if part:IsA("BasePart") then
                    local original = State.noclipOriginal[part]
                    if original ~= nil then
                        part.CanCollide = original
                    end
                end
            end
        end
        State.noclipOriginal = {}
    end
end

local function stopFly()
    if State.flyVelocity then
        pcall(function() State.flyVelocity:Destroy() end)
        State.flyVelocity = nil
    end
end

local function startFly()
    local character = getCharacter(LocalPlayer)
    if not character then return end
    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    stopFly()
    local velocity = Instance.new("BodyVelocity")
    velocity.Name = "4080_Fly"
    velocity.MaxForce = Vector3.new(100000, 100000, 100000)
    velocity.P = 1250
    velocity.Velocity = Vector3.zero
    velocity.Parent = root
    State.flyVelocity = velocity
end

local function updateFly()
    if not Config.Movement.FlyEnabled then
        if State.flyVelocity then stopFly() end
        return
    end
    if not State.flyVelocity then startFly() end
    local character, humanoid = getCharacter(LocalPlayer)
    if not character or not humanoid then stopFly(); return end
    local root = character:FindFirstChild("HumanoidRootPart")
    if not root or not State.flyVelocity or State.flyVelocity.Parent ~= root then startFly(); return end
    local move = humanoid.MoveDirection
    local horizontal = Vector3.new(move.X, 0, move.Z)
    if horizontal.Magnitude > 0 then
        horizontal = horizontal.Unit * Config.Movement.FlySpeed
    end
    local vertical = 0
    if State.flyUp then vertical = vertical + 1 end
    if State.flyDown then vertical = vertical - 1 end
    State.flyVelocity.Velocity = horizontal + Vector3.new(0, vertical * Config.Movement.FlySpeed, 0)
end

local SPEED_MODES = { "Velocity", "WalkSpeed", "CFrame" }
local BHOP_MODES = { "Hold Jump", "Always" }

-- Speed hack. Runs every Heartbeat (not every 0.25 s like before), so the game cannot fight it between ticks.
--  Velocity : sets the horizontal velocity directly (works even if the game keeps resetting WalkSpeed)
--  WalkSpeed: sets Humanoid.WalkSpeed every frame
--  CFrame   : adds the missing distance by moving the root
local function updateSpeed(dt)
    local cfg = Config.Movement
    local character, humanoid = getCharacter(LocalPlayer)
    if not character or not humanoid then return end

    local wantWalkSpeed = cfg.SpeedEnabled and cfg.SpeedMode == "WalkSpeed"
    if wantWalkSpeed then
        if humanoid.WalkSpeed ~= cfg.Speed then humanoid.WalkSpeed = cfg.Speed end
        State.speedApplied = true
    elseif State.speedApplied then
        humanoid.WalkSpeed = State.defaultWalkSpeed
        State.speedApplied = false
    end

    if not cfg.SpeedEnabled or cfg.SpeedMode == "WalkSpeed" then
        State.speedBoosting = false
        return
    end
    local root = getRoot(character)
    if not root then return end
    local move = humanoid.MoveDirection
    local flat = Vector3.new(move.X, 0, move.Z)
    if flat.Magnitude < 0.05 then
        if State.speedBoosting and cfg.SpeedMode == "Velocity" and humanoid.FloorMaterial ~= Enum.Material.Air then
            local velocity = root.AssemblyLinearVelocity
            root.AssemblyLinearVelocity = Vector3.new(0, velocity.Y, 0)
        end
        State.speedBoosting = false
        return
    end
    local direction = flat.Unit
    State.speedBoosting = true
    if cfg.SpeedMode == "Velocity" then
        local velocity = root.AssemblyLinearVelocity
        root.AssemblyLinearVelocity = Vector3.new(direction.X * cfg.Speed, velocity.Y, direction.Z * cfg.Speed)
    else
        local extra = math.max(cfg.Speed - humanoid.WalkSpeed, 0)
        if extra > 0 then
            root.CFrame = root.CFrame + direction * (extra * dt)
        end
    end
end

-- Bunny hop: jumps again the instant you touch the ground and keeps (and slowly builds) horizontal speed in the air.
local function updateBhop(dt)
    local cfg = Config.Movement
    if not cfg.Bhop then
        State.bhopSpeed = nil
        return
    end
    local character, humanoid = getCharacter(LocalPlayer)
    if not character or not humanoid then return end
    local root = getRoot(character)
    if not root then return end

    local move = humanoid.MoveDirection
    local flat = Vector3.new(move.X, 0, move.Z)
    local moving = flat.Magnitude > 0.1
    local held = humanoid.Jump
        or State.jumpHeldUntil > os.clock()
        or UserInputService:IsKeyDown(Enum.KeyCode.Space)
    local wants = (cfg.BhopMode == "Always" and moving) or (cfg.BhopMode ~= "Always" and held)
    local grounded = humanoid.FloorMaterial ~= Enum.Material.Air

    if grounded then
        if wants and moving then
            local base = cfg.SpeedEnabled and cfg.Speed or humanoid.WalkSpeed
            State.bhopSpeed = math.min(math.max(State.bhopSpeed or base, base) + cfg.BhopGain, cfg.BhopMax)
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            local direction = flat.Unit
            local velocity = root.AssemblyLinearVelocity
            root.AssemblyLinearVelocity = Vector3.new(direction.X * State.bhopSpeed, velocity.Y, direction.Z * State.bhopSpeed)
        elseif wants then
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            State.bhopSpeed = nil
        else
            State.bhopSpeed = nil
        end
    elseif State.bhopSpeed and moving then
        local direction = flat.Unit
        local velocity = root.AssemblyLinearVelocity
        root.AssemblyLinearVelocity = Vector3.new(direction.X * State.bhopSpeed, velocity.Y, direction.Z * State.bhopSpeed)
    end
end

local function updateMovement(dt)
    if State.unloaded then return end
    State.movementAccum = State.movementAccum + dt
    if State.movementAccum >= 0.25 then
        State.movementAccum = 0
        applyMovementSettings()
        if Config.Movement.Noclip ~= State.noclipWasOn then
            setNoclip(Config.Movement.Noclip)
        end
    end
    if Config.Movement.Noclip then
        State.noclipAccum = State.noclipAccum + dt
        if State.noclipAccum >= 0.25 then
            State.noclipAccum = 0
            setNoclip(true)
        end
    end
    updateSpeed(dt)
    updateBhop(dt)
    updateFly()
end

-- ===================== Anti-Aim =====================
local AA_TYPES = { "None", "Spin", "Jitter", "Backwards", "Sideways", "Random", "Sway", "Desync", "At Target" }
local AA_OFFSET_MODES = { "Off", "Right", "Left", "Flip", "Jitter" }
local AA_PITCH = { "Off", "Down", "Up", "Jitter", "Random" }

State.joints = nil
State.rootModified = false
State.neckModified = false
State.aaTime = 0
State.aaYaw = 0
State.aaRandomTick = -1
State.aaRandomYaw = 0
State.aaPitchTick = -1
State.aaPitchRandom = 0
State.aaRootC0 = nil
State.aaNeckC0 = nil
State.aaTargetPos = nil
State.aaTargetAccum = 0

-- Finds the joint that carries the root (HumanoidRootPart -> torso) and the neck (torso -> Head)
-- by looking at which parts they connect, so custom rigs with odd joint names work too.
local function findJoints(character)
    local hrp = character:FindFirstChild("HumanoidRootPart")
    local head = character:FindFirstChild("Head")
    local root, neck
    local function direct(part)
        return part ~= nil and part.Parent == character
    end
    for pass = 1, 2 do
        for _, descendant in ipairs(character:GetDescendants()) do
            local isJoint = (pass == 1 and descendant:IsA("Motor6D")) or (pass == 2 and descendant:IsA("JointInstance"))
            if isJoint and direct(descendant.Part0) and direct(descendant.Part1) then
                if not root and hrp and descendant.Part0 == hrp then root = descendant end
                if not neck and head and descendant.Part1 == head then neck = descendant end
            end
        end
        if root and neck then break end
    end
    return root, neck
end

local function getJoints(character)
    local cache = State.joints
    if cache and cache.character == character then
        if cache.none then
            if os.clock() < cache.retryAt then return nil end
        elseif (not cache.root or cache.root.Parent) and (not cache.neck or cache.neck.Parent) then
            return cache
        end
    end
    local root, neck = findJoints(character)
    if not root and not neck then
        State.joints = { character = character, none = true, retryAt = os.clock() + 1 }
        return nil
    end
    cache = {
        character = character,
        root = root,
        rootC0 = root and root.C0 or nil,
        neck = neck,
        neckC0 = neck and neck.C0 or nil,
        r15 = character:FindFirstChild("UpperTorso") ~= nil,
    }
    State.joints = cache
    State.rootModified = false
    State.neckModified = false
    return cache
end

local function wrapAngle(angle)
    return (angle + math.pi) % (math.pi * 2) - math.pi
end

local function nearestEnemyPosition(origin)
    local bestPosition, bestDistance = nil, math.huge
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local character, humanoid = getCharacter(player)
            if character and humanoid and humanoid.Health > 0 then
                local isAlly = false
                if not Config.Settings.Deathmatch then
                    isAlly = resolveTeam(player) == true
                end
                if not isAlly then
                    local root = getRoot(character)
                    if root then
                        local distance = (root.Position - origin).Magnitude
                        if distance < bestDistance then
                            bestDistance = distance
                            bestPosition = root.Position
                        end
                    end
                end
            end
        end
    end
    return bestPosition
end

local function flip(rate)
    return (math.floor(State.aaTime * rate) % 2 == 0) and 1 or -1
end

local function aaYaw(dt, hrp)
    local aa = Config.AntiAim
    local kind = aa.Type
    local yaw = 0
    if kind == "Spin" then
        State.aaYaw = (State.aaYaw + math.rad(aa.Speed) * dt) % (math.pi * 2)
        yaw = State.aaYaw
    elseif kind == "Jitter" then
        yaw = flip(aa.Rate) * math.rad(aa.Angle)
    elseif kind == "Backwards" then
        yaw = math.pi
    elseif kind == "Sideways" then
        yaw = flip(2) * math.rad(90)
    elseif kind == "Random" then
        local step = math.floor(State.aaTime * aa.Rate)
        if step ~= State.aaRandomTick then
            State.aaRandomTick = step
            State.aaRandomYaw = math.rad(math.random(-180, 180))
        end
        yaw = State.aaRandomYaw
    elseif kind == "Sway" then
        yaw = math.sin(State.aaTime * aa.Speed / 180) * math.rad(aa.Angle)
    elseif kind == "Desync" then
        yaw = math.pi + flip(aa.Rate) * math.rad(aa.Angle) * 0.5
    elseif kind == "At Target" then
        -- always keep the back turned to the nearest enemy (with a small jitter on top)
        local target = State.aaTargetPos
        yaw = math.pi
        if target and hrp then
            local away = hrp.Position - target
            local flat = Vector3.new(away.X, 0, away.Z)
            if flat.Magnitude > 0.1 then
                local desired = math.atan2(-flat.X, -flat.Z)
                local look = hrp.CFrame.LookVector
                local current = math.atan2(-look.X, -look.Z)
                yaw = wrapAngle(desired - current) + flip(aa.Rate) * math.rad(aa.Angle) * 0.35
            end
        end
    end
    return yaw + math.rad(aa.Offset)
end

local function aaPitchValue()
    local aa = Config.AntiAim
    local amount = math.rad(aa.PitchAngle)
    local mode = aa.Pitch
    if mode == "Down" then return -amount end
    if mode == "Up" then return amount end
    if mode == "Jitter" then return flip(aa.Rate) * amount end
    if mode == "Random" then
        local step = math.floor(State.aaTime * aa.Rate)
        if step ~= State.aaPitchTick then
            State.aaPitchTick = step
            State.aaPitchRandom = (math.random() * 2 - 1) * amount
        end
        return State.aaPitchRandom
    end
    return 0
end

State.aaOffsetTick = -1
State.aaOffsetValue = 0

-- Moves the whole body sideways relative to the root part (HumanoidRootPart), in studs.
local function aaOffsetVector()
    local aa = Config.AntiAim
    local mode = aa.OffsetMode
    local studs = aa.OffsetStuds
    if mode == "Right" then
        return Vector3.new(studs, 0, 0)
    elseif mode == "Left" then
        return Vector3.new(-studs, 0, 0)
    elseif mode == "Flip" then
        return Vector3.new(flip(aa.OffsetRate) * studs, 0, 0)
    elseif mode == "Jitter" then
        local step = math.floor(State.aaTime * aa.OffsetRate)
        if step ~= State.aaOffsetTick then
            State.aaOffsetTick = step
            State.aaOffsetValue = (math.random() * 2 - 1) * studs
        end
        return Vector3.new(State.aaOffsetValue, 0, 0)
    end
    return Vector3.new(0, 0, 0)
end

-- Turns the body (root joint) and tilts the head (neck joint). Only C0 is touched and the original is always restored.
local function updateBodyJoints(dt)
    local aa = Config.AntiAim
    local wantRoot = aa.Enabled
    local wantPitch = aa.Enabled and aa.Pitch ~= "Off"
    if not (wantRoot or wantPitch or State.rootModified or State.neckModified) then return end
    local character = LocalPlayer.Character
    if not character then return end
    local joints = getJoints(character)
    if not joints then return end
    State.aaTime = State.aaTime + dt
    local hrp = character:FindFirstChild("HumanoidRootPart")

    if wantRoot and aa.Type == "At Target" then
        State.aaTargetAccum = State.aaTargetAccum + dt
        if State.aaTargetAccum >= 0.1 or not State.aaTargetPos then
            State.aaTargetAccum = 0
            if hrp then State.aaTargetPos = nearestEnemyPosition(hrp.Position) end
        end
    end

    if joints.root then
        if wantRoot then
            State.aaRootC0 = CFrame.new(aaOffsetVector()) * CFrame.Angles(0, aaYaw(dt, hrp), 0) * joints.rootC0
            joints.root.C0 = State.aaRootC0
            State.rootModified = true
        elseif State.rootModified then
            joints.root.C0 = joints.rootC0
            State.rootModified = false
            State.aaRootC0 = nil
        end
    end

    if joints.neck then
        if wantPitch then
            -- rotate around the neck pivot; the sign differs between R15 and R6 because their neck axes differ
            local sign = joints.r15 and 1 or -1
            State.aaNeckC0 = joints.neckC0 * CFrame.Angles(sign * aaPitchValue(), 0, 0)
            joints.neck.C0 = State.aaNeckC0
            State.neckModified = true
        elseif State.neckModified then
            joints.neck.C0 = joints.neckC0
            State.neckModified = false
            State.aaNeckC0 = nil
        end
    end
end

-- Games / animations may rewrite the joints between our update and the physics step,
-- so the last computed values are written again at the very end of the render step, on Stepped and on Heartbeat.
local function reapplyBodyJoints()
    if not (State.rootModified or State.neckModified) then return end
    local joints = State.joints
    if not joints or joints.none or joints.character ~= LocalPlayer.Character then return end
    if joints.root and State.rootModified and State.aaRootC0 and joints.root.Parent then
        joints.root.C0 = State.aaRootC0
    end
    if joints.neck and State.neckModified and State.aaNeckC0 and joints.neck.Parent then
        joints.neck.C0 = State.aaNeckC0
    end
end

-- ===================== Notifications + GUI building blocks (OpenCode-style dark UI) =====================
local FONT = Enum.Font.GothamMedium
local FONT_BOLD = Enum.Font.GothamBold
local FONT_CODE = Enum.Font.Code
local FONT_PIXEL = Enum.Font.Arcade

local function tween(object, duration, properties, style, direction)
    local info = TweenInfo.new(duration, style or Enum.EasingStyle.Quint, direction or Enum.EasingDirection.Out)
    local playing = TweenService:Create(object, info, properties)
    playing:Play()
    return playing
end

local function notify(text, color)
    if not State.gui then
        print("[4080] " .. tostring(text))
        return
    end
    if State.lastNotify then
        pcall(function() State.lastNotify:Destroy() end)
    end
    local frame = Instance.new("Frame")
    frame.Size = UDim2.fromOffset(320, 40)
    frame.Position = UDim2.new(0.5, 0, 0, 14)
    frame.AnchorPoint = Vector2.new(0.5, 0)
    frame.BackgroundColor3 = Theme.popup
    frame.BackgroundTransparency = 1
    frame.BorderSizePixel = 0
    frame.ZIndex = 200
    frame.Parent = State.gui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 14)
    corner.Parent = frame

    local stroke = Instance.new("UIStroke")
    stroke.Color = Theme.border
    stroke.Thickness = 1
    stroke.Transparency = 1
    stroke.Parent = frame

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -24, 1, 0)
    label.Position = UDim2.fromOffset(12, 0)
    label.BackgroundTransparency = 1
    label.Text = tostring(text)
    label.TextColor3 = color or Theme.text
    label.TextTransparency = 1
    label.TextSize = 14
    label.Font = FONT
    label.TextWrapped = true
    label.ZIndex = 201
    label.Parent = frame

    State.lastNotify = frame
    tween(frame, 0.35, { Position = UDim2.new(0.5, 0, 0, 46), BackgroundTransparency = 0 }, Enum.EasingStyle.Back)
    tween(stroke, 0.3, { Transparency = 0 })
    tween(label, 0.3, { TextTransparency = 0 })
    task.delay(3, function()
        if not frame or not frame.Parent then return end
        tween(frame, 0.3, { Position = UDim2.new(0.5, 0, 0, 24), BackgroundTransparency = 1 })
        tween(label, 0.3, { TextTransparency = 1 })
        local fade = tween(stroke, 0.3, { Transparency = 1 })
        fade.Completed:Connect(function()
            if frame then frame:Destroy() end
        end)
    end)
end

local layoutOrder = 0
local function nextOrder()
    layoutOrder = layoutOrder + 1
    return layoutOrder
end

local function addCorner(object, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 10)
    corner.Parent = object
    return corner
end

local function addStroke(object, color, thickness, transparency)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color or Theme.border
    stroke.Thickness = thickness or 1
    stroke.Transparency = transparency or 0
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = object
    return stroke
end

local function addList(parent, padding)
    local list = Instance.new("UIListLayout")
    list.Padding = UDim.new(0, padding or 8)
    list.SortOrder = Enum.SortOrder.LayoutOrder
    list.Parent = parent
    return list
end

local function addPadding(parent, all)
    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, all or 10)
    padding.PaddingBottom = UDim.new(0, all or 10)
    padding.PaddingLeft = UDim.new(0, all or 10)
    padding.PaddingRight = UDim.new(0, all or 10)
    padding.Parent = parent
    return padding
end

local function styleCard(row)
    row.BackgroundColor3 = Theme.row
    row.BackgroundTransparency = 0
    row.BorderSizePixel = 0
    addCorner(row, 14)
    addStroke(row, Theme.border, 1, 0)
end

local function isPress(input)
    return input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1
end

-- little "squish" animation on press / release
local function pressable(button, depth)
    local scale = Instance.new("UIScale")
    scale.Parent = button
    button.InputBegan:Connect(function(input)
        if isPress(input) then tween(scale, 0.08, { Scale = depth or 0.95 }) end
    end)
    button.InputEnded:Connect(function(input)
        if isPress(input) then tween(scale, 0.22, { Scale = 1 }, Enum.EasingStyle.Back) end
    end)
    return scale
end

local function makeLabel(parent, text, height, color, bold, textSize)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, height or 20)
    label.BackgroundTransparency = 1
    label.Text = tostring(text)
    label.TextColor3 = color or Theme.text
    label.TextSize = textSize or 13
    label.Font = bold and FONT_BOLD or FONT
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.TextWrapped = true
    label.Active = false
    label.LayoutOrder = nextOrder()
    label.Parent = parent
    return label
end

-- group header, like "OpenCode" in the model list
local function makeSection(parent, text)
    local label = makeLabel(parent, text, 26, Theme.muted, false, 13)
    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 6)
    padding.PaddingTop = UDim.new(0, 8)
    padding.Parent = label
    return label
end

-- ---- icons drawn from plain frames (no asset ids needed) ----
local function iconBar(parent, x, y, w, h, rotation, color, radius)
    local bar = Instance.new("Frame")
    bar.AnchorPoint = Vector2.new(0.5, 0.5)
    bar.Size = UDim2.fromOffset(w, h)
    bar.Position = UDim2.fromOffset(x, y)
    bar.Rotation = rotation or 0
    bar.BackgroundColor3 = color
    bar.BorderSizePixel = 0
    bar.Active = false
    bar.Parent = parent
    addCorner(bar, radius or 1)
    return bar
end

local function iconBox(parent, x, y, w, h, color, thickness, radius)
    local box = Instance.new("Frame")
    box.Size = UDim2.fromOffset(w, h)
    box.Position = UDim2.fromOffset(x, y)
    box.BackgroundTransparency = 1
    box.BorderSizePixel = 0
    box.Active = false
    box.Parent = parent
    addCorner(box, radius or 3)
    addStroke(box, color, thickness or 1.5, 0)
    return box
end

local function iconHolder(parent, size, position, anchor)
    local holder = Instance.new("Frame")
    holder.Size = UDim2.fromOffset(size.X, size.Y)
    holder.Position = position or UDim2.new()
    holder.AnchorPoint = anchor or Vector2.new(0, 0)
    holder.BackgroundTransparency = 1
    holder.BorderSizePixel = 0
    holder.Active = false
    holder.Parent = parent
    return holder
end

local function makeChevron(parent, position, color, anchor)
    local holder = iconHolder(parent, Vector2.new(12, 8), position, anchor or Vector2.new(0.5, 0.5))
    iconBar(holder, 3, 4, 8, 2, 40, color)
    iconBar(holder, 9, 4, 8, 2, -40, color)
    return holder
end

local function makeSlidersIcon(parent, position, color)
    local holder = iconHolder(parent, Vector2.new(22, 20), position, Vector2.new(0.5, 0.5))
    local rows = { { 4, 15 }, { 10, 6 }, { 16, 14 } }
    for _, row in ipairs(rows) do
        iconBar(holder, 11, row[1], 20, 2, 0, color)
        local knob = Instance.new("Frame")
        knob.Size = UDim2.fromOffset(7, 7)
        knob.AnchorPoint = Vector2.new(0.5, 0.5)
        knob.Position = UDim2.fromOffset(row[2], row[1])
        knob.BackgroundColor3 = Theme.row
        knob.BorderSizePixel = 0
        knob.Active = false
        knob.Parent = holder
        addCorner(knob, 4)
        addStroke(knob, color, 1.6, 0)
    end
    return holder
end

local function makeSearchIcon(parent, position, color)
    local holder = iconHolder(parent, Vector2.new(18, 18), position, Vector2.new(0.5, 0.5))
    local ring = Instance.new("Frame")
    ring.Size = UDim2.fromOffset(11, 11)
    ring.Position = UDim2.fromOffset(1, 1)
    ring.BackgroundTransparency = 1
    ring.BorderSizePixel = 0
    ring.Active = false
    ring.Parent = holder
    addCorner(ring, 6)
    addStroke(ring, color, 1.6, 0)
    iconBar(holder, 14, 14, 6, 2, 45, color)
    return holder
end

-- ---- popup picker (model list / effort picker in the reference) ----
local function closeDropdown()
    local dropdown = State.dropdown
    if not dropdown then return end
    State.dropdown = nil
    pcall(function()
        tween(dropdown.scale, 0.12, { Scale = 0.94 })
        tween(dropdown.popup, 0.12, { BackgroundTransparency = 1 })
    end)
    task.delay(0.12, function()
        pcall(function() dropdown.catcher:Destroy() end)
    end)
end

-- spec: { items = { {header=} | {text=, chip=, color=, checked=, onTap=} }, width, alignLeft, preferAbove,
--         search = bool, searchPlaceholder, footer = { text, onTap } }
local function openPicker(anchor, spec)
    closeDropdown()
    local main = State.main
    if not main then return end
    local uiScale = State.guiScale and State.guiScale.Scale or 1
    local items = spec.items or {}
    local width = spec.width or 230
    local searchHeight = spec.search and 56 or 0
    local footerHeight = spec.footer and 52 or 0

    local contentHeight = 0
    for _, item in ipairs(items) do
        contentHeight = contentHeight + (item.header and 32 or 42)
    end
    local listHeight = math.min(contentHeight, spec.maxHeight or 230) + 10
    local height = searchHeight + footerHeight + listHeight

    local catcher = Instance.new("TextButton")
    catcher.Name = "DropdownCatcher"
    catcher.Size = UDim2.fromScale(1, 1)
    catcher.BackgroundTransparency = 1
    catcher.Text = ""
    catcher.AutoButtonColor = false
    catcher.ZIndex = 100
    catcher.Parent = main
    catcher.Activated:Connect(closeDropdown)

    local popup = Instance.new("Frame")
    popup.Size = UDim2.fromOffset(width, height)
    popup.BackgroundColor3 = Theme.popup
    popup.BackgroundTransparency = 1
    popup.BorderSizePixel = 0
    popup.Active = true
    popup.ZIndex = 101
    popup.Parent = catcher
    addCorner(popup, 18)
    addStroke(popup, Theme.border, 1, 0)

    local popupScale = Instance.new("UIScale")
    popupScale.Scale = 0.9
    popupScale.Parent = popup

    State.dropdown = { catcher = catcher, popup = popup, scale = popupScale }

    local mainPosition = main.AbsolutePosition
    local anchorPosition = anchor.AbsolutePosition
    local anchorSize = anchor.AbsoluteSize
    local mainWidth = main.AbsoluteSize.X / uiScale
    local mainHeight = main.AbsoluteSize.Y / uiScale
    local anchorLeft = (anchorPosition.X - mainPosition.X) / uiScale
    local anchorRight = anchorLeft + anchorSize.X / uiScale
    local anchorTop = (anchorPosition.Y - mainPosition.Y) / uiScale
    local anchorBottom = anchorTop + anchorSize.Y / uiScale
    local x = spec.alignLeft and anchorLeft or (anchorRight - width)
    local above = anchorTop - height - 8
    local below = anchorBottom + 8
    local y
    if spec.preferAbove then
        y = (above >= 8) and above or below
    else
        y = (below + height <= mainHeight - 8) and below or above
    end
    x = clamp(x, 8, math.max(8, mainWidth - width - 8))
    y = clamp(y, 8, math.max(8, mainHeight - height - 8))
    popup.Position = UDim2.fromOffset(x, y)

    local list = Instance.new("ScrollingFrame")
    list.Position = UDim2.fromOffset(6, searchHeight + 5)
    list.Size = UDim2.new(1, -12, 0, listHeight - 10)
    list.BackgroundTransparency = 1
    list.BorderSizePixel = 0
    list.ScrollBarThickness = 0
    list.CanvasSize = UDim2.new(0, 0, 0, 0)
    list.AutomaticCanvasSize = Enum.AutomaticSize.Y
    list.ScrollingDirection = Enum.ScrollingDirection.Y
    list.ZIndex = 102
    list.Parent = popup
    local listLayout = Instance.new("UIListLayout")
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Parent = list

    local function populate(filter)
        for _, child in ipairs(list:GetChildren()) do
            if child:IsA("GuiObject") then child:Destroy() end
        end
        local shown = 0
        local hasFilter = filter ~= nil and filter ~= ""
        for index, item in ipairs(items) do
            if item.header then
                if not hasFilter then
                    local header = Instance.new("TextLabel")
                    header.Size = UDim2.new(1, 0, 0, 32)
                    header.BackgroundTransparency = 1
                    header.Text = tostring(item.header)
                    header.TextColor3 = Theme.muted
                    header.TextSize = 14
                    header.Font = FONT
                    header.TextXAlignment = Enum.TextXAlignment.Left
                    header.LayoutOrder = index
                    header.ZIndex = 103
                    header.Parent = list
                    local headerPadding = Instance.new("UIPadding")
                    headerPadding.PaddingLeft = UDim.new(0, 12)
                    headerPadding.PaddingTop = UDim.new(0, 8)
                    headerPadding.Parent = header
                end
            elseif not hasFilter or string.find(string.lower(tostring(item.text)), filter, 1, true) then
                shown = shown + 1
                local button = Instance.new("TextButton")
                button.Size = UDim2.new(1, 0, 0, 42)
                button.BackgroundColor3 = Color3.fromRGB(58, 58, 62)
                button.BackgroundTransparency = 1
                button.Text = ""
                button.AutoButtonColor = false
                button.LayoutOrder = index
                button.ZIndex = 103
                button.Parent = list
                addCorner(button, 11)

                local inner = Instance.new("Frame")
                inner.Size = UDim2.new(1, -46, 1, 0)
                inner.Position = UDim2.fromOffset(12, 0)
                inner.BackgroundTransparency = 1
                inner.Active = false
                inner.ZIndex = 104
                inner.Parent = button
                local innerLayout = Instance.new("UIListLayout")
                innerLayout.FillDirection = Enum.FillDirection.Horizontal
                innerLayout.Padding = UDim.new(0, 10)
                innerLayout.SortOrder = Enum.SortOrder.LayoutOrder
                innerLayout.VerticalAlignment = Enum.VerticalAlignment.Center
                innerLayout.Parent = inner

                if item.color then
                    local dot = Instance.new("Frame")
                    dot.Size = UDim2.fromOffset(12, 12)
                    dot.BackgroundColor3 = item.color
                    dot.BorderSizePixel = 0
                    dot.Active = false
                    dot.LayoutOrder = 1
                    dot.ZIndex = 105
                    dot.Parent = inner
                    addCorner(dot, 6)
                end

                local label = Instance.new("TextLabel")
                label.Size = UDim2.fromOffset(0, 42)
                label.AutomaticSize = Enum.AutomaticSize.X
                label.BackgroundTransparency = 1
                label.Text = tostring(item.text)
                label.TextColor3 = item.checked and Theme.accent or Theme.text
                label.TextTransparency = 1
                label.TextSize = 17
                label.Font = FONT
                label.LayoutOrder = 2
                label.ZIndex = 105
                label.Parent = inner

                if item.chip then
                    local chip = Instance.new("TextLabel")
                    chip.Size = UDim2.fromOffset(0, 22)
                    chip.AutomaticSize = Enum.AutomaticSize.X
                    chip.BackgroundTransparency = 1
                    chip.Text = tostring(item.chip)
                    chip.TextColor3 = Theme.muted
                    chip.TextSize = 12
                    chip.Font = FONT
                    chip.LayoutOrder = 3
                    chip.ZIndex = 105
                    chip.Parent = inner
                    addCorner(chip, 7)
                    addStroke(chip, Color3.fromRGB(62, 62, 66), 1, 0)
                    local chipPadding = Instance.new("UIPadding")
                    chipPadding.PaddingLeft = UDim.new(0, 8)
                    chipPadding.PaddingRight = UDim.new(0, 8)
                    chipPadding.Parent = chip
                end

                if item.checked then
                    local check = Instance.new("TextLabel")
                    check.Size = UDim2.fromOffset(24, 42)
                    check.Position = UDim2.new(1, -32, 0, 0)
                    check.BackgroundTransparency = 1
                    check.Text = "✓"
                    check.TextColor3 = Theme.accent
                    check.TextSize = 18
                    check.Font = FONT_BOLD
                    check.ZIndex = 105
                    check.Parent = button
                end

                -- staggered fade-in of the rows
                task.delay(shown * 0.025, function()
                    if label and label.Parent then tween(label, 0.2, { TextTransparency = 0 }) end
                end)

                button.InputBegan:Connect(function(input)
                    if isPress(input) then tween(button, 0.08, { BackgroundTransparency = 0.45 }) end
                end)
                button.InputEnded:Connect(function(input)
                    if isPress(input) then tween(button, 0.2, { BackgroundTransparency = 1 }) end
                end)
                button.Activated:Connect(function()
                    closeDropdown()
                    if item.onTap then item.onTap() end
                end)
            end
        end
    end
    populate("")

    if spec.search then
        local searchIcon = makeSearchIcon(popup, UDim2.fromOffset(26, 28), Theme.muted)
        searchIcon.ZIndex = 102
        local box = Instance.new("TextBox")
        box.Size = UDim2.new(1, -62, 0, 40)
        box.Position = UDim2.fromOffset(46, 8)
        box.BackgroundTransparency = 1
        box.Text = ""
        box.PlaceholderText = spec.searchPlaceholder or "Поиск"
        box.PlaceholderColor3 = Theme.muted
        box.TextColor3 = Theme.text
        box.TextSize = 18
        box.Font = FONT
        box.TextXAlignment = Enum.TextXAlignment.Left
        box.ClearTextOnFocus = false
        box.ZIndex = 102
        box.Parent = popup
        local divider = Instance.new("Frame")
        divider.Size = UDim2.new(1, 0, 0, 1)
        divider.Position = UDim2.fromOffset(0, 55)
        divider.BackgroundColor3 = Theme.border
        divider.BorderSizePixel = 0
        divider.ZIndex = 102
        divider.Parent = popup
        box:GetPropertyChangedSignal("Text"):Connect(function()
            populate(string.lower(box.Text))
        end)
    end

    if spec.footer then
        local divider = Instance.new("Frame")
        divider.Size = UDim2.new(1, 0, 0, 1)
        divider.Position = UDim2.new(0, 0, 1, -footerHeight)
        divider.BackgroundColor3 = Theme.border
        divider.BorderSizePixel = 0
        divider.ZIndex = 102
        divider.Parent = popup
        local footer = Instance.new("TextButton")
        footer.Size = UDim2.new(1, 0, 0, footerHeight)
        footer.Position = UDim2.new(0, 0, 1, -footerHeight)
        footer.BackgroundTransparency = 1
        footer.Text = ""
        footer.AutoButtonColor = false
        footer.ZIndex = 102
        footer.Parent = popup
        makeSlidersIcon(footer, UDim2.fromOffset(30, footerHeight / 2), Theme.text).ZIndex = 103
        local footerLabel = Instance.new("TextLabel")
        footerLabel.Size = UDim2.new(1, -64, 1, 0)
        footerLabel.Position = UDim2.fromOffset(52, 0)
        footerLabel.BackgroundTransparency = 1
        footerLabel.Text = tostring(spec.footer.text)
        footerLabel.TextColor3 = Theme.text
        footerLabel.TextSize = 17
        footerLabel.Font = FONT
        footerLabel.TextXAlignment = Enum.TextXAlignment.Left
        footerLabel.ZIndex = 103
        footerLabel.Parent = footer
        footer.Activated:Connect(function()
            closeDropdown()
            if spec.footer.onTap then spec.footer.onTap() end
        end)
    end

    tween(popupScale, 0.28, { Scale = 1 }, Enum.EasingStyle.Back)
    tween(popup, 0.16, { BackgroundTransparency = 0 })
end

-- fires on release, and only if the finger barely moved (so scrolling the page never triggers it)
local function makeToggle(parent, text, default, callback)
    -- a real button: scrolling the page by dragging over it works, and it only fires on a tap
    local row = Instance.new("TextButton")
    row.Size = UDim2.new(1, 0, 0, 50)
    row.Text = ""
    row.AutoButtonColor = false
    row.LayoutOrder = nextOrder()
    row.Parent = parent
    styleCard(row)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -90, 1, 0)
    label.Position = UDim2.fromOffset(18, 0)
    label.BackgroundTransparency = 1
    label.Text = tostring(text)
    label.TextColor3 = Theme.text
    label.TextSize = 16
    label.Font = FONT
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextWrapped = true
    label.Active = false
    label.Parent = row

    local switch = Instance.new("Frame")
    switch.Size = UDim2.fromOffset(46, 26)
    switch.Position = UDim2.new(1, -64, 0.5, -13)
    switch.BackgroundColor3 = Theme.switchOff
    switch.BorderSizePixel = 0
    switch.Active = false
    switch.Parent = row
    addCorner(switch, 13)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.fromOffset(20, 20)
    knob.Position = UDim2.fromOffset(3, 3)
    knob.BackgroundColor3 = Color3.fromRGB(245, 245, 247)
    knob.BorderSizePixel = 0
    knob.Active = false
    knob.Parent = switch
    addCorner(knob, 10)

    local value = default and true or false
    local function render(animated)
        local goalColor = value and Theme.accent or Theme.switchOff
        local goalKnob = value and Color3.fromRGB(14, 14, 18) or Color3.fromRGB(245, 245, 247)
        local goalPosition = value and UDim2.fromOffset(23, 3) or UDim2.fromOffset(3, 3)
        if animated then
            tween(switch, 0.22, { BackgroundColor3 = goalColor })
            tween(knob, 0.3, { Position = goalPosition, BackgroundColor3 = goalKnob }, Enum.EasingStyle.Back)
        else
            switch.BackgroundColor3 = goalColor
            knob.BackgroundColor3 = goalKnob
            knob.Position = goalPosition
        end
    end
    local function set(newValue, silent)
        value = newValue and true or false
        render(false)
        if not silent and callback then callback(value) end
    end
    row.Activated:Connect(function()
        value = not value
        render(true)
        if callback then callback(value) end
    end)
    render(false)
    return set
end

-- Slider that does not fight with scrolling:
--  * grab the knob (big touch area) and drag sideways to change the value; the page stops scrolling while you hold it
--  * a quick tap on the bar jumps to that spot
--  * dragging up/down from the bar just scrolls the page and never changes the value
local function makeSlider(parent, text, minValue, maxValue, defaultValue, step, callback)
    step = step or 1
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 68)
    row.LayoutOrder = nextOrder()
    row.Parent = parent
    styleCard(row)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -130, 0, 24)
    label.Position = UDim2.fromOffset(18, 8)
    label.BackgroundTransparency = 1
    label.Text = tostring(text)
    label.TextColor3 = Theme.text
    label.TextSize = 15
    label.Font = FONT
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Active = false
    label.Parent = row

    local valueLabel = Instance.new("TextLabel")
    valueLabel.Size = UDim2.fromOffset(100, 24)
    valueLabel.Position = UDim2.new(1, -118, 0, 8)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Text = ""
    valueLabel.TextColor3 = Theme.accent
    valueLabel.TextSize = 15
    valueLabel.Font = FONT_BOLD
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.Active = false
    valueLabel.Parent = row

    local track = Instance.new("TextButton")
    track.Size = UDim2.new(1, -36, 0, 30)
    track.Position = UDim2.new(0, 18, 1, -36)
    track.BackgroundTransparency = 1
    track.Text = ""
    track.AutoButtonColor = false
    track.Parent = row

    local line = Instance.new("Frame")
    line.Size = UDim2.new(1, 0, 0, 4)
    line.Position = UDim2.new(0, 0, 0.5, -2)
    line.BackgroundColor3 = Theme.track
    line.BorderSizePixel = 0
    line.Active = false
    line.Parent = track
    addCorner(line, 2)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(0, 0, 1, 0)
    fill.BackgroundColor3 = Theme.accent
    fill.BorderSizePixel = 0
    fill.Active = false
    fill.Parent = line
    addCorner(fill, 2)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.fromOffset(16, 16)
    knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.Position = UDim2.new(0, 0, 0.5, 0)
    knob.BackgroundColor3 = Color3.fromRGB(245, 245, 247)
    knob.BorderSizePixel = 0
    knob.Active = false
    knob.Parent = track
    addCorner(knob, 9)

    local value = clamp(defaultValue, minValue, maxValue)
    local scroller = parent:IsA("ScrollingFrame") and parent or nil
    local grabbing = false
    local pending = nil

    local function formatValue(number)
        if step >= 1 then return tostring(math.floor(number + 0.5)) end
        if step >= 0.1 then return string.format("%.1f", number) end
        return string.format("%.2f", number)
    end
    local function relativeValue()
        return (value - minValue) / math.max(maxValue - minValue, 0.0001)
    end
    local function render()
        local relative = relativeValue()
        fill.Size = UDim2.new(relative, 0, 1, 0)
        knob.Position = UDim2.new(relative, 0, 0.5, 0)
        valueLabel.Text = formatValue(value)
    end
    local function set(newValue, silent)
        newValue = clamp(newValue, minValue, maxValue)
        newValue = round(newValue, step)
        newValue = clamp(newValue, minValue, maxValue)
        value = newValue
        render()
        if not silent and callback then callback(value) end
    end
    local function updateFromX(x)
        local absolute = track.AbsolutePosition
        local size = track.AbsoluteSize
        local relative = clamp((x - absolute.X) / math.max(size.X, 1), 0, 1)
        set(minValue + (maxValue - minValue) * relative)
    end
    local function endGrab()
        if not grabbing then return end
        grabbing = false
        if scroller then scroller.ScrollingEnabled = true end
        tween(knob, 0.2, { Size = UDim2.fromOffset(16, 16) }, Enum.EasingStyle.Back)
    end

    track.InputBegan:Connect(function(input)
        if not isPress(input) then return end
        local scale = State.guiScale and State.guiScale.Scale or 1
        local knobX = track.AbsolutePosition.X + track.AbsoluteSize.X * relativeValue()
        if math.abs(input.Position.X - knobX) <= 34 * scale then
            grabbing = true
            if scroller then scroller.ScrollingEnabled = false end
            tween(knob, 0.15, { Size = UDim2.fromOffset(22, 22) }, Enum.EasingStyle.Back)
            updateFromX(input.Position.X)
        else
            pending = { input = input, x = input.Position.X, y = input.Position.Y }
        end
    end)
    connect(UserInputService.InputChanged, function(input)
        if grabbing then
            if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement then
                updateFromX(input.Position.X)
            end
        elseif pending and input == pending.input then
            if math.abs(input.Position.X - pending.x) > 10 or math.abs(input.Position.Y - pending.y) > 10 then
                pending = nil -- the finger moved: this was a scroll, not a tap
            end
        end
    end)
    connect(UserInputService.InputEnded, function(input)
        if not isPress(input) then return end
        if grabbing then
            endGrab()
        elseif pending and input == pending.input then
            local tap = pending
            pending = nil
            if math.abs(input.Position.X - tap.x) <= 10 and math.abs(input.Position.Y - tap.y) <= 10 then
                updateFromX(tap.x)
            end
        end
    end)
    render()
    return set
end

-- one line text field (for the custom sound id / link)
local function makeInput(parent, text, placeholder, default, callback)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 74)
    row.LayoutOrder = nextOrder()
    row.Parent = parent
    styleCard(row)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -36, 0, 24)
    label.Position = UDim2.fromOffset(18, 8)
    label.BackgroundTransparency = 1
    label.Text = tostring(text)
    label.TextColor3 = Theme.text
    label.TextSize = 15
    label.Font = FONT
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Active = false
    label.Parent = row

    local boxFrame = Instance.new("Frame")
    boxFrame.Size = UDim2.new(1, -36, 0, 30)
    boxFrame.Position = UDim2.new(0, 18, 1, -38)
    boxFrame.BackgroundColor3 = Theme.panel
    boxFrame.BorderSizePixel = 0
    boxFrame.Parent = row
    addCorner(boxFrame, 10)
    local boxStroke = addStroke(boxFrame, Theme.border, 1, 0)

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(1, -20, 1, 0)
    box.Position = UDim2.fromOffset(10, 0)
    box.BackgroundTransparency = 1
    box.Text = tostring(default or "")
    box.PlaceholderText = placeholder or ""
    box.PlaceholderColor3 = Theme.muted
    box.TextColor3 = Theme.text
    box.TextSize = 14
    box.Font = FONT
    box.TextXAlignment = Enum.TextXAlignment.Left
    box.ClearTextOnFocus = false
    box.TextTruncate = Enum.TextTruncate.AtEnd
    box.Parent = boxFrame
    box.Focused:Connect(function() tween(boxStroke, 0.2, { Color = Theme.accent }) end)
    box.FocusLost:Connect(function()
        tween(boxStroke, 0.25, { Color = Theme.border })
        if callback then callback(box.Text) end
    end)
    local function set(newText)
        box.Text = tostring(newText or "")
    end
    return set
end

-- row with the current value on the right; a tap opens a popup list with a check on the selected item
local function makeCycle(parent, text, options, defaultIndex, callback)
    local row = Instance.new("TextButton")
    row.Size = UDim2.new(1, 0, 0, 50)
    row.Text = ""
    row.AutoButtonColor = false
    row.LayoutOrder = nextOrder()
    row.Parent = parent
    styleCard(row)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -230, 1, 0)
    label.Position = UDim2.fromOffset(18, 0)
    label.BackgroundTransparency = 1
    label.Text = tostring(text)
    label.TextColor3 = Theme.text
    label.TextSize = 16
    label.Font = FONT
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextWrapped = true
    label.Active = false
    label.Parent = row

    local pill = Instance.new("Frame")
    pill.Size = UDim2.fromOffset(180, 34)
    pill.Position = UDim2.new(1, -194, 0.5, -17)
    pill.BackgroundColor3 = Theme.panel
    pill.BorderSizePixel = 0
    pill.Active = false
    pill.Parent = row
    addCorner(pill, 11)
    addStroke(pill, Theme.border, 1, 0)

    local valueLabel = Instance.new("TextLabel")
    valueLabel.Size = UDim2.new(1, -38, 1, 0)
    valueLabel.Position = UDim2.fromOffset(14, 0)
    valueLabel.BackgroundTransparency = 1
    valueLabel.TextColor3 = Theme.text
    valueLabel.TextSize = 15
    valueLabel.Font = FONT
    valueLabel.TextXAlignment = Enum.TextXAlignment.Left
    valueLabel.TextTruncate = Enum.TextTruncate.AtEnd
    valueLabel.Active = false
    valueLabel.Parent = pill
    makeChevron(pill, UDim2.new(1, -18, 0.5, 0), Theme.muted)

    local index = defaultIndex or 1
    local function render()
        valueLabel.Text = tostring(options[index])
    end
    local function set(newIndex, silent)
        index = ((newIndex - 1) % #options) + 1
        render()
        if not silent and callback then callback(options[index], index) end
    end
    row.Activated:Connect(function()
        local items = {}
        for optionIndex, option in ipairs(options) do
            items[#items + 1] = {
                text = option,
                checked = optionIndex == index,
                onTap = function() set(optionIndex) end,
            }
        end
        openPicker(pill, { items = items, width = 230 })
    end)
    render()
    return set
end

local function makeColorCycle(parent, text, presets, defaultIndex, callback)
    local row = Instance.new("TextButton")
    row.Size = UDim2.new(1, 0, 0, 50)
    row.Text = ""
    row.AutoButtonColor = false
    row.LayoutOrder = nextOrder()
    row.Parent = parent
    styleCard(row)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -230, 1, 0)
    label.Position = UDim2.fromOffset(18, 0)
    label.BackgroundTransparency = 1
    label.Text = tostring(text)
    label.TextColor3 = Theme.text
    label.TextSize = 16
    label.Font = FONT
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextWrapped = true
    label.Active = false
    label.Parent = row

    local pill = Instance.new("Frame")
    pill.Size = UDim2.fromOffset(180, 34)
    pill.Position = UDim2.new(1, -194, 0.5, -17)
    pill.BackgroundColor3 = Theme.panel
    pill.BorderSizePixel = 0
    pill.Active = false
    pill.Parent = row
    addCorner(pill, 11)
    addStroke(pill, Theme.border, 1, 0)

    local dot = Instance.new("Frame")
    dot.Size = UDim2.fromOffset(12, 12)
    dot.Position = UDim2.new(0, 14, 0.5, -6)
    dot.BorderSizePixel = 0
    dot.Active = false
    dot.Parent = pill
    addCorner(dot, 6)

    local valueLabel = Instance.new("TextLabel")
    valueLabel.Size = UDim2.new(1, -68, 1, 0)
    valueLabel.Position = UDim2.fromOffset(34, 0)
    valueLabel.BackgroundTransparency = 1
    valueLabel.TextColor3 = Theme.text
    valueLabel.TextSize = 15
    valueLabel.Font = FONT
    valueLabel.TextXAlignment = Enum.TextXAlignment.Left
    valueLabel.Active = false
    valueLabel.Parent = pill
    makeChevron(pill, UDim2.new(1, -18, 0.5, 0), Theme.muted)

    local index = defaultIndex or 1
    local function render()
        local preset = presets[index]
        valueLabel.Text = preset.name
        dot.BackgroundColor3 = preset.color
    end
    local function set(newIndex, silent)
        index = ((newIndex - 1) % #presets) + 1
        render()
        if not silent and callback then callback(index, presets[index]) end
    end
    row.Activated:Connect(function()
        local items = {}
        for presetIndex, preset in ipairs(presets) do
            items[#items + 1] = {
                text = preset.name,
                color = preset.color,
                checked = presetIndex == index,
                onTap = function() set(presetIndex) end,
            }
        end
        openPicker(pill, { items = items, width = 230 })
    end)
    render()
    return set
end

local function makeButton(parent, text, callback, color)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, 0, 0, 48)
    button.Text = tostring(text)
    local textColor = Theme.text
    if color == Theme.danger then
        textColor = Theme.danger
    elseif color == Theme.accent or color == Theme.accent2 then
        textColor = Theme.accent
    end
    button.TextColor3 = textColor
    button.TextSize = 16
    button.Font = FONT
    button.AutoButtonColor = false
    button.LayoutOrder = nextOrder()
    button.Parent = parent
    styleCard(button)
    pressable(button, 0.97)
    button.Activated:Connect(function()
        if callback then callback() end
    end)
    return button
end

local function makeButtonRow(parent, leftText, rightText, onLeftDown, onLeftUp, onRightDown, onRightUp)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 48)
    row.BackgroundTransparency = 1
    row.LayoutOrder = nextOrder()
    row.Parent = parent

    local list = Instance.new("UIListLayout")
    list.FillDirection = Enum.FillDirection.Horizontal
    list.Padding = UDim.new(0, 8)
    list.SortOrder = Enum.SortOrder.LayoutOrder
    list.Parent = row

    local function makeHalf(textValue, order)
        local button = Instance.new("TextButton")
        button.Size = UDim2.new(0.5, -4, 1, 0)
        button.Text = tostring(textValue)
        button.TextColor3 = Theme.text
        button.TextSize = 16
        button.Font = FONT
        button.AutoButtonColor = false
        button.LayoutOrder = order
        button.Parent = row
        styleCard(button)
        pressable(button, 0.97)
        return button
    end
    local left = makeHalf(leftText, 1)
    local right = makeHalf(rightText, 2)

    local function wire(button, onDown, onUp)
        button.InputBegan:Connect(function(input)
            if isPress(input) then
                tween(button, 0.08, { BackgroundColor3 = Theme.tabActive })
                if onDown then onDown() end
            end
        end)
        button.InputEnded:Connect(function(input)
            if isPress(input) then
                tween(button, 0.2, { BackgroundColor3 = Theme.row })
                if onUp then onUp() end
            end
        end)
    end
    wire(left, onLeftDown, onLeftUp)
    wire(right, onRightDown, onRightUp)
    return row
end

-- ===================== Trigger bot =====================
local TRIGGER_MODES = { "Click", "Hold" }
local FIRE_METHODS = { "Auto", "Mouse", "Tool", "Virtual", "Signal" }
local TRIGGER_PARTS = { "Head", "UpperTorso", "Torso", "HumanoidRootPart" }
State.lastFireAt = 0
State.triggerShots = 0
State.triggerTargetName = nil
State.triggerMethodName = nil
State.triggerHeldMethod = nil

local function lazyService(name)
    local ok, service = pcall(function() return game:GetService(name) end)
    if ok then return service end
    return nil
end

local function currentTool()
    local character = LocalPlayer.Character
    return character and character:FindFirstChildOfClass("Tool") or nil
end

-- Auto: mouse functions of the executor when it has them, else the equipped tool, else virtual input
local function resolveFireMethod()
    return Config.Trigger.Method
end

local function screenCenter()
    local viewport = Camera and Camera.ViewportSize or Vector2.new(800, 400)
    return viewport.X * 0.5, viewport.Y * 0.5
end

local fireDown
fireDown = function(method)
    State.lastFireAt = os.clock()
    if method == "Auto" then
        -- Auto: the equipped tool AND the executor's mouse, whichever the game listens to
        fireDown("Tool")
        fireDown("Mouse")
        return
    end
    if method == "Mouse" then
        if type(mouse1press) == "function" then pcall(mouse1press)
        elseif type(mouse1click) == "function" then pcall(mouse1click) end
    elseif method == "Tool" then
        local tool = currentTool()
        if tool then pcall(function() tool:Activate() end) end
    elseif method == "Virtual" then
        local x, y = screenCenter()
        local vim = lazyService("VirtualInputManager")
        local ok = vim ~= nil and pcall(function() vim:SendMouseButtonEvent(x, y, 0, true, game, 0) end)
        if not ok then
            local vu = lazyService("VirtualUser")
            if vu then pcall(function() vu:Button1Down(Vector2.new(x, y), Camera.CFrame) end) end
        end
    elseif method == "Signal" then
        local tool = currentTool()
        if tool and type(firesignal) == "function" then pcall(firesignal, tool.Activated) end
    end
end

local fireUp
fireUp = function(method)
    if method == "Auto" then
        fireUp("Tool")
        fireUp("Mouse")
        return
    end
    if method == "Mouse" then
        if type(mouse1release) == "function" then pcall(mouse1release) end
    elseif method == "Tool" then
        local tool = currentTool()
        if tool then pcall(function() tool:Deactivate() end) end
    elseif method == "Virtual" then
        local x, y = screenCenter()
        local vim = lazyService("VirtualInputManager")
        local ok = vim ~= nil and pcall(function() vim:SendMouseButtonEvent(x, y, 0, false, game, 0) end)
        if not ok then
            local vu = lazyService("VirtualUser")
            if vu then pcall(function() vu:Button1Up(Vector2.new(x, y), Camera.CFrame) end) end
        end
    elseif method == "Signal" then
        local tool = currentTool()
        if tool and type(firesignal) == "function" then pcall(firesignal, tool.Deactivated) end
    end
end

-- one full click with the selected method
local function fireClick()
    local method = resolveFireMethod()
    State.triggerMethodName = method
    State.triggerShots = State.triggerShots + 1
    if method == "Mouse" and type(mouse1click) == "function" then
        State.lastFireAt = os.clock()
        pcall(mouse1click)
        return
    end
    fireDown(method)
    task.delay(0.03, function() fireUp(method) end)
end

local function pressTrigger()
    if State.triggerHolding then return end
    State.triggerHolding = true
    State.triggerHeldMethod = resolveFireMethod()
    State.triggerMethodName = State.triggerHeldMethod
    State.triggerShots = State.triggerShots + 1
    fireDown(State.triggerHeldMethod)
end

local function releaseTrigger()
    if not State.triggerHolding then return end
    State.triggerHolding = false
    fireUp(State.triggerHeldMethod or resolveFireMethod())
    State.triggerHeldMethod = nil
end

-- walks up from a hit part to the player whose character contains it (works with armor models, accessories, nested models)
local function playerFromInstance(instance)
    local current = instance
    while current and current ~= Workspace do
        local player = Players:GetPlayerFromCharacter(current)
        if player then return player, current end
        current = current.Parent
    end
    return nil
end

-- 1) enemy exactly under the crosshair (ray from the screen center with the ORIGINAL raycast function)
local function triggerTargetUnderCrosshair()
    if not Camera then return nil end
    local cframe = Camera.CFrame
    local origin = cframe.Position
    local direction = cframe.LookVector * Config.Trigger.MaxDistance
    local params = State.triggerParams
    if not params then
        params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.IgnoreWater = true
        State.triggerParams = params
    end
    local ignore = {}
    if LocalPlayer.Character then ignore[1] = LocalPlayer.Character end
    local hit = nil
    for _ = 1, 5 do
        params.FilterDescendantsInstances = ignore
        local result = rawRaycast(origin, direction, params)
        if not result then break end
        local instance = result.Instance
        if playerFromInstance(instance) or not instance:IsA("BasePart") or instance.Transparency < 0.9 then
            hit = instance
            break
        end
        ignore[#ignore + 1] = instance -- an invisible blocker (zone, glass...) is skipped
    end
    if not hit then
        State.triggerRayInfo = "ничего"
        return nil
    end
    local player, character = playerFromInstance(hit)
    State.triggerRayInfo = hit.Name .. (player and (" (" .. player.Name .. ")") or "")
    if not player or player == LocalPlayer then return nil end
    if not passesTeam(player, not Config.Settings.Deathmatch) then return nil end
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return nil end
    if Config.Trigger.HeadOnly and hit.Name ~= "Head" then return nil end
    return player
end

-- 2) enemy whose body is within a few pixels of the screen center and visible (covers crosshairs that are not exactly centered)
local function triggerTargetNearCenter()
    local radius = Config.Trigger.Radius
    if radius <= 0 or not Camera then return nil end
    local viewport = Camera.ViewportSize
    local center = Vector2.new(viewport.X * 0.5, viewport.Y * 0.5)
    local cameraPosition = Camera.CFrame.Position
    local bestPlayer, bestDistance = nil, radius
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and passesTeam(player, not Config.Settings.Deathmatch) then
            local character, humanoid = getCharacter(player)
            if character and humanoid and humanoid.Health > 0 then
                local root = getRoot(character)
                if root and (root.Position - cameraPosition).Magnitude <= Config.Trigger.MaxDistance then
                    for _, name in ipairs(TRIGGER_PARTS) do
                        if not Config.Trigger.HeadOnly or name == "Head" then
                            local part = getPart(character, name)
                            if part then
                                local screen, onScreen = projectPoint(part.Position)
                                if screen and onScreen then
                                    local distance = (screen - center).Magnitude
                                    if distance < bestDistance and hasLineOfSight(character, part) then
                                        bestPlayer, bestDistance = player, distance
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    return bestPlayer
end

local function updateTrigger()
    local cfg = Config.Trigger
    if not cfg.Enabled then
        releaseTrigger()
        State.triggerSince = nil
        State.triggerTargetName = nil
        State.triggerRayInfo = nil
        return
    end
    local target = triggerTargetUnderCrosshair() or triggerTargetNearCenter()
    if not target and cfg.UseSilent and Config.Silent.Enabled and State.silentTargetPlayer and State.silentTarget and State.silentLOS then
        -- silent aim will redirect the bullet, so the crosshair does not have to be on the enemy
        target = State.silentTargetPlayer
    end
    if not target then
        State.triggerSince = nil
        State.triggerTargetName = nil
        releaseTrigger()
        return
    end
    local now = os.clock()
    State.engaged[target] = now
    State.triggerTargetName = target.Name
    State.triggerSince = State.triggerSince or now
    if now - State.triggerSince < cfg.Delay / 1000 then return end
    if cfg.Mode == "Hold" then
        pressTrigger()
    elseif now - State.triggerLastShot >= cfg.Interval / 1000 then
        State.triggerLastShot = now
        fireClick()
    end
end

-- ===================== Kill sounds =====================
-- IDs collected from public Roblox sound-ID lists (short clips; Roblox can take uploads down, so any of them may stop playing).
-- "Custom" accepts a numeric ID, rbxassetid://..., or a direct http(s) link to an mp3/ogg/wav file
-- (the link is downloaded once with the executor and played with getcustomasset).
local SOUND_PRESETS = {
    { name = "Neverlose", id = 8679627751 },
    { name = "Rust Headshot", id = 5043539486 },
    { name = "Rust Headshot 2", id = 4764109000 },
    { name = "UwU", id = 8323804973 },
    { name = "Rivals Kill", id = 90763320252335 },
    { name = "SF2 Perfect", id = 4467682848 },
    { name = "Jevil Hit", id = 2606662454 },
    { name = "Good Boy", id = 94713839999709 },
    { name = "Custom ID / URL" },
}
local SOUND_PRESET_NAMES = {}
for _, preset in ipairs(SOUND_PRESETS) do SOUND_PRESET_NAMES[#SOUND_PRESET_NAMES + 1] = preset.name end
local SOUND_MODES = { "Auto", "My targets", "Any enemy" }
local SoundService = game:GetService("SoundService")
State.soundFiles = {}
State.soundDownloads = {}
State.killStatActive = false

local function trimText(text)
    return (string.gsub(string.gsub(tostring(text or ""), "^%s+", ""), "%s+$", ""))
end

local function soundFileName(url)
    local sum = 0
    for index = 1, #url do
        sum = (sum * 31 + string.byte(url, index)) % 4294967296
    end
    local lower = string.lower(url)
    local extension = "mp3"
    if string.find(lower, ".ogg", 1, true) then extension = "ogg" end
    if string.find(lower, ".wav", 1, true) then extension = "wav" end
    return string.format("4080_sound_%d.%s", sum, extension)
end

local function fetchSound(url)
    if State.soundFiles[url] then return State.soundFiles[url] end
    if State.soundDownloads[url] then return nil end
    if type(writefile) ~= "function" or type(getcustomasset) ~= "function" then
        notify("Executor без writefile/getcustomasset: ссылки не поддерживаются, нужен ID", Theme.danger)
        return nil
    end
    State.soundDownloads[url] = true
    task.spawn(function()
        local body = nil
        local requester = request or http_request or (syn and syn.request) or (http and http.request)
        if requester then
            local ok, response = pcall(requester, { Url = url, Method = "GET" })
            if ok and type(response) == "table" and type(response.Body) == "string"
                and (response.StatusCode == nil or response.StatusCode == 200) then
                body = response.Body
            end
        end
        if not body then
            local ok, result = pcall(function() return game:HttpGet(url) end)
            if ok and type(result) == "string" and #result > 100 then body = result end
        end
        if body then
            local file = soundFileName(url)
            if pcall(writefile, file, body) then
                local ok, asset = pcall(getcustomasset, file)
                if ok and asset then
                    State.soundFiles[url] = asset
                    notify("Звук загружен", Theme.accent)
                end
            end
        else
            notify("Не удалось скачать звук по ссылке", Theme.danger)
        end
        State.soundDownloads[url] = nil
    end)
    return nil
end

local function currentSoundSource()
    local cfg = Config.Sounds
    local preset = nil
    for _, entry in ipairs(SOUND_PRESETS) do
        if entry.name == cfg.Preset then
            preset = entry
            break
        end
    end
    if preset and preset.id then
        return "rbxassetid://" .. tostring(preset.id)
    end
    local custom = trimText(cfg.Custom)
    if custom == "" then return nil end
    if string.match(custom, "^%d+$") then return "rbxassetid://" .. custom end
    if string.find(custom, "^rbxassetid://") or string.find(custom, "^rbxasset://") then return custom end
    if string.find(custom, "^https?://") then return fetchSound(custom) end
    return nil
end

local function playKillSound()
    local source = currentSoundSource()
    if not source then return false end
    local sound = Instance.new("Sound")
    sound.Name = "4080_KillSound"
    sound.SoundId = source
    sound.Volume = Config.Sounds.Volume
    sound.Parent = SoundService
    sound:Play()
    task.delay(8, function() pcall(function() sound:Destroy() end) end)
    return true
end

local function onPlayerDied(player)
    local cfg = Config.Sounds
    if not cfg.KillEnabled or player == LocalPlayer then return end
    -- the game's own Kills stat is exact: when it exists it is the only thing that triggers the sound
    if State.killStatActive then return end
    local isAlly = false
    if not Config.Settings.Deathmatch then isAlly = resolveTeam(player) == true end
    if isAlly then return end

    -- 1) killer tag ("creator" ObjectValue inside the Humanoid, used by many games): the sound only plays if it points at us
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local tag = humanoid and humanoid:FindFirstChild("creator")
    if tag and tag:IsA("ObjectValue") then
        if tag.Value == LocalPlayer then playKillSound() end
        return
    end

    -- 2) no stat and no tag: only if we were shooting, aiming at them and they were taking damage, all within the last second
    local now = os.clock()
    local engaged = State.engaged[player]
    local damaged = State.damagedAt[player]
    if engaged and now - engaged < 1 and damaged and now - damaged < 1 and now - State.lastFireAt < 1 then
        playKillSound()
    end
end

trackPlayerHumanoid = function(player, character)
    if State.unloaded or player == LocalPlayer then return end
    local humanoid = character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid", 5)
    if not humanoid then return end
    local last = humanoid.Health
    connect(humanoid.HealthChanged, function(health)
        if health < last then State.damagedAt[player] = os.clock() end
        last = health
    end)
    connect(humanoid.Died, function() onPlayerDied(player) end)
end

-- remember when WE fire (equipped tool activated, left mouse button), used as evidence for kill detection
local function watchLocalTools(character)
    local function hookTool(tool)
        if tool:IsA("Tool") then
            connect(tool.Activated, function() State.lastFireAt = os.clock() end)
        end
    end
    for _, child in ipairs(character:GetChildren()) do hookTool(child) end
    connect(character.ChildAdded, hookTool)
end
connect(LocalPlayer.CharacterAdded, watchLocalTools)
if LocalPlayer.Character then task.spawn(watchLocalTools, LocalPlayer.Character) end
connect(UserInputService.InputBegan, function(input, processed)
    if not processed and input.UserInputType == Enum.UserInputType.MouseButton1 then
        State.lastFireAt = os.clock()
    end
end)

-- games with a Kills / Eliminations stat: the sound plays exactly when that number goes up
task.spawn(function()
    local stats = LocalPlayer:WaitForChild("leaderstats", 8)
    if not stats or State.unloaded then return end
    task.wait(0.5)
    for _, child in ipairs(stats:GetChildren()) do
        local lower = string.lower(child.Name)
        if child:IsA("ValueBase") and type(child.Value) == "number"
            and (string.find(lower, "kill", 1, true) or string.find(lower, "elim", 1, true) or string.find(lower, "frag", 1, true)) then
            State.killStatActive = true
            local last = child.Value
            connect(child:GetPropertyChangedSignal("Value"), function()
                local value = child.Value
                if value > last and Config.Sounds.KillEnabled then
                    playKillSound()
                end
                last = value
            end)
        end
    end
end)

-- ===================== Optimization =====================
-- Client-side only: nothing here is sent to the server, and every change is saved so it can be restored.
local Opt = {}
Opt.lighting = game:GetService("Lighting")
Opt.originals = setmetatable({}, { __mode = "k" }) -- instance -> kind -> property -> original value
Opt.saved = {}                                      -- lighting / rendering settings
Opt.explosions = 0
Opt.touched = 0
Opt.scanId = 0
Opt.effects = {
    ParticleEmitter = true, Fire = true, Smoke = true, Sparkles = true, Trail = true, Beam = true,
    PointLight = true, SpotLight = true, SurfaceLight = true,
}
Opt.postfx = {
    BlurEffect = true, BloomEffect = true, ColorCorrectionEffect = true, SunRaysEffect = true, DepthOfFieldEffect = true,
}

function Opt.set(instance, kind, property, value)
    local ok = pcall(function()
        local saved = Opt.originals[instance]
        if not saved then
            saved = {}
            Opt.originals[instance] = saved
        end
        local bucket = saved[kind]
        if not bucket then
            bucket = {}
            saved[kind] = bucket
        end
        if bucket[property] == nil then bucket[property] = instance[property] end
        instance[property] = value
    end)
    if ok then Opt.touched = Opt.touched + 1 end
end

function Opt.restore(kind)
    for instance, saved in pairs(Opt.originals) do
        local bucket = saved[kind]
        if bucket then
            for property, value in pairs(bucket) do
                pcall(function() instance[property] = value end)
            end
            saved[kind] = nil
        end
    end
end

-- Roblox's official Explosion object: hide its visual effect, no craters, no local blast physics
function Opt.explosion(explosion)
    pcall(function()
        explosion.Visible = false
        explosion.BlastPressure = 0
        explosion.DestroyJointRadiusPercent = 0
        explosion.ExplosionType = Enum.ExplosionType.NoCraters
    end)
    Opt.explosions = Opt.explosions + 1
end

-- deletes small loose (unanchored) parts around an explosion on this client only
function Opt.cleanDebris(position, radius)
    local ok = pcall(function()
        local params = OverlapParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        local excluded = {}
        for _, player in ipairs(Players:GetPlayers()) do
            if player.Character then excluded[#excluded + 1] = player.Character end
        end
        params.FilterDescendantsInstances = excluded
        params.MaxParts = 600
        local removed = 0
        for _, part in ipairs(Workspace:GetPartBoundsInRadius(position, radius, params)) do
            if not part.Anchored and part.Size.Magnitude < 14 and not part:FindFirstAncestorOfClass("Tool") then
                part:Destroy()
                removed = removed + 1
            end
        end
        Opt.touched = Opt.touched + removed
    end)
    return ok
end

function Opt.handle(instance, fromScan)
    local cfg = Config.Optimize
    local class = instance.ClassName
    if class == "Explosion" then
        if cfg.Explosions then Opt.explosion(instance) end
        if cfg.DebrisCleaner and not fromScan then
            local position, radius = instance.Position, instance.BlastRadius
            task.delay(0.25, function() Opt.cleanDebris(position, radius * 1.5 + 6) end)
            task.delay(1.5, function() Opt.cleanDebris(position, radius * 1.5 + 6) end)
        end
    elseif cfg.Effects and Opt.effects[class] then
        Opt.set(instance, "effects", "Enabled", false)
    elseif cfg.Textures and (class == "Decal" or class == "Texture") then
        Opt.set(instance, "textures", "Transparency", 1)
    elseif cfg.Materials and instance:IsA("BasePart") then
        Opt.set(instance, "materials", "Material", Enum.Material.SmoothPlastic)
        Opt.set(instance, "materials", "Reflectance", 0)
        Opt.set(instance, "materials", "CastShadow", false)
    end
end

-- goes through everything that already exists, in small batches so the game does not freeze
function Opt.scan()
    Opt.scanId = Opt.scanId + 1
    local id = Opt.scanId
    task.spawn(function()
        local list = Workspace:GetDescendants()
        for index, instance in ipairs(list) do
            if State.unloaded or id ~= Opt.scanId then return end
            pcall(Opt.handle, instance, true)
            if index % 250 == 0 then task.wait() end
        end
    end)
end

function Opt.applyGlobal()
    local cfg = Config.Optimize
    local saved = Opt.saved
    local lighting = Opt.lighting

    -- shadows
    if cfg.Shadows then
        if saved.shadows == nil then saved.shadows = lighting.GlobalShadows end
        lighting.GlobalShadows = false
    elseif saved.shadows ~= nil then
        lighting.GlobalShadows = saved.shadows
        saved.shadows = nil
    end

    -- post-processing (blur, bloom, sun rays ... in Lighting and on the camera)
    local containers = { lighting }
    if Workspace.CurrentCamera then containers[2] = Workspace.CurrentCamera end
    if cfg.PostFX then
        for _, container in ipairs(containers) do
            for _, child in ipairs(container:GetChildren()) do
                if Opt.postfx[child.ClassName] then Opt.set(child, "postfx", "Enabled", false) end
            end
        end
    else
        Opt.restore("postfx")
    end

    -- graphics quality, mesh detail, terrain decoration
    local ok, rendering = pcall(function() return settings().Rendering end)
    if ok and rendering then
        if cfg.LowQuality then
            if saved.quality == nil then
                saved.quality = rendering.QualityLevel
                pcall(function() saved.mesh = rendering.MeshPartDetailLevel end)
            end
            pcall(function() rendering.QualityLevel = Enum.QualityLevel.Level01 end)
            pcall(function() rendering.MeshPartDetailLevel = Enum.MeshPartDetailLevel.Level04 end)
        elseif saved.quality ~= nil then
            pcall(function() rendering.QualityLevel = saved.quality end)
            pcall(function() if saved.mesh ~= nil then rendering.MeshPartDetailLevel = saved.mesh end end)
            saved.quality = nil
            saved.mesh = nil
        end
    end
    pcall(function()
        local terrain = Workspace.Terrain
        if cfg.LowQuality then
            if saved.decoration == nil then saved.decoration = terrain.Decoration end
            terrain.Decoration = false
        elseif saved.decoration ~= nil then
            terrain.Decoration = saved.decoration
            saved.decoration = nil
        end
    end)
end

function Opt.refresh()
    local cfg = Config.Optimize
    Opt.applyGlobal()
    if not cfg.Effects then Opt.restore("effects") end
    if not cfg.Materials then Opt.restore("materials") end
    if not cfg.Textures then Opt.restore("textures") end
    if cfg.Effects or cfg.Materials or cfg.Textures then Opt.scan() end
end

function Opt.shutdown()
    local cfg = Config.Optimize
    for key in pairs(cfg) do cfg[key] = false end
    Opt.scanId = Opt.scanId + 1
    Opt.refresh()
end

-- new objects (explosions, particles, debris) are handled the moment they appear
connect(Workspace.DescendantAdded, function(instance)
    local cfg = Config.Optimize
    if cfg.Explosions or cfg.Effects or cfg.Textures or cfg.Materials or cfg.DebrisCleaner then
        pcall(Opt.handle, instance, false)
    end
end)

-- ===================== Local knife (client-side item) =====================
-- Nothing here is replicated: the knife exists only on your screen. It is welded to your right hand, so it
-- follows you while you run, jump and bunny hop. Knives are built from simple parts and animated in code
-- (draw, idle / run sway, inspect flips). One real Roblox model (Creator Store "Butterfly Knife" by @elitz164,
-- asset 5679481639) can be loaded through the executor and gets the same animations.
local Knife = {}
Knife.names = { "Butterfly", "Karambit", "Bayonet", "Flip Knife", "Classic Knife", "Butterfly (Roblox model)" }
Knife.skins = {
    { name = "Steel", color = Color3.fromRGB(196, 200, 210), material = Enum.Material.Metal },
    { name = "Gold", color = Color3.fromRGB(235, 190, 70), material = Enum.Material.Metal },
    { name = "Doppler", color = Color3.fromRGB(60, 120, 255), material = Enum.Material.Metal },
    { name = "Crimson", color = Color3.fromRGB(190, 30, 45), material = Enum.Material.Metal },
    { name = "Fade", color = Color3.fromRGB(255, 120, 190), material = Enum.Material.Metal },
    { name = "Black", color = Color3.fromRGB(28, 28, 32), material = Enum.Material.Metal },
}
Knife.skinNames = {}
for _, skin in ipairs(Knife.skins) do Knife.skinNames[#Knife.skinNames + 1] = skin.name end
Knife.assetId = 5679481639
Knife.assetName = "Butterfly (Roblox model)"
Knife.assetStatus = "не загружена"
Knife.assetData = nil
Knife.assetLoading = false
Knife.loadedVersion = 0
Knife.builders = {}
Knife.hidden = setmetatable({}, { __mode = "k" })
Knife.time = 0
Knife.drawStart = 0
Knife.nextInspect = 0
Knife.inspectStart = nil
Knife.toolsAt = 0

function Knife.ease(x)
    x = clamp(x, 0, 1)
    return x * x * (3 - 2 * x)
end

function Knife.currentSkin()
    for _, skin in ipairs(Knife.skins) do
        if skin.name == Config.Knife.Skin then return skin end
    end
    return Knife.skins[1]
end

-- creates a part welded to `parent`; positions and sizes are multiplied by the Size setting
function Knife.part(parent, size, cframe, color, material, transparency)
    local scale = Config.Knife.Scale
    local part = Instance.new("Part")
    part.Size = size * scale
    part.Color = color
    part.Material = material or Enum.Material.SmoothPlastic
    part.Transparency = transparency or 0
    part.Anchored = false
    part.CanCollide = false
    part.CanQuery = false
    part.CanTouch = false
    part.Massless = true
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth
    part.Parent = Knife.model
    local weld = Instance.new("Weld")
    weld.Part0 = parent
    weld.Part1 = part
    weld.C0 = CFrame.new(cframe.Position * scale) * (cframe - cframe.Position)
    weld.Parent = part
    return part, weld
end

-- invisible pivot that carries a moving piece of the knife
function Knife.group(parent, cframe)
    local part, weld = Knife.part(parent, Vector3.new(0.05, 0.05, 0.05), cframe, Color3.new(0, 0, 0), nil, 1)
    return part, weld, weld.C0
end

function Knife.blade(parent, length, width, skin)
    local color = skin.color
    local dark = color:Lerp(Color3.new(0, 0, 0), 0.45)
    local groove = color:Lerp(Color3.new(0, 0, 0), 0.22)
    Knife.part(parent, Vector3.new(0.05, width, length), CFrame.new(0, 0, -length * 0.5), color, skin.material)
    Knife.part(parent, Vector3.new(0.05, width * 0.72, width * 0.72), CFrame.new(0, 0, -length) * CFrame.Angles(math.pi / 4, 0, 0), color, skin.material)
    Knife.part(parent, Vector3.new(0.07, 0.05, length), CFrame.new(0, width * 0.5, -length * 0.5), dark, skin.material)
    Knife.part(parent, Vector3.new(0.056, 0.045, length * 0.65), CFrame.new(0, 0.02, -length * 0.45), groove, skin.material)
end

Knife.dark = Color3.fromRGB(38, 38, 42)
Knife.metal = Color3.fromRGB(150, 150, 158)

function Knife.flipInspect(duration, flips)
    return function(e)
        local p = clamp(e / duration, 0, 1)
        local s = math.sin(p * math.pi)
        return CFrame.new(0.1 * s, 0.3 * s, -0.3 * s) * CFrame.Angles(Knife.ease(p) * math.pi * 2 * flips, 0, 0.25 * s)
    end
end

function Knife.turnInspect(duration)
    return function(e)
        local p = clamp(e / duration, 0, 1)
        local s = math.sin(p * math.pi)
        return CFrame.new(0.15 * s, 0.35 * s, -0.35 * s) * CFrame.Angles(-0.7 * s, Knife.ease(p) * math.pi * 2, 0.5 * s)
    end
end

Knife.builders["Classic Knife"] = function(root, skin)
    Knife.blade(root, 1.15, 0.3, skin)
    Knife.part(root, Vector3.new(0.2, 0.24, 0.9), CFrame.new(0, 0, 0.47), Knife.dark)
    Knife.part(root, Vector3.new(0.14, 0.44, 0.1), CFrame.new(0, 0, 0.02), Knife.metal, Enum.Material.Metal)
    Knife.part(root, Vector3.new(0.22, 0.26, 0.1), CFrame.new(0, 0, 0.95), Knife.metal, Enum.Material.Metal)
    return { gripZ = 0.47, duration = 1.8, inspect = Knife.turnInspect(1.8) }
end

Knife.builders["Bayonet"] = function(root, skin)
    Knife.blade(root, 1.4, 0.34, skin)
    Knife.part(root, Vector3.new(0.2, 0.25, 0.9), CFrame.new(0, 0, 0.47), Color3.fromRGB(70, 52, 40))
    Knife.part(root, Vector3.new(0.15, 0.5, 0.12), CFrame.new(0, 0, 0.02), Knife.metal, Enum.Material.Metal)
    Knife.part(root, Vector3.new(0.22, 0.28, 0.12), CFrame.new(0, 0, 0.95), Knife.metal, Enum.Material.Metal)
    Knife.part(root, Vector3.new(0.12, 0.12, 0.12), CFrame.new(0, -0.26, 0.2), Knife.metal, Enum.Material.Metal)
    return { gripZ = 0.47, duration = 2.0, inspect = Knife.turnInspect(2.0) }
end

-- hooked blade that curves downwards, finger ring behind the handle; spins around the ring
Knife.builders["Karambit"] = function(root, skin)
    local radius = 0.27
    for index = 0, 9 do
        local angle = index / 10 * math.pi * 2
        Knife.part(root, Vector3.new(0.09, 0.07, 0.17),
            CFrame.new(0, radius * math.sin(angle), radius * math.cos(angle)) * CFrame.Angles(-(angle + math.pi / 2), 0, 0),
            Knife.dark)
    end
    Knife.part(root, Vector3.new(0.2, 0.22, 0.7), CFrame.new(0, 0, -0.62), Knife.dark)
    local arc = 1.1
    for index = 0, 6 do
        local angle = index * 0.26
        local height = 0.24 - index * 0.026
        Knife.part(root, Vector3.new(0.05, height, 0.24),
            CFrame.new(0, -arc * (1 - math.cos(angle)), -1.0 - arc * math.sin(angle)) * CFrame.Angles(-angle, 0, 0),
            skin.color, skin.material)
    end
    return {
        gripZ = 0,
        duration = 2.2,
        inspect = function(e)
            local p = clamp(e / 2.2, 0, 1)
            local s = math.sin(p * math.pi)
            return CFrame.new(0, 0.3 * s, -0.2 * s) * CFrame.Angles(Knife.ease(p) * math.pi * 4, 0, 0.2 * s)
        end,
    }
end

-- balisong: two handle halves swing around the pivot
Knife.builders["Butterfly"] = function(root, skin)
    Knife.blade(root, 1.1, 0.3, skin)
    local halves = {}
    for index, side in ipairs({ -1, 1 }) do
        local group, weld, base = Knife.group(root, CFrame.new(0, 0, 0))
        Knife.part(group, Vector3.new(0.1, 0.22, 0.95), CFrame.new(side * 0.13, 0, 0.5), Knife.dark)
        Knife.part(group, Vector3.new(0.12, 0.1, 0.2), CFrame.new(side * 0.13, 0, 0.98), Knife.metal, Enum.Material.Metal)
        halves[index] = { weld = weld, base = base }
    end
    local function setAngle(angle)
        for _, half in ipairs(halves) do
            half.weld.C0 = half.base * CFrame.Angles(angle, 0, 0)
        end
    end
    return {
        gripZ = 0.5,
        duration = 2.6,
        inspect = function(e)
            local p = clamp(e / 2.6, 0, 1)
            local s = math.sin(p * math.pi)
            return CFrame.new(0.1 * s, 0.3 * s, -0.25 * s) * CFrame.Angles(-0.4 * s, Knife.ease(p) * math.pi * 2, 0)
        end,
        animate = function(e)
            if not e then setAngle(0) return end
            local p = clamp(e / 2.6, 0, 1)
            setAngle(Knife.ease((p - 0.1) / 0.8) * math.pi * 4)
        end,
    }
end

-- folding knife: the blade folds into the handle, the knife flips, then it opens again
Knife.builders["Flip Knife"] = function(root, skin)
    local group, weld, base = Knife.group(root, CFrame.new(0, 0, 0))
    Knife.blade(group, 1.15, 0.3, skin)
    Knife.part(root, Vector3.new(0.22, 0.26, 0.95), CFrame.new(0, 0, 0.5), Knife.dark)
    Knife.part(root, Vector3.new(0.12, 0.3, 0.12), CFrame.new(0, 0, 0.02), Knife.metal, Enum.Material.Metal)
    local function setHinge(angle)
        weld.C0 = base * CFrame.Angles(angle, 0, 0)
    end
    return {
        gripZ = 0.5,
        duration = 2.4,
        inspect = function(e)
            local p = clamp(e / 2.4, 0, 1)
            local s = math.sin(p * math.pi)
            local spin = 0
            if p > 0.25 and p < 0.7 then spin = Knife.ease((p - 0.25) / 0.45) * math.pi * 2 end
            if p >= 0.7 then spin = math.pi * 2 end
            return CFrame.new(0.1 * s, 0.3 * s, -0.25 * s) * CFrame.Angles(spin, 0, 0)
        end,
        animate = function(e)
            if not e then setHinge(0) return end
            local p = clamp(e / 2.4, 0, 1)
            if p < 0.25 then
                setHinge(Knife.ease(p / 0.25) * math.pi)
            elseif p < 0.7 then
                setHinge(math.pi)
            else
                setHinge(math.pi * (1 - Knife.ease((p - 0.7) / 0.25)))
            end
        end,
    }
end

-- ---- the real Roblox model ----
function Knife.loadAsset()
    if Knife.assetData or Knife.assetLoading then return end
    Knife.assetLoading = true
    Knife.assetStatus = "загрузка..."
    task.spawn(function()
        local object = nil
        local ok, objects = pcall(function() return game:GetObjects("rbxassetid://" .. Knife.assetId) end)
        if ok and type(objects) == "table" then object = objects[1] end
        if not object then
            local okInsert, loaded = pcall(function() return game:GetService("InsertService"):LoadAsset(Knife.assetId) end)
            if okInsert and loaded then object = loaded end
        end
        Knife.assetLoading = false
        if not object then
            Knife.assetStatus = "не удалось загрузить, используется встроенная бабочка"
            return
        end
        local parts = {}
        if object:IsA("BasePart") then parts[#parts + 1] = object end
        for _, descendant in ipairs(object:GetDescendants()) do
            if descendant:IsA("BasePart") then parts[#parts + 1] = descendant end
        end
        if #parts == 0 then
            Knife.assetStatus = "в ассете нет деталей, используется встроенная бабочка"
            return
        end
        local holder = Instance.new("Model")
        for _, part in ipairs(parts) do part.Parent = holder end
        local boxCFrame, boxSize = holder:GetBoundingBox()
        -- the longest side of the model becomes the blade axis
        local longest = math.max(boxSize.X, boxSize.Y, boxSize.Z)
        local axisX, axisZ
        if boxSize.X == longest then
            axisX, axisZ = boxCFrame.YVector, boxCFrame.XVector
        elseif boxSize.Y == longest then
            axisX, axisZ = boxCFrame.ZVector, boxCFrame.YVector
        else
            axisX, axisZ = boxCFrame.XVector, boxCFrame.ZVector
        end
        local rootCFrame = CFrame.fromMatrix(boxCFrame.Position, axisX, axisZ:Cross(axisX), axisZ)
        local entries = {}
        for _, part in ipairs(parts) do
            entries[#entries + 1] = { part = part, offset = rootCFrame:ToObjectSpace(part.CFrame) }
        end
        Knife.assetData = { entries = entries, length = longest, holder = holder }
        Knife.assetStatus = "загружена"
        Knife.loadedVersion = Knife.loadedVersion + 1
    end)
end

Knife.builders[Knife.assetName] = function(root, skin)
    local data = Knife.assetData
    if not data then return nil end
    local factor = (1.7 / math.max(data.length, 0.01)) * Config.Knife.Scale
    for _, entry in ipairs(data.entries) do
        local clone = entry.part:Clone()
        for _, descendant in ipairs(clone:GetDescendants()) do
            if descendant:IsA("LuaSourceContainer") or descendant:IsA("JointInstance") or descendant:IsA("WeldConstraint") then
                descendant:Destroy()
            end
        end
        clone.Anchored = false
        clone.CanCollide = false
        clone.CanQuery = false
        clone.CanTouch = false
        clone.Massless = true
        clone.Size = clone.Size * factor
        clone.Parent = Knife.model
        local weld = Instance.new("Weld")
        weld.Part0 = root
        weld.Part1 = clone
        weld.C0 = CFrame.new(entry.offset.Position * factor) * (entry.offset - entry.offset.Position)
        weld.Parent = clone
    end
    return { gripZ = 0, duration = 2.2, inspect = Knife.flipInspect(2.2, 2) }
end

-- ---- building / destroying ----
function Knife.restoreTools()
    for part in pairs(Knife.hidden) do
        pcall(function() part.LocalTransparencyModifier = 0 end)
        Knife.hidden[part] = nil
    end
end

function Knife.destroy()
    if Knife.model then
        pcall(function() Knife.model:Destroy() end)
    end
    Knife.model, Knife.root, Knife.grip, Knife.info = nil, nil, nil, nil
    Knife.restoreTools()
end

function Knife.build(character, hand)
    Knife.destroy()
    local cfg = Config.Knife
    local model = Instance.new("Model")
    model.Name = "4080_Knife"
    Knife.model = model
    local root = Instance.new("Part")
    root.Name = "KnifeRoot"
    root.Size = Vector3.new(0.05, 0.05, 0.05)
    root.Transparency = 1
    root.Anchored = false
    root.CanCollide = false
    root.CanQuery = false
    root.CanTouch = false
    root.Massless = true
    root.Parent = model
    Knife.root = root

    local skin = Knife.currentSkin()
    local info = nil
    if cfg.Knife == Knife.assetName then
        info = Knife.builders[Knife.assetName](root, skin)
    end
    if not info then
        local builder = Knife.builders[cfg.Knife]
        if not builder or cfg.Knife == Knife.assetName then builder = Knife.builders["Butterfly"] end
        info = builder(root, skin)
    end
    Knife.info = info
    model.Parent = Workspace.CurrentCamera or Workspace

    local grip = Instance.new("Weld")
    grip.Part0 = hand
    grip.Part1 = root
    grip.C1 = CFrame.new(0, 0, (info.gripZ or 0) * cfg.Scale)
    grip.Parent = root
    Knife.grip = grip
    Knife.hand, Knife.character = hand, character
    Knife.builtKnife, Knife.builtSkin, Knife.builtScale = cfg.Knife, cfg.Skin, cfg.Scale
    Knife.builtVersion = Knife.loadedVersion
    Knife.drawStart = Knife.time
    Knife.inspectStart = nil
    Knife.nextInspect = Knife.time + 0.75 -- an inspect right after the draw animation
end

function Knife.startInspect()
    if Knife.info and not Knife.inspectStart then
        Knife.inspectStart = Knife.time
    end
end

function Knife.hideTools(character, hide)
    for _, tool in ipairs(character:GetChildren()) do
        if tool:IsA("Tool") then
            for _, descendant in ipairs(tool:GetDescendants()) do
                if descendant:IsA("BasePart") then
                    if hide then
                        descendant.LocalTransparencyModifier = 1
                        Knife.hidden[descendant] = true
                    elseif Knife.hidden[descendant] then
                        descendant.LocalTransparencyModifier = 0
                        Knife.hidden[descendant] = nil
                    end
                end
            end
        end
    end
end

function Knife.update(dt)
    local cfg = Config.Knife
    if not cfg.Enabled then
        if Knife.model then Knife.destroy() end
        return
    end
    local character = LocalPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not character or not humanoid or humanoid.Health <= 0 then
        if Knife.model then Knife.destroy() end
        return
    end
    local hand = character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm") or getRoot(character)
    if not hand then return end
    if not Knife.model or not Knife.model.Parent or Knife.character ~= character or Knife.hand ~= hand
        or Knife.builtKnife ~= cfg.Knife or Knife.builtSkin ~= cfg.Skin or Knife.builtScale ~= cfg.Scale
        or (cfg.Knife == Knife.assetName and Knife.builtVersion ~= Knife.loadedVersion) then
        Knife.build(character, hand)
    end
    Knife.time = Knife.time + dt
    local t = Knife.time

    -- the weapon you are holding is hidden (for you only) while the knife is out
    if t - Knife.toolsAt > 0.4 then
        Knife.toolsAt = t
        Knife.hideTools(character, cfg.HideTools)
    end

    -- idle sway, plus a stronger bob while running
    local root = getRoot(character)
    local velocity = root and root.AssemblyLinearVelocity or Vector3.new(0, 0, 0)
    local moving = clamp(Vector3.new(velocity.X, 0, velocity.Z).Magnitude / 16, 0, 2)
    local sway = CFrame.new(math.sin(t * 1.3) * 0.015, math.sin(t * 1.9) * 0.02, 0)
        * CFrame.Angles(math.sin(t * 1.7) * 0.035, 0, math.sin(t * 1.1) * 0.04)
    if moving > 0.05 then
        local phase = t * (6 + moving * 3)
        sway = sway * CFrame.new(math.sin(phase * 0.5) * 0.05 * moving, math.abs(math.sin(phase)) * 0.06 * moving, 0)
            * CFrame.Angles(math.sin(phase) * 0.12 * moving, 0, math.cos(phase * 0.5) * 0.1 * moving)
    end

    -- draw animation
    local draw = CFrame.new()
    local drawElapsed = t - Knife.drawStart
    if drawElapsed < 0.6 then
        local inverse = 1 - drawElapsed / 0.6
        draw = CFrame.new(0, -1.2 * inverse * inverse, 0.5 * inverse) * CFrame.Angles(-1.1 * inverse, 0, 0.7 * inverse)
    end

    -- inspect animation (automatic every few seconds, or from the button)
    local info = Knife.info
    local inspect = CFrame.new()
    if Knife.inspectStart then
        local elapsed = t - Knife.inspectStart
        if elapsed >= info.duration then
            Knife.inspectStart = nil
            Knife.nextInspect = t + cfg.InspectEvery
            if info.animate then info.animate(nil) end
        else
            inspect = info.inspect(elapsed)
            if info.animate then info.animate(elapsed) end
        end
    elseif cfg.AutoInspect and t >= Knife.nextInspect and drawElapsed >= 0.6 then
        Knife.startInspect()
    end

    -- the hand: R15 RightHand or R6 Right Arm (the knife points forward from the fist)
    local fist = CFrame.new(0, hand.Name == "RightHand" and -0.05 or -1, 0) * CFrame.Angles(math.rad(cfg.HoldAngle), 0, 0)
    if cfg.Knife == Knife.assetName and Knife.assetData then
        fist = fist * CFrame.Angles(0, cfg.AssetFlip and math.pi or 0, cfg.AssetRoll * math.pi / 2)
    end
    Knife.grip.C0 = fist * draw * sway * inspect
end

local function indexOf(list, value)
    for index, entry in ipairs(list) do
        if entry == value then return index end
    end
    return 1
end

local function colorPresetIndex(name)
    for index, preset in ipairs(COLOR_PRESETS) do
        if preset.name == name then return index end
    end
    return 1
end

local installSilentHooks
local refreshAll
local resetConfig
local reinstallHooks
local unload

local function buildGUI()
    local GUI_WIDTH = 600
    local GUI_HEIGHT = 410
    local GUI_MIN_WIDTH = 190
    local HEADER_HEIGHT = 26
    local TAB_HEIGHT = 50
    local KEYS_HEIGHT = 54
    local GUI_MIN_HEIGHT = HEADER_HEIGHT

    local parent = nil
    if Cap.GetHui then
        local ok, hui = pcall(gethui)
        if ok and hui then parent = hui end
    end
    if not parent then
        local ok, coreGui = pcall(function() return game:GetService("CoreGui") end)
        if ok and coreGui then parent = coreGui end
    end
    if not parent then parent = LocalPlayer:WaitForChild("PlayerGui") end

    local viewportSize = Camera and Camera.ViewportSize or Vector2.new(1920, 1080)
    local fitScale = clamp(math.min((viewportSize.Y - 40) / GUI_HEIGHT, (viewportSize.X - 20) / GUI_WIDTH), 0.5, 1)
    if Config.Settings.GUIScale > fitScale then
        Config.Settings.GUIScale = fitScale
    end

    local gui = Instance.new("ScreenGui")
    gui.Name = "4080_NoobWarfare"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 999999
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = parent
    State.gui = gui
    if type(protectgui) == "function" then pcall(protectgui, gui) end

    local main = Instance.new("Frame")
    main.Name = "Main"
    main.Size = UDim2.fromOffset(GUI_WIDTH, GUI_HEIGHT)
    main.AnchorPoint = Vector2.new(0.5, 0.5)
    main.Position = UDim2.fromScale(0.5, 0.5)
    main.BackgroundColor3 = Theme.bg
    main.BackgroundTransparency = 0
    main.BorderSizePixel = 0
    main.ClipsDescendants = true
    main.Active = true
    main.ZIndex = 2
    main.Parent = gui
    addCorner(main, 22)
    addStroke(main, Theme.border, 1, 0)
    State.main = main

    local guiScale = Instance.new("UIScale")
    guiScale.Scale = Config.Settings.GUIScale
    guiScale.Parent = main
    State.guiScale = guiScale

    local function getViewport()
        local camera = Workspace.CurrentCamera
        return camera and camera.ViewportSize or Vector2.new(1920, 1080)
    end

    local function getRenderedGuiSize()
        local scale = State.guiScale and State.guiScale.Scale or Config.Settings.GUIScale
        local width = State.minimized and GUI_MIN_WIDTH or GUI_WIDTH
        local height = State.minimized and GUI_MIN_HEIGHT or GUI_HEIGHT
        return Vector2.new(width * scale, height * scale)
    end

    local function setGuiCenter(center)
        local viewport = getViewport()
        local size = getRenderedGuiSize()
        local halfX = size.X * 0.5
        local halfY = size.Y * 0.5
        local maxX = math.max(halfX, viewport.X - halfX)
        local maxY = math.max(halfY, viewport.Y - halfY)
        local clampedX = clamp(center.X, halfX, maxX)
        local clampedY = clamp(center.Y, halfY, maxY)
        State.guiCenter = Vector2.new(clampedX, clampedY)
        -- the full window and the collapsed bar remember their own positions
        if State.minimized then
            State.miniCenter = State.guiCenter
        else
            State.fullCenter = State.guiCenter
        end
        main.Position = UDim2.fromScale(clampedX / math.max(viewport.X, 1), clampedY / math.max(viewport.Y, 1))
    end

    local function refreshGuiLayout()
        local viewport = getViewport()
        local center = State.guiCenter or Vector2.new(viewport.X * 0.5, viewport.Y * 0.5)
        setGuiCenter(center)
    end

    State.refreshGuiLayout = refreshGuiLayout
    local initialViewport = getViewport()
    setGuiCenter(Vector2.new(initialViewport.X * 0.5, initialViewport.Y * 0.5))

    -- ===== top handle: drag it to move the window =====
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, HEADER_HEIGHT)
    header.BackgroundTransparency = 1
    header.BorderSizePixel = 0
    header.Active = true
    header.Parent = main

    local grabber = Instance.new("Frame")
    grabber.Size = UDim2.fromOffset(46, 5)
    grabber.Position = UDim2.new(0.5, -23, 0, 10)
    grabber.BackgroundColor3 = Theme.track
    grabber.BorderSizePixel = 0
    grabber.Active = false
    grabber.Parent = header
    addCorner(grabber, 3)

    local collapseButton = Instance.new("TextButton")
    collapseButton.Size = UDim2.fromOffset(34, 22)
    collapseButton.Position = UDim2.new(1, -46, 0, 2)
    collapseButton.BackgroundTransparency = 1
    collapseButton.Text = ""
    collapseButton.AutoButtonColor = false
    collapseButton.Parent = header
    local collapseIcon = makeChevron(collapseButton, UDim2.fromScale(0.5, 0.5), Theme.muted)

    -- ===== tab strip =====
    local tabArea = Instance.new("Frame")
    tabArea.Name = "Tabs"
    tabArea.Size = UDim2.new(1, 0, 0, TAB_HEIGHT)
    tabArea.Position = UDim2.fromOffset(0, HEADER_HEIGHT)
    tabArea.BackgroundTransparency = 1
    tabArea.BorderSizePixel = 0
    tabArea.Parent = main

    local tabScroll = Instance.new("ScrollingFrame")
    tabScroll.Name = "TabScroll"
    tabScroll.Size = UDim2.fromScale(1, 1)
    tabScroll.BackgroundTransparency = 1
    tabScroll.BorderSizePixel = 0
    tabScroll.ScrollBarThickness = 0
    tabScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    tabScroll.AutomaticCanvasSize = Enum.AutomaticSize.X
    tabScroll.ScrollingDirection = Enum.ScrollingDirection.X
    tabScroll.Parent = tabArea
    local tabScrollPadding = Instance.new("UIPadding")
    tabScrollPadding.PaddingTop = UDim.new(0, 7)
    tabScrollPadding.PaddingLeft = UDim.new(0, 14)
    tabScrollPadding.PaddingRight = UDim.new(0, 14)
    tabScrollPadding.Parent = tabScroll
    local tabLayout = Instance.new("UIListLayout")
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.Padding = UDim.new(0, 6)
    tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabLayout.Parent = tabScroll

    -- ===== page area =====
    local content = Instance.new("Frame")
    content.Name = "Content"
    content.Size = UDim2.new(1, 0, 1, -(HEADER_HEIGHT + TAB_HEIGHT + KEYS_HEIGHT))
    content.Position = UDim2.fromOffset(0, HEADER_HEIGHT + TAB_HEIGHT)
    content.BackgroundTransparency = 1
    content.ClipsDescendants = true
    content.Parent = main
    State.content = content

    local pageFade = Instance.new("Frame")
    pageFade.Name = "PageFade"
    pageFade.Size = UDim2.fromScale(1, 1)
    pageFade.BackgroundColor3 = Theme.bg
    pageFade.BackgroundTransparency = 1
    pageFade.BorderSizePixel = 0
    pageFade.Active = false
    pageFade.ZIndex = 30
    pageFade.Parent = content

    -- ===== bottom key strip =====
    local keysBar = Instance.new("ScrollingFrame")
    keysBar.Name = "Keys"
    keysBar.Size = UDim2.new(1, 0, 0, KEYS_HEIGHT)
    keysBar.Position = UDim2.new(0, 0, 1, -KEYS_HEIGHT)
    keysBar.BackgroundColor3 = Color3.fromRGB(14, 14, 14)
    keysBar.BorderSizePixel = 0
    keysBar.ScrollBarThickness = 0
    keysBar.CanvasSize = UDim2.new(0, 0, 0, 0)
    keysBar.AutomaticCanvasSize = Enum.AutomaticSize.X
    keysBar.ScrollingDirection = Enum.ScrollingDirection.X
    keysBar.Parent = main
    local keysDivider = Instance.new("Frame")
    keysDivider.Size = UDim2.new(1, 0, 0, 1)
    keysDivider.Position = UDim2.new(0, 0, 1, -KEYS_HEIGHT)
    keysDivider.BackgroundColor3 = Theme.border
    keysDivider.BorderSizePixel = 0
    keysDivider.ZIndex = 5
    keysDivider.Parent = main
    local keysPadding = Instance.new("UIPadding")
    keysPadding.PaddingLeft = UDim.new(0, 12)
    keysPadding.PaddingRight = UDim.new(0, 12)
    keysPadding.PaddingTop = UDim.new(0, 8)
    keysPadding.Parent = keysBar
    local keysLayout = Instance.new("UIListLayout")
    keysLayout.FillDirection = Enum.FillDirection.Horizontal
    keysLayout.Padding = UDim.new(0, 10)
    keysLayout.SortOrder = Enum.SortOrder.LayoutOrder
    keysLayout.Parent = keysBar

    -- ===== collapse / reset position =====
    local function setCollapsed(collapsed)
        closeDropdown()
        local oldTopLeft = Vector2.new(main.AbsolutePosition.X, main.AbsolutePosition.Y)
        State.minimized = collapsed and true or false
        tabArea.Visible = not State.minimized
        content.Visible = not State.minimized
        keysBar.Visible = not State.minimized
        keysDivider.Visible = not State.minimized
        main.Size = UDim2.fromOffset(State.minimized and GUI_MIN_WIDTH or GUI_WIDTH, State.minimized and GUI_MIN_HEIGHT or GUI_HEIGHT)
        tween(collapseIcon, 0.3, { Rotation = State.minimized and 180 or 0 }, Enum.EasingStyle.Back)
        if State.minimized then
            if State.miniCenter then
                setGuiCenter(State.miniCenter)
            else
                local size = getRenderedGuiSize()
                setGuiCenter(oldTopLeft + Vector2.new(size.X * 0.5, size.Y * 0.5))
            end
        else
            local viewport = getViewport()
            setGuiCenter(State.fullCenter or Vector2.new(viewport.X * 0.5, viewport.Y * 0.5))
        end
    end

    local function resetGuiPosition()
        if State.minimized then setCollapsed(false) end
        State.miniCenter = nil
        local viewport = getViewport()
        setGuiCenter(Vector2.new(viewport.X * 0.5, viewport.Y * 0.5))
    end

    collapseButton.Activated:Connect(function() setCollapsed(not State.minimized) end)

    -- ===== pages + tab selection =====
    local function createPage(name)
        local page = Instance.new("ScrollingFrame")
        page.Name = name
        page.Size = UDim2.fromScale(1, 1)
        page.BackgroundTransparency = 1
        page.BorderSizePixel = 0
        page.ScrollBarThickness = 3
        page.ScrollBarImageColor3 = Theme.track
        page.CanvasSize = UDim2.new(0, 0, 0, 0)
        page.AutomaticCanvasSize = Enum.AutomaticSize.Y
        page.ScrollingDirection = Enum.ScrollingDirection.Y
        page.Visible = false
        page.Parent = content
        addList(page, 8)
        addPadding(page, 14)
        State.pages[name] = page
        return page
    end

    State.tabPills = {}
    local function selectTab(name)
        closeDropdown()
        local page = State.pages[name]
        if not page then return end
        State.activeTab = name
        for pageName, other in pairs(State.pages) do
            other.Visible = pageName == name
        end
        for tabId, pill in pairs(State.tabPills) do
            local active = tabId == name
            tween(pill.frame, 0.22, { BackgroundTransparency = active and 0 or 1 })
            tween(pill.label, 0.22, { TextColor3 = active and Theme.text or Theme.muted })
        end
        -- the page slides up and fades in
        page.Position = UDim2.fromOffset(0, 18)
        tween(page, 0.34, { Position = UDim2.fromOffset(0, 0) })
        pageFade.BackgroundTransparency = 0.3
        tween(pageFade, 0.3, { BackgroundTransparency = 1 })
    end

    local aimPage = createPage("Aimbot")
    local silentPage = createPage("Silent Aim")
    local espPage = createPage("ESP")
    local movementPage = createPage("Movement")
    local antiAimPage = createPage("Anti-Aim")
    local triggerPage = createPage("Trigger")
    local soundsPage = createPage("Sounds")
    local optimizePage = createPage("Optimize")
    local knifePage = createPage("Knife")
    local settingsPage = createPage("Settings")

    makeSection(aimPage, "Targeting")
    local aimEnabledSet = makeToggle(aimPage, "Aimbot Enabled", Config.Aimbot.Enabled, function(value)
        Config.Aimbot.Enabled = value
    end)
    local aimFovSet = makeSlider(aimPage, "FOV (pixels)", 20, 400, Config.Aimbot.FOV, 1, function(value)
        Config.Aimbot.FOV = value
    end)
    local aimSmoothSet = makeSlider(aimPage, "Smoothness", 0, 100, Config.Aimbot.Smoothness, 1, function(value)
        Config.Aimbot.Smoothness = value
    end)
    local aimSpeedSet = makeSlider(aimPage, "Aim Speed", 1, 30, Config.Aimbot.Speed, 1, function(value)
        Config.Aimbot.Speed = value
    end)
    local aimPartOptions = { "Head", "UpperTorso", "HumanoidRootPart", "Nearest" }
    local aimPartSet = makeCycle(aimPage, "Target Bone", aimPartOptions, indexOf(aimPartOptions, Config.Aimbot.Part), function(value)
        Config.Aimbot.Part = value
    end)
    local aimTeamSet = makeToggle(aimPage, "Team Check", Config.Aimbot.TeamCheck, function(value)
        Config.Aimbot.TeamCheck = value
    end)
    local aimDistanceSet = makeSlider(aimPage, "Max Distance", 50, 2000, Config.Aimbot.MaxDistance, 10, function(value)
        Config.Aimbot.MaxDistance = value
    end)
    local aimVisibleSet = makeToggle(aimPage, "Visible Only", Config.Aimbot.VisibleOnly, function(value)
        Config.Aimbot.VisibleOnly = value
    end)
    local aimWallbangSet = makeToggle(aimPage, "Wallbang", Config.Aimbot.Wallbang, function(value)
        Config.Aimbot.Wallbang = value
    end)
    State.aimWallbangSet = aimWallbangSet
    local aimPriorityOptions = { "Crosshair", "Distance" }
    local aimPrioritySet = makeCycle(aimPage, "Priority", aimPriorityOptions, indexOf(aimPriorityOptions, Config.Aimbot.Priority), function(value)
        Config.Aimbot.Priority = value
    end)

    State.refreshers[#State.refreshers + 1] = function() aimEnabledSet(Config.Aimbot.Enabled, true) end
    State.refreshers[#State.refreshers + 1] = function() aimFovSet(Config.Aimbot.FOV, true) end
    State.refreshers[#State.refreshers + 1] = function() aimSmoothSet(Config.Aimbot.Smoothness, true) end
    State.refreshers[#State.refreshers + 1] = function() aimSpeedSet(Config.Aimbot.Speed, true) end
    State.refreshers[#State.refreshers + 1] = function() aimPartSet(indexOf(aimPartOptions, Config.Aimbot.Part), true) end
    State.refreshers[#State.refreshers + 1] = function() aimTeamSet(Config.Aimbot.TeamCheck, true) end
    State.refreshers[#State.refreshers + 1] = function() aimDistanceSet(Config.Aimbot.MaxDistance, true) end
    State.refreshers[#State.refreshers + 1] = function() aimVisibleSet(Config.Aimbot.VisibleOnly, true) end
    State.refreshers[#State.refreshers + 1] = function() aimWallbangSet(Config.Aimbot.Wallbang, true) end
    State.refreshers[#State.refreshers + 1] = function() aimPrioritySet(indexOf(aimPriorityOptions, Config.Aimbot.Priority), true) end

    makeSection(silentPage, "Silent Aim")
    local silentEnabledSet = makeToggle(silentPage, "Silent Aim Enabled", Config.Silent.Enabled, function(value)
        Config.Silent.Enabled = value
        if value then
            installSilentHooks()
        else
            restoreHooks()
        end
    end)
    local silentFovSet = makeSlider(silentPage, "FOV (pixels)", 20, 400, Config.Silent.FOV, 1, function(value)
        Config.Silent.FOV = value
    end)
    local silentPartSet = makeCycle(silentPage, "Target Bone", aimPartOptions, indexOf(aimPartOptions, Config.Silent.Part), function(value)
        Config.Silent.Part = value
    end)
    local silentTeamSet = makeToggle(silentPage, "Team Check", Config.Silent.TeamCheck, function(value)
        Config.Silent.TeamCheck = value
    end)
    local silentDistanceSet = makeSlider(silentPage, "Max Distance", 50, 2500, Config.Silent.MaxDistance, 10, function(value)
        Config.Silent.MaxDistance = value
    end)
    local silentWallbangSet = makeToggle(silentPage, "Wallbang", Config.Silent.Wallbang, function(value)
        Config.Silent.Wallbang = value
    end)
    State.silentWallbangSet = silentWallbangSet
    local silentMarkerSet = makeToggle(silentPage, "Show Target", Config.Silent.ShowTarget, function(value)
        Config.Silent.ShowTarget = value
    end)
    State.silentStatusLabel = makeLabel(silentPage, "Hooks: idle", 28, Theme.muted, false, 11)
    makeLabel(silentPage, "Mouse Hook is off by default. The game kicked on indexInstance detection; enable it only if shots use Mouse.Hit.", 34, Theme.muted, false, 10)

    State.refreshers[#State.refreshers + 1] = function() silentEnabledSet(Config.Silent.Enabled, true) end
    State.refreshers[#State.refreshers + 1] = function() silentFovSet(Config.Silent.FOV, true) end
    State.refreshers[#State.refreshers + 1] = function() silentPartSet(indexOf(aimPartOptions, Config.Silent.Part), true) end
    State.refreshers[#State.refreshers + 1] = function() silentTeamSet(Config.Silent.TeamCheck, true) end
    State.refreshers[#State.refreshers + 1] = function() silentDistanceSet(Config.Silent.MaxDistance, true) end
    State.refreshers[#State.refreshers + 1] = function() silentWallbangSet(Config.Silent.Wallbang, true) end
    State.refreshers[#State.refreshers + 1] = function() silentMarkerSet(Config.Silent.ShowTarget, true) end

    makeSection(espPage, "Visuals")
    local espEnabledSet = makeToggle(espPage, "ESP Enabled", Config.ESP.Enabled, function(value)
        Config.ESP.Enabled = value
        -- team check is switched on together with ESP and cannot be turned off here (only in the code)
        Config.ESP.TeamCheck = true
    end)
    local espBoxStyleSet = makeCycle(espPage, "Box Style", BOX_STYLES, indexOf(BOX_STYLES, Config.ESP.BoxStyle), function(name)
        Config.ESP.BoxStyle = name
    end)
    local espFillSet = makeToggle(espPage, "Box Fill", Config.ESP.Fill, function(value)
        Config.ESP.Fill = value
    end)
    local espOutlineSet = makeToggle(espPage, "Outlines (dark contrast)", Config.ESP.Outline, function(value)
        Config.ESP.Outline = value
    end)
    local espChamsSet = makeToggle(espPage, "Chams (glow through walls)", Config.ESP.Chams, function(value)
        Config.ESP.Chams = value
    end)
    local espSkeletonSet = makeToggle(espPage, "Skeleton", Config.ESP.Skeleton, function(value)
        Config.ESP.Skeleton = value
    end)
    local espHeadDotSet = makeToggle(espPage, "Head Circle", Config.ESP.HeadDot, function(value)
        Config.ESP.HeadDot = value
    end)
    local espTracersSet = makeToggle(espPage, "Tracers", Config.ESP.Tracers, function(value)
        Config.ESP.Tracers = value
    end)
    local espTracerOriginSet = makeCycle(espPage, "Tracer Origin", TRACER_ORIGINS, indexOf(TRACER_ORIGINS, Config.ESP.TracerOrigin), function(name)
        Config.ESP.TracerOrigin = name
    end)
    local espArrowsSet = makeToggle(espPage, "Off-screen Arrows", Config.ESP.Arrows, function(value)
        Config.ESP.Arrows = value
    end)

    makeSection(espPage, "Info")
    local espNameSet = makeToggle(espPage, "Names", Config.ESP.Name, function(value)
        Config.ESP.Name = value
    end)
    local espHealthSet = makeToggle(espPage, "Health Bar", Config.ESP.Health, function(value)
        Config.ESP.Health = value
    end)
    local espHealthTextSet = makeToggle(espPage, "Health Number", Config.ESP.HealthText, function(value)
        Config.ESP.HealthText = value
    end)
    local espDistanceSet = makeToggle(espPage, "Distance", Config.ESP.Distance, function(value)
        Config.ESP.Distance = value
    end)
    local espWeaponSet = makeToggle(espPage, "Held Weapon", Config.ESP.Weapon, function(value)
        Config.ESP.Weapon = value
    end)

    makeSection(espPage, "Colors")
    local espVisibilitySet = makeToggle(espPage, "Visible / Hidden Colors", Config.ESP.VisibilityColors, function(value)
        Config.ESP.VisibilityColors = value
    end)
    local enemyColorSet = makeColorCycle(espPage, "Enemy Color (behind walls)", COLOR_PRESETS, colorPresetIndex(Config.ESP.EnemyColorName), function(index, preset)
        Config.ESP.EnemyColor = preset.color
        Config.ESP.EnemyColorName = preset.name
    end)
    local visibleColorSet = makeColorCycle(espPage, "Visible Color", COLOR_PRESETS, colorPresetIndex(Config.ESP.VisibleColorName), function(index, preset)
        Config.ESP.VisibleColor = preset.color
        Config.ESP.VisibleColorName = preset.name
    end)

    makeSection(espPage, "Range & style")
    local espDistanceFilterSet = makeSlider(espPage, "Max Distance", 50, 3000, Config.ESP.MaxDistance, 50, function(value)
        Config.ESP.MaxDistance = value
    end)
    local espOpacitySet = makeSlider(espPage, "Opacity", 10, 100, Config.ESP.Opacity, 5, function(value)
        Config.ESP.Opacity = value
    end)
    local espTextSizeSet = makeSlider(espPage, "Text Size", 10, 22, Config.ESP.TextSize, 1, function(value)
        Config.ESP.TextSize = value
    end)
    local espChamsFillSet = makeSlider(espPage, "Chams Fill Transparency", 0, 100, Config.ESP.ChamsFill, 5, function(value)
        Config.ESP.ChamsFill = value
    end)
    local espArrowRadiusSet = makeSlider(espPage, "Arrow Distance from Center", 80, 400, Config.ESP.ArrowRadius, 10, function(value)
        Config.ESP.ArrowRadius = value
    end)
    makeLabel(espPage, "Teammates are never shown. Turn on Deathmatch (bottom bar) to see every player as an enemy. With Visible / Hidden Colors on, enemies in line of sight use the Visible color and the ones behind walls use the Enemy color.", 58, Theme.muted, false, 11)

    State.refreshers[#State.refreshers + 1] = function()
        espEnabledSet(Config.ESP.Enabled, true)
        espBoxStyleSet(indexOf(BOX_STYLES, Config.ESP.BoxStyle), true)
        espFillSet(Config.ESP.Fill, true)
        espOutlineSet(Config.ESP.Outline, true)
        espChamsSet(Config.ESP.Chams, true)
        espSkeletonSet(Config.ESP.Skeleton, true)
        espHeadDotSet(Config.ESP.HeadDot, true)
        espTracersSet(Config.ESP.Tracers, true)
        espTracerOriginSet(indexOf(TRACER_ORIGINS, Config.ESP.TracerOrigin), true)
        espArrowsSet(Config.ESP.Arrows, true)
        espNameSet(Config.ESP.Name, true)
        espHealthSet(Config.ESP.Health, true)
        espHealthTextSet(Config.ESP.HealthText, true)
        espDistanceSet(Config.ESP.Distance, true)
        espWeaponSet(Config.ESP.Weapon, true)
        espVisibilitySet(Config.ESP.VisibilityColors, true)
        enemyColorSet(colorPresetIndex(Config.ESP.EnemyColorName), true)
        visibleColorSet(colorPresetIndex(Config.ESP.VisibleColorName), true)
        espDistanceFilterSet(Config.ESP.MaxDistance, true)
        espOpacitySet(Config.ESP.Opacity, true)
        espTextSizeSet(Config.ESP.TextSize, true)
        espChamsFillSet(Config.ESP.ChamsFill, true)
        espArrowRadiusSet(Config.ESP.ArrowRadius, true)
    end

    makeSection(movementPage, "Movement")
    local speedEnabledSet = makeToggle(movementPage, "Speed Hack", Config.Movement.SpeedEnabled, function(value)
        Config.Movement.SpeedEnabled = value
        applyMovementSettings()
    end)
    local speedModeSet = makeCycle(movementPage, "Speed Mode", SPEED_MODES, indexOf(SPEED_MODES, Config.Movement.SpeedMode), function(name)
        Config.Movement.SpeedMode = name
    end)
    local speedSet = makeSlider(movementPage, "Speed", 16, 200, Config.Movement.Speed, 1, function(value)
        Config.Movement.Speed = value
    end)
    local jumpEnabledSet = makeToggle(movementPage, "Jump Hack", Config.Movement.JumpEnabled, function(value)
        Config.Movement.JumpEnabled = value
        applyMovementSettings()
    end)
    local jumpSet = makeSlider(movementPage, "Jump Power", 50, 300, Config.Movement.JumpPower, 1, function(value)
        Config.Movement.JumpPower = value
        applyMovementSettings()
    end)
    makeSection(movementPage, "Bunny hop")
    local bhopSet = makeToggle(movementPage, "Bunny Hop", Config.Movement.Bhop, function(value)
        Config.Movement.Bhop = value
        State.bhopSpeed = nil
    end)
    local bhopModeSet = makeCycle(movementPage, "Bhop Mode", BHOP_MODES, indexOf(BHOP_MODES, Config.Movement.BhopMode), function(name)
        Config.Movement.BhopMode = name
    end)
    local bhopGainSet = makeSlider(movementPage, "Speed Gain per Hop", 0, 8, Config.Movement.BhopGain, 0.5, function(value)
        Config.Movement.BhopGain = value
    end)
    local bhopMaxSet = makeSlider(movementPage, "Bhop Max Speed", 20, 120, Config.Movement.BhopMax, 1, function(value)
        Config.Movement.BhopMax = value
    end)
    makeLabel(movementPage, "Hold Jump: hops while the jump button / space is held. Always: hops all the time while you move.", 34, Theme.muted, false, 11)

    makeSection(movementPage, "Fly & misc")
    local flyEnabledSet = makeToggle(movementPage, "Fly", Config.Movement.FlyEnabled, function(value)
        Config.Movement.FlyEnabled = value
        if not value then stopFly() end
    end)
    local flySpeedSet = makeSlider(movementPage, "Fly Speed", 10, 300, Config.Movement.FlySpeed, 1, function(value)
        Config.Movement.FlySpeed = value
    end)
    makeButtonRow(movementPage, "Fly Up", "Fly Down",
        function() State.flyUp = true end,
        function() State.flyUp = false end,
        function() State.flyDown = true end,
        function() State.flyDown = false end
    )
    local noclipSet = makeToggle(movementPage, "Noclip", Config.Movement.Noclip, function(value)
        Config.Movement.Noclip = value
        if value then setNoclip(true) else setNoclip(false) end
    end)
    local wallshotSet = makeToggle(movementPage, "Wallshot (Aim + Silent)", Config.Movement.Wallshot, function(value)
        Config.Movement.Wallshot = value
        Config.Aimbot.Wallbang = value
        Config.Silent.Wallbang = value
        if State.aimWallbangSet then State.aimWallbangSet(value, true) end
        if State.silentWallbangSet then State.silentWallbangSet(value, true) end
    end)
    State.wallshotSet = wallshotSet
    makeLabel(movementPage, "Speed modes: Velocity works even when the game resets WalkSpeed, WalkSpeed sets it every frame, CFrame moves you the missing distance. Fly horizontal control uses the mobile joystick; Fly Up / Fly Down are hold buttons.", 58, Theme.muted, false, 11)

    State.refreshers[#State.refreshers + 1] = function() speedEnabledSet(Config.Movement.SpeedEnabled, true) end
    State.refreshers[#State.refreshers + 1] = function() speedSet(Config.Movement.Speed, true) end
    State.refreshers[#State.refreshers + 1] = function()
        speedModeSet(indexOf(SPEED_MODES, Config.Movement.SpeedMode), true)
        bhopSet(Config.Movement.Bhop, true)
        bhopModeSet(indexOf(BHOP_MODES, Config.Movement.BhopMode), true)
        bhopGainSet(Config.Movement.BhopGain, true)
        bhopMaxSet(Config.Movement.BhopMax, true)
    end
    State.refreshers[#State.refreshers + 1] = function() jumpEnabledSet(Config.Movement.JumpEnabled, true) end
    State.refreshers[#State.refreshers + 1] = function() jumpSet(Config.Movement.JumpPower, true) end
    State.refreshers[#State.refreshers + 1] = function() flyEnabledSet(Config.Movement.FlyEnabled, true) end
    State.refreshers[#State.refreshers + 1] = function() flySpeedSet(Config.Movement.FlySpeed, true) end
    State.refreshers[#State.refreshers + 1] = function() noclipSet(Config.Movement.Noclip, true) end
    State.refreshers[#State.refreshers + 1] = function() wallshotSet(Config.Movement.Wallshot, true) end

    -- ===== Anti-Aim =====
    makeSection(antiAimPage, "Body")
    local aaEnabledSet = makeToggle(antiAimPage, "Anti-Aim Enabled", Config.AntiAim.Enabled, function(value)
        Config.AntiAim.Enabled = value
    end)
    local aaTypeSet = makeCycle(antiAimPage, "Type", AA_TYPES, indexOf(AA_TYPES, Config.AntiAim.Type), function(name)
        Config.AntiAim.Type = name
    end)
    local aaSpeedSet = makeSlider(antiAimPage, "Spin / Sway Speed (deg/s)", 30, 2000, Config.AntiAim.Speed, 10, function(value)
        Config.AntiAim.Speed = value
    end)
    local aaAngleSet = makeSlider(antiAimPage, "Jitter / Desync / Sway Angle", 10, 180, Config.AntiAim.Angle, 1, function(value)
        Config.AntiAim.Angle = value
    end)
    local aaRateSet = makeSlider(antiAimPage, "Flip Rate (Hz)", 1, 30, Config.AntiAim.Rate, 1, function(value)
        Config.AntiAim.Rate = value
    end)
    local aaOffsetSet = makeSlider(antiAimPage, "Yaw Offset", -180, 180, Config.AntiAim.Offset, 5, function(value)
        Config.AntiAim.Offset = value
    end)

    makeSection(antiAimPage, "Hitbox offset")
    local aaOffsetModeSet = makeCycle(antiAimPage, "Offset Mode", AA_OFFSET_MODES, indexOf(AA_OFFSET_MODES, Config.AntiAim.OffsetMode), function(name)
        Config.AntiAim.OffsetMode = name
    end)
    local aaOffsetStudsSet = makeSlider(antiAimPage, "Offset Distance (studs)", 0.5, 8, Config.AntiAim.OffsetStuds, 0.5, function(value)
        Config.AntiAim.OffsetStuds = value
    end)
    local aaOffsetRateSet = makeSlider(antiAimPage, "Offset Flip Rate (Hz)", 1, 30, Config.AntiAim.OffsetRate, 1, function(value)
        Config.AntiAim.OffsetRate = value
    end)

    makeSection(antiAimPage, "Head")
    local aaPitchSet = makeCycle(antiAimPage, "Head Pitch", AA_PITCH, indexOf(AA_PITCH, Config.AntiAim.Pitch), function(name)
        Config.AntiAim.Pitch = name
    end)
    local aaPitchAngleSet = makeSlider(antiAimPage, "Pitch Angle", 10, 89, Config.AntiAim.PitchAngle, 1, function(value)
        Config.AntiAim.PitchAngle = value
    end)
makeLabel(antiAimPage, "Type None = no rotation (use only the offset). Offset moves your whole body sideways away from the point the server treats as your position: Right / Left = fixed, Flip = switches sides, Jitter = random side every tick. Roblox shows everybody the same body, so the offset body is what is visible and hittable; Flip and Jitter make shots miss by moving it faster than they can aim. Head Pitch needs Anti-Aim Enabled.", 86, Theme.muted, false, 11)

    State.refreshers[#State.refreshers + 1] = function()
        aaEnabledSet(Config.AntiAim.Enabled, true)
        aaTypeSet(indexOf(AA_TYPES, Config.AntiAim.Type), true)
        aaSpeedSet(Config.AntiAim.Speed, true)
        aaAngleSet(Config.AntiAim.Angle, true)
        aaRateSet(Config.AntiAim.Rate, true)
        aaOffsetSet(Config.AntiAim.Offset, true)
        aaPitchSet(indexOf(AA_PITCH, Config.AntiAim.Pitch), true)
        aaPitchAngleSet(Config.AntiAim.PitchAngle, true)
        aaOffsetModeSet(indexOf(AA_OFFSET_MODES, Config.AntiAim.OffsetMode), true)
        aaOffsetStudsSet(Config.AntiAim.OffsetStuds, true)
        aaOffsetRateSet(Config.AntiAim.OffsetRate, true)
    end

    -- ===== Trigger bot =====
    makeSection(triggerPage, "Trigger bot")
    local triggerEnabledSet = makeToggle(triggerPage, "Trigger Bot", Config.Trigger.Enabled, function(value)
        Config.Trigger.Enabled = value
        if not value then releaseTrigger() end
    end)
    local triggerModeSet = makeCycle(triggerPage, "Fire Mode", TRIGGER_MODES, indexOf(TRIGGER_MODES, Config.Trigger.Mode), function(name)
        releaseTrigger()
        Config.Trigger.Mode = name
    end)
    local triggerDelaySet = makeSlider(triggerPage, "Reaction Delay (ms)", 0, 300, Config.Trigger.Delay, 5, function(value)
        Config.Trigger.Delay = value
    end)
    local triggerIntervalSet = makeSlider(triggerPage, "Click Interval (ms)", 30, 400, Config.Trigger.Interval, 10, function(value)
        Config.Trigger.Interval = value
    end)
    local triggerDistanceSet = makeSlider(triggerPage, "Max Distance", 50, 2000, Config.Trigger.MaxDistance, 50, function(value)
        Config.Trigger.MaxDistance = value
    end)
    local triggerHeadSet = makeToggle(triggerPage, "Head Only", Config.Trigger.HeadOnly, function(value)
        Config.Trigger.HeadOnly = value
    end)
    local triggerSilentSet = makeToggle(triggerPage, "Also fire on the Silent Aim target", Config.Trigger.UseSilent, function(value)
        Config.Trigger.UseSilent = value
    end)
    local triggerRadiusSet = makeSlider(triggerPage, "Aim Radius around the center (px)", 0, 60, Config.Trigger.Radius, 1, function(value)
        Config.Trigger.Radius = value
    end)
    local triggerMethodSet = makeCycle(triggerPage, "Fire Method", FIRE_METHODS, indexOf(FIRE_METHODS, Config.Trigger.Method), function(name)
        releaseTrigger()
        Config.Trigger.Method = name
    end)
    makeButton(triggerPage, "Test Fire (one shot with this method)", function()
        fireClick()
        notify("Выстрел методом: " .. tostring(State.triggerMethodName), Theme.accent)
    end, Theme.accent)
    local triggerStatusLabel = makeLabel(triggerPage, "", 22, Theme.accent, false, 12)
    makeLabel(triggerPage, "Fires when an enemy is under the crosshair or within the radius (and visible). Teammates are skipped; Deathmatch makes everybody an enemy. If it finds targets but nothing shoots, change Fire Method and press Test Fire: Mouse = executor mouse1click, Tool = activates the equipped tool, Virtual = virtual mouse click, Signal = fires the tool's Activated event. Click mode clicks every interval, Hold keeps the trigger down.", 100, Theme.muted, false, 11)

    State.refreshers[#State.refreshers + 1] = function()
        triggerEnabledSet(Config.Trigger.Enabled, true)
        triggerModeSet(indexOf(TRIGGER_MODES, Config.Trigger.Mode), true)
        triggerDelaySet(Config.Trigger.Delay, true)
        triggerIntervalSet(Config.Trigger.Interval, true)
        triggerDistanceSet(Config.Trigger.MaxDistance, true)
        triggerHeadSet(Config.Trigger.HeadOnly, true)
        triggerSilentSet(Config.Trigger.UseSilent, true)
        triggerRadiusSet(Config.Trigger.Radius, true)
        triggerMethodSet(indexOf(FIRE_METHODS, Config.Trigger.Method), true)
    end

    -- ===== Kill sounds =====
    makeSection(soundsPage, "Kill sound")
    local soundEnabledSet = makeToggle(soundsPage, "Kill Sound", Config.Sounds.KillEnabled, function(value)
        Config.Sounds.KillEnabled = value
    end)
    local soundPresetSet
    soundPresetSet = makeCycle(soundsPage, "Sound", SOUND_PRESET_NAMES, indexOf(SOUND_PRESET_NAMES, Config.Sounds.Preset), function(name)
        Config.Sounds.Preset = name
        if not playKillSound() then
            notify("Для этого пункта вставь ID или ссылку ниже", Theme.muted)
        end
    end)
    local soundCustomSet = makeInput(soundsPage, "Custom sound (ID or direct link)", "123456789  /  rbxassetid://...  /  https://...mp3", Config.Sounds.Custom, function(text)
        Config.Sounds.Custom = trimText(text)
        if Config.Sounds.Custom ~= "" then
            Config.Sounds.Preset = "Custom ID / URL"
            soundPresetSet(indexOf(SOUND_PRESET_NAMES, Config.Sounds.Preset), true)
            currentSoundSource() -- starts the download for links
        end
    end)
    local soundVolumeSet = makeSlider(soundsPage, "Volume", 0.5, 10, Config.Sounds.Volume, 0.5, function(value)
        Config.Sounds.Volume = value
    end)
    makeButton(soundsPage, "Test Sound", function()
        if not playKillSound() then
            notify("Нет звука: выбери пресет или вставь ID / ссылку", Theme.danger)
        end
    end, Theme.accent)
    makeLabel(soundsPage, "The sound plays only for YOUR kills. It uses the game's Kills / Eliminations stat when there is one, then the killer tag on the victim's Humanoid, and if the game has neither, only when you were shooting at that enemy and they died within a second. Presets are public Roblox audio IDs and may stop working if Roblox removes them; a direct link to an mp3 / ogg / wav (or any other ID) always works through Custom.", 98, Theme.muted, false, 11)

    State.refreshers[#State.refreshers + 1] = function()
        soundEnabledSet(Config.Sounds.KillEnabled, true)
        soundPresetSet(indexOf(SOUND_PRESET_NAMES, Config.Sounds.Preset), true)
        soundCustomSet(Config.Sounds.Custom)
        soundVolumeSet(Config.Sounds.Volume, true)
    end

    -- ===== Local knife =====
    makeSection(knifePage, "Local knife")
    local knifeEnabledSet = makeToggle(knifePage, "Local Knife (only you can see it)", Config.Knife.Enabled, function(value)
        Config.Knife.Enabled = value
        if value and Config.Knife.Knife == Knife.assetName then Knife.loadAsset() end
    end)
    local knifeTypeSet = makeCycle(knifePage, "Knife", Knife.names, indexOf(Knife.names, Config.Knife.Knife), function(name)
        Config.Knife.Knife = name
        if name == Knife.assetName then Knife.loadAsset() end
    end)
    local knifeSkinSet = makeCycle(knifePage, "Skin", Knife.skinNames, indexOf(Knife.skinNames, Config.Knife.Skin), function(name)
        Config.Knife.Skin = name
    end)

    makeSection(knifePage, "Animation")
    local knifeAutoSet = makeToggle(knifePage, "Auto Inspect", Config.Knife.AutoInspect, function(value)
        Config.Knife.AutoInspect = value
    end)
    local knifeEverySet = makeSlider(knifePage, "Inspect every (seconds)", 3, 30, Config.Knife.InspectEvery, 1, function(value)
        Config.Knife.InspectEvery = value
    end)
    makeButton(knifePage, "Inspect Now", function()
        Knife.startInspect()
    end, Theme.accent)

    makeSection(knifePage, "Look")
    local knifeHideSet = makeToggle(knifePage, "Hide the weapon in my hand", Config.Knife.HideTools, function(value)
        Config.Knife.HideTools = value
        Knife.toolsAt = 0
    end)
    local knifeScaleSet = makeSlider(knifePage, "Size", 0.6, 2, Config.Knife.Scale, 0.1, function(value)
        Config.Knife.Scale = value
    end)
    local knifeAngleSet = makeSlider(knifePage, "Hold Angle", -90, 90, Config.Knife.HoldAngle, 5, function(value)
        Config.Knife.HoldAngle = value
    end)

    makeSection(knifePage, "Roblox model")
    makeButton(knifePage, "Rotate Model 90°", function()
        Config.Knife.AssetRoll = (Config.Knife.AssetRoll + 1) % 4
    end, Theme.panel)
    makeButton(knifePage, "Flip Model (tip the other way)", function()
        Config.Knife.AssetFlip = not Config.Knife.AssetFlip
    end, Theme.panel)
    local knifeStatusLabel = makeLabel(knifePage, "", 22, Theme.accent, false, 12)
    makeLabel(knifePage, "The knife exists only on your screen: other players do not see it and it does nothing in the game. It is attached to your right hand, so you can run, jump and bunny hop with it. It draws itself with an animation, sways while you run and plays an inspect flip every few seconds. 'Butterfly (Roblox model)' loads a real knife model from the Roblox Creator Store through your executor (game:GetObjects); if it points the wrong way use Rotate / Flip. If it cannot be loaded, the built-in butterfly is used.", 120, Theme.muted, false, 11)

    State.refreshers[#State.refreshers + 1] = function()
        knifeEnabledSet(Config.Knife.Enabled, true)
        knifeTypeSet(indexOf(Knife.names, Config.Knife.Knife), true)
        knifeSkinSet(indexOf(Knife.skinNames, Config.Knife.Skin), true)
        knifeAutoSet(Config.Knife.AutoInspect, true)
        knifeEverySet(Config.Knife.InspectEvery, true)
        knifeHideSet(Config.Knife.HideTools, true)
        knifeScaleSet(Config.Knife.Scale, true)
        knifeAngleSet(Config.Knife.HoldAngle, true)
    end

    -- ===== Optimization =====
    makeSection(optimizePage, "Explosions")
    local optExplosionsSet = makeToggle(optimizePage, "Remove Explosion Effects", Config.Optimize.Explosions, function(value)
        Config.Optimize.Explosions = value
        Opt.refresh()
    end)
    local optDebrisSet = makeToggle(optimizePage, "Debris Cleaner (loose parts after explosions)", Config.Optimize.DebrisCleaner, function(value)
        Config.Optimize.DebrisCleaner = value
        Opt.refresh()
    end)

    makeSection(optimizePage, "Effects")
    local optEffectsSet = makeToggle(optimizePage, "Remove Particles / Fire / Smoke / Trails / Lights", Config.Optimize.Effects, function(value)
        Config.Optimize.Effects = value
        Opt.refresh()
    end)
    local optPostFxSet = makeToggle(optimizePage, "Disable Post-Processing (blur, bloom, sun rays)", Config.Optimize.PostFX, function(value)
        Config.Optimize.PostFX = value
        Opt.refresh()
    end)

    makeSection(optimizePage, "Graphics")
    local optShadowsSet = makeToggle(optimizePage, "Disable Shadows", Config.Optimize.Shadows, function(value)
        Config.Optimize.Shadows = value
        Opt.refresh()
    end)
    local optQualitySet = makeToggle(optimizePage, "Lowest Graphics Quality", Config.Optimize.LowQuality, function(value)
        Config.Optimize.LowQuality = value
        Opt.refresh()
    end)
    local optMaterialsSet = makeToggle(optimizePage, "Flat Materials (no reflections)", Config.Optimize.Materials, function(value)
        Config.Optimize.Materials = value
        Opt.refresh()
    end)
    local optTexturesSet = makeToggle(optimizePage, "Hide Decals & Textures", Config.Optimize.Textures, function(value)
        Config.Optimize.Textures = value
        Opt.refresh()
    end)

    local function syncOptimizeToggles()
        optExplosionsSet(Config.Optimize.Explosions, true)
        optDebrisSet(Config.Optimize.DebrisCleaner, true)
        optEffectsSet(Config.Optimize.Effects, true)
        optPostFxSet(Config.Optimize.PostFX, true)
        optShadowsSet(Config.Optimize.Shadows, true)
        optQualitySet(Config.Optimize.LowQuality, true)
        optMaterialsSet(Config.Optimize.Materials, true)
        optTexturesSet(Config.Optimize.Textures, true)
    end
    makeButton(optimizePage, "Max FPS (turn everything on)", function()
        local cfg = Config.Optimize
        cfg.Explosions, cfg.Effects, cfg.PostFX, cfg.Shadows = true, true, true, true
        cfg.LowQuality, cfg.Materials, cfg.Textures = true, true, true
        syncOptimizeToggles()
        Opt.refresh()
        notify("Оптимизация: всё включено", Theme.accent)
    end, Theme.accent)
    makeButton(optimizePage, "Restore Everything", function()
        local cfg = Config.Optimize
        for key in pairs(cfg) do cfg[key] = false end
        syncOptimizeToggles()
        Opt.refresh()
        notify("Всё возвращено как было", Theme.muted)
    end, Theme.panel)
    local optimizeStatusLabel = makeLabel(optimizePage, "", 22, Theme.accent, false, 12)
    makeLabel(optimizePage, "Everything here changes only what YOUR client draws; nothing is sent to the server. Explosion effects are Roblox's official Explosion objects: their visual effect is switched off the moment they appear. Debris Cleaner deletes small loose parts around an explosion (client side only) - turn it on if the lag comes from flying pieces. Flat Materials and Hide Decals go through the whole map in small batches, and Restore Everything puts all original values back.", 110, Theme.muted, false, 11)

    State.refreshers[#State.refreshers + 1] = function()
        syncOptimizeToggles()
        Opt.refresh()
    end

    makeSection(settingsPage, "Interface")
    local guiScaleSet = makeSlider(settingsPage, "GUI Scale", 0.6, 1.2, Config.Settings.GUIScale, 0.05, function(value)
        Config.Settings.GUIScale = value
        if State.guiScale then State.guiScale.Scale = value end
        if State.refreshGuiLayout then State.refreshGuiLayout() end
    end)
    local showFovSet = makeToggle(settingsPage, "Show FOV Circle", Config.Settings.ShowFOV, function(value)
        Config.Settings.ShowFOV = value
    end)
    local mouseHookSet = makeToggle(settingsPage, "Mouse Hook (index)", Config.Silent.MouseHook, function(value)
        Config.Silent.MouseHook = value
        if value then
            if Config.Silent.Enabled then installSilentHooks() end
        else
            restoreIndexHook()
        end
    end)
    makeButton(settingsPage, "Reset Config", function()
        if resetConfig then resetConfig() end
    end, Theme.accent2)
    makeButton(settingsPage, "Reset GUI Position", function()
        resetGuiPosition()
    end, Theme.panel)

    makeSection(settingsPage, "Diagnostics")
    makeToggle(settingsPage, "Shot Probe (shoot a few times)", false, function(value)
        State.probe.on = value
        if value then
            if installNamecallHook() then
                notify("Probe ON - shoot, then Copy Probe Log", Theme.accent)
            else
                notify("Probe: namecall hook unavailable", Theme.danger)
            end
            updateHookStatus()
        elseif not Config.Silent.Enabled then
            restoreHooks()
        end
    end)
    makeButton(settingsPage, "Copy Probe Log", function()
        local entries = {}
        for _, key in ipairs(State.probe.order) do
            entries[#entries + 1] = { key = key, count = State.probe.entries[key].count }
        end
        table.sort(entries, function(a, b) return a.count > b.count end)
        local lines = { "Noob Warfare probe | executor: " .. tostring(State.executor) }
        for _, entry in ipairs(entries) do
            lines[#lines + 1] = string.format("%dx  %s", entry.count, entry.key)
        end
        local text = table.concat(lines, "\n")
        if type(setclipboard) == "function" and pcall(setclipboard, text) then
            notify("Copied " .. #entries .. " probe entries", Theme.accent)
        else
            print(text)
            notify("No clipboard - probe log printed to console", Theme.muted)
        end
    end, Theme.accent2)
    makeButton(settingsPage, "Clear Probe Log", function()
        State.probe.entries = {}
        State.probe.order = {}
        notify("Probe log cleared", Theme.muted)
    end, Theme.panel)

    local teamSourceButton
    local function teamSourceText()
        return "Team Source: " .. tostring(Config.Settings.TeamSource or "Auto")
    end
    teamSourceButton = makeButton(settingsPage, teamSourceText(), function()
        local options = { "Auto" }
        for _, candidate in ipairs(getCachedTeamCandidates(LocalPlayer)) do
            options[#options + 1] = candidate.source
        end
        local current = Config.Settings.TeamSource or "Auto"
        local nextIndex = 1
        for index, name in ipairs(options) do
            if name == current then
                nextIndex = index % #options + 1
                break
            end
        end
        Config.Settings.TeamSource = options[nextIndex]
        invalidateTeamCache()
        teamSourceButton.Text = teamSourceText()
        notify(teamSourceText(), Theme.accent)
    end, Theme.accent2)
    State.refreshers[#State.refreshers + 1] = function()
        teamSourceButton.Text = teamSourceText()
        invalidateTeamCache()
    end
    makeButton(settingsPage, "Reinstall Hooks", function()
        if reinstallHooks then reinstallHooks() end
    end, Theme.panel)
    makeButton(settingsPage, "Panic / Unload", function()
        if unload then unload() end
    end, Theme.danger)

    State.refreshers[#State.refreshers + 1] = function() guiScaleSet(Config.Settings.GUIScale, true) end
    State.refreshers[#State.refreshers + 1] = function() showFovSet(Config.Settings.ShowFOV, true) end
    State.refreshers[#State.refreshers + 1] = function() mouseHookSet(Config.Silent.MouseHook, true) end

    makeSection(settingsPage, "Runtime")
    State.runtimeLabels.executor = makeLabel(settingsPage, "Executor: " .. State.executor, 24, Theme.muted, false, 11)
    State.runtimeLabels.hooks = makeLabel(settingsPage, "Hooks: checking...", 28, Theme.muted, false, 11)
    State.runtimeLabels.hits = makeLabel(settingsPage, "Hook hits: R:0 N:0 M:0", 18, Theme.muted, false, 11)
    State.runtimeLabels.drawing = makeLabel(settingsPage, "Drawing: " .. (Cap.Drawing and "yes" or "no (Highlight fallback)"), 24, Theme.muted, false, 11)
    State.runtimeLabels.rig = makeLabel(settingsPage, "Rig: checking...", 18, Theme.muted, false, 11)
    State.runtimeLabels.team = makeLabel(settingsPage, "Team: checking...", 36, Theme.muted, false, 11)
    State.runtimeLabels.game = makeLabel(settingsPage, string.format("Place: %s | Job: %s", tostring(game.PlaceId), tostring(game.JobId)), 28, Theme.muted, false, 11)
    State.runtimeLabels.players = makeLabel(settingsPage, "Players: 0 / 32", 18, Theme.muted, false, 11)
    State.runtimeLabels.fps = makeLabel(settingsPage, "FPS: 0", 18, Theme.muted, false, 11)
    makeLabel(settingsPage, "Noob Warfare // 4080 build. Touch-first controls.", 18, Theme.muted, false, 10)

    -- ===== quick toggles (bottom bar) =====
    local features = {
        aim = { label = "Aimbot", get = function() return Config.Aimbot.Enabled end, set = aimEnabledSet },
        silent = { label = "Silent Aim", get = function() return Config.Silent.Enabled end, set = silentEnabledSet },
        trigger = { label = "Trigger", get = function() return Config.Trigger.Enabled end, set = triggerEnabledSet },
        esp = { label = "ESP", get = function() return Config.ESP.Enabled end, set = espEnabledSet },
        aa = { label = "Anti-Aim", get = function() return Config.AntiAim.Enabled end, set = aaEnabledSet },
        bhop = { label = "Bunny Hop", get = function() return Config.Movement.Bhop end, set = bhopSet },
        knife = { label = "Knife", get = function() return Config.Knife.Enabled end, set = knifeEnabledSet },
    }
    local function toggleFeature(key)
        local feature = features[key]
        local newValue = not feature.get()
        feature.set(newValue)
        notify(feature.label .. (newValue and ": включён" or ": выключен"), newValue and Theme.accent or Theme.muted)
    end
    local function setDeathmatch(value)
        Config.Settings.Deathmatch = value and true or false
        invalidateTeamCache()
        notify(Config.Settings.Deathmatch and "Deathmatch: все игроки — враги" or "Teams: свои скрыты", Theme.accent)
    end

    -- ===== tabs =====
    local tabOrder = { "Aimbot", "Silent Aim", "Trigger", "ESP", "Movement", "Anti-Aim", "Sounds", "Knife", "Optimize", "Settings" }
    local tabLabels = { Settings = "Настройки", Optimize = "Оптимизация", Knife = "Ножи" }
    State.openTabs = {}

    local function createTabPill(id)
        local frame = Instance.new("TextButton")
        frame.Name = "Tab_" .. id
        frame.Size = UDim2.fromOffset(0, 36)
        frame.AutomaticSize = Enum.AutomaticSize.X
        frame.BackgroundColor3 = Theme.tabActive
        frame.BackgroundTransparency = 1
        frame.Text = ""
        frame.AutoButtonColor = false
        frame.LayoutOrder = indexOf(tabOrder, id)
        frame.Parent = tabScroll
        addCorner(frame, 12)
        local framePadding = Instance.new("UIPadding")
        framePadding.PaddingLeft = UDim.new(0, 16)
        framePadding.PaddingRight = UDim.new(0, 16)
        framePadding.Parent = frame

        local label = Instance.new("TextLabel")
        label.Size = UDim2.fromOffset(0, 36)
        label.AutomaticSize = Enum.AutomaticSize.X
        label.BackgroundTransparency = 1
        label.Text = tabLabels[id] or id
        label.TextColor3 = Theme.muted
        label.TextSize = 17
        label.Font = FONT
        label.Active = false
        label.Parent = frame

        frame.Activated:Connect(function() selectTab(id) end)
        pressable(frame, 0.96)
        State.tabPills[id] = { frame = frame, label = label }
        State.openTabs[id] = true
    end
    for _, id in ipairs(tabOrder) do createTabPill(id) end

    -- ===== bottom quick bar =====
    local keyButtons = {}
    local function makeKey(label, onTap, isActive)
        local key = Instance.new("TextButton")
        key.Size = UDim2.fromOffset(0, 38)
        key.AutomaticSize = Enum.AutomaticSize.X
        key.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
        key.Text = label
        key.TextColor3 = Color3.fromRGB(222, 222, 226)
        key.TextSize = 16
        key.Font = FONT
        key.AutoButtonColor = false
        key.LayoutOrder = #keyButtons + 1
        key.Parent = keysBar
        addCorner(key, 12)
        local stroke = addStroke(key, Color3.fromRGB(48, 48, 50), 1.5, 0)
        local keyPadding = Instance.new("UIPadding")
        keyPadding.PaddingLeft = UDim.new(0, 16)
        keyPadding.PaddingRight = UDim.new(0, 16)
        keyPadding.Parent = key
        pressable(key, 0.92)
        key.Activated:Connect(onTap)
        keyButtons[#keyButtons + 1] = { key = key, stroke = stroke, isActive = isActive }
        return key
    end

    local function refreshKeys()
        for _, entry in ipairs(keyButtons) do
            if entry.isActive then
                local active = entry.isActive()
                tween(entry.stroke, 0.2, { Color = active and Theme.accent or Color3.fromRGB(48, 48, 50) })
                tween(entry.key, 0.2, { TextColor3 = active and Theme.accent or Color3.fromRGB(222, 222, 226) })
            end
        end
    end

    makeKey("Aimbot", function() toggleFeature("aim"); refreshKeys() end, features.aim.get)
    makeKey("Silent", function() toggleFeature("silent"); refreshKeys() end, features.silent.get)
    makeKey("Trigger", function() toggleFeature("trigger"); refreshKeys() end, features.trigger.get)
    makeKey("ESP", function() toggleFeature("esp"); refreshKeys() end, features.esp.get)
    makeKey("Anti-Aim", function() toggleFeature("aa"); refreshKeys() end, features.aa.get)
    makeKey("Bhop", function() toggleFeature("bhop"); refreshKeys() end, features.bhop.get)
    makeKey("Knife", function() toggleFeature("knife"); refreshKeys() end, features.knife.get)
    makeKey("Deathmatch", function()
        setDeathmatch(not Config.Settings.Deathmatch)
        refreshKeys()
    end, function() return Config.Settings.Deathmatch end)
    local unloadKey
    local unloadArmed = false
    unloadKey = makeKey("Unload", function()
        if unloadArmed then
            if unload then unload() end
            return
        end
        unloadArmed = true
        unloadKey.Text = "Unload?"
        tween(unloadKey, 0.2, { TextColor3 = Theme.danger })
        task.delay(2.5, function()
            unloadArmed = false
            if unloadKey and unloadKey.Parent then
                unloadKey.Text = "Unload"
                tween(unloadKey, 0.2, { TextColor3 = Color3.fromRGB(222, 222, 226) })
            end
        end)
    end)

    State.homeStatus = function()
        refreshKeys()
        knifeStatusLabel.Text = "Модель Roblox: " .. tostring(Knife.assetStatus)
        optimizeStatusLabel.Text = string.format("Взрывов обработано: %d   |   Изменено: %d", Opt.explosions, Opt.touched)
        triggerStatusLabel.Text = string.format("Луч: %s   |   Цель: %s   |   Метод: %s   |   Выстрелов: %d",
            State.triggerRayInfo or "—", State.triggerTargetName or "нет", State.triggerMethodName or resolveFireMethod(), State.triggerShots)
    end
    State.homeStatus()

    -- ===== drag (by the top handle) =====
    local dragging = false
    local dragStart = nil
    local dragCenter = nil
    header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = Vector2.new(input.Position.X, input.Position.Y)
            dragCenter = State.guiCenter
            if not dragCenter then
                dragCenter = Vector2.new(
                    main.AbsolutePosition.X + main.AbsoluteSize.X * 0.5,
                    main.AbsolutePosition.Y + main.AbsoluteSize.Y * 0.5
                )
            end
            tween(grabber, 0.15, { BackgroundColor3 = Theme.accent, Size = UDim2.fromOffset(58, 5), Position = UDim2.new(0.5, -29, 0, 10) })
        end
    end)
    connect(UserInputService.InputChanged, function(input)
        if not dragging or not dragStart or not dragCenter then return end
        if input.UserInputType ~= Enum.UserInputType.Touch and input.UserInputType ~= Enum.UserInputType.MouseMovement then return end
        local position = Vector2.new(input.Position.X, input.Position.Y)
        setGuiCenter(dragCenter + (position - dragStart))
    end)
    connect(UserInputService.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            if dragging then
                tween(grabber, 0.25, { BackgroundColor3 = Theme.track, Size = UDim2.fromOffset(46, 5), Position = UDim2.new(0.5, -23, 0, 10) }, Enum.EasingStyle.Back)
            end
            dragging = false
            dragStart = nil
            dragCenter = nil
        end
    end)

    if Cap.Drawing then
        State.fovDrawing = newDrawing("Circle")
        State.silentMarker = newDrawing("Circle")
        if State.fovDrawing then State.fovDrawing.Visible = false end
        if State.silentMarker then State.silentMarker.Visible = false end
    end
    if not State.fovDrawing then
        local ring = Instance.new("Frame")
        ring.Name = "4080_FOV"
        ring.Size = UDim2.fromOffset(200, 200)
        ring.AnchorPoint = Vector2.new(0.5, 0.5)
        ring.Position = UDim2.new(0.5, 0, 0.5, 0)
        ring.BackgroundTransparency = 1
        ring.BorderSizePixel = 0
        ring.Active = false
        ring.Visible = false
        ring.ZIndex = 0
        ring.Parent = gui
        addCorner(ring, 9999)
        local ringStroke = Instance.new("UIStroke")
        ringStroke.Color = Theme.accent
        ringStroke.Thickness = 1
        ringStroke.Transparency = 0.45
        ringStroke.Parent = ring
        State.fovRing = ring
    end

    -- intro: the window pops in and fades up
    local introCover = Instance.new("Frame")
    introCover.Size = UDim2.fromScale(1, 1)
    introCover.BackgroundColor3 = Theme.bg
    introCover.BorderSizePixel = 0
    introCover.Active = false
    introCover.ZIndex = 150
    introCover.Parent = main
    local targetScale = Config.Settings.GUIScale
    guiScale.Scale = targetScale * 0.88
    tween(guiScale, 0.65, { Scale = targetScale }, Enum.EasingStyle.Back)
    local introFade = tween(introCover, 0.5, { BackgroundTransparency = 1 })
    introFade.Completed:Connect(function() introCover:Destroy() end)

    selectTab("Aimbot")
    updateHookStatus()
end

refreshAll = function()
    for _, refresher in ipairs(State.refreshers) do
        pcall(refresher)
    end
end

resetConfig = function()
    Config = defaultConfig()
    local viewportSize = Camera and Camera.ViewportSize or Vector2.new(1920, 1080)
    local fitScale = clamp(math.min((viewportSize.Y - 40) / 410, (viewportSize.X - 20) / 600), 0.5, 1)
    if Config.Settings.GUIScale > fitScale then
        Config.Settings.GUIScale = fitScale
    end
    if State.hooksInstalled or State.restoreIndex then
        restoreHooks()
    end
    if State.guiScale then State.guiScale.Scale = Config.Settings.GUIScale end
    refreshAll()
    applyMovementSettings()
    setNoclip(false)
    stopFly()
    State.flyUp = false
    State.flyDown = false
    notify("Config reset", Theme.accent)
end

installSilentHooks = function()
    if not Config.Silent.Enabled then
        updateHookStatus()
        return
    end
    if State.hooksInstalled then
        if Config.Silent.MouseHook then installIndexHook() end
        return
    end
    State.hooksInstalled = true
    local raycast = installRaycastHook()
    local namecall = installNamecallHook()
    local index = false
    if Config.Silent.MouseHook then index = installIndexHook() end
    updateHookStatus()
    if not raycast and not namecall and not index then
        notify("Silent Aim: no compatible hooks in this executor", Theme.danger)
    else
        local parts = {}
        if raycast then parts[#parts + 1] = "Raycast" end
        if namecall then parts[#parts + 1] = "Namecall" end
        if index then parts[#parts + 1] = "Mouse" end
        notify("Hooks installed: " .. table.concat(parts, " + "), Theme.accent)
    end
end

reinstallHooks = function()
    restoreHooks()
    State.hooksInstalled = false
    if Config.Silent.Enabled then
        installSilentHooks()
    else
        updateHookStatus()
        notify("Silent Aim is off - hooks idle", Theme.muted)
    end
end

unload = function()
    if State.unloaded then return end
    State.unloaded = true
    pcall(Opt.shutdown)
    Config.Knife.Enabled = false
    pcall(Knife.destroy)
    Config.Trigger.Enabled = false
    pcall(releaseTrigger)
    Config.AntiAim.Enabled = false
    pcall(updateBodyJoints, 0)
    pcall(function() RunService:UnbindFromRenderStep("4080_AA") end)
    closeDropdown()
    pcall(function() RunService:UnbindFromRenderStep("4080_Render") end)
    restoreHooks()
    fullUnhook()
    stopFly()
    setNoclip(false)
    local _, humanoid = getCharacter(LocalPlayer)
    if humanoid then
        humanoid.WalkSpeed = State.defaultWalkSpeed
        humanoid.UseJumpPower = State.defaultUseJumpPower
        if State.defaultUseJumpPower then
            humanoid.JumpPower = State.defaultJumpPower
        else
            humanoid.JumpHeight = State.defaultJumpHeight
        end
    end
    local espPlayers = {}
    for player in pairs(State.esp) do espPlayers[#espPlayers + 1] = player end
    for _, player in ipairs(espPlayers) do destroyESP(player) end
    removeDrawing(State.fovDrawing)
    removeDrawing(State.silentMarker)
    for _, connection in ipairs(State.connections) do
        pcall(function() connection:Disconnect() end)
    end
    State.connections = {}
    if State.gui then pcall(function() State.gui:Destroy() end) end
    State.gui = nil
    print("[4080] unloaded")
end

local function updateRuntime(dt)
    State.teamRefreshAccum = State.teamRefreshAccum + dt
    if State.teamRefreshAccum >= 60 then
        State.teamRefreshAccum = 0
        State.teamCache = {}
    end
    State.fpsAccum = State.fpsAccum + dt
    State.fpsFrames = State.fpsFrames + 1
    if State.fpsAccum >= 0.5 then
        State.fps = math.floor(State.fpsFrames / State.fpsAccum + 0.5)
        State.fpsAccum = 0
        State.fpsFrames = 0
        if State.runtimeLabels.fps then
            State.runtimeLabels.fps.Text = "FPS: " .. tostring(State.fps)
        end
        if State.runtimeLabels.players then
            State.runtimeLabels.players.Text = "Players: " .. tostring(#(Players:GetPlayers())) .. " / 32"
        end
        if State.runtimeLabels.hits then
            State.runtimeLabels.hits.Text = string.format("Hook hits: R:%d N:%d M:%d",
                State.hookHits.Raycast, State.hookHits.Namecall, State.hookHits.Mouse)
        end
        if State.runtimeLabels.rig then
            local character = getCharacter(LocalPlayer)
            local rig = "?"
            if character then
                rig = character:FindFirstChild("UpperTorso") and "R15" or "R6"
            end
            State.runtimeLabels.rig.Text = "Rig: " .. rig
        end
        if State.runtimeLabels.team then
            local candidates = getCachedTeamCandidates(LocalPlayer)
            local text = "Team: unknown (no Team/attr)"
            if #candidates > 0 then
                text = "Team: " .. candidates[1].source .. "=" .. candidates[1].value
            end
            local allies, enemies, unknown = 0, 0, 0
            for _, other in ipairs(Players:GetPlayers()) do
                if other ~= LocalPlayer then
                    local ally = resolveTeam(other)
                    if ally == true then
                        allies = allies + 1
                    elseif ally == false then
                        enemies = enemies + 1
                    else
                        unknown = unknown + 1
                    end
                end
            end
            text = text .. string.format("\nAllies: %d | Enemies: %d | Unknown: %d", allies, enemies, unknown)
            State.runtimeLabels.team.Text = text
        end
        updateHookStatus()
        if State.homeStatus then pcall(State.homeStatus) end
    end
end

local function onRender(dt)
    if State.unloaded then return end
    if not Camera then Camera = Workspace.CurrentCamera end
    if not Camera then return end
    State.frameId = State.frameId + 1
    local clock = os.clock()
    if clock - State.partCacheTime > 2 then
        State.partCacheTime = clock
        State.partCache = setmetatable({}, { __mode = "k" })
    end
    pcall(updateFOV)
    pcall(updateBodyJoints, dt)
    pcall(Knife.update, dt)
    -- aimbot, silent aim and trigger bot now run every frame (they used to run at 30 Hz)
    pcall(updateAimbot, dt)
    pcall(updateSilentTarget)
    pcall(updateSilentMarker)
    pcall(updateTrigger)

    State.espAccum = State.espAccum + dt
    local espInterval = 1 / math.max(Config.ESP.UpdateRate, 1)
    if State.espAccum >= espInterval then
        State.espAccum = 0
        pcall(updateESP)
    end

    pcall(updateRuntime, dt)
end

connect(Workspace:GetPropertyChangedSignal("CurrentCamera"), function()
    Camera = Workspace.CurrentCamera
end)

connect(Players.PlayerRemoving, function(player)
    destroyESP(player)
    State.teamCache[player] = nil
end)

connect(Players.PlayerAdded, function(player)
    watchPlayer(player)
    State.teamCache = {}
end)

for _, player in ipairs(Players:GetPlayers()) do
    watchPlayer(player)
end

connect(LocalPlayer.CharacterAdded, function()
    State.joints = nil
    State.rootModified = false
    State.neckModified = false
    invalidateTeamCache()
    State.noclipOriginal = {}
    State.noclipWasOn = false
    State.flyVelocity = nil
    task.wait(0.6)
    if State.unloaded then return end
    captureDefaults()
    applyMovementSettings()
    if Config.Movement.Noclip then setNoclip(true) end
    if Config.Movement.FlyEnabled then startFly() end
end)

task.spawn(function()
    if not LocalPlayer.Character then
        LocalPlayer.CharacterAdded:Wait()
    end
    task.wait(0.8)
    if State.unloaded then return end
    captureDefaults()
    applyMovementSettings()
end)

local guiOk, guiError = pcall(buildGUI)
if not guiOk then
    warn("[4080] GUI build failed: " .. tostring(guiError))
    if State.gui then
        pcall(function() State.gui:Destroy() end)
        State.gui = nil
    end
    for _, connection in ipairs(State.connections) do
        pcall(function() connection:Disconnect() end)
    end
    State.connections = {}
else
    local bindOk, bindError = pcall(function()
        RunService:BindToRenderStep("4080_Render", Enum.RenderPriority.Camera.Value + 1, onRender)
    end)
    if not bindOk then
        warn("[4080] render bind failed: " .. tostring(bindError))
    end

    connect(RunService.Heartbeat, function(dt)
        pcall(updateMovement, dt)
        pcall(reapplyBodyJoints)
    end)
    connect(RunService.Stepped, function()
        pcall(reapplyBodyJoints)
    end)
    connect(UserInputService.JumpRequest, function()
        State.jumpHeldUntil = os.clock() + 0.3
    end)
    pcall(function()
        RunService:BindToRenderStep("4080_AA", Enum.RenderPriority.Last.Value, function()
            pcall(reapplyBodyJoints)
        end)
    end)

    if game.PlaceId == GAME.PlaceId then
        notify("Noob Warfare loaded // 4080", Theme.accent)
    else
        notify("Place " .. tostring(game.PlaceId) .. " // universal mode", Color3.fromRGB(255, 180, 80))
    end
end






