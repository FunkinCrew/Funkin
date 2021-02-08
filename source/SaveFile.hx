package;

import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import lime.system.System;
#if sys
import sys.io.File;
import haxe.io.Path;
import openfl.utils.ByteArray;
import flash.display.BitmapData;
#end
import haxe.Json;
import haxe.format.JsonParser;
class SaveFile extends FlxSpriteGroup
{
	public var targetY:Float = 0;
	public var save:FlxSprite;
	public var loadSprite:FlxSprite;
	public var leftArrow:FlxSprite;
	public var rightArrow:FlxSprite;
	public var deleteConfirm:FlxSprite;
	public var erasedSprite:FlxSprite;
	public var askingToConfirm:Bool = false;
	public var selectingLoad:Bool = true;
	public var playerIcon:HealthIcon;
	public function new(x:Float, y:Float, saveNum:Int = 0)
	{
		super(x, y);
		var tex = FlxAtlasFrames.fromSparrow('assets/images/save-data.png', 'assets/images/save-data.xml');
		selectingLoad = true;
		targetY = saveNum;
		save = new FlxSprite();
		save.frames = tex;
		save.setGraphicSize(Std.int(save.width * 2));
		leftArrow = new FlxSprite(250, 180);
		leftArrow.frames = tex;
		leftArrow.setGraphicSize(Std.int(leftArrow.width * 2));
		rightArrow = new FlxSprite(60, leftArrow.y);
		rightArrow.frames = tex;
		rightArrow.setGraphicSize(Std.int(rightArrow.width * 2));
		deleteConfirm = new FlxSprite(230, 100);
		loadSprite = new FlxSprite(leftArrow.x + leftArrow.width, leftArrow.y);
		loadSprite.frames = tex;

		loadSprite.setGraphicSize(Std.int(loadSprite.width * 2));
		deleteConfirm.frames = tex;
		deleteConfirm.setGraphicSize(Std.int(deleteConfirm.width * 1.5));
		erasedSprite = new FlxSprite(200, 100);
		erasedSprite.frames = tex;
		save.animation.addByPrefix('default', 'save file', 24);
		loadSprite.animation.addByPrefix('load', 'load', 24);
		loadSprite.animation.addByPrefix('delete', 'deletea', 24);
		leftArrow.animation.addByPrefix('default', 'left arrow', 24);
		rightArrow.animation.addByPrefix('default', 'right arrow', 24);
		deleteConfirm.animation.addByPrefix('default', 'delete confirm', 24);
		erasedSprite.animation.addByPrefix('default', 'deleted', 24);
		var iconType = '';
		switch (saveNum) {
			case 0:
				iconType = 'bf';
			case 1:
				iconType = 'bf-old';
			case 2:
				iconType = 'bf-pixel';
		}
		playerIcon = new HealthIcon(iconType, false);
		playerIcon.setGraphicSize(Std.int(playerIcon.width * 1.3));
		playerIcon.updateHitbox();
		playerIcon.y += 20;
		playerIcon.x += 20;
		add(save);
		save.antialiasing = true;
		loadSprite.antialiasing = true;
		leftArrow.antialiasing = true;
		rightArrow.antialiasing = true;
		deleteConfirm.antialiasing = true;
		erasedSprite.antialiasing = true;
		add(loadSprite);
		add(leftArrow);
		add(rightArrow);
		add(deleteConfirm);
		add(erasedSprite);
		add(playerIcon);
		save.animation.play('default');
		save.animation.pause();
		loadSprite.animation.play('load');
		loadSprite.animation.pause();
		save.updateHitbox();
		loadSprite.updateHitbox();
		leftArrow.animation.play('default');
		leftArrow.animation.pause();
		leftArrow.updateHitbox();
		rightArrow.animation.play('default');
		rightArrow.animation.pause();
		rightArrow.updateHitbox();
		deleteConfirm.animation.play('default');
		deleteConfirm.animation.pause();
		deleteConfirm.updateHitbox();
		erasedSprite.animation.play('default');
		erasedSprite.animation.pause();
		erasedSprite.updateHitbox();
		erasedSprite.visible = false;
		deleteConfirm.visible = false;
		loadSprite.x = leftArrow.x + leftArrow.width;
		rightArrow.x = loadSprite.x + loadSprite.width;
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		y = FlxMath.lerp(y, 120 + (targetY * 420), 0.17);
	}
	public function askToConfirm(?turnOn:Bool = true) {
		deleteConfirm.visible = turnOn;
		askingToConfirm = turnOn;
		erasedSprite.visible = false;
		if (turnOn) {
			playerIcon.animation.curAnim.curFrame = 1;
		} else {
			playerIcon.animation.curAnim.curFrame = 0;
		}
	}
	public function changeSelection() {
		if (selectingLoad) {
			loadSprite.animation.play('delete');
			selectingLoad = false;
			loadSprite.updateHitbox();
			leftArrow.x = 690;
			loadSprite.x = leftArrow.x + leftArrow.width;
			rightArrow.x = loadSprite.x + loadSprite.width;
		}	else {
			loadSprite.animation.play('load');
			selectingLoad = true;
			loadSprite.updateHitbox();
			leftArrow.x = 750;
			loadSprite.x = leftArrow.x + leftArrow.width;
			rightArrow.x = loadSprite.x + loadSprite.width;
		}

	}
}
