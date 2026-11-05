package funkin.ui.debug.charting.handlers.chart;

#if FEATURE_CHART_EDITOR
import flixel.FlxBasic;
import flixel.FlxSprite;
import flixel.util.FlxColor;
import flixel.util.FlxSort;
import funkin.data.song.SongData.CommentData;
import funkin.data.song.SongData.SongNoteData;
import funkin.data.song.SongNoteDataUtils;
import funkin.play.notes.notekind.NoteKindManager;
import funkin.ui.debug.charting.components.comments.ChartEditorCommentPanel;
import funkin.ui.debug.charting.components.comments.ChartEditorCommentPinSprite;
import funkin.ui.debug.charting.components.notes.ChartEditorEventSprite;
import funkin.ui.debug.charting.components.notes.ChartEditorHoldNoteSprite;
import funkin.ui.debug.charting.components.notes.ChartEditorNoteSprite;
import funkin.ui.debug.charting.components.grid.ChartEditorSelectionSquareSprite;
import haxe.ui.tooltips.ToolTipManager;
using Lambda;

@:access(haxe.ui.tooltips.ToolTipManager)
@:access(funkin.audio.VoicesGroup)
@:access(funkin.ui.debug.charting.ChartEditorState)
class ChartEditorNoteDisplayHandler
{
  public static function handleNoteDisplay(state:ChartEditorState):Void
  {
    if (state.noteSnapRatio != state.eventChainSnapRatio)
    {
      state.eventChainSnapRatio = state.noteSnapRatio;
      state.noteDisplayDirty = true;
    }

    if (state.noteDisplayDirty)
    {
      if (!ChartEditorTimeScale.CONSTANT_SCROLL) state.updateGridScale(true);
      state.noteDisplayDirty = false;

      // Some optimization to cull notes -

      // Update for whether downscroll is enabled.
      state.renderedNotes.flipX = (state.isViewDownscroll);

      // Calculate the top and bottom of the view area.
      var viewAreaTopPixels:Float = ChartEditorState.MENU_BAR_HEIGHT;
      var visibleGridHeightPixels:Float = FlxG.height - ChartEditorState.MENU_BAR_HEIGHT - ChartEditorState.PLAYBAR_HEIGHT; // The area underneath the menu bar and playbar is not visible.
      var viewAreaBottomPixels:Float = viewAreaTopPixels + visibleGridHeightPixels;

      var viewAreaTopMs:Float = ChartEditorTimeScale.pixelsToMs(state.scrollPositionInPixels - visibleGridHeightPixels);
      var viewAreaBottomMs:Float = ChartEditorTimeScale.pixelsToMs(state.scrollPositionInPixels + visibleGridHeightPixels * 2);

      // One pass over the chart collects everything in range
      state.windowNoteSet.clear();
      state.windowNotes.resize(0);

      var chartNotes:Array<SongNoteData> = state.currentSongChartNoteData;
      if (state.longestHoldRevision != state.chartRevision || state.longestHoldSource != chartNotes)
      {
        state.longestHoldRevision = state.chartRevision;
        state.longestHoldSource = chartNotes;
        state.longestHoldMs = 0;
        for (noteData in chartNotes)
        {
          if (noteData != null && noteData.length > state.longestHoldMs) state.longestHoldMs = noteData.length;
        }
      }
      var firstTime:Float = viewAreaTopMs - state.longestHoldMs;
      var low:Int = 0;
      var high:Int = chartNotes.length;
      while (low < high)
      {
        var mid:Int = (low + high) >> 1;
        if (chartNotes[mid] != null && chartNotes[mid].time < firstTime) low = mid + 1;
        else
          high = mid;
      }
      for (noteIndex in low...chartNotes.length)
      {
        var noteData:SongNoteData = chartNotes[noteIndex];
        if (noteData == null) continue;
        if (noteData.time > viewAreaBottomMs) break;
        // Hold notes that started earlier but still reach into the range count too.
        if (noteData.time + Math.max(0, noteData.length) < viewAreaTopMs) continue;
        state.windowNoteSet.set(noteData, true);
        state.windowNotes.push(noteData);
      }
      state.windowEventSet.clear();
      for (eventData in state.currentSongChartEventData)
      {
        if (eventData != null && eventData.time >= viewAreaTopMs && eventData.time <= viewAreaBottomMs) state.windowEventSet.set(eventData, true);
      }
      state.selectedNoteSet.clear();
      for (noteData in state.currentNoteSelection)
        state.selectedNoteSet.set(noteData, true);
      state.selectedEventSet.clear();
      for (eventData in state.currentEventSelection)
        state.selectedEventSet.set(eventData, true);

      // Remove notes that are no longer visible and list the ones that are.
      state.displayedNoteSet.clear();
      for (noteSprite in state.renderedNotes.members)
      {
        if (noteSprite == null || noteSprite.noteData == null || !noteSprite.exists || !noteSprite.visible) continue;

        // Resolve an issue where dragging an event too far would cause it to be hidden.
        var isSelectedAndDragged = (state.dragTargetCurrentStep != 0) && state.selectedNoteSet.exists(noteSprite.noteData);

        if ((state.windowNoteSet.exists(noteSprite.noteData) && noteSprite.isNoteVisible(viewAreaBottomPixels, viewAreaTopPixels)) || isSelectedAndDragged)
        {
          // Note is already displayed and should remain displayed.
          state.displayedNoteSet.set(noteSprite.noteData, true);

          // Update the note sprite's position.
          noteSprite.updateNotePosition(state.renderedNotes);
        }
        else
        {
          // This sprite is off-screen or was deleted.
          // Kill the note sprite and recycle it.
          noteSprite.kill();
        }
      }

      state.displayedHoldNotes.clear();
      for (holdNoteSprite in state.renderedHoldNotes.members)
      {
        if (holdNoteSprite == null || holdNoteSprite.noteData == null || !holdNoteSprite.exists || !holdNoteSprite.visible) continue;

        // Fixes an issue where dragging a hold note too far would hide its sustain trail
        var isSelectedAndDragged = (state.dragTargetCurrentStep != 0) && state.selectedNoteSet.exists(holdNoteSprite.noteData);

        if (!isSelectedAndDragged && (holdNoteSprite.noteData == state.currentPlaceNoteData // Being dragged, displayed by gridGhostHoldNoteSprite instead.
          || !state.windowNoteSet.exists(holdNoteSprite.noteData) // Deleted or out of range.
          || !holdNoteSprite.isHoldNoteVisible(viewAreaBottomPixels, viewAreaTopPixels) // Off-screen.
          || holdNoteSprite.noteData.length == 0 // Also deleted.
        ))
        {
          // Kill the hold note sprite and recycle it.
          holdNoteSprite.kill();
        }
        else
        {
          state.displayedHoldNotes.set(holdNoteSprite.noteData, holdNoteSprite);
          // Update the hold note sprite's height and position.
          var holdNoteHeight = ChartEditorTimeScale.lengthToPixels(holdNoteSprite.noteData.time, holdNoteSprite.noteData.length, holdNoteSprite.noteData.getStepLength());
          holdNoteSprite.setHeightDirectly(holdNoteHeight);
          holdNoteSprite.updateHoldNotePosition(state.renderedHoldNotes);
        }
      }

      // Remove events that are no longer visible and list the ones that are.
      state.rebuildEventChains();
      state.displayedEventSet.clear();
      for (eventSprite in state.renderedEvents.members)
      {
        if (eventSprite == null || eventSprite.eventData == null || !eventSprite.exists || !eventSprite.visible) continue;

        // Resolve an issue where dragging an event too far would cause it to be hidden.
        var isSelectedAndDragged = (state.dragTargetCurrentStep != 0) && state.selectedEventSet.exists(eventSprite.eventData);

        var isChainFollower:Bool = state.eventChainFollowers.exists(eventSprite.eventData);
        if (!isChainFollower
          && ((state.windowEventSet.exists(eventSprite.eventData) && eventSprite.isEventVisible(viewAreaBottomPixels, viewAreaTopPixels)) || isSelectedAndDragged))
        {
          // Event is already displayed and should remain displayed.
          state.displayedEventSet.set(eventSprite.eventData, true);

          // Update the event sprite's position.
          eventSprite.updateEventPosition(state.renderedEvents);
          // Update the sprite's graphic. TODO: Is this inefficient?
          eventSprite.playAnimation(eventSprite.eventData.eventKind);
          eventSprite.overlappingEventDatas = state.eventChainRest.get(eventSprite.eventData) ?? [];
        }
        else
        {
          // This event was deleted.
          // Kill the event sprite and recycle it.
          eventSprite.kill();
        }
      }

      // Add notes that are now visible.
      for (noteData in state.windowNotes)
      {
        // Remember if we are already displaying this note.
        if (state.displayedNoteSet.exists(noteData)) continue;

        if (!ChartEditorNoteSprite.wouldNoteBeVisible(
          viewAreaBottomPixels,
          viewAreaTopPixels,
          noteData,
          state.renderedNotes
        )) continue; // Else, this note is visible and we need to render it!

        // Get a note sprite from the pool.
        // If we can reuse a deleted note, do so.
        // If a new note is needed, call buildNoteSprite.
        var noteSprite:ChartEditorNoteSprite = state.renderedNotes.recycle(() -> new ChartEditorNoteSprite(state));
        state.notesNeedSort = true;
        // trace('Creating new Note... (${renderedNotes.members.length})');
        noteSprite.parentState = state;

        // The note sprite handles animation playback and positioning.
        noteSprite.noteData = noteData;
        noteSprite.noteStyle = NoteKindManager.getNoteStyleId(noteData.kind, state.currentSongNoteStyle) ?? state.currentSongNoteStyle;
        noteSprite.overrideStepTime = null;
        noteSprite.overrideData = null;

        // Setting note data resets the position relative to the group!
        // If we don't update the note position AFTER setting the note data, the note will be rendered offscreen at y=5000.
        noteSprite.updateNotePosition(state.renderedNotes);

        // Add hold notes that are now visible (and not already displayed).
        if (
          noteSprite.noteData != null
          && noteSprite.noteData.length > 0
          && !state.displayedHoldNotes.exists(noteSprite.noteData)
          && noteSprite.noteData != state.currentPlaceNoteData
        )
        {
          var holdNoteSprite:ChartEditorHoldNoteSprite = state.renderedHoldNotes.recycle(() -> new ChartEditorHoldNoteSprite(state));
          state.displayedHoldNotes.set(noteSprite.noteData, holdNoteSprite);
          // trace('Creating new HoldNote... (${renderedHoldNotes.members.length})');

          var noteLengthPixels:Float = ChartEditorTimeScale.lengthToPixels(noteSprite.noteData.time, noteSprite.noteData.length, noteSprite.noteData.getStepLength());

          holdNoteSprite.noteData = noteSprite.noteData;
          holdNoteSprite.overrideStepTime = null;
          holdNoteSprite.overrideData = null;
          holdNoteSprite.noteDirection = noteSprite.noteData.getDirection();

          holdNoteSprite.setHeightDirectly(noteLengthPixels);

          holdNoteSprite.noteStyle = NoteKindManager.getNoteStyleId(noteSprite.noteData.kind, state.currentSongNoteStyle) ?? state.currentSongNoteStyle;

          holdNoteSprite.updateHoldNotePosition(state.renderedHoldNotes);
        }
      }

      // Add events that are now visible.
      for (eventData in state.currentSongChartEventData)
      {
        // Remember if we are already displaying this event.
        if (!state.windowEventSet.exists(eventData) || state.displayedEventSet.exists(eventData)) continue;
        if (state.eventChainFollowers.exists(eventData)) continue;

        if (!ChartEditorEventSprite.wouldEventBeVisible(viewAreaBottomPixels, viewAreaTopPixels, eventData, state.renderedNotes)) continue;

        // Else, this event is visible and we need to render it!

        // Get an event sprite from the pool.
        // If we can reuse a deleted event, do so.
        // If a new event is needed, call buildEventSprite.
        var eventSprite:ChartEditorEventSprite = state.renderedEvents.recycle(() -> new ChartEditorEventSprite(state), false, true);
        eventSprite.parentState = state;
        // trace('Creating new Event... (${renderedEvents.members.length})');

        if (eventData?.value != null && (eventData.getString('ease') != null && eventData.getInt('easeDir') == null))
        {
          eventData.value = state.migrateEventEaseDirectionFields(eventData.value);
        }

        // The event sprite handles animation playback and positioning.
        eventSprite.eventData = eventData;
        eventSprite.overrideStepTime = null;

        // Update the tooltip in-case there's overlapping events.
        eventSprite.overlappingEventDatas = state.eventChainRest.get(eventData) ?? [];

        // Setting event data resets position relative to the grid so we fix that.
        eventSprite.x += state.renderedEvents.x;
        eventSprite.y += state.renderedEvents.y;
      }

      // Add hold notes that have been made visible (but not their parents)
      for (noteData in state.windowNotes)
      {
        // Is the note a hold note?
        if (noteData.length <= 0) continue;

        // Is the note the one we are dragging? If so, ghostHoldNoteSprite will handle it.
        if (noteData == state.currentPlaceNoteData) continue;

        // Is the hold note rendered already?
        if (state.displayedHoldNotes.exists(noteData)) continue;

        // Is the hold note offscreen?
        if (!ChartEditorHoldNoteSprite.wouldHoldNoteBeVisible(viewAreaBottomPixels, viewAreaTopPixels, noteData, state.renderedHoldNotes)) continue;

        // Hold note should be rendered.
        var holdNoteFactory = function()
        {
          // TODO: Print some kind of warning if `renderedHoldNotes.members` is too high?
          return new ChartEditorHoldNoteSprite(state);
        }
        var holdNoteSprite:ChartEditorHoldNoteSprite = state.renderedHoldNotes.recycle(holdNoteFactory);
        state.displayedHoldNotes.set(noteData, holdNoteSprite);

        var noteLengthPixels:Float = ChartEditorTimeScale.lengthToPixels(noteData.time, noteData.length, noteData.getStepLength());

        holdNoteSprite.noteData = noteData;
        holdNoteSprite.overrideStepTime = null;
        holdNoteSprite.overrideData = null;
        holdNoteSprite.noteDirection = noteData.getDirection();
        holdNoteSprite.setHeightDirectly(noteLengthPixels);

        holdNoteSprite.noteStyle = NoteKindManager.getNoteStyleId(noteData.kind, state.currentSongNoteStyle) ?? state.currentSongNoteStyle;

        holdNoteSprite.updateHoldNotePosition(state.renderedHoldNotes);
      }

      // Destroy all existing selection squares.
      for (member in state.renderedSelectionSquares.members)
      {
        // Killing the sprite is cheap because we can recycle it.
        member.kill();
      }

      // Gather stacked notes to render later
      // No need to update it every time we scroll
      // Only when the chart actually changed, it is slow on big charts.
      if (Math.abs(state.currentScrollEase - state.scrollPositionInPixels) < .0001
        && (state.stackedNotesRevision != state.chartRevision
          || state.stackedNotesSource != state.currentSongChartNoteData
          || state.stackedNotesThreshold != ChartEditorState.stackedNoteThreshold))
      {
        state.stackedNotesRevision = state.chartRevision;
        state.stackedNotesSource = state.currentSongChartNoteData;
        state.stackedNotesThreshold = ChartEditorState.stackedNoteThreshold;
        state.currentOverlappingNotes = SongNoteDataUtils.listStackedNotes(state.currentSongChartNoteData, ChartEditorState.stackedNoteThreshold);
        state.stackedNoteSet.clear();
        for (noteData in state.currentOverlappingNotes)
          state.stackedNoteSet.set(noteData, true);
      }

      // Readd selection squares for selected notes.
      // Recycle selection squares if possible.
      for (noteSprite in state.renderedNotes.members)
      {
        if (noteSprite == null || noteSprite.noteData == null || !noteSprite.exists || !noteSprite.visible) continue;

        // TODO: Handle selection of hold notes.
        if (state.selectedNoteSet.exists(noteSprite.noteData))
        {
          var holdNoteSprite:Null<ChartEditorHoldNoteSprite> = (noteSprite.noteData.length > 0) ? state.displayedHoldNotes.get(noteSprite.noteData) : null;

          // Determine if the note is being dragged and offset the vertical position accordingly.
          if (state.dragTargetCurrentStep != 0.0)
          {
            var stepTime:Float = (noteSprite.noteData == null) ? 0.0 : noteSprite.noteData.getStepTime();
            // Update the note's "ghost" step time.
            noteSprite.overrideStepTime = (stepTime + state.dragTargetCurrentStep).clamp(0, state.lastSnappedGridStep);
            // Then reapply the note sprite's position relative to the grid.
            noteSprite.updateNotePosition(state.renderedNotes);

            // We only need to update the position of the hold note tails as we drag the note.
            if (holdNoteSprite != null)
            {
              holdNoteSprite.overrideStepTime = noteSprite.overrideStepTime;
              holdNoteSprite.updateHoldNotePosition(state.renderedHoldNotes);
            }
          }
          else
          {
            if (noteSprite.overrideStepTime != null)
            {
              // Reset the note's "ghost" step time.
              noteSprite.overrideStepTime = null;
              // Then reapply the note sprite's position relative to the grid.
              noteSprite.updateNotePosition(state.renderedNotes);

              if (holdNoteSprite != null)
              {
                holdNoteSprite.overrideStepTime = null;
                holdNoteSprite.updateHoldNotePosition(state.renderedHoldNotes);
              }
            }
          }

          // Determine if the note is being dragged and offset the horizontal position accordingly.
          if (state.dragTargetCurrentColumn != 0)
          {
            var data:Int = (noteSprite.noteData == null) ? 0 : noteSprite.noteData.data;
            // Update the note's "ghost" column.
            noteSprite.overrideData = ChartEditorNoteUtil.gridColumnToNoteData(
              (ChartEditorNoteUtil.noteDataToGridColumn(data) + state.dragTargetCurrentColumn).clamp(0, ChartEditorState.STRUMLINE_SIZE * 2 - 1)
            );
            // Then reapply the note sprite's position relative to the grid.
            noteSprite.updateNotePosition(state.renderedNotes);

            // We only need to update the position of the hold note tails as we drag the note.
            if (holdNoteSprite != null)
            {
              holdNoteSprite.overrideData = noteSprite.overrideData;
              holdNoteSprite.updateHoldNotePosition(state.renderedHoldNotes);
            }
          }
          else
          {
            if (noteSprite.overrideData != null)
            {
              // Reset the note's "ghost" column.
              noteSprite.overrideData = null;
              // Then reapply the note sprite's position relative to the grid.
              noteSprite.updateNotePosition(state.renderedNotes);

              if (holdNoteSprite != null)
              {
                holdNoteSprite.overrideData = null;
                holdNoteSprite.noteDirection = noteSprite.noteData.getDirection();
                holdNoteSprite.updateHoldNoteGraphic();
                holdNoteSprite.updateHoldNotePosition(state.renderedHoldNotes);
              }
            }
          }

          // Then, render the selection square.
          var selectionSquare:ChartEditorSelectionSquareSprite = state.renderedSelectionSquares.recycle(state.buildSelectionSquare);

          // Set the position and size (because we might be recycling one with bad values).
          selectionSquare.noteData = noteSprite.noteData;
          selectionSquare.eventData = null;
          selectionSquare.x = noteSprite.x;
          selectionSquare.y = noteSprite.y;
          selectionSquare.width = ChartEditorState.GRID_SIZE;
          selectionSquare.color = FlxColor.WHITE;
          selectionSquare.isError = false;

          var stepLength = noteSprite.noteData.getStepLength();

          selectionSquare.height = (stepLength <= 0) ? ChartEditorState.GRID_SIZE : (ChartEditorTimeScale.lengthToPixels(noteSprite.noteData.time, noteSprite.noteData.length, stepLength) + ChartEditorState.GRID_SIZE / 2);
        }
        else if (state.stackedNoteSet.exists(noteSprite.noteData))
        {
          // TODO: Maybe use another way to display these notes.
          var selectionSquare:ChartEditorSelectionSquareSprite = state.renderedSelectionSquares.recycle(state.buildSelectionSquare);

          // Set the position and size (because we might be recycling one with bad values).
          selectionSquare.noteData = noteSprite.noteData;
          selectionSquare.eventData = null;
          selectionSquare.x = noteSprite.x;
          selectionSquare.y = noteSprite.y;
          selectionSquare.width = selectionSquare.height = ChartEditorState.GRID_SIZE;
          selectionSquare.color = FlxColor.RED;
          selectionSquare.isError = true;
        }

        // Additional cleanup on notes.
        if (state.noteTooltipsDirty) noteSprite.updateTooltipText();
      }

      // Re-query event errors before drawing selection boxes and tooltips.
      if (state.noteTooltipsDirty)
      {
        for (eventData in state.currentSongChartEventData)
        {
          state.isEventInvalidated(eventData);
        }
      }

      for (eventSprite in state.renderedEvents.members)
      {
        if (eventSprite == null || eventSprite.eventData == null || !eventSprite.exists || !eventSprite.visible) continue;

        var eventSelected:Bool = state.selectedEventSet.exists(eventSprite.eventData);
        var isInvalidated:Bool = eventSprite.eventData.getValidationErrors().length > 0;

        // Update position before rendering.
        if (eventSelected)
        {
          // Determine if the note is being dragged and offset the position accordingly.
          if (state.dragTargetCurrentStep != 0.0 || state.dragTargetCurrentColumn != 0)
          {
            var stepTime = (eventSprite.eventData == null) ? 0 : eventSprite.eventData.getStepTime();
            eventSprite.overrideStepTime = (stepTime + state.dragTargetCurrentStep).clamp(0, state.lastSnappedGridStep);
            // Then reapply the note sprite's position relative to the grid.
            eventSprite.updateEventPosition(state.renderedEvents);
          }
          else
          {
            if (eventSprite.overrideStepTime != null)
            {
              eventSprite.overrideStepTime = null;
              eventSprite.updateEventPosition(state.renderedEvents);
            }
          }
        }

        // Then render the error box...
        if (isInvalidated)
        {
          // TODO: Maybe use another way to display these events.
          var selectionSquare:ChartEditorSelectionSquareSprite = state.renderedSelectionSquares.recycle(state.buildSelectionSquare);

          // Set the position and size (because we might be recycling one with bad values).
          selectionSquare.noteData = null;
          selectionSquare.eventData = eventSprite.eventData;
          selectionSquare.x = eventSprite.x;
          selectionSquare.y = eventSprite.y;
          selectionSquare.width = eventSprite.width;
          selectionSquare.height = eventSprite.height;
          selectionSquare.color = FlxColor.RED;
          selectionSquare.isError = true;
        }

        // Then render the selection box on TOP of the error box...
        if (eventSelected)
        {
          // Then, render the selection square.
          var selectionSquare:ChartEditorSelectionSquareSprite = state.renderedSelectionSquares.recycle(state.buildSelectionSquare);

          // Set the position and size (because we might be recycling one with bad values).
          selectionSquare.noteData = null;
          selectionSquare.eventData = eventSprite.eventData;
          selectionSquare.x = eventSprite.x;
          selectionSquare.y = eventSprite.y;
          selectionSquare.width = eventSprite.width;
          selectionSquare.height = eventSprite.height;
          selectionSquare.color = FlxColor.WHITE;
          selectionSquare.isError = false;
        }
        else
        {
          if (eventSprite.overrideStepTime != null)
          {
            eventSprite.overrideStepTime = null;
            eventSprite.updateEventPosition(state.renderedEvents);
          }
        }

        // Additional cleanup on notes.
        if (state.noteTooltipsDirty) eventSprite.updateTooltipText();
      }

      state.noteTooltipsDirty = false;

      // Sort the notes DESCENDING. This keeps the sustain behind the associated note.
      if (state.notesNeedSort || state.dragTargetCurrentStep != 0 || state.dragTargetCurrentColumn != 0)
      {
        state.renderedNotes.sort(FlxSort.byY, FlxSort.DESCENDING);
        state.notesNeedSort = false;
      }

      // Sort the events DESCENDING. This keeps the sustain behind the associated note.
      state.renderedEvents.sort(function(order:Int, obj1:FlxBasic, obj2:FlxBasic):Int
      {
        var event1:ChartEditorEventSprite = cast obj1;
        var event2:ChartEditorEventSprite = cast obj2;

        var sel1 = event1.eventData != null && state.selectedEventSet.exists(event1.eventData);
        var sel2 = event2.eventData != null && state.selectedEventSet.exists(event2.eventData);

        if (sel1 && !sel2) return 1;
        if (!sel1 && sel2) return -1;

        return FlxSort.byValues(order, event1.y, event2.y);
      }, FlxSort.DESCENDING);
    }
  }

