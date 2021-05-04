trace(" : )");
var steve;
var johns;
var tower;
var losers;
function start(song) {
    trace(" : )");
    var bg = new FlxSprite(-400, -400).loadGraphic(hscriptPath + 'tankSky.png');
    bg.scrollFactor.set();
    bg.antialiasing = true;
    addSprite(bg, BEHIND_ALL);

    var clouds = new FlxSprite(FlxG.random.int(-700, -100), FlxG.random.int(-20, 20)).loadGraphic(hscriptPath + 'tankClouds.png');

	clouds.antialiasing = true;
	clouds.scrollFactor.set(0.1, 0.1);
    clouds.velocity.x = FlxG.random.float(5,15);
    addSprite(clouds, BEHIND_ALL);
    var mountains = new FlxSprite(-300, -20).loadGraphic(hscriptPath + 'tankMountains.png');
    mountains.antialiasing = true;
    mountains.setGraphicSize(Std.int(mountains.width * 1.2));
    mountains.updateHitbox();
    mountains.scrollFactor.set(0.2, 0.2);
    addSprite(mountains, BEHIND_ALL);
    var building = new FlxSprite(-200).loadGraphic(hscriptPath + 'tankBuildings.png');
    building.setGraphicSize(Std.int(building.width * 1.1));
    building.antialiasing = true;
    building.updateHitbox();
    building.scrollFactor.set(0.3, 0.3);
    addSprite(building, BEHIND_ALL);
    var ruins = new FlxSprite(-200).loadGraphic(hscriptPath + 'tankRuins.png');
    ruins.scrollFactor.set(0.35, 0.35);
    ruins.setGraphicSize(Std.int(1.1 * ruins.width));
    ruins.updateHitbox();
    ruins.antialiasing = true;
    addSprite(ruins, BEHIND_ALL);
    var smokeLeft = new FlxSprite(-200 , -100);
    smokeLeft.frames = FlxAtlasFrames.fromSparrow(hscriptPath + 'smokeLeft.png', hscriptPath + 'smokeLeft.xml');
    smokeLeft.animation.addByPrefix('idle', 'SmokeBlurLeft', 24, true);
    smokeLeft.animation.play('idle', true);
    smokeLeft.scrollFactor.set(0.4, 0.4);
    smokeLeft.antialiasing = true;
    addSprite(smokeLeft, BEHIND_ALL);


    trace(":weary:");
	var smokeRight = new FlxSprite(1100, -100);
	smokeRight.frames = FlxAtlasFrames.fromSparrow(hscriptPath + 'smokeRight.png', hscriptPath + 'smokeRight.xml');
	smokeRight.animation.addByPrefix('idle', 'SmokeRight', 24, true);
	smokeRight.animation.play('idle', true);
	smokeRight.scrollFactor.set(0.4, 0.4);
    smokeRight.antialiasing = true;
	addSprite(smokeRight, BEHIND_ALL);
    trace(":hueh:");
	tower = new FlxSprite(100, 50);
    trace("WAH tower");
	tower.frames = FlxAtlasFrames.fromSparrow(hscriptPath + 'tankWatchtower.png', hscriptPath + 'tankWatchtower.xml');
    trace("RED ALERT: ioajfha");
	tower.animation.addByPrefix('idle', 'watchtower gradient color', 24, false);
	tower.animation.play('idle', true);
    trace("eugh");
	tower.scrollFactor.set(0.5, 0.5);
	tower.updateHitbox();
	tower.antialiasing = true;
	addSprite(tower, BEHIND_ALL);
    trace(":pensive:");
    steve = new FlxSprite(300, 300);
    steve.frames = FlxAtlasFrames.fromSparrow(hscriptPath + 'tankRolling.png', hscriptPath + 'tankRolling.xml');
    steve.animation.addByPrefix('idle', "BG tank w lighting", 24, true);
    steve.animation.play('idle', true);
    steve.antialiasing = true;
    steve.scrollFactor.set(0.5, 0.5);
    addSprite(steve, BEHIND_ALL);

    // note to gamers, type classes don't work
    trace("before johnathan");
    johns = new FlxGroup();
    addSprite(johns, BEHIND_ALL);
    var ground = new FlxSprite(-420, -150).loadGraphic(hscriptPath + 'tankGround.png');
    ground.setGraphicSize(Std.int(1.15 * ground.width));
    ground.updateHitbox();
    ground.antialiasing = true;
    addSprite(ground, BEHIND_ALL);
    losers = new FlxGroup();
    var tank0 = new FlxSprite(-500, 650);
    tank0.frames = FlxAtlasFrames.fromSparrow(hscriptPath + 'tank0.png', hscriptPath + 'tank0.xml');
    tank0.antialiasing = true;
    tank0.animation.addByPrefix("idle", "fg", 24, false);
    tank0.scrollFactor.set(1.7, 1.5);
    tank0.animation.play("idle");
    losers.add(tank0);

	var tank1 = new FlxSprite(-300, 750);
	tank1.frames = FlxAtlasFrames.fromSparrow(hscriptPath + 'tank1.png', hscriptPath + 'tank1.xml');
	tank1.antialiasing = true;
	tank1.animation.addByPrefix("idle", "fg", 24, false);
	tank1.scrollFactor.set(2, 0.2);
	tank1.animation.play("idle");
	losers.add(tank1);

	var tank2 = new FlxSprite(450, 940);
	tank2.frames = FlxAtlasFrames.fromSparrow(hscriptPath + 'tank2.png', hscriptPath + 'tank2.xml');
	tank2.antialiasing = true;
	tank2.animation.addByPrefix("idle", "foreground", 24, false);
	tank2.scrollFactor.set(1.5, 1.5);
	tank2.animation.play("idle");
	losers.add(tank2);

	var tank4 = new FlxSprite(1300, 900);
	tank4.frames = FlxAtlasFrames.fromSparrow(hscriptPath + 'tank4.png', hscriptPath + 'tank4.xml');
	tank4.antialiasing = true;
	tank4.animation.addByPrefix("idle", "fg", 24, false);
	tank4.scrollFactor.set(1.5, 1.5);
	tank4.animation.play("idle");
	losers.add(tank4);

	var tank5 = new FlxSprite(1620, 700);
	tank5.frames = FlxAtlasFrames.fromSparrow(hscriptPath + 'tank5.png', hscriptPath + 'tank5.xml');
	tank5.antialiasing = true;
	tank5.animation.addByPrefix("idle", "fg", 24, false);
	tank5.scrollFactor.set(1.5, 1.5);
	tank5.animation.play("idle");
	losers.add(tank5);

	var tank3 = new FlxSprite(1300, 1200);
	tank3.frames = FlxAtlasFrames.fromSparrow(hscriptPath + 'tank3.png', hscriptPath + 'tank3.xml');
	tank3.antialiasing = true;
	tank3.animation.addByPrefix("idle", "fg", 24, false);
	tank3.scrollFactor.set(3.5, 2.5);
	tank3.animation.play("idle");
	losers.add(tank3);

    addSprite(losers, BEHIND_NONE);

	getHaxeActor("gf").y += 10;
	getHaxeActor("gf").x -= 30;
	getHaxeActor("boyfriend").x += 40;
	trace(getHaxeActor("dad"));
	getHaxeActor("dad").y += 60;
	getHaxeActor("dad").x -= 80;
	setDefaultZoom(0.9);
    trace(gf.like);
	if (getHaxeActor("gf").like != "pico-speaker") {
        getHaxeActor("gf").x -= 170;
		getHaxeActor("gf").y -= 75;
    } else {
		getHaxeActor("gf").y -= 200;
		getHaxeActor("gf").x -= 50;
		trace("finna instance");
        /*
		var john = new RunningTankman(20, 500, hscriptPath);
		john.strumTime = gf.animationNotes[0][0];
		john.resetShit(20, 600, true);
        johns.add(john);
		for (c in 0...gf.animationNotes.length)
		{
			if (FlxG.random.float(0, 100) < 16)
			{
				var jahn = new RunningTankman(500, 20, hscriptPath);
				jahn.strumTime = gf.animationNotes[c + 1][0];
				jahn.resetShit(500, 200 + FlxG.random.int(50, 100), 2 > gf.animationNotes[c + 1][1]);
                johns.add(jahn);
				trace("make johgf");
			}
		}*/
    }
    
}



function beatHit(beat)
{
    losers.forEach(function (spr) {
        spr.animation.play("idle", true);
    });
    tower.animation.play("idle", true);
}
var tankAngle = FlxG.random.int(-90, 45);
var tankSpeed = FlxG.random.float(5, 7);
var tankX = 400;
function moveTank() {
    if (!isInCutscene()) {
        tankAngle += FlxG.elapsed * tankSpeed;
        steve.angle = tankAngle - 90 + 15;
        steve.x = tankX + 1500 * FlxMath.fastCos(FlxAngle.asRadians(tankAngle + 180));
        steve.y = 1300 + 1100 * FlxMath.fastSin(FlxAngle.asRadians(tankAngle + 180));
    }
}
function update(elapsed)
{
    moveTank();

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

