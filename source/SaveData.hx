import flixel.util.FlxSave;
import ui.FlxVirtualPad;
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

		if (FlxG.save.data.buttons = null)
		{
			FlxG.save.data.buttons = new Array();
			var _pad:FlxVirtualPad;

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
	}
}