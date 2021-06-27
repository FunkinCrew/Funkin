package ui;

import flixel.graphics.FlxGraphic;
import flixel.addons.ui.FlxButtonPlus;
import flixel.FlxSprite;
import flixel.FlxG;
import flixel.graphics.frames.FlxTileFrames;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxPoint;
import flixel.system.FlxAssets;
import flixel.util.FlxDestroyUtil;
import flixel.ui.FlxButton;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.frames.FlxFrame;
import flixel.ui.FlxVirtualPad;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;

// copyed from flxvirtualpad
class Hitbox extends FlxSpriteGroup
{
	public var hitbox:FlxSpriteGroup;

	var sizex:Int = 320;

	var screensizey:Int = 720;

	public var buttonLeft:FlxButton;
	public var buttonDown:FlxButton;
	public var buttonUp:FlxButton;
	public var buttonRight:FlxButton;
	
	public function new(?widghtScreen:Int)
	{
		super();

		/*if (widghtScreen == null)
			widghtScreen = FlxG.width;*/

		sizex = widghtScreen != null ? Std.int(widghtScreen / 4) : 320;

		
		//add graphic
		hitbox = new FlxSpriteGroup();
		hitbox.scrollFactor.set();

		var hitbox_hint:FlxSprite = new FlxSprite(0, 0).loadGraphic('assets/shared/images/hitbox/hitbox_hint.png');

		hitbox_hint.alpha = 0.2;

		add(hitbox_hint);


		hitbox.add(add(buttonLeft = createhitbox(0, "left")));

		hitbox.add(add(buttonDown = createhitbox(sizex, "down")));

		hitbox.add(add(buttonUp = createhitbox(sizex * 2, "up")));

		hitbox.add(add(buttonRight = createhitbox(sizex * 3, "right")));
	}

	public function createhitbox(X:Float, framestring:String) {
		var button = new FlxButton(X, 0);
		var frames = FlxAtlasFrames.fromSparrow('assets/shared/images/hitbox/hitbox.png', 'assets/shared/images/hitbox/hitbox.xml');
		
		var graphic:FlxGraphic = FlxGraphic.fromFrame(frames.getByName(framestring));

		button.loadGraphic(graphic);

		button.alpha = 0;

	
		button.onDown.callback = function (){
			FlxTween.num(0, 0.75, .075, {ease: FlxEase.circInOut}, function (a:Float) { button.alpha = a; });
		};

		button.onUp.callback = function (){
			FlxTween.num(0.75, 0, .1, {ease: FlxEase.circInOut}, function (a:Float) { button.alpha = a; });
		}
		
		button.onOut.callback = function (){
			FlxTween.num(button.alpha, 0, .2, {ease: FlxEase.circInOut}, function (a:Float) { button.alpha = a; });
		}

		return button;
	}

	override public function destroy():Void
		{
			super.destroy();
	
			buttonLeft = null;
			buttonDown = null;
			buttonUp = null;
			buttonRight = null;
		}
}