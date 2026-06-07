package funkin.ui.debug.charting.components.palette;

#if FEATURE_CHART_EDITOR
import haxe.DynamicAccess;
import funkin.util.SearchUtil.FuzzyScore;
import funkin.util.SearchUtil;
import funkin.data.song.SongData.CommentData;
import funkin.ui.debug.charting.components.ChartEditorCommandPalette.PaletteCommand;

/**
 * Utility functions for building the item list in the command palette.
 */
@:nullSafety
@:access(funkin.ui.debug.charting.ChartEditorState)
class ChartEditorCommandPaletteItemBuilder
{
  /**
   * Clear the command palette, then populate the list of commands.
   *
   * @param palette The CommandPalette to operate on.
   */
  public static function populatePaletteItems(palette:ChartEditorCommandPalette):Void
  {
    palette.clearPalette();

    var items:Array<PaletteCommand> = buildItems(palette);

    for (item in items)
    {
      palette.commandPaletteList.dataSource.add(renderPaletteItem(item));
    }

    palette.handleSelection();
  }

  static inline function renderPaletteItem(item:PaletteCommand):Dynamic
  {
    // Restructure the palette item so that it sets the item's HTML text rather than merely setting the text.
    // If only there was an easier way to add a struct value with a `.` in the property name...

    var listItem:DynamicAccess<Dynamic> = {
      subtitle: item.subtitle,
      shortcut: item.shortcut,
      execute: item.execute,
    };
    // I wish there was an easier way to directly initialize a struct with a `.` in a property name.
    listItem.set('title.htmlText', (item.html ?? false) ? item.title : '<font color="#F9F9F9">${item.title}</font>');

    return listItem;
  }

  /**
   * Build a list of available commands to display, based on the current input.
   *
   * @param palette The CommandPalette to operate on.
   * @return An array of commands to display.
   */
  static function buildItems(palette:ChartEditorCommandPalette):Array<PaletteCommand>
  {
    var input:String = palette.commandPaletteInput.text;

    if (input.startsWith(':'))
    {
      // : - Go to Measure (type to choose a measure number)
      return buildItemsGoToMeasure(palette);
    }
    else if (input.startsWith('#'))
    {
      // # - Go to Comment (type to search for comments)
      return buildItemsGoToComment(palette);
    }
    else if (input.startsWith('>'))
    {
      // > - Run Command (type to search for commands)
      return buildItemsRunCommand(palette);
    }
    else if (input.startsWith('?'))
    {
      // ? - Display Help
      return buildItemsHelp(palette);
    }
    else
    {
      // ? - Display Help
      return buildItemsHelp(palette);
    }
  }

  /**
   * Build a list of items for the "Go to Measure" command.
   *
   * @param palette The CommandPalette to operate on.
   * @return An array of commands to display.
   */
  static function buildItemsGoToMeasure(palette:ChartEditorCommandPalette):Array<PaletteCommand>
  {
    var input:String = palette.commandPaletteInput.text;
    var endMeasure:Int = Std.int(Math.ceil(Conductor.instance.getTimeInMeasures(palette.chartEditorState.songLengthInMs)));

    if (input == ':')
    {
      return [{
        title: ':',
        subtitle: 'Type a measure number to go to (from 1 to $endMeasure).',
        shortcut: 'Ctrl+G',
        execute: (_) -> false,
      }];
    }
    else
    {
      var measureNumber:Null<Int> = parseMeasureNumber(input);

      if (measureNumber == null)
      {
        return [{
          title: ':',
          subtitle: 'Type a measure number to go to (from 1 to $endMeasure).',
          shortcut: 'Ctrl+G',
          execute: (_) -> false,
        }];
      }

      if (measureNumber > endMeasure) measureNumber = endMeasure;
      return [{
        title: ':',
        subtitle: 'Press ENTER to go to measure $measureNumber',
        shortcut: '',
        execute: ChartEditorCommandPaletteCommands.tryGoToMeasure,
      }];
    }
  }

