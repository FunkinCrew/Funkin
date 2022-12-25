package;

import flixel.FlxG;
import openfl.display.BitmapData;
import openfl.utils.Assets;

class AssetManager {

    public static function getBitmapData(id:String, useCache:Bool = true):BitmapData
    {
        var bitmap = Assets.getBitmapData(id, useCache);

        var maxTextureSize = FlxG.bitmap.maxTextureSize;

        if (maxTextureSize < Math.max(bitmap.image.width, bitmap.image.height))
        {
            var newWidth = Math.floor(bitmap.image.width / Math.ceil(bitmap.image.width / maxTextureSize));
            var newHeight = Math.floor(bitmap.image.height / Math.ceil(bitmap.image.height / maxTextureSize));

            bitmap.image.resize(newWidth, newHeight);
        }

        return bitmap;
    }
}