  /**
   * Builds the group that will hold all the notes.
   */
  public static function buildNoteGroup(state:ChartEditorState):Void
  {
    if (state.gridTiledSprite == null) throw 'ERROR: Tried to build note groups, but gridTiledSprite is null! Check ChartEditorState.buildGrid().';

    state.renderedHoldNotes.setPosition(state.gridTiledSprite.x, state.gridTiledSprite.y);
    state.add(state.renderedHoldNotes);
    state.renderedHoldNotes.zIndex = 24;

    state.renderedNotes.setPosition(state.gridTiledSprite.x, state.gridTiledSprite.y);
    state.add(state.renderedNotes);
    state.renderedNotes.zIndex = 25;

    state.renderedEvents.setPosition(state.gridTiledSprite.x, state.gridTiledSprite.y);
    state.add(state.renderedEvents);
    state.renderedEvents.zIndex = 25;

    state.renderedSelectionSquares.setPosition(state.gridTiledSprite.x, state.gridTiledSprite.y);
    state.add(state.renderedSelectionSquares);
    state.renderedSelectionSquares.zIndex = 26;
  }

  /**
   * This is for the smaller green squares that appear over each note when you select them.
   */
  public static function buildSelectionSquare(state:ChartEditorState):ChartEditorSelectionSquareSprite
  {
    if (state.selectionSquareBitmap == null) throw 'ERROR: Tried to build selection square, but selectionSquareBitmap is null! Check ChartEditorThemeHandler.updateSelectionSquare()';

    // FlxG.bitmapLog.add(selectionSquareBitmap, "selectionSquareBitmap");
    var result = new ChartEditorSelectionSquareSprite(state);
    return result;
  }

