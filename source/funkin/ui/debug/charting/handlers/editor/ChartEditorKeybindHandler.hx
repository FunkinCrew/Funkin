package funkin.ui.debug.charting.handlers.editor;

#if FEATURE_CHART_EDITOR
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import funkin.assets.ValidatedPaths as Paths;
import funkin.data.song.SongData.SongEventData;
import funkin.data.song.SongData.SongNoteData;
import funkin.data.song.SongDataUtils;
import funkin.save.Save;
import funkin.ui.debug.charting.commands.comments.AddCommentCommand;
import funkin.ui.debug.charting.commands.events.AddEventsCommand;
import funkin.ui.debug.charting.commands.notes.AddNotesCommand;
import funkin.ui.debug.charting.commands.items.CopyItemsCommand;
import funkin.ui.debug.charting.commands.items.CutItemsCommand;
import funkin.ui.debug.charting.commands.selection.DeselectAllItemsBetweenTimeCommand;
import funkin.ui.debug.charting.commands.selection.DeselectAllItemsCommand;
import funkin.ui.debug.charting.commands.notes.ExtendNoteLengthCommand;
import funkin.ui.debug.charting.commands.notes.FlipNotesCommand;
import funkin.ui.debug.charting.commands.selection.InvertSelectedItemsCommand;
import funkin.ui.debug.charting.commands.notes.MirrorNotesCommand;
import funkin.ui.debug.charting.commands.notes.ModifyNotesLengthCommand;
import funkin.ui.debug.charting.commands.items.PasteItemsCommand;
import funkin.ui.debug.charting.selection.ChartEditorSelectableItems;
import funkin.ui.debug.charting.commands.events.RemoveEventsCommand;
import funkin.ui.debug.charting.commands.items.RemoveItemsCommand;
import funkin.ui.debug.charting.commands.notes.RemoveNotesCommand;
import funkin.ui.debug.charting.commands.notes.RemoveStackedNotesCommand;
import funkin.ui.debug.charting.commands.selection.SelectAllItemsBetweenTimeCommand;
import funkin.ui.debug.charting.commands.selection.SelectAllItemsCommand;
import funkin.ui.debug.charting.commands.selection.SelectItemsCommand;
import funkin.ui.debug.charting.toolboxes.ChartEditorListKeyTarget;
import haxe.ui.containers.menus.Menu;
using Lambda;

