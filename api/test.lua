-- Auto Parry Script for Violence District v5
-- Created for Roblox Violence District

local Player = game.Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Configuration
local Config = {
    Enabled = false, -- Default OFF
    ParryDelay = 0.05,
    DetectionRange = 12, -- Detection range 12
    ShowDebug = true,
    AutoParryKey = Enum.KeyCode.P,
    ParryCooldown = 63, -- 1 menit 3 detik
    ParryAnimationDuration = 3.0,
}

-- Animation IDs for parry (Skin: Enten)
local PARRY_ANIMATIONS = {
    ['rbxassetid://127096285501517'] = true,  -- Parry animation 1
    ['rbxassetid://104952902180174'] = true,  -- Parry animation 2
}

-- Animation IDs for killer attacks
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

-- Remote Events & Functions
local Remotes = {
    Attack = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("Attack"),
    Generator = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("Generator"),
    Killes = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("Killes"),
    RemotesFolder = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("Remotes"),
    Parry = ReplicatedStorage:FindFirstChild("ParryClient"),
    ParryResult = ReplicatedStorage:FindFirstChild("ParryResult"),
    ParryAnimation = ReplicatedStorage:FindFirstChild("parry"),
    AnimationControl = ReplicatedStorage:FindFirstChild("AnimationControl"),
    AnimationHandler = ReplicatedStorage:FindFirstChild("AnimationHandler"),
    ParryingDagger = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("Items") and ReplicatedStorage.Remotes.Items:FindFirstChild("Parrying Dagger"),
    EmoteHandler = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("EmoteHandler"),
}

-- Get specific remotes from folders
local function GetRemoteFromFolder(folder, remoteName)
    if not folder then return nil end
    for _, child in pairs(folder:GetChildren()) do
        if child.Name == remoteName then
            return child
        end
    end
    return nil
end

-- Attack remotes
local AttackRemotes = {
    AfterAttack = Remotes.Attack and GetRemoteFromFolder(Remotes.Attack, "AfterAttack"),
    BasicAttack = Remotes.Attack and GetRemoteFromFolder(Remotes.Attack, "BasicAttack"),
    Lunge = Remotes.Attack and GetRemoteFromFolder(Remotes.Attack, "Lunge"),
    LungeDetect = Remotes.Attack and GetRemoteFromFolder(Remotes.Attack, "LungeDetect"),
    TrailEvent = Remotes.Attack and GetRemoteFromFolder(Remotes.Attack, "TrailEvent"),
    hit = Remotes.Attack and GetRemoteFromFolder(Remotes.Attack, "hit"),
}

-- Killes remotes
local KillesRemotes = {
    Damage = Remotes.Killes and GetRemoteFromFolder(Remotes.Killes, "Damage"),
    DamageDone = Remotes.Killes and GetRemoteFromFolder(Remotes.Killes, "DamageDone"),
    Damageviz = Remotes.Killes and GetRemoteFromFolder(Remotes.Killes, "Damageviz"),
    Highlightbindable = Remotes.Killes and GetRemoteFromFolder(Remotes.Killes, "Highlightbindable"),
    Highlightremote = Remotes.Killes and GetRemoteFromFolder(Remotes.Killes, "Highlightremote"),
    Instinct = Remotes.Killes and GetRemoteFromFolder(Remotes.Killes, "Instinct"),
    Revealed = Remotes.Killes and GetRemoteFromFolder(Remotes.Killes, "Revealed"),
    SetAction = Remotes.Killes and GetRemoteFromFolder(Remotes.Killes, "SetAction"),
    SlowAttack = Remotes.Killes and GetRemoteFromFolder(Remotes.Killes, "SlowAttack"),
    Startmori = Remotes.Killes and GetRemoteFromFolder(Remotes.Killes, "Startmori"),
    Stunned = Remotes.Killes and GetRemoteFromFolder(Remotes.Killes, "Stunned"),
}

