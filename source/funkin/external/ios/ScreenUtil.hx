package funkin.external.ios;

#if ios
/**
 * A Utility class to get iOS screen related informations.
 */
@:build(funkin.util.macro.LinkerMacro.xml('project/Build.xml'))
@:include('ScreenUtil.hpp')
@:unreflective
extern class ScreenUtil
{
  @:native('getSafeAreaInsets')
  static function getSafeAreaInsets(top:cpp.RawPointer<Float>, bottom:cpp.RawPointer<Float>, left:cpp.RawPointer<Float>, right:cpp.RawPointer<Float>):Void;

  @:native('getScreenSize')
  static function getScreenSize(width:cpp.RawPointer<Float>, height:cpp.RawPointer<Float>):Void;
}
#end
