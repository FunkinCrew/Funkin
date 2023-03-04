package ui;

import flixel.FlxG;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.FlxSprite;
import Controls;
#if desktop
import sys.FileSystem;
import sys.io.File;
import haxe.Json;
import haxe.format.JsonParser;
#end

#if polymod
import polymod.Polymod;
import polymod.Polymod.ModMetadata;
#end

using StringTools;

class ModMenu extends ui.OptionsState.Page
{
	var modList:Array<ModMetadata> = [];
	public static var grpMods:FlxTypedGroup<ModMenuItem>;
	public static var enabledMods:Array<String> = [];

	var curSelected:Int = 0;

	var descriptionText:FlxText;
	var descBg:FlxSprite;
	public static var MOD_PATH = "mods";

	public function new():Void
	{
		super();

		grpMods = new FlxTypedGroup<ModMenuItem>();
		add(grpMods);

		refreshModList();

		descBg = new FlxSprite(0, FlxG.height - 90).makeGraphic(FlxG.width, 90, 0xFF000000);
		descBg.alpha = 0.6;
		add(descBg);

		descriptionText = new FlxText(descBg.x, descBg.y + 4, FlxG.width, "Description", 18);
		descriptionText.setFormat(Paths.font("vcr.ttf"), 18, FlxColor.WHITE, CENTER);
		descriptionText.borderColor = FlxColor.BLACK;
		descriptionText.borderSize = 1;
		descriptionText.borderStyle = OUTLINE;
		descriptionText.scrollFactor.set();
		descriptionText.screenCenter(X);
		add(descriptionText);
	}

	override function update(elapsed:Float)
	{
		if (FlxG.keys.justPressed.R)
			refreshModList();

		selections();

		if (controls.UI_UP_P)
			selections(-1);
		if (controls.UI_DOWN_P)
			selections(1);

		if (FlxG.keys.justPressed.SPACE){
			grpMods.members[curSelected].modEnabled = !grpMods.members[curSelected].modEnabled;
		}

		if (FlxG.keys.justPressed.I && curSelected != 0)
		{
			var oldOne = grpMods.members[curSelected - 1];
			grpMods.members[curSelected - 1] = grpMods.members[curSelected];
			grpMods.members[curSelected] = oldOne;
			selections(-1);
		}

		if (FlxG.keys.justPressed.K && curSelected < grpMods.members.length - 1)
		{
			var oldOne = grpMods.members[curSelected + 1];
			grpMods.members[curSelected + 1] = grpMods.members[curSelected];
			grpMods.members[curSelected] = oldOne;
			selections(1);
		}

		super.update(elapsed);
	}

	private function selections(change:Int = 0):Void
	{
		curSelected += change;

		if (curSelected >= modList.length)
			curSelected = 0;
		if (curSelected < 0)
			curSelected = modList.length - 1;

		for (txt in 0...grpMods.length)
		{
			if (txt == curSelected)
			{
				grpMods.members[txt].color = FlxColor.YELLOW;
			}
			else
				grpMods.members[txt].color = FlxColor.WHITE;
		}

		descriptionText.screenCenter(X);

		descriptionText.text = 
		modList[curSelected].description
		+ "\nContributors:";

		var _count:Int = 0;
		for (i in modList[curSelected].contributors){
			if (_count != 0){
				descriptionText.text =
				descriptionText.text
				+ ",";
			}
			descriptionText.text =
			descriptionText.text
			+ i.name+"("+i.role+")";
		}

		descriptionText.text =
		descriptionText.text
		+ "\nnekoEngine Version: " + modList[curSelected].apiVersion 
		+ "\nMod Version: " + modList[curSelected].modVersion 
		+ "\n";

		organizeByY();
	}

	private function refreshModList():Void
	{
		while (grpMods.members.length > 0)
		{
			grpMods.remove(grpMods.members[0], true);
		}

		#if polymod
		modList = [];
		
		trace("mods path:" + FileSystem.absolutePath(MOD_PATH));
		if (!FileSystem.exists(MOD_PATH))
		{
			FlxG.log.warn("missing mods folder, expected: " + FileSystem.absolutePath(MOD_PATH));
			return;
		}

		enabledMods = CoolUtil.hotTextFile(MOD_PATH+"/modList.txt");

		modList = Polymod.scan({modRoot: MOD_PATH});

		var loopNum:Int = 0;
		for (i in modList)
		{
			trace(i.id);
			var txt:ModMenuItem = new ModMenuItem(0, 10 + (40 * loopNum), 0, i.id, 32);
			txt.text = i.id;
			if (enabledMods.contains(i.id))
				txt.modEnabled = true;
			grpMods.add(txt);

			loopNum++;
		}
		#end
	}

	private function organizeByY():Void
	{
		for (i in 0...grpMods.length)
		{
			grpMods.members[i].y = 10 + (40 * i);
		}
	}
}

class ModMenuItem extends FlxText
{
	public var modEnabled:Bool = false;
	public var daMod:String;

	public function new(x:Float, y:Float, w:Float, str:String, size:Int)
	{
		super(x, y, w, str, size);
	}

	override function update(elapsed:Float)
	{
		if (modEnabled)
			alpha = 1;
		else
			alpha = 0.5;

		super.update(elapsed);
	}
}
