-- This is only for local repository and should be created by users

local AssetService = game:GetService("AssetService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local currentCamera = workspace.CurrentCamera

local deskInstance = workspace:WaitForChild(("%s_DESK"):format(player.Name))
local cameraPart: Part = deskInstance:WaitForChild("CAM")
local screen: Part = deskInstance:WaitForChild("SCREEN")

local Icon = require(script.Parent.TopbarPlus)
local Skyboxes = require(script.Parent.Skyboxes)
local remote = script.Parent.Parent:WaitForChild("MachinaRemote") :: RemoteFunction

local Config = require(script.Parent.Parent.Config)
local PcSystem = require(script.Parent.Parent.platforms.x86.PcSystem)

local DEFAULT_SKYBOX = "Baltic Dune"
local AUTO_POWER = true

local TOPBAR_TOGGLE_KEY = Enum.KeyCode.F5
local STATS_TOGGLE_KEY = Enum.KeyCode.F6

local FRAME_PUSH_RATE = 0.35
local FRAME_PULL_RATE = 0.35
local STATS_RATE = 0.5
local STAGE_RATE = 0.15

local SCROLL_STEP = 6
local CAMERA_DRAG_SENS = 0.01
local CAMERA_FOV_DEFAULT = 75
local CAMERA_FOV_MIN = 5
local CAMERA_FOV_MAX = 85
local CAMERA_BOUNDS_X = 1.4
local CAMERA_BOUNDS_Y = 0.9

local SKY_PROPS = {
	"SkyboxBk",
	"SkyboxDn",
	"SkyboxFt",
	"SkyboxLf",
	"SkyboxRt",
	"SkyboxUp",
}

local ROBLOX_KEYCODE_TO_EMU_KEY = {
	[Enum.KeyCode.A] = "A",
	[Enum.KeyCode.B] = "B",
	[Enum.KeyCode.C] = "C",
	[Enum.KeyCode.D] = "D",
	[Enum.KeyCode.E] = "E",
	[Enum.KeyCode.F] = "F",
	[Enum.KeyCode.G] = "G",
	[Enum.KeyCode.H] = "H",
	[Enum.KeyCode.I] = "I",
	[Enum.KeyCode.J] = "J",
	[Enum.KeyCode.K] = "K",
	[Enum.KeyCode.L] = "L",
	[Enum.KeyCode.M] = "M",
	[Enum.KeyCode.N] = "N",
	[Enum.KeyCode.O] = "O",
	[Enum.KeyCode.P] = "P",
	[Enum.KeyCode.Q] = "Q",
	[Enum.KeyCode.R] = "R",
	[Enum.KeyCode.S] = "S",
	[Enum.KeyCode.T] = "T",
	[Enum.KeyCode.U] = "U",
	[Enum.KeyCode.V] = "V",
	[Enum.KeyCode.W] = "W",
	[Enum.KeyCode.X] = "X",
	[Enum.KeyCode.Y] = "Y",
	[Enum.KeyCode.Z] = "Z",
	[Enum.KeyCode.Zero] = "Zero",
	[Enum.KeyCode.One] = "One",
	[Enum.KeyCode.Two] = "Two",
	[Enum.KeyCode.Three] = "Three",
	[Enum.KeyCode.Four] = "Four",
	[Enum.KeyCode.Five] = "Five",
	[Enum.KeyCode.Six] = "Six",
	[Enum.KeyCode.Seven] = "Seven",
	[Enum.KeyCode.Eight] = "Eight",
	[Enum.KeyCode.Nine] = "Nine",
	[Enum.KeyCode.Return] = "Return",
	[Enum.KeyCode.Space] = "Space",
	[Enum.KeyCode.Backspace] = "Backspace",
	[Enum.KeyCode.Tab] = "Tab",
	[Enum.KeyCode.Escape] = "Escape",
	[Enum.KeyCode.LeftShift] = "LeftShift",
	[Enum.KeyCode.RightShift] = "RightShift",
	[Enum.KeyCode.LeftControl] = "LeftControl",
	[Enum.KeyCode.RightControl] = "RightControl",
	[Enum.KeyCode.LeftAlt] = "LeftAlt",
	[Enum.KeyCode.RightAlt] = "RightAlt",
	[Enum.KeyCode.CapsLock] = "CapsLock",
	[Enum.KeyCode.F1] = "F1",
	[Enum.KeyCode.F2] = "F2",
	[Enum.KeyCode.F3] = "F3",
	[Enum.KeyCode.F4] = "F4",
	[Enum.KeyCode.F5] = "F5",
	[Enum.KeyCode.F6] = "F6",
	[Enum.KeyCode.F7] = "F7",
	[Enum.KeyCode.F8] = "F8",
	[Enum.KeyCode.F9] = "F9",
	[Enum.KeyCode.F10] = "F10",
	[Enum.KeyCode.F11] = "F11",
	[Enum.KeyCode.F12] = "F12",
	[Enum.KeyCode.Up] = "Up",
	[Enum.KeyCode.Down] = "Down",
	[Enum.KeyCode.Left] = "Left",
	[Enum.KeyCode.Right] = "Right",
	[Enum.KeyCode.Delete] = "Delete",
	[Enum.KeyCode.Insert] = "Insert",
	[Enum.KeyCode.Home] = "Home",
	[Enum.KeyCode.End] = "End",
	[Enum.KeyCode.PageUp] = "PageUp",
	[Enum.KeyCode.PageDown] = "PageDown",
	[Enum.KeyCode.Minus] = "Minus",
	[Enum.KeyCode.Equals] = "Equals",
	[Enum.KeyCode.LeftBracket] = "LeftBracket",
	[Enum.KeyCode.RightBracket] = "RightBracket",
	[Enum.KeyCode.Semicolon] = "Semicolon",
	[Enum.KeyCode.Quote] = "Quote",
	[Enum.KeyCode.Backquote] = "Backquote",
	[Enum.KeyCode.BackSlash] = "BackSlash",
	[Enum.KeyCode.Comma] = "Comma",
	[Enum.KeyCode.Period] = "Period",
	[Enum.KeyCode.Slash] = "Slash",
}

local THEME = {
	Text = Color3.fromRGB(238, 241, 245),
	MutedText = Color3.fromRGB(138, 147, 160),
	Success = Color3.fromRGB(99, 208, 141),
	Warning = Color3.fromRGB(255, 191, 92),
	Danger = Color3.fromRGB(255, 110, 110),
	ScreenBackground = Color3.fromRGB(0, 0, 0),
}

local STAGE_COLORS = {
	RUNNING = THEME.Success,
	FAULT = THEME.Danger,
}

type SpectateState = {
	targetUserId: number?,
	targetName: string?,
	targetDesk: Model?,
	image: EditableImage?,
	active: boolean,
	targetScreenGui: SurfaceGui?,
	targetScreenImageLabel: ImageLabel?,
}

local machine
local ui

local icons = {}
local topbarVisible = true

local baseCFrame: CFrame
local cameraOffset = Vector2.zero
local isPanning = false
local lastMousePos = Vector2.zero

local lastPush = 0
local lastPull = 0

local spectateState: SpectateState = {
	targetUserId = nil,
	targetName = nil,
	targetDesk = nil,
	image = nil,
	active = false,
	targetScreenGui = nil,
	targetScreenImageLabel = nil,
}

local spectateDropdownIcons = {}
local localSkyboxName = DEFAULT_SKYBOX

local function lerp(a, b, t)
	return a + (b - a) * t
end

local function create(className: string, props: { [string]: any }, parent: Instance?): Instance
	local instance = Instance.new(className)
	for key, value in props do
		instance[key] = value
	end

	if parent then
		instance.Parent = parent
	end

	return instance
end

local function registerIcon(icon)
	table.insert(icons, icon)
	return icon
end

local function getHeadshot(userId: number): string
	return ("rbxthumb://type=AvatarHeadShot&id=%d&w=150&h=150"):format(userId)
end

local function clampCameraOffset(offset: Vector2): Vector2
	return Vector2.new(
		math.clamp(offset.X, -CAMERA_BOUNDS_X, CAMERA_BOUNDS_X),
		math.clamp(offset.Y, -CAMERA_BOUNDS_Y, CAMERA_BOUNDS_Y)
	)
end

local function attemptRepeatedly(callback: () -> ())
	for _ = 1, 6 do
		if pcall(callback) then
			return
		end
		task.wait(0.2)
	end
end

local function getDeskByUserId(userId: number): Model?
	for _, instance in workspace:GetChildren() do
		if instance:IsA("Model") and instance:GetAttribute("OwnerUserId") == userId then
			return instance
		end
	end

	return nil
end

local function setModelVisibleLocal(model: Instance?, visible: boolean)
	if not model then
		return
	end

	local transparency = visible and 0 or 1

	for _, obj in model:GetDescendants() do
		if obj:IsA("BasePart") then
			obj.LocalTransparencyModifier = transparency
		elseif obj:IsA("Decal") or obj:IsA("Texture") then
			obj.Transparency = transparency
		elseif obj:IsA("ParticleEmitter") 
			or obj:IsA("Trail") 
			or obj:IsA("Beam") then
			obj.Enabled = visible
		elseif obj:IsA("SurfaceAppearance") then
			obj.AlphaMode = visible and Enum.AlphaMode.Overlay or Enum.AlphaMode.Transparency
		end
	end
	
	model.DescendantAdded:Once(function(descendant)
		setModelVisibleLocal(model, visible)
	end)
end

local function destroySpectateScreenMirror()
	if spectateState.targetScreenGui then
		spectateState.targetScreenGui:Destroy()
		spectateState.targetScreenGui = nil
		spectateState.targetScreenImageLabel = nil
	end
end

local function createSpectateScreenMirror(targetDesk: Model)
	destroySpectateScreenMirror()

	local targetScreen = targetDesk:FindFirstChild("SCREEN")
	if not targetScreen or not targetScreen:IsA("BasePart") then
		return
	end

	local surfaceGui = Instance.new("SurfaceGui")
	surfaceGui.Name = "SpectateMirror"
	surfaceGui.Adornee = targetScreen
	surfaceGui.Face = Enum.NormalId.Front
	surfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
	surfaceGui.CanvasSize = Vector2.new(Config.SCREEN_W, Config.SCREEN_H)
	surfaceGui.AlwaysOnTop = true
	surfaceGui.LightInfluence = 0
	surfaceGui.Brightness = 2
	surfaceGui.MaxDistance = 0
	surfaceGui.Parent = playerGui

	local imageLabel = Instance.new("ImageLabel")
	imageLabel.Name = "Screen"
	imageLabel.Size = UDim2.fromScale(1, 1)
	imageLabel.BackgroundColor3 = THEME.ScreenBackground
	imageLabel.BorderSizePixel = 0
	imageLabel.ScaleType = Enum.ScaleType.Stretch
	imageLabel.ResampleMode = Enum.ResamplerMode.Pixelated
	imageLabel.Parent = surfaceGui

	spectateState.targetScreenGui = surfaceGui
	spectateState.targetScreenImageLabel = imageLabel
end

local function setCharacterVisible(visible: boolean)
	local character = player.Character
	if not character then
		return
	end

	local transparency = visible and 0 or 1

	for _, obj in character:GetDescendants() do
		if obj:IsA("BasePart") then
			obj.LocalTransparencyModifier = transparency
		elseif obj:IsA("Decal") or obj:IsA("Texture") then
			obj.Transparency = transparency
		end
	end
end

player.CharacterAdded:Connect(function()
	if spectateState.active then
		task.defer(function()
			setCharacterVisible(false)
		end)
	end
end)

local function showMessage(title: string, text: string, color: Color3?, duration: number?)
	if not ui or not ui.messageFrame then
		return
	end

	duration = duration or 2.5

	ui.messageTitle.Text = title
	ui.messageBody.Text = text
	ui.messageTitle.TextColor3 = color or THEME.Text
	ui.messageFrame.Visible = true

	local token = os.clock()
	ui._messageToken = token

	task.delay(duration, function()
		if not ui or ui._messageToken ~= token then
			return
		end

		ui.messageFrame.Visible = false
	end)
end

local function getSkyboxByName(name: string)
	for _, skyData in ipairs(Skyboxes) do
		if skyData.Name == name then
			return skyData
		end
	end

	return nil
end

local function createSkyFromData(name: string, data: { [string]: any }): Sky
	local sky = Instance.new("Sky")
	sky.Name = name

	for _, prop in SKY_PROPS do
		local value = data[prop]
		if value ~= nil then
			(sky :: any)[prop] = value
		end
	end

	return sky
end

local function applySkybox(skyData)
	for _, child in Lighting:GetChildren() do
		if child:IsA("Sky") then
			child:Destroy()
		end
	end

	local sky = createSkyFromData(skyData.Name, skyData)
	sky.Parent = Lighting
end

local function applySkyboxByName(name: string)
	local skyData = getSkyboxByName(name)
	if skyData then
		applySkybox(skyData)
	end
end

local function resetCamera()
	cameraOffset = Vector2.zero
	currentCamera.FieldOfView = CAMERA_FOV_DEFAULT
end

local function applyPanDelta(delta: Vector2)
	cameraOffset = clampCameraOffset(
		Vector2.new(cameraOffset.X - delta.X * CAMERA_DRAG_SENS, cameraOffset.Y + delta.Y * CAMERA_DRAG_SENS)
	)
end

local function updateCamera()
	local offset = baseCFrame.RightVector * cameraOffset.X + baseCFrame.UpVector * cameraOffset.Y
	currentCamera.CFrame = baseCFrame + offset
end

local function disableCoreGui()
	for _, coreGuiType in Enum.CoreGuiType:GetEnumItems() do
		if coreGuiType ~= Enum.CoreGuiType.All then
			attemptRepeatedly(function()
				StarterGui:SetCoreGuiEnabled(coreGuiType, false)
			end)
		end
	end

	attemptRepeatedly(function()
		StarterGui:SetCore("TopbarEnabled", false)
	end)
end

local function setTopbarVisible(visible: boolean)
	topbarVisible = visible

	for _, icon in icons do
		icon:setEnabled(visible)
		if not visible then
			icon:deselect()
		end
	end
end

local function ensureSpectateImage(width: number, height: number): EditableImage
	local existing = spectateState.image
	if existing then
		local size = existing.Size
		if size.X == width and size.Y == height then
			return existing
		end
	end

	local newImage = AssetService:CreateEditableImage({
		Size = Vector2.new(width, height),
	})
	spectateState.image = newImage

	local content = Content.fromObject(newImage)
	ui.imageLabel.ImageContent = content

	if spectateState.targetScreenImageLabel then
		spectateState.targetScreenImageLabel.ImageContent = content
	end

	return newImage
end

local function applySpectateFrame(result)
	if not result or not result.frame then
		return
	end

	local frame = result.frame
	local previousImage = spectateState.image
	local image = ensureSpectateImage(frame.width, frame.height)

	image:WritePixelsBuffer(Vector2.zero, Vector2.new(frame.width, frame.height), frame.buffer)

	if image ~= previousImage then
		local content = Content.fromObject(image)
		ui.imageLabel.ImageContent = content

		if spectateState.targetScreenImageLabel then
			spectateState.targetScreenImageLabel.ImageContent = content
		end
	end

	if result.cameraCFrame then
		baseCFrame = result.cameraCFrame
	end

	if result.skyboxName then
		applySkyboxByName(result.skyboxName)
	end
end

local function stopSpectating()
	if not spectateState.active then
		return
	end

	remote:InvokeServer("StopSpectate")

	if spectateState.targetDesk then
		setModelVisibleLocal(spectateState.targetDesk:FindFirstChild("Rig"), true)
	end

	destroySpectateScreenMirror()

	spectateState.targetUserId = nil
	spectateState.targetName = nil
	spectateState.targetDesk = nil
	spectateState.image = nil
	spectateState.active = false

	ui.imageLabel.ImageContent = Content.fromObject(machine.display)

	baseCFrame = cameraPart.CFrame
	resetCamera()
	applySkyboxByName(localSkyboxName)

	setCharacterVisible(true)

	showMessage("Spectate", "Stopped spectating.", THEME.MutedText)
end

local function startSpectating(targetUserId: number)
	local result = remote:InvokeServer("StartSpectate", targetUserId)
	if not result or not result.ok then
		showMessage("Spectate Failed", result and result.message or "Could not spectate.", THEME.Danger)
		return
	end

	spectateState.targetUserId = result.targetUserId
	spectateState.targetName = result.targetName
	spectateState.active = true

	local targetDesk = getDeskByUserId(result.targetUserId)
	spectateState.targetDesk = targetDesk

	if targetDesk then
		setModelVisibleLocal(targetDesk:FindFirstChild("Rig"), false)
		createSpectateScreenMirror(targetDesk)
	end

	if result.cameraCFrame then
		baseCFrame = result.cameraCFrame
	end
	cameraOffset = Vector2.zero

	if result.skyboxName then
		applySkyboxByName(result.skyboxName)
	end

	applySpectateFrame(result)
	setCharacterVisible(false)

	showMessage(
		"Spectating",
		("Now spectating %s."):format(result.targetDisplayName or result.targetName or "unknown"),
		THEME.Success
	)
end

local function pullSpectateFrame()
	if not spectateState.active then
		return
	end

	local result = remote:InvokeServer("GetSpectateFrame")
	if not result or not result.ok then
		showMessage("Spectate Ended", result and result.message or "Spectate ended.", THEME.Warning)
		stopSpectating()
		return
	end

	if spectateState.targetUserId ~= result.targetUserId then
		local targetDesk = result.targetUserId and getDeskByUserId(result.targetUserId) or nil

		if spectateState.targetDesk and spectateState.targetDesk ~= targetDesk then
			setModelVisibleLocal(spectateState.targetDesk:FindFirstChild("Rig"), true)
		end

		spectateState.targetUserId = result.targetUserId
		spectateState.targetDesk = targetDesk

		if targetDesk then
			setModelVisibleLocal(targetDesk:FindFirstChild("Rig"), false)
			createSpectateScreenMirror(targetDesk)
		else
			destroySpectateScreenMirror()
		end
	end

	applySpectateFrame(result)
end

local function pushOwnFrame()
	if spectateState.active then
		return
	end

	if not machine:isPowered() then
		return
	end

	local display = machine.display
	if not display then
		return
	end

	local size = display.Size
	local pixels = display:ReadPixelsBuffer(Vector2.zero, size)

	remote:InvokeServer("PushFrame", {
		width = size.X,
		height = size.Y,
		buffer = pixels,
	})
end

local function destroySpectateDropdownIcons()
	for _, icon in spectateDropdownIcons do
		pcall(function()
			icon:destroy()
		end)
	end

	table.clear(spectateDropdownIcons)
end

local function trackSpectateDropdownIcon(icon)
	table.insert(spectateDropdownIcons, icon)
	return icon
end

local function rebuildSpectateDropdown()
	local result = remote:InvokeServer("GetMenuData")
	if not result or not ui or not ui.spectateIcon then
		return
	end

	destroySpectateDropdownIcons()

	local dropdownIcons = {}
	local allowed = result.self.spectatorsAllowed

	local toggleIcon = trackSpectateDropdownIcon(
		Icon.new()
			:setLabel(("Spectators Allowed: %s"):format(allowed and "True" or "False"))
			:oneClick(true)
			:autoDeselect(true)
	)

	toggleIcon.selected:Connect(function()
		local response = remote:InvokeServer("SetSpectatorsAllowed", not allowed)
		if response and response.ok then
			showMessage(
				"Spectate Settings",
				("Spectators allowed: %s"):format(response.spectatorsAllowed and "True" or "False"),
				response.spectatorsAllowed and THEME.Success or THEME.Warning
			)
			rebuildSpectateDropdown()
		end
	end)

	table.insert(dropdownIcons, toggleIcon)

	local stopIcon = trackSpectateDropdownIcon(Icon.new():setLabel("Stop Spectating"):oneClick(true):autoDeselect(true))

	stopIcon.selected:Connect(function()
		stopSpectating()
		rebuildSpectateDropdown()
	end)

	table.insert(dropdownIcons, stopIcon)

	for _, entry in ipairs(result.players) do
		local suffix = entry.spectatorsAllowed and "" or " [NOT ALLOWED]"
		local playerIcon = trackSpectateDropdownIcon(
			Icon.new()
				:setLabel(("%s (@%s)%s"):format(entry.displayName, entry.name, suffix))
				:setImage(getHeadshot(entry.userId))
				:oneClick(true)
				:autoDeselect(true)
		)

		playerIcon.selected:Connect(function()
			if not entry.spectatorsAllowed then
				showMessage(
					"Spectate Blocked",
					("%s does not allow spectators."):format(entry.displayName),
					THEME.Danger
				)
				return
			end

			startSpectating(entry.userId)
			rebuildSpectateDropdown()
		end)

		table.insert(dropdownIcons, playerIcon)
	end

	ui.spectateIcon:setDropdown(dropdownIcons)
end

local function updateStage()
	local powered = machine:isPowered()
	ui.offOverlay.Visible = not powered

	local stage = powered and machine:getBootStage() or "OFFLINE"
	local color = STAGE_COLORS[stage] or (powered and THEME.Warning or THEME.Danger)

	ui.statusIcon:setLabel("● " .. stage)
	ui.statusIcon:setTextColor(color)
end

local function updateStats()
	if not ui.statsPanel.Visible then
		return
	end

	if not machine:isPowered() then
		ui.statsLabel.Text = "POWERED OFF"
		return
	end

	local stats = machine:getStats()
	local cpu = stats.cpuStats or {}
	local ram = stats.ramStats or {}
	local hdd = stats.hddStats or {}
	local bus = stats.busStats or {}
	local gpu = stats.gpuStats or {}

	ui.statsLabel.Text = string.format(
		"Machina  [%s stats]\n\n"
			.. "Stage      %s\n"
			.. "Uptime     %.1fs\n"
			.. "CPU cycles %d\n"
			.. "CPU instrs %d\n"
			.. "RAM r/w    %d / %d\n"
			.. "HDD r/w    %d / %d\n"
			.. "Bus IRQs   %d\n"
			.. "GPU flush  %d",
		STATS_TOGGLE_KEY.Name,
		tostring(stats.bootStage),
		stats.uptime or 0,
		cpu.cycles or 0,
		cpu.instructions or 0,
		ram.reads or 0,
		ram.writes or 0,
		hdd.reads or 0,
		hdd.writes or 0,
		bus.irqFired or 0,
		gpu.flushes or 0
	)
end

local function powerOn()
	if machine:isPowered() then
		return
	end

	machine:powerOn()
	updateStage()
end

local function shutdown()
	if not machine:isPowered() then
		return
	end

	machine:shutdown()
	updateStage()
end

local function reboot()
	if not machine:isPowered() then
		return
	end

	machine:reboot()
	updateStage()
end

local function createSkyboxDropdown()
	local entries = table.clone(Skyboxes)
	table.sort(entries, function(a, b)
		return a.Name < b.Name
	end)

	local skyIcons = {}
	for _, skyData in entries do
		local skyIcon = Icon.new():setLabel(skyData.Name):oneClick(true):autoDeselect(true)
		skyIcon.selected:Connect(function()
			applySkybox(skyData)

			local response = remote:InvokeServer("SetSkybox", skyData.Name)
			if response and response.ok and type(response.skyboxName) == "string" then
				localSkyboxName = response.skyboxName
			else
				localSkyboxName = skyData.Name
			end

			showMessage("Skybox", ("Skybox set to %s."):format(localSkyboxName), THEME.Success)
		end)
		table.insert(skyIcons, skyIcon)
	end

	return registerIcon(
		Icon.new()
			:setLabel("Skybox")
			:align("Left")
			:autoDeselect(true)
			:modifyTheme({ "Dropdown", "MaxIcons", 6 })
			:modifyChildTheme({ "Widget", "MinimumWidth", 170 })
			:setDropdown(skyIcons)
	)
end

local function createSpectateIcon()
	return registerIcon(
		Icon.new()
			:setLabel("Spectate")
			:setImage(7035631382)
			:setImageScale(0.6)
			:align("Left")
			:autoDeselect(true)
			:modifyTheme({ "Dropdown", "MaxIcons", 8 })
			:modifyChildTheme({ "Widget", "MinimumWidth", 220 })
	)
end

local function buildGui()
	local existing = playerGui:FindFirstChild("MachinaGui")
	if existing then
		existing:Destroy()
	end

	local gui = create("ScreenGui", {
		Name = "MachinaGui",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = 1000,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	}, playerGui)

	local surfaceGui = create("SurfaceGui", {
		Name = "MachinaSurface",
		Adornee = screen,
		ResetOnSpawn = false,
		Face = Enum.NormalId.Front,
		SizingMode = Enum.SurfaceGuiSizingMode.FixedSize,
		CanvasSize = Vector2.new(Config.SCREEN_W, Config.SCREEN_H),
		AlwaysOnTop = true,
		LightInfluence = 0,
		Brightness = 2,
		MaxDistance = 0,
	}, playerGui)

	local imageLabel = create("ImageLabel", {
		Name = "Screen",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = THEME.ScreenBackground,
		BorderSizePixel = 0,
		ScaleType = Enum.ScaleType.Stretch,
		ResampleMode = Enum.ResamplerMode.Pixelated,
	}, surfaceGui)

	local offOverlay = create("TextButton", {
		Name = "OffOverlay",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(5, 6, 9),
		BackgroundTransparency = 0.15,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Font = Enum.Font.GothamMedium,
		Text = "Click to boot",
		TextColor3 = THEME.Text,
		TextSize = 14,
		ZIndex = 4,
	}, surfaceGui)

	create("UIStroke", {
		Color = Color3.fromRGB(0, 0, 0),
		Transparency = 0.35,
		Thickness = 1.5,
	}, offOverlay)

	create("TextLabel", {
		Name = "OffHint",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -22),
		Size = UDim2.fromOffset(420, 28),
		BackgroundTransparency = 1,
		Font = Enum.Font.Gotham,
		Text = ("%s stats  |  %s topbar"):format(STATS_TOGGLE_KEY.Name, TOPBAR_TOGGLE_KEY.Name),
		TextColor3 = THEME.MutedText,
		TextSize = 8,
		TextWrapped = true,
		ZIndex = 5,
	}, offOverlay)

	local statsPanel = create("Frame", {
		Name = "StatsPanel",
		Position = UDim2.fromOffset(14, 60),
		Size = UDim2.fromOffset(340, 210),
		BackgroundColor3 = Color3.fromRGB(9, 12, 17),
		BackgroundTransparency = 0.08,
		BorderSizePixel = 0,
		Visible = false,
		ZIndex = 10,
	}, gui)

	create("UICorner", { CornerRadius = UDim.new(0, 10) }, statsPanel)
	create("UIStroke", { Color = Color3.fromRGB(40, 46, 58), Transparency = 0.15, Thickness = 1 }, statsPanel)
	create("UIPadding", {
		PaddingTop = UDim.new(0, 12),
		PaddingBottom = UDim.new(0, 12),
		PaddingLeft = UDim.new(0, 12),
		PaddingRight = UDim.new(0, 12),
	}, statsPanel)

	local statsLabel = create("TextLabel", {
		Name = "StatsLabel",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Font = Enum.Font.Code,
		Text = "",
		TextColor3 = THEME.Text,
		TextSize = 17,
		TextWrapped = false,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		ZIndex = 11,
	}, statsPanel)

	local cameraHint = create("Frame", {
		Name = "CameraHint",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 0.98, 0),
		AutomaticSize = Enum.AutomaticSize.XY,
		BackgroundColor3 = Color3.fromRGB(20, 24, 32),
		BackgroundTransparency = 0.05,
		BorderSizePixel = 0,
		ZIndex = 20,
	}, gui)

	create("UICorner", { CornerRadius = UDim.new(0, 14) }, cameraHint)
	create("UIStroke", { Color = Color3.fromRGB(60, 70, 90), Transparency = 0.2, Thickness = 1 }, cameraHint)
	create("UIPadding", {
		PaddingTop = UDim.new(0, 10),
		PaddingBottom = UDim.new(0, 10),
		PaddingLeft = UDim.new(0, 14),
		PaddingRight = UDim.new(0, 14),
	}, cameraHint)
	create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 10),
	}, cameraHint)

	local hintIcon = create("Frame", {
		Size = UDim2.fromOffset(28, 28),
		BackgroundColor3 = Color3.fromRGB(40, 55, 90),
		BackgroundTransparency = 0.2,
		BorderSizePixel = 0,
	}, cameraHint)
	create("UICorner", { CornerRadius = UDim.new(1, 0) }, hintIcon)
	create("TextLabel", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		Text = "⟲",
		TextColor3 = Color3.fromRGB(150, 180, 255),
		TextSize = 16,
	}, hintIcon)

	local textContainer = create("Frame", {
		AutomaticSize = Enum.AutomaticSize.XY,
		BackgroundTransparency = 1,
	}, cameraHint)
	create("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		Padding = UDim.new(0, 2),
	}, textContainer)
	create("TextLabel", {
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.XY,
		Font = Enum.Font.GothamMedium,
		Text = "Camera & Controls",
		TextColor3 = THEME.Text,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, textContainer)
	create("TextLabel", {
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.XY,
		Font = Enum.Font.Gotham,
		Text = "ALT+LMB drag = pan  •  ALT+Scroll = zoom  •  ALT+R = reset",
		TextColor3 = THEME.MutedText,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, textContainer)

	local messageFrame = create("Frame", {
		Name = "MessageFrame",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 0.98, 0),
		AutomaticSize = Enum.AutomaticSize.XY,
		BackgroundColor3 = Color3.fromRGB(20, 24, 32),
		BackgroundTransparency = 0.05,
		BorderSizePixel = 0,
		Visible = false,
		ZIndex = 30,
	}, gui)

	create("UICorner", { CornerRadius = UDim.new(0, 14) }, messageFrame)
	create("UIStroke", { Color = Color3.fromRGB(60, 70, 90), Transparency = 0.2, Thickness = 1 }, messageFrame)
	create("UIPadding", {
		PaddingTop = UDim.new(0, 10),
		PaddingBottom = UDim.new(0, 10),
		PaddingLeft = UDim.new(0, 14),
		PaddingRight = UDim.new(0, 14),
	}, messageFrame)
	create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 10),
	}, messageFrame)

	local messageIcon = create("Frame", {
		Name = "Icon",
		Size = UDim2.fromOffset(28, 28),
		BackgroundColor3 = Color3.fromRGB(40, 55, 90),
		BackgroundTransparency = 0.2,
		BorderSizePixel = 0,
	}, messageFrame)
	create("UICorner", { CornerRadius = UDim.new(1, 0) }, messageIcon)
	create("TextLabel", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		Text = "i",
		TextColor3 = Color3.fromRGB(150, 180, 255),
		TextSize = 16,
		ZIndex = 31,
	}, messageIcon)

	local messageTextContainer = create("Frame", {
		Name = "TextContainer",
		AutomaticSize = Enum.AutomaticSize.XY,
		BackgroundTransparency = 1,
	}, messageFrame)
	create(
		"UIListLayout",
		{ FillDirection = Enum.FillDirection.Vertical, Padding = UDim.new(0, 2) },
		messageTextContainer
	)

	local messageTitle = create("TextLabel", {
		Name = "Title",
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.XY,
		Font = Enum.Font.GothamMedium,
		Text = "Message",
		TextColor3 = THEME.Text,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 31,
	}, messageTextContainer)

	local messageBody = create("TextLabel", {
		Name = "Body",
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.XY,
		Font = Enum.Font.Gotham,
		Text = "",
		TextColor3 = THEME.MutedText,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 31,
	}, messageTextContainer)

	local statusIcon = registerIcon(Icon.new():setLabel("● OFFLINE"):setTextColor(THEME.Danger):align("Left"))
	local statsIcon = registerIcon(Icon.new():setLabel("Stats"):align("Left"))
	local skyboxIcon = createSkyboxDropdown()
	local spectateIcon = createSpectateIcon()
	local rebootIcon = registerIcon(Icon.new():setLabel("Reboot"):align("Right"):oneClick())
	local shutdownIcon = registerIcon(Icon.new():setLabel("Shutdown"):align("Right"):oneClick())

	return {
		gui = gui,
		surfaceGui = surfaceGui,
		imageLabel = imageLabel,
		offOverlay = offOverlay,
		statsPanel = statsPanel,
		statsLabel = statsLabel,
		cameraHint = cameraHint,
		messageFrame = messageFrame,
		messageTitle = messageTitle,
		messageBody = messageBody,
		statusIcon = statusIcon,
		statsIcon = statsIcon,
		skyboxIcon = skyboxIcon,
		spectateIcon = spectateIcon,
		rebootIcon = rebootIcon,
		shutdownIcon = shutdownIcon,
	}
