package debuggers;

import flixel.addons.ui.FlxUIInputText;
import flixel.addons.ui.FlxUINumericStepper;
import flixel.addons.ui.FlxUITabMenu;
import openfl.events.IOErrorEvent;
import openfl.events.Event;
import openfl.net.FileReference;
import flixel.FlxSprite;
import flixel.FlxObject;
import game.Conductor;
import flixel.math.FlxMath;
import states.OptionsMenu;
import game.Character;
import ui.FlxUIDropDownMenuCustom;
import states.MusicBeatState;
import utilities.CoolUtil;
import game.StageGroup;
import flixel.util.FlxColor;
import flixel.text.FlxText;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.addons.ui.FlxUIDropDownMenu;
import flixel.ui.FlxButton;
import haxe.Json;

using StringTools;

class StageMakingState extends MusicBeatState
{
    var _file:FileReference;
    
    /* STAGE STUFF */
    public var stages:Array<String>;

    public var stage_Name:String = 'stage';
    private var stage:StageGroup;

    private var stageObjectPos:Array<FlxSprite> = [];

    public var stageData:StageData;

    private var bfChar:String = "bf";
    private var gfChar:String = "gf";
    private var dadChar:String = "dad";

    public var bf:Character;
    public var gf:Character;
    public var dad:Character;

    public var bf_Pos:FlxSprite;
    public var gf_Pos:FlxSprite;
    public var dad_Pos:FlxSprite;

    private var selectedThing:Bool = false;
    private var selected:Dynamic;

    private var objects:Array<Array<Dynamic>> = [];
    private var selectedObject:Int = 0;

    /* UI */
    private var json_Button:FlxButton;
    private var stage_Dropdown:FlxUIDropDownMenuCustom;
    private var object_Dropdown:FlxUIDropDownMenuCustom;
    private var cam_Zoom:FlxText;

    private var stage_Label:FlxText;
    private var sprite_Label:FlxText;

    private var xStepper:FlxUINumericStepper;
    private var x_Label:FlxText;

    private var yStepper:FlxUINumericStepper;
    private var y_Label:FlxText;

    private var charDropDown:FlxUIDropDownMenuCustom;

    private var scaleStepper:FlxUINumericStepper;
    private var scale_Label:FlxText;

    private var alphaStepper:FlxUINumericStepper;
    private var alpha_Label:FlxText;

    private var fileInput:FlxUIInputText;
    private var file_Label:FlxText;

    private var scrollStepper:FlxUINumericStepper;
    private var scroll_Label:FlxText;

    private var UI_box:FlxUITabMenu;

    private var startY:Int = 50;
    private var zoom:Float;

    /* CAMERA */
    private var stageCam:FlxCamera;
    private var camHUD:FlxCamera;

    private var camFollow:FlxObject;

    public function new(selectedStage:String)
    {
        super();

        stages = CoolUtil.coolTextFile(Paths.txt('stageList'));

        if(selectedStage != null)
            stage_Name = selectedStage;

        FlxG.mouse.visible = true;
    }

