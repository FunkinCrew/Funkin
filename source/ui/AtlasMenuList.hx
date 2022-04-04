package ui;

import flixel.graphics.frames.FlxAtlasFrames;
import flixel.util.typeLimit.OneOfTwo;

class AtlasMenuList extends MenuTypedList<AtlasMenuItem>
{
	var atlas:FlxAtlasFrames;

	public function new(atlas:OneOfTwo<String, FlxAtlasFrames>, dir:NavControls = Vertical, ?wrapDir:WrapMode)
	{
		super(dir, wrapDir);

		if (Std.isOfType(atlas, String))
		{
			this.atlas = Paths.getSparrowAtlas(atlas);
		}
		else
		{
			this.atlas = atlas;
		}
	}

	override public function destroy()
	{
		super.destroy();
		atlas = null;
	}
}