package fmf.songs;

import flixel.util.FlxColor;
import fmf.characters.*;
import flixel.FlxG;
import flixel.FlxSprite;
import Song.SwagSong;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.system.FlxSound;
import flixel.util.FlxTimer;

class WinterHorrorland extends SongPlayer
{
	var blackScreen:FlxSprite;
	var dialogueCallback:Void->Void;

	override function loadMap()
	{
		var bg:FlxSprite = new FlxSprite(-400, -500).loadGraphic(Paths.image('christmas/evilBG', 'week5'));
		bg.antialiasing = true;
		bg.scrollFactor.set(0.2, 0.2);
		bg.active = false;
		bg.setGraphicSize(Std.int(bg.width * 0.8));
		bg.updateHitbox();
		playState.add(bg);

		var evilTree:FlxSprite = new FlxSprite(300, -300).loadGraphic(Paths.image('christmas/evilTree', 'week5'));
		evilTree.antialiasing = true;
		evilTree.scrollFactor.set(0.2, 0.2);
		playState.add(evilTree);

		var evilSnow:FlxSprite = new FlxSprite(-200, 700).loadGraphic(Paths.image("christmas/evilSnow", 'week5'));
		evilSnow.antialiasing = true;
		evilSnow.scale.x = 1.25;
		playState.add(evilSnow);
	}

	override function showDialogue()
	{
		lightItUp();

		new FlxTimer().start(0.15, function(tmr:FlxTimer)
		{
			playState.add(dialogueBox);
			trace('whee mai dialgue siht!');
			
			dialogueCallback = dialogueBox.finishThing; //tmp callback
			dialogueBox.finishThing = zoomOut; //recreate callback shit
		});
	}

	function lightItUp()
	{
		blackScreen = new FlxSprite(0, 0).makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.BLACK);
		playState.add(blackScreen);
		blackScreen.scrollFactor.set();
		playState.camHUD.visible = false;

		new FlxTimer().start(0.1, function(tmr:FlxTimer)
		{
			playState.remove(blackScreen);
			playState.camHUD.visible = true;
			FlxG.sound.play(Paths.sound('Lights_Turn_On'));
			playState.camFollow.y = -2050;
			playState.camFollow.x += 200;
			FlxG.camera.focusOn(playState.camFollow.getPosition());
			FlxG.camera.zoom = 1.5;
		});
	}

	function zoomOut()
	{
		new FlxTimer().start(0.8, function(tmr:FlxTimer)
		{
			FlxTween.tween(FlxG.camera, {zoom: playState.defaultCamZoom}, 2.5, {
				ease: FlxEase.quadInOut,
				onComplete: function(twn:FlxTween)
				{
					dialogueCallback();
				}
			});
		});
	}

	override function getGFTex()
	{
		var tex = Paths.getSparrowAtlas('gf/gfChristmas');
		gf.frames = tex;
	}

	override function getDadTex()
	{
		var tex = Paths.getSparrowAtlas('characters/Monster_Assets');
		dad.frames = tex;
	}

	override function getBFTex()
	{
		var tex = Paths.getSparrowAtlas('characters/bfChristmas');
		bf.frames = tex;
	}

	override function createDadAnimations()
	{
		var animation = dad.animation;

		animation.addByPrefix('idle', 'monster idle', 24, false);
		animation.addByPrefix('singUP', 'monster up note', 24, false);
		animation.addByPrefix('singDOWN', 'monster down', 24, false);
		animation.addByPrefix('singLEFT', 'Monster left note', 24, false);
		animation.addByPrefix('singRIGHT', 'Monster Right note', 24, false);

		dad.animation = animation;
	}

	override function createDadAnimationOffsets()
	{
		dad.addOffset('idle');
		dad.addOffset("singUP", -20, 50);
		dad.addOffset("singRIGHT", -51);
		dad.addOffset("singLEFT", -30);
		dad.addOffset("singDOWN", -40, -94);

		dad.playAnim('idle');
	}

	override function createCharacters()
	{
		super.createCharacters();

		dad.x -= 550;
		// dad.y += 0;

		gf.scale.x = 2;
		gf.scale.y = 2;

		gf.y += 100;
		gf.x += 50;

		bf.x += 150;
		bf.y += 50;
	}
}