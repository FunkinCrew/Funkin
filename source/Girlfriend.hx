package;

import flixel.graphics.frames.FlxAtlasFrames;

class Girlfriend extends Character
{
	public function new(x:Float, y:Float)
	{
		super(x, y);

		var tex = FlxAtlasFrames.fromSparrow(AssetPaths.GF_assets__png, AssetPaths.GF_assets__xml);
		frames = tex;
		animation.addByPrefix('cheer', 'GF Cheer');
		animation.addByIndices('sad', 'gf sad', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12], "", 24, false);
		animation.addByIndices('danceLeft', 'GF Dancing Beat', [30, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14], "", 24, false);
		animation.addByIndices('danceRight', 'GF Dancing Beat', [15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29], "", 24, false);

		addOffset('cheer');
		addOffset('sad');
		addOffset('danceLeft');
		addOffset('danceRight');

		playAnim('danceRight');
	}

	private var danced:Bool = false;

	public function dance()
	{
		danced = !danced;

		if (danced)
			playAnim('danceRight');
		else
			playAnim('danceLeft');
	}
}
