package funkin.util.assets;

import funkin.play.AnimationData;
import flixel.FlxSprite;

class FlxAnimationUtil
{
	/**
	 * Properly adds an animation to a sprite based on JSON data.
	 */
	public static function addAtlasAnimation(target:FlxSprite, anim:AnimationData)
	{
		var frameRate = anim.frameRate == null ? 24 : anim.frameRate;
		var looped = anim.looped == null ? false : anim.looped;
		var flipX = anim.flipX == null ? false : anim.flipX;
		var flipY = anim.flipY == null ? false : anim.flipY;

		if (anim.frameIndices != null && anim.frameIndices.length > 0)
		{
			// trace('addByIndices(${anim.name}, ${anim.prefix}, ${anim.frameIndices}, ${frameRate}, ${looped}, ${flipX}, ${flipY})');
			target.animation.addByIndices(anim.name, anim.prefix, anim.frameIndices, "", frameRate, looped, flipX, flipY);
			// trace('RESULT:${target.animation.getAnimationList()}');
		}
		else
		{
			// trace('addByPrefix(${anim.name}, ${anim.prefix}, ${frameRate}, ${looped}, ${flipX}, ${flipY})');
			target.animation.addByPrefix(anim.name, anim.prefix, frameRate, looped, flipX, flipY);
			// trace('RESULT:${target.animation.getAnimationList()}');
		}
	}

	/**
	 * Properly adds multiple animations to a sprite based on JSON data.
	 */
	public static function addAtlasAnimations(target:FlxSprite, animations:Array<AnimationData>)
	{
		for (anim in animations)
		{
			addAtlasAnimation(target, anim);
		}
	}
}
