-- area51.lua | RealYoHub (PremiumUI GameBridge auto-handshake)
-- 第一行必须是本注释：用于确认 GitHub 上是 handshake 版
local GAME = { Name = "RealYoHub Area51", Brand = "PremiumUI" }

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

_G.savedPosition = _G.savedPosition or nil

local Runtime = { Mode = "Original", Bridge = nil, Host = nil }

-------------------------------------------------
-- 工具：阶段保护（错误打印到 console，不再被宿主按钮吞掉）
-------------------------------------------------
local function SafeCall(tag, fn, ...)
    local ok, err = pcall(fn, ...)
    if not ok then
        warn(("[RealYoHub][ERR] %s : %s"):format(tag, tostring(err)))
    end
    return ok
end

-------------------------------------------------
-- 1) 宿主检测（5秒重试 + 自诊断）
-------------------------------------------------
local AUTO_ACCEPT = true -- future: 改成询问框结果

local function FindHostUI(timeout)
    timeout = timeout or 5
    local sources = {
        { name = "shared",  get = function() return shared and shared.PremiumUI end },
        { name = "_G",      get = function() return _G and _G.PremiumUI end },
        { name = "getgenv", get = function()
            local ok, g = pcall(getgenv)
            return ok and g and g.PremiumUI
        end },
    }
    local deadline = tick() + timeout
    local why = "三个注册表全空：宿主未发布（末尾 Bridge 追加块没加/宿主没跑完）"
    while true do
        for _, src in ipairs(sources) do
            local ok, obj = pcall(src.get)
            if ok and type(obj) == "table" then
                if obj.IsPremiumUI ~= true then
                    why = "命中 " .. src.name .. " 但 IsPremiumUI=false"
                elseif obj.Brand ~= GAME.Brand then
                    why = "命中 " .. src.name .. " 但品牌不符: " .. tostring(obj.Brand)
                elseif type(obj.RequestGameBridge) ~= "function" or type(obj.RenameMain) ~= "function" then
                    why = "命中 " .. src.name .. " 但缺 Bridge/Rename API（宿主是未补装的旧单体版）"
                elseif obj.Initialized ~= true then
                    why = "命中 " .. src.name .. " 但宿主尚未初始化"
                else
                    return obj, src.name
                end
            end
        end
        if tick() >= deadline then break end
        task.wait(0.2)
    end
    return nil, why
end

local HostUI, whyOrSrc = FindHostUI(5)

if HostUI then
    print(("[RealYoHub] 检测到宿主(via %s)，自动握手"):format(whyOrSrc))
else
    warn("[RealYoHub] 未握手，回退 WindUI。原因: " .. tostring(whyOrSrc))
end

if AUTO_ACCEPT and HostUI then
    local ok, bridgeOrErr = HostUI:RequestGameBridge({
        Brand = GAME.Brand,
        Protocol = HostUI.BridgeProtocol or 2,
        Name = GAME.Name,
        Category = "腳本中心",
        Sub = "自家腳本",
        Mode = "Replace",
        Focus = false,
    })
    if ok and type(bridgeOrErr) == "table" then
        Runtime.Mode = "Host"
        Runtime.Bridge = bridgeOrErr
        Runtime.Host = HostUI
    else
        warn("[RealYoHub] handshake failed:", tostring(bridgeOrErr))
    end
end

-------------------------------------------------
-- 2) 接管映射改名（核心同tab聚合 / 通用进空白tab / 替换即改名）
-------------------------------------------------
if Runtime.Mode == "Host" then
    SafeCall("RenameMain4", function() HostUI:RenameMain(4, "RealYoHub") end)
    SafeCall("RenameSub41", function() HostUI:RenameSub(4, 1, "Area 51") end)
    SafeCall("RenameSub42", function() HostUI:RenameSub(4, 2, "Gun Modded") end)
    SafeCall("RenameSub43", function() HostUI:RenameSub(4, 3, "Teleport") end)
    SafeCall("RenameMain2", function() HostUI:RenameMain(2, "Universal Tools") end)
    SafeCall("RenameSub22", function() HostUI:RenameSub(2, 2, "FE Tools") end)
