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
    var cwd:String = Path.addTrailingSlash(Sys.getCwd());
    var gameDir:String = '';
    #if android
    gameDir = Path.addTrailingSlash(extension.androidtools.content.Context.getExternalFilesDir());
    #elseif ios
    // Why? Because for some reason lime.system.System.documentsDirectory is returning a directory that's different and we're unable to read or write from, so it's disabled and no solution is found...
    trace('[WARN]: Reseting the Current Working Directory is unavailable on iOS targets');
    gameDir = cwd;
    #elseif mac
    gameDir = Path.addTrailingSlash(Path.join([Path.directory(Sys.programPath()), '../Resources/']));
    #else
    gameDir = Path.addTrailingSlash(Path.directory(Sys.programPath()));
    #end
    if (cwd == gameDir)
    {
      trace('Working directory is already correct.');
    }
    else
    {
      trace('Changing working directory from ${Sys.getCwd()} to ${gameDir}');
      Sys.setCwd(gameDir);
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
          case "--stage":
            if (args.length == 0)
            {
              trace('No stage path provided.');
              printUsage();
            }
            else
            {
              result.stage.shouldLoadStage = true;
              result.stage.stagePath = args.shift();
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
        else if (arg.endsWith(Constants.EXT_STAGE))
        {
          result.stage.shouldLoadStage = true;
          result.stage.stagePath = arg;
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
    trace('Usage: Funkin.exe [--chart <chart>] [--stage <stage>] [--help] [--version]');
  }

  static function buildDefaultParams():CLIParams
  {
    return {
      args: [],

      chart:
        {
          shouldLoadChart: false,
          chartPath: null
        },
      stage:
        {
          shouldLoadStage: false,
          stagePath: null
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
  var stage:CLIStageParams;
}

typedef CLIChartParams =
{
  var shouldLoadChart:Bool;
  var chartPath:Null<String>;
};

typedef CLIStageParams =
{
  var shouldLoadStage:Bool;
  var stagePath:Null<String>;
};
