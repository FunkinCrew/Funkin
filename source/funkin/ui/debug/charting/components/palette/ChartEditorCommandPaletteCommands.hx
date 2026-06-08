package funkin.ui.debug.charting.components.palette;

import funkin.ui.debug.charting.commands.AddNewTimeChangeCommand;
#if FEATURE_CHART_EDITOR
import funkin.util.SearchUtil;
import funkin.util.SearchUtil.FuzzyScore;
import funkin.ui.debug.charting.ChartEditorState;
import funkin.ui.debug.charting.components.ChartEditorCommandPalette.PaletteCommand;
import funkin.ui.debug.charting.commands.AddCommentCommand;
import funkin.ui.debug.charting.commands.CopyItemsCommand;
import funkin.ui.debug.charting.commands.CutItemsCommand;
import funkin.ui.debug.charting.commands.DeselectAllItemsBetweenTimeCommand;
import funkin.ui.debug.charting.commands.DeselectAllItemsCommand;
import funkin.ui.debug.charting.commands.FlipNotesCommand;
import funkin.ui.debug.charting.commands.InvertSelectedItemsCommand;
import funkin.ui.debug.charting.commands.MirrorNotesCommand;
import funkin.ui.debug.charting.commands.PasteItemsCommand;
import funkin.ui.debug.charting.commands.RemoveEventsCommand;
import funkin.ui.debug.charting.commands.RemoveItemsCommand;
import funkin.ui.debug.charting.commands.RemoveNotesCommand;
import funkin.ui.debug.charting.commands.RemoveStackedNotesCommand;
import funkin.ui.debug.charting.commands.SelectAllItemsBetweenTimeCommand;
import funkin.ui.debug.charting.commands.SelectAllItemsCommand;
import funkin.ui.debug.charting.commands.SelectItemsCommand;
import funkin.ui.debug.charting.handlers.ChartEditorNotificationHandler;
import funkin.ui.debug.charting.handlers.ChartEditorToolboxHandler;

/**
 * Holds and filters the list of available commands for the command palette.
 */
