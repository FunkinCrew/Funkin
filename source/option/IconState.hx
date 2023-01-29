package option;

import ui.Mobilecontrols;
import flixel.ui.FlxButton;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.FlxSprite;
import flixel.FlxG;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import Config;

class IconState extends MusicBeatState{
	var curSelectedText:FlxText;

	var iconPreview:FlxSprite;
	var iconPreviewB:FlxSprite;
	var leftArrow:FlxButton;
	var rightArrow:FlxButton;




	override public function create(){
		var menuBG:FlxSprite = new FlxSprite().loadGraphic('assets/images/menuDesat.png');
		menuBG.color = 0xFFea71fd;
		menuBG.setGraphicSize(Std.int(menuBG.width * 1.1));
		menuBG.updateHitbox();
		menuBG.screenCenter();
		menuBG.antialiasing = true;
		add(menuBG);

		iconPreviewB = new FlxSprite().loadGraphic('assets/images/iconGridB.png');
		iconPreviewB.scale.set(0.75, 0.75);
		iconPreviewB.updateHitbox();
		iconPreviewB.screenCenter(X);
		iconPreviewB.y = 100;
		add(iconPreviewB);
		iconPreview = new FlxSprite().loadGraphic('assets/images/iconGrid.png');
		iconPreview.scale.set(0.75, 0.75);
		iconPreview.updateHitbox();
		iconPreview.screenCenter(X);
		iconPreview.y = 100;
		add(iconPreview);

		var ui_tex = FlxAtlasFrames.fromSparrow('assets/images/campaign_menu_UI_assets.png',
			'assets/images/campaign_menu_UI_assets.xml');

		leftArrow = new FlxButton(0, 0, "", () -> setPrimary(Config.icon = !Config.icon));
		leftArrow.frames = ui_tex;
		leftArrow.animation.addByPrefix("normal", "arrow left");
		leftArrow.animation.addByPrefix("highlight", "arrow left");
		leftArrow.animation.addByPrefix("pressed", "arrow push left");
		leftArrow.screenCenter(Y);
		leftArrow.x = 20;
		add(leftArrow);

		rightArrow = new FlxButton(0, 0, "", () -> setPrimary(Config.icon = !Config.icon));
		rightArrow.frames = ui_tex;
		rightArrow.animation.addByPrefix("normal", 'arrow right');
		rightArrow.animation.addByPrefix("highlight", 'arrow right');
		rightArrow.animation.addByPrefix("pressed", "arrow push right", 24, false);
		rightArrow.screenCenter(Y);
		rightArrow.x = FlxG.width - rightArrow.width + 130;
		add(rightArrow);
		
		curSelectedText = new FlxText(0, 0, 0,"\n" , 24);
		curSelectedText.screenCenter(X);
		curSelectedText.y = 30;
		curSelectedText.alpha = 0.6;
		add(curSelectedText);

		var notice = new FlxText(0, 0, 0,"Press LEFT or RIGHT to change Icons\n" , 24);
		notice.screenCenter(X);
		notice.y = FlxG.height - 56;
		notice.alpha = 0.6;
		add(notice);

		setPrimary(Config.icon);

		Mobilecontrols.addVirtualPad(LEFT_RIGHT, A_B);

		super.create();
	}

	function setPrimary(isB:Bool = false) {
		if (isB)
		{
			curSelectedText.text = 'current: Alt version';
			curSelectedText.screenCenter();
			curSelectedText.y = 10;
		}
		else
		{
			curSelectedText.text = 'current: Original version';
			curSelectedText.screenCenter();
			curSelectedText.y = 10;
		}

		FlxTween.num(0, 1, 0.2, { }, (val) -> {
			if (isB)
			{
				iconPreview.alpha = 1 - val;
				iconPreviewB.alpha = val;
			}
			else
			{
				iconPreview.alpha = val;
				iconPreviewB.alpha = 1 - val;
			}
			
		});
	}

	override function update(elapsed:Float){
		super.update(elapsed);

		if (controls.RIGHT_P)
			rightArrow.animation.play("pressed");
		if (controls.RIGHT_R)
			rightArrow.animation.play("normal");

		if (controls.LEFT_P)
			leftArrow.animation.play("pressed");
		if (controls.LEFT_R)
			leftArrow.animation.play("normal");


		if (controls.RIGHT_P || controls.LEFT_P){
			setPrimary(Config.icon = !Config.icon);
		}

		if (controls.BACK){
		    FlxG.switchState(new option.PreferencesState());
		}
	}
}