package;

import flixel.util.FlxColor;
import flixel.text.FlxText;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.addons.transition.FlxTransitionableState;
import flixel.FlxG;
import flixel.FlxSprite;

class DonateScreenState extends MusicBeatState {
	var blurb:Array<String> = [
		"your donations help us",
		"develop the funkiest game",
		"this side of the internet",
		"",
		"support the funky cause",
		"give a lil bit back"
	];

	override function create()
	{
		transIn = FlxTransitionableState.defaultTransIn;
		transOut = FlxTransitionableState.defaultTransOut;

		// TODO play "Give a Lil' Bit Back" here

		persistentUpdate = persistentDraw = true;

		var bg:FlxSprite = new FlxSprite(-80).loadGraphic(Paths.image('menuBG'));
		bg.color = 0xFF8F8F; // this was supposed to be red but it came out orange. oh well
		bg.setGraphicSize(Std.int(bg.width * 1.1));
		bg.updateHitbox();
		bg.screenCenter();
		bg.antialiasing = true;
		add(bg);

		var tex = Paths.getSparrowAtlas('FNF_main_menu_assets');

		var menuItem:FlxSprite = new FlxSprite(0, 520);
		menuItem.frames = tex;
		menuItem.animation.addByPrefix('selected', "donate white", 24);
		menuItem.animation.play('selected');
		menuItem.updateHitbox();
		menuItem.screenCenter(X);
		add(menuItem);
		menuItem.antialiasing = true;

		var textGroup:FlxTypedGroup<Alphabet> = new FlxTypedGroup<Alphabet>();
		add(textGroup);
		for (i in 0...blurb.length)
		{
			var money:Alphabet = new Alphabet(0, 0, blurb[i], true, false);
			money.screenCenter(X);
			money.y += (i * 60) + 120;
			textGroup.add(money);
		}

		#if html5
		var someText:FlxText = new FlxText(0, 684, 0, "(opens the itch.io page in a new tab)");
		#else
		var someText:FlxText = new FlxText(0, 684, 0, "(opens the itch.io page in a browser window)");
		#end
		someText.setFormat("VCR OSD Mono", 24, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		someText.updateHitbox();
		someText.screenCenter(X);
		add(someText);

		super.create();
	}

	override function update(elapsed:Float)
	{
		if (controls.BACK)
		{
			FlxG.switchState(new MainMenuState());
		}

		if (controls.ACCEPT)
		{
			#if linux
			Sys.command('/usr/bin/xdg-open', ["https://ninja-muffin24.itch.io/funkin", "&"]);
			#else
			FlxG.openURL('https://ninja-muffin24.itch.io/funkin');
			#end
		}

		super.update(elapsed);
	}
}