@:nullSafety
@:access(funkin.ui.debug.charting.ChartEditorState)
class ChartEditorCommandPaletteCommands
{
  /**
   * The full list of available commands to be executed.
   */
  public static final COMMANDS:Array<PaletteCommand> = [
    command('Undo', 'Undo the last chart editor command.', 'Ctrl+Z', (palette) ->
    {
      palette.chartEditorState.undoLastCommand();
    }),
    command('Redo', 'Redo the last undone chart editor command.', 'Ctrl+Y', (palette) ->
    {
      palette.chartEditorState.redoLastCommand();
    }),
    command('Copy Selection', 'Copy the selected notes and events to clipboard.', 'Ctrl+C', (palette) ->
    {
      palette.chartEditorState.performCommand(
        new CopyItemsCommand(palette.chartEditorState.currentNoteSelection, palette.chartEditorState.currentEventSelection)
      );
    }),
    command('Cut Selection', 'Cut the selected notes and events to clipboard.', 'Ctrl+X', (palette) ->
    {
      palette.chartEditorState.performCommand(
        new CutItemsCommand(palette.chartEditorState.currentNoteSelection, palette.chartEditorState.currentEventSelection)
      );
    }),
    command('Paste from Clipboard', 'Paste clipboard contents near the playhead position, snapped to the grid.', 'Ctrl+V', (palette) ->
    {
      palette.chartEditorState.performCommand(new PasteItemsCommand(playheadTimeMs(palette, true)));
    }),
    command('Paste from Clipboard (Unsnapped)', 'Paste clipboard contents at the exact playhead position.', 'Ctrl+Shift+V', (palette) ->
    {
      palette.chartEditorState.performCommand(new PasteItemsCommand(playheadTimeMs(palette, false)));
    }),
    command('Delete Selection', 'Delete the selected notes and events.', 'Delete', (palette) ->
    {
      deleteSelection(palette);
    }),
    command('Delete Selected Notes', 'Delete the selected notes.', (palette) ->
    {
      palette.chartEditorState.performCommand(new RemoveNotesCommand(palette.chartEditorState.currentNoteSelection));
    }),
    command('Delete Selected Events', 'Delete the selected events.', (palette) ->
    {
      palette.chartEditorState.performCommand(new RemoveEventsCommand(palette.chartEditorState.currentEventSelection));
    }),
    command('Remove Stacked Notes', 'Remove stacked notes from the current chart.', 'Shift+Delete', (palette) ->
    {
      palette.chartEditorState.performCommand(new RemoveStackedNotesCommand());
    }),
    command('Remove Stacked Notes in Selection', 'Remove stacked notes from the selection.', '', (palette) ->
    {
      palette.chartEditorState.performCommand(new RemoveStackedNotesCommand(palette.chartEditorState.currentNoteSelection));
    }),
    command('Flip Notes', 'Flip selected notes between the player and opponent sides.', 'Ctrl+F', (palette) ->
    {
      palette.chartEditorState.performCommand(new FlipNotesCommand(palette.chartEditorState.currentNoteSelection));
    }),
    command('Mirror Notes Horizontally', 'Mirror selected notes on the X axis.', 'Ctrl+Shift+M', (palette) ->
    {
      mirrorNotes(palette, true, false);
    }),
    command('Mirror Notes Vertically', 'Mirror selected notes on the Y axis.', 'Ctrl+Alt+M', (palette) ->
    {
      mirrorNotes(palette, false, true);
    }),
    command('Mirror Notes Horizontally and Vertically', 'Mirror selected notes on both axes.', 'Ctrl+Alt+Shift+M', (palette) ->
    {
      mirrorNotes(palette, true, true);
    }),
    command('Select All Notes', 'Select all notes in chart.', 'Ctrl+A', (palette) ->
    {
      palette.chartEditorState.performCommand(new SelectAllItemsCommand(true, false));
    }),
    command('Select All Notes (Append)', 'Add all notes in chart to selection.', 'Ctrl+Shift+A', (palette) ->
    {
      palette.chartEditorState.performCommand(new SelectItemsCommand(palette.chartEditorState.currentSongChartNoteData, []));
    }),
    command('Select All Events', 'Select all events in chart.', 'Ctrl+Alt+A', (palette) ->
    {
      palette.chartEditorState.performCommand(new SelectAllItemsCommand(false, true));
    }),
    command('Select All Events (Append)', 'Add all events in chart to selection.', 'Ctrl+Alt+Shift+A', (palette) ->
    {
      palette.chartEditorState.performCommand(new SelectItemsCommand([], palette.chartEditorState.currentSongChartEventData));
    }),
    command('Select All Notes and Events', 'Select every note and event in chart.', '', (palette) ->
    {
      palette.chartEditorState.performCommand(new SelectAllItemsCommand(true, true));
    }),
    command('Select All', 'Select all notes and events in chart.', (palette) ->
    {
      palette.chartEditorState.performCommand(new SelectAllItemsCommand(true, true));
    }),
    command('Invert Selection', 'Select unselected items and deselect selected items.', 'Ctrl+I', (palette) ->
    {
      palette.chartEditorState.performCommand(new InvertSelectedItemsCommand());
    }),
    command('Deselect All', 'Remove all notes and events from selection.', 'Ctrl+D', (palette) ->
    {
      palette.chartEditorState.performCommand(new DeselectAllItemsCommand());
    }),
    command('Select Items Above Playhead', 'Add all notes and events above the playhead to selection.', 'Shift+Home', (palette) ->
    {
      palette.chartEditorState.performCommand(new SelectAllItemsBetweenTimeCommand(playheadTimeMs(palette, false), true, true, true));
    }),
    command('Select Items Below Playhead', 'Add all notes and events below the playhead to selection.', 'Shift+End', (palette) ->
    {
      palette.chartEditorState.performCommand(new SelectAllItemsBetweenTimeCommand(playheadTimeMs(palette, false), false, true, true));
    }),
    command('Deselect Items Above Playhead', 'Remove notes and events above the playhead from selection.', 'Ctrl+Shift+Home', (palette) ->
    {
      palette.chartEditorState.performCommand(new DeselectAllItemsBetweenTimeCommand(playheadTimeMs(palette, false), true, true, true));
    }),
    command('Deselect Items Below Playhead', 'Remove notes and events below the playhead from selection.', 'Ctrl+Shift+End', (palette) ->
    {
      palette.chartEditorState.performCommand(new DeselectAllItemsBetweenTimeCommand(playheadTimeMs(palette, false), false, true, true));
    }),
    command('Add Comment', 'Add a new comment at the playhead position.', 'B', (palette) ->
    {
      var state = palette.chartEditorState;
      state.performCommand(new AddCommentCommand({
        time: playheadTimeMs(palette, false),
        text: 'New Comment',
        color: state.commentColorToPlace,
      }));
      ChartEditorNotificationHandler.success(state, 'New Comment', 'Added a comment at the playhead position.');
    }),
    command('Decrement Difficulty', 'Switch to the previous difficulty.', 'Ctrl+Left', (palette) ->
    {
      palette.chartEditorState.incrementDifficulty(-1);
    }),
    command('Increment Difficulty', 'Switch to the next difficulty.', 'Ctrl+Right', (palette) ->
    {
      palette.chartEditorState.incrementDifficulty(1);
    }),
    command('Add Time Change', 'Add a new BPM/time signature change at the playhead position.', (palette) ->
    {
      var state = palette.chartEditorState;
      var currentTimeChangeIndex = 0;
      var currentTimeChange = Conductor.instance.currentTimeChange;
      if (currentTimeChange != null)
      {
        currentTimeChangeIndex = state.currentSongMetadata.timeChanges.indexOf(currentTimeChange);
      }
      var timestamp = state.scrollPositionInMs + state.playheadPositionInMs;
      state.performCommand(new AddNewTimeChangeCommand(currentTimeChangeIndex, timestamp));
    }),
    command('Play or Pause Song', 'Toggle chart audio playback.', 'Space', (palette) ->
    {
      palette.chartEditorState.toggleAudioPlayback();
    }),
    command('Playtest Song', 'Start a playtest from the chart.', 'Enter', (palette) ->
    {
      ChartEditorToolboxHandler.hideAllToolboxes(palette.chartEditorState);
      palette.chartEditorState.testSongInPlayState(false);
    }),
    command('Playtest Song (Minimal Mode)', 'Start a minimal-mode playtest from the chart.', 'Shift+Enter', (palette) ->
    {
      ChartEditorToolboxHandler.hideAllToolboxes(palette.chartEditorState);
      palette.chartEditorState.testSongInPlayState(true);
    }),
    command('Move to Camera Editor', 'Move this chart into the camera editor.', (palette) ->
    {
      palette.chartEditorState.moveToCameraEditor();
    }),
  ];

