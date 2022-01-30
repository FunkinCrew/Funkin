-- same time that 'start' is called for regular modcharts :flushed:
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

-- same thing as create, just a different name
function start(stage)
	
end

-- called each frame with elapsed being the seconds between the last frame
function update(elapsed)

end

-- everytime a beat hit is called on the song this happens
function beatHit(curBeat)

end