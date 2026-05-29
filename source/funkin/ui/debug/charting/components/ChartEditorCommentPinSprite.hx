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

    final MOUSE_CHILDREN = false;
    final MOUSE_ENABLED = true;
    final PIXEL_PERFECT = false; // DISABLE pixel perfect so scaling doesn't break hover
    FlxMouseEvent.add(this, (_) -> onMouseDown(), (_) -> onMouseUp(), (_) -> onMouseOver(), (_) -> onMouseOut(), MOUSE_CHILDREN, MOUSE_ENABLED, PIXEL_PERFECT);
  }

  /**
   * Build the texture for the pin.
   */
  function buildSprite():Void
  {
    loadTexture('ui/editors/chart-editor/comment-pin');
    this.updateHitbox();
    this.angle = 270;
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
    updateTooltipPosition();
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

    this.x = ChartEditorState.NOTE_PREVIEW_X_POS - this.height + 6;
    this.y = position - (this.height / 2);
  }

  function updateColor():Void
  {
    if (commentData == null) return;

    this.color = FlxColor.fromString(commentData.color) ?? FlxColor.RED;
  }

  function updateTooltipPosition():Void
  {
    if (commentData == null || (tooltip.tipData?.text ?? '').length == 0)
    {
      // Disable the tooltip.
      ToolTipManager.instance.unregisterTooltipRegion(tooltip);
    }
    else
    {
      // Update the position.
      tooltip.left = this.x;
      tooltip.top = this.y;
      tooltip.width = this.width;
      tooltip.height = this.height;

      // Enable the tooltip.
      ToolTipManager.instance.registerTooltipRegion(tooltip);
    }
  }

  function updateTooltipText():Void
  {
    if (commentData == null) return;
    tooltip.tipData = {
      text: commentData.text,
    };
  }

  /**
   * Called when the mouse is pressed on this sprite.
   */
  function onMouseDown():Void
  {
  }

  /**
   * Called when the mouse is released on this sprite.
   */
  function onMouseUp():Void
  {
    // Released mouse while hovering over comment,
    // click to navigate.
    if (commentData != null) chartEditorState.easeToSongTimeMs(commentData.time);
  }

  /**
   * Called when the mouse is hovered over on this sprite.
   */
  function onMouseOver():Void
  {
    trace('Mouse over comment: ${commentData?.text}');
    this.scale.set(1.2, 1.2);
    this.x = ChartEditorState.NOTE_PREVIEW_X_POS - this.height + 6 - (this.height * 0.2);
    updateTooltipPosition();
  }

  /**
   * Called when the mouse is hovered off on this sprite.
   */
  function onMouseOut():Void
  {
    trace('Mouse out comment: ${commentData?.text}');
    this.scale.set(1.0, 1.0);
    this.x = ChartEditorState.NOTE_PREVIEW_X_POS - this.height + 6;
    updateTooltipPosition();
  }

  override public function kill()
  {
    super.kill();

    // Remove the tooltip to prevent recently deleted pins from showing a tooltip.
    ToolTipManager.instance.unregisterTooltipRegion(tooltip);
  }
}
#end