  /**
   * Show tooltips for the notes and events on the grid.
   */
  public static function handleGridTooltips(state:ChartEditorState, elapsed:Float):Void
  {
    var target:Null<FlxSprite> = null;
    var options:Null<haxe.ui.tooltips.ToolTipOptions> = null;

    if (state.gridTiledSprite != null && !state.isCursorOverHaxeUI && !state.isHaxeUIDialogOpen && FlxG.mouse.overlaps(state.gridTiledSprite))
    {
      for (eventSprite in state.renderedEvents.members)
      {
        if (eventSprite == null || !eventSprite.alive || !eventSprite.visible || eventSprite.eventData == null) continue;
        if ((eventSprite.tooltip.tipData?.text ?? '').length == 0 || !FlxG.mouse.overlaps(eventSprite)) continue;
        target = eventSprite;
        options = eventSprite.tooltip;
        break;
      }

      if (target == null)
      {
        for (noteSprite in state.renderedNotes.members)
        {
          if (noteSprite == null || !noteSprite.alive || !noteSprite.visible || noteSprite.noteData == null) continue;
          if ((noteSprite.tooltip.tipData?.text ?? '').length == 0 || !FlxG.mouse.overlaps(noteSprite)) continue;
          target = noteSprite;
          options = noteSprite.tooltip;
          break;
        }
      }
    }

    if (target != state.gridTooltipTarget)
    {
      if (state.gridTooltipShown) state.hideTooltip();
      state.gridTooltipTarget = target;
      state.gridTooltipTime = 0;
    }

    var manager:ToolTipManager = ToolTipManager.instance;
    if (target == null && manager._toolTip != null && !manager._toolTip.hidden && manager._currentRegion == null && manager._currentComponent == null)
    {
      manager._toolTip.hide();
    }

    if (target == null || options == null || state.gridTooltipShown) return;

    state.gridTooltipTime += elapsed;
    if (state.gridTooltipTime * 1000 < ToolTipManager.defaultDelay) return;

    ToolTipManager.instance.showToolTipAt(haxe.ui.backend.flixel.MouseHelper.currentWorldX, haxe.ui.backend.flixel.MouseHelper.currentWorldY, options);
    state.gridTooltipShown = true;
  }

