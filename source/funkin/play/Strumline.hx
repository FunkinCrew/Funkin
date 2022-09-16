package funkin.play;

import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.math.FlxPoint;
import flixel.tweens.FlxEase;
import funkin.noteStuff.NoteBasic.NoteColor;
import funkin.noteStuff.NoteBasic.NoteDir;
import funkin.noteStuff.NoteBasic.NoteType;
import funkin.util.Constants;

/**
 * A group controlling the individual notes of the strumline for a given player.
 * 
 * FUN FACT: Setting the X and Y of a FlxSpriteGroup will move all the sprites in the group.
 */
class Strumline extends FlxTypedSpriteGroup<StrumlineArrow>
{
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
		var arrow:StrumlineArrow = new StrumlineArrow(index, style);
		add(arrow);
	}

	/**
	 * Apply a small animation which moves the arrow down and fades it in.
	 * Only plays at the start of Free Play songs.
	 * 
	 * Note that modifying the offset of the whole strumline won't have the 
	 * @param arrow The arrow to animate.
	 * @param index The index of the arrow in the strumline.
	 */
	function fadeInArrow(arrow:FlxSprite):Void
	{
		arrow.y -= 10;
		arrow.alpha = 0;
		FlxTween.tween(arrow, {y: arrow.y + 10, alpha: 1}, 1, {ease: FlxEase.circOut, startDelay: 0.5 + (0.2 * arrow.ID)});
	}

	public function fadeInArrows():Void
	{
		for (arrow in this.members)
		{
			fadeInArrow(arrow);
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
	public inline function getArrow(value:Int):StrumlineArrow
	{
		// members maintains the order that the arrows were added.
		return this.members[value];
	}

	public inline function getArrowByNoteType(value:NoteType):StrumlineArrow
	{
		return getArrow(value.int);
	}

	public inline function getArrowByNoteDir(value:NoteDir):StrumlineArrow
	{
		return getArrow(value.int);
	}

	public inline function getArrowByNoteColor(value:funkin.noteStuff.NoteBasic.NoteColor):StrumlineArrow
	{
		return getArrow(value.int);
	}

	/**
	 * Get the default Y offset of the strumline.
	 * @return Int
	 */
	public static inline function getYPos():Int
	{
		return PreferencesMenu.getPref('downscroll') ? (FlxG.height - 150) : 50;
	}
}

class StrumlineArrow extends FlxSprite
{
	var style:StrumlineStyle;

	public function new(id:Int, style:StrumlineStyle)
	{
		super(0, 0);

		this.ID = id;
		this.style = style;

		// TODO: Unhardcode this. Maybe use a note style system>
		switch (style)
		{
			case PIXEL:
				buildPixelGraphic();
			case NORMAL:
				buildNormalGraphic();
		}

		this.updateHitbox();
		scrollFactor.set(0, 0);
		animation.play('static');
	}

	public function playAnimation(anim:String, force:Bool = false)
	{
		animation.play(anim, force);
		centerOffsets();
		centerOrigin();
	}

	/**
	 * Applies the default note style to an arrow.
	 */
	function buildNormalGraphic():Void
	{
		this.frames = Paths.getSparrowAtlas('NOTE_assets');

		this.animation.addByPrefix('green', 'arrowUP');
		this.animation.addByPrefix('blue', 'arrowDOWN');
		this.animation.addByPrefix('purple', 'arrowLEFT');
		this.animation.addByPrefix('red', 'arrowRIGHT');

		this.setGraphicSize(Std.int(this.width * 0.7));
		this.antialiasing = true;

		this.x += Note.swagWidth * this.ID;

		switch (Math.abs(this.ID))
		{
			case 0:
				this.animation.addByPrefix('static', 'arrow static instance 1');
				this.animation.addByPrefix('pressed', 'left press', 24, false);
				this.animation.addByPrefix('confirm', 'left confirm', 24, false);
			case 1:
				this.animation.addByPrefix('static', 'arrow static instance 2');
				this.animation.addByPrefix('pressed', 'down press', 24, false);
				this.animation.addByPrefix('confirm', 'down confirm', 24, false);
			case 2:
				this.animation.addByPrefix('static', 'arrow static instance 4');
				this.animation.addByPrefix('pressed', 'up press', 24, false);
				this.animation.addByPrefix('confirm', 'up confirm', 24, false);
			case 3:
				this.animation.addByPrefix('static', 'arrow static instance 3');
				this.animation.addByPrefix('pressed', 'right press', 24, false);
				this.animation.addByPrefix('confirm', 'right confirm', 24, false);
		}
	}

	/**
	 * Applies the pixel note style to an arrow.
	 */
	function buildPixelGraphic():Void
	{
		this.loadGraphic(Paths.image('weeb/pixelUI/arrows-pixels'), true, 17, 17);

		this.animation.add('purplel', [4]);
		this.animation.add('blue', [5]);
		this.animation.add('green', [6]);
		this.animation.add('red', [7]);

		this.setGraphicSize(Std.int(this.width * Constants.PIXEL_ART_SCALE));
		this.updateHitbox();

		// Forcibly disable anti-aliasing on pixel graphics to stop blur.
		this.antialiasing = false;

		this.x += Note.swagWidth * this.ID;

		// TODO: Seems weird that these are hardcoded like this... no XML?
		switch (Math.abs(this.ID))
		{
			case 0:
				this.animation.add('static', [0]);
				this.animation.add('pressed', [4, 8], 12, false);
				this.animation.add('confirm', [12, 16], 24, false);
			case 1:
				this.animation.add('static', [1]);
				this.animation.add('pressed', [5, 9], 12, false);
				this.animation.add('confirm', [13, 17], 24, false);
			case 2:
				this.animation.add('static', [2]);
				this.animation.add('pressed', [6, 10], 12, false);
				this.animation.add('confirm', [14, 18], 12, false);
			case 3:
				this.animation.add('static', [3]);
				this.animation.add('pressed', [7, 11], 12, false);
				this.animation.add('confirm', [15, 19], 24, false);
		}
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
