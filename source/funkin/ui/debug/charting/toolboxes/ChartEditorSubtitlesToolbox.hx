package funkin.ui.debug.charting.toolboxes;

#if FEATURE_CHART_EDITOR
import haxe.ui.containers.dialogs.CollapsibleDialog;

import funkin.util.SRTUtil.SubtitleEntry;
import funkin.ui.debug.charting.util.ChartEditorDropdowns;
import haxe.ui.components.NumberStepper;
import haxe.ui.components.DropDown;
import haxe.ui.components.TextField;
import haxe.ui.components.Button;
import haxe.ui.events.UIEvent;


/**
 * The toolbox which allows for viewing and editing subtitles in editor.
 */
// @:nullSafety // TODO: Fix null safety when used with HaxeUI build macros.
@:access(funkin.ui.debug.charting.ChartEditorState)
@:build(haxe.ui.ComponentBuilder.build("assets/exclude/ui/editors/chart-editor/toolboxes/subtitles.xml"))
class ChartEditorSubtitlesToolbox extends ChartEditorBaseToolbox
{
  var inputSubtitle:DropDown;
  var inputStartTimeStamp:NumberStepper;
  var inputEndTimeStamp:NumberStepper;
  var inputSubtitleText:TextField;
  var subtitleDropdownItemRenderer:haxe.ui.core.ItemRenderer;
  var createSubtitle:Button;
  var removeSubtitle:Button;
  var saveSubtitles:Button;
  var loadSubtitles:Button;

  var populateinputSubtitleDropDown:Bool = true;

  private function new(chartEditorState2:ChartEditorState)
  {
    super(chartEditorState2);

    subtitleDropdownItemRenderer = inputSubtitle.findComponent(haxe.ui.core.ItemRenderer);

    initialize();

    this.onDialogClosed = onClose;
  }

  function onClose(event:UIEvent)
  {
    chartEditorState.menubarItemToggleToolboxSubtitles.selected = false;
  }

  function initialize():Void
  {

    inputSubtitle.onChange = function(event:UIEvent)
    {
      populateinputSubtitleDropDown = false;

      refresh();

      populateinputSubtitleDropDown = true;
    }

    var startingSubtitle = ChartEditorDropdowns.populateDropdownWithSubtitles(inputSubtitle, chartEditorState.currentSongSubtitles.data);
    inputSubtitle.value = startingSubtitle;

    inputStartTimeStamp.onChange = function(event:UIEvent) {
      if (event.value == null || event.value <= 0) return;

      var currentSubtitle = chartEditorState.currentSongSubtitles.data[inputSubtitle.selectedIndex];
      var currentStartTimeStamp = currentSubtitle.start;
      if (event.value != currentStartTimeStamp) {
        chartEditorState.currentSongSubtitles.data[inputSubtitle.selectedIndex].start = event.value;
        reloadSubtitles();
      }
    }

    inputEndTimeStamp.onChange = function(event:UIEvent) {
      if (event.value == null || event.value <= 0) return;

      var currentSubtitle = chartEditorState.currentSongSubtitles.data[inputSubtitle.selectedIndex];
      var currentEndTimeStamp = currentSubtitle.end;
      if (event.value != currentEndTimeStamp) {
        chartEditorState.currentSongSubtitles.data[inputSubtitle.selectedIndex].end = event.value;
        reloadSubtitles();
      }
    }

    inputSubtitleText.onChange = function(event:UIEvent) {
      var valid:Bool = event.target.text != null && event.target.text != '';

      var currentSubtitle = chartEditorState.currentSongSubtitles.data[inputSubtitle.selectedIndex];
      var currentText = currentSubtitle.text;
      if (event.value != currentText)
      {
        chartEditorState.currentSongSubtitles.data[inputSubtitle.selectedIndex].text = event.target.text;
        reloadSubtitles();
      }
    }

    createSubtitle.onClick = function(_:UIEvent) {

      var startTimeStamp = chartEditorState.scrollPositionInMs + chartEditorState.playheadPositionInMs;

      chartEditorState.currentSongSubtitles.data.insert(inputSubtitle.selectedIndex,
        new SubtitleEntry(inputSubtitle.selectedIndex + 1, startTimeStamp, startTimeStamp + 3000, 'Subtitle'));

      if (
        inputSubtitle.selectedIndex
        + 1 != chartEditorState.currentSongSubtitles.data.length - 1
      ) for (index in inputSubtitle.selectedIndex + 1...chartEditorState.currentSongSubtitles.data.length - 1)
      {
        chartEditorState.currentSongSubtitles.data[index].id += 1;
      }

      refreshSubtitles(inputSubtitle.selectedIndex);
      reloadSubtitles();
    }

    removeSubtitle.onClick = function(_:UIEvent) {

      chartEditorState.currentSongSubtitles.data.splice(inputSubtitle.selectedIndex, 1);

      if (
        inputSubtitle.selectedIndex != chartEditorState.currentSongSubtitles.data.length
          - 1
      ) for (index in inputSubtitle.selectedIndex...chartEditorState.currentSongSubtitles.data.length - 1)
      {
        chartEditorState.currentSongSubtitles.data[index].id -= 1;
      }

      refreshSubtitles(inputSubtitle.selectedIndex);
      reloadSubtitles();
    }

    saveSubtitles.onClick = function(_:UIEvent) {}

    loadSubtitles.onClick = function(_:UIEvent) {}

  }

  public function refreshSubtitles(startingSubtitlesIndex:Int = 0):Void
  {
    var startingSubtitle = ChartEditorDropdowns.populateDropdownWithSubtitles(inputSubtitle, chartEditorState.currentSongSubtitles.data);
    inputSubtitle.selectedIndex = Std.parseInt(startingSubtitle.id);
    inputSubtitle.value = startingSubtitle;
  }

  // Reload the visible subtitles.
  private function reloadSubtitles()
  {
    chartEditorState.loadSubtitles(chartEditorState.currentSongSubtitles, false);
  }

  public override function refresh()
  {
    if (populateinputSubtitleDropDown) refreshSubtitles();
    var currentSubtitle = chartEditorState.currentSongSubtitles.data[inputSubtitle.selectedIndex];
    if (currentSubtitle == null)
    {
      inputStartTimeStamp.value = chartEditorState.currentSongSubtitles.data[0].start;
      inputEndTimeStamp.value = chartEditorState.currentSongSubtitles.data[0].end;
      inputSubtitleText.value = chartEditorState.currentSongSubtitles.data[0].text;
    }
    else
    {
      inputStartTimeStamp.value = currentSubtitle.start;
      inputEndTimeStamp.value = currentSubtitle.end;
      inputSubtitleText.value = currentSubtitle.text;
    }
  }

  public static function build(chartEditorState:ChartEditorState):ChartEditorSubtitlesToolbox
  {
    return new ChartEditorSubtitlesToolbox(chartEditorState);
  }
}
#end
