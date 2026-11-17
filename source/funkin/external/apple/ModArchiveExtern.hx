package funkin.external.apple;

#if (ios && cpp)
/**
 * Utility class for importing mod archives on Apple devices
 */
@:build(funkin.util.macro.LinkerMacro.xml('project/Build.xml'))
@:include('FNFCExtern.hpp')
@:unreflective
extern class ModArchiveExtern
{
  /**
   * Copies the mod archiv efrom the specified URL into the app cache
   *
   * @param url The URL of the mod archive
   * @param callback A function to be called when copy operation completes
   */
  @:native('Apple_ModArchiveExtern_CopyModArchiveIntoCache')
  static function copyModArchiveIntoCache(url:cpp.ConstCharStar,
    callback:cpp.Callable<(event:cpp.ConstCharStar, value:cpp.ConstCharStar) -> Void>):Void;
}
#end