  /**
   * The full list of toolboxes to be opened.
   */
  public static final TOOLBOX_COMMANDS:Array<PaletteCommand> = [
    command('Difficulty Toolbox', 'Show the chart difficulty toolbox.', (palette) ->
    {
      openToolbox(palette, ChartEditorState.CHART_EDITOR_TOOLBOX_DIFFICULTY_LAYOUT);
    }),
    command('Metadata Toolbox', 'Show the song metadata toolbox.', (palette) ->
    {
      openToolbox(palette, ChartEditorState.CHART_EDITOR_TOOLBOX_METADATA_LAYOUT);
    }),
    command('Offsets Toolbox', 'Show the audio offsets toolbox.', (palette) ->
    {
      openToolbox(palette, ChartEditorState.CHART_EDITOR_TOOLBOX_OFFSETS_LAYOUT);
    }),
    command('Note Data Toolbox', 'Show the note data toolbox.', (palette) ->
    {
      openToolbox(palette, ChartEditorState.CHART_EDITOR_TOOLBOX_NOTE_DATA_LAYOUT);
    }),
    command('Event Data Toolbox', 'Show the event data toolbox.', (palette) ->
    {
      openToolbox(palette, ChartEditorState.CHART_EDITOR_TOOLBOX_EVENT_DATA_LAYOUT);
    }),
    command('Freeplay Toolbox', 'Show the freeplay preview toolbox.', (palette) ->
    {
      openToolbox(palette, ChartEditorState.CHART_EDITOR_TOOLBOX_FREEPLAY_LAYOUT);
    }),
    command('Playtest Properties Toolbox', 'Show the playtest properties toolbox.', (palette) ->
    {
      openToolbox(palette, ChartEditorState.CHART_EDITOR_TOOLBOX_PLAYTEST_PROPERTIES_LAYOUT);
    }),
    command('Player Preview Toolbox', 'Show the player character preview toolbox.', (palette) ->
    {
      openToolbox(palette, ChartEditorState.CHART_EDITOR_TOOLBOX_PLAYER_PREVIEW_LAYOUT);
    }),
    command('Opponent Preview Toolbox', 'Show the opponent character preview toolbox.', (palette) ->
    {
      openToolbox(palette, ChartEditorState.CHART_EDITOR_TOOLBOX_OPPONENT_PREVIEW_LAYOUT);
    }),
  ];