@:access(haxe.ui.tooltips.ToolTipManager)
@:access(funkin.audio.VoicesGroup)
@:access(funkin.ui.debug.charting.ChartEditorState)
class ChartEditorKeybindHandler
{
  /**
   * Handle keybinds for scrolling the chart editor grid.
   */
  public static function handleScrollKeybinds(state:ChartEditorState):Void
  {
    // Don't scroll when the user is interacting with the UI, unless a playbar button (the << >> ones) is pressed.
    if ((state.isHaxeUIFocused || (state.isCursorOverHaxeUI && !state.canScrollComment && state.scrollAnchorScreenPos == null)) && state.playbarButtonPressed == null) return;

    var scrollAmount:Float = 0; // Amount to scroll the grid.
    var playheadAmount:Float = 0; // Amount to scroll the playhead relative to the grid.
    var shouldPause:Bool = false; // Whether to pause the song when scrolling.
    var shouldEase:Bool = false; // Whether to ease the scroll.
    var shouldSnap:Bool = false; // Whether the move is a fixed number of grid steps, so the playhead should land on the grid.

    // Handle scroll anchor
    if (state.scrollAnchorScreenPos != null)
    {
      var currentScreenPos = FlxPoint.weak(FlxG.mouse.x, FlxG.mouse.y);
      var distance = currentScreenPos - state.scrollAnchorScreenPos;

      var verticalDistance = distance.y;

      // How much scrolling should be done based on the distance of the cursor from the anchor.
      final ANCHOR_SCROLL_SPEED = 12;

      scrollAmount = ANCHOR_SCROLL_SPEED * verticalDistance * FlxG.elapsed;
      shouldPause = true;
    }

    // Ctrl+Mouse Wheel = Zoom
    if (FlxG.mouse.deltaWheel.y != 0 && state.pressingControl())
    {
      handleZoomWheel(state, FlxG.mouse.deltaWheel.y);
    }
    // Mouse Wheel = Scroll
    else if (FlxG.mouse.deltaWheel.y != 0)
    {
      scrollAmount = -ChartEditorTimeScale.currentStepPixels() * FlxG.mouse.deltaWheel.y;
      shouldPause = true;
      shouldSnap = true;
    }

    // Up Arrow = Scroll Up
    if (state.upKeyHandler.activated && state.currentLiveInputStyle != WASDKeys)
    {
      scrollAmount = -ChartEditorTimeScale.currentStepPixels() * 4;
      shouldPause = true;
      shouldSnap = true;
    }
    // Down Arrow = Scroll Down
    if (state.downKeyHandler.activated && state.currentLiveInputStyle != WASDKeys)
    {
      scrollAmount = ChartEditorTimeScale.currentStepPixels() * 4;
      shouldPause = true;
      shouldSnap = true;
    }

    // W = Scroll Up (doesn't work with Ctrl+Scroll)
    if (state.wKeyHandler.activated && state.currentLiveInputStyle != WASDKeys && !state.pressingControl())
    {
      scrollAmount = -ChartEditorTimeScale.currentStepPixels() * 4;
      shouldPause = true;
      shouldSnap = true;
    }
    // S = Scroll Down (doesn't work with Ctrl+Scroll)
    if (state.sKeyHandler.activated && state.currentLiveInputStyle != WASDKeys && !state.pressingControl())
    {
      scrollAmount = ChartEditorTimeScale.currentStepPixels() * 4;
      shouldPause = true;
      shouldSnap = true;
    }

    // GAMEPAD LEFT STICK UP = Scroll Up by 1 note snap
    if (state.leftStickUpGamepadHandler.activated)
    {
      scrollAmount = -ChartEditorTimeScale.currentStepPixels() * state.noteSnapRatio;
      shouldPause = true;
      shouldSnap = true;
    }
    // GAMEPAD LEFT STICK DOWN = Scroll Down by 1 note snap
    if (state.leftStickDownGamepadHandler.activated)
    {
      scrollAmount = ChartEditorTimeScale.currentStepPixels() * state.noteSnapRatio;
      shouldPause = true;
      shouldSnap = true;
    }

    // GAMEPAD RIGHT STICK UP = Scroll Up by 1 note snap (playhead only)
    if (state.rightStickUpGamepadHandler.activated)
    {
      playheadAmount = -ChartEditorTimeScale.currentStepPixels() * state.noteSnapRatio;
      shouldPause = true;
      shouldSnap = true;
    }
    // GAMEPAD RIGHT STICK DOWN = Scroll Down by 1 note snap (playhead only)
    if (state.rightStickDownGamepadHandler.activated)
    {
      playheadAmount = ChartEditorTimeScale.currentStepPixels() * state.noteSnapRatio;
      shouldPause = true;
      shouldSnap = true;
    }

    var funcJumpUp = (playheadOnly:Bool) ->
    {
      var playheadPosition:Float = ChartEditorTimeScale.pixelsToMs(state.currentScrollEase + state.playheadPositionInPixels);
      var currentPositionMeasure:Float = Conductor.instance.getTimeInMeasures(playheadPosition);
      var currentPositionMeasureFlooredInMs:Float = Conductor.instance.getMeasureTimeInMs(Math.floor(currentPositionMeasure));
      var targetScrollPosition:Float = 0;
      if (FlxMath.inBounds(
        playheadPosition,
        currentPositionMeasureFlooredInMs - 1,
        currentPositionMeasureFlooredInMs + Conductor.instance.getTypeLengthAtMs(playheadPosition, 'step')
      ))
      {
        targetScrollPosition = Conductor.instance.getMeasureTimeInMs(Math.floor(currentPositionMeasure - 1));
      }
      else
      {
        targetScrollPosition = currentPositionMeasureFlooredInMs;
      }

      targetScrollPosition = ChartEditorTimeScale.msToPixels(targetScrollPosition);
      playheadPosition = ChartEditorTimeScale.msToPixels(playheadPosition);

      if (playheadOnly)
      {
        playheadAmount = targetScrollPosition - playheadPosition;
      }
      else
      {
        scrollAmount = targetScrollPosition - playheadPosition;
      }
    }

    // PAGE UP = Jump up to nearest measure
    // GAMEPAD LEFT STICK LEFT = Jump up to nearest measure
    if (state.pageUpKeyHandler.activated || state.leftStickLeftGamepadHandler.activated)
    {
      funcJumpUp(false);
      shouldPause = true;
    }
    if (state.rightStickLeftGamepadHandler.activated)
    {
      funcJumpUp(true);
      shouldPause = true;
    }
    if (state.playbarButtonPressed == 'playbarBack')
    {
      state.playbarButtonPressed = '';
      funcJumpUp(false);
      shouldPause = true;
    }

    var funcJumpDown = (playheadOnly:Bool) ->
    {
      var playheadPosition:Float = ChartEditorTimeScale.pixelsToMs(state.currentScrollEase + state.playheadPositionInPixels);
      var currentPositionMeasure:Float = Conductor.instance.getTimeInMeasures(playheadPosition);
      var targetScrollPosition:Float = Conductor.instance.getMeasureTimeInMs(Math.floor(currentPositionMeasure + 1.0001));
      // Now, why the hell is that .0001 there? It's to fix floating point bullshit that would result in "floor(measure + 1)" giving back
      // the SAME MEASURE NUMBER that you can see in the Flixel F2 debugger.
      // tldr: we wouldn't actually jump to the next measure.

      targetScrollPosition = ChartEditorTimeScale.msToPixels(targetScrollPosition);
      playheadPosition = ChartEditorTimeScale.msToPixels(playheadPosition);

      if (playheadOnly)
      {
        playheadAmount = targetScrollPosition - playheadPosition;
      }
      else
      {
        scrollAmount = targetScrollPosition - playheadPosition;
      }
    }

    // PAGE DOWN = Jump down to nearest measure
    // GAMEPAD LEFT STICK RIGHT = Jump down to nearest measure
    if (state.pageDownKeyHandler.activated || state.leftStickRightGamepadHandler.activated)
    {
      funcJumpDown(false);
      shouldPause = true;
    }
    if (state.rightStickRightGamepadHandler.activated)
    {
      funcJumpDown(true);
      shouldPause = true;
    }
    if (state.playbarButtonPressed == 'playbarForward')
    {
      state.playbarButtonPressed = '';
      funcJumpDown(false);
      shouldPause = true;
    }

    // SHIFT + Scroll = Scroll Fast
    // GAMEPAD LEFT STICK CLICK + Scroll = Scroll Fast
    if (FlxG.keys.pressed.SHIFT || (FlxG.gamepads.firstActive?.pressed?.LEFT_STICK_CLICK ?? false))
    {
      scrollAmount *= 2;
    }
    // CONTROL + Scroll = Scroll Precise
    if (state.pressingControl())
    {
      scrollAmount /= 4;
    }

    // Alt + Drag = Scroll but move the playhead the same amount.
    if (FlxG.keys.pressed.ALT)
    {
      playheadAmount = scrollAmount;
      scrollAmount = 0;
      shouldPause = false;
    }

    // HOME = Scroll to Top
    if (!FlxG.keys.pressed.SHIFT && FlxG.keys.justPressed.HOME)
    {
      // Scroll amount is the difference between the current position and the top.
      scrollAmount = 0 - state.scrollPositionInPixels;
      playheadAmount = 0 - state.playheadPositionInPixels;
      shouldPause = true;
    }
    if (state.playbarButtonPressed == 'playbarStart')
    {
      state.playbarButtonPressed = '';
      scrollAmount = 0 - state.scrollPositionInPixels;
      playheadAmount = 0 - state.playheadPositionInPixels;
      shouldPause = true;
    }

    // END = Scroll to Bottom
    if (!FlxG.keys.pressed.SHIFT && FlxG.keys.justPressed.END)
    {
      // Scroll amount is the difference between the current position and the bottom.
      scrollAmount = state.songLengthInPixels - state.scrollPositionInPixels;
      shouldPause = true;
    }
    if (state.playbarButtonPressed == 'playbarEnd')
    {
      state.playbarButtonPressed = '';
      scrollAmount = state.songLengthInPixels - state.scrollPositionInPixels;
      shouldPause = true;
    }

    shouldEase = true;
    if (shouldPause && (state.audioInstTrack?.isPlaying || state.audioVocalTrackGroup.playing)) state.stopAudioPlayback(); // Only do this once, not every frame

    if (shouldSnap && state.currentScrollEase != null)
    {
      var playheadAbsolute:Float = state.currentScrollEase + state.playheadPositionInPixels;
      if (scrollAmount != 0) scrollAmount = state.snapStepMove(playheadAbsolute, scrollAmount) - playheadAbsolute;
      if (playheadAmount != 0) playheadAmount = state.snapStepMove(playheadAbsolute, playheadAmount) - playheadAbsolute;
    }

    // Resync the conductor and audio tracks.
    if (playheadAmount != 0) state.playheadPositionInPixels += playheadAmount;

    if (scrollAmount != 0) state.currentScrollEase += scrollAmount;
  }