  /**
   * Parse the measure number from the Command Palette input.
   *
   * @param input The input string to parse.
   * @return The measure number to navigate to, or `null` if the input is invalid.
   */
  public static function parseMeasureNumber(input:String):Null<Int>
  {
    var subInput:String = input.substr(1);
    // Get the substring that's just the first numbers of the input.
    var endIndex = 0;
    for (i in 0...subInput.length)
    {
      if ((subInput.charCodeAt(i) ?? 0) >= '0'.code && (subInput.charCodeAt(i) ?? 0) <= '9'.code)
      {
        endIndex = i + 1;
      }
      else
      {
        break;
      }
    }
    if (endIndex == 0) return null;
    var measureNumber:Null<Int> = Std.parseInt(subInput.substr(0, endIndex));
    return measureNumber;
  }

  /**
   * Build a list of items for the "Go to Comment" command.
   *
   * @param palette The CommandPalette to operate on.
   * @return An array of commands to display.
   */
  static function buildItemsGoToComment(palette:ChartEditorCommandPalette):Array<PaletteCommand>
  {
    var input:String = palette.commandPaletteInput.text;

    var subInput:String = input.substr(1);
    var filtered:Bool = subInput.length > 0;

    var commentScores:Array<
      {score:FuzzyScore, comment:CommentData}> = [];

    if (filtered)
    {
      commentScores = palette.chartEditorState.currentSongChartCommentData.map((comment) ->
      {
        var score:FuzzyScore = SearchUtil.scoreFuzzy(comment.text, subInput, {
          allowNonContiguous: true,
          allowPartial: false
        });
        return {
          score: score,
          comment: comment
        };
      }).filter((commentScore) -> commentScore.score.score > 0);
      commentScores.sort((a, b) -> b.score.score - a.score.score);
    }
    else
    {
      commentScores = palette.chartEditorState.currentSongChartCommentData.map((comment) ->
      {
        return {
          score: SearchUtil.NO_SCORE,
          comment: comment
        };
      });
    }

    var goToCommentCommands:Array<PaletteCommand> = commentScores.map((score) ->
    {
      return {
        title: SearchUtil.highlightFuzzyText(score.comment.text, score.score),
        html: filtered,
        subtitle: 'Go to comment',
        shortcut: '',
        execute: (_) ->
        {
          palette.chartEditorState.easeToSongTimeMs(score.comment.time);
          return true;
        },
      }
    });

    return goToCommentCommands;
  }

  /**
   * Build a list of items for the "Run Command" command.
   *
   * @param palette The CommandPalette to operate on.
   * @return An array of commands to display.
   */
  static function buildItemsRunCommand(palette:ChartEditorCommandPalette):Array<PaletteCommand>
  {
    var input:String = palette.commandPaletteInput.text;

    if (input == '>')
    {
      // Display the full command list.
      return ChartEditorCommandPaletteCommands.buildCommandList();
    }
    else
    {
      // Filter the command list based on the user input.
      var subInput:String = input.substr(1);

      var result:Array<PaletteCommand> = ChartEditorCommandPaletteCommands.buildCommandList(subInput);

      // Show a fallback if there is no matching command.
      if (result.length == 0)
      {
        return [{
          title: '>',
          subtitle: 'Unknown command "$subInput", please refine your search.',
          shortcut: '',
          execute: (_) -> false,
        }];
      }

      return result;
    }
  }

  /**
   * Build a list of other commands that can be run.
   *
   * @param palette The CommandPalette to operate on.
   * @return An array of commands to display.
   */
  static function buildItemsHelp(palette:ChartEditorCommandPalette):Array<PaletteCommand>
  {
    return [
      {
        title: ':',
        subtitle: 'Go to Measure',
        shortcut: 'Ctrl+G',
        execute: (_) ->
        {
          ChartEditorCommandPalette.openPalette(palette.chartEditorState, ':');
          return false;
        },
      },
      {
        title: '#',
        subtitle: 'Search for Comment',
        shortcut: 'Ctrl+B',
        execute: (_) ->
        {
          ChartEditorCommandPalette.openPalette(palette.chartEditorState, '#');
          return false;
        },
      },
      {
        title: '>',
        subtitle: 'Show and Run Commands',
        shortcut: 'Ctrl+Shift+P',
        execute: (_) ->
        {
          ChartEditorCommandPalette.openPalette(palette.chartEditorState, '>');
          return false;
        },
      }
    ];
  }
}
#end