  static function playheadTimeMs(palette:ChartEditorCommandPalette, snapped:Bool):Float
  {
    var state = palette.chartEditorState;
    var targetMs:Float = state.scrollPositionInMs + state.playheadPositionInMs;
    if (!snapped) return targetMs;

    var targetStep:Float = Conductor.instance.getTimeInSteps(targetMs);
    var targetSnappedStep:Float = Math.floor(targetStep / state.noteSnapRatio) * state.noteSnapRatio;
    return Conductor.instance.getStepTimeInMs(targetSnappedStep);
  }

  static function deleteSelection(palette:ChartEditorCommandPalette):Void
  {
    var state = palette.chartEditorState;
    var hasNotes:Bool = state.currentNoteSelection.length > 0;
    var hasEvents:Bool = state.currentEventSelection.length > 0;

    if (hasNotes && hasEvents)
    {
      state.performCommand(new RemoveItemsCommand(state.currentNoteSelection, state.currentEventSelection));
    }
    else if (hasNotes)
    {
      state.performCommand(new RemoveNotesCommand(state.currentNoteSelection));
    }
    else if (hasEvents)
    {
      state.performCommand(new RemoveEventsCommand(state.currentEventSelection));
    }
  }

  static function mirrorNotes(palette:ChartEditorCommandPalette, mirrorX:Bool, mirrorY:Bool):Void
  {
    var state = palette.chartEditorState;
    state.performCommand(
      new MirrorNotesCommand(
        state.currentNoteSelection,
        state.menubarItemMirrorFlipWithinStrumline.selected,
        !state.menubarItemMirrorFlipWithinStrumline.selected,
        mirrorX,
        mirrorY
      )
    );
  }

  static function openToolbox(palette:ChartEditorCommandPalette, id:String):Void
  {
    var state = palette.chartEditorState;

    switch (id)
    {
      case ChartEditorState.CHART_EDITOR_TOOLBOX_DIFFICULTY_LAYOUT:
        state.menubarItemToggleToolboxDifficulty.selected = true;
      case ChartEditorState.CHART_EDITOR_TOOLBOX_METADATA_LAYOUT:
        state.menubarItemToggleToolboxMetadata.selected = true;
      case ChartEditorState.CHART_EDITOR_TOOLBOX_OFFSETS_LAYOUT:
        state.menubarItemToggleToolboxOffsets.selected = true;
      case ChartEditorState.CHART_EDITOR_TOOLBOX_NOTE_DATA_LAYOUT:
        state.menubarItemToggleToolboxNoteData.selected = true;
      case ChartEditorState.CHART_EDITOR_TOOLBOX_EVENT_DATA_LAYOUT:
        state.menubarItemToggleToolboxEventData.selected = true;
      case ChartEditorState.CHART_EDITOR_TOOLBOX_FREEPLAY_LAYOUT:
        state.menubarItemToggleToolboxFreeplay.selected = true;
      case ChartEditorState.CHART_EDITOR_TOOLBOX_PLAYTEST_PROPERTIES_LAYOUT:
        state.menubarItemToggleToolboxPlaytestProperties.selected = true;
      case ChartEditorState.CHART_EDITOR_TOOLBOX_PLAYER_PREVIEW_LAYOUT:
        state.menubarItemToggleToolboxPlayerPreview.selected = true;
        state.playerPreviewDirty = true;
      case ChartEditorState.CHART_EDITOR_TOOLBOX_OPPONENT_PREVIEW_LAYOUT:
        state.menubarItemToggleToolboxOpponentPreview.selected = true;
        state.opponentPreviewDirty = true;
      default:
    }

    ChartEditorToolboxHandler.setToolboxState(state, id, true);
  }

  /**
   * A helper function for constructing a PaletteCommand.
   * @param title The title of the command.
   * @param subtitle The subtitle of the command.
   * @param shortcut The keyboard shortcut to display.
   * @param execute The function to run when the command is executed.
   * @param closeAfterExecute Whether the palette should close after the command runs.
   * @return The constructed PaletteCommand.
   */
  static inline function command(title:String, subtitle:String = '', shortcut:String = '', execute:(ChartEditorCommandPalette) -> Void, closeAfterExecute:Bool = true):PaletteCommand
  {
    return {
      title: title,
      html: false,
      subtitle: subtitle,
      shortcut: shortcut,
      execute: (palette) ->
      {
        execute(palette);
        return closeAfterExecute;
      }
    }
  }

