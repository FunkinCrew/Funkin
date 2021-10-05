package options;

import flixel.util.FlxColor;
import flixel.FlxSprite;
import ui.Checkbox;
import flixel.FlxG;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import Config;
import utils.AndroidData;

class PreferencesState extends MusicBeatState
{
	private var grptext:FlxTypedGroup<Alphabet>;

	private var checkboxGroup:FlxTypedGroup<Checkbox>;

	var curSelected:Int = 0;

	var menuItems:Array<String> = ['downscroll', 'ghost tapping', 'middlescroll', 'cutscenes', 'note splash', 'note glow', 'optimization', 'dfjk', 'change icons'];

	var notice:FlxText;
	var data:AndroidData = new AndroidData();

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
					ch.change(data.getScroll());
				case "cutscenes":
					ch.change(data.getCutscenes());
				case "note splash":
					ch.change(data.getSploosh());
				case "note glow":
					ch.change(data.getGlow());
				case "middlescroll":
					ch.change(data.getMid());
				case "optimization":
					ch.change(data.getOsu());
				case "dfjk":
					ch.change(data.getDfjk());
				case "ghost tapping":
					ch.change(config.ghost);
				case "change icons":
					//do nothing.
			}

			// DONT PUT X IN THE FIRST PARAMETER OF new ALPHABET() !!
		}

		var noticebg = new FlxSprite(0, FlxG.height - 56).makeGraphic(FlxG.width, 30, FlxColor.BLACK);
		noticebg.alpha = 0.25;


		notice = new FlxText(0, 0, 0,"Cam Speed: " + MusicBeatState.camMove + "Press LEFT or RIGHT to change values\n", 24);

		//notice.x = (FlxG.width / 2) - (notice.width / 2);
		notice.screenCenter();
		notice.y = FlxG.height - 56;
		notice.alpha = 0.6;
		add(noticebg);
		add(notice);

		#if mobileC
		addVirtualPad(FULL, A_B);
		#end

		changeSelection();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		data.flushData();

		if (controls.RIGHT) {
			MusicBeatState.camMove = floatToStringPrecision(Math.abs(MusicBeatState.camMove + 0.01), 2);
			config.camSave(MusicBeatState.camMove);
		}
		if (controls.LEFT) {
			MusicBeatState.camMove = floatToStringPrecision(Math.abs(MusicBeatState.camMove - 0.01), 2);
			config.camSave(MusicBeatState.camMove);
		}//waht.

		notice.text = "Cam Speed: " + MusicBeatState.camMove + "Press LEFT or RIGHT to change values\n";

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
					data.saveScroll(checkboxGroup.members[curSelected].change());
				case "cutscenes":
					data.saveCutscenes(checkboxGroup.members[curSelected].change());
				case "note splash":
					data.saveSploosh(checkboxGroup.members[curSelected].change());//wjat.
				case "note glow":
					data.saveGlow(checkboxGroup.members[curSelected].change());
				case "middlescroll":
					data.saveMid(checkboxGroup.members[curSelected].change());
				case "optimization":
					data.saveOsu(checkboxGroup.members[curSelected].change());
				case "dfjk":
					data.saveDfjk(checkboxGroup.members[curSelected].change());
				case "change icons":
					FlxG.switchState(new options.IconState());
					data.flushData();
				case "ghost tapping":
					config.ghost = checkboxGroup.members[curSelected].change();
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

	// code from here https://stackoverflow.com/questions/23689001/how-to-reliably-format-a-floating-point-number-to-a-specified-number-of-decimal
	public static function floatToStringPrecision(n:Float, prec:Int){
		n = Math.round(n * Math.pow(10, prec));
		var str = ''+n;
		var len = str.length;
		if(len <= prec){
		  while(len < prec){
			str = '0'+str;
			len++;
		  }
		  return Std.parseFloat('0.'+str);
		}
		else{
		  return Std.parseFloat(str.substr(0, str.length-prec) + '.'+str.substr(str.length-prec));
		}//what.
	  }
}