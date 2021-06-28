import flixel.util.FlxSave;
import ui.FlxVirtualPad;
import Config;
import flixel.math.FlxPoint;
import flixel.FlxG;

class SaveData
{
	//var _pad:FlxVirtualPad;
	public static function initLoad()
	{
		if (FlxG.save.data.camMove == null)
			FlxG.save.data.camMove = 0.06;

		if (FlxG.save.data.downscroll == null)
			FlxG.save.data.downscroll = false;

		if (FlxG.save.data.dfjk == null)
			FlxG.save.data.dfjk = false;

		if (FlxG.save.data.controlmode == null)
			FlxG.save.data.controlmode = 0;

		if (FlxG.save.data.splash == null)
			FlxG.save.data.splash = true;

		if (FlxG.save.data.cutscene == null)
			FlxG.save.data.cutscene = true;
	}

	public static function initButton(_pad:FlxVirtualPad):FlxVirtualPad
	{
		if (FlxG.save.data.buttons == null)
		{
			FlxG.save.data.buttons = new Array();

			for (buttons in _pad)
			{
				FlxG.save.data.buttons.push(FlxPoint.get(buttons.x, buttons.y));
			}
		}else
		{
			var tempCount:Int = 0;
			for (buttons in _pad)
			{
				FlxG.save.data.buttons[tempCount] = FlxPoint.get(buttons.x, buttons.y);
				tempCount++;
			}
		}
		return _pad;
		FlxG.save.flush();
	}
}