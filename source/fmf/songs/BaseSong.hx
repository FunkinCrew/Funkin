package fmf.songs;

import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.FlxG;
import flixel.util.FlxTimer;
import flixel.FlxObject;
import flixel.math.FlxPoint;
import fmf.characters.*;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup;
import Song.SwagSong;

// base song hold variable and some helper function
class BaseSong
{


	// characters shit
	public var bf:Character;


	// bf place here for debug menu support
	// bf skins
	private function getBFTex():Void
	{
		var tex = Paths.getSparrowAtlas('characters/BoyFriend_Assets');
		bf.frames = tex;
	}

	// create animation for BF
	private function createBFAnimations():Void
	{
		bf.animation.addByPrefix('idle', 'BF idle dance', 24, false);
		bf.animation.addByPrefix('singUP', 'BF NOTE UP0', 24, false);
		bf.animation.addByPrefix('singLEFT', 'BF NOTE LEFT0', 24, false);
		bf.animation.addByPrefix('singRIGHT', 'BF NOTE RIGHT0', 24, false);
		bf.animation.addByPrefix('singDOWN', 'BF NOTE DOWN0', 24, false);
		bf.animation.addByPrefix('singUPmiss', 'BF NOTE UP MISS', 24, false);
		bf.animation.addByPrefix('singLEFTmiss', 'BF NOTE LEFT MISS', 24, false);
		bf.animation.addByPrefix('singRIGHTmiss', 'BF NOTE RIGHT MISS', 24, false);
		bf.animation.addByPrefix('singDOWNmiss', 'BF NOTE DOWN MISS', 24, false);
		bf.animation.addByPrefix('hey', 'BF HEY', 24, false);

		bf.animation.addByPrefix('scared', 'BF idle shaking', 24);
	}

	// create animation offset for BF
	private function createBFAnimationOffsets():Void
	{
		bf.addOffset('idle', -5);
		bf.addOffset("singUP", -29, 27);
		bf.addOffset("singRIGHT", -38, -7);
		bf.addOffset("singLEFT", 12, -6);
		bf.addOffset("singDOWN", -10, -50);
		bf.addOffset("singUPmiss", -29, 27);
		bf.addOffset("singRIGHTmiss", -30, 21);
		bf.addOffset("singLEFTmisss", 12, 24);
		bf.addOffset("singDOWNmiss", -11, -19);
		bf.addOffset("hey", 7, 4);
		bf.addOffset('scared', -4);

		bf.playAnim('idle');
		bf.flipX = true;
	}

	// set additional animation for BF
	private function setBF()
	{
		bf.dance();
		bf.flipX = !bf.flipX;

		// Doesn't flip for BF, since his are already in the right place???		{
		var oldRight = bf.animation.getByName('singRIGHT').frames;
		bf.animation.getByName('singRIGHT').frames = bf.animation.getByName('singLEFT').frames;
		bf.animation.getByName('singLEFT').frames = oldRight;

		// IF THEY HAVE MISS ANIMATIONS??
		if (bf.animation.getByName('singRIGHTmiss') != null)
		{
			var oldMiss = bf.animation.getByName('singRIGHTmiss').frames;
			bf.animation.getByName('singRIGHTmiss').frames = bf.animation.getByName('singLEFTmiss').frames;
			bf.animation.getByName('singLEFTmiss').frames = oldMiss;
		}
	}

	// set BF difference behaviour
	function getBFVersion():Character
	{
		return new Boyfriend(770, 450);
	}

	// create BF
	public function createBF():Void
	{
		bf = getBFVersion();
		getBFTex();
		createBFAnimations();
		createBFAnimationOffsets();
		setBF();
	}

	// set icon bf
	public function getBFIcon(icon:HealthIcon)
	{
		icon.loadGraphic(Paths.image('iconGrid'), true, 150, 150);
		icon.animation.add('bf', [0, 1], 0, false, true);
		icon.animation.play("bf");
	}

	// set icon dad
	public function getDadIcon(icon:HealthIcon)
	{
		icon.loadGraphic(Paths.image('iconGrid'), true, 150, 150);
		icon.animation.add('dad', [16, 6], 0, false, false);
		icon.animation.play("dad");

	}

	// get arrow skin depending on song
	public function getArrowSkin(i:Int, babyArrow:FlxSprite)
	{
		babyArrow.frames = Paths.getSparrowAtlas('NOTE_assets');
		babyArrow.animation.addByPrefix('green', 'arrowUP');
		babyArrow.animation.addByPrefix('blue', 'arrowDOWN');
		babyArrow.animation.addByPrefix('purple', 'arrowLEFT');
		babyArrow.animation.addByPrefix('red', 'arrowRIGHT');

		babyArrow.antialiasing = true;
		babyArrow.setGraphicSize(Std.int(babyArrow.width * 0.7));

		switch (Math.abs(i))
		{
			case 0:
				babyArrow.x += Note.swagWidth * 0;
				babyArrow.animation.addByPrefix('static', 'arrowLEFT');
				babyArrow.animation.addByPrefix('pressed', 'left press', 24, false);
				babyArrow.animation.addByPrefix('confirm', 'left confirm', 24, false);
			case 1:
				babyArrow.x += Note.swagWidth * 1;
				babyArrow.animation.addByPrefix('static', 'arrowDOWN');
				babyArrow.animation.addByPrefix('pressed', 'down press', 24, false);
				babyArrow.animation.addByPrefix('confirm', 'down confirm', 24, false);
			case 2:
				babyArrow.x += Note.swagWidth * 2;
				babyArrow.animation.addByPrefix('static', 'arrowUP');
				babyArrow.animation.addByPrefix('pressed', 'up press', 24, false);
				babyArrow.animation.addByPrefix('confirm', 'up confirm', 24, false);
			case 3:
				babyArrow.x += Note.swagWidth * 3;
				babyArrow.animation.addByPrefix('static', 'arrowRIGHT');
				babyArrow.animation.addByPrefix('pressed', 'right press', 24, false);
				babyArrow.animation.addByPrefix('confirm', 'right confirm', 24, false);
		}
	}

	// get note skin depending on song
	public function getNoteSkin(note:Note)
	{
		note.frames = Paths.getSparrowAtlas('NOTE_assets');

		note.animation.addByPrefix('greenScroll', 'green0');
		note.animation.addByPrefix('redScroll', 'red0');
		note.animation.addByPrefix('blueScroll', 'blue0');
		note.animation.addByPrefix('purpleScroll', 'purple0');

		note.animation.addByPrefix('purpleholdend', 'pruple end hold');
		note.animation.addByPrefix('greenholdend', 'green hold end');
		note.animation.addByPrefix('redholdend', 'red hold end');
		note.animation.addByPrefix('blueholdend', 'blue hold end');

		note.animation.addByPrefix('purplehold', 'purple hold piece');
		note.animation.addByPrefix('greenhold', 'green hold piece');
		note.animation.addByPrefix('redhold', 'red hold piece');
		note.animation.addByPrefix('bluehold', 'blue hold piece');

		note.setGraphicSize(Std.int(note.width * 0.7));
		note.updateHitbox();
		note.antialiasing = true;
	}
}