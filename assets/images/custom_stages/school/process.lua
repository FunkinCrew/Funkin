function start(song) 
    print("start :)");
    makeSprite("weebSky", "bg", BEHIND_ALL,STATIC_IMAGE);
    print("make sprite");
    setActorScrollFactor(0.1, 0.1, "bg");
    local widShit = getActorWidth("bg") * 6;
    setActorScale(6, "bg");
    setActorAntialias(false, "bg");
    makeSprite("weebSchool", "school", BEHIND_ALL,STATIC_IMAGE);
    setActorScrollFactor(0.6, 0.9, "school");
    setActorX(-200, "school");
    setActorScale(widShit/getActorWidth("school"), "school");
    setActorAntialias(false, "school");
    makeSprite("weebStreet", "street", BEHIND_ALL,STATIC_IMAGE);
    setActorX(-200, "street");
    setActorScrollFactor(0.95, 0.95, "street");
    setActorScale(widShit/getActorWidth("street"), "street");
    setActorAntialias(false, "street");
    makeSprite("weebTreesBack", "fgTrees", BEHIND_ALL,STATIC_IMAGE);
    setActorX(-30, "fgTrees");
    setActorY(130, "fgTrees");
    setActorScale(widShit *0.8/getActorWidth("fgTrees"), "fgTrees");
    setActorAntialias(false, "fgTrees");
    setActorScrollFactor(0.9, 0.9, "fgTrees");
    newRangeArray(0, 18, "treeIndices")
    makeSprite("weebTrees", "bgTrees", BEHIND_ALL,PACKER_SHEET);
    addActorAnimation("treeLoop", "treeIndices", 12, true, "bgTrees");
    playActorAnimation("treeLoop", true,"bgTrees");
    setActorX(-580, "bgTrees");
    setActorY(-800, "bgTrees");
    setActorScale(widShit *1.4/getActorWidth("bgTrees"), "bgTrees");
    setActorAntialias(false, "bgTrees");
    setActorScrollFactor(0.85, 0.85, "bgTrees");
    makeSprite("petals", "petals", BEHIND_ALL,SPARROW_SHEET);
    addActorAnimationPrefix("PETALS ALL", "leaves", 24, true, "petals");
    playActorAnimation("leaves",true, "petals");
    setActorX(-200, "petals");
    setActorY(-40, "petals");
    setActorScale(widShit/getActorWidth("petals"), "petals");
    setActorAntialias(false, "petals");
    setActorScrollFactor(0.85, 0.85, "petals");

    makeSprite("bgFreaks", "gorls", BEHIND_ALL,SPARROW_SHEET);
    setActorX(-100, "gorls");
    setActorY(190, "gorls");
    newRangeArray(0,14, "danceLeft");
    newRangeArray(15,30, "danceRight");
    print(isMoody);
    if (isMoody == 1) then
        addActorAnimationIndices("BG fangirls dissuaded", "danceLeft", "danceLeft", 24, "gorls");
        addActorAnimationIndices("BG fangirls dissuaded", "danceRight", "danceRight", 24, "gorls");
    else
        addActorAnimationIndices("BG girls group", "danceLeft", "danceLeft", 24, "gorls");
        addActorAnimationIndices("BG girls group", "danceRight", "danceRight", 24, "gorls");
    end
    playActorAnimation("danceLeft",true, "gorls");
    setActorX(getActorX("boyfriend") + 200, "boyfriend");

    setActorY(getActorY("boyfriend") + 220, "boyfriend");
    setActorX(getActorX("girlfriend") + 180, "girlfriend");
    setActorY(getActorY("girlfriend") + 300, "girlfriend");
    setActorFollowCam(getActorFollowCamX("boyfriend")-100, getActorFollowCamY("boyfriend")-100, "boyfriend");
    makeActorPixel("gorls");
    print("finish start :)");
end
DanceDir = false;
function beatHit(beat)
    DanceDir = not DanceDir;
    if (DanceDir) then
        playActorAnimation("danceRight", true,  "gorls");
    else
        playActorAnimation("danceLeft", true, "gorls");
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