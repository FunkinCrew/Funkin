package game;

import lime.utils.Assets;
import haxe.Json;
import openfl.display.BitmapData;
#if polymod
import polymod.backends.PolymodAssets;
#end
import game.Character.CharacterAnimation;
import flixel.util.FlxColor;
import flixel.math.FlxPoint;
import openfl.filters.BlurFilter;
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

    public var player_1_Point:FlxPoint = new FlxPoint(1000, 800);
    public var player_2_Point:FlxPoint = new FlxPoint(300, 725);
    public var gf_Point:FlxPoint = new FlxPoint(600, 700);

    private var stage_Data:StageData;

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

    // WASTELAND STUFF
    private var watchTower:FlxSprite;
    private var rollingTank:FlxSprite;

    private var tankAngle:Float = FlxG.random.int(-90, 45);
    private var tankSpeed:Float = FlxG.random.float(5, 7);

    private var tankMen:Array<FlxSprite> = [];

    private var onBeatHit_Group:FlxTypedGroup<FlxSprite> = new FlxTypedGroup<FlxSprite>();

    public function updateStage(?newStage:String)
    {
        if(newStage != null)
            stage = newStage;

        var bruhStages = ['spooky','philly','limo','mall','evil-mall','school','evil-school','wasteland'];

        if(!bruhStages.contains(stage))
        {
            var JSON_Data:String = "";

            #if sys
            JSON_Data = PolymodAssets.getText(Paths.json("stage data/" + stage)).trim();
            #else
            JSON_Data = Assets.getText(Paths.json("stage data/" + stage)).trim();
            #end

            stage_Data = cast Json.parse(JSON_Data);
        }

        clear();

        switch(stage)
        {
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
            case "wasteland":
            {
                camZoom = 0.9;

                var sky = new FlxSprite(-400, -400);
                sky.scrollFactor.set(0, 0);
                sky.loadGraphic(Paths.image(stage + '/tankSky', 'stages'));
                add(sky);

                var clouds = new FlxSprite(FlxG.random.int(-700, -100), FlxG.random.int(-20, 20));
                clouds.scrollFactor.set(0.1, 0.1);
                clouds.loadGraphic(Paths.image(stage + '/tankClouds', 'stages'));
                clouds.velocity.set(FlxG.random.float(5, 15));
                add(clouds);

                var mountains = new FlxSprite(-300, -20);
                mountains.scrollFactor.set(0.2, 0.2);
                mountains.loadGraphic(Paths.image(stage + '/tankMountains', 'stages'));
                mountains.setGraphicSize(Std.int(mountains.width * 1.2));
                mountains.updateHitbox();
                add(mountains);

                var buildings = new FlxSprite(-200, 0);
                buildings.scrollFactor.set(0.3, 0.3);
                buildings.loadGraphic(Paths.image(stage + '/tankBuildings', 'stages'));
                buildings.setGraphicSize(Std.int(buildings.width * 1.1));
                buildings.updateHitbox();
                add(buildings);

                var ruins = new FlxSprite(-200, 0);
                ruins.scrollFactor.set(0.35, 0.35);
                ruins.loadGraphic(Paths.image(stage + '/tankRuins', 'stages'));
                ruins.setGraphicSize(Std.int(ruins.width * 1.1));
                ruins.updateHitbox();
                add(ruins);

                var leftSmoke = new FlxSprite(-200, -100);
                leftSmoke.scrollFactor.set(0.4, 0.4);
                leftSmoke.frames = Paths.getSparrowAtlas(stage + '/smokeLeft', 'stages');
                leftSmoke.animation.addByPrefix("default", "SmokeBlurLeft", 24, true);
                leftSmoke.animation.play("default");
                add(leftSmoke);

                var rightSmoke = new FlxSprite(1100, -100);
                rightSmoke.scrollFactor.set(0.4, 0.4);
                rightSmoke.frames = Paths.getSparrowAtlas(stage + '/smokeRight', 'stages');
                rightSmoke.animation.addByPrefix("default", "SmokeRight", 24, true);
                rightSmoke.animation.play("default");
                add(rightSmoke);

                watchTower = new FlxSprite(100, 50);
                watchTower.scrollFactor.set(0.5, 0.5);
                watchTower.frames = Paths.getSparrowAtlas(stage + '/tankWatchtower', 'stages');
                watchTower.animation.addByPrefix("idle", "watchtower gradient color", 24, false);
                watchTower.animation.play("idle");
                add(watchTower);

                rollingTank = new FlxSprite(300, 300);
                rollingTank.scrollFactor.set(0.5, 0.5);
                rollingTank.frames = Paths.getSparrowAtlas(stage + '/tankRolling', 'stages');
                rollingTank.animation.addByPrefix("idle", "BG tank w lighting", 24, true);
                rollingTank.animation.play("idle");
                add(rollingTank);

                var ground = new FlxSprite(-420, -150);
                ground.loadGraphic(Paths.image(stage + '/tankGround', 'stages'));
                ground.setGraphicSize(Std.int(ground.width * 1.15));
                ground.updateHitbox();
                add(ground);

                moveTank();

                // THE FRONT MENSSSS

                var tankMan0 = new FlxSprite(-500, 650);
                tankMan0.scrollFactor.set(1.7, 1.5);
                tankMan0.frames = Paths.getSparrowAtlas(stage + '/tank0', 'stages');
                tankMan0.animation.addByPrefix("idle", "fg", 24, false);
                tankMan0.animation.play("idle");
                PlayState.instance.foregroundSprites.add(tankMan0);

                var tankMan1 = new FlxSprite(-300, 750);
                tankMan1.scrollFactor.set(2, 0.2);
                tankMan1.frames = Paths.getSparrowAtlas(stage + '/tank1', 'stages');
                tankMan1.animation.addByPrefix("idle", "fg", 24, false);
                tankMan1.animation.play("idle");
                PlayState.instance.foregroundSprites.add(tankMan1);

                var tankMan2 = new FlxSprite(450, 940);
                tankMan2.scrollFactor.set(1.5, 1.5);
                tankMan2.frames = Paths.getSparrowAtlas(stage + '/tank2', 'stages');
                tankMan2.animation.addByPrefix("idle", "foreground", 24, false);
                tankMan2.animation.play("idle");
                PlayState.instance.foregroundSprites.add(tankMan2);

                var tankMan3 = new FlxSprite(1300, 900);
                tankMan3.scrollFactor.set(1.5, 1.5);
                tankMan3.frames = Paths.getSparrowAtlas(stage + '/tank4', 'stages');
                tankMan3.animation.addByPrefix("idle", "fg", 24, false);
                tankMan3.animation.play("idle");
                PlayState.instance.foregroundSprites.add(tankMan3);

                var tankMan4 = new FlxSprite(1300, 1200);
                tankMan4.scrollFactor.set(3.5, 2.5);
                tankMan4.frames = Paths.getSparrowAtlas(stage + '/tank3', 'stages');
                tankMan4.animation.addByPrefix("idle", "fg", 24, false);
                tankMan4.animation.play("idle");
                PlayState.instance.foregroundSprites.add(tankMan4);

                var tankMan5 = new FlxSprite(1620, 700);
                tankMan5.scrollFactor.set(1.5, 1.5);
                tankMan5.frames = Paths.getSparrowAtlas(stage + '/tank5', 'stages');
                tankMan5.animation.addByPrefix("idle", "fg", 24, false);
                tankMan5.animation.play("idle");
                PlayState.instance.foregroundSprites.add(tankMan5);

                tankMen.push(tankMan0);
                tankMen.push(tankMan1);
                tankMen.push(tankMan2);
                tankMen.push(tankMan3);
                tankMen.push(tankMan4);
                tankMen.push(tankMan5);
            }

            // CUSTOM SHIT
            default:
            {
                trace(stage_Data);

                camZoom = stage_Data.camera_Zoom;

                player_1_Point.set(stage_Data.character_Positions[0][0], stage_Data.character_Positions[0][1]);
                player_2_Point.set(stage_Data.character_Positions[1][0], stage_Data.character_Positions[1][1]);
                gf_Point.set(stage_Data.character_Positions[2][0], stage_Data.character_Positions[2][1]);

                for(Object in stage_Data.objects)
                {
                    var Sprite = new FlxSprite(Object.position[0], Object.position[1]);

                    trace(Object);

                    if(Object.color != null && Object.color != [])
                        Sprite.color = FlxColor.fromRGB(Object.color[0], Object.color[1], Object.color[2]);

                    Sprite.antialiasing = Object.antialiased;
                    Sprite.scrollFactor.set(Object.scroll_Factor[0], Object.scroll_Factor[1]);

                    if(Object.is_Animated)
                    {
                        #if sys
                        Sprite.frames = Paths.getSparrowAtlasSYS(stage + "/" + Object.file_Name, "stages");
                        #else
                        Sprite.frames = Paths.getSparrowAtlas(stage + "/" + Object.file_Name, "stages");
                        #end

                        for(Animation in Object.animations)
                        {
                            var Anim_Name = Animation.name;

                            if(Animation.name == "beatHit")
                                onBeatHit_Group.add(Sprite);

                            Sprite.animation.addByPrefix(
                                Anim_Name,
                                Animation.animation_name,
                                Animation.fps,
                                Animation.looped
                            );
                        }

                        if(Object.start_Animation != "" && Object.start_Animation != null)
                            Sprite.animation.play(Object.start_Animation);
                    }
                    else
                    {
                        #if sys
                        if(Assets.exists(Paths.image(stage + "/" + Object.file_Name, "stages")))
                            Sprite.loadGraphic(Paths.image(stage + "/" + Object.file_Name, "stages"));
                        else
                            Sprite.loadGraphic(Paths.imageSYS(stage + "/" + Object.file_Name, "stages"), false, 0, 0, false, Object.file_Name);
                        #else
                        Sprite.loadGraphic(Paths.image(stage + "/" + Object.file_Name, "stages"));
                        #end
                    }

                    Sprite.setGraphicSize(Std.int(Sprite.width * Object.scale));
                    Sprite.updateHitbox();

                    add(Sprite);
                }
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
            case 'wasteland':
                PlayState.gf.y += 10;
                PlayState.gf.x -= 60;

                PlayState.boyfriend.x += 40;

                PlayState.dad.y += 60;
                PlayState.dad.x -= 80;

                if(PlayState.gf.curCharacter == 'pico-speaker')
                {
                    PlayState.gf.x -= 170;
                    PlayState.gf.y -= 45;
                }
        }

        var p1 = PlayState.boyfriend;
        var gf = PlayState.gf;
        var p2 = PlayState.dad;

        p1.setPosition(player_1_Point.x - (p1.width / 2), player_1_Point.y - p1.height);
        gf.setPosition(gf_Point.x - (gf.width / 2), gf_Point.y - gf.height);
        p2.setPosition(player_2_Point.x - (p2.width / 2), player_2_Point.y - p2.height);

        if(PlayState.SONG.player2.startsWith("gf") && PlayState.SONG.gf.startsWith("gf"))
            p2.setPosition(gf.x, gf.y);
    }

    override public function new(?stageName:String) {
        super();

        stage = stageName;
        updateStage();
    }

    public function beatHit()
    {
        for(sprite in onBeatHit_Group)
        {
            sprite.animation.play("beatHit", true);
        }

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
            case 'wasteland':
            {
                watchTower.animation.play("idle", true);

                for(object in tankMen)
                {
                    object.animation.play("idle", true);
                }
            }
        }
    }

    override function update(elapsed:Float)
    {
        super.update(elapsed);

        switch(stage)
        {
            case 'philly':
                if (trainMoving)
                {
                    trainFrameTiming += goodElapse;
    
                    if (trainFrameTiming >= 1 / 24)
                    {
                        updateTrainPos();
                        trainFrameTiming = 0;
                    }
                }
            case 'wasteland':
                moveTank();
        }

        goodElapse = elapsed;
    }

    //wasteland
    function moveTank()
    {
        var tankX = 400;
        tankAngle += FlxG.elapsed * tankSpeed;
        rollingTank.angle = tankAngle - 90 + 15;
        rollingTank.x = tankX + 1500 * Math.cos(Math.PI / 180 * (1 * tankAngle + 180));
        rollingTank.y = 1300 + 1100 * Math.sin(Math.PI / 180 * (1 * tankAngle + 180));
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

typedef StageData =
{
    var character_Positions:Array<Array<Int>>;
    var camera_Zoom:Float;

    var objects:Array<StageObject>;
}

typedef StageObject =
{
    // General Sprite Object Data //
    var position:Array<Float>;
    var scale:Float;
    var antialiased:Bool;
    var scroll_Factor:Array<Float>;

    var color:Array<Int>;
    
    // Image Info //
    var file_Name:String;
    var is_Animated:Bool;

    // Animations //
    var animations:Array<CharacterAnimation>;

    var on_Beat_Hit_Animation:String;
    var on_Step_Hit_Animation:String;

    var start_Animation:String;
}