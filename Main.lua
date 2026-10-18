-- Main Script.lua
local LIB_URL = "https://raw.githubusercontent.com/gy1619/RealYoHub/refs/heads/main/Astool.lua?t=" .. os.time()
local UI

do
    if shared and shared.RealYoUI then UI = shared.RealYoUI end
    if not UI then
        local ok, ret = pcall(function() return loadstring(game:HttpGet(LIB_URL))() end)
        if ok and type(ret) == "table" then UI = ret end
    end
    if not UI and _G and _G.RealYoUI then UI = _G.RealYoUI end
end

if not UI or not UI.IsRealYoUI then
    warn("[RealYoUI] UI library load failed. Check GitHub URL or syntax.")
    return
end

UI:Initialize({
    Title = "RealYo UI",
    Subtitle = "SZE",
})

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local TeleportService = game:GetService("TeleportService")
local LocalPlayer = Players.LocalPlayer
local taskWait = (task and task.wait) or function() return wait() end

local S = UI.S
local TS = UI.TS
local Create = UI.Create
local AddCorner = UI.AddCorner
local SafeClick = UI.SafeClick
local RegisterLang = UI.RegisterLang
local T = UI.T
local Toast = UI.Toast
local MakeText = UI.MakeText
local MakeSection = UI.MakeSection
local MakeButton = UI.MakeButton
local MakeTextBox = UI.MakeTextBox
local MakeToggle = UI.MakeToggle
local MakeSlider = UI.MakeSlider
local MakeDropdown = UI.MakeDropdown
local MakeColorPicker = UI.MakeColorPicker
local MakeInlineAlphaSlider = UI.MakeInlineAlphaSlider
local FlowOf = UI.FlowOf
local CreateGrid = UI.CreateGrid
local COL = UI.COL
local License = UI.License
local DEVICE_ID = UI.DEVICE_ID
local pages = UI.pages
local SetLanguage = UI.SetLanguage
local ApplyTheme = UI.ApplyTheme
local ApplyFont = UI.ApplyFont
local LoadAvatar = UI.LoadAvatar
local ListConfigNames = UI.ListConfigNames
local SaveConfig = UI.SaveConfig
local LoadConfig = UI.LoadConfig
local DeleteConfig = UI.DeleteConfig
local GetAutoLoad = UI.GetAutoLoad
local SetAutoLoad = UI.SetAutoLoad

local function ScrollOf(page) return page:FindFirstChildOfClass("ScrollingFrame") end

local Mods = {
    SpeedOn = false, Speed = 16, JumpOn = false, Jump = 50, Fly = false, FlySpeed = 50,
    Noclip = false, InfJump = false, HealthLock = false, AntiAFK = false, NoFog = false,
    FullBright = false, TimeLock = false, Time = 14, FPSBoost = false,
}
local ESP = {
    Enabled = false, Boxes = false, Names = false, Tracers = false, MaxDistance = 500,
    Color = Color3.fromRGB(255, 50, 50), R = 255, G = 50, B = 50, Rainbow = false,
    RainbowSpeed = 1, Thickness = 1, FontSize = 13, Transparency = 0.5,
}

local function UpdateESP()
    local localRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not localRoot then return end
    if ESP.Rainbow then ESP.Color = Color3.fromHSV((tick() * ESP.RainbowSpeed) % 1, 1, 1) end
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local root = player.Character:FindFirstChild("HumanoidRootPart")
            local hum = player.Character:FindFirstChildOfClass("Humanoid")
            if root and hum and hum.Health > 0 then
                local dist = (root.Position - localRoot.Position).Magnitude
                if ESP.Enabled and dist <= ESP.MaxDistance then
                    local hl = root:FindFirstChild("RealYoHL")
                    if not hl then hl = Instance.new("Highlight"); hl.Name = "RealYoHL"; hl.Adornee = player.Character; hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop; hl.Parent = root end
                    hl.FillColor = ESP.Color; hl.OutlineColor = ESP.Color; hl.FillTransparency = ESP.Transparency; hl.OutlineTransparency = 0
                else
                    local hl = root:FindFirstChild("RealYoHL")
                    if hl then hl:Destroy() end
                end
            end
        end
    end
