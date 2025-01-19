package funkin.mobile.external;

/**
 * A Utility class to get iOS screen related informations.
 */
@:build(funkin.mobile.macros.LinkerMacro.xml('project/Build.xml'))
@:include('ScreenUtils.hpp')
@:unreflective
extern class ScreenUtils
{
  @:native('getSafeAreaInsets')
  static function getSafeAreaInsets(top:cpp.RawPointer<Float>, bottom:cpp.RawPointer<Float>, left:cpp.RawPointer<Float>, right:cpp.RawPointer<Float>):Void;
}
