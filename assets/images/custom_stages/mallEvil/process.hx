
function start(song) {
    var bg = new FlxSprite(-400, -500).loadGraphic(hscriptPath + 'evilBG.png');
    bg.scrollFactor.set(0.2, 0.2);
    bg.antialiasing = true;
    bg.setGraphicSize(Std.int(0.8 * bg.width));
    bg.updateHitbox();
    addSprite(bg, BEHIND_ALL);
;
    var tree = new FlxSprite(300, -300).loadGraphic(hscriptPath + 'evilTree.png');
    tree.antialiasing = true;
    tree.scrollFactor.set(0.4, 0.4);
    addSprite(tree, BEHIND_ALL);
    var snow = new FlxSprite(-200, 700).loadGraphic(hscriptPath + 'evilSnow.png');
    snow.antialiasing = true;
    addSprite(snow, BEHIND_ALL);
    boyfriend.x += 320;

    dad.y -=80;
}


function beatHit(beat)
{
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