  /**
   * Handles the hiding of stale tooltips that are no longer relevant.
   */
  public static function handleStaleTooltip(state:ChartEditorState):Void
  {
    var manager:ToolTipManager = ToolTipManager.instance;
    var showing:Bool = manager._toolTip != null && !manager._toolTip.hidden;
    if (!showing && manager._timer == null) return;

    var mouseX:Float = haxe.ui.backend.flixel.MouseHelper.currentWorldX;
    var mouseY:Float = haxe.ui.backend.flixel.MouseHelper.currentWorldY;

    var region = manager._currentRegion;
    if (region != null)
    {
      var stillThere:Bool = manager._toolTipRegions.contains(region);
      var underMouse:Bool = mouseX >= region.left && mouseX < region.left + region.width && mouseY >= region.top && mouseY < region.top + region.height;
      if (!stillThere || !underMouse || state.isHaxeUIDialogOpen)
      {
        manager._currentRegion = null;
        state.hideTooltip();
      }
      return;
    }

    var component = manager._currentComponent;
    if (component != null && (!component.exists || component.hidden || !component.hitTest(mouseX, mouseY)))
    {
      state.hideTooltip();
    }
  }

  public static function hideTooltip(state:ChartEditorState):Void
  {
    var manager:ToolTipManager = ToolTipManager.instance;
    manager.stopCurrent();
    manager.hideCurrentToolTip();
    state.gridTooltipShown = false;
  }

