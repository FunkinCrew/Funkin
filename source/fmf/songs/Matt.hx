package fmf.songs;

import flixel.FlxSprite;
import fmf.characters.*;

class Matt extends SongPlayer
{


	override function loadMap()
	{
		playState.defaultCamZoom = 0.8;
		var bg:FlxSprite = new FlxSprite(-600, -200).loadGraphic(Paths.image('matt/swordfight', "mods"));
		bg.antialiasing = true;
		bg.scrollFactor.set(0.9, 0.9);
		bg.active = true;
		playState.add(bg);
	}
    override function getDadTex()
	{
		var tex = Paths.getSparrowAtlas('matt/matt_assets', "mods");
		dad.frames = tex;
	}

	override function getGFTex()
	{
		var tex = Paths.getSparrowAtlas("matt/GF_MII_assets", "mods");
		gf.frames = tex;
	}

	override function createDadAnimations():Void
	{
		var animation = dad.animation;
		animation.addByPrefix('idle', "matt idle", 24);
		animation.addByPrefix('singUP', 'matt up note', 24, false);
		animation.addByPrefix('singDOWN', 'matt down note', 24, false);
		animation.addByPrefix('singLEFT', 'matt left note', 24, false);
		animation.addByPrefix('singRIGHT', 'matt right note', 24, false);

		dad.animation = animation;
	}

	override function createDadAnimationOffsets():Void
	{
		dad.addOffset("singUP", 0, 20);
		dad.addOffset("singRIGHT", -15, -20);
		dad.addOffset("singLEFT", 30, -40);
		dad.addOffset("singDOWN", 0, -20);
		dad.dance();

	}

	override function createCharacters()
	{
		super.createCharacters();

		dad.x -= 250;
		dad.y += 150;

		gf.y -= 200;
	}

	public override function getDadIcon(icon:HealthIcon)
	{
		icon.loadGraphic(Paths.image('matt/iconGrid', "mods"), true, 150, 150);
		icon.animation.add('dad', [23, 24], 0, false, false);
		icon.animation.play("dad");
	}

}