end

-------------------------------------------------
-- 3) 通知适配
-------------------------------------------------
local function Notify(title, content, duration, icon)
    if Runtime.Mode == "Host" and Runtime.Host and type(Runtime.Host.Toast) == "function" then
        pcall(function() Runtime.Host:Toast("[" .. title .. "] " .. tostring(content or "")) end)
    else
        pcall(function() Notifier.new({ Title = title, Content = content, Duration = duration or 5, Icon = icon or "info" }) end)
    end
end

-------------------------------------------------
-- 4) 适配器（功能代码只写一遍）
-------------------------------------------------
local function BridgeAdapter(bridge)
    local A = { _b = bridge }
    function A:Section(t) return self._b:Section(t) end
    function A:Label(t) return self._b:Label(t) end
    function A:Button(t, cb) return self._b:Button(t, cb) end
    function A:Toggle(t, def, cb) return self._b:Toggle(t, def, cb) end
    function A:Slider(t, min, max, def, cb) return self._b:Slider(t, min, max, def, cb) end
    function A:Input(t, placeholder, cb)
        local box = self._b:TextBox(placeholder, "")
        if box then
            box:GetPropertyChangedSignal("Text"):Connect(function() cb(box.Text) end)
        end
        return box
    end
    return A
end

local function WindAdapter(tab)
    local A = { _t = tab }
    function A:Section(t) if self._t.Section then pcall(function() self._t:Section({ Title = t }) end) end end
    function A:Label(t) if self._t.Label then pcall(function() self._t:Label({ Title = t }) end) end end
    function A:Button(t, cb) self._t:Button({ Title = t, Callback = cb }) end
    function A:Toggle(t, def, cb) self._t:Toggle({ Title = t, Default = def, Callback = cb }) end
    function A:Slider(t, min, max, def, cb)
        if self._t.Slider then self._t:Slider({ Title = t, Min = min, Max = max, Default = def, Callback = cb }) end
    end
    function A:Input(t, placeholder, cb) self._t:Input({ Title = t, Placeholder = placeholder, Callback = cb }) end
    return A
end