end
RunService.RenderStepped:Connect(UpdateESP)

local function GetChar() return LocalPlayer.Character end
local function GetRoot() local c = GetChar() return c and c:FindFirstChild("HumanoidRootPart") end
local function GetHum() local c = GetChar() return c and c:FindFirstChildOfClass("Humanoid") end
local function ApplySpeedJump() local hum = GetHum(); if not hum then return end; hum.WalkSpeed = Mods.SpeedOn and Mods.Speed or 16; hum.JumpPower = Mods.JumpOn and Mods.Jump or 50 end

local flyVel, flyConn = nil, nil
local function SetFly(on)
    Mods.Fly = on
    if flyConn then flyConn:Disconnect() flyConn = nil end
    if flyVel then flyVel:Destroy() flyVel = nil end
    local root = GetRoot()
    if on and root then
        flyVel = Instance.new("BodyVelocity"); flyVel.MaxForce = Vector3.new(100000, 100000, 100000); flyVel.Velocity = Vector3.zero; flyVel.Parent = root
        flyConn = RunService.Heartbeat:Connect(function() local hum = GetHum(); if not hum or not flyVel or not flyVel.Parent then return end; local md = hum.MoveDirection; flyVel.Velocity = Vector3.new(md.X, 0, md.Z) * Mods.FlySpeed end)
    end
end

local infJumpConn = nil
local function SetInfJump(on)
    Mods.InfJump = on
    if infJumpConn then infJumpConn:Disconnect() infJumpConn = nil end
    if on then infJumpConn = UserInputService.JumpRequest:Connect(function() local hum = GetHum(); if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end end) end
end

local afkConn = nil
local function SetAntiAFK(on)
    Mods.AntiAFK = on
    if afkConn then afkConn:Disconnect() afkConn = nil end
    if on then afkConn = LocalPlayer.Idled:Connect(function() local vu = game:GetService("VirtualUser"); vu:CaptureController(); vu:ClickButton2(Vector2.new(0, 0)) end) end
end

local lightOrig = nil
local function SetFullBright(on)
    Mods.FullBright = on
    if on then
        if not lightOrig then lightOrig = { Brightness = Lighting.Brightness, Ambient = Lighting.Ambient, GlobalShadows = Lighting.GlobalShadows, OutdoorAmbient = Lighting.OutdoorAmbient } end
        Lighting.Brightness = 2; Lighting.GlobalShadows = false; Lighting.Ambient = Color3.fromRGB(128, 128, 128); Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
    else
        if lightOrig then Lighting.Brightness = lightOrig.Brightness; Lighting.Ambient = lightOrig.Ambient; Lighting.GlobalShadows = lightOrig.GlobalShadows; Lighting.OutdoorAmbient = lightOrig.OutdoorAmbient end
    end
end

local fogOrig = nil
local function SetNoFog(on) Mods.NoFog = on; if on then if fogOrig == nil then fogOrig = Lighting.FogEnd end; Lighting.FogEnd = 1000000 else if fogOrig then Lighting.FogEnd = fogOrig end end end

