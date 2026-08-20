-- Auto Parry Script for Violence District
-- Created for Roblox Violence District

local Player = game.Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")

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

-- UI Creation
local function CreateUI()
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "AutoParryUI"
    ScreenGui.Parent = Player.PlayerGui
    ScreenGui.ResetOnSpawn = false
    
    -- Main Frame
    local MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.new(0, 200, 0, 100)
    MainFrame.Position = UDim2.new(0, 10, 0.5, -50)
    MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    MainFrame.BackgroundTransparency = 0.2
    MainFrame.BorderSizePixel = 0
    MainFrame.Parent = ScreenGui
    
    -- Corner rounding
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 8)
    Corner.Parent = MainFrame
    
    -- Title
    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, 0, 0, 25)
    Title.Position = UDim2.new(0, 0, 0, 0)
    Title.BackgroundTransparency = 1
    Title.Text = "Auto Parry"
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.TextSize = 16
    Title.Font = Enum.Font.GothamBold
    Title.Parent = MainFrame
    
    -- Status Label
    local StatusLabel = Instance.new("TextLabel")
    StatusLabel.Size = UDim2.new(1, 0, 0, 25)
    StatusLabel.Position = UDim2.new(0, 0, 0, 30)
    StatusLabel.BackgroundTransparency = 1
    StatusLabel.Text = "Status: " .. (Config.Enabled and "ON" or "OFF")
    StatusLabel.TextColor3 = Config.Enabled and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
    StatusLabel.TextSize = 14
    StatusLabel.Font = Enum.Font.Gotham
    StatusLabel.Parent = MainFrame
    
    -- Toggle Button
    local ToggleButton = Instance.new("TextButton")
    ToggleButton.Size = UDim2.new(0.8, 0, 0, 30)
    ToggleButton.Position = UDim2.new(0.1, 0, 0, 60)
    ToggleButton.BackgroundColor3 = Config.Enabled and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(200, 0, 0)
    ToggleButton.Text = Config.Enabled and "Disable" or "Enable"
    ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    ToggleButton.TextSize = 14
    ToggleButton.Font = Enum.Font.Gotham
    ToggleButton.Parent = MainFrame
    
    local ToggleCorner = Instance.new("UICorner")
    ToggleCorner.CornerRadius = UDim.new(0, 4)
    ToggleCorner.Parent = ToggleButton
    
    -- Toggle function
    ToggleButton.MouseButton1Click:Connect(function()
        Config.Enabled = not Config.Enabled
        StatusLabel.Text = "Status: " .. (Config.Enabled and "ON" or "OFF")
        StatusLabel.TextColor3 = Config.Enabled and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
        ToggleButton.Text = Config.Enabled and "Disable" or "Enable"
        ToggleButton.BackgroundColor3 = Config.Enabled and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(200, 0, 0)
        
        if not Config.Enabled then
            isParrying = false
        end
    end)
    
    -- Make UI draggable
    local dragging = false
    local dragStart, startPos
    
    MainFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
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
    
    MainFrame.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    
    return ScreenGui
end

-- Helper Functions
local function GetKillers()
    local killers = {}
    for _, player in pairs(game.Players:GetPlayers()) do
        if player ~= Player and player.Character and player.Character:FindFirstChild("Humanoid") then
            -- Check if player is killer (you can adjust this based on actual game mechanics)
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
    
    -- Check if we have the Parrying Dagger equipped
    -- (You might need to adjust this based on how the game checks for items)
    local hasParryDagger = false
    -- Add your item check logic here
    
    -- Find the killer and check if they're attacking
    local killer = GetClosestKiller()
    if not killer or not killer.Character then return end
    
    local humanoid = killer.Character:FindFirstChild("Humanoid")
    if not humanoid then return end
    
    -- Check if killer is playing an attack animation
    local animator = humanoid:FindFirstChild("Animator")
    if animator then
        local tracks = animator:GetPlayingAnimationTracks()
        for _, track in pairs(tracks) do
            local animId = track.Animation.AnimationId
            if IsAttackAnimation(animId) then
                -- Attack detected, perform parry
                isParrying = true
                lastAttackTime = currentTime
                
                -- Fire the parry remote
                if Remotes.Parry then
                    Remotes.Parry:FireServer()
                    
                    if Config.ShowDebug then
                        print("Parry triggered against: " .. killer.Name)
                    end
                end
                
                -- Reset parry state after a short delay
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

-- Listen for attack events (alternative detection method)
local function SetupAttackEventListeners()
    -- Listen for AttackEvent
    if Remotes.AttackEvent then
        Remotes.AttackEvent.OnClientEvent:Connect(function(attacker, data)
            if not Config.Enabled then return end
            if attacker == Player then return end
            
            -- Check if attacker is a killer
            if attacker and attacker:IsA("Player") and attacker ~= Player then
                -- Perform parry with a small delay for timing
                task.wait(Config.ParryDelay)
                PerformParry()
            end
        end)
    end
    
    -- Listen for BasicAttack or Lunge events
    local attackFolder = game:GetService("ReplicatedStorage"):FindFirstChild("Attack")
    if attackFolder then
        for _, remote in pairs(attackFolder:GetChildren()) do
            if remote:IsA("RemoteEvent") or remote:IsA("RemoteFunction") then
                if remote.Name == "BasicAttack" or remote.Name == "Lunge" or remote.Name == "AfterAttack" then
                    remote.OnClientEvent:Connect(function(...)
                        if not Config.Enabled then return end
                        -- Check if the event was fired by a killer
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
        -- Update UI status if it exists
        local ui = Player.PlayerGui:FindFirstChild("AutoParryUI")
        if ui then
            local statusLabel = ui.MainFrame:FindFirstChild("StatusLabel")
            if statusLabel then
                statusLabel.Text = "Status: " .. (Config.Enabled and "ON" or "OFF")
                statusLabel.TextColor3 = Config.Enabled and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
            end
            local toggleButton = ui.MainFrame:FindFirstChild("ToggleButton")
            if toggleButton then
                toggleButton.Text = Config.Enabled and "Disable" or "Enable"
                toggleButton.BackgroundColor3 = Config.Enabled and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(200, 0, 0)
            end
        end
    end
end)

-- Handle character respawn
Player.CharacterAdded:Connect(function(newCharacter)
    Character = newCharacter
    task.wait(1)
end)

-- Initialize
CreateUI()
StartAutoParry()
SetupAttackEventListeners()

print("Auto Parry script loaded successfully!")
print("Press " .. tostring(Config.AutoParryKey.Name) .. " to toggle auto parry.")
print("Status: " .. (Config.Enabled and "ON" or "OFF"))

-- Optional: Display status in chat
local function DisplayStatus()
    game:GetService("StarterGui"):SetCore("ChatMakeSystemMessage", {
        Text = "Auto Parry: " .. (Config.Enabled and "Enabled" or "Disabled"),
        Color = Config.Enabled and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
    })
end

-- Call on load
task.wait(1)
DisplayStatus()
