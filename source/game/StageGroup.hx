package game;

import states.PlayState;
import backgrounds.BackgroundGirls;
import backgrounds.BackgroundDancer;
import flixel.addons.effects.FlxTrail;
import flixel.util.FlxTimer;
import flixel.system.FlxSound;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;

using StringTools;

class StageGroup extends FlxGroup
{
    public var stage:String = "chromatic-stage";
    public var camZoom:Float = 1.05;
    private var goodElapse:Float = 0;

    // SPOOKY STUFF
    private var halloweenBG:FlxSprite;
    private var lightningStrikeBeat:Int = 0;
    private var lightningOffset:Int = 8;

    // PHILLY STUFF
    private var phillyCityLights:FlxTypedGroup<FlxSprite>;
    private var phillyTrain:FlxSprite;
    private var trainSound:FlxSound;
    private var trainMoving:Bool = false;
    private var startedMoving:Bool = false;
    private var trainFinishing:Bool = false;
    private var trainFrameTiming:Float = 0;
    private var trainCars:Int = 8;
    private var trainCooldown:Int = 0;
    private var curLight:Int = 0;

    // LIMO STUFF
    private var grpLimoDancers:FlxTypedGroup<BackgroundDancer>;
    private var fastCar:FlxSprite;
    private var fastCarCanDrive:Bool = true;

    // for layering because FUCK I HATE LAYERING IN HAXEFLIXEL AAAAAAAAAAAAAAAAAA
    public var limo:FlxSprite;

    // MALL STUFF
    private var santa:FlxSprite;
    private var upperBoppers:FlxSprite;
    private var bottomBoppers:FlxSprite;

    // SCHOOL STUFF
    private var bgGirls:BackgroundGirls;

