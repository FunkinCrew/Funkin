package;

import Controls;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.input.actions.FlxActionInput;
import flixel.input.gamepad.FlxGamepad;
import flixel.util.FlxSignal;

// import ui.DeviceManager;
// import props.Player;
class PlayerSettings
{
	static public var numPlayers(default, null) = 0;
	static public var numAvatars(default, null) = 0;
	static public var player1(default, null):PlayerSettings;
	static public var player2(default, null):PlayerSettings;

	static public var onAvatarAdd(default, null) = new FlxTypedSignal<PlayerSettings->Void>();
	static public var onAvatarRemove(default, null) = new FlxTypedSignal<PlayerSettings->Void>();

	public var id(default, null):Int;

	public var controls(default, null):Controls;

	// public var avatar:Player;
	// public var camera(get, never):PlayCamera;

	function new(id)
	{
		this.id = id;
		this.controls = new Controls('player$id', None);
		
		#if CLEAR_INPUT_SAVE
		FlxG.save.data.controls = null;
		FlxG.save.flush();
		#end
		
		var useDefault = true;
		var controlData = FlxG.save.data.controls;
		if (controlData != null)
		{
			var keyData:Dynamic = null;
			if (id == 0 && controlData.p1 != null && controlData.p1.keys != null)
				keyData = controlData.p1.keys;
			else if (id == 1 && controlData.p2 != null && controlData.p2.keys != null)
				keyData = controlData.p2.keys;
			
			if (keyData != null)
			{
				useDefault = false;
				trace("loaded key data: " + haxe.Json.stringify(keyData));
				controls.fromSaveData(keyData, Keys);
			}
		}
		
		if (useDefault)
			controls.setKeyboardScheme(Solo);
	}
	
	function addGamepad(gamepad:FlxGamepad)
	{
		var useDefault = true;
		var controlData = FlxG.save.data.controls;
		if (controlData != null)
		{
			var padData:Dynamic = null;
			if (id == 0 && controlData.p1 != null && controlData.p1.pad != null)
				padData = controlData.p1.pad;
			else if (id == 1 && controlData.p2 != null && controlData.p2.pad != null)
				padData = controlData.p2.pad;
			
			if (padData != null)
			{
				useDefault = false;
				trace("loaded pad data: " + haxe.Json.stringify(padData));
				controls.addGamepadWithSaveData(gamepad.id, padData);
			}
		}
		
		if (useDefault)
			controls.addDefaultGamepad(gamepad.id);
	}
	
	public function saveControls()
	{
		if (FlxG.save.data.controls == null)
			FlxG.save.data.controls = {};
		
		var playerData:{ ?keys:Dynamic, ?pad:Dynamic }
		if (id == 0)
		{
			if (FlxG.save.data.controls.p1 == null)
				FlxG.save.data.controls.p1 = {};
			playerData = FlxG.save.data.controls.p1;
		}
		else
		{
			if (FlxG.save.data.controls.p2 == null)
				FlxG.save.data.controls.p2 = {};
			playerData = FlxG.save.data.controls.p2;
		}
		
		var keyData = controls.createSaveData(Keys);
		if (keyData != null)
		{
			playerData.keys = keyData;
			trace("saving key data: " + haxe.Json.stringify(keyData));
		}
		
		if (controls.gamepadsAdded.length > 0)
		{
			var padData = controls.createSaveData(Gamepad(controls.gamepadsAdded[0]));
			if (padData != null)
			{
				trace("saving pad data: " + haxe.Json.stringify(padData));
				playerData.pad = padData;
			}
		}
		
		FlxG.save.flush();
	}
	
	static public function init():Void
	{
		if (player1 == null)
		{
			player1 = new PlayerSettings(0);
			++numPlayers;
		}
		
		FlxG.gamepads.deviceConnected.add(onGamepadAdded);

		var numGamepads = FlxG.gamepads.numActiveGamepads;
		for (i in 0...numGamepads)
		{
			var gamepad = FlxG.gamepads.getByID(i);
			if (gamepad != null)
				onGamepadAdded(gamepad);
		}

		// 	player1.controls.addDefaultGamepad(0);
		// }

		// if (numGamepads > 1)
		// {
		// 	if (player2 == null)
		// 	{
		// 		player2 = new PlayerSettings(1, None);
		// 		++numPlayers;
		// 	}

		// 	var gamepad = FlxG.gamepads.getByID(1);
		// 	if (gamepad == null)
		// 		throw 'Unexpected null gamepad. id:0';

		// 	player2.controls.addDefaultGamepad(1);
		// }

		// DeviceManager.init();
	}
	
	static function onGamepadAdded(gamepad:FlxGamepad)
	{
		player1.addGamepad(gamepad);
	}
	

	/*
	public function setKeyboardScheme(scheme)
	{
		controls.setKeyboardScheme(scheme);
	}

	static public function addAvatar(avatar:Player):PlayerSettings
	{
		var settings:PlayerSettings;

		if (player1 == null)
		{
			player1 = new PlayerSettings(0, Solo);
			++numPlayers;
		}

		if (player1.avatar == null)
			settings = player1;
		else
		{
			if (player2 == null)
			{
				if (player1.controls.keyboardScheme.match(Duo(true)))
					player2 = new PlayerSettings(1, Duo(false));
				else
					player2 = new PlayerSettings(1, None);
				++numPlayers;
			}

			if (player2.avatar == null)
				settings = player2;
			else
				throw throw 'Invalid number of players: ${numPlayers + 1}';
		}
		++numAvatars;
		settings.avatar = avatar;
		avatar.settings = settings;

		splitCameras();

		onAvatarAdd.dispatch(settings);

		return settings;
	}

	static public function removeAvatar(avatar:Player):Void
	{
		var settings:PlayerSettings;

		if (player1 != null && player1.avatar == avatar)
			settings = player1;
		else if (player2 != null && player2.avatar == avatar)
		{
			settings = player2;
			if (player1.controls.keyboardScheme.match(Duo(_)))
				player1.setKeyboardScheme(Solo);
		}
		else
			throw "Cannot remove avatar that is not for a player";

		settings.avatar = null;
		while (settings.controls.gamepadsAdded.length > 0)
		{
			final id = settings.controls.gamepadsAdded.shift();
			settings.controls.removeGamepad(id);
			DeviceManager.releaseGamepad(FlxG.gamepads.getByID(id));
		}

		--numAvatars;

		splitCameras();

		onAvatarRemove.dispatch(avatar.settings);
	}

	 */

	static public function reset()
	{
		player1 = null;
		player2 = null;
		numPlayers = 0;
	}
}
