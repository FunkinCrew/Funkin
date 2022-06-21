package states.menu;

import flixel.text.FlxText;
import flixel.FlxG;
import engine.functions.Option;
import engine.io.Paths;
import flixel.FlxSprite;
import flixel.FlxState;

class GamemodeState extends FlxState
{
    public static var activeGamemodes:Array<String> = [];

    var textBoi:FlxText;

    public override function create()
    {
        super.create();

        if (Option.recieveValue("GRAPHICS_globalAA") == 0)
        {
            FlxG.camera.antialiasing = true;
        }

        var bg = new FlxSprite(0, 0);
        bg.loadGraphic(Paths.image("menuBGBlue"));
        add(bg);

        textBoi = new FlxText(0, 0, FlxG.width, "Gamemodes");
        textBoi.setFormat("assets/fonts/PhantomMuff.ttf", 32, 0xffffffff, CENTER);
        add(textBoi);
    }

    public override function update(elapsed:Float)
    {
        super.update(elapsed);
    }
}