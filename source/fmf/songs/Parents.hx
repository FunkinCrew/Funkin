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

	var fc:Bool = true;

	var bgGirls:BackgroundGirls;

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
		playState.add(fgSnow);

		santa = new FlxSprite(-840, 150);
		santa.frames = Paths.getSparrowAtlas('christmas/santa', 'week5');
		santa.animation.addByPrefix('idle', 'santa idle in fear', 24, false);
		santa.antialiasing = true;
		if (FlxG.save.data.distractions)
		{
			playState.add(santa);
		}

	}

	override function getGFTex()
	{
		var tex = Paths.getSparrowAtlas('gf/GF_normal');
		gf.frames = tex;
    }

    override function getDadTex()
	{
		var tex = Paths.getSparrowAtlas('characters/spooky_kids_assets');
		dad.frames = tex;
	}
   
	override function createDadAnimations():Void
	{
		var animation = dad.animation;
      
        animation.addByPrefix('singUP', 'spooky UP NOTE', 24, false);
        animation.addByPrefix('singDOWN', 'spooky DOWN note', 24, false);
        animation.addByPrefix('singLEFT', 'note sing left', 24, false);
        animation.addByPrefix('singRIGHT', 'spooky sing right', 24, false);
        animation.addByIndices('danceLeft', 'spooky dance idle', [0, 2, 6], "", 12, false);
        animation.addByIndices('danceRight', 'spooky dance idle', [8, 10, 12, 14], "", 12, false);


		dad.animation = animation;
	}

	override function createDadAnimationOffsets():Void
	{
        dad.addOffset('danceLeft');
        dad.addOffset('danceRight');

        dad.addOffset("singUP", -20, 26);
        dad.addOffset("singRIGHT", -130, -14);
        dad.addOffset("singLEFT", 130, -10);
        dad.addOffset("singDOWN", -50, -130);
	}


	override function createCharacters()
	{
        super.createCharacters();
        dad.x -= 250;
        dad.y += 50;
        gf.y -= 125;
        bf.x += 50;
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