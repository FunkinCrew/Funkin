package source; // Yeah, I know...

import sys.FileSystem;
import sys.io.File;

class Postbuild
{
  static inline final buildTimeFile = '.build_time';

  static function main()
  {
    printBuildTime();
  }

  static function printBuildTime()
  {
    // get buildEnd before fs operations since they are blocking
    var end:Float = Sys.time();
    if (FileSystem.exists(buildTimeFile))
    {
      var fi = File.read(buildTimeFile);
      var start:Float = fi.readDouble();
      fi.close();

      sys.FileSystem.deleteFile(buildTimeFile);

      var buildTime = roundToTwoDecimals(end - start);

      trace('Build took: ${buildTime} seconds');
    }
  }

  private static function roundToTwoDecimals(value:Float):Float
  {
    return Math.round(value * 100) / 100;
  }
}
