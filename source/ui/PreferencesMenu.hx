package ui;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.util.FlxColor;
import ui.AtlasText.AtlasFont;
import ui.TextMenuList.TextMenuItem;

class PreferencesMenu extends ui.OptionsState.Page
{
	public static var preferences:Map<String, Dynamic> = new Map();

	var items:TextMenuList;

	var checkboxes:Array<Dynamic> = [];

	public function new()
	{
		super();
		add(items = new TextMenuList());

		createPrefItem('naughtyness', 'censor-naughty', false);
		createPrefItem('downscroll', 'downscroll', false);
		createPrefItem('flashing menu', 'flashing-menu', true);
	}

	public static function initPrefs():Void
	{
		preferenceCheck('censor-naughty', false);
		preferenceCheck('downscroll', false);
		preferenceCheck('flashing-menu', true);
	}

	private function createPrefItem(prefName:String, prefString:String, prefValue:Dynamic):Void
	{
		items.createItem(100, 100 * items.length, prefName, AtlasFont.Bold, function()
		{
			preferenceCheck(prefString, prefValue);

			switch (Type.typeof(prefValue).getName())
			{
				case 'TBool':
					prefToggle(prefString);

				default:
					trace('swag');
			}
		});

		switch (Type.typeof(prefValue).getName())
		{
			case 'TBool':
				createCheckbox(prefString);

			default:
				trace('swag');
		}

		trace(Type.typeof(prefValue).getName());
	}

	function createCheckbox(prefString:String)
	{
		var checkbox:CheckboxThingie = new CheckboxThingie(0, 100 * items.length, preferences.get(prefString));
		add(checkbox);
	}

	/**
	 * Assumes that the preference has already been checked/set?
	 */
	private function prefToggle(prefName:String)
	{
		var daSwap:Bool = preferences.get(prefName);
		daSwap = !daSwap;
		preferences.set(prefName, daSwap);
		trace('toggled? ' + preferences.get(prefName));
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
	}

	private static function preferenceCheck(prefString:String, prefValue:Dynamic):Void
	{
		if (preferences.get(prefString) == null)
		{
			preferences.set(prefString, prefValue);
			trace('set preference!');
		}
		else
		{
			trace('found preference: ' + preferences.get(prefString));
		}
	}
}

class CheckboxThingie extends FlxSprite
{
	public var daValue(default, set):Bool = false;

	public function new(x:Float, y:Float, daValue:Bool = false)
	{
		super(x, y);

		this.daValue = daValue;
		makeGraphic(50, 50, FlxColor.WHITE);
	}

	function set_daValue(value:Bool):Bool
	{
		if (value)
			color = FlxColor.GREEN;
		else
			color = FlxColor.RED;

		return value;
	}
}
