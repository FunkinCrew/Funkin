function start(song) 
    print("start :)");
    makeSprite("sky", "bg", BEHIND_ALL,STATIC_IMAGE);
    setActorX(-100, "bg");
    print("make sprite");
    setActorScrollFactor(0.1, 0.1, "bg");
    
    makeSprite("city", "city", BEHIND_ALL,STATIC_IMAGE);
    setActorScrollFactor(0.3, 0.3, "city");
    setActorScale(0.85, "city");
    setActorX(-10, "city");
    print("make city");
    -- haxe is exclusive range, lua inclusive
    for i = 0, 4, 1 do
        makeSprite("win"..i, "lights"..i, BEHIND_ALL, STATIC_IMAGE);
        setActorX(-10, "lights"..i);
        setActorScale(0.85, "lights"..i);
        setActorAlpha(0, "lights"..i);
        setActorScrollFactor(0.3, 0.3, "lights"..i);
        
    end
    makeSprite("behindTrain", "streetBehind", BEHIND_ALL, STATIC_IMAGE);
    setActorX(-40, "streetBehind");
    setActorY(50, "streetBehind");

    makeSprite("train", "train", BEHIND_ALL, STATIC_IMAGE);
    setActorX(2000, "train");
    setActorY(360, "train");
    addSoundToList("train_passes", "trainSound");
    makeSprite("street", "street", BEHIND_ALL, STATIC_IMAGE);
    setActorX(-40, "street");
    setActorY(50, "street");

    print("finish start :)");
end
TrainCooldown = 0;
TrainCars = 8;
TrainMoving = false;
TrainFinishing = false;
TrainFrameTiming = 0.0;
StartedMoving = false;
function beatHit(beat)
    if not TrainMoving then
        TrainCooldown = TrainCooldown + 1;
    end
    print("beep");
    if beat % 4 == 0 then
        for i = 0, 4, 1 do
            setActorAlpha(0, "lights" .. i);
        end
        setActorAlpha(1, "lights" .. math.random(0,4));
    end
    print("bop");
    if beat % 8 == 4 and math.random(0,100) <= 30 and not TrainMoving and TrainCooldown > 8 then
        TrainCooldown = math.random(-4, 0);
        print("bonk");
        doVroomVroom();
    end
end
function update(elapsed)
    if TrainMoving then
        TrainFrameTiming = TrainFrameTiming + elapsed;
        if TrainFrameTiming >= 1 / 24 then
            updateVroomVroom();
            TrainFrameTiming = 0;
        end
    end
end
function doVroomVroom()
    TrainMoving = true;
    if not getSoundPlaying("trainSound") then
        playStoredSound(false, "trainSound");
    end
end
function updateVroomVroom()
    if (getSoundTime("trainSound") >= 4700) then
        StartedMoving = true;
        playCharacterAnimation("hairBlow", false, "girlfriend");
    end
    if (StartedMoving) then
        setActorX(getActorX("train") - 400, "train");
        if getActorX("train") < -2000 and not TrainFinishing then
            setActorX(-1150, "train");
            TrainCars = TrainCars - 1;
            if TrainCars <= 0 then
                TrainFinishing = true;
            end
        end
        if getActorX("train") < -4000 and TrainFinishing then
            resetVroomVroom();
        end
    end
end
function resetVroomVroom()
    playCharacterAnimation("hairFall", false, "girlfriend");
    setActorX(screenWidth + 200, "train");
    TrainMoving = false;
    TrainCars = 8;
    TrainFinishing = false;
    StartedMoving = false;
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