  public static function updatePlayheadGhostHoldNotes(state:ChartEditorState):Void
  {
    // Ensure all the ghost hold notes exist.
    while (state.gridPlayheadGhostHoldNotes.length < (ChartEditorState.STRUMLINE_SIZE * 2))
    {
      var ghost = new ChartEditorHoldNoteSprite(state);
      ghost.alpha = 0.6;
      ghost.noteData = null;
      ghost.visible = false;
      ghost.zIndex = 21;
      state.add(ghost); // Don't add to `renderedHoldNotes` because then it will get killed every frame.

      state.gridPlayheadGhostHoldNotes.push(ghost);
      state.refresh();
    }

    // Update playhead ghost hold notes.
    for (column in 0...state.gridPlayheadGhostHoldNotes.length)
    {
      var targetNoteData = state.currentLiveInputPlaceNoteData[column];
      var ghostHold = state.gridPlayheadGhostHoldNotes[column];

      if (targetNoteData == null && ghostHold.noteData != null)
      {
        // Remove the ghost hold note.
        ghostHold.noteData = null;
      }

      if (targetNoteData != null && ghostHold.noteData == null)
      {
        // Readd the new ghost hold note.
        ghostHold.noteData = targetNoteData.clone();
        ghostHold.noteDirection = ghostHold.noteData.getDirection();
        ghostHold.visible = true;
        ghostHold.alpha = 0.6;
        ghostHold.setHeightDirectly(0);
        ghostHold.noteStyle = NoteKindManager.getNoteStyleId(ghostHold.noteData.kind, state.currentSongNoteStyle) ?? state.currentSongNoteStyle;
        ghostHold.updateHoldNotePosition(state.renderedHoldNotes);
      }

      if (ghostHold.noteData == null)
      {
        ghostHold.visible = false;
        ghostHold.setHeightDirectly(0);
        state.playheadDragLengthCurrent[column] = 0;
        continue;
      }

      var playheadFractionalStep:Float = ChartEditorTimeScale.pixelsToStep(state.scrollPositionInPixels + state.playheadPositionInPixels);
      var playheadSnappedStep:Float = Math.fround(playheadFractionalStep / state.noteSnapRatio) * state.noteSnapRatio;
      playheadSnappedStep = Math.min(playheadSnappedStep, state.lastSnappedGridStep);
      var playheadSnappedMs:Float = Conductor.instance.getStepTimeInMs(playheadSnappedStep);

      var newNoteLength:Float = playheadSnappedMs - ghostHold.noteData.time;
      trace('newNoteLength: ${newNoteLength}');

      if (newNoteLength > 0)
      {
        ghostHold.noteData.length = newNoteLength;
        var targetNoteLengthSteps:Float = ghostHold.noteData.getStepLength(true);
        var targetNoteLengthStepsInt:Int = Std.int(Math.floor(targetNoteLengthSteps));
        var targetNoteLengthPixels:Float = ChartEditorTimeScale.lengthToPixels(ghostHold.noteData.time, newNoteLength, targetNoteLengthSteps);

        if (state.playheadDragLengthCurrent[column] != targetNoteLengthStepsInt)
        {
          state.playStretchySound();
          state.playheadDragLengthCurrent[column] = targetNoteLengthStepsInt;
        }
        ghostHold.visible = true;
        ghostHold.alpha = 0.6;
        ghostHold.setHeightDirectly(targetNoteLengthPixels, true);
        ghostHold.updateHoldNotePosition(state.renderedHoldNotes);
        trace('lerpLength: ${ghostHold.fullSustainLength}');
        trace('position: ${ghostHold.x}, ${ghostHold.y}');
      }
      else
      {
        ghostHold.visible = false;
        ghostHold.setHeightDirectly(0);
        state.playheadDragLengthCurrent[column] = 0;
        continue;
      }
    }
  }

