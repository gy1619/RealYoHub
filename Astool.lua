-- PremiumUI.lua
-- PremiumUI Standalone UI Library + GameBridge Takeover Protocol V3.2
local Lib = {
    Version = "3.2.0",
    Brand = "PremiumUI",
    BridgeProtocol = 2,
    IsPremiumUI = true,
    Initialized = false,
}

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local LocalPlayer = Players.LocalPlayer

local cloneref = cloneref or function(o) return o end
local okCore, CoreGuiService = pcall(function() return cloneref(game:GetService("CoreGui")) end)
local taskWait = (task and task.wait) or function() return wait() end

local camNow = workspace.CurrentCamera
local vpSize = (camNow and camNow.ViewportSize) or Vector2.new(1280, 720)
if vpSize.X < 100 then vpSize = Vector2.new(1280, 720) end
local UI_SCALE = math.min(vpSize.X / 1280, vpSize.Y / 720)
if UI_SCALE <= 0 then UI_SCALE = 1 end

local function S(v) return v * UI_SCALE end
local function TS(v) return math.max(10, math.floor(v * UI_SCALE)) end
Lib.S = S
Lib.TS = TS

local function Create(class, props, parent)
    local obj = Instance.new(class)
    for k, v in pairs(props or {}) do obj[k] = v end
    if parent then obj.Parent = parent end
    return obj
end
Lib.Create = Create

-- ★ 关键修复：AddCorner 必须在 Toast 之前定义
local function AddCorner(parent, r) return Create("UICorner", { CornerRadius = UDim.new(0, r) }, parent) end
Lib.AddCorner = AddCorner

local COL = {
    TextDark = Color3.fromRGB(70, 70, 70), TextDim = Color3.fromRGB(110, 110, 110),
    Red = Color3.fromRGB(215, 60, 60), Green = Color3.fromRGB(50, 190, 90),
    PillGray = Color3.fromRGB(75, 75, 75), White = Color3.fromRGB(255, 255, 255),
}
Lib.COL = COL

local currentLang = "en"
local I18N = {
    ["首頁設置"]="Home",["繪制面板"]="ESP",["通用功能"]="Misc",["腳本中心"]="Scripts",
    ["公告相關"]="Info",["其他相關"]="Other",["配置相關"]="Configs",["界面相關"]="Appearance",
    ["透視相關"]="Chams",["方框相關"]="Boxes",["骨骼相關"]="Skeleton",["距離相關"]="Tags",
    ["移動相關"]="Movement",["角色相關"]="Player",["世界相關"]="World",["實用相關"]="Utility",
    ["自家腳本"]="Our Scripts",["免卡腳本"]="Free Hubs",["需卡密腳本"]="Key Hubs",["通用管理員"]="Admin",
    ["當前狀態: 當前開放 (無需卡密)"]="Status: Open (No Key)",
    ["前往DC群組"]="Join Discord",["設備碼:"]="HWID:",["複製"]="Copy",["HWID已複製"]="HWID copied",
    ["當前注入器不支持剪貼板"]="Executor lacks clipboard",
    ["剩餘時間: 暫時免費  無須獲取密鑰"]="Time Left: Free (No Key)",
    ["SZE內部"]="SZE Internal",
    ["歡迎使用 如果你是買來的 那麼你吃上了 脚本未公開"]="Welcome! If you paid, you got scammed - not public",
    ["繪制刷新幀率"]="Render FPS",["刷新率"]="FPS",["防禁令"]="Anti-BAN",
    ["水印"]="Watermark",["測試1"]="Test 1",["測試2"]="Test 2",["測試3"]="Test 3",["測試4"]="Test 4",
    ["節能模式"]="Low Power",["繪制樣式"]="ESP Theme",
    ["暗淡淺灰"]="Dull Gray",["霓虹彩虹"]="Neon Rainbow",["經典白色"]="Classic White",
    ["測試"]="Test",["測試按鈕"]="Test Button",["殼功能, 未配置"]="Shell feature, not configured",
    ["語言設置"]="Language",["Chinese Mode"]="Chinese Mode",
    ["配置管理"]="Config Manager",["輸入配置名稱"]="Config name",["配置選擇"]="Config",
    ["暫無配置"]="(none)",["保存配置"]="Save",["讀取配置"]="Load",["刪除配置"]="Delete",
    ["刷新列表"]="Refresh",["配置列表已刷新"]="Config list refreshed",
    ["自動加載配置"]="Auto-Load",["請先輸入配置名稱"]="Enter a config name first",
    ["配置存於注入器目錄 PremiumUI_Configs"]="Configs saved in PremiumUI_Configs",
    ["主題與邊框"]="Theme & Border",["罐頭主題"]="Presets",["邊框樣式"]="Border Style",["字體樣式"]="Font",
    ["自定義調色 (畫板)"]="Custom Colors (Picker)",["調色目標"]="Color Target",
    ["經典"]="Classic",["深藍"]="Deep Blue",["賽博"]="Cyber",["吸血"]="Vampire",
    ["彩虹"]="Rainbow",["單色"]="Solid",
    ["UI底"]="UI BG",["組件"]="Components",["主文字"]="Main Text",["暗文字"]="Dim Text",["強調色"]="Accent",["邊框"]="Border",
    ["色相"]="Hue",["飽和"]="Sat",["明度"]="Val",["目標: "]="Target: ",
    ["目標: UI底 (拖動畫板套用)"]="Target: UI BG (drag picker)",
    ["ESP 透視控制 (所見即所得)"]="ESP (WYSIWYG)",["啟動透視"]="Enable ESP",["顯示名字"]="Names",
    ["最大距離"]="Max Distance",["透明度"]="Fill Alpha",["進階配置"]="Advanced",
    ["方框/線條粗細"]="Thickness",["名字字體大小"]="Font Size",["自定義RGB"]="Custom RGB",
    ["開啟彩虹"]="Rainbow Mode",["速度"]="Speed",["已設置為彩虹"]="Rainbow set",
    ["开源通用功能"]="Open-source Utilities",
    ["飛行"]="Fly",["穿牆"]="Noclip",["無限跳"]="Inf Jump",["移速"]="Speed",["跳躍力度"]="Jump Power",
    ["飛行速度"]="Fly Speed",["移動速度"]="Walk Speed",
    ["防掛機踢出"]="Anti-AFK",["重置角色"]="Reset Character",
    ["全亮"]="Fullbright",["去霧"]="No Fog",["鎖定時間"]="Lock Time",["鎖定時間點"]="Time of Day",
    ["複製當前坐標"]="Copy Position",["坐標已複製"]="Position copied",["重加入服務器"]="Rejoin",
    ["管理员命令脚本"]="Admin script",["角色未就緒"]="Character not ready",
    ["电脑端Survive in area 51!"]="PC: Survive in Area 51",["手机端Survive in area 51!"]="Mobile: Survive in Area 51",
    ["已执行"]="Executed",["未知错误"]="Error",
    ["自家脚本 RealYoHub"]="Our Scripts - RealYoHub",["尚未完善"]="WIP",
    ["加載 Infinite Yield"]="Load Infinite Yield",
    ["Infinite Yield 已啟動"]="Infinite Yield loaded",
    ["加載失敗 (網絡/執行器限制)"]="Load failed (network/executor)",
    ["UI透明度"]="UI Alpha",
}
Lib.I18N = I18N

local function T(s)
    if s == nil then return "" end
    if currentLang == "en" then return I18N[s] or s end
    return s
end
Lib.T = T

local langRegistry = {}
local langEntryByObj = {}
local function RegisterLang(obj, zh, ph, custom)
    local e = { obj = obj, zh = zh, ph = ph, custom = custom }
    langEntryByObj[obj] = e
    table.insert(langRegistry, e)
    return e
end
Lib.RegisterLang = RegisterLang

local function ApplyLanguage()
    for _, e in ipairs(langRegistry) do
        local o = e.obj
        if o and o.Parent then
            if e.custom then e.custom()
            elseif e.ph then o.PlaceholderText = T(e.zh)
            else o.Text = T(e.zh) end
        end
    end
end

