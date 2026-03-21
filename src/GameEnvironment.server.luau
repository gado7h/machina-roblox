local Players = game:GetService("Players")
Players.CharacterAutoLoads = false

local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local DESK_TEMPLATE = ServerStorage:WaitForChild("DESK_TEMPLATE")

local REMOTE_NAME = "MachinaRemote"
local DEFAULT_SKYBOX = "Baltic Dune"
local DEFAULT_SPECTATORS_ALLOWED = true
local DESK_SPACING = 200

local settingsStore = DataStoreService:GetDataStore("Machina_PlayerSettings_v1")

local remote = ReplicatedStorage:FindFirstChildOfClass("REMOTE_NAME")
if remote and not remote:IsA("RemoteFunction") then
	remote:Destroy()
	remote = nil
end

if not remote then
	remote = Instance.new("RemoteFunction")
	remote.Name = REMOTE_NAME
	remote.Parent = ReplicatedStorage
end

type PlayerSettings = {
	spectatorsAllowed: boolean,
	skyboxName: string,
}

type LiveFrame = {
	width: number,
	height: number,
	buffer: buffer,
	timestamp: number,
}

local nextDeskX = 0

local playerSettings: { [number]: PlayerSettings } = {}
local liveFrames: { [number]: LiveFrame } = {}

local viewerToTarget: { [number]: number } = {}
local targetToViewers: { [number]: { [number]: true } } = {}

local function getSettingsKey(userId: number): string
	return ("player_%d"):format(userId)
end

local function getDeskName(playerName: string): string
	return ("%s_DESK"):format(playerName)
end

local function getDeskByPlayer(player: Player): Model?
	local desk = workspace:FindFirstChild(getDeskName(player.Name))
	if desk and desk:IsA("Model") then
		return desk
	end

	return nil
end

local function getDeskCameraCFrame(player: Player): CFrame?
	local desk = getDeskByPlayer(player)
	if not desk then
		return nil
	end

	local cameraPart = desk:FindFirstChild("CAM")
	if cameraPart and cameraPart:IsA("BasePart") then
		return cameraPart.CFrame
	end

	return nil
end

local function getOrCreateSettings(userId: number): PlayerSettings
	local settings = playerSettings[userId]
	if settings then
		return settings
	end

	settings = {
		spectatorsAllowed = DEFAULT_SPECTATORS_ALLOWED,
		skyboxName = DEFAULT_SKYBOX,
	}
	playerSettings[userId] = settings

	return settings
end

local function loadSettings(player: Player)
	local loadedData = nil

	local ok, err = pcall(function()
		loadedData = settingsStore:GetAsync(getSettingsKey(player.UserId))
	end)

	if not ok then
		warn(("Failed to load settings for %s: %s"):format(player.Name, tostring(err)))
	end

	local settings = getOrCreateSettings(player.UserId)
	if type(loadedData) ~= "table" then
		return
	end

	if type(loadedData.spectatorsAllowed) == "boolean" then
		settings.spectatorsAllowed = loadedData.spectatorsAllowed
	end

	if type(loadedData.skyboxName) == "string" and loadedData.skyboxName ~= "" then
		settings.skyboxName = loadedData.skyboxName
	end
end

local function saveSettings(player: Player)
	local settings = playerSettings[player.UserId]
	if not settings then
		return
	end

	local ok, err = pcall(function()
		settingsStore:UpdateAsync(getSettingsKey(player.UserId), function()
			return {
				spectatorsAllowed = settings.spectatorsAllowed,
				skyboxName = settings.skyboxName,
			}
		end)
	end)

	if not ok then
		warn(("Failed to save settings for %s: %s"):format(player.Name, tostring(err)))
	end
end

