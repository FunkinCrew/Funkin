package states.menu;

import engine.functions.Option;
import flixel.addons.transition.FlxTransitionableState;
import engine.base.MusicBeatState;
import flixel.FlxState;
import flixel.text.FlxText;
import engine.io.Paths;
import flixel.FlxG;

class RatingState extends MusicBeatState
{
    var misses:Int;
    var sicks:Int;
    var goods:Int;
    var bads:Int;
    var shits:Int;
    var whereGo:FlxState;

    public override function new(misses:Int, sicks:Int, goods:Int, bads:Int, shits:Int, whereGo:FlxState)
    {
        super();

        this.misses = misses;
        this.sicks = sicks;
        this.goods = goods;
        this.bads = bads;
        this.shits = shits;
        this.whereGo = whereGo;
    }

    public override function create()
    {
        if (Option.recieveValue("GRAPHICS_globalAA") == 0)
            FlxG.camera.antialiasing = true;
        else
            FlxG.camera.antialiasing = false;

        transIn = FlxTransitionableState.defaultTransIn;
        transOut = FlxTransitionableState.defaultTransOut;

        super.create();

        FlxG.sound.playMusic(Paths.music("breakfast", "shared"));
        FlxG.sound.music.fadeIn(7, 0, 1);

        var text:FlxText = new FlxText(10, 10, FlxG.width,
            "Song Finished\n" +
            "Misses: " + misses + "\n" +
            "Sicks: " + sicks + "\n" +
            "Goods: " + goods + "\n" +
            "Bads: " + bads + "\n" +
            "Shits: " + shits + "\n" +
            "Hit: " + (sicks + goods + bads + shits) + "/" + (misses + sicks + goods + bads + shits) +
            " (that's " + ((sicks + goods + bads + shits) / (misses + sicks + goods + bads + shits)) * 100 + "%)");
        text.setFormat("assets/fonts/PhantomMuff.ttf", 32, 0xFFFFFFFF, LEFT);
        add(text);
    }

    public override function update(elapsed:Float)
    {
        super.update(elapsed);

        if (FlxG.keys.justPressed.ANY)
        {
            FlxG.switchState(whereGo);
        }
    }
}