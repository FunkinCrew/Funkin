package fmf.songs;

import fmf.characters.*;
import flixel.FlxG;
import flixel.FlxSprite;

class Monster extends Spookez
{
	override function getDadTex()
	{
		var tex = Paths.getSparrowAtlas('characters/Monster_Assets');
		dad.frames = tex;
	}

	override function createDadAnimations():Void
	{
		var animation = dad.animation;

		animation.addByPrefix('idle', 'monster idle', 24, false);
		animation.addByPrefix('danceLeft', 'monster idle', 24, false);
		animation.addByPrefix('danceRight', 'monster idle', 24, false);

		animation.addByPrefix('singUP', 'monster up note', 24, false);
		animation.addByPrefix('singDOWN', 'monster down', 24, false);
		animation.addByPrefix('singLEFT', 'Monster left note', 24, false);
		animation.addByPrefix('singRIGHT', 'Monster Right note', 24, false);

		dad.animation = animation;
	}

	override function createDadAnimationOffsets():Void
	{
		dad.addOffset('idle');
		dad.addOffset("singUP", -20, 50);
		dad.addOffset("singRIGHT", -51);
		dad.addOffset("singLEFT", -30);
		dad.addOffset("singDOWN", -30, -40);

		dad.dance();
	}
	override function createCharacters()
	{
		super.createCharacters();
		dad.x -= 100;
		dad.y -= 75;
	
	}

	public override function getDadIcon(icon:HealthIcon)
	{
		icon.loadGraphic(Paths.image('iconGrid'), true, 150, 150);
		icon.animation.add('dad', [19, 20], 0, false, false);
		icon.animation.play("dad");
	}

}