local function applyDeskAttributes(player: Player)
	local desk = getDeskByPlayer(player)
	if not desk then
		return
	end

	local settings = getOrCreateSettings(player.UserId)

	desk:SetAttribute("OwnerUserId", player.UserId)
	desk:SetAttribute("OwnerName", player.Name)
	desk:SetAttribute("OwnerDisplayName", player.DisplayName)
	desk:SetAttribute("SpectatorsAllowed", settings.spectatorsAllowed)
	desk:SetAttribute("SkyboxName", settings.skyboxName)
end

local function removeViewer(viewerUserId: number)
	local targetUserId = viewerToTarget[viewerUserId]
	if not targetUserId then
		return
	end

	viewerToTarget[viewerUserId] = nil

	local viewers = targetToViewers[targetUserId]
	if not viewers then
		return
	end

	viewers[viewerUserId] = nil

	if next(viewers) == nil then
		targetToViewers[targetUserId] = nil
	end
end

local function clearTargetViewers(targetUserId: number)
	local viewers = targetToViewers[targetUserId]
	if not viewers then
		return
	end

	for viewerUserId in viewers do
		viewerToTarget[viewerUserId] = nil
	end

	targetToViewers[targetUserId] = nil
end

local function seatDeskRig(desk: Model, player: Player)
	local rig = desk:FindFirstChild("Rig")
	local seat = desk:FindFirstChild("Seat")

	if not rig or not rig:IsA("Model") or not seat or not seat:IsA("Seat") then
		return
	end

	local humanoid = rig:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	local ok, description = pcall(function()
		return Players:GetHumanoidDescriptionFromUserIdAsync(player.UserId)
	end)

	if ok and description then
		pcall(function()
			humanoid:ApplyDescriptionAsync(description)
		end)
	else
		warn(("Failed to get description for %s"):format(player.Name))
	end

	seat:Sit(humanoid)
end

local function spawnDeskForPlayer(player: Player)
	local desk = DESK_TEMPLATE:Clone()
	desk.Name = getDeskName(player.Name)
	desk.Parent = workspace
	desk:PivotTo(CFrame.new(nextDeskX, 0, 0))

	seatDeskRig(desk, player)
	applyDeskAttributes(player)

	nextDeskX += DESK_SPACING
end

local function destroyDeskForPlayer(player: Player)
	local desk = getDeskByPlayer(player)
	if not desk then
		return
	end

	desk:Destroy()
end

local function getMenuData(requestingPlayer: Player)
	local selfSettings = getOrCreateSettings(requestingPlayer.UserId)
	local entries = {}

	for _, otherPlayer in Players:GetPlayers() do
		if otherPlayer ~= requestingPlayer then
			local otherSettings = getOrCreateSettings(otherPlayer.UserId)

			table.insert(entries, {
				userId = otherPlayer.UserId,
				name = otherPlayer.Name,
				displayName = otherPlayer.DisplayName,
				spectatorsAllowed = otherSettings.spectatorsAllowed,
			})
		end
	end

	table.sort(entries, function(a, b)
		return string.lower(a.displayName) < string.lower(b.displayName)
	end)

	return {
		self = {
			spectatorsAllowed = selfSettings.spectatorsAllowed,
			skyboxName = selfSettings.skyboxName,
		},
		players = entries,
		currentTargetUserId = viewerToTarget[requestingPlayer.UserId],
	}
end

local function serializeFrame(frame: LiveFrame?)
	if not frame then
		return nil
	end

	return {
		width = frame.width,
		height = frame.height,
		buffer = frame.buffer,
	}
end