    override public function create()
    {
        FlxG.mouse.visible = true;

        stageCam = new FlxCamera();
        camHUD = new FlxCamera();
        camHUD.bgColor.alpha = 0;

		FlxG.cameras.reset(stageCam);
		FlxG.cameras.add(camHUD, false);

		FlxG.cameras.setDefaultDrawTarget(stageCam, true);

		FlxG.camera = stageCam;

        bf = new Character(0, 0, bfChar, true);

        gf = new Character(0, 0, gfChar);
        gf.scrollFactor.set(0.95, 0.95);

        dad = new Character(0, 0, dadChar);

        UI_box = new FlxUITabMenu(null, [], false);

		UI_box.resize(300, 400);
		UI_box.x = 10;
		UI_box.y = startY;
        UI_box.scrollFactor.set();
        UI_box.cameras = [camHUD];

        stage_Label = new FlxText(20, startY + 10, 0, "Stage Settings", 12);
        stage_Label.scrollFactor.set();
        stage_Label.cameras = [camHUD];

        stage_Dropdown = new FlxUIDropDownMenuCustom(20, stage_Label.y + stage_Label.height + 4, FlxUIDropDownMenu.makeStrIdLabelArray(stages, true), function(stageName:String)
        {
            stage_Name = stages[Std.parseInt(stageName)];
            reloadStage();
        });

        stage_Dropdown.selectedLabel = stage_Name;
        stage_Dropdown.scrollFactor.set();
        stage_Dropdown.cameras = [camHUD];

        cam_Zoom = new FlxText(10, 0, 0, "Camera Zoom: " + stageCam.zoom, 24);
        cam_Zoom.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        cam_Zoom.scrollFactor.set();
        cam_Zoom.cameras = [camHUD];

        json_Button = new FlxButton(stage_Dropdown.x + stage_Dropdown.width + 4, stage_Dropdown.y, "Save JSON", function() {
            saveLevel();
        });
        json_Button.scrollFactor.set();
        json_Button.cameras = [camHUD];

        sprite_Label = new FlxText(20, json_Button.y + json_Button.height + 4, 0, "Sprite Settings", 12);
        sprite_Label.scrollFactor.set();
        sprite_Label.cameras = [camHUD];

        xStepper = new FlxUINumericStepper(20, sprite_Label.y + sprite_Label.height + 4, 1, 0, -100000, 100000, 1);
		xStepper.value = 0;
        xStepper.name = "x_stepper";
        xStepper.scrollFactor.set();
        xStepper.cameras = [camHUD];

        x_Label = new FlxText(xStepper.x + xStepper.width + 2, xStepper.y - 2, 0, "X", 10);
        x_Label.scrollFactor.set();
        x_Label.cameras = [camHUD];

        yStepper = new FlxUINumericStepper(x_Label.x + x_Label.width + 2, xStepper.y, 1, 0, -100000, 100000, 1);
		yStepper.value = 0;
        yStepper.name = "y_stepper";
        yStepper.scrollFactor.set();
        yStepper.cameras = [camHUD];

        y_Label = new FlxText(yStepper.x + yStepper.width + 2, yStepper.y - 2, 0, "Y", 10);
        y_Label.scrollFactor.set();
        y_Label.cameras = [camHUD];

        scaleStepper = new FlxUINumericStepper(20, y_Label.y + y_Label.height + 4, 0.05, 0, 0.1, 100, 2);
		scaleStepper.value = 0;
        scaleStepper.name = "scale_stepper";
        scaleStepper.scrollFactor.set();
        scaleStepper.cameras = [camHUD];

        scale_Label = new FlxText(scaleStepper.x + scaleStepper.width + 2, scaleStepper.y - 2, 0, "Scale", 10);
        scale_Label.scrollFactor.set();
        scale_Label.cameras = [camHUD];

        alphaStepper = new FlxUINumericStepper(scale_Label.x + scale_Label.width + 2, scaleStepper.y, 0.05, 0, 0, 1, 2);
		alphaStepper.value = 0;
        alphaStepper.name = "alpha_stepper";
        alphaStepper.scrollFactor.set();
        alphaStepper.cameras = [camHUD];

        alpha_Label = new FlxText(alphaStepper.x + alphaStepper.width + 2, alphaStepper.y - 2, 0, "Alpha", 10);
        alpha_Label.scrollFactor.set();
        alpha_Label.cameras = [camHUD];

        fileInput = new FlxUIInputText(20, scaleStepper.y + scaleStepper.height + 2, 70, "", 8);
        fileInput.scrollFactor.set();
        fileInput.cameras = [camHUD];

        file_Label = new FlxText(fileInput.x + fileInput.width + 2, fileInput.y - 2, 0, "File Name", 10);
        file_Label.scrollFactor.set();
        file_Label.cameras = [camHUD];

        scrollStepper = new FlxUINumericStepper(fileInput.x, fileInput.y + fileInput.height + 2, 0.05, 0, 0, 10, 2);
		scrollStepper.value = 0;
        scrollStepper.name = "scroll_stepper";
        scrollStepper.scrollFactor.set();
        scrollStepper.cameras = [camHUD];

        scroll_Label = new FlxText(scrollStepper.x + scrollStepper.width + 2, scrollStepper.y - 2, 0, "Scroll Factor", 10);
        scroll_Label.scrollFactor.set();
        scroll_Label.cameras = [camHUD];

        var characterData:Array<String> = CoolUtil.coolTextFile(Paths.txt('characterList'));

        var chars:Array<String> = ["bf", "gf", ""];

		for(item in characterData)
		{
			var characterDataVal:Array<String> = item.split(":");
			var charName:String = characterDataVal[0];
			chars.push(charName);
		}

        charDropDown = new FlxUIDropDownMenuCustom(y_Label.x + y_Label.width + 2, yStepper.y - 2, FlxUIDropDownMenu.makeStrIdLabelArray(chars, true), function(character:String)
        {
            var daChar = chars[Std.parseInt(character)];

            if(selected == bf_Pos)
            {
                remove(bf);
                bf.kill();
                bf.destroy();

                bf = new Character(0, 0, daChar, true);

                if(bf.otherCharacters == null)
                {
                    if(bf.coolTrail != null)
                        add(bf.coolTrail);
        
                    add(bf);
                }
                else
                {
                    for(character in bf.otherCharacters)
                    {
                        if(character.coolTrail != null)
                            add(character.coolTrail);
                        
                        add(character);
                    }
                }

                stage.setCharOffsets(bf, gf, dad);
            }
            else if(selected == gf_Pos)
            {
                remove(gf);
                gf.kill();
                gf.destroy();

                gf = new Character(0, 0, daChar, false);

                if(gf.otherCharacters == null)
                {
                    if(gf.coolTrail != null)
                        add(gf.coolTrail);
        
                    add(gf);
                }
                else
                {
                    for(character in gf.otherCharacters)
                    {
                        if(character.coolTrail != null)
                            add(character.coolTrail);
                        
                        add(character);
                    }
                }

                stage.setCharOffsets(bf, gf, dad);
            }
            else if(selected == dad_Pos)
            {
                remove(dad);
                dad.kill();
                dad.destroy();

                dad = new Character(0, 0, daChar, false);

                if(dad.otherCharacters == null)
                {
                    if(dad.coolTrail != null)
                        add(dad.coolTrail);
        
                    add(dad);
                }
                else
                {
                    for(character in dad.otherCharacters)
                    {
                        if(character.coolTrail != null)
                            add(character.coolTrail);
                        
                        add(character);
                    }
                }

                stage.setCharOffsets(bf, gf, dad);
            }
        });

        charDropDown.scrollFactor.set();
        charDropDown.cameras = [camHUD];

        camFollow = new FlxObject(0, 0, 2, 2);
		camFollow.screenCenter();

        FlxG.camera.follow(camFollow);

        reloadStage();

        bf_Pos = new FlxSprite(stage.player_1_Point.x, stage.player_1_Point.y);
        bf_Pos.makeGraphic(32, 32, FlxColor.RED);
        bf_Pos.updateHitbox();

        gf_Pos = new FlxSprite(stage.gf_Point.x, stage.gf_Point.y);
        gf_Pos.makeGraphic(32, 32, FlxColor.RED);
        gf_Pos.updateHitbox();

        dad_Pos = new FlxSprite(stage.player_2_Point.x, stage.player_2_Point.y);
        dad_Pos.makeGraphic(32, 32, FlxColor.RED);
        dad_Pos.updateHitbox();

        add(bf_Pos);
        add(gf_Pos);
        add(dad_Pos);
    }