  public static function releaseScrollAnchor(state:ChartEditorState):Void
  {
    state.scrollAnchorScreenPos.put();
    state.scrollAnchorScreenPos = null;

    if (state.currentScrollEase == null) return;

    // Snapped in steps rather than pixels.
    var playheadAbsolute:Float = state.currentScrollEase + state.playheadPositionInPixels;
    var gridSteps:Float = ChartEditorTimeScale.pixelsToStep(playheadAbsolute) / state.noteSnapRatio;
    var targetSteps:Float = Math.fround(gridSteps);
    if (state.currentScrollEase > state.scrollPositionInPixels) targetSteps = Math.fceil(gridSteps - 0.001);
    else if (state.currentScrollEase < state.scrollPositionInPixels) targetSteps = Math.ffloor(gridSteps + 0.001);
    var playheadStep:Float = ChartEditorTimeScale.pixelsToStep(playheadAbsolute);
    var snappedStep:Float = state.snapToSubBeat(playheadStep, targetSteps * state.noteSnapRatio);
    state.currentScrollEase += ChartEditorTimeScale.stepToPixels(snappedStep) - playheadAbsolute;
  }

  /**
   * Snap a move to the nearest grid step, based on the current note snap ratio.
   * @param fromPixels The absolute position of the playhead in the song, in pixels.
   * @param amountPixels How far the move goes, in pixels.
   * @return The absolute position to land on, in pixels.
   */
  public static function snapStepMove(state:ChartEditorState, fromPixels:Float, amountPixels:Float):Float
  {
    // Snapped in steps rather than pixels, since with constant scroll the two don't line up.
    var amountSteps:Float = amountPixels / ChartEditorTimeScale.currentStepPixels();
    var gridSteps:Float = Math.min(state.noteSnapRatio, Math.abs(amountSteps));
    if (gridSteps <= 0) return fromPixels + amountPixels;
    var fromStep:Float = ChartEditorTimeScale.pixelsToStep(fromPixels);
    var targetStep:Float = Math.fround((fromStep + amountSteps) / gridSteps) * gridSteps;

    targetStep = state.firstSubBeatStepBetween(fromStep, targetStep) ?? targetStep;
    return ChartEditorTimeScale.stepToPixels(targetStep);
  }

