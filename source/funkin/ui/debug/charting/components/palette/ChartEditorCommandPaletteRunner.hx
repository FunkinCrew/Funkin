package funkin.ui.debug.charting.components.palette;

#if FEATURE_CHART_EDITOR
/**
 * Utility functions for performing actions from the command palette.
 */
@:nullSafety
@:access(funkin.ui.debug.charting.ChartEditorState)
@:access(funkin.ui.debug.charting.components.ChartEditorCommandPalette)
class ChartEditorCommandPaletteRunner
{
  /**
   * Try and execute the currently selected command.
   *
   * @param palette The CommandPalette to operate on.
   */
  public static function tryPerformCommand(palette:ChartEditorCommandPalette):Void
  {
    var input:String = palette.commandPaletteInput.text;

    trace('Command Palette: Try perform command "$input"');

    if (input.startsWith(':'))
    {
      tryPerformCommandGoToMeasure(palette);
    }
    else
    {
      trace('Command Palette: Unknown command "$input"');
    }
  }

  static function tryPerformCommandGoToMeasure(palette:ChartEditorCommandPalette):Void
  {
    var input:String = palette.commandPaletteInput.text;
    // Don't do anything if blank.
    if (input == ':')
    {
      trace('Command Palette: Invalid input for GoToMeasure "$input"');
      return;
    }
    var measureNumber:Null<Int> = ChartEditorCommandPaletteItemBuilder.parseMeasureNumber(input);
    // Don't do anything if unparsed.
    if (measureNumber == null)
    {
      trace('Command Palette: Invalid input for GoToMeasure "$input"');
      return;
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

    // Close the palette when the command is successful.
    palette.close();
  }
}
#end
