-- PremiumUI.lua
-- PremiumUI Standalone UI Library + Takeover Compatibility Layer

local Lib = {
    Version = "1.0.0",
    Brand = "PremiumUI",
    Protocol = 1,
    IsPremiumUI = true,
    Initialized = false,
    UIScale = 1,
    ViewportSize = Vector2.new(1280, 720),
    Options = {
        Title = "Premium UI",
        Subtitle = "SZE",
    },
}

-------------------------------------------------
-- Services
-------------------------------------------------
local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local Lighting         = game:GetService("Lighting")
local HttpService      = game:GetService("HttpService")

Lib.Players = Players
Lib.LocalPlayer = Players.LocalPlayer

local LocalPlayer = Players.LocalPlayer

local cloneref = cloneref or function(o) return o end

local taskWait  = (task and task.wait) or function() return wait() end
local taskSpawn = (task and task.spawn) or function(f) return spawn(f) end
local taskDelay = (task and task.delay) or function(t, f) return delay(t, f) end

-------------------------------------------------
-- Global export
-------------------------------------------------
local function ExportGlobal()
    pcall(function()
        if getgenv then
            getgenv().PremiumUI = Lib
        end
    end)

    pcall(function()
        shared.PremiumUI = Lib
    end)

    pcall(function()
        _G.PremiumUI = Lib
    end)
end

ExportGlobal()

-------------------------------------------------
-- Utils
-------------------------------------------------
local function HashStr(s)
    local h = 5381
    for i = 1, #s do
        h = (h * 33 + string.byte(s, i)) % 4294967296
    end
    return string.format("%08X", h)
end

Lib.HashStr = HashStr

local function S(v)
    return v * Lib.UIScale
end

local function TS(v)
    return math.max(10, math.floor(v * Lib.UIScale))
end

function Lib:S(v)
    return v * self.UIScale
end

function Lib:TS(v)
    return math.max(10, math.floor(v * self.UIScale))
end

local function Create(class, props, parent)
    local obj = Instance.new(class)
    for k, v in pairs(props or {}) do
        obj[k] = v
    end
    if parent then
        obj.Parent = parent
    end
    return obj
end

Lib.Create = Create

local function AddCorner(parent, r)
    return Create("UICorner", {
        CornerRadius = UDim.new(0, r),
    }, parent)
end

Lib.AddCorner = AddCorner

local function SafeClick(obj, cb)
    local down, moved, startPos = false, false, nil

    obj.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            down, moved = true, false
            startPos = inp.Position
        end
    end)

    obj.InputChanged:Connect(function(inp)
        if down and startPos and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
            if (inp.Position - startPos).Magnitude > 8 then
                moved = true
            end
        end
    end)

    obj.InputEnded:Connect(function(inp)
        if down and (inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch) then
            down = false
            if not moved and cb then
                pcall(cb)
            end
        end
    end)
end

function Lib:SafeClick(obj, cb)
    SafeClick(obj, cb)
end

-------------------------------------------------
-- Colors / Theme
-------------------------------------------------
local COL = {
    TextDark = Color3.fromRGB(70, 70, 70),
    TextDim = Color3.fromRGB(110, 110, 110),
    Red = Color3.fromRGB(215, 60, 60),
    Green = Color3.fromRGB(50, 190, 90),
    PillGray = Color3.fromRGB(75, 75, 75),
    Gray = Color3.fromRGB(120, 120, 120),
    White = Color3.fromRGB(255, 255, 255),
}

Lib.Colors = COL

local Theme = {
    Panel = Color3.fromRGB(22, 22, 28),
    Accent = Color3.fromRGB(215, 60, 60),
    Button = Color3.fromRGB(48, 48, 56),
    ButtonText = Color3.fromRGB(235, 235, 240),
    Slider = Color3.fromRGB(230, 190, 60),
    Text = Color3.fromRGB(255, 255, 255),
    TextDim = Color3.fromRGB(150, 150, 160),
    Rainbow = true,
}

Lib.Theme = Theme

local ThemePresets = {
    DeepBlue = {
        Panel = Color3.fromRGB(14, 20, 36),
        Accent = Color3.fromRGB(60, 130, 255),
        Button = Color3.fromRGB(28, 40, 66),
        ButtonText = Color3.fromRGB(220, 235, 255),
        Slider = Color3.fromRGB(90, 160, 255),
        Text = Color3.fromRGB(235, 242, 255),
        TextDim = Color3.fromRGB(130, 150, 185),
        Rainbow = false,
    },
    Neon = {
        Panel = Color3.fromRGB(10, 10, 16),
        Accent = Color3.fromRGB(0, 255, 200),
        Button = Color3.fromRGB(24, 24, 34),
        ButtonText = Color3.fromRGB(200, 255, 240),
        Slider = Color3.fromRGB(0, 255, 200),
        Text = Color3.fromRGB(230, 255, 250),
        TextDim = Color3.fromRGB(120, 160, 150),
        Rainbow = true,
    },
    Vampire = {
        Panel = Color3.fromRGB(20, 10, 14),
        Accent = Color3.fromRGB(200, 30, 60),
        Button = Color3.fromRGB(40, 20, 28),
        ButtonText = Color3.fromRGB(255, 220, 225),
        Slider = Color3.fromRGB(220, 60, 90),
        Text = Color3.fromRGB(255, 235, 238),
        TextDim = Color3.fromRGB(170, 120, 130),
        Rainbow = false,
    },
    Emerald = {
        Panel = Color3.fromRGB(12, 24, 18),
        Accent = Color3.fromRGB(40, 200, 120),
        Button = Color3.fromRGB(24, 44, 34),
        ButtonText = Color3.fromRGB(215, 255, 235),
        Slider = Color3.fromRGB(70, 220, 150),
        Text = Color3.fromRGB(230, 255, 242),
        TextDim = Color3.fromRGB(130, 170, 150),
        Rainbow = false,
    },
    Sunset = {
        Panel = Color3.fromRGB(28, 16, 30),
        Accent = Color3.fromRGB(255, 120, 60),
        Button = Color3.fromRGB(52, 32, 54),
        ButtonText = Color3.fromRGB(255, 235, 220),
        Slider = Color3.fromRGB(255, 150, 80),
        Text = Color3.fromRGB(255, 242, 232),
        TextDim = Color3.fromRGB(185, 140, 160),
        Rainbow = true,
    },
    Classic = {
        Panel = Color3.fromRGB(22, 22, 28),
        Accent = Color3.fromRGB(215, 60, 60),
        Button = Color3.fromRGB(48, 48, 56),
        ButtonText = Color3.fromRGB(235, 235, 240),
        Slider = Color3.fromRGB(230, 190, 60),
        Text = Color3.fromRGB(255, 255, 255),
        TextDim = Color3.fromRGB(150, 150, 160),
        Rainbow = true,
    },
}

Lib.ThemePresets = ThemePresets

Lib.TR = {
    Panels = {},
    Accents = {},
    ButtonsBg = {},
    Buttons = {},
    Sliders = {},
    Toggles = {},
    Texts = {},
    Dims = {},
    Borders = {},
}

Lib.rainbowGrads = {}
Lib.langRegistry = {}
Lib.langEntryByObj = {}
Lib.SettingsRegistry = {}
Lib.Categories = {}
Lib.TopButtons = {}
Lib.Panels = {}
Lib.CurrentCategory = nil
Lib.CurrentSub = 1
Lib.CurrentPage = nil
Lib.UIVisible = false
Lib.ThemeFont = nil
Lib.currentLang = "en"
Lib.I18N = {}

Lib.ConfigDir = "PremiumUI_Configs"
Lib.AutoFile = Lib.ConfigDir .. "/_autoload_.json"

Lib.Takeover = {
    Sessions = {},
    Version = Lib.Protocol,
}

local panelDrag = nil
local openDropdown = nil
local rainbowT0 = tick()

local EASE = TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

local RAINBOW_SEQ = ColorSequence.new({
    ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 70, 70)),
    ColorSequenceKeypoint.new(0.25, Color3.fromRGB(255, 210, 70)),
    ColorSequenceKeypoint.new(0.50, Color3.fromRGB(90, 255, 130)),
    ColorSequenceKeypoint.new(0.75, Color3.fromRGB(90, 170, 255)),
    ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 90, 255)),
})

local HUE_SEQ = ColorSequence.new({
    ColorSequenceKeypoint.new(0.00, Color3.fromHSV(0.00, 1, 1)),
    ColorSequenceKeypoint.new(0.16, Color3.fromHSV(0.16, 1, 1)),
    ColorSequenceKeypoint.new(0.33, Color3.fromHSV(0.33, 1, 1)),
    ColorSequenceKeypoint.new(0.50, Color3.fromHSV(0.50, 1, 1)),
    ColorSequenceKeypoint.new(0.66, Color3.fromHSV(0.66, 1, 1)),
    ColorSequenceKeypoint.new(0.83, Color3.fromHSV(0.83, 1, 1)),
    ColorSequenceKeypoint.new(1.00, Color3.fromHSV(1.00, 1, 1)),
})

