package funkin.ui.debug.charting.contextmenus;

import haxe.ui.containers.menus.MenuItem;
import haxe.ui.containers.properties.Property;
import haxe.ui.components.DropDown;
import haxe.ui.components.Label;
import haxe.ui.core.Screen;
import haxe.ui.events.UIEvent;
import funkin.data.song.SongData.SongNoteData;
import funkin.ui.debug.charting.commands.MoveNotesCommand;
import funkin.ui.debug.charting.commands.FlipNotesCommand;
import funkin.ui.debug.charting.commands.RemoveNotesCommand;
import funkin.ui.debug.charting.commands.ExtendNoteLengthCommand;

@:access(funkin.ui.debug.charting.ChartEditorState)
@:build(haxe.ui.ComponentBuilder.build("assets/exclude/data/ui/chart-editor/context-menus/note.xml"))
class ChartEditorNoteContextMenu extends ChartEditorBaseContextMenu
{
  var contextmenuNoteKind:Label;
  var contextmenuPosition:Property;
  var contextmenuUnit:DropDown;
  var contextmenuFlip:MenuItem;
  var contextmenuDelete:MenuItem;

  public var selectedUnit:Int;

  public var data:SongNoteData;

  public function new(chartEditorState2:ChartEditorState, xPos2:Float = 0, yPos2:Float = 0, data:SongNoteData, selectedUnit:Int = 0)
  {
    super(chartEditorState2, xPos2, yPos2);
    this.data = data;
    contextmenuPosition.value = data.time;
    if (data.kind == null) contextmenuNoteKind.text = 'Default';
    else
      contextmenuNoteKind.text = data.kind;
    this.selectedUnit = selectedUnit;
    contextmenuUnit.selectedIndex = selectedUnit;
    contextmenuUnit.value = contextmenuUnit.dataSource.get(contextmenuUnit.selectedIndex);

    initialize();
  }

  public function initialize():Void
  {
    if (contextmenuNoteKind.text != data.kind)
    {
      if (data.kind == null) contextmenuNoteKind.text = 'Default';
      else
        contextmenuNoteKind.text = data.kind;
    }
    // NOTE: Remember to use commands here to ensure undo/redo works properly
    contextmenuUnit.onChange = function(_) {
      // Why does the dropdown do this after I specifically set the value of the damn thing?
      if (contextmenuUnit.selectedIndex == -1)
      {
        contextmenuUnit.pauseEvent(UIEvent.CHANGE, true);
        contextmenuUnit.selectedIndex = selectedUnit;
        contextmenuUnit.resumeEvent(UIEvent.CHANGE, true, true);
      }
      switch (contextmenuUnit.value.id)
      {
        // Ugh, I hate this code. Surely there's a way to make this cleaner, right?
        case "MILLISECONDS":
          contextmenuPosition.label = "Time (MS)";
          if (contextmenuPosition.value != data.time)
          {
            contextmenuPosition.pauseEvent(UIEvent.CHANGE, true);
            contextmenuPosition.value = data.time;
            contextmenuPosition.resumeEvent(UIEvent.CHANGE, true, true);
          }

        case "STEPS":
          contextmenuPosition.label = "Time (Steps)";
          if (contextmenuPosition.value != data.getStepTime())
          {
            contextmenuPosition.pauseEvent(UIEvent.CHANGE, true);
            contextmenuPosition.value = data.getStepTime();
            contextmenuPosition.resumeEvent(UIEvent.CHANGE, true, true);
          }

        default:
          contextmenuPosition.label = "Time (MS)";
          if (contextmenuPosition.value != data.time)
          {
            contextmenuPosition.pauseEvent(UIEvent.CHANGE, true);
            contextmenuPosition.value = data.time;
            contextmenuPosition.resumeEvent(UIEvent.CHANGE, true, true);
          }
      }
    }
    var id:String = contextmenuUnit.dataSource.get(contextmenuUnit.selectedIndex).id;

    contextmenuPosition.onChange = function(_) {
      var newTime:Float = contextmenuPosition.value;
      if (contextmenuUnit.selectedIndex == -1)
      {
        contextmenuUnit.pauseEvent(UIEvent.CHANGE, true);
        contextmenuUnit.selectedIndex = selectedUnit;
        contextmenuUnit.resumeEvent(UIEvent.CHANGE, true, true);
      }
      switch (contextmenuUnit.value.id)
      {
        case "MILLISECONDS":
          // Don't move the note if we don't have to
          if (newTime != 0 && newTime != data.time)
          {
            data.time = newTime;
            chartEditorState.performCommand(new MoveNotesCommand(chartEditorState.currentNoteSelection, newTime, 0, true));
          }
        case "STEPS":
          if (newTime != 0 && newTime != data.getStepTime())
          {
            data.time = Conductor.instance.getStepTimeInMs(newTime);
            chartEditorState.performCommand(new MoveNotesCommand(chartEditorState.currentNoteSelection, newTime, 0, true, true));
          }
        default:
          if (newTime != 0 && newTime != data.time)
          {
            data.time = newTime;
            chartEditorState.performCommand(new MoveNotesCommand(chartEditorState.currentNoteSelection, newTime, 0, true));
          }
      }
    }
    // Update the value without triggering the event, though only if it's necessary
    if (id == "MILLISECONDS" && contextmenuPosition.value != data.time)
    {
      contextmenuPosition.pauseEvent(UIEvent.CHANGE, true);
      contextmenuPosition.value = data.time;
      contextmenuPosition.resumeEvent(UIEvent.CHANGE, true, true);
    }
    else if (id == "STEPS" && contextmenuPosition.value != data.getStepTime())
    {
      contextmenuPosition.pauseEvent(UIEvent.CHANGE, true);
      contextmenuPosition.value = data.getStepTime();
      contextmenuPosition.resumeEvent(UIEvent.CHANGE, true, true);
    }


    contextmenuFlip.onClick = function(_) {
      chartEditorState.performCommand(new FlipNotesCommand([data]));
    }

    contextmenuAddHold.onClick = function(_) {
      chartEditorState.performCommand(new ExtendNoteLengthCommand(data, 4, STEPS));
    }

    contextmenuDelete.onClick = function(_) {
      chartEditorState.performCommand(new RemoveNotesCommand([data]));
    }
  }
}
