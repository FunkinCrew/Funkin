package funkin.ui.debug.charting.toolboxes;

#if FEATURE_CHART_EDITOR
import funkin.data.song.SongData.SongTimeChange;
import funkin.ui.debug.charting.commands.timing.AddNewTimeChangeCommand;
import funkin.ui.debug.charting.commands.timing.ModifyTimeChangeCommand;
import funkin.ui.debug.charting.commands.timing.RemoveTimeChangeCommand;
import funkin.ui.debug.charting.handlers.ui.ChartEditorContextMenuHandler;
import haxe.ui.components.DropDown;
import haxe.ui.components.Label;
import haxe.ui.components.NumberStepper;
import haxe.ui.containers.Frame;
import haxe.ui.containers.HBox;
import haxe.ui.containers.VBox;
import haxe.ui.containers.menus.Menu;
import haxe.ui.containers.menus.MenuItem;
import haxe.ui.containers.menus.MenuSeparator;
import haxe.ui.events.MouseEvent;
import haxe.ui.events.UIEvent;

/**
 * The toolbox which lists the song's time changes.
 */
// @:nullSafety // TODO: Fix null safety when used with HaxeUI build macros.
@:access(funkin.ui.debug.charting.ChartEditorState)
@:build(haxe.ui.ComponentBuilder.build('assets/exclude/ui/editors/chart-editor/toolboxes/timing.xml'))
class ChartEditorTimingToolbox extends ChartEditorBaseToolbox implements ChartEditorListKeyTarget
{
  static final ROW_STYLE:String = 'padding: 4px; padding-left: 8px; background-opacity: 0;';
  static final SELECTED_STYLE:String = 'background-color: #3C8DF0; background-opacity: 0.45;';
  static final HOVER_STYLE:String = 'background-color: #888888; background-opacity: 0.2;';
  static final DIM_STYLE:String = 'color: #888888;';

  /**
   * How far the start of a time change moves per click of its stepper, in beats.
   */
  static final BEAT_STEP:Float = 1 / Constants.STEPS_PER_BEAT;

  /**
   * The choices in the beat note dropdown, in order.
   */
  static final DENOMINATORS:Array<Int> = [2, 4, 8, 16];

  var timingToolboxRows:VBox;
  var timingToolboxDetails:Frame;
  var timingInputBPM:NumberStepper;
  var timingLabelStart:Label;
  var timingInputStart:NumberStepper;
  var timingInputNumerator:NumberStepper;
  var timingInputDenominator:DropDown;

  /**
   * The index of the time change being edited.
   */
  var selectedIndex:Int = 0;

  /**
   * Set while the inputs are being filled in, so that doesn't count as an edit.
   */
  var refreshing:Bool = false;

  /**
   * The row for each time change (for rebuilding)
   */
  var rowViews:Array<{row:HBox, name:Label, time:Label, info:Label}> = [];

  var addRow:Null<HBox> = null;
  var hoveredRow:Null<HBox> = null;

  public function new(chartEditorState2:ChartEditorState)
  {
    super(chartEditorState2);

    this.onDialogClosed = onClose;

    timingToolboxRows.registerEvent(MouseEvent.MOUSE_MOVE, function(event:MouseEvent)
    {
      updateHover(event.screenX, event.screenY);
    });
    timingToolboxRows.registerEvent(MouseEvent.MOUSE_OUT, function(_)
    {
      updateHover(null, null);
    });

    initializeInputs();
    refresh();
  }

  function onClose(event:UIEvent)
  {
    chartEditorState.menubarItemToggleToolboxTiming.selected = false;
    chartEditorState.timeChangeItems.clearSelection();
  }

  var timeChanges(get, never):Array<SongTimeChange>;

  function get_timeChanges():Array<SongTimeChange>
  {
    return chartEditorState.currentSongMetadata.timeChanges;
  }

