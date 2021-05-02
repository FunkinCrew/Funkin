package;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSubState;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.text.FlxText;
import lime.system.System;
import flixel.FlxSprite;
import flixel.FlxCamera;
import lime.utils.Assets;
#if sys
import sys.io.File;
import sys.FileSystem;
import haxe.io.Path;
import Song.SwagSong;
import openfl.utils.ByteArray;
import lime.media.AudioBuffer;
import flash.media.Sound;
#end
import haxe.Json;
import tjson.TJSON;
using StringTools;
class VictoryLoopState extends MusicBeatSubstate
{
	var bf:Character;
	var camFollow:FlxObject;
	var gf:Character;
	var dad:Character;
	var stageSuffix:String = "";
	var victoryTxt:Alphabet;
	var retryTxt:Alphabet;
	var continueTxt:Alphabet;
	var scoreTxt:Alphabet;
	var rating:Alphabet;
	var selectingRetry:Bool = false;
	var canPlayHey:Bool = true;
	var accuracy:Float;
	var accuracyTxt:FlxText;
	var camHUD:FlxCamera;
	public function new(x:Float, y:Float, gfX:Float, gfY:Float, accuracy:Float, score:Int, dadX:Float, dadY:Float)
	{
		//var background:FlxSprite = new FlxSprite(0,0).makeGraphic(FlxG.width, FlxG.height, FlxColor.PINK);
		//add(background);
		var daStage = PlayState.curStage;
		this.accuracy = accuracy;
		var p1 = PlayState.SONG.player1;
		gf = new Character(gfX,gfY,PlayState.SONG.gf);
		var daBf:String = 'bf';
		trace(p1);
		if (p1 == "bf-pixel") {
			stageSuffix = '-pixel';
		}
		// if opponent play
		
		victoryTxt = new Alphabet(10, 10, "Victory",true);
		retryTxt = new Alphabet(10, FlxG.height, "Replay", true);
		retryTxt.y -= retryTxt.height;
		continueTxt = new Alphabet(10, FlxG.height - retryTxt.height, "Continue", true);
		scoreTxt = new Alphabet(10, victoryTxt.y + victoryTxt.height, Std.string(score),true);
		continueTxt.y -= scoreTxt.height;
		rating = new Alphabet(10, FlxG.height/2, "", true, 90, 0.48, true);
		rating.setGraphicSize(3);
		rating.updateHitbox();
		retryTxt.alpha = 0.6;
		// if you do this you are epic gamer
		if (accuracy == 1) {
			rating.text = "S+";
		} else if (accuracy >= 0.95) {
			rating.text = "S";
		} else if ( accuracy >= 0.93) {
			rating.text = "S-";
		} else if (accuracy >= 0.90) {
			rating.text = "A+";
		} else if (accuracy >= 0.85) {
			rating.text = "A";
		} else if (accuracy >= 0.82) {
			rating.text = "A-";
		} else if (accuracy >= 0.8) {
			rating.text = "B+";
		} else if (accuracy >= 0.78) {
			rating.text = "B";
		} else if (accuracy >= 0.75) {
			rating.text = "B-";
		} else if (accuracy >= 0.72) {
			rating.text = "C+";
		} else if (accuracy >= 0.69) {
			rating.text = "C";
		} else if (accuracy >= 0.65){
			rating.text = "C-";
		} else if (accuracy >= 0.60) {
			rating.text = "D+";
		} else if (accuracy >= 0.55) {
			rating.text = "D";
		} else if (accuracy >= 0.50) {
			rating.text = "D-";
		} else {
			rating.text = "F";
		}
		rating.addText();
		accuracyTxt = new FlxText(10, rating.y + rating.height,0 , "ACCURACY: "+Math.round(accuracy * 100) + "%");
		accuracyTxt.setFormat("assets/fonts/vcr.ttf", 26, FlxColor.WHITE, RIGHT);
		var characterList = Assets.getText('assets/data/characterList.txt');
		if (!StringTools.contains(characterList, p1)) {
			var parsedCharJson:Dynamic = CoolUtil.parseJson(Assets.getText('assets/images/custom_chars/custom_chars.jsonc'));
			var parsedAnimJson = CoolUtil.parseJson(FNFAssets.getText("assets/images/custom_chars/"+Reflect.field(parsedCharJson,p1).like+".json"));
			switch (parsedAnimJson.like) {
				case "bf-pixel":
					// gotta deal with this dude
					stageSuffix = '-pixel';
			}
		}
		super();

		Conductor.songPosition = 0;

		
		if (PlayState.opponentPlayer)
		{
			bf = new Character(dadX, dadY, PlayState.SONG.player2);
		} else {
			bf = new Character(x, y, PlayState.SONG.player1, true);
		}
		dad = new Character(dadX, dadY, PlayState.SONG.player2);
		if (!PlayState.duoMode) {
			dad.visible = false;
		}
		// i mean, not really, but being controlled doesn't mean actually recieving input
		// it just means it acts like a player
		bf.beingControlled = true;
		// now listen here bf I take care of the animation
		bf.beNormal = false;
		add(gf);
		add(bf);
		if (PlayState.opponentPlayer) {
			camFollow = new FlxObject(dad.getGraphicMidpoint().x, dad.getGraphicMidpoint().y, 1, 1);
		} else {
			camFollow = new FlxObject(bf.getGraphicMidpoint().x, bf.getGraphicMidpoint().y, 1, 1);
		}
		if (PlayState.duoMode) {
			camFollow.x = gf.getGraphicMidpoint().x;
			camFollow.y = gf.getGraphicMidpoint().y;
		}
		add(camFollow);
		add(victoryTxt);
		add(retryTxt);
		add(scoreTxt);
		add(continueTxt);
		add(rating);
		add(accuracyTxt);
		retryTxt.visible = false;
		continueTxt.visible = false;
		rating.visible = false;
		scoreTxt.visible = false;
		accuracyTxt.visible = false;
		// make files seperate to allow modding
		if (accuracy >= 0.65) {
			Conductor.changeBPM(150);
			FlxG.sound.playMusic('assets/music/goodScore' + TitleState.soundExt);
		} else if (accuracy >= 0.5) {
			Conductor.changeBPM(100);
			FlxG.sound.playMusic('assets/music/mehScore' + TitleState.soundExt);
		} else {
			Conductor.changeBPM(100);
			FlxG.sound.playMusic('assets/music/badScore' + TitleState.soundExt);
		}

		// FlxG.camera.followLerp = 1;
		// FlxG.camera.focusOn(FlxPoint.get(FlxG.width / 2, FlxG.height / 2));
		FlxG.camera.scroll.set();
		FlxG.camera.target = null;
		FlxG.camera.follow(camFollow, LOCKON, 0.01);
		bf.playAnim('idle');
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (controls.ACCEPT)
		{
			if (selectingRetry && !PlayState.isStoryMode) {
				endBullshit();
			} else {
				FlxG.sound.music.stop();

				if (PlayState.isStoryMode)
					FlxG.switchState(new StoryMenuState());
				else
					FlxG.switchState(new FreeplayState());
			}
		}

		if ((controls.UP_P || controls.DOWN_P)) {
			selectingRetry = !selectingRetry;
			if (selectingRetry) {
				retryTxt.alpha = 1;
				continueTxt.alpha = 0.6;
			} else {
				retryTxt.alpha = 0.6;
				continueTxt.alpha = 1;
			}
		}
		if (FlxG.sound.music.playing)
		{
			Conductor.songPosition = FlxG.sound.music.time;
		}
	}

