package funkin.ui.debug.charting.handlers.chart;

#if FEATURE_CHART_EDITOR
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import funkin.assets.ValidatedPaths as Paths;
import funkin.audio.FunkinSound;
import funkin.data.song.SongData.SongEventData;
import funkin.data.song.SongData.SongNoteData;
import funkin.data.song.SongDataUtils;
import funkin.input.Cursor;
import funkin.play.notes.notekind.NoteKindManager;
import funkin.ui.debug.charting.commands.comments.AddCommentCommand;
import funkin.ui.debug.charting.toolboxes.ChartEditorListKeyTarget;
import funkin.ui.debug.charting.commands.events.AddEventsCommand;
import funkin.ui.debug.charting.commands.notes.AddNotesCommand;
import funkin.ui.debug.charting.commands.selection.DeselectAllItemsCommand;
import funkin.ui.debug.charting.commands.selection.DeselectItemsCommand;
import funkin.ui.debug.charting.commands.notes.ExtendNoteLengthCommand;
import funkin.ui.debug.charting.commands.events.MoveEventsCommand;
import funkin.ui.debug.charting.commands.items.AlignItemsToSubBeatsCommand;
import funkin.ui.debug.charting.commands.items.MoveItemsCommand;
import funkin.ui.debug.charting.commands.notes.MoveNotesCommand;
import funkin.ui.debug.charting.commands.events.RemoveEventsCommand;
import funkin.ui.debug.charting.commands.notes.RemoveNotesCommand;
import funkin.ui.debug.charting.commands.selection.SelectItemsCommand;
import funkin.ui.debug.charting.commands.selection.SetItemSelectionCommand;
import funkin.ui.debug.charting.components.notes.ChartEditorEventSprite;
import funkin.ui.debug.charting.components.notes.ChartEditorHoldNoteSprite;
import funkin.ui.debug.charting.components.notes.ChartEditorNoteSprite;
import funkin.ui.debug.charting.components.grid.ChartEditorSelectionSquareSprite;
import haxe.ui.core.Screen;
import haxe.ui.dragdrop.DragManager;
using Lambda;

