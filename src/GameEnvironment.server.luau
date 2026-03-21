local Players = game:GetService("Players")
Players.CharacterAutoLoads = false

local ServerStorage = game:GetService("ServerStorage")
local DESK_TEMPLATE = ServerStorage.DESK_TEMPLATE

local currentX = 0

local function onPlayerAdded(player: Player)
	local desk = DESK_TEMPLATE:Clone()
	desk.Parent = workspace
	desk:PivotTo(CFrame.new(Vector3.new(currentX, 0, 0)))
	desk.Name = `{player.Name}_DESK`

	local humanoid = desk.Rig.Humanoid
	local description = Players:GetHumanoidDescriptionFromUserIdAsync(player.UserId)
	humanoid:ApplyDescriptionAsync(description)
	desk.Seat:Sit(humanoid)

	currentX += 200
end

local function onPlayerRemoving(player: Player)
	local desk: Model = workspace:FindFirstChild(`{player.Name}_DESK`)
	if desk then
		currentX = desk:GetPivot().X
		desk:Destroy()
	end
end

for _, player in Players:GetPlayers() do
	onPlayerAdded(player)
end
Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)
