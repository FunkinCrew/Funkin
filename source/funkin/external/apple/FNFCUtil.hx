package funkin.external.apple;

#if ((ios || macos) && cpp)
/**
 * A utility class for FNFC loading on apple devices.
 */
@:build(funkin.util.macro.LinkerMacro.xml('project/Build.xml'))
@:include('FNFCUtil.hpp')
@:unreflective
extern class FNFCUtil
{
  /**
   * Copies the FNFC resource from the specified URL into the cache.
   *
   * @param url The URL of the FNFC resource to copy into the cache.
   * @param callback A function to be called when the copy operation completes.
   */
  @:native('Apple_FNFCUtil_CopyFNFCIntoCache')
  static function copyFNFCIntoCache(url:cpp.ConstCharStar, callback:cpp.Callable<(event:cpp.ConstCharStar, value:cpp.ConstCharStar) -> Void>):Void;
}
#end
