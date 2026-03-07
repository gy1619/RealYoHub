--No fucking skid my frd
--倒卖死全家

local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()

WindUI:Popup({
    Title = "RealYoHub V1.2.4",
    IconThemed = true,
    Content = "Welcome " .. game.Players.LocalPlayer.Name .. "\nArea 51 All ready",
    Buttons = {
        { Title = "Leave", Variant = "Secondary", Callback = function() end },
        { Title = "Execute", Icon = "zap", Variant = "Primary", Callback = function()
            LoadScript()
        end }
    }
})

function LoadScript()
    createUI()
end

function createUI()
    local Window = WindUI:CreateWindow({
        Title = "RealYoHub V1.2.4",
        Icon = "palette",
        Author = "Welcome "..game.Players.LocalPlayer.Name.."\nMade by KevinSze",
        Folder = "Premium",
        Size = UDim2.fromOffset(550, 380),
        Theme = "Light",
        User = { Enabled = true, Anonymous = true },
        SideBarWidth = 200,
        HideSearchBar = false
       })

    Window:Tag({ Title = "51 Area", Color = Color3.fromHex("#00ffff") })

    Window:EditOpenButton({
        Title = "RealYoHub",
        Icon = "crown",
        CornerRadius = UDim.new(0, 8),
        StrokeThickness = 3,
        Color = ColorSequence.new(
            Color3.fromRGB(255, 255, 0),
            Color3.fromRGB(255, 165, 0),
            Color3.fromRGB(255, 0, 0),
            Color3.fromRGB(139, 0, 0)
        ),
        Draggable = true
    })

    local Area51Tab       = Window:Tab({ Title = "Area 51", Icon = "globe" })
    local Area51GunTPTab  = Window:Tab({ Title = "Gun Modded", Icon = "crosshair" })
    local Area51TPTab     = Window:Tab({ Title = "Teleport", Icon = "map-pin" })
    local FETab           = Window:Tab({ Title = "FE Tools", Icon = "zap" })

    local Players          = game:GetService("Players")
    local LocalPlayer      = Players.LocalPlayer
    local RunService       = game:GetService("RunService")
    local UserInputService = game:GetService("UserInputService")

    _G.savedPosition = _G.savedPosition or nil
    local connections = {}
    local farmConn = nil

    Area51Tab:Toggle({
    Title = "Speed Hack",
    Default = false,
    Callback = function(v)
        pcall(function()
            local players = game:GetService("Players")
            local runService = game:GetService("RunService")
            local player = players.LocalPlayer
            local char = player.Character or player.CharacterAdded:Wait()
            local humanoid = char:WaitForChild("Humanoid")
            local root = char:WaitForChild("HumanoidRootPart")
            
            local teleportDistance = 1.5
            local teleportInterval = 0.01
            local lastTeleportTime = 0
            
            local rayParams = RaycastParams.new()
            rayParams.FilterDescendantsInstances = {char}
            rayParams.FilterType = Enum.RaycastFilterType.Exclude
            
            if v then  
                speedHackConnection = runService.Heartbeat:Connect(function()
                    if tick() - lastTeleportTime < teleportInterval then return end
                    
                    local moveDir = humanoid.MoveDirection
                    if moveDir.Magnitude > 0 then
                        local teleportVector = moveDir * teleportDistance
                        
                        local result = workspace:Raycast(root.Position, teleportVector, rayParams)
                        if not result or result.Distance > teleportDistance then
                            root.CFrame = root.CFrame + Vector3.new(teleportVector.X, 0, teleportVector.Z)
                        end
                        
                        lastTeleportTime = tick()
                    end
                end)
            else  
                if speedHackConnection then
                    speedHackConnection:Disconnect()
                    speedHackConnection = nil
                end
            end
        end)
    end
})

    Area51Tab:Input({
    Title = "Fly Height",
    Placeholderholder = ".",
    Callback = function(Value)
        local run_service = game:GetService("RunService")
        local workspace = game:GetService("Workspace")
        local players = game:GetService("Players")
        
        local player = players.LocalPlayer
        local height = tonumber(Value) or 0
        
    
        if height <= 0 then
            if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                local bp = player.Character.HumanoidRootPart:FindFirstChild("FloatBP")
                if bp then bp:Destroy() end
            end
            if player.Character and player.Character:FindFirstChild("FloatConn") then
                player.Character.FloatConn:Disconnect()
            end
            return
        end
        
      
        height = math.clamp(height, 1, 100)
        
        local function onCharacterAdded(character)
          
            if character:FindFirstChild("FloatConn") then
                character.FloatConn:Disconnect()
            end
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
            
            local connection = run_service.Heartbeat:Connect(function()
                local rayOrigin = rootPart.Position
                local rayDirection = Vector3.new(0, -500, 0) 
                
                local raycastParams = RaycastParams.new()
                raycastParams.FilterType = Enum.RaycastFilterType.Exclude
                raycastParams.FilterDescendantsInstances = {character}
                
                local raycastResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
                
                if raycastResult then
                    local targetY = raycastResult.Position.Y + height + humanoid.HipHeight
                    bodyPos.Position = Vector3.new(rootPart.Position.X, targetY, rootPart.Position.Z)
                end
            end)
            
            connection.Name = "FloatConn"
            character.FloatConn = connection
        end
        
        if player.Character then
            onCharacterAdded(player.Character)
        end
        
        player.CharacterAdded:Connect(onCharacterAdded)
    end
})

    Area51Tab:Toggle({
        Title = "Farm Money",
        Default = false,
        Callback = function(v)
            if v then
                farmConn = RunService.Heartbeat:Connect(function()
                    local mobs = {"Prisoner Zombie","Lurker","Dweller","Eyeless Jack","Glacier","Hydra","Jengu","Jeff the Killer","Rager","Skeleton","Snowman","Toxicle","004"}
                    for _, mob in workspace:GetChildren() do
                        if table.find(mobs, mob.Name) and mob:FindFirstChild("Head") and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Head") then
                            mob.Head.CFrame = LocalPlayer.Character.Head.CFrame + LocalPlayer.Character.Head.CFrame.LookVector * 7
                        end
                    end
                end)
            else
                if farmConn then farmConn:Disconnect() farmConn = nil end
            end
        end
    })

    local function AddWeaponButton(name, mid, final, special)
        Area51Tab:Button({
            Title = "Instant Get "..name,
            Callback = function()
                local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if not root then return end

                if special then
                    root.CFrame = CFrame.new(-19.90, 1051.92, 1158.23)
                    task.wait(0.4)
                    local btn = workspace:FindFirstChild("Incinerator") and workspace.Incinerator:FindFirstChild("ChallengeButton7") and workspace.Incinerator.ChallengeButton7:FindFirstChild("Button")
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
                Notifier.new({Title="Success", Content="Obtained "..name, Duration=5, Icon="package"})
            end
        })
    end

    AddWeaponButton("Burning Sword",        nil,                                Vector3.new(62.23, 1062.00, 1159.89), true)
    AddWeaponButton("Red Missile Launcher",Vector3.new(625.76, 1127.85, 749.51), Vector3.new(-353.435, 1070.29, 409.856))
    AddWeaponButton("Vulcan",              Vector3.new(625.76, 1127.85, 749.51), Vector3.new(-600.846, 950.275, 154.955))
    AddWeaponButton("Ice Crossbow",        Vector3.new(625.76, 1127.85, 749.51), Vector3.new(243.564, 687.29, 943.856))

    Area51GunTPTab:Button({
    Title = "Modded ALL GUN(CAN'T UNDO)",
    Callback = function()
        if _G.AllGunMod then return end
        _G.AllGunMod = true
        
        task.spawn(function()
            while _G.AllGunMod do
                for _, tool in pairs(LocalPlayer.Backpack:GetChildren()) do
                    if tool:IsA("Tool") and tool:FindFirstChild("Setting") then
                        pcall(function()
                            local s = require(tool.Setting)
                            s.BaseDamage = 999999
                            s.FireRate = 0.01
                            s.AmmoPerClip = 99999
                            s.Spread = 0
                            s.Auto = true
                            s.Radius = 50
                            s.CameraShakingEnabled = false
                        end)
                    end
                end
                
                if LocalPlayer.Character then
                    for _, tool in pairs(LocalPlayer.Character:GetChildren()) do
                        if tool:IsA("Tool") and tool:FindFirstChild("Setting") then
                            pcall(function()
                                local s = require(tool.Setting)
                                s.BaseDamage = 999999
                                s.FireRate = 0.01
                                s.AmmoPerClip = 99999
                                s.Spread = 0
                                s.Auto = true
                                s.CameraShakingEnabled = false
                            end)
                        end
                    end
                end
                
                task.wait(0.2)
            end
        end)
    end
})

    -- 枪械修改
    local GunMods = { BaseDamage=999999, FireRate=0.01, AmmoPerClip=99999, Spread=0, Auto=true, CameraShakingEnabled=false }
    local ActiveGunMods = {}

    local function ApplyGunMod(name)
        if ActiveGunMods[name] then return end
        ActiveGunMods[name] = true
        task.spawn(function()
            while ActiveGunMods[name] and task.wait(0.3) do
                local tool = LocalPlayer.Backpack:FindFirstChild(name) or (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild(name))
                if tool and tool:FindFirstChild("Setting") then
                    local s = require(tool.Setting)
                    for k,v in pairs(GunMods) do s[k] = v end
                end
            end
        end)
    end

    local guns = {"Beretta 87","AK47","Desert Eagle","Golden Eagle","M16A4","UZI","LX1","LX2","LX3","RGB","Reaper's Scythe","Water Gun","Red Missile Launcher","Ice Crossbow","Mech O' Matic"}
    for _, g in guns do
        Area51GunTPTab:Toggle({
            Title = g.." Modded",
            Default = false,
            Callback = function(v)
                if v then
                    ApplyGunMod(g)
                    Notifier.new({Title="Gun", Content=g.." Modded", Icon="zap"})
                else
                    ActiveGunMods[g] = false
                end
            end
        })
    end

    -- 传送点
    local places = {
        ["Crafting Room"] = Vector3.new(953.97, 1060, 713.44),
        ["Shop"]          = Vector3.new(588.74, 1151, 665.43),
        ["Portal"]        = Vector3.new(-106.58, 982, 822.14),
        ["Reaper Room"]   = Vector3.new(-190.57, 982.00, 275.41),
        ["Incinerator"]   = Vector3.new(-316.88, 1062, 1158.83),
        ["Mineshaft"]     = Vector3.new(-470.29, 753.00, 871.53),
        ["T.S.I.Z"]       = Vector3.new(168.73, 674.00, 888.06),
        ["Main Hall"]     = Vector3.new(395.33, 982.00, 750.03),
        ["Factory"]       = Vector3.new(-394.82, 1062.00, 865.68),
        ["Prison"]        = Vector3.new(-458.12, 1062.00, 1065.26),
        ["Sewers"]        = Vector3.new(-497.02, 922.10, 79.18),
        ["Robot Zone"]    = Vector3.new(-14.21, 883.00, 731.27),
        ["Volcano"]       = Vector3.new(-510.616, 992.000, 305.217),
        ["Jack Spawn"]    = Vector3.new(-361.266, 864.100, -58.076)
    }
    for name, pos in pairs(places) do
        Area51TPTab:Button({
            Title = "TP → "..name,
            Callback = function()
                local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if root then
                    root.CFrame = CFrame.new(623.5, 1072, 749.75)
                    task.wait(2)
                    root.CFrame = CFrame.new(pos)
                end
            end
        })
    end



    -- Hide Name（修复变量未定义 + 拼写错误）
    local nicknameHidden = false
    local originalName = ""

    Area51TPTab:Toggle({
        Title = "Hide Name → Fuck51DevLoL",
        Default = false,
        Callback = function(v)
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
                    Notifier.new({Title="Name Hidden", Content="Now showing: Fuck51DevLoL", Duration=3, Icon="user"})
                elseif not v and nicknameHidden then
                    nickname.Text = originalName
                    nicknameHidden = false
                    Notifier.new({Title="Name Restored", Content="Back to original name", Duration=3, Icon="user"})
                end
            end)
        end
    })