  function initializeInputs():Void
  {
    timingInputBPM.onChange = function(event:UIEvent)
    {
      if (refreshing || event.value == null || event.value <= 0) return;
      var timeChange:Null<SongTimeChange> = timeChanges[selectedIndex];
      if (timeChange == null || event.value == timeChange.bpm) return;
      modify(timeChange.timeStamp, event.value, timeChange.timeSignatureNum, timeChange.timeSignatureDen);
    };

    timingInputStart.onChange = function(event:UIEvent)
    {
      if (refreshing || event.value == null || selectedIndex == 0) return;
      var timeChange:Null<SongTimeChange> = timeChanges[selectedIndex];
      if (timeChange == null) return;
      var shown:Float = Math.max(timingInputStart.min, Math.min(timingInputStart.max, msToBeats(timeChange.timeStamp, selectedIndex)));
      if (Math.abs(event.value - shown) < BEAT_STEP / 2) return;
      // The stepper works in beats, the metadata keeps milliseconds.
      var targetTimeStamp:Float = beatsToMs(event.value, selectedIndex);
      if (Math.abs(targetTimeStamp - timeChange.timeStamp) <= 0.0001) return;
      modify(targetTimeStamp, timeChange.bpm, timeChange.timeSignatureNum, timeChange.timeSignatureDen);
    };

    timingInputNumerator.onChange = function(event:UIEvent)
    {
      if (refreshing || event.value == null) return;
      var timeChange:Null<SongTimeChange> = timeChanges[selectedIndex];
      var numerator:Int = Std.int(event.value);
      if (timeChange == null || numerator < 1 || numerator == timeChange.timeSignatureNum) return;
      modify(timeChange.timeStamp, timeChange.bpm, numerator, timeChange.timeSignatureDen);
    };

    timingInputDenominator.onChange = function(event:UIEvent)
    {
      if (refreshing) return;
      var denominator:Null<Int> = Std.parseInt(event?.data?.text);
      var timeChange:Null<SongTimeChange> = timeChanges[selectedIndex];
      if (timeChange == null || denominator == null || denominator == timeChange.timeSignatureDen) return;
      modify(timeChange.timeStamp, timeChange.bpm, timeChange.timeSignatureNum, denominator);
    };
  }

  function modify(timeStamp:Float, bpm:Float, numerator:Int, denominator:Int):Void
  {
    chartEditorState.performCommand(new ModifyTimeChangeCommand(selectedIndex, timeStamp, bpm, numerator, denominator));
  }

  /**
   * Rebuild the list and select the given time change.
   */
  public function refreshTimeChanges(index:Int = 0):Void
  {
    selectedIndex = index;
    refresh();

    chartEditorState.timeChangeItems.selectIndex(selectedIndex, false, false);
    chartEditorState.updateSongTime();
  }

  /**
   * Update the list and inputs after the selected time change was edited.
   */
  public function refreshTimeChangeInputs(updateList:Bool = true):Void
  {
    refresh();
  }

  override public function refresh():Void
  {
    super.refresh();

    if (timeChanges.length == 0) return;
    if (selectedIndex >= timeChanges.length) selectedIndex = timeChanges.length - 1;
    if (selectedIndex < 0) selectedIndex = 0;

    if (rowViews.length != timeChanges.length) rebuildList();
    else
      updateRows();
    refreshInputs();
  }

  function rebuildList():Void
  {
    timingToolboxRows.removeAllComponents();
    rowViews = [];
    hoveredRow = null;

    for (index in 0...timeChanges.length)
    {
      var row:HBox = makeRow();
      var name:Label = new Label();
      row.addComponent(name);
      var time:Label = new Label();
      time.styleString = DIM_STYLE;
      time.percentWidth = 100;
      row.addComponent(time);
      var info:Label = new Label();
      row.addComponent(info);

      row.onClick = _ ->
      {
        chartEditorState.listKeyTarget = this;
        select(index);
      };
      row.onDblClick = _ -> { jumpTo(index); };
      row.onRightClick = _ ->
      {
        chartEditorState.listKeyTarget = this;
        openRowMenu(index);
      };
      timingToolboxRows.addComponent(row);
      rowViews.push({row: row, name: name, time: time, info: info});
    }

    var add:HBox = makeRow();
    var addLabel:Label = new Label();
    addLabel.text = '+ Add time change at playhead';
    addLabel.styleString = DIM_STYLE;
    add.addComponent(addLabel);
    add.onClick = _ -> { addAtPlayhead(); };
    timingToolboxRows.addComponent(add);
    addRow = add;

    updateRows();
  }