-- Parrying Dagger item remotes
local ParryingDaggerRemotes = {}
if Remotes.ParryingDagger then
    for _, child in pairs(Remotes.ParryingDagger:GetChildren()) do
        ParryingDaggerRemotes[child.Name] = child
    end
end

-- Variables
local isParrying = false
local lastParryTime = 0
local UI = nil
local isParryAnimPlaying = false
local parryAnimTracks = {} -- Store both animation tracks
local originalWalkSpeed = 16
local originalJumpPower = 50
local parryCount = 0
local isCooldownActive = false

-- Debug function
local function DebugLog(...)
    if Config.ShowDebug then
        print("[AutoParry]", ...)
    end
end

-- Play Both Parry Animations
local function PlayParryAnimations()
    if not Character then return false end
    
    local humanoid = Character:FindFirstChild("Humanoid")
    if not humanoid then return false end
    
    local animator = humanoid:FindFirstChild("Animator")
    if not animator then return false end
    
    -- Stop any existing parry animations
    for _, track in pairs(parryAnimTracks) do
        if track and track.IsPlaying then
            track:Stop()
        end
    end
    parryAnimTracks = {}
    
    -- Play both animations
    local successCount = 0
    for animId, _ in pairs(PARRY_ANIMATIONS) do
        local success, anim = pcall(function()
            return Instance.new("Animation")
        end)
        
        if success and anim then
            anim.AnimationId = animId
            local track = animator:LoadAnimation(anim)
            if track then
                track:Play()
                table.insert(parryAnimTracks, track)
                successCount = successCount + 1
                DebugLog("Playing parry animation: " .. animId)
            end
        end
    end
    
    if successCount > 0 then
        isParryAnimPlaying = true
        DebugLog("Both parry animations playing! (" .. successCount .. " animations)")
        return true
    else
        DebugLog("Failed to load parry animations!")
        return false
    end
end

-- Stop Parry Animations
local function StopParryAnimations()
    for _, track in pairs(parryAnimTracks) do
        if track and track.IsPlaying then
            track:Stop()
        end
    end
    parryAnimTracks = {}
    isParryAnimPlaying = false
    DebugLog("Parry animations stopped")
end

-- Create visual effect for parry
local function CreateParryEffect()
    if not Character or not Character:FindFirstChild("HumanoidRootPart") then return end
    
    local rootPart = Character.HumanoidRootPart
    local position = rootPart.Position
    
    -- Create multiple rings
    for i = 1, 3 do
        local ring = Instance.new("Part")
        ring.Size = Vector3.new(6 + (i * 2), 0.2, 6 + (i * 2))
        ring.Position = position + Vector3.new(0, 0.3 + (i * 0.2), 0)
        ring.Anchored = true
        ring.CanCollide = false
        ring.Transparency = 0.4 + (i * 0.1)
        ring.BrickColor = BrickColor.new("Bright blue")
        ring.Material = Enum.Material.Neon
        ring.Parent = workspace
        
        -- Fade out
        local startTime = tick()
        local duration = 0.8
        
        game:GetService("RunService").Heartbeat:Connect(function()
            local elapsed = tick() - startTime
            if elapsed >= duration then
                ring:Destroy()
                return
            end
            
            local alpha = 1 - (elapsed / duration)
            ring.Transparency = 0.4 + (0.6 * (1 - alpha))
            ring.Size = Vector3.new(
                6 + (i * 2) + (elapsed * 15),
                0.2,
                6 + (i * 2) + (elapsed * 15)
            )
        end)
    end
    
    DebugLog("Parry visual effects created")
end

