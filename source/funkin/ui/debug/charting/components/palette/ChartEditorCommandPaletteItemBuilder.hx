package funkin.ui.debug.charting.components.palette;

import haxe.DynamicAccess;
import funkin.util.SearchUtil.FuzzyScore;
import funkin.util.SearchUtil;
import funkin.data.song.SongData.CommentData;

#if FEATURE_CHART_EDITOR
/**
 * Utility functions for building the item list in the command palette.
 */
@:nullSafety
@:access(funkin.ui.debug.charting.ChartEditorState)
@:access(funkin.ui.debug.charting.components.ChartEditorCommandPalette)
class ChartEditorCommandPaletteItemBuilder
{
  /**
   * Clear and repopulate the command palette.
   *
   * @param palette The CommandPalette to operate on.
   */
  public static function populatePaletteItems(palette:ChartEditorCommandPalette):Void
  {
    clearPalette(palette);

    var items:Array<PaletteCommand> = buildItems(palette);

    for (item in items)
    {
      var listItem:DynamicAccess<Dynamic> = {
        subtitle: item.subtitle,
        shortcut: item.shortcut,
        execute: item.execute,
      };
      // I wish there was an easier way to directly initialize a struct with a `.` in a property name.
      if (item.html ?? false)
      {
        listItem.set('title.htmlText', item.title);
      }
      else
      {
        listItem.set('title.htmlText', '<font color="#F9F9F9">${item.title}</font>');
      }

      palette.commandPaletteList.dataSource.add(listItem);
    }

    handleSelection(palette);
  }

  static function clearPalette(palette:ChartEditorCommandPalette):Void
  {
    palette.commandPaletteList.dataSource.clear();
  }

  static function handleSelection(palette:ChartEditorCommandPalette):Void
  {
    // Clamp the selection index.
    var itemCount:Int = palette.commandPaletteList.dataSource.size;

    // Make it loop around
    if (palette.selectionIndex < 0) palette.selectionIndex = itemCount - 1;
    if (palette.selectionIndex >= itemCount) palette.selectionIndex = 0;

    if (itemCount > 1)
    {
      // Select the correct element.
      palette.commandPaletteList.selectedIndex = palette.selectionIndex;
    }
    else
    {
      // Don't select the only element.
      palette.commandPaletteList.selectedIndex = -1;
    }
  }

  static function buildItems(palette:ChartEditorCommandPalette):Array<PaletteCommand>
  {
    var input:String = palette.commandPaletteInput.text;

    if (input.startsWith(':'))
    {
      return buildItemsGoToMeasure(palette);
    }
    else if (input.startsWith('#'))
    {
      return buildItemsGoToComment(palette);
    }
    else if (input.startsWith('>'))
    {
      return buildItemsRunCommand(palette);
    }
    else
    {
      return buildItemsHelp(palette);
    }
  }

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
        trace('  Checking comment "${comment.text}"');
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

  static function buildItemsRunCommand(palette:ChartEditorCommandPalette):Array<PaletteCommand>
  {
    var input:String = palette.commandPaletteInput.text;

    if (input == '>')
    {
      return ChartEditorCommandPaletteCommands.buildCommandList();
    }
    else
    {
      var subInput:String = input.substr(1);

      var result:Array<PaletteCommand> = ChartEditorCommandPaletteCommands.buildCommandList(subInput);

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
   * Show the list of options
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

/**
 * The data for displaying a single command in the command palette.
 */
typedef PaletteCommand =
{
  var title:String;
  var ?html:Bool;
  var subtitle:String;
  var shortcut:String;

  /**
   * The command to execute.
   * @param palette The palette that is executing the command.
   * @return Whether the palette should close after executing the command.
   */
  var execute:(ChartEditorCommandPalette) -> Bool;
}
#end
