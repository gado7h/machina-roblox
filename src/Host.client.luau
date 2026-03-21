--This is only for local repository and should be created by users
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")
local AssetService = game:GetService("AssetService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local currentCamera = workspace.CurrentCamera

local Icon = require(script.Parent.TopbarPlus)
local Skyboxes = require(script.Parent.Skyboxes)

local deskInstance = workspace:WaitForChild(`{player.Name}_DESK`)
local cameraPart: Part = deskInstance:WaitForChild("CAM")
local screen: Part = deskInstance:WaitForChild("SCREEN")

local Config = require(script.Parent.Parent.Config)
local PcSystem = require(script.Parent.Parent.platforms.x86.PcSystem)

local DEFAULT_SKYBOX = "Baltic Dune"

local AUTO_POWER = true

local TOPBAR_TOGGLE_KEY = Enum.KeyCode.F5
local STATS_TOGGLE_KEY = Enum.KeyCode.F6

local SCROLL_STEP = 6
local CAMERA_DRAG_SENS = 0.01
local CAMERA_FOV_DEFAULT = 75
local CAMERA_FOV_MIN = 5
local CAMERA_FOV_MAX = 85
local CAMERA_BOUNDS_X = 1.4
local CAMERA_BOUNDS_Y = 0.9

local STATS_RATE = 0.5 
local STAGE_RATE = 0.15 

local THEME = {
	Text = Color3.fromRGB(238, 241, 245),
	MutedText = Color3.fromRGB(138, 147, 160),
	Success = Color3.fromRGB(99, 208, 141),
	Warning = Color3.fromRGB(255, 191, 92),
	Danger = Color3.fromRGB(255, 110, 110),
	ScreenBackground = Color3.fromRGB(0, 0, 0),
}

local SKY_PROPS = {
	"SkyboxBk",
	"SkyboxDn",
	"SkyboxFt",
	"SkyboxLf",
	"SkyboxRt",
	"SkyboxUp",
	"SunAngularSize",
	"MoonAngularSize",
	"StarCount",
	"CelestialBodiesShown",
}

local function getSkyboxByName(name: string)
	for _, sky in ipairs(Skyboxes) do
		if sky.Name == name then
			return sky
		end
	end
	return false
end

local function createSkyFromData(name: string, data: {[string]: any}): Sky
	local sky = Instance.new("Sky")
	sky.Name = name

	for _, prop in SKY_PROPS do
		local value = data[prop]
		if value ~= nil then
			sky[prop] = value
		end
	end

	return sky
end

local machine
local ui
local icons = {}
local topbarVisible = true

local baseCFrame: CFrame 
local cameraOffset = Vector2.zero
local isPanning = false
local lastMousePos = Vector2.zero

local function create(className: string, props: { [string]: any }, parent: Instance): Instance
	local inst = Instance.new(className)
	for k, v in props do
		inst[k] = v
	end
	inst.Parent = parent
	return inst
end

local function clampOffset(v: Vector2): Vector2
	return Vector2.new(
		math.clamp(v.X, -CAMERA_BOUNDS_X, CAMERA_BOUNDS_X),
		math.clamp(v.Y, -CAMERA_BOUNDS_Y, CAMERA_BOUNDS_Y)
	)
end

local function registerIcon(icon)
	icons[#icons + 1] = icon
	return icon
end

local function resetCamera()
	cameraOffset = Vector2.zero
	currentCamera.FieldOfView = CAMERA_FOV_DEFAULT
end

local function applyPanDelta(delta: Vector2)
	cameraOffset = clampOffset(
		Vector2.new(cameraOffset.X - delta.X * CAMERA_DRAG_SENS, cameraOffset.Y + delta.Y * CAMERA_DRAG_SENS)
	)
end

local function updateCamera()
	local offset = baseCFrame.RightVector * cameraOffset.X + baseCFrame.UpVector * cameraOffset.Y
	currentCamera.CFrame = baseCFrame + offset
end

local function disableCoreGui()
	local function attempt(fn)
		for _ = 1, 6 do
			if pcall(fn) then
				return
			end
			task.wait(0.2)
		end
	end

	for _, t in Enum.CoreGuiType:GetEnumItems() do
		if t ~= Enum.CoreGuiType.All then
			attempt(function()
				StarterGui:SetCoreGuiEnabled(t, false)
			end)
		end
	end

	attempt(function()
		StarterGui:SetCore("TopbarEnabled", false)
	end)
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

local function setTopbarVisible(visible: boolean)
	topbarVisible = visible
	for _, icon in icons do
		icon:setEnabled(visible)
		if not visible then
			icon:deselect()
		end
	end
end

local function createSkyboxDropdown()
	local entries = table.clone(Skyboxes)

	table.sort(entries, function(a, b)
		return a.Name < b.Name
	end)

	local skyIcons = {}
	for _, skyData in entries do
		local icon = Icon.new():setLabel(skyData.Name):oneClick(true):autoDeselect(true)
		icon.selected:Connect(function()
			applySkybox(skyData)
		end)
		skyIcons[#skyIcons + 1] = icon
	end

	return registerIcon(
		Icon.new()
			:setLabel("Skybox")
			:align("Left")
			:autoDeselect(true)
			:modifyTheme({ "Dropdown", "MaxIcons", 6 })
			:modifyChildTheme({ "Widget", "MinimumWidth", 140 })
			:setDropdown(skyIcons)
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
		Text = `{STATS_TOGGLE_KEY.Name} stats  |  {TOPBAR_TOGGLE_KEY.Name} topbar`,
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
	create("UIStroke", {
		Color = Color3.fromRGB(40, 46, 58),
		Transparency = 0.15,
		Thickness = 1,
	}, statsPanel)
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
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 16),
		AutomaticSize = Enum.AutomaticSize.XY,
		BackgroundColor3 = Color3.fromRGB(20, 24, 32),
		BackgroundTransparency = 0.05,
		BorderSizePixel = 0,
		ZIndex = 20,
	}, gui)

	create("UICorner", { CornerRadius = UDim.new(0, 14) }, cameraHint)
	create("UIStroke", {
		Color = Color3.fromRGB(60, 70, 90),
		Transparency = 0.2,
		Thickness = 1,
	}, cameraHint)
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

	local statusIcon = registerIcon(Icon.new():setLabel("● OFFLINE"):setTextColor(THEME.Danger):align("Left"))
	local statsIcon = registerIcon(Icon.new():setLabel("Stats"):align("Left"))
	local skyboxIcon = createSkyboxDropdown()
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
		statusIcon = statusIcon,
		statsIcon = statsIcon,
		skyboxIcon = skyboxIcon,
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
			frame.BackgroundTransparency = math.lerp(0.05, 1, t)
			if stroke then
				stroke.Transparency = math.lerp(0.2, 1, t)
			end
			for _, d in frame:GetDescendants() do
				if d:IsA("TextLabel") then
					d.TextTransparency = t
				end
			end
			task.wait(0.025)
		end
		frame.Visible = false
	end)
