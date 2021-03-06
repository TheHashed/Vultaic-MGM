arena = {
	readyTimer = Timer:create(),
	waterCheckTimer = Timer:create(),
	-- Player
	trainingAward = false
}
local waterCraftIDS = {
	[539] = true,
	[460] = true,
	[417] = true,
	[447] = true,
	[472] = true,
	[473] = true,
	[493] = true,
	[595] = true,
	[484] = true,
	[430] = true,
	[453] = true,
	[452] = true,
	[446] = true,
	[454] = true
}
spectate = {}
enterKey = next(getBoundKeys("enter_exit"))
addEvent("onClientJoinArena", true)
addEvent("onClientLeaveArena", true)
addEvent("onClientPlayerJoinArena", true)
addEvent("onClientPlayerLeaveArena", true)
addEvent("onClientArenaStateChanging", true)
addEvent("onClientArenaMapStarting", true)
addEvent("onClientArenaSpawn", true)
addEvent("onClientArenaWasted", true)
addEvent("onClientArenaGridCountdown", true)
addEvent("onClientArenaNextmapChanged", true)
addEvent("onClientArenaHunterReached", true)
addEvent("onClientArenaRequestSpectateStart", true)
addEvent("onClientArenaRequestSpectateStop", true)
addEvent("onClientArenaRequestSpectateEnd", true)
addEvent("onClientArenaPlayerStateChange", true)
addEvent("mapmanager:onMapLoad", true)
addEvent("racepickups:onClientPickupRacepickup", true)

addEventHandler("onClientJoinArena", resourceRoot,
function(data)
	-- Update synced data
	for i, v in pairs(data) do
		arena[i] = v
	end
	-- Gameplay functions
	setBlurLevel(0)
	setPedCanBeKnockedOffBike(localPlayer, false)
	-- Handlers
	addCommandHandler("suicide", requestKill)
	addCommandHandler("kill", requestKill)
	addEventHandler("mapmanager:onMapLoad", localPlayer, requestToptimes)
	addEventHandler("racepickups:onClientPickupRacepickup", localPlayer, handlePickupHit)
	-- Binds
	bindKey(enterKey, "down", "suicide")
	bindKey("b", "down", "manualspectate")
	-- UI stuff
	triggerEvent("radar:setVisible", localPlayer, true)
	triggerEvent("racehud:show", localPlayer, {state = data.state, mapName = data.mapInfo.mapName, nextMapName = data.nextMap, timeIsUpStartTick = getTickCount(), timeIsUpDuration = data.duration})
end)

addEventHandler("onClientLeaveArena", resourceRoot,
function()
	spectate.stop()
	-- Reset gameplay functions
	setPedCanBeKnockedOffBike(localPlayer, true)
	arena.waterCheckTimer:killTimer()
	arena.readyTimer:killTimer()
	gridCountdown(false)
	-- Handlers
	removeCommandHandler("suicide", requestKill)
	removeCommandHandler("kill", requestKill)
	removeEventHandler("mapmanager:onMapLoad", localPlayer, requestToptimes)
	removeEventHandler("racepickups:onClientPickupRacepickup", localPlayer, handlePickupHit)
	-- Binds
	unbindKey(enterKey, "down", "suicide")
	unbindKey("b", "down", "manualspectate")
	-- UI stuff
	triggerEvent("radar:setVisible", localPlayer, false)
	triggerEvent("racehud:hide", localPlayer)
	arena.timeIsUpStartTick = nil
	arena.timeIsUpTick = nil
end)

addEventHandler("onClientArenaStateChanging", resourceRoot,
function(currentState, newState, data)
	arena.state = newState and newState or arena.state
	if arena.state == "running" then
		arena.timeIsUpStartTick = getTickCount()
		arena.timeIsUpTick = arena.timeIsUpStartTick + data.duration
	end
end)

addEventHandler("onClientArenaMapStarting", resourceRoot,
function(mapInfo)
	arena.mapInfo = mapInfo
	arena.trainingAward = false
end)

function gridCountdown(countdown)
	if countdown == 0 then
		triggerEvent("racepickups:checkAllPickups", localPlayer)
		local vehicle = arena.vehicle or getPedOccupiedVehicle(localPlayer)
		if isElement(vehicle) then
			setElementFrozen(localPlayer, false)
			setElementFrozen(vehicle, false)
			setVehicleDamageProof(vehicle, false)
			setElementCollisionsEnabled(vehicle, true)
		end
	end
end
addEventHandler("onClientArenaGridCountdown", resourceRoot, gridCountdown)

addEventHandler("onClientArenaNextmapChanged", resourceRoot,
function(nextMap)
	arena.nextMap = nextMap or nil
end)

addEventHandler("onClientArenaSpawn", resourceRoot,
function(vehicle)
	arena.vehicle = vehicle
	spectate.stop()
	setCameraTarget(localPlayer)
	arena.readyTimer:setTimer(function()
		local cameraTarget = getCameraTarget()
		if isElement(cameraTarget) and cameraTarget == localPlayer and isPedInVehicle(localPlayer) then
			triggerServerEvent("onPlayerReady", localPlayer)
			removeVehicleNitro()
			fadeCamera(true)
			arena.readyTimer:killTimer()
		end
	end, 500, 0)
	arena.waterCheckTimer:setTimer(checkWater, 1000, 0)
	removeVehicleNitro()
	fixVehicle(arena.vehicle)
	toggleAllControls(true)
	triggerEvent("racepickups:updateVehicleWeapons", localPlayer)
end)

