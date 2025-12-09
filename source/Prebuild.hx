package source; // Yeah, I know...

import sys.io.File;

/**
 * A script which executes before the game is built.
 */
class Prebuild
{
  static inline final BUILD_TIME_FILE:String = '.build_time';

  static function main():Void
  {
    var start:Float = Sys.time();
    // Sys.println('[INFO] Performing pre-build tasks...');

    saveBuildTime();

    var end:Float = Sys.time();
    var duration:Float = end - start;
    // Sys.println('[INFO] Finished pre-build tasks in $duration seconds.');
  }

  static function saveBuildTime():Void
  {
    // PostBuild.hx reads this file and computes the total build duration.
    var fo:sys.io.FileOutput = File.write(BUILD_TIME_FILE);
    var now:Float = Sys.time();
    fo.writeDouble(now);
    fo.close();
  }
}
