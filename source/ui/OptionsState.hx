package ui;

import flixel.FlxG;
import flixel.FlxSprite;
import haxe.ds.EnumValueMap;

using StringTools;

class OptionsState extends MusicBeatState
{
	var currentName:PageName = Options;
	var pages:EnumValueMap<PageName, Page> = new EnumValueMap();

	function get_currentPage()
	{
		return pages.get(currentName);
	}

	override function create()
	{
		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.color = 0xFFEA71FD;
		bg.setGraphicSize(Std.int(bg.width * 1.1));
		bg.updateHitbox();
		bg.screenCenter();
		bg.scrollFactor.set();
		add(bg);
		var optionsmenu = addPage(Options, new OptionsMenu(false));
		var preferencesmenu = addPage(Preferences, new PreferencesMenu());
		var controlsmenu = addPage(Controls, new ControlsMenu());
		if (optionsmenu.hasMultipleOptions())
		{
			optionsmenu.onExit.add(exitToMainMenu);
			controlsmenu.onExit.add(function()
			{
				switchPage(Options);
			});
			preferencesmenu.onExit.add(function()
			{
				switchPage(Options);
			});
		}
		else
		{
			controlsmenu.onExit.add(exitToMainMenu);
			setPage(Controls);
		}
		pages.get(currentName).set_enabled(false);
		super.create();
	}

	function addPage(name:PageName, menu:Dynamic)
	{
		menu.onSwitch.add(switchPage);
		pages.set(name, menu);
		add(menu);
		menu.exists = currentName == name;
		return menu;
	}

	function setPage(name:PageName)
	{
		if (pages.exists(currentName))
			pages.get(currentName).exists = false;
		currentName = name;
		if (pages.exists(currentName))
			pages.get(currentName).exists = true;
	}

	override function finishTransIn()
	{
		super.finishTransIn();
		pages.get(currentName).set_enabled(true);
	}

	function switchPage(name:PageName)
	{
		setPage(name);
	}

	function exitToMainMenu()
	{
		pages.get(currentName).set_enabled(false);
		FlxG.switchState(new MainMenuState());
	}
}