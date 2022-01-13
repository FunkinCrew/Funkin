package substates;

import states.LoadingState;
import flixel.graphics.frames.FlxAtlasFrames;
import lime.utils.Assets;
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

class UISkinSelect extends MusicBeatSubstate
{
    var key_Count:Int = 4;
    var arrow_Group:FlxTypedGroup<FlxSprite> = new FlxTypedGroup<FlxSprite>();
    var ui_Skin:String = utilities.Options.getData("uiSkin");

    public var ui_Settings:Array<String> = CoolUtil.coolTextFile(Paths.txt("ui skins/" + utilities.Options.getData("uiSkin") + "/config"));
    public var ui_Skins:Array<String> = CoolUtil.coolTextFile(Paths.txt("uiSkinList"));

    public var mania_gap:Array<String>;
    public var mania_size:Array<String>;
    public var mania_offset:Array<String>;

    var current_UI_Skin:FlxText;
    var bg:FlxSprite;

    var leaving = false;

    var curSelected:Int = 0;

    public function new()
    {
        super();
        
        bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
        bg.alpha = 0;
        bg.scrollFactor.set();
        add(bg);

        current_UI_Skin = new FlxText(0, 50, 0, "Selected Skin: > " + ui_Skin + " <", 32, true);
        current_UI_Skin.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
        current_UI_Skin.screenCenter(X);
        add(current_UI_Skin);

        FlxTween.tween(bg, {alpha: 0.5}, 1, {ease: FlxEase.circOut, startDelay: 0});

        #if PRELOAD_ALL
        create_Arrows();

        add(arrow_Group);

        curSelected = ui_Skins.indexOf(ui_Skin);
        #else
        leaving = true;

        Assets.loadLibrary("shared").onComplete(function (_) {
            leaving = false;

            create_Arrows();
            add(arrow_Group);
            curSelected = ui_Skins.indexOf(ui_Skin);
        });
        #end
    }

    override function update(elapsed:Float) {
        super.update(elapsed);

        var left = controls.LEFT_P;
		var right = controls.RIGHT_P;
		var accepted = controls.ACCEPT;
        var back = controls.BACK;

        if(back && !leaving)
        {
            leaving = true;

            FlxG.save.flush();

            FlxTween.tween(bg, {alpha: 0}, 0.4, {ease: FlxEase.circOut, startDelay: 0,
                onUpdate: function(tween:FlxTween) {
                    for(x in arrow_Group.members)
                    {
                        x.alpha = bg.alpha;
                    }

                    current_UI_Skin.alpha = bg.alpha;
                },
                onComplete: function(tween:FlxTween) {
                    FlxG.state.closeSubState();
                }
            });
        }

        if(left || right && !leaving)
        {
            if(left)
                curSelected--;
            if(right)
                curSelected++;

            if (curSelected < 0)
                curSelected = ui_Skins.length - 1;

            if (curSelected >= ui_Skins.length)
                curSelected = 0;

            ui_Skin = ui_Skins[curSelected];

            create_Arrows();

            current_UI_Skin.text = "Selected Skin: > " + ui_Skin + " <";
        }

        if(accepted && !leaving)
            utilities.Options.setData(ui_Skin, "uiSkin");
    }

