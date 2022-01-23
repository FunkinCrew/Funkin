package;

import charting.ChartingState;
import flixel.addons.transition.FlxTransitionSprite.GraphicTransTileDiamond;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.transition.TransitionData;
import flixel.graphics.FlxGraphic;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.util.FlxColor;
import openfl.display.BitmapData;
import ui.PreferencesMenu;
import ui.stageBuildShit.StageBuilderState;

using StringTools;

#if colyseus
import io.colyseus.Client;
import io.colyseus.Room;
#end
#if discord_rpc
import Discord.DiscordClient;
#end
#if desktop
import sys.FileSystem;
import sys.io.File;
import sys.thread.Thread;
#end

class InitState extends FlxTransitionableState
{
	override public function create():Void
	{
		#if android
		FlxG.android.preventDefaultKeys = [FlxAndroidKey.BACK];
		#end
		#if newgrounds
		NGio.init();
		#end
		#if discord_rpc
		DiscordClient.initialize();

		Application.current.onExit.add(function(exitCode)
		{
			DiscordClient.shutdown();
		});
		#end

		// ==== flixel shit ==== //

		// This big obnoxious white button is for MOBILE, so that you can press it
		// easily with your finger when debug bullshit pops up during testing lol!
		FlxG.debugger.addButton(LEFT, new BitmapData(200, 200), function()
		{
			FlxG.debugger.visible = false;
		});

		FlxG.sound.muteKeys = [ZERO];
		FlxG.game.focusLostFramerate = 60;

		// FlxG.stage.window.borderless = true;
		// FlxG.stage.window.mouseLock = true;

		var diamond:FlxGraphic = FlxGraphic.fromClass(GraphicTransTileDiamond);
		diamond.persist = true;
		diamond.destroyOnNoUse = false;

		FlxTransitionableState.defaultTransIn = new TransitionData(FADE, FlxColor.BLACK, 1, new FlxPoint(0, -1), {asset: diamond, width: 32, height: 32},
			new FlxRect(-200, -200, FlxG.width * 1.4, FlxG.height * 1.4));
		FlxTransitionableState.defaultTransOut = new TransitionData(FADE, FlxColor.BLACK, 0.7, new FlxPoint(0, 1), {asset: diamond, width: 32, height: 32},
			new FlxRect(-200, -200, FlxG.width * 1.4, FlxG.height * 1.4));

		// ===== save shit ===== //

		FlxG.save.bind('funkin', 'ninjamuffin99');

		// https://github.com/HaxeFlixel/flixel/pull/2396
		// IF/WHEN MY PR GOES THRU AND IT GETS INTO MAIN FLIXEL, DELETE THIS CHUNKOF CODE, AND THEN UNCOMMENT THE LINE BELOW
		// FlxG.sound.loadSavedPrefs();

		if (FlxG.save.data.volume != null)
			FlxG.sound.volume = FlxG.save.data.volume;
		if (FlxG.save.data.mute != null)
			FlxG.sound.muted = FlxG.save.data.mute;

		// FlxG.save.close();
		// FlxG.sound.loadSavedPrefs();
		PreferencesMenu.initPrefs();
		PlayerSettings.init();
		Highscore.load();

		if (FlxG.save.data.weekUnlocked != null)
		{
			// FIX LATER!!!
			// WEEK UNLOCK PROGRESSION!!
			// StoryMenuState.weekUnlocked = FlxG.save.data.weekUnlocked;

			if (StoryMenuState.weekUnlocked.length < 4)
				StoryMenuState.weekUnlocked.insert(0, true);

			// QUICK PATCH OOPS!
			if (!StoryMenuState.weekUnlocked[0])
				StoryMenuState.weekUnlocked[0] = true;
		}

		if (FlxG.save.data.seenVideo != null)
			VideoState.seenVideo = FlxG.save.data.seenVideo;

		// ===== fuck outta here ===== //

		// FlxTransitionableState.skipNextTransOut = true;
		FlxTransitionableState.skipNextTransIn = true;

		#if FREEPLAY
		FlxG.switchState(new FreeplayState());
		#elseif ANIMATE
		FlxG.switchState(new animate.AnimTestStage());
		#elseif CHARTING
		FlxG.switchState(new ChartingState());
		#elseif STAGEBUILD
		FlxG.switchState(new StageBuilderState());
		#elseif ANIMDEBUG
		FlxG.switchState(new ui.animDebugShit.DebugBoundingState());
		#elseif NETTEST
		FlxG.switchState(new netTest.NetTest());
		#else
		FlxG.sound.cache(Paths.music('freakyMenu'));
		FlxG.switchState(new TitleState());
		#end
	}
}
