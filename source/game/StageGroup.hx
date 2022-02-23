package game;

#if polymod
import polymod.backends.PolymodAssets;
#end

#if linc_luajit
import modding.ModchartUtilities;
#end

import utilities.CoolUtil;
import lime.utils.Assets;
import haxe.Json;
import flixel.util.FlxColor;
import flixel.math.FlxPoint;
import states.PlayState;
import backgrounds.DancingSprite;
import flixel.util.FlxTimer;
import flixel.system.FlxSound;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import modding.CharacterConfig;

using StringTools;

class StageGroup extends FlxGroup
{
    public var stage:String = "stage";
    public var camZoom:Float = 1.05;
    private var goodElapse:Float = 0;

    public var player_1_Point:FlxPoint = new FlxPoint(1000, 800);
    public var player_2_Point:FlxPoint = new FlxPoint(300, 800);
    public var gf_Point:FlxPoint = new FlxPoint(600, 750);

    public var p1_Scroll:Float = 1.0;
    public var p2_Scroll:Float = 1.0;
    public var gf_Scroll:Float = 0.95;

    public var p1_Cam_Offset:FlxPoint = new FlxPoint(0,0);
    public var p2_Cam_Offset:FlxPoint = new FlxPoint(0,0);

    private var stage_Data:StageData;

    public var stage_Objects:Array<Array<Dynamic>> = [];

    // PHILLY STUFF
    private var phillyCityLights:FlxTypedGroup<FlxSprite>;
    private var phillyTrain:FlxSprite;
    private var trainSound:FlxSound;
    private var trainMoving:Bool = false;
    private var startedMoving:Bool = false;
    private var trainFinishing:Bool = false;
    private var trainFrameTiming:Float = 0;
    private var trainCars:Int = 8;
    private var trainCooldown:Int = 0;
    private var curLight:Int = 0;

    // MALL STUFF
    private var santa:FlxSprite;
    private var upperBoppers:FlxSprite;
    private var bottomBoppers:FlxSprite;

    // SCHOOL STUFF
    private var bgGirls:BackgroundGirls;

    // other

    private var onBeatHit_Group:FlxTypedGroup<FlxSprite> = new FlxTypedGroup<FlxSprite>();

    public var foregroundSprites:FlxGroup = new FlxGroup();
    public var infrontOfGFSprites:FlxGroup = new FlxGroup();

    #if linc_luajit
    public var stageScript:ModchartUtilities = null;
    #end

