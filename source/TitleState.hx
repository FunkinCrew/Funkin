package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.transition.FlxTransitionSprite.GraphicTransTileDiamond;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.transition.TransitionData;
import flixel.graphics.FlxGraphic;
import flixel.group.FlxGroup;
import flixel.input.gamepad.FlxGamepad;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;

class TitleState extends MusicBeatState
{
	static var initialized:Bool = false;
	static public var soundExt:String = ".mp3";

	var blackScreen:FlxSprite;
	var credGroup:FlxGroup;
	var credTextShit:FlxText;

	override public function create():Void
	{
		#if (!web)
		TitleState.soundExt = '.ogg';
		#end

		super.create();

		if (!initialized)
		{
			var diamond:FlxGraphic = FlxGraphic.fromClass(GraphicTransTileDiamond);
			diamond.persist = true;
			diamond.destroyOnNoUse = false;

			FlxTransitionableState.defaultTransIn = new TransitionData(FADE, FlxColor.BLACK, 2, new FlxPoint(0, -1), {asset: diamond, width: 32, height: 32},
				new FlxRect(0, 0, FlxG.width, FlxG.height));
			FlxTransitionableState.defaultTransOut = new TransitionData(FADE, FlxColor.BLACK, 1.3, new FlxPoint(0, 1),
				{asset: diamond, width: 32, height: 32}, new FlxRect(0, 0, FlxG.width, FlxG.height));

			initialized = true;

			FlxTransitionableState.defaultTransIn.tileData = {asset: diamond, width: 32, height: 32};
			FlxTransitionableState.defaultTransOut.tileData = {asset: diamond, width: 32, height: 32};

			transIn = FlxTransitionableState.defaultTransIn;
			transOut = FlxTransitionableState.defaultTransOut;
		}

		persistentUpdate = true;

		var bg:FlxSprite = new FlxSprite().loadGraphic(AssetPaths.stageback__png);
		bg.antialiasing = true;
		bg.setGraphicSize(Std.int(bg.width * 0.6));
		bg.updateHitbox();
		add(bg);

		var logoBl:FlxSprite = new FlxSprite().loadGraphic(AssetPaths.logo__png);
		logoBl.screenCenter();
		logoBl.color = FlxColor.BLACK;
		add(logoBl);

		var logo:FlxSprite = new FlxSprite().loadGraphic(AssetPaths.logo__png);
		logo.screenCenter();
		logo.antialiasing = true;
		add(logo);

		FlxTween.tween(logoBl, {y: logoBl.y + 50}, 0.6, {ease: FlxEase.quadInOut, type: PINGPONG});
		FlxTween.tween(logo, {y: logoBl.y + 50}, 0.6, {ease: FlxEase.quadInOut, type: PINGPONG, startDelay: 0.1});

		credGroup = new FlxGroup();
		add(credGroup);

		blackScreen = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		credGroup.add(blackScreen);

		credTextShit = new FlxText(0, 0, 0, "ninjamuffin99\nPhantomArcade\nEvilsk8er\nAnd Kawaisprite", 24);
		credTextShit.screenCenter();
		credTextShit.alignment = CENTER;

		credTextShit.visible = false;

		FlxTween.tween(credTextShit, {y: credTextShit.y + 20}, 2.9, {ease: FlxEase.quadInOut, type: PINGPONG});

		credGroup.add(credTextShit);

		FlxG.sound.playMusic('assets/music/freakyMenu' + TitleState.soundExt, 0, false);

		FlxG.sound.music.fadeIn(4, 0, 0.7);
	}

	var transitioning:Bool = false;

	override function update(elapsed:Float)
	{
		Conductor.songPosition = FlxG.sound.music.time;

		var pressedEnter:Bool = FlxG.keys.justPressed.ENTER;

		var gamepad:FlxGamepad = FlxG.gamepads.lastActive;

		if (gamepad != null)
		{
			if (gamepad.justPressed.START)
				pressedEnter = true;
		}

		if (pressedEnter && !skippedIntro)
		{
			skipIntro();
		}

		if (pressedEnter && !transitioning && skippedIntro)
		{
			FlxG.camera.flash(FlxColor.WHITE, 1);

			transitioning = true;
			FlxG.sound.music.stop();

			new FlxTimer().start(2, function(tmr:FlxTimer)
			{
				FlxG.switchState(new PlayState());
			});
			FlxG.sound.play('assets/music/titleShoot' + TitleState.soundExt, 0.7);
		}

		super.update(elapsed);
	}

	override function beatHit()
	{
		super.beatHit();

		FlxG.log.add(curBeat);

		switch (curBeat)
		{
			case 1:
				credTextShit.visible = true;
			case 3:
				credTextShit.text += '\npresent...';
			case 4:
				credTextShit.visible = false;
				credTextShit.text = 'In association \nwith';
				credTextShit.screenCenter();
			case 5:
				credTextShit.visible = true;
			case 7:
				credTextShit.text += '\nNewgrounds';
			case 8:
				credTextShit.visible = false;
				credTextShit.text = 'Shoutouts Tom Fulp';
				credTextShit.screenCenter();
			case 9:
				credTextShit.visible = true;
			case 11:
				credTextShit.text += '\nlmao';
			case 12:
				credTextShit.visible = false;
				credTextShit.text = "Friday";
				credTextShit.screenCenter();
			case 13:
				credTextShit.visible = true;
			case 14:
				credTextShit.text += '\nNight';
			case 15:
				credTextShit.text += '\nFunkin';

			case 16:
				skipIntro();
		}
	}

	var skippedIntro:Bool = false;

	function skipIntro():Void
	{
		if (!skippedIntro)
		{
			FlxG.camera.flash(FlxColor.WHITE, 4);
			remove(credGroup);
		}
	}
}
