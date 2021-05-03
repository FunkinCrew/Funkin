var bg;
function start(song) {
    bg = new FlxSprite(-200, -100);
    var tex = FlxAtlasFrames.fromSparrow(hscriptPath + 'halloween_bg.png', hscriptPath + 'halloween_bg.xml');
    bg.frames = tex;
    bg.animation.addByPrefix("idle", "halloweem bg0", 24, true);
    bg.animation.addByPrefix("lightning", "halloweem bg lightning strike",24,false );
    bg.animation.play("idle");
    bg.antialiasing = true;
    addSprite(bg, BEHIND_ALL);
}

var lightningBeat = 0;
var lightningOffset = 8;
function beatHit(beat)
{
    if (FlxG.random.bool(10) && beat > lightningBeat + lightningOffset) {
        FlxG.sound.play(hscriptPath + 'lightning.ogg');
        bg.animation.play("lightning");
        lightningBeat = beat;
        lightningOffset = FlxG.random.int(8,24);
        getHaxeActor("boyfriend").playAnim("scared", true);
        getHaxeActor("gf").playAnim("scared", true);
    }
}

function update(elapsed)
{
}

function stepHit(step)
{
}

function playerTwoTurn()
{
}

function playerTwoMiss()
{
}

function playerTwoSing()
{
}

function playerOneTurn()
{
}

function playerOneMiss()
{
}

function playerOneSing()
{
}

