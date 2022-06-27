package states.menu;
import openfl.utils.Dictionary;
import flixel.group.FlxGroup;
import flixel.addons.transition.FlxTransitionableState;
import engine.base.Controls.Control;
import engine.util.PlayerSettings;
import engine.util.CoolUtil;
import engine.io.Paths;
import engine.assets.Alphabet;
import engine.base.MusicBeatState;
import flash.text.TextField;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.input.keyboard.FlxKey;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import lime.utils.Assets;

using StringTools;
class OptionsMenu extends MusicBeatState
{
	// options are at the top of create() now	
	var optionGroups:Array<OptionGroup> = [];
	

	var curDisplayed:FlxTypedGroup<FlxText>;

	var curSelectedGroup:Int;
	var curSelectedOption:Int;

	var inGroup:Bool = false;
	var focusedOnRange:Bool = false;

	var descriptionText:FlxText;
	var headerText:FlxText;

	var categoryBG:FlxSprite;

	var selectorSprite:FlxSprite;

	var focusSprite1:FlxSprite;
	var focusSprite2:FlxSprite;

	var valueMap:Map<String, Dynamic>;

	override function create()
	{
		if (engine.functions.Option.recieveValue("GRAPHICS_globalAA") == 0)
			{
				FlxG.camera.antialiasing = true;
			}
			else
			{
				FlxG.camera.antialiasing = false;
			}

		optionGroups = [
			new OptionGroup("Graphics", [
				new CycleOption("Antialiasing %v", "Decides whether edges on sprites should be smooth. Affects performance.", ["On", "Off"], "GRAPHICS_globalAA"),
				new CycleOption("Focus Mode %v", "Only draws HUD elements when enabled.", ["Off", "On"], "GRAPHICS_liteMode"),
			]),
			new OptionGroup("Gameplay", [
				new CycleOption("%v Score Text", "How to show the Score Text", ["New", "Old", "Hidden"], "GAMEPLAY_scoreTxtMode"),
				//! broken! new CycleOption("Difficult Jacks %v", "With this option turned off, you only need to press once to trigger both notes.", ["On", "Off"], "GAMEPLAY_difficultJacks"),
				new CycleOption("Ghost Tapping %v", "When enabled, you will not get a miss for pressing a key without a note.", ["On", "Off"], "GAMEPLAY_ghostTapping"),
				new CycleOption("Botplay %v", "Whether the game plays itself or not", ["Off", "On"], "GAMEPLAY_botplay"),
				new CycleOption("Downscroll %v", "Downscroll.", ["Off", "On"], "GAMEPLAY_downscroll"),
				new FunctionOption("Set Keybinds", "Opens the keybind menu.", () -> {
					FlxG.switchState(new KeybindState());
				}),
			]),
			new OptionGroup("Fun", [
				new CycleOption("Instadeath %v", "For those who want an actual challenge", ["Off", "On"], "FUN_instadeath")
			]),
			new OptionGroup("Misc", [
				new FunctionOption("Mod Manager", "Opens the mod manager.", () -> {
					FlxG.switchState(new ModManagerState());
				}),
				new FunctionOption("Reset Option", "Resets all options to their default values.", clearOptions),
				new FunctionOption("Reset Everything", "Resets everything stored in the save file.", () -> {
					resetBinds();
					FlxG.save.erase();
				}),
				// new CycleOption("Enable experimental charter %v", "Enable new charter", ["Off", "On"], "MISC_newCharter")
			]),
		];

		transIn = FlxTransitionableState.defaultTransIn;
		transOut = FlxTransitionableState.defaultTransOut;

		var stateBG:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		stateBG.color = 0xFFea71fd;
		stateBG.setGraphicSize(Std.int(stateBG.width * 1.1));
		stateBG.updateHitbox();
		stateBG.screenCenter();
		stateBG.antialiasing = false;
		add(stateBG);

		var menuBG:FlxSprite = new FlxSprite().makeGraphic(Std.int(FlxG.width * 0.9), Std.int(FlxG.height * 0.9), 0xAA000000);
		menuBG.screenCenter();
		add(menuBG);

		categoryBG = new FlxSprite().makeGraphic(Std.int(FlxG.width * 0.1), Std.int(FlxG.height * 0.9), 0xAA555555);
		categoryBG.setPosition(menuBG.x, menuBG.y);
		add(categoryBG);

		var descriptionBG:FlxSprite = new FlxSprite().makeGraphic(Std.int(menuBG.width - categoryBG.width), Std.int(FlxG.height * 0.05), 0xAA555555);
		descriptionBG.setPosition(categoryBG.x + categoryBG.width, menuBG.y + menuBG.height - descriptionBG.height);
		add(descriptionBG);

		descriptionText = new FlxText(0, 0, descriptionBG.width, "Please select an option to view its description.");
		descriptionText.setFormat(Paths.font("PhantomMuff.ttf"), Std.int(descriptionBG.height * 0.8), 0xFFFFFFFF, CENTER);
		descriptionText.setPosition(descriptionBG.x, descriptionBG.y + descriptionBG.height / 2 - descriptionText.height / 2);
		add(descriptionText);

		headerText = new FlxText(0, 0, descriptionBG.width, "Header text.");
		headerText.setFormat(Paths.font("PhantomMuff.ttf"), Std.int(descriptionBG.height * 0.8), 0xFFFFFFFF, CENTER);
		headerText.setPosition(descriptionBG.x, menuBG.y);
		add(headerText);

		
		for (i in 0...optionGroups.length)
		{
			var btnBg:FlxSprite = new FlxSprite().makeGraphic(Std.int(FlxG.width * 0.1), Std.int(FlxG.height * 0.05), 0xCC111111);
			btnBg.x = menuBG.x;
			btnBg.y = menuBG.y + (i * Std.int(FlxG.height * 0.05)) + i * 2;
			add(btnBg);
			
			var btnTxt:FlxText = new FlxText(0, 0, btnBg.width, optionGroups[i].name);
			btnTxt.setFormat(Paths.font('PhantomMuff.ttf'), 12, 0xFFFFFFFF, CENTER);
			btnTxt.x = btnBg.x;
			btnTxt.y = btnBg.y + btnBg.height / 2 - btnTxt.height / 2;
			add(btnTxt);
		}

		if (FlxG.save.data.optionValueMap != null)
			valueMap = FlxG.save.data.optionValueMap;
		else
			valueMap = new Map<String, Dynamic>();

		curDisplayed = new FlxTypedGroup<FlxText>();
		updateMenu();
		add(curDisplayed);

		headerText.text = optionGroups[0].name;

		selectorSprite = new FlxSprite(0, 0);
		selectorSprite.makeGraphic(Std.int(FlxG.width * 0.1), Std.int(FlxG.height * 0.05), 0x55FFFFFF);
		selectorSprite.setPosition(menuBG.x, menuBG.y);
		add(selectorSprite);

		super.create();
		
	}

