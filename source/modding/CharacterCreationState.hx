package modding;

import ui.FlxUIDropDownMenuCustom;
import states.MusicBeatState;
import flixel.util.FlxColor;
import states.MainMenuState;
import flixel.util.FlxTimer.FlxTimerManager;
import openfl.events.IOErrorEvent;
import openfl.events.Event;
import openfl.net.FileReference;
#if discord_rpc
import utilities.Discord.DiscordClient;
#end
import flixel.ui.FlxButton;
import openfl.display.BitmapData;
import lime.utils.Assets;
import flixel.addons.ui.FlxUICheckBox;
import flixel.text.FlxText;
import flixel.FlxG;
import flixel.addons.ui.FlxUITabMenu;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.ui.FlxUIInputText;
import flixel.addons.ui.FlxUI;
import flixel.group.FlxGroup;
import game.Character;
import haxe.Json;
#if sys
import sys.io.File;
import sys.FileSystem;
import polymod.backends.PolymodAssets;
#end
import modding.CharacterConfig;
import flixel.FlxState;

using StringTools;

class CharacterCreationState extends MusicBeatState
{
    // OTHER STUFF IDK LMAO //
    public static var instance:CharacterCreationState;

    // SETTINGS //
    public var Character_Name:String = "bf";
    public var Image_Path:String = "BOYFRIEND";

    public var Default_FlipX:Bool = true;
    public var LeftAndRight_Idle:Bool = false;

    public var Spritesheet_Type:SpritesheetType = SPARROW;

    public var Animations:Array<CharacterAnimation> = [];

    public var Graphics_Size:Float;
    public var Bar_Color:Array<Int> = [255, 0, 0];

    // VARIABLES //
    
    // DATA //
    private var Raw_JSON_Data:String;
    private var CC_Data:CharacterConfig;

    private var Animation_List:Array<String>;
    private var Selected_Animation:String = "idle";

    // OBJECTS //
    private var UI_Group:FlxGroup = new FlxGroup();

    private var Character:Character;

    private var Image_Path_Box:FlxUIInputText;
    private var Char_Name_Box:FlxUIInputText;

    private var UI_Base:FlxUI;
    
    private var Animation_List_Menu:FlxUIDropDownMenuCustom;

    public function new(?New_Character:String = "bf")
    {
        super();

        instance = this;

        Character_Name = New_Character;
    }

    override function create()
    {
        FlxG.mouse.visible = true;

        if(Assets.getLibrary("shared") == null)
        {
			Assets.loadLibrary("shared").onComplete(function (_) {
                Load_Character_File_JSON_Data();

                Create_UI();
                add(UI_Group);
                add(Character);
        
                #if discord_rpc
                DiscordClient.changePresence("Creating A Character", null, null);
                #end
            });
        }
        else
        {
            Load_Character_File_JSON_Data();

            Create_UI();
            add(UI_Group);
            add(Character);
    
            #if discord_rpc
            DiscordClient.changePresence("Creating A Character", null, null);
            #end
        }
    }

    public function Read_JSON_Data(?JSON_Data:Null<String>)
    {
        if(JSON_Data == null)
            CC_Data = cast Json.parse(Raw_JSON_Data);
        else
            CC_Data = cast Json.parse(JSON_Data);

        Image_Path = CC_Data.imagePath;
        Default_FlipX = CC_Data.defaultFlipX;
        LeftAndRight_Idle = CC_Data.dancesLeftAndRight;
        Spritesheet_Type = SPARROW;
        Animations = CC_Data.animations;

        if(CC_Data.graphicsSize != null)
            Graphics_Size = CC_Data.graphicsSize;
        else
            Graphics_Size = 1;
    }

