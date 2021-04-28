function start(song) 
    print("start :)");
    makeSprite("stageback", "bg", BEHIND_ALL,STATIC_IMAGE);
    setActorX(-600, "bg");
    setActorY(-200, "bg");
    print("make sprite");
    setActorScrollFactor(0.9, 0.9, "bg");
    
    makeSprite("stagefront", "stageFront", BEHIND_ALL,STATIC_IMAGE);
    setActorScrollFactor(0.9, 0.9, "stageFront");
    setActorScale(1.1, "stageFront");
    setActorX(-650, "stageFront");
    setActorY(600, "stageFront");
    makeSprite("stagecurtains", "stageCurtains", BEHIND_ALL,STATIC_IMAGE);
    
    setActorScale(0.9, "stageCurtains");
    setActorX(-500, "stageCurtains");
    setActorY(-300, "stageCurtains");
    setActorScrollFactor(1.3, 1.3, "stageCurtains");
    setDefaultZoom(0.9);
    print("finish start :)");
end
function beatHit(beat)
    -- do nothing
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