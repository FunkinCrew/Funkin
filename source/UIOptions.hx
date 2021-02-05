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
using StringTools;
class UIOptions extends MusicBeatState
{


	public var alwaysDoCutscenes:Bool = false;
	public var fullComboMode:Bool = false;
	public var perfectMode:Bool = false;
	var alwaysCutsceneCheckBox:FlxUICheckBox;
	var perfectModeCheckBox:FlxUICheckBox;
	var fullComboCheckBox:FlxUICheckBox;
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
		alwaysDoCutscenes = false;
		var file = CoolUtil.coolTextFile('assets/data/options.txt');
		if (StringTools.contains(file[0],'true'))
			alwaysDoCutscenes = true;
		if (StringTools.contains(file[1], 'true')) {
			perfectMode = true;
		}
		if (StringTools.contains(file[2], 'true')) {
			fullComboMode = true;
		}
		alwaysCutsceneCheckBox = new FlxUICheckBox(100, 100, null, null,"Always Show Cutscenes", 100);
		alwaysCutsceneCheckBox.checked = alwaysDoCutscenes;
		perfectModeCheckBox = new FlxUICheckBox(100,160, null, null,"Perfect Mode", 100);
		perfectModeCheckBox.checked = perfectMode;
		fullComboCheckBox = new FlxUICheckBox(100,220, null, null,"Full Combo Mode", 100);
		fullComboCheckBox.checked = fullComboMode;
		optionUI.add(alwaysCutsceneCheckBox);
		optionUI.add(perfectModeCheckBox);
		optionUI.add(fullComboCheckBox);
		add(optionUI);
		super.create();
	}
	override function update(elapsed:Float) {
		super.update(elapsed);
		if (controls.BACK) {
			FlxG.mouse.visible = false;
			File.saveContent('assets/data/options.txt', 'alwaysDoCutscenes: '+alwaysCutsceneCheckBox.checked + '\nperfectMode: '+perfectModeCheckBox.checked+'\nfullComboMode: '+fullComboCheckBox.checked);
			FlxG.switchState(new MainMenuState());
		}

	}
}
