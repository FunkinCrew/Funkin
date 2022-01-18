package ui;

import flixel.graphics.frames.FlxAtlasFrames;
import flixel.FlxSprite;

using StringTools;

class AtlasMenuItem extends MenuItem
{	
	var atlas:FlxAtlasFrames;

	public function new(?X:Float = 0, ?Y:Float = 0, name:String, atlas:FlxAtlasFrames, callback:Dynamic)
	{
		this.atlas = atlas;
		super(X, Y, name, callback);
	}

	override public function setData(name:String, callback:Dynamic = null)
	{
		frames = atlas;
		animation.addByPrefix('idle', '$name idle', 24);
		animation.addByPrefix('selected', '$name selected', 24);
		super.setData(name, callback);
	}

	public function changeAnim(anim:String)
	{
		animation.play(anim);
		updateHitbox();
	}

	override public function idle()
	{
		changeAnim('idle');
	}

	override public function select()
	{
		changeAnim('selected');
	}

	override function get_selected()
	{
		return animation.curAnim != null ? animation.curAnim.name == 'selected' : false;
	}
}