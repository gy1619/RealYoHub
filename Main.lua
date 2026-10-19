-- Main Script.lua (loader v5: 空格修复 + Luau兼容 + 缺缩放块自动补插)
local LIB_URLS = {
    "https://raw.githubusercontent.com/gy1619/RealYoHub/refs/heads/main/Astool.lua?t=" .. tostring(os.time()),
    "https://raw.githubusercontent.com/gy1619/RealYoHub/main/Astool.lua?t=" .. tostring(os.time()),
}

-- ========== 1. Luau 方言兼容过滤器 ==========
local function FixLuauCompat(src)
    local count = 0
    src = src:gsub("%(([%w_%.]+)%s*~%s*([%w_%.]+)%s*%)", function(a, b)
        count = count + 1
        return "bit32.bxor(" .. a .. ", " .. b .. ")"
    end)
    src = src:gsub("%(([%w_%.]+)%s*<<%s*([%w_%.]+)%s*%)", function(a, b)
        count = count + 1
        return "bit32.lshift(" .. a .. ", " .. b .. ")"
    end)
    src = src:gsub("%(([%w_%.]+)%s*>>%s*([%w_%.]+)%s*%)", function(a, b)
        count = count + 1
        return "bit32.rshift(" .. a .. ", " .. b .. ")"
    end)
    if count > 0 then
        warn(("[RealYoUI] Luau Compat Filter: converted %d bitwise ops"):format(count))
    end
    return src
end

-- ========== 2. 缺失缩放块自动补插 (S/TS/vpSize/UI_SCALE) ==========
local SCALE_BLOCK = [[
local camNow = workspace.CurrentCamera
local vpSize = (camNow and camNow.ViewportSize) or Vector2.new(1280, 720)
if vpSize.X < 100 then vpSize = Vector2.new(1280, 720) end
local UI_SCALE = math.min(vpSize.X / 1280, vpSize.Y / 720)
if UI_SCALE <= 0 then UI_SCALE = 1 end
local function S(v) return v * UI_SCALE end
local function TS(v) return math.max(10, math.floor(v * UI_SCALE)) end
Lib.S = S
Lib.TS = TS
]]

local function FixMissingScale(src)
    if src:find("local%s+UI_SCALE") or src:find("local%s+function%s+S%(v%)") then
        return src
    end
    local out, n = src:gsub("(local%s+taskWait%s*=[^\n]*\n)", "%1" .. SCALE_BLOCK, 1)
    if n == 0 then
        out, n = src:gsub("(local%s+LocalPlayer%s*=%s*Players%.LocalPlayer\n)", "%1" .. SCALE_BLOCK, 1)
    end
    if n > 0 then
        warn("[RealYoUI] Scale block missing -> auto-injected (S/TS/vpSize)")
    end
    return out
end

-- ========== 3. 空格/断词修复引擎 ==========
local KW = {}
for _, w in ipairs({
    "and","break","do","else","elseif","end","false","for","function",
    "if","in","local","nil","not","or","repeat","return","then","true",
    "until","while","continue",
}) do KW[w] = true end

local function TrimStr(s) return (s:match("^%s*(.-)%s*$")) end

