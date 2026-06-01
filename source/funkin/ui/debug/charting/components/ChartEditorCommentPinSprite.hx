package funkin.ui.debug.charting.components;

import funkin.util.HaxeUIUtil;
#if FEATURE_CHART_EDITOR
import flixel.FlxSprite;
import flixel.input.mouse.FlxMouseEvent;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import funkin.data.song.SongData.CommentData;
import funkin.graphics.FunkinSprite;
import haxe.ui.tooltips.ToolTipManager;
import haxe.ui.tooltips.ToolTipRegionOptions;

/**
 * A sprite that can be used to display a comment pin, to the left of the note preview.
 * Designed to be used and reused efficiently.
 */
@:nullSafety
@:access(funkin.ui.debug.charting.ChartEditorState)
class ChartEditorCommentPinSprite extends FunkinSprite
{
  /**
   * The comment data that this sprite represents.
   * You can set this to null to kill the sprite and flag it for recycling.
   */
  public var commentData(default, set):Null<CommentData> = null;

  var chartEditorState:ChartEditorState;

  public var tooltip:ToolTipRegionOptions;

  public function new(state:ChartEditorState)
  {
    super();

    this.chartEditorState = state;
    this.tooltip = HaxeUIUtil.buildTooltip('N/A');

    buildSprite();

    FlxMouseEvent.add(this, onMouseDown, onMouseUp, onMouseOver, onMouseOut);
  }

  /**
   * Build the texture for the pin.
   */
  function buildSprite():Void
  {
    loadTexture('ui/editors/chart-editor/pin-red-small');
  }

  /**
   * Called when the comment data is set.
   */
  function set_commentData(value:Null<CommentData>):Null<CommentData>
  {
    this.commentData = value;

    if (this.commentData == null)
    {
      this.kill();
      updateTooltipPosition();
      return this.commentData;
    }

    this.visible = true;

    updatePosition();
    updateTooltipText();
    updateColor();

    return this.commentData;
  }

  function updatePosition():Void
  {
    if (commentData == null) return;

    var position:Float = FlxMath.remapToRange( // Remap the comment timestamp...
      commentData.time, // ...from song time...
      0, chartEditorState.songLengthInMs, // ...to note preview position.
      ChartEditorState.NOTE_PREVIEW_Y_POS, ChartEditorState.NOTE_PREVIEW_Y_POS + (chartEditorState.notePreview?.height ?? 0.0));

    this.x = ChartEditorState.NOTE_PREVIEW_X_POS;
    this.y = position;
  }

  function updateColor():Void
  {
    if (this.commentData == null) return;

    this.color = FlxColor.fromString(this.commentData.color) ?? FlxColor.RED;
  }

  function updateTooltipPosition():Void
  {
    if (this.commentData == null || (this.tooltip.tipData?.text ?? '').length == 0)
    {
      // Disable the tooltip.
      ToolTipManager.instance.unregisterTooltipRegion(this.tooltip);
    }
    else
    {
      // Update the position.
      this.tooltip.left = this.x;
      this.tooltip.top = this.y;
      this.tooltip.width = this.width;
      this.tooltip.height = this.height;

      // Enable the tooltip.
      ToolTipManager.instance.registerTooltipRegion(this.tooltip);
    }
  }

  function updateTooltipText():Void
  {
    if (this.commentData == null) return;
    this.tooltip.tipData = {
      text: this.commentData.text,
    };
  }

  /**
   * Called when the mouse is pressed on this sprite.
   */
  function onMouseDown(_:FlxSprite):Void
  {
  }

  /**
   * Called when the mouse is released on this sprite.
   */
  function onMouseUp(_:FlxSprite):Void
  {
  }

  /**
   * Called when the mouse is hovered over on this sprite.
   */
  function onMouseOver(_:FlxSprite):Void
  {
    trace('Mouse over comment: ${this.commentData?.text}');
  }

  /**
   * Called when the mouse is hovered off on this sprite.
   */
  function onMouseOut(_:FlxSprite):Void
  {
    trace('Mouse out comment: ${this.commentData?.text}');
  }

  override public function kill()
  {
    super.kill();

    // Remove the tooltip to prevent recently deleted pins from showing a tooltip.
    ToolTipManager.instance.unregisterTooltipRegion(this.tooltip);
  }
}
#end
