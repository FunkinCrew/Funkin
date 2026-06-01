package funkin.ui.debug.charting.components.palette;

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

    var items:Array<PaletteItem> = buildItems(palette);

    for (item in items)
    {
      palette.commandPaletteList.dataSource.add(item);
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
    if (palette.selectionIndex < 0) palette.selectionIndex = 0;
    if (palette.selectionIndex >= palette.commandPaletteList.itemCount) palette.selectionIndex = palette.commandPaletteList.itemCount - 1;

    if (palette.commandPaletteList.itemCount > 1)
    {
      // Select the first element.
      palette.commandPaletteList.selectedIndex = palette.selectionIndex;
    }
    else
    {
      // Don't select the only element.
      palette.commandPaletteList.selectedIndex = -1;
    }
  }

  static function buildItems(palette:ChartEditorCommandPalette):Array<PaletteItem>
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

  static function buildItemsGoToMeasure(palette:ChartEditorCommandPalette):Array<PaletteItem>
  {
    var input:String = palette.commandPaletteInput.text;
    var endMeasure:Int = Std.int(Math.ceil(Conductor.instance.getTimeInMeasures(palette.chartEditorState.songLengthInMs)));

    if (input == ':')
    {
      return [{
        title: ':',
        subtitle: 'Type a measure number to go to (from 1 to $endMeasure).',
        shortcut: 'Ctrl+G',
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
        }];
      }

      if (measureNumber > endMeasure) measureNumber = endMeasure;
      return [{
        title: ':',
        subtitle: 'Press ENTER to go to measure $measureNumber',
        shortcut: '',
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

  static function buildItemsGoToComment(palette:ChartEditorCommandPalette):Array<PaletteItem>
  {
    var input:String = palette.commandPaletteInput.text;

    if (input == '#')
    {
      return [{
        title: '#',
        subtitle: 'Enter a term to search for across comments.',
        shortcut: '',
      }];
    }
    else
    {
      var subInput:String = input.substr(1);

      // TODO: Actually implement.
      return [{
        title: '#',
        subtitle: 'Enter a term to search for across comments.',
        shortcut: '',
      }];
    }
  }

  static function buildItemsRunCommand(palette:ChartEditorCommandPalette):Array<PaletteItem>
  {
    var input:String = palette.commandPaletteInput.text;

    if (input == '>')
    {
      return ChartEditorCommandPaletteCommands.buildCommandList();
    }
    else
    {
      var subInput:String = input.substr(1);

      var result:Array<PaletteItem> = ChartEditorCommandPaletteCommands.buildCommandList(subInput);

      if (result.length == 0)
      {
        return [{
          title: '>',
          subtitle: 'Unknown command "$subInput", please refine your search.',
          shortcut: '',
        }];
      }

      return result;
    }
  }

  /**
   * Show the list of options
   */
  static function buildItemsHelp(palette:ChartEditorCommandPalette):Array<PaletteItem>
  {
    return [
      {
        title: ':',
        subtitle: 'Go to Measure',
        shortcut: 'Ctrl+G',
      },
      // {
      //   title '#',
      //   subtitle 'Search for Comment',
      //   shortcut '',
      // },
      {
        title: '>',
        subtitle: 'Show and Run Commands',
        shortcut: 'Ctrl+Shift+P',
      }
    ];
  }
}

/**
 * The data for displaying a single item in the command palette.
 */
typedef PaletteItem =
{
  var title:String;
  var subtitle:String;
  var shortcut:String;
};

typedef PaletteCommand =
{
  > PaletteItem,
  var execute:(ChartEditorCommandPalette) -> Void;
}
#end
