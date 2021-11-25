package;

import flixel.FlxG;

using StringTools;

class VideoState extends MusicBeatState
{
	public static var seenVideo:Bool = false;

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (FlxG.keys.justPressed.ESCAPE)
		{
			FlxG.switchState(new TitleState());
		}
	}
}