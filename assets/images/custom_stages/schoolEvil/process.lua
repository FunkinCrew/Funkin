function start(song) 
    print("start :)");
    makeSprite("animatedEvilSchool", "bg", BEHIND_ALL, SPARROW_SHEET);
    addActorAnimationPrefix("background 2", "idle", 24, true, "bg");
    playActorAnimation("idle", true, "bg");
    setActorX(400, "bg");
    setActorY(200, "bg");
    setActorScrollFactor(0.8, 0.9, "bg");
    setActorScaleMember(6,"bg");
    
    setActorAntialias(false, "bg");
    setActorX(getActorX("boyfriend") + 200, "boyfriend");

    setActorY(getActorY("boyfriend") + 220, "boyfriend");
    setActorX(getActorX("girlfriend") + 180, "girlfriend");
    setActorY(getActorY("girlfriend") + 300, "girlfriend");
    setActorFollowCam(getActorFollowCamX("boyfriend")-100, getActorFollowCamY("boyfriend")-100, "boyfriend");
    print("make sprite");
end
function beatHit(beat)
end
function update(elapsed)

end
function stepHit(step)
-- do nothing dumbass
end
function playerTwoTurn()
    
end
function playerOneTurn()
    
end
function playerTwoSing()
    
end
function playerOneSing()
    
end
function playerOneMiss()
    
end