-- Perform Parry with Animation
local function PerformParry()
    if isParrying then return end
    if not Config.Enabled then return end
    if isParryAnimPlaying then return end
    if isCooldownActive then return end
    
    local currentTime = tick()
    if currentTime - lastParryTime < Config.ParryCooldown then return end
    
    -- Try multiple parry methods
    local parrySuccess = false
    
    -- Method 1: ParryClient
    if Remotes.Parry then
        pcall(function()
            Remotes.Parry:FireServer()
            parrySuccess = true
            DebugLog("Parry via ParryClient")
        end)
    end
    
    -- Method 2: Parry from Parrying Dagger
    if not parrySuccess and ParryingDaggerRemotes.parry then
        pcall(function()
            ParryingDaggerRemotes.parry:FireServer()
            parrySuccess = true
            DebugLog("Parry via ParryingDagger.parry")
        end)
    end
    
    -- Method 3: parry remote
    if not parrySuccess and Remotes.ParryAnimation then
        pcall(function()
            Remotes.ParryAnimation:FireServer()
            parrySuccess = true
            DebugLog("Parry via parry")
        end)
    end
    
    -- Method 4: AnimationControl
    if not parrySuccess and Remotes.AnimationControl then
        pcall(function()
            Remotes.AnimationControl:FireServer("Parry")
            parrySuccess = true
            DebugLog("Parry via AnimationControl")
        end)
    end
    
    if parrySuccess then
        isParrying = true
        lastParryTime = currentTime
        parryCount = parryCount + 1
        
        -- Stop emote if needed
        if Remotes.EmoteHandler then
            pcall(function()
                Remotes.EmoteHandler:FireServer("StopEmote")
            end)
        end
        
        -- Play both parry animations
        local animSuccess = PlayParryAnimations()
        
        if animSuccess then
            -- Disable movement during parry animation
            local humanoid = Character:FindFirstChild("Humanoid")
            if humanoid then
                originalWalkSpeed = humanoid.WalkSpeed
                originalJumpPower = humanoid.JumpPower
                humanoid.WalkSpeed = 0
                humanoid.JumpPower = 0
                DebugLog("Movement disabled during parry (3 seconds)")
            end
            
            DebugLog("✅ Parry executed successfully! (Cooldown: 63 seconds)")
            
            -- Create visual effect
            CreateParryEffect()
            
            -- Schedule animation stop after 3 seconds
            task.wait(Config.ParryAnimationDuration)
            
            -- Stop animation and re-enable movement
            StopParryAnimations()
            if humanoid then
                humanoid.WalkSpeed = originalWalkSpeed
                humanoid.JumpPower = originalJumpPower
                DebugLog("Movement re-enabled")
            end
            
            -- Start cooldown
            isCooldownActive = true
            DebugLog("Cooldown started: 63 seconds")
            
            -- Cooldown countdown
            local remainingTime = Config.ParryCooldown
            while remainingTime > 0 do
                if not Config.Enabled then break end
                task.wait(1)
                remainingTime = remainingTime - 1
                if remainingTime % 5 == 0 then
                    DebugLog("Cooldown remaining: " .. remainingTime .. " seconds")
                end
            end
            
            isCooldownActive = false
            DebugLog("Cooldown finished!")
            
            isParrying = false
        else
            isParrying = false
        end
    else
        DebugLog("❌ No parry remote found!")
    end
end

-- Check if character is attacking via animation
local function IsCharacterAttacking(character)
    if not character then return false end
    
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then return false end
    
    local animator = humanoid:FindFirstChild("Animator")
    if not animator then return false end
    
    local tracks = animator:GetPlayingAnimationTracks()
    for _, track in pairs(tracks) do
        local animId = track.Animation.AnimationId
        if VD_ATTACK_ANIMS[animId] then
            return true
        end
    end
    
    return false
end

-- Get closest attacking killer
local function GetClosestKiller()
    if not Character or not Character:FindFirstChild("HumanoidRootPart") then 
        return nil 
    end
    
    local rootPart = Character.HumanoidRootPart
    local closestKiller = nil
    local closestDistance = Config.DetectionRange
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= Player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local killerRoot = player.Character.HumanoidRootPart
            local distance = (rootPart.Position - killerRoot.Position).Magnitude
            
            if distance < closestDistance then
                if IsCharacterAttacking(player.Character) then
                    closestDistance = distance
                    closestKiller = player
                end
            end
        end
    end
    
    return closestKiller