local noclipAcc = 0
RunService.Heartbeat:Connect(function(dt)
    if Mods.TimeLock then Lighting.ClockTime = Mods.Time end
    local char = GetChar()
    if char and Mods.Noclip then
        noclipAcc = noclipAcc + dt
        if noclipAcc >= 0.25 then noclipAcc = 0; for _, p in ipairs(char:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = false end end end
    end
end)
LocalPlayer.CharacterAdded:Connect(function() taskWait(1); ApplySpeedJump(); if Mods.Fly then SetFly(true) end end)

local PreviewHL, PreviewFF = nil, nil
local function UpdatePreviewESP()
    local AvatarWorld = UI.AvatarWorld
    if not AvatarWorld then return end
    local model = AvatarWorld:FindFirstChildOfClass("Model")
    if not model then return end
    if PreviewHL and not PreviewHL.Parent then PreviewHL = nil end
    if PreviewFF and not PreviewFF.Parent then PreviewFF = nil end
    if ESP.Enabled then
        local col = ESP.Rainbow and Color3.fromHSV((tick() * ESP.RainbowSpeed) % 1, 1, 1) or ESP.Color
        if not PreviewHL then PreviewHL = Instance.new("Highlight"); PreviewHL.Name = "PreviewHL"; PreviewHL.Parent = model end
        PreviewHL.Adornee = model; PreviewHL.FillColor = col; PreviewHL.OutlineColor = col; PreviewHL.FillTransparency = ESP.Transparency; PreviewHL.OutlineTransparency = 0; PreviewHL.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        if not PreviewFF then PreviewFF = Instance.new("ForceField"); PreviewFF.Name = "PreviewFF"; PreviewFF.Parent = model end
        PreviewFF.Visible = true
    else
        if PreviewHL then PreviewHL:Destroy() PreviewHL = nil end
        if PreviewFF then PreviewFF:Destroy() PreviewFF = nil end
    end
end
RunService.RenderStepped:Connect(function() if ESP.Rainbow and UI.UIVisible then UpdatePreviewESP() end end)

local home = ScrollOf(pages[1][1])
MakeText(home, "當前狀態: " .. License.Status, COL.Green)
MakeButton(home, "前往DC群組", function() setclipboard("https://discord.gg/SjRufjdF33") end)

local uidRow = FlowOf(home).AddFull(S(26))
Create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, S(6)) }, uidRow)
Create("TextLabel", { Size = UDim2.fromOffset(S(60), S(26)), BackgroundTransparency = 1, Text = T("設備碼:"), TextColor3 = COL.Green, TextSize = TS(12), Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Left, Parent = uidRow })
Create("TextLabel", { Size = UDim2.fromOffset(S(240), S(26)), BackgroundTransparency = 1, Text = DEVICE_ID, TextColor3 = COL.Red, TextSize = TS(12), Font = Enum.Font.Code, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Parent = uidRow })
local copyBtn = Create("TextButton", { Size = UDim2.fromOffset(S(50), S(24)), BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 0.35, Text = T("複製"), TextColor3 = COL.TextDark, TextSize = TS(12), Font = Enum.Font.GothamMedium, AutoButtonColor = false, Parent = uidRow })
RegisterLang(copyBtn, "複製")
AddCorner(copyBtn, S(4))
SafeClick(copyBtn, function() if setclipboard then pcall(function() setclipboard(DEVICE_ID) end); Toast("HWID已複製") else Toast("當前注入器不支持剪貼板") end end)

MakeSlider(home, "繪制刷新幀率", 10, 120, 60, function() end)
local homeGrid = CreateGrid(home)
MakeToggle(homeGrid, "刷新率", false, function(on) end)
MakeToggle(homeGrid, "防禁令", false, function(on) Toast("防禁令(殼): " .. (on and "開啟" or "關閉")) end)
MakeToggle(homeGrid, "測試4", true, function(on) end)
MakeToggle(homeGrid, "水印", false, function(on) end)
MakeToggle(homeGrid, "測試1", false, function() end)
MakeToggle(homeGrid, "測試2", false, function() end)
MakeToggle(homeGrid, "測試3", true, function() end)
MakeToggle(homeGrid, "節能模式", false, function() end)
MakeDropdown(home, "繪制樣式", { "暗淡淺灰", "霓虹彩虹", "經典白色" }, "暗淡淺灰", function(opt) Toast("繪制樣式: " .. opt) end)
MakeDropdown(home, "測試", { "123", "456", "789" }, "123", function(opt) Toast("測試: " .. opt) end)
MakeButton(home, "測試按鈕", function() Toast("殼功能, 未配置") end)
MakeText(home, "剩餘時間: " .. License.Remain, COL.Green)
MakeText(home, "SZE內部", COL.Red)
MakeText(home, "歡迎使用 如果你是買來的 那麼你吃上了 脚本未公開", COL.TextDark)