local function GetHWID()
    local cands = { "gethwid", "get_hwid", "GetHwid", "gethardwareid", "get_sha1" }
    for _, fn in ipairs(cands) do
        local f = _G[fn]
        if type(f) == "function" then
            local ok, r = pcall(f)
            if ok and r then return tostring(r) end
        end
    end
    return "NOHWID"
end

local function HashStr(s)
    local h = 5381
    for i = 1, #s do h = (h * 33 + string.byte(s, i)) % 4294967296 end
    return string.format("%08X", h)
end
Lib.HashStr = HashStr

local DEVICE_ID = HashStr(LocalPlayer.UserId .. "_" .. GetHWID()) .. HashStr("PremiumUI_SZE" .. LocalPlayer.UserId)
Lib.DEVICE_ID = DEVICE_ID

local License = {
    Mode = "open", Status = "當前開放 (無需卡密)",
    Remain = "暫時免費  無須獲取密鑰", BoundDevice = DEVICE_ID,
}
Lib.License = License

local SettingRegistry = {}
local function RegisterSetting(name, kind, get, set)
    table.insert(SettingRegistry, { name = name, kind = kind, get = get, set = set })
end
Lib.RegisterSetting = RegisterSetting

local CFG_DIR = "PremiumUI_Configs"
local AUTO_FILE = CFG_DIR .. "/_autoload_.json"
local function FileSupport() return type(writefile) == "function" and type(readfile) == "function" and type(isfile) == "function" end
local function EnsureFolder() pcall(function() if type(makefolder) == "function" and not isfolder(CFG_DIR) then makefolder(CFG_DIR) end end) end

local function ListConfigNames()
    local names = {}
    pcall(function()
        if type(listfiles) == "function" then
            for _, p in ipairs(listfiles(CFG_DIR)) do
                local n = tostring(p):match("([^/\\]+)%.json$")
                if n and n ~= "_autoload_" then table.insert(names, n) end
            end
        end
    end)
    return names
end
Lib.ListConfigNames = ListConfigNames

local ScreenGui = nil
local ToastHolder = nil

local function Toast(msg)
    if not ToastHolder then print("[Toast]", msg) return end
    local label = Create("TextLabel", {
        Size = UDim2.fromOffset(S(280), S(30)), BackgroundColor3 = Color3.fromRGB(20, 20, 20),
        Text = msg, TextColor3 = COL.White, TextSize = TS(13), Font = Enum.Font.GothamMedium,
        BackgroundTransparency = 1, TextTransparency = 1, Parent = ToastHolder,
    })
    AddCorner(label, S(6))
    TweenService:Create(label, TweenInfo.new(0.2), { BackgroundTransparency = 0.25, TextTransparency = 0 }):Play()
    taskWait(1.8)
    TweenService:Create(label, TweenInfo.new(0.3), { BackgroundTransparency = 1, TextTransparency = 1 }):Play()
    taskWait(0.35)
    label:Destroy()
end
Lib.Toast = Toast

local function SaveConfig(name)
    if not FileSupport() then Toast("當前注入器不支持文件保存") return end
    local data = {}
    for _, e in ipairs(SettingRegistry) do data[e.name] = e.get() end
    EnsureFolder()
    local ok = pcall(function() writefile(CFG_DIR .. "/" .. name .. ".json", HttpService:JSONEncode(data)) end)
    Toast(ok and ("配置已保存: " .. name) or "保存失敗")
end
Lib.SaveConfig = SaveConfig

local function LoadConfig(name)
    if not FileSupport() then Toast("當前注入器不支持文件讀取") return end
    local path = CFG_DIR .. "/" .. name .. ".json"
    local ok, raw = pcall(function() if not isfile(path) then return nil end return readfile(path) end)
    if not ok or not raw then Toast("配置不存在: " .. name) return end
    local ok2, data = pcall(function() return HttpService:JSONDecode(raw) end)
    if not ok2 or type(data) ~= "table" then Toast("配置損壞: " .. name) return end
    local count = 0
    for _, e in ipairs(SettingRegistry) do if data[e.name] ~= nil then e.set(data[e.name]); count = count + 1 end end
    Toast(("配置已讀取: %s (%d項)"):format(name, count))
end
Lib.LoadConfig = LoadConfig

local function DeleteConfig(name)
    if not FileSupport() then Toast("當前注入器不支持文件刪除") return end
    local ok = pcall(function() if isfile(CFG_DIR .. "/" .. name .. ".json") then delfile(CFG_DIR .. "/" .. name .. ".json") end end)
    Toast(ok and ("配置已刪除: " .. name) or "刪除失敗")
end
Lib.DeleteConfig = DeleteConfig

local function GetAutoLoad()
    local ok, raw = pcall(function() if not isfile(AUTO_FILE) then return nil end return readfile(AUTO_FILE) end)
    if not ok or not raw then return false, nil end
    local ok2, d = pcall(function() return HttpService:JSONDecode(raw) end)
    if ok2 and type(d) == "table" then return d.enabled == true, d.name end
    return false, nil
end
Lib.GetAutoLoad = GetAutoLoad

local function SetAutoLoad(enabled, name)
    if not FileSupport() then Toast("當前注入器不支持文件保存") return end
    EnsureFolder()
    pcall(function() writefile(AUTO_FILE, HttpService:JSONEncode({ enabled = enabled, name = name })) end)
end
Lib.SetAutoLoad = SetAutoLoad

local rainbowGrads = {}
local rainbowT0 = tick()
local RAINBOW_SEQ = ColorSequence.new({
    ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 70, 70)), ColorSequenceKeypoint.new(0.25, Color3.fromRGB(255, 210, 70)),
    ColorSequenceKeypoint.new(0.50, Color3.fromRGB(90, 255, 130)), ColorSequenceKeypoint.new(0.75, Color3.fromRGB(90, 170, 255)),
    ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 90, 255)),
})

local function AddRainbowStroke(parent, thickness, glow)
    local stroke = Create("UIStroke", { Thickness = thickness or math.max(1, S(1.5)), Color = COL.White }, parent)
    local grad = Create("UIGradient", { Rotation = 25, Color = RAINBOW_SEQ }, stroke)
    table.insert(rainbowGrads, grad)
    if glow then
        local layers = { { S(4), 0.5 }, { S(7), 0.75 }, { S(10), 0.9 } }
        for _, info in ipairs(layers) do
            local s2 = Create("UIStroke", { Thickness = info[1], Color = COL.White, Transparency = info[2] }, parent)
            local g2 = Create("UIGradient", { Rotation = 25, Color = RAINBOW_SEQ }, s2)
            table.insert(rainbowGrads, g2)
        end
    end
    return stroke
end

local function AddRainbowBar(parent)
    local bar = Create("Frame", { Size = UDim2.new(1, 0, 0, math.max(1, S(2))), BackgroundColor3 = COL.White, Parent = parent })
    local grad = Create("UIGradient", { Rotation = 0, Color = RAINBOW_SEQ }, bar)
    table.insert(rainbowGrads, grad)
    return bar
end

local function AddGlass(parent)
    parent.BackgroundColor3 = COL.White
    parent.BackgroundTransparency = 0.45
end

local function SafeClick(obj, cb)
    local down, moved, startPos = false, false, nil
    obj.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            down, moved = true, false; startPos = inp.Position
        end
    end)
    obj.InputChanged:Connect(function(inp)
        if down and startPos and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
            if (inp.Position - startPos).Magnitude > 8 then moved = true end
        end
    end)
    obj.InputEnded:Connect(function(inp)
        if down and (inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch) then
            down = false; if not moved then cb() end
        end
    end)
end
Lib.SafeClick = SafeClick

local UIVisible = false
Lib.UIVisible = UIVisible
local panelList = {}
local panelDrag = nil

UserInputService.InputChanged:Connect(function(inp)
    if panelDrag and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
        local d = inp.Position - panelDrag.start
        local f = panelDrag.frame
        local nx = math.clamp(panelDrag.orig.X.Offset + d.X, 0, math.max(0, vpSize.X - f.AbsoluteSize.X))
        local ny = math.clamp(panelDrag.orig.Y.Offset + d.Y, 0, math.max(0, vpSize.Y - f.AbsoluteSize.Y))
        f.Position = UDim2.fromOffset(nx, ny)
    end
end)
UserInputService.InputEnded:Connect(function(inp)
    if panelDrag and (inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch) then panelDrag = nil end
end)