-------------------------------------------------
-- I18N
-------------------------------------------------
function Lib:AddI18N(map)
    for k, v in pairs(map or {}) do
        self.I18N[k] = v
    end
end

function Lib:T(s)
    if self.currentLang == "en" then
        return self.I18N[s] or s
    end
    return s
end

function Lib:RegisterLang(obj, zh, ph, custom)
    local e = {
        obj = obj,
        zh = zh,
        ph = ph,
        custom = custom,
    }

    if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
        e.origFont = obj.Font
    end

    self.langEntryByObj[obj] = e
    table.insert(self.langRegistry, e)
    return e
end

function Lib:ApplyLanguage()
    for _, e in ipairs(self.langRegistry) do
        local o = e.obj
        if o and o.Parent then
            if e.custom then
                pcall(e.custom)
            elseif e.ph then
                o.PlaceholderText = self:T(e.zh)
            else
                o.Text = self:T(e.zh)
            end

            if not e.ph then
                if self.ThemeFont then
                    o.Font = self.ThemeFont
                elseif e.origFont then
                    o.Font = e.origFont
                end
            end
        end
    end
end

function Lib:SetLanguage(lang)
    self.currentLang = lang
    self:ApplyLanguage()
    self:Toast(lang == "en" and "Language: English" or "語言: 中文")
end

function Lib:SetGlobalFont(f)
    self.ThemeFont = f
    for _, e in ipairs(self.langRegistry) do
        local o = e.obj
        if o and o.Parent and (o:IsA("TextLabel") or o:IsA("TextButton") or o:IsA("TextBox")) then
            o.Font = f
        end
    end
end

-------------------------------------------------
-- Rainbow / Glass
-------------------------------------------------
local function AddRainbowStroke(parent, thickness, glow)
    local stroke = Create("UIStroke", {
        Thickness = thickness or math.max(1, S(1.5)),
        Color = COL.White,
    }, parent)

    local grad = Create("UIGradient", {
        Rotation = 25,
        Color = RAINBOW_SEQ,
    }, stroke)

    table.insert(Lib.rainbowGrads, grad)
    table.insert(Lib.TR.Borders, {
        stroke = stroke,
        grad = grad,
    })

    if glow then
        local layers = {
            { S(4), 0.5 },
            { S(7), 0.75 },
            { S(10), 0.9 },
        }

        for _, info in ipairs(layers) do
            local s2 = Create("UIStroke", {
                Thickness = info[1],
                Color = COL.White,
                Transparency = info[2],
            }, parent)

            local g2 = Create("UIGradient", {
                Rotation = 25,
                Color = RAINBOW_SEQ,
            }, s2)

            table.insert(Lib.rainbowGrads, g2)
            table.insert(Lib.TR.Borders, {
                stroke = s2,
                grad = g2,
            })
        end
    end

    return stroke
end

local function AddRainbowBar(parent)
    local bar = Create("Frame", {
        Size = UDim2.new(1, 0, 0, math.max(1, S(2))),
        BackgroundColor3 = COL.White,
        Parent = parent,
    })

    local grad = Create("UIGradient", {
        Rotation = 0,
        Color = RAINBOW_SEQ,
    }, bar)

    table.insert(Lib.rainbowGrads, grad)
    table.insert(Lib.TR.Borders, {
        stroke = nil,
        grad = grad,
    })

    return bar
end

local function AddGlass(parent)
    parent.BackgroundColor3 = Lib.Theme.Panel
    parent.BackgroundTransparency = 0.05
    table.insert(Lib.TR.Panels, parent)
end

-------------------------------------------------
-- Toast
-------------------------------------------------
function Lib:Toast(msg)
    if not self.Initialized or not self.ToastHolder then
        print("[PremiumUI] " .. tostring(msg))
        return
    end

    taskSpawn(function()
        local label = Create("TextLabel", {
            Size = UDim2.fromOffset(S(280), S(30)),
            BackgroundColor3 = Color3.fromRGB(20, 20, 20),
            Text = tostring(msg),
            TextColor3 = COL.White,
            TextSize = TS(13),
            Font = Enum.Font.GothamMedium,
            BackgroundTransparency = 1,
            TextTransparency = 1,
            Parent = self.ToastHolder,
        })

        AddCorner(label, S(6))

        TweenService:Create(label, TweenInfo.new(0.2), {
            BackgroundTransparency = 0.25,
            TextTransparency = 0,
        }):Play()

        taskWait(1.8)

        TweenService:Create(label, TweenInfo.new(0.3), {
            BackgroundTransparency = 1,
            TextTransparency = 1,
        }):Play()

        taskWait(0.35)
        label:Destroy()
    end)
end

-------------------------------------------------
-- Theme refresh
-------------------------------------------------
function Lib:RefreshTheme()
    for _, p in ipairs(self.TR.Panels) do
        if p and p.Parent then
            p.BackgroundColor3 = self.Theme.Panel
        end
    end

    for _, a in ipairs(self.TR.Accents) do
        if a and a.Parent then
            a.BackgroundColor3 = self.Theme.Accent
        end
    end

    for _, b in ipairs(self.TR.ButtonsBg) do
        if b and b.Parent then
            b.BackgroundColor3 = self.Theme.Button
        end
    end

    for _, b in ipairs(self.TR.Buttons) do
        if b and b.Parent then
            b.BackgroundColor3 = self.Theme.Button
            b.TextColor3 = self.Theme.ButtonText
        end
    end

    for _, s in ipairs(self.TR.Sliders) do
        if s and s.Parent then
            s.BackgroundColor3 = self.Theme.Slider
        end
    end

    for _, tg in ipairs(self.TR.Toggles) do
        if tg.box and tg.box.Parent then
            tg.box.BackgroundColor3 = tg.state and self.Theme.Accent or COL.Gray
        end
    end

    for _, x in ipairs(self.TR.Texts) do
        if x and x.Parent then
            x.TextColor3 = self.Theme.Text
        end
    end

    for _, d in ipairs(self.TR.Dims) do
        if d and d.Parent then
            d.TextColor3 = self.Theme.TextDim
        end
    end

    for _, bi in ipairs(self.TR.Borders) do
        if bi.grad then
            bi.grad.Enabled = self.Theme.Rainbow
        end
        if bi.stroke then
            bi.stroke.Color = self.Theme.Rainbow and COL.White or self.Theme.Accent
        end
    end
end

function Lib:ApplyPreset(name)
    local p = self.ThemePresets[name]
    if not p then
        return
    end

    for k, v in pairs(p) do
        self.Theme[k] = v
    end

    self:RefreshTheme()
    self:Toast(self:T("主題已切換") .. ": " .. name)
end

-------------------------------------------------
-- Settings / Config
-------------------------------------------------
function Lib:RegisterSetting(name, kind, get, set)
    table.insert(self.SettingsRegistry, {
        name = name,
        kind = kind,
        get = get,
        set = set,
    })
end

local function FileSupport()
    return type(writefile) == "function" and type(readfile) == "function" and type(isfile) == "function"
end

local function EnsureFolder(dir)
    pcall(function()
        if type(makefolder) == "function" and not isfolder(dir) then
            makefolder(dir)
        end
    end)
end

function Lib:ListConfigNames()
    local names = {}

    pcall(function()
        if type(listfiles) == "function" then
            for _, p in ipairs(listfiles(self.ConfigDir)) do
                local n = tostring(p):match("([^/\\]+)%.json$")
                if n and n ~= "_autoload_" then
                    table.insert(names, n)
                end
            end
        end
    end)

    return names
end

function Lib:SaveConfig(name)
    if not FileSupport() then
        self:Toast("當前注入器不支持文件保存")
        return
    end

    local data = {}
    for _, e in ipairs(self.SettingsRegistry) do
        data[e.name] = e.get()
    end

    EnsureFolder(self.ConfigDir)

    local ok = pcall(function()
        writefile(self.ConfigDir .. "/" .. name .. ".json", HttpService:JSONEncode(data))
    end)

    self:Toast(ok and ("配置已保存: " .. name) or "保存失敗")
end

function Lib:LoadConfig(name)
    if not FileSupport() then
        self:Toast("當前注入器不支持文件讀取")
        return
    end

    local ok, raw = pcall(function()
        if not isfile(self.ConfigDir .. "/" .. name .. ".json") then
            return nil
        end
        return readfile(self.ConfigDir .. "/" .. name .. ".json")
    end)

    if not ok or not raw then
        self:Toast("配置不存在: " .. name)
        return
    end

    local ok2, data = pcall(function()
        return HttpService:JSONDecode(raw)
    end)

    if not ok2 or type(data) ~= "table" then
        self:Toast("配置損壞: " .. name)
        return
    end

    local count = 0
    for _, e in ipairs(self.SettingsRegistry) do
        if data[e.name] ~= nil then
            e.set(data[e.name])
            count = count + 1
        end
    end

    self:Toast(("配置已讀取: %s (%d項)"):format(name, count))
end

function Lib:DeleteConfig(name)
    if not FileSupport() then
        self:Toast("當前注入器不支持文件刪除")
        return
    end

    local ok = pcall(function()
        if isfile(self.ConfigDir .. "/" .. name .. ".json") then
            delfile(self.ConfigDir .. "/" .. name .. ".json")
        end
    end)

    self:Toast(ok and ("配置已刪除: " .. name) or "刪除失敗")