local sc12 = ScrollOf(pages[1][2])
MakeSection(sc12, "語言設置")
local langGrid = CreateGrid(sc12)
MakeToggle(langGrid, "Chinese Mode", false, function(on) SetLanguage(on and "zh" or "en") end)
MakeText(sc12, "SZELON0 on top", COL.TextDim)

local cfg = ScrollOf(pages[1][3])
MakeSection(cfg, "配置管理")
local cfgNameBox = MakeTextBox(cfg, "輸入配置名稱", "default")
local initNames = ListConfigNames()
local cfgDrop = MakeDropdown(cfg, "配置選擇", (#initNames > 0) and initNames or { "暫無配置" }, (#initNames > 0) and initNames[1] or "暫無配置", function(opt) if opt ~= "暫無配置" then cfgNameBox.Text = opt end end)
local cfgGrid = CreateGrid(cfg)
MakeButton(cfgGrid, "保存配置", function() local n = cfgNameBox.Text:gsub("^%s+", ""):gsub("%s+$", ""); if n == "" then Toast("請先輸入配置名稱") return end; SaveConfig(n); cfgDrop.SetOptions(ListConfigNames()) end)
MakeButton(cfgGrid, "讀取配置", function() local n = cfgNameBox.Text:gsub("^%s+", ""):gsub("%s+$", ""); if n == "" then Toast("請先輸入配置名稱") return end; LoadConfig(n) end)
MakeButton(cfgGrid, "刪除配置", function() local n = cfgNameBox.Text:gsub("^%s+", ""):gsub("%s+$", ""); if n == "" then Toast("請先輸入配置名稱") return end; DeleteConfig(n); cfgDrop.SetOptions(ListConfigNames()) end)
MakeButton(cfgGrid, "刷新列表", function() cfgDrop.SetOptions(ListConfigNames()); Toast("配置列表已刷新") end)
local autoOn0, autoName0 = GetAutoLoad()
MakeToggle(cfg, "自動加載配置", autoOn0, function(on) local n = cfgNameBox.Text:gsub("^%s+", ""):gsub("%s+$", ""); if n == "" then n = "default" end; SetAutoLoad(on, n); Toast(on and ("执行將自動加載: " .. n) or "關閉自動加載") end, false)
MakeText(cfg, "配置存於注入器目錄 RealYo_Configs", COL.TextDim)

local sc14 = ScrollOf(pages[1][4])
MakeSection(sc14, "主題與邊框")
local themeOptions = { T("經典"), T("深藍"), T("賽博"), T("吸血") }
MakeDropdown(sc14, "罐頭主題", themeOptions, T("經典"), function(opt)
    local nameMap = { Classic = "經典", ["Deep Blue"] = "深藍", Cyber = "賽博", Vampire = "吸血" }
    ApplyTheme(nameMap[opt] or opt)
end)
MakeInlineAlphaSlider(FlowOf(sc14))
MakeDropdown(sc14, "邊框樣式", { "彩虹", "單色" }, "彩虹", function(o) UI.AP.BorderRainbow = (o == "彩虹"); Toast(UI.AP.BorderRainbow and "邊框: 彩虹" or "邊框: 單色") end)
MakeDropdown(sc14, "字體樣式", { "Gotham", "SciFi", "SourceSans", "FredokaOne", "Code", "Ubuntu", "Bangers", "Merriweather" }, "Gotham", ApplyFont)
MakeSection(sc14, "自定義調色 (畫板)")
local pickerTarget = "UI底"
local pickerInfoLabel = nil
MakeDropdown(sc14, "調色目標", { "UI底", "組件", "主文字", "暗文字", "強調色", "邊框" }, "UI底", function(o) pickerTarget = o; if pickerInfoLabel then pickerInfoLabel.Text = T("目標: ") .. T(o) end; Toast(T("調色目標") .. ": " .. T(o)) end)
pickerInfoLabel = MakeText(sc14, "目標: UI底 (拖動畫板套用)", COL.TextDim)
MakeColorPicker(sc14)

local draw = ScrollOf(pages[2][1])
MakeSection(draw, "ESP 透視控制 (所見即所得)")
local espGrid = CreateGrid(draw)
MakeToggle(espGrid, "啟動透視", false, function(on) ESP.Enabled = on; UpdatePreviewESP() end)
MakeToggle(espGrid, "顯示名字", false, function(on) ESP.Names = on end)
MakeSlider(draw, "最大距離", 50, 1000, 500, function(v) ESP.MaxDistance = v end)
MakeSlider(draw, "透明度", 0, 100, 50, function(v) ESP.Transparency = v / 100; UpdatePreviewESP() end)
MakeSection(draw, "進階配置")
MakeSlider(draw, "方框/線條粗細", 1, 10, 1, function(v) ESP.Thickness = v end)
MakeSlider(draw, "名字字體大小", 10, 30, 13, function(v) ESP.FontSize = v end)
MakeSection(draw, "自定義RGB")
MakeSlider(draw, "R", 0, 255, 255, function(v) ESP.R = v; ESP.Color = Color3.fromRGB(ESP.R, ESP.G, ESP.B); UpdatePreviewESP() end)
MakeSlider(draw, "G", 0, 255, 50, function(v) ESP.G = v; ESP.Color = Color3.fromRGB(ESP.R, ESP.G, ESP.B); UpdatePreviewESP() end)
MakeSlider(draw, "B", 0, 255, 50, function(v) ESP.B = v; ESP.Color = Color3.fromRGB(ESP.R, ESP.G, ESP.B); UpdatePreviewESP() end)
MakeSection(draw, "彩虹")
local rainbowGrid = CreateGrid(draw)
MakeToggle(rainbowGrid, "開啟彩虹", false, function(on) Toast("已設置為彩虹"); ESP.Rainbow = on; UpdatePreviewESP() end)
MakeSlider(draw, "速度", 1, 50, 10, function(v) ESP.RainbowSpeed = v / 10 end)

local move = ScrollOf(pages[3][1])
MakeSection(move, "开源通用功能")
local moveGrid = CreateGrid(move)
MakeToggle(moveGrid, "飛行", false, function(on) SetFly(on) end)
MakeToggle(moveGrid, "穿牆", false, function(on) Mods.Noclip = on end)
MakeToggle(moveGrid, "無限跳", false, function(on) SetInfJump(on) end)
MakeToggle(moveGrid, "移速", false, function(on) Mods.SpeedOn = on; ApplySpeedJump() end)
MakeToggle(moveGrid, "跳躍力度", false, function(on) Mods.JumpOn = on; ApplySpeedJump() end)
MakeSlider(move, "飛行速度", 10, 200, 50, function(v) Mods.FlySpeed = v end)
MakeSlider(move, "移動速度", 16, 300, 16, function(v) Mods.Speed = v; ApplySpeedJump() end)
MakeSlider(move, "跳躍力度", 50, 500, 50, function(v) Mods.Jump = v; ApplySpeedJump() end)

local charPage = ScrollOf(pages[3][2])
local charGrid = CreateGrid(charPage)
MakeToggle(charGrid, "防掛機踢出", false, function(on) SetAntiAFK(on) end)
MakeButton(charPage, "重置角色", function() local hum = GetHum(); if hum then hum.Health = 0 end end)

local world = ScrollOf(pages[3][3])
local worldGrid = CreateGrid(world)
MakeToggle(worldGrid, "全亮", false, function(on) SetFullBright(on) end)
MakeToggle(worldGrid, "去霧", false, function(on) SetNoFog(on) end)
MakeToggle(worldGrid, "鎖定時間", false, function(on) Mods.TimeLock = on end)
MakeSlider(world, "鎖定時間點", 0, 24, 14, function(v) Mods.Time = v end)

local util = ScrollOf(pages[3][4])
MakeButton(util, "複製當前坐標", function() local root = GetRoot(); if not root then Toast("角色未就緒") return end; if setclipboard then pcall(function() setclipboard(tostring(root.CFrame)) end); Toast("坐標已複製") else Toast("注入器不支持剪貼板") end end)
MakeButton(util, "重加入服務器", function() pcall(function() TeleportService:Teleport(game.PlaceId) end) end)
MakeText(util, "管理员命令脚本", COL.TextDim)

local script1 = ScrollOf(pages[4][1])
MakeButton(script1, "外接：Area51 (RealYoHub)", function()
    local url = "https://raw.githubusercontent.com/gy1619/RealYoHub/refs/heads/main/area51.lua?t=" .. os.time()
    local ok, err = pcall(function() loadstring(game:HttpGet(url))() end)
    Toast(ok and "Area51 已执行" or ("Area51 失败: " .. tostring(err):sub(1, 60)))
end)
MakeButton(script1, "BrookHaven RP", function() local ry = pcall(function() loadstring(game:HttpGet("https://gist.githubusercontent.com/gy1619/29ee3701d50f59ee4061c5a96d7a79c5/raw/bf871ba30f57e8929a4d847841114f31d9f73894/bhhrp.lua"))() end); Toast(ry and "已执行" or "未知错误") end)
MakeButton(script1, "My Restaurant", function() local ry = pcall(function() loadstring(game:HttpGet("https://gist.githubusercontent.com/gy1619/a44f37202fd255c36bfd2e05b66204bd/raw/374703400612786c6ad8b1dbe57d9de42f3c879b/My%20Restaurant.lua"))() end); Toast(ry and "已执行" or "未知错误") end)
MakeButton(script1, "Cut Grass", function() local ry = pcall(function() loadstring(game:HttpGet("https://gist.githubusercontent.com/gy1619/58841eb6cb738a4c9fffeaee95d8d6c8/raw/77d5043da62b0a092f0416787d6ca284899d8ece/Cut%20Grass.lua"))() end); Toast(ry and "已执行" or "未知错误") end)
MakeButton(script1, "Poop a Big Poop", function() local ry = pcall(function() loadstring(game:HttpGet("https://gist.githubusercontent.com/gy1619/ddd84a349399d4059acd9778c79b73c4/raw/403cdb6417fc2a5af213d0eaafde1a643b1d6155/pabp.lua"))() end); Toast(ry and "已执行" or "未知错误") end)
MakeText(script1, "自家脚本 RealYoHub", COL.TextDim)

local script2 = ScrollOf(pages[4][2]); MakeText(script2, "尚未完善", COL.TextDim)
local script3 = ScrollOf(pages[4][3]); MakeText(script3, "尚未完善", COL.TextDim)
local script4 = ScrollOf(pages[4][4])
MakeButton(script4, "加載 Infinite Yield", function() local ok = pcall(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))() end); Toast(ok and "Infinite Yield 已啟動" or "加載失敗 (網絡/注入器限制)") end)
MakeText(script4, "管理员命令脚本", COL.TextDim)

LoadAvatar()
task.delay(2.5, UpdatePreviewESP)
LocalPlayer.CharacterAdded:Connect(function() taskWait(2); LoadAvatar() end)
if autoOn0 and autoName0 then task.delay(1, function() LoadConfig(autoName0) end) end
taskWait(0.5)
Toast("加载完成，設備碼: " .. DEVICE_ID)
taskWait(0.5)
Toast("點擊懸浮球打開, 按住面板頂部空白條可拖動")
print(">>> [RealYoUI] Script Loaded Successfully!")
