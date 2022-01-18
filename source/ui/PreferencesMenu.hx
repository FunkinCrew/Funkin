package ui;

import openfl.Lib;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxCamera;
import flixel.util.FlxColor;
import haxe.ds.StringMap;

using StringTools;

class PreferencesMenu extends Page
{
	public static var preferences:StringMap<Dynamic> = new StringMap<Dynamic>();

	var checkboxes = [];
	var menuCamera:FlxCamera;
	var items:TextMenuList;
	var camFollow:FlxObject;

	override public function new()
	{
		super();
		menuCamera = new FlxCamera();
		FlxG.cameras.add(menuCamera, false);
		menuCamera.bgColor = FlxColor.TRANSPARENT;
		set_camera(menuCamera);
		items = new TextMenuList();
		add(items);
		createPrefItem('naughtyness', 'censor-naughty', true);
		createPrefItem('downscroll', 'downscroll', false);
		createPrefItem('flashing menu', 'flashing-menu', true);
		createPrefItem('Camera Zooming on Beat', 'camera-zoom', true);
		createPrefItem('FPS Counter', 'fps-counter', true);
		createPrefItem('Auto Pause', 'auto-pause', false);
		camFollow = new FlxObject(FlxG.width / 2, 0, 140, 70);
		if (items != null)
		{
			camFollow.y = items.members[items.selectedIndex].y;
		}
		menuCamera.follow(camFollow, null, 0.06);
		menuCamera.deadzone.x = 0;
		menuCamera.deadzone.y = 160;
		menuCamera.deadzone.width = menuCamera.width;
		menuCamera.deadzone.height = 40;
		menuCamera.minScrollY = 0;
		items.onChange.add(function(b)
		{
			camFollow.y = b.y;
		});
	}

	public function createPrefItem(label:String, identifier:String, value:Bool)
	{
		items.createItem(120, 120 * items.length + 30, label, Bold, function()
		{
			preferenceCheck(identifier, value);
			var valueType = Type.typeof(value);
			if (valueType.getName() == 'TBool')
			{
				prefToggle(identifier);
			}
			else
			{
				trace('swag');
			}
		});
		var valueType = Type.typeof(value);
		if (valueType.getName() == 'TBool')
		{
			createCheckbox(identifier);
		}
		else
		{
			trace('swag');
		}
		valueType = Type.typeof(value); // the variable being repeated looks weird, but I swear this is in the game's code
		trace(valueType.getName());
	}

	public function createCheckbox(identifier:String)
	{
		var box = new CheckboxThingie(0, 120 * (items.length - 1), preferences.get(identifier));
		checkboxes.push(box);
		add(box);
	}

	public function prefToggle(identifier:String)
	{
		var value = preferences.get(identifier);
		value = !value;
		preferences.set(identifier, value);
		checkboxes[items.selectedIndex].set_daValue(value);
		trace('toggled? ' + Std.string(preferences.get(identifier)));
		switch (identifier)
		{
			case 'auto-pause':
				FlxG.autoPause = getPref('auto-pause');
			case 'fps-counter':
				if (getPref('fps-counter'))
					Lib.current.stage.addChild(Main.fpsCounter);
				else
					Lib.current.stage.removeChild(Main.fpsCounter);
		}
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		menuCamera.followLerp = CoolUtil.camLerpShit(0.05);
		items.forEach(function(item:MenuItem)
		{
			if (items.members[items.selectedIndex] == item)
				item.x = 150;
			else
				item.x = 120;
		});
	}

	public static function getPref(pref:String)
	{
		return preferences.get(pref);
	}

	public static function initPrefs()
	{
		preferenceCheck('censor-naughty', true);
		preferenceCheck('downscroll', false);
		preferenceCheck('flashing-menu', true);
		preferenceCheck('camera-zoom', true);
		preferenceCheck('fps-counter', true);
		preferenceCheck('auto-pause', false);
		preferenceCheck('master-volume', 1);
		if (!getPref('fps-counter'))
		{
			Lib.current.stage.removeChild(Main.fpsCounter);
		}
		FlxG.autoPause = getPref('auto-pause');
	}

	public static function preferenceCheck(identifier:String, value:Dynamic)
	{
		if (preferences.get(identifier) == null)
		{
			preferences.set(identifier, value);
			trace('set preference!');
		}
		else
		{
			trace('found preference: ' + Std.string(preferences.get(identifier)));
		}
	}
}