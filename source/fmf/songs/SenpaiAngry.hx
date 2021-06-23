package fmf.songs;

import flixel.math.FlxPoint;
import fmf.characters.*;
import flixel.FlxG;
import flixel.FlxSprite;

class SenpaiAngry extends Senpai
{
	// same as senpai, just replace character

	override function getDadTex()
	{
		var frames = Paths.getSparrowAtlas('characters/senpai');
		dad.frames = frames;
	}

	override function loadMap()
	{
		super.loadMap();

		if (FlxG.save.data.distractions)
		{
			bgGirls.getScared();
		}
	}

	override function showDialogue()
	{
		FlxG.sound.play(Paths.sound('ANGRY'));
		super.showDialogue();
	}

	override function createDadAnimations()
	{
		var animation = dad.animation;

		animation.addByPrefix('idle', 'Angry Senpai Idle', 24, false);
		animation.addByPrefix('singUP', 'Angry Senpai UP NOTE', 24, false);
		animation.addByPrefix('singLEFT', 'Angry Senpai LEFT NOTE', 24, false);
		animation.addByPrefix('singRIGHT', 'Angry Senpai RIGHT NOTE', 24, false);
		animation.addByPrefix('singDOWN', 'Angry Senpai DOWN NOTE', 24, false);

		dad.animation = animation;
	}

	override function createDadAnimationOffsets()
	{
		dad.addOffset('idle');
		dad.addOffset("singUP", 5, 37);
		dad.addOffset("singRIGHT");
		dad.addOffset("singLEFT", 40);
		dad.addOffset("singDOWN", 14);
		dad.playAnim('idle');

		dad.setGraphicSize(Std.int(dad.width * 6));
		dad.updateHitbox();

		dad.antialiasing = false;
	}

}