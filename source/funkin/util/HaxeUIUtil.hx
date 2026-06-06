package funkin.util;

#if FEATURE_HAXEUI
import haxe.ui.tooltips.ToolTipRegionOptions;
import haxe.ui.util.Color as HaxeUIColor;

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

  /**
   * Builds HTML-styled text from an array of text components
   * @param components A list of text components to build
   * @return The HTML-styled text
   */
  public static function buildStyledHTML(components:Array<TextComponent>):String
  {
    var result:String = '';
    for (component in components)
    {
      var part:String = '${component.text}';

      // font color is sadly the only supported thing in HaxeUI
      if (component.color != null)
      {
        part = '<font color="${component.color.toHex()}">${component.text}</font>';
      }

      result += part;
    }
    return result;
  }
}

/**
 * A simplified object for building styled text.
 */
typedef TextComponent =
{
  /**
   * The text to display.
   */
  text:String,

  /**
   * The color of the text.
   */
  ?color:HaxeUIColor
};

#end
