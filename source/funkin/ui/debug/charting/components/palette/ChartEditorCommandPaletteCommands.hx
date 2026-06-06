package funkin.ui.debug.charting.components.palette;

#if FEATURE_CHART_EDITOR
import funkin.util.SearchUtil;
import funkin.util.SearchUtil.FuzzyScore;
import funkin.ui.debug.charting.components.palette.ChartEditorCommandPaletteItemBuilder.PaletteCommand;
import funkin.ui.debug.charting.commands.SelectAllItemsCommand;
import funkin.ui.debug.charting.commands.SelectItemsCommand;
import funkin.ui.debug.charting.commands.AddEventsCommand;
import funkin.ui.debug.charting.commands.AddNewTimeChangeCommand;
import funkin.ui.debug.charting.commands.AddNotesCommand;
import funkin.ui.debug.charting.commands.ChartEditorCommand;
import funkin.ui.debug.charting.commands.CopyItemsCommand;
import funkin.ui.debug.charting.commands.CutItemsCommand;
import funkin.ui.debug.charting.commands.DeselectAllItemsBetweenTimeCommand;
import funkin.ui.debug.charting.commands.DeselectAllItemsCommand;
import funkin.ui.debug.charting.commands.DeselectItemsCommand;
import funkin.ui.debug.charting.commands.ExtendNoteLengthCommand;
import funkin.ui.debug.charting.commands.FlipNotesCommand;
import funkin.ui.debug.charting.commands.InvertSelectedItemsCommand;
import funkin.ui.debug.charting.commands.MirrorNotesCommand;
import funkin.ui.debug.charting.commands.MoveEventsCommand;
import funkin.ui.debug.charting.commands.MoveItemsCommand;
import funkin.ui.debug.charting.commands.MoveNotesCommand;
import funkin.ui.debug.charting.commands.PasteItemsCommand;
import funkin.ui.debug.charting.commands.RemoveEventsCommand;
import funkin.ui.debug.charting.commands.RemoveItemsCommand;
import funkin.ui.debug.charting.commands.RemoveNotesCommand;
import funkin.ui.debug.charting.commands.RemoveStackedNotesCommand;
import funkin.ui.debug.charting.commands.SelectAllItemsBetweenTimeCommand;
import funkin.ui.debug.charting.commands.SelectAllItemsCommand;
import funkin.ui.debug.charting.commands.SelectItemsCommand;
import funkin.ui.debug.charting.commands.SetItemSelectionCommand;
import funkin.ui.debug.charting.commands.SwitchDifficultyCommand;

/**
 * Holds and filters the list of available commands for the command palette.
 */
@:nullSafety
@:access(funkin.ui.debug.charting.ChartEditorState)
@:access(funkin.ui.debug.charting.components.ChartEditorCommandPalette)
class ChartEditorCommandPaletteCommands
{
  /**
   * The full list of available commands to be executed.
   */
  public static final COMMANDS:Array<PaletteCommand> = [
    {
      title: 'Select All Notes',
      subtitle: 'Select all notes in chart.',
      shortcut: 'Ctrl+A',
      execute: (palette) ->
      {
        palette.chartEditorState.performCommand(new SelectAllItemsCommand(true, false));
        return true;
      }
    },
    {
      title: 'Select All Notes (Append)',
      subtitle: 'Add all notes in chart to selection.',
      shortcut: 'Ctrl+Shift+A',
      execute: (palette) ->
      {
        palette.chartEditorState.performCommand(new SelectItemsCommand(palette.chartEditorState.currentSongChartNoteData, []));
        return true;
      }
    },
    {
      title: 'Select All Events',
      subtitle: 'Select all events in chart.',
      shortcut: 'Ctrl+Alt+A',
      execute: (palette) ->
      {
        palette.chartEditorState.performCommand(new SelectAllItemsCommand(false, true));
        return true;
      }
    },
    {
      title: 'Select All Events (Append)',
      subtitle: 'Add all events in chart to selection.',
      shortcut: 'Ctrl+Alt+Shift+A',
      execute: (palette) ->
      {
        palette.chartEditorState.performCommand(new SelectItemsCommand([], palette.chartEditorState.currentSongChartEventData));
        return true;
      }
    },
    {
      title: 'Deselect All',
      subtitle: 'Remove all notes and events from selection.',
      shortcut: 'Ctrl+D',
      execute: (palette) ->
      {
        palette.chartEditorState.performCommand(new DeselectAllItemsCommand());
        return true;
      }
    },
    {
      title: 'Decrement Difficulty',
      subtitle: 'Switch to the previous difficulty.',
      shortcut: 'Ctrl+Left',
      execute: (palette) ->
      {
        palette.chartEditorState.incrementDifficulty(-1);
        return true;
      }
    },
    {
      title: 'Increment Difficulty',
      subtitle: 'Switch to the next difficulty.',
      shortcut: 'Ctrl+Right',
      execute: (palette) ->
      {
        palette.chartEditorState.incrementDifficulty(1);
        return true;
      }
    },
  ];

  /**
   * Output a list of commands to display in the palette.
   *
   * @param filter The filter string to apply to the command list.
   * @return The list of commands.
   */
  public static function buildCommandList(filter:String = ''):Array<PaletteCommand>
  {
    if (filter == '') return COMMANDS;

    var commandScores:Array<
      {score:FuzzyScore, command:PaletteCommand}> = COMMANDS.map((command) ->
      {
        var score:FuzzyScore = SearchUtil.scoreFuzzy(command.title, filter, {
          allowNonContiguous: true,
          allowPartial: false
        });
        return {
          score: score,
          command: command
        };
      }).filter((commandScore) -> commandScore.score.score > 0);
    commandScores.sort((a, b) -> b.score.score - a.score.score);

    return commandScores.map((commandScore) -> {
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
    var input:String = palette.commandPaletteInput.text;
    // Don't do anything if blank.
    if (input == ':')
    {
      trace('Command Palette: Invalid input for GoToMeasure "$input"');
      return false;
    }
    var measureNumber:Null<Int> = ChartEditorCommandPaletteItemBuilder.parseMeasureNumber(input);
    // Don't do anything if unparsed.
    if (measureNumber == null)
    {
      trace('Command Palette: Invalid input for GoToMeasure "$input"');
      return false;
    }

    measureNumber -= 1;

    var endMeasure:Int = Std.int(Math.ceil(Conductor.instance.getTimeInMeasures(palette.chartEditorState.songLengthInMs)));
    if (measureNumber > endMeasure) measureNumber = endMeasure;
    if (measureNumber < 0) measureNumber = 0;

    var targetTimeMs:Float = Conductor.instance.getMeasureTimeInMs(measureNumber);
    var targetTimeSteps:Float = Conductor.instance.getTimeInSteps(targetTimeMs);
    var targetTimePixels:Float = targetTimeSteps * ChartEditorState.GRID_SIZE;

    trace('Command Palette: Jumping to measure $measureNumber at $targetTimeMs ms!');
    palette.chartEditorState.currentScrollEase = targetTimePixels;

    // Command was successful.
    return true;
  }
}
#end
