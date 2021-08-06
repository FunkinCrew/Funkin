package ui;

import utilities.PlayerSettings;
import flixel.FlxG;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.util.FlxColor;
import flixel.util.FlxAxes;
import flixel.text.FlxText;
import flixel.FlxSprite;

class ControlsBox extends FlxTypedGroup<FlxSprite>
{
    // Creates controls box
    var box = new FlxSprite(0, 30);
    var controlsText = new FlxText(0, 50, 0, "null", 32);
    var selectedKey = 0;
    var controlsTableIGuess = ["Left", "Down", "Up", "Right", "Reset"];

    public function new()
    {
        super();

        // Creates controls text
        controlsText.text = (
            "-- Controls --\n"
            + FlxG.save.data.leftBind
            + " "
            + FlxG.save.data.downBind
            + " "
            + FlxG.save.data.upBind
            + " "
            + FlxG.save.data.rightBind
            + "\nReset: "
            + FlxG.save.data.killBind
            + "\nSelected: "
            + controlsTableIGuess[selectedKey]
        );

        controlsText.screenCenter(FlxAxes.X);
        controlsText.alignment = CENTER;

        // Updates boxes positioning and stuff i guess
        box.makeGraphic(Std.int(controlsText.width) + 25, Std.int(controlsText.height) + 25, FlxColor.BLACK);
        box.alpha = 0.5;
        box.screenCenter(FlxAxes.X);

        // Adds box before text for correct layering
        add(box);
        add(controlsText);
    }

    override function update(elapsed:Float)
    {
        if (FlxG.keys.justPressed.ANY)
        {
            if (!FlxG.keys.pressed.ESCAPE)
            {
                switch(selectedKey)
                {
                    case 0:
                        FlxG.save.data.leftBind = FlxG.keys.getIsDown()[0].ID.toString();
                    case 1:
                        FlxG.save.data.downBind = FlxG.keys.getIsDown()[0].ID.toString();
                    case 2:
                        FlxG.save.data.upBind = FlxG.keys.getIsDown()[0].ID.toString();
                    case 3:
                        FlxG.save.data.rightBind = FlxG.keys.getIsDown()[0].ID.toString();
                    case 4:
                        FlxG.save.data.killBind = FlxG.keys.getIsDown()[0].ID.toString();
                }
    
                selectedKey++;
    
                if (selectedKey > 4)
                {
                    selectedKey = 0;
                }
                
                FlxG.save.flush();
    
                controlsText.text = (
                    "-- Controls --\n"
                    + FlxG.save.data.leftBind
                    + " "
                    + FlxG.save.data.downBind
                    + " "
                    + FlxG.save.data.upBind
                    + " "
                    + FlxG.save.data.rightBind
                    + "\nReset: "
                    + FlxG.save.data.killBind
                    + "\nSelected: "
                    + controlsTableIGuess[selectedKey]
                    
                );

                controlsText.screenCenter(FlxAxes.X);
    
                box.makeGraphic(Std.int(controlsText.width) + 25, Std.int(controlsText.height) + 25, FlxColor.BLACK);
                box.screenCenter(FlxAxes.X);
            }
        }

        super.update(elapsed);
    }
}