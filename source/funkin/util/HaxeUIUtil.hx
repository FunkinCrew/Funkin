package funkin.util;

import haxe.ui.tooltips.ToolTipRegionOptions;

@:nullSafety
class HaxeUIUtil
{
  public static function buildTooltip(text:String, left:Float = 0.0, top:Float = 0.0, width:Float = 0.0, height:Float = 0.0):ToolTipRegionOptions
  {
    return {
      tipData: {text: text},
      left: left,
      top: top,
      width: width,
      height: height
    }
  }
}