    override function getEvent(id:String, sender:Dynamic, data:Dynamic, ?params:Array<Dynamic>)
    {
        if(id == FlxUINumericStepper.CHANGE_EVENT && (sender is FlxUINumericStepper))
        {
            var nums:FlxUINumericStepper = cast sender;
			var wname = nums.name;

            switch(wname)
			{
				case 'x_stepper':
					if(selectedObject != 0 || selected == bf_Pos || selected == dad_Pos || selected == gf_Pos)
                    {
                        selected.x = nums.value;

                        if(selected == bf_Pos || selected == dad_Pos || selected == gf_Pos)
                        {
                            if(selected == bf_Pos)
                            {
                                stage.player_1_Point.x = selected.x;
                                stage.player_1_Point.y = selected.y;
                
                                if(stageData != null)
                                    stageData.character_Positions[0] = [stage.player_1_Point.x, stage.player_1_Point.y];
                
                                stage.setCharOffsets(bf, gf, dad);
                            }
                            else if(selected == gf_Pos)
                            {
                                stage.gf_Point.x = selected.x;
                                stage.gf_Point.y = selected.y;
                
                                if(stageData != null)
                                    stageData.character_Positions[2] = [stage.gf_Point.x, stage.gf_Point.y];
                
                                stage.setCharOffsets(bf, gf, dad);
                            }
                            else if(selected == dad_Pos)
                            {
                                stage.player_2_Point.x = selected.x;
                                stage.player_2_Point.y = selected.y;
                
                                if(stageData != null)
                                    stageData.character_Positions[1] = [stage.player_2_Point.x, stage.player_2_Point.y];
                
                                stage.setCharOffsets(bf, gf, dad);
                            }
                        }
                        else
                        {
                            if(stageData != null)
                                stageData.objects[selectedObject - 1].position = [selected.x, selected.y];
                        }
                    }
                case 'y_stepper':
                    if(selectedObject != 0 || selected == bf_Pos || selected == dad_Pos || selected == gf_Pos)
                    {
                        selected.y = nums.value;

                        if(selected == bf_Pos || selected == dad_Pos || selected == gf_Pos)
                        {
                            if(selected == bf_Pos)
                            {
                                stage.player_1_Point.x = selected.x;
                                stage.player_1_Point.y = selected.y;
                
                                if(stageData != null)
                                    stageData.character_Positions[0] = [stage.player_1_Point.x, stage.player_1_Point.y];
                
                                stage.setCharOffsets(bf, gf, dad);
                            }
                            else if(selected == gf_Pos)
                            {
                                stage.gf_Point.x = selected.x;
                                stage.gf_Point.y = selected.y;
                
                                if(stageData != null)
                                    stageData.character_Positions[2] = [stage.gf_Point.x, stage.gf_Point.y];
                
                                stage.setCharOffsets(bf, gf, dad);
                            }
                            else if(selected == dad_Pos)
                            {
                                stage.player_2_Point.x = selected.x;
                                stage.player_2_Point.y = selected.y;
                
                                if(stageData != null)
                                    stageData.character_Positions[1] = [stage.player_2_Point.x, stage.player_2_Point.y];
                
                                stage.setCharOffsets(bf, gf, dad);
                            }
                        }
                        else
                        {
                            if(stageData != null)
                                stageData.objects[selectedObject - 1].position = [selected.x, selected.y];
                        }
                    }
                case 'scale_stepper':
                    if(selectedObject != 0 && !(selected == bf_Pos || selected == dad_Pos || selected == gf_Pos))
                    {
                        var Object = stageData.objects[selectedObject - 1];
                        var Sprite:Dynamic = objects[selectedObject - 1][1];

                        if(Object.updateHitbox || Object.updateHitbox == null)
                        {
                            if(Object.uses_Frame_Width)
                                Sprite.setGraphicSize(Std.int(Sprite.frameWidth / Object.scale));
                            else
                                Sprite.setGraphicSize(Std.int(Sprite.width / Object.scale));
                        }

                        if(Object.updateHitbox || Object.updateHitbox == null)
                            Sprite.updateHitbox();

                        if(Object.uses_Frame_Width)
                            Sprite.setGraphicSize(Std.int(Sprite.frameWidth * nums.value));
                        else
                            Sprite.setGraphicSize(Std.int(Sprite.width * nums.value));

                        if(Object.updateHitbox || Object.updateHitbox == null)
                            Sprite.updateHitbox();

                        stageData.objects[selectedObject - 1].scale = nums.value;
                    }
                case 'alpha_stepper':
                    if(selectedObject != 0 || selected == bf_Pos || selected == dad_Pos || selected == gf_Pos)
                    {
                        if(!(selected == bf_Pos || selected == dad_Pos || selected == gf_Pos))
                            Reflect.setProperty(stage.stage_Objects[selectedObject - 1][1], "alpha", nums.value);
                        else
                        {
                            if(selected == bf_Pos)
                                bf.alpha = nums.value;
                            else if(selected == gf_Pos)
                                gf.alpha = nums.value;
                            else if(selected == dad_Pos)
                                dad.alpha = nums.value;
                        }

                        if(!(selected == bf_Pos || selected == dad_Pos || selected == gf_Pos))
                            stageData.objects[selectedObject - 1].alpha = nums.value;
                    }
                case 'scroll_stepper':
                    if(selectedObject != 0 && !(selected == bf_Pos || selected == dad_Pos || selected == gf_Pos))
                    {
                        var cool:Dynamic = stage.stage_Objects[selectedObject - 1][1];

                        cool.scrollFactor.set(nums.value, nums.value);

                        stageData.objects[selectedObject - 1].scroll_Factor = [nums.value, nums.value];
                    }
                    else if((selected == bf_Pos || selected == dad_Pos || selected == gf_Pos))
                    {
                        if(stageData.character_Scrolls == null)
                            stageData.character_Scrolls = [1,1,0.95];

                        if(selected == bf_Pos)
                        {
                            stageData.character_Scrolls[0] = nums.value;
                            stage.p1_Scroll = nums.value;
                            bf.scrollFactor.set(nums.value, nums.value);
                        }

                        if(selected == dad_Pos)
                        {
                            stageData.character_Scrolls[1] = nums.value;
                            stage.p2_Scroll = nums.value;
                            dad.scrollFactor.set(nums.value, nums.value);
                        }

                        if(selected == gf_Pos)
                        {
                            stageData.character_Scrolls[2] = nums.value;
                            stage.gf_Scroll = nums.value;
                            gf.scrollFactor.set(nums.value, nums.value);
                        }
                    }
			}
        }
    }