end

function Lib:GetAutoLoad()
    local ok, raw = pcall(function()
        if not isfile(self.AutoFile) then
            return nil
        end
        return readfile(self.AutoFile)
    end)

    if not ok or not raw then
        return false, nil
    end

    local ok2, d = pcall(function()
        return HttpService:JSONDecode(raw)
    end)

    if ok2 and type(d) == "table" then
        return d.enabled == true, d.name
    end

    return false, nil
end

function Lib:SetAutoLoad(enabled, name)
    if not FileSupport() then
        self:Toast("當前注入器不支持文件保存")
        return
    end

    EnsureFolder(self.ConfigDir)

    pcall(function()
        writefile(self.AutoFile, HttpService:JSONEncode({
            enabled = enabled,
            name = name,
        }))
    end)
end

-------------------------------------------------
-- Dropdown close
-------------------------------------------------
local function CloseDropdown()
    if openDropdown then
        openDropdown.Visible = false
        openDropdown = nil
    end
end

function Lib:CloseDropdown()
    CloseDropdown()
end

-------------------------------------------------
-- Host helpers
-------------------------------------------------
function Lib:HostInfo(host)
    if type(host) == "table" then
        if host.__type == "grid" then
            return host:Add(), true
        elseif host.__type == "page" then
            return host.Scroll, false
        end
    elseif typeof(host) == "Instance" then
        return host, false
    end

    return nil, false
end

-------------------------------------------------
-- Controls
-------------------------------------------------
function Lib:Label(host, text, color, size)
    local parent, inGrid = self:HostInfo(host)
    if not parent then
        return
    end

    local l = Create("TextLabel", {
        Size = UDim2.new(1, inGrid and 0 or -S(8), 0, S(18)),
        BackgroundTransparency = 1,
        Text = self:T(text),
        TextColor3 = color or COL.Text,
        TextSize = size or TS(13),
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
        Parent = parent,
    })

    self:RegisterLang(l, text)

    if color == COL.TextDim then
        table.insert(self.TR.Dims, l)
    elseif color ~= COL.Green and color ~= COL.Red then
        table.insert(self.TR.Texts, l)
    end

    return l
end

function Lib:Button(host, text, cb)
    local parent, inGrid = self:HostInfo(host)
    if not parent then
        return
    end

    local btn = Create("TextButton", {
        Size = UDim2.new(1, inGrid and 0 or -S(8), 0, inGrid and S(26) or S(28)),
        BackgroundColor3 = self.Theme.Button,
        BackgroundTransparency = 0.1,
        Text = self:T(text),
        TextColor3 = self.Theme.ButtonText,
        Font = Enum.Font.GothamMedium,
        TextSize = inGrid and TS(12) or TS(13),
        AutoButtonColor = false,
        Parent = parent,
    })

    AddCorner(btn, S(5))

    Create("UIStroke", {
        Thickness = 1,
        Color = Color3.fromRGB(160, 160, 160),
        Transparency = 0.5,
    }, btn)

    SafeClick(btn, function()
        if cb then
            pcall(cb)
        end
    end)

    self:RegisterLang(btn, text)
    table.insert(self.TR.Buttons, btn)

    return btn
end

function Lib:TextBox(host, placeholder, default)
    local parent, inGrid = self:HostInfo(host)
    if not parent then
        return
    end

    local box = Create("TextBox", {
        Size = UDim2.new(1, inGrid and 0 or -S(8), 0, S(28)),
        BackgroundColor3 = self.Theme.Button,
        BackgroundTransparency = 0.1,
        Text = default or "",
        PlaceholderText = self:T(placeholder),
        TextColor3 = self.Theme.ButtonText,
        Font = Enum.Font.GothamMedium,
        TextSize = TS(13),
        ClearTextOnFocus = false,
        Parent = parent,
    })

    AddCorner(box, S(5))

    Create("UIStroke", {
        Thickness = 1,
        Color = Color3.fromRGB(160, 160, 160),
        Transparency = 0.5,
    }, box)

    self:RegisterLang(box, placeholder, true)
    table.insert(self.TR.Buttons, box)

    return box
end

function Lib:Toggle(host, text, default, cb, register)
    if register == nil then
        register = true
    end

    local parent, inGrid = self:HostInfo(host)
    if not parent then
        return
    end

    local state = default and true or false

    local row = Create("Frame", {
        Size = UDim2.new(1, inGrid and 0 or -S(8), 0, S(28)),
        BackgroundTransparency = 1,
        Parent = parent,
    })

    local box = Create("Frame", {
        Size = UDim2.fromOffset(S(18), S(18)),
        Position = UDim2.fromOffset(0, S(5)),
        BackgroundColor3 = state and self.Theme.Accent or COL.Gray,
        Parent = row,
    })

    AddCorner(box, S(3))

    local label = Create("TextLabel", {
        Size = UDim2.new(1, -S(26), 1, 0),
        Position = UDim2.fromOffset(S(26), 0),
        BackgroundTransparency = 1,
        Text = self:T(text),
        TextColor3 = self.Theme.Text,
        TextSize = TS(13),
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = row,
    })

    self:RegisterLang(label, text)
    table.insert(self.TR.Texts, label)

    local entry = {
        box = box,
        state = state,
    }

    table.insert(self.TR.Toggles, entry)

    local function apply(v, fire)
        v = v and true or false

        if v == state then
            return
        end

        state = v
        entry.state = state
        box.BackgroundColor3 = state and self.Theme.Accent or COL.Gray

        if fire and cb then
            pcall(cb, state)
        end
    end

    SafeClick(row, function()
        apply(not state, true)
    end)

    if register then
        self:RegisterSetting(text, "toggle", function()
            return state
        end, function(v)
            apply(v, true)
        end)
    end

    return row
end