	override function update(elapsed:Float)
	{
		
		if (FlxG.save.data.UP == null)
			FlxG.save.data.UP = "W";
		if (FlxG.save.data.DOWN == null)
			FlxG.save.data.DOWN = "S";
		if (FlxG.save.data.LEFT == null)
			FlxG.save.data.LEFT = "A";
		if (FlxG.save.data.RIGHT == null)
			FlxG.save.data.RIGHT = "D";

		selectorSprite.y = categoryBG.y + (curSelectedGroup * Std.int(FlxG.height * 0.05)) + curSelectedGroup * 2;

		if (inGroup)
		{
			for (item in curDisplayed)
			{
				item.alpha = 1;
			}
		}
		else
		{
			for (item in curDisplayed)
			{
				item.alpha = 0.5;
			}
		}

		if (controls.BACK)
		{
			FlxG.switchState(new MainMenuState());
			FlxG.save.data.optionValueMap = valueMap;
		}
		if (controls.RIGHT_P)
		{
			if (!focusedOnRange)
			{
				inGroup = true;
				descriptionText.text = optionGroups[curSelectedGroup].options[curSelectedOption].description;
			}
			else
			{
				if (valueMap[(optionGroups[curSelectedGroup].options[curSelectedOption] : RangeOption).saveTo] + (optionGroups[curSelectedGroup].options[curSelectedOption] : RangeOption).stepSize <= (optionGroups[curSelectedGroup].options[curSelectedOption] : RangeOption).max)
				{
					valueMap.set((optionGroups[curSelectedGroup].options[curSelectedOption] : RangeOption).saveTo, valueMap[(optionGroups[curSelectedGroup].options[curSelectedOption] : RangeOption).saveTo] + (optionGroups[curSelectedGroup].options[curSelectedOption] : RangeOption).stepSize);
					updateMenu();
				}
				else
				{
					valueMap.set((optionGroups[curSelectedGroup].options[curSelectedOption] : RangeOption).saveTo, (optionGroups[curSelectedGroup].options[curSelectedOption] : RangeOption).max);
					updateMenu();
				}
			}
		}
		if (controls.LEFT_P)
		{
			if (!focusedOnRange)
			{
				inGroup = false;
				descriptionText.text = "Please select an option to view its description.";
			}
			else
			{
				if (valueMap[(optionGroups[curSelectedGroup].options[curSelectedOption] : RangeOption).saveTo] - (optionGroups[curSelectedGroup].options[curSelectedOption] : RangeOption).stepSize >= (optionGroups[curSelectedGroup].options[curSelectedOption] : RangeOption).min)
				{
					valueMap.set((optionGroups[curSelectedGroup].options[curSelectedOption] : RangeOption).saveTo, valueMap[(optionGroups[curSelectedGroup].options[curSelectedOption] : RangeOption).saveTo] - (optionGroups[curSelectedGroup].options[curSelectedOption] : RangeOption).stepSize);
					updateMenu();
				}
				else
				{
					valueMap.set((optionGroups[curSelectedGroup].options[curSelectedOption] : RangeOption).saveTo, (optionGroups[curSelectedGroup].options[curSelectedOption] : RangeOption).min);
					updateMenu();
				}
			}
		}
		if (controls.UP_P && !focusedOnRange)
		{
			if (!inGroup)
			{
				if (curSelectedGroup > 0)
				{
					curSelectedGroup--;
					updateMenu();
					curSelectedOption = 0;
				}
				else
				{
					curSelectedGroup = optionGroups.length - 1;
					updateMenu();
					curSelectedOption = 0;
				}
			}
			else
			{
				if (curSelectedOption > 0)
				{
					curSelectedOption--;
					updateMenu();
				}
				else
				{
					curSelectedOption = optionGroups[curSelectedGroup].options.length - 1;
					updateMenu();
				}
			}
		}

		if (controls.DOWN_P && !focusedOnRange)
		{
			if (!inGroup)
			{
				if (curSelectedGroup < optionGroups.length - 1)
				{
					curSelectedGroup++;
					updateMenu();
					curSelectedOption = 0;
				}
				else
				{
					curSelectedGroup = 0;
					updateMenu();
					curSelectedOption = 0;
				}
			}
			else
			{
				if (curSelectedOption < optionGroups[curSelectedGroup].options.length - 1)
				{
					curSelectedOption++;
					updateMenu();
				}
				else
				{
					curSelectedOption = 0;
					updateMenu();
				}
			}
		}

		if (controls.ACCEPT && inGroup)
		{
			if (Std.isOfType(optionGroups[curSelectedGroup].options[curSelectedOption], CycleOption))
			{
				// bro what even is this code
				(optionGroups[curSelectedGroup].options[curSelectedOption] : CycleOption).curValue = valueMap[(optionGroups[curSelectedGroup].options[curSelectedOption] : CycleOption).saveTo];
				if ((optionGroups[curSelectedGroup].options[curSelectedOption] : CycleOption).curValue > (optionGroups[curSelectedGroup].options[curSelectedOption] : CycleOption).possibleValues.length - 2)
					(optionGroups[curSelectedGroup].options[curSelectedOption] : CycleOption).curValue = 0;
				else
					(optionGroups[curSelectedGroup].options[curSelectedOption] : CycleOption).curValue++;

				valueMap.set(optionGroups[curSelectedGroup].options[curSelectedOption].saveTo, (optionGroups[curSelectedGroup].options[curSelectedOption] : CycleOption).curValue);

				updateMenu();
			}
			else if (Std.isOfType(optionGroups[curSelectedGroup].options[curSelectedOption], RangeOption))
			{
				if (!focusedOnRange)
				{
					descriptionText.text = "Focused on option. Press ENTER again to apply.";
				}
				else
				{
					descriptionText.text = optionGroups[curSelectedGroup].options[curSelectedOption].description;
				}
				focusedOnRange = !focusedOnRange;
			}
			else if (Std.isOfType(optionGroups[curSelectedGroup].options[curSelectedOption], FunctionOption))
			{
				(optionGroups[curSelectedGroup].options[curSelectedOption] : FunctionOption).func();
			}
		}

		super.update(elapsed);
		
	}

