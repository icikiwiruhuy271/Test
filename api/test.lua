-- Auto Parry Script for Violence District v6
-- Optimized & Fixed Version

local Player = game.Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

-- Configuration
local Config = {
    Enabled = false,
    DetectionRange = 12,
    ParryAnimationDuration = 2.0, -- 2 detik
}

-- Parry Animations (Skin: Enten)
local PARRY_ANIMATIONS = {
    'rbxassetid://127096285501517',
    'rbxassetid://104952902180174',
}

-- Killer Attack Animations
local VD_ATTACK_ANIMS = {
    ['rbxassetid://78432063483146'] = true,
    ['rbxassetid://121216847022485'] = true,
    ['rbxassetid://74968262036854'] = true,
    ['rbxassetid://132817836308238'] = true,
    ['rbxassetid://82666958311998'] = true,
    ['rbxassetid://111920872708571'] = true,
    ['rbxassetid://106871536134254'] = true,
    ['rbxassetid://109402730355822'] = true,
    ['rbxassetid://130593238885843'] = true,
    ['rbxassetid://138720291317243'] = true,
    ['rbxassetid://139369275981139'] = true,
    ['rbxassetid://133963973694098'] = true,
    ['rbxassetid://78935059863801'] = true,
    ['rbxassetid://118907603246885'] = true,
    ['rbxassetid://135002183282873'] = true,
    ['rbxassetid://113255068724446'] = true,
    ['rbxassetid://129784271201071'] = true,
    ['rbxassetid://105374834496520'] = true,
    ['rbxassetid://117070354890871'] = true,
    ['rbxassetid://115244153053858'] = true,
    ['rbxassetid://110355011987939'] = true,
    ['rbxassetid://117042998468241'] = true,
    ['rbxassetid://122812055447896'] = true,
}

-- Remote Setup
local function GetRemote(path)
    local current = ReplicatedStorage
    for _, part in ipairs(path) do
        if not current then return nil end
        current = current:FindFirstChild(part)
    end
    return current
end

local Remotes = {
    Parry = GetRemote({"ParryClient"}),
    ParryResult = GetRemote({"ParryResult"}),
    ParryAnim = GetRemote({"parry"}),
    AnimControl = GetRemote({"AnimationControl"}),
    AnimHandler = GetRemote({"AnimationHandler"}),
    EmoteHandler = GetRemote({"Remotes", "EmoteHandler"}),
    ParryDagger = GetRemote({"Remotes", "Items", "Parrying Dagger", "parry"}),
    AttackEvent = GetRemote({"Remotes", "Remotes", "AttackEvent"}),
}

-- Attack Remotes
local AttackFolder = GetRemote({"Remotes", "Attack"})
local AttackRemotes = {}
if AttackFolder then
    for _, child in pairs(AttackFolder:GetChildren()) do
        if child:IsA("RemoteEvent") then
            AttackRemotes[child.Name] = child
        end
    end
end

-- Killes Remotes
local KillesFolder = GetRemote({"Remotes", "Killes"})
local KillesRemotes = {}
if KillesFolder then
    for _, child in pairs(KillesFolder:GetChildren()) do
        if child:IsA("RemoteEvent") then
            KillesRemotes[child.Name] = child
        end
    end
end

-- Variables
local isParrying = false
local isAnimPlaying = false
local isCooldown = false
local lastParryTime = 0
local parryAnimTracks = {}
local originalSpeed = 16
local originalJump = 50
local uiElements = {}

-- Debug
local function DebugLog(msg)
    -- Disable debug for performance
    -- print("[AutoParry]", msg)
end

-- Play Parry Animations
local function PlayParryAnimations()
    if not Character then return false end
    
    local humanoid = Character:FindFirstChild("Humanoid")
    if not humanoid then return false end
    
    local animator = humanoid:FindFirstChild("Animator")
    if not animator then return false end
    
    -- Clear old animations
    for _, track in pairs(parryAnimTracks) do
        if track and track.IsPlaying then
            track:Stop()
        end
    end
    parryAnimTracks = {}
    
    -- Play both animations
    local count = 0
    for _, animId in ipairs(PARRY_ANIMATIONS) do
        local anim = Instance.new("Animation")
        anim.AnimationId = animId
        local track = animator:LoadAnimation(anim)
        if track then
            track:Play()
            table.insert(parryAnimTracks, track)
            count = count + 1
        end
    end
    
    if count > 0 then
        isAnimPlaying = true
        return true
    end
    return false