end

local function showCameraHint()
	local frame = ui.cameraHint
	local stroke = frame:FindFirstChildOfClass("UIStroke")
	frame.Visible = true

	task.delay(8, function()
		if not frame.Parent then
			return
		end

		for i = 1, 15 do
			local t = i / 15
			frame.BackgroundTransparency = lerp(0.05, 1, t)

			if stroke then
				stroke.Transparency = lerp(0.2, 1, t)
			end

			for _, descendant in frame:GetDescendants() do
				if descendant:IsA("TextLabel") then
					descendant.TextTransparency = t
				end
			end

			task.wait(0.025)
		end

		frame.Visible = false
	end)
end

local function setupInput()
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then
			return
		end

		if input.KeyCode == STATS_TOGGLE_KEY then
			local visible = not ui.statsPanel.Visible
			ui.statsPanel.Visible = visible

			if visible then
				ui.statsIcon:select()
				updateStats()
			else
				ui.statsIcon:deselect()
			end
		elseif input.KeyCode == TOPBAR_TOGGLE_KEY then
			setTopbarVisible(not topbarVisible)
		elseif input.KeyCode == Enum.KeyCode.R and UserInputService:IsKeyDown(Enum.KeyCode.LeftAlt) then
			resetCamera()
		elseif
			input.UserInputType == Enum.UserInputType.MouseButton1 and UserInputService:IsKeyDown(Enum.KeyCode.LeftAlt)
		then
			isPanning = true
			lastMousePos = Vector2.new(input.Position.X, input.Position.Y)
		end

		if input.UserInputType == Enum.UserInputType.Keyboard and machine and machine.isPowered and machine:isPowered() then
			local emuKey = ROBLOX_KEYCODE_TO_EMU_KEY[input.KeyCode]
			if emuKey then
				machine:keyDown(emuKey)
			end
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			isPanning = false
		elseif input.UserInputType == Enum.UserInputType.Keyboard and machine and machine.isPowered and machine:isPowered() then
			local emuKey = ROBLOX_KEYCODE_TO_EMU_KEY[input.KeyCode]
			if emuKey then
				machine:keyUp(emuKey)
			end
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			if isPanning then
				local position = Vector2.new(input.Position.X, input.Position.Y)
				applyPanDelta(position - lastMousePos)
				lastMousePos = position
			end
		elseif
			input.UserInputType == Enum.UserInputType.MouseWheel and UserInputService:IsKeyDown(Enum.KeyCode.LeftAlt)
		then
			currentCamera.FieldOfView =
				math.clamp(currentCamera.FieldOfView - input.Position.Z * SCROLL_STEP, CAMERA_FOV_MIN, CAMERA_FOV_MAX)
		end
	end)
