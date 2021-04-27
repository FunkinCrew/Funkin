function start(song) 
    print("start :)");
    makeSprite("bgWalls", "bg", BEHIND_ALL,STATIC_IMAGE);
    setActorX(-1000, "bg");
    setActorY(-500, "bg");
    setActorScale(0.8, "bg");
    print("make sprite");
    setActorScrollFactor(0.2, 0.2, "bg");
    
    makeSprite("upperBop", "upperBop", BEHIND_ALL,SPARROW_SHEET);
    addActorAnimationPrefix("Upper Crowd Bob", "bop", 24, false, "upperBop");
    
    setActorScale(0.85, "upperBop");
    setActorX(-240, "upperBop");
    setActorY(-90, "upperBop");
    setActorScrollFactor(0.33, 0.33, "upperBop");

    makeSprite("bgEscalator", "escal", BEHIND_ALL,STATIC_IMAGE);
    setActorX(-1100, "escal");
    setActorY(-600, "escal");
    setActorScrollFactor(0.3, 0.3, "escal");
    setActorScale(0.9, "escal");
    
    
    makeSprite("christmasTree", "tree", BEHIND_ALL,STATIC_IMAGE);
    setActorX(370, "tree");
    setActorY(-250, "tree");
    setActorScrollFactor(0.4, 0.4, "tree");

    makeSprite("bottomBop", "bum", BEHIND_ALL,SPARROW_SHEET);
    addActorAnimationPrefix("Bottom Level Boppers", "bop", 24, false, "bum");
    setActorScrollFactor(0.9, 0.9, "bum");
    setActorX(-300, "bum");
    setActorY(140, "bum");
    makeSprite("fgSnow", "snow", BEHIND_ALL,STATIC_IMAGE);
    setActorX(-600, "snow");
    setActorY(700, "snow");

    makeSprite("santa", "satan", BEHIND_ALL,SPARROW_SHEET);
    addActorAnimationPrefix("santa idle in fear", "idle", 24, false, "satan");
    setActorX(-840, "satan");
    setActorY(150, "satan");
    setDefaultZoom(0.8);
    print(":)");
    setActorX(getActorX("boyfriend") + 200, "boyfriend");
    print(":)");
    setActorFollowCam(getActorFollowCamX("boyfriend"), getActorFollowCamY("boyfriend")-100, "boyfriend");
    print("finish start :)");
end
function beatHit(beat)
    playActorAnimation("idle", true, "satan");
    playActorAnimation("bop", true, "bum");
    playActorAnimation("bop", true, "upperBop");
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