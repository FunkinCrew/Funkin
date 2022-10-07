package funkin.ui.debug.charting;

import flixel.FlxSprite;
import flixel.graphics.frames.FlxFramesCollection;
import flixel.graphics.frames.FlxTileFrames;
import flixel.math.FlxPoint;
import funkin.play.song.SongData.SongNoteData;

/**
 * A note sprite that can be used to display a note in a chart.
 * Designed to be used and reused efficiently. Has no gameplay functionality.
 */
class ChartEditorNoteSprite extends FlxSprite
{
	/**
	 * The note data that this sprite represents.
	 * You can set this to null to kill the sprite and flag it for recycling.
	 */
	public var noteData(default, set):SongNoteData;

	/**
	 * The note skin that this sprite displays.
	 */
	public var noteSkin(default, set):String = 'Normal';

	public function new()
	{
		super();

		if (noteFrameCollection == null)
		{
			initFrameCollection();
		}

		this.frames = noteFrameCollection;

		// Initialize all the animations, not just the one we're going to use immediately,
		// so that later we can reuse the sprite without having to initialize more animations during scrolling.
		this.animation.addByPrefix('tapLeftNormal', 'purple instance');
		this.animation.addByPrefix('tapDownNormal', 'blue instance');
		this.animation.addByPrefix('tapUpNormal', 'green instance');
		this.animation.addByPrefix('tapRightNormal', 'red instance');

		this.animation.addByPrefix('holdLeftNormal', 'purple hold piece instance');
		this.animation.addByPrefix('holdDownNormal', 'blue hold piece instance');
		this.animation.addByPrefix('holdUpNormal', 'green hold piece instance');
		this.animation.addByPrefix('holdRightNormal', 'red hold piece instance');

		this.animation.addByPrefix('holdEndLeftNormal', 'pruple end hold instance');
		this.animation.addByPrefix('holdEndDownNormal', 'blue end hold instance');
		this.animation.addByPrefix('holdEndUpNormal', 'green end hold instance');
		this.animation.addByPrefix('holdEndRightNormal', 'red end hold instance');

		this.animation.addByPrefix('tapLeftPixel', 'pixel4');
		this.animation.addByPrefix('tapDownPixel', 'pixel5');
		this.animation.addByPrefix('tapUpPixel', 'pixel6');
		this.animation.addByPrefix('tapRightPixel', 'pixel7');

		resizeNote();
	}

	static var noteFrameCollection:FlxFramesCollection = null;

	/**
	 * We load all the note frames once, then reuse them.
	 */
	static function initFrameCollection():Void
	{
		noteFrameCollection = new FlxFramesCollection(null, ATLAS, null);

		// TODO: Automatically iterate over the list of note skins.

		// Normal notes
		var frameCollectionNormal = Paths.getSparrowAtlas('NOTE_assets');

		for (frame in frameCollectionNormal.frames)
		{
			noteFrameCollection.pushFrame(frame);
		}

		// Pixel notes
		var graphicPixel = FlxG.bitmap.add(Paths.image('weeb/pixelUI/arrows-pixels', 'week6'), false, null);
		if (graphicPixel == null)
			trace('ERROR: Could not load graphic: ' + Paths.image('weeb/pixelUI/arrows-pixels', 'week6'));
		var frameCollectionPixel = FlxTileFrames.fromGraphic(graphicPixel, new FlxPoint(17, 17));
		for (i in 0...frameCollectionPixel.frames.length)
		{
			var frame = frameCollectionPixel.frames[i];

			frame.name = 'pixel' + i;
			noteFrameCollection.pushFrame(frame);
		}
	}

	function set_noteData(value:SongNoteData):SongNoteData
	{
		this.noteData = value;

		if (this.noteData == null)
		{
			this.kill();
			return this.noteData;
		}

		this.visible = true;

		// Update the position to match the note skin.
		setNotePosition();

		// Update the animation to match the note skin.
		playNoteAnimation();

		return this.noteData;
	}

	function set_noteSkin(value:String):String
	{
		// Don't update if the skin hasn't changed.
		if (value == this.noteSkin)
			return this.noteSkin;

		this.noteSkin = value;

		// Make sure to update the graphic to match the note skin.
		playNoteAnimation();

		return this.noteSkin;
	}

	function setNotePosition()
	{
		var cursorColumn:Int = this.noteData.data;

		if (cursorColumn < 0)
			cursorColumn = 0;
		if (cursorColumn >= (ChartEditorState.STRUMLINE_SIZE * 2 + 1))
		{
			cursorColumn = (ChartEditorState.STRUMLINE_SIZE * 2 + 1);
		}
		else
		{
			// Invert player and opponent columns.
			if (cursorColumn >= ChartEditorState.STRUMLINE_SIZE)
			{
				cursorColumn -= ChartEditorState.STRUMLINE_SIZE;
			}
			else
			{
				cursorColumn += ChartEditorState.STRUMLINE_SIZE;
			}
		}
		this.x = cursorColumn * ChartEditorState.GRID_SIZE;

		// Notes far in the song will start far down, but the group they belong to will have a high negative offset.
		// TODO: stepTime doesn't account for fluctuating BPMs.
		this.y = this.noteData.stepTime * ChartEditorState.GRID_SIZE;
	}

	function playNoteAnimation()
	{
		var animationName = 'tap${this.noteData.getDirectionName()}${this.noteSkin}';
		this.animation.play(animationName);
	}

	function resizeNote()
	{
		this.setGraphicSize(ChartEditorState.GRID_SIZE);
		this.updateHitbox();

		// TODO: Make this an attribute of the note skin.
		this.antialiasing = (noteSkin != 'Pixel');
	}
}