addEventHandler("onClientArenaWasted", resourceRoot,
function()
	spectate.start()
	arena.readyTimer:killTimer()
end)

addEventHandler("onClientArenaHunterReached", resourceRoot,
function(notifyMessage)
	resetFarClipDistance()
	resetFogDistance()
	resetWaterColor()
	resetWaterLevel()
	setGameSpeed(1)
	setGravity(0.008)
	resetSkyGradient()
	resetSunSize()
	resetHeatHaze()
	resetRainLevel()
	resetSunColor()
	resetWindVelocity()
	setWaveHeight(0)
	setTime(0, 0)
	setWeather(1)
	setCloudsEnabled(false)
	setMinuteDuration(600000)
	if notifyMessage then
		triggerEvent("notification:create", localPlayer, "Arena", "Hunter reached! Resetting time & weather.")
	end
end)

function spectate.start(...)
	exports.core:startSpectating(...)
end

addEventHandler("onClientArenaRequestSpectateStart", resourceRoot,
function()
	spectate.start(true)
end)

function spectate.stop(...)
	exports.core:stopSpectating(...)
end
addEventHandler("onClientArenaRequestSpectateStop", resourceRoot, spectate.stop)

addEventHandler("onClientArenaRequestSpectateEnd", resourceRoot,
function()
	exports.core:forcedStopSpectating()
end)

addEventHandler("onClientArenaPlayerStateChange", resourceRoot,
function(player, state)
	if player ~= localPlayer then
		if state == "alive" then
			setPlayerVisible(player, true)
		else
			setPlayerVisible(player, false)
		end
	end
end)

addEventHandler("onClientPlayerJoinArena", resourceRoot,
function(player)
	tableInsert(arena.players, player)
	if player == localPlayer then
		return
	end
	setPlayerVisible(player, false)
end)

addEventHandler("onClientPlayerLeaveArena", resourceRoot,
function(player)
	tableRemove(arena.players, player)
end)

function requestKill()
	if arena.state == "running" and not isPlayerDead(localPlayer) then
		triggerServerEvent("onRequestKillPlayer", localPlayer)
	end
end

function checkWater()
	if isElement(arena.vehicle) then
		if not waterCraftIDS[getElementModel(arena.vehicle)] then
			local x, y, z = getElementPosition(localPlayer)
			local waterZ = getWaterLevel(x, y, z)
			if waterZ and z < waterZ - 0.5 then
				if getElementData(localPlayer, "state") ~= "alive" and not training.stats.active then
					return
				end
				setElementHealth(localPlayer, 0)
				triggerServerEvent("onRequestKillPlayer", localPlayer)
			end
		end
		if not getVehicleEngineState(arena.vehicle) then
			setVehicleEngineState(arena.vehicle, true)
		end
	end
end

function removeVehicleNitro()
	if isElement(arena.vehicle) then
		removeVehicleUpgrade(arena.vehicle, 1010)
	end
end

function setPlayerVisible(player, visible)
	if isElement(player) then
		local vehicle = getPedOccupiedVehicle(player)
		local visibleDimension = getElementDimension(localPlayer)
		if visible then
			setElementDimension(player, visibleDimension)
			if isElement(vehicle) then
				setElementDimension(vehicle, visibleDimension)
			end
		else
			visibleDimension = visibleDimension + 1
			setElementDimension(player, visibleDimension)
			if isElement(vehicle) then
				setElementDimension(vehicle, visibleDimension)
			end
		end
	end
end

function isPlayerDead(player)
	return not getElementHealth(player) or getElementHealth(player) < 1e-45 or isPedDead(player)
end

function getTimePassed()
	if arena.timeIsUpStartTick and arena.timeIsUpTick then
		return math.max(getTickCount() - arena.timeIsUpStartTick, 0)
	end
	return nil
end

function getTimeLeft()
	if arena.timeIsUpStartTick and arena.timeIsUpTick then
		return math.max(arena.timeIsUpTick - getTickCount(), 0)
	end
	return nil
end

function requestToptimes()
	triggerServerEvent("toptimes:onPlayerRequestToptimes", localPlayer)
	arena.toptimeAdded = nil
end

function handlePickupHit(pickupType, pickupVehicle)
	if not arena.trainingAward and pickupType == "vehiclechange" and pickupVehicle == 425 then
		triggerServerEvent("arena:onPlayerHunter", resourceRoot, pickupType, pickupVehicle)
		arena.trainingAward = true
	end
	if pickupType == "vehiclechange" and pickupVehicle == 425 and getElementData(localPlayer, "state") == "alive" and not arena.toptimeAdded then
		local timePassed = getTimePassed()
		if timePassed then
			triggerServerEvent("toptimes:onPlayerRequestAddToptime", localPlayer, timePassed)
		end
		arena.toptimeAdded = true
	end
end

_getCameraTarget = getCameraTarget
function getCameraTarget()
	local target = _getCameraTarget()
	if isElement(target) and getElementType(target) == "vehicle" then
		target = getVehicleOccupant(target)
	end
	return target
end