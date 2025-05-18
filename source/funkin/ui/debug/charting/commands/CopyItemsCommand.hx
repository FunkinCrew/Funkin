package funkin.ui.debug.charting.commands;

import funkin.data.song.SongData.SongNoteData;
import funkin.data.song.SongData.SongEventData;
import funkin.data.song.SongDataUtils;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;

/**
 * Command that copies a given set of notes and song events to the clipboard,
 * without deleting them from the chart editor.
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

  public function execute(state:ChartEditorState):Void
  {
    // Calculate a single time offset for all the notes and events.
    var timeOffset:Null<Int> = state.currentNoteSelection.length > 0 ? Std.int(state.currentNoteSelection[0].time) : null;
    if (state.currentEventSelection.length > 0)
    {
      if (timeOffset == null || state.currentEventSelection[0].time < timeOffset)
      {
        timeOffset = Std.int(state.currentEventSelection[0].time);
      }
    }

    SongDataUtils.writeItemsToClipboard(
      {
        notes: SongDataUtils.buildNoteClipboard(state.currentNoteSelection, timeOffset),
        events: SongDataUtils.buildEventClipboard(state.currentEventSelection, timeOffset),
      });

    performVisuals(state);
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
          FlxTween.tween(note, {"angle": 0}, 0.8, {ease: FlxEase.elasticOut});

          FlxTween.tween(note.scale, {"y": prevX, "x": prevY}, 0.7,
            {
              ease: FlxEase.elasticOut,
              onComplete: function(_) {
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
          FlxTween.tween(event, {"angle": 0}, 0.8, {ease: FlxEase.elasticOut});

          FlxTween.tween(event.scale, {"y": prevX, "x": prevY}, 0.7,
            {
              ease: FlxEase.elasticOut,
              onComplete: function(_) {
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
      FlxTween.tween(state.txtCopyNotif, {y: state.txtCopyNotif.y - 32}, 0.5,
        {
          type: FlxTweenType.ONESHOT,
          ease: FlxEase.quadOut,
          onComplete: function(_) {
            state.txtCopyNotif.visible = false;
          }
        });
    }
  }

  public function undo(state:ChartEditorState):Void
  {
    // This command is not undoable. Do nothing.
  }

  public function shouldAddToHistory(state:ChartEditorState):Bool
  {
    // This command is not undoable. Don't add it to the history.
    return false;
  }

  public function toString():String
  {
    var len:Int = notes.length + events.length;

    if (notes.length == 0) return 'Copy $len Events to Clipboard';
    else if (events.length == 0) return 'Copy $len Notes to Clipboard';
    else
      return 'Copy $len Items to Clipboard';
  }
}