end

-- Main detection loop - FIXED for moving
local function StartAutoParry()
    RunService.Heartbeat:Connect(function()
        if not Config.Enabled then return end
        if not Character or not Character.Parent then
            Character = Player.Character
            return
        end
        
        -- Check if player is alive
        local humanoid = Character:FindFirstChild("Humanoid")
        if not humanoid or humanoid.Health <= 0 then
            return
        end
        
        -- Skip if parry animation is playing
        if isParryAnimPlaying then return end
        if isCooldownActive then return end
        
        -- Always check for killer attacks (even when moving)
        local killer = GetClosestKiller()
        if killer then
            PerformParry()
        end
    end)
end

-- Setup ALL attack remote listeners
local function SetupAllAttackListeners()
    -- Listen to all attack remotes
    for remoteName, remote in pairs(AttackRemotes) do
        if remote and remote:IsA("RemoteEvent") then
            remote.OnClientEvent:Connect(function(...)
                if not Config.Enabled then return end
                if isParryAnimPlaying then return end
                if isCooldownActive then return end
                
                local args = {...}
                if args[1] and type(args[1]) == "Instance" then
                    if args[1]:IsA("Player") and args[1] ~= Player then
                        DebugLog("Attack detected: " .. remoteName .. " from: " .. args[1].Name)
                        task.wait(Config.ParryDelay)
                        PerformParry()
                    end
                else
                    DebugLog("Attack detected: " .. remoteName .. " (no player info)")
                    task.wait(Config.ParryDelay)
                    PerformParry()
                end
            end)
        end
    end
    
    -- Listen to Killes remotes
    for remoteName, remote in pairs(KillesRemotes) do
        if remote and remote:IsA("RemoteEvent") then
            remote.OnClientEvent:Connect(function(...)
                if not Config.Enabled then return end
                if isParryAnimPlaying then return end
                if isCooldownActive then return end
                
                local args = {...}
                if args[1] and type(args[1]) == "Instance" then
                    if args[1]:IsA("Player") and args[1] ~= Player then
                        DebugLog("Killes event: " .. remoteName .. " from: " .. args[1].Name)
                        task.wait(Config.ParryDelay)
                        PerformParry()
                    end
                end
            end)
        end
    end
    
    -- Listen to AttackEvent
    if Remotes.RemotesFolder then
        local attackEvent = Remotes.RemotesFolder:FindFirstChild("AttackEvent")
        if attackEvent then
            attackEvent.OnClientEvent:Connect(function(attacker, data)
                if not Config.Enabled then return end
                if attacker == Player then return end
                if isParryAnimPlaying then return end
                if isCooldownActive then return end
                
                if attacker and attacker:IsA("Player") then
                    DebugLog("AttackEvent from: " .. attacker.Name)
                    task.wait(Config.ParryDelay)
                    PerformParry()
                end
            end)
        end
    end
    
    DebugLog("All attack listeners setup complete!")
end

-- Check all remotes
local function CheckAllRemotes()
    DebugLog("=== Remote Check ===")
    DebugLog("Attack folder: " .. tostring(Remotes.Attack ~= nil))
    DebugLog("Generator folder: " .. tostring(Remotes.Generator ~= nil))
    DebugLog("Killes folder: " .. tostring(Remotes.Killes ~= nil))
    DebugLog("Remotes folder: " .. tostring(Remotes.RemotesFolder ~= nil))
    DebugLog("ParryClient: " .. tostring(Remotes.Parry ~= nil))
    DebugLog("ParryResult: " .. tostring(Remotes.ParryResult ~= nil))
    DebugLog("parry: " .. tostring(Remotes.ParryAnimation ~= nil))
    DebugLog("AnimationControl: " .. tostring(Remotes.AnimationControl ~= nil))
    DebugLog("AnimationHandler: " .. tostring(Remotes.AnimationHandler ~= nil))
    DebugLog("Parrying Dagger: " .. tostring(Remotes.ParryingDagger ~= nil))
    DebugLog("ParryingDagger.parry: " .. tostring(ParryingDaggerRemotes.parry ~= nil))
    DebugLog("EmoteHandler: " .. tostring(Remotes.EmoteHandler ~= nil))
    DebugLog("=========================")
    
    return true
