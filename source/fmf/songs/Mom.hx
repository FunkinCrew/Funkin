package fmf.songs;

import flixel.util.FlxTimer;
import flixel.util.FlxColor;
import openfl.filters.ShaderFilter;
import flixel.group.FlxGroup.FlxTypedGroup;
import fmf.characters.*;
import flixel.FlxG;
import flixel.FlxSprite;
import Song.SwagSong;

class Mom extends SongPlayer
{
	var limo:FlxSprite;
	var grpLimoDancers:FlxTypedGroup<BackgroundDancer>;
	var fastCar:FlxSprite;
	var fastCarCanDrive:Bool = true;

	override function loadMap()
	{
		var skyBG:FlxSprite = new FlxSprite(-120, -50).loadGraphic(Paths.image('limo/limoSunset', 'week4'));
		skyBG.scrollFactor.set(0.1, 0.1);
		playState.add(skyBG);

		var bgLimo:FlxSprite = new FlxSprite(-200, 480);
		bgLimo.frames = Paths.getSparrowAtlas('limo/bgLimo', 'week4');
		bgLimo.animation.addByPrefix('drive', "background limo pink", 24);
		bgLimo.animation.play('drive');
		bgLimo.scrollFactor.set(0.4, 0.4);
		playState.add(bgLimo);
		if (FlxG.save.data.distractions)
		{
			grpLimoDancers = new FlxTypedGroup<BackgroundDancer>();
			playState.add(grpLimoDancers);

			for (i in 0...5)
			{
				var dancer:BackgroundDancer = new BackgroundDancer((370 * i) + 130, bgLimo.y - 400);
				dancer.scrollFactor.set(0.4, 0.4);
				grpLimoDancers.add(dancer);
			}
		}

		var overlayShit:FlxSprite = new FlxSprite(-500, -600).loadGraphic(Paths.image('limo/limoOverlay', 'week4'));
		overlayShit.alpha = 0.5;
		playState.add(overlayShit);

		// var shaderBullshit = new BlendModeEffect(new OverlayShader(), FlxColor.RED);

		// FlxG.camera.setFilters([new ShaderFilter(cast shaderBullshit.shader)]);

		// overlayShit.blend = shaderBullshit;

		var limoTex = Paths.getSparrowAtlas('limo/limoDrive', 'week4');

		limo = new FlxSprite(-120, 550);
		limo.frames = limoTex;
		limo.animation.addByPrefix('drive', "Limo stage", 24);
		limo.animation.play('drive');
		limo.antialiasing = true;

		fastCar = new FlxSprite(-300, 160).loadGraphic(Paths.image('limo/fastCarLol', 'week4'));

		if (FlxG.save.data.distractions)
		{
			resetFastCar();
			playState.add(fastCar);
		}
	}

	override function getGFTex()
	{
		var tex = Paths.getSparrowAtlas('gf/gfCar');
		gf.frames = tex;
	}

	override function createGFAnimations()
	{
		var animation = gf.animation;
		animation.addByIndices('singUP', 'GF Dancing Beat Hair blowing CAR', [0], "", 24, false);
		animation.addByPrefix('danceLeft', 'GF Dancing Beat Hair blowing CAR', 24,
			true); // , [15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29], "", 24,
		animation.addByPrefix('danceRight', 'GF Dancing Beat Hair blowing CAR', 24,
			true); // , [15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29], "", 24,
		gf.animation = animation;
	}

	override function createGFAnimationOffsets()
	{
		gf.addOffset('danceLeft', 0);
		gf.addOffset('danceRight', 0);

		gf.playAnim('danceRight');
	}

	override function getDadTex()
	{
		var tex = Paths.getSparrowAtlas('characters/Mom_Assets');
		dad.frames = tex;
	}

	override function createDadAnimations():Void
	{
		var animation = dad.animation;
		animation.addByPrefix('idle', "Mom Idle", 24, false);
		animation.addByPrefix('singUP', "Mom Up Pose", 24, false);
		animation.addByPrefix('singDOWN', "MOM DOWN POSE", 24, false);
		animation.addByPrefix('singLEFT', 'Mom Left Pose', 24, false);
		animation.addByPrefix('singRIGHT', 'Mom Pose Left', 24, false);

		dad.animation = animation;
	}

	override function createDadAnimationOffsets():Void
	{
		dad.addOffset('idle');
		dad.addOffset("singUP", 14, 71);
		dad.addOffset("singRIGHT", 10, -60);
		dad.addOffset("singLEFT", 250, -23);
		dad.addOffset("singDOWN", 20, -160);
		dad.dance();
	}

	override function createCharacters()
	{
		createGF();
		createBF();
		createDad();

		gf.scrollFactor.set(0.95, 0.95);
		gf.y -= 50;

		dad.x -= 250;
		dad.y -= 200;

		bf.y -= 220;
		bf.x += 260;

		playState.add(gf);
		playState.add(limo);
		playState.add(dad);
		playState.add(bf);
	}

	function resetFastCar():Void
	{
		if (FlxG.save.data.distractions)
		{
			fastCar.x = -12600;
			fastCar.y = FlxG.random.int(140, 250);
			fastCar.velocity.x = 0;
			fastCarCanDrive = true;
		}
	}

	function fastCarDrive()
	{
		if (FlxG.save.data.distractions)
		{
			FlxG.sound.play(Paths.soundRandom('carPass', 0, 1), 0.7);

			fastCar.velocity.x = (FlxG.random.int(170, 220) / FlxG.elapsed) * 3;
			fastCarCanDrive = false;
			new FlxTimer().start(2, function(tmr:FlxTimer)
			{
				resetFastCar();
			});
		}
	}

	override function midSongEventUpdate(curBeat:Int):Void
	{
		if (FlxG.save.data.distractions)
		{
			grpLimoDancers.forEach(function(dancer:BackgroundDancer)
			{
				dancer.dance();
			});

			if (FlxG.random.bool(10) && fastCarCanDrive)
				fastCarDrive();
		}
	}

	public override function updateCamFollowDad():Void
	{
		playState.camFollow.y = dad.getMidpoint().y;
	}

	override function updateCamFollowBF():Void
	{
		playState.camFollow.x = bf.getMidpoint().x - 300;
	}
}