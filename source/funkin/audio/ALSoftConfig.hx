package funkin.audio;

#if desktop
import haxe.io.Path;

import sys.FileSystem;

/*
 * A class that simply points the audio backend OpenALSoft to use a custom
 * configuration when the game starts up.
 *
 * The config file overrides a few global OpenALSoft settings to improve audio
 * quality on desktop targets.
 */
@:nullSafety
class ALSoftConfig
{
  private static function __init__():Void
  {
    var configPath:String = Path.directory(Path.withoutExtension(#if hl Sys.getCwd() #else Sys.programPath() #end));
    #if windows
    configPath += "/plugins/alsoft.ini";
    #elseif mac
    configPath = '${Path.directory(configPath)}/Resources/plugins/alsoft.conf';
    #else
    configPath += "/plugins/alsoft.conf";
    #end

    Sys.putEnv("ALSOFT_CONF", FileSystem.fullPath(configPath));
  }
}
#end