local function MakeDragHandle(panel, size, position)
    local handle = Create("Frame", { Size = size, Position = position, BackgroundTransparency = 1, Parent = panel, ZIndex = 4 })
    handle.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            panelDrag = { frame = panel, start = inp.Position, orig = panel.Position }
        end
    end)
    return handle
end

local sideW = S(150)
local sidePad, sideBtnH, sideGap = S(6), S(40), S(6)
local mainNames = { "首頁設置", "繪制面板", "通用功能", "腳本中心" }
local sideH = S(28) + sidePad + #mainNames * sideBtnH + (#mainNames - 1) * sideGap + sidePad
local mainW, mainH = S(640), S(520)
local rightW, rightH = S(170), S(420)
local gap = S(18)
local totalW = sideW + mainW + rightW + gap * 2
local startX = (vpSize.X - totalW) / 2
local sideY = (vpSize.Y - sideH) / 2
local mainY = (vpSize.Y - mainH) / 2
local rightY = (vpSize.Y - rightH) / 2
local subNameSets = {
    { "公告相關", "其他相關", "配置相關", "界面相關" },
    { "透視相關", "方框相關", "骨骼相關", "距離相關" },
    { "移動相關", "角色相關", "世界相關", "實用相關" },
    { "自家腳本", "免卡腳本", "需卡密腳本", "通用管理員" },
}

local function EstW(text, size)
    size = size or TS(13)
    local s = tostring(text)
    local bytes, cjk = #s, 0
    for i = 1, bytes do if string.byte(s, i) > 127 then cjk = cjk + 1 end end
    return (cjk / 3) * size * 1.05 + (bytes - cjk) * size * 0.7 + S(4)
end

local flowByScroll = {}
local function FlowOf(scroll)
    if flowByScroll[scroll] then return flowByScroll[scroll] end
    local container = Create("Frame", { Size = UDim2.new(1, -S(8), 0, 0), BackgroundTransparency = 1, Parent = scroll })
    local slots = {}
    local padX, padY = S(12), S(10)
    local function layout()
        local maxW = container.AbsoluteSize.X
        if maxW < 50 then maxW = mainW - S(40) end
        local curX, curY, rowH, rowWide = 0, 0, 0, false
        for _, s in ipairs(slots) do
            local h = s.Size.Y.Offset
            if s:GetAttribute("full") then
                if curX > 0 then curX = 0; curY = curY + rowH + padY; rowH = 0 end
                s.Position = UDim2.fromOffset(0, curY)
                s.Size = UDim2.new(1, 0, 0, h)
                curY = curY + h + padY
                rowWide = false
            else
                local w = s.Size.X.Offset
                local wide = s:GetAttribute("wide")
                if curX > 0 then
                    local wrap = (curX + w > maxW) or (wide and not rowWide and (maxW - curX) < w * 2)
                    if wrap then curX = 0; curY = curY + rowH + padY; rowH = 0; rowWide = false end
                end
                s.Position = UDim2.fromOffset(curX, curY)
                curX = curX + w + padX
                if h > rowH then rowH = h end
                rowWide = rowWide or wide
            end
        end
        container.Size = UDim2.new(1, -S(8), 0, curY + rowH + S(2))
    end
    local flow = {}
    flow.Add = function(w, h)
        local slot = Create("Frame", { Size = UDim2.fromOffset(math.ceil(w or S(150)), math.ceil(h or S(28))), BackgroundTransparency = 1, Parent = container })
        if (w or 0) >= S(240) then slot:SetAttribute("wide", true) end
        table.insert(slots, slot)
        flow._used = true
        layout()
        return slot
    end
    flow.AddFull = function(h)
        local slot = Create("Frame", { Size = UDim2.new(1, 0, 0, math.ceil(h or S(20))), BackgroundTransparency = 1, Parent = container })
        slot:SetAttribute("full", true)
        table.insert(slots, slot)
        flow._used = true
        layout()
        return slot
    end
    flowByScroll[scroll] = flow
    return flow
end
Lib.FlowOf = FlowOf

local function AsFlow(parent) return (type(parent) == "table" and parent.Add) and parent or FlowOf(parent) end
local function CreateGrid(scroll) return FlowOf(scroll) end
Lib.CreateGrid = CreateGrid

local function MakeText(parent, text, color, size)
    local slot = AsFlow(parent).AddFull((size or TS(13)) + S(6))
    local l = Create("TextLabel", {
        Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1,
        Text = T(text), TextColor3 = color, TextSize = size or TS(13),
        Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true, Parent = slot,
    })
    RegisterLang(l, text)
    return l
end

local function MakeSection(parent, text)
    local flow = AsFlow(parent)
    local had = flow._used
    local slot = flow.AddFull(S(26))
    if had then
        Create("Frame", {
            Size = UDim2.new(1, -S(24), 0, math.max(1, S(1))), Position = UDim2.fromOffset(S(12), 0),
            BackgroundColor3 = Color3.fromRGB(128, 128, 128), BackgroundTransparency = 0.6, Parent = slot,
        })
    end
    local l = Create("TextLabel", {
        Size = UDim2.new(1, 0, 0, S(18)), Position = UDim2.fromOffset(0, S(8)), BackgroundTransparency = 1,
        Text = T(text), TextColor3 = COL.TextDark, TextSize = TS(12), Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = slot,
    })
    RegisterLang(l, text)
    return l
end

local function MakeButton(parent, text, cb)
    local host = AsFlow(parent).Add(math.max(S(40) + EstW(T(text), TS(12)), S(90)), S(28))
    local btn = Create("TextButton", {
        Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 0.35,
        Text = T(text), TextColor3 = COL.TextDark, Font = Enum.Font.GothamMedium,
        TextSize = TS(12), AutoButtonColor = false, Parent = host,
    })
    AddCorner(btn, S(5))
    Create("UIStroke", { Thickness = 1, Color = Color3.fromRGB(160, 160, 160), Transparency = 0.4 }, btn)
    SafeClick(btn, function() if cb then cb() end end)
    RegisterLang(btn, text)
    return btn
end

local function MakeTextBox(parent, placeholder, default)
    local host = AsFlow(parent).Add(S(200), S(28))
    local box = Create("TextBox", {
        Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = COL.White, BackgroundTransparency = 0.35,
        Text = default or "", PlaceholderText = T(placeholder), TextColor3 = COL.TextDark,
        Font = Enum.Font.GothamMedium, TextSize = TS(13), ClearTextOnFocus = false, Parent = host,
    })
    AddCorner(box, S(5))
    Create("UIStroke", { Thickness = 1, Color = Color3.fromRGB(160, 160, 160), Transparency = 0.4 }, box)
    RegisterLang(box, placeholder, true)
    return box
end

local function MakeToggle(parent, text, default, cb, register)
    if register == nil then register = true end
    local host = AsFlow(parent).Add(S(36) + EstW(T(text)) + S(10), S(28))
    local state = default and true or false
    local row = Create("Frame", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Parent = host })
    local box = Create("Frame", {
        Size = UDim2.fromOffset(S(18), S(18)), Position = UDim2.fromOffset(0, S(5)),
        BackgroundColor3 = state and COL.Red or Color3.fromRGB(120, 120, 120), Parent = row,
    })
    AddCorner(box, S(3))
    local label = Create("TextLabel", {
        Size = UDim2.new(1, -S(26), 1, 0), Position = UDim2.fromOffset(S(26), 0), BackgroundTransparency = 1,
        Text = T(text), TextColor3 = COL.TextDark, TextSize = TS(13), Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Parent = row,
    })
    RegisterLang(label, text)
    local function apply(v, fire)
        v = v and true or false
        if v == state then return end
        state = v
        box.BackgroundColor3 = state and COL.Red or Color3.fromRGB(120, 120, 120)
        if fire and cb then cb(state) end
    end
    SafeClick(row, function() apply(not state, true) end)
    if register then RegisterSetting(text, "toggle", function() return state end, function(v) apply(v, true) end) end
    return row
end