@:access(haxe.ui.tooltips.ToolTipManager)
@:access(funkin.audio.VoicesGroup)
@:access(funkin.ui.debug.charting.ChartEditorState)
class ChartEditorCursorHandler
{
  /**
   * Handle display of the mouse cursor.
   */
  public static function handleCursor(state:ChartEditorState):Void
  {
    if (state.gridGhostNote != null) state.gridGhostNote.visible = false;
    if (state.gridGhostHoldNote != null) state.gridGhostHoldNote.visible = false;
    if (state.gridGhostEvent != null) state.gridGhostEvent.visible = false;
    if (state.gridCursorLine != null) state.gridCursorLine.visible = false;

    // Mouse sounds
    if (FlxG.mouse.justPressed) FunkinSound.playOnce(Paths.sound('ui/editors/chart-editor/charting-sounds/click-down').toString());
    if (FlxG.mouse.justReleased) FunkinSound.playOnce(Paths.sound('ui/editors/chart-editor/charting-sounds/click-up').toString());

    if (state.playbarHeadDragging) Screen.instance.setCursor('grabbing');

    // Note: If a menu is open in HaxeUI, don't handle cursor behavior.
    var shouldHandleCursor:Bool =
      !(state.isHaxeUIFocused || state.playbarHeadDragging || state.isHaxeUIDialogOpen || DragManager.instance.isDragging)
      || (state.selectionBoxStartPos != null)
      || (state.dragTargetNote != null || state.dragTargetEvent != null);

    var eventColumn:Int = (ChartEditorState.STRUMLINE_SIZE * 2 + 1) - 1;

    // TODO: TBH some of this should be using FlxMouseEventManager...

    // early return if we shouldn't handle the cursor at all
    if (!shouldHandleCursor)
    {
      // Do not set Cursor.cursorMode here, because it will be set by the HaxeUI.
      return;
    }

    // Over the course of this big conditional block,
    // we determine what the cursor should look like,
    // and fall back to the default cursor if none of the conditions are met.
    var targetCursorMode:Null<CursorMode> = null;

    if (state.gridTiledSprite == null) throw 'ERROR: Tried to handle cursor, but gridTiledSprite is null! Check ChartEditorState.buildGrid()';

    var overlapsGrid:Bool = FlxG.mouse.overlaps(state.gridTiledSprite);

    var overlapsRenderedNotes:Bool = true;
    var overlapsRenderedEvents:Bool = true;
    var overlapsRenderedHoldNotes:Bool = true;

    var overlapsRenderedPins:Bool = FlxG.mouse.overlaps(state.renderedPins);

    var highlightedNote:Null<ChartEditorNoteSprite> = null;
    var highlightedEvent:Null<ChartEditorEventSprite> = null;
    var highlightedHoldNote:Null<ChartEditorHoldNoteSprite> = null;

    // Find the first note that is at the cursor position.
    if (overlapsGrid && FlxG.mouse.overlaps(state.renderedNotes))
    {
      highlightedNote = state.renderedNotes.members.find(function(note:ChartEditorNoteSprite):Bool
      {
        // If note.alive is false, the note is dead and awaiting recycling.
        return note.alive && FlxG.mouse.overlaps(note);
      });
    }

    if (highlightedNote == null)
    {
      // Cursor is not overlapping an note
      overlapsRenderedNotes = false;
    }

    // Find the first event that is at the cursor position.
    // Skip this if we're already highlighting a note.
    if (overlapsGrid && !overlapsRenderedNotes && FlxG.mouse.overlaps(state.renderedEvents))
    {
      var newOverlappingEvents:Array<ChartEditorEventSprite> = state.renderedEvents.members.filter(function(event:ChartEditorEventSprite):Bool
      {
        return event.alive && FlxG.mouse.overlaps(event);
      });

      if (newOverlappingEvents.length > 0)
      {
        newOverlappingEvents.sort(function(a:ChartEditorEventSprite, b:ChartEditorEventSprite):Int
        {
          return state.currentSongChartEventData.indexOf(a.eventData) - state.currentSongChartEventData.indexOf(b.eventData);
        });

        var eventsChanged:Bool = state.currentOverlappingEvents.length != newOverlappingEvents.length;
        if (!eventsChanged)
        {
          for (i in 0...newOverlappingEvents.length)
          {
            if (newOverlappingEvents[i] != state.currentOverlappingEvents[i])
            {
              eventsChanged = true;
              break;
            }
          }
        }

        if (eventsChanged)
        {
          state.currentOverlappingEvents = newOverlappingEvents;
          state.currentOverlappingEventCycleIndex = 0;

          for (i in 0...state.currentOverlappingEvents.length)
          {
            if (state.isEventSelected(state.currentOverlappingEvents[i].eventData))
            {
              state.currentOverlappingEventCycleIndex = i;
              break;
            }
          }
        }

        highlightedEvent = state.currentOverlappingEvents[state.currentOverlappingEventCycleIndex];
      }
      else
      {
        state.currentOverlappingEvents = [];
        state.currentOverlappingEventCycleIndex = 0;
      }
    }
    else
    {
      state.currentOverlappingEvents = [];
      state.currentOverlappingEventCycleIndex = 0;
    }

    if (highlightedEvent == null)
    {
      // Cursor is not overlapping an event
      overlapsRenderedEvents = false;
    }

    // Find the first hold note that is at the cursor position.
    // Skip this if we're already highlighting a note or event.
    if (overlapsGrid && !(overlapsRenderedNotes || overlapsRenderedEvents) && FlxG.mouse.overlaps(state.renderedHoldNotes))
    {
      if (overlapsGrid) highlightedHoldNote = state.renderedHoldNotes.members.find(function(holdNote:ChartEditorHoldNoteSprite):Bool
      {
        // If holdNote.alive is false, the holdNote is dead and awaiting recycling.
        return holdNote.alive && FlxG.mouse.overlaps(holdNote);
      });
    }

    if (highlightedHoldNote == null)
    {
      // Cursor is not overlapping a hold note
      overlapsRenderedHoldNotes = false;
    }

    // Cursor position relative to the grid.
    var cursorX:Float = FlxG.mouse.viewX - state.gridTiledSprite.x;
    var cursorY:Float = FlxG.mouse.viewY - state.gridTiledSprite.y;

    var overlapsSelection:Bool = false;

    var highlightedSelectionSquare:Null<ChartEditorSelectionSquareSprite> = null;

    if (overlapsGrid)
    {
      highlightedSelectionSquare = state.renderedSelectionSquares.members.find((selectionSquare:ChartEditorSelectionSquareSprite) ->
      {
        return selectionSquare.alive && !selectionSquare.isError && FlxG.mouse.overlaps(selectionSquare);
      });
    }

    if (highlightedSelectionSquare != null)
    {
      overlapsSelection = true;
    }

    var overlapsHealthIcons:Bool = FlxG.mouse.overlaps(state.healthIconBF) || FlxG.mouse.overlaps(state.healthIconDad);

    if (FlxG.mouse.justPressedMiddle)
    {
      if (state.scrollAnchorScreenPos == null)
      {
        state.scrollAnchorScreenPos = FlxPoint.get(FlxG.mouse.x, FlxG.mouse.y);
        state.selectionBoxStartPos = null;
      }
      else
      {
        state.releaseScrollAnchor();
        Screen.instance.setCursor('default');
      }
    }

    if (FlxG.mouse.justPressedRight)
    {
      if (state.gridPlayhead != null && FlxG.mouse.overlaps(state.gridPlayhead) && !state.isCursorOverHaxeUI)
      {
        var playheadPosMs:Float = state.scrollPositionInMs + state.playheadPositionInMs;

        // Add a new comment at the grid playhead's position.
        state.performCommand(new AddCommentCommand({
          time: playheadPosMs,
          text: 'New Comment',
          color: state.commentColorToPlace,
        }));
        state.success('New Comment', 'Added a comment at the playhead position.');
      }
    }

    // An odd way to fix this since measureTicks contains more than just the gray sidebar now.
    var gridPlayheadScrollArea:FlxRect = FlxRect.weak(state.measureTicks?.x ?? -100, ChartEditorState.GRID_INITIAL_Y_POS, ChartEditorState.GRID_SIZE, FlxG.height - ChartEditorState.PLAYBAR_HEIGHT - ChartEditorState.GRID_INITIAL_Y_POS);

    if (FlxG.mouse.justPressed)
    {
      if (state.scrollAnchorScreenPos != null)
      {
        state.releaseScrollAnchor();
        Screen.instance.setCursor('default');
      }
      else
      {
        if (!FlxG.keys.pressed.SHIFT)
        {
          // Dragging playhead
          if (state.measureTicks != null && gridPlayheadScrollArea.containsXY(FlxG.mouse.viewX, FlxG.mouse.viewY) && !state.isCursorOverHaxeUI)
          {
            state.gridPlayheadScrollAreaPressed = true;
            if ((state.audioInstTrack != null && state.audioInstTrack.isPlaying) || state.audioVocalTrackGroup.playing)
            {
              state.playbarHeadDraggingWasPlaying = true;
              state.stopAudioPlayback();
            }
          }
          else if (state.notePreview != null && FlxG.mouse.overlaps(state.notePreview) && !state.isCursorOverHaxeUI)
          {
            // Clicked note preview
            state.notePreviewScrollAreaStartPos = FlxPoint.get(FlxG.mouse.viewX, FlxG.mouse.viewY);
          }
        }
        else if (!state.isCursorOverHaxeUI && FlxG.keys.pressed.SHIFT)
        {
          trace('Started selection box at (${FlxG.mouse.viewX}, ${FlxG.mouse.viewY})');
          state.selectionBoxStartPos = FlxPoint.get(FlxG.mouse.viewX, FlxG.mouse.viewY);
          // Drawing selection box.
          targetCursorMode = Crosshair;
        }
      }
    }

    if (state.gridPlayheadScrollAreaPressed && FlxG.mouse.released)
    {
      state.gridPlayheadScrollAreaPressed = false;
      // If we were dragging the playhead while the song was playing, resume playing.
      if (state.playbarHeadDraggingWasPlaying)
      {
        state.playbarHeadDraggingWasPlaying = false;
        state.startAudioPlayback();
      }
    }

    if (state.notePreviewScrollAreaStartPos != null && FlxG.mouse.released)
    {
      state.notePreviewScrollAreaStartPos.put();
      state.notePreviewScrollAreaStartPos = null;
      state.notePreviewPlayHeadDragging = false;

      if (state.playbarHeadDraggingWasPlaying)
      {
        state.playbarHeadDraggingWasPlaying = false;
        state.startAudioPlayback();
      }
    }

    if (state.gridPlayheadScrollAreaPressed)
    {
      // Clicked on the playhead scroll area.
      // Move the playhead to the cursor position.
      state.playheadPositionInPixels = FlxG.mouse.viewY - (ChartEditorState.GRID_INITIAL_Y_POS);
      state.moveSongToScrollPosition();

      // Cursor should be a grabby hand.
      if (targetCursorMode == null) targetCursorMode = Grabbing;
    }

    // The song position of the cursor, in steps.
    var cursorFractionalStep:Float = ChartEditorTimeScale.pixelsToStep(cursorY);
    var cursorMs:Float = Conductor.instance.getStepTimeInMs(cursorFractionalStep);
    // Round the cursor step to the nearest snap quant.
    var cursorSnappedStep:Float = Math.max(0, Math.fround(cursorFractionalStep / state.noteSnapRatio) * state.noteSnapRatio);
    cursorSnappedStep = Math.min(cursorSnappedStep, state.lastSnappedGridStep);

    cursorSnappedStep = state.snapToSubBeat(cursorFractionalStep, cursorSnappedStep);
    var cursorSnappedMs:Float = Conductor.instance.getStepTimeInMs(cursorSnappedStep);

    // A line across the grid at the snap the cursor would place on.
    var draggedStep:Null<Float> = null;
    if (state.dragTargetNote?.noteData != null) draggedStep = state.dragTargetNote.noteData.getStepTime();
    else if (state.dragTargetEvent?.eventData != null) draggedStep = state.dragTargetEvent.eventData.getStepTime();

    if (state.showCursorLine && state.gridCursorLine != null && (draggedStep != null || (overlapsGrid && !state.isCursorOverHaxeUI)))
    {
      var lineStep:Float = (draggedStep != null) ? (draggedStep + state.dragTargetCurrentStep).clamp(0, state.lastSnappedGridStep) : cursorSnappedStep;
      state.gridCursorLine.visible = true;
      state.gridCursorLine.x = state.gridTiledSprite.x;
      state.gridCursorLine.y = Math.round(state.gridTiledSprite.y + ChartEditorTimeScale.stepToPixels(lineStep)) - Std.int(state.gridCursorLine.height / 2);
    }

    // The direction value for the column at the cursor.
    var cursorGridPos:Int = Math.floor(cursorX / ChartEditorState.GRID_SIZE);
    var cursorColumn:Int = ChartEditorNoteUtil.gridColumnToNoteData(cursorGridPos);

    if (state.selectionBoxStartPos != null)
    {
      var cursorXStart:Float = state.selectionBoxStartPos.x - state.gridTiledSprite.x;
      var cursorYStart:Float = state.selectionBoxStartPos.y - state.gridTiledSprite.y;

      var hasDraggedMouse:Bool = Math.abs(cursorX - cursorXStart) > ChartEditorState.DRAG_THRESHOLD || Math.abs(cursorY - cursorYStart) > ChartEditorState.DRAG_THRESHOLD;

      // Determine if we dragged the mouse at all.
      if (hasDraggedMouse)
      {
        // Handle releasing the selection box.
        if (FlxG.mouse.justReleased)
        {
          // We released the mouse. Select the notes in the box.
          var cursorFractionalStepStart:Float = ChartEditorTimeScale.pixelsToStep(cursorYStart);
          var cursorStepStart:Int = Math.floor(cursorFractionalStepStart);
          var cursorMsStart:Float = Conductor.instance.getStepTimeInMs(cursorStepStart);
          var cursorColumnBase:Int = Math.floor(cursorX / ChartEditorState.GRID_SIZE);
          var cursorColumnBaseStart:Int = Math.floor(cursorXStart / ChartEditorState.GRID_SIZE);

          // Since this selects based on noteData directly,
          // we don't need to specifically exclude sustain pieces.

          // This logic is gross because the columns go 4567-0123-8.
          // We build a list of columns to select.
          var columnStart:Int = Std.int(Math.min(cursorColumnBase, cursorColumnBaseStart));
          var columnEnd:Int = Std.int(Math.max(cursorColumnBase, cursorColumnBaseStart));
          var columns:Array<Int> = [for (i in columnStart...(columnEnd + 1)) i].map(function(i:Int):Int
          {
            if (i >= eventColumn)
            {
              // Don't invert the event column.
              return eventColumn;
            }
            else if (i >= ChartEditorState.STRUMLINE_SIZE)
            {
              // Invert the player columns.
              return i - ChartEditorState.STRUMLINE_SIZE;
            }
            else if (i >= 0)
            {
              // Invert the opponent columns.
              return i + ChartEditorState.STRUMLINE_SIZE;
            }
            else
            {
              // Minimum of -1.
              return -1;
            }
          });

          var boxLeft:Float = Math.min(FlxG.mouse.viewX, state.selectionBoxStartPos.x);
          var boxRight:Float = Math.max(FlxG.mouse.viewX, state.selectionBoxStartPos.x);
          var boxStartMs:Float = Math.min(cursorMsStart, cursorMs);
          var boxEndMs:Float = Math.max(cursorMsStart, cursorMs);
          var boxHasItems:Bool = state.selectables.exists(selectable -> selectable.hasItemsInBox(boxLeft, boxRight, boxStartMs, boxEndMs));

          if (columns.length > 0)
          {
            var notesToSelect:Array<SongNoteData> = state.currentSongChartNoteData;
            notesToSelect = SongDataUtils.getNotesInTimeRange(notesToSelect, Math.min(cursorMsStart, cursorMs), Math.max(cursorMsStart, cursorMs));
            notesToSelect = SongDataUtils.getNotesWithData(notesToSelect, columns);

            var eventsToSelect:Array<SongEventData> = [];

            if (columns.indexOf(eventColumn) != -1)
            {
              // The drag selection included the event column.
              eventsToSelect = state.currentSongChartEventData;
              eventsToSelect = SongDataUtils.getEventsInTimeRange(eventsToSelect, Math.min(cursorMsStart, cursorMs), Math.max(cursorMsStart, cursorMs));
            }

            if (notesToSelect.length > 0 || eventsToSelect.length > 0 || boxHasItems)
            {
              if (state.pressingControl())
              {
                // Add to the selection.
                state.performCommand(new SelectItemsCommand(notesToSelect, eventsToSelect));
              }
              else
              {
                // Set the selection.
                state.performCommand(new SetItemSelectionCommand(notesToSelect, eventsToSelect));
              }

              // Picked after the notes, since picking notes lets go of the other kinds.
              var keys:Null<ChartEditorListKeyTarget> = state.listKeyTarget;
              for (selectable in state.selectables)
              {
                selectable.selectInBox(boxLeft, boxRight, boxStartMs, boxEndMs, state.pressingControl());
              }
              // The keys stay with the notes and events when any got picked.
              if (notesToSelect.length > 0 || eventsToSelect.length > 0) state.listKeyTarget = keys;
            }
            else
            {
              // We made a selection box, but it didn't select anything.

              if (!state.pressingControl())
              {
                // Deselect all items.
                var shouldDeselect:Bool = !state.wasCursorOverHaxeUI && (state.currentNoteSelection.length > 0 || state.currentEventSelection.length > 0);
                if (shouldDeselect)
                {
                  state.performCommand(new DeselectAllItemsCommand());
                }
              }
            }
          }
          else
          {
            // We made a selection box, but it didn't select any columns.
          }

          // Clear the selection box.
          state.selectionBoxStartPos.put();
          state.selectionBoxStartPos = null;
          state.setSelectionBoxBounds();
        }
        else
        {
          // Clicking and dragging.
          state.scrollMouseToGrid();

          // Scroll the screen if the mouse is above or below the grid.
          if (FlxG.mouse.viewY < ChartEditorState.MENU_BAR_HEIGHT)
          {
            // Scroll up.
            var diff:Float = ChartEditorState.MENU_BAR_HEIGHT - FlxG.mouse.viewY;
            state.currentScrollEase -= diff * 0.5; // Too fast!
          }
          else if (FlxG.mouse.viewY > (state.playbarHeadLayout?.y ?? 0.0))
          {
            // Scroll down.
            var diff:Float = FlxG.mouse.viewY - (state.playbarHeadLayout?.y ?? 0.0);
            state.currentScrollEase += (diff * 0.5); // Too fast!
          }

          // Render the selection box, and keep the rendered graphic clamped to the size of the screen
          var selectionRect:FlxRect = FlxRect.weak();
          selectionRect.x = Math.min(FlxG.mouse.viewX, state.selectionBoxStartPos.x);
          selectionRect.y = Math.min(Math.max(0, state.selectionBoxStartPos.y), FlxG.mouse.viewY);
          selectionRect.width = Math.abs(FlxG.mouse.viewX - state.selectionBoxStartPos.x);
          selectionRect.height = Math.abs(FlxG.mouse.viewY - Math.max(Math.min(FlxG.height, state.selectionBoxStartPos.y), 0));
          state.setSelectionBoxBounds(selectionRect);

          targetCursorMode = Crosshair;
        }
      }
      else if (FlxG.mouse.justReleased)
      {
        // Clear the selection box.
        state.selectionBoxStartPos.put();
        state.selectionBoxStartPos = null;
        state.setSelectionBoxBounds();

        if (overlapsGrid)
        {
          // We clicked on the grid without moving the mouse.

          if (state.pressingControl())
          {
            if (highlightedNote != null && highlightedNote.noteData != null)
            {
              // Control click to select/deselect an individual note.
              if (state.isNoteSelected(highlightedNote.noteData))
              {
                state.performCommand(new DeselectItemsCommand([highlightedNote.noteData], []));
              }
              else
              {
                state.performCommand(new SelectItemsCommand([highlightedNote.noteData], []));
              }
            }
            else if (highlightedEvent != null && highlightedEvent.eventData != null)
            {
              // Control click to select/deselect an individual note.
              if (state.isEventSelected(highlightedEvent.eventData))
              {
                state.performCommand(new DeselectItemsCommand([], [highlightedEvent.eventData]));
              }
              else
              {
                state.performCommand(new SelectItemsCommand([], [highlightedEvent.eventData]));
              }
            }
            else if (highlightedHoldNote != null && highlightedHoldNote.noteData != null)
            {
              // Control click to select/deselect an individual note.
              if (state.isNoteSelected(highlightedHoldNote.noteData))
              {
                state.performCommand(new DeselectItemsCommand([highlightedHoldNote.noteData], []));
              }
              else
              {
                state.performCommand(new SelectItemsCommand([highlightedHoldNote.noteData], []));
              }
            }
            else
            {
              // Do nothing if you control-clicked on an empty space.
            }
          }
          else
          {
            if (highlightedNote != null && highlightedNote.noteData != null)
            {
              // Click a note to select it.
              state.performCommand(new SetItemSelectionCommand([highlightedNote.noteData], []));
            }
            else if (highlightedEvent != null && highlightedEvent.eventData != null)
            {
              // Click an event to select it.
              state.performCommand(new SetItemSelectionCommand([], [highlightedEvent.eventData]));
            }
            else if (highlightedHoldNote != null && highlightedHoldNote.noteData != null)
            {
              // Click a hold note to select it.
              state.performCommand(new SetItemSelectionCommand([highlightedHoldNote.noteData], []));
            }
            else
            {
              // Click on an empty space to deselect everything.
              var shouldDeselect:Bool = !state.wasCursorOverHaxeUI && (state.currentNoteSelection.length > 0 || state.currentEventSelection.length > 0);
              if (shouldDeselect)
              {
                state.performCommand(new DeselectAllItemsCommand());
              }
            }
          }
        }
        else
        {
          // If we clicked and released outside the grid.

          if (!state.pressingControl())
          {
            // Deselect all items.
            var shouldDeselect:Bool = !state.wasCursorOverHaxeUI && (state.currentNoteSelection.length > 0 || state.currentEventSelection.length > 0);
            if (shouldDeselect)
            {
              state.performCommand(new DeselectAllItemsCommand());
            }
          }
        }
      }
    }
    else if (state.notePreviewScrollAreaStartPos != null)
    {
      state.notePreviewPlayHeadDragging = true;
      // Stop audio playback while dragging on the note preview playhead.
      if ((state.audioInstTrack != null && state.audioInstTrack.isPlaying) || state.audioVocalTrackGroup.playing)
      {
        state.playbarHeadDraggingWasPlaying = true;
        state.stopAudioPlayback();
      }

      // Player is clicking and holding on note preview to scrub around.
      targetCursorMode = Grabbing;

      var clickedPosInPixels:Float = FlxMath.remapToRange(
        FlxG.mouse.viewY,
        (state.notePreview?.y ?? 0.0),
        (state.notePreview?.y ?? 0.0) + (state.notePreview?.height ?? 0.0),
        0,
        state.songLengthInPixels
      );

      state.currentScrollEase = clickedPosInPixels;
      state.easeSongToScrollPosition(state.currentScrollEase);
    }
    else if (state.scrollAnchorScreenPos != null)
    {
      // Cursor should be a scroll anchor.
      targetCursorMode = Scroll;
      Screen.instance.setCursor('scroll');
    }
    else if (state.dragTargetNote != null || state.dragTargetEvent != null)
    {
      if (FlxG.mouse.justReleased)
      {
        // Perform the actual drag operation.
        var dragDistanceSteps:Float = state.dragTargetCurrentStep;
        var dragDistanceMs:Float = 0;
        if (state.dragTargetNote != null && state.dragTargetNote.noteData != null)
        {
          dragDistanceMs = Conductor.instance.getStepTimeInMs(state.dragTargetNote.noteData.getStepTime() + dragDistanceSteps) - state.dragTargetNote.noteData.time;
        }
        else if (state.dragTargetEvent != null && state.dragTargetEvent.eventData != null)
        {
          dragDistanceMs = Conductor.instance.getStepTimeInMs(state.dragTargetEvent.eventData.getStepTime() + dragDistanceSteps) - state.dragTargetEvent.eventData.time;
        }
        var dragDistanceColumns:Int = state.dragTargetCurrentColumn;

        if (state.dragAlignToSubBeats)
        {
          var newSubBeats:Array<Float> = [];
          function alignedTime(stepTime:Float):Float
          {
            var step:Float = state.dragPreviewStep(stepTime);
            var time:Float = Conductor.instance.getStepTimeInMs(step);
            if (state.needsSubBeat(step) && !newSubBeats.contains(time)) newSubBeats.push(time);
            return time;
          }
          var noteTimes:Array<Float> = [for (note in state.currentNoteSelection) alignedTime(note.getStepTime())];
          var eventTimes:Array<Float> = [for (event in state.currentEventSelection) alignedTime(event.getStepTime())];
          state.performCommand(new AlignItemsToSubBeatsCommand(state.currentNoteSelection, state.currentEventSelection, noteTimes, eventTimes,
            dragDistanceColumns, newSubBeats));

          state.dragTargetNote = null;
          state.dragTargetEvent = null;
          state.dragTargetCurrentStep = 0;
          state.dragTargetCurrentColumn = 0;
          state.dragAlignToSubBeats = false;
          state.noteDisplayDirty = true;
          return;
        }

        if (state.dragTargetCurrentStep == 0 && state.dragTargetCurrentColumn == 0)
        {
          // There's no need to move anything.
          // Also prevents the selection boxes on notes from disappearing when they're 'moved' like this.

          if (state.dragTargetEvent != null && state.currentOverlappingEvents.length > 1 && state.dragEventWasSelected)
          {
            var nextIndex:Int = (state.currentOverlappingEventCycleIndex + 1) % state.currentOverlappingEvents.length;
            highlightedEvent = state.currentOverlappingEvents[nextIndex];
            state.performCommand(new SetItemSelectionCommand([], [highlightedEvent.eventData]));
          }

          state.dragTargetNote = null;
          state.dragTargetEvent = null;
          state.dragTargetCurrentStep = 0;
          state.dragTargetCurrentColumn = 0;
          return;
        }

        if (state.currentNoteSelection.length > 0 && state.currentEventSelection.length > 0)
        {
          // Both notes and events are selected.
          state.performCommand(new MoveItemsCommand(state.currentNoteSelection, state.currentEventSelection, dragDistanceMs, dragDistanceColumns));
        }
        else if (state.currentNoteSelection.length > 0)
        {
          // Only notes are selected.
          state.performCommand(new MoveNotesCommand(state.currentNoteSelection, dragDistanceMs, dragDistanceColumns));
        }
        else if (state.currentEventSelection.length > 0)
        {
          // Only events are selected.
          state.performCommand(new MoveEventsCommand(state.currentEventSelection, dragDistanceMs));
        }

        // Finished dragging. Release the note at the new position.
        state.dragTargetNote = null;
        state.dragTargetEvent = null;

        state.noteDisplayDirty = true;

        state.dragTargetCurrentStep = 0;
        state.dragTargetCurrentColumn = 0;
      }
      else
      {
        // Player is clicking and holding on a selected note or event to move the selection around.
        targetCursorMode = Grabbing;

        state.scrollMouseToGrid();

        // calculate distance between the position dragged to and the original position.
        var dragDistanceSteps:Float =
          Conductor.instance.getTimeInSteps(cursorSnappedMs).clamp(0, state.lastSnappedGridStep)
          - state.dragStartCursorStep;

        // Alt drags freely, off the snap.
        if (FlxG.keys.pressed.ALT)
        {
          dragDistanceSteps = cursorFractionalStep.clamp(0, state.lastSnappedGridStep) - state.dragStartCursorFractionalStep;
        }

        var selectionEndStep:Float = 0;
        for (note in state.currentNoteSelection)
        {
          selectionEndStep = Math.max(selectionEndStep, note.getStepTime() + note.getStepLength() + 1);
        }
        for (event in state.currentEventSelection)
        {
          selectionEndStep = Math.max(selectionEndStep, event.getStepTime() + 1);
        }

        var maxDragDistanceSteps:Float = Math.max(Math.floor((state.gridLengthInSteps - selectionEndStep) / state.noteSnapRatio) * state.noteSnapRatio, 0);
        if (dragDistanceSteps > maxDragDistanceSteps) dragDistanceSteps = maxDragDistanceSteps;

        var dragDistanceColumns:Int = cursorGridPos - state.dragStartCursorColumn;

        // Holding Alt places freely, and a sub-beat is made under each item that lands off the snap.
        var alignToSubBeats:Bool = FlxG.keys.pressed.ALT;

        if ((state.dragTargetCurrentColumn != dragDistanceColumns && overlapsGrid)
          || state.dragTargetCurrentStep != dragDistanceSteps
          || state.dragAlignToSubBeats != alignToSubBeats)
        {
          // Play a sound as we drag.
          state.playSound(Paths.sound('ui/editors/chart-editor/charting-sounds/note-place').toString());

          state.dragTargetCurrentStep = dragDistanceSteps;
          state.dragTargetCurrentColumn = dragDistanceColumns;
          state.dragAlignToSubBeats = alignToSubBeats;

          state.noteDisplayDirty = true;
        }
      }
    }
    else if (state.currentPlaceNoteData != null)
    {
      // Handle extending the note as you drag.

      var stepTime:Float = inline state.currentPlaceNoteData.getStepTime();
      var dragLengthSteps:Float = Conductor.instance.getTimeInSteps(cursorSnappedMs) - stepTime;
      var dragLengthMs:Float = dragLengthSteps * Conductor.instance.stepLengthMs;
      var dragLengthPixels:Float = ChartEditorTimeScale.lengthToPixels(state.currentPlaceNoteData.time, cursorSnappedMs - state.currentPlaceNoteData.time, dragLengthSteps);

      if (state.gridGhostHoldNote != null)
      {
        if (dragLengthSteps > 0)
        {
          if (state.dragLengthCurrent != dragLengthSteps)
          {
            state.playStretchySound();

            state.dragLengthCurrent = dragLengthSteps;
          }

          var sameHold:Bool = (state.gridGhostHoldNote.noteData == state.currentPlaceNoteData);

          state.gridGhostHoldNote.visible = true;
          state.gridGhostHoldNote.noteData = state.currentPlaceNoteData;
          state.gridGhostHoldNote.noteDirection = state.currentPlaceNoteData.getDirection();
          state.gridGhostHoldNote.setHeightDirectly(dragLengthPixels, sameHold);
          state.gridGhostHoldNote.noteStyle = NoteKindManager.getNoteStyleId(state.currentPlaceNoteData.kind, state.currentSongNoteStyle) ?? state.currentSongNoteStyle;
          state.gridGhostHoldNote.updateHoldNotePosition(state.renderedHoldNotes);
          state.gridGhostHoldNote.updateHoldNoteGraphic();
        }
        else
        {
          state.gridGhostHoldNote.setHeightDirectly(0);
        }
      }

      if (FlxG.mouse.justReleased)
      {
        if (dragLengthSteps > 0)
        {
          state.playSound(Paths.sound('ui/editors/chart-editor/charting-sounds/stretch-snap').toString());
          // Apply the new length.
          state.performCommand(new ExtendNoteLengthCommand(state.currentPlaceNoteData, dragLengthMs));
        }
        else
        {
          // Apply the new (zero) length if we are changing the length.
          if (state.currentPlaceNoteData.length > 0)
          {
            state.playSound(Paths.sound('ui/editors/chart-editor/charting-sounds/stretch-snap').toString());
            state.performCommand(new ExtendNoteLengthCommand(state.currentPlaceNoteData, 0));
          }
        }

        // Finished dragging. Release the note.
        state.currentPlaceNoteData = null;
        if (state.gridGhostHoldNote != null) state.gridGhostHoldNote.noteData = null;
      }
      else
      {
        state.scrollMouseToGrid(0.2);

        // Cursor should be a grabby hand.
        if (targetCursorMode == null) targetCursorMode = Grabbing;
      }
    }
    else if (overlapsRenderedPins)
    {
      // Cursor should be a pointer.
      targetCursorMode = Pointer;
    }
    else
    {
      if (FlxG.mouse.justPressed && !FlxG.keys.pressed.SHIFT)
      {
        // Just clicked to place a note.
        if (!state.isCursorOverHaxeUI && overlapsGrid)
        {
          // We clicked on the grid without moving the mouse.

          if (state.pressingControl())
          {
            // Control click to select/deselect an individual note.
            if (highlightedNote != null && highlightedNote.noteData != null)
            {
              if (state.isNoteSelected(highlightedNote.noteData))
              {
                state.performCommand(new DeselectItemsCommand([highlightedNote.noteData], []));
              }
              else
              {
                state.performCommand(new SelectItemsCommand([highlightedNote.noteData], []));
              }
            }
            else if (highlightedEvent != null && highlightedEvent.eventData != null)
            {
              if (state.isEventSelected(highlightedEvent.eventData))
              {
                state.performCommand(new DeselectItemsCommand([], [highlightedEvent.eventData]));
              }
              else
              {
                state.performCommand(new SelectItemsCommand([], [highlightedEvent.eventData]));
              }
            }
            else if (highlightedHoldNote != null && highlightedHoldNote.noteData != null)
            {
              if (state.isNoteSelected(highlightedHoldNote.noteData))
              {
                state.performCommand(new DeselectItemsCommand([highlightedHoldNote.noteData], []));
              }
              else
              {
                state.performCommand(new SelectItemsCommand([highlightedHoldNote.noteData], []));
              }
            }
            else
            {
              // Do nothing when control clicking nothing.
            }
          }
          else
          {
            if (highlightedNote != null && highlightedNote.noteData != null)
            {
              if (state.isNoteSelected(highlightedNote.noteData))
              {
                // Clicked a selected event, start dragging.
                state.dragTargetNote = highlightedNote;
                state.dragStartCursorStep = Conductor.instance.getTimeInSteps(cursorSnappedMs);
                state.dragStartCursorFractionalStep = cursorFractionalStep;
                state.dragStartCursorColumn = cursorGridPos;
              }
              else
              {
                // If you click an unselected note, and aren't holding Control, deselect everything else.
                state.performCommand(new SetItemSelectionCommand([highlightedNote.noteData], []));
                state.dragTargetNote = highlightedNote;
                state.dragStartCursorStep = Conductor.instance.getTimeInSteps(cursorSnappedMs);
                state.dragStartCursorFractionalStep = cursorFractionalStep;
                state.dragStartCursorColumn = cursorGridPos;
              }
            }
            else if (highlightedEvent != null && highlightedEvent.eventData != null)
            {
              if (state.isEventSelected(highlightedEvent.eventData))
              {
                // Clicked a selected event, start dragging.
                state.dragTargetEvent = highlightedEvent;
                state.dragStartCursorStep = Conductor.instance.getTimeInSteps(cursorSnappedMs);
                state.dragStartCursorFractionalStep = cursorFractionalStep;
                state.dragStartCursorColumn = cursorGridPos;
                state.dragEventWasSelected = true;
              }
              else
              {
                // If you click an unselected event, and aren't holding Control, deselect everything else.
                state.performCommand(new SetItemSelectionCommand([], [highlightedEvent.eventData]));
                state.dragTargetEvent = highlightedEvent;
                state.dragStartCursorStep = Conductor.instance.getTimeInSteps(cursorSnappedMs);
                state.dragStartCursorFractionalStep = cursorFractionalStep;
                state.dragStartCursorColumn = cursorGridPos;
                state.dragEventWasSelected = false;
              }
            }
            else if (highlightedHoldNote != null && highlightedHoldNote.noteData != null)
            {
              // Clicked a hold note, start dragging TO EXTEND NOTE LENGTH.
              state.currentPlaceNoteData = highlightedHoldNote.noteData;
            }
            else
            {
              var shouldDeselect:Bool = !state.wasCursorOverHaxeUI && (state.currentNoteSelection.length > 0 || state.currentEventSelection.length > 0);
              if (shouldDeselect)
              {
                state.performCommand(new DeselectAllItemsCommand());
              }
              // Click a blank space to place a note and select it.

              if (cursorGridPos == eventColumn)
              {
                // Create an event and place it in the chart.
                // TODO: Figure out configuring event data.
                var newEventData:SongEventData = new SongEventData(cursorSnappedMs, state.eventKindToPlace, state.eventDataToPlace.copy());

                state.performCommand(new AddEventsCommand([newEventData], state.pressingControl()));
              }
              else
              {
                // Create a note and place it in the chart.
                var newNoteData:SongNoteData = new SongNoteData(
                  cursorSnappedMs,
                  cursorColumn,
                  0,
                  state.noteKindToPlace,
                  ChartEditorNoteUtil.cloneNoteParams(state.noteParamsToPlace)
                );

                state.performCommand(new AddNotesCommand([newNoteData], state.pressingControl()));

                state.currentPlaceNoteData = newNoteData;
              }
            }
          }
        }
        else
        {
          // If we clicked and released outside the grid (or on HaxeUI), do nothing.
        }
      }

      var rightMouseUpdated:Bool = (FlxG.mouse.justPressedRight) || (FlxG.mouse.pressedRight && (FlxG.mouse.deltaX > 0 || FlxG.mouse.deltaY > 0));
      if (rightMouseUpdated && overlapsGrid)
      {
        // We right clicked on the grid.

        if (highlightedNote != null && highlightedNote.noteData != null)
        {
          // TODO: Handle the case of clicking on a sustain piece.
          if (FlxG.keys.pressed.SHIFT)
          {
            // Shift + Right click opens the context menu.
            // If we are clicking a large selection, open the Selection context menu, otherwise open the Note context menu.
            var isHighlightedNoteSelected:Bool = state.isNoteSelected(highlightedNote.noteData);
            var useSingleNoteContextMenu:Bool = (!isHighlightedNoteSelected) || (isHighlightedNoteSelected && state.currentNoteSelection.length == 1);
            // Show the context menu connected to the note.
            if (useSingleNoteContextMenu)
            {
              // Open the hold note menu instead if the highlighted note has a length value
              if (highlightedNote.noteData.length > 0) state.openHoldNoteContextMenu(FlxG.mouse.viewX, FlxG.mouse.viewY, highlightedNote.noteData);
              else
                state.openNoteContextMenu(FlxG.mouse.viewX, FlxG.mouse.viewY, highlightedNote.noteData);
            }
            else
            {
              state.openSelectionContextMenu(FlxG.mouse.viewX, FlxG.mouse.viewY);
            }
          }
          else
          {
            // Right click removes the note.
            state.performCommand(new RemoveNotesCommand([highlightedNote.noteData]));
          }
        }
        else if (highlightedEvent != null && highlightedEvent.eventData != null)
        {
          if (FlxG.keys.pressed.SHIFT)
          {
            // Shift + Right click opens the context menu.
            // If we are clicking a large selection, open the Selection context menu, otherwise open the Event context menu.
            var isHighlightedEventSelected:Bool = state.isEventSelected(highlightedEvent.eventData);
            var useSingleEventContextMenu:Bool = (!isHighlightedEventSelected) || (isHighlightedEventSelected && state.currentEventSelection.length == 1);
            if (useSingleEventContextMenu)
            {
              state.openEventContextMenu(FlxG.mouse.viewX, FlxG.mouse.viewY, highlightedEvent.eventData);
            }
            else
            {
              state.openSelectionContextMenu(FlxG.mouse.viewX, FlxG.mouse.viewY);
            }
          }
          else
          {
            // Right click removes the event.
            state.performCommand(new RemoveEventsCommand([highlightedEvent.eventData]));
          }
        }
        else if (highlightedHoldNote != null && highlightedHoldNote.noteData != null)
        {
          if (FlxG.keys.pressed.SHIFT)
          {
            // Shift + Right click opens the context menu.
            // If we are clicking a large selection, open the Selection context menu, otherwise open the Note context menu.
            var isHighlightedNoteSelected:Bool = state.isNoteSelected(highlightedHoldNote.noteData);
            var useSingleNoteContextMenu:Bool = (!isHighlightedNoteSelected) || (isHighlightedNoteSelected && state.currentNoteSelection.length == 1);
            // Show the context menu connected to the note.
            if (useSingleNoteContextMenu)
            {
              state.openHoldNoteContextMenu(FlxG.mouse.viewX, FlxG.mouse.viewY, highlightedHoldNote.noteData);
            }
            else
            {
              state.openSelectionContextMenu(FlxG.mouse.viewX, FlxG.mouse.viewY);
            }
          }
          else
          {
            // Right click removes hold from the note.
            state.playSound(Paths.sound('ui/editors/chart-editor/charting-sounds/stretch-snap').toString());
            state.performCommand(new ExtendNoteLengthCommand(highlightedHoldNote.noteData, 0));
          }
        }
        else if (FlxG.mouse.justPressedRight && state.noteKindToPlace != null)
        {
          state.noteKindToPlace = null;
          state.noteParamsToPlace = [];
          state.refreshToolbox(ChartEditorState.CHART_EDITOR_TOOLBOX_NOTE_DATA_LAYOUT);
          state.playSound(Paths.sound('ui/editors/chart-editor/charting-sounds/note-erase').toString());
        }
      }

      var isOrWillSelect =
        overlapsSelection
        || state.dragTargetNote != null
        || state.dragTargetEvent != null
        || overlapsRenderedNotes
        || overlapsRenderedHoldNotes
        || overlapsRenderedEvents;
      // Handle grid cursor.
      if (!state.isCursorOverHaxeUI && overlapsGrid && !isOrWillSelect && !state.gridPlayheadScrollAreaPressed)
      {
        // Indicate that we can place a note here.

        if (cursorGridPos == eventColumn)
        {
          if (state.gridGhostEvent == null) throw 'ERROR: Tried to handle cursor, but gridGhostEvent is null! Check ChartEditorState.buildGrid()';

          var eventData:SongEventData = state.gridGhostEvent.eventData != null ? state.gridGhostEvent.eventData : new SongEventData(cursorMs, state.eventKindToPlace, null);

          if (state.eventKindToPlace != eventData.eventKind)
          {
            eventData.eventKind = state.eventKindToPlace;
          }
          eventData.time = cursorSnappedMs;

          state.gridGhostEvent.visible = true;
          state.gridGhostEvent.eventData = eventData;
          state.gridGhostEvent.updateEventPosition(state.renderedEvents);

          targetCursorMode = Cell;
        }
        else
        {
          if (state.gridGhostNote == null) throw 'ERROR: Tried to handle cursor, but gridGhostNote is null! Check ChartEditorState.buildGrid()';

          var noteData:SongNoteData = state.gridGhostNote.noteData != null ? state.gridGhostNote.noteData : new SongNoteData(
            cursorMs,
            cursorColumn,
            0,
            state.noteKindToPlace,
            ChartEditorNoteUtil.cloneNoteParams(state.noteParamsToPlace)
          );

          if (cursorColumn != noteData.data || state.noteKindToPlace != noteData.kind || state.noteParamsToPlace != noteData.params)
          {
            noteData.kind = state.noteKindToPlace;
            noteData.params = state.noteParamsToPlace;
            noteData.data = cursorColumn;
            state.gridGhostNote.noteStyle = NoteKindManager.getNoteStyleId(noteData.kind, state.currentSongNoteStyle) ?? state.currentSongNoteStyle;
            state.gridGhostNote.playNoteAnimation();
          }
          noteData.time = cursorSnappedMs;

          state.gridGhostNote.visible = true;
          state.gridGhostNote.noteData = noteData;
          state.gridGhostNote.updateNotePosition(state.renderedNotes);

          targetCursorMode = Cell;
        }
      }
    }

    if (targetCursorMode == null)
    {
      if (state.activeToolboxes.get(ChartEditorState.CHART_EDITOR_TOOLBOX_PLAYER_PREVIEW_LAYOUT)?.hitTest(FlxG.mouse.viewX, FlxG.mouse.viewY) == true
        || state.activeToolboxes.get(ChartEditorState.CHART_EDITOR_TOOLBOX_OPPONENT_PREVIEW_LAYOUT)?.hitTest(FlxG.mouse.viewX, FlxG.mouse.viewY) == true)
      {
        targetCursorMode = Pointer;
      }
      else if (FlxG.mouse.pressed)
      {
        if (overlapsSelection)
        {
          targetCursorMode = Grabbing;
        }
      }
      else
      {
        if (!state.isCursorOverHaxeUI)
        {
          if (state.notePreview != null && FlxG.mouse.overlaps(state.notePreview))
          {
            targetCursorMode = Pointer;
          }
          else if (state.measureTicks != null && FlxG.mouse.overlaps(state.measureTicks))
          {
            targetCursorMode = Pointer;
          }
          else if (overlapsSelection)
          {
            targetCursorMode = Pointer;
          }
          else if (overlapsRenderedNotes)
          {
            targetCursorMode = Pointer;
          }
          else if (overlapsRenderedHoldNotes)
          {
            targetCursorMode = Pointer;
          }
          else if (overlapsRenderedEvents)
          {
            targetCursorMode = Pointer;
          }
          else if (overlapsGrid)
          {
            targetCursorMode = Cell;
          }
          else if (overlapsHealthIcons)
          {
            targetCursorMode = Pointer;
          }
        }
      }
    }

    // Actually set the cursor mode to the one we specified earlier.
    Cursor.cursorMode = targetCursorMode ?? Default;
  }
}
#end
