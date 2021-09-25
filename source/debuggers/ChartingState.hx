package debuggers;

import game.Conductor;
#if sys
import polymod.backends.PolymodAssets;
import modding.ModdingSound;
#end

import states.LoadingState;
import game.Song;
import states.PlayState;
import flixel.FlxObject;
import flixel.util.FlxColor;
import flixel.addons.display.FlxGridOverlay;
import flixel.FlxG;
import utilities.CoolUtil;
import lime.utils.Assets;
import ui.HealthIcon;
import flixel.system.FlxSound;
import game.Note;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.FlxSprite;
import game.Song.SwagSong;
import flixel.text.FlxText;
import openfl.net.FileReference;
import states.MusicBeatState;

using StringTools;

class ChartingState extends MusicBeatState
{
    // Constants
    var Grid_Size:Int = 40;
    
    // Coolness
    var FileRef:FileReference;
    var SONG:SwagSong;

    // SONG Variables
    var Cur_Section:Int = 0;
    var Song_Name:String = "Test";
    var Difficulty:String = 'Normal';

    var Cur_Mod:String = "default";

    // UI Shit Lmao
    var Info_Text:FlxText;
    var Song_Line:FlxSprite;
    var Grid_Highlight:FlxSprite;

    var Current_Notes:FlxTypedGroup<Note>;
	var Current_Sustains:FlxTypedGroup<FlxSprite>;

    var Note_Grid:FlxSprite;
    var Note_Grid_Above:FlxSprite;
    var Note_Grid_Below:FlxSprite;
    var Note_Grid_Seperator:FlxSprite;

    var Section_Left_Icon:HealthIcon;
    var Next_Section_Left_Icon:HealthIcon;

    var Section_Right_Icon:HealthIcon;
    var Next_Section_Right_Icon:HealthIcon;

    // Note Variables
    var Selected_Note:Array<Dynamic>;
    var Cur_Note_Char:Int = 0;

    // Other
    var Vocal_Track:FlxSound;

    var Character_Lists:Map<String, Array<String>> = new Map<String, Array<String>>();

    var Camera_Object:FlxObject = new FlxObject();

    override function create()
    {
        // FOR WHEN COMING IN FROM THE TOOLS PAGE LOL
		if (Assets.getLibrary("shared") == null)
			Assets.loadLibrary("shared");

        #if sys
		var characterList = CoolUtil.coolTextFilePolymod(Paths.txt('characterList'));
		#else
		var characterList = CoolUtil.coolTextFile(Paths.txt('characterList'));
		#end

        for(Text in characterList)
        {
            var Properties = Text.split(":");

            var name = Properties[0];
            var mod = Properties[1];

            var base_array;

            if(Character_Lists.get(mod) != null)
                base_array = Character_Lists.get(mod);
            else
                base_array = [];

            base_array.push(name);
            Character_Lists.set(mod, base_array);
        }

        FlxG.mouse.visible = true;

        updateGrid();

        Camera_Object.screenCenter(X);
        Camera_Object.y = Grid_Size * 26;

        FlxG.camera.follow(Camera_Object);

        if(PlayState.SONG != null)
            SONG = PlayState.SONG;
        else
            SONG = Song.loadFromJson("tutorial", "tutorial");

        loadSong(SONG.song);
		Conductor.changeBPM(SONG.bpm);
		Conductor.mapBPMChanges(SONG);

        FlxG.sound.music.play();
    }

    override function update(elapsed:Float)
    {
        super.update(elapsed);

        Camera_Object.y += -1 * (FlxG.mouse.wheel * Grid_Size);

		if (FlxG.keys.justPressed.ENTER)
        {
            FlxG.mouse.visible = false;
            PlayState.SONG = SONG;
            FlxG.sound.music.stop();
            Vocal_Track.stop();
            LoadingState.loadAndSwitchState(new PlayState());
        }
    }

    function updateGrid()
    {
        Note_Grid_Above = FlxGridOverlay.create(Grid_Size, Grid_Size, Grid_Size * 8, Grid_Size * 16);

        Note_Grid_Above.screenCenter();
        Note_Grid_Above.color = FlxColor.fromRGB(180, 180, 180);

        add(Note_Grid_Above);

        Note_Grid = FlxGridOverlay.create(Grid_Size, Grid_Size, Grid_Size * 8, Grid_Size * 16);

        Note_Grid.screenCenter();
        Note_Grid.y += Grid_Size * 16;

        add(Note_Grid);

        Note_Grid_Below = FlxGridOverlay.create(Grid_Size, Grid_Size, Grid_Size * 8, Grid_Size * 16);

        Note_Grid_Below.screenCenter();
        Note_Grid_Below.y += (Grid_Size * 16) * 2;
        Note_Grid_Below.color = FlxColor.fromRGB(180, 180, 180);

        add(Note_Grid_Below);
    }

    function loadSong(daSong:String):Void
    {
        if (FlxG.sound.music != null)
            FlxG.sound.music.stop();

        #if sys
        if(Assets.exists(Paths.inst(daSong)))
            FlxG.sound.music = new FlxSound().loadEmbedded(Paths.inst(daSong));
        else
            FlxG.sound.music = new ModdingSound().loadByteArray(PolymodAssets.getBytes(Paths.instSYS(daSong)));

        FlxG.sound.music.persist = true;

        #else
        FlxG.sound.music = new FlxSound().loadEmbedded(Paths.inst(daSong));
        FlxG.sound.music.persist = true;
        #end
        
        if (SONG.needsVoices)
        {
            #if sys
            if(Assets.exists(Paths.voices(daSong)))
                Vocal_Track = new FlxSound().loadEmbedded(Paths.voices(daSong));
            else
                Vocal_Track = new ModdingSound().loadByteArray(PolymodAssets.getBytes(Paths.voicesSYS(daSong)));
            #else
            Vocal_Track = new FlxSound().loadEmbedded(Paths.voices(daSong));
            #end
        }
        else
            Vocal_Track = new FlxSound();

        FlxG.sound.list.add(Vocal_Track);

        FlxG.sound.music.pause();
        Vocal_Track.pause();

        FlxG.sound.music.onComplete = function()
        {
            Vocal_Track.pause();
            Vocal_Track.time = 0;
            FlxG.sound.music.pause();
            FlxG.sound.music.time = 0;
            //changeSection();
        };
    }
}