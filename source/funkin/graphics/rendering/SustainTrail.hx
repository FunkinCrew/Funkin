package funkin.graphics.rendering;

import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import flixel.graphics.tile.FlxDrawTrianglesItem;
import flixel.math.FlxMath;

/**
 * This is based heavily on the `FlxStrip` class. It uses `drawTriangles()` to clip a sustain note
 * trail at a certain time.
 * The whole `FlxGraphic` is used as a texture map. See the `NOTE_hold_assets.fla` file for specifics
 * on how it should be constructed.
 *
 * @author MtH
 */
class SustainTrail extends FlxSprite
{
	/**
	 * Used to determine which note color/direction to draw for the sustain.
	 */
	public var noteData:Int = 0;

	/**
	 * The zoom level to render the sustain at.
	 * Defaults to 1.0, increased to 6.0 for pixel notes.
	 */
	public var zoom(default, set):Float = 1;

	/**
	 * The strumtime of the note, in milliseconds.
	 */
	public var strumTime:Float = 0; // millis

	/**
	 * The sustain length of the note, in milliseconds.
	 */
	public var sustainLength(default, set):Float = 0; // millis

	/**
	 * The scroll speed of the note, as a multiplier.
	 */
	public var scrollSpeed(default, set):Float = 1.0; // stand-in for PlayState scroll speed

	/**
	 * Whether the note was missed.
	 */
	public var missed:Bool = false; // maybe BlendMode.MULTIPLY if missed somehow, drawTriangles does not support!

	/**
	 * A `Vector` of floats where each pair of numbers is treated as a coordinate location (an x, y pair).
	 */
	private var vertices:DrawData<Float> = new DrawData<Float>();

	/**
	 * A `Vector` of integers or indexes, where every three indexes define a triangle.
	 */
	private var indices:DrawData<Int> = new DrawData<Int>();

	/**
	 * A `Vector` of normalized coordinates used to apply texture mapping.
	 */
	private var uvtData:DrawData<Float> = new DrawData<Float>();

	private var processedGraphic:FlxGraphic;

	/**
	 * What part of the trail's end actually represents the end of the note.
	 * This can be used to have a little bit sticking out.
	 */
	public var endOffset:Float = 0.5; // 0.73 is roughly the bottom of the sprite in the normal graphic!

	/**
	 * At what point the bottom for the trail's end should be clipped off.
	 * Used in cases where there's an extra bit of the graphic on the bottom to avoid antialiasing issues with overflow.
	 */
	public var bottomClip:Float = 0.9;

	/**
	 * Normally you would take strumTime:Float, noteData:Int, sustainLength:Float, parentNote:Note (?)
	 * @param NoteData 
	 * @param SustainLength 
	 * @param FileName 
	 */
	public function new(NoteData:Int, SustainLength:Float, Path:String, ?Alpha:Float = 0.6, ?Pixel:Bool = false)
	{
		super(0, 0, Path);

		// BASIC SETUP
		this.sustainLength = SustainLength;
		this.noteData = NoteData;

		// CALCULATE SIZE
		if (Pixel)
		{
			this.endOffset = bottomClip = 1;
			this.antialiasing = false;
			this.zoom = 6.0;
		}
		else
		{
			this.antialiasing = true;
			this.zoom = 1.0;
		}
		// width = graphic.width / 8 * zoom; // amount of notes * 2
		height = sustainHeight(sustainLength, scrollSpeed);
		// instead of scrollSpeed, PlayState.SONG.speed

		alpha = Alpha; // setting alpha calls updateColorTransform(), which initializes processedGraphic!

		updateClipping();
		indices = new DrawData<Int>(12, true, [0, 1, 2, 2, 3, 0, 4, 5, 6, 6, 7, 4]);
	}

	/**
	 * Calculates height of a sustain note for a given length (milliseconds) and scroll speed.
	 * @param	susLength	The length of the sustain note in milliseconds.
	 * @param	scroll		The current scroll speed.
	 */
	public static inline function sustainHeight(susLength:Float, scroll:Float)
	{
		return (susLength * 0.45 * scroll);
	}