function Lib:Slider(host, text, min, max, default, cb)
    local parent, inGrid = self:HostInfo(host)
    if not parent then
        return
    end

    local row = Create("Frame", {
        Size = UDim2.new(1, inGrid and 0 or -S(8), 0, S(34)),
        BackgroundColor3 = self.Theme.Button,
        BackgroundTransparency = 0.35,
        Parent = parent,
    })

    AddCorner(row, S(6))
    table.insert(self.TR.ButtonsBg, row)

    local bar = Create("Frame", {
        Size = UDim2.new(1, -S(180), 0, S(8)),
        Position = UDim2.fromOffset(S(10), S(13)),
        BackgroundColor3 = COL.Gray,
        BackgroundTransparency = 0.3,
        Parent = row,
    })

    AddCorner(bar, S(4))

    local fill = Create("Frame", {
        BackgroundColor3 = self.Theme.Slider,
        Parent = bar,
    })

    AddCorner(fill, S(4))
    table.insert(self.TR.Sliders, fill)

    local knob = Create("Frame", {
        Size = UDim2.fromOffset(S(14), S(14)),
        BackgroundColor3 = COL.White,
        Parent = bar,
        ZIndex = 2,
    })

    AddCorner(knob, S(7))

    local valLabel = Create("TextLabel", {
        Size = UDim2.fromOffset(S(44), S(20)),
        Position = UDim2.new(1, -S(168), 0.5, -S(10)),
        BackgroundTransparency = 1,
        TextColor3 = self.Theme.ButtonText,
        TextSize = TS(13),
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Right,
        Parent = row,
    })

    table.insert(self.TR.Texts, valLabel)

    local desc = Create("TextLabel", {
        Size = UDim2.fromOffset(S(110), S(20)),
        Position = UDim2.new(1, -S(116), 0.5, -S(10)),
        BackgroundTransparency = 1,
        Text = self:T(text),
        TextColor3 = self.Theme.TextDim,
        TextSize = TS(12),
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = row,
    })

    self:RegisterLang(desc, text)
    table.insert(self.TR.Dims, desc)

    local currentVal = default
    local dragging = false

    local function setRatio(r, fire)
        r = math.clamp(r, 0, 1)

        fill.Size = UDim2.new(r, 0, 1, 0)
        knob.Position = UDim2.new(r, -S(7), 0.5, -S(7))

        currentVal = math.floor(min + (max - min) * r + 0.5)
        valLabel.Text = tostring(currentVal)

        if fire and cb then
            pcall(cb, currentVal)
        end
    end

    local function updateFromX(x, fire)
        if bar.AbsoluteSize.X <= 0 then
            return
        end

        setRatio((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, fire)
    end

    setRatio((default - min) / (max - min), false)

    bar.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            updateFromX(inp.Position.X, true)
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

    self:RegisterSetting(text, "slider", function()
        return currentVal
    end, function(v)
        v = math.clamp(tonumber(v) or default, min, max)
        setRatio((v - min) / (max - min), true)
    end)

    return row
end

function Lib:Dropdown(host, text, options, default, cb)
    local parent, inGrid = self:HostInfo(host)
    if not parent then
        return
    end

    local row = Create("Frame", {
        Size = UDim2.new(1, inGrid and 0 or -S(8), 0, S(30)),
        BackgroundTransparency = 1,
        Parent = parent,
    })

    local btn = Create("TextButton", {
        Size = UDim2.fromOffset(S(150), S(26)),
        BackgroundColor3 = self.Theme.Button,
        BackgroundTransparency = 0.1,
        Text = self:T(default) .. "  v",
        TextColor3 = self.Theme.ButtonText,
        TextSize = TS(12),
        Font = Enum.Font.GothamMedium,
        AutoButtonColor = false,
        Parent = row,
    })

    AddCorner(btn, S(5))

    Create("UIStroke", {
        Thickness = 1,
        Color = Color3.fromRGB(160, 160, 160),
        Transparency = 0.5,
    }, btn)

    table.insert(self.TR.Buttons, btn)

    local desc = Create("TextLabel", {
        Size = UDim2.fromOffset(S(140), S(26)),
        Position = UDim2.fromOffset(S(158), 0),
        BackgroundTransparency = 1,
        Text = self:T(text),
        TextColor3 = self.Theme.TextDim,
        TextSize = TS(12),
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = row,
    })

    self:RegisterLang(desc, text)
    table.insert(self.TR.Dims, desc)

    local list = Create("Frame", {
        BackgroundColor3 = self.Theme.Panel,
        BackgroundTransparency = 0.05,
        Visible = false,
        Parent = self.ScreenGui,
        ZIndex = 70,
    })

    AddCorner(list, S(5))
    table.insert(self.TR.Panels, list)

    Create("UIListLayout", {
        Padding = UDim.new(0, S(2)),
    }, list)

    Create("UIPadding", {
        PaddingTop = UDim.new(0, S(3)),
        PaddingLeft = UDim.new(0, S(3)),
        PaddingRight = UDim.new(0, S(3)),
    }, list)

    local handle = {}
    local cur = default

    self:RegisterLang(btn, nil, false, function()
        btn.Text = self:T(cur) .. "  v"
    end)

    local function buildOptions(opts)
        for _, c in ipairs(list:GetChildren()) do
            if c:IsA("TextButton") then
                c:Destroy()
            end
        end

        for _, opt in ipairs(opts) do
            local ob = Create("TextButton", {
                Size = UDim2.new(1, 0, 0, S(24)),
                BackgroundTransparency = 1,
                Text = self:T(opt),
                TextColor3 = self.Theme.Text,
                TextSize = TS(12),
                Font = Enum.Font.Gotham,
                AutoButtonColor = false,
                Parent = list,
            })

            self:RegisterLang(ob, opt)
            table.insert(self.TR.Texts, ob)

            SafeClick(ob, function()
                cur = opt
                btn.Text = self:T(opt) .. "  v"
                CloseDropdown()

                if cb then
                    pcall(cb, opt)
                end
            end)
        end

        list.Size = UDim2.fromOffset(S(150), S(26) * #opts + S(6))
    end

    buildOptions(options)

    function handle.SetOptions(opts)
        buildOptions(opts or {})
    end

    SafeClick(btn, function()
        if openDropdown == list then
            CloseDropdown()
            return
        end

        CloseDropdown()

        list.Position = UDim2.fromOffset(
            btn.AbsolutePosition.X,
            btn.AbsolutePosition.Y + btn.AbsoluteSize.Y + S(4)
        )

        list.Visible = true
        openDropdown = list
    end)

    return handle
end

function Lib:ColorPicker(host, text, getDefault, cb)
    local parent = self:HostInfo(host)
    if not parent then
        return
    end

    local holder = Create("Frame", {
        Size = UDim2.new(1, -S(8), 0, S(150)),
        BackgroundColor3 = self.Theme.Button,
        BackgroundTransparency = 0.5,
        Parent = parent,
    })

    AddCorner(holder, S(6))

    local label = Create("TextLabel", {
        Size = UDim2.new(1, -S(16), 0, S(18)),
        Position = UDim2.fromOffset(S(8), S(4)),
        BackgroundTransparency = 1,
        Text = self:T(text),
        TextColor3 = self.Theme.Text,
        TextSize = TS(12),
        Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = holder,
    })

    self:RegisterLang(label, text)
    table.insert(self.TR.Texts, label)

    local sv = Create("Frame", {
        Size = UDim2.new(1, -S(16), 0, S(84)),
        Position = UDim2.fromOffset(S(8), S(24)),
        BackgroundColor3 = Color3.fromHSV(0, 1, 1),
        Parent = holder,
    })

    AddCorner(sv, S(4))

    Create("UIGradient", {
        Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.new(1, 1, 1)),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(1, 1),
        }),
    }, sv)

    Create("UIGradient", {
        Color = ColorSequence.new(Color3.new(0, 0, 0), Color3.new(0, 0, 0)),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(1, 0),
        }),
        Rotation = 90,
    }, sv)

    local svKnob = Create("Frame", {
        Size = UDim2.fromOffset(S(12), S(12)),
        BackgroundTransparency = 1,
        ZIndex = 5,
        Parent = sv,
    })

    Create("UIStroke", {
        Thickness = 2,
        Color = Color3.new(1, 1, 1),
    }, svKnob)

    AddCorner(svKnob, S(6))

    local hue = Create("Frame", {
        Size = UDim2.new(1, -S(16), 0, S(14)),
        Position = UDim2.fromOffset(S(8), S(116)),
        BackgroundColor3 = Color3.new(1, 0, 0),
        Parent = holder,
    })

    AddCorner(hue, S(4))

    Create("UIGradient", {
        Color = HUE_SEQ,
    }, hue)

    local hueKnob = Create("Frame", {
        Size = UDim2.fromOffset(S(4), S(18)),
        Position = UDim2.new(0, -S(2), 0, -S(2)),
        BackgroundColor3 = Color3.new(1, 1, 1),
        ZIndex = 5,
        Parent = hue,
    })

    AddCorner(hueKnob, S(2))

    local defaultColor = getDefault and getDefault() or Color3.new(1, 1, 1)

    if typeof(defaultColor) ~= "Color3" then
        defaultColor = Color3.new(1, 1, 1)
    end

    local h, s, v = Color3.toHSV(defaultColor)

    local function render(fire)
        sv.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
        svKnob.Position = UDim2.new(s, -S(6), 1 - v, -S(6))
        hueKnob.Position = UDim2.new(h, -S(2), 0, -S(2))

        if fire and cb then
            pcall(cb, Color3.fromHSV(h, s, v))
        end
    end

    local svDrag = false
    local hueDrag = false

    local function svUpdate(x, y, fire)
        s = math.clamp((x - sv.AbsolutePosition.X) / math.max(1, sv.AbsoluteSize.X), 0, 1)
        v = 1 - math.clamp((y - sv.AbsolutePosition.Y) / math.max(1, sv.AbsoluteSize.Y), 0, 1)
        render(fire)
    end

    local function hueUpdate(x, fire)
        h = math.clamp((x - hue.AbsolutePosition.X) / math.max(1, hue.AbsoluteSize.X), 0, 1)
        render(fire)
    end

    sv.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            svDrag = true
            svUpdate(inp.Position.X, inp.Position.Y, true)
        end
    end)

    hue.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            hueDrag = true
            hueUpdate(inp.Position.X, true)
        end
    end)

    UserInputService.InputChanged:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch then
            if svDrag then
                svUpdate(inp.Position.X, inp.Position.Y, true)
            end

            if hueDrag then
                hueUpdate(inp.Position.X, true)
            end
        end
    end)

    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            svDrag = false
            hueDrag = false
        end
    end)

    render(false)

    return holder
end

-------------------------------------------------
-- Grid / Page objects
-------------------------------------------------
local function AddControlMethods(obj)
    obj.Label = function(self, ...)
        return Lib:Label(self, ...)
    end

    obj.Button = function(self, ...)
        return Lib:Button(self, ...)
    end

    obj.Toggle = function(self, ...)
        return Lib:Toggle(self, ...)
    end

    obj.Slider = function(self, ...)
        return Lib:Slider(self, ...)
    end

    obj.Dropdown = function(self, ...)
        return Lib:Dropdown(self, ...)
    end

    obj.Box = function(self, ...)
        return Lib:TextBox(self, ...)
    end

    obj.ColorPicker = function(self, ...)
        return Lib:ColorPicker(self, ...)
    end
end

