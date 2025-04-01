package funkin.util;

import haxe.ui.tooltips.ToolTipRegionOptions;

class HaxeUIUtil
{
  public static function buildTooltip(text:String, ?left:Float, ?top:Float, ?width:Float, ?height:Float):ToolTipRegionOptions
  {
    return {
      tipData: {text: text},
      left: left ?? 0.0,
      top: top ?? 0.0,
      width: width ?? 0.0,
      height: height ?? 0.0
    }
  }
}
