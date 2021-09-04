package;

import flixel.FlxG;
import flixel.text.FlxText;
import flixel.FlxState;

class Disclaimer extends FlxState {
    public override function create() {
        super.create();

        if (FlxG.sound.music != null) {
            FlxG.sound.music.stop();
        }

        var mainTxt:FlxText = new FlxText(0, 0, 0, "WHOOPS!\n\n\n\nIt seems you tried to compile this mod to a target that isn't C++\nDue to issues this mod is only compatable with C++.\nSorry!", 32);
        mainTxt.screenCenter();
        mainTxt.alignment = CENTER;
        add(mainTxt);
    }
}
