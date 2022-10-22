package;

import flixel.FlxG;

/*
* Loosely based off of Kade Engine's Options Menu! 
* this is a WIP!!! may not work properly
*/

class OptionCategory
{
	private var _options:Array<Option> = [];
	private var _name:String = "Category";

	public final function getName():String
	{
		return _name;
	}

	public final function getOptions():Array<Option>
	{
		return _options;
	}

	public final function appendOption(option:Option)
	{
		_options.push(option);
	}

	public final function removeOption(option:Option)
	{
		_options.remove(option);
	}

	public function new(name:String, options:Array<Option>)
	{
		_name = name;
		_options = options;
	}
}


class Option
{
	private var display:String = "";
	private var description:String = "Description";

	public function new()
	{
		display = updateText();
	}

	public final function getDisplay():String
	{
		return display;
	}

	public final function getDescription():String
	{
		return description;
	}

	private function updateText():String { return ""; }
	public function onPress():Bool { return false; }
}

class PauseCountdownOption extends Option
{
	public function new(desc:String)
	{
		super();
		description = desc;
	}

	override public function onPress():Bool
	{
		FlxG.save.data.pauseCountdown = !FlxG.save.data.pauseCountdown;
		return true;
	}

	override private function updateText():String
	{
		return FlxG.save.data.pauseCountdown ? "COUNTDOWN TRUE" : "COUNTDOWN FALSE";
	}
}