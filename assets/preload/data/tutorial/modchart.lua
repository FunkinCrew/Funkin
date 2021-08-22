function start(song) -- do nothing
    spinLength = 0
end

function update(elapsed)
    if difficulty == 2 and curStep > 400 then
        if spinLength < 32 then
            spinLength = spinLength + 0.2
        end

        local currentBeat = (songPos / 1000)*(bpm/60)
		for i=0,7 do
            setActorAngle((spinLength / 7) * -math.sin((currentBeat + i*0.25) * math.pi), i)
			setActorX(_G['defaultStrum'..i..'X'] + spinLength * math.sin((currentBeat + i*0.25) * math.pi), i)
			setActorY(_G['defaultStrum'..i..'Y'] + spinLength * math.cos((currentBeat + i*0.25) * math.pi), i)
		end
    end
end

function beatHit(beat) -- do nothing
    
end

function stepHit(step) -- do nothing

end

function playerTwoTurn()
    tweenCameraZoom(1.3,(crochet * 4) / 1000)
end

function playerOneTurn()
    tweenCameraZoom(1,(crochet * 4) / 1000)
end