  /**
   * Handle using `renderedPins` to display comment pins from `currentSongChartCommentData`.
   */
  public static function handleCommentDisplay(state:ChartEditorState):Void
  {
    // We need to update when comments change OR we scroll.
    if (state.noteDisplayDirty || state.commentDisplayDirty)
    {
      // Current algorithm displays every on-screen comment, starting closest to the playhead

      var playheadPosMs:Float = state.scrollPositionInMs + state.playheadPositionInMs;

      var startPos:Float = ChartEditorTimeScale.pixelsToMs(state.scrollPositionInPixels - (ChartEditorState.GRID_TOP_PAD + state.commentPanels[0].height));
      var endPos:Float = ChartEditorTimeScale.pixelsToMs(state.scrollPositionInPixels + (FlxG.height - ChartEditorState.PLAYBAR_HEIGHT - ChartEditorState.GRID_INITIAL_Y_POS));

      var nearbyCommentData:Array<CommentData> = state.currentSongChartCommentData.filter((comment) ->
      {
        return (comment.time >= startPos && comment.time <= endPos);
      });

      nearbyCommentData.sort((commentA, commentB) ->
      {
        if (commentA.time == commentB.time) return 0;

        // Sort by which is closer to the playheadPosMs.
        var commentADistance = Math.abs(commentA.time - playheadPosMs);
        var commentBDistance = Math.abs(commentB.time - playheadPosMs);
        return (commentADistance - commentBDistance) > 0 ? 1 : -1;
      });

      while (state.commentPanels.length < nearbyCommentData.length)
      {
        state.buildCommentPanel();
      }

      var unplaced:Array<CommentData> = nearbyCommentData.copy();
      var freePanels:Array<ChartEditorCommentPanel> = [];
      for (commentPanel in state.commentPanels)
      {
        var current:Null<CommentData> = commentPanel.commentData;
        if (current != null && unplaced.remove(current)) continue;
        freePanels.push(commentPanel);
      }
      for (commentPanel in freePanels)
      {
        commentPanel.commentData = unplaced.length > 0 ? unplaced.shift() : null;
      }

      for (commentPanel in state.commentPanels)
      {
        commentPanel.updateText();
        commentPanel.updateColor();
      }
    }

    for (commentPanel in state.commentPanels)
    {
      if (commentPanel.commentData != null) commentPanel.updatePosition();
    }

    if (state.commentDisplayDirty)
    {
      state.commentDisplayDirty = false;

      // Remove comments that are no longer visible and list the ones that are.
      var displayedCommentData:Array<CommentData> = [];
      for (pinSprite in state.renderedPins.members)
      {
        if (pinSprite == null || pinSprite.commentData == null || !pinSprite.exists || !pinSprite.visible) continue;

        if (!state.currentSongChartCommentData.contains(pinSprite.commentData))
        {
          // Comment has been removed!
          // Clearing the comment data on the pin will automatically kill it.
          pinSprite.commentData = null;
        }
        else
        {
          // Mark that we are already rendering this comment.
          displayedCommentData.push(pinSprite.commentData);

          // Make sure the pin display is up to date.
          pinSprite.updateDisplay();
        }
      }

      // Add comments that are newly visible.
      for (commentData in state.currentSongChartCommentData)
      {
        if (displayedCommentData.contains(commentData)) continue;

        var pinSprite:ChartEditorCommentPinSprite = state.renderedPins.recycle(() -> new ChartEditorCommentPinSprite(state));

        // Updating the comment data automatically triggers a position/color/text update.
        pinSprite.commentData = commentData;
      }
    }
  }

