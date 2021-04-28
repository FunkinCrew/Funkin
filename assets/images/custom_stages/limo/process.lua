function start(song) 
    print("start :)");
    makeSprite("limoSunset", "bg", BEHIND_ALL,STATIC_IMAGE);
    setActorX(-120, "bg");
    setActorY(-50, "bg");
    print("make sprite");
    setActorScrollFactor(0.1, 0.1, "bg");
    
    makeSprite("bgLimo", "bgLimo", BEHIND_ALL,SPARROW_SHEET);
    addActorAnimationPrefix("background limo pink", "drive", 24, true, "bgLimo");
    playActorAnimation("drive",false, "bgLimo");
    setActorScrollFactor(0.4, 0.4, "bgLimo");
    setActorX(-200, "bgLimo");
    print("sus");
    
    setActorY(480, "bgLimo");
    newRangeArray(0, 14, "danceLeft");
    newRangeArray(15,29, "danceRight");
    for i = 0, 4, 1 do
        makeSprite("limoDancer", "dancer"..i, BEHIND_ALL,SPARROW_SHEET);
        print("owo");
        setActorX((370 * i) + 130, "dancer"..i);
        setActorY(80, "dancer"..i);
        
        addActorAnimationIndices("bg dancer sketch PINK", "danceLeft", "danceLeft", 24, "dancer"..i);
        addActorAnimationIndices("bg dancer sketch PINK", "danceRight", "danceRight", 24, "dancer"..i);
        playActorAnimation("danceLeft", false, "dancer"..i);
        setActorScrollFactor(0.4, 0.4, "dancer"..i);
    end
    print("finish dancers");
    makeSprite("limoDrive", "limo", bitwiseor(BEHIND_DAD, BEHIND_BF), SPARROW_SHEET);
    setActorX(-120, "limo");
    setActorY(550, "limo");
    addActorAnimationPrefix("Limo stage", "drive", 24, true, "limo");
    playActorAnimation("drive", false, "limo");
    makeSprite("fastCarLol", "fastcar", BEHIND_NONE, STATIC_IMAGE);
    setActorX(-300, "fastcar");
    setActorY(160, "fastcar");
    setDefaultZoom(0.9);
    setActorX(getActorX("boyfriend") + 260, "boyfriend");
    setActorY(getActorY("boyfriend") - 220, "boyfriend");
    setActorFollowCam(getActorFollowCamX("boyfriend")-200, getActorFollowCamY("boyfriend"), "boyfriend");
    ResetVroomVroom();
    print("finish start :)");
end
GroupBeat = false;
VroomVroomCanVroom = true;
function beatHit(beat)
    GroupBeat = not GroupBeat;
    if GroupBeat then
        for i = 0, 4, 1 do
            playActorAnimation("danceLeft",true, "dancer"..i)
        end
    else
        for i = 0, 4, 1 do
            playActorAnimation("danceRight", true,"dancer"..i)
        end
    end
    print("hehe");
    print(VroomVroomCanVroom);
    print(math.random(0, 10));
    if (math.random(0, 10) <= 1 and VroomVroomCanVroom) then
        DoVroomVroom();
    end
    print("hen");
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
function ResetVroomVroom()
    setActorX(-12600,"fastcar");
    setActorY(math.random(140,250), "fastcar");
    setActorVelocityX(0, "fastcar");
    VroomVroomCanVroom = true;
end
function DoVroomVroom()
    print("do vroom vroom");
    playSound("carPass"..math.random(0,1));
    print("played sound")
    setActorVelocityX((math.random(170, 220) / elapsed()) * 3, "fastcar");
    print("set velocity");
    VroomVroomCanVroom = false;
    addTimer("ResetVroomVroom", 2);
end