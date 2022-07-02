package option;

import flixel.util.FlxColor;
import flixel.FlxSprite;
import flixel.FlxG;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import Config;

class IconState extends MusicBeatState{
	var curIcon:FlxSprite;

	var Icon:Bool;
	override public function create(){
		Icon = Config.icon;
		
		var notice:FlxText;

		if (Icon){
			curIcon = new FlxSprite().loadGraphic('assets/images/iconGridB.png');
		}
		else{
			curIcon = new FlxSprite().loadGraphic('assets/images/iconGrid.png');
		}
		curIcon.scale.set(1.5,1.5);
		add(curIcon);

		notice = new FlxText(0, 0, 0,"Press LEFT or RIGHT to change Icons\n" , 24);

		notice.screenCenter();
		notice.y = FlxG.height - 56;
		notice.alpha = 0.6;

		add(notice);

		#if mobileC
		addVirtualPad(LEFT_RIGHT, A_B);
		#end

		super.create();
	}

	override function update(elapsed:Float){
		super.update(elapsed);

		if (controls.RIGHT_P || controls.LEFT_P){
			if (!Icon)
				Config.icon = true;
			else
				Config.icon = false;

			FlxG.resetState();
		}

		if (controls.BACK){
		    FlxG.switchState(new option.PreferencesState());
		}
	}
}