package;

import openfl.display.Bitmap;
import openfl.geom.Rectangle;
import openfl.display.BitmapData;
import utils.Version;
import flixel.ui.FlxButton;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import lime.app.Application;

class OutdatedSubState extends MusicBeatState
{
	public static var leftState:Bool = false;

	var newver:Float;
	public function new(ver:Float) {
		newver = ver;
		super();
	}

	override function create()
	{
		super.create();
		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.fromRGB(253, 253, 150));
		add(bg);

		var button = new FlxButton(32, 32, "", ()-> {
			FlxG.switchState(new MainMenuState());
		}).loadGraphic('assets/android/back.png');
		add(button);

		var vertext = new FlxText();
		vertext.text = 'current build: ${Version.get().build}\nnew build: ${newver}\n';
		vertext.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, CENTER);
		vertext.setBorderStyle(SHADOW, FlxColor.BLACK, 3);
		vertext.x = 5;
		vertext.y = FlxG.height - vertext.height - 10;
		add(vertext);

		var logoBl = new FlxSprite();
		logoBl.frames = Paths.getSparrowAtlas('logoBumpin');
		logoBl.antialiasing = true;
		logoBl.animation.addByPrefix('bump', 'logo bumpin', 24);
		logoBl.animation.play('bump');
		//logoBl.scale.set(0.7, 0.7);//yrses
		logoBl.updateHitbox();
		logoBl.screenCenter(X);
		logoBl.y = -75;
		add(logoBl);

		var text = new FlxText();
		text.text = "HEY! You're running an outdated version of the game!";
		text.setFormat("VCR OSD Mono", 32, FlxColor.WHITE, CENTER);
		text.setBorderStyle(SHADOW, FlxColor.BLACK, 3);
		text.screenCenter(X);
		text.y = FlxG.height - text.height - 175;
		add(text);

		var t = FlxG.bitmap.add(buttonbm());
		// FlxG.addChildBelowMouse(new Bitmap(t));
		var dontaskButton = new FlxButton(0, 0, "Dont ask again", () -> {
			FlxG.save.data.dontaskupdate = true;
			FlxG.save.flush();
			FlxG.switchState(new MainMenuState());
		});
		dontaskButton.loadGraphic(t, true, 180, 50);
		dontaskButton.label.setFormat("VCR OSD Mono", 22, FlxColor.WHITE, CENTER);
		@:privateAccess
		dontaskButton.updateLabelPosition();
		// dontaskButton.screenCenter(X);
		dontaskButton.x = 448;
		dontaskButton.y = text.y + dontaskButton.height + 50;
		add(dontaskButton);

		var downloadButton = new FlxButton(0, 0, "Download", () -> {
			FlxG.openURL('https://github.com/luckydog7/Funkin-android/releases');
		});
		downloadButton.loadGraphic(t, true, 180, 50);
		dontaskButton.label.setFormat("VCR OSD Mono", 22, FlxColor.WHITE, CENTER);
		@:privateAccess
		downloadButton.updateLabelPosition();
		downloadButton.label.text = "Download";
		// downloadButton.screenCenter(X);
		downloadButton.x = dontaskButton.x + downloadButton.width + 25;
		downloadButton.y = text.y + downloadButton.height + 50;
		add(downloadButton);
		// var ver = "v" + Application.current.meta.get('version');
		// var txt:FlxText = new FlxText(0, 0, FlxG.width,
		// 	"HEY! You're running an outdated version of the game!\nCurrent version is "
		// 	+ ver
		// 	+ " while the most recent version is "
		// 	// + NGio.GAME_VER
		// 	+ "! Press Space to go to itch.io, or ESCAPE to ignore this!!",
		// 	32);
		// txt.setFormat("VCR OSD Mono", 32, FlxColor.WHITE, CENTER);
		// txt.screenCenter();
		// add(txt);
	}

	function buttonbm():BitmapData {
		var size = {width: 180, height: 150}
		var bd = new BitmapData(size.width, size.height, false, FlxColor.fromRGB(174, 198, 207));
		// bd.fillRect(new Rectangle(0, size.height / 3, size.width, size.height / 3), FlxColor.fromRGB(96, 192, 216)); // hover
		bd.fillRect(new Rectangle(0, (size.height / 3) * 2, size.width, size.height / 3), FlxColor.fromRGB(146, 166, 173)); // hold
		return bd;
	}

	// override function update(elapsed:Float)
	// {
	// 	if (controls.ACCEPT)
	// 	{
	// 		FlxG.openURL("https://ninja-muffin24.itch.io/funkin");
	// 	}
	// 	if (controls.BACK)
	// 	{
	// 		leftState = true;
	// 		FlxG.switchState(new MainMenuState());
	// 	}
	// 	super.update(elapsed);
	// }
}
