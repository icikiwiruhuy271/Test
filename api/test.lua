-- Auto Parry Script for Violence District v3
-- Created for Roblox Violence District

local Player = game.Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Configuration
local Config = {
    Enabled = true,
    ParryDelay = 0.05, -- Delay before parrying (in seconds)
    DetectionRange = 50, -- Max range to detect killer attacks
    ShowDebug = true, -- Set to true for debug info
    AutoParryKey = Enum.KeyCode.P, -- Toggle key
    ParryCooldown = 0.25, -- Cooldown between parries
    UseAllDetections = true, -- Use all detection methods
}

-- Remote Events & Functions - COMPLETE
local Remotes = {
    -- Attack folder
    Attack = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("Attack"),
    
    -- Generator folder
    Generator = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("Generator"),
    
    -- Killes folder
    Killes = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("Killes"),
    
    -- Remotes folder
    RemotesFolder = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("Remotes"),
    
    -- Parry related
    Parry = ReplicatedStorage:FindFirstChild("ParryClient"),
    ParryResult = ReplicatedStorage:FindFirstChild("ParryResult"),
    ParryAnimation = ReplicatedStorage:FindFirstChild("parry"),
    AnimationControl = ReplicatedStorage:FindFirstChild("AnimationControl"),
    AnimationHandler = ReplicatedStorage:FindFirstChild("AnimationHandler"),
    
    -- Items
    ParryingDagger = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("Items") and ReplicatedStorage.Remotes.Items:FindFirstChild("Parrying Dagger"),
    
    -- Emote
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

-- Generator remotes
local GeneratorRemotes = {
    BreakGenAnim = Remotes.Generator and GetRemoteFromFolder(Remotes.Generator, "BreakGenAnim"),
    BreakGenCommit = Remotes.Generator and GetRemoteFromFolder(Remotes.Generator, "BreakGenCommit"),
    BreakGenEvent = Remotes.Generator and GetRemoteFromFolder(Remotes.Generator, "BreakGenEvent"),
    BreakGenReject = Remotes.Generator and GetRemoteFromFolder(Remotes.Generator, "BreakGenReject"),
    Escpetime = Remotes.Generator and GetRemoteFromFolder(Remotes.Generator, "Escpetime"),
    GeenDone = Remotes.Generator and GetRemoteFromFolder(Remotes.Generator, "GeenDone"),
    RepairAnim = Remotes.Generator and GetRemoteFromFolder(Remotes.Generator, "RepairAnim"),
    RepairEvent = Remotes.Generator and GetRemoteFromFolder(Remotes.Generator, "RepairEvent"),
    RepairVFX = Remotes.Generator and GetRemoteFromFolder(Remotes.Generator, "RepairVFX"),
    SkillCheckEvent = Remotes.Generator and GetRemoteFromFolder(Remotes.Generator, "SkillCheckEvent"),
    SkillChekFallEvent = Remotes.Generator and GetRemoteFromFolder(Remotes.Generator, "SkillChekFallEvent"),
    SkillCheckResultEvent = Remotes.Generator and GetRemoteFromFolder(Remotes.Generator, "SkillCheckResultEvent"),
    Skillcheckvalidetect = Remotes.Generator and GetRemoteFromFolder(Remotes.Generator, "Skillcheckvalidetect"),
    allgendone = Remotes.Generator and GetRemoteFromFolder(Remotes.Generator, "allgendone"),
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

-- Variables
local isParrying = false
local lastParryTime = 0
local UI = nil
local currentTarget = nil
local detectedAttacks = {}

-- Debug function
local function DebugLog(...)
    if Config.ShowDebug then
        print("[AutoParry]", ...)
    end
end

-- Perform Parry - MAIN FUNCTION
local function PerformParry()
    if isParrying then return end
    if not Config.Enabled then return end
    
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
        
        -- Stop emote if needed
        if Remotes.EmoteHandler then
            pcall(function()
                Remotes.EmoteHandler:FireServer("StopEmote")
            end)
        end
        
        -- Reset parry state
        task.wait(0.15)
        isParrying = false
        
        DebugLog("✅ Parry executed successfully!")
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
    
    for _, player in pairs(game.Players:GetPlayers()) do
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

-- Main detection loop
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
        
        -- Find closest attacking killer
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
                
                local args = {...}
                -- Check if first arg is a player
                if args[1] and type(args[1]) == "Instance" then
                    if args[1]:IsA("Player") and args[1] ~= Player then
                        DebugLog("Attack detected: " .. remoteName .. " from: " .. args[1].Name)
                        task.wait(Config.ParryDelay)
                        PerformParry()
                    end
                else
                    -- If no player arg, still try to parry
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
                if attacker and attacker:IsA("Player") then
                    DebugLog("AttackEvent from: " .. attacker.Name)
                    task.wait(Config.ParryDelay)
                    PerformParry()
                end
            end)
        end
    end
    
    -- Listen to Generator events (some might be related to attacks)
    for remoteName, remote in pairs(GeneratorRemotes) do
        if remote and remote:IsA("RemoteEvent") then
            remote.OnClientEvent:Connect(function(...)
                if not Config.Enabled then return end
                
                local args = {...}
                -- Check if any arg is a player that's not us
                for _, arg in pairs(args) do
                    if type(arg) == "Instance" and arg:IsA("Player") and arg ~= Player then
                        DebugLog("Generator event: " .. remoteName .. " from: " .. arg.Name)
                        task.wait(Config.ParryDelay)
                        PerformParry()
                        break
                    end
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
    
    -- Check attack remotes
    local attackCount = 0
    for name, remote in pairs(AttackRemotes) do
        if remote then attackCount = attackCount + 1 end
    end
    DebugLog("Attack remotes found: " .. attackCount)
    
    -- Check killes remotes
    local killesCount = 0
    for name, remote in pairs(KillesRemotes) do
        if remote then killesCount = killesCount + 1 end
    end
    DebugLog("Killes remotes found: " .. killesCount)
    
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
    task.wait(1)
end)

-- UI Creation function (same as before, but I'll keep it compact)
local function CreateUI()
    -- [UI CODE - Same as previous version]
    -- (Keeping it short to avoid repetition, but include the full UI code)
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "AutoParryUI"
    ScreenGui.Parent = Player.PlayerGui
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    local MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.new(0, 210, 0, 120)
    MainFrame.Position = UDim2.new(0, 10, 0.5, -60)
    MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
    MainFrame.BackgroundTransparency = 0.15
    MainFrame.BorderSizePixel = 0
    MainFrame.ClipsDescendants = true
    MainFrame.Parent = ScreenGui
    
    -- ... (rest of UI code from previous version)
    -- I'll include the full UI code below
    
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
    
    -- Drag Handle
    local DragHandle = Instance.new("Frame")
    DragHandle.Size = UDim2.new(1, 0, 0, 30)
    DragHandle.Position = UDim2.new(0, 0, 0, 0)
    DragHandle.BackgroundColor3 = Color3.fromRGB(40, 40, 70)
    DragHandle.BackgroundTransparency = 0.3
    DragHandle.BorderSizePixel = 0
    DragHandle.Parent = MainFrame
    local DragCorner = Instance.new("UICorner")
    DragCorner.CornerRadius = UDim.new(0, 12)
    DragCorner.Parent = DragHandle
    
    -- Title
    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, -60, 1, 0)
    Title.Position = UDim2.new(0, 10, 0, 0)
    Title.BackgroundTransparency = 1
    Title.Text = "⚔️ Auto Parry"
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.TextSize = 16
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
    StatusContainer.Size = UDim2.new(0.9, 0, 0, 30)
    StatusContainer.Position = UDim2.new(0.05, 0, 0, 35)
    StatusContainer.BackgroundTransparency = 1
    StatusContainer.Parent = MainFrame
    
    -- Status Label
    local StatusLabel = Instance.new("TextLabel")
    StatusLabel.Size = UDim2.new(1, 0, 1, 0)
    StatusLabel.Position = UDim2.new(0, 0, 0, 0)
    StatusLabel.BackgroundTransparency = 1
    StatusLabel.Text = Config.Enabled and "🟢 Status: ON" or "🔴 Status: OFF"
    StatusLabel.TextColor3 = Config.Enabled and Color3.fromRGB(0, 255, 100) or Color3.fromRGB(255, 50, 50)
    StatusLabel.TextSize = 14
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
    
    -- Buttons Container
    local ButtonsContainer = Instance.new("Frame")
    ButtonsContainer.Size = UDim2.new(0.9, 0, 0, 35)
    ButtonsContainer.Position = UDim2.new(0.05, 0, 0, 70)
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
        
        if not Config.Enabled then
            isParrying = false
        end
        
        game:GetService("StarterGui"):SetCore("ChatMakeSystemMessage", {
            Text = "Auto Parry: " .. (Config.Enabled and "Enabled ✅" or "Disabled ❌"),
            Color = Config.Enabled and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
        })
    end)
    
    -- Dragging system
    local dragging = false
    local dragStart = nil
    local startPos = nil
    
    local function UpdatePosition(input)
        local delta = input.Position - dragStart
        local newX = startPos.X.Offset + delta.X
        local newY = startPos.Y.Offset + delta.Y
        
        local viewportSize = game:GetService("GuiService"):GetViewportSize()
        local frameSize = MainFrame.AbsoluteSize
        newX = math.clamp(newX, 0, viewportSize.X - frameSize.X)
        newY = math.clamp(newY, 0, viewportSize.Y - frameSize.Y)
        
        MainFrame.Position = UDim2.new(startPos.X.Scale, newX, startPos.Y.Scale, newY)
    end
    
    DragHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = MainFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            UpdatePosition(input)
        end
    end)
    
    return ScreenGui
end

-- Initialize
print("=== Auto Parry Script v3 - COMPLETE ===")
print("Loading with ALL remotes...")

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
print("📌 Status: " .. (Config.Enabled and "ON" or "OFF"))
print("📌 Debug mode: " .. (Config.ShowDebug and "ON" or "OFF"))

-- Display initial status
task.wait(1)
game:GetService("StarterGui"):SetCore("ChatMakeSystemMessage", {
    Text = "Auto Parry v3: " .. (Config.Enabled and "Enabled ✅" or "Disabled ❌"),
    Color = Config.Enabled and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
})

-- Show detected remotes in chat
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
