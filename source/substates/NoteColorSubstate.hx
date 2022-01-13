package substates;

import shaders.NoteColors;
import game.StrumNote;
import utilities.PlayerSettings;
import flixel.text.FlxText;
import utilities.CoolUtil;
import flixel.tweens.FlxEase;
import utilities.NoteVariables;
import flixel.tweens.FlxTween;
import flixel.group.FlxGroup;
import flixel.util.FlxColor;
import flixel.FlxG;
import flixel.FlxSprite;
import lime.utils.Assets;

class NoteColorSubstate extends MusicBeatSubstate
{
    var key_Count:Int = 4;
    var arrow_Group:FlxTypedGroup<StrumNote> = new FlxTypedGroup<StrumNote>();

    public var ui_Settings:Array<String>;
    public var mania_size:Array<String>;
    public var mania_offset:Array<String>;

    public var arrow_Configs:Map<String, Array<String>> = new Map<String, Array<String>>();

    var selectedControl:Int = 0;
    var selectingStuff:Bool = false;

    var coolText:FlxText = new FlxText(0,25,0,"Use UP and DOWN to change number of keys\nLEFT and RIGHT to change arrow selected\nHue: 0, Saturation: 0, Value: 0\n", 32);

    var mania_gap:Array<String>;

    var selectedValue:Int = 0; // 0 = hue, 1 = saturation, 2 = value... k?

    var current_ColorVals:Array<Int> = [0,0,0];

    var colorMins:Array<Int> = [-360, -100, -100];
    var colorMaxs:Array<Int> = [360, 100, 100];

    public function new()
    {
        ui_Settings = CoolUtil.coolTextFile(Paths.txt("ui skins/default/config"));
        mania_size = CoolUtil.coolTextFile(Paths.txt("ui skins/default/maniasize"));
        mania_offset = CoolUtil.coolTextFile(Paths.txt("ui skins/default/maniaoffset"));
        mania_gap = CoolUtil.coolTextFile(Paths.txt("ui skins/default/maniagap"));

        arrow_Configs.set("default", CoolUtil.coolTextFile(Paths.txt("ui skins/default/default")));

        super();

        coolText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
        coolText.screenCenter(X);
        
        var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
        bg.alpha = 0;
        bg.scrollFactor.set();
        add(bg);

        FlxTween.tween(bg, {alpha: 0.5}, 1, {ease: FlxEase.circOut, startDelay: 0});

        #if PRELOAD_ALL
        create_Arrows();
        add(arrow_Group);
        #else
        Assets.loadLibrary("shared").onComplete(function (_) {
            create_Arrows();
            add(arrow_Group);
        });
        #end
        
        add(coolText);

        updateColorValsBase();
        update_Text();
    }

    override function update(elapsed:Float) {
        super.update(elapsed);

        var leftP = controls.LEFT_P;
		var rightP = controls.RIGHT_P;
        var upP = controls.UP_P;
		var downP = controls.DOWN_P;
        var accept = controls.ACCEPT;
        var reset = controls.RESET;
        var back = controls.BACK;

        if(arrow_Group != null)
        {
            if(reset)
            {
                current_ColorVals = [0,0,0];

                arrow_Group.members[selectedControl].colorSwap.hue = 0;
                arrow_Group.members[selectedControl].colorSwap.saturation = 0;
                arrow_Group.members[selectedControl].colorSwap.brightness = 0;

                NoteColors.setNoteColor(NoteVariables.Other_Note_Anim_Stuff[key_Count - 1][selectedControl], current_ColorVals);
            }

            if(back && selectingStuff)
                selectingStuff = false;
            else if(back)
            {
                FlxG.mouse.visible = false;
                FlxG.state.closeSubState();
            }
    
            for(x in arrow_Group)
            {
                if(x.ID == selectedControl && accept && !selectingStuff)
                {
                    selectedControl = x.ID;
                    selectingStuff = true;
                }
    
                if(x.ID == selectedControl)
                    x.alpha = 1;
                else
                    x.alpha = 0.6;
            }
    
            if(!selectingStuff && (upP || downP))
            {
                if(downP)
                    key_Count -= 1;
    
                if(upP)
                    key_Count += 1;
    
                if(key_Count < 1)
                    key_Count = 1;
    
                if(key_Count > NoteVariables.Note_Count_Directions.length)
                    key_Count = NoteVariables.Note_Count_Directions.length;
    
                create_Arrows();
            }

            if(selectingStuff && (upP || downP))
            {
                if(downP)
                    current_ColorVals[selectedValue] -= 1;
    
                if(upP)
                    current_ColorVals[selectedValue] += 1;
    
                if(current_ColorVals[selectedValue] < colorMins[selectedValue])
                    current_ColorVals[selectedValue] = colorMins[selectedValue];
    
                if(current_ColorVals[selectedValue] > colorMaxs[selectedValue])
                    current_ColorVals[selectedValue] = colorMaxs[selectedValue];
    
                switch(selectedValue)
                {
                    case 0:
                        arrow_Group.members[selectedControl].colorSwap.hue = current_ColorVals[selectedValue] / 360;
                    case 1:
                        arrow_Group.members[selectedControl].colorSwap.saturation = current_ColorVals[selectedValue] / 100;
                    case 2:
                        arrow_Group.members[selectedControl].colorSwap.brightness = current_ColorVals[selectedValue] / 100;
                }

                NoteColors.setNoteColor(NoteVariables.Other_Note_Anim_Stuff[key_Count - 1][selectedControl], current_ColorVals);
            }

            if(!selectingStuff && (leftP || rightP))
            {
                if(leftP)
                    selectedControl -= 1;

                if(rightP)
                    selectedControl += 1;

                if(selectedControl < 0)
                    selectedControl = key_Count - 1;

                if(selectedControl > key_Count - 1)
                    selectedControl = 0;

                updateColorValsBase();
            }

            if(selectingStuff && (leftP || rightP))
            {
                if(leftP)
                    selectedValue -= 1;

                if(rightP)
                    selectedValue += 1;

                if(selectedValue < 0)
                    selectedValue = 2;

                if(selectedValue > 2)
                    selectedValue = 0;
            }
    
            update_Text();
        }
    }

