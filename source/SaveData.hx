import flixel.util.FlxSave;
import Config;

class SaveData
{
	var camlerp:FlxSave;
	camlerp = new FlxSave();
	camlerp.bind("camMovement");

	public static function initSave()
	{
		if (Config.fps == 60)
			camlerp.data.camMove = 0.06;
		else if (Config.fps == 90)
		
	}
}