function Lib:Grid(parent)
    local grid = Create("Frame", {
        Size = UDim2.new(1, -S(8), 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Parent = parent,
    })

    Create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        Padding = UDim.new(0, S(10)),
    }, grid)

    local colL = Create("Frame", {
        Size = UDim2.new(0.5, -S(5), 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Parent = grid,
    })

    local colR = Create("Frame", {
        Size = UDim2.new(0.5, -S(5), 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Parent = grid,
    })

    for _, c in ipairs({ colL, colR }) do
        Create("UIListLayout", {
            FillDirection = Enum.FillDirection.Vertical,
            Padding = UDim.new(0, S(6)),
        }, c)
    end

    local obj = {
        __type = "grid",
        Frame = grid,
        colL = colL,
        colR = colR,
        nextLeft = true,
    }

    function obj.Add(self)
        local c = self.nextLeft and self.colL or self.colR
        self.nextLeft = not self.nextLeft
        return c
    end

    AddControlMethods(obj)

    return obj
end

local function NewPageObject(frame, scroll, catKey, subKey)
    local page = {
        __type = "page",
        Frame = frame,
        Scroll = scroll,
        Category = catKey,
        Sub = subKey,
        Owner = nil,
    }

    AddControlMethods(page)

    page.Grid = function(self)
        return Lib:Grid(self.Scroll)
    end

    page.Clear = function(self)
        for _, c in ipairs(self.Scroll:GetChildren()) do
            if not c:IsA("UIListLayout") and not c:IsA("UIPadding") then
                c:Destroy()
            end
        end

        for _, c in ipairs(self.Frame:GetChildren()) do
            if c ~= self.Scroll and not c:IsA("UIListLayout") and not c:IsA("UIPadding") then
                c:Destroy()
            end
        end

        self.Owner = nil
        self.Scroll.Visible = true
    end

    return page
end

function Lib:CreatePageFrame(catKey, subKey)
    local page = Create("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Visible = false,
        Parent = self.Clip,
    })

    local scroll = Create("ScrollingFrame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = math.max(2, S(3)),
        ScrollBarImageColor3 = Color3.fromRGB(120, 120, 120),
        Parent = page,
        BorderSizePixel = 0,
    })

    Create("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical,
        Padding = UDim.new(0, S(8)),
    }, scroll)

    Create("UIPadding", {
        PaddingTop = UDim.new(0, S(10)),
        PaddingLeft = UDim.new(0, S(6)),
        PaddingRight = UDim.new(0, S(6)),
        PaddingBottom = UDim.new(0, S(10)),
    }, scroll)

    return NewPageObject(page, scroll, catKey, subKey)
end

-------------------------------------------------
-- Category / Page navigation
-------------------------------------------------
function Lib:UpdateSideHeight()
    if not self.M then
        return
    end

    local n = #self.Categories
    if n == 0 then
        return
    end

    local h = S(28) + self.M.sidePad + n * self.M.sideBtnH + (n - 1) * self.M.sideGap + self.M.sidePad
    self.SideOuter.Size = UDim2.fromOffset(self.M.sideW, h)
end

function Lib:UpdateSideHighlight()
    for idx, cat in ipairs(self.Categories) do
        if cat.SideButton then
            cat.SideButton.TextColor3 = (idx == self.CurrentCategory) and self.Theme.Text or self.Theme.TextDim
        end
    end
end

function Lib:RebuildTop(cat)
    for _, child in ipairs(self.TopList:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end

    self.TopButtons = {}

    local n = math.max(1, #cat.SubNames)

    self.TopIndicator.Size = UDim2.new(1 / n, -S(10), 0, S(32))

    if #cat.SubNames == 0 then
        return
    end

    for j, name in ipairs(cat.SubNames) do
        local b = Create("TextButton", {
            Size = UDim2.new(1 / n, 0, 1, 0),
            BackgroundTransparency = 1,
            Text = self:T(name),
            TextColor3 = (j == (cat.SelectedSub or 1)) and self.Theme.Text or self.Theme.TextDim,
            Font = Enum.Font.GothamBold,
            TextSize = TS(13),
            AutoButtonColor = false,
            Parent = self.TopList,
        })

        self:RegisterLang(b, name)
        table.insert(self.TR.Texts, b)

        SafeClick(b, function()
            self:SelectSub(j)
        end)

        self.TopButtons[j] = b
    end
end

function Lib:UpdateTopHighlight(j)
    local cat = self.Categories[self.CurrentCategory]
    if not cat then
        return
    end

    local n = math.max(1, #cat.SubNames)

    self.TopIndicator.Size = UDim2.new(1 / n, -S(10), 0, S(32))

    TweenService:Create(self.TopIndicator, EASE, {
        Position = UDim2.new((j - 1) / n, S(5), 0, S(6)),
    }):Play()

    for idx, b in ipairs(self.TopButtons or {}) do
        b.TextColor3 = (idx == j) and self.Theme.Text or self.Theme.TextDim
    end
end

function Lib:SlideToPage(newPage, dirX, dirY)
    if self.CurrentPage == newPage then
        return
    end

    local old = self.CurrentPage
    self.CurrentPage = newPage

    local cw = self.Clip.AbsoluteSize.X
    local ch = self.Clip.AbsoluteSize.Y

    newPage.Position = UDim2.fromOffset(dirX * cw, dirY * ch)
    newPage.Visible = true

    TweenService:Create(newPage, EASE, {
        Position = UDim2.fromOffset(0, 0),
    }):Play()

    if old then
        TweenService:Create(old, EASE, {
            Position = UDim2.fromOffset(-dirX * cw, -dirY * ch),
        }):Play()

        local oldRef = old

        taskDelay(0.32, function()
            if self.CurrentPage ~= oldRef then
                oldRef.Visible = false
                oldRef.Position = UDim2.fromOffset(0, 0)
            end
        end)
    end
end

function Lib:SelectCategory(i)
    local cat = self.Categories[i]
    if not cat then
        return
    end

    if self.CurrentCategory == i then
        return
    end

    local dir = 0
    if self.CurrentCategory then
        dir = i > self.CurrentCategory and 1 or -1
    end

    self.CurrentCategory = i
    self.CurrentSub = cat.SelectedSub or 1

    self:UpdateSideHighlight()

    TweenService:Create(self.SideIndicator, EASE, {
        Position = UDim2.fromOffset(
            self.M.sidePad,
            S(28) + self.M.sidePad + (i - 1) * (self.M.sideBtnH + self.M.sideGap)
        ),
    }):Play()

    self:RebuildTop(cat)
    self:UpdateTopHighlight(self.CurrentSub)

    local page = cat.Pages[self.CurrentSub]
    if page then
        self:SlideToPage(page.Frame, 0, dir)
    end
end

function Lib:SelectSub(j)
    local cat = self.Categories[self.CurrentCategory]
    if not cat then
        return
    end

    if j == self.CurrentSub then
        return
    end

    local dir = j > self.CurrentSub and 1 or -1

    self.CurrentSub = j
    cat.SelectedSub = j

    self:UpdateTopHighlight(j)

    local page = cat.Pages[j]
    if page then
        self:SlideToPage(page.Frame, dir, 0)
    end
end

function Lib:AddCategory(name, subNames)
    local idx = #self.Categories + 1

    local cat = {
        Key = name,
        SubNames = subNames or {},
        Pages = {},
        SelectedSub = 1,
    }

    local b = Create("TextButton", {
        Size = UDim2.new(1, 0, 0, self.M.sideBtnH),
        BackgroundTransparency = 1,
        Text = self:T(name),
        TextColor3 = self.Theme.TextDim,
        Font = Enum.Font.GothamMedium,
        TextSize = TS(14),
        AutoButtonColor = false,
        Parent = self.SideList,
    })

    SafeClick(b, function()
        self:SelectCategory(idx)
    end)

    self:RegisterLang(b, name)
    table.insert(self.TR.Texts, b)

    cat.SideButton = b

    for _, sub in ipairs(cat.SubNames) do
        local p = self:CreatePageFrame(name, sub)
        table.insert(cat.Pages, p)
    end

    table.insert(self.Categories, cat)

    self:UpdateSideHeight()
    self:UpdateSideHighlight()

    if idx == 1 then
        self:SelectCategory(1)
    end

    return cat
end

function Lib:AddSubToCategory(cat, subName)
    table.insert(cat.SubNames, subName)

    local p = self:CreatePageFrame(cat.Key, subName)
    table.insert(cat.Pages, p)

    if self.CurrentCategory and self.Categories[self.CurrentCategory] == cat then
        self:RebuildTop(cat)
        self:UpdateTopHighlight(cat.SelectedSub or 1)
    end

    return p
end

function Lib:GetPage(catKey, subKey)
    for _, cat in ipairs(self.Categories) do
        if cat.Key == catKey then
            for j, sub in ipairs(cat.SubNames) do
                if sub == subKey then
                    return cat.Pages[j], cat, j
                end
            end
        end
    end

    return nil
end

function Lib:GetOrCreatePage(catKey, subKey)
    local cat

    for _, c in ipairs(self.Categories) do
        if c.Key == catKey then
            cat = c
            break
        end
    end

    if not cat then
        cat = self:AddCategory(catKey, { subKey })
        return cat.Pages[1], cat, 1
    end

    for j, s in ipairs(cat.SubNames) do
        if s == subKey then
            return cat.Pages[j], cat, j
        end
    end

    local p = self:AddSubToCategory(cat, subKey)
    return p, cat, #cat.SubNames
end

-------------------------------------------------
-- Visibility / Drag / Ball
-------------------------------------------------
function Lib:SetVisible(v)
    if v == self.UIVisible then
        return
    end

    self.UIVisible = v

    if v then
        for _, p in ipairs(self.Panels) do
            p.Visible = true

            local sc = p:FindFirstChildOfClass("UIScale")
            if sc then
                sc.Scale = 0.85

                TweenService:Create(sc, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                    Scale = 1,
                }):Play()
            end
        end
    else
        CloseDropdown()

        for _, p in ipairs(self.Panels) do
            local sc = p:FindFirstChildOfClass("UIScale")
            if sc then
                TweenService:Create(sc, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                    Scale = 0.85,
                }):Play()
            end
        end

        taskDelay(0.2, function()
            if not self.UIVisible then
                for _, p in ipairs(self.Panels) do
                    p.Visible = false
                end
            end
        end)
    end
end

function Lib:Toggle()
    self:SetVisible(not self.UIVisible)
end

function Lib:MakeDragHandle(panel, size, position)
    local handle = Create("Frame", {
        Size = size,
        Position = position,
        BackgroundTransparency = 1,
        Parent = panel,
        ZIndex = 4,
    })

    handle.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            panelDrag = {
                frame = panel,
                start = inp.Position,
                orig = panel.Position,
            }
        end
    end)

    return handle