    function create_Arrows(?new_Key_Count = 4)
    {
        ui_Settings = CoolUtil.coolTextFile(Paths.txt("ui skins/" + ui_Skin + "/config"));
        mania_size = CoolUtil.coolTextFile(Paths.txt("ui skins/" + ui_Skin + "/maniasize"));
		mania_offset = CoolUtil.coolTextFile(Paths.txt("ui skins/" + ui_Skin + "/maniaoffset"));

        if(Assets.exists(Paths.txt("ui skins/" + ui_Skin + "/maniagap")))
			mania_gap = CoolUtil.coolTextFile(Paths.txt("ui skins/" + ui_Skin + "/maniagap"));
		else
			mania_gap = CoolUtil.coolTextFile(Paths.txt("ui skins/default/maniagap"));

        if(new_Key_Count != null)
            key_Count = new_Key_Count;

        for(x in arrow_Group.members)
        {
            x.kill();
            x.destroy();
        }

        arrow_Group.clear();

        Note.swagWidth = 160 * 0.7;

        var arrow_Tex:FlxAtlasFrames;

        arrow_Tex = Paths.getSparrowAtlas('ui skins/' + ui_Skin + "/arrows/default", 'shared');

		for (i in 0...key_Count)
        {
            var babyArrow:FlxSprite = new FlxSprite(0, FlxG.height / 2);

            babyArrow.frames = arrow_Tex;

            babyArrow.antialiasing = ui_Settings[3] == "true";

			babyArrow.setGraphicSize(Std.int((babyArrow.width * Std.parseFloat(ui_Settings[0])) * (Std.parseFloat(ui_Settings[2]) - (Std.parseFloat(mania_size[4 - 1])))));
			babyArrow.updateHitbox();

            babyArrow.screenCenter(X);
            babyArrow.x += (babyArrow.width + (2 + Std.parseFloat(mania_gap[4 - 1]))) * Math.abs(i) + Std.parseFloat(mania_offset[4 - 1]);

            var animation_Base_Name = NoteVariables.Note_Count_Directions[key_Count - 1][Std.int(Math.abs(i))].toLowerCase();

            babyArrow.animation.addByPrefix('static', animation_Base_Name + " static");
            babyArrow.animation.addByPrefix('pressed', NoteVariables.Other_Note_Anim_Stuff[key_Count - 1][i] + ' press', 24, false);
            babyArrow.animation.addByPrefix('confirm', NoteVariables.Other_Note_Anim_Stuff[key_Count - 1][i] + ' confirm', 24, false);

            babyArrow.scrollFactor.set();

            babyArrow.setPosition(babyArrow.x - (babyArrow.width * 1.4), babyArrow.y - (10 + (babyArrow.height / 2)));
            babyArrow.alpha = 0;

            FlxTween.tween(babyArrow, {y: babyArrow.y + 10, alpha: 1}, 1, {ease: FlxEase.circOut, startDelay: 0.2});

            babyArrow.ID = i;

            babyArrow.animation.play('static');
            arrow_Group.add(babyArrow);
        }

        var rating_List:Array<String> = ['marvelous', 'sick', 'good', 'bad', 'shit'];

        for(i in 0...rating_List.length)
        {
            var rating = new FlxSprite(50, 180 + (i * 100));

            rating.loadGraphic(Paths.image("ui skins/" + ui_Skin + "/ratings/" + rating_List[i], 'shared'));

            rating.y -= 10;
            rating.alpha = 0;
            FlxTween.tween(rating, {y: rating.y + 10, alpha: 1}, 1, {ease: FlxEase.circOut, startDelay: 0.2});

            rating.setGraphicSize(Std.int(rating.width * Std.parseFloat(ui_Settings[0]) * Std.parseFloat(ui_Settings[4])));
            rating.antialiasing = ui_Settings[3] == "true";
            rating.updateHitbox();

            arrow_Group.add(rating);
        }

        var combo = new FlxSprite(900, 180);

        combo.loadGraphic(Paths.image("ui skins/" + ui_Skin + "/ratings/combo", 'shared'));

        combo.y -= 10;
        combo.alpha = 0;
        FlxTween.tween(combo, {y: combo.y + 10, alpha: 1}, 1, {ease: FlxEase.circOut, startDelay: 0.2});

        combo.setGraphicSize(Std.int(combo.width * Std.parseFloat(ui_Settings[0]) * Std.parseFloat(ui_Settings[4])));
        combo.antialiasing = ui_Settings[3] == "true";
        combo.updateHitbox();

        arrow_Group.add(combo);

        for(i in 0...10)
        {
            var number = new FlxSprite(930 + ((i % 3) * 60), 330 + ((Math.floor(i / 3)) * 75));

            number.loadGraphic(Paths.image("ui skins/" + ui_Skin + "/numbers/num" + i, 'shared'));

            number.setGraphicSize(Std.int(number.width * Std.parseFloat(ui_Settings[1])));
			number.antialiasing = ui_Settings[3] == "true";
			number.updateHitbox();

            number.y -= 10;
            number.alpha = 0;
            FlxTween.tween(number, {y: number.y + 10, alpha: 1}, 1, {ease: FlxEase.circOut, startDelay: 0.2});

            arrow_Group.add(number);
        }
    }
}