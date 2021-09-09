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

    #if sys
	public var ui_Settings:Array<String> = CoolUtil.coolTextFilePolymod(Paths.txt("ui skins/" + FlxG.save.data.uiSkin + "/config"));
	#else
	public var ui_Settings:Array<String> = CoolUtil.coolTextFile(Paths.txt("ui skins/" + FlxG.save.data.uiSkin + "/config"));
	#end

    var controlsLmao:Array<String> = [FlxG.save.data.leftBind, FlxG.save.data.downBind, FlxG.save.data.upBind, FlxG.save.data.rightBind];

    var selectedControl:Int = 0;
    var selectingStuff:Bool = false;

    public function new()
    {
        FlxG.mouse.visible = true;

        super();
        
        var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
        bg.alpha = 0;
        bg.scrollFactor.set();
        add(bg);

        FlxTween.tween(bg, {alpha: 0.5}, 1, {ease: FlxEase.circOut, startDelay: 0});

        create_Arrows();

        add(arrow_Group);
        add(text_Group);
    }

    override function update(elapsed:Float) {
        super.update(elapsed);

        var upP = controls.UP_P;
		var downP = controls.DOWN_P;
		var accepted = controls.ACCEPT;
        var back = controls.BACK;

        if(back)
        {
            FlxG.save.data.leftBind = controlsLmao[0];
            FlxG.save.data.downBind = controlsLmao[1];
            FlxG.save.data.upBind = controlsLmao[2];
            FlxG.save.data.rightBind = controlsLmao[3];

            FlxG.save.flush();

            FlxG.mouse.visible = false;

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
        {
            controlsLmao[selectedControl] = FlxG.keys.getIsDown()[0].ID.toString();
            selectingStuff = false;
        }

        update_Text();
    }

    function update_Text()
    {
        for(i in 0...text_Group.length)
        {
            text_Group.members[i].text = controlsLmao[i];
        }
    }

    function create_Arrows(?new_Key_Count = 4)
    {
        if(new_Key_Count != null)
            key_Count = new_Key_Count;

        arrow_Group.clear();

        Note.swagWidth = 160 * (0.7 - ((key_Count - 4) * 0.06));

		for (i in 0...key_Count)
        {
            var babyArrow:FlxSprite = new FlxSprite(0, FlxG.height / 2);

            babyArrow.frames = Paths.getSparrowAtlas('ui skins/' + FlxG.save.data.uiSkin + "/arrows/default", 'shared');

            babyArrow.antialiasing = ui_Settings[3] == "true";

            babyArrow.setGraphicSize(Std.int((babyArrow.width * Std.parseFloat(ui_Settings[0])) * (Std.parseFloat(ui_Settings[2]) - ((key_Count - 4) * 0.06))));
            babyArrow.screenCenter(X);
            babyArrow.x += Note.swagWidth * Math.abs(i);

            var animation_Base_Name = NoteVariables.Note_Count_Directions[key_Count - 1][Std.int(Math.abs(i))].getName().toLowerCase();

            babyArrow.animation.addByPrefix('static', animation_Base_Name + " static");
            babyArrow.animation.addByPrefix('pressed', NoteVariables.Other_Note_Anim_Stuff[key_Count - 1][i] + ' press', 24, false);
            babyArrow.animation.addByPrefix('confirm', NoteVariables.Other_Note_Anim_Stuff[key_Count - 1][i] + ' confirm', 24, false);

            babyArrow.updateHitbox();
            babyArrow.scrollFactor.set();

            babyArrow.setPosition(babyArrow.x - (babyArrow.width * 1.4), babyArrow.y - (10 + (babyArrow.height / 2)));
            babyArrow.alpha = 0;

            FlxTween.tween(babyArrow, {y: babyArrow.y + 10, alpha: 1}, 1, {ease: FlxEase.circOut, startDelay: 0.2 + (0.2 * i)});

            babyArrow.ID = i;

            babyArrow.animation.play('static');
            arrow_Group.add(babyArrow);
            text_Group.add(new FlxText(babyArrow.x + 40, babyArrow.y + 40, babyArrow.width, controlsLmao[i],36));
        }
    }
}