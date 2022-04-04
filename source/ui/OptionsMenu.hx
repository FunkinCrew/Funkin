package ui;

import flixel.FlxG;

class OptionsMenu extends Page
{
	var items:TextMenuList;

	override public function new(showDonate:Bool)
	{
		super();
		add(items = new TextMenuList());
		createItem('preferences', function()
		{
			onSwitch.dispatch(PageName.Preferences);
		});
		createItem('controls', function()
		{
			onSwitch.dispatch(PageName.Controls);
		});
		if (showDonate)
		{
			createItem('donate', selectDonate, true);
		}
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

	public function createItem(label:String, callback:Dynamic, ?fireInstantly:Bool = false)
	{
		var item:TextMenuItem = items.createItem(0, 100 + 100 * items.length, label, Bold, callback);
		item.fireInstantly = fireInstantly;
		item.screenCenter(X);
		return item;
	}

	override function set_enabled(state:Bool)
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

	// function selectLogin()
	// {
	// 	openNgPrompt(NgPrompt.showLogin());
	// }

	// function selectLogout()
	// {
	// 	openNgPrompt(NgPrompt.showLogout());
	// }

	// function openNgPrompt(prompt:Prompt, ?callback:Dynamic)
	// {
	// 	var func:Dynamic = checkLoginStatus();
	// 	if (callback != null)
	// 	{
	// 		func = function()
	// 		{
	// 			checkLoginStatus();
	// 			callback();
	// 		};
	// 	}
	// 	openPrompt(prompt, func);
	// }

	// function checkLoginStatus()
	// {
	// 	var hasLogout:Bool = items.has('logout');
	// 	if (hasLogout)
	// 	{
	// 		if (NG.core != null)
	// 		{
	// 			if (NG.core.loggedIn)
	// 			{
	// 				if (!hasLogout && NG.core != null && NG.core.loggedIn)
	// 					items.resetItem('logout', 'login', selectLogin);
	// 			}
	// 			else
	// 			{
	// 				items.resetItem('login', 'logout', selectLogout);
	// 			}
	// 		}
	// 	}
	// }
}