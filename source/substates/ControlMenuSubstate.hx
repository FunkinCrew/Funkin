package substates;

import utilities.PlayerSettings;
import openfl.events.FullScreenEvent;
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

    var coolText:FlxText = new FlxText(0,25,0,"Use LEFT and RIGHT to change number of keys\nESCAPE to save binds and exit menu\nRESET+SHIFT to Reset Binds to default\n", 32);

    var killKey:FlxSprite = new FlxSprite();
    var killBind:String = FlxG.save.data.killBind;
    var killText:FlxText = new FlxText();

    var fullscreenKey:FlxSprite = new FlxSprite();
    var fullscreenBind:String = FlxG.save.data.fullscreenBind;
    var fullscreenText:FlxText = new FlxText();

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

        setupKeySprite(fullscreenKey, -95);

        var fullscreenIcon:FlxSprite = new FlxSprite();
        fullscreenIcon.frames = Paths.getSparrowAtlas("Bind_Menu_Assets", "preload");
        fullscreenIcon.animation.addByPrefix("idle", "Fullscreen Symbol", 24);
        fullscreenIcon.animation.play("idle");
        fullscreenIcon.updateHitbox();

        fullscreenIcon.x = fullscreenKey.x + (fullscreenKey.width / 2) - (fullscreenIcon.width / 2);
        fullscreenIcon.y = fullscreenKey.y - fullscreenIcon.height - 11;

        setupKeySprite(killKey, 95);

        var killIcon:FlxSprite = new FlxSprite();
        killIcon.frames = Paths.getSparrowAtlas("Bind_Menu_Assets", "preload");
        killIcon.animation.addByPrefix("idle", "Death Icon", 24);
        killIcon.animation.play("idle");
        killIcon.updateHitbox();

        killIcon.x = killKey.x + (killKey.width / 2) - (killIcon.width / 2);
        killIcon.y = killKey.y - killIcon.height - 16;

        add(fullscreenKey);
        add(fullscreenIcon);

        fullscreenText.setFormat(Paths.font("vcr.ttf"), 38, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);

        fullscreenText.text = fullscreenBind;
        fullscreenText.x = fullscreenKey.x + (fullscreenKey.width / 2) - (fullscreenText.width / 2);
        fullscreenText.y = fullscreenKey.y;

        add(fullscreenText);

        add(killKey);
        add(killIcon);

        killText.setFormat(Paths.font("vcr.ttf"), 38, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);

        killText.text = killBind;
        killText.x = killKey.x + (killKey.width / 2) - (killText.width / 2);
        killText.y = killKey.y;

        add(killText);
    }

    override function update(elapsed:Float) {
        super.update(elapsed);

        var leftP = controls.LEFT_P;
		var rightP = controls.RIGHT_P;
        var reset = controls.RESET;
        var back = controls.BACK;
        var shift = FlxG.keys.pressed.SHIFT;

        if(reset && shift)
        {
            binds = NoteVariables.Default_Binds;
            fullscreenBind = "F11";
            killBind = "R";
        }
        
        if(back)
        {
            FlxG.save.data.binds = this.binds;
            FlxG.save.data.fullscreenBind = fullscreenBind;
            FlxG.save.data.killBind = killBind;

            FlxG.save.flush();
            PlayerSettings.player1.controls.loadKeyBinds();

            this.binds = FlxG.save.data.binds;

            FlxG.mouse.visible = false;
            FlxG.state.closeSubState();
        }

        if(FlxG.mouse.overlaps(fullscreenKey) && FlxG.mouse.justPressed && !selectingStuff)
        {
            selectedControl = -1;
            selectingStuff = true;
        }
        else if(FlxG.mouse.overlaps(fullscreenKey))
            fullscreenKey.color = FlxColor.GRAY;
        else
            fullscreenKey.color = FlxColor.WHITE;

        if(FlxG.mouse.overlaps(killKey) && FlxG.mouse.justPressed && !selectingStuff)
        {
            selectedControl = -2;
            selectingStuff = true;
        }
        else if(FlxG.mouse.overlaps(killKey))
            killKey.color = FlxColor.GRAY;
        else
            killKey.color = FlxColor.WHITE;

        for(x in arrow_Group)
        {
            if(FlxG.mouse.overlaps(x) && FlxG.mouse.justPressed && !selectingStuff)
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
            var curKey = FlxG.keys.getIsDown()[0].ID.toString();

            if(selectedControl > -1)
                this.binds[key_Count - 1][selectedControl] = curKey;
            else
            {
                switch(selectedControl)
                {
                    case -1:
                        fullscreenBind = curKey;
                    case -2:
                        killBind = curKey;
                }
            }
        }

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

        fullscreenText.text = fullscreenBind;
        fullscreenText.x = fullscreenKey.x + (fullscreenKey.width / 2) - (fullscreenText.width / 2);
        fullscreenText.y = fullscreenKey.y + (fullscreenKey.height / 2) - (fullscreenText.height / 2);

        killText.text = killBind;
        killText.x = killKey.x + (killKey.width / 2) - (killText.width / 2);
        killText.y = killKey.y + (killKey.height / 2) - (killText.height / 2);
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

            var coolText = new FlxText(babyArrow.x + (babyArrow.width / 2), babyArrow.y + coolWidth, coolWidth, binds[key_Count - 1][i], coolWidth);
            coolText.setFormat(Paths.font("vcr.ttf"), coolWidth, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);

            text_Group.add(coolText);
        }
    }

    function setupKeySprite(key:FlxSprite, ?x:Float = 0.0)
    {
        key.frames = Paths.getSparrowAtlas("Bind_Menu_Assets", "preload");
        key.animation.addByPrefix("idle", "Button", 24);
        key.animation.play("idle");
        key.updateHitbox();

        key.screenCenter(X);
        key.y = FlxG.height - key.height - 8;

        key.x += x;
    }
}