end

function Lib:CreateBall()
    local M = self.M
    local ballSize = M.ballSize
    local vp = self.ViewportSize

    self.Ball = Create("TextButton", {
        Size = UDim2.fromOffset(ballSize, ballSize),
        Position = UDim2.fromOffset(S(14), (vp.Y - ballSize) / 2),
        BackgroundTransparency = 1,
        Text = "",
        AutoButtonColor = false,
        Parent = self.ScreenGui,
    })

    local BallRing = Create("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Parent = self.Ball,
    })

    AddCorner(BallRing, ballSize / 2)

    local ringStroke = Create("UIStroke", {
        Thickness = math.max(2, S(3)),
        Color = COL.White,
    }, BallRing)

    local ringGrad = Create("UIGradient", {
        Rotation = 0,
        Color = RAINBOW_SEQ,
    }, ringStroke)

    table.insert(self.rainbowGrads, ringGrad)

    local discOuter = Create("Frame", {
        Size = UDim2.fromOffset(ballSize * 0.76, ballSize * 0.76),
        Position = UDim2.new(0.5, -ballSize * 0.38, 0.5, -ballSize * 0.38),
        BackgroundColor3 = Color3.fromRGB(110, 220, 70),
        Parent = self.Ball,
    })

    AddCorner(discOuter, ballSize)

    local discMid = Create("Frame", {
        Size = UDim2.fromOffset(ballSize * 0.52, ballSize * 0.52),
        Position = UDim2.new(0.5, -ballSize * 0.26, 0.5, -ballSize * 0.26),
        BackgroundColor3 = Color3.fromRGB(200, 230, 60),
        Parent = self.Ball,
    })

    AddCorner(discMid, ballSize)

    local discCore = Create("Frame", {
        Size = UDim2.fromOffset(ballSize * 0.26, ballSize * 0.26),
        Position = UDim2.new(0.5, -ballSize * 0.13, 0.5, -ballSize * 0.13),
        BackgroundColor3 = Color3.fromRGB(240, 90, 40),
        Parent = self.Ball,
    })

    AddCorner(discCore, ballSize)

    local ballDrag = false
    local ballMoved = false
    local bStart = nil
    local bPos = nil

    self.Ball.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            ballDrag, ballMoved = true, false
            bStart = inp.Position
            bPos = self.Ball.Position
        end
    end)

    self.Ball.InputChanged:Connect(function(inp)
        if ballDrag and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
            local d = inp.Position - bStart

            if math.abs(d.X) + math.abs(d.Y) > 6 then
                ballMoved = true
            end

            if ballMoved then
                local nx = math.clamp(bPos.X.Offset + d.X, 0, vp.X - ballSize)
                local ny = math.clamp(bPos.Y.Offset + d.Y, 0, vp.Y - ballSize)

                self.Ball.Position = UDim2.fromOffset(nx, ny)
            end
        end
    end)

    self.Ball.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            ballDrag = false

            if not ballMoved then
                self:SetVisible(not self.UIVisible)
            end
        end
    end)
end

-------------------------------------------------
-- Avatar
-------------------------------------------------
function Lib:CenterAvatar(model)
    if model and model.PrimaryPart then
        model:PivotTo(CFrame.new(0, 0, 0) * CFrame.Angles(0, math.rad(180), 0))
    end
end

function Lib:LoadAvatar()
    if not self.AvatarWorld then
        return
    end

    taskSpawn(function()
        for _, c in ipairs(self.AvatarWorld:GetChildren()) do
            if c:IsA("Model") then
                c:Destroy()
            end
        end

        local ok3d, desc = pcall(function()
            return Players:GetHumanoidDescriptionFromUserId(LocalPlayer.UserId)
        end)

        if ok3d and desc then
            local okModel, model = pcall(function()
                return Players:CreateHumanoidModelFromDescription(desc, Enum.HumanoidRigType.R15)
            end)

            if okModel and model then
                model.Parent = self.AvatarWorld

                local root = model:WaitForChild("HumanoidRootPart", 3)
                if root then
                    root.Anchored = true
                    self:CenterAvatar(model)
                    self.AvatarImage.Visible = false
                    return
                end
            end
        end

        self.AvatarImage.Visible = true

        local okT, url = pcall(function()
            return Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.AvatarThumbnail, Enum.ThumbnailSize.Size420x420)
        end)

        if not okT or not url then
            okT, url = pcall(function()
                return Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
            end)
        end

        if okT and url then
            self.AvatarImage.Image = url
        end
    end)
end

-------------------------------------------------
-- Takeover / Handshake
-------------------------------------------------
function Lib:GetBrand()
    return self.Brand
end

function Lib:GetProtocol()
    return self.Protocol
end

function Lib:IsHostBrand(brand)
    return self.Brand == brand
end

function Lib:GetHandshakeToken(brand, protocol, salt)
    return HashStr(tostring(brand) .. "|" .. tostring(protocol) .. "|" .. tostring(self.Version) .. "|" .. tostring(salt or ""))
end

function Lib:Handshake(info)
    info = info or {}

    if info.Brand ~= self.Brand then
        return false, "brand_mismatch"
    end

    if info.Protocol and info.Protocol ~= self.Protocol then
        return false, "protocol_mismatch"
    end

    if info.Token then
        local expected = self:GetHandshakeToken(info.Brand, info.Protocol, info.Salt)
        if info.Token ~= expected then
            return false, "token_mismatch"
        end
    end

    return true, {
        Brand = self.Brand,
        Protocol = self.Protocol,
        Version = self.Version,
        Initialized = self.Initialized,
    }
end

function Lib:MountTakeoverTab(session, payload, spec)
    if type(spec) ~= "table" then
        return false, "tab_spec_invalid"
    end

    local catKey = spec.Category or spec.NewCategory or payload.Name or "External"
    local subKey = spec.Sub or spec.NewSub or "Main"

    local page, cat, subIdx = self:GetOrCreatePage(catKey, subKey)
    if not page then
        return false, "page_create_failed"
    end

    if payload.ReplaceConflicts == nil then
        payload.ReplaceConflicts = true
    end

    local shouldClear = false

    if spec.Mode == "Replace" or spec.Clear == true then
        shouldClear = true
    end

    if payload.ReplaceConflicts and spec.Mode ~= "Append" then
        shouldClear = true
    end

    if shouldClear then
        page:Clear()
        page.Scroll.Visible = true
    end

    page.Owner = session.Name

    if type(spec.Build) == "function" then
        local ok, err = pcall(spec.Build, page, self, session)

        if not ok then
            warn("[PremiumUI Takeover] Build error:", err)
            return false, "build_error"
        end
    end

    table.insert(session.Pages, page)

    if spec.Focus then
        for i, c in ipairs(self.Categories) do
            if c == cat then
                self:SelectCategory(i)
                self:SelectSub(subIdx)
                break
            end
        end
    end

    return true
end

function Lib:RequestTakeover(payload)
    if type(payload) ~= "table" then
        return false, "payload_invalid"
    end

    local ok, err = self:Handshake(payload)
    if not ok then
        return false, err
    end

    if not self.Initialized then
        return false, "ui_not_initialized"
    end

    local session = {
        Name = payload.Name or "ExternalScript",
        Pages = {},
        Active = true,
    }

    function session.Toast(_, msg)
        Lib:Toast(msg)
    end

    function session.Unmount(_)
        for _, p in ipairs(session.Pages) do
            pcall(function()
                p:Clear()
                p.Owner = nil
            end)
        end

        session.Active = false
    end

    for _, spec in ipairs(payload.Tabs or {}) do
        local mountOk, mountErr = self:MountTakeoverTab(session, payload, spec)

        if not mountOk then
            return false, mountErr
        end
    end

    table.insert(self.Takeover.Sessions, session)

    self:Toast(("Takeover: %s"):format(session.Name))

    return true, session
end

Lib.Takeover.Check = function(_, brand, protocol)
    return Lib.Brand == brand and (protocol == nil or protocol == Lib.Protocol)
end

Lib.Takeover.Request = function(_, payload)
    return Lib:RequestTakeover(payload)
end

-------------------------------------------------
-- Initialize
-------------------------------------------------
function Lib:ComputeScale()
    local cam = workspace.CurrentCamera
    local vp = (cam and cam.ViewportSize) or Vector2.new(1280, 720)

    if vp.X < 100 then
        vp = Vector2.new(1280, 720)
    end

    self.ViewportSize = vp
    self.UIScale = math.min(vp.X / 1280, vp.Y / 720)

    if self.UIScale <= 0 or self.UIScale ~= self.UIScale then
        self.UIScale = 1
    end