	function set_zoom(z:Float)
	{
		this.zoom = z;
		width = graphic.width / 8 * z;
		updateClipping();
		return this.zoom;
	}

	function set_sustainLength(s:Float)
	{
		height = sustainHeight(s, scrollSpeed);
		return sustainLength = s;
	}

	function set_scrollSpeed(s:Float)
	{
		height = sustainHeight(sustainLength, s);
		return scrollSpeed = s;
	}

	/**
	 * Sets up new vertex and UV data to clip the trail.
	 * If flipY is true, top and bottom bounds swap places.
	 * @param songTime	The time to clip the note at, in milliseconds.
	 */
	public function updateClipping(songTime:Float = 0):Void
	{
		var clipHeight:Float = FlxMath.bound(sustainHeight(sustainLength - (songTime - strumTime), scrollSpeed), 0, height);
		if (clipHeight == 0)
		{
			visible = false;
			return;
		}
		else
			visible = true;
		var bottomHeight:Float = graphic.height * zoom * endOffset;
		var partHeight:Float = clipHeight - bottomHeight;
		// == HOLD == //
		// left bound
		vertices[6] = vertices[0] = 0.0;
		// top bound
		vertices[3] = vertices[1] = flipY ? clipHeight : height - clipHeight;
		// right bound
		vertices[4] = vertices[2] = width;
		// bottom bound (also top bound for hold ends)
		if (partHeight > 0)
			vertices[7] = vertices[5] = flipY ? 0.0 + bottomHeight : vertices[1] + partHeight;
		else
			vertices[7] = vertices[5] = vertices[1];

		// same shit with da bounds, just in relation to the texture
		uvtData[6] = uvtData[0] = 1 / 4 * (noteData % 4);
		// height overflows past image bounds so wraps around, looping the texture
		// flipY bounds are not swapped for UV data, so the graphic is actually flipped
		// top bound
		uvtData[3] = uvtData[1] = (-partHeight) / graphic.height / zoom;
		uvtData[4] = uvtData[2] = uvtData[0] + 1 / 8; // 1
		// bottom bound
		uvtData[7] = uvtData[5] = 0.0;

		// == HOLD ENDS == //
		// left bound
		vertices[14] = vertices[8] = vertices[0];
		// top bound
		vertices[11] = vertices[9] = vertices[5];
		// right bound
		vertices[12] = vertices[10] = vertices[2];
		// bottom bound, mind the bottomClip because it clips off bottom of graphic!!
		vertices[15] = vertices[13] = flipY ? graphic.height * (-bottomClip + endOffset) : height + graphic.height * (bottomClip - endOffset);

		uvtData[14] = uvtData[8] = uvtData[2];
		if (partHeight > 0)
			uvtData[11] = uvtData[9] = 0.0;
		else
			uvtData[11] = uvtData[9] = (bottomHeight - clipHeight) / zoom / graphic.height;
		uvtData[12] = uvtData[10] = uvtData[8] + 1 / 8;
		// again, clips off bottom !!
		uvtData[15] = uvtData[13] = bottomClip;
	}

	@:access(flixel.FlxCamera)
	override public function draw():Void
	{
		if (alpha == 0 || graphic == null || vertices == null)
			return;

		for (camera in cameras)
		{
			if (!camera.visible || !camera.exists || !isOnScreen(camera))
				continue;

			getScreenPosition(_point, camera).subtractPoint(offset);
			camera.drawTriangles(processedGraphic, vertices, indices, uvtData, null, _point, blend, true, antialiasing);
		}
	}

	override public function destroy():Void
	{
		vertices = null;
		indices = null;
		uvtData = null;
		processedGraphic.destroy();

		super.destroy();
	}

	override function updateColorTransform():Void
	{
		super.updateColorTransform();
		if (processedGraphic != null)
			processedGraphic.destroy();
		processedGraphic = FlxGraphic.fromGraphic(graphic, true);
		processedGraphic.bitmap.colorTransform(processedGraphic.bitmap.rect, colorTransform);
	}
}