end

-- Stop Parry Animations
local function StopParryAnimations()
    for _, track in pairs(parryAnimTracks) do
        if track and track.IsPlaying then
            track:Stop()
        end
    end
    parryAnimTracks = {}
    isAnimPlaying = false
end

-- Create Parry Effect
local function CreateParryEffect()
    if not Character or not Character:FindFirstChild("HumanoidRootPart") then return end
    
    local pos = Character.HumanoidRootPart.Position
    
    for i = 1, 2 do
        local ring = Instance.new("Part")
        ring.Size = Vector3.new(6 + (i * 3), 0.2, 6 + (i * 3))
        ring.Position = pos + Vector3.new(0, 0.3 + (i * 0.2), 0)
        ring.Anchored = true
        ring.CanCollide = false
        ring.Transparency = 0.5
        ring.BrickColor = BrickColor.new("Bright blue")
        ring.Material = Enum.Material.Neon
        ring.Parent = workspace
        
        task.spawn(function()
            for t = 0, 0.8, 0.05 do
                task.wait(0.05)
                local alpha = 1 - (t / 0.8)
                ring.Transparency = 0.3 + (0.7 * (1 - alpha))
                ring.Size = Vector3.new(
                    6 + (i * 3) + (t * 20),
                    0.2,
                    6 + (i * 3) + (t * 20)
                )
            end
            ring:Destroy()
        end)
    end
end

-- Check if killer is attacking
local function IsKillerAttacking(character)
    if not character then return false end
    
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then return false end
    
    local animator = humanoid:FindFirstChild("Animator")
    if not animator then return false end
    
    for _, track in pairs(animator:GetPlayingAnimationTracks()) do
        if VD_ATTACK_ANIMS[track.Animation.AnimationId] then
            return true
        end
    end
    
    return false
end

-- Get closest killer
local function GetClosestKiller()
    if not Character or not Character:FindFirstChild("HumanoidRootPart") then 
        return nil 
    end
    
    local root = Character.HumanoidRootPart
    local closest = nil
    local minDist = Config.DetectionRange
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= Player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local dist = (root.Position - player.Character.HumanoidRootPart.Position).Magnitude
            if dist < minDist and IsKillerAttacking(player.Character) then
                minDist = dist
                closest = player
            end
        end
    end
    
    return closest
end

-- Main Parry Function
local function PerformParry()
    if isParrying or isAnimPlaying or isCooldown then return end
    if not Config.Enabled then return end
    if not Character then return end
    
    -- Check game cooldown via ParryResult
    if Remotes.ParryResult then
        -- Try to detect cooldown from ParryResult
    end
    
    local parrySuccess = false
    
    -- Try all parry methods
    if Remotes.Parry then
        pcall(function()
            Remotes.Parry:FireServer()
            parrySuccess = true
        end)
    end
    
    if not parrySuccess and Remotes.ParryDagger then
        pcall(function()
            Remotes.ParryDagger:FireServer()
            parrySuccess = true
        end)
    end
    
    if not parrySuccess and Remotes.ParryAnim then
        pcall(function()
            Remotes.ParryAnim:FireServer()
            parrySuccess = true
        end)
    end
    
    if not parrySuccess and Remotes.AnimControl then
        pcall(function()
            Remotes.AnimControl:FireServer("Parry")
            parrySuccess = true
        end)
    end
    
    if parrySuccess then
        isParrying = true
        lastParryTime = tick()
        
        -- Stop emote
        if Remotes.EmoteHandler then
            pcall(function()
                Remotes.EmoteHandler:FireServer("StopEmote")
            end)
        end
        
        -- Play animations
        local hasAnim = PlayParryAnimations()
        
        if hasAnim then
            -- Disable movement
            local humanoid = Character:FindFirstChild("Humanoid")
            if humanoid then
                originalSpeed = humanoid.WalkSpeed
                originalJump = humanoid.JumpPower
                humanoid.WalkSpeed = 0
                humanoid.JumpPower = 0
            end
            
            -- Visual effect
            CreateParryEffect()
            
            -- Wait for animation
            task.wait(Config.ParryAnimationDuration)
            
            -- Re-enable movement
            if humanoid then
                humanoid.WalkSpeed = originalSpeed
                humanoid.JumpPower = originalJump
            end
            
            -- Stop animations
            StopParryAnimations()
            
            -- Start cooldown (63 seconds)
            isCooldown = true
            DebugLog("Cooldown started (63s)")
            
            -- Cooldown timer
            local cooldownTime = 63
            while cooldownTime > 0 do
                if not Config.Enabled then 
                    isCooldown = false
                    break 
                end
                task.wait(1)
                cooldownTime = cooldownTime - 1
                
                -- Update UI cooldown
                if uiElements.cooldownLabel then
                    uiElements.cooldownLabel.Text = "⏱️ " .. cooldownTime .. "s"
                end
            end
            
            isCooldown = false
            DebugLog("Cooldown finished")
            
            if uiElements.cooldownLabel then
                uiElements.cooldownLabel.Text = "⏱️ Ready"
            end
        end
        
        isParrying = false
    end