    var prevFileName:String = "";

    override public function update(elapsed:Float) {
        super.update(elapsed);

        if(selectedObject != 0)
        {
            if(prevFileName != fileInput.text)
            {
                stageData.objects[selectedObject - 1].file_Name = fileInput.text;
    
                if(selectedObject != 0 && !(selected == bf_Pos || selected == dad_Pos || selected == gf_Pos))
                {
                    var Object:StageObject = stageData.objects[selectedObject - 1];
                    var Sprite:Dynamic = objects[selectedObject - 1][1];
    
                    if(Object.updateHitbox || Object.updateHitbox == null)
                    {
                        if(Object.uses_Frame_Width)
                            Sprite.setGraphicSize(Std.int(Sprite.frameWidth / Object.scale));
                        else
                            Sprite.setGraphicSize(Std.int(Sprite.width / Object.scale));
                    }
    
                    if(Object.updateHitbox || Object.updateHitbox == null)
                        Sprite.updateHitbox();
    
                    if(Object.is_Animated)
                    {
                        Sprite.frames = Paths.getSparrowAtlas(stage_Name + "/" + fileInput.text, "stages");
    
                        for(Animation in Object.animations)
                        {
                            var Anim_Name = Animation.name;
    
                            @:privateAccess
                            if(Animation.name == "beatHit")
                                stage.onBeatHit_Group.add(Sprite);
    
                            Sprite.animation.addByPrefix(
                                Anim_Name,
                                Animation.animation_name,
                                Animation.fps,
                                Animation.looped
                            );
                        }
    
                        if(Object.start_Animation != "" && Object.start_Animation != null && Object.start_Animation != "null")
                            Sprite.animation.play(Object.start_Animation);
                    }
                    else
                        Sprite.loadGraphic(Paths.image(stage_Name + "/" + fileInput.text, "stages"));
    
                    if(Object.updateHitbox || Object.updateHitbox == null)
                        Sprite.updateHitbox();
    
                    if(Object.uses_Frame_Width)
                        Sprite.setGraphicSize(Std.int(Sprite.frameWidth * Object.scale));
                    else
                        Sprite.setGraphicSize(Std.int(Sprite.width * Object.scale));
    
                    if(Object.updateHitbox || Object.updateHitbox == null)
                        Sprite.updateHitbox();
                }
            }
        }

        prevFileName = fileInput.text;

        if(FlxG.mouse.overlaps(bf_Pos) && FlxG.mouse.pressed && !selectedThing)
        {
            selectedThing = true;
            selected = bf_Pos;

            xStepper.value = selected.x;
            yStepper.value = selected.y;
            alphaStepper.value = bf.alpha;
            scrollStepper.value = bf.scrollFactor.x;

            selectedObject = 0;
        }
        else if(FlxG.mouse.overlaps(gf_Pos) && FlxG.mouse.pressed && !selectedThing)
        {
            selectedThing = true;
            selected = gf_Pos;

            xStepper.value = selected.x;
            yStepper.value = selected.y;
            alphaStepper.value = gf.alpha;
            scrollStepper.value = gf.scrollFactor.x;

            selectedObject = 0;
        }
        else if(FlxG.mouse.overlaps(dad_Pos) && FlxG.mouse.pressed && !selectedThing)
        {
            selectedThing = true;
            selected = dad_Pos;

            xStepper.value = selected.x;
            yStepper.value = selected.y;
            alphaStepper.value = dad.alpha;
            scrollStepper.value = dad.scrollFactor.x;

            selectedObject = 0;
        }
        else if(FlxG.mouse.pressed && !selectedThing)
        {
            for(spriteIndex in 0...stageObjectPos.length)
            {
                var sprite = stageObjectPos[spriteIndex];

                if(FlxG.mouse.overlaps(sprite) && FlxG.mouse.pressed && !selectedThing)
                {
                    selectedObject = spriteIndex + 1;
                    
                    selectedThing = true;
                    selected = sprite;
                    
                    xStepper.value = selected.x;
                    yStepper.value = selected.y;

                    var cool:Dynamic = objects[spriteIndex][1];
                    
                    alphaStepper.value = cool.alpha;
                    scrollStepper.value = cool.scrollFactor.x;
                }
            }
        }
        else if(!FlxG.mouse.pressed)
            selectedThing = false;

        if(FlxG.mouse.pressed && selectedThing)
        {
            selected.x = FlxG.mouse.x - selected.frameWidth / 2;
            selected.y = FlxG.mouse.y - selected.frameHeight / 2;

            xStepper.value = selected.x;
            yStepper.value = selected.y;

            alphaStepper.value = selected.alpha;
            scrollStepper.value = selected.scrollFactor.x;

            if(selected == bf_Pos)
            {
                stage.player_1_Point.x = selected.x;
                stage.player_1_Point.y = selected.y;

                if(stageData != null)
                    stageData.character_Positions[0] = [stage.player_1_Point.x, stage.player_1_Point.y];

                stage.setCharOffsets(bf, gf, dad);
            }
            else if(selected == gf_Pos)
            {
                stage.gf_Point.x = selected.x;
                stage.gf_Point.y = selected.y;

                if(stageData != null)
                    stageData.character_Positions[2] = [stage.gf_Point.x, stage.gf_Point.y];

                stage.setCharOffsets(bf, gf, dad);
            }
            else if(selected == dad_Pos)
            {
                stage.player_2_Point.x = selected.x;
                stage.player_2_Point.y = selected.y;

                if(stageData != null)
                    stageData.character_Positions[1] = [stage.player_2_Point.x, stage.player_2_Point.y];

                stage.setCharOffsets(bf, gf, dad);
            }
            else
            {
                if(stageData != null)
                {
                    stageData.objects[selectedObject - 1].position = [selected.x, selected.y];

                    var coolMan:Dynamic = objects[selectedObject - 1][1];

                    coolMan.setPosition(selected.x, selected.y);

                    alphaStepper.value = coolMan.alpha;

                    scaleStepper.value = stageData.objects[selectedObject - 1].scale;

                    scrollStepper.value = coolMan.scrollFactor.x;

                    fileInput.text = stageData.objects[selectedObject - 1].file_Name;
                }
            }
        }

        for(spriteIndex in 0...stageObjectPos.length) {
            var sprite = stageObjectPos[spriteIndex];

            if(stageData.objects[spriteIndex].scroll_Factor != null)
                sprite.scrollFactor.set(stageData.objects[spriteIndex].scroll_Factor[0], stageData.objects[spriteIndex].scroll_Factor[1]);
        }

        bf_Pos.setPosition(stage.player_1_Point.x, stage.player_1_Point.y);
        gf_Pos.setPosition(stage.gf_Point.x, stage.gf_Point.y);
        dad_Pos.setPosition(stage.player_2_Point.x, stage.player_2_Point.y);

        if(bf != null)
            bf_Pos.scrollFactor.set(bf.scrollFactor.x, bf.scrollFactor.y);

        if(gf != null)
            gf_Pos.scrollFactor.set(gf.scrollFactor.x, gf.scrollFactor.y);

        if(dad != null)
            dad_Pos.scrollFactor.set(dad.scrollFactor.x, dad.scrollFactor.y);

        var shiftThing:Int = FlxG.keys.pressed.SHIFT ? 5 : 1;

        if(!fileInput.hasFocus)
        {
            if(FlxG.keys.pressed.I || FlxG.keys.pressed.J || FlxG.keys.pressed.K || FlxG.keys.pressed.L)
            {
                if (FlxG.keys.pressed.I)
                    camFollow.velocity.y = -90 * shiftThing;
                else if (FlxG.keys.pressed.K)
                    camFollow.velocity.y = 90 * shiftThing;
                else
                    camFollow.velocity.y = 0;
    
                if (FlxG.keys.pressed.J)
                    camFollow.velocity.x = -90 * shiftThing;
                else if (FlxG.keys.pressed.L)
                    camFollow.velocity.x = 90 * shiftThing;
                else
                    camFollow.velocity.x = 0;
            }
            else
            {
                camFollow.velocity.set();
            }
        }

        if(FlxG.sound.music != null)
			Conductor.songPosition = FlxG.sound.music.time;

        // camera movement zoom
        if(!fileInput.hasFocus)
        {
            if(FlxG.keys.justPressed.E)
                stageCam.zoom += 0.1;

            if(FlxG.keys.justPressed.Q)
                stageCam.zoom -= 0.1;

            if(FlxG.keys.justPressed.ESCAPE)
                FlxG.switchState(new OptionsMenu());
        }

        // zoom lock
        if(stageCam.zoom < 0.1)
            stageCam.zoom = 0.1;

        // da math
        zoom = FlxMath.roundDecimal(stageCam.zoom, 1);

        cam_Zoom.text = 'Camera Zoom: $zoom\nIJKL to move camera\nE and Q to zoom\nSHIFT for faster camera\n';
        cam_Zoom.x = FlxG.width - cam_Zoom.width - 2;
    }

