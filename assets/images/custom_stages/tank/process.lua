local CurSong = "idk lol";
-- guess what this means
local JohnLength = 0;
function start(song) 
    CurSong = song;
    print("start :)");
    -- ay yo ninjamuffin a bitch, i be out here
    -- porting the ng build before he be
    makeSprite("tankSky", "sky", BEHIND_ALL,STATIC_IMAGE);
    setActorX(-400, "sky");
    setActorY(-400, "sky");
    print("make sprite");
    -- so fucking far it doesn't move away when camera shifts
    setActorScrollFactor(0, 0, "sky");
    
    makeSprite("tankClouds", "clouds", BEHIND_ALL,STATIC_IMAGE);
    setActorScrollFactor(0.1, 0.1, "clouds");
    setActorX(math.random(-700, -100), "clouds");
    setActorY(math.random(-20, 20), "clouds");
    setActorVelocityX(math.random() + math.random(5, 14), "clouds");

    makeSprite("tankMountains", "mountains", BEHIND_ALL,STATIC_IMAGE);
    
    setActorScale(1.2, "mountains");
    setActorX(-300, "mountains");
    setActorY(-20, "mountains");
    setActorScrollFactor(0.2, 0.2, "mountains");

    makeSprite("tankBuildings", "building", BEHIND_ALL,STATIC_IMAGE);
    
    setActorScale(1.1, "building");
    setActorX(-200, "building");
    setActorScrollFactor(0.3, 0.3, "building");

    makeSprite("tankRuins", "ruins", BEHIND_ALL,STATIC_IMAGE);
    
    setActorScale(1.1, "ruins");
    setActorX(-200, "ruins");

    setActorScrollFactor(0.35, 0.35, "ruins");
    makeSprite("smokeLeft", "smokeLeft", BEHIND_ALL,SPARROW_SHEET);
    addActorAnimationPrefix("SmokeBlurLeft", "idle", 24, true, "smokeLeft");
    playActorAnimation("idle", true, "smokeLeft");
    setActorX(-200, "smokeLeft");
    setActorY(-100, "smokeLeft");
    setActorScrollFactor(0.4, 0.4, "smokeLeft");

    makeSprite("smokeRight", "smokeRight", BEHIND_ALL,SPARROW_SHEET);
    addActorAnimationPrefix("SmokeRight", "idle", 24, true, "smokeRight");
    playActorAnimation("idle", true, "smokeRight");
    setActorX(1100, "smokeRight");
    setActorY(-100, "smokeRight");
    setActorScrollFactor(0.4, 0.4, "smokeRight");
    makeSprite("tankWatchtower", "tower", BEHIND_ALL,SPARROW_SHEET);
    addActorAnimationPrefix("watchtower gradient color", "idle", 24, false, "tower");
    playActorAnimation("idle", true, "tower");
    setActorX(100, "tower");
    setActorY(50, "tower");
    setActorScrollFactor(0.5, 0.5, "tower");
    makeSprite("tankRolling", "tankGround", BEHIND_ALL, SPARROW_SHEET);
    addActorAnimationPrefix("BG tank w lighting", "idle", 24, true, "tankGround");
    playActorAnimation("idle", true, "tankGround");
    setActorX(300, "tankGround");
    setActorY(300, "tankGround");
    setActorScrollFactor(0.5, 0.5, "tankGround");

    makeSprite("tankGround", "tankDirt", BEHIND_ALL, STATIC_IMAGE);
    setActorX(-420, "tankDirt");
    setActorY(-150, "tankDirt");
    setActorScale(1.15, "tankDirt");
    -- usually you make a new group but we don't do that :hueh:
    -- we will instance the tank men on the fly
    
    makeSprite("tank0", "tank0", BEHIND_NONE, SPARROW_SHEET);
    setActorX(-500, "tank0");
    setActorY(650, "tank0");
    addActorAnimationPrefix("fg", "idle", 24, false, "tank0");
    playActorAnimation("idle", true, "tank0");
    setActorScrollFactor(1.7, 1.5, "tank0");

    makeSprite("tank1", "tank1", BEHIND_NONE, SPARROW_SHEET);
    setActorX(-300, "tank1");
    setActorY(750, "tank1");
    addActorAnimationPrefix("fg", "idle", 24, false, "tank1");
    playActorAnimation("idle", true, "tank1");
    setActorScrollFactor(2, 0.2, "tank1");

    makeSprite("tank2", "tank2", BEHIND_NONE, SPARROW_SHEET);
    setActorX(450, "tank2");
    setActorY(940, "tank2");
    addActorAnimationPrefix("foreground", "idle", 24, false, "tank2");
    playActorAnimation("idle", true, "tank2");
    setActorScrollFactor(1.5, 1.5, "tank2");

    makeSprite("tank4", "tank4", BEHIND_NONE, SPARROW_SHEET);
    setActorX(1300, "tank4");
    setActorY(900, "tank4");
    addActorAnimationPrefix("fg", "idle", 24, false, "tank4");
    playActorAnimation("idle", true, "tank4");
    setActorScrollFactor(1.5, 1.5, "tank4");

    makeSprite("tank5", "tank5", BEHIND_NONE, SPARROW_SHEET);
    setActorX(1620, "tank5");
    setActorY(700, "tank5");
    addActorAnimationPrefix("fg", "idle", 24, false, "tank5");
    playActorAnimation("idle", true, "tank5");
    setActorScrollFactor(1.5, 1,5, "tank5");

    makeSprite("tank3", "tank3", BEHIND_NONE, SPARROW_SHEET);
    setActorX(1300, "tank3");
    setActorY(1200, "tank3");
    addActorAnimationPrefix("fg", "idle", 24, false, "tank3");
    playActorAnimation("idle", true, "tank3");
    setActorScrollFactor(3.5, 2.5, "tank3");
    setActorY(getActorY("girlfriend") + 10, "girlfriend");
    setActorX(getActorX("girlfriend") - 30, "girlfriend");
    print(isCharLike("pico-speaker", "girlfriend"));
    setActorY(getActorY("girlfriend") -75, "girlfriend");
    setActorX(getActorX("girlfriend") - 170, "girlfriend");
            setActorX(getActorX("boyfriend") + 40, "boyfriend");
    
    if isCharLike("pico-speaker", "girlfriend") == 1 then
        -- do nothing
    else

        setActorY(getActorY("dad") + 60, "dad");
        setActorX(getActorX("dad") - 80, "dad");
    end
    setDefaultZoom(0.9);
    print("finish start :)");
end
function beatHit(beat)
    for i = 0, 5, 1 do
        playActorAnimation("idle", true, "tank"..i);
    end
    playActorAnimation("idle", true, "tower");
end
TankAngle = math.random(-90, 45);
TankSpeed = math.random() + math.random(5, 6);
function moveTank(elapsed)
    TankAngle = TankAngle + (elapsed * TankSpeed);
    setActorAngle(TankAngle - 90 + 15, "tankGround");
    print(TankAngle -90 + 15);
    setActorX(getActorX("tankGround") + (1500 * math.cos(math.rad(getActorAngle("tankGround") + 180))), "tankGround");
    -- times pi/180 is like deg2rad, convert degrees to radians
    setActorY(1300 + (1100 * math.sin(math.rad(getActorAngle("tankGround") + 180))), "tankGround");

end
function update(elapsed)
    moveTank(elapsed);
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