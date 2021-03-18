package;

import Controls.Control;
import flixel.FlxG;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import polymod.Polymod;
#if desktop
import sys.FileSystem;
#end

class ModdingSubstate extends MusicBeatSubstate
{
	var grpMods:FlxTypedGroup<ModMenuItem>;
	var enabledMods:Array<String> = [];
	var modFolders:Array<String> = [];

	var curSelected:Int = 0;

	public function new():Void
	{
		super();

		grpMods = new FlxTypedGroup<ModMenuItem>();
		add(grpMods);

		refreshModList();
	}

	override function update(elapsed:Float)
	{
		if (FlxG.keys.justPressed.R)
			refreshModList();

		selections();

		if (controls.UP_P)
			selections(-1);
		if (controls.DOWN_P)
			selections(1);

		if (FlxG.keys.justPressed.SPACE)
			grpMods.members[curSelected].modEnabled = !grpMods.members[curSelected].modEnabled;

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

		if (curSelected >= modFolders.length)
			curSelected = 0;
		if (curSelected < 0)
			curSelected = modFolders.length - 1;

		for (txt in 0...grpMods.length)
		{
			if (txt == curSelected)
			{
				grpMods.members[txt].color = FlxColor.YELLOW;
			}
			else
				grpMods.members[txt].color = FlxColor.WHITE;
		}

		organizeByY();
	}

	private function refreshModList():Void
	{
		while (grpMods.members.length > 0)
		{
			grpMods.remove(grpMods.members[0], true);
		}

		#if desktop
		var modList = [];
		modFolders = [];

		#if desktop
		for (file in FileSystem.readDirectory('./mods'))
		{
			if (FileSystem.isDirectory('./mods/' + file))
				modFolders.push(file);
		}

		enabledMods = [];

		modList = Polymod.scan('./mods');

		trace(modList);

		var loopNum:Int = 0;
		for (i in modFolders)
		{
			var txt:ModMenuItem = new ModMenuItem(0, 10 + (40 * loopNum), 0, i, 32);
			txt.text = i;
			grpMods.add(txt);

			loopNum++;
		}
		#end
		} private function organizeByY():Void

		{
			for (i in 0...grpMods.length)
			{
				grpMods.members[i].y = 10 + (40 * i);
			}
		}
		} class ModMenuItem extends FlxText

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
