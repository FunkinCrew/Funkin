package funkin.external.crash;

#if cpp
@:build(funkin.util.macro.LinkerMacro.xml('project/Build.xml'))
@:include('nativecrash.hpp')
extern class NativeCrash
{
  /**
   * Installs the handler.
   * @param logDir Directory the report is written to, created if it does not exist.
   * @param appName Name shown in the dialog title and at the top of the report.
   */
  @:native('NATIVECRASH_Install')
  static function install(logDir:cpp.ConstCharStar, appName:cpp.ConstCharStar):Void;

  /**
   * Records what the game is currently doing, printed verbatim in the report.
   * @param info The breadcrumb, truncated if it does not fit.
   */
  @:native('NATIVECRASH_SetContext')
  static function setContext(info:cpp.ConstCharStar):Void;

  /**
   * Writes through a null pointer to trigger a real segfault, for testing the handler.
   */
  @:native('NATIVECRASH_ForceCrash')
  static function forceCrash():Void;
}
#end