end

-- Keyboard shortcut
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Config.AutoParryKey then
        Config.Enabled = not Config.Enabled
        
        -- Update UI
        local ui = Player.PlayerGui:FindFirstChild("AutoParryUI")
        if ui then
            local mainFrame = ui:FindFirstChild("MainFrame")
            if mainFrame then
                local statusLabel = mainFrame:FindFirstChild("StatusContainer") and mainFrame.StatusContainer:FindFirstChild("StatusLabel")
                local toggleButton = mainFrame:FindFirstChild("ButtonsContainer") and mainFrame.ButtonsContainer:FindFirstChild("ToggleButton")
                local statusGlow = mainFrame:FindFirstChild("StatusContainer") and mainFrame.StatusContainer:FindFirstChild("StatusGlow")
                local cooldownLabel = mainFrame:FindFirstChild("CooldownLabel")
                
                if statusLabel then
                    statusLabel.Text = Config.Enabled and "🟢 Status: ON" or "🔴 Status: OFF"
                    statusLabel.TextColor3 = Config.Enabled and Color3.fromRGB(0, 255, 100) or Color3.fromRGB(255, 50, 50)
                end
                if toggleButton then
                    toggleButton.Text = Config.Enabled and "✕ Disable" or "✓ Enable"
                    toggleButton.BackgroundColor3 = Config.Enabled and Color3.fromRGB(0, 180, 80) or Color3.fromRGB(180, 40, 40)
                end
                if statusGlow then
                    statusGlow.BackgroundColor3 = Config.Enabled and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
                end
                if cooldownLabel then
                    cooldownLabel.Text = "⏱️ Cooldown: " .. (Config.Enabled and "Ready" or "Disabled")
                end
            end
        end
        
        game:GetService("StarterGui"):SetCore("ChatMakeSystemMessage", {
            Text = "Auto Parry: " .. (Config.Enabled and "Enabled ✅" or "Disabled ❌"),
            Color = Config.Enabled and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
        })
    end
end)

-- Handle character respawn
Player.CharacterAdded:Connect(function(newCharacter)
    Character = newCharacter
    isParrying = false
    isParryAnimPlaying = false
    isCooldownActive = false
    parryAnimTracks = {}
    task.wait(1)
end)