    public function updateStage(?newStage:String)
    {
        if(newStage != null)
        {
            stage = newStage;
        }

        clear();

        switch(stage)
        {
            case "stage":
            {
                camZoom = 0.9;
                
                var bg:FlxSprite = new FlxSprite(-600, -200).loadGraphic(Paths.image(stage + '/stageback', 'stages'));
                bg.antialiasing = true;
                bg.scrollFactor.set(0.9, 0.9);
                bg.active = false;
                add(bg);

                var stageFront:FlxSprite = new FlxSprite(-650, 600).loadGraphic(Paths.image(stage + '/stagefront', 'stages'));
                stageFront.setGraphicSize(Std.int(stageFront.width * 1.1));
                stageFront.updateHitbox();
                stageFront.antialiasing = true;
                stageFront.scrollFactor.set(0.9, 0.9);
                stageFront.active = false;
                add(stageFront);

                var stageCurtains:FlxSprite = new FlxSprite(-500, -300).loadGraphic(Paths.image(stage + '/stagecurtains', 'stages'));
                stageCurtains.setGraphicSize(Std.int(stageCurtains.width * 0.9));
                stageCurtains.updateHitbox();
                stageCurtains.antialiasing = true;
                stageCurtains.scrollFactor.set(1.3, 1.3);
                stageCurtains.active = false;
                add(stageCurtains);
            }
            case "chromatic-stage":
            {
                camZoom = 0.9;
                
                var testBg:FlxSprite = new FlxSprite(-600, -200).loadGraphic(Paths.image(stage + '/chr-stageback', 'stages'));
                testBg.antialiasing = true;
                testBg.scrollFactor.set(0.9, 0.9);
                testBg.active = false;
                add(testBg);

                var testFront:FlxSprite = new FlxSprite(-650, 600).loadGraphic(Paths.image(stage + '/chr-stagefront', 'stages'));
                testFront.setGraphicSize(Std.int(testFront.width * 1.1));
                testFront.updateHitbox();
                testFront.antialiasing = true;
                testFront.scrollFactor.set(0.9, 0.9);
                testFront.active = false;
                add(testFront);

                var testCurtains:FlxSprite = new FlxSprite(-500, -300).loadGraphic(Paths.image(stage + '/chr-stagecurtains', 'stages'));
                testCurtains.setGraphicSize(Std.int(testCurtains.width * 0.9));
                testCurtains.updateHitbox();
                testCurtains.antialiasing = true;
                testCurtains.scrollFactor.set(1.3, 1.3);
                testCurtains.active = false;
                add(testCurtains);
            }
            case "spooky":
            {
                var hallowTex = Paths.getSparrowAtlas(stage + '/halloween_bg', 'stages');

                halloweenBG = new FlxSprite(-200, -100);
                halloweenBG.frames = hallowTex;
                halloweenBG.animation.addByPrefix('idle', 'halloweem bg0');
                halloweenBG.animation.addByPrefix('lightning', 'halloweem bg lightning strike', 24, false);
                halloweenBG.animation.play('idle');
                halloweenBG.antialiasing = true;
                add(halloweenBG);
            }
            case "philly":
            {
                var bg:FlxSprite = new FlxSprite(-100).loadGraphic(Paths.image(stage + '/sky', 'stages'));
                bg.scrollFactor.set(0.1, 0.1);
                add(bg);

                var city:FlxSprite = new FlxSprite(-10).loadGraphic(Paths.image(stage + '/city', 'stages'));
                city.scrollFactor.set(0.3, 0.3);
                city.setGraphicSize(Std.int(city.width * 0.85));
                city.updateHitbox();
                add(city);

                phillyCityLights = new FlxTypedGroup<FlxSprite>();
                add(phillyCityLights);

                for (i in 0...5)
                {
                    var light:FlxSprite = new FlxSprite(city.x).loadGraphic(Paths.image(stage + '/win' + i, 'stages'));
                    light.scrollFactor.set(0.3, 0.3);
                    light.visible = false;
                    light.setGraphicSize(Std.int(light.width * 0.85));
                    light.updateHitbox();
                    light.antialiasing = true;
                    phillyCityLights.add(light);
                }

                var streetBehind:FlxSprite = new FlxSprite(-40, 50).loadGraphic(Paths.image(stage + '/behindTrain', 'stages'));
                add(streetBehind);

                phillyTrain = new FlxSprite(2000, 360).loadGraphic(Paths.image(stage + '/train', 'stages'));
                add(phillyTrain);

                trainSound = new FlxSound().loadEmbedded(Paths.sound('train_passes'));
                FlxG.sound.list.add(trainSound);

                var street:FlxSprite = new FlxSprite(-40, streetBehind.y).loadGraphic(Paths.image(stage + '/street', 'stages'));
                add(street);
            }
            case "limo":
            {
                camZoom = 0.9;

                var skyBG:FlxSprite = new FlxSprite(-120, -50).loadGraphic(Paths.image(stage + '/limoSunset', 'stages'));
                skyBG.scrollFactor.set(0.1, 0.1);
                add(skyBG);

                var bgLimo:FlxSprite = new FlxSprite(-200, 480);
                bgLimo.frames = Paths.getSparrowAtlas(stage + '/bgLimo', 'stages');
                bgLimo.animation.addByPrefix('drive', "background limo pink", 24);
                bgLimo.animation.play('drive');
                bgLimo.scrollFactor.set(0.4, 0.4);
                add(bgLimo);

                grpLimoDancers = new FlxTypedGroup<BackgroundDancer>();
                add(grpLimoDancers);

                for (i in 0...5)
                {
                    var dancer:BackgroundDancer = new BackgroundDancer((370 * i) + 130, bgLimo.y - 400);
                    dancer.scrollFactor.set(0.4, 0.4);
                    grpLimoDancers.add(dancer);
                }

                var limoTex = Paths.getSparrowAtlas(stage + '/limoDrive', 'stages');

                limo = new FlxSprite(-120, 550);
                limo.frames = limoTex;
                limo.animation.addByPrefix('drive', "Limo stage", 24);
                limo.animation.play('drive');
                limo.antialiasing = true;
                add(limo);

                fastCar = new FlxSprite(-300, 160).loadGraphic(Paths.image(stage + '/fastCarLol', 'stages'));
            }
            case "mall":
            {
                camZoom = 0.8;

                var bg:FlxSprite = new FlxSprite(-1000, -500).loadGraphic(Paths.image(stage + '/bgWalls', 'stages'));
                bg.antialiasing = true;
                bg.scrollFactor.set(0.2, 0.2);
                bg.active = false;
                bg.setGraphicSize(Std.int(bg.width * 0.8));
                bg.updateHitbox();
                add(bg);

                upperBoppers = new FlxSprite(-240, -90);
                upperBoppers.frames = Paths.getSparrowAtlas(stage + '/upperBop', 'stages');
                upperBoppers.animation.addByPrefix('bop', "Upper Crowd Bob", 24, false);
                upperBoppers.antialiasing = true;
                upperBoppers.scrollFactor.set(0.33, 0.33);
                upperBoppers.setGraphicSize(Std.int(upperBoppers.width * 0.85));
                upperBoppers.updateHitbox();
                add(upperBoppers);

                var bgEscalator:FlxSprite = new FlxSprite(-1100, -600).loadGraphic(Paths.image(stage + '/bgEscalator', 'stages'));
                bgEscalator.antialiasing = true;
                bgEscalator.scrollFactor.set(0.3, 0.3);
                bgEscalator.active = false;
                bgEscalator.setGraphicSize(Std.int(bgEscalator.width * 0.9));
                bgEscalator.updateHitbox();
                add(bgEscalator);

                var tree:FlxSprite = new FlxSprite(370, -250).loadGraphic(Paths.image(stage + '/christmasTree', 'stages'));
                tree.antialiasing = true;
                tree.scrollFactor.set(0.40, 0.40);
                add(tree);

                bottomBoppers = new FlxSprite(-300, 140);
                bottomBoppers.frames = Paths.getSparrowAtlas(stage + '/bottomBop', 'stages');
                bottomBoppers.animation.addByPrefix('bop', 'Bottom Level Boppers', 24, false);
                bottomBoppers.antialiasing = true;
                bottomBoppers.scrollFactor.set(0.9, 0.9);
                bottomBoppers.setGraphicSize(Std.int(bottomBoppers.width * 1));
                bottomBoppers.updateHitbox();
                add(bottomBoppers);

                var fgSnow:FlxSprite = new FlxSprite(-600, 700).loadGraphic(Paths.image(stage + '/fgSnow', 'stages'));
                fgSnow.active = false;
                fgSnow.antialiasing = true;
                add(fgSnow);

                santa = new FlxSprite(-840, 150);
                santa.frames = Paths.getSparrowAtlas(stage + '/santa', 'stages');
                santa.animation.addByPrefix('idle', 'santa idle in fear', 24, false);
                santa.antialiasing = true;
                add(santa);
            }
            case "evil-mall":
            {
                var bg:FlxSprite = new FlxSprite(-400, -500).loadGraphic(Paths.image(stage + '/evilBG', 'stages'));
                bg.antialiasing = true;
                bg.scrollFactor.set(0.2, 0.2);
                bg.active = false;
                bg.setGraphicSize(Std.int(bg.width * 0.8));
                bg.updateHitbox();
                add(bg);

                var evilTree:FlxSprite = new FlxSprite(300, -300).loadGraphic(Paths.image(stage + '/evilTree', 'stages'));
                evilTree.antialiasing = true;
                evilTree.scrollFactor.set(0.2, 0.2);
                add(evilTree);

                var evilSnow:FlxSprite = new FlxSprite(-200, 700).loadGraphic(Paths.image(stage + "/evilSnow", 'stages'));
                evilSnow.antialiasing = true;
                add(evilSnow);
            }
            case "school":
            {
                var bgSky = new FlxSprite().loadGraphic(Paths.image(stage + '/weebSky', 'stages'));
                bgSky.scrollFactor.set(0.1, 0.1);
                add(bgSky);

                var repositionShit = -200;

                var bgSchool:FlxSprite = new FlxSprite(repositionShit, 0).loadGraphic(Paths.image(stage + '/weebSchool', 'stages'));
                bgSchool.scrollFactor.set(0.6, 0.90);
                add(bgSchool);

                var bgStreet:FlxSprite = new FlxSprite(repositionShit).loadGraphic(Paths.image(stage + '/weebStreet', 'stages'));
                bgStreet.scrollFactor.set(0.95, 0.95);
                add(bgStreet);

                var fgTrees:FlxSprite = new FlxSprite(repositionShit + 170, 130).loadGraphic(Paths.image(stage + '/weebTreesBack', 'stages'));
                fgTrees.scrollFactor.set(0.9, 0.9);
                add(fgTrees);

                var bgTrees:FlxSprite = new FlxSprite(repositionShit - 380, -800);
                var treetex = Paths.getPackerAtlas(stage + '/weebTrees', 'stages');
                bgTrees.frames = treetex;
                bgTrees.animation.add('treeLoop', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18], 12);
                bgTrees.animation.play('treeLoop');
                bgTrees.scrollFactor.set(0.85, 0.85);
                add(bgTrees);

                var treeLeaves:FlxSprite = new FlxSprite(repositionShit, -40);
                treeLeaves.frames = Paths.getSparrowAtlas(stage + '/petals', 'stages');
                treeLeaves.animation.addByPrefix('leaves', 'PETALS ALL', 24, true);
                treeLeaves.animation.play('leaves');
                treeLeaves.scrollFactor.set(0.85, 0.85);
                add(treeLeaves);

                var widShit = Std.int(bgSky.width * 6);

                bgSky.setGraphicSize(widShit);
                bgSchool.setGraphicSize(widShit);
                bgStreet.setGraphicSize(widShit);
                bgTrees.setGraphicSize(Std.int(widShit * 1.4));
                fgTrees.setGraphicSize(Std.int(widShit * 0.8));
                treeLeaves.setGraphicSize(widShit);

                fgTrees.updateHitbox();
                bgSky.updateHitbox();
                bgSchool.updateHitbox();
                bgStreet.updateHitbox();
                bgTrees.updateHitbox();
                treeLeaves.updateHitbox();

                bgGirls = new BackgroundGirls(-100, 190);
                bgGirls.scrollFactor.set(0.9, 0.9);

                if (PlayState.SONG.song.toLowerCase() == 'roses')
                {
                    bgGirls.getScared();
                }

                bgGirls.setGraphicSize(Std.int(bgGirls.width * PlayState.daPixelZoom));
                bgGirls.updateHitbox();
                add(bgGirls);
            }
            case "evil-school":
            {
                var bg:FlxSprite = new FlxSprite(400, 220);
                bg.frames = Paths.getSparrowAtlas(stage + '/animatedEvilSchool', 'stages');
                bg.animation.addByPrefix('idle', 'background 2', 24);
                bg.animation.play('idle');
                bg.scrollFactor.set(0.8, 0.9);
                bg.scale.set(6, 6);
                add(bg);
            }
        }
    }

    public function setCharOffsets():Void
    {
        switch(stage)
        {
            case 'limo':
				PlayState.boyfriend.y -= 220;
				PlayState.boyfriend.x += 260;

				resetFastCar();
				add(fastCar);
			case 'mall':
				PlayState.boyfriend.x += 200;
			case 'evil-mall':
				PlayState.boyfriend.x += 320;
				PlayState.dad.y -= 80;
			case 'school':
				PlayState.boyfriend.x += 200;
				PlayState.boyfriend.y += 220;
				PlayState.gf.x += 180;
				PlayState.gf.y += 300;
			case 'evil-school':
                var evilTrail = new FlxTrail(PlayState.dad, null, 4, 24, 0.3, 0.069);
                add(evilTrail);

				PlayState.boyfriend.x += 200;
				PlayState.boyfriend.y += 220;
				PlayState.gf.x += 180;
				PlayState.gf.y += 300;
        }
    }

    override public function new(?stageName:String) {
        super();

        stage = stageName;
        updateStage();
    }

    public function beatHit()
    {
        switch(stage)
        {
            case 'philly':
            {
                if (!trainMoving)
					trainCooldown += 1;

				if (PlayState.currentBeat % 4 == 0)
				{
					phillyCityLights.forEach(function(light:FlxSprite)
					{
						light.visible = false;
					});

					curLight = FlxG.random.int(0, phillyCityLights.length - 1);

					phillyCityLights.members[curLight].visible = true;
					// phillyCityLights.members[curLight].alpha = 1;
				}

				if (PlayState.currentBeat % 8 == 4 && FlxG.random.bool(30) && !trainMoving && trainCooldown > 8)
				{
					trainCooldown = FlxG.random.int(-4, 0);
					trainStart();
				}
            }
            case 'school':
            {
                bgGirls.dance();
            }
            case 'mall':
            {
                upperBoppers.animation.play('bop', true);
				bottomBoppers.animation.play('bop', true);
				santa.animation.play('idle', true);
            }
            case 'limo':
            {
                grpLimoDancers.forEach(function(dancer:BackgroundDancer)
                {
                    dancer.dance();
                });

                if (FlxG.random.bool(10) && fastCarCanDrive)
                    fastCarDrive();
            }
            case 'spooky':
            {
                if (FlxG.random.bool(10) && PlayState.currentBeat > lightningStrikeBeat + lightningOffset)
                {
                    lightningStrikeShit();
                }
            }
        }
    }

    override function update(elapsed:Float)
    {
        super.update(elapsed);

        if(stage == "philly")
        {
            if (trainMoving)
            {
                trainFrameTiming += goodElapse;

                if (trainFrameTiming >= 1 / 24)
                {
                    updateTrainPos();
                    trainFrameTiming = 0;
                }
            }
        }

        goodElapse = elapsed;
    }

    // philly

    function updateTrainPos() {
        if (trainSound.time >= 4700)
        {
            startedMoving = true;
            PlayState.gf.playAnim('hairBlow');
        }

        if (startedMoving)
        {
            phillyTrain.x -= 400;

            if (phillyTrain.x < -2000 && !trainFinishing)
            {
                phillyTrain.x = -1150;
                trainCars -= 1;

                if (trainCars <= 0)
                    trainFinishing = true;
            }

            if (phillyTrain.x < -4000 && trainFinishing)
                trainReset();
        }
    }

    function trainReset()
    {
        PlayState.gf.playAnim('hairFall');
		phillyTrain.x = FlxG.width + 200;
		trainMoving = false;
		trainCars = 8;
		trainFinishing = false;
		startedMoving = false;
    }

    function trainStart():Void
    {
        trainMoving = true;
        if (!trainSound.playing)
            trainSound.play(true);
    }

    // limo

	function resetFastCar():Void
	{
		fastCar.x = -12600;
		fastCar.y = FlxG.random.int(140, 250);
		fastCar.velocity.x = 0;
		fastCarCanDrive = true;
	}

	function fastCarDrive()
	{
		FlxG.sound.play(Paths.soundRandom('carPass', 0, 1), 0.7);

		fastCar.velocity.x = (FlxG.random.int(170, 220) / FlxG.elapsed) * 3;
		fastCarCanDrive = false;
		new FlxTimer().start(2, function(tmr:FlxTimer)
		{
			resetFastCar();
		});
	}

    // spooky

    function lightningStrikeShit():Void
    {
        PlayState.boyfriend.playAnim('scared', true);
        PlayState.gf.playAnim('scared', true);
        
        FlxG.sound.play(Paths.soundRandom('thunder_', 1, 2));
        halloweenBG.animation.play('lightning');

        lightningStrikeBeat = PlayState.currentBeat;
        lightningOffset = FlxG.random.int(8, 24);
    }
}