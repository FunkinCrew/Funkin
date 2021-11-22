package ui;

using StringTools;

class PreferencesMenu extends Page
{
	public static var preferences:Array<String> = ['flashing-menu'];

	public static function initPrefs()
	{

	}

	public static function getPref(pref:String)
	{
		return preferences.contains(pref);
	}
}