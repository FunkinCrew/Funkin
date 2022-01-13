package substates;

import lime.app.Application;
import openfl.Lib;
import game.Conductor;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.FlxG;
import flixel.FlxSprite;

class MaxFPSMenu extends MusicBeatSubstate
{
    var fps:Int = 0;
    var offsetText:FlxText = new FlxText(0,0,0,"Max FPS: 120",64).setFormat(Paths.font("vcr.ttf"), 64, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);

    public function new()
    {
        super();

        fps = utilities.Options.getData("maxFPS");
        
        var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
        bg.alpha = 0;
        bg.scrollFactor.set();
        add(bg);

        FlxTween.tween(bg, {alpha: 0.5}, 1, {ease: FlxEase.circOut, startDelay: 0});

        offsetText.text = "Max FPS: " + fps;
        offsetText.screenCenter();
        add(offsetText);
    }

    override function update(elapsed:Float) {
        super.update(elapsed);

        var leftP = controls.LEFT_P;
		var rightP = controls.RIGHT_P;

        var left = controls.LEFT;
		var right = controls.RIGHT;

        var accept = controls.ACCEPT;
        var back = controls.BACK;

        if(back)
        {
            utilities.Options.setData(fps, "maxFPS");
            FlxG.state.closeSubState();
        }

        if(left && !FlxG.keys.pressed.SHIFT)
            fps -= 1;
        if(right && !FlxG.keys.pressed.SHIFT)
            fps += 1;

        if(leftP && FlxG.keys.pressed.SHIFT)
            fps -= 1;
        if(rightP && FlxG.keys.pressed.SHIFT)
            fps += 1;

        if(accept)
            fps = Application.current.window.displayMode.refreshRate;

        if(fps > 1000)
            fps = 1000;

        if(fps < 10)
            fps = 10;

        offsetText.text = "Max FPS: " + fps + "\nENTER for VSYNC\n";
        offsetText.screenCenter();
    }
}