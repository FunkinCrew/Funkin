package source; // Yeah, I know...

import sys.io.File;

class Prebuild
{
  static inline final buildTimeFile = '.build_time';

  static function main()
  {
    saveBuildTime();
    trace('Building...');
  }

  static function saveBuildTime()
  {
    var fo = File.write(buildTimeFile);
    var now = Sys.time();
    fo.writeDouble(now);
    fo.close();
  }
}
