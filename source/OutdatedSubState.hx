package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import lime.app.Application;

class OutdatedSubState extends MusicBeatState
{
	public static var leftState:Bool = false;

	public static var needVer:String;
	public static var currChanges:String;

	override function create()
	{
		super.create();
		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		add(bg);
		var ver = "v" + MainMenuState.version;
		var txt:FlxText = new FlxText(0, 0, FlxG.width,
			'HEY! Your version of UFNF is outdated!\nThe most recent version is v${needVer} while you have ${ver}!\nIf you\'re seeing this on a mod and aren\'t the developer, you can ignore this!\n\nChanges:\n${currChanges}\n\nPress ENTER to go to github or ESCAPE to ignore',
			32);
		txt.setFormat("VCR OSD Mono", 32, FlxColor.WHITE, CENTER);
		txt.screenCenter();
		add(txt);
	}

	override function update(elapsed:Float)
	{
		if (controls.ACCEPT)
		{
			FlxG.openURL("https://github.com/thepercentageguy/Unnamed-FNF-Engine");
		}
		if (controls.BACK)
		{
			leftState = true;
			FlxG.switchState(new MainMenuState());
		}
		super.update(elapsed);
	}
}
