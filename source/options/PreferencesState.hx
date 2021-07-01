package options;

import flixel.util.FlxColor;
import flixel.FlxSprite;
import ui.Checkbox;
import flixel.FlxG;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import Config;

class PreferencesState extends MusicBeatState
{
    private var grptext:FlxTypedGroup<Alphabet>;

    private var checkboxGroup:FlxTypedGroup<Checkbox>;

    var curSelected:Int = 0;

	var menuItems:Array<String> = ['downscroll', 'disable cutscenes', 'note splash'];

	var notice:FlxText;

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
					ch.change(config.downscroll);
				case "disable cutscenes":
					ch.change(config.cutscenes);
				case "note splash":
					ch.change(config.splash);
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

		if (controls.RIGHT) {
		    MusicBeatState.camMove = floatToStringPrecision(Math.abs(MusicBeatState.camMove + 0.01), 2);
		    config.camSave(MusicBeatState.camMove);
		}
		if (controls.LEFT) {
		    MusicBeatState.camMove = floatToStringPrecision(Math.abs(MusicBeatState.camMove - 0.01), 2);
		    config.camSave(MusicBeatState.camMove);
		}

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
					config.downscroll = checkboxGroup.members[curSelected].change();
                case "disable cutscenes":
                    config.cutscenes = checkboxGroup.members[curSelected].change();
                case "note splash":
                    config.splash = checkboxGroup.members[curSelected].change();
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
		}
	  }
}