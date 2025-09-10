package funkin.external.apple;

#if ios
@:build(funkin.util.macro.LinkerMacro.xml('project/Build.xml'))
@:include('FNFCUtil.hpp')
@:unreflective
extern class FNFCUtil
{
  @:native('copyFNFCIntoCache')
  static function copyFNFCIntoCache(url:cpp.ConstCharStar):cpp.ConstCharStar;
}
#end
