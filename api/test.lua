-- Auto Parry Script for Violence District
-- Created for Roblox Violence District

local Player = game.Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
local TweenService = game:GetService("TweenService")

-- Configuration
local Config = {
    Enabled = true,
    ParryDelay = 0.1, -- Delay before parrying (in seconds)
    DetectionRange = 30, -- Max range to detect killer attacks
    ShowDebug = false,
    AutoParryKey = Enum.KeyCode.P, -- Toggle key
}

-- Remote Events & Functions
local Remotes = {
    AttackEvent = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes") and game:GetService("ReplicatedStorage").Remotes:FindFirstChild("AttackEvent"),
    Parry = game:GetService("ReplicatedStorage"):FindFirstChild("ParryClient"),
    ParryResult = game:GetService("ReplicatedStorage"):FindFirstChild("ParryResult"),
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

-- Variables
local isParrying = false
local lastAttackTime = 0
local parryCooldown = 0.5
local detectedKillers = {}
local currentTarget = nil
local UI = nil

-- UI Creation with Improved Dragging
local function CreateUI()
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "AutoParryUI"
    ScreenGui.Parent = Player.PlayerGui
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    -- Main Frame
    local MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.new(0, 210, 0, 120)
    MainFrame.Position = UDim2.new(0, 10, 0.5, -60)
    MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
    MainFrame.BackgroundTransparency = 0.15
    MainFrame.BorderSizePixel = 0
    MainFrame.ClipsDescendants = true
    MainFrame.Parent = ScreenGui
    
    -- Shadow effect
    local Shadow = Instance.new("Frame")
    Shadow.Size = UDim2.new(1, 10, 1, 10)
    Shadow.Position = UDim2.new(0, -5, 0, -5)
    Shadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    Shadow.BackgroundTransparency = 0.5
    Shadow.BorderSizePixel = 0
    Shadow.Parent = MainFrame
    
    -- Main background with gradient
    local Gradient = Instance.new("UIGradient")
    Gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(25, 25, 40)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(15, 15, 30))
    })
    Gradient.Rotation = 45
    Gradient.Parent = MainFrame
    
    -- Corner rounding
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
    
    -- Drag Handle (top bar)
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
    
    -- Drag Handle Gradient
    local DragGradient = Instance.new("UIGradient")
    DragGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(50, 50, 90)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 30, 60))
    })
    DragGradient.Rotation = 90
    DragGradient.Parent = DragHandle
    
    -- Title with icon
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
    
    -- Drag indicator (3 dots)
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
    
    -- Status background glow
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
    
    -- Button hover effect
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
    
    -- Button click animation
    local function AnimateButton(button, press)
        local targetScale = press and 0.95 or 1
        local targetTransparency = press and 0.7 or 1
        
        local tweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        local tween = TweenService:Create(button, tweenInfo, {
            BackgroundTransparency = targetTransparency
        })
        tween:Play()
        
        local scaleTween = TweenService:Create(button, tweenInfo, {
            Size = UDim2.new(targetScale, 0, targetScale, 0)
        })
        scaleTween:Play()
    end
    
    -- Toggle function
    ToggleButton.MouseButton1Down:Connect(function()
        AnimateButton(ToggleButton, true)
    end)
    
    ToggleButton.MouseButton1Up:Connect(function()
        AnimateButton(ToggleButton, false)
    end)
    
    ToggleButton.MouseEnter:Connect(function()
        ButtonHover.Visible = true
    end)
    
    ToggleButton.MouseLeave:Connect(function()
        ButtonHover.Visible = false
    end)
    
    ToggleButton.MouseButton1Click:Connect(function()
        Config.Enabled = not Config.Enabled
        
        -- Update UI with animation
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
        
        -- Send status to chat
        game:GetService("StarterGui"):SetCore("ChatMakeSystemMessage", {
            Text = "Auto Parry: " .. (Config.Enabled and "Enabled ✅" or "Disabled ❌"),
            Color = Config.Enabled and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
        })
    end)
    
    -- DRAGGING SYSTEM - Improved
    local dragging = false
    local dragInput = nil
    local dragStart = nil
    local startPos = nil
    
    local function UpdatePosition(input)
        local delta = input.Position - dragStart
        local newX = startPos.X.Offset + delta.X
        local newY = startPos.Y.Offset + delta.Y
        
        -- Clamp to screen edges
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
    
    DragHandle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    
    -- Make entire frame draggable (except buttons)
    MainFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            -- Check if click is on a button
            local mousePos = input.Position
            local relativePos = MainFrame.AbsolutePosition
            local relativeSize = MainFrame.AbsoluteSize
            
            -- Check if click is in the drag handle area
            if input.Position.Y >= relativePos.Y and input.Position.Y <= relativePos.Y + 30 then
                dragging = true
                dragStart = input.Position
                startPos = MainFrame.Position
                
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                    end
                end)
            end
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            UpdatePosition(input)
        end
    end)
    
    -- Touch support for mobile
    if UserInputService.TouchEnabled then
        local touchStart = nil
        
        MainFrame.TouchBegan:Connect(function(touch)
            if touch.Position.Y >= MainFrame.AbsolutePosition.Y and touch.Position.Y <= MainFrame.AbsolutePosition.Y + 30 then
                dragging = true
                touchStart = touch
                dragStart = touch.Position
                startPos = MainFrame.Position
            end
        end)
        
        MainFrame.TouchMoved:Connect(function(touch)
            if dragging and touch then
                UpdatePosition(touch)
            end
        end)
        
        MainFrame.TouchEnded:Connect(function()
            dragging = false
        end)
    end
    
    return ScreenGui