    function reloadStage()
    {
        objects = [];
        stageObjectPos = [];
        selectedObject = 0;

        clear();

        add(camFollow);

        stage = new StageGroup(stage_Name);
        add(stage);

        @:privateAccess
        stageData = stage.stage_Data;

        stage.setCharOffsets(bf, gf, dad);

        if(gf.otherCharacters == null)
        {
            if(gf.coolTrail != null)
                add(gf.coolTrail);

            add(gf);
        }
        else
        {
            for(character in gf.otherCharacters)
            {
                if(character.coolTrail != null)
                    add(character.coolTrail);
                
                add(character);
            }
        }

        add(stage.infrontOfGFSprites);

        if(dad.otherCharacters == null)
        {
            if(dad.coolTrail != null)
                add(dad.coolTrail);

            add(dad);
        }
        else
        {
            for(character in dad.otherCharacters)
            {
                if(character.coolTrail != null)
                    add(character.coolTrail);

                add(character);
            }
        }

        if(bf.otherCharacters == null)
        {
            if(bf.coolTrail != null)
                add(bf.coolTrail);
            
            add(bf);
        }
        else
        {
            for(character in bf.otherCharacters)
            {
                if(character.coolTrail != null)
                    add(character.coolTrail);

                add(character);
            }
        }

        add(stage.foregroundSprites);

        add(bf_Pos);
        add(gf_Pos);
        add(dad_Pos);

        for(objectArray in stage.stage_Objects)
        {
            objects.push([objectArray[0], objectArray[1]]);

            var sprite = objectArray[1];

            var pos = new FlxSprite(sprite.x, sprite.y);
            pos.makeGraphic(32, 32, FlxColor.RED);
            add(pos);

            stageObjectPos.push(pos);
        }

        add(UI_box);

        add(stage_Label);

        add(cam_Zoom);
        add(json_Button);

        add(sprite_Label);

        add(xStepper);
        add(x_Label);

        add(yStepper);
        add(y_Label);

        add(scaleStepper);
        add(scale_Label);

        add(alphaStepper);
        add(alpha_Label);

        add(fileInput);
        add(file_Label);

        add(scrollStepper);
        add(scroll_Label);

        add(charDropDown);
        add(stage_Dropdown);
    }