  public static function buildCommentPanel(state:ChartEditorState):Void
  {
    var commentPanel:ChartEditorCommentPanel = new ChartEditorCommentPanel(state);
    commentPanel.zIndex = 10;
    commentPanel.hidden = true;
    state.add(commentPanel);
    state.commentPanels.push(commentPanel);
    state.refresh();
  }

  public static function handleRangeSelection(state:ChartEditorState):Void
  {
    if (FlxG.keys.justPressed.TAB && !(state.isHaxeUIDialogOpen || state.isHaxeUIFocused))
    {
      var playheadMs:Float = state.scrollPositionInMs + state.playheadPositionInMs;
      var start:Null<Float> = state.rangeSelectionStartMs;
      if (start == null || state.rangeSelectionEndMs != null)
      {
        // Start a new selection.
        state.rangeSelectionStartMs = playheadMs;
        state.rangeSelectionEndMs = null;
      }
      else
      {
        state.rangeSelectionStartMs = Math.min(start, playheadMs);
        state.rangeSelectionEndMs = Math.max(start, playheadMs);
      }
    }

    var sprite:Null<FlxSprite> = state.rangeSelectionSprite;
    if (sprite == null || state.gridTiledSprite == null) return;

    var start:Null<Float> = state.rangeSelectionStartMs;
    sprite.visible = start != null;
    if (start == null) return;

    var top:Float = state.gridTiledSprite.y + ChartEditorTimeScale.msToPixels(start);
    var end:Null<Float> = state.rangeSelectionEndMs;
    var height:Float = ChartEditorState.RANGE_SELECTION_MARKER_HEIGHT;
    if (end != null)
    {
      height = Math.max(ChartEditorState.RANGE_SELECTION_MARKER_HEIGHT, ChartEditorTimeScale.msToPixels(end) - ChartEditorTimeScale.msToPixels(start));
      sprite.alpha = ChartEditorState.RANGE_SELECTION_ALPHA;
    }
    else
    {
      top -= ChartEditorState.RANGE_SELECTION_MARKER_HEIGHT / 2;
      sprite.alpha = 1;
    }

    sprite.scale.set(state.gridTiledSprite.width, height);
    sprite.updateHitbox();
    sprite.x = state.gridTiledSprite.x;
    sprite.y = top;
  }
}
#end
