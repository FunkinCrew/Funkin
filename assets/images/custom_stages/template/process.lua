function start(song) 
    print("start :)");
    makeSprite("stageback", "bg", true);
    setActorX(-600, "bg");
    setActorY(-200, "bg");
    print("make sprite");
    setActorScrollFactor(0.9, 0.9, "bg");
    
    makeSprite("stagefront", "stageFront", true);
    setActorScrollFactor(0.9, 0.9, "stageFront");
    setActorScale(1.1, "stageFront");
    setActorX(-650, "stageFront");
    setActorY(600, "stageFront");
    makeSprite("stagecurtains", "stageCurtains", true);
    
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