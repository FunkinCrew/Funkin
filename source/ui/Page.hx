package ui;

import flixel.FlxG;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.util.FlxSignal;
import flixel.util.FlxSignal.FlxTypedSignal;

using StringTools;

class Page extends FlxTypedGroup<Dynamic>
{
	var enabled:Bool = true;
	var canExit:Bool = true;
	public var onExit:FlxSignal;
	public var onSwitch:FlxTypedSignal<PageName->Void>;

	override public function new(MaxSize:Int = 0)
	{
		onExit = new FlxSignal();
		onSwitch = new FlxTypedSignal<PageName->Void>();
		super(MaxSize);
	}

	public function exit()
	{
		onExit.dispatch();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		if (enabled) updateEnabled(elapsed);
	}

	function updateEnabled(elapsed:Float)
	{
		if (canExit && PlayerSettings.player1.controls.BACK)
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));
			onExit.dispatch();
		}
	}

	public function set_enabled(state:Bool)
	{
		return enabled = state;
	}

	public function openPrompt(prompt, callback)
	{
		set_enabled(false);
		prompt.closeCallback = function()
		{
			set_enabled(true);
			if (callback != null)
				callback();
		}
	}

	override public function destroy()
	{
		super.destroy();
		onSwitch.removeAll;
	}
}