end

-- Helper Functions
local function GetKillers()
    local killers = {}
    for _, player in pairs(game.Players:GetPlayers()) do
        if player ~= Player and player.Character and player.Character:FindFirstChild("Humanoid") then
            local character = player.Character
            if character:FindFirstChild("Humanoid") and character.Humanoid.Health > 0 then
                table.insert(killers, player)
            end
        end
    end
    return killers
end

local function IsAttackAnimation(animId)
    return VD_ATTACK_ANIMS[animId] or false
end

local function GetClosestKiller()
    if not Character or not Character:FindFirstChild("HumanoidRootPart") then return nil end
    
    local rootPart = Character.HumanoidRootPart
    local closestKiller = nil
    local closestDistance = Config.DetectionRange
    
    for _, player in pairs(game.Players:GetPlayers()) do
        if player ~= Player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local killerRoot = player.Character.HumanoidRootPart
            local distance = (rootPart.Position - killerRoot.Position).Magnitude
            
            if distance < closestDistance then
                closestDistance = distance
                closestKiller = player
            end
        end
    end
    
    return closestKiller
end

local function PerformParry()
    if isParrying or not Config.Enabled then return end
    
    local currentTime = tick()
    if currentTime - lastAttackTime < parryCooldown then return end
    
    local killer = GetClosestKiller()
    if not killer or not killer.Character then return end
    
    local humanoid = killer.Character:FindFirstChild("Humanoid")
    if not humanoid then return end
    
    local animator = humanoid:FindFirstChild("Animator")
    if animator then
        local tracks = animator:GetPlayingAnimationTracks()
        for _, track in pairs(tracks) do
            local animId = track.Animation.AnimationId
            if IsAttackAnimation(animId) then
                isParrying = true
                lastAttackTime = currentTime
                
                if Remotes.Parry then
                    Remotes.Parry:FireServer()
                    
                    if Config.ShowDebug then
                        print("Parry triggered against: " .. killer.Name)
                    end
                end
                
                task.wait(0.15)
                isParrying = false
                
                break
            end
        end
    end
end

-- Main Auto-Parry Loop
local function StartAutoParry()
    RunService.Heartbeat:Connect(function()
        if not Config.Enabled then return end
        if not Character or not Character.Parent then
            Character = Player.Character
            return
        end
        
        PerformParry()
    end)
end

-- Listen for attack events
local function SetupAttackEventListeners()
    if Remotes.AttackEvent then
        Remotes.AttackEvent.OnClientEvent:Connect(function(attacker, data)
            if not Config.Enabled then return end
            if attacker == Player then return end
            
            if attacker and attacker:IsA("Player") and attacker ~= Player then
                task.wait(Config.ParryDelay)
                PerformParry()
            end
        end)
    end
    
    local attackFolder = game:GetService("ReplicatedStorage"):FindFirstChild("Attack")
    if attackFolder then
        for _, remote in pairs(attackFolder:GetChildren()) do
            if remote:IsA("RemoteEvent") or remote:IsA("RemoteFunction") then
                if remote.Name == "BasicAttack" or remote.Name == "Lunge" or remote.Name == "AfterAttack" then
                    remote.OnClientEvent:Connect(function(...)
                        if not Config.Enabled then return end
                        local args = {...}
                        if args[1] and type(args[1]) == "Instance" and args[1].Parent and args[1].Parent:IsA("Player") then
                            if args[1] ~= Player then
                                task.wait(Config.ParryDelay)
                                PerformParry()
                            end
                        end
                    end)
                end
            end
        end
    end
end

-- Keyboard shortcut to toggle
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Config.AutoParryKey then
        Config.Enabled = not Config.Enabled
        
        -- Update UI status
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
        
        -- Send status to chat
        game:GetService("StarterGui"):SetCore("ChatMakeSystemMessage", {
            Text = "Auto Parry: " .. (Config.Enabled and "Enabled ✅" or "Disabled ❌"),
            Color = Config.Enabled and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
        })
    end
end)

-- Handle character respawn
Player.CharacterAdded:Connect(function(newCharacter)
    Character = newCharacter
    task.wait(1)
end)

-- Initialize
UI = CreateUI()
StartAutoParry()
SetupAttackEventListeners()

print("Auto Parry script loaded successfully!")
print("Press " .. tostring(Config.AutoParryKey.Name) .. " to toggle auto parry.")
print("Status: " .. (Config.Enabled and "ON" or "OFF"))

-- Display initial status
task.wait(1)
game:GetService("StarterGui"):SetCore("ChatMakeSystemMessage", {
    Text = "Auto Parry: " .. (Config.Enabled and "Enabled ✅" or "Disabled ❌"),
    Color = Config.Enabled and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
})
