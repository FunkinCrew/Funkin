package option;

import flixel.math.FlxMath;
import flixel.util.FlxColor;
import flixel.FlxSprite;
import ui.Checkbox;
import flixel.FlxG;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import Config;
import ui.Mobilecontrols;
// import utils.AndroidData;

class PreferencesState extends MusicBeatState
{
	private var grptext:FlxTypedGroup<Alphabet>;

	private var checkboxGroup:FlxTypedGroup<Checkbox>;

	var curSelected:Int = 0;

	var menuItems:Array<String> = ['downscroll', 'ghost tapping', 'middlescroll', 'cutscenes', 'note splash', 'note glow', 'optimization',/* 'dfjk',*/ 'change icons'];

	var notice:FlxText;
	// var data:AndroidData = new AndroidData();

	override public function create() 
	{
		var menuBG:FlxSprite = new FlxSprite().loadGraphic('assets/images/menuDesat.png');
		menuBG.color = 0xFFea71fd;
		menuBG.setGraphicSize(Std.int(menuBG.width * 1.1));
		menuBG.updateHitbox();
		menuBG.screenCenter();
		menuBG.antialiasing = true;
		add(menuBG);

		grptext = new FlxTypedGroup<Alphabet>();
		add(grptext);

		checkboxGroup = new FlxTypedGroup<Checkbox>();
		add(checkboxGroup);

		for (i in 0...menuItems.length)
		{ 
			var controlLabel:Alphabet = new Alphabet(0, (70 * i) + 30, menuItems[i], true, false);
			controlLabel.isMenuItem = true;
			controlLabel.targetY = i;
			grptext.add(controlLabel);

			var ch = new Checkbox(controlLabel.x + controlLabel.width + 10, controlLabel.y - 20);
			checkboxGroup.add(ch);
			add(ch);

			switch (menuItems[i]){
				case "downscroll":
					ch.change(Config.downscroll);
				case "cutscenes":
					ch.change(Config.cutscenes);
				case "note splash":
					ch.change(Config.splash);
				case "note glow":
					ch.change(Config.glow);
				case "middlescroll":
					ch.change(Config.mid);
				case "optimization":
					ch.change(Config.osu);
				// case "dfjk":
				// 	ch.change(Config.getDfjk());
				case "ghost tapping":
					ch.change(Config.ghost);
				case "change icons":
					//do nothing.
			}

			// DONT PUT X IN THE FIRST PARAMETER OF new ALPHABET() !!
		}

		var noticebg = new FlxSprite(0, FlxG.height - 56).makeGraphic(FlxG.width, 30, FlxColor.BLACK);
		noticebg.alpha = 0.25;


		notice = new FlxText(0, 0, 0,"Cam Speed: " + PlayState.camFollowSpeed + "Press LEFT or RIGHT to change values\n", 24);

		//notice.x = (FlxG.width / 2) - (notice.width / 2);
		notice.screenCenter();
		notice.y = FlxG.height - 56;
		notice.alpha = 0.6;
		add(noticebg);
		add(notice);

		Mobilecontrols.addVirtualPad(FULL, A_B);

		changeSelection();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (controls.RIGHT) {
			PlayState.camFollowSpeed = FlxMath.roundDecimal(Math.abs(PlayState.camFollowSpeed + 0.01), 2);
			Config.cam = (PlayState.camFollowSpeed);
		}
		if (controls.LEFT) {
			PlayState.camFollowSpeed = FlxMath.roundDecimal(Math.abs(PlayState.camFollowSpeed - 0.01), 2);
			Config.cam = (PlayState.camFollowSpeed);
		}//waht.

		notice.text = "Cam Speed: " + PlayState.camFollowSpeed + "Press LEFT or RIGHT to change values\n";

		for (i in 0...checkboxGroup.length)
		{
			checkboxGroup.members[i].x = grptext.members[i].x + grptext.members[i].width + 10;
			checkboxGroup.members[i].y = grptext.members[i].y - 20;
		} 

		if (controls.ACCEPT)
		{
			var daSelected:String = menuItems[curSelected];

			trace(curSelected);

			switch (daSelected)
			{
				case "downscroll":
					Config.downscroll = (checkboxGroup.members[curSelected].change());
				case "cutscenes":
					Config.cutscenes = (checkboxGroup.members[curSelected].change());
				case "note splash":
					Config.splash = (checkboxGroup.members[curSelected].change());//wjat.
				case "note glow":
					Config.glow = (checkboxGroup.members[curSelected].change());
				case "middlescroll":
					Config.mid = (checkboxGroup.members[curSelected].change());
				case "optimization":
					Config.osu = (checkboxGroup.members[curSelected].change());
				// case "dfjk":
				// 	Config.dfjk = (checkboxGroup.members[curSelected].change());
				case "change icons":
					FlxG.switchState(new option.IconState());
				case "ghost tapping":
					Config.ghost = checkboxGroup.members[curSelected].change();
			}
		}

		if (controls.BACK #if android || FlxG.android.justReleased.BACK #end) {
			FlxG.switchState(new OptionsMenu());
		}

		if (controls.UP_P)
			changeSelection(-1);
		if (controls.DOWN_P)
			changeSelection(1);

	}

	function changeSelection(change:Int = 0)
	{
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		curSelected += change;

		if (curSelected < 0)
			curSelected = grptext.length - 1;
		if (curSelected >= grptext.length)
			curSelected = 0;

		var bullShit:Int = 0;

		for (item in grptext.members)
		{
			item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = 0.6;
			// item.setGraphicSize(Std.int(item.width * 0.8));

			if (item.targetY == 0)
			{
				item.alpha = 1;
				// item.setGraphicSize(Std.int(item.width));
			}
		}
	}
}