  /**
   * Handle changing the note snapping level.
   */
  public static function handleSnap(state:ChartEditorState):Void
  {
    if (state.currentLiveInputStyle != WASDKeys)
    {
      // Shift + Left/Right changes the playback speed instead.
      if (FlxG.keys.justPressed.LEFT && !state.pressingControl() && !FlxG.keys.pressed.SHIFT)
      {
        state.noteSnapQuantIndex--;
        if (state.noteSnapQuantIndex < 0) state.noteSnapQuantIndex = ChartEditorState.SNAP_QUANTS.length - 1;
      }

      if (FlxG.keys.justPressed.RIGHT && !state.pressingControl() && !FlxG.keys.pressed.SHIFT)
      {
        state.noteSnapQuantIndex++;
        if (state.noteSnapQuantIndex >= ChartEditorState.SNAP_QUANTS.length) state.noteSnapQuantIndex = 0;
      }
    }

    if (FlxG.keys.justPressed.LBRACKET)
    {
      state.noteSnapQuantIndex--;
      if (state.noteSnapQuantIndex < 0) state.noteSnapQuantIndex = ChartEditorState.SNAP_QUANTS.length - 1;
    }
    if (FlxG.keys.justPressed.RBRACKET)
    {
      state.noteSnapQuantIndex++;
      if (state.noteSnapQuantIndex >= ChartEditorState.SNAP_QUANTS.length) state.noteSnapQuantIndex = 0;
    }
  }

  public static function handlePlayhead(state:ChartEditorState):Void
  {
    // Place notes at the playhead with the keyboard.
    for (note => key in ChartEditorState.LIVE_INPUT_KEYS[state.currentLiveInputStyle])
    {
      if (FlxG.keys.checkStatus(key, JUST_PRESSED)) state.placeNoteAtPlayhead(note)
      else if (FlxG.keys.checkStatus(key, JUST_RELEASED)) state.finishPlaceNoteAtPlayhead(note);
    }

    // Place events at playhead.
    if (FlxG.keys.justPressed.COMMA) state.placeEventAtPlayhead(true);
    if (FlxG.keys.justPressed.PERIOD) state.placeEventAtPlayhead(false);

    state.updatePlayheadGhostHoldNotes();
  }

  public static function placeNoteAtPlayhead(state:ChartEditorState, column:Int):Void
  {
    // SHIFT + press or LEFT_SHOULDER + press to remove notes instead of placing them.
    var removeNoteInstead:Bool = FlxG.keys.pressed.SHIFT || (FlxG.gamepads.firstActive?.pressed?.LEFT_SHOULDER ?? false);

    var playheadFractionalStep:Float = ChartEditorTimeScale.pixelsToStep(state.scrollPositionInPixels + state.playheadPositionInPixels);
    // Notes are centered on their line, so the nearest snap is the one the playhead is over.
    var playheadSnappedStep:Float = Math.fround(playheadFractionalStep / state.noteSnapRatio) * state.noteSnapRatio;
    playheadSnappedStep = Math.min(playheadSnappedStep, state.lastSnappedGridStep);
    var playheadSnappedMs:Float = Conductor.instance.getStepTimeInMs(playheadSnappedStep);

    // Look for notes within half a snap of the playhead, since placing rounds to the nearest snap.
    var halfSnapMs:Float = Conductor.instance.getTypeLengthAtMs(playheadSnappedMs, 'step') * state.noteSnapRatio / 2;
    var notesAtPos:Array<SongNoteData> = SongDataUtils.getNotesInTimeRange(state.currentSongChartNoteData, playheadSnappedMs - halfSnapMs, playheadSnappedMs + halfSnapMs);
    notesAtPos = SongDataUtils.getNotesWithData(notesAtPos, [column]);

    if (notesAtPos.length > 0)
    {
      trace('Removing existing note at position. ${column}');
      state.performCommand(new RemoveNotesCommand(notesAtPos));
    }
    else if (!removeNoteInstead)
    {
      trace('Placing note. ${column}');
      var newNoteData:SongNoteData = new SongNoteData(playheadSnappedMs, column, 0, state.noteKindToPlace, ChartEditorNoteUtil.cloneNoteParams(state.noteParamsToPlace));
      state.performCommand(new AddNotesCommand([newNoteData], state.pressingControl()));
      state.currentLiveInputPlaceNoteData[column] = newNoteData;
    }
  }

  public static function placeEventAtPlayhead(state:ChartEditorState, isOpponent:Bool):Void
  {
    // SHIFT + press or LEFT_SHOULDER + press to remove events instead of placing them.
    var removeEventInstead:Bool = FlxG.keys.pressed.SHIFT || (FlxG.gamepads.firstActive?.pressed?.LEFT_SHOULDER ?? false);

    var playheadFractionalStep:Float = ChartEditorTimeScale.pixelsToStep(state.scrollPositionInPixels + state.playheadPositionInPixels);
    var playheadSnappedStep:Float = Math.fround(playheadFractionalStep / state.noteSnapRatio) * state.noteSnapRatio;
    playheadSnappedStep = Math.min(playheadSnappedStep, state.lastSnappedGridStep);
    var playheadSnappedMs:Float = Conductor.instance.getStepTimeInMs(playheadSnappedStep);

    // Look for events within 1 step of the playhead.
    var eventsAtPos:Array<SongEventData> = SongDataUtils.getEventsInTimeRange(
      state.currentSongChartEventData,
      playheadSnappedMs,
      playheadSnappedMs + Conductor.instance.getTypeLengthAtMs(playheadSnappedMs, 'step') * state.noteSnapRatio
    );
    eventsAtPos = SongDataUtils.getEventsWithKind(eventsAtPos, ['FocusCamera']);

    if (eventsAtPos.length == 0 && !removeEventInstead)
    {
      trace('Placing event ${isOpponent}');
      var newEventData:SongEventData = new SongEventData(playheadSnappedMs, 'FocusCamera', {
        char: isOpponent ? 1 : 0,
      });
      state.performCommand(new AddEventsCommand([newEventData], state.pressingControl()));
    }
    else if (removeEventInstead)
    {
      trace('Removing existing event at position.');
      state.performCommand(new RemoveEventsCommand(eventsAtPos));
    }
    else
    {
      trace('Already an event there.');
    }
  }