    private function Create_UI()
    {
        // BASE //
        UI_Base = new FlxUI(null, null);

        // CHARTING STATE THING //
        var UI_box = new FlxUITabMenu(null, [], false);

        UI_box.resize(300, 400);
        UI_box.x = 10;
        UI_box.y = 70;

        var Grid_Background:FlxSprite = FlxGridOverlay.create(25, 25);
		Grid_Background.scrollFactor.set(0,0);

        // TEXT LABELS //
        var Name_Label:FlxText = new FlxText(20, 70, 0, "Character Name");
        var Path_Label:FlxText = new FlxText(20, 100, 0, "Image Path (after shared/characters/)");

        var Actions_Label:FlxText = new FlxText(20, 300, 0, "Actions");

        // TEXT BOXES //
        var Name_Box:FlxUIInputText = new FlxUIInputText(20, 85, 150, Character_Name, 8);
        Char_Name_Box = Name_Box;

        var Path_Box:FlxUIInputText = new FlxUIInputText(20, 115, 150, Image_Path, 8);
        Image_Path_Box = Path_Box;

        // CHECK BOXES //
        var Flip_Box:FlxUICheckBox = new FlxUICheckBox(20, 135, null, null, "Flipped by Default?", 250);
        Flip_Box.checked = Default_FlipX;

        Flip_Box.callback = function()
        {
            Default_FlipX = Flip_Box.checked;
        };

        var L_And_R_Box:FlxUICheckBox = new FlxUICheckBox(20, 160, null, null, "Dances to the left and right?", 250);
        L_And_R_Box.checked = LeftAndRight_Idle;

        L_And_R_Box.callback = function()
        {
            LeftAndRight_Idle = L_And_R_Box.checked;
        };

        // DROP DOWNS //
        Load_Animations();

        // BUTTONS //
        var Reload_Char:FlxButton = new FlxButton(20, 325, "Load Settings", function(){
            if(Character != null)
            {
                remove(Character);
                Character.kill();
                Character.destroy();
            }

            Create_Character();

            add(Character);

            Load_Animations();
        });

        var Reload_Json:FlxButton = new FlxButton(Reload_Char.x + Reload_Char.width, Reload_Char.y, "Load JSON", function(){
            if(Character != null)
            {
                remove(Character);
                Character.kill();
                Character.destroy();
            }

            Load_Character_File_JSON_Data();
            Create_Character();

            Path_Box.text = Image_Path;
            Name_Box.text = Character_Name;
            Flip_Box.checked = Default_FlipX;
            L_And_R_Box.checked = LeftAndRight_Idle;

            add(Character);

            Load_Animations();
        });

        var Save_JSON:FlxButton = new FlxButton(Reload_Char.x, Reload_Char.y + Reload_Char.height + 2, "Save JSON", function(){
            save_JSON();
        });

        var Play_Selected_Animation:FlxButton = new FlxButton(Animation_List_Menu.x + Animation_List_Menu.width + 1, Animation_List_Menu.y, "Play Animation", function(){
            Character.playAnim(Selected_Animation, true);
            Character.screenCenter();
        });

        // ADDING OBJECTS //
        UI_Base.add(Grid_Background);

        UI_Base.add(UI_box);

        UI_Base.add(Name_Label);
        UI_Base.add(Name_Box);

        UI_Base.add(Path_Label);
        UI_Base.add(Path_Box);

        UI_Base.add(Flip_Box);
        UI_Base.add(L_And_R_Box);

        UI_Base.add(Actions_Label);
        UI_Base.add(Reload_Char);
        UI_Base.add(Reload_Json);
        UI_Base.add(Save_JSON);

        UI_Base.add(Animation_List_Menu);
        UI_Base.add(Play_Selected_Animation);

        UI_Group.add(UI_Base);

        Create_Character();
    }

    function Load_New_JSON_Data()
    {
        CC_Data = {
            imagePath: Image_Path,
            animations: Animations,
            defaultFlipX: Default_FlipX,
            dancesLeftAndRight: LeftAndRight_Idle,
            graphicsSize: Graphics_Size,
            barColor: Bar_Color,
            positionOffset: [0,0],
            cameraOffset: [0,0],
            characters: [],
            offsetsFlipWhenEnemy: false,
            offsetsFlipWhenPlayer: true,
            trail: false,
            trailLength: 4,
            trailDelay: 24,
            trailStalpha: 0.3,
            trailDiff: 0.069,
            deathCharacterName: "bf-dead",
            swapDirectionSingWhenPlayer: true,
            healthIcon: Character_Name,
            antialiased: true
        };
    }

    function Load_Character_File_JSON_Data()
    {
        Raw_JSON_Data = "";

		#if sys
		Raw_JSON_Data = PolymodAssets.getText(Paths.jsonSYS("character data/" + Character_Name + "/config")).trim();
		#else
		Raw_JSON_Data = Assets.getText(Paths.json("character data/" + Character_Name + "/config")).trim();
		#end

        Read_JSON_Data();
    }

    function Create_Character(?New_Char:String)
    {
        if(New_Char != null)
            Character_Name = New_Char;

        Load_New_JSON_Data();

        Character = new Character(0, 0, "", true);
        Character.debugMode = true;
        Character.loadCharacterConfiguration(CC_Data);
        Character.loadOffsetFile(Character_Name);
        Character.screenCenter();
        Character.visible = true;
    }

    function Load_Animations()
    {
        Animation_List = [];

        for(animation in CC_Data.animations)
        {
            var name = animation.name;

            Animation_List.push(name);
        }

        var newList:Bool = true;

        if(Animation_List_Menu != null)
        {
            UI_Base.remove(Animation_List_Menu);
            Animation_List_Menu.destroy();
            newList = false;
        }

        Animation_List_Menu = new FlxUIDropDownMenuCustom(100, 300, FlxUIDropDownMenuCustom.makeStrIdLabelArray(Animation_List, true), function(id:String){
            Selected_Animation = Animation_List[Std.parseInt(id)];
            Character.playAnim(Selected_Animation, true);
            Character.screenCenter();
            Load_Animation_Info();
        });

        if(LeftAndRight_Idle)
            Selected_Animation = Animation_List[Std.parseInt("danceLeft")];
        else
            Selected_Animation = Animation_List[Std.parseInt("idle")];

        if(!newList)
            UI_Base.add(Animation_List_Menu);
    }

    function Load_Animation_Info()
    {

    }

    override function update(elapsed:Float) {
        super.update(elapsed);

        if(Char_Name_Box != null)
            Character_Name = Char_Name_Box.text;
        if(Image_Path_Box != null)
            Image_Path = Image_Path_Box.text;

        if(Character != null)
            Character.screenCenter();

        if(FlxG.keys.justPressed.ESCAPE)
        {
            FlxG.mouse.visible = false;
            FlxG.switchState(new MainMenuState());
        }
    }

    var _file:FileReference;

    private function save_JSON()
    {
        var data:String = Json.stringify(CC_Data, null, "\t");

        if ((data != null) && (data.length > 0))
        {
            _file = new FileReference();
            _file.addEventListener(Event.COMPLETE, onSaveComplete);
            _file.addEventListener(Event.CANCEL, onSaveCancel);
            _file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);

            _file.save(data.trim(), "config.json");
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

enum SpritesheetType
{
    SPARROW;
    PACKER;
}