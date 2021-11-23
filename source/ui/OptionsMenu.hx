package ui;

import flixel.FlxG;

using StringTools;

class OptionsMenu extends Page
{
	var items:TextMenuList;

	override public function new(a:Bool)
	{
		super();
		items = new TextMenuList();
		add(items);
		createItem('preferences', function()
		{
			onSwitch.dispatch(PageName.Preferences);
		});
		createItem('controls', function()
		{
			onSwitch.dispatch(PageName.Controls);
		});
		if (a) createItem('donate', selectDonate, true);
		// if (NG.core != null && NG.core.loggedIn)
		// {
		// 	createItem('logout', selectLogout);
		// }
		// else
		// {
		// 	createItem('login', selectLogin);
		// }
		createItem('exit', exit);
	}

	public function createItem(label:String, callback:Dynamic, fireInstantly:Bool = false)
	{
		var item = items.createItem(0, 100 + 100 * items.length, label, Bold, callback);
		item.fireInstantly = fireInstantly;
		item.screenCenter(X);
		return item;
	}

	override public function set_enabled(state:Bool)
	{
		items.enabled = state;
		return super.set_enabled(state);
	}

	public function hasMultipleOptions()
	{
		return items.length > 2;
	}

	function selectDonate()
	{
		#if linux
		Sys.command('/usr/bin/xdg-open', ["https://ninja-muffin24.itch.io/funkin", "&"]);
		#else
		FlxG.openURL('https://ninja-muffin24.itch.io/funkin');
		#end
	}
}