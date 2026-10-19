-- area51.lua | RealYoHub (RealYoUI GameBridge auto-handshake)
local GAME = { Name = "RealYoHub Area51", Brand = "RealYoUI" }
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
_G.savedPosition = _G.savedPosition or nil
local Runtime = { Mode = "Original", Bridge = nil, Host = nil }

local function SafeCall(tag, fn, ...)
    local ok, err = pcall(fn, ...)
    if not ok then warn(("[RealYoHub][ERR] %s : %s"):format(tag, tostring(err))) end
    return ok
end

local AUTO_ACCEPT = true

local function FindHostUI(timeout)
    timeout = timeout or 5
    local sources = {
        { name = "shared", get = function() return shared and shared.RealYoUI end },
        { name = "_G", get = function() return _G and _G.RealYoUI end },
        { name = "getgenv", get = function()
            local ok, g = pcall(getgenv)
            return ok and g and g.RealYoUI
        end },
    }
    local deadline = tick() + timeout
    local why = "Host not found"
    
    while true do
        for _, src in ipairs(sources) do
            local ok, obj = pcall(src.get)
            if ok and type(obj) == "table" then 
                if obj.IsRealYoUI ~= true then 
                    why = "Found " .. src.name .. " but IsRealYoUI=false"
                elseif obj.Brand ~= GAME.Brand then 
                    why = "Found " .. src.name .. " but Brand mismatch"
                elseif type(obj.RequestGameBridge) ~= "function" then 
                    why = "Found " .. src.name .. " but missing API"
                elseif obj.Initialized ~= true then 
                    why = "Found " .. src.name .. " but not initialized"
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
    print(("[RealYoHub] Host detected (via %s), handshaking"):format(whyOrSrc))
else
    warn("[RealYoHub] Handshake failed. Reason: " .. tostring(whyOrSrc))
end

if AUTO_ACCEPT and HostUI then
    local ok, success, bridgeOrErr = pcall(function()
        return HostUI:RequestGameBridge({
            Brand = GAME.Brand,
            Protocol = HostUI.BridgeProtocol or 2,
            Name = GAME.Name,
            RequestedCategory = "Info",
            Category = "Info",
            Sub = "Annc",
            Mode = "Replace",
            Focus = false,
        })
    end)
    if ok and success == true and type(bridgeOrErr) == "table" then
        Runtime.Mode = "Host"
        Runtime.Bridge = bridgeOrErr
        Runtime.Host = HostUI
        print("[RealYoHub] Bridge obtained, Mode=Host")
    else
        warn("[RealYoHub][ERR] RequestGameBridge: " .. tostring(ok and bridgeOrErr or success))
    end
end

if Runtime.Mode == "Host" then
    SafeCall("RenameMain1", function()
    HostUI:RenameMain(1, "RealYoHub")
end)

SafeCall("RenameSub11", function()
    HostUI:RenameSub(1, 1, "Area 51")
end)

SafeCall("RenameSub12", function()
    HostUI:RenameSub(1, 2, "Gun Modded")
end)

SafeCall("RenameSub13", function()
    HostUI:RenameSub(1, 3, "Teleport")
end)

SafeCall("RenameSub14", function()
    HostUI:RenameSub(1, 4, "FE Tools")
end)
end

local function Notify(title, content, duration, icon)
    if Runtime.Mode == "Host" and Runtime.Host and type(Runtime.Host.Toast) == "function" then
        pcall(function() Runtime.Host:Toast("[" .. title .. "] " .. tostring(content or "")) end)
    end
end

