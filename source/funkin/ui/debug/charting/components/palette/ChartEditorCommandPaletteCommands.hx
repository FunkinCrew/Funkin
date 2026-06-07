package funkin.ui.debug.charting.components.palette;

#if FEATURE_CHART_EDITOR
import funkin.util.SearchUtil;
import funkin.util.SearchUtil.FuzzyScore;
import funkin.ui.debug.charting.components.ChartEditorCommandPalette.PaletteCommand;
import funkin.ui.debug.charting.commands.DeselectAllItemsCommand;
import funkin.ui.debug.charting.commands.SelectAllItemsCommand;
import funkin.ui.debug.charting.commands.SelectItemsCommand;

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
    command('Select All Notes', 'Select all notes and events in chart.', 'Ctrl+Shift+A', (palette) ->
    {
      palette.chartEditorState.performCommand(new SelectAllItemsCommand(true, true));
    }),
    command('Select All Notes (Append)', 'Add all notes and events in chart to selection.', 'Ctrl+Shift+A', (palette) ->
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
    command('Deselect All', 'Remove all notes and events from selection.', 'Ctrl+D', (palette) ->
    {
      palette.chartEditorState.performCommand(new DeselectAllItemsCommand());
    }),
    command('Decrement Difficulty', 'Switch to the previous difficulty.', 'Ctrl+Left', (palette) ->
    {
      palette.chartEditorState.incrementDifficulty(-1);
    }),
    command('Increment Difficulty', 'Switch to the next difficulty.', 'Ctrl+Right', (palette) ->
    {
      palette.chartEditorState.incrementDifficulty(1);
    }),
  ];

  /**
   * A helper function for constructing a PaletteCommand.
   * @param title The title of the command.
   * @param subtitle The subtitle of the command.
   * @param shortcut The keyboard shortcut to display.
   * @param execute The function to run when the command is executed.
   *   Always returns `true` to close the palette.
   * @return The constructed PaletteCommand.
   */
  static inline function command(title:String, subtitle:String = '', shortcut:String = '', execute:(ChartEditorCommandPalette) -> Void):PaletteCommand
  {
    return {
      title: title,
      html: false,
      subtitle: subtitle,
      shortcut: shortcut,
      execute: (palette) ->
      {
        execute(palette);
        return true;
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
