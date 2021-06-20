package fmf.songs;

import flixel.math.FlxPoint;
import fmf.characters.*;
import flixel.FlxG;
import flixel.FlxSprite;

class Senpai extends SongPlayer
{
	var bgGirls:BackgroundGirls;

	override function loadMap()
	{
		playState.defaultCamZoom = 1.15;

		var bgSky = new FlxSprite().loadGraphic(Paths.image('weeb/weebSky', 'week6'));
		bgSky.scrollFactor.set(0.1, 0.1);
		playState.add(bgSky);

		var repositionShit = -200;

		var bgSchool:FlxSprite = new FlxSprite(repositionShit, 0).loadGraphic(Paths.image('weeb/weebSchool', 'week6'));
		bgSchool.scrollFactor.set(0.6, 0.90);

		playState.add(bgSchool);

		var bgStreet:FlxSprite = new FlxSprite(repositionShit).loadGraphic(Paths.image('weeb/weebStreet', 'week6'));
		bgStreet.scrollFactor.set(0.95, 0.95);
		playState.add(bgStreet);

		var fgTrees:FlxSprite = new FlxSprite(repositionShit + 170, 130).loadGraphic(Paths.image('weeb/weebTreesBack', 'week6'));
		fgTrees.scrollFactor.set(0.9, 0.9);
		playState.add(fgTrees);

		var bgTrees:FlxSprite = new FlxSprite(repositionShit - 380, -800);
		var treetex = Paths.getPackerAtlas('weeb/weebTrees', 'week6');
		bgTrees.frames = treetex;
		bgTrees.animation.add('treeLoop', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18], 12);
		bgTrees.animation.play('treeLoop');
		bgTrees.scrollFactor.set(0.85, 0.85);
		playState.add(bgTrees);

		var treeLeaves:FlxSprite = new FlxSprite(repositionShit, -40);
		treeLeaves.frames = Paths.getSparrowAtlas('weeb/petals', 'week6');
		treeLeaves.animation.addByPrefix('leaves', 'PETALS ALL', 24, true);
		treeLeaves.animation.play('leaves');
		treeLeaves.scrollFactor.set(0.85, 0.85);
		playState.add(treeLeaves);

		var widShit = Std.int(bgSky.width * 6);

		bgSky.setGraphicSize(widShit);
		bgSchool.setGraphicSize(widShit);
		bgStreet.setGraphicSize(widShit);
		bgTrees.setGraphicSize(Std.int(widShit * 1.4));
		fgTrees.setGraphicSize(Std.int(widShit * 0.8));
		treeLeaves.setGraphicSize(widShit);

		fgTrees.updateHitbox();
		bgSky.updateHitbox();
		bgSchool.updateHitbox();
		bgStreet.updateHitbox();
		bgTrees.updateHitbox();
		treeLeaves.updateHitbox();

		bgGirls = new BackgroundGirls(-100, 190);
		bgGirls.scrollFactor.set(0.9, 0.9);

		bgGirls.setGraphicSize(Std.int(bgGirls.width * PlayState.daPixelZoom));
		bgGirls.updateHitbox();

