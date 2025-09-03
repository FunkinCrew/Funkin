package source; // Yeah, I know...

import sys.FileSystem;
import sys.io.File;

using StringTools;

/**
 * A script which executes after the game is built.
 */
class Postbuild
{
  static inline final BUILD_TIME_FILE:String = '.build_time';

  static function main():Void
  {
    printBuildTime();
  }

  static function printBuildTime():Void
  {
    // get buildEnd before fs operations since they are blocking
    var end:Float = Sys.time();
    if (FileSystem.exists(BUILD_TIME_FILE))
    {
      var fi:sys.io.FileInput = File.read(BUILD_TIME_FILE);
      var start:Float = fi.readDouble();
      fi.close();

      sys.FileSystem.deleteFile(BUILD_TIME_FILE);

      Sys.println('[INFO] Build took: ${format(end - start)}');
    }
  }

  static function format(time:Float, decimals:Int = 1):String
  {
    var parts:Array<String> = [];
    var days:Int = Math.floor(time / 86400);
    var hours:Int = Math.floor((time % 86400) / 3600);
    var minutes:Int = Math.floor((time % 3600) / 60);
    var secs:Float = time % 60;

    if (days > 0)
    {
      parts.push('$days ${(days == 1 ? "day" : "days")}');
    }

    if (hours > 0)
    {
      parts.push('$hours ${(hours == 1 ? "hour" : "hours")}');
    }

    if (minutes > 0)
    {
      parts.push('$minutes ${(minutes == 1 ? "minute" : "minutes")}');
    }

    if (secs > 0 || parts.length == 0)
    {
      parts.push('${Std.string(Math.round(secs * Math.pow(10, decimals)) / Math.pow(10, decimals)).trim()} ${(secs == 1.0 ? "second" : "seconds")}');
    }

    return parts.join(' ');
  }
}
