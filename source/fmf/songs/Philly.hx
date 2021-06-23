package fmf.songs;

import fmf.characters.*;
import flixel.util.FlxTimer;
import flixel.system.FlxSound;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.FlxG;
import flixel.FlxSprite;
import Song.SwagSong;

class Philly extends SongPlayer
{
	var phillyCityLights:FlxTypedGroup<FlxSprite>;
	var phillyTrain:FlxSprite;
	var trainSound:FlxSound;

	var trainMoving:Bool = false;
	var trainFrameTiming:Float = 0;

	var trainCars:Int = 8;
	var trainFinishing:Bool = false;
	var trainCooldown:Int = 0;

	var startedMoving:Bool = false;

	var curLight:Int = 0;

	function trainStart():Void
	{
		if (FlxG.save.data.distractions)
		{
			trainMoving = true;
			if (!trainSound.playing)
				trainSound.play(true);
		}
	}

	function updateTrainPos():Void
	{
		if (FlxG.save.data.distractions)
		{
			if (trainSound.time >= 4700)
			{
				startedMoving = true;
				gf.playAnim('hairBlow');
			}

			if (startedMoving)
			{
				// trace("moving: " + phillyTrain.x);

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
	}

	function trainReset():Void
	{
		if (FlxG.save.data.distractions)
		{
			gf.playAnim('hairFall');

			phillyTrain.x = FlxG.width + 200;
			trainMoving = false;
			trainSound.stop();
			trainSound.time = 0;

			trainCars = 8;
			trainFinishing = false;
			startedMoving = false;

			new FlxTimer().start(0.5, function(tmr:FlxTimer)
			{
				gf.playAnim('danceRight');
			});
		}
	}

	override function loadMap()
	{
		var bg:FlxSprite = new FlxSprite(-100).loadGraphic(Paths.image('philly/sky', 'week3'));
		bg.scrollFactor.set(0.1, 0.1);
		playState.add(bg);

		var city:FlxSprite = new FlxSprite(-10).loadGraphic(Paths.image('philly/city', 'week3'));
		city.scrollFactor.set(0.3, 0.3);
		city.setGraphicSize(Std.int(city.width * 0.85));
		city.updateHitbox();
		playState.add(city);

		phillyCityLights = new FlxTypedGroup<FlxSprite>();
		if (FlxG.save.data.distractions)
		{
			playState.add(phillyCityLights);
		}

		for (i in 0...5)
		{
			var light:FlxSprite = new FlxSprite(city.x).loadGraphic(Paths.image('philly/win' + i, 'week3'));
			light.scrollFactor.set(0.3, 0.3);
			light.visible = false;
			light.setGraphicSize(Std.int(light.width * 0.85));
			light.updateHitbox();
			light.antialiasing = true;
			phillyCityLights.add(light);
		}

		var streetBehind:FlxSprite = new FlxSprite(-40, 50).loadGraphic(Paths.image('philly/behindTrain', 'week3'));
		playState.add(streetBehind);

		phillyTrain = new FlxSprite(2000, 360).loadGraphic(Paths.image('philly/train', 'week3'));

		if (FlxG.save.data.distractions)
		{
			playState.add(phillyTrain);
		}

		trainSound = new FlxSound().loadEmbedded(Paths.sound('train_passes'));
		FlxG.sound.list.add(trainSound);

		var street:FlxSprite = new FlxSprite(-200, streetBehind.y).loadGraphic(Paths.image('philly/street', 'week3'));
		street.scale.x = 2;
		playState.add(street);
	}

	override function getGFTex()
	{
		var tex = Paths.getSparrowAtlas('gf/GF_hair');
		gf.frames = tex;
	}

	override function getDadTex()
	{
		var tex = Paths.getSparrowAtlas('characters/Pico_FNF_assetss');
		dad.frames = tex;
	}

	override function createDadAnimations():Void
	{
		var animation = dad.animation;

		animation.addByPrefix('idle', "Pico Idle Dance", 24);
		animation.addByPrefix('singUP', 'pico Up note0', 24, false);
		animation.addByPrefix('singDOWN', 'Pico Down Note0', 24, false);
		animation.addByPrefix('singLEFT', 'Pico Note Right0', 24, false);
		animation.addByPrefix('singRIGHT', 'Pico NOTE LEFT0', 24, false);
		animation.addByPrefix('singRIGHTmiss', 'Pico NOTE LEFT miss', 24, false);
		animation.addByPrefix('singLEFTmiss', 'Pico Note Right Miss', 24, false);

		animation.addByPrefix('singUPmiss', 'pico Up note miss', 24);
		animation.addByPrefix('singDOWNmiss', 'Pico Down Note MISS', 24);
		dad.animation = animation;
	}

	override function createDadAnimationOffsets():Void
	{
		dad.addOffset('idle');
		dad.addOffset("singUP", -29, 27);
		dad.addOffset("singRIGHT", -68, -7);
		dad.addOffset("singLEFT", 65, 9);
		dad.addOffset("singDOWN", 200, -70);
		dad.addOffset("singUPmiss", -19, 67);
		dad.addOffset("singRIGHTmiss", -60, 41);
		dad.addOffset("singLEFTmiss", 62, 64);
		dad.addOffset("singDOWNmiss", 210, -28);

		dad.playAnim('idle');

	}

	override function createDad()
	{
		super.createDad();

		dad.flipX = true;
		dad.x -= 350;
	}

	override function createGF()
	{
		super.createGF();

		gf.scale.x = 1.5;
		gf.scale.y = 1.5;

		gf.x += 65;
		gf.y += 145;
	}

	override function createCharacters()
	{
		super.createCharacters();

		gf.y -= 125;
		bf.x += 50;
	}

	override function setCamPosition()
	{
		camPos.x += 600;
	}


	override function midSongEventUpdate(curBeat:Int):Void
	{
		if (playState.gfStep())
		{
			switch (PlayState.CURRENT_SONG)
			{
				case 'pico':
					picoMidSongEvent(curBeat);

				case 'philly':
					phillyMidSongEvent(curBeat);

				case 'blammed':
					blammedMidSongEvent(curBeat);
			}
		}

		updateTrain(curBeat);
	}

	function updateTrain(curBeat:Int)
	{
		if (!trainMoving)
			trainCooldown += 1;

		if (curBeat % 4 == 0)
		{
			phillyCityLights.forEach(function(light:FlxSprite)
			{
				light.visible = false;
			});

			curLight = FlxG.random.int(0, phillyCityLights.length - 1);

			phillyCityLights.members[curLight].visible = true;
		}

		if (curBeat % 8 == 4 && FlxG.random.bool(30) && !trainMoving && trainCooldown > 8)
		{
			if (FlxG.save.data.distractions)
			{
				trainCooldown = FlxG.random.int(-4, 0);
				trainStart();
			}
		}
	}

	override function update(elapsed:Float)
	{
		if (trainMoving)
		{
			// trace('update train: ' + elapsed);
			trainFrameTiming += elapsed;

			if (trainFrameTiming >= 1 / 24)
			{
				updateTrainPos();
				trainFrameTiming = 0;
			}
		}
	}

	function picoMidSongEvent(curBeat:Int)
	{
		if (curBeat < 250)
		{
			// Beats to skip or to stop GF from cheering
			if (curBeat != 184 && curBeat != 216)
			{
				if (curBeat % 16 == 8 && curBeat >= 32 && !trainMoving)
				{
					gf.playAnimForce('cheer', 0.5);
				}
			}
		}
	}

	function phillyMidSongEvent(curBeat:Int)
	{
		if (curBeat < 250)
		{
			// Beats to skip or to stop GF from cheering
			if (curBeat != 184 && curBeat != 216)
			{
				if (curBeat % 16 == 8 && !trainMoving)
				{
					gf.playAnimForce('cheer', 0.5);
				}
			}
		}
	}

	function blammedMidSongEvent(curBeat:Int)
	{
		if (curBeat > 30 && curBeat < 190)
		{
			if (curBeat < 90 || curBeat > 128)
			{
				if (curBeat % 4 == 2)
				{
					gf.playAnimForce('cheer', 0.5);
				}
			}
		}
	}

	public override function getDadIcon(icon:HealthIcon)
	{
		icon.loadGraphic(Paths.image('iconGrid'), true, 150, 150);
		icon.animation.add('dad', [4, 5], 0, false, false);
		icon.animation.play("dad");
	}

}