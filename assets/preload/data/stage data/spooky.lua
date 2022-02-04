function create(stage)
	print(stage .. " is our stage!")

	if animatedBackgrounds then
		createSound("thunder1", "thunder_1", "shared", false)
		createSound("thunder2", "thunder_2", "shared", false)
	end
end

local lastBeat = 0
local beatOffset = 8

local time = 0

local justScared = false

function update(elapsed)
	if animatedBackgrounds then
		time = time + elapsed
	end
end

-- everytime a beat hit is called on the song this happens
function beatHit(beat)
	if animatedBackgrounds then
		randomizeStuff(beat)

		if math.random(1, 10) == 3 and beat > lastBeat + beatOffset then
			lastBeat = beat

			setCharacterShouldDance("boyfriend", false)
			setCharacterShouldDance("girlfriend", false)

			playCharacterAnimation("boyfriend", "scared", true)
			playCharacterAnimation("girlfriend", "scared", true)

			playActorAnimation("bg", "lightning", true)

			playSound("thunder" .. tostring(math.random(1,2)))

			beatOffset = math.random(8, 24)

			justScared = true
		elseif justScared then
			setCharacterShouldDance("boyfriend", true)
			setCharacterShouldDance("girlfriend", true)

			justScared = false
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