-------------------------------------------------
-- 5) 功能模块（逻辑 1:1 保留自原 area51）
-------------------------------------------------
local function BuildArea51(A)
    local speedHackConnection = nil
    local farmConn = nil

    A:Toggle("Speed Hack", false, function(v)
        pcall(function()
            local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
            local humanoid = char:WaitForChild("Humanoid")
            local root = char:WaitForChild("HumanoidRootPart")
            local teleportDistance = 1.5
            local teleportInterval = 0.01
            local lastTeleportTime = 0
            local rayParams = RaycastParams.new()
            rayParams.FilterDescendantsInstances = { char }
            rayParams.FilterType = Enum.RaycastFilterType.Exclude
            if v then
                speedHackConnection = RunService.Heartbeat:Connect(function()
                    if tick() - lastTeleportTime < teleportInterval then return end
                    local moveDir = humanoid.MoveDirection
                    if moveDir.Magnitude > 0 then
                        local teleportVector = moveDir * teleportDistance
                        local result = Workspace:Raycast(root.Position, teleportVector, rayParams)
                        if not result or result.Distance > teleportDistance then
                            root.CFrame = root.CFrame + Vector3.new(teleportVector.X, 0, teleportVector.Z)
                        end
                        lastTeleportTime = tick()
                    end
                end)
            else
                if speedHackConnection then speedHackConnection:Disconnect() speedHackConnection = nil end
            end
        end)
    end)

    A:Input("Fly Height", ".", function(Value)
        local height = tonumber(Value) or 0
        if height <= 0 then
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                local bp = LocalPlayer.Character.HumanoidRootPart:FindFirstChild("FloatBP")
                if bp then bp:Destroy() end
            end
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("FloatConn") then
                LocalPlayer.Character.FloatConn:Disconnect()
            end
            return
        end
        height = math.clamp(height, 1, 100)
        local function onCharacterAdded(character)
            if character:FindFirstChild("FloatConn") then character.FloatConn:Disconnect() end
            if character:FindFirstChild("HumanoidRootPart") then
                local bp = character.HumanoidRootPart:FindFirstChild("FloatBP")
                if bp then bp:Destroy() end
            end
            local humanoid = character:WaitForChild("Humanoid")
            local rootPart = character:WaitForChild("HumanoidRootPart")
            local bodyPos = Instance.new("BodyPosition")
            bodyPos.MaxForce = Vector3.new(0, 4000, 0)
            bodyPos.P = 12500
            bodyPos.D = 1000
            bodyPos.Name = "FloatBP"
            bodyPos.Parent = rootPart
            local connection = RunService.Heartbeat:Connect(function()
                local rayOrigin = rootPart.Position
                local rayDirection = Vector3.new(0, -500, 0)
                local raycastParams = RaycastParams.new()
                raycastParams.FilterType = Enum.RaycastFilterType.Exclude
                raycastParams.FilterDescendantsInstances = { character }
                local raycastResult = Workspace:Raycast(rayOrigin, rayDirection, raycastParams)
                if raycastResult then
                    local targetY = raycastResult.Position.Y + height + humanoid.HipHeight
                    bodyPos.Position = Vector3.new(rootPart.Position.X, targetY, rootPart.Position.Z)
                end
            end)
            connection.Name = "FloatConn"
            character.FloatConn = connection
        end
        if LocalPlayer.Character then onCharacterAdded(LocalPlayer.Character) end
        LocalPlayer.CharacterAdded:Connect(onCharacterAdded)
    end)

    A:Toggle("Farm Money", false, function(v)
        if v then
            farmConn = RunService.Heartbeat:Connect(function()
                local mobs = { "Prisoner Zombie", "Lurker", "Dweller", "Eyeless Jack", "Glacier", "Hydra", "Jengu", "Jeff the Killer", "Rager", "Skeleton", "Snowman", "Toxicle", "004" }
                for _, mob in ipairs(Workspace:GetChildren()) do
                    if table.find(mobs, mob.Name) and mob:FindFirstChild("Head") and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Head") then
                        mob.Head.CFrame = LocalPlayer.Character.Head.CFrame + LocalPlayer.Character.Head.CFrame.LookVector * 7
                    end
                end
            end)
        else
            if farmConn then farmConn:Disconnect() farmConn = nil end
        end
    end)

    local function AddWeaponButton(name, mid, final, special)
        A:Button("Instant Get " .. name, function()
            local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if not root then return end
            if special then
                root.CFrame = CFrame.new(-19.90, 1051.92, 1158.23)
                task.wait(0.4)
                local btn = Workspace:FindFirstChild("Incinerator") and Workspace.Incinerator:FindFirstChild("ChallengeButton7") and Workspace.Incinerator.ChallengeButton7:FindFirstChild("Button")
                if btn then
                    local p = btn:FindFirstChildOfClass("ProximityPrompt")
                    if p then p.HoldDuration = 0 fireproximityprompt(p) end
                end
                task.wait(0.8)
                root.CFrame = CFrame.new(623.5, 1072, 749.75)
                task.wait(0.6)
            else
                if mid then root.CFrame = CFrame.new(mid) task.wait(3) end
            end
            root.CFrame = CFrame.new(final)
            Notify("Success", "Obtained " .. name, 5, "package")
        end)
    end
    AddWeaponButton("Burning Sword", nil, Vector3.new(62.23, 1062.00, 1159.89), true)
    AddWeaponButton("Red Missile Launcher", Vector3.new(625.76, 1127.85, 749.51), Vector3.new(-353.435, 1070.29, 409.856))
    AddWeaponButton("Vulcan", Vector3.new(625.76, 1127.85, 749.51), Vector3.new(-600.846, 950.275, 154.955))
    AddWeaponButton("Ice Crossbow", Vector3.new(625.76, 1127.85, 749.51), Vector3.new(243.564, 687.29, 943.856))

    A:Toggle("Auto Supply Crate", false, function(state)
        if not state then
            if _G.RealSupplyLoop then _G.RealSupplyLoop = false end
            return
        end
        local player = LocalPlayer
        local character = player.Character or player.CharacterAdded:Wait()
        local hrp = character:WaitForChild("HumanoidRootPart")
        local lastMovingPos = hrp.CFrame
        local safePoint = CFrame.new(625.76, 1127.85, 749.51)
        _G.RealSupplyLoop = true
        task.spawn(function()
            while _G.RealSupplyLoop do
                task.wait(0.0001)
                pcall(function()
                    local hum = player.Character and player.Character:FindFirstChild("Humanoid")
                    if hum and hum.MoveDirection.Magnitude > 0 then
                        lastMovingPos = player.Character.HumanoidRootPart.CFrame
                    end
                end)
            end
        end)
        task.spawn(function()
            while _G.RealSupplyLoop do
                task.wait(1.3)
                pcall(function()
                    local char = player.Character or player.CharacterAdded:Wait()
                    local root = char:FindFirstChild("HumanoidRootPart")
                    if not root then return end
                    local hasPickedThisWave = false
                    repeat
                        local supplies = {}
                        for _, obj in ipairs(Workspace:GetChildren()) do
                            if obj.Name == "SupplyCrate" or obj.Name == "Ball" then
                                table.insert(supplies, obj)
                            end
                        end
                        if #supplies == 0 then break end
                        local target = nil
                        for _, supply in ipairs(supplies) do
                            if (supply.Position - Vector3.new(-816, 5181, 493)).Magnitude > 5
                                and (supply.Position - Vector3.new(-816, 5181, 630)).Magnitude > 5
                                and (supply.Position - Vector3.new(-816, 5181, 376)).Magnitude > 5 then
                                target = supply
                                break
                            end
                        end
                        if not target then break end
                        hasPickedThisWave = true
                        root.CFrame = safePoint
                        task.wait(1.5)
                        root.CFrame = target.CFrame + Vector3.new(0, 3, 0)
                        task.wait(0.3)
                        local p = target:FindFirstChildOfClass("ProximityPrompt")
                        if p then
                            p.HoldDuration = 0
                            fireproximityprompt(p)
                        end
                        task.wait(0.4)
                    until false
                    if hasPickedThisWave then root.CFrame = lastMovingPos end
                end)
            end
        end)
    end)

    A:Button("Supply Instant Pickup", function()
        task.spawn(function()
            while task.wait(2) do
                for _, v in ipairs(Workspace:GetDescendants()) do
                    if v:IsA("ProximityPrompt") and v.Parent and (v.Parent.Name:find("Supply") or (v.Parent.Parent and v.Parent.Parent.Name:find("Supply"))) then
                        v.HoldDuration = 0
                    end
                end
            end
        end)
        Notify("Supply", "Instant pickup enabled", 6, "package")
    end)

    local blacklistCoordinates = {
        Vector3.new(-816, 5181, 493),
        Vector3.new(-816, 5181, 630),
        Vector3.new(-816, 5181, 376),
    }
    local function teleportToRandomSupply(supplyName)
        pcall(function()
            local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
            local hrp = character:FindFirstChild("HumanoidRootPart")
            if not hrp then return end
            local supplies, valid = {}, {}
            for _, obj in ipairs(Workspace:GetChildren()) do
                if obj.Name == supplyName then table.insert(supplies, obj) end
            end
            if #supplies == 0 then return end
            for _, supply in ipairs(supplies) do
                local blacklisted = false
                for _, bc in ipairs(blacklistCoordinates) do
                    if (supply.Position - bc).Magnitude < 5 then blacklisted = true break end
                end
                if not blacklisted then table.insert(valid, supply) end
            end
            if #valid == 0 then return end
            local target = valid[math.random(1, #valid)]
            hrp.CFrame = target.CFrame + Vector3.new(0, 3, 0)
        end)
    end
    A:Button("TP to Random SupplyCrate", function() teleportToRandomSupply("SupplyCrate") end)
    A:Button("TP to Random SupplyBall", function() teleportToRandomSupply("SupplyBall") end)

    A:Button("Destroy All Damage Parts", function()
        for _, v in ipairs(Workspace:GetDescendants()) do
            if v.Name == "DamagePart" or v.Name == "Lava" or v.Name:find("Fire") then
                v:Destroy()
            end
        end
        Notify("Cleanup", "All damage parts removed", 5, "trash-2")
    end)
end

local function BuildGunModded(A)
    A:Button("Modded ALL GUN(CAN'T UNDO)", function()
        if _G.AllGunMod then return end
        _G.AllGunMod = true
        task.spawn(function()
            while _G.AllGunMod do
                for _, tool in pairs(LocalPlayer.Backpack:GetChildren()) do
                    if tool:IsA("Tool") and tool:FindFirstChild("Setting") then
                        pcall(function()
                            local s = require(tool.Setting)
                            s.BaseDamage = 999999 s.FireRate = 0.01 s.AmmoPerClip = 99999
                            s.Spread = 0 s.Auto = true s.Radius = 50 s.CameraShakingEnabled = false
                        end)
                    end
                end
                if LocalPlayer.Character then
                    for _, tool in pairs(LocalPlayer.Character:GetChildren()) do
                        if tool:IsA("Tool") and tool:FindFirstChild("Setting") then
                            pcall(function()
                                local s = require(tool.Setting)
                                s.BaseDamage = 999999 s.FireRate = 0.01 s.AmmoPerClip = 99999
                                s.Spread = 0 s.Auto = true s.CameraShakingEnabled = false
                            end)
                        end
                    end
                end
                task.wait(0.2)
            end
        end)
    end)

    local GunMods = { BaseDamage = 999999, FireRate = 0.01, AmmoPerClip = 99999, Spread = 0, Auto = true, CameraShakingEnabled = false }
    local ActiveGunMods = {}
    local function ApplyGunMod(name)
        if ActiveGunMods[name] then return end
        ActiveGunMods[name] = true
        task.spawn(function()
            while ActiveGunMods[name] and task.wait(0.3) do
                local tool = LocalPlayer.Backpack:FindFirstChild(name) or (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild(name))
                if tool and tool:FindFirstChild("Setting") then
                    local s = require(tool.Setting)
                    for k, v in pairs(GunMods) do s[k] = v end
                end
            end
        end)
    end
    local guns = { "Beretta 87", "AK47", "Desert Eagle", "Golden Eagle", "M16A4", "UZI", "LX1", "LX2", "LX3", "RGB", "Reaper's Scythe", "Water Gun", "Red Missile Launcher", "Ice Crossbow", "Mech O' Matic" }
    for _, g in ipairs(guns) do
        A:Toggle(g .. " Modded", false, function(v)
            if v then
                ApplyGunMod(g)
                Notify("Gun", g .. " Modded", 4, "zap")
            else
                ActiveGunMods[g] = false
            end
        end)
    end
end

local function BuildTeleport(A)
    local places = {
        ["Crafting Room"] = Vector3.new(953.97, 1060, 713.44),
        ["Shop"] = Vector3.new(588.74, 1151, 665.43),
        ["Portal"] = Vector3.new(-106.58, 982, 822.14),
        ["Reaper Room"] = Vector3.new(-190.57, 982.00, 275.41),
        ["Incinerator"] = Vector3.new(-316.88, 1062, 1158.83),
        ["Mineshaft"] = Vector3.new(-470.29, 753.00, 871.53),
        ["T.S.I.Z"] = Vector3.new(168.73, 674.00, 888.06),
        ["Main Hall"] = Vector3.new(395.33, 982.00, 750.03),
        ["Factory"] = Vector3.new(-394.82, 1062.00, 865.68),
        ["Prison"] = Vector3.new(-458.12, 1062.00, 1065.26),
        ["Sewers"] = Vector3.new(-497.02, 922.10, 79.18),
        ["Robot Zone"] = Vector3.new(-14.21, 883.00, 731.27),
        ["Volcano"] = Vector3.new(-510.616, 992.000, 305.217),
        ["Jack Spawn"] = Vector3.new(-361.266, 864.100, -58.076),
    }
    for name, pos in pairs(places) do
        A:Button("TP → " .. name, function()
            local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if root then
                root.CFrame = CFrame.new(623.5, 1072, 749.75)
                task.wait(2)
                root.CFrame = CFrame.new(pos)
            end
        end)
    end

    local nicknameHidden = false
    local originalName = ""
    A:Toggle("Hide Name → Fuck51DevLoL", false, function(v)
        pcall(function()
            local gui = LocalPlayer:FindFirstChild("PlayerGui")
            if not gui then return end
            local eventGui = gui:FindFirstChild("EventGUI")
            if not eventGui then return end
            local nickname = eventGui:FindFirstChild("Nickname")
            if not nickname then return end
            if v and not nicknameHidden then
                originalName = nickname.Text
                nickname.Text = "Fuck51DevLoL"
                nicknameHidden = true
                Notify("Name Hidden", "Now showing: Fuck51DevLoL", 3, "user")
            elseif not v and nicknameHidden then
                nickname.Text = originalName
                nicknameHidden = false
                Notify("Name Restored", "Back to original name", 3, "user")
            end
        end)
    end)
end

local function BuildFETools(A)
    local connections = {}

    A:Button("Player Join Notification", function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/boyscp/scriscriptsc/main/bbn.lua"))()
    end)
    A:Button("Noclip", function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/TtmScripter/OtherScript/main/Noclip"))()
    end)
    A:Button("Fly", function()
        loadstring(game:HttpGet("https://pastebin.com/raw/brP8SAfJ"))()
    end)
    A:Button("Save Position", function()
        local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if root then
            _G.savedPosition = root.Position
            Notify("Position", "Saved!", 3, "save")
        end
    end)
    A:Button("Copy Position", function()
        if _G.savedPosition then
            setclipboard(string.format("Vector3.new(%.3f, %.3f, %.3f)", _G.savedPosition.X, _G.savedPosition.Y, _G.savedPosition.Z))
            Notify("Position", "Copied!", 4, "copy")
        end
    end)
    A:Button("TP to Saved Position", function()
        if _G.savedPosition then
            local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if root then root.CFrame = CFrame.new(_G.savedPosition) end
        end
    end)
    A:Button("ESP", function()
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character then
                local hl = Instance.new("Highlight")
                hl.FillColor = Color3.fromRGB(255, 0, 255)
                hl.OutlineColor = Color3.new(1, 1, 1)
                hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                hl.Adornee = plr.Character
                hl.Parent = plr.Character
            end
        end
    end)

    A:Toggle("Night Vision", false, function(v)
        game.Lighting.Ambient = v and Color3.new(1, 1, 1) or Color3.new(0, 0, 0)
    end)

    A:Toggle("Infinite Jump", false, function(v)
        if v then
            table.insert(connections, UserInputService.JumpRequest:Connect(function()
                local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                if hum then hum:ChangeState("Jumping") end
            end))
        else
            for _, c in ipairs(connections) do c:Disconnect() end
            connections = {}
        end
    end)

    A:Toggle("Auto Interact", false, function(v)
        if v then
            table.insert(connections, RunService.Heartbeat:Connect(function()
                for _, obj in ipairs(Workspace:GetDescendants()) do
                    if obj:IsA("ProximityPrompt") then fireproximityprompt(obj) end
                end
            end))
        else
            for _, c in ipairs(connections) do c:Disconnect() end
            connections = {}
        end
    end)
end

-------------------------------------------------
-- 6) 分发：宿主接管 / WindUI 回退
-------------------------------------------------
if Runtime.Mode == "Host" then
    local bridge = Runtime.Bridge

    SafeCall("Build Area51", function()
        bridge:UsePageIndex(4, 1, "Replace")
        BuildArea51(BridgeAdapter(bridge))
    end)
    SafeCall("Build GunModded", function()
        bridge:UsePageIndex(4, 2, "Replace")
        BuildGunModded(BridgeAdapter(bridge))
    end)
    SafeCall("Build Teleport", function()
        bridge:UsePageIndex(4, 3, "Replace")
        BuildTeleport(BridgeAdapter(bridge))
    end)
    SafeCall("Build FETools", function()
        bridge:UsePageIndex(2, 2, "Replace")
        BuildFETools(BridgeAdapter(bridge))
    end)
    SafeCall("Focus", function() bridge:Focus() end)

    Notify("RealYoHub", "Handshake OK - hosted by PremiumUI", 6, "crown")
else
    local okWind, WindUI = pcall(function()
        return loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()
    end)
    if not okWind or type(WindUI) ~= "table" then
        warn("[RealYoHub][ERR] WindUI load failed: " .. tostring(WindUI))
        return
    end

    local createUI
    local function LoadScript() createUI() end

    WindUI:Popup({
        Title = "RealYoHub V1.2.4 ",
        IconThemed = true,
        Content = "Welcome  " .. LocalPlayer.Name .. "\nArea 51 All ready ",
        Buttons = {
            { Title = "Leave ", Variant = "Secondary ", Callback = function() end },
            { Title = "Execute ", Icon = "zap ", Variant = "Primary ", Callback = function() LoadScript() end },
        },
    })

    createUI = function()
        local Window = WindUI:CreateWindow({
            Title = "RealYoHub V1.2.4",
            Icon = "palette",
            Author = "Welcome " .. LocalPlayer.Name .. "\nMade by KevinSze",
            Folder = "Premium",
            Size = UDim2.fromOffset(550, 380),
            Theme = "Light",
            User = { Enabled = true, Anonymous = true },
            SideBarWidth = 200,
            HideSearchBar = false,
        })
        Window:Tag({ Title = "51 Area", Color = Color3.fromHex("#00ffff") })
        Window:EditOpenButton({
            Title = "RealYoHub",
            Icon = "crown",
            CornerRadius = UDim.new(0, 8),
            StrokeThickness = 3,
            Color = ColorSequence.new(
                Color3.fromRGB(255, 255, 0), Color3.fromRGB(255, 165, 0),
                Color3.fromRGB(255, 0, 0), Color3.fromRGB(139, 0, 0)
            ),
            Draggable = true,
        })

        local Area51Tab      = Window:Tab({ Title = "Area 51", Icon = "globe" })
        local Area51GunTPTab = Window:Tab({ Title = "Gun Modded", Icon = "crosshair" })
        local Area51TPTab    = Window:Tab({ Title = "Teleport", Icon = "map-pin" })
        local FETab          = Window:Tab({ Title = "FE Tools", Icon = "zap" })

        SafeCall("Wind Build Area51",   function() BuildArea51(WindAdapter(Area51Tab)) end)
        SafeCall("Wind Build GunModded",function() BuildGunModded(WindAdapter(Area51GunTPTab)) end)
        SafeCall("Wind Build Teleport", function() BuildTeleport(WindAdapter(Area51TPTab)) end)
        SafeCall("Wind Build FETools",  function() BuildFETools(WindAdapter(FETab)) end)

        Notify("RealYoHub V1.2.4", "Loaded successfully!\nRightControl = Toggle Menu", 8, "crown")
        Window:AutoSaveConfig(true)
    end
end