local function MakeSlider(parent, text, min, max, default, cb)
    local row = AsFlow(parent).Add(S(252), S(30))
    local desc = Create("TextLabel", {
        Size = UDim2.fromOffset(S(92), S(16)), Position = UDim2.new(0, 0, 0.5, -S(8)), BackgroundTransparency = 1,
        Text = T(text), TextColor3 = COL.TextDim, TextSize = TS(11), Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Parent = row,
    })
    RegisterLang(desc, text)
    local track = Create("Frame", {
        Size = UDim2.fromOffset(S(120), S(8)), Position = UDim2.new(0, S(96), 0.5, -S(4)),
        BackgroundColor3 = Color3.fromRGB(120, 120, 120), BackgroundTransparency = 0.3, Parent = row,
    })
    AddCorner(track, S(4))
    local fill = Create("Frame", { BackgroundColor3 = COL.Red, Parent = track })
    AddCorner(fill, S(4))
    fill:SetAttribute("role", "accentbg")
    local knob = Create("Frame", {
        Size = UDim2.fromOffset(S(12), S(12)), BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 2, Parent = track,
    })
    AddCorner(knob, S(6))
    local valLabel = Create("TextLabel", {
        Size = UDim2.fromOffset(S(34), S(16)), Position = UDim2.new(0, S(218), 0.5, -S(8)), BackgroundTransparency = 1,
        TextColor3 = COL.TextDark, TextSize = TS(11), Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Right, Parent = row,
    })
    local currentVal = default
    local dragging = false
    local function setRatio(r, fire)
        r = math.clamp(r, 0, 1)
        fill.Size = UDim2.new(r, 0, 1, 0)
        knob.Position = UDim2.new(r, -S(6), 0.5, -S(6))
        currentVal = math.floor(min + (max - min) * r + 0.5)
        valLabel.Text = tostring(currentVal)
        if fire and cb then cb(currentVal) end
    end
    local function updateFromX(x, fire)
        if track.AbsoluteSize.X <= 0 then return end
        setRatio((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, fire)
    end
    setRatio((default - min) / (max - min), false)
    track.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            dragging = true; updateFromX(inp.Position.X, true)
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if dragging and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
            updateFromX(inp.Position.X, true)
        end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if dragging and (inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch) then
            dragging = false
        end
    end)
    RegisterSetting(text, "slider", function() return currentVal end, function(v)
        v = math.clamp(tonumber(v) or default, min, max)
        setRatio((v - min) / (max - min), true)
    end)
end

local openDropdown = nil
local function CloseDropdown() if openDropdown then openDropdown.Visible = false; openDropdown = nil end end
UserInputService.InputBegan:Connect(function(inp)
    if openDropdown and (inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch) then
        local p = inp.Position; local lp = openDropdown.AbsolutePosition; local ls = openDropdown.AbsoluteSize
        if p.X < lp.X or p.X > lp.X + ls.X or p.Y < lp.Y or p.Y > lp.Y + ls.Y then CloseDropdown() end
    end
end)

