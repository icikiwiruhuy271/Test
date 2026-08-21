-- Auto Parry Script for Violence District v8
-- Ultimate Optimized Version

local Player = game.Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

-- Configuration
local Config = {
    Enabled = false,
    DetectionRange = 12,
    ParryAnimationDuration = 2.0,
    ShowRangeCircle = true,
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
    ChaseRunevent = GetRemote({"Remotes", "Chase", "Runevent"}),
    UpdateCharacterLook = GetRemote({"Remotes", "Game", "UpdateCharacterLook"}),
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
local rangeCircle = nil
local uiElements = {}
local hitCooldown = 0
local isHitValid = false

-- Create Range Circle
local function CreateRangeCircle()
    if rangeCircle then
        rangeCircle:Destroy()
        rangeCircle = nil
    end
    
    if not Config.ShowRangeCircle then return end
    if not Character then return end
    
    local circleGroup = Instance.new("Model")
    circleGroup.Name = "ParryRangeCircle"
    circleGroup.Parent = Workspace
    
    local segments = 32
    local radius = Config.DetectionRange
    
    for i = 1, segments do
        local angle = (i / segments) * math.pi * 2
        local x = math.cos(angle) * radius
        local z = math.sin(angle) * radius
        
        local part = Instance.new("Part")
        part.Size = Vector3.new(0.3, 0.05, 0.3)
        part.Position = Vector3.new(x, 0.1, z)
        part.Anchored = true
        part.CanCollide = false
        part.Transparency = 0.7
        part.BrickColor = BrickColor.new("Bright blue")
        part.Material = Enum.Material.Neon
        part.Parent = circleGroup
    end
    
    rangeCircle = circleGroup
    
    RunService.Heartbeat:Connect(function()
        if not rangeCircle or not Character then 
            if rangeCircle then
                rangeCircle:Destroy()
                rangeCircle = nil
            end
            return 
        end
        
        local root = Character:FindFirstChild("HumanoidRootPart")
        if root then
            rangeCircle:SetPrimaryPartCFrame(CFrame.new(root.Position))
        end
    end)
end

-- Update Range Circle
local function UpdateRangeCircle()
    if rangeCircle then
        rangeCircle:Destroy()
        rangeCircle = nil
    end
    CreateRangeCircle()
end

-- Check if hit is valid (hit player body)
local function IsValidHit(killer)
    if not killer or not killer.Character then return false end
    
    local killerRoot = killer.Character:FindFirstChild("HumanoidRootPart")
    local playerRoot = Character:FindFirstChild("HumanoidRootPart")
    
    if not killerRoot or not playerRoot then return false end
    
    -- Check distance
    local dist = (killerRoot.Position - playerRoot.Position).Magnitude
    if dist > Config.DetectionRange then return false end
    
    -- Check if killer is facing player
    local lookVector = killerRoot.CFrame.LookVector
    local toPlayer = (playerRoot.Position - killerRoot.Position).Unit
    local dot = lookVector:Dot(toPlayer)
    
    -- Killer must be facing player (angle check)
    if dot < 0.3 then return false end
    
    -- Check if any body part is in range
    local bodyParts = {"Head", "Torso", "HumanoidRootPart", "LeftArm", "RightArm", "LeftLeg", "RightLeg"}
    for _, partName in ipairs(bodyParts) do
        local part = Character:FindFirstChild(partName)
        if part then
            local partDist = (killerRoot.Position - part.Position).Magnitude
            if partDist < 8 then -- 8 studs hit range
                return true
            end
        end
    end
    
    return false
end

-- Play Parry Animations (both)
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

-- Play Single Parry Animation (for wall hits)
local function PlaySingleParryAnimation()
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
    
    -- Play only first animation
    local anim = Instance.new("Animation")
    anim.AnimationId = PARRY_ANIMATIONS[1]
    local track = animator:LoadAnimation(anim)
    if track then
        track:Play()
        table.insert(parryAnimTracks, track)
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
            if IsKillerAttacking(player.Character) then
                local dist = (root.Position - player.Character.HumanoidRootPart.Position).Magnitude
                if dist < minDist then
                    minDist = dist
                    closest = player
                end
            end
        end
    end
    
    return closest
end

-- Main Parry Function
local function PerformParry(killer)
    if isParrying or isAnimPlaying or isCooldown then return end
    if not Config.Enabled then return end
    if not Character then return end
    
    -- Check if hit is valid
    local isValid = false
    local isWallHit = false
    
    if killer then
        isValid = IsValidHit(killer)
        if not isValid then
            isWallHit = true
        end
    end
    
    -- Chase Runevent
    if Remotes.ChaseRunevent then
        pcall(function()
            Remotes.ChaseRunevent:FireServer()
        end)
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
        
        -- Update character look
        if Remotes.UpdateCharacterLook then
            pcall(function()
                Remotes.UpdateCharacterLook:FireServer()
            end)
        end
        
        -- Play animations based on hit type
        local hasAnim = false
        if isValid then
            -- Valid hit: play both animations
            hasAnim = PlayParryAnimations()
        else
            -- Wall hit: play single animation
            hasAnim = PlaySingleParryAnimation()
        end
        
        if hasAnim then
            -- Disable movement
            local humanoid = Character:FindFirstChild("Humanoid")
            if humanoid then
                originalSpeed = humanoid.WalkSpeed
                originalJump = humanoid.JumpPower
                humanoid.WalkSpeed = 0
                humanoid.JumpPower = 0
            end
            
            -- Wait for animation
            if isValid then
                task.wait(Config.ParryAnimationDuration) -- 2 detik
            else
                task.wait(1.0) -- 1 detik untuk wall hit
            end
            
            -- Re-enable movement
            if humanoid then
                humanoid.WalkSpeed = originalSpeed
                humanoid.JumpPower = originalJump
            end
            
            -- Stop animations
            StopParryAnimations()
            
            -- Start cooldown (63 seconds)
            isCooldown = true
            
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
        
        -- Check for killer
        local killer = GetClosestKiller()
        if killer then
            PerformParry(killer)
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
                PerformParry(args[1])
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
                    PerformParry(args[1])
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
                PerformParry(attacker)
            end
        end)
    end
    
    -- Chase Runevent
    if Remotes.ChaseRunevent then
        Remotes.ChaseRunevent.OnClientEvent:Connect(function()
            if not Config.Enabled then return end
            if isParrying or isAnimPlaying or isCooldown then return end
            task.wait(0.05)
            -- Try to get killer from chase
            local killer = GetClosestKiller()
            if killer then
                PerformParry(killer)
            end
        end)
    end
