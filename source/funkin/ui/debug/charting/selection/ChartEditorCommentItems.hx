package funkin.ui.debug.charting.selection;

#if FEATURE_CHART_EDITOR
import funkin.data.song.SongData.CommentData;
import funkin.ui.debug.charting.commands.comments.AddCommentCommand;
import funkin.ui.debug.charting.commands.comments.MoveCommentsCommand;
import funkin.ui.debug.charting.commands.comments.RemoveCommentCommand;
import funkin.ui.debug.charting.components.comments.ChartEditorCommentPanel;

/**
 * The comment panels right of the grid. The header picks and drags, the text box picks and types.
 */
@:access(funkin.ui.debug.charting.ChartEditorState)
class ChartEditorCommentItems extends ChartEditorSelectableItems<CommentData>
{
  /**
   * The last copied comments, with times relative to the first one.
   */
  var copied:Array<CommentData> = [];

  /**
   * The comments whose panels are open. The rest show only their header.
   */
  var expanded:Array<CommentData> = [];

  public function isExpanded(comment:CommentData):Bool
  {
    return expanded.contains(comment);
  }

  /**
   * Open or close a comment's panel.
   */
  public function toggleExpanded(comment:CommentData):Void
  {
    if (!expanded.remove(comment)) expanded.push(comment);
    for (panel in state.commentPanels)
    {
      if (panel.commentData == comment) panel.expanded = isExpanded(comment);
    }
  }

  function panelUnderMouse():Null<ChartEditorCommentPanel>
  {
    for (panel in state.commentPanels)
    {
      if (!panel.hidden && panel.commentData != null && panel.hitTest(FlxG.mouse.viewX, FlxG.mouse.viewY)) return panel;
    }
    return null;
  }

  override function itemUnderMouse():Null<CommentData>
  {
    return panelUnderMouse()?.commentData;
  }

  override function canGrab(item:CommentData):Bool
  {
    var panel:Null<ChartEditorCommentPanel> = panelUnderMouse();
    return panel != null && panel.commentData == item && panel.headerContains(FlxG.mouse.viewX, FlxG.mouse.viewY);
  }

  override function itemsInBox(left:Float, right:Float, startMs:Float, endMs:Float):Array<CommentData>
  {
    // The box has to reach the panels right of the grid.
    if (right < ChartEditorCommentHandler.commentPanelX()) return [];
    return state.currentSongChartCommentData.filter(comment -> comment.time >= startMs && comment.time <= endMs);
  }

  override function getTime(item:CommentData):Float
  {
    return item.time;
  }

  override function setTimes(items:Array<CommentData>, times:Array<Float>):Void
  {
    for (i in 0...items.length)
    {
      items[i].time = times[i];
    }
    state.commentDisplayDirty = true;
  }

  override function commitMove(items:Array<CommentData>, targetTimes:Array<Float>):Void
  {
    state.performCommand(new MoveCommentsCommand(items, targetTimes));
  }

  override function onPress(item:CommentData, grabbing:Bool):Void
  {
    var panel:Null<ChartEditorCommentPanel> = panelUnderMouse();
    if (panel == null || !panel.textContains(FlxG.mouse.viewX, FlxG.mouse.viewY)) ChartEditorToolboxHandler.clearHaxeUIFocus();
  }

  /**
   * Clicking the header without dragging opens or closes the comment.
   */
  override function onClickReleased(item:CommentData, wasOnlySelection:Bool):Void
  {
    if (canGrab(item)) toggleExpanded(item);
  }

  override function onSelectionChanged():Void
  {
    state.commentDisplayDirty = true;
  }

  /**
   * Copies the picked comments, keeping how far apart they are.
   */
  override public function copySelection():Void
  {
    var picked:Array<CommentData> = sortedSelection();
    if (picked.length == 0) return;
    var start:Float = picked[0].time;
    copied = [for (comment in picked) {time: comment.time - start, text: comment.text, color: comment.color}];
    ChartEditorSelectableItems.lastCopied = this;
    state.success('Copied Comments', picked.length == 1 ? 'Copied 1 comment.' : 'Copied ${picked.length} comments.');
  }

  /**
   * Pastes the copied comments starting at the playhead, then picks them.
   */
  override public function pasteSelection():Void
  {
    if (copied.length == 0) return;
    var playheadMs:Float = state.scrollPositionInMs + state.playheadPositionInMs;
    var pasted:Array<CommentData> = [for (comment in copied) {time: playheadMs + comment.time, text: comment.text, color: comment.color}];
    state.performCommand(new AddCommentCommand(pasted[0], pasted.slice(1), true));
  }

  override public function deleteSelection():Void
  {
    var picked:Array<CommentData> = sortedSelection();
    if (picked.length == 0) return;
    state.performCommand(new RemoveCommentCommand(picked[0], picked.slice(1)));
  }

  function sortedSelection():Array<CommentData>
  {
    var picked:Array<CommentData> = selected.copy();
    picked.sort((a, b) -> a.time < b.time ? -1 : (a.time > b.time ? 1 : 0));
    return picked;
  }
}
#end
