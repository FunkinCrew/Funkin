package;

import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.util.FlxColor;
import flixel.util.FlxAxes;
import flixel.text.FlxText;
import flixel.FlxSprite;

class ControlsBox extends FlxTypedGroup<FlxSprite>
{
    // Creates controls box
    var box = new FlxSprite();
    var controlsText = new FlxText(0, 50, 0, "null", 32);

    public function new()
    {
        super();

        // Creates controls text
        controlsText.text = "W, A, S, D \n--\n UP, LEFT, DOWN, RIGHT";
        controlsText.screenCenter(FlxAxes.X);
        controlsText.alignment = CENTER;

        // Sets stuff related to the text (may be changed mid running idk)
        box.makeGraphic(Std.int(controlsText.width) + 10, Std.int(controlsText.height) + 10, FlxColor.BLACK);
        box.alpha = 0.5;
        box.x = controlsText.x;
        box.y = controlsText.y;

        // Adds box before text for correct layering
        add(box);
        add(controlsText);
    }
}