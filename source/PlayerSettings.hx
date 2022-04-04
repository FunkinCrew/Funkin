package;

import flixel.input.gamepad.FlxGamepad;
import haxe.Json;
import Controls;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.util.FlxSignal;

// import ui.DeviceManager;
// import props.Player;
class PlayerSettings
{
	static public var numPlayers(default, null) = 0;
	// static public var numAvatars(default, null) = 0;
	static public var player1(default, null):PlayerSettings;
	static public var player2(default, null):PlayerSettings;

	#if (haxe >= "4.0.0")
	static public final onAvatarAdd = new FlxTypedSignal<PlayerSettings->Void>();
	static public final onAvatarRemove = new FlxTypedSignal<PlayerSettings->Void>();
	#else
	static public var onAvatarAdd = new FlxTypedSignal<PlayerSettings->Void>();
	static public var onAvatarRemove = new FlxTypedSignal<PlayerSettings->Void>();
	#end

	public var id(default, null):Int;

	#if (haxe >= "4.0.0")
	public final controls:Controls;
	#else
	public var controls:Controls;
	#end

	// public var avatar:Player;
	// public var camera(get, never):PlayCamera;

	function new(id)
	{
		this.id = id;
		controls = new Controls('player$id', KeyboardScheme.None);
		var setDefault:Bool = true;
		var saveControls = FlxG.save.data.controls;
		if (saveControls != null)
		{
			var keys = null;
			if (id == 0 && saveControls.p1 != null && saveControls.p1.keys != null)
			{
				keys = saveControls.p1.keys;
			}
			else if (id == 1 && saveControls.p2 != null && saveControls.p2.keys != null)
			{
				keys = saveControls.p2.keys;
			}
			if (keys != null)
			{
				setDefault = false;
				trace('loaded key data: ' + Json.stringify(keys));
				controls.fromSaveData(keys, Device.Keys);
			}
		}
		if (setDefault)
		{
			controls.setKeyboardScheme(KeyboardScheme.Solo);
		}
	}

	function addGamepad(pad:FlxGamepad)
	{
		var setDefault:Bool = true;
		var saveControls = FlxG.save.data.controls;
		if (saveControls != null)
		{
			var pad = null;
			if (id == 0 && saveControls.p1 != null && saveControls.p1.pad != null)
			{
				pad = saveControls.p1.pad;
			}
			else if (id == 1 && saveControls.p2 != null && saveControls.p2.pad != null)
			{
				pad = saveControls.p2.pad;
			}
			if (pad != null)
			{
				setDefault = false;
				trace('loaded pad data: ' + Json.stringify(pad));
				controls.addGamepadWithSaveData(pad.id, pad);
			}
		}
		if (setDefault)
		{
			controls.addDefaultGamepad(pad.id);
		}
	}

	public function saveControls()
	{
		if (FlxG.save.data.controls == null)
		{
			FlxG.save.data.controls = {};
		}
		var keydata = null;
		if (id == 0)
		{
			if (FlxG.save.data.controls.p1 == null)
			{
				FlxG.save.data.controls.p1 = {};
			}
			keydata = FlxG.save.data.controls.p1;
		}
		else
		{
			if (FlxG.save.data.controls.p2 == null)
			{
				FlxG.save.data.controls.p2 = {};
			}
			keydata = FlxG.save.data.controls.p2;
		}
		var savedata = this.controls.createSaveData(Device.Keys);
		if (savedata != null)
		{
			keydata.keys = savedata;
			trace('saving key data: ' + Json.stringify(savedata));
		}
		if (controls.gamepadsAdded.length > 0)
		{
			savedata = this.controls.createSaveData(Device.Gamepad(controls.gamepadsAdded[0]));
			if (savedata != null)
			{
				trace('saving pad data: ' + Json.stringify(savedata));
				keydata.pad = savedata;
			}
		}
		FlxG.save.flush();
	}

	static public function init():Void
	{
		if (player1 == null)
		{
			player1 = new PlayerSettings(0);
			numPlayers++;
		}

		FlxG.gamepads.deviceConnected.add(onGamepadAdded);
		for (pad in FlxG.gamepads.getActiveGamepads())
		{
			if (pad != null)
			{
				onGamepadAdded(pad);
			}
		}
	}

	static public function onGamepadAdded(pad):Void
	{
		player1.addGamepad(pad);
	}
}