local function MakeDropdown(parent, text, options, default, cb)
    local row = AsFlow(parent).Add(S(150) + EstW(T(text), TS(12)) + S(16), S(30))
    local btn = Create("TextButton", {
        Size = UDim2.fromOffset(S(150), S(26)), BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 0.35,
        Text = T(default) .. "  v", TextColor3 = COL.TextDark, TextSize = TS(12),
        Font = Enum.Font.GothamMedium, AutoButtonColor = false, Parent = row,
    })
    AddCorner(btn, S(5))
    Create("UIStroke", { Thickness = 1, Color = Color3.fromRGB(160, 160, 160), Transparency = 0.4 }, btn)
    local desc = Create("TextLabel", {
        Size = UDim2.new(1, -S(154), 1, 0), Position = UDim2.fromOffset(S(154), 0), BackgroundTransparency = 1,
        Text = T(text), TextColor3 = COL.TextDim, TextSize = TS(12), Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Parent = row,
    })
    RegisterLang(desc, text)
    local list = Create("Frame", {
        BackgroundColor3 = Color3.fromRGB(40, 40, 40), BackgroundTransparency = 0.1,
        Visible = false, Parent = ScreenGui, ZIndex = 70,
    })
    AddCorner(list, S(5))
    Create("UIListLayout", { Padding = UDim.new(0, S(2)) }, list)
    Create("UIPadding", { PaddingTop = UDim.new(0, S(3)), PaddingLeft = UDim.new(0, S(3)), PaddingRight = UDim.new(0, S(3)) }, list)
    local handle = {}; local cur = default
    RegisterLang(btn, nil, false, function() btn.Text = T(cur) .. "  v" end)
    local function buildOptions(opts)
        for _, c in ipairs(list:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
        for _, opt in ipairs(opts) do
            local ob = Create("TextButton", {
                Size = UDim2.new(1, 0, 0, S(24)), BackgroundTransparency = 1,
                Text = T(opt), TextColor3 = COL.White, TextSize = TS(12),
                Font = Enum.Font.Gotham, AutoButtonColor = false, Parent = list,
            })
            RegisterLang(ob, opt)
            SafeClick(ob, function()
                cur = opt; btn.Text = T(opt) .. "  v"; CloseDropdown()
                if cb then cb(opt) end
            end)
        end
        list.Size = UDim2.fromOffset(S(150), S(26) * #opts + S(6))
    end
    buildOptions(options)
    handle.Row = row
    function handle.SetOptions(opts) buildOptions(opts) end
    SafeClick(btn, function()
        if openDropdown == list then CloseDropdown() return end
        CloseDropdown()
        list.Position = UDim2.fromOffset(btn.AbsolutePosition.X, btn.AbsolutePosition.Y + btn.AbsoluteSize.Y + S(4))
        list.Visible = true; openDropdown = list
    end)
    return handle
end

local AP = {
    Panel = Color3.fromRGB(255, 255, 255), PanelT = 0.45, Comp = Color3.fromRGB(255, 255, 255), CompT = 0.35,
    Text = Color3.fromRGB(70, 70, 70), Dim = Color3.fromRGB(110, 110, 110), Accent = Color3.fromRGB(215, 60, 60),
    Stroke = Color3.fromRGB(160, 160, 160), BorderRainbow = true, Border = Color3.fromRGB(215, 60, 60),
}
Lib.AP = AP

local ORIG = { Comp = Color3.fromRGB(255, 255, 255), Text = Color3.fromRGB(70, 70, 70), Dim = Color3.fromRGB(110, 110, 110), Accent = Color3.fromRGB(215, 60, 60) }
local Themes = {
    ["經典"] = { Panel = Color3.fromRGB(255,255,255), PanelT = 0.45, Comp = Color3.fromRGB(255,255,255), CompT = 0.35, Text = Color3.fromRGB(70,70,70), Dim = Color3.fromRGB(110,110,110), Accent = Color3.fromRGB(215,60,60), Stroke = Color3.fromRGB(160,160,160), BorderRainbow = true, Border = Color3.fromRGB(215,60,60) },
    ["深藍"] = { Panel = Color3.fromRGB(16,24,45), PanelT = 0.1, Comp = Color3.fromRGB(45,70,120), CompT = 0.15, Text = Color3.fromRGB(215,230,255), Dim = Color3.fromRGB(130,160,200), Accent = Color3.fromRGB(70,150,255), Stroke = Color3.fromRGB(90,120,170), BorderRainbow = false, Border = Color3.fromRGB(70,150,255) },
    ["賽博"] = { Panel = Color3.fromRGB(12,12,18), PanelT = 0.1, Comp = Color3.fromRGB(30,40,45), CompT = 0.15, Text = Color3.fromRGB(200,255,240), Dim = Color3.fromRGB(110,160,150), Accent = Color3.fromRGB(0,255,200), Stroke = Color3.fromRGB(0,180,150), BorderRainbow = false, Border = Color3.fromRGB(0,255,200) },
    ["吸血"] = { Panel = Color3.fromRGB(28,12,18), PanelT = 0.1, Comp = Color3.fromRGB(60,25,35), CompT = 0.15, Text = Color3.fromRGB(255,225,230), Dim = Color3.fromRGB(190,120,130), Accent = Color3.fromRGB(230,45,70), Stroke = Color3.fromRGB(180,60,80), BorderRainbow = false, Border = Color3.fromRGB(230,45,70) },
}

local function TagObj(d)
    if d:GetAttribute("role") then return end
    if d:IsA("UIStroke") then d:SetAttribute("role", d:FindFirstChildOfClass("UIGradient") and "rainbow" or "stroke") return end
    local isGui = d:IsA("Frame") or d:IsA("TextButton") or d:IsA("TextBox") or d:IsA("TextLabel")
    if not isGui then return end
    local bg = d.BackgroundColor3
    local skipBg = bg == Color3.fromRGB(20, 20, 20) or bg == Color3.fromRGB(40, 40, 40)
    if d:IsA("Frame") and d:FindFirstChildOfClass("UIScale") then d:SetAttribute("role", "panel") return end
    if not skipBg then
        if d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox") then
            local tc = d.TextColor3
            if tc == ORIG.Text then d:SetAttribute("role", "text")
            elseif tc == ORIG.Dim then d:SetAttribute("role", "dim")
            elseif tc == ORIG.Accent then d:SetAttribute("role", "accenttext") end
        end
        local bt = d.BackgroundTransparency
        if bt >= 0.05 and bt <= 0.5 then d:SetAttribute("role", "comp")
        elseif bg == ORIG.Accent and d:IsA("Frame") and d.AbsoluteSize.X > S(40) then d:SetAttribute("role", "accentbg") end
    end
end

local function ApplyObj(d)
    local role = d:GetAttribute("role")
    if role == "panel" then d.BackgroundColor3 = AP.Panel; d.BackgroundTransparency = AP.PanelT
    elseif role == "comp" then d.BackgroundColor3 = AP.Comp; d.BackgroundTransparency = AP.CompT; if d:IsA("TextButton") or d:IsA("TextBox") then d.TextColor3 = AP.Text end
    elseif role == "text" then d.TextColor3 = AP.Text
    elseif role == "dim" then d.TextColor3 = AP.Dim
    elseif role == "accenttext" then d.TextColor3 = AP.Accent
    elseif role == "accentbg" then d.BackgroundColor3 = AP.Accent
    elseif role == "stroke" then d.Color = AP.Stroke
    elseif role == "rainbow" then local g = d:FindFirstChildOfClass("UIGradient"); if g then if AP.BorderRainbow then g.Color = RAINBOW_SEQ else g.Color = ColorSequence.new(AP.Border, AP.Border) end end end
end

local function ApplyAll()
    pcall(function()
        for _, p in ipairs(panelList) do p.BackgroundColor3 = AP.Panel; p.BackgroundTransparency = AP.PanelT end
    end)
    if ScreenGui then
        for _, d in ipairs(ScreenGui:GetDescendants()) do TagObj(d); ApplyObj(d) end
    end
end

local apDirty = false
RunService.Heartbeat:Connect(function() if apDirty then apDirty = false; ApplyAll() end end)
local function QueueApply() apDirty = true end

local function ApplyTheme(name)
    local t = Themes[name]
    if not t then return end
    for k, v in pairs(t) do AP[k] = v end
    COL.PillGray = AP.Panel; COL.TextDark = AP.Text; COL.TextDim = AP.Dim; COL.Red = AP.Accent
    QueueApply()
    Toast("主題: " .. name)
end

local function SetTargetColor(target, col)
    if target == "UI底" then AP.Panel = col; AP.PanelT = 0.1
    elseif target == "組件" then AP.Comp = col; AP.CompT = 0.15
    elseif target == "主文字" then AP.Text = col; COL.TextDark = col
    elseif target == "暗文字" then AP.Dim = col; COL.TextDim = col
    elseif target == "強調色" then AP.Accent = col; COL.Red = col
    elseif target == "邊框" then AP.Border = col; AP.BorderRainbow = false end
    QueueApply()
end

local function ApplyFont(fontName)
    local f = Enum.Font[fontName]
    if not f then return end
    if ScreenGui then
        for _, d in ipairs(ScreenGui:GetDescendants()) do
            if d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox") then d.Font = f end
        end
    end
    Toast("字體: " .. fontName)
end

local pickerTarget = "UI底"
local pickerInfoLabel = nil
local function MakeColorPicker(parent)
    local holder = Create("Frame", {
        Size = UDim2.new(1, -S(8), 0, S(88)), BackgroundColor3 = Color3.fromRGB(40, 40, 40),
        BackgroundTransparency = 0.2, Parent = parent,
    })
    AddCorner(holder, S(6))
    local preview = Create("Frame", {
        Size = UDim2.fromOffset(S(30), S(30)), Position = UDim2.new(1, -S(38), S(8)),
        BackgroundColor3 = Color3.fromRGB(255, 0, 0), Parent = holder,
    })
    AddCorner(preview, S(6))
    Create("UIStroke", { Thickness = 1, Color = Color3.new(1, 1, 1), Transparency = 0.4 }, preview)
    local h, s, v = 0, 1, 1
    local dragId = nil
    local function makeBar(title, yPos)
        local lab = Create("TextLabel", {
            Size = UDim2.fromOffset(S(44), S(16)), Position = UDim2.fromOffset(S(8), yPos + S(1)), BackgroundTransparency = 1,
            Text = T(title), TextColor3 = Color3.new(1, 1, 1), TextSize = TS(11), Font = Enum.Font.GothamMedium,
            TextXAlignment = Enum.TextXAlignment.Left, Parent = holder,
        })
        RegisterLang(lab, title)
        local track = Create("Frame", {
            Size = UDim2.new(1, -S(100), 0, S(16)), Position = UDim2.fromOffset(S(56), yPos),
            BackgroundColor3 = Color3.new(1, 1, 1), Parent = holder,
        })
        AddCorner(track, S(4))
        local grad = Create("UIGradient", { Color = ColorSequence.new(Color3.new(0, 0, 0), Color3.new(1, 1, 1)) }, track)
        local knob = Create("Frame", {
            Size = UDim2.fromOffset(S(6), S(22)), BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 3, Parent = track,
        })
        AddCorner(knob, S(3))
        Create("UIStroke", { Thickness = 1, Color = Color3.new(0, 0, 0), Transparency = 0.4 }, knob)
        return { track = track, grad = grad, knob = knob }
    end
    local barH = makeBar("色相", S(8))
    local barS = makeBar("飽和", S(32))
    local barV = makeBar("明度", S(56))
    barH.grad.Color = RAINBOW_SEQ
    local function render()
        local hueCol = Color3.fromHSV(h, 1, 1)
        barS.grad.Color = ColorSequence.new(Color3.new(1, 1, 1), hueCol)
        barV.grad.Color = ColorSequence.new(Color3.new(0, 0, 0), hueCol)
        preview.BackgroundColor3 = Color3.fromHSV(h, s, v)
        barH.knob.Position = UDim2.new(h, -S(3), 0.5, -S(11))
        barS.knob.Position = UDim2.new(s, -S(3), 0.5, -S(11))
        barV.knob.Position = UDim2.new(v, -S(3), 0.5, -S(11))
    end
    local function fire()
        local col = Color3.fromHSV(h, s, v)
        SetTargetColor(pickerTarget, col)
        if pickerInfoLabel then
            pickerInfoLabel.Text = T("目標: ") .. T(pickerTarget) .. (" RGB(%d,%d,%d)"):format(math.floor(col.R * 255), math.floor(col.G * 255), math.floor(col.B * 255))
        end
    end
    local function bindBar(bar, id)
        bar.track.InputBegan:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
                dragId = id
                local r = math.clamp((inp.Position.X - bar.track.AbsolutePosition.X) / math.max(1, bar.track.AbsoluteSize.X), 0, 1)
                if id == "h" then h = r elseif id == "s" then s = r else v = r end
                render(); fire()
            end
        end)
    end
    bindBar(barH, "h"); bindBar(barS, "s"); bindBar(barV, "v")
    UserInputService.InputChanged:Connect(function(inp)
        if dragId and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
            local bar = (dragId == "h") and barH or (dragId == "s") and barS or barV
            local r = math.clamp((inp.Position.X - bar.track.AbsolutePosition.X) / math.max(1, bar.track.AbsoluteSize.X), 0, 1)
            if dragId == "h" then h = r elseif dragId == "s" then s = r else v = r end
            render(); fire()
        end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then dragId = nil end
    end)
    render()
    return holder
end

local function MakeInlineAlphaSlider(flow)
    local row = flow.Add(S(210), S(20))
    local lab = Create("TextLabel", {
        Size = UDim2.fromOffset(S(64), S(16)), Position = UDim2.fromOffset(0, 0.5, -S(8)), BackgroundTransparency = 1,
        Text = T("UI透明度"), TextColor3 = COL.TextDim, TextSize = TS(11), Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = row,
    })
    RegisterLang(lab, "UI透明度")
    local track = Create("Frame", {
        Size = UDim2.fromOffset(S(136), S(8)), Position = UDim2.fromOffset(S(68), 0.5, -S(4)),
        BackgroundColor3 = Color3.fromRGB(120, 120, 120), BackgroundTransparency = 0.3, Parent = row,
    })
    AddCorner(track, S(4))
    local fill = Create("Frame", { BackgroundColor3 = AP.Accent, Parent = track })
    AddCorner(fill, S(4))
    local knob = Create("Frame", {
        Size = UDim2.fromOffset(S(12), S(12)), BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 2, Parent = track,
    })
    AddCorner(knob, S(6))
    local drag = false
    local function setR(r, fire)
        r = math.clamp(r, 0, 1)
        fill.Size = UDim2.new(r, 0, 1, 0)
        knob.Position = UDim2.new(r, -S(6), 0.5, -S(6))
        if fire then AP.PanelT = 0.9 * (1 - r); QueueApply() end
    end
    setR(1 - (AP.PanelT / 0.9), false)
    track.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            drag = true; setR((inp.Position.X - track.AbsolutePosition.X) / math.max(1, track.AbsoluteSize.X), true)
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if drag and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
            setR((inp.Position.X - track.AbsolutePosition.X) / math.max(1, track.AbsoluteSize.X), true)
        end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then drag = false end
    end)