	function updateMenu()
	{
		// not copied from sublim engine, at all.	
		// updateFPS();

		headerText.text = optionGroups[curSelectedGroup].name;

		if (inGroup && !focusedOnRange)
			descriptionText.text = optionGroups[curSelectedGroup].options[curSelectedOption].description;
		else if (focusedOnRange)
			descriptionText.text = "Focused on option. Press ENTER again to apply.";
		else
			descriptionText.text = "Please select an option to view its description.";

		// idk how shit this math is, copilot made it. but it works :)
		if (selectorSprite != null)
			selectorSprite.y = categoryBG.y + (curSelectedGroup * Std.int(FlxG.height * 0.05)) + curSelectedGroup * 2;

		for (item in curDisplayed)
		{
			remove(item); // remove all the old ones
		}

		curDisplayed.clear();
		for (i in 0...optionGroups[curSelectedGroup].options.length)
		{
			var value:Any = "";
			var text:FlxText = new FlxText(0, 0, FlxG.width, optionGroups[curSelectedGroup].options[i].label);
			text.setFormat(Paths.font('PhantomMuff.ttf'), 16, 0xFFFFFFFF, LEFT);
			text.x = categoryBG.x + categoryBG.width + 10;
			text.y = categoryBG.y + (i * text.height) + i * 4 + headerText.height;
			value = getOptionValue(optionGroups[curSelectedGroup].options[i], optionGroups[curSelectedGroup].options[i].saveTo, Std.isOfType(optionGroups[curSelectedGroup].options[i], CycleOption));
			text.text = text.text.replace("%v", Std.string(value));
			add(text);
			trace("Option");
			curDisplayed.add(text);
		}
		if (curDisplayed.members[curSelectedOption] != null)
			curDisplayed.members[curSelectedOption].text += " <<";
		else
		{
			// if we fucked up, fix it and try again
			curSelectedOption = 0;
			updateMenu();
		}
		
	}

