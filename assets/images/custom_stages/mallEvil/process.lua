function start(song) 
    print("start :)");
    makeSprite("evilBG", "bg", BEHIND_ALL,STATIC_IMAGE);
    setActorX(-400, "bg");
    setActorY(-500, "bg");
    setActorScale(0.8, "bg");
    setActorScrollFactor(0.2, 0.2, "bg");

    
    makeSprite("evilTree", "tree", BEHIND_ALL,STATIC_IMAGE);
    setActorX(300, "tree");
    setActorY(-300, "tree");
    setActorScrollFactor(0.2, 0.2, "tree");

    makeSprite("evilSnow", "snow", BEHIND_ALL,STATIC_IMAGE);
    setActorX(-200, "snow");
    setActorY(700, "snow");
    setActorX(getActorX("boyfriend") + 320, "boyfriend");
    setActorY(getActorY("dad") - 80, "dad");
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