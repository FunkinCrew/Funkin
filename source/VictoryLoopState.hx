package;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSubState;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import lime.system.System;
import lime.utils.Assets;
#if sys
import sys.io.File;
import sys.FileSystem;
import haxe.io.Path;
import openfl.utils.ByteArray;
import lime.media.AudioBuffer;
import flash.media.Sound;
#end
import haxe.Json;
using StringTools;
class VictoryLoopState extends MusicBeatSubstate
{
	var bf:Boyfriend;
	var camFollow:FlxObject;

	var stageSuffix:String = "";

	public function new(x:Float, y:Float)
	{
		var daStage = PlayState.curStage;
		var p1 = PlayState.SONG.player1;
		var daBf:String = 'bf';
		trace(p1);
		if (p1 == "bf-pixel") {
			stageSuffix = '-pixel';
		}
		var characterList = Assets.getText('assets/data/characterList.txt');
		if (!StringTools.contains(characterList, p1)) {
			var parsedCharJson:Dynamic = Json.parse(Assets.getText('assets/images/custom_chars/custom_chars.json'));
			var parsedAnimJson = Json.parse(File.getContent("assets/images/custom_chars/"+Reflect.field(parsedCharJson,p1).like+".json"));
			switch (parsedAnimJson.like) {
				case "bf":
					// bf has a death animation
					daBf = p1;
				case "bf-pixel":
					// gotta deal with this dude
					daBf = p1 + '-dead';
					stageSuffix = '-pixel';
				default:
					// just use bf, avoid pain
					daBf = 'bf';
			}
		}
		super();

		Conductor.songPosition = 0;

		bf = new Boyfriend(x, y, PlayState.SONG.player1);
		add(bf);

		camFollow = new FlxObject(bf.getGraphicMidpoint().x, bf.getGraphicMidpoint().y, 1, 1);
		add(camFollow);

		Conductor.changeBPM(100);
		FlxG.sound.playMusic('assets/music/Test_Inst' + TitleState.soundExt);
		// FlxG.camera.followLerp = 1;
		// FlxG.camera.focusOn(FlxPoint.get(FlxG.width / 2, FlxG.height / 2));
		FlxG.camera.scroll.set();
		FlxG.camera.target = null;
		bf.playAnim('singUP');
		// do this because this makes it so if there is no hey anim he sings up
		bf.playAnim('hey');
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (controls.ACCEPT)
		{
			endBullshit();
		}

		if (controls.BACK)
		{
			FlxG.sound.music.stop();

			if (PlayState.isStoryMode)
				FlxG.switchState(new StoryMenuState());
			else
				FlxG.switchState(new FreeplayState());
		}


		if (FlxG.sound.music.playing)
		{
			Conductor.songPosition = FlxG.sound.music.time;
		}
	}

	override function beatHit()
	{
		super.beatHit();

		FlxG.log.add('beat');
	}

	var isEnding:Bool = false;

	function endBullshit():Void
	{
		if (!isEnding)
		{
			isEnding = true;
			FlxG.sound.music.stop();
			FlxG.sound.play('assets/music/gameOverEnd' + stageSuffix + TitleState.soundExt);
			new FlxTimer().start(0.7, function(tmr:FlxTimer)
			{
				FlxG.camera.fade(FlxColor.BLACK, 2, false, function()
				{
					FlxG.switchState(new PlayState());
				});
			});
		}
	}
}
