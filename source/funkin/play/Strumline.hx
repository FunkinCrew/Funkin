package funkin.play;

import funkin.ui.PreferencesMenu;
import funkin.Note.NoteColor;
import funkin.Note.NoteDir;
import funkin.Note.NoteType;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import funkin.util.Constants;
import flixel.FlxSprite;
import flixel.math.FlxPoint;
import flixel.group.FlxGroup.FlxTypedGroup;

/**
 * A group controlling the individual notes of the strumline for a given player.
 */
class Strumline extends FlxTypedGroup<FlxSprite>
{
	public var offset(default, set):FlxPoint = new FlxPoint(0, 0);

	function set_offset(value:FlxPoint):FlxPoint
	{
		this.offset = value;
		updatePositions();
		return value;
	}

	/**
	 * The style of the strumline.
	 * Options are normal and pixel.
	 */
	var style:StrumlineStyle;

	/**
	 * The player this strumline belongs to.
	 * 0 is Player 1, etc.
	 */
	var playerId:Int;

	/**
	 * The number of notes in the strumline.
	 */
	var size:Int;

	public function new(playerId:Int = 0, style:StrumlineStyle = NORMAL, size:Int = 4)
	{
		super(0);
		this.playerId = playerId;
		this.style = style;
		this.size = size;

		generateStrumline();
	}

	function generateStrumline():Void
	{
		for (index in 0...size)
		{
			createStrumlineArrow(index);
		}
	}

	function createStrumlineArrow(index:Int):Void
	{
		var arrow:FlxSprite = new FlxSprite(0, 0);

		arrow.ID = index;

		// Color changing for arrows is a WIP.
		/*
			var colorSwapShader:ColorSwap = new ColorSwap();
			colorSwapShader.update(Note.arrowColors[i]);
			arrow.shader = colorSwapShader;
		 */

		switch (style)
		{
			case NORMAL:
				createNormalNote(arrow);
			case PIXEL:
				createPixelNote(arrow);
		}

		arrow.updateHitbox();
		arrow.scrollFactor.set();

		arrow.animation.play('static');

		applyFadeIn(arrow);

		add(arrow);
	}

	/**
	 * Apply a small animation which moves the arrow down and fades it in.
	 * Only plays at the start of Free Play songs I guess?
	 * @param arrow The arrow to animate.
	 * @param index The index of the arrow in the strumline.
	 */
	function applyFadeIn(arrow:FlxSprite):Void
	{
		if (!PlayState.isStoryMode)
		{
			arrow.y -= 10;
			arrow.alpha = 0;
			FlxTween.tween(arrow, {y: arrow.y + 10, alpha: 1}, 1, {ease: FlxEase.circOut, startDelay: 0.5 + (0.2 * arrow.ID)});
		}
	}

	/**
	 * Applies the default note style to an arrow.
	 * @param arrow The arrow to apply the style to.
	 * @param index The index of the arrow in the strumline.
	 */
	function createNormalNote(arrow:FlxSprite):Void
	{
		arrow.frames = Paths.getSparrowAtlas('NOTE_assets');

		arrow.animation.addByPrefix('green', 'arrowUP');
		arrow.animation.addByPrefix('blue', 'arrowDOWN');
		arrow.animation.addByPrefix('purple', 'arrowLEFT');
		arrow.animation.addByPrefix('red', 'arrowRIGHT');

		arrow.setGraphicSize(Std.int(arrow.width * 0.7));
		arrow.antialiasing = true;

		arrow.x += Note.swagWidth * arrow.ID;

		switch (Math.abs(arrow.ID))
		{
			case 0:
				arrow.animation.addByPrefix('static', 'arrow static instance 1');
				arrow.animation.addByPrefix('pressed', 'left press', 24, false);
				arrow.animation.addByPrefix('confirm', 'left confirm', 24, false);
			case 1:
				arrow.animation.addByPrefix('static', 'arrow static instance 2');
				arrow.animation.addByPrefix('pressed', 'down press', 24, false);
				arrow.animation.addByPrefix('confirm', 'down confirm', 24, false);
			case 2:
				arrow.animation.addByPrefix('static', 'arrow static instance 4');
				arrow.animation.addByPrefix('pressed', 'up press', 24, false);
				arrow.animation.addByPrefix('confirm', 'up confirm', 24, false);
			case 3:
				arrow.animation.addByPrefix('static', 'arrow static instance 3');
				arrow.animation.addByPrefix('pressed', 'right press', 24, false);
				arrow.animation.addByPrefix('confirm', 'right confirm', 24, false);
		}
	}

	/**
	 * Applies the pixel note style to an arrow.
	 * @param arrow The arrow to apply the style to.
	 * @param index The index of the arrow in the strumline.
	 */
	function createPixelNote(arrow:FlxSprite):Void
	{
		arrow.loadGraphic(Paths.image('weeb/pixelUI/arrows-pixels'), true, 17, 17);

		arrow.animation.add('purplel', [4]);
		arrow.animation.add('blue', [5]);
		arrow.animation.add('green', [6]);
		arrow.animation.add('red', [7]);

		arrow.setGraphicSize(Std.int(arrow.width * Constants.PIXEL_ART_SCALE));
		arrow.updateHitbox();

		// Forcibly disable anti-aliasing on pixel graphics to stop blur.
		arrow.antialiasing = false;

		arrow.x += Note.swagWidth * arrow.ID;

		// TODO: Seems weird that these are hardcoded...
		switch (Math.abs(arrow.ID))
		{
			case 0:
				arrow.animation.add('static', [0]);
				arrow.animation.add('pressed', [4, 8], 12, false);
				arrow.animation.add('confirm', [12, 16], 24, false);
			case 1:
				arrow.animation.add('static', [1]);
				arrow.animation.add('pressed', [5, 9], 12, false);
				arrow.animation.add('confirm', [13, 17], 24, false);
			case 2:
				arrow.animation.add('static', [2]);
				arrow.animation.add('pressed', [6, 10], 12, false);
				arrow.animation.add('confirm', [14, 18], 12, false);
			case 3:
				arrow.animation.add('static', [3]);
				arrow.animation.add('pressed', [7, 11], 12, false);
				arrow.animation.add('confirm', [15, 19], 24, false);
		}
	}

	function updatePositions()
	{
		for (arrow in members)
		{
			arrow.x = Note.swagWidth * arrow.ID;
			arrow.x += offset.x;

			arrow.y = 0;
			arrow.y += offset.y;
		}
	}

	/**
	 * Retrieves the arrow at the given position in the strumline.
	 * @param index The index to retrieve.
	 * @return The corresponding FlxSprite.
	 */
	public inline function getArrow(value:Int):FlxSprite
	{
		// members maintains the order that the arrows were added.
		return this.members[value];
	}

	public inline function getArrowByNoteType(value:NoteType):FlxSprite
	{
		return getArrow(value.int);
	}

	public inline function getArrowByNoteDir(value:NoteDir):FlxSprite
	{
		return getArrow(value.int);
	}

	public inline function getArrowByNoteColor(value:NoteColor):FlxSprite
	{
		return getArrow(value.int);
	}

	public static inline function getYPos():Int
	{
		return PreferencesMenu.getPref('downscroll') ? (FlxG.height - 150) : 50;
	}
}

/**
 * TODO: Unhardcode this and make it part of the note style system.
 */
enum StrumlineStyle
{
	NORMAL;
	PIXEL;
}
