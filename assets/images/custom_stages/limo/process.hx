
// flx sprite
var bg;
var bgLimo;
var dancers;
var limo;
var fastcar;
function start(song) {
    trace("start :)");
    bg = new FlxSprite(-120,-50).loadGraphic(hscriptPath + 'limoSunset.png');
    bg.scrollFactor.set(0.1, 0.1);
    bg.antialiasing = true;
    addSprite(bg, BEHIND_ALL);
    bgLimo = new FlxSprite(-200,480);
    var tex = FlxAtlasFrames.fromSparrow(hscriptPath + 'bgLimo.png', hscriptPath + 'bgLimo.xml');
    bgLimo.frames = tex;
    bgLimo.animation.addByPrefix('idle', 'background limo pink', 24, true);
    bgLimo.animation.play('idle', true);
    bgLimo.scrollFactor.set(0.4, 0.4);
    bgLimo.antialiasing = true;
    addSprite(bgLimo, BEHIND_ALL);
    dancers = new FlxGroup();
	var bootex = FlxAtlasFrames.fromSparrow(hscriptPath + 'limoDancer.png',hscriptPath + 'limoDancer.xml');
    for (i in 0...5) {
        var boogie = new MetroSprite((370 * i) + 130, 80, false);
        boogie.frames = bootex;
        boogie.animation.addByIndices('danceLeft', 'bg dancer sketch PINK', makeRangeArray(15), "", 24, false);
        boogie.animation.addByIndices('danceRight', 'bg dancer sketch PINK', makeRangeArray(30,15), "", 24, false);
        boogie.animation.play('danceLeft', false);
        boogie.antialiasing = true;
        boogie.scrollFactor.set(0.4, 0.4);
        dancers.add(boogie);
    }
    addSprite(dancers, BEHIND_ALL);
    limo = new FlxSprite(-120, 550);
    var limotex = FlxAtlasFrames.fromSparrow(hscriptPath + 'limoDrive.png', hscriptPath  + 'limoDrive.xml');
    limo.frames = limotex;
    limo.animation.addByPrefix('drive', 'Limo stage', 24, true);
    limo.animation.play('drive', false);
    limo.antialiasing = true;
    addSprite(limo, BEHIND_DAD | BEHIND_BF);
    fastcar = new FlxSprite(-300, 160).loadGraphic(hscriptPath + 'fastCarLol.png');
    addSprite(fastcar, BEHIND_NONE);
    setDefaultZoom(0.9);
    getHaxeActor("bf").x += 260;
    getHaxeActor("bf").y -= 220;
    getHaxeActor("bf").followCamX -= 200;
    resetVroomVroom();
    trace("finish start :)");

}

var vroomVroomCanVroom = true;
function resetVroomVroom() {
    fastcar.x = -12600;
    fastcar.y = FlxG.random.int(140,250);
    fastcar.velocity.x = 0;
    vroomVroomCanVroom = true;
}
function doVroomVroom() {
    FlxG.sound.play(hscriptPath + 'carPass' + FlxG.random.int(0,1)+'.ogg');
    fastcar.velocity.x = FlxG.random.int(170,220) / FlxG.elapsed;
    vroomVroomCanVroom = false;
    new FlxTimer().start(2, function(tmr) {
        resetVroomVroom();
    });
}
function beatHit(beat) {
    dancers.forEach(function (spr) {
        spr.dance();
    });
    if (FlxG.random.bool(10) && vroomVroomCanVroom) {
        doVroomVroom();
    }
}
function update(elapsed) {}
function stepHit(step) {}
function playerTwoTurn() {}
function playerTwoMiss() {}
function playerTwoSing() {}
function playerOneTurn() {}
function playerOneMiss() {}
function playerOneSing() {}
