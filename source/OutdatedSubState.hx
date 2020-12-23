package;

import flixel.FlxG;
import flixel.FlxSubState;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import lime.app.Application;

class OutdatedSubState extends MusicBeatSubstate
{
	public function new()
	{
		super();
		var ver = "v" + Application.current.meta.get('version');
		var txt:FlxText = new FlxText(0, 0, 0,
			"HEY! You're running an outdated version of the game!\nCurrent version is "
			+ ver
			+ " while the current version is "
			+ NGio.GAME_VER
			+ " ! Press Space to go to itch.io, or ESCAPE to ignore this!!",
			32);
		txt.setFormat("VCR OSD Mono", 32, FlxColor.WHITE, CENTER);
		txt.screenCenter();
		add(txt);
	}

	override function update(elapsed:Float)
	{
		if (controls.ACCEPT)
		{
			FlxG.openURL("https://ninja-muffin24.itch.io/funkin");
		}
		if (controls.BACK)
		{
			close();
		}
		super.update(elapsed);
	}
}