    function update_Text()
    {
        var hue = Std.string(current_ColorVals[0]);
        var sat = Std.string(current_ColorVals[1]);
        var val = Std.string(current_ColorVals[2]);

        switch(selectedValue)
        {
            case 0:
                hue = "> " + hue + " <";
            case 1:
                sat = "> " + sat + " <";
            case 2:
                val = "> " + val + " <";
        }

        coolText.text = "Use UP and DOWN to change number of keys or the selected color\nLEFT and RIGHT to change arrow selected or the color selected\nR to Reset Note Colors\nENTER to select a note\nHue: " + hue + ", Saturation: " + sat + ", Value: " + val + "\n";
        coolText.screenCenter(X);
    }

    function updateColorValsBase()
    {
        current_ColorVals = NoteColors.getNoteColor(NoteVariables.Other_Note_Anim_Stuff[key_Count - 1][selectedControl]);
    }

    function create_Arrows(?new_Key_Count)
    {
        if(new_Key_Count != null)
            key_Count = new_Key_Count;

        arrow_Group.clear();

        var strumLine:FlxSprite = new FlxSprite(0, FlxG.height / 2);

		for (i in 0...key_Count)
        {
            var babyArrow:StrumNote = new StrumNote(0, strumLine.y, i, "default", ui_Settings, mania_size, key_Count);

            babyArrow.frames = Paths.getSparrowAtlas("ui skins/default/arrows/default", 'shared');

			babyArrow.antialiasing = ui_Settings[3] == "true";

			babyArrow.setGraphicSize(Std.int((babyArrow.width * Std.parseFloat(ui_Settings[0])) * (Std.parseFloat(ui_Settings[2]) - (Std.parseFloat(mania_size[key_Count-1])))));
			babyArrow.updateHitbox();

			babyArrow.animation.addByPrefix('default', NoteVariables.Other_Note_Anim_Stuff[key_Count - 1][i] + "0");
			babyArrow.animation.addByPrefix('pressed', NoteVariables.Other_Note_Anim_Stuff[key_Count - 1][i] + ' press', 24, false);
			babyArrow.animation.addByPrefix('confirm', NoteVariables.Other_Note_Anim_Stuff[key_Count - 1][i] + ' confirm', 24, false);
			
			babyArrow.playAnim('default');

			babyArrow.x += (babyArrow.width + (2 + Std.parseFloat(mania_gap[key_Count - 1]))) * Math.abs(i) + Std.parseFloat(mania_offset[key_Count - 1]);
			babyArrow.y = strumLine.y - (babyArrow.height / 2);

            babyArrow.y -= 10;
            babyArrow.alpha = 0;
            FlxTween.tween(babyArrow, {y: babyArrow.y + 10, alpha: 1}, 1, {ease: FlxEase.circOut, startDelay: 0.5 + (0.2 * i)});

			babyArrow.ID = i;

			babyArrow.x += 100 - ((key_Count - 4) * 16) + (key_Count >= 10 ? 30 : 0);
			babyArrow.x += ((FlxG.width / 2) * 0.5);

            arrow_Group.add(babyArrow);
        }
    }
}