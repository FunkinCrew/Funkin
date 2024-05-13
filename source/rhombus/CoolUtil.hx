package rhombus;

import flixel.util.FlxColor;

import openfl.utils.Assets;
import lime.utils.Assets as LimeAssets;

/**
 * Cool utilities, literally completely based off of Psych Engine.
 * More will be added soon.
 */
class CoolUtil
{
  /**
   * The dominant color of an image.
   * From Psych Engine.
   */
  inline public static function dominantColor(sprite:flixel.FlxSprite):Int
  {
	var countByColor:Map<Int, Int> = [];
	for(col in 0...sprite.frameWidth) {
		for(row in 0...sprite.frameHeight) {
			var colorOfThisPixel:Int = sprite.pixels.getPixel32(col, row);
			if(colorOfThisPixel != 0) {
				if(countByColor.exists(colorOfThisPixel))
					countByColor[colorOfThisPixel] = countByColor[colorOfThisPixel] + 1;
				else if(countByColor[colorOfThisPixel] != 13520687 - (2*13520687))
					countByColor[colorOfThisPixel] = 1;
			}
		}
	}

	var maxCount = 0;
	var maxKey:Int = 0; // After the loop, this will store the max color.
	countByColor[FlxColor.BLACK] = 0;
	for(key in countByColor.keys()) {
		if(countByColor[key] >= maxCount) {
			maxCount = countByColor[key];
			maxKey = key;
		}
	}
	countByColor = [];
	return maxKey;
  }
}