	function getOptionValue(option:Any, name:String, isCycle:Bool):Any
	{
		if (valueMap == null)
			return null;

		trace('getOptionValue: ${name}, ISCYCLE: ${isCycle}');

		if (isCycle)
		{
			try
			{
				if (valueMap[name] == null)
					valueMap[name] = 0;

				return (option : CycleOption).possibleValues[valueMap[name]];
			}
			catch (e)
			{
				trace('${(option : CycleOption) == null}');
				return 0;
			}
		}
		else
		{
			if (valueMap[name] == null && Std.isOfType(option, RangeOption))
				valueMap[name] = (option : RangeOption).min;

			return valueMap[name];
		}
	}

	function clearOptions()
	{
		valueMap.clear();
		updateMenu();
		for (group in optionGroups)
		{
			for (option in group.options)
			{
				if (Std.isOfType(option, CycleOption))
				{
					(option : CycleOption).curValue = 0;
					valueMap[option.saveTo] = 0;
				}
				else if (Std.isOfType(option, RangeOption))
				{
					(option : RangeOption).curValue = (option : RangeOption).min;
					valueMap[option.saveTo] = (option : RangeOption).min;
				}
			}
		}
		resetBinds();
	}

	function updateFPS() {
		if (FlxG.save.data.frameRate > FlxG.drawFramerate){
			FlxG.updateFramerate = valueMap["GRAPHICS_fpsCap"];
			FlxG.drawFramerate = valueMap["GRAPHICS_fpsCap"];
		}
		else{
			FlxG.drawFramerate = valueMap["GRAPHICS_fpsCap"];
			FlxG.updateFramerate = valueMap["GRAPHICS_fpsCap"];
		}
	}

