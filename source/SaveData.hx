import flixel.util.FlxSave;
import Config;

class SaveData
{
	var camlerp:FlxSave;
	camlerp = new FlxSave();
	camlerp.bind("camMovement");

	public static function initSave()
	{
		if (Config.fpsVal == 60)
		{
			//camlerp.data.camMove = 0.06;
			MusicBeatState.camMove = 0.06;
		}
		else if (Config.fpsVal == 90)
		{
			//camlerp.data.camMove = 0.9;
			MusicBeatState.camMove = 0.9;
		}
	}
}