  public static function finishPlaceNoteAtPlayhead(state:ChartEditorState, column:Int):Void
  {
    if (state.currentLiveInputPlaceNoteData[column] == null) return;

    var playheadFractionalStep:Float = ChartEditorTimeScale.pixelsToStep(state.scrollPositionInPixels + state.playheadPositionInPixels);
    var playheadSnappedStep:Float = Math.fround(playheadFractionalStep / state.noteSnapRatio) * state.noteSnapRatio;
    playheadSnappedStep = Math.min(playheadSnappedStep, state.lastSnappedGridStep);
    var playheadSnappedMs:Float = Conductor.instance.getStepTimeInMs(playheadSnappedStep);

    var newNoteLength:Float = playheadSnappedMs - state.currentLiveInputPlaceNoteData[column].time;
    trace('finishPlace newNoteLength: ${newNoteLength}');

    if (newNoteLength < Conductor.instance.stepLengthMs)
    {
      // Don't extend the note if it's too short.
      trace('Not extending note. ${column}');
      state.currentLiveInputPlaceNoteData[column] = null;
      state.gridPlayheadGhostHoldNotes[column].noteData = null;
    }
    else
    {
      // Extend the note to the playhead position.
      trace('Extending note. ${column}');
      state.playSound(Paths.sound('ui/editors/chart-editor/charting-sounds/stretch-snap').toString());
      state.performCommand(new ExtendNoteLengthCommand(state.currentLiveInputPlaceNoteData[column], newNoteLength));
      state.currentLiveInputPlaceNoteData[column] = null;
      state.gridPlayheadGhostHoldNotes[column].noteData = null;
    }
  }

  /**
   * Handle keybinds for File menu items.
   */
  public static function handleFileKeybinds(state:ChartEditorState):Void
  {
    // CTRL + N = New Chart
    if (state.pressingControl() && FlxG.keys.justPressed.N && !state.isHaxeUIDialogOpen && !FlxG.keys.pressed.SHIFT && !FlxG.keys.pressed.ALT)
    {
      state.openWelcomeDialog(true);
    }

    // CTRL + O = Open Chart
    if (state.pressingControl() && FlxG.keys.justPressed.O && !state.isHaxeUIDialogOpen)
    {
      state.openBrowseFNFC(true);
    }

    if (state.pressingControl() && FlxG.keys.justPressed.S && !state.isHaxeUIDialogOpen)
    {
      if (state.currentWorkingFilePath == null || FlxG.keys.pressed.SHIFT)
      {
        // CTRL + SHIFT + S = Save As
        state.exportCurrentChartToFNFC(false, null, function(path:String)
        {
          // CTRL + SHIFT + S Successful
          state.success('Saved Chart', 'Chart saved successfully to ${path}.');
        }, function()
        {
          // CTRL + SHIFT + S Cancelled
        });
      }
      else
      {
        // CTRL + S = Save Chart
        state.exportCurrentChartToFNFC(true, state.currentWorkingFilePath);
        state.success('Saved Chart', 'Chart saved successfully to ${state.currentWorkingFilePath}.');
      }
    }

    // CTRL + Q = Quit to Menu
    if (state.pressingControl() && FlxG.keys.justPressed.Q)
    {
      state.quitChartEditor(true);
    }
  }

  public static function handleListKeybinds(state:ChartEditorState):Void
  {
    var target:Null<ChartEditorListKeyTarget> = state.listKeyTarget;
    if (target == null) return;
    if (!target.isListShown() || (FlxG.mouse.justPressed || FlxG.mouse.justPressedRight) && !target.containsMouse())
    {
      state.listKeyTarget = null;
      return;
    }
    // Typing in a text field, such as a rename.
    if (state.isHaxeUIFocused) return;

    if (state.pressingControl() && FlxG.keys.justPressed.C) target.copySelection();
    if (state.pressingControl() && FlxG.keys.justPressed.V) target.pasteSelection();

    var delete:Bool = FlxG.keys.justPressed.DELETE;
    #if mac
    delete = delete || FlxG.keys.justPressed.BACKSPACE;
    #end
    if (delete) target.deleteSelection();
  }

  /**
   * Undo and redo, which also work while a panel has focus.
   */
  public static function handleUndoRedoKeybinds(state:ChartEditorState):Void
  {
    // CTRL + Z = Undo
    if (state.undoKeyHandler.activated)
    {
      state.undoLastCommand();
    }

    // CTRL + Y = Redo
    if (state.redoKeyHandler.activated)
    {
      state.redoLastCommand();
    }
  }

  /**
   * How much wheel movement makes one zoom step.
   */
  static final ZOOM_WHEEL_STEP:Float = 1;

  /**
   * The shortest time between zoom steps, in seconds.
   */
  static final ZOOM_WHEEL_COOLDOWN:Float = 0.1;

  /**
   * Wheel movement that hasn't added up to a zoom step yet.
   */
  static var zoomWheelAmount:Float = 0;

