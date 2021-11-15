package ui;

import flixel.graphics.frames.FlxAtlasFrames;
import flixel.FlxSprite;

using StringTools;

class AtlasMenuItem extends MenuItem
{	
	var atlas:FlxAtlasFrames;

	public function new(X:Float = 0, Y:Float = 0, name:String, atlas:FlxAtlasFrames, callback:Dynamic)
	{
		this.atlas = atlas;
		super(X, Y, name, callback);
	}

	public override function setData(name:String, callback:Dynamic = null)
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

	public override function idle()
	{
		changeAnim('idle');
	}

	public override function select()
	{
		changeAnim('selected');
	}

	public override function get_selected()
	{
		return animation.curAnim != null ? animation.curAnim.name == 'selected' : false;
	}
}