end

-- Create UI with Range Input for Mobile
local function CreateUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "AutoParryUI"
    screenGui.Parent = Player.PlayerGui
    screenGui.ResetOnSpawn = false
    
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 240, 0, 200)
    mainFrame.Position = UDim2.new(0, 10, 0.5, -100)
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
    statusLabel.Size = UDim2.new(0.9, 0, 0, 22)
    statusLabel.Position = UDim2.new(0.05, 0, 0, 33)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = Config.Enabled and "🟢 ON" or "🔴 OFF"
    statusLabel.TextColor3 = Config.Enabled and Color3.fromRGB(0, 255, 100) or Color3.fromRGB(255, 50, 50)
    statusLabel.TextSize = 13
    statusLabel.Font = Enum.Font.GothamSemibold
    statusLabel.Parent = mainFrame
    
    -- Cooldown
    local cooldownLabel = Instance.new("TextLabel")
    cooldownLabel.Size = UDim2.new(0.9, 0, 0, 18)
    cooldownLabel.Position = UDim2.new(0.05, 0, 0, 57)
    cooldownLabel.BackgroundTransparency = 1
    cooldownLabel.Text = "⏱️ Ready"
    cooldownLabel.TextColor3 = Color3.fromRGB(100, 255, 150)
    cooldownLabel.TextSize = 11
    cooldownLabel.Font = Enum.Font.Gotham
    cooldownLabel.Parent = mainFrame
    
    -- Range Label
    local rangeLabel = Instance.new("TextLabel")
    rangeLabel.Size = UDim2.new(0.3, 0, 0, 22)
    rangeLabel.Position = UDim2.new(0.05, 0, 0, 78)
    rangeLabel.BackgroundTransparency = 1
    rangeLabel.Text = "Range:"
    rangeLabel.TextColor3 = Color3.fromRGB(200, 200, 255)
    rangeLabel.TextSize = 12
    rangeLabel.Font = Enum.Font.Gotham
    rangeLabel.Parent = mainFrame
    
    -- Range Input Box (for mobile)
    local rangeInput = Instance.new("TextBox")
    rangeInput.Size = UDim2.new(0.2, 0, 0, 22)
    rangeInput.Position = UDim2.new(0.35, 0, 0, 78)
    rangeInput.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
    rangeInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    rangeInput.Text = tostring(Config.DetectionRange)
    rangeInput.TextSize = 12
    rangeInput.Font = Enum.Font.Gotham
    rangeInput.TextXAlignment = Enum.TextXAlignment.Center
    rangeInput.PlaceholderText = "5-30"
    rangeInput.Parent = mainFrame
    
    local inputCorner = Instance.new("UICorner")
    inputCorner.CornerRadius = UDim.new(0, 4)
    inputCorner.Parent = rangeInput
    
    -- Range Slider (for PC)
    local sliderFrame = Instance.new("Frame")
    sliderFrame.Size = UDim2.new(0.35, 0, 0, 15)
    sliderFrame.Position = UDim2.new(0.58, 0, 0, 82)
    sliderFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
    sliderFrame.BorderSizePixel = 0
    sliderFrame.Parent = mainFrame
    
    local sliderCorner = Instance.new("UICorner")
    sliderCorner.CornerRadius = UDim.new(0, 8)
    sliderCorner.Parent = sliderFrame
    
    local sliderButton = Instance.new("TextButton")
    sliderButton.Size = UDim2.new(0, 20, 1, 0)
    sliderButton.Position = UDim2.new((Config.DetectionRange - 5) / 25, 0, 0, 0)
    sliderButton.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
    sliderButton.Text = ""
    sliderButton.BorderSizePixel = 0
    sliderButton.Parent = sliderFrame
    
    local sliderCorner2 = Instance.new("UICorner")
    sliderCorner2.CornerRadius = UDim.new(0, 8)
    sliderCorner2.Parent = sliderButton
    
    -- Range value display
    local rangeDisplay = Instance.new("TextLabel")
    rangeDisplay.Size = UDim2.new(0, 30, 0, 22)
    rangeDisplay.Position = UDim2.new(0.92, 0, 0, 78)
    rangeDisplay.BackgroundTransparency = 1
    rangeDisplay.Text = tostring(Config.DetectionRange)
    rangeDisplay.TextColor3 = Color3.fromRGB(100, 200, 255)
    rangeDisplay.TextSize = 12
    rangeDisplay.Font = Enum.Font.GothamBold
    rangeDisplay.Parent = mainFrame
    
    -- Toggle Button
    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(0.8, 0, 0, 30)
    toggleBtn.Position = UDim2.new(0.1, 0, 0, 155)
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
        rangeLabel = rangeLabel,
        rangeInput = rangeInput,
        rangeDisplay = rangeDisplay,
        sliderButton = sliderButton,
        sliderFrame = sliderFrame,
        toggleBtn = toggleBtn,
        screenGui = screenGui
    }
    
    -- Range Input function (for mobile)
    rangeInput.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            local newRange = tonumber(rangeInput.Text)
            if newRange and newRange >= 5 and newRange <= 30 then
                Config.DetectionRange = math.floor(newRange)
                rangeDisplay.Text = tostring(Config.DetectionRange)
                sliderButton.Position = UDim2.new((Config.DetectionRange - 5) / 25, 0, 0, 0)
                UpdateRangeCircle()
            else
                rangeInput.Text = tostring(Config.DetectionRange)
            end
        end
    end)
    
    -- Slider dragging (for PC)
    local isDragging = false
    
    local function UpdateRange(input)
        local sliderPos = input.Position.X - sliderFrame.AbsolutePosition.X
        local newPos = math.clamp(sliderPos / sliderFrame.AbsoluteSize.X, 0, 1)
        local newRange = math.floor(5 + (newPos * 25))
        newRange = math.clamp(newRange, 5, 30)
        
        Config.DetectionRange = newRange
        sliderButton.Position = UDim2.new(newPos, 0, 0, 0)
        rangeDisplay.Text = tostring(newRange)
        rangeInput.Text = tostring(newRange)
        
        UpdateRangeCircle()
    end
    
    sliderButton.MouseButton1Down:Connect(function()
        isDragging = true
    end)
    
    sliderButton.MouseButton1Up:Connect(function()
        isDragging = false
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if isDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            UpdateRange(input)
        end
    end)
    
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
            CreateRangeCircle()
        end
    end)
    
    -- Create range circle initially
    CreateRangeCircle()
