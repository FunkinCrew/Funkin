package ui;

import flixel.FlxG;
import ui.AtlasText.AtlasFont;

class PreferencesMenu extends ui.OptionsState.Page
{
	public static var preferences:Map<String, Dynamic> = new Map();

	var items:TextMenuList;

	public function new()
	{
		super();
		add(items = new TextMenuList());

		createPrefItem('naughtyness', 'censor-naughty', false);
		createPrefItem('downscroll', 'downscroll', false);
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

		trace(Type.typeof(prefValue).getName());
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

	private function preferenceCheck(prefString:String, prefValue:Dynamic):Void
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
