package funkin.ui.debug.charting.commands.items;

#if FEATURE_CHART_EDITOR
import funkin.data.song.SongData.SongNoteData;
import funkin.data.song.SongData.SongEventData;
import funkin.data.song.SongDataUtils;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import funkin.data.song.SongDataUtils.SongClipboardItems;
import funkin.ui.debug.charting.commands.ChartEditorCommand;
import funkin.ui.debug.charting.selection.ChartEditorSelectableItems;

/**
 * Represents a reversible action to copy the currently selected notes and events to the clipboard.
 */
@:nullSafety
@:access(funkin.ui.debug.charting.ChartEditorState)
class CopyItemsCommand implements ChartEditorCommand
{
  var notes:Array<SongNoteData>;
  var events:Array<SongEventData>;

  public function new(notes:Array<SongNoteData>, events:Array<SongEventData>)
  {
    this.notes = notes;
    this.events = events;
  }

  /**
   * Perform the action, copying the currently selected notes and events to the clipboard.
   *
   * @param state The ChartEditorState to perform the command on.
   */
  public function execute(state:ChartEditorState):Void
  {
    ChartEditorSelectableItems.lastCopied = null;
    SongDataUtils.writeItemsToClipboard(buildClipboard(state, state.currentNoteSelection, state.currentEventSelection, state.subBeatItems.selectedTimes()));

    performVisuals(state);
    state.clipboardDirty = true;
    state.clipboardValid = true;
  }

  /**
   * Build a clipboard object from the given notes, events, and sub-beats.
   */
  public static function buildClipboard(state:ChartEditorState, notes:Array<SongNoteData>, events:Array<SongEventData>,
      subBeats:Array<Float>):SongClipboardItems
  {
    var earliest:Float = Math.POSITIVE_INFINITY;
    for (note in notes) if (note.time < earliest) earliest = note.time;
    for (event in events) if (event.time < earliest) earliest = event.time;
    for (time in subBeats) if (time < earliest) earliest = time;

    var timeOffset:Float = 0;
    if (earliest != Math.POSITIVE_INFINITY)
    {
      var step:Float = Conductor.instance.getTimeInSteps(earliest);
      timeOffset = Conductor.instance.getStepTimeInMs(Math.floor(step / state.noteSnapRatio + 0.0001) * state.noteSnapRatio);
    }

    var sortedSubBeats:Array<Float> = subBeats.copy();
    sortedSubBeats.sort((a, b) -> a < b ? -1 : (a > b ? 1 : 0));
    return {
      notes: SongDataUtils.buildNoteClipboard(notes, timeOffset),
      events: SongDataUtils.buildEventClipboard(events, timeOffset),
      subBeats: [for (time in sortedSubBeats) time - timeOffset]
    };
  }

  function performVisuals(state:ChartEditorState):Void
  {
    var hasNotes:Bool = false;
    var hasEvents:Bool = false;

    // Wiggle copied notes.
    if (state.currentNoteSelection.length > 0)
    {
      hasNotes = true;

      for (note in state.renderedNotes.members)
      {
        if (state.isNoteSelected(note.noteData))
        {
          FlxTween.globalManager.cancelTweensOf(note);
          FlxTween.globalManager.cancelTweensOf(note.scale);
          note.playNoteAnimation();
          var prevX:Float = note.scale.x;
          var prevY:Float = note.scale.y;

          note.scale.x *= 1.2;
          note.scale.y *= 1.2;

          note.angle = FlxG.random.bool() ? -10 : 10;
          FlxTween.tween(note, {
            'angle': 0
          }, 0.8, {
            ease: FlxEase.elasticOut
          });

          FlxTween.tween(note.scale, {
            'x': prevX,
            'y': prevY
          }, 0.7, {
            ease: FlxEase.elasticOut,
            onComplete: function(_)
            {
              note.playNoteAnimation();
            }
          });
        }
      }
    }

    // Wiggle copied events.
    if (state.currentEventSelection.length > 0)
    {
      hasEvents = true;

      for (event in state.renderedEvents.members)
      {
        if (state.isEventSelected(event.eventData))
        {
          FlxTween.globalManager.cancelTweensOf(event);
          FlxTween.globalManager.cancelTweensOf(event.scale);
          event.playAnimation();
          var prevX:Float = event.scale.x;
          var prevY:Float = event.scale.y;

          event.scale.x *= 1.2;
          event.scale.y *= 1.2;

          event.angle = FlxG.random.bool() ? -10 : 10;
          FlxTween.tween(event, {
            'angle': 0
          }, 0.8, {
            ease: FlxEase.elasticOut
          });

          FlxTween.tween(event.scale, {
            'x': prevX,
            'y': prevY
          }, 0.7, {
            ease: FlxEase.elasticOut,
            onComplete: function(_)
            {
              event.playAnimation();
            }
          });
        }
      }
    }

    // Display the "Copied Notes" text.
    if ((hasNotes || hasEvents) && state.txtCopyNotif != null)
    {
      var copiedString:String = '';
      if (hasNotes)
      {
        var copiedNotes:Int = state.currentNoteSelection.length;
        copiedString += '${copiedNotes} note';
        if (copiedNotes > 1) copiedString += 's';

        if (hasEvents) copiedString += ' and ';
      }
      if (hasEvents)
      {
        var copiedEvents:Int = state.currentEventSelection.length;
        copiedString += '${state.currentEventSelection.length} event';
        if (copiedEvents > 1) copiedString += 's';
      }

      FlxTween.globalManager.cancelTweensOf(state.txtCopyNotif);

      state.txtCopyNotif.visible = true;
      state.txtCopyNotif.text = 'Copied ${copiedString} to clipboard';
      state.txtCopyNotif.x = FlxG.mouse.x - (state.txtCopyNotif.width / 2);
      state.txtCopyNotif.y = FlxG.mouse.y - 16;
      FlxTween.tween(state.txtCopyNotif, {
        y: state.txtCopyNotif.y - 32
      }, 0.5, {
        type: FlxTweenType.ONESHOT,
        ease: FlxEase.quadOut,
        onComplete: function(_)
        {
          state.txtCopyNotif.visible = false;
        }
      });
    }
  }

  /**
   * Reverse the action.
   * This function does nothing, since the command is not added to the history.
   *
   * @param state The ChartEditorState to perform the command on.
   */
  public function undo(state:ChartEditorState):Void
  {
    // This command is not undoable. Do nothing.
  }

  /**
   * Since this command is not undoable, it should not be added to the history.
   *
   * @param state The ChartEditorState to perform the command on.
   * @return Whether the command should be added to the history.
   */
  public function shouldAddToHistory(state:ChartEditorState):Bool
  {
    // This command is not undoable. Don't add it to the history.
    return false;
  }

  /**
   * Convert the action to a string. Used to display the action in the undo/redo history.
   * @return This command, as a readable string.
   */
  public function toString():String
  {
    var len:Int = notes.length + events.length;

    if (notes.length == 0)
    {
      return 'Copy $len Events to Clipboard';
    }
    else if (events.length == 0)
    {
      return 'Copy $len Notes to Clipboard';
    }
    else
    {
      return 'Copy $len Items to Clipboard';
    }
  }
}
#end