end

local pages = {}
Lib.pages = pages
local EASE = TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local currentPage = nil

local function SlideToPage(newPage, dirX, dirY)
    if currentPage == newPage then return end
    local old = currentPage; currentPage = newPage
    local cw, ch = newPage.Parent.AbsoluteSize.X, newPage.Parent.AbsoluteSize.Y
    newPage.Position = UDim2.fromOffset(dirX * cw, dirY * ch); newPage.Visible = true
    TweenService:Create(newPage, EASE, { Position = UDim2.fromOffset(0, 0) }):Play()
    if old then
        TweenService:Create(old, EASE, { Position = UDim2.fromOffset(-dirX * cw, -dirY * ch) }):Play()
        local oldRef = old
        task.delay(0.32, function() oldRef.Visible = false; oldRef.Position = UDim2.fromOffset(0, 0) end)
    end
end

local AvatarWorld = nil
Lib.AvatarWorld = AvatarWorld

local function LoadAvatar()
    if not AvatarWorld then return end
    for _, c in ipairs(AvatarWorld:GetChildren()) do if c:IsA("Model") then c:Destroy() end end
    local ok3d = pcall(function()
        local desc = Players:GetHumanoidDescriptionFromUserId(LocalPlayer.UserId)
        local model = Players:CreateHumanoidModelFromDescription(desc, Enum.HumanoidRigType.R15)
        if not model then error("model nil") end
        model.Parent = AvatarWorld
        local root = model:WaitForChild("HumanoidRootPart", 3)
        if not root then error("no root") end
        root.Anchored = true
        if model.PrimaryPart then model:PivotTo(CFrame.new(0, 0, 0) * CFrame.Angles(0, math.rad(180), 0)) end
    end)
end
Lib.LoadAvatar = LoadAvatar

local SetUIVisible
local function SetLanguage(lang)
    currentLang = lang
    ApplyLanguage()
    Toast(lang == "en" and "Language: English" or "語言: 中文")
end
Lib.SetLanguage = SetLanguage