	override function beatHit()
	{
		super.beatHit();
		if (curBeat == 3) {
			scoreTxt.visible = true;
		}
		if (curBeat == 5) {
			rating.visible = true;
			accuracyTxt.visible = true;
		}
		if (curBeat == 8) {
			retryTxt.visible = true;
			continueTxt.visible = true;
		}
		if (accuracy >= 0.65) {
			gf.dance();
		} else {
			gf.playAnim('sad');
			if (gf.animation.curAnim.name != 'sad') {
				// boogie if no sad anim, looks kinda silly
				gf.dance();
			}
		}

		FlxG.log.add('beat');
		if (curBeat % 2 == 0 && accuracy >= 0.65) {
			switch(bf.animation.curAnim.name) {
				case "idle":
					bf.playAnim('singUP');
				case "singLEFT":
					bf.playAnim('singUP');
				case "singUP":
					bf.playAnim('singRIGHT');
				case "singRIGHT":
					bf.playAnim('singDOWN');
				case "singDOWN":
					bf.playAnim('singLEFT');
			}
		} else if (curBeat % 2 == 0){
			// funny look he misses now
			switch(bf.animation.curAnim.name) {
				case "idle":
					bf.playAnim('singUPmiss');
				case "singLEFTmiss":
					bf.playAnim('singUPmiss');
				case "singUPmiss":
					bf.playAnim('singRIGHTmiss');
				case "singRIGHTmiss":
					bf.playAnim('singDOWNmiss');
				case "singDOWNmiss":
					bf.playAnim('singLEFTmiss');
			}
		}
	}

	var isEnding:Bool = false;

	function endBullshit():Void
	{
		if (!isEnding)
		{
			isEnding = true;
			FlxG.sound.music.stop();
			FlxG.sound.play('assets/music/gameOverEnd' + stageSuffix + TitleState.soundExt);
			if (PlayState.isStoryMode) {
				// most variables should already be set?
				PlayState.storyPlaylist = StoryMenuState.storySongPlaylist;
				trace(PlayState.storyPlaylist);
				var diffic = DifficultyIcons.getEndingFP(PlayState.storyDifficulty);
				for (peckUpAblePath in PlayState.storyPlaylist) {
					if (!FNFAssets.exists('assets/data/'+peckUpAblePath.toLowerCase()+'/'+peckUpAblePath.toLowerCase() + diffic+'.json')) {
						// probably messed up difficulty
						trace("UH OH DIFFICULTY DOESN'T EXIST FOR A SONG");
						trace("CHANGING TO DEFAULT DIFFICULTY");
						diffic = "";
						PlayState.storyDifficulty = DifficultyIcons.getDefaultDiffFP();
					}
				}
				PlayState.SONG = Song.loadFromJson(StoryMenuState.storySongPlaylist[0].toLowerCase() + diffic, StoryMenuState.storySongPlaylist[0].toLowerCase());
				PlayState.campaignScore = 0;
				PlayState.campaignAccuracy = 0;
			}
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