    public function updateStage(?newStage:String)
    {
        if(newStage != null)
            stage = newStage;

        var bruhStages = ['school','school-mad','evil-school'];

        var stagesNormally = CoolUtil.coolTextFile(Paths.txt('stageList'));

        if(stage != "")
        {
            if(!bruhStages.contains(stage) && stagesNormally.contains(stage))
            {
                var JSON_Data:String = "";
    
                JSON_Data = Assets.getText(Paths.json("stage data/" + stage)).trim();
                stage_Data = cast Json.parse(JSON_Data);
            }
        }

        clear();

        if(stage != "")
        {
            switch(stage)
            {
                case "school":
                {
                    player_2_Point.x = 379;
                    player_2_Point.y = 928;
                    gf_Point.x = 709;
                    gf_Point.y = 856;
                    player_1_Point.x = 993;
                    player_1_Point.y = 944;

                    var bgSky = new FlxSprite().loadGraphic(Paths.image(stage + '/weebSky', 'stages'));
                    bgSky.scrollFactor.set(0.1, 0.1);
                    add(bgSky);

                    var repositionShit = -200;

                    var bgSchool:FlxSprite = new FlxSprite(repositionShit, 0).loadGraphic(Paths.image(stage + '/weebSchool', 'stages'));
                    bgSchool.scrollFactor.set(0.6, 0.90);
                    add(bgSchool);

                    var bgStreet:FlxSprite = new FlxSprite(repositionShit).loadGraphic(Paths.image(stage + '/weebStreet', 'stages'));
                    bgStreet.scrollFactor.set(0.95, 0.95);
                    add(bgStreet);

                    var fgTrees:FlxSprite = new FlxSprite(repositionShit + 170, 130).loadGraphic(Paths.image(stage + '/weebTreesBack', 'stages'));
                    fgTrees.scrollFactor.set(0.9, 0.9);
                    add(fgTrees);

                    var bgTrees:FlxSprite = new FlxSprite(repositionShit - 380, -800);
                    var treetex = Paths.getPackerAtlas(stage + '/weebTrees', 'stages');
                    bgTrees.frames = treetex;
                    bgTrees.animation.add('treeLoop', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18], 12);
                    bgTrees.animation.play('treeLoop');
                    bgTrees.scrollFactor.set(0.85, 0.85);
                    add(bgTrees);

                    var treeLeaves:FlxSprite = new FlxSprite(repositionShit, -40);
                    treeLeaves.frames = Paths.getSparrowAtlas(stage + '/petals', 'stages');
                    treeLeaves.animation.addByPrefix('leaves', 'PETALS ALL', 24, true);
                    treeLeaves.animation.play('leaves');
                    treeLeaves.scrollFactor.set(0.85, 0.85);
                    add(treeLeaves);

                    var widShit = Std.int(bgSky.width * 6);

                    bgSky.setGraphicSize(widShit);
                    bgSchool.setGraphicSize(widShit);
                    bgStreet.setGraphicSize(widShit);
                    bgTrees.setGraphicSize(Std.int(widShit * 1.4));
                    fgTrees.setGraphicSize(Std.int(widShit * 0.8));
                    treeLeaves.setGraphicSize(widShit);

                    fgTrees.updateHitbox();
                    bgSky.updateHitbox();
                    bgSchool.updateHitbox();
                    bgStreet.updateHitbox();
                    bgTrees.updateHitbox();
                    treeLeaves.updateHitbox();

                    bgGirls = new BackgroundGirls(-100, 190);
                    bgGirls.scrollFactor.set(0.9, 0.9);

                    bgGirls.setGraphicSize(Std.int(bgGirls.width * PlayState.daPixelZoom));
                    bgGirls.updateHitbox();
                    add(bgGirls);
                }
                case "school-mad":
                {
                    stage = "school";

                    player_2_Point.x = 379;
                    player_2_Point.y = 928;
                    gf_Point.x = 709;
                    gf_Point.y = 856;
                    player_1_Point.x = 993;
                    player_1_Point.y = 944;

                    var bgSky = new FlxSprite().loadGraphic(Paths.image(stage + '/weebSky', 'stages'));
                    bgSky.scrollFactor.set(0.1, 0.1);
                    add(bgSky);

                    var repositionShit = -200;

                    var bgSchool:FlxSprite = new FlxSprite(repositionShit, 0).loadGraphic(Paths.image(stage + '/weebSchool', 'stages'));
                    bgSchool.scrollFactor.set(0.6, 0.90);
                    add(bgSchool);

                    var bgStreet:FlxSprite = new FlxSprite(repositionShit).loadGraphic(Paths.image(stage + '/weebStreet', 'stages'));
                    bgStreet.scrollFactor.set(0.95, 0.95);
                    add(bgStreet);

                    var fgTrees:FlxSprite = new FlxSprite(repositionShit + 170, 130).loadGraphic(Paths.image(stage + '/weebTreesBack', 'stages'));
                    fgTrees.scrollFactor.set(0.9, 0.9);
                    add(fgTrees);

                    var bgTrees:FlxSprite = new FlxSprite(repositionShit - 380, -800);
                    var treetex = Paths.getPackerAtlas(stage + '/weebTrees', 'stages');
                    bgTrees.frames = treetex;
                    bgTrees.animation.add('treeLoop', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18], 12);
                    bgTrees.animation.play('treeLoop');
                    bgTrees.scrollFactor.set(0.85, 0.85);
                    add(bgTrees);

                    var treeLeaves:FlxSprite = new FlxSprite(repositionShit, -40);
                    treeLeaves.frames = Paths.getSparrowAtlas(stage + '/petals', 'stages');
                    treeLeaves.animation.addByPrefix('leaves', 'PETALS ALL', 24, true);
                    treeLeaves.animation.play('leaves');
                    treeLeaves.scrollFactor.set(0.85, 0.85);
                    add(treeLeaves);

                    var widShit = Std.int(bgSky.width * 6);

                    bgSky.setGraphicSize(widShit);
                    bgSchool.setGraphicSize(widShit);
                    bgStreet.setGraphicSize(widShit);
                    bgTrees.setGraphicSize(Std.int(widShit * 1.4));
                    fgTrees.setGraphicSize(Std.int(widShit * 0.8));
                    treeLeaves.setGraphicSize(widShit);

                    fgTrees.updateHitbox();
                    bgSky.updateHitbox();
                    bgSchool.updateHitbox();
                    bgStreet.updateHitbox();
                    bgTrees.updateHitbox();
                    treeLeaves.updateHitbox();

                    bgGirls = new BackgroundGirls(-100, 190);
                    bgGirls.scrollFactor.set(0.9, 0.9);

                    bgGirls.getScared();

                    bgGirls.setGraphicSize(Std.int(bgGirls.width * PlayState.daPixelZoom));
                    bgGirls.updateHitbox();
                    add(bgGirls);

                    stage = "school-mad";
                }
                case "evil-school":
                {
                    player_1_Point.x = 995;
                    player_1_Point.y = 918;
                    gf_Point.x = 645;
                    gf_Point.y = 834;
                    player_2_Point.x = 325;
                    player_2_Point.y = 918;
                    
                    var bg:FlxSprite = new FlxSprite(400, 220);
                    bg.frames = Paths.getSparrowAtlas(stage + '/animatedEvilSchool', 'stages');
                    bg.animation.addByPrefix('idle', 'background 2', 24);
                    bg.animation.play('idle');
                    bg.scrollFactor.set(0.8, 0.9);
                    bg.scale.set(6, 6);
                    add(bg);
                }
                // CUSTOM SHIT
                default:
                {
                    if(stage_Data != null)
                    {
                        camZoom = stage_Data.camera_Zoom;

                        if(stage_Data.camera_Offsets != null)
                        {
                            p1_Cam_Offset.set(stage_Data.camera_Offsets[0][0], stage_Data.camera_Offsets[0][1]);
                            p2_Cam_Offset.set(stage_Data.camera_Offsets[1][0], stage_Data.camera_Offsets[1][1]);
                        }
        
                        player_1_Point.set(stage_Data.character_Positions[0][0], stage_Data.character_Positions[0][1]);
                        player_2_Point.set(stage_Data.character_Positions[1][0], stage_Data.character_Positions[1][1]);
                        gf_Point.set(stage_Data.character_Positions[2][0], stage_Data.character_Positions[2][1]);

                        if(stage_Data.character_Scrolls != null)
                        {
                            p1_Scroll = stage_Data.character_Scrolls[0];
                            p2_Scroll = stage_Data.character_Scrolls[1];
                            gf_Scroll = stage_Data.character_Scrolls[2];
                        }

                        var null_Object_Name_Loop:Int = 0;
        
                        for(Object in stage_Data.objects)
                        {
                            var Sprite = new FlxSprite(Object.position[0], Object.position[1]);
        
                            if(Object.color != null && Object.color != [])
                                Sprite.color = FlxColor.fromRGB(Object.color[0], Object.color[1], Object.color[2]);
        
                            Sprite.antialiasing = Object.antialiased;
                            Sprite.scrollFactor.set(Object.scroll_Factor[0], Object.scroll_Factor[1]);

                            if(Object.object_Name != null && Object.object_Name != "")
                                stage_Objects.push([Object.object_Name, Sprite, Object]);
                            else
                            {
                                stage_Objects.push(["undefinedSprite" + null_Object_Name_Loop, Sprite, Object]);
                                null_Object_Name_Loop++;
                            }

                            if(Object.is_Animated)
                            {
                                Sprite.frames = Paths.getSparrowAtlas(stage + "/" + Object.file_Name, "stages");
        
                                for(Animation in Object.animations)
                                {
                                    var Anim_Name = Animation.name;
        
                                    if(Animation.name == "beatHit")
                                        onBeatHit_Group.add(Sprite);
        
                                    if(Animation.indices == null)
                                    {
                                        Sprite.animation.addByPrefix(
                                            Anim_Name,
                                            Animation.animation_name,
                                            Animation.fps,
                                            Animation.looped
                                        );
                                    }
                                    else if(Animation.indices.length == 0)
                                    {
                                        Sprite.animation.addByPrefix(
                                            Anim_Name,
                                            Animation.animation_name,
                                            Animation.fps,
                                            Animation.looped
                                        );
                                    }
                                    else
                                    {
                                        Sprite.animation.addByIndices(
                                            Anim_Name,
                                            Animation.animation_name,
                                            Animation.indices,
                                            "",
                                            Animation.fps,
                                            Animation.looped
                                        );
                                    }
                                }
        
                                if(Object.start_Animation != "" && Object.start_Animation != null && Object.start_Animation != "null")
                                    Sprite.animation.play(Object.start_Animation);
                            }
                            else
                                Sprite.loadGraphic(Paths.image(stage + "/" + Object.file_Name, "stages"));
        
                            if(Object.uses_Frame_Width)
                                Sprite.setGraphicSize(Std.int(Sprite.frameWidth * Object.scale));
                            else
                                Sprite.setGraphicSize(Std.int(Sprite.width * Object.scale));

                            if(Object.updateHitbox || Object.updateHitbox == null)
                                Sprite.updateHitbox();

                            if(Object.alpha != null)
                                Sprite.alpha = Object.alpha;
        
                            if(Object.layer != null)
                            {
                                switch(Object.layer.toLowerCase())
                                {
                                    case "foreground":
                                        foregroundSprites.add(Sprite);
                                    case "gf":
                                        infrontOfGFSprites.add(Sprite);
                                    default:
                                        add(Sprite);
                                }
                            }
                            else
                                add(Sprite);
                        }
                    }
                }
            }
        }
    }

    public function createLuaStuff()
    {
        #if linc_luajit
        #if polymod // change this in future whenever custom backend
        if(stage_Data != null)
        {
            if(stage_Data.scriptName != null && Assets.exists(Paths.lua("stage data/" + stage_Data.scriptName)))
                stageScript = ModchartUtilities.createModchartUtilities(PolymodAssets.getPath(Paths.lua("stage data/" + stage_Data.scriptName)));
        }
        #end
        #end
    }

    public function setCharOffsets(?p1:Character, ?gf:Character, ?p2:Character):Void
    {
        if(p1 == null)
            p1 = PlayState.boyfriend;

        if(gf == null)
            gf = PlayState.gf;

        if(p2 == null)
            p2 = PlayState.dad;

        p1.setPosition((player_1_Point.x - (p1.width / 2)) + p1.positioningOffset[0], (player_1_Point.y - p1.height) + p1.positioningOffset[1]);
        gf.setPosition((gf_Point.x - (gf.width / 2)) + gf.positioningOffset[0], (gf_Point.y - gf.height) + gf.positioningOffset[1]);
        p2.setPosition((player_2_Point.x - (p2.width / 2)) + p2.positioningOffset[0], (player_2_Point.y - p2.height) + p2.positioningOffset[1]);

        p1.scrollFactor.set(p1_Scroll, p1_Scroll);
        p2.scrollFactor.set(p2_Scroll, p2_Scroll);
        gf.scrollFactor.set(gf_Scroll, gf_Scroll);

        if(p2.curCharacter.startsWith("gf") && gf.curCharacter.startsWith("gf"))
        {
            p2.setPosition(gf.x, gf.y);
            p2.scrollFactor.set(gf_Scroll, gf_Scroll);

            if(p2.visible)
                gf.visible = false;
        }

        if(p1.otherCharacters != null)
        {
            for(character in p1.otherCharacters)
            {
                character.setPosition((player_1_Point.x - (character.width / 2)) + character.positioningOffset[0], (player_1_Point.y - character.height) + character.positioningOffset[1]);
                character.scrollFactor.set(p1_Scroll, p1_Scroll);
            }
        }

        if(gf.otherCharacters != null)
        {
            for(character in gf.otherCharacters)
            {
                character.setPosition((gf_Point.x - (character.width / 2)) + character.positioningOffset[0], (gf_Point.y - character.height) + character.positioningOffset[1]);
                character.scrollFactor.set(gf_Scroll, gf_Scroll);
            }
        }

        if(p2.otherCharacters != null)
        {
            for(character in p2.otherCharacters)
            {
                character.setPosition((player_2_Point.x - (character.width / 2)) + character.positioningOffset[0], (player_2_Point.y - character.height) + character.positioningOffset[1]);
                character.scrollFactor.set(p2_Scroll, p2_Scroll);
            }
        }
    }

    public function getCharacterPos(character:Int, char:Character = null):Dynamic
    {
        switch(character)
        {
            case 0: // bf
                if(char == null)
                    char = PlayState.boyfriend;

                return [(player_1_Point.x - (char.width / 2)) + char.positioningOffset[0], (player_1_Point.y - char.height) + char.positioningOffset[1]];
            case 1: // dad
                if(char == null)
                    char = PlayState.dad;

                return [(player_2_Point.x - (char.width / 2)) + char.positioningOffset[0], (player_2_Point.y - char.height) + char.positioningOffset[1]];
            case 2: // gf
                if(char == null)
                    char = PlayState.gf;

                return [(gf_Point.x - (char.width / 2)) + char.positioningOffset[0], (gf_Point.y - char.height) + char.positioningOffset[1]];
        }

        return [0,0];
    }

    override public function new(?stageName:String) {
        super();

        stage = stageName;
        updateStage();
    }

    public function beatHit()
    {
        if(utilities.Options.getData("animatedBGs"))
        {
            for(sprite in onBeatHit_Group)
            {
                sprite.animation.play("beatHit", true);
            }
            
            switch(stage)
            {
                case 'school' | 'school-mad':
                {
                    bgGirls.dance();
                }
            }
        }
    }

    override function update(elapsed:Float)
    {
        super.update(elapsed);

        goodElapse = elapsed;
    }

    // philly

    function updateTrainPos() {
        if (trainSound.time >= 4700)
        {
            startedMoving = true;
            PlayState.gf.playAnim('hairBlow');
        }

        if (startedMoving)
        {
            phillyTrain.x -= 400;

            if (phillyTrain.x < -2000 && !trainFinishing)
            {
                phillyTrain.x = -1150;
                trainCars -= 1;

                if (trainCars <= 0)
                    trainFinishing = true;
            }

            if (phillyTrain.x < -4000 && trainFinishing)
                trainReset();
        }
    }

    function trainReset()
    {
        PlayState.gf.playAnim('hairFall');
        
		phillyTrain.x = FlxG.width + 200;
		trainMoving = false;
		trainCars = 8;
		trainFinishing = false;
		startedMoving = false;
    }

    function trainStart():Void
    {
        trainMoving = true;
        if (!trainSound.playing)
            trainSound.play(true);
    }

    // LUA SHIT LOL

    override public function destroy() {
        #if linc_luajit
        if(stageScript != null)
        {
            stageScript.die();
            stageScript = null;
        }
        #end

        super.destroy();
    }
}

typedef StageData =
{
    var character_Positions:Array<Array<Float>>;
    var character_Scrolls:Array<Float>;

    var camera_Zoom:Float;
    var camera_Offsets:Array<Array<Float>>;

    var objects:Array<StageObject>;

    var scriptName:Null<String>;
}

typedef StageObject =
{
    // General Sprite Object Data //
    var position:Array<Float>;
    var scale:Float;
    var antialiased:Bool;
    var scroll_Factor:Array<Float>;

    var color:Array<Int>;

    var uses_Frame_Width:Bool;

    var object_Name:Null<String>;

    var layer:Null<String>; // default is bg, but fg is possible

    var alpha:Null<Float>;

    var updateHitbox:Null<Bool>;
    
    // Image Info //
    var file_Name:String;
    var is_Animated:Bool;

    // Animations //
    var animations:Array<CharacterAnimation>;

    var start_Animation:String;
}