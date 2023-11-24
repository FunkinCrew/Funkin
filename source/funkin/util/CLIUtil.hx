package funkin.util;

import haxe.io.Path;

/**
 * Utilties for interpreting command line arguments.
 */
@:nullSafety
class CLIUtil
{
  /**
   * If we don't do this, dragging and dropping a file onto the executable
   * causes it to be unable to find the assets folder.
   */
  public static function resetWorkingDir():Void
  {
    #if sys
    var exeDir:String = Path.addTrailingSlash(Path.directory(Sys.programPath()));
    #if mac
    exeDir = Path.addTrailingSlash(Path.join([exeDir, '../Resources/']));
    #end
    var cwd:String = Path.addTrailingSlash(Sys.getCwd());
    if (cwd == exeDir)
    {
      trace('Working directory is already correct.');
    }
    else
    {
      trace('Changing working directory from ${Sys.getCwd()} to ${exeDir}');
      Sys.setCwd(exeDir);
    }
    #end
  }

  public static function processArgs():CLIParams
  {
    #if sys
    return interpretArgs(cleanArgs(Sys.args()));
    #else
    return buildDefaultParams();
    #end
  }

  static function interpretArgs(args:Array<String>):CLIParams
  {
    var result = buildDefaultParams();

    result.args = [for (arg in args) arg]; // Copy the array.

    while (args.length > 0)
    {
      var arg:Null<String> = args.shift();
      if (arg == null) continue;

      if (arg.startsWith('-'))
      {
        switch (arg)
        {
          // Flags
          case '-h' | '--help':
            printUsage();
          case '-v' | '--version':
            trace(Constants.GENERATED_BY);
          case '--chart':
            if (args.length == 0)
            {
              trace('No chart path provided.');
              printUsage();
            }
            else
            {
              result.chart.shouldLoadChart = true;
              result.chart.chartPath = args.shift();
            }
        }
      }
      else
      {
        // Make an attempt to interpret the argument.

        if (arg.endsWith(Constants.EXT_CHART))
        {
          result.chart.shouldLoadChart = true;
          result.chart.chartPath = arg;
        }
        else
        {
          trace('Unrecognized argument: ${arg}');
          printUsage();
        }
      }
    }

    return result;
  }

  static function printUsage():Void
  {
    trace('Usage: Funkin.exe [--chart <chart>] [--help] [--version]');
  }

  static function buildDefaultParams():CLIParams
  {
    return {
      args: [],

      chart:
        {
          shouldLoadChart: false,
          chartPath: null
        }
    };
  }

  /**
   * Clean up the arguments passed to the application before parsing them.
   * @param args The arguments to clean up.
   * @return The cleaned up arguments.
   */
  static function cleanArgs(args:Array<String>):Array<String>
  {
    var result:Array<String> = [];

    if (args == null || args.length == 0) return result;

    return args.map(function(arg:String):String {
      if (arg == null) return '';

      return arg.trim();
    }).filter(function(arg:String):Bool {
      return arg != null && arg != '';
    });
  }
}

typedef CLIParams =
{
  var args:Array<String>;

  var chart:CLIChartParams;
}

typedef CLIChartParams =
{
  var shouldLoadChart:Bool;
  var chartPath:Null<String>;
};
