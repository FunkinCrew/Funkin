package funkin.ui.debug.charting;

import flixel.FlxObject;
import flixel.FlxBasic;
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
	public var parentState:ChartEditorState;

	/**
	 * The note data that this sprite represents.
	 * You can set this to null to kill the sprite and flag it for recycling.
	 */
	public var noteData(default, set):SongNoteData;

	/**
	 * This note is the previous sprite in a sustain chain.
	 */
	public var parentNoteSprite(default, set):ChartEditorNoteSprite = null;

	/**
	 * This note is the next sprite in a sustain chain.
	 */
	public var childNoteSprite(default, set):ChartEditorNoteSprite = null;

	public function new(parent:ChartEditorState)
	{
		super();

		this.parentState = parent;

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

		this.animation.addByPrefix('holdLeftNormal', 'LeftHoldPiece');
		this.animation.addByPrefix('holdDownNormal', 'DownHoldPiece');
		this.animation.addByPrefix('holdUpNormal', 'UpHoldPiece');
		this.animation.addByPrefix('holdRightNormal', 'RightHoldPiece');

		this.animation.addByPrefix('holdEndLeftNormal', 'LeftHoldEnd');
		this.animation.addByPrefix('holdEndDownNormal', 'DownHoldEnd');
		this.animation.addByPrefix('holdEndUpNormal', 'UpHoldEnd');
		this.animation.addByPrefix('holdEndRightNormal', 'RightHoldEnd');

		this.animation.addByPrefix('tapLeftPixel', 'pixel4');
		this.animation.addByPrefix('tapDownPixel', 'pixel5');
		this.animation.addByPrefix('tapUpPixel', 'pixel6');
		this.animation.addByPrefix('tapRightPixel', 'pixel7');
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
		var frameCollectionNormal2 = Paths.getSparrowAtlas('NoteHoldNormal');

		for (frame in frameCollectionNormal2.frames)
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
			// Disown parent.
			this.parentNoteSprite = null;
			if (this.childNoteSprite != null)
			{
				// Kill all children and disown them.
				this.childNoteSprite.noteData = null;
				this.childNoteSprite = null;
			}
			this.kill();
			return this.noteData;
		}

		this.visible = true;

		// Update the animation to match the note data.
		// Animation is updated first so size is correct before updating position.
		playNoteAnimation();

		// Update the position to match the note data.
		updateNotePosition();

		return this.noteData;
	}

	public function updateNotePosition(?origin:FlxObject)
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

		if (parentNoteSprite == null)
		{
			this.x = cursorColumn * ChartEditorState.GRID_SIZE;

			// Notes far in the song will start far down, but the group they belong to will have a high negative offset.
			// TODO: stepTime doesn't account for fluctuating BPMs.
			if (this.noteData.stepTime >= 0)
				this.y = this.noteData.stepTime * ChartEditorState.GRID_SIZE;

			if (origin != null) {
				this.x += origin.x;
				this.y += origin.y;
			}
		}
		else
		{
			// If this is a hold note, we need to adjust the position to be centered.
			if (parentNoteSprite.parentNoteSprite == null)
			{
				this.x = parentNoteSprite.x;
				this.x += (ChartEditorState.GRID_SIZE / 2);
				this.x -= this.width / 2;
			}
			else
			{
				this.x = parentNoteSprite.x;
			}

			this.y = parentNoteSprite.y;
			if (parentNoteSprite.parentNoteSprite == null)
			{
				this.y += parentNoteSprite.height / 2;
			}
			else
			{
				this.y += parentNoteSprite.height - 1;
			}
		}
	}

	function set_parentNoteSprite(value:ChartEditorNoteSprite):ChartEditorNoteSprite
	{
		this.parentNoteSprite = value;

		if (this.parentNoteSprite != null)
		{
			this.noteData = this.parentNoteSprite.noteData;
		}

		return this.parentNoteSprite;
	}

	function set_childNoteSprite(value:ChartEditorNoteSprite):ChartEditorNoteSprite
	{
		this.childNoteSprite = value;

		if (this.parentNoteSprite != null)
		{
			this.noteData = this.parentNoteSprite.noteData;
		}

		return this.childNoteSprite;
	}

	public function playNoteAnimation()
	{
		// Decide whether to display a note or a sustain.
		var baseAnimationName:String = 'tap';
		if (this.parentNoteSprite != null)
			baseAnimationName = (this.childNoteSprite != null) ? 'hold' : 'holdEnd';

		// Play the appropriate animation for the type, direction, and skin.
		var animationName = '${baseAnimationName}${this.noteData.getDirectionName()}${this.parentState.currentSongNoteSkin}';

		this.animation.play(animationName);

		// Resize note.

		switch (baseAnimationName)
		{
			case 'tap':
				this.setGraphicSize(0, ChartEditorState.GRID_SIZE);
			case 'hold':
				if (parentNoteSprite.parentNoteSprite == null)
				{
					this.setGraphicSize(Std.int(ChartEditorState.GRID_SIZE / 2), Std.int(ChartEditorState.GRID_SIZE / 2));
				}
				else
				{
					this.setGraphicSize(Std.int(ChartEditorState.GRID_SIZE / 2), ChartEditorState.GRID_SIZE);
				}
			case 'holdEnd':
				this.setGraphicSize(Std.int(ChartEditorState.GRID_SIZE / 2), Std.int(ChartEditorState.GRID_SIZE / 2));
		}
		this.updateHitbox();

		// TODO: Make this an attribute of the note skin.
		this.antialiasing = (this.parentState.currentSongNoteSkin != 'Pixel');
	}

	/**
	 * Return whether this note (or its parent) is currently visible.
	 */
	public function isNoteVisible(viewAreaBottom:Float, viewAreaTop:Float):Bool
	{
		var outsideViewArea = (this.y + this.height < viewAreaTop || this.y > viewAreaBottom);

		if (!outsideViewArea)
		{
			return true;
		}

		// TODO: Check if this note's parent or child is visible.

		return false;
	}

	public function getBaseNoteSprite()
	{
		if (this.parentNoteSprite == null)
			return this;
		else
			return this.parentNoteSprite;
	}
}
