package;

import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import shaderslmfao.ColorSwap;
import ui.PreferencesMenu;

using StringTools;

#if polymod
import polymod.format.ParseRules.TargetSignatureElement;
#end

class Note extends FlxSprite
{
	public var data:NoteData = {
		strumTime: 0,
		sustainLength: 0,
		altNote: false,
		noteData: 0
	};

	public var mustPress:Bool = false;
	public var followsTime:Bool = true; // used if you want the note to follow the time shit!
	public var canBeHit:Bool = false;
	public var tooLate:Bool = false;
	public var wasGoodHit:Bool = false;
	public var prevNote:Note;

	private var willMiss:Bool = false;

	public var invisNote:Bool = false;

	public var sustainLength:Float = 0;
	public var isSustainNote:Bool = false;

	public var colorSwap:ColorSwap;

	public static var swagWidth:Float = 160 * 0.7;
	public static var PURP_NOTE:Int = 0;
	public static var GREEN_NOTE:Int = 2;
	public static var BLUE_NOTE:Int = 1;
	public static var RED_NOTE:Int = 3;

	// SCORING STUFF
	public static var safeFrames:Int = 10;
	public static var HIT_WINDOW:Float = (safeFrames / 60) * 1000; // 166.67 ms hit window
	// anything above bad threshold is shit
	public static var BAD_THRESHOLD:Float = 0.8; // 	125ms	, 8 frames
	public static var GOOD_THRESHOLD:Float = 0.55; // 	91.67ms	, 5.5 frames
	public static var SICK_THRESHOLD:Float = 0.2; // 	33.33ms	, 2 frames

	public var noteSpeedMulti:Float = 1;
	public var pastHalfWay:Bool = false;

	// anything below sick threshold is sick
	public static var arrowColors:Array<Float> = [1, 1, 1, 1];

	public function new(strumTime:Float = 0, noteData:Int, ?prevNote:Note, ?sustainNote:Bool = false)
	{
		super();

		if (prevNote == null)
			prevNote = this;

		this.prevNote = prevNote;
		isSustainNote = sustainNote;

		x += 50;
		// MAKE SURE ITS DEFINITELY OFF SCREEN?
		y -= 2000;
		data.strumTime = strumTime;

		data.noteData = noteData;

		var daStage:String = PlayState.curStage;

		switch (daStage)
		{
			case 'school' | 'schoolEvil':
				loadGraphic(Paths.image('weeb/pixelUI/arrows-pixels'), true, 17, 17);

				animation.add('greenScroll', [6]);
				animation.add('redScroll', [7]);
				animation.add('blueScroll', [5]);
				animation.add('purpleScroll', [4]);

				if (isSustainNote)
				{
					loadGraphic(Paths.image('weeb/pixelUI/arrowEnds'), true, 7, 6);

					animation.add('purpleholdend', [4]);
					animation.add('greenholdend', [6]);
					animation.add('redholdend', [7]);
					animation.add('blueholdend', [5]);

					animation.add('purplehold', [0]);
					animation.add('greenhold', [2]);
					animation.add('redhold', [3]);
					animation.add('bluehold', [1]);
				}

				setGraphicSize(Std.int(width * PlayState.daPixelZoom));
				updateHitbox();

			default:
				frames = Paths.getSparrowAtlas('NOTE_assets');

				animation.addByPrefix('greenScroll', 'green instance');
				animation.addByPrefix('redScroll', 'red instance');
				animation.addByPrefix('blueScroll', 'blue instance');
				animation.addByPrefix('purpleScroll', 'purple instance');

				animation.addByPrefix('purpleholdend', 'pruple end hold');
				animation.addByPrefix('greenholdend', 'green hold end');
				animation.addByPrefix('redholdend', 'red hold end');
				animation.addByPrefix('blueholdend', 'blue hold end');

				animation.addByPrefix('purplehold', 'purple hold piece');
				animation.addByPrefix('greenhold', 'green hold piece');
				animation.addByPrefix('redhold', 'red hold piece');
				animation.addByPrefix('bluehold', 'blue hold piece');

				setGraphicSize(Std.int(width * 0.7));
				updateHitbox();
				antialiasing = true;

				// colorSwap.colorToReplace = 0xFFF9393F;
				// colorSwap.newColor = 0xFF00FF00;

				// color = FlxG.random.color();
				// color.saturation *= 4;
				// replaceColor(0xFFC1C1C1, FlxColor.RED);
		}

		colorSwap = new ColorSwap();
		shader = colorSwap.shader;
		updateColors();

		switch (noteData)
		{
			case 0:
				x += swagWidth * 0;
				animation.play('purpleScroll');
			case 1:
				x += swagWidth * 1;
				animation.play('blueScroll');
			case 2:
				x += swagWidth * 2;
				animation.play('greenScroll');
			case 3:
				x += swagWidth * 3;
				animation.play('redScroll');
		}

		// trace(prevNote);

		if (isSustainNote && prevNote != null)
		{
			alpha = 0.6;

			if (PreferencesMenu.getPref('downscroll'))
				angle = 180;

			x += width / 2;

			switch (noteData)
			{
				case 2:
					animation.play('greenholdend');
				case 3:
					animation.play('redholdend');
				case 1:
					animation.play('blueholdend');
				case 0:
					animation.play('purpleholdend');
			}

			updateHitbox();

			x -= width / 2;

			if (PlayState.curStage.startsWith('school'))
				x += 30;

			if (prevNote.isSustainNote)
			{
				switch (prevNote.data.noteData)
				{
					case 0:
						prevNote.animation.play('purplehold');
					case 1:
						prevNote.animation.play('bluehold');
					case 2:
						prevNote.animation.play('greenhold');
					case 3:
						prevNote.animation.play('redhold');
				}

				prevNote.updateHitbox();

				var scaleThing:Float = Math.round((Conductor.stepCrochet) * (0.45 * FlxMath.roundDecimal(SongLoad.getSpeed(), 2)));
				// get them a LIL closer together cuz the antialiasing blurs the edges
				if (antialiasing)
					scaleThing *= 1.0 + (1.0 / prevNote.frameHeight);
				prevNote.scale.y = scaleThing / prevNote.frameHeight;
				prevNote.updateHitbox();
			}
		}
	}

	override function destroy()
	{
		prevNote = null;

		super.destroy();
	}

	public function updateColors():Void
	{
		colorSwap.update(arrowColors[data.noteData]);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (mustPress)
		{
			// miss on the NEXT frame so lag doesnt make u miss notes
			if (willMiss && !wasGoodHit)
			{
				tooLate = true;
				canBeHit = false;
			}
			else
			{
				if (!pastHalfWay && data.strumTime <= Conductor.songPosition)
				{
					pastHalfWay = true;
					noteSpeedMulti *= 2;
				}

				if (data.strumTime > Conductor.songPosition - HIT_WINDOW)
				{ // * 0.5 if sustain note, so u have to keep holding it closer to all the way thru!
					if (data.strumTime < Conductor.songPosition + (HIT_WINDOW * (isSustainNote ? 0.5 : 1)))
						canBeHit = true;
				}
				else
				{
					canBeHit = true;
					willMiss = true;
				}
			}
		}
		else
		{
			canBeHit = false;

			if (data.strumTime <= Conductor.songPosition)
				wasGoodHit = true;
		}

		if (tooLate)
		{
			if (alpha > 0.3)
				alpha = 0.3;
		}
	}
}

typedef NoteData =
{
	var strumTime:Float;
	var noteData:Int;
	var sustainLength:Float;
	var altNote:Bool;
}
