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
    local why = "三个注册表全空：宿主未发布"
    
    while true do
        for _, src in ipairs(sources) do
            local ok, obj = pcall(src.get)
            if ok and type(obj) == "table" then 
                if obj.IsRealYoUI ~= true then 
                    why = "命中 " .. src.name .. " 但 IsRealYoUI=false"
                elseif obj.Brand ~= GAME.Brand then 
                    why = "命中 " .. src.name .. " 但品牌不符"
                elseif type(obj.RequestGameBridge) ~= "function" or type(obj.RenameMain) ~= "function" then 
                    why = "命中 " .. src.name .. " 但缺 API"
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
    local ok, success, bridgeOrErr = pcall(function()
        return HostUI:RequestGameBridge({
            Brand = GAME.Brand,
            Protocol = HostUI.BridgeProtocol or 2,
            Name = GAME.Name,
            -- ✅ 弹性协议字段：声明抢占 Info 页
            RequestedCategory = "Info", 
            Priority = 90,              
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
        print("[RealYoHub] bridge obtained, Mode=Host")
    else
        warn("[RealYoHub][ERR] RequestGameBridge: " .. tostring(ok and bridgeOrErr or success))
    end
end

if Runtime.Mode == "Host" then
    -- 重命名被接管后的 Info 页 (Index 1) 及其子标签
    SafeCall("RenameMain1", function() HostUI:RenameMain(1, "RealYoHub") end)
    SafeCall("RenameSub11", function() HostUI:RenameSub(1, 1, "Area 51") end)
    SafeCall("RenameSub12", function() HostUI:RenameSub(1, 2, "Gun Modded") end)
    SafeCall("RenameSub13", function() HostUI:RenameSub(1, 3, "Teleport") end)
    SafeCall("RenameSub14", function() HostUI:RenameSub(1, 4, "FE Tools") end)
end

local function Notify(title, content, duration, icon)
    if Runtime.Mode == "Host" and Runtime.Host and type(Runtime.Host.Toast) == "function" then
        pcall(function() Runtime.Host:Toast("[" .. title .. "] " .. tostring(content or "")) end)
    else
        pcall(function() Notifier.new({ Title = title, Content = content, Duration = duration or 5, Icon = icon or "info" }) end)
    end
end

local function BridgeAdapter(bridge)
    local A = { _b = bridge }
    function A:Section(t) return self._b:Section(t) end
    function A:Label(t) return self._b:Label(t) end
    function A:Button(t, cb) return self._b:Button(t, cb) end
    function A:Toggle(t, def, cb) return self._b:Toggle(t, def, cb) end
    function A:Slider(t, min, max, def, cb) return self._b:Slider(t, min, max, def, cb) end
    function A:Input(t, placeholder, cb)
        local box = self._b:TextBox(placeholder, "")
        if box then box:GetPropertyChangedSignal("Text"):Connect(function() cb(box.Text) end) end
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
    function A:Slider(t, min, max, def, cb) if self._t.Slider then self._t:Slider({ Title = t, Min = min, Max = max, Default = def, Callback = cb }) end end
    function A:Input(t, placeholder, cb) self._t:Input({ Title = t, Placeholder = placeholder, Callback = cb }) end
    return A
end

-- [此处省略 BuildArea51, BuildGunModded, BuildTeleport, BuildFETools 的具体实现代码，保持你原有的逻辑即可]
-- 为了节省空间，这里假设这些函数已经定义好，直接看底部的构建逻辑。
-- 如果你需要完整的函数代码，请保留你原文件中的 BuildArea51 等函数定义。

local function BuildArea51(A)
    -- ... (保留你原有的 Area51 功能代码) ...
    A:Button("Test Button Area51", function() Notify("Test", "Area51 Works") end)
end

local function BuildGunModded(A)
    -- ... (保留你原有的 GunModded 功能代码) ...
    A:Button("Test Button Gun", function() Notify("Test", "Gun Works") end)
end

local function BuildTeleport(A)
    -- ... (保留你原有的 Teleport 功能代码) ...
    A:Button("Test Button TP", function() Notify("Test", "TP Works") end)
end

local function BuildFETools(A)
    -- ... (保留你原有的 FETools 功能代码) ...
    A:Button("Test Button FE", function() Notify("Test", "FE Works") end)
end

if Runtime.Mode == "Host" then
    local bridge = Runtime.Bridge
    -- ✅ 构建到 Index 1 (原 Info 页) 的 4 个子页面
    SafeCall("Build Area51", function() bridge:UsePageIndex(1, 1, "Replace"); BuildArea51(BridgeAdapter(bridge)) end)
    SafeCall("Build GunModded", function() bridge:UsePageIndex(1, 2, "Replace"); BuildGunModded(BridgeAdapter(bridge)) end)
    SafeCall("Build Teleport", function() bridge:UsePageIndex(1, 3, "Replace"); BuildTeleport(BridgeAdapter(bridge)) end)
    SafeCall("Build FETools", function() bridge:UsePageIndex(1, 4, "Replace"); BuildFETools(BridgeAdapter(bridge)) end)
    SafeCall("Focus", function() bridge:Focus() end)
    Notify("RealYoHub", "Handshake OK - hosted by RealYoUI", 6, "crown")
else
    -- [保留你原有的 WindUI 回退逻辑]
    local okWind, WindUI = pcall(function() return loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))() end)
    if not okWind or type(WindUI) ~= "table" then warn("[RealYoHub][ERR] WindUI load failed: " .. tostring(WindUI)); return end
    -- ... (WindUI 初始化代码) ...
end
