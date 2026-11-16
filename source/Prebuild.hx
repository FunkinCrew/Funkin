package source; // Yeah, I know...

import sys.io.File;

using tools.AnsiUtil;

/**
 * A script which executes before the game is built.
 */
class Prebuild
{
  static inline final BUILD_TIME_FILE:String = '.build_time';

  static function main():Void
  {
    var start:Float = Sys.time();
    // Sys.println(' INFO '.bold().bg_blue() + " Performing pre-build tasks...");

    saveBuildTime();

    patchIOSURLScheme();

    var end:Float = Sys.time();
    var duration:Float = end - start;
    // Sys.println(' INFO '.bold().bg_blue() + ' Finished pre-build tasks in $duration seconds.');
  }

  static function saveBuildTime():Void
  {
    // PostBuild.hx reads this file and computes the total build duration.
    var fo:sys.io.FileOutput = File.write(BUILD_TIME_FILE);
    var now:Float = Sys.time();
    fo.writeDouble(now);
    fo.close();
  }

  static function patchIOSURLScheme():Void
  {
    final plist:Null<String> = Sys.getEnv('FUNKIN_IOS_INFO_PLIST');
    final scheme:Null<String> = Sys.getEnv('FUNKIN_IOS_URL_SCHEME');
    final name:Null<String> = Sys.getEnv('FUNKIN_IOS_URL_NAME');

    if (plist == null || plist == '' || scheme == null || scheme == '' || name == null || name == '') return;

    if (!sys.FileSystem.exists(plist))
    {
      Sys.println(' WARNING '.bold().bg_yellow() + ' Could not find $plist to add the "$scheme" URL scheme to.');
      return;
    }

    final existing:Null<String> = runPlistBuddy(plist, 'Print :CFBundleURLTypes');

    if (existing != null)
    {
      for (line in existing.split('\n'))
      {
        if (StringTools.trim(line) == scheme) return;
      }
    }
    else
    {
      runPlistBuddy(plist, 'Add :CFBundleURLTypes array');
    }

    for (command in [
      'Add :CFBundleURLTypes:0 dict',
      'Add :CFBundleURLTypes:0:CFBundleURLName string $name',
      'Add :CFBundleURLTypes:0:CFBundleTypeRole string Viewer',
      'Add :CFBundleURLTypes:0:CFBundleURLSchemes array',
      'Add :CFBundleURLTypes:0:CFBundleURLSchemes:0 string $scheme'
    ])
    {
      if (runPlistBuddy(plist, command) == null)
      {
        Sys.println(' WARNING '.bold().bg_yellow() + ' Failed to add the "$scheme" URL scheme to $plist ($command).');
        return;
      }
    }

    Sys.println(' INFO '.bold().bg_blue() + ' Added the "$scheme" URL scheme to $plist.');
  }

  static function runPlistBuddy(plist:String, command:String):Null<String>
  {
    final process:sys.io.Process = new sys.io.Process('/usr/libexec/PlistBuddy', ['-c', command, plist]);
    final output:String = process.stdout.readAll().toString();
    final exitCode:Int = process.exitCode();

    process.close();

    return exitCode == 0 ? output : null;
  }
}
