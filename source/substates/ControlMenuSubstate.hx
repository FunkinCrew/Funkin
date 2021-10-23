package substates;

import flixel.text.FlxText;
import utilities.CoolUtil;
import game.Note;
import flixel.tweens.FlxEase;
import utilities.NoteVariables;
import flixel.tweens.FlxTween;
import flixel.group.FlxGroup;
import flixel.util.FlxColor;
import flixel.FlxG;
import flixel.FlxSprite;

class ControlMenuSubstate extends MusicBeatSubstate
{
    var key_Count:Int = 4;
    var arrow_Group:FlxTypedGroup<FlxSprite> = new FlxTypedGroup<FlxSprite>();
    var text_Group:FlxTypedGroup<FlxText> = new FlxTypedGroup<FlxText>();

    public var ui_Settings:Array<String> = CoolUtil.coolTextFile(Paths.txt("ui skins/default/config"));
    public var mania_Size:Array<String> = CoolUtil.coolTextFile(Paths.txt("ui skins/default/maniasize"));
    public var mania_offset:Array<String> = CoolUtil.coolTextFile(Paths.txt("ui skins/default/maniaoffset"));

    public var arrow_Configs:Map<String, Array<String>> = new Map<String, Array<String>>();

    var binds:Array<Array<String>> = FlxG.save.data.binds;

    var selectedControl:Int = 0;
    var selectingStuff:Bool = false;

    var coolText:FlxText = new FlxText(0,25,0,"Use LEFT and RIGHT to change number of keys\nESCAPE to save binds and exit menu\n", 32);

    public function new()
    {
        FlxG.mouse.visible = true;

        arrow_Configs.set("default", CoolUtil.coolTextFile(Paths.txt("ui skins/default/default")));

        super();

        coolText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
        coolText.screenCenter(X);
        
        var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
        bg.alpha = 0;
        bg.scrollFactor.set();
        add(bg);

        FlxTween.tween(bg, {alpha: 0.5}, 1, {ease: FlxEase.circOut, startDelay: 0});

        create_Arrows();

        add(arrow_Group);
        add(text_Group);
        add(coolText);
    }

    override function update(elapsed:Float) {
        super.update(elapsed);

        var leftP = controls.LEFT_P;
		var rightP = controls.RIGHT_P;
        var reset = controls.RESET;
        var back = controls.BACK;

        if(reset)
            binds = NoteVariables.Default_Binds;

        if(back)
        {
            FlxG.mouse.visible = false;

            FlxG.save.data.binds = binds;
            FlxG.save.flush();

            FlxG.state.closeSubState();
        }

        for(x in arrow_Group)
        {
            if(FlxG.mouse.overlaps(x) &&  FlxG.mouse.justPressed && !selectingStuff)
            {
                selectedControl = x.ID;
                selectingStuff = true;
            }

            if(FlxG.mouse.overlaps(x) || x.ID == selectedControl && selectingStuff)
                x.color = FlxColor.GRAY;
            else
                x.color = FlxColor.WHITE;
        }

        if(selectingStuff && FlxG.keys.justPressed.ANY)
            binds[key_Count - 1][selectedControl] = FlxG.keys.getIsDown()[0].ID.toString();

        if(!selectingStuff && (leftP || rightP))
        {
            if(leftP)
                key_Count -= 1;

            if(rightP)
                key_Count += 1;

            if(key_Count < 1)
                key_Count = 1;

            if(key_Count > 18)
                key_Count = 18;

            create_Arrows();
        }

        if(selectingStuff && FlxG.keys.justPressed.ANY)
            selectingStuff = false;

        update_Text();
    }

    function update_Text()
    {
        for(i in 0...text_Group.length)
        {
            text_Group.members[i].text = binds[key_Count - 1][i];
        }
    }

    function create_Arrows(?new_Key_Count)
    {
        if(new_Key_Count != null)
            key_Count = new_Key_Count;

        arrow_Group.clear();
        text_Group.clear();

        Note.swagWidth = 160 * (0.7 - ((key_Count - 4) * 0.06));

        var lmaoStuff = Std.parseFloat(ui_Settings[0]) * (Std.parseFloat(ui_Settings[2]) - (Std.parseFloat(mania_Size[key_Count - 1])));

		for (i in 0...key_Count)
        {
            var babyArrow:FlxSprite = new FlxSprite(FlxG.width / 2, FlxG.height / 2);

            babyArrow.frames = Paths.getSparrowAtlas("ui skins/default/arrows/default", 'shared');

            babyArrow.antialiasing = ui_Settings[3] == "true";

            babyArrow.setGraphicSize(Std.int(babyArrow.width * lmaoStuff));
            babyArrow.screenCenter(X);

            var animation_Base_Name = NoteVariables.Note_Count_Directions[key_Count - 1][Std.int(Math.abs(i))].getName().toLowerCase();

            babyArrow.animation.addByPrefix('static', animation_Base_Name + " static");
            babyArrow.animation.addByPrefix('pressed', NoteVariables.Other_Note_Anim_Stuff[key_Count - 1][i] + ' press', 24, false);
            babyArrow.animation.addByPrefix('confirm', NoteVariables.Other_Note_Anim_Stuff[key_Count - 1][i] + ' confirm', 24, false);

            babyArrow.updateHitbox();
            babyArrow.scrollFactor.set();

            if(i == 0)
            {
                babyArrow.x -= babyArrow.width;
                babyArrow.x += ((babyArrow.width + 2) * Math.abs(i));
            }
            else
            {
                babyArrow.x = arrow_Group.members[0].x;

                arrow_Group.forEach(function(arrow:FlxSprite) {
                    babyArrow.x += arrow.width;
                });

                babyArrow.x += 2;
            }

            babyArrow.y -= (babyArrow.height / 2);

            babyArrow.alpha = 0;

            FlxTween.tween(babyArrow, {y: babyArrow.y + 10, alpha: 1}, 1, {ease: FlxEase.circOut, startDelay: 0.2 + (0.2 * i)});

            babyArrow.ID = i;

            babyArrow.offset.y += Std.parseFloat(arrow_Configs.get("default")[0]) * lmaoStuff;

            babyArrow.animation.play('static');

            arrow_Group.add(babyArrow);

            var coolWidth = Std.int(40 - ((key_Count - 5) * 2));

            text_Group.add(new FlxText(babyArrow.x + (babyArrow.width / 2), babyArrow.y + coolWidth, coolWidth, binds[key_Count - 1][i], coolWidth));
        }
    }
}