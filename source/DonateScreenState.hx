package;

import flixel.group.FlxGroup.FlxTypedGroup;
import openfl.Assets;
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

	var textGroup:FlxTypedGroup<Alphabet>;
	var menuItem:FlxSprite;

	override function create()
	{
		transIn = FlxTransitionableState.defaultTransIn;
		transOut = FlxTransitionableState.defaultTransOut;

		// TODO play "Give a Lil' Bit Back" here

		persistentUpdate = persistentDraw = true;

		var bg:FlxSprite = new FlxSprite(-80).loadGraphic(Paths.image('menuBG'));
		bg.color = 0x8F2828; // red, the color of passion
		bg.setGraphicSize(Std.int(bg.width * 1.1));
		bg.updateHitbox();
		bg.screenCenter();
		bg.antialiasing = true;
		add(bg);

		var tex = Paths.getSparrowAtlas('FNF_main_menu_assets');

		menuItem = new FlxSprite(0, 520);
		menuItem.frames = tex;
		menuItem.animation.addByPrefix('selected', "donate white", 24);
		menuItem.animation.play('selected');
		menuItem.updateHitbox();
		menuItem.screenCenter(X);
		add(menuItem);
		menuItem.antialiasing = true;

		textGroup = new FlxTypedGroup<Alphabet>();
		add(textGroup);
		for (i in 0...blurb.length)
		{
			var money:Alphabet = new Alphabet(0, 0, blurb[i], true, false);
			money.screenCenter(X);
			money.y += (i * 60) + 120;
			textGroup.add(money);
		}

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

		menuItem.screenCenter(X);
	}
}