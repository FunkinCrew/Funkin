package;

import flixel.FlxG;
import openfl.display.BitmapData;
import openfl.utils.Assets;

class AssetManager {

    public static var maxCustomTextureSize:Float = 0;

    public static function getBitmapData(id:String, useCache:Bool = true):BitmapData
    {
        var bitmap = Assets.getBitmapData(id, useCache);

        var maxImageSize = Math.max(bitmap.image.width, bitmap.image.height);

        var maxTextureSize = FlxG.bitmap.maxTextureSize;

        trace(maxImageSize);
        trace(maxCustomTextureSize);
        if (maxCustomTextureSize != 0 && maxImageSize > 1024)
        {
            maxTextureSize = Math.round(maxImageSize * maxCustomTextureSize);

            trace(maxTextureSize);
        }

        if (maxTextureSize < maxImageSize)
        {
            var newWidth = Math.floor(bitmap.image.width / Math.ceil(bitmap.image.width / maxTextureSize));
            var newHeight = Math.floor(bitmap.image.height / Math.ceil(bitmap.image.height / maxTextureSize));

            bitmap.image.resize(newWidth, newHeight);
        }

        return bitmap;
    }
}