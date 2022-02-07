local trainMoving = false
local trainCooldown = 0

local trainFrameTiming = 0

local startedMoving = false

local trainFinishing = false

local trainCars = 0

local time = 0

-- when the stage lua is created
function create(stage)
	print(stage .. " is our stage!")

	hideLights()

	createSound("train", "train_passes", "shared")
end

-- called each frame with elapsed being the seconds between the last frame
function update(elapsed)
	time = time + elapsed

	if trainMoving then
		trainFrameTiming = trainFrameTiming + elapsed

		if trainFrameTiming >= 1 / 24 then
			updateTrainPos()
			trainFrameTiming = 0
		end
	end
end

function beatHit(curBeat)
	randomizeStuff()

	if not trainMoving then
		trainCooldown = trainCooldown + 1
	end

	if curBeat % 4 == 0 then
		hideLights()

		local lightSelected = math.random(1, 5)

		setActorVisible(true, "light" .. tostring(lightSelected))
	end

	if curBeat % 8 == 4 and math.random(1,10) <= 3 and not trainMoving and trainCooldown > 8 then
		trainCooldown = math.random(-4, 0)
		startDaTrain()
	end
end

function hideLights()
	for i = 1, 5, 1 do -- loop 5 times
		setActorVisible(false, "light" .. tostring(i)) -- set light[insert loop num here] to not be visible
	end
end

function startDaTrain()
	trainMoving = true

	playSound("train", true)
end

function updateTrainPos()
	if getSoundTime("train") >= 4700 then
		startedMoving = true
		playCharacterAnimation("girlfriend", "hairBlow", false)
	end

	if startedMoving then
		setActorX(getActorX("train") - 400, "train")

		if getActorX("train") < -2000 and not trainFinishing then
			setActorX(-1150, "train")
			trainCars = trainCars - 1

			if trainCars <= 0 then
				trainFinishing = true
			end
		end

		if getActorX("train") < -4000 and trainFinishing then
			trainReset()
		end
	end
end

function trainReset()
	playCharacterAnimation("girlfriend", "hairFall", true)
    
	setActorX(windowWidth + 200, "train")
	trainMoving = false
	trainCars = 8
	trainFinishing = false
	startedMoving = false
end

function randomizeStuff()
	local ticks = getPropertyFromClass("flixel.FlxG", "game.ticks") / 1000

	local offsetRand = songBpm + bpm + curBeat + scrollspeed + keyCount + curStep + crochet + safeZoneOffset + screenWidth + screenHeight + fpsCap
	offsetRand = offsetRand + getWindowX() + getWindowY()
	offsetRand = offsetRand + ticks
	
	math.randomseed(time + offsetRand)
end