function Lib:Initialize(opts)
    if self.Initialized then return self end
    opts = opts or {}

    ScreenGui = Create("ScreenGui", {
        Name = "PremiumUI_SZE" .. math.random(10000, 99999), ResetOnSpawn = false,
        IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    })
    ScreenGui.Parent = (okCore and CoreGuiService) or LocalPlayer:WaitForChild("PlayerGui")
    self.ScreenGui = ScreenGui

    ToastHolder = Create("Frame", {
        Size = UDim2.fromOffset(S(300), S(160)), Position = UDim2.fromOffset((vpSize.X - S(300)) / 2, S(12)),
        BackgroundTransparency = 1, Parent = ScreenGui, ZIndex = 60,
    })
    Create("UIListLayout", { Padding = UDim.new(0, S(6)), HorizontalAlignment = Enum.HorizontalAlignment.Center }, ToastHolder)

    RunService.RenderStepped:Connect(function()
        local rot = ((tick() - rainbowT0) * 24) % 360
        for _, g in ipairs(rainbowGrads) do g.Rotation = rot end
    end)

    local SideOuter = Create("Frame", { Size = UDim2.fromOffset(sideW, sideH), Position = UDim2.fromOffset(startX, sideY), Visible = false, Parent = ScreenGui })
    AddGlass(SideOuter); AddCorner(SideOuter, S(12)); AddRainbowStroke(SideOuter, math.max(1, S(1.5)), true); Create("UIScale", { Scale = 1 }, SideOuter)
    local SideIndicator = Create("Frame", { Size = UDim2.fromOffset(sideW - sidePad * 2, sideBtnH), Position = UDim2.fromOffset(sidePad, S(28) + sidePad), BackgroundColor3 = COL.PillGray, BackgroundTransparency = 0.1, Parent = SideOuter, ZIndex = 1 })
    AddCorner(SideIndicator, S(8))
    local SideList = Create("Frame", { Size = UDim2.new(1, 0, 1, -S(28)), Position = UDim2.fromOffset(0, S(28)), BackgroundTransparency = 1, Parent = SideOuter, ZIndex = 2 })
    Create("UIListLayout", { FillDirection = Enum.FillDirection.Vertical, Padding = UDim.new(0, sideGap) }, SideList)
    Create("UIPadding", { PaddingTop = UDim.new(0, sidePad), PaddingLeft = UDim.new(0, sidePad), PaddingRight = UDim.new(0, sidePad) }, SideList)

    local MainPanel = Create("Frame", { Size = UDim2.fromOffset(mainW, mainH), Position = UDim2.fromOffset(startX + sideW + gap, mainY), Visible = false, Parent = ScreenGui })
    AddGlass(MainPanel); AddCorner(MainPanel, S(12)); AddRainbowStroke(MainPanel, math.max(1, S(1.5)), true); Create("UIScale", { Scale = 1 }, MainPanel)
    local CloseBtn = Create("TextButton", { Size = UDim2.fromOffset(S(26), S(26)), Position = UDim2.new(1, -S(32), 0, S(2)), BackgroundTransparency = 1, Text = "X", TextColor3 = COL.Red, TextSize = TS(15), Font = Enum.Font.GothamBold, AutoButtonColor = false, Parent = MainPanel, ZIndex = 5 })
    local TopOuter = Create("Frame", { Size = UDim2.new(1, -S(60), 0, S(44)), Position = UDim2.fromOffset(S(10), S(30)), BackgroundTransparency = 1, Parent = MainPanel })
    local TopIndicator = Create("Frame", { Size = UDim2.new(0.25, -S(10), 0, S(32)), Position = UDim2.new(0, S(5), 0, S(6)), BackgroundColor3 = COL.Red, Parent = TopOuter, ZIndex = 1 })
    AddCorner(TopIndicator, S(8))
    local TopList = Create("Frame", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Parent = TopOuter, ZIndex = 2 })
    Create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal }, TopList)
    local Divider = AddRainbowBar(MainPanel); Divider.Position = UDim2.fromOffset(S(10), S(74)); Divider.Size = UDim2.new(1, -S(20), 0, math.max(1, S(2)))
    local Clip = Create("Frame", { Size = UDim2.new(1, -S(20), 1, -S(86)), Position = UDim2.fromOffset(S(10), S(78)), BackgroundTransparency = 1, ClipsDescendants = true, Parent = MainPanel })

    for m = 1, 4 do
        pages[m] = {}
        for j = 1, 4 do
            local page = Create("Frame", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Visible = (m == 1 and j == 1), Parent = Clip })
            local scroll = Create("ScrollingFrame", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = math.max(2, S(3)), ScrollBarImageColor3 = Color3.fromRGB(120, 120, 120), Parent = page })
            Create("UIListLayout", { FillDirection = Enum.FillDirection.Vertical, Padding = UDim.new(0, S(8)) }, scroll)
            Create("UIPadding", { PaddingTop = UDim.new(0, S(10)), PaddingLeft = UDim.new(0, S(6)), PaddingRight = UDim.new(0, S(6)), PaddingBottom = UDim.new(0, S(10)) }, scroll)
            pages[m][j] = page
        end
    end
    currentPage = pages[1][1]

    local RightPanel = Create("Frame", { Size = UDim2.fromOffset(rightW, rightH), Position = UDim2.fromOffset(startX + sideW + gap + mainW + gap, rightY), Visible = false, Parent = ScreenGui })
    AddGlass(RightPanel); AddCorner(RightPanel, S(12)); AddRainbowStroke(RightPanel, math.max(1, S(1.5)), true); Create("UIScale", { Scale = 1 }, RightPanel)
    local AvatarViewport = Create("ViewportFrame", { Size = UDim2.new(1, -S(10), 1, -S(34)), Position = UDim2.fromOffset(S(5), S(28)), BackgroundTransparency = 1, ClipsDescendants = true, Parent = RightPanel })
    AddCorner(AvatarViewport, S(8))
    AvatarViewport.LightColor = Color3.fromRGB(255, 255, 255); AvatarViewport.LightDirection = Vector3.new(0, -1, -0.4); AvatarViewport.Ambient = Color3.fromRGB(140, 140, 140)
    AvatarWorld = Instance.new("WorldModel"); AvatarWorld.Parent = AvatarViewport
    self.AvatarWorld = AvatarWorld
    local AvatarCamera = Instance.new("Camera"); AvatarCamera.FieldOfView = 40; AvatarCamera.Parent = AvatarViewport; AvatarViewport.CurrentCamera = AvatarCamera; AvatarCamera.CFrame = CFrame.new(Vector3.new(0, -0.2, 11), Vector3.new(0, -0.2, 0))

    panelList = { SideOuter, MainPanel, RightPanel }

    SetUIVisible = function(v)
        if v == UIVisible then return end
        UIVisible = v; self.UIVisible = v
        if v then
            for _, p in ipairs(panelList) do p.Visible = true; local sc = p:FindFirstChildOfClass("UIScale"); if sc then sc.Scale = 0.85; TweenService:Create(sc, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play() end end
        else
            CloseDropdown()
            for _, p in ipairs(panelList) do local sc = p:FindFirstChildOfClass("UIScale"); if sc then TweenService:Create(sc, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Scale = 0.85 }):Play() end end
            task.delay(0.2, function() if not UIVisible then for _, p in ipairs(panelList) do p.Visible = false end end end)
        end
    end

    SafeClick(CloseBtn, function() SetUIVisible(false) end)
    MakeDragHandle(MainPanel, UDim2.new(1, -S(40), 0, S(28)), UDim2.fromOffset(S(4), 0))
    MakeDragHandle(SideOuter, UDim2.new(1, 0, 0, S(26)), UDim2.fromOffset(0, 0))
    MakeDragHandle(RightPanel, UDim2.new(1, 0, 0, S(26)), UDim2.fromOffset(0, 0))

    local sideButtons, topButtons = {}, {}
    local currentMain, currentSub = 1, 1
    local function RefreshTopNames(m) for j, b in ipairs(topButtons) do local name = subNameSets[m][j]; b.Text = T(name); if langEntryByObj[b] then langEntryByObj[b].zh = name end end end
    local function SelectMain(i)
        if i == currentMain then return end
        local dir = i > currentMain and 1 or -1; currentMain = i
        for idx, b in ipairs(sideButtons) do b.TextColor3 = (idx == i) and COL.White or COL.TextDark end
        TweenService:Create(SideIndicator, EASE, { Position = UDim2.fromOffset(sidePad, S(28) + sidePad + (i - 1) * (sideBtnH + sideGap)) }):Play()
        RefreshTopNames(i); SlideToPage(pages[i][currentSub], 0, dir)
    end
    local function SelectSub(j)
        if j == currentSub then return end
        local dir = j > currentSub and 1 or -1; currentSub = j
        for idx, b in ipairs(topButtons) do b.TextColor3 = (idx == j) and COL.White or COL.TextDark end
        TweenService:Create(TopIndicator, EASE, { Position = UDim2.new((j - 1) * 0.25, S(5), 0, S(6)) }):Play()
        SlideToPage(pages[currentMain][j], dir, 0)
    end

    -- ★ 关键修复：暴露局部变量给 Bridge 协议使用
    self._mainNames = mainNames
    self._subNameSets = subNameSets
    self._sideButtons = sideButtons
    self._topButtons = topButtons
    self._refreshTopNames = RefreshTopNames
    self._getCurrentMain = function() return currentMain end
    self._selectMain = SelectMain
    self._selectSub = SelectSub

    for i, name in ipairs(mainNames) do
        local b = Create("TextButton", { Size = UDim2.new(1, 0, 0, sideBtnH), BackgroundTransparency = 1, Text = T(name), TextColor3 = (i == 1) and COL.White or COL.TextDark, Font = Enum.Font.GothamMedium, TextSize = TS(14), AutoButtonColor = false, Parent = SideList })
        sideButtons[i] = b; SafeClick(b, function() SelectMain(i) end); RegisterLang(b, name)
    end
    for j, name in ipairs(subNameSets[1]) do
        local b = Create("TextButton", { Size = UDim2.new(0.25, 0, 1, 0), BackgroundTransparency = 1, Text = T(name), TextColor3 = (j == 1) and COL.White or COL.TextDark, Font = Enum.Font.GothamBold, TextSize = TS(13), AutoButtonColor = false, Parent = TopList })
        topButtons[j] = b; SafeClick(b, function() SelectSub(j) end); RegisterLang(b, name)
    end

    local ballSize = S(56)
    local Ball = Create("TextButton", { Size = UDim2.fromOffset(ballSize, ballSize), Position = UDim2.fromOffset(S(14), (vpSize.Y - ballSize) / 2), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, Parent = ScreenGui })
    local BallRing = Create("Frame", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Parent = Ball }); AddCorner(BallRing, ballSize / 2)
    local ringStroke = Create("UIStroke", { Thickness = math.max(2, S(3)), Color = COL.White }, BallRing)
    local ringGrad = Create("UIGradient", { Rotation = 0, Color = RAINBOW_SEQ }, ringStroke); table.insert(rainbowGrads, ringGrad)
    local discOuter = Create("Frame", { Size = UDim2.fromOffset(ballSize * 0.76, ballSize * 0.76), Position = UDim2.new(0.5, -ballSize * 0.38, 0.5, -ballSize * 0.38), BackgroundColor3 = Color3.fromRGB(110, 220, 70), Parent = Ball }); AddCorner(discOuter, ballSize)
    local discMid = Create("Frame", { Size = UDim2.fromOffset(ballSize * 0.52, ballSize * 0.52), Position = UDim2.new(0.5, -ballSize * 0.26, 0.5, -ballSize * 0.26), BackgroundColor3 = Color3.fromRGB(200, 230, 60), Parent = Ball }); AddCorner(discMid, ballSize)
    local discCore = Create("Frame", { Size = UDim2.fromOffset(ballSize * 0.26, ballSize * 0.26), Position = UDim2.new(0.5, -ballSize * 0.13, 0.5, -ballSize * 0.13), BackgroundColor3 = Color3.fromRGB(240, 90, 40), Parent = Ball }); AddCorner(discCore, ballSize)
    local ballDrag, ballMoved = false, false; local bStart, bPos = nil, nil
    Ball.InputBegan:Connect(function(inp) if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then ballDrag, ballMoved = true, false; bStart = inp.Position; bPos = Ball.Position end end)
    Ball.InputChanged:Connect(function(inp)
        if ballDrag and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
            local d = inp.Position - bStart; if math.abs(d.X) + math.abs(d.Y) > 6 then ballMoved = true end
            if ballMoved then local nx = math.clamp(bPos.X.Offset + d.X, 0, vpSize.X - ballSize); local ny = math.clamp(bPos.Y.Offset + d.Y, 0, vpSize.Y - ballSize); Ball.Position = UDim2.fromOffset(nx, ny) end
        end
    end)
    Ball.InputEnded:Connect(function(inp) if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then ballDrag = false; if not ballMoved then SetUIVisible(not UIVisible) end end end)

    self.MakeText = MakeText
    self.MakeSection = MakeSection
    self.MakeButton = MakeButton
    self.MakeTextBox = MakeTextBox
    self.MakeToggle = MakeToggle
    self.MakeSlider = MakeSlider
    self.MakeDropdown = MakeDropdown
    self.MakeColorPicker = MakeColorPicker
    self.MakeInlineAlphaSlider = MakeInlineAlphaSlider
    self.ApplyTheme = ApplyTheme
    self.SetTargetColor = SetTargetColor
    self.ApplyFont = ApplyFont
    self.GetScroll = function(m, j) return pages[m][j]:FindFirstChildOfClass("ScrollingFrame") end

    self.Initialized = true
    return self