  static var lastZoomStepTime:Float = 0;
  static var lastZoomWheelTime:Float = 0;

  static function handleZoomWheel(state:ChartEditorState, delta:Float):Void
  {
    var now:Float = haxe.Timer.stamp();
    if (now - lastZoomWheelTime > 0.3 || (zoomWheelAmount != 0 && (delta > 0) != (zoomWheelAmount > 0))) zoomWheelAmount = 0;
    lastZoomWheelTime = now;
    zoomWheelAmount += delta;

    if (Math.abs(zoomWheelAmount) < ZOOM_WHEEL_STEP || now - lastZoomStepTime < ZOOM_WHEEL_COOLDOWN) return;
    state.zoomLevelIndex += zoomWheelAmount > 0 ? 1 : -1;
    zoomWheelAmount = 0;
    lastZoomStepTime = now;
  }

  /**
   * Handle keybinds for edit menu items.
   */
  public static function handleEditKeybinds(state:ChartEditorState):Void
  {
    var listHasKeys:Bool = state.listKeyTarget != null;

    // CTRL + C = Copy
    if (!listHasKeys && state.pressingControl() && FlxG.keys.justPressed.C)
    {
      state.performCommand(new CopyItemsCommand(state.currentNoteSelection, state.currentEventSelection));
    }

    // CTRL + X = Cut
    if (!listHasKeys && state.pressingControl() && FlxG.keys.justPressed.X)
    {
      // Cut selected notes.
      state.performCommand(new CutItemsCommand(state.currentNoteSelection, state.currentEventSelection));
    }

    // CTRL + V = Paste
    if (!listHasKeys && state.pressingControl() && FlxG.keys.justPressed.V && !ChartEditorSelectableItems.pasteLastCopied())
    {
      // CTRL + SHIFT + V = Paste Unsnapped.
      var targetMs:Float = if (FlxG.keys.pressed.SHIFT)
      {
        state.scrollPositionInMs + state.playheadPositionInMs;
      }
      else
      {
        var targetMs:Float = state.scrollPositionInMs + state.playheadPositionInMs;
        var targetStep:Float = Conductor.instance.getTimeInSteps(targetMs);
        var targetSnappedStep:Float = Math.floor(targetStep / state.noteSnapRatio) * state.noteSnapRatio;
        var targetSnappedMs:Float = Conductor.instance.getStepTimeInMs(targetSnappedStep);
        targetSnappedMs;
      }
      state.performCommand(new PasteItemsCommand(targetMs));
    }

    // DELETE = Delete
    var delete:Bool = FlxG.keys.justPressed.DELETE;

    // on macbooks, Delete == backspace
    #if mac
    delete = delete || FlxG.keys.justPressed.BACKSPACE;
    #end

    if (delete && !listHasKeys)
    {
      var noteSelection = state.currentNoteSelection.length > 0;
      var eventSelection = state.currentEventSelection.length > 0;

      // Shift to delete stacked notes
      if (FlxG.keys.pressed.SHIFT)
      {
        if (eventSelection && !noteSelection)
        {
          state.performCommand(new RemoveEventsCommand(state.currentEventSelection));
        }
        else
        {
          state.performCommand(new RemoveStackedNotesCommand(noteSelection ? state.currentNoteSelection : null));
        }
      }
      else
      {
        // Delete selected items.
        if (noteSelection && eventSelection)
        {
          state.performCommand(new RemoveItemsCommand(state.currentNoteSelection, state.currentEventSelection));
        }
        else if (noteSelection)
        {
          state.performCommand(new RemoveNotesCommand(state.currentNoteSelection));
        }
        else if (eventSelection)
        {
          state.performCommand(new RemoveEventsCommand(state.currentEventSelection));
        }
      }
    }

    // E = Increase Notes Length
    if (!state.pressingControl() && FlxG.keys.justPressed.E && state.currentNoteSelection.length > 0)
    {
      // Increase selected notes length according to the current note snap level
      state.performCommand(new ModifyNotesLengthCommand(state.currentNoteSelection, state.noteSnapRatio * Conductor.instance.stepLengthMs));
    }

    // Q = Decrease Notes Length
    if (!state.pressingControl() && FlxG.keys.justPressed.Q && state.currentNoteSelection.length > 0)
    {
      // Decrease selected notes length according to the current note snap level
      state.performCommand(new ModifyNotesLengthCommand(state.currentNoteSelection, state.noteSnapRatio * Conductor.instance.stepLengthMs * -1));
    }

    // CTRL + F = Flip Notes
    if (state.pressingControl() && FlxG.keys.justPressed.F)
    {
      // Flip selected notes.
      state.performCommand(new FlipNotesCommand(state.currentNoteSelection));
    }

    // CTRL + SHIFT + ALT + M = Mirror Notes along XY axis
    if (FlxG.keys.pressed.CONTROL && FlxG.keys.pressed.SHIFT && FlxG.keys.pressed.ALT && FlxG.keys.justPressed.M)
    {
      state.performCommand(
        new MirrorNotesCommand(state.currentNoteSelection, state.menubarItemMirrorFlipWithinStrumline.selected, !state.menubarItemMirrorFlipWithinStrumline.selected, true, true)
      );
    }

    // CTRL + SHIFT + M = Mirror Notes along X axis
    if (!FlxG.keys.pressed.ALT && FlxG.keys.pressed.CONTROL && FlxG.keys.pressed.SHIFT && FlxG.keys.justPressed.M)
    {
      state.performCommand(
        new MirrorNotesCommand(
          state.currentNoteSelection,
          state.menubarItemMirrorFlipWithinStrumline.selected,
          !state.menubarItemMirrorFlipWithinStrumline.selected,
          true,
          false
        )
      );
    }

    // CTRL + ALT + M = Mirror Notes along the Y axis
    if (!FlxG.keys.pressed.SHIFT && FlxG.keys.pressed.CONTROL && FlxG.keys.pressed.ALT && FlxG.keys.justPressed.M)
    {
      state.performCommand(
        new MirrorNotesCommand(
          state.currentNoteSelection,
          state.menubarItemMirrorFlipWithinStrumline.selected,
          !state.menubarItemMirrorFlipWithinStrumline.selected,
          false,
          true
        )
      );
    }

    // CTRL + A = Select All Notes
    if (state.pressingControl() && FlxG.keys.justPressed.A)
    {
      // Select all items.
      if (FlxG.keys.pressed.ALT)
      {
        if (FlxG.keys.pressed.SHIFT)
        {
          // CTRL + ALT + SHIFT + A = Append All Events to Selection
          state.performCommand(new SelectItemsCommand([], state.currentSongChartEventData));
        }
        else
        {
          // CTRL + ALT + A = Set Selection to All Events
          state.performCommand(new SelectAllItemsCommand(false, true));
        }
      }
      else
      {
        if (FlxG.keys.pressed.SHIFT)
        {
          // CTRL + SHIFT + A = Append All Notes to Selection
          state.performCommand(new SelectItemsCommand(state.currentSongChartNoteData, []));
        }
        else
        {
          // CTRL + A = Set Selection to All Notes
          state.performCommand(new SelectAllItemsCommand(true, false));
        }
      }
    }

    // CTRL + I = Select Inverse
    if (state.pressingControl() && FlxG.keys.justPressed.I)
    {
      // Select unselected items and deselect selected items.
      state.performCommand(new InvertSelectedItemsCommand());
    }

    // CTRL + D = Select None
    if (state.pressingControl() && FlxG.keys.justPressed.D)
    {
      // Deselect all items.
      state.performCommand(new DeselectAllItemsCommand());
    }

    // SHIFT + Home = Select all above playhead
    if (FlxG.keys.pressed.SHIFT && FlxG.keys.justPressed.HOME)
    {
      // CTRL +  SHIFT + Home = Inverse - deselect all above playhead
      if (FlxG.keys.pressed.CONTROL)
      {
        state.performCommand(new DeselectAllItemsBetweenTimeCommand(state.scrollPositionInMs + state.playheadPositionInMs, true, true, true));
      }
      else
      {
        state.performCommand(new SelectAllItemsBetweenTimeCommand(state.scrollPositionInMs + state.playheadPositionInMs, true, true, true));
      }
    }

    // SHIFT + End = Select all below playhead
    if (FlxG.keys.pressed.SHIFT && FlxG.keys.justPressed.END)
    {
      // CTRL +  SHIFT + Home = Inverse - deselect all below playhead
      if (FlxG.keys.pressed.CONTROL)
      {
        state.performCommand(new DeselectAllItemsBetweenTimeCommand(state.scrollPositionInMs + state.playheadPositionInMs, false, true, true));
      }
      else
      {
        state.performCommand(new SelectAllItemsBetweenTimeCommand(state.scrollPositionInMs + state.playheadPositionInMs, false, true, true));
      }
    }
  }

