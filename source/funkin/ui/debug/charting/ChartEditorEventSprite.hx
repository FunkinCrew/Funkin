package funkin.ui.debug.charting;

import openfl.display.BitmapData;
import openfl.utils.Assets;
import flixel.FlxObject;
import flixel.FlxBasic;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxFramesCollection;
import flixel.graphics.frames.FlxTileFrames;
import flixel.math.FlxPoint;
import funkin.play.song.SongData.SongEventData;

/**
 * A event sprite that can be used to display a song event in a chart.
 * Designed to be used and reused efficiently. Has no gameplay functionality.
 */
class ChartEditorEventSprite extends FlxSprite
{
  public var parentState:ChartEditorState;

  /**
   * The note data that this sprite represents.
   * You can set this to null to kill the sprite and flag it for recycling.
   */
  public var eventData(default, set):SongEventData;

  /**
   * The image used for all song events. Cached for performance.
   */
  static var eventSpriteBasic:BitmapData;

  public function new(parent:ChartEditorState)
  {
    super();

    this.parentState = parent;

    buildGraphic();
  }

  function buildGraphic():Void
  {
    if (eventSpriteBasic == null)
    {
      eventSpriteBasic = Assets.getBitmapData(Paths.image('ui/chart-editor/event'));
    }

    loadGraphic(eventSpriteBasic);
    setGraphicSize(ChartEditorState.GRID_SIZE);
    this.updateHitbox();
  }

  function set_eventData(value:SongEventData):SongEventData
  {
    this.eventData = value;

    if (this.eventData == null)
    {
      // Disown parent.
      this.kill();
      return this.eventData;
    }

    this.visible = true;

    // Update the position to match the note data.
    updateEventPosition();

    return this.eventData;
  }

  public function updateEventPosition(?origin:FlxObject)
  {
    this.x = (ChartEditorState.STRUMLINE_SIZE * 2 + 1 - 1) * ChartEditorState.GRID_SIZE;
    if (this.eventData.stepTime >= 0) this.y = this.eventData.stepTime * ChartEditorState.GRID_SIZE;

    if (origin != null)
    {
      this.x += origin.x;
      this.y += origin.y;
    }
  }

  /**
   * Return whether this note (or its parent) is currently visible.
   */
  public function isEventVisible(viewAreaBottom:Float, viewAreaTop:Float):Bool
  {
    var outsideViewArea = (this.y + this.height < viewAreaTop || this.y > viewAreaBottom);

    if (!outsideViewArea)
    {
      return true;
    }

    // TODO: Check if this note's parent or child is visible.

    return false;
  }
}