end

-- Detection Loop
local function StartDetection()
    RunService.Heartbeat:Connect(function()
        if not Config.Enabled then return end
        if isParrying or isAnimPlaying or isCooldown then return end
        if not Character or not Character.Parent then
            Character = Player.Character
            return
        end
        
        local humanoid = Character:FindFirstChild("Humanoid")
        if not humanoid or humanoid.Health <= 0 then return end
        
        -- Check for killer (even when moving)
        local killer = GetClosestKiller()
        if killer then
            PerformParry()
        end
    end)
end

-- Setup Remote Listeners
local function SetupListeners()
    -- Attack Remotes
    for name, remote in pairs(AttackRemotes) do
        remote.OnClientEvent:Connect(function(...)
            if not Config.Enabled then return end
            if isParrying or isAnimPlaying or isCooldown then return end
            
            local args = {...}
            if args[1] and type(args[1]) == "Instance" and args[1]:IsA("Player") and args[1] ~= Player then
                task.wait(0.05)
                PerformParry()
            end
        end)
    end
    
    -- Killes Remotes
    for name, remote in pairs(KillesRemotes) do
        if remote:IsA("RemoteEvent") then
            remote.OnClientEvent:Connect(function(...)
                if not Config.Enabled then return end
                if isParrying or isAnimPlaying or isCooldown then return end
                
                local args = {...}
                if args[1] and type(args[1]) == "Instance" and args[1]:IsA("Player") and args[1] ~= Player then
                    task.wait(0.05)
                    PerformParry()
                end
            end)
        end
    end
    
    -- AttackEvent
    if Remotes.AttackEvent then
        Remotes.AttackEvent.OnClientEvent:Connect(function(attacker)
            if not Config.Enabled then return end
            if attacker == Player then return end
            if isParrying or isAnimPlaying or isCooldown then return end
            
            if attacker and attacker:IsA("Player") then
                task.wait(0.05)
                PerformParry()
            end
        end)
    end
end

