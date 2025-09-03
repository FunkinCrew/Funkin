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
    var units = [
      {name: "day", secs: 86400},
      {name: "hour", secs: 3600},
      {name: "minute", secs: 60},
      {name: "second", secs: 1}
    ];

    var parts:Array<String> = [];
    var remaining:Float = time;

    for (unit in units)
    {
      var value:Float;
      if (unit.name == "second")
      {
        // handle seconds with decimals
        value = Math.round(remaining * Math.pow(10, decimals)) / Math.pow(10, decimals);
      }
      else
      {
        value = Math.floor(remaining / unit.secs);
        remaining %= unit.secs;
      }

      //
      if (value > 0 || (unit.name == "second" && parts.length == 0))
      {
        parts.push('${value} ${unit.name}${value == 1 ? "" : "s"}');
      }
    }

    return parts.join(" ");
  }
}
