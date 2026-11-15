-- BestScore: each player's best score in a DataStore. Every call is wrapped in pcall, so the game
-- plays on with a best of 0 when the store is unavailable (as it is in an unpublished place).

local DataStoreService = game:GetService("DataStoreService")

local BestScore = {}

local STORE_NAME = "DuskVaultBestScore"

local store = nil -- the DataStore, or false once it is known to be unavailable

function BestScore.load(userId) -- pcall GetAsync; 0 when the store is down
	local scores = BestScore.open()
	if not scores then
		return 0
	end
	local ok, saved = pcall(scores.GetAsync, scores, tostring(userId))
	if not ok then
		warn("BestScore: load failed, starting from 0:", saved)
		return 0
	end
	return if type(saved) == "number" then saved else 0
end

function BestScore.save(userId, score)
	local scores = BestScore.open()
	if not scores then
		return
	end
	local ok, problem = pcall(scores.UpdateAsync, scores, tostring(userId), function(saved)
		return math.max(if type(saved) == "number" then saved else 0, score)
	end)
	if not ok then
		warn("BestScore: save failed, best score kept for this session only:", problem)
	end
end

function BestScore.open()
	if store == nil then
		local ok, result = pcall(DataStoreService.GetDataStore, DataStoreService, STORE_NAME)
		store = if ok then result else false
		if not ok then
			warn("BestScore: no DataStore here, best scores last for the session:", result)
		end
	end
	return store
end

return BestScore
