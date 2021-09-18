#if sys
package;

import lime.app.Application;
#if desktop
import Discord.DiscordClient;
#end
import openfl.display.BitmapData;
import openfl.utils.Assets;
import flixel.ui.FlxBar;
import haxe.Exception;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
#if cpp
import sys.FileSystem;
import sys.io.File;
#end
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.transition.FlxTransitionSprite.GraphicTransTileDiamond;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.transition.TransitionData;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.text.FlxText;

using StringTools;

class Loading extends MusicBeatState
{
	var toBeDone = 0;
	var done = 0;

	var loaded = false;

	var text:FlxText;
	var wblogo:FlxSprite;

	public static var bitmapData:Map<String,FlxGraphic>;

	var images = [];
	var music = [];
	var charts = [];


	override function create()
	{

		DiscordClient.changePresence('In the Menus', null);

		FlxG.save.bind('funkin', 'ninjamuffin99');

		PlayerSettings.init();

		Data.init();

		FlxG.mouse.visible = false;

		FlxG.worldBounds.set(0,0);

		bitmapData = new Map<String,FlxGraphic>();

		text = new FlxText(FlxG.width / 2, FlxG.height / 2 + 300,0,"Loading...");
		text.size = 34;
		text.alignment = FlxTextAlign.CENTER;
		text.alpha = 0;

		wblogo = new FlxSprite(FlxG.width / 2, FlxG.height / 2).loadGraphic(Paths.image('WBLogo'));
		wblogo.x -= wblogo.width / 2;
		wblogo.y -= wblogo.height / 2 + 100;
		text.y -= wblogo.height / 2 - 125;
		text.x -= 170;
		wblogo.setGraphicSize(Std.int(wblogo.width * 0.6));
		if(FlxG.save.data.antialiasing != null)
			wblogo.antialiasing = FlxG.save.data.antialiasing;
		else
			wblogo.antialiasing = true;
		
		wblogo.alpha = 0;

		FlxGraphic.defaultPersist = FlxG.save.data.cacheImages;

		#if cpp
    	trace("caching music...");

		for (i in FileSystem.readDirectory(FileSystem.absolutePath("assets/songs")))
		{
			music.push(i);
		}
		#end

		toBeDone = Lambda.count(images) + Lambda.count(music);

		var bar = new FlxBar(10,FlxG.height - 50,FlxBarFillDirection.LEFT_TO_RIGHT,FlxG.width,40,null,"done",0,toBeDone);
		bar.color = FlxColor.PURPLE;

		add(bar);

		add(wblogo);
		add(text);

		trace('starting caching..');
		
		#if cpp
		// update thread

		sys.thread.Thread.create(() -> {
			while(!loaded)
			{
				if (toBeDone != 0 && done != toBeDone)
					{
						var alpha = HelperFunctions.truncateFloat(done / toBeDone * 100,2) / 100;
						wblogo.alpha = alpha;
						text.alpha = alpha;
						text.text = "Loading... (" + done + "/" + toBeDone + ")";
					}
			}
		
		});

		// cache thread

		sys.thread.Thread.create(() -> {
			cache();
		});
		#end

		super.create();
	}

	var calledDone = false;

	override function update(elapsed) 
	{
		super.update(elapsed);
	}


	function cache()
	{
		#if !linux
		trace("LOADING: " + toBeDone + " OBJECTS.");

		for (i in music)
		{
			FlxG.sound.cache(Paths.inst(i));
			FlxG.sound.cache(Paths.voices(i));
			trace("cached " + i);
			done++;
		}


		trace("Finished caching...");

		loaded = true;

		trace(Assets.cache.hasBitmapData('GF_assets'));

		#end
		FlxG.switchState(new TitleState());
	}

}
#end