end

-------------------------------------------------
-- GameBridge Protocol V3 (Takeover) - 真实可用实现
-------------------------------------------------
local function FindPageIndices(category, sub)
    local mNames = Lib._mainNames or { "首頁設置", "繪制面板", "通用功能", "腳本中心" }
    local sSets = Lib._subNameSets or {
        { "公告相關", "其他相關", "配置相關", "界面相關" },
        { "透視相關", "方框相關", "骨骼相關", "距離相關" },
        { "移動相關", "角色相關", "世界相關", "實用相關" },
        { "自家腳本", "免卡腳本", "需卡密腳本", "通用管理員" },
    }
    for m, mn in ipairs(mNames) do
        if mn == category then
            for j, sn in ipairs(sSets[m] or {}) do
                if sn == sub then return m, j end
            end
            return m, nil
        end
    end
    return nil, nil
end

local BridgeMeta = {}
BridgeMeta.__index = BridgeMeta

function BridgeMeta:UsePageIndex(m, j, mode)
    local scroll = self.UI:GetScroll(m, j)
    if not scroll then return false, "page_not_ready" end
    if mode ~= "Append" then
        for _, c in ipairs(scroll:GetChildren()) do
            if not c:IsA("UIListLayout") and not c:IsA("UIPadding") then c:Destroy() end
        end
    end
    self.Host = scroll
    self.MainIndex = m
    self.SubIndex = j
    return true
end

function BridgeMeta:Focus()
    if self.MainIndex and self.UI._selectMain then
        self.UI._selectMain(self.MainIndex)
        self.UI._selectSub(self.SubIndex)
    end
end

function BridgeMeta:Grid()
    local g = self.UI.CreateGrid(self.Host)
    self.Host = g
    return g
end

function BridgeMeta:ClearPage()
    local scroll = self.UI:GetScroll(self.MainIndex, self.SubIndex)
    if scroll then
        for _, c in ipairs(scroll:GetChildren()) do
            if not c:IsA("UIListLayout") and not c:IsA("UIPadding") then c:Destroy() end
        end
    end
    self.Host = scroll
end

function BridgeMeta:Create(comp)
    if type(comp) ~= "table" then return nil, "component_invalid" end
    local kind = comp.Type or comp.type
    local host = comp.Host or self.Host
    local text = comp.Text or comp.text or ""
    local cb = comp.Callback or comp.callback or comp.OnClick or comp.OnChange
    if kind == "Label" or kind == "Text" then
        return self.UI.MakeText(host, text, comp.Color or self.UI.COL.TextDark, comp.Size)
    elseif kind == "Section" then
        return self.UI.MakeText(host, text, self.UI.COL.TextDim)
    elseif kind == "Button" then
        return self.UI.MakeButton(host, text, cb)
    elseif kind == "Toggle" then
        return self.UI.MakeToggle(host, text, comp.Default or false, cb, comp.Register)
    elseif kind == "Slider" then
        return self.UI.MakeSlider(host, text, comp.Min or 0, comp.Max or 100, comp.Default or comp.Min or 0, cb)
    elseif kind == "Dropdown" then
        local opts = comp.Options or {}
        return self.UI.MakeDropdown(host, text, opts, comp.Default or opts[1], cb)
    elseif kind == "TextBox" or kind == "Input" then
        return self.UI.MakeTextBox(host, comp.Placeholder or text, comp.Default or "")
    elseif kind == "Grid" then
        return self:Grid()
    end
    return nil, "component_unknown:" .. tostring(kind)
end

function BridgeMeta:Label(text, opts) opts = opts or {}; return self:Create({ Type = "Label", Text = text, Color = opts.Color, Size = opts.Size, Host = opts.Host }) end
function BridgeMeta:Section(text, opts) opts = opts or {}; return self:Create({ Type = "Section", Text = text, Host = opts.Host }) end
function BridgeMeta:Button(text, cb, opts) opts = opts or {}; return self:Create({ Type = "Button", Text = text, Callback = cb, Host = opts.Host }) end
function BridgeMeta:Toggle(text, default, cb, opts) opts = opts or {}; return self:Create({ Type = "Toggle", Text = text, Default = default, Callback = cb, Register = opts.Register, Host = opts.Host }) end
function BridgeMeta:Slider(text, min, max, default, cb, opts) opts = opts or {}; return self:Create({ Type = "Slider", Text = text, Min = min, Max = max, Default = default, Callback = cb, Host = opts.Host }) end
function BridgeMeta:Dropdown(text, options, default, cb, opts) opts = opts or {}; return self:Create({ Type = "Dropdown", Text = text, Options = options, Default = default, Callback = cb, Host = opts.Host }) end
function BridgeMeta:TextBox(placeholder, default, opts) opts = opts or {}; return self:Create({ Type = "TextBox", Placeholder = placeholder, Default = default, Host = opts.Host }) end

function Lib:RenameMain(i, newName)
    if Lib._sideButtons and Lib._sideButtons[i] then
        Lib._sideButtons[i].Text = Lib.T(newName)
        return true
    end
    return false
end

function Lib:RenameSub(m, j, newName)
    if Lib._subNameSets and Lib._subNameSets[m] and Lib._subNameSets[m][j] then
        Lib._subNameSets[m][j] = newName
        if Lib._refreshTopNames and Lib._getCurrentMain and Lib._getCurrentMain() == m then
            Lib._refreshTopNames(m)
        end
        return true
    end
    return false
end

function Lib:RequestGameBridge(payload)
    payload = payload or {}
    if payload.Brand ~= self.Brand then return false, "brand_mismatch" end
    if payload.Protocol and payload.Protocol ~= self.BridgeProtocol then return false, "protocol_mismatch" end
    if not self.Initialized then return false, "ui_not_initialized" end

    local category = payload.Category or "腳本中心"
    local sub = payload.Sub or "自家腳本"
    local m, j = FindPageIndices(category, sub)
    if not m or not j then return false, "page_not_found" end
    local scroll = self:GetScroll(m, j)
    if not scroll then return false, "page_not_ready" end

    if payload.Mode ~= "Append" then
        for _, c in ipairs(scroll:GetChildren()) do
            if not c:IsA("UIListLayout") and not c:IsA("UIPadding") then c:Destroy() end
        end
    end

    local bridge = setmetatable({
        UI = self, Name = payload.Name or "GameScript", Active = true,
        Protocol = self.BridgeProtocol, Host = scroll, MainIndex = m, SubIndex = j,
    }, BridgeMeta)

    if payload.Focus then bridge:Focus() end
    return true, bridge
end

-------------------------------------------------
-- Host Publish (秒刷发布)
-------------------------------------------------
local function PublishHost()
    pcall(function() shared.PremiumUI = Lib end)
    pcall(function() _G.PremiumUI = Lib end)
    pcall(function() if getgenv then getgenv().PremiumUI = Lib end end)
end
PublishHost()
print(">>> [PremiumUI] Host published: shared/_G/getgenv PremiumUI ready, BridgeProtocol=2")

return Lib
