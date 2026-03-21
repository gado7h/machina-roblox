local Players = game:GetService("Players")
Players.CharacterAutoLoads = false

local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local DESK_TEMPLATE = ServerStorage.DESK_TEMPLATE
local remote = Instance.new("RemoteFunction")
remote.Parent = ReplicatedStorage

local settingsStore = DataStoreService:GetDataStore("Machina_PlayerSettings_v1")

local DEFAULT_SKYBOX = "Baltic Dune"
local DEFAULT_SPECTATORS_ALLOWED = true

local currentX = 0

local playerSettings = {} :: {
	[number]: {
		spectatorsAllowed: boolean,
		skyboxName: string,
	},
}

local liveFrames = {} :: {
	[number]: {
		width: number,
		height: number,
		buffer: buffer,
		timestamp: number,
	},
}

local viewerToTarget = {} :: { [number]: number }
local targetToViewers = {} :: { [number]: { [number]: true } }

local function getKey(userId: number): string
	return ("player_%d"):format(userId)
end

local function getDesk(player: Player): Model?
	return workspace:FindFirstChild(("%s_DESK"):format(player.Name))
end

local function loadSettings(player: Player)
	local data

	local ok, err = pcall(function()
		data = settingsStore:GetAsync(getKey(player.UserId))
	end)

	if not ok then
		warn("Failed to load settings for", player.Name, err)
	end

	data = type(data) == "table" and data or {}

	playerSettings[player.UserId] = {
		spectatorsAllowed = if data.spectatorsAllowed == nil
			then DEFAULT_SPECTATORS_ALLOWED
			else data.spectatorsAllowed,
		skyboxName = data.skyboxName or DEFAULT_SKYBOX,
	}
end

local function saveSettings(player: Player)
	local settings = playerSettings[player.UserId]
	if not settings then
		return
	end

	local ok, err = pcall(function()
		settingsStore:UpdateAsync(getKey(player.UserId), function()
			return {
				spectatorsAllowed = settings.spectatorsAllowed,
				skyboxName = settings.skyboxName,
			}
		end)
	end)

	if not ok then
		warn("Failed to save settings for", player.Name, err)
	end
end

local function applyDeskAttributes(player: Player)
	local desk = getDesk(player)
	local settings = playerSettings[player.UserId]
	if not desk or not settings then
		return
	end

	desk:SetAttribute("OwnerUserId", player.UserId)
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
	if viewers then
		viewers[viewerUserId] = nil
		if next(viewers) == nil then
			targetToViewers[targetUserId] = nil
		end
	end
end

local function onPlayerAdded(player: Player)
	loadSettings(player)

	local desk = DESK_TEMPLATE:Clone()
	desk.Parent = workspace
	desk:PivotTo(CFrame.new(currentX, 0, 0))
	desk.Name = `{player.Name}_DESK`

	local humanoid = desk.Rig.Humanoid
	local description = Players:GetHumanoidDescriptionFromUserIdAsync(player.UserId)
	humanoid:ApplyDescriptionAsync(description)
	desk.Seat:Sit(humanoid)

	applyDeskAttributes(player)

	currentX += 200
end

local function onPlayerRemoving(player: Player)
	removeViewer(player.UserId)
	targetToViewers[player.UserId] = nil
	liveFrames[player.UserId] = nil

	saveSettings(player)
	playerSettings[player.UserId] = nil

	local desk: Model? = workspace:FindFirstChild(`{player.Name}_DESK`)
	if desk then
		currentX = desk:GetPivot().X
		desk:Destroy()
	end
end

local function getMenuData(requestingPlayer: Player)
	local selfSettings = playerSettings[requestingPlayer.UserId]

	local playerEntries = {}

	for _, other in Players:GetPlayers() do
		if other ~= requestingPlayer then
			local settings = playerSettings[other.UserId]
			table.insert(playerEntries, {
				userId = other.UserId,
				name = other.Name,
				displayName = other.DisplayName,
				spectatorsAllowed = settings and settings.spectatorsAllowed or DEFAULT_SPECTATORS_ALLOWED,
			})
		end
	end

	table.sort(playerEntries, function(a, b)
		return string.lower(a.displayName) < string.lower(b.displayName)
	end)

	return {
		self = {
			spectatorsAllowed = selfSettings.spectatorsAllowed,
			skyboxName = selfSettings.skyboxName,
		},
		players = playerEntries,
		currentTargetUserId = viewerToTarget[requestingPlayer.UserId],
	}
end

remote.OnServerInvoke = function(player: Player, action: string, payload)
	if action == "GetMenuData" then
		return getMenuData(player)
	end

	if action == "SetSpectatorsAllowed" then
		local allowed = payload == true

		playerSettings[player.UserId].spectatorsAllowed = allowed
		applyDeskAttributes(player)

		if not allowed then
			local viewers = targetToViewers[player.UserId]
			if viewers then
				for viewerUserId in viewers do
					viewerToTarget[viewerUserId] = nil
				end
				targetToViewers[player.UserId] = nil
			end
		end

		return {
			ok = true,
			spectatorsAllowed = allowed,
		}
	end

	if action == "SetSkybox" then
		if type(payload) ~= "string" or payload == "" then
			return {
				ok = false,
				message = "Invalid skybox.",
			}
		end

		playerSettings[player.UserId].skyboxName = payload
		applyDeskAttributes(player)

		return {
			ok = true,
			skyboxName = payload,
		}
	end

	if action == "StartSpectate" then
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

		local settings = playerSettings[targetUserId]
		if not settings or not settings.spectatorsAllowed then
			return {
				ok = false,
				message = "Not allowed to spectate.",
			}
		end

		removeViewer(player.UserId)

		viewerToTarget[player.UserId] = targetUserId
		targetToViewers[targetUserId] = targetToViewers[targetUserId] or {}
		targetToViewers[targetUserId][player.UserId] = true

		local frame = liveFrames[targetUserId]
		local targetDesk = getDesk(target)

		return {
			ok = true,
			targetUserId = targetUserId,
			targetName = target.Name,
			targetDisplayName = target.DisplayName,
			cameraCFrame = targetDesk and targetDesk:WaitForChild("CAM").CFrame or nil,
			skyboxName = settings.skyboxName,
			frame = frame and {
				width = frame.width,
				height = frame.height,
				buffer = frame.buffer,
			} or nil,
		}
	end

	if action == "StopSpectate" then
		removeViewer(player.UserId)
		return { ok = true }
	end

	if action == "PushFrame" then
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

	if action == "GetSpectateFrame" then
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

		local settings = playerSettings[targetUserId]
		if not settings or not settings.spectatorsAllowed then
			removeViewer(player.UserId)
			return {
				ok = false,
				message = "Not allowed to spectate.",
			}
		end

		local frame = liveFrames[targetUserId]
		local targetDesk = getDesk(target)

		return {
			ok = true,
			targetUserId = targetUserId,
			cameraCFrame = targetDesk and targetDesk:WaitForChild("CAM").CFrame or nil,
			skyboxName = settings.skyboxName,
			frame = frame and {
				width = frame.width,
				height = frame.height,
				buffer = frame.buffer,
			} or nil,
		}
	end

	return {
		ok = false,
		message = ("Unknown action: %s"):format(tostring(action)),
	}
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
