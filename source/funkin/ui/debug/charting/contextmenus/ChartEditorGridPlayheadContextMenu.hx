package funkin.ui.debug.charting.contextmenus;

#if FEATURE_CHART_EDITOR
import haxe.ui.containers.menus.MenuItem;
import funkin.data.song.SongData.SongNoteData;
import funkin.ui.debug.charting.commands.AddNewTimeChangeCommand;
import funkin.ui.debug.charting.commands.AddLabelCommand;

@:access(funkin.ui.debug.charting.ChartEditorState)
@:build(haxe.ui.ComponentBuilder.build("assets/exclude/data/ui/chart-editor/context-menus/grid-playhead.xml"))
class ChartEditorGridPlayheadContextMenu extends ChartEditorBaseContextMenu
{
  var contextmenuAddLabel:MenuItem;
  var contextmenuAddTimeChange:MenuItem;

  public function new(chartEditorState2:ChartEditorState, xPos2:Float = 0, yPos2:Float = 0)
  {
    super(chartEditorState2, xPos2, yPos2);

    initialize();
  }

  public function initialize():Void
  {
    // NOTE: Remember to use commands here to ensure undo/redo works properly
    contextmenuAddLabel.onClick = function(_) {
      chartEditorState.performCommand(new AddLabelCommand(chartEditorState.scrollPositionInMs + chartEditorState.playheadPositionInMs));
    }

    contextmenuAddTimeChange.onClick = function(_) {
      var currentTimeChangeIndex = chartEditorState.currentSongMetadata.timeChanges.indexOf(Conductor.instance.currentTimeChange);
      chartEditorState.performCommand(new AddNewTimeChangeCommand(currentTimeChangeIndex,
        chartEditorState.scrollPositionInMs + chartEditorState.playheadPositionInMs));
      chartEditorState.success('New Time Change', '${undoHistory[undoHistory.length - 1].toString()} ms');
    }
  }
}
#end