	function resetBinds()
	{
		controls.unbindKeys(Control.LEFT, [FlxKey.fromString(FlxG.save.data.LEFT), FlxKey.LEFT]);
		controls.bindKeys(Control.LEFT, [FlxKey.fromString("A"), FlxKey.LEFT]);

		controls.unbindKeys(Control.RIGHT, [FlxKey.fromString(FlxG.save.data.RIGHT), FlxKey.RIGHT]);
		controls.bindKeys(Control.RIGHT, [FlxKey.fromString("D"), FlxKey.RIGHT]);

		controls.unbindKeys(Control.UP, [FlxKey.fromString(FlxG.save.data.UP), FlxKey.UP]);
		controls.bindKeys(Control.UP, [FlxKey.fromString("W"), FlxKey.UP]);

		controls.unbindKeys(Control.DOWN, [FlxKey.fromString(FlxG.save.data.DOWN), FlxKey.DOWN]);
		controls.bindKeys(Control.DOWN, [FlxKey.fromString("S"), FlxKey.DOWN]);
	}
}


/**
 * An option type that cycles through a list of options. Used for things like true/false, on/off, etc.
 * @param label The text displayed in the options menu. Use `%v` to display the value; `%v` will be replaced with the current value.
 * @param description The description of the option.
 * @param defaultIndex The index of the default value in the array.
 * @param possibleValues An array of values to cycle through.
 * @param saveTo the name of the variable in the save file to save to.
 */
class CycleOption
{
	public var label:String;
	public var defaultIndex:Int;
	public var possibleValues:Array<Dynamic>;
	public var description:String;
	public var curValue:Int;
	public var saveTo:String;

	public function new(label:String, description:String, possibleValues:Array<Dynamic>, saveTo:String)
	{
		this.label = label;
		this.possibleValues = possibleValues;
		this.description = description;
		this.curValue = defaultIndex;
		this.saveTo = saveTo;
	}
}

/**
 * An option type that allows the user to pick a value between a min and max.
 * @param label The text displayed in the options menu. Use `%v` to display the value; `%v` will be replaced with the current value.
 * @param description The description of the option.
 * @param defaultValue The default value.
 * @param min The minimum value.
 * @param max The maximum value.
 * @param stepSize the size between steps
 * @param saveTo the name of the variable in the save file to save to.
 */
class RangeOption
{
	public var label:String;
	public var defaultValue:Float;
	public var min:Float;
	public var max:Float;
	public var description:String;
	public var curValue:Float;
	public var stepSize:Float;
	public var saveTo:String;

	public function new(label:String, description:String, min:Float, max:Float, stepSize:Float, saveTo:String)
	{
		this.label = label;
		this.min = min;
		this.max = max;
		this.description = description;
		this.curValue = defaultValue;
		this.stepSize = stepSize;
		this.saveTo = saveTo;
	}
}

/**
 * An option type that calls a function when interacted with.
 * @param label The text displayed in the options menu.
 * @param description The description of the option.
 * @param func The function to call.
 */
class FunctionOption {
	public var label:String;
	public var description:String;
	public var func:Void -> Void;

	public function new(label:String, description:String, func:Void -> Void)
	{
		this.label = label;
		this.description = description;
		this.func = func;
	}
}

/**
 * OptionGroup is a container for a set of options. Otherwise known as a "page" in the options menu.
 * @param name The text displayed in the options menu.
 * @param options An array of options to display.
 */
class OptionGroup
{
	public var name:String;
	public var options:Array<Dynamic>;

	public function new(name:String, options:Array<Dynamic>)
	{
		this.name = name;
		this.options = options;
	}
}