-- Create Simple UI (No drag)
local function CreateUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "AutoParryUI"
    screenGui.Parent = Player.PlayerGui
    screenGui.ResetOnSpawn = false
    
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 200, 0, 130)
    mainFrame.Position = UDim2.new(0, 10, 0.5, -65)
    mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 35)
    mainFrame.BackgroundTransparency = 0.1
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = screenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = mainFrame
    
    -- Border
    local border = Instance.new("Frame")
    border.Size = UDim2.new(1, 0, 1, 0)
    border.BackgroundTransparency = 1
    border.BorderSizePixel = 1
    border.BorderColor3 = Color3.fromRGB(60, 60, 100)
    border.Parent = mainFrame
    local borderCorner = Instance.new("UICorner")
    borderCorner.CornerRadius = UDim.new(0, 10)
    borderCorner.Parent = border
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 30)
    title.Position = UDim2.new(0, 0, 0, 0)
    title.BackgroundColor3 = Color3.fromRGB(40, 40, 70)
    title.BackgroundTransparency = 0.3
    title.Text = "⚔️ Auto Parry [Enten]"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextSize = 14
    title.Font = Enum.Font.GothamBold
    title.Parent = mainFrame
    
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 10)
    titleCorner.Parent = title
    
    -- Status
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Size = UDim2.new(0.9, 0, 0, 25)
    statusLabel.Position = UDim2.new(0.05, 0, 0, 35)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = Config.Enabled and "🟢 ON" or "🔴 OFF"
    statusLabel.TextColor3 = Config.Enabled and Color3.fromRGB(0, 255, 100) or Color3.fromRGB(255, 50, 50)
    statusLabel.TextSize = 14
    statusLabel.Font = Enum.Font.GothamSemibold
    statusLabel.Parent = mainFrame
    
    -- Cooldown
    local cooldownLabel = Instance.new("TextLabel")
    cooldownLabel.Size = UDim2.new(0.9, 0, 0, 20)
    cooldownLabel.Position = UDim2.new(0.05, 0, 0, 62)
    cooldownLabel.BackgroundTransparency = 1
    cooldownLabel.Text = "⏱️ Ready"
    cooldownLabel.TextColor3 = Color3.fromRGB(100, 255, 150)
    cooldownLabel.TextSize = 12
    cooldownLabel.Font = Enum.Font.Gotham
    cooldownLabel.Parent = mainFrame
    
    -- Toggle Button
    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(0.8, 0, 0, 30)
    toggleBtn.Position = UDim2.new(0.1, 0, 0, 88)
    toggleBtn.BackgroundColor3 = Config.Enabled and Color3.fromRGB(0, 180, 80) or Color3.fromRGB(180, 40, 40)
    toggleBtn.Text = Config.Enabled and "Disable" or "Enable"
    toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleBtn.TextSize = 13
    toggleBtn.Font = Enum.Font.Gotham
    toggleBtn.Parent = mainFrame
    
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 6)
    btnCorner.Parent = toggleBtn
    
    -- Store UI elements
    uiElements = {
        mainFrame = mainFrame,
        statusLabel = statusLabel,
        cooldownLabel = cooldownLabel,
        toggleBtn = toggleBtn,
        screenGui = screenGui
    }
    
    -- Toggle function
    toggleBtn.MouseButton1Click:Connect(function()
        Config.Enabled = not Config.Enabled
        
        statusLabel.Text = Config.Enabled and "🟢 ON" or "🔴 OFF"
        statusLabel.TextColor3 = Config.Enabled and Color3.fromRGB(0, 255, 100) or Color3.fromRGB(255, 50, 50)
        toggleBtn.Text = Config.Enabled and "Disable" or "Enable"
        toggleBtn.BackgroundColor3 = Config.Enabled and Color3.fromRGB(0, 180, 80) or Color3.fromRGB(180, 40, 40)
        
        if not Config.Enabled then
            isParrying = false
            isCooldown = false
            isAnimPlaying = false
            StopParryAnimations()
            if uiElements.cooldownLabel then
                uiElements.cooldownLabel.Text = "⏱️ Disabled"
            end
        else
            if uiElements.cooldownLabel then
                uiElements.cooldownLabel.Text = "⏱️ Ready"
            end
        end
    end)
end

-- Handle respawn
Player.CharacterAdded:Connect(function(newChar)
    Character = newChar
    isParrying = false
    isAnimPlaying = false
    isCooldown = false
    parryAnimTracks = {}
    task.wait(0.5)
end)

-- Initialize
print("=== Auto Parry v6 - Optimized ===")
print("Loading...")

CreateUI()
StartDetection()
SetupListeners()

print("✅ Loaded successfully!")
print("📌 Press P to toggle")
print("📌 Status: OFF (default)")
print("📌 Animations: 2 (Enten Skin)")
print("📌 Cooldown: 63 seconds")
print("📌 Range: 12")

-- Initial status
task.wait(1)
game:GetService("StarterGui"):SetCore("ChatMakeSystemMessage", {
    Text = "Auto Parry v6: OFF (Press P to enable)",
    Color = Color3.fromRGB(255, 200, 0)
})
