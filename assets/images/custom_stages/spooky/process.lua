function start(song) 
    print("start :)");
    makeSprite("halloween_bg", "bg", BEHIND_ALL, SPARROW_SHEET);
    setActorX(-200, "bg");
    setActorY(-100, "bg");
    addActorAnimationPrefix("halloweem bg0", "idle", 24, true, "bg");
    addActorAnimationPrefix("halloweem bg lightning strike","lightning", 24, false, "bg");
    playActorAnimation("idle", false, "bg");

    print("make sprite");
end
lightningBeat = 0;
lightingOffset = 8;
function beatHit(beat)
    if (math.random(0,100) <= 10 and beat > lightningBeat + lightingOffset) then
        playSound("lightning");
        print("do lightning :)");
        playActorAnimation("lightning", false, "bg");
        lightningBeat = beat;
        lightingOffset = math.random(8,24);
        playCharacterAnimation("scared", true, "boyfriend");
        playCharacterAnimation("scared", true, "girlfriend");
    end
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