Area51Tab:Toggle({
    Title = "Auto Supply Crate",
    Default = false,
    Callback = function(state)
        if not state then
            if _G.RealSupplyLoop then _G.RealSupplyLoop = false end
            return
        end

        local player = game.Players.LocalPlayer
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
                        for _, obj in workspace:GetChildren() do
                            if obj.Name == "SupplyCrate" or obj.Name == "Ball" then
                                table.insert(supplies, obj)
                            end
                        end

                        if #supplies == 0 then break end

                        local target = nil
                        for _, supply in ipairs(supplies) do
                            if (supply.Position - Vector3.new(-816,5181,493)).Magnitude > 5
                            and (supply.Position - Vector3.new(-816,5181,630)).Magnitude > 5
                            and (supply.Position - Vector3.new(-816,5181,376)).Magnitude > 5 then
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

                        local p = target:FindFirstChildOfClass("ProximityPrompt", true)
                        if p then
                            p.HoldDuration = 0
                            fireproximityprompt(p)
                        end

                        task.wait(0.4)
                    until false

                    
                    if hasPickedThisWave then
                        root.CFrame = lastMovingPos
                    end
                end)
            end
        end)
    end
})

Area51Tab:Button({
        Title = "Supply Instant Pickup",
        Callback = function()
            task.spawn(function()
                while task.wait(2) do
                    for _, v in workspace:GetDescendants() do
                        if v:IsA("ProximityPrompt") and v.Parent and (v.Parent.Name:find("Supply") or v.Parent.Parent.Name:find("Supply")) then
                            v.HoldDuration = 0
                        end
                    end
                end
            end)
            Notifier.new({Title="Supply", Content="Instant pickup enabled", Duration=6, Icon="package"})
        end
    })

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

