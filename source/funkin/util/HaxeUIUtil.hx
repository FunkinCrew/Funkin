package funkin.util;

#if FEATURE_HAXEUI
import haxe.ui.tooltips.ToolTipRegionOptions;

/**
 * Utility functions for working with HaxeUI.
 */
@:nullSafety
class HaxeUIUtil
{
  /**
   * Builds a ToolTipRegionOptions object with the specified text and positioning parameters.
   *
   * @param text The text to display in the tooltip.
   * @param left The left position of the tooltip.
   * @param top The top position of the tooltip.
   * @param width The width of the tooltip.
   * @param height The height of the tooltip.
   * @return A ToolTipRegionOptions object configured with the provided parameters.
   */
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
#end