-- ✅ BridgeAdapter 支持 Config 分组 (Group)
local function BridgeAdapter(bridge)
    local A = { _b = bridge }
    function A:Section(t) return self._b:Section(t) end
    function A:Label(t) return self._b:Label(t) end
    function A:Button(t, cb) return self._b:Button(t, cb) end
    -- ✅ 关键：传入 group 参数，实现 AK47.Damage 这种嵌套保存
    function A:Toggle(t, def, cb, group) return self._b:Toggle(t, def, cb, { Group = group }) end
    function A:Slider(t, min, max, def, cb, group) return self._b:Slider(t, min, max, def, cb, { Group = group }) end
    function A:Input(t, placeholder, cb)
        local box = self._b:TextBox(placeholder, "")
        if box then box:GetPropertyChangedSignal("Text"):Connect(function() cb(box.Text) end) end
        return box
    end
    function A:Dropdown(t, opts, def, cb) return self._b:Dropdown(t, opts, def, cb) end
    return A
end

-- ✅✅✅ 智能 Gun Modded V2 (实时监测 + 动态 Setting) ✅✅✅
local function BuildGunModded(A)
    local bridge = A._b
    local scrollHost = bridge.Host          -- 锁定滚动页，动态组件都挂在这里
    local weaponData = {}                   -- name -> setting 表
    local weaponDrop = nil                  -- 下拉框 handle
    local lastSig = nil
    local dynFrame = nil                    -- 当前动态组件容器
    local dynGroup = nil                    -- 当前动态组件的 config 分组

    -- 1. 扫描武器：条件 = Tool 里有叫 Setting 的子物体（按你的要求）
    local function scanWeapons()
        weaponData = {}
        local list, seen = {}, {}
        local function tryAdd(tool)
            if not (tool and tool:IsA("Tool")) then return end
            local cfg = tool:FindFirstChild("Setting")
            if not cfg or seen[tool.Name] then return end
            seen[tool.Name] = true
            table.insert(list, tool.Name)
            local ok, setting = pcall(require, cfg)   -- ModuleScript，return 那张表
            if ok and type(setting) == "table" then
                weaponData[tool.Name] = setting
            end
        end
        local function check(container)
            if not container then return end
            for _, tool in ipairs(container:GetChildren()) do tryAdd(tool) end
        end
        check(LocalPlayer.Backpack)
        check(LocalPlayer.Character)
        return list
    end

    -- 2. 清掉旧动态组件 + 清掉它的 config 注册
    local function clearDyn()
        if dynFrame then pcall(function() dynFrame:Destroy() end) dynFrame = nil end
        if dynGroup then
            pcall(function()
                if bridge.UI and bridge.UI.PurgeSettings then bridge.UI.PurgeSettings(dynGroup) end
            end)
            dynGroup = nil
        end
    end

    -- 3. 动态渲染某把武器的 Setting
    local function renderProperties(name)
        local setting = weaponData[name]
        if not setting then Notify("GunMod", "cannot read " .. name .. " Setting", 3) return end
        clearDyn()
        dynGroup = name
        dynFrame = Instance.new("Frame")
        dynFrame.Name = "DynProps"
        dynFrame.BackgroundTransparency = 1
        dynFrame.Size = UDim2.new(1, 0, 0, 0)
        dynFrame.AutomaticSize = Enum.AutomaticSize.Y
        dynFrame.Parent = scrollHost
        local lay = Instance.new("UIListLayout")
        lay.Padding = UDim.new(0, 2)
        lay.Parent = dynFrame

        local oldHost = bridge.Host
        bridge.Host = dynFrame   -- ✅ 接下来的组件全部建进 dynFrame，换武器时整体销毁

        A:Section("Properties for " .. name)
        local keys = {}
        for k in pairs(setting) do table.insert(keys, k) end
        table.sort(keys)         -- 固定顺序，每次渲染不乱跳
        for _, key in ipairs(keys) do
            local value = setting[key]
            local t = type(value)
            if t == "boolean" then
                A:Toggle(key, value, function(v) setting[key] = v end, name)
            elseif t == "number" then
                if key:match("ID$") or key:match("Id$") then
                    A:Label(key .. " = " .. tostring(value))        -- 资产ID，只读
                elseif value == math.floor(value) then
                    local mx = (value <= 0) and 100 or math.clamp(value * 10, 10, 100000)
                    A:Slider(key, 0, mx, value, function(v) setting[key] = v end, name)
                else
                    local v100 = math.floor(value * 100 + 0.5)
                    local mx100 = math.clamp(v100 * 10, 100, 10000)
                    A:Slider(key .. " (x0.01)", 0, mx100, v100, function(v) setting[key] = v / 100 end, name)
                end
            else
                A:Label(key .. " = " .. tostring(value))            -- Vector3/Enum/表 等只读
            end
        end
        bridge.Host = oldHost
        Notify("GunMod", "loaded " .. name .. " setting (" .. #keys .. " item)", 3)
    end

    -- 4. 重扫 + 同步下拉框
    local function rescan()
        local list = scanWeapons()
        local sig = table.concat(list, "|")
        if sig ~= lastSig then
            lastSig = sig
            if weaponDrop then
                weaponDrop.SetOptions((#list > 0) and list or { "No weapons" })
            end
        end
        return list
    end

    -- 5. 实时监测：捡枪/装备/掉枪立刻刷新列表
    local function watchContainer(c)
        if not c then return end
        c.ChildAdded:Connect(function(ch)
            if ch:IsA("Tool") then task.delay(0.15, rescan) end
        end)
        c.ChildRemoved:Connect(function(ch)
            if ch:IsA("Tool") then rescan() end
        end)
    end
    watchContainer(LocalPlayer.Backpack)
    if LocalPlayer.Character then watchContainer(LocalPlayer.Character) end
    LocalPlayer.CharacterAdded:Connect(function(ch) watchContainer(ch))

    -- 6. UI
    A:Section("Weapon Scanner")
    local list = rescan()
    A:Button("Refresh Weapons", function()
        local l = rescan()
        Notify("Scanner", "Found " .. #l .. " weapons", 3)
    end)
    A:Section("Select Weapon")
    weaponDrop = A:Dropdown("Choose Weapon",
        (#list > 0) and list or { "No weapons" },
        (#list > 0) and list[1] or "No weapons",
        function(selected) renderProperties(selected) end)
    A:Section("Instructions")
end

-- ✅✅✅ Area 51 功能 (完整) ✅✅✅
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
    
    A:Input("Fly Height", "0", function(Value)
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

-- ✅✅✅ Teleport 功能 (完整) ✅✅✅
local function BuildTeleport(A)
    local places = {
        ["Crafting Room"] = Vector3.new(953.97, 1060, 713.44), ["Shop"] = Vector3.new(588.74, 1151, 665.43),
        ["Portal"] = Vector3.new(-106.58, 982, 822.14), ["Reaper Room"] = Vector3.new(-190.57, 982.00, 275.41),
        ["Incinerator"] = Vector3.new(-316.88, 1062, 1158.83), ["Mineshaft"] = Vector3.new(-470.29, 753.00, 871.53),
        ["T.S.I.Z"] = Vector3.new(168.73, 674.00, 888.06), ["Main Hall"] = Vector3.new(395.33, 982.00, 750.03),
        ["Factory"] = Vector3.new(-394.82, 1062.00, 865.68), ["Prison"] = Vector3.new(-458.12, 1062.00, 1065.26),
        ["Sewers"] = Vector3.new(-497.02, 922.10, 79.18), ["Robot Zone"] = Vector3.new(-14.21, 883.00, 731.27),
        ["Volcano"] = Vector3.new(-510.616, 992.000, 305.217), ["Jack Spawn"] = Vector3.new(-361.266, 864.100, -58.076),
    }
    for name, pos in pairs(places) do
        A:Button("TP → " .. name, function()
            local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if root then root.CFrame = CFrame.new(623.5, 1072, 749.75); task.wait(2); root.CFrame = CFrame.new(pos) end
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
                originalName = nickname.Text; nickname.Text = "Fuck51DevLoL"; nicknameHidden = true
                Notify("Name Hidden", "Now showing: Fuck51DevLoL", 3, "user")
            elseif not v and nicknameHidden then
                nickname.Text = originalName; nicknameHidden = false
                Notify("Name Restored", "Back to original name", 3, "user")
            end
        end)
    end)
end

-- ✅✅✅ FE Tools 功能 (完整) ✅✅✅
local function BuildFETools(A)
    local connections = {}
    A:Button("Player Join Notification", function() loadstring(game:HttpGet("https://raw.githubusercontent.com/boyscp/scriscriptsc/main/bbn.lua"))() end)
    A:Button("Noclip", function() loadstring(game:HttpGet("https://raw.githubusercontent.com/TtmScripter/OtherScript/main/Noclip"))() end)
    A:Button("Fly", function() loadstring(game:HttpGet("https://pastebin.com/raw/brP8SAfJ"))() end)
    A:Button("Save Position", function()
        local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if root then _G.savedPosition = root.Position; Notify("Position", "Saved!", 3, "save") end
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
                hl.FillColor = Color3.fromRGB(255, 0, 255); hl.OutlineColor = Color3.new(1, 1, 1)
                hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop; hl.Adornee = plr.Character; hl.Parent = plr.Character
            end
        end
    end)
    A:Toggle("Night Vision", false, function(v) game.Lighting.Ambient = v and Color3.new(1, 1, 1) or Color3.new(0, 0, 0) end)
    A:Toggle("Infinite Jump", false, function(v)
        if v then
            table.insert(connections, UserInputService.JumpRequest:Connect(function()
                local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                if hum then hum:ChangeState("Jumping") end
            end))
        else for _, c in ipairs(connections) do c:Disconnect() end; connections = {} end
    end)
    A:Toggle("Auto Interact", false, function(v)
        if v then
            table.insert(connections, RunService.Heartbeat:Connect(function()
                for _, obj in ipairs(Workspace:GetDescendants()) do
                    if obj:IsA("ProximityPrompt") then fireproximityprompt(obj) end
                end
            end))
        else for _, c in ipairs(connections) do c:Disconnect() end; connections = {} end
    end)
end


-- ✅ 定义完整性自检 (防粘贴截断/错位导致的 nil 调用)
local function DefCheck()
    local missing = {}
    local function chk(n, v)
        if type(v) ~= "function" then table.insert(missing, n) end
    end
    chk("SafeCall", SafeCall)
    chk("FindHostUI", FindHostUI)
    chk("Notify", Notify)
    chk("BridgeAdapter", BridgeAdapter)
    chk("BuildArea51", BuildArea51)
    chk("BuildGunModded", BuildGunModded)
    chk("BuildTeleport", BuildTeleport)
    chk("BuildFETools", BuildFETools)
    if #missing > 0 then
        warn("[RealYoHub][FATAL] missing definitions: " .. table.concat(missing, ", "))
        warn("[RealYoHub][FATAL] Area51.lua 上传截断或粘贴错位，请用 GitHub 的 Upload file / Replace 整文件重传，不要手机剪贴板分段粘")
        return false
    end
    return true
end

-- ✅ 执行构建
if Runtime.Mode == "Host" and DefCheck() then
    local bridge = Runtime.Bridge
    SafeCall("Build Area51", function() bridge:UsePageIndex(1, 1, "Replace"); BuildArea51(BridgeAdapter(bridge)) end)
    SafeCall("Build GunModded", function() bridge:UsePageIndex(1, 2, "Replace"); BuildGunModded(BridgeAdapter(bridge)) end)
    SafeCall("Build Teleport", function() bridge:UsePageIndex(1, 3, "Replace"); BuildTeleport(BridgeAdapter(bridge)) end)
    SafeCall("Build FETools", function() bridge:UsePageIndex(1, 4, "Replace"); BuildFETools(BridgeAdapter(bridge)) end)
    SafeCall("Focus", function() bridge:Focus() end)
    SafeCall("HandshakeToast", function() Notify("RealYoHub", "Handshake OK - hosted by RealYoUI", 6, "crown") end)
else
    warn("[RealYoHub] not built. Mode=" .. tostring(Runtime.Mode) .. " (Host 未握手成功 或 DefCheck 失败，见上方 [FATAL])")
end