    override function beatHit()
    {
        super.beatHit();

        stage.beatHit();

        if(bf.otherCharacters == null)
            bf.dance();
        else
        {
            for(character in bf.otherCharacters)
            {
                character.dance();
            }
        }

        if(dad.otherCharacters == null)
            dad.dance();
        else
        {
            for(character in dad.otherCharacters)
            {
                character.dance();
            }
        }

        if(gf.otherCharacters == null)
            gf.dance();
        else
        {
            for(character in gf.otherCharacters)
            {
                character.dance();
            }
        }
    }

    private function saveLevel()
    {
        var data:String = Json.stringify(stageData, null, "\t");

        if ((data != null) && (data.length > 0))
        {
            _file = new FileReference();
            _file.addEventListener(Event.COMPLETE, onSaveComplete);
            _file.addEventListener(Event.CANCEL, onSaveCancel);
            _file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);

            _file.save(data.trim(), stage_Name + ".json");
        }
    }

    function onSaveComplete(_):Void
    {
        _file.removeEventListener(Event.COMPLETE, onSaveComplete);
        _file.removeEventListener(Event.CANCEL, onSaveCancel);
        _file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
        _file = null;
        FlxG.log.notice("Successfully saved LEVEL DATA.");
    }

    /**
        * Called when the save file dialog is cancelled.
        */
    function onSaveCancel(_):Void
    {
        _file.removeEventListener(Event.COMPLETE, onSaveComplete);
        _file.removeEventListener(Event.CANCEL, onSaveCancel);
        _file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
        _file = null;
    }

    /**
        * Called if there is an error while saving the gameplay recording.
        */
    function onSaveError(_):Void
    {
        _file.removeEventListener(Event.COMPLETE, onSaveComplete);
        _file.removeEventListener(Event.CANCEL, onSaveCancel);
        _file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
        _file = null;
        FlxG.log.error("Problem saving Level data");
    }
}