  /**
   * Handle keybinds for View menu items.
   */
  public static function handleViewKeybinds(state:ChartEditorState):Void
  {
    if (state.currentLiveInputStyle != WASDKeys)
    {
      if (state.pressingControl() && FlxG.keys.justPressed.LEFT)
      {
        state.incrementDifficulty(-1);
      }
      if (state.pressingControl() && FlxG.keys.justPressed.RIGHT)
      {
        state.incrementDifficulty(1);
      }
      // Would bind Ctrl+A and Ctrl+D here, but they are already bound to Select All and Select None.
    }
    else
    {
      // trace('Ignoring keybinds for View menu items because we are in live input mode (${currentLiveInputStyle}).');
    }

    // Shift + Left/Right = Change the playback speed by 0.1x.
    if (FlxG.keys.pressed.SHIFT && !state.pressingControl() && !state.isHaxeUIFocused)
    {
      if (FlxG.keys.justPressed.RIGHT) state.changePlaybackSpeed(0.1);
      if (FlxG.keys.justPressed.LEFT) state.changePlaybackSpeed(-0.1);
    }

    // B = Add or remove a sub-beat under the mouse.
    if (!state.pressingControl() && !FlxG.keys.pressed.SHIFT && !FlxG.keys.pressed.ALT && FlxG.keys.justPressed.B && !state.isHaxeUIDialogOpen && !state.isHaxeUIFocused)
    {
      state.toggleSubBeatAtCursor();
    }

    // ALT + B = New Comment.
    if (!state.pressingControl() && !FlxG.keys.pressed.SHIFT && FlxG.keys.pressed.ALT && FlxG.keys.justPressed.B && !state.isHaxeUIDialogOpen && !state.isHaxeUIFocused)
    {
      // Add a new comment at the grid playhead's position.
      var playheadPosMs:Float = state.scrollPositionInMs + state.playheadPositionInMs;
      state.performCommand(new AddCommentCommand({
        time: playheadPosMs,
        text: 'New Comment',
        color: state.commentColorToPlace,
      }));
      state.success('New Comment', 'Added a comment at the playhead position.');
    }
  }

