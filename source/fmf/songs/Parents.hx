package fmf.songs;

import fmf.characters.*;
import flixel.FlxG;
import flixel.FlxSprite;
import Song.SwagSong;

class Parents extends SongPlayer
{
	var upperBoppers:FlxSprite;
	var bottomBoppers:FlxSprite;
	var santa:FlxSprite;


	override function loadMap()
	{
		playState.defaultCamZoom = 0.80;

		var bg:FlxSprite = new FlxSprite(-1000, -500).loadGraphic(Paths.image('christmas/bgWalls', 'week5'));
		bg.antialiasing = true;
		bg.scrollFactor.set(0.2, 0.2);
		bg.active = false;
		bg.setGraphicSize(Std.int(bg.width * 0.8));
		bg.updateHitbox();
		playState.add(bg);

		upperBoppers = new FlxSprite(-240, -90);
		upperBoppers.frames = Paths.getSparrowAtlas('christmas/upperBop', 'week5');
		upperBoppers.animation.addByPrefix('bop', "Upper Crowd Bob", 24, false);
		upperBoppers.antialiasing = true;
		upperBoppers.scrollFactor.set(0.33, 0.33);
		upperBoppers.setGraphicSize(Std.int(upperBoppers.width * 0.85));
		upperBoppers.updateHitbox();
		if (FlxG.save.data.distractions)
		{
			playState.add(upperBoppers);
		}

		var bgEscalator:FlxSprite = new FlxSprite(-1100, -600).loadGraphic(Paths.image('christmas/bgEscalator', 'week5'));
		bgEscalator.antialiasing = true;
		bgEscalator.scrollFactor.set(0.3, 0.3);
		bgEscalator.active = false;
		bgEscalator.setGraphicSize(Std.int(bgEscalator.width * 0.9));
		bgEscalator.updateHitbox();
		playState.add(bgEscalator);

		var tree:FlxSprite = new FlxSprite(370, -250).loadGraphic(Paths.image('christmas/christmasTree', 'week5'));
		tree.antialiasing = true;
		tree.scrollFactor.set(0.40, 0.40);
		playState.add(tree);

		bottomBoppers = new FlxSprite(-300, 140);
		bottomBoppers.frames = Paths.getSparrowAtlas('christmas/bottomBop', 'week5');
		bottomBoppers.animation.addByPrefix('bop', 'Bottom Level Boppers', 24, false);
		bottomBoppers.antialiasing = true;
		bottomBoppers.scrollFactor.set(0.9, 0.9);
		bottomBoppers.setGraphicSize(Std.int(bottomBoppers.width * 1));
		bottomBoppers.updateHitbox();
		if (FlxG.save.data.distractions)
		{
			playState.add(bottomBoppers);
		}

		var fgSnow:FlxSprite = new FlxSprite(-600, 700).loadGraphic(Paths.image('christmas/fgSnow', 'week5'));
		fgSnow.active = false;
		fgSnow.antialiasing = true;
		fgSnow.scale.x = 1.25;
		playState.add(fgSnow);

		santa = new FlxSprite(1300, 150);
		santa.frames = Paths.getSparrowAtlas('christmas/santa', 'week5');
		santa.animation.addByPrefix('idle', 'santa idle in fear', 24, false);
		santa.antialiasing = true;
		santa.flipX = true;

		santa.scale.x = 0.5;
		santa.scale.y = 0.5;

		santa.y += 100;

		if (FlxG.save.data.distractions)
		{
			playState.add(santa);
		}
	}

	override function getGFTex()
	{
		var tex = Paths.getSparrowAtlas('gf/gfChristmas');
		gf.frames = tex;
	}

	override function getBFTex()
	{
		var tex = Paths.getSparrowAtlas('characters/bfChristmas');
		bf.frames = tex;
	}

	override function getDadTex()
	{
		var frames = Paths.getSparrowAtlas('characters/mom_dad_christmas_assets');
		dad.frames = frames;
	}

	override function createDadAnimations():Void
	{
		var animation = dad.animation;

		animation.addByPrefix('idle', 'Parent Christmas Idle', 24, false);
		animation.addByPrefix('singUP', 'Parent Up Note Dad', 24, false);
		animation.addByPrefix('singDOWN', 'Parent Down Note Dad', 24, false);
		animation.addByPrefix('singLEFT', 'Parent Left Note Dad', 24, false);
		animation.addByPrefix('singRIGHT', 'Parent Right Note Dad', 24, false);

		animation.addByPrefix('singUP-alt', 'Parent Up Note Mom', 24, false);
		animation.addByPrefix('singDOWN-alt', 'Parent Down Note Mom', 24, false);
		animation.addByPrefix('singLEFT-alt', 'Parent Left Note Mom', 24, false);
		animation.addByPrefix('singRIGHT-alt', 'Parent Right Note Mom', 24, false);

		dad.animation = animation;
	}

	override function createDadAnimationOffsets():Void
	{
		dad.addOffset('idle');
		dad.addOffset("singUP", -47, 24);
		dad.addOffset("singRIGHT", -1, -23);
		dad.addOffset("singLEFT", -30, 16);
		dad.addOffset("singDOWN", -31, -29);
		dad.addOffset("singUP-alt", -47, 24);
		dad.addOffset("singRIGHT-alt", -1, -24);
		dad.addOffset("singLEFT-alt", -30, 15);
		dad.addOffset("singDOWN-alt", -30, -27);

		dad.playAnim('idle');
	}

	override function createCharacters()
	{
		super.createCharacters();

		dad.scale.x = 2;
		dad.scale.y = 2;

		dad.x -= 600;
		dad.y += 50;

		gf.scale.x = 2;
		gf.scale.y = 2;

		gf.y += 100;
		gf.x += 50;

		bf.x += 150;
		bf.y += 50;
	}

	override function updateCamFollowBF()
	{
		playState.camFollow.y = bf.getMidpoint().y - 200;
	}

	override function midSongEventUpdate(curBeat:Int):Void
	{
		if (playState.gfStep())
		{
			switch (PlayState.CURRENT_SONG)
			{
				case 'cocoa':
					cocoaMidSongEvent(curBeat);

				case 'eggnog':
					eggnogMidSongEvent(curBeat);
			}
		}

		if (FlxG.save.data.distractions)
		{
			upperBoppers.animation.play('bop', true);
			bottomBoppers.animation.play('bop', true);
			santa.animation.play('idle', true);
		}
	}

	function cocoaMidSongEvent(curBeat:Int)
	{
		if (curBeat < 170)
			if (curBeat < 65 || curBeat > 130 && curBeat < 145)
				if (curBeat % 16 == 15)
					gf.playAnimForce('cheer', 0.5);
	}

	function eggnogMidSongEvent(curBeat:Int)
	{
		if (curBeat > 10 && curBeat != 111 && curBeat < 220)
			if (curBeat % 8 == 7)
				gf.playAnimForce('cheer', 0.5);
	}

	function lightningStrikeShit(curBeat:Int):Void
	{
	}
}