-- UI Creation - FIXED for mobile drag
local function CreateUI()
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "AutoParryUI"
    ScreenGui.Parent = Player.PlayerGui
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    local MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.new(0, 220, 0, 150)
    MainFrame.Position = UDim2.new(0, 10, 0.5, -75)
    MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
    MainFrame.BackgroundTransparency = 0.15
    MainFrame.BorderSizePixel = 0
    MainFrame.ClipsDescendants = true
    MainFrame.Parent = ScreenGui
    
    -- Shadow
    local Shadow = Instance.new("Frame")
    Shadow.Size = UDim2.new(1, 10, 1, 10)
    Shadow.Position = UDim2.new(0, -5, 0, -5)
    Shadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    Shadow.BackgroundTransparency = 0.5
    Shadow.BorderSizePixel = 0
    Shadow.Parent = MainFrame
    
    -- Gradient
    local Gradient = Instance.new("UIGradient")
    Gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(25, 25, 40)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(15, 15, 30))
    })
    Gradient.Rotation = 45
    Gradient.Parent = MainFrame
    
    -- Corner
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 12)
    Corner.Parent = MainFrame
    
    -- Border
    local Border = Instance.new("Frame")
    Border.Size = UDim2.new(1, 0, 1, 0)
    Border.Position = UDim2.new(0, 0, 0, 0)
    Border.BackgroundTransparency = 1
    Border.BorderSizePixel = 1
    Border.BorderColor3 = Color3.fromRGB(60, 60, 100)
    Border.Parent = MainFrame
    local BorderCorner = Instance.new("UICorner")
    BorderCorner.CornerRadius = UDim.new(0, 12)
    BorderCorner.Parent = Border
    
    -- Drag Handle (entire top area for mobile)
    local DragHandle = Instance.new("Frame")
    DragHandle.Size = UDim2.new(1, 0, 0, 35)
    DragHandle.Position = UDim2.new(0, 0, 0, 0)
    DragHandle.BackgroundColor3 = Color3.fromRGB(40, 40, 70)
    DragHandle.BackgroundTransparency = 0.3
    DragHandle.BorderSizePixel = 0
    DragHandle.Parent = MainFrame
    local DragCorner = Instance.new("UICorner")
    DragCorner.CornerRadius = UDim.new(0, 12)
    DragCorner.Parent = DragHandle
    
    -- Title with skin name
    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, -60, 1, 0)
    Title.Position = UDim2.new(0, 10, 0, 0)
    Title.BackgroundTransparency = 1
    Title.Text = "⚔️ Auto Parry [ENTEN]"
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.TextSize = 14
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Font = Enum.Font.GothamBold
    Title.Parent = DragHandle
    
    -- Drag indicator
    local DragDots = Instance.new("TextLabel")
    DragDots.Size = UDim2.new(0, 30, 1, 0)
    DragDots.Position = UDim2.new(1, -35, 0, 0)
    DragDots.BackgroundTransparency = 1
    DragDots.Text = "⠿"
    DragDots.TextColor3 = Color3.fromRGB(150, 150, 200)
    DragDots.TextSize = 20
    DragDots.Font = Enum.Font.Gotham
    DragDots.Parent = DragHandle
    
    -- Status Container
    local StatusContainer = Instance.new("Frame")
    StatusContainer.Size = UDim2.new(0.9, 0, 0, 25)
    StatusContainer.Position = UDim2.new(0.05, 0, 0, 40)
    StatusContainer.BackgroundTransparency = 1
    StatusContainer.Parent = MainFrame
    
    -- Status Label
    local StatusLabel = Instance.new("TextLabel")
    StatusLabel.Size = UDim2.new(1, 0, 1, 0)
    StatusLabel.Position = UDim2.new(0, 0, 0, 0)
    StatusLabel.BackgroundTransparency = 1
    StatusLabel.Text = Config.Enabled and "🟢 Status: ON" or "🔴 Status: OFF"
    StatusLabel.TextColor3 = Config.Enabled and Color3.fromRGB(0, 255, 100) or Color3.fromRGB(255, 50, 50)
    StatusLabel.TextSize = 13
    StatusLabel.TextXAlignment = Enum.TextXAlignment.Center
    StatusLabel.Font = Enum.Font.GothamSemibold
    StatusLabel.Parent = StatusContainer
    
    -- Status glow
    local StatusGlow = Instance.new("Frame")
    StatusGlow.Size = UDim2.new(1, 0, 1, 0)
    StatusGlow.Position = UDim2.new(0, 0, 0, 0)
    StatusGlow.BackgroundColor3 = Config.Enabled and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
    StatusGlow.BackgroundTransparency = 0.85
    StatusGlow.BorderSizePixel = 0
    StatusGlow.Parent = StatusContainer
    local GlowCorner = Instance.new("UICorner")
    GlowCorner.CornerRadius = UDim.new(0, 6)
    GlowCorner.Parent = StatusGlow
    
    -- Cooldown Label
    local CooldownLabel = Instance.new("TextLabel")
    CooldownLabel.Size = UDim2.new(0.9, 0, 0, 20)
    CooldownLabel.Position = UDim2.new(0.05, 0, 0, 68)
    CooldownLabel.BackgroundTransparency = 1
    CooldownLabel.Text = "⏱️ Cooldown: Ready"
    CooldownLabel.TextColor3 = Color3.fromRGB(100, 255, 150)
    CooldownLabel.TextSize = 12
    CooldownLabel.TextXAlignment = Enum.TextXAlignment.Center
    CooldownLabel.Font = Enum.Font.Gotham
    CooldownLabel.Parent = MainFrame
    
    -- Buttons Container
    local ButtonsContainer = Instance.new("Frame")
    ButtonsContainer.Size = UDim2.new(0.9, 0, 0, 35)
    ButtonsContainer.Position = UDim2.new(0.05, 0, 0, 92)
    ButtonsContainer.BackgroundTransparency = 1
    ButtonsContainer.Parent = MainFrame
    
    -- Toggle Button
    local ToggleButton = Instance.new("TextButton")
    ToggleButton.Size = UDim2.new(1, 0, 1, 0)
    ToggleButton.Position = UDim2.new(0, 0, 0, 0)
    ToggleButton.BackgroundColor3 = Config.Enabled and Color3.fromRGB(0, 180, 80) or Color3.fromRGB(180, 40, 40)
    ToggleButton.Text = Config.Enabled and "✕ Disable" or "✓ Enable"
    ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    ToggleButton.TextSize = 14
    ToggleButton.Font = Enum.Font.Gotham
    ToggleButton.AutoButtonColor = false
    ToggleButton.Parent = ButtonsContainer
    local ToggleCorner = Instance.new("UICorner")
    ToggleCorner.CornerRadius = UDim.new(0, 8)
    ToggleCorner.Parent = ToggleButton
    
    -- Button hover
    local ButtonHover = Instance.new("Frame")
    ButtonHover.Size = UDim2.new(1, 0, 1, 0)
    ButtonHover.Position = UDim2.new(0, 0, 0, 0)
    ButtonHover.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    ButtonHover.BackgroundTransparency = 0.9
    ButtonHover.BorderSizePixel = 0
    ButtonHover.Visible = false
    ButtonHover.Parent = ToggleButton
    local HoverCorner = Instance.new("UICorner")
    HoverCorner.CornerRadius = UDim.new(0, 8)
    HoverCorner.Parent = ButtonHover
    
    -- Toggle function
    ToggleButton.MouseEnter:Connect(function()
        ButtonHover.Visible = true
    end)
    ToggleButton.MouseLeave:Connect(function()
        ButtonHover.Visible = false
    end)
    ToggleButton.MouseButton1Click:Connect(function()
        Config.Enabled = not Config.Enabled
        local newColor = Config.Enabled and Color3.fromRGB(0, 180, 80) or Color3.fromRGB(180, 40, 40)
        local newText = Config.Enabled and "✕ Disable" or "✓ Enable"
        local statusText = Config.Enabled and "🟢 Status: ON" or "🔴 Status: OFF"
        local statusColor = Config.Enabled and Color3.fromRGB(0, 255, 100) or Color3.fromRGB(255, 50, 50)
        local glowColor = Config.Enabled and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
        
        ToggleButton.Text = newText
        ToggleButton.BackgroundColor3 = newColor
        StatusLabel.Text = statusText
        StatusLabel.TextColor3 = statusColor
        StatusGlow.BackgroundColor3 = glowColor
        CooldownLabel.Text = Config.Enabled and "⏱️ Cooldown: Ready" or "⏱️ Cooldown: Disabled"
        
        if not Config.Enabled then
            isParrying = false
            isCooldownActive = false
            StopParryAnimations()
        end
        
        game:GetService("StarterGui"):SetCore("ChatMakeSystemMessage", {
            Text = "Auto Parry: " .. (Config.Enabled and "Enabled ✅" or "Disabled ❌"),
            Color = Config.Enabled and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
        })
    end)
    
    -- DRAGGING SYSTEM - IMPROVED FOR MOBILE
    local dragging = false
    local dragStart = nil
    local startPos = nil
    local dragObject = nil
    
    local function UpdatePosition(input)
        local delta = input.Position - dragStart
        local newX = startPos.X.Offset + delta.X
        local newY = startPos.Y.Offset + delta.Y
        
        local viewportSize = GuiService:GetViewportSize()
        local frameSize = MainFrame.AbsoluteSize
        newX = math.clamp(newX, 0, viewportSize.X - frameSize.X)
        newY = math.clamp(newY, 0, viewportSize.Y - frameSize.Y)
        
        MainFrame.Position = UDim2.new(startPos.X.Scale, newX, startPos.Y.Scale, newY)
    end
    
    -- Mouse drag
    DragHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = MainFrame.Position
            dragObject = input
        end
    end)
    
    DragHandle.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
            dragObject = nil
        end
    end)
    
    -- Touch drag for mobile
    DragHandle.TouchBegan:Connect(function(touch)
        dragging = true
        dragStart = touch.Position
        startPos = MainFrame.Position
        dragObject = touch
    end)
    
    DragHandle.TouchEnded:Connect(function()
        dragging = false
        dragObject = nil
    end)
    
    -- Update position on input changed
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            UpdatePosition(input)
        end
    end)
    
    -- Touch moved for mobile
    DragHandle.TouchMoved:Connect(function(touch)
        if dragging then
            UpdatePosition(touch)
        end
    end)
    
    return ScreenGui