end

local function setupIcons()
	ui.offOverlay.Activated:Connect(powerOn)

	ui.statsIcon.selected:Connect(function()
		ui.statsPanel.Visible = true
		updateStats()
	end)

	ui.statsIcon.deselected:Connect(function()
		ui.statsPanel.Visible = false
	end)

	ui.rebootIcon.selected:Connect(reboot)
	ui.shutdownIcon.selected:Connect(shutdown)

	ui.spectateIcon.selected:Connect(function()
		rebuildSpectateDropdown()
	end)

	Players.PlayerAdded:Connect(function()
		task.defer(rebuildSpectateDropdown)
	end)

	Players.PlayerRemoving:Connect(function(leavingPlayer)
		if spectateState.active and spectateState.targetUserId == leavingPlayer.UserId then
			stopSpectating()
			showMessage("Spectate Ended", ("%s left the game."):format(leavingPlayer.DisplayName), THEME.Warning)
		end

		task.defer(rebuildSpectateDropdown)
	end)

	rebuildSpectateDropdown()
end

local function main()
	ui = buildGui()
	showCameraHint()

	local editableImage = AssetService:CreateEditableImage({
		Size = Vector2.new(Config.SCREEN_W, Config.SCREEN_H),
	})
	ui.imageLabel.ImageContent = Content.fromObject(editableImage)

	machine = PcSystem.new(Config)
	machine.display = editableImage
	machine:setFramePresenter(function(pixelBuffer, width, height)
		editableImage:WritePixelsBuffer(Vector2.zero, Vector2.new(width, height), pixelBuffer)
	end)

	setupInput()
	setupIcons()

	currentCamera.CameraType = Enum.CameraType.Scriptable
	baseCFrame = cameraPart.CFrame
	currentCamera.CFrame = baseCFrame
	currentCamera.FieldOfView = CAMERA_FOV_DEFAULT

	local menuData = remote:InvokeServer("GetMenuData")
	local initialSkybox = menuData and menuData.self and menuData.self.skyboxName or DEFAULT_SKYBOX
	localSkyboxName = initialSkybox
	applySkyboxByName(initialSkybox)

	setModelVisibleLocal(deskInstance:FindFirstChild("Rig"), false)
	task.defer(disableCoreGui)

	if AUTO_POWER then
		task.defer(powerOn)
	else
		updateStage()
	end

	local stageTimer = 0
	local statsTimer = 0

	RunService.Heartbeat:Connect(function(dt)
		updateCamera()

		stageTimer += dt
		if stageTimer >= STAGE_RATE then
			stageTimer = 0
			updateStage()
		end

		statsTimer += dt
		if statsTimer >= STATS_RATE then
			statsTimer = 0
			updateStats()
		end

		lastPush += dt
		if lastPush >= FRAME_PUSH_RATE then
			lastPush = 0
			pushOwnFrame()
		end

		lastPull += dt
		if lastPull >= FRAME_PULL_RATE then
			lastPull = 0
			pullSpectateFrame()
		end
	end)
end

main()