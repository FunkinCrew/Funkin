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

    public var left:FlxButton;
    public var down:FlxButton;
    public var up:FlxButton;
    public var right:FlxButton;
    var sp:Float  = 0.25;
    public function new(?widghtScreen:Int, ?heightScreen:Int)
    {
        super(widghtScreen, heightScreen);

        sizex = widghtScreen != null ? Std.int(widghtScreen / 4) : 320;

        
        //add graphic
        hitbox = new FlxSpriteGroup();
        hitbox.scrollFactor.set();

        // var hitbox_hint:FlxSprite = new FlxSprite(0, 0).loadGraphic('assets/shared/images/hitbox/hitbox_hint.png');

        // hitbox_hint.alpha = 0.3;

        // add(hitbox_hint);


        hitbox.add(add(left = createhitbox(0, "left")));

        hitbox.add(add(down = createhitbox(1, "down")));

        hitbox.add(add(up = createhitbox(2, "up")));

        hitbox.add(add(right = createhitbox(3, "right")));
    }


    public function createhitbox(X:Float, framestring:String) {
        var button = new FlxButton(X, 0);
        var frames = Paths.getSparrowAtlas('hitbox');// FlxAtlasFrames.fromSparrow('assets/shared/images/hitbox/hitbox.png', 'assets/shared/images/hitbox/hitbox.xml');
        

        button.loadGraphic(FlxGraphic.fromFrame(frames.getByName(framestring)));

        button.alpha = sp;
        switch (X){
            case 0:
                button.x = 0;
            case 1:
                button.x = button.width;
            case 2:
                button.x = FlxG.width  - (button.width * 2);
            case 3:
                button.x = FlxG.width  - (button.width);

        }
    
        button.onDown.callback = function (){
            FlxTween.num(sp, 0.75, .075, {ease: FlxEase.circInOut}, function (a:Float) { button.alpha = a; });
        };

        button.onUp.callback = function (){
            FlxTween.num(0.75, sp, .1, {ease: FlxEase.circInOut}, function (a:Float) { button.alpha = a; });
        }
        
        button.onOut.callback = function (){
            FlxTween.num(button.alpha, sp, .2, {ease: FlxEase.circInOut}, function (a:Float) { button.alpha = a; });
        }

        return button;
    }

    override public function destroy():Void
        {
            super.destroy();
    
            left = null;
            down = null;
            up = null;
            right = null;
        }
}