end

local STAGE_COLORS = {
	RUNNING = THEME.Success,
	FAULT = THEME.Danger,
}

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

	local s = machine:getStats()
	local cpu = s.cpuStats or {}
	local ram = s.ramStats or {}
	local hdd = s.hddStats or {}
	local bus = s.busStats or {}
	local gpu = s.gpuStats or {}

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
		tostring(s.bootStage),
		s.uptime or 0,
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
	machine:bindInput(UserInputService)
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
			input.UserInputType == Enum.UserInputType.MouseButton1
			and UserInputService:IsKeyDown(Enum.KeyCode.LeftAlt)
		then
			isPanning = true
			lastMousePos = Vector2.new(input.Position.X, input.Position.Y)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			isPanning = false
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			if isPanning then
				local pos = Vector2.new(input.Position.X, input.Position.Y)
				applyPanDelta(pos - lastMousePos)
				lastMousePos = pos
			end
		elseif
			input.UserInputType == Enum.UserInputType.MouseWheel
			and UserInputService:IsKeyDown(Enum.KeyCode.LeftAlt)
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
end

local function main()
	ui = buildGui()
	showCameraHint()

	local editableImage = AssetService:CreateEditableImage({
		Size = Vector2.new(Config.SCREEN_W, Config.SCREEN_H),
	})
	ui.imageLabel.ImageContent = Content.fromObject(editableImage)

	machine = PcSystem.new(Config, editableImage)

	setupInput()
	setupIcons()

	currentCamera.CameraType = Enum.CameraType.Scriptable
	baseCFrame = cameraPart.CFrame
	currentCamera.CFrame = baseCFrame
	currentCamera.FieldOfView = CAMERA_FOV_DEFAULT

	applySkybox(getSkyboxByName(DEFAULT_SKYBOX))
	deskInstance.Rig:Destroy()

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
	end)
end

main()