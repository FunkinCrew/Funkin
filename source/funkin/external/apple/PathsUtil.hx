package funkin.external.apple;

#if ((ios || macos) && cpp)
/**
 * A utility class to get application paths.
 */
@:build(funkin.util.macro.LinkerMacro.xml('project/Build.xml'))
@:include('PathsUtil.hpp')
@:unreflective
extern class PathsUtil
{
  /**
   * Returns the current application's cache directory.
   *
   * @return A UTF-8 string containing the cache directory path, or `NULL` on failure.
   */
  @:native('Apple_PathsUtil_GetCacheDirectory')
  static function getCacheDirectory():cpp.ConstCharStar;
}
#end
