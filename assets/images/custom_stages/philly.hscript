var train;
var lights;
var trainSound;
function start(song) {
    var bg = new FlxSprite(-100).loadGraphic(hscriptPath + 'sky.png');
    bg.scrollFactor.set(0.1, 0.1);
    bg.antialiasing = true;
    addSprite(bg, BEHIND_ALL);
    trace("poyo");
    var city = new FlxSprite(-10).loadGraphic(hscriptPath + 'city.png');
    trace("woozy");
    trace(":woozy-face:");
    city.scrollFactor.set(0.3, 0.3);
    city.antialiasing = true;
    city.scale.set(0.85, 0.85);
    city.updateHitbox();
    trace(":POG:");
    addSprite(city, BEHIND_ALL);
    lights = new FlxGroup();
    for (i in 0...5) {
        var light = new FlxSprite(-10).loadGraphic(hscriptPath + 'win' + i + '.png');
        light.setGraphicSize(Std.int(0.85 * light.width));
        light.updateHitbox();
        light.visible = false;
        light.antialiasing = true;
        light.scrollFactor.set(0.3,0.3);
        lights.add(light);
    }
    addSprite(lights, BEHIND_ALL);
    var streetBehind = new FlxSprite(-40, 50).loadGraphic(hscriptPath + 'behindTrain.png');
    streetBehind.antialiasing = true;
    addSprite(streetBehind, BEHIND_ALL);
    train = new FlxSprite(2000, 360).loadGraphic(hscriptPath + 'train.png');
    train.antialiasing = true;
    addSprite(train, BEHIND_ALL);
    trainSound = new FlxSound().loadEmbedded(hscriptPath + 'train_passes.ogg');
    FlxG.sound.list.add(trainSound);
    var street = new FlxSprite(-40, 50).loadGraphic(hscriptPath + 'street.png');
    street.antialiasing = true;
    addSprite(street, BEHIND_ALL);
    setDefaultZoom(0.9);
}

var trainCooldown = 0;
var trainCars = 8;
var trainMoving = false;
var trainFinishing = false;
var trainFrameTiming = 0.0;
var startedMoving = false;
function beatHit(beat)
{
    if (!trainMoving) {
        trainCooldown += 1;
    }
    if (beat % 4 == 0) {
        lights.forEach(function(spr) {
            spr.visible = false;
        });
        lights.members[FlxG.random.int(0,4)].visible = true;
    }
    if (beat % 8 == 4 && FlxG.random.bool(30) && !trainMoving && trainCooldown > 8) {
        trainCooldown = FlxG.random.int(-4,0);
        doVroomVroom();
    }
}

function update(elapsed)
{
    if (trainMoving) {
        trainFrameTiming += elapsed;
        if (trainFrameTiming >= 1/24) {
            updateVroomVroom();
            trainFrameTiming = 0.0;
        }
    }
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

function doVroomVroom() {
    trainMoving = true;
    if (!trainSound.playing) {
        trainSound.play(false);
    }
}
function updateVroomVroom() {
    if (trainSound.time >= 4700) {
        startedMoving = true;
        gf.playAnim("hairBlow");
    }
    if (startedMoving) {
        train.x -= 400;
        if (train.x < -2000 && !trainFinishing) {
            train.x = -1150;
            trainCars -= 1;
            if (trainCars <= 0) {
                trainFinishing = true;
            }
        }
        if (train.x < -4000 && trainFinishing) {
            resetVroomVroom();
        }
    }
}
function resetVroomVroom() {
    gf.playAnim("hairFall");
    train.x = FlxG.width + 200;
    trainMoving = false;
    trainCars = 8;
    trainFinishing = false;
    startedMoving = false;
}