-- Sessions: the server side of the game and the one place a player's run lives. It takes intents
-- from the Intent remote, changes that player's state with the shared Rules, and answers with the
-- new state on the Snapshot remote. Clients never change state themselves.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Rules = require(ReplicatedStorage.Rules)
local BestScore = require(script.Parent.BestScore)

local Remotes = ReplicatedStorage.Remotes

local INTENTS = {
	ready = true,
	start = true,
	up = true,
	down = true,
	left = true,
	right = true,
	wait = true,
	smoke = true,
}

local sessions = {} -- [Player] = that player's run state

local openSession

local function answerIntent(player, intent) -- server owns the state: check, apply Rules, reply
	if type(intent) ~= "string" or not INTENTS[intent] then
		return
	end
	local state = sessions[player]
	if state then
		local bestBefore = state.best
		Rules.act(state, intent)
		if state.best > bestBefore then
			task.spawn(BestScore.save, player.UserId, state.best)
		end
	elseif intent == "ready" then
		state = openSession(player)
	end
	if state then
		Remotes.Snapshot:FireClient(player, state)
	end
end

function openSession(player) -- yields while the saved best score loads
	local best = BestScore.load(player.UserId)
	if not player:IsDescendantOf(game) then
		return nil
	end
	sessions[player] = sessions[player] or Rules.newRun(best)
	return sessions[player]
end

Remotes.Intent.OnServerEvent:Connect(answerIntent)
Players.PlayerRemoving:Connect(function(player)
	sessions[player] = nil
end)
