package source; // Yeah, I know...

import sys.io.File;

/**
 * A script which executes before the game is built.
 */
class Prebuild
{
  static inline final BUILD_TIME_FILE:String = '.build_time';

  static final NG_CREDS_PATH:String = './source/funkin/api/newgrounds/NewgroundsCredentials.hx';

  static final NG_CREDS_TEMPLATE:String = "package funkin.api.newgrounds;

class NewgroundsCredentials
{
  public static final APP_ID:String = #if API_NG_APP_ID haxe.macro.Compiler.getDefine(\"API_NG_APP_ID\") #else 'INSERT APP ID HERE' #end;
  public static final ENCRYPTION_KEY:String = #if API_NG_ENC_KEY haxe.macro.Compiler.getDefine(\"API_NG_ENC_KEY\") #else 'INSERT ENCRYPTION KEY HERE' #end;
}";

  static function main():Void
  {
    var start:Float = Sys.time();
    trace('[PREBUILD] Performing pre-build tasks...');

    saveBuildTime();

    buildCredsFile();
    buildHXCPP();

    var end:Float = Sys.time();
    var duration:Float = end - start;
    trace('[PREBUILD] Finished pre-build tasks in $duration seconds.');
  }

  static function saveBuildTime():Void
  {
    // PostBuild.hx reads this file and computes the total build duration.
    var fo:sys.io.FileOutput = File.write(BUILD_TIME_FILE);
    var now:Float = Sys.time();
    fo.writeDouble(now);
    fo.close();
  }

  static function buildCredsFile():Void
  {
    if (sys.FileSystem.exists(NG_CREDS_PATH))
    {
      trace('[PREBUILD] NewgroundsCredentials.hx already exists, skipping.');
    }
    else
    {
      trace('[PREBUILD] Creating NewgroundsCredentials.hx...');

      var fileContents:String = NG_CREDS_TEMPLATE;

      sys.io.File.saveContent(NG_CREDS_PATH, fileContents);
    }
  }

  static function buildHXCPP():Void
  {
    // This sometimes needs to be run on HXCPP development builds.
    // It's quick enough to run that it saves work to just run it every time.
    trace('[PREBUILD] Building HXCPP binaries...');

    Sys.command("cd", [".\\.haxelib\\hxcpp\\git\\tools\\hxcpp"]);
    Sys.command("haxe", ["compile.hxml"]);
  }
}