end

-- Initialize
print("=== Auto Parry Script v5 - FINAL ===")
print("Loading with animations...")
print("Skin: Enten")

-- Check all remotes
CheckAllRemotes()

-- Create UI
UI = CreateUI()

-- Start auto parry
StartAutoParry()

-- Setup all attack listeners
SetupAllAttackListeners()

print("✅ Auto Parry loaded successfully!")
print("📌 Press " .. tostring(Config.AutoParryKey.Name) .. " to toggle")
print("📌 Status: " .. (Config.Enabled and "ON" or "OFF (Default OFF)"))
print("📌 Parry Animation: 3 seconds duration")
print("📌 Cooldown: 63 seconds (1 minute 3 seconds)")
print("📌 Detection Range: 12")
print("📌 Animations loaded: " .. #PARRY_ANIMATIONS)
print("📌 Skin: Enten")

-- Display initial status
task.wait(1)
game:GetService("StarterGui"):SetCore("ChatMakeSystemMessage", {
    Text = "Auto Parry v5: " .. (Config.Enabled and "Enabled ✅" or "Disabled ❌ (Press P to enable)"),
    Color = Config.Enabled and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 200, 0)
})

-- Show animation info
task.wait(0.5)
game:GetService("StarterGui"):SetCore("ChatMakeSystemMessage", {
    Text = "🎬 Parry animations: 2 (Skin: Enten)",
    Color = Color3.fromRGB(255, 200, 100)
})

-- Show parry remotes found
task.wait(0.5)
local remoteCount = 0
if Remotes.Parry then remoteCount = remoteCount + 1 end
if ParryingDaggerRemotes.parry then remoteCount = remoteCount + 1 end
if Remotes.ParryAnimation then remoteCount = remoteCount + 1 end
if Remotes.AnimationControl then remoteCount = remoteCount + 1 end

game:GetService("StarterGui"):SetCore("ChatMakeSystemMessage", {
    Text = "📡 Parry remotes found: " .. remoteCount,
    Color = Color3.fromRGB(100, 200, 255)
})

task.wait(0.5)
game:GetService("StarterGui"):SetCore("ChatMakeSystemMessage", {
    Text = "⏱️ Cooldown: 63 seconds | Range: 12",
    Color = Color3.fromRGB(255, 150, 50)
})