local function Tokenize(src)
    local toks = {}
    local i, n = 1, #src
    while i <= n do
        local ws = src:match("^%s+", i)
        if ws then
            toks[#toks+1] = { t = "ws", v = ws }; i = i + #ws
        elseif src:sub(i, i+1) == "--" then
            local nl = src:find("\n", i) or (n + 1)
            toks[#toks+1] = { t = "comment", v = src:sub(i, nl - 1) }; i = nl
        elseif src:sub(i, i) == '"' or src:sub(i, i) == "'" then
            local q = src:sub(i, i); local j = i + 1; local buf = {}
            while j <= n do
                local ch = src:sub(j, j)
                if ch == "\\" and j + 1 <= n then
                    buf[#buf+1] = src:sub(j, j+1); j = j + 2
                elseif ch == q then j = j + 1; break
                elseif ch == "\n" then break
                else buf[#buf+1] = ch; j = j + 1 end
            end
            toks[#toks+1] = { t = "string", v = q .. TrimStr(table.concat(buf)) .. q }
            i = j
        elseif src:match("^0[xX][%da-fA-F]+", i) then
            local s = src:match("^0[xX][%da-fA-F]+", i)
            toks[#toks+1] = { t = "num", v = s }; i = i + #s
        elseif src:sub(i, i):match("%d") and src:match("^%d+%.?%d*", i) then
            local s = src:match("^%d+%.?%d*", i)
            toks[#toks+1] = { t = "num", v = s }; i = i + #s
        elseif src:match("^%.%d+", i) then
            local s = src:match("^%.%d+", i)
            toks[#toks+1] = { t = "num", v = s }; i = i + #s
        elseif src:match("^[%a_][%w_]*", i) then
            local s = src:match("^[%a_][%w_]*", i)
            toks[#toks+1] = { t = KW[s] and "kw" or "ident", v = s }; i = i + #s
        else
            toks[#toks+1] = { t = "op", v = src:sub(i, i) }; i = i + 1
        end
    end
    return toks
end

local MERGE_OPS = { ["="] = true, ["~"] = true, ["<"] = true, [">"] = true, ["."] = true, [".."] = true }

local function RepairSource(src)
    local toks = Tokenize(src)
    local out = {}
    local prev, prevSep = nil, nil
    for _, tk in ipairs(toks) do
        if tk.t == "ws" then
            prevSep = (prevSep or "") .. tk.v
        elseif tk.t == "comment" then
            if prevSep then out[#out+1] = { t = "ws", v = prevSep }; prevSep = nil end
            out[#out+1] = tk
            prev = { t = "comment", v = "" }
        else
            local merged = false
            if prev and prevSep and not prevSep:find("\n") then
                if prev.t == "ident" and tk.t == "ident" and not KW[prev.v] and not KW[tk.v] then
                    prev.v = prev.v .. tk.v
                    if KW[prev.v] then prev.t = "kw" end
                    merged = true
                elseif prev.t == "op" and tk.t == "op" and MERGE_OPS[prev.v] and (tk.v == "=" or tk.v == ".") then
                    prev.v = prev.v .. tk.v
                    merged = true
                end
            end
            if not merged then
                if prevSep then out[#out+1] = { t = "ws", v = prevSep }; prevSep = nil end
                out[#out+1] = tk
                prev = tk
            else
                prevSep = nil
            end
        end
    end
    if prevSep then out[#out+1] = { t = "ws", v = prevSep } end
    local parts = {}
    for _, t in ipairs(out) do parts[#parts+1] = t.v end
    return table.concat(parts)
end
-- ========== 修复引擎结束 ==========

-- ========== 4. 核心加载逻辑 ==========
local function PickRealYoUI()
    local candidates = {}
    if shared and shared.RealYoUI then table.insert(candidates, shared.RealYoUI) end
    local genvOK, g = pcall(function() if getgenv then return getgenv() end return nil end)
    if genvOK and g and g.RealYoUI then table.insert(candidates, g.RealYoUI) end
    if _G and _G.RealYoUI then table.insert(candidates, _G.RealYoUI) end
    for _, ui in ipairs(candidates) do
        if type(ui) == "table" and ui.IsRealYoUI == true and type(ui.Initialize) == "function" then
            return ui
        end
    end
    return nil
end

local function HttpGetText(url)
    local ok, body = pcall(function() return game:HttpGet(url) end)
    if ok and type(body) == "string" and body ~= "" then return body end
    local req = request or http_request or (syn and syn.request)
    if type(req) == "function" then
        local res = req({ Url = url, Method = "GET" })
        if type(res) == "table" and type(res.Body) == "string" and res.Body ~= "" then return res.Body end
    end
    error(body or "HttpGet failed")
end

local function LoadFromSource(source)
    source = FixMissingScale(source)
    local fixed = FixLuauCompat(source)
    local fn, err = loadstring(fixed)
    local repaired = false
    if type(fn) ~= "function" then
        fixed = FixMissingScale(FixLuauCompat(RepairSource(fixed)))
        local fn2, err2 = loadstring(fixed)
        if type(fn2) ~= "function" then
            return nil, ("raw: %s | repaired: %s"):format(tostring(err), tostring(err2))
        end
        fn = fn2
        repaired = true
    end
    local ok, ret = pcall(fn)
    if not ok then
        local errLine = tonumber(tostring(ret):match(":(%d+):"))
        warn("[RealYoUI] runtime error inside library, repaired=" .. tostring(repaired))
        if errLine then
            local lines = {}
            for l in (fixed .. "\n"):gmatch("([^\n]*)\n") do lines[#lines+1] = l end
            warn(("----- library source around line %d -----"):format(errLine))
            for i = math.max(1, errLine - 4), math.min(#lines, errLine + 2) do
                warn(("%4d| %s"):format(i, lines[i] or ""))
            end
            warn("------------------------------------------")
        end
        pcall(function() if setclipboard then setclipboard(fixed) end end)
        warn("[RealYoUI] full repaired source -> clipboard")
        return nil, "runtime: " .. tostring(ret)
    end
    if repaired then
        pcall(function() if setclipboard then setclipboard(fixed) end end)
        warn("[RealYoUI] remote source was corrupted; auto-repaired (fixed copy -> clipboard)")
    end
    return ret, nil
end

local UI = PickRealYoUI()
if not UI then
    local lastError = "no published RealYoUI host"
    for _, url in ipairs(LIB_URLS) do
        local ok, source = pcall(HttpGetText, url)
        if not ok then
            lastError = tostring(source)
        elseif source:match("^%s*404") or source:find("<html", 1, true) or source:find("<!DOCTYPE", 1, true) then
            lastError = "URL returned 404/html, not Lua"
        else
            local ret, err = LoadFromSource(source)
            UI = PickRealYoUI()
            if not UI and type(ret) == "table" then UI = ret end
            if UI then break end
            lastError = err or "script executed but UI table not found"
        end
    end
    if not UI or UI.IsRealYoUI ~= true or type(UI.Initialize) ~= "function" then
        warn("[RealYoUI] UI library load failed. Detail: " .. tostring(lastError))
        return
    end
end

-- ✅ 核心：由宿主定义 Tab 结构和优先级
UI:Initialize({
    Title = "RealYo UI",
    Subtitle = "SZE",
    Tabs = {
        {Name = "Info", Priority = 100},
        {Name = "ESP", Priority = 80},
        {Name = "FE", Priority = 60},
        {Name = "ScriptHub", Priority = 10}
    },
})

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local TeleportService = game:GetService("TeleportService")
local LocalPlayer = Players.LocalPlayer
local taskWait = (task and task.wait) or function() return wait() end

local S = UI.S; local TS = UI.TS; local Create = UI.Create; local AddCorner = UI.AddCorner
local SafeClick = UI.SafeClick; local Toast = UI.Toast
local MakeText = UI.MakeText; local MakeSection = UI.MakeSection; local MakeButton = UI.MakeButton
local MakeTextBox = UI.MakeTextBox; local MakeToggle = UI.MakeToggle; local MakeSlider = UI.MakeSlider
local MakeDropdown = UI.MakeDropdown; local MakeColorPicker = UI.MakeColorPicker
local MakeInlineAlphaSlider = UI.MakeInlineAlphaSlider; local FlowOf = UI.FlowOf; local CreateGrid = UI.CreateGrid
local COL = UI.COL; local License = UI.License; local DEVICE_ID = UI.DEVICE_ID; local pages = UI.pages
local ApplyTheme = UI.ApplyTheme; local ApplyFont = UI.ApplyFont; local LoadAvatar = UI.LoadAvatar
local ListConfigNames = UI.ListConfigNames; local SaveConfig = UI.SaveConfig; local LoadConfig = UI.LoadConfig
local DeleteConfig = UI.DeleteConfig; local GetAutoLoad = UI.GetAutoLoad; local SetAutoLoad = UI.SetAutoLoad
local function ScrollOf(page)
    if not page then
        warn("[RealYoUI] ScrollOf: page is nil")
        return nil
    end
    local s = page:FindFirstChildOfClass("ScrollingFrame")
    if not s then
        warn("[RealYoUI] ScrollOf: scroll missing, auto-recreate")
        s = UI.Create("ScrollingFrame", {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ScrollBarThickness = math.max(2, 3),
            ScrollBarImageColor3 = Color3.fromRGB(120, 120, 120),
            Parent = page,
        })
        UI.Create("UIListLayout", {
            FillDirection = Enum.FillDirection.Vertical,
            Padding = UDim.new(0, 8),
        }, s)
        UI.Create("UIPadding", {
            PaddingTop = UDim.new(0, 10),
            PaddingLeft = UDim.new(0, 6),
            PaddingRight = UDim.new(0, 6),
            PaddingBottom = UDim.new(0, 10),
        }, s)
    end
    return s
end

-- 构建前探针：告诉我们到底哪几页缺 scroll（用于定位根因，不影响运行）
for m = 1, 4 do
    for j = 1, 4 do
        local pg = (pages[m] or {})[j]
        if not pg or not pg:FindFirstChildOfClass("ScrollingFrame") then
            warn(("[RealYoUI] pages[%d][%d] scroll missing BEFORE build"):format(m, j))
        end
    end
end

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

-- ✅ 页面构建
local home = ScrollOf(pages[1][1])
MakeText(home, "Status: " .. License.Status, COL.Green)
MakeButton(home, "Join Discord", function() setclipboard("https://discord.gg/SjRufjdF33") end)
local uidRow = FlowOf(home).AddFull(S(26))
Create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, S(6)) }, uidRow)
Create("TextLabel", { Size = UDim2.fromOffset(S(60), S(26)), BackgroundTransparency = 1, Text = "HWID:", TextColor3 = COL.Green, TextSize = TS(12), Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Left, Parent = uidRow })
Create("TextLabel", { Size = UDim2.fromOffset(S(240), S(26)), BackgroundTransparency = 1, Text = DEVICE_ID, TextColor3 = COL.Red, TextSize = TS(12), Font = Enum.Font.Code, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Parent = uidRow })
local copyBtn = Create("TextButton", { Size = UDim2.fromOffset(S(50), S(24)), BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 0.35, Text = "Copy", TextColor3 = COL.TextDark, TextSize = TS(12), Font = Enum.Font.GothamMedium, AutoButtonColor = false, Parent = uidRow })
AddCorner(copyBtn, S(4))
SafeClick(copyBtn, function() if setclipboard then pcall(function() setclipboard(DEVICE_ID) end); Toast("HWID Replicated") else Toast("Executer not support copy") end end)
MakeText(home, "Left time: " .. License.Remain, COL.Green)
MakeText(home, "SZE internal", COL.Red)
MakeText(home, "welcome, Scripts are temporarily free.", COL.TextDark)

local sc12 = ScrollOf(pages[1][2])
MakeSection(sc12, "Not yet")
MakeText(sc12, "SZELON0 on top", COL.TextDim)

local cfg = ScrollOf(pages[1][3])
MakeSection(cfg, "Config")
local cfgNameBox = MakeTextBox(cfg, "Config name", "default")
local initNames = ListConfigNames()
local cfgDrop = MakeDropdown(cfg, "Config choose", (#initNames > 0) and initNames or {"No config"}, (#initNames > 0) and initNames[1] or "No config", function(opt) if opt ~= "No config" then cfgNameBox.Text = opt end end)
local cfgGrid = CreateGrid(cfg)
MakeButton(cfgGrid, "Save config", function() local n = cfgNameBox.Text:gsub("^%s+", ""):gsub("%s+$", ""); if n == "" then Toast("input name") return end; SaveConfig(n); cfgDrop.SetOptions(ListConfigNames()) end)
MakeButton(cfgGrid, "Open config", function() local n = cfgNameBox.Text:gsub("^%s+", ""):gsub("%s+$", ""); if n == "" then Toast("input name") return end; LoadConfig(n) end)
MakeButton(cfgGrid, "Delete config", function() local n = cfgNameBox.Text:gsub("^%s+", ""):gsub("%s+$", ""); if n == "" then Toast("input name") return end; DeleteConfig(n); cfgDrop.SetOptions(ListConfigNames()) end)
MakeButton(cfgGrid, "refresh list", function() cfgDrop.SetOptions(ListConfigNames()); Toast("refreshed") end)
local autoOn0, autoName0 = GetAutoLoad()
MakeToggle(cfg, "Set as auto load", autoOn0, function(on) local n = cfgNameBox.Text:gsub("^%s+", ""):gsub("%s+$", ""); if n == "" then n = "default" end; SetAutoLoad(on, n); Toast(on and ("Execute will auto load: " .. n) or "close auto load") end, false)
MakeText(cfg, "Config save in directory RealYo_Configs", COL.TextDim)

local sc14 = ScrollOf(pages[1][4])
MakeSection(sc14, "theme")
local themeOptions = {"Classic", "DeepBlue", "Cyber", "Vampire"}
MakeDropdown(sc14, "theme", themeOptions, "Classic", function(opt) ApplyTheme(opt) end)
MakeInlineAlphaSlider(FlowOf(sc14))
MakeDropdown(sc14, "Frame", {"Rainbow", "Monocolour"}, "Rainbow", function(o) UI.AP.BorderRainbow = (o == "Rainbow"); Toast(UI.AP.BorderRainbow and "Frame: Rainbow" or "Frame: Monocolour") end)
MakeDropdown(sc14, "Font", {"Gotham", "SciFi", "SourceSans", "FredokaOne", "Code", "Ubuntu", "Bangers", "Merriweather"}, "Gotham", ApplyFont)
MakeSection(sc14, "RGB")
local pickerTarget = "UI bottom"
local pickerInfoLabel = nil
MakeDropdown(sc14, "Color target", {"UI bottom", "package", "main text", "dark text", "emphasis color", "frame"}, "UI bottom", function(o) pickerTarget = o; if pickerInfoLabel then pickerInfoLabel.Text = "Target: " .. o end; Toast("Color target: " .. o) end)
pickerInfoLabel = MakeText(sc14, "Target: UI bottom", COL.TextDim)
MakeColorPicker(sc14)

local draw = ScrollOf(pages[2][1])
MakeSection(draw, "ESP")
local espGrid = CreateGrid(draw)
MakeToggle(espGrid, "Open", false, function(on) ESP.Enabled = on; UpdatePreviewESP() end)
MakeToggle(espGrid, "Name", false, function(on) ESP.Names = on end)
MakeSlider(draw, "Distance", 50, 1000, 500, function(v) ESP.MaxDistance = v end)
MakeSlider(draw, "Transparent", 0, 100, 50, function(v) ESP.Transparency = v / 100; UpdatePreviewESP() end)
MakeSection(draw, "Advanced")
MakeSlider(draw, "Thickness", 1, 10, 1, function(v) ESP.Thickness = v end)
MakeSlider(draw, "font size", 10, 30, 13, function(v) ESP.FontSize = v end)
MakeSection(draw, "RGB")
MakeSlider(draw, "R", 0, 255, 255, function(v) ESP.R = v; ESP.Color = Color3.fromRGB(ESP.R, ESP.G, ESP.B); UpdatePreviewESP() end)
MakeSlider(draw, "G", 0, 255, 50, function(v) ESP.G = v; ESP.Color = Color3.fromRGB(ESP.R, ESP.G, ESP.B); UpdatePreviewESP() end)
MakeSlider(draw, "B", 0, 255, 50, function(v) ESP.B = v; ESP.Color = Color3.fromRGB(ESP.R, ESP.G, ESP.B); UpdatePreviewESP() end)
MakeSection(draw, "Rainbow")
local rainbowGrid = CreateGrid(draw)
MakeToggle(rainbowGrid, "Rainbow", false, function(on) Toast("Set to Rainbow"); ESP.Rainbow = on; UpdatePreviewESP() end)
MakeSlider(draw, "Speed", 1, 50, 10, function(v) ESP.RainbowSpeed = v / 10 end)

local move = ScrollOf(pages[3][1])
MakeSection(move, "FE")
local moveGrid = CreateGrid(move)
MakeToggle(moveGrid, "Fly", false, function(on) SetFly(on) end)
MakeToggle(moveGrid, "Noclip", false, function(on) Mods.Noclip = on end)
MakeToggle(moveGrid, "Inf jump", false, function(on) SetInfJump(on) end)
MakeToggle(moveGrid, "Walk Speed", false, function(on) Mods.SpeedOn = on; ApplySpeedJump() end)
MakeToggle(moveGrid, "Jump Power", false, function(on) Mods.JumpOn = on; ApplySpeedJump() end)
MakeSlider(move, "Fly Speed", 10, 200, 50, function(v) Mods.FlySpeed = v end)
MakeSlider(move, "Walk Speed", 16, 300, 16, function(v) Mods.Speed = v; ApplySpeedJump() end)
MakeSlider(move, "Jump power", 50, 500, 50, function(v) Mods.Jump = v; ApplySpeedJump() end)

local charPage = ScrollOf(pages[3][2])
local charGrid = CreateGrid(charPage)
MakeToggle(charGrid, "AntiAFK", false, function(on) SetAntiAFK(on) end)
MakeButton(charPage, "Reset character", function() local hum = GetHum(); if hum then hum.Health = 0 end end)

local world = ScrollOf(pages[3][3])
local worldGrid = CreateGrid(world)
MakeToggle(worldGrid, "Full bright", false, function(on) SetFullBright(on) end)
MakeToggle(worldGrid, "No fog", false, function(on) SetNoFog(on) end)
MakeToggle(worldGrid, "Lock time", false, function(on) Mods.TimeLock = on end)
MakeSlider(world, "Time", 0, 24, 14, function(v) Mods.Time = v end)

local util = ScrollOf(pages[3][4])
MakeButton(util, "Copy current location", function() local root = GetRoot(); if not root then Toast("角色未就绪") return end; if setclipboard then pcall(function() setclipboard(tostring(root.CFrame)) end); Toast("copy") else Toast("注入器不支持剪贴板") end end)
MakeButton(util, "Rejoin", function() pcall(function() TeleportService:Teleport(game.PlaceId) end) end)

-- ✅ RealYoHub / ScriptHub 页面 (Index 4) - 包含所有其他脚本按钮
local function RunRemoteLua(url, tag)
    local ok, err = pcall(function()
        local src = HttpGetText(url)
        local fn, cerr = loadstring(src)
        if type(fn) ~= "function" then
            local fixed = RepairSource(src)
            local fn2, cerr2 = loadstring(fixed)
            if type(fn2) ~= "function" then
                warn(("[RealYoUI] %s COMPILE FAILED"):format(tag))
                warn("raw     : " .. tostring(cerr))
                warn("repaired: " .. tostring(cerr2))
                error("compile failed")
            end
            fn, src = fn2, fixed
            warn(("[RealYoUI] %s source auto-repaired"):format(tag))
        end
        local ok2, rerr = pcall(fn)
        if not ok2 then
            local line = tonumber(tostring(rerr):match(":(%d+):"))
            warn(("[RealYoUI] %s RUNTIME ERROR: %s"):format(tag, tostring(rerr)))
            if line then
                local lines = {}
                for l in (src .. "\n"):gmatch("([^\n]*)\n") do lines[#lines+1] = l end
                warn(("----- %s source around line %d -----"):format(tag, line))
                for i = math.max(1, line - 5), math.min(#lines, line + 3) do
                    warn(("%4d| %s"):format(i, lines[i] or ""))
                end
                warn("------------------------------------------")
            end
            pcall(function() if setclipboard then setclipboard(src) end end)
            warn(("[RealYoUI] %s full source -> clipboard"):format(tag))
            error(tostring(rerr))
        end
    end)
    return ok, err
end
local script1 = ScrollOf(pages[4][1])
MakeButton(script1, "Survive in area 51!", function()
    local ok, err = RunRemoteLua("https://raw.githubusercontent.com/gy1619/RealYoHub/refs/heads/main/Area51.lua?t=" .. os.time(), "Area51")
    Toast(ok and "Executed" or ("Fail: " .. tostring(err):sub(1, 60)))
end)
MakeButton(script1, "BrookHaven RP", function() local ry = pcall(function() loadstring(game:HttpGet("https://gist.githubusercontent.com/gy1619/29ee3701d50f59ee4061c5a96d7a79c5/raw/bf871ba30f57e8929a4d847841114f31d9f73894/bhhrp.lua"))() end); Toast(ry and "Executed" or "Fail") end)
MakeButton(script1, "My Restaurant", function() local ry = pcall(function() loadstring(game:HttpGet("https://gist.githubusercontent.com/gy1619/a44f37202fd255c36bfd2e05b66204bd/raw/374703400612786c6ad8b1dbe57d9de42f3c879b/My%20Restaurant.lua"))() end); Toast(ry and "Executed" or "Fail") end)
MakeButton(script1, "Cut Grass", function() local ry = pcall(function() loadstring(game:HttpGet("https://gist.githubusercontent.com/gy1619/58841eb6cb738a4c9fffeaee95d8d6c8/raw/77d5043da62b0a092f0416787d6ca284899d8ece/Cut%20Grass.lua"))() end); Toast(ry and "Executed" or "Fail") end)
MakeButton(script1, "Poop a Big Poop", function() local ry = pcall(function() loadstring(game:HttpGet("https://gist.githubusercontent.com/gy1619/ddd84a349399d4059acd9778c79b73c4/raw/403cdb6417fc2a5af213d0eaafde1a643b1d6155/pabp.lua"))() end); Toast(ry and "Executed" or "Fail") end)
MakeText(script1, "RealYoHub", COL.TextDim)

local script2 = ScrollOf(pages[4][2]); MakeText(script2, "Not Yet", COL.TextDim)
local script3 = ScrollOf(pages[4][3]); MakeText(script3, "Not Yet", COL.TextDim)
local script4 = ScrollOf(pages[4][4])
MakeButton(script4, "Infinite Yield", function() local ok = pcall(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))() end); Toast(ok and "done" or "fail") end)
MakeText(script4, "Admin script", COL.TextDim)

LoadAvatar()
task.delay(2.5, UpdatePreviewESP)
LocalPlayer.CharacterAdded:Connect(function() taskWait(2); LoadAvatar() end)
if autoOn0 and autoName0 then task.delay(1, function() LoadConfig(autoName0) end) end
taskWait(0.5)
Toast("Loaded, HWID: " .. DEVICE_ID)
taskWait(0.5)
Toast("Loaded Successfully")
