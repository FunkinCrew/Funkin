package options;

import flixel.util.FlxColor;
import flixel.FlxSprite;
import flixel.FlxG;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import Config;
import utils.AndroidData;

class IconState extends MusicBeatState{
	var data:AndroidData = new AndroidData();
	var curIcon:FlxSprite;

	var Icon:Bool;
	override public function create(){
		Icon = data.getIcon();
		
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

		data.flushData();

		if (controls.RIGHT_P || controls.LEFT_P){
			if (!Icon)
				data.saveIcon(true);
			else
				data.saveIcon(false);

			data.flushData();
			FlxG.resetState();
		}

		if (controls.BACK){
		    data.flushData();
		    FlxG.switchState(new options.PreferencesState());
		}
	}
}