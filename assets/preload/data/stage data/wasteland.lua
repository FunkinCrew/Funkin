-- same time that 'start' is called for regular modcharts :flushed:
local tankAngle = 0
local tankSpeed = 0
local time = 0

function start(stage)
	print(stage .. " is our stage!")

	randomizeStuff(getPropertyFromClass("flixel.FlxG", "game.ticks"))

	setActorX(math.random(-700, -100), "clouds")
	setActorY(math.random(-20, 20), "clouds")
	setActorVelocityX(math.random(5, 15), "clouds")

	tankAngle = math.random(-90, 45)
	tankSpeed = math.random(5, 7)

	moveDaTank()
end

local exponential2 = 0

-- called each frame with elapsed being the seconds between the last frame
function update(elapsed)
	time = time + elapsed

	moveDaTank()
end

function randomizeStuff(beat)
	local ticks = getPropertyFromClass("flixel.FlxG", "game.ticks") / 1000

	local offsetRand = songBpm + bpm + beat + curBeat + scrollspeed + keyCount + curStep + crochet + safeZoneOffset + screenWidth + screenHeight + fpsCap
	offsetRand = offsetRand + getWindowX() + getWindowY()
	offsetRand = offsetRand + ticks
	
	math.randomseed(time + offsetRand)
end

function moveDaTank()
	local tankX = 400

	tankAngle = tankAngle + (getPropertyFromClass("flixel.FlxG", "elapsed") * tankSpeed)

	setActorAngle(tankAngle - 90 + 15, "tank")
	
	local x = tankX + 1500 * math.cos(math.pi / 180 * (1 * tankAngle + 180))
	local y = 1300 + 1100 * math.sin(math.pi / 180 * (1 * tankAngle + 180))

	setActorX(x, "tank")
	setActorY(y, "tank")
end