		if (FlxG.save.data.distractions)
		{
			playState.add(bgGirls);
		}
	}

	override function getDadTex()
	{
		var frames = Paths.getSparrowAtlas('characters/senpai');
		dad.frames = frames;
	}

	override function getGFTex()
	{
		var tex = Paths.getSparrowAtlas('weeb/gfPixel');
		gf.frames = tex;
	}

	override function getBFTex()
	{
		var frames = Paths.getSparrowAtlas('characters/bfPixel');
		bf.frames = frames;

		frames = null; // alloc
	}

	override function createGFAnimations()
	{
		var animation = gf.animation;
		animation.addByIndices('singUP', 'GF IDLE', [2], "", 24, false);
		animation.addByIndices('danceLeft', 'GF IDLE', [30, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14], "", 24, false);
		animation.addByIndices('danceRight', 'GF IDLE', [15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29], "", 24, false);

		gf.animation = animation;
	}

	override function createGFAnimationOffsets()
	{
		gf.addOffset('danceLeft', 0);
		gf.addOffset('danceRight', 0);

		gf.setGraphicSize(Std.int(gf.width * PlayState.daPixelZoom));
		gf.updateHitbox();

		gf.y += 30;
		gf.antialiasing = false;

		gf.playAnim('danceRight');
	}

	override function createBFAnimations()
	{
		var animation = bf.animation;

		animation.addByPrefix('idle', 'BF IDLE', 24, false);
		animation.addByPrefix('singUP', 'BF UP NOTE', 24, false);
		animation.addByPrefix('singLEFT', 'BF LEFT NOTE', 24, false);
		animation.addByPrefix('singRIGHT', 'BF RIGHT NOTE', 24, false);
		animation.addByPrefix('singDOWN', 'BF DOWN NOTE', 24, false);
		animation.addByPrefix('singUPmiss', 'BF UP MISS', 24, false);
		animation.addByPrefix('singLEFTmiss', 'BF LEFT MISS', 24, false);
		animation.addByPrefix('singRIGHTmiss', 'BF RIGHT MISS', 24, false);
		animation.addByPrefix('singDOWNmiss', 'BF DOWN MISS', 24, false);

		bf.animation = animation;
	}

	override function createBFAnimationOffsets()
	{
		bf.addOffset('idle');
		bf.addOffset("singUP");
		bf.addOffset("singRIGHT");
		bf.addOffset("singLEFT");
		bf.addOffset("singDOWN");
		bf.addOffset("singUPmiss");
		bf.addOffset("singRIGHTmiss");
		bf.addOffset("singLEFTmiss");
		bf.addOffset("singDOWNmiss");
		bf.setGraphicSize(Std.int(bf.width * 6));
		bf.updateHitbox();

		bf.playAnim('idle');
		bf.width -= 100;
		bf.height -= 100;

		bf.antialiasing = false;

		bf.flipX = true;
	}

	override function createDadAnimations():Void
	{
		var animation = dad.animation;

		animation.addByPrefix('idle', 'Senpai Idle', 24, false);
		animation.addByPrefix('singUP', 'SENPAI UP NOTE', 24, false);
		animation.addByPrefix('singLEFT', 'SENPAI LEFT NOTE', 24, false);
		animation.addByPrefix('singRIGHT', 'SENPAI RIGHT NOTE', 24, false);
		animation.addByPrefix('singDOWN', 'SENPAI DOWN NOTE', 24, false);

		dad.animation = animation;
	}

	override function createDadAnimationOffsets():Void
	{
		dad.addOffset('idle');
		dad.addOffset("singUP", 5, 37);
		dad.addOffset("singRIGHT");
		dad.addOffset("singLEFT", 40);
		dad.addOffset("singDOWN", 14);
		dad.setGraphicSize(Std.int(dad.width * 6));
		dad.updateHitbox();
		dad.antialiasing = false;

		dad.dance();
	}

	override function setCamPosition()
	{
		camPos.x = bf.x;
		camPos.y = bf.y;
	}

	override function midSongEventUpdate(curBeat:Int)
	{
		if (FlxG.save.data.distractions)
			bgGirls.dance();
	}

	override function updateCamFollowDad()
	{
		playState.camFollow.y = dad.getMidpoint().y - 430;
		playState.camFollow.x = dad.getMidpoint().x - 100;
	}

	override function updateCamFollowBF()
	{
		playState.camFollow.x = bf.getMidpoint().x - 200;
		playState.camFollow.y = bf.getMidpoint().y - 200;
	}

	private override function introType():String
	{
		return "-pixel";
	}

	override function initVariables()
	{
		super.initVariables();
		introAlts = ['weeb/pixelUI/ready-pixel', 'weeb/pixelUI/set-pixel', 'weeb/pixelUI/date-pixel'];
	}

	override function ready()
	{
		super.ready();
		readySprite.setGraphicSize(Std.int(readySprite.width * PlayState.daPixelZoom));
	}

	override function set()
	{
		super.set();
		setSprite.setGraphicSize(Std.int(setSprite.width * PlayState.daPixelZoom));
	}

	override function go()
	{
		super.go();
		goSprite.setGraphicSize(Std.int(goSprite.width * PlayState.daPixelZoom));
	}

	override function createCharacters()
	{
		super.createCharacters();

		dad.x -= 200;
		dad.y += 150;

		bf.x += 200;
		bf.y += 220;

		gf.x += 150;
		gf.y += 150;
	}
}