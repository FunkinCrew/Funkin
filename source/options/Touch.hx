/*
package options;

import flixel.FlxG;
import flixel.graphics.frames.FlxTileFrames;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxPoint;
import flixel.system.FlxAssets;
import flixel.util.FlxDestroyUtil;
import flixel.ui.FlxButton;
import flixel.graphics.frames.FlxAtlasFrames;
import flash.display.BitmapData;
import flixel.graphics.FlxGraphic;
import openfl.utils.ByteArray;

class Touch extends FlxSpriteGroup
{
    public var UP_P = false;
    public var DOWN_P = false;
    public var RIGHT_P = false;
    public var LEFT_P = false;


    var tx:Float;
    var ty:Float;


	public function new()
	{
		super();
	}

    override public function update() {
        for (touch in FlxG.touches.list)
        {
            UP_P = false;
            DOWN_P = false;
            

            if (touch.justPressed){
                tx = touch.x;
                ty = touch.y;
            }
            if (touch.justReleased){
                if (touch.y > ty && (touch.y - ty > 300))
                {
                    DOWN_P = true;
                } else if (touch.y < ty && (ty - touch.y > 300)) 
                {
                    UP_P = true;
                }


                if (touch.x > tx && (touch.x - tx > 300))
                {
                    RIGHT_P = true;
                } else if (touch.x < tx && (tx - touch.x > 300)) 
                {
                    LEFT_P = true;
                }
            }

        }


        super();
    }
}

*/