  /**
   * Fill in each row's text and highlight, only touching what changed.
   */
  function updateRows():Void
  {
    for (index in 0...rowViews.length)
    {
      var view = rowViews[index];
      var timeChange:SongTimeChange = timeChanges[index];
      setText(view.name, 'Beat ${formatNumber(timeChange.beatTime)}');
      setText(view.time, formatTime(timeChange.timeStamp));
      setText(view.info, '${formatNumber(timeChange.bpm)} BPM, ${timeChange.timeSignatureNum}/${timeChange.timeSignatureDen}');
      styleRow(view.row);
    }
    if (addRow != null) styleRow(addRow);
  }

  static function setText(label:Label, text:String):Void
  {
    if (label.text != text) label.text = text;
  }

  function makeRow():HBox
  {
    var row:HBox = new HBox();
    row.percentWidth = 100;
    row.styleString = ROW_STYLE;
    return row;
  }

  function styleRow(row:HBox):Void
  {
    var selected:Bool = selectedIndex < rowViews.length && rowViews[selectedIndex].row == row;
    var style:String = ROW_STYLE + (selected ? SELECTED_STYLE : (row == hoveredRow ? HOVER_STYLE : ''));
    if (row.styleString != style) row.styleString = style;
  }

  /**
   * Highlight the row under the mouse.
   */
  function updateHover(screenX:Null<Float>, screenY:Null<Float>):Void
  {
    var target:Null<HBox> = null;
    if (screenX != null)
    {
      for (view in rowViews)
      {
        if (view.row.hitTest(screenX, screenY))
        {
          target = view.row;
          break;
        }
      }
      if (target == null && addRow != null && addRow.hitTest(screenX, screenY)) target = addRow;
    }
    if (target == hoveredRow) return;
    var previous:Null<HBox> = hoveredRow;
    hoveredRow = target;
    if (previous != null) styleRow(previous);
    if (target != null) styleRow(target);
  }

  function refreshInputs():Void
  {
    var timeChange:Null<SongTimeChange> = timeChanges[selectedIndex];
    if (timeChange == null) return;

    refreshing = true;
    timingToolboxDetails.text = selectedIndex == 0 ? 'Song start' : 'Time change at beat ${formatNumber(timeChange.beatTime)}';
    if (timingInputBPM.value != timeChange.bpm) timingInputBPM.value = timeChange.bpm;
    if (timingInputNumerator.value != timeChange.timeSignatureNum) timingInputNumerator.value = timeChange.timeSignatureNum;
    var denominatorIndex:Int = DENOMINATORS.indexOf(timeChange.timeSignatureDen);
    if (denominatorIndex >= 0 && timingInputDenominator.selectedIndex != denominatorIndex) timingInputDenominator.selectedIndex = denominatorIndex;

    var first:Bool = selectedIndex == 0;
    timingLabelStart.hidden = first;
    timingInputStart.hidden = first;
    if (!first)
    {
      var previous:SongTimeChange = timeChanges[selectedIndex - 1];
      var next:Null<SongTimeChange> = timeChanges[selectedIndex + 1];
      var min:Float = previous.beatTime + BEAT_STEP;
      var max:Float = (next != null ? next.beatTime : msToBeats(chartEditorState.songLengthInMs, selectedIndex)) - BEAT_STEP;
      var value:Float = msToBeats(timeChange.timeStamp, selectedIndex);
      if (timingInputStart.step != BEAT_STEP) timingInputStart.step = BEAT_STEP;
      if (timingInputStart.min != min) timingInputStart.min = min;
      if (timingInputStart.max != max) timingInputStart.max = max;
      if (timingInputStart.value != value) timingInputStart.value = value;
    }
    refreshing = false;
  }

  function select(index:Int):Void
  {
    chartEditorState.timeChangeItems.selectIndex(index, false);
    if (index == selectedIndex) return;
    selectedIndex = index;
    refresh();
  }

  function jumpTo(index:Int):Void
  {
    var timeChange:Null<SongTimeChange> = timeChanges[index];
    if (timeChange == null) return;
    chartEditorState.easeToSongTimeMs(timeChange.timeStamp);
  }

  function addAtPlayhead():Void
  {
    var currentIndex:Int = timeChanges.indexOf(Conductor.instance.currentTimeChange);
    if (currentIndex < 0) currentIndex = 0;
    chartEditorState.performCommand(new AddNewTimeChangeCommand(currentIndex, chartEditorState.scrollPositionInMs + chartEditorState.playheadPositionInMs));
  }

  function removeTimeChange(index:Int):Void
  {
    if (index <= 0 || index >= timeChanges.length) return;
    chartEditorState.performCommand(new RemoveTimeChangeCommand(index));
  }

