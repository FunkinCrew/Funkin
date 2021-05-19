package;

import Controls.Control;
import flash.text.TextField;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.input.keyboard.FlxKey;
import flixel.addons.ui.FlxInputText;
import flixel.addons.ui.FlxUI9SliceSprite;
import flixel.addons.ui.FlxUI;
import flixel.addons.ui.FlxUICheckBox;
import flixel.addons.ui.FlxUIDropDownMenu;
import flixel.addons.ui.FlxUIInputText;
import flixel.addons.ui.FlxUINumericStepper;
import flixel.addons.ui.FlxUITabMenu;
import flixel.addons.ui.FlxUITooltip.FlxUITooltipStyle;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import lime.utils.Assets;
import sys.io.File;
import haxe.Json;
using StringTools;
class UIOptions extends MusicBeatState
{


	var alwaysCutsceneCheckBox:FlxUICheckBox;
	var perfectModeCheckBox:FlxUICheckBox;
	var fullComboCheckBox:FlxUICheckBox;
	var practiceCheckBox:FlxUICheckBox;
	var useModifierMenuCheck:FlxUICheckBox;
	var _options:Dynamic;
	override function create()
	{
		var menuBG:FlxSprite = new FlxSprite().loadGraphic('assets/images/menuDesat.png');
		var optionUI = new FlxUI();
		menuBG.color = 0xFFea71fd;
		menuBG.setGraphicSize(Std.int(menuBG.width * 1.1));
		menuBG.updateHitbox();
		menuBG.screenCenter();
		menuBG.antialiasing = true;
		FlxG.mouse.visible = true;
		add(menuBG);
		// cursed never gonna be used so weee
		_options = FlxG.save.data.options;
		alwaysCutsceneCheckBox = new FlxUICheckBox(100, 100, null, null,"Always Show Cutscenes", 100);
		alwaysCutsceneCheckBox.checked = _options.alwaysDoCutscenes;
		perfectModeCheckBox = new FlxUICheckBox(100,160, null, null,"Perfect Mode", 100);
		perfectModeCheckBox.checked = _options.perfectMode;
		fullComboCheckBox = new FlxUICheckBox(100,220, null, null,"Full Combo Mode", 100);
		fullComboCheckBox.checked = _options.fullComboMode;
		practiceCheckBox = new FlxUICheckBox(100,280, null, null,"Practice Mode", 100);
		practiceCheckBox.checked = _options.practiceMode;
		useModifierMenuCheck = new FlxUICheckBox(100,340, null, null,"Use Modifier Menu", 100);
		useModifierMenuCheck.checked = _options.useModifierMenu;
		optionUI.add(alwaysCutsceneCheckBox);
		optionUI.add(perfectModeCheckBox);
		optionUI.add(fullComboCheckBox);
		optionUI.add(practiceCheckBox);
		optionUI.add(useModifierMenuCheck);
		add(optionUI);
		super.create();
	}
	override function update(elapsed:Float) {
		super.update(elapsed);
		if (controls.BACK) {
			FlxG.mouse.visible = false;
			File.saveContent('assets/data/options.json', Json.stringify(_options));
			LoadingState.loadAndSwitchState(new MainMenuState());
		}

	}
	override function getEvent(id:String, sender:Dynamic, data:Dynamic, ?params:Array<Dynamic>) {
		if (id == FlxUICheckBox.CLICK_EVENT)
		{
			var check:FlxUICheckBox = cast sender;
			var label = check.getLabel().text;
			switch (label)
			{
				case 'Always Show Cutscenes':
					_options.alwaysDoCutscenes = check.checked;
				case 'Perfect Mode':
					_options.perfectMode = check.checked;
				case "Full Combo Mode":
					_options.fullComboMode = check.checked;
				case "Practice Mode":
					_options.practiceMode = check.checked;
				case "Use Modifier Menu":
					_options.useModifierMenu = check.checked;

			}
		}
	}
}
