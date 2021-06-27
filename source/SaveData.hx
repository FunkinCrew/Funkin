import flixel.util.FlxSave;
import Config;

class SaveData
{
	public static function initLoad()
	{
		if (FlxG.save.data.camMove == null)
			FlxG.save.data.camMove == 0.06;

		if (FlxG.save.data.downscroll = null)
			FlxG.save.data.downscroll = false:

		if (FlxG.save.data.dfjk = null)
			FlxG.save.data.dfjk = false;

		if (FlxG.save.data.controlmode == null)
		    FlxG.save.data.controlmode == 0;
	}
}