  /**
   * Build a list of commands for the palette.
   *
   * @param filter The filter string to apply to the command list.
   * @return The list of commands.
   */
  public static function buildCommandList(filter:String = ''):Array<PaletteCommand>
  {
    if (filter == '') return COMMANDS;

    // Score each command based on similarity.
    // Remove any entry that has 0 points (no matches).
    var commandScores:Array<
      {score:FuzzyScore, command:PaletteCommand}> = COMMANDS.map((command) ->
      {
        var score:FuzzyScore = SearchUtil.scoreFuzzy(command.title, filter, {
          allowNonContiguous: true, // The characters can be split up as long as they appear in order.
          allowPartial: false // All characters must be present.
        });
        return {
          score: score,
          command: command
        };
      }).filter((commandScore) -> commandScore.score.score > 0);
    // Sort by highest score first.
    commandScores.sort((a, b) -> b.score.score - a.score.score);

    return commandScores.map((commandScore) -> {
      // Apply inline style to the title to highlight the matching characters.
      title: SearchUtil.highlightFuzzyText(commandScore.command.title, commandScore.score),
      html: true,
      subtitle: commandScore.command.subtitle,
      shortcut: commandScore.command.shortcut,
      execute: commandScore.command.execute,
    });
  }

  /**
   * Build a list of toolbox commands for the palette.
   *
   * @param filter The filter string to apply to the command list.
   * @return The list of toolbox commands.
   */
  public static function buildToolboxList(filter:String = ''):Array<PaletteCommand>
  {
    if (filter == '') return TOOLBOX_COMMANDS;

    // Score each command based on similarity.
    // Remove any entry that has 0 points (no matches).
    var commandScores:Array<
      {score:FuzzyScore, command:PaletteCommand}> = TOOLBOX_COMMANDS.map((command) ->
      {
        var score:FuzzyScore = SearchUtil.scoreFuzzy(command.title, filter, {
          allowNonContiguous: true, // The characters can be split up as long as they appear in order.
          allowPartial: false // All characters must be present.
        });
        return {
          score: score,
          command: command
        };
      }).filter((commandScore) -> commandScore.score.score > 0);
    // Sort by highest score first.
    commandScores.sort((a, b) -> b.score.score - a.score.score);

    return commandScores.map((commandScore) -> {
      // Apply inline style to the title to highlight the matching characters.
      title: SearchUtil.highlightFuzzyText(commandScore.command.title, commandScore.score),
      html: true,
      subtitle: commandScore.command.subtitle,
      shortcut: commandScore.command.shortcut,
      execute: commandScore.command.execute,
    });
  }

  /**
   * Go to a specific measure in the chart.
   *
   * @param palette The active Command Palette.
   * @return Whether the command was successful.
   */
  public static function tryGoToMeasure(palette:ChartEditorCommandPalette):Bool
  {
    // Read the input.
    var input:String = palette.commandPaletteInput.text;
    // Don't do anything if blank.
    if (input == ':')
    {
      trace('Command Palette: Invalid input for GoToMeasure "$input"');
      return false;
    }
    // Parse the measure number to jump to.
    var measureNumber:Null<Int> = ChartEditorCommandPaletteItemBuilder.parseMeasureNumber(input);
    // Don't do anything if unparsed.
    if (measureNumber == null)
    {
      trace('Command Palette: Invalid input for GoToMeasure "$input"');
      return false;
    }

    // Go to the start of the measure, not the end.
    measureNumber -= 1;

    // Clamp to song start/end.
    var endMeasure:Int = Std.int(Math.ceil(Conductor.instance.getTimeInMeasures(palette.chartEditorState.songLengthInMs)));
    if (measureNumber > endMeasure) measureNumber = endMeasure;
    if (measureNumber < 0) measureNumber = 0;

    // Determine the target position.
    var targetTimeMs:Float = Conductor.instance.getMeasureTimeInMs(measureNumber);

    // Scroll to the target position.
    palette.chartEditorState.easeToSongTimeMs(targetTimeMs);

    // Command was successful.
    return true;
  }
}
#end
