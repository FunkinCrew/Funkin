package funkin.external.apple;

#if ((ios || macos) && cpp)
/**
 * A utility class to get information about the mem usage.
 */
@:build(funkin.util.macro.LinkerMacro.xml('project/Build.xml'))
@:include('MemoryUtil.hpp')
@:unreflective
extern class MemoryUtil
{
  /**
   * Retrieves the current process's resident set size (RSS) in bytes on Apple platforms.
   *
   * @return The resident set size (RSS) in bytes if successful; otherwise, returns 0 on failure.
   */
  @:native('Apple_MemoryUtil_GetCurrentProcessRss')
  static function getCurrentProcessRss():cpp.SizeT;
}
#end
