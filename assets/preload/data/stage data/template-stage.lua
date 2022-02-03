-- when the stage lua is created
function create(stage)
	print(stage .. " is our stage!")

	-- make our sprites B)
	makeStageSprite("stageback", "stageback", -600, -200, 1)
	setActorScroll(0.9, 0.9, "stageback")

	makeStageSprite("stagefront", "stagefront", -650, 600, 1.1)
	setActorScroll(0.9, 0.9, "stagefront")

	makeStageSprite("stagecurtains", "stagecurtains", -500, -300, 0.9)
	setActorScroll(1.3, 1.3, "stagecurtains")

	-- set extra properties like camera zoom (can be done in json still but frick you)
	setProperty("stage", "camZoom", 0.9)
end

-- same as start function in a regular modchart
function start(stage)
	
end

-- called each frame with elapsed being the seconds between the last frame
function update(elapsed)

end

-- everytime a beat hit is called on the song this happens
function beatHit(curBeat)

end

-- any other functions from regular modcharts can also be put here :DDD