  /**
   * Handle keybinds for the Test menu items.
   */
  public static function handleTestKeybinds(state:ChartEditorState):Void
  {
    // Use wasOpen, otherwise the command palette triggers playtests.
    if (!state.wasHaxeUIDialogOpen && !state.isHaxeUIFocused && FlxG.keys.justPressed.ENTER)
    {
      var minimal = FlxG.keys.pressed.SHIFT;
      state.hideAllToolboxes();
      state.testSongInPlayState(minimal);
    }
  }

  /**
   * Handle keybinds for Help menu items.
   */
  public static function handleHelpKeybinds(state:ChartEditorState):Void
  {
    // F1 = Open Help
    if (FlxG.keys.justPressed.F1 && !state.isHaxeUIDialogOpen)
    {
      state.openUserGuideDialog();
    }
  }

  /**
   * Handle keybinds for audio playback.
   */
  public static function handleAudioKeybinds(state:ChartEditorState):Void
  {
    // Same as the Audio -> Mute Metronome toggle, which keeps the volume as it is.
    if (!state.isHaxeUIFocused && FlxG.keys.pressed.SHIFT && FlxG.keys.justPressed.M && !state.pressingControl())
    {
      state.metronomeMuted = !state.metronomeMuted;
      state.menubarItemMuteMetronome.selected = state.metronomeMuted;
    }
    // Same as the Audio -> Mute Hitsounds toggle, which keeps the volumes as they are.
    if (!state.isHaxeUIFocused && FlxG.keys.pressed.SHIFT && FlxG.keys.justPressed.H)
    {
      state.hitsoundsMuted = !state.hitsoundsMuted;
      state.menubarItemMuteHitsounds.selected = state.hitsoundsMuted;
    }
    // Same as the Audio -> Mute Instrumental toggle, which keeps the volume as it is.
    if (!state.isHaxeUIFocused && FlxG.keys.pressed.SHIFT && FlxG.keys.justPressed.I)
    {
      state.instrumentalMuted = !state.instrumentalMuted;
      state.menubarItemMuteInstrumental.selected = state.instrumentalMuted;
    }
    // Both vocal mute toggles at once. Mutes both unless both are already muted, then unmutes both.
    if (!state.isHaxeUIFocused && FlxG.keys.pressed.SHIFT && FlxG.keys.justPressed.V && !state.pressingControl())
    {
      var mute:Bool = !(state.playerVocalsMuted && state.opponentVocalsMuted);
      state.playerVocalsMuted = state.opponentVocalsMuted = mute;
      state.menubarItemMutePlayerVocals.selected = state.menubarItemMuteOpponentVocals.selected = mute;
    }
    // Same as the Audio -> Mute Player Vocals toggle.
    if (!state.isHaxeUIFocused && FlxG.keys.pressed.SHIFT && FlxG.keys.justPressed.B)
    {
      state.playerVocalsMuted = !state.playerVocalsMuted;
      state.menubarItemMutePlayerVocals.selected = state.playerVocalsMuted;
    }
    // Same as the Audio -> Mute Opponent Vocals toggle.
    if (!state.isHaxeUIFocused && FlxG.keys.pressed.SHIFT && FlxG.keys.justPressed.D && !state.pressingControl())
    {
      state.opponentVocalsMuted = !state.opponentVocalsMuted;
      state.menubarItemMuteOpponentVocals.selected = state.opponentVocalsMuted;
    }
  }

  /**
   * Initialize TurboKeyHandlers and add them to the state (so `update()` is called)
   * We can then probe `keyHandler.activated` to see if the key combo's action should be taken.
   */
  public static function setupTurboKeyHandlers(state:ChartEditorState):Void
  {
    // Keyboard shortcuts
    state.add(state.undoKeyHandler);
    state.add(state.redoKeyHandler);
    state.add(state.upKeyHandler);
    state.add(state.downKeyHandler);
    state.add(state.wKeyHandler);
    state.add(state.sKeyHandler);
    state.add(state.pageUpKeyHandler);
    state.add(state.pageDownKeyHandler);

    // Gamepad inputs
    state.add(state.dpadUpGamepadHandler);
    state.add(state.dpadDownGamepadHandler);
    state.add(state.dpadLeftGamepadHandler);
    state.add(state.dpadRightGamepadHandler);
    state.add(state.leftStickUpGamepadHandler);
    state.add(state.leftStickDownGamepadHandler);
    state.add(state.leftStickLeftGamepadHandler);
    state.add(state.leftStickRightGamepadHandler);
    state.add(state.rightStickUpGamepadHandler);
    state.add(state.rightStickDownGamepadHandler);
    state.add(state.rightStickLeftGamepadHandler);
    state.add(state.rightStickRightGamepadHandler);
  }

  public static function copySelection(state:ChartEditorState):Void
  {
    ChartEditorSelectableItems.lastCopied = null;
    state.clipboardDirty = true;
    state.clipboardValid = true;
    // Doesn't use a command because it's not undoable.

    SongDataUtils.writeItemsToClipboard(CopyItemsCommand.buildClipboard(state, state.currentNoteSelection, state.currentEventSelection,
      state.subBeatItems.selectedTimes()));
  }
}
#end