end

-- Handle respawn
Player.CharacterAdded:Connect(function(newChar)
    Character = newChar
    isParrying = false
    isAnimPlaying = false
    isCooldown = false
    parryAnimTracks = {}
    task.wait(0.5)
    CreateRangeCircle()
end)

-- Keyboard shortcut
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.P then
        Config.Enabled = not Config.Enabled
        
        if uiElements.statusLabel then
            uiElements.statusLabel.Text = Config.Enabled and "🟢 ON" or "🔴 OFF"
            uiElements.statusLabel.TextColor3 = Config.Enabled and Color3.fromRGB(0, 255, 100) or Color3.fromRGB(255, 50, 50)
        end
        if uiElements.toggleBtn then
            uiElements.toggleBtn.Text = Config.Enabled and "Disable" or "Enable"
            uiElements.toggleBtn.BackgroundColor3 = Config.Enabled and Color3.fromRGB(0, 180, 80) or Color3.fromRGB(180, 40, 40)
        end
        
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
            CreateRangeCircle()
        end
    end
end)

-- Initialize
print("=== Auto Parry v8 - Ultimate Optimized ===")
print("Loading...")

CreateUI()
StartDetection()
SetupListeners()

print("✅ Loaded successfully!")
print("📌 Press P to toggle")
print("📌 Status: OFF (default)")
print("📌 Animations: 2 (Enten Skin)")
print("📌 Cooldown: 63 seconds")
print("📌 Range: Adjustable (5-30)")
print("📌 Valid Hit Detection: Enabled")
print("📌 Wall Hit: Single Animation")
print("📌 Body Hit: Both Animations")

-- Initial status
task.wait(1)
game:GetService("StarterGui"):SetCore("ChatMakeSystemMessage", {
    Text = "Auto Parry v8: OFF (Press P to enable)",
    Color = Color3.fromRGB(255, 200, 0)
})
