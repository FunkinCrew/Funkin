package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.animation.FlxBaseAnimation;
import flixel.graphics.frames.FlxAtlasFrames;

using StringTools;

class GF extends Character
{

	override function dance():Void
	{
		playAnim('idle');
	}


}
