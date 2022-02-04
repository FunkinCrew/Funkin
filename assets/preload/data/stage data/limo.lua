-- same time that 'start' is called for regular modcharts :flushed:
function create(stage)
	print(stage .. " is our stage!")

	setActorX(-12600, "car")
	setActorY(math.random(140, 250), "car")
	setActorVelocityX(0, "car")

	if animatedBackgrounds then
		createSound("pass1", "carPass0")
		createSound("pass2", "carPass1")
	end
end

local danceValue = false
local carCanGoVroom = true
local funnyTimer = 0
local time = 0

function update(elapsed)
	if animatedBackgrounds then
		time = time + elapsed
		funnyTimer = funnyTimer + elapsed

		if not carCanGoVroom and funnyTimer >= 2 then
			randomizeStuff(curBeat)

			setActorX(-12600, "car")
			setActorY(math.random(140, 250), "car")
			setActorVelocityX(0, "car")

			carCanGoVroom = true
		end
	end
end

-- everytime a beat hit is called on the song this happens
function beatHit(beat)
	if animatedBackgrounds then
		danceValue = not danceValue

		if danceValue then
			playActorAnimation("dancer1", "danceRight", true)
			playActorAnimation("dancer2", "danceRight", true)
			playActorAnimation("dancer3", "danceRight", true)
			playActorAnimation("dancer4", "danceRight", true)
		else
			playActorAnimation("dancer1", "danceLeft", true)
			playActorAnimation("dancer2", "danceLeft", true)
			playActorAnimation("dancer3", "danceLeft", true)
			playActorAnimation("dancer4", "danceLeft", true)
		end

		randomizeStuff(beat)

		if math.random(1,10) == 3 and carCanGoVroom then
			playSound("pass" .. tostring(math.random(1,2)), true)

			setActorVelocityX((math.random(170, 220) / getPropertyFromClass("flixel.FlxG", "elapsed")) * 3, "car")

			carCanGoVroom = false
			funnyTimer = 0
		end
	end
end

function randomizeStuff(beat)
	local ticks = getPropertyFromClass("flixel.FlxG", "game.ticks") / 1000

	local offsetRand = songBpm + bpm + beat + curBeat + scrollspeed + keyCount + curStep + crochet + safeZoneOffset + screenWidth + screenHeight + fpsCap
	offsetRand = offsetRand + getWindowX() + getWindowY()
	offsetRand = offsetRand + ticks
	
	math.randomseed(time + offsetRand)
end