  function openRowMenu(index:Int):Void
  {
    select(index);

    var menu:Menu = new Menu();
    menu.left = FlxG.mouse.viewX;
    menu.top = FlxG.mouse.viewY;
    addMenuItem(menu, 'Jump to', () -> jumpTo(index));
    addMenuItem(menu, 'Add time change at playhead', () -> addAtPlayhead());
    menu.addComponent(new MenuSeparator());
    var deleteItem:MenuItem = addMenuItem(menu, 'Delete', () -> removeTimeChange(index));
    deleteItem.disabled = index == 0;
    ChartEditorContextMenuHandler.openCustomContextMenu(chartEditorState, menu);
  }

  function addMenuItem(menu:Menu, text:String, action:Void->Void):MenuItem
  {
    var item:MenuItem = new MenuItem();
    item.text = text;
    item.onClick = _ -> { action(); };
    menu.addComponent(item);
    return item;
  }

  /**
   * How long a beat lasts under the given time change, in milliseconds.
   */
  static function beatLengthMs(timeChange:SongTimeChange):Float
  {
    return ((Constants.SECS_PER_MIN / timeChange.bpm) * Constants.MS_PER_SEC) * (4 / timeChange.timeSignatureDen);
  }

  /**
   * Converts a time change's start from milliseconds to beats.
   */
  function msToBeats(ms:Float, index:Int):Float
  {
    var previous:Null<SongTimeChange> = timeChanges[index - 1];
    if (previous == null) return Conductor.instance.getTimeInSteps(ms) / Constants.STEPS_PER_BEAT;
    return previous.beatTime + (ms - previous.timeStamp) / beatLengthMs(previous);
  }

  /**
   * Converts a time change's start from beats back to the milliseconds the metadata stores.
   */
  function beatsToMs(beats:Float, index:Int):Float
  {
    var previous:Null<SongTimeChange> = timeChanges[index - 1];
    if (previous == null) return Conductor.instance.getBeatTimeInMs(beats);
    return previous.timeStamp + (beats - previous.beatTime) * beatLengthMs(previous);
  }

  static function formatNumber(value:Float):String
  {
    var rounded:Float = Math.round(value * 1000) / 1000;
    return '$rounded';
  }

  static function formatTime(ms:Float):String
  {
    var totalSeconds:Float = Math.max(0, ms) / Constants.MS_PER_SEC;
    var minutes:Int = Std.int(totalSeconds / 60);
    var seconds:Float = totalSeconds - minutes * 60;
    var secondsText:String = '${Math.floor(seconds * 1000) / 1000}';
    if (seconds < 10) secondsText = '0$secondsText';
    return '$minutes:$secondsText';
  }

  /**
   * The BPM and time signature copied with Ctrl+C.
   */
  static var copiedTimeChange:Null<{bpm:Float, numerator:Int, denominator:Int}> = null;

  public function containsMouse():Bool
  {
    return hitTest(FlxG.mouse.viewX, FlxG.mouse.viewY);
  }

  public function isListShown():Bool
  {
    return haxe.ui.core.Screen.instance.rootComponents.contains(this) && !hidden;
  }

  public function copySelection():Void
  {
    var timeChange:Null<SongTimeChange> = timeChanges[selectedIndex];
    if (timeChange == null) return;
    copiedTimeChange = {bpm: timeChange.bpm, numerator: timeChange.timeSignatureNum, denominator: timeChange.timeSignatureDen};
    chartEditorState.success('Copied Time Change', '${formatNumber(timeChange.bpm)} BPM, ${timeChange.timeSignatureNum}/${timeChange.timeSignatureDen}');
  }

  /**
   * Add a time change at the playhead with the copied BPM and time signature.
   */
  public function pasteSelection():Void
  {
    var copied = copiedTimeChange;
    if (copied == null) return;
    var count:Int = timeChanges.length;
    addAtPlayhead();
    if (timeChanges.length == count) return;
    modify(timeChanges[selectedIndex].timeStamp, copied.bpm, copied.numerator, copied.denominator);
  }

  public function deleteSelection():Void
  {
    removeTimeChange(selectedIndex);
  }

  public static function build(chartEditorState:ChartEditorState):ChartEditorTimingToolbox
  {
    return new ChartEditorTimingToolbox(chartEditorState);
  }
}
#end
