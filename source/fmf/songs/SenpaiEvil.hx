package fmf.songs;

import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.addons.effects.FlxTrail;
import flixel.addons.effects.chainable.FlxEffectSprite;
import flixel.addons.effects.chainable.FlxWaveEffect;
import flixel.math.FlxPoint;
import fmf.characters.*;
import flixel.FlxG;
import flixel.FlxSprite;

class SenpaiEvil extends Senpai
{
	override function loadMap()
	{
		var posX = 400;
		var posY = 200;

		var bg:FlxSprite = new FlxSprite(posX, posY);
		bg.frames = Paths.getSparrowAtlas('weeb/animatedEvilSchool', 'week6');
		bg.animation.addByPrefix('idle', 'background 2', 24);
		bg.animation.play('idle');
		bg.scrollFactor.set(0.8, 0.9);
		bg.scale.set(6, 6);
		playState.add(bg);
	}

	override function showDialogue()
	{
		var red:FlxSprite = new FlxSprite(-100, -100).makeGraphic(FlxG.width * 2, FlxG.height * 2, 0xFFff1b31);
		red.scrollFactor.set();

		var senpaiEvil:FlxSprite = new FlxSprite();
		senpaiEvil.frames = Paths.getSparrowAtlas('weeb/senpaiCrazy');
		senpaiEvil.animation.addByPrefix('idle', 'Senpai Pre Explosion', 24, false);
		senpaiEvil.setGraphicSize(Std.int(senpaiEvil.width * 6));
		senpaiEvil.scrollFactor.set();
		senpaiEvil.updateHitbox();
		senpaiEvil.screenCenter();
		playState.add(red);

		new FlxTimer().start(0.3, function(tmr:FlxTimer)
		{
			playState.inCutscene = true;
			playState.add(senpaiEvil);
			senpaiEvil.alpha = 0;
			new FlxTimer().start(0.3, function(swagTimer:FlxTimer)
			{
				senpaiEvil.alpha += 0.15;
				if (senpaiEvil.alpha < 1)
				{
					swagTimer.reset();
				}
				else
				{
					senpaiEvil.animation.play('idle');
					FlxG.sound.play(Paths.sound('Senpai_Dies'), 1, false, null, true, function()
					{
						playState.remove(senpaiEvil);
						playState.remove(red);
						FlxG.camera.fade(FlxColor.WHITE, 0.01, true, function()
						{
							playState.add(dialogueBox);
						}, true);
					});
					new FlxTimer().start(3.2, function(deadTime:FlxTimer)
					{
						FlxG.camera.fade(FlxColor.WHITE, 1.6, false);
					});
				}
			});
		});
	}

	override function getDadTex()
	{
		var frames = Paths.getPackerAtlas('characters/spirit');
		dad.frames = frames;
	}

	override function getGFTex()
	{
		var tex = Paths.getSparrowAtlas('weeb/gfPixel');
		gf.frames = tex;
	}

	override function createDadAnimations():Void
	{
		var animation = dad.animation;

		animation.addByPrefix('idle', "idle spirit_", 24, false);
		animation.addByPrefix('singUP', "up_", 24, false);
		animation.addByPrefix('singRIGHT', "right_", 24, false);
		animation.addByPrefix('singLEFT', "left_", 24, false);
		animation.addByPrefix('singDOWN', "spirit down_", 24, false);

		dad.animation = animation;
	}

	override function createDadAnimationOffsets():Void
	{
		dad.addOffset('idle', -220, -280);
		dad.addOffset('singUP', -220, -240);
		dad.addOffset("singRIGHT", -220, -280);
		dad.addOffset("singLEFT", -200, -280);
		dad.addOffset("singDOWN", 170, 110);

		dad.setGraphicSize(Std.int(dad.width * 6));
		dad.updateHitbox();
		dad.antialiasing = false;

		dad.dance();
	}

	override function midSongEventUpdate(curBeat:Int)
	{
		// no mse shit
	}

	override function updateCamFollowDad()
	{
		playState.camFollow.y = dad.getMidpoint().y;
		playState.camFollow.x = dad.getMidpoint().x + 250;
	}

	override function updateCamFollowBF()
	{
		playState.camFollow.x = bf.getMidpoint().x - 200;
		playState.camFollow.y = bf.getMidpoint().y - 200;
	}

	override function initVariables()
	{
		super.initVariables();
		introAlts = ['weeb/pixelUI/ready-pixel', 'weeb/pixelUI/set-pixel', 'weeb/pixelUI/date-pixel'];
	}

	override function createCharacters()
	{
		super.createCharacters();
		gf.alpha = 0; // hide gf shit

		dad.y -= 300;
		
		//create evil trail shit
		if (FlxG.save.data.distractions)
		{
			var evilTrail = new FlxTrail(dad, null, 4, 24, 0.3, 0.069);
			playState.add(evilTrail);
		}
	}


	public override function getDadIcon(icon:HealthIcon)
	{
		icon.loadGraphic(Paths.image('iconGrid'), true, 150, 150);
		icon.animation.add('dad', [23, 23], 0, false, false);
		icon.animation.play("dad");
		icon.antialiasing = false;
	}
	
}