end

function Lib:Initialize(opts)
    if self.Initialized then
        return self
    end

    opts = opts or {}

    if opts.Brand then
        self.Brand = opts.Brand
    end

    if opts.Title then
        self.Options.Title = opts.Title
    end

    if opts.Subtitle then
        self.Options.Subtitle = opts.Subtitle
    end

    self:ComputeScale()

    local screen = Create("ScreenGui", {
        Name = "PremiumUI_SZE" .. math.random(10000, 99999),
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    })

    local okCore, CoreGuiService = pcall(function()
        return cloneref(game:GetService("CoreGui"))
    end)

    local pGui = (okCore and CoreGuiService) or (LocalPlayer and LocalPlayer:FindFirstChildOfClass("PlayerGui")) or game:GetService("CoreGui")
    screen.Parent = pGui

    self.ScreenGui = screen

    self.ToastHolder = Create("Frame", {
        Size = UDim2.fromOffset(S(300), S(160)),
        Position = UDim2.fromOffset((self.ViewportSize.X - S(300)) / 2, S(12)),
        BackgroundTransparency = 1,
        Parent = screen,
        ZIndex = 60,
    })

    Create("UIListLayout", {
        Padding = UDim.new(0, S(6)),
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
    }, self.ToastHolder)

    self.FPSLabel = Create("TextLabel", {
        Size = UDim2.fromOffset(S(90), S(26)),
        Position = UDim2.fromOffset(self.ViewportSize.X - S(98), S(8)),
        BackgroundColor3 = Color3.fromRGB(20, 20, 20),
        BackgroundTransparency = 0.3,
        Text = "FPS: --",
        TextColor3 = COL.White,
        TextSize = TS(13),
        Font = Enum.Font.GothamBold,
        Visible = false,
        Parent = screen,
        ZIndex = 55,
    })

    AddCorner(self.FPSLabel, S(6))

    self.Watermark = Create("TextLabel", {
        Size = UDim2.fromOffset(S(180), S(24)),
        Position = UDim2.fromOffset(S(8), S(8)),
        BackgroundTransparency = 1,
        Text = self.Options.Title .. " | " .. self.Options.Subtitle,
        TextColor3 = COL.White,
        TextSize = TS(12),
        Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left,
        Visible = false,
        Parent = screen,
        ZIndex = 55,
    })

    local M = {
        sideW = S(150),
        sidePad = S(6),
        sideBtnH = S(40),
        sideGap = S(6),
        mainW = S(640),
        mainH = S(520),
        rightW = S(170),
        rightH = S(420),
        gap = S(18),
        ballSize = S(56),
    }

    self.M = M

    local totalW = M.sideW + M.mainW + M.rightW + M.gap * 2
    local startX = (self.ViewportSize.X - totalW) / 2

    local defaultSideH = S(28) + M.sidePad + 4 * M.sideBtnH + 3 * M.sideGap + M.sidePad

    local sideY = (self.ViewportSize.Y - defaultSideH) / 2
    local mainY = (self.ViewportSize.Y - M.mainH) / 2
    local rightY = (self.ViewportSize.Y - M.rightH) / 2

    self.SideOuter = Create("Frame", {
        Size = UDim2.fromOffset(M.sideW, defaultSideH),
        Position = UDim2.fromOffset(startX, sideY),
        Visible = false,
        Parent = screen,
    })

    AddGlass(self.SideOuter)
    AddCorner(self.SideOuter, S(12))
    AddRainbowStroke(self.SideOuter, math.max(1, S(1.5)), true)
    Create("UIScale", { Scale = 1 }, self.SideOuter)

    self.SideIndicator = Create("Frame", {
        Size = UDim2.fromOffset(M.sideW - M.sidePad * 2, M.sideBtnH),
        Position = UDim2.fromOffset(M.sidePad, S(28) + M.sidePad),
        BackgroundColor3 = self.Theme.Button,
        BackgroundTransparency = 0.1,
        Parent = self.SideOuter,
        ZIndex = 1,
    })

    AddCorner(self.SideIndicator, S(8))
    table.insert(self.TR.ButtonsBg, self.SideIndicator)

    self.SideList = Create("Frame", {
        Size = UDim2.new(1, 0, 1, -S(28)),
        Position = UDim2.fromOffset(0, S(28)),
        BackgroundTransparency = 1,
        Parent = self.SideOuter,
        ZIndex = 2,
    })

    Create("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical,
        Padding = UDim.new(0, M.sideGap),
    }, self.SideList)

    Create("UIPadding", {
        PaddingTop = UDim.new(0, M.sidePad),
        PaddingLeft = UDim.new(0, M.sidePad),
        PaddingRight = UDim.new(0, M.sidePad),
    }, self.SideList)

    self.MainPanel = Create("Frame", {
        Size = UDim2.fromOffset(M.mainW, M.mainH),
        Position = UDim2.fromOffset(startX + M.sideW + M.gap, mainY),
        Visible = false,
        Parent = screen,
    })

    AddGlass(self.MainPanel)
    AddCorner(self.MainPanel, S(12))
    AddRainbowStroke(self.MainPanel, math.max(1, S(1.5)), true)
    Create("UIScale", { Scale = 1 }, self.MainPanel)

    self.CloseBtn = Create("TextButton", {
        Size = UDim2.fromOffset(S(26), S(26)),
        Position = UDim2.new(1, -S(32), 0, S(2)),
        BackgroundTransparency = 1,
        Text = "X",
        TextColor3 = COL.Red,
        TextSize = TS(15),
        Font = Enum.Font.GothamBold,
        AutoButtonColor = false,
        Parent = self.MainPanel,
        ZIndex = 5,
    })

    SafeClick(self.CloseBtn, function()
        self:SetVisible(false)
    end)

    self:MakeDragHandle(self.MainPanel, UDim2.new(1, -S(40), 0, S(28)), UDim2.fromOffset(S(4), 0))
    self:MakeDragHandle(self.SideOuter, UDim2.new(1, 0, 0, S(26)), UDim2.fromOffset(0, 0))

    self.TopOuter = Create("Frame", {
        Size = UDim2.new(1, -S(60), 0, S(44)),
        Position = UDim2.fromOffset(S(10), S(30)),
        BackgroundTransparency = 1,
        Parent = self.MainPanel,
    })

    self.TopIndicator = Create("Frame", {
        Size = UDim2.new(0.25, -S(10), 0, S(32)),
        Position = UDim2.new(0, S(5), 0, S(6)),
        BackgroundColor3 = self.Theme.Accent,
        Parent = self.TopOuter,
        ZIndex = 1,
    })

    AddCorner(self.TopIndicator, S(8))
    table.insert(self.TR.Accents, self.TopIndicator)

    self.TopList = Create("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Parent = self.TopOuter,
        ZIndex = 2,
    })

    Create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
    }, self.TopList)

    self.Divider = AddRainbowBar(self.MainPanel)
    self.Divider.Position = UDim2.fromOffset(S(10), S(74))
    self.Divider.Size = UDim2.new(1, -S(20), 0, math.max(1, S(2)))

    self.Clip = Create("Frame", {
        Size = UDim2.new(1, -S(20), 1, -S(86)),
        Position = UDim2.fromOffset(S(10), S(78)),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        Parent = self.MainPanel,
    })

    self.RightPanel = Create("Frame", {
        Size = UDim2.fromOffset(M.rightW, M.rightH),
        Position = UDim2.fromOffset(startX + M.sideW + M.gap + M.mainW + M.gap, rightY),
        Visible = false,
        Parent = screen,
    })

    AddGlass(self.RightPanel)
    AddCorner(self.RightPanel, S(12))
    AddRainbowStroke(self.RightPanel, math.max(1, S(1.5)), true)
    Create("UIScale", { Scale = 1 }, self.RightPanel)
    self:MakeDragHandle(self.RightPanel, UDim2.new(1, 0, 0, S(26)), UDim2.fromOffset(0, 0))

    self.AvatarImage = Create("ImageLabel", {
        Size = UDim2.new(1, -S(10), 1, -S(34)),
        Position = UDim2.fromOffset(S(5), S(28)),
        BackgroundTransparency = 1,
        ScaleType = Enum.ScaleType.Fit,
        Parent = self.RightPanel,
    })

    AddCorner(self.AvatarImage, S(8))

    self.AvatarViewport = Create("ViewportFrame", {
        Size = UDim2.new(1, -S(10), 1, -S(34)),
        Position = UDim2.fromOffset(S(5), S(28)),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        Parent = self.RightPanel,
    })

    AddCorner(self.AvatarViewport, S(8))

    self.AvatarViewport.LightColor = Color3.fromRGB(255, 255, 255)
    self.AvatarViewport.LightDirection = Vector3.new(0, -1, -0.4)
    self.AvatarViewport.Ambient = Color3.fromRGB(140, 140, 140)

    self.AvatarWorld = Instance.new("WorldModel")
    self.AvatarWorld.Parent = self.AvatarViewport

    self.AvatarCamera = Instance.new("Camera")
    self.AvatarCamera.FieldOfView = 40
    self.AvatarCamera.Parent = self.AvatarViewport
    self.AvatarViewport.CurrentCamera = self.AvatarCamera
    self.AvatarCamera.CFrame = CFrame.new(Vector3.new(0, -0.2, 11), Vector3.new(0, -0.2, 0))

    self:CreateBall()

    self.Panels = {
        self.SideOuter,
        self.MainPanel,
        self.RightPanel,
    }

    self.Initialized = true

    self:RefreshTheme()
    ExportGlobal()

    return self
end

-------------------------------------------------
-- Runtime services
-------------------------------------------------
RunService.RenderStepped:Connect(function()
    local rot = ((tick() - rainbowT0) * 24) % 360

    for _, g in ipairs(Lib.rainbowGrads) do
        if g and g.Parent then
            g.Rotation = rot
        end
    end
end)

UserInputService.InputChanged:Connect(function(inp)
    if panelDrag and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
        local d = inp.Position - panelDrag.start
        local f = panelDrag.frame

        local nx = math.clamp(panelDrag.orig.X.Offset + d.X, 0, math.max(0, Lib.ViewportSize.X - f.AbsoluteSize.X))
        local ny = math.clamp(panelDrag.orig.Y.Offset + d.Y, 0, math.max(0, Lib.ViewportSize.Y - f.AbsoluteSize.Y))

        f.Position = UDim2.fromOffset(nx, ny)
    end
end)

UserInputService.InputEnded:Connect(function(inp)
    if panelDrag and (inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch) then
        panelDrag = nil
    end
end)

UserInputService.InputBegan:Connect(function(inp)
    if openDropdown and openDropdown.Parent and (inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch) then
        local p = inp.Position
        local lp = openDropdown.AbsolutePosition
        local ls = openDropdown.AbsoluteSize

        if p.X < lp.X or p.X > lp.X + ls.X or p.Y < lp.Y or p.Y > lp.Y + ls.Y then
            CloseDropdown()
        end
    end
end)

local fpsFrames = 0
local fpsTime = 0

RunService.Heartbeat:Connect(function(dt)
    fpsFrames = fpsFrames + 1
    fpsTime = fpsTime + dt

    if fpsTime >= 0.5 then
        local fps = math.floor(fpsFrames / fpsTime)

        if Lib.FPSLabel and Lib.FPSLabel.Visible then
            Lib.FPSLabel.Text = "FPS: " .. fps
        end

        fpsFrames, fpsTime = 0, 0
    end
end)
-------------------------------------------------
-- GameBridge Protocol v2
-- 用于外部游戏脚本检测同品牌 UI 后接管组件
-------------------------------------------------

Lib.BridgeProtocol = 2

local BridgeMeta = {}
BridgeMeta.__index = BridgeMeta

local function NormalizeHost(host)
    if type(host) == "table" and host.__type == "page" then
        return host.Scroll
    end
    return host
end

function BridgeMeta:UsePage(category, sub, mode)
    local page, cat, subIdx = self.UI:GetOrCreatePage(category, sub)
    if not page then
        return false, "page_create_failed"
    end

    if mode ~= "Append" then
        page:Clear()
        page.Scroll.Visible = true
    end

    self.Page = page
    self.Category = cat
    self.SubIndex = subIdx
    self.Host = page

    return true
end

function BridgeMeta:Focus()
    if not self.Category then
        return
    end

    for i, c in ipairs(self.UI.Categories) do
        if c == self.Category then
            self.UI:SelectCategory(i)

            if self.SubIndex then
                self.UI:SelectSub(self.SubIndex)
            end

            break
        end
    end
end

function BridgeMeta:Grid(host)
    local target = host or self.Page

    if type(target) == "table" then
        if target.__type == "page" then
            target = target.Scroll
        elseif target.__type == "grid" then
            target = target:Add()
        end
    end

    local g = self.UI:Grid(target)
    self.Host = g

    return g
end

function BridgeMeta:UseGrid(grid)
    self.Host = grid
    return grid
end

function BridgeMeta:ResetHost()
    self.Host = self.Page
    return self.Page
end

function BridgeMeta:Create(comp)
    if type(comp) ~= "table" then
        return nil, "component_invalid"
    end

    local kind = comp.Type or comp.type or comp.Component or comp.component
    if not kind then
        return nil, "component_missing_type"
    end

    local host = NormalizeHost(comp.Host or self.Host or self.Page)

    local text = comp.Text or comp.text or comp.Title or comp.title or ""
    local cb = comp.Callback
        or comp.callback
        or comp.OnClick
        or comp.onClick
        or comp.OnChange
        or comp.onChange

    if kind == "Label" or kind == "Text" or kind == "Section" then
        local color = comp.Color or comp.color

        if kind == "Section" and not color then
            color = self.UI.Colors.Green
        end

        return self.UI:Label(host, text, color, comp.Size or comp.size)

    elseif kind == "Button" then
        return self.UI:Button(host, text, cb)

    elseif kind == "Toggle" then
        return self.UI:Toggle(
            host,
            text,
            comp.Default or comp.default or false,
            cb,
            comp.Register ~= false
        )

    elseif kind == "Slider" then
        local min = comp.Min or comp.min or 0
        local max = comp.Max or comp.max or 100
        local value = comp.Default or comp.default or comp.Value or comp.value or min

        return self.UI:Slider(host, text, min, max, value, cb)

    elseif kind == "Dropdown" then
        local opts = comp.Options or comp.options or {}
        local def = comp.Default or comp.default or opts[1]

        return self.UI:Dropdown(host, text, opts, def, cb)

    elseif kind == "TextBox" or kind == "Input" then
        return self.UI:TextBox(
            host,
            comp.Placeholder or comp.placeholder or text,
            comp.Default or comp.default or ""
        )

    elseif kind == "Grid" then
        return self:Grid(host)

    elseif kind == "Noop" or kind == "Spacer" then
        return true
    end

    return nil, "component_unknown:" .. tostring(kind)
end

function BridgeMeta:Label(text, opts)
    opts = opts or {}
    return self:Create({
        Type = "Label",
        Text = text,
        Color = opts.Color,
        Size = opts.Size,
        Host = opts.Host,
    })
end

function BridgeMeta:Section(text, opts)
    opts = opts or {}
    return self:Create({
        Type = "Section",
        Text = text,
        Color = opts.Color or self.UI.Colors.Green,
        Host = opts.Host,
    })
end

function BridgeMeta:Button(text, cb, opts)
    opts = opts or {}
    return self:Create({
        Type = "Button",
        Text = text,
        Callback = cb,
        Host = opts.Host,
    })
end

function BridgeMeta:Toggle(text, default, cb, opts)
    opts = opts or {}
    return self:Create({
        Type = "Toggle",
        Text = text,
        Default = default,
        Callback = cb,
        Register = opts.Register,
        Host = opts.Host,
    })
end

function BridgeMeta:Slider(text, min, max, default, cb, opts)
    opts = opts or {}
    return self:Create({
        Type = "Slider",
        Text = text,
        Min = min,
        Max = max,
        Default = default,
        Callback = cb,
        Host = opts.Host,
    })
end

function BridgeMeta:Dropdown(text, options, default, cb, opts)
    opts = opts or {}
    return self:Create({
        Type = "Dropdown",
        Text = text,
        Options = options,
        Default = default,
        Callback = cb,
        Host = opts.Host,
    })
end

function BridgeMeta:TextBox(placeholder, default, opts)
    opts = opts or {}
    return self:Create({
        Type = "TextBox",
        Placeholder = placeholder,
        Default = default,
        Host = opts.Host,
    })
end

function BridgeMeta:ClearPage()
    if self.Page then
        self.Page:Clear()
        self.Page.Scroll.Visible = true
    end
end

function BridgeMeta:Unmount()
    self:ClearPage()
    self.Active = false
end

function Lib:RequestGameBridge(payload)
    payload = payload or {}

    if payload.Brand ~= self.Brand then
        return false, "brand_mismatch"
    end

    if payload.Protocol and payload.Protocol ~= self.BridgeProtocol then
        return false, "protocol_mismatch"
    end

    if not self.Initialized then
        return false, "ui_not_initialized"
    end

    local category = payload.Category or payload.Name or "External Game"
    local sub = payload.Sub or "Main"

    local page, cat, subIdx = self:GetOrCreatePage(category, sub)
    if not page then
        return false, "page_create_failed"
    end

    if payload.Mode ~= "Append" then
        page:Clear()
        page.Scroll.Visible = true
    end

    local bridge = setmetatable({
        UI = self,
        Name = payload.Name or "GameScript",
        Page = page,
        Category = cat,
        SubIndex = subIdx,
        Host = page,
        Active = true,
        Protocol = self.BridgeProtocol,
    }, BridgeMeta)

    if payload.Focus then
        bridge:Focus()
    end

    table.insert(self.Takeover.Sessions, bridge)

    self:Toast(("GameBridge: %s"):format(bridge.Name))

    return true, bridge
end
return Lib
