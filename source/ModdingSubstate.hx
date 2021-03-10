package;

import flixel.text.FlxText;
#if desktop
import sys.FileSystem;
#end

class ModdingSubstate extends MusicBeatSubstate
{
	public function new():Void
	{
		super();

		// var pathShit

		#if desktop
		var modList = [];

		for (file in FileSystem.readDirectory('./mods'))
		{
			if (FileSystem.isDirectory("./mods/" + file))
				modList.push(file);
		}

		trace(modList);

		var loopNum:Int = 0;
		for (i in modList)
		{
			var txt:FlxText = new FlxText(0, 10 + (40 * loopNum), 0, i, 32);
			add(txt);

			loopNum++;
		}
		#end
	}
}