local function handleStartSpectate(player: Player, payload: any)
	local targetUserId = tonumber(payload)
	if not targetUserId then
		return {
			ok = false,
			message = "Invalid target.",
		}
	end

	local target = Players:GetPlayerByUserId(targetUserId)
	if not target or target == player then
		return {
			ok = false,
			message = "Invalid target.",
		}
	end

	local targetSettings = playerSettings[targetUserId]
	if not targetSettings or not targetSettings.spectatorsAllowed then
		return {
			ok = false,
			message = "Not allowed to spectate.",
		}
	end

	removeViewer(player.UserId)

	viewerToTarget[player.UserId] = targetUserId
	targetToViewers[targetUserId] = targetToViewers[targetUserId] or {}
	targetToViewers[targetUserId][player.UserId] = true

	return {
		ok = true,
		targetUserId = targetUserId,
		targetName = target.Name,
		targetDisplayName = target.DisplayName,
		cameraCFrame = getDeskCameraCFrame(target),
		skyboxName = targetSettings.skyboxName,
		frame = serializeFrame(liveFrames[targetUserId]),
	}
end

local function handleGetSpectateFrame(player: Player)
	local targetUserId = viewerToTarget[player.UserId]
	if not targetUserId then
		return {
			ok = false,
			message = "Not spectating.",
		}
	end

	local target = Players:GetPlayerByUserId(targetUserId)
	if not target then
		removeViewer(player.UserId)
		return {
			ok = false,
			message = "Target left.",
		}
	end

	local targetSettings = playerSettings[targetUserId]
	if not targetSettings or not targetSettings.spectatorsAllowed then
		removeViewer(player.UserId)
		return {
			ok = false,
			message = "Not allowed to spectate.",
		}
	end

	return {
		ok = true,
		targetUserId = targetUserId,
		cameraCFrame = getDeskCameraCFrame(target),
		skyboxName = targetSettings.skyboxName,
		frame = serializeFrame(liveFrames[targetUserId]),
	}
end

local function handlePushFrame(player: Player, payload: any)
	if type(payload) ~= "table" then
		return false
	end

	local width = payload.width
	local height = payload.height
	local frameBuffer = payload.buffer

	if type(width) ~= "number" or type(height) ~= "number" or typeof(frameBuffer) ~= "buffer" then
		return false
	end

	liveFrames[player.UserId] = {
		width = width,
		height = height,
		buffer = frameBuffer,
		timestamp = os.clock(),
	}

	return true
end

remote.OnServerInvoke = function(player: Player, action: string, payload: any)
	if action == "GetMenuData" then
		return getMenuData(player)
	end

	if action == "SetSpectatorsAllowed" then
		local settings = getOrCreateSettings(player.UserId)
		settings.spectatorsAllowed = payload == true

		applyDeskAttributes(player)

		if not settings.spectatorsAllowed then
			clearTargetViewers(player.UserId)
		end

		return {
			ok = true,
			spectatorsAllowed = settings.spectatorsAllowed,
		}
	end

	if action == "SetSkybox" then
		if type(payload) ~= "string" or payload == "" then
			return {
				ok = false,
				message = "Invalid skybox.",
			}
		end

		local settings = getOrCreateSettings(player.UserId)
		settings.skyboxName = payload
		applyDeskAttributes(player)

		return {
			ok = true,
			skyboxName = settings.skyboxName,
		}
	end

	if action == "StartSpectate" then
		return handleStartSpectate(player, payload)
	end

	if action == "StopSpectate" then
		removeViewer(player.UserId)
		return { ok = true }
	end

	if action == "PushFrame" then
		return handlePushFrame(player, payload)
	end

	if action == "GetSpectateFrame" then
		return handleGetSpectateFrame(player)
	end

	return {
		ok = false,
		message = ("Unknown action: %s"):format(tostring(action)),
	}
end

local function onPlayerAdded(player: Player)
	loadSettings(player)
	spawnDeskForPlayer(player)
end

local function onPlayerRemoving(player: Player)
	removeViewer(player.UserId)
	clearTargetViewers(player.UserId)

	liveFrames[player.UserId] = nil
	saveSettings(player)
	playerSettings[player.UserId] = nil

	destroyDeskForPlayer(player)
end

for _, player in Players:GetPlayers() do
	onPlayerAdded(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

game:BindToClose(function()
	for _, player in Players:GetPlayers() do
		saveSettings(player)
	end
end)