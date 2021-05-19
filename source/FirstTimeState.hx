package;

import flixel.graphics.frames.FlxAtlasFrames;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import lime.app.Application;

class FirstTimeState extends MusicBeatState
{
	public static var leftState:Bool = false;

	var sinMod:Float = 0;
	var txt:FlxText = new FlxText(0, 360, FlxG.width,
		"WARNING:\nP-Side may potentially trigger seizures for people with photosensitive epilepsy.Viewer discretion is advised.\n\n"
		+ "This mod took a long time already, so don't be surprised if it takes a while."
		+ " \nI'm remixing the songs (help would be appreciated tho) so don't mind if it doesnt sound like the best lol."
		+ "\nThis mod was built using the FNF Modding+ source code, but with multiple engine modifications by me."
		+ "Now that all that is cleared up, i hope yu enjoy!\nPress ENTER to continue!",
		32);

	override function create()
	{
		super.create();
		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		add(bg);
		
		txt.setFormat("VCR OSD Mono", 32, FlxColor.WHITE, CENTER);
		add(txt);

		if (FlxG.save.data.FirstTime != null)
			TitleState.firstTime = FlxG.save.data.FirstTime;
	}

	override function update(elapsed:Float)
	{
		sinMod += 0.007;
		txt.y = Math.sin(sinMod)*60+100;

		if (controls.ACCEPT)
		{
			LoadingState.loadAndSwitchState(new MainMenuState());
		}
		super.update(elapsed);
	}
}