-- 你原来的黑名单坐标（完全保留）
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

        for _, obj in pairs(Workspace:GetChildren()) do
            if obj.Name == supplyName then
                table.insert(supplies, obj)
            end
        end

        if #supplies == 0 then return end

        for _, supply in ipairs(supplies) do
            local blacklisted = false
            for _, bc in ipairs(blacklistCoordinates) do
                if (supply.Position - bc).Magnitude < 5 then
                    blacklisted = true
                    break
                end
            end
            if not blacklisted then
                table.insert(valid, supply)
            end
        end

        if #valid == 0 then return end

        local target = valid[math.random(1, #valid)]
        hrp.CFrame = target.CFrame + Vector3.new(0, 3, 0)

    end)
end

    Area51Tab:Button({ Title = "TP to Random SupplyCrate", Callback = function() teleportToRandomSupply("SupplyCrate") end })
    Area51Tab:Button({ Title = "TP to Random SupplyBall", Callback = function() teleportToRandomSupply("SupplyBall") end })

    Area51Tab:Button({
        Title = "Destroy All Damage Parts",
        Callback = function()
            for _, v in workspace:GetDescendants() do
                if v.Name == "DamagePart" or v.Name == "Lava" or v.Name:find("Fire") then
                    v:Destroy()
                end
            end
            Notifier.new({Title="Cleanup", Content="All damage parts removed", Icon="trash-2"})
        end
    })

    FETab:Button({ Title = "Player Join Notification", Callback = function() loadstring(game:HttpGet("https://raw.githubusercontent.com/boyscp/scriscriptsc/main/bbn.lua"))() end })
    FETab:Button({ Title = "Noclip", Callback = function() loadstring(game:HttpGet("https://raw.githubusercontent.com/TtmScripter/OtherScript/main/Noclip"))() end })
    FETab:Button({ Title = "Fly", Callback = function() loadstring(game:HttpGet("https://pastebin.com/raw/brP8SAfJ"))() end })

    FETab:Button({ Title = "Save Position", Callback = function()
        local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if root then _G.savedPosition = root.Position Notifier.new({Title="Position", Content="Saved!", Duration=3, Icon="save"}) end
    end })

    FETab:Button({ Title = "Copy Position", Callback = function()
        if _G.savedPosition then
            setclipboard(string.format("Vector3.new(%.3f, %.3f, %.3f)", _G.savedPosition.X, _G.savedPosition.Y, _G.savedPosition.Z))
            Notifier.new({Title="Position", Content="Copied!", Duration=4, Icon="copy"})
        end
    end })

    FETab:Button({ Title = "TP to Saved Position", Callback = function()
        if _G.savedPosition then
            local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if root then root.CFrame = CFrame.new(_G.savedPosition) end
        end
    end })

    FETab:Button({ Title = "ESP", Callback = function()
        for _, plr in Players:GetPlayers() do
            if plr ~= LocalPlayer and plr.Character then
                local hl = Instance.new("Highlight", plr.Character)
                hl.FillColor = Color3.fromRGB(255, 0, 255)
                hl.OutlineColor = Color3.new(1,1,1)
                hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                hl.Adornee = plr.Character
            end
        end
    end })

    FETab:Toggle({ Title = "Night Vision", Default = false, Callback = function(v) game.Lighting.Ambient = v and Color3.new(1,1,1) or Color3.new(0,0,0) end })
    FETab:Toggle({ Title = "Infinite Jump", Default = false, Callback = function(v)
        if v then
            table.insert(connections, UserInputService.JumpRequest:Connect(function()
                LocalPlayer.Character:FindFirstChildOfClass("Humanoid"):ChangeState("Jumping")
            end))
        else
            for _, c in connections do c:Disconnect() end connections = {}
        end
    end })

    FETab:Toggle({ Title = "Auto Interact", Default = false, Callback = function(v)
        if v then
            table.insert(connections, RunService.Heartbeat:Connect(function()
                for _, obj in workspace:GetDescendants() do
                    if obj:IsA("ProximityPrompt") then fireproximityprompt(obj) end
                end
            end))
        else
            for _, c in connections do c:Disconnect() end connections = {}
        end
    end })

    Notifier.new({Title = "RealYoHub V1.2.4", Content = "Loaded successfully!\nRightControl = Toggle Menu", Duration = 8, Icon = "crown"})
    Window:AutoSaveConfig(true)
end
