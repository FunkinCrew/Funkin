package debuggers;

#if discord_rpc
import utilities.Discord.DiscordClient;
#end

import game.Section.SwagSection;
import flixel.math.FlxMath;
import game.Conductor;
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

class ChartingStateDev extends MusicBeatState
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

    /* icons lol */

    var P1_Tex:HealthIcon;
    var P2_Tex:HealthIcon;

    var Section_Left_Icon:FlxSprite;
    var Next_Section_Left_Icon:FlxSprite;

    /* divider between left and right icons lmao */

    var Section_Right_Icon:FlxSprite;
    var Next_Section_Right_Icon:FlxSprite;

    /* stop icons lol */

    // Note Variables
    var Selected_Note:Array<Dynamic>;
    var Cur_Note_Char:Int = 0;

    // Other
    var Vocal_Track:FlxSound;

    var Character_Lists:Map<String, Array<String>> = new Map<String, Array<String>>();

    var Camera_Object:FlxObject = new FlxObject();

    var Inst_Track:FlxSound;

    override function create()
    {
        #if discord_rpc
        DiscordClient.changePresence("Charting a song", null, null);
        #end

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

        if(PlayState.SONG != null)
        {
            SONG = PlayState.SONG;
            SONG.speed = PlayState.previousScrollSpeedLmao;
        }
        else
            SONG = Song.loadFromJson("tutorial", "tutorial");

        P1_Tex = new HealthIcon(SONG.player1);
        P2_Tex = new HealthIcon(SONG.player2);

        FlxG.mouse.visible = true;

        Current_Notes = new FlxTypedGroup<Note>();
        Current_Sustains = new FlxTypedGroup<FlxSprite>();

        Camera_Object.screenCenter(X);
        Camera_Object.y = Grid_Size * 26;

        FlxG.camera.follow(Camera_Object);

        loadSong(SONG.song);
		Conductor.changeBPM(SONG.bpm);
		Conductor.mapBPMChanges(SONG);

        updateGrid();

        Info_Text = new FlxText(0,4,0,"Time: 0.0 / " + (Inst_Track.length / 1000), 20);
        Info_Text.setFormat(null, 20, FlxColor.WHITE, RIGHT);
        Info_Text.x = FlxG.width - Info_Text.width;
        Info_Text.scrollFactor.set();
        add(Info_Text);

        add(Current_Sustains);
        add(Current_Notes);
    }

    override function update(elapsed:Float)
    {
        super.update(elapsed);

		if (FlxG.keys.justPressed.ENTER)
        {
            FlxG.mouse.visible = false;
            PlayState.SONG = SONG;
            FlxG.sound.music.stop();
            Vocal_Track.stop();
            LoadingState.loadAndSwitchState(new PlayState());
        }

        if (FlxG.keys.justPressed.SPACE)
        {
            if(Inst_Track.playing)
            {
                Inst_Track.pause();

                if(SONG.needsVoices)
                    Vocal_Track.pause();
            }
            else
            {
                if(SONG.needsVoices)
                    Vocal_Track.time = Inst_Track.time;

                Inst_Track.play();

                if(SONG.needsVoices)
                    Vocal_Track.play();
            }
        }

        if (controls.RESET)
        {
            Inst_Track.stop();

            if(SONG.needsVoices)
                Vocal_Track.stop();
        }

        var Previous_Y = Camera_Object.y;
        var Above_Value = Note_Grid_Above.y + Note_Grid_Above.height;
        var Below_Value = Note_Grid_Below.y;

        if(FlxG.mouse.wheel != 0)
        {
            var Prev_Playing = Inst_Track.playing;

            if(Prev_Playing)
                Inst_Track.pause();
            
            Inst_Track.time += -1 * (FlxG.mouse.wheel * Grid_Size);

            if(Inst_Track.time < 0)
                Inst_Track.time = Inst_Track.length;

            if(Inst_Track.time > Inst_Track.length)
                Inst_Track.time = 0;

            if(SONG.needsVoices)
                Vocal_Track.time = Inst_Track.time;

            if(Prev_Playing)
            {
                Inst_Track.play();

                if(SONG.needsVoices)
                    Vocal_Track.play();
            }
        }

        Camera_Object.y = getYfromStrum((Inst_Track.time - sectionStartTime()) % (Conductor.stepCrochet * SONG.notes[Cur_Section].lengthInSteps));

        Conductor.songPosition = Inst_Track.time;

        updateCurStep();
        updateSection();

        Info_Text.text = (
            "Time: " + (Inst_Track.time / 1000) + " / " + (Inst_Track.length / 1000) +
            "\n" + "Cur Beat: " + curBeat +
            "\n" + "Cur Step: " + curStep +
            "\n" + "Cur Section: " + Cur_Section +
            "\n" + "BPM: " + Conductor.bpm +
            "\n"
        );

        Info_Text.x = FlxG.width - Info_Text.width;
    }

    function cleanupSections()
    {
        // get rid of bad sections lmao
        while(sectionStartTime(SONG.notes.length - 1) >= Inst_Track.length)
            SONG.notes.pop();
    }

    function updateGrid()
    {
        var Next_Section = Cur_Section + 1;

        if(Next_Section > SONG.notes.length - 1)
            addSection(SONG.notes[Cur_Section].lengthInSteps);

        if(sectionStartTime(Next_Section) >= Inst_Track.length)
            Next_Section = 0;

        cleanupSections();

        var Prev_Section = Cur_Section - 1;

        if(Prev_Section < 0)
            Prev_Section = SONG.notes.length - 1;

        var prev_sectionInfo:Array<Dynamic> = SONG.notes[Prev_Section].sectionNotes;
        var sectionInfo:Array<Dynamic> = SONG.notes[Cur_Section].sectionNotes;
        var next_sectionInfo:Array<Dynamic> = SONG.notes[Next_Section].sectionNotes;

        if(Note_Grid_Above != null)
        {
            remove(Note_Grid_Above);
            Note_Grid_Above.kill();
            Note_Grid_Above.destroy();

            remove(Note_Grid);
            Note_Grid.kill();
            Note_Grid.destroy();

            remove(Note_Grid_Below);
            Note_Grid_Below.kill();
            Note_Grid_Below.destroy();
        }

        Note_Grid_Above = FlxGridOverlay.create(Grid_Size, Grid_Size, Grid_Size * (SONG.keyCount * 2), Grid_Size * SONG.notes[Prev_Section].lengthInSteps);

        Note_Grid_Above.screenCenter();
        Note_Grid_Above.color = FlxColor.fromRGB(180, 180, 180);

        add(Note_Grid_Above);

        Note_Grid = FlxGridOverlay.create(Grid_Size, Grid_Size, Grid_Size * (SONG.keyCount * 2), Grid_Size * SONG.notes[Cur_Section].lengthInSteps);

        Note_Grid.screenCenter();
        Note_Grid.y = Note_Grid_Above.y + Note_Grid_Above.height;

        add(Note_Grid);

        Note_Grid_Below = FlxGridOverlay.create(Grid_Size, Grid_Size, Grid_Size * (SONG.keyCount * 2), Grid_Size * SONG.notes[Next_Section].lengthInSteps);

        Note_Grid_Below.screenCenter();
        Note_Grid_Below.y = Note_Grid.y + Note_Grid.height;
        Note_Grid_Below.color = FlxColor.fromRGB(180, 180, 180);

        add(Note_Grid_Below);

        /* THIS SECTION */
        if(Section_Left_Icon != null)
        {
            remove(Section_Left_Icon);
            Section_Left_Icon.kill();
            Section_Left_Icon.destroy();

            remove(Section_Right_Icon);
            Section_Right_Icon.kill();
            Section_Right_Icon.destroy();

            remove(Next_Section_Left_Icon);
            Next_Section_Left_Icon.kill();
            Next_Section_Left_Icon.destroy();

            remove(Next_Section_Right_Icon);
            Next_Section_Right_Icon.kill();
            Next_Section_Right_Icon.destroy();
        }
        
        Section_Left_Icon = new FlxSprite();
        Section_Left_Icon.loadGraphicFromSprite((SONG.notes[Cur_Section].mustHitSection ? P1_Tex : P2_Tex));
		Section_Left_Icon.scrollFactor.set(1, 1);
		Section_Left_Icon.setGraphicSize(Grid_Size);
		Section_Left_Icon.updateHitbox();
        Section_Left_Icon.x = Note_Grid.x - Section_Left_Icon.width;
        Section_Left_Icon.y = Note_Grid.y;
        Section_Left_Icon.animation.add("char", [0, 1, 2], 0, false, false);
		Section_Left_Icon.animation.play("char");
		add(Section_Left_Icon);

        Section_Right_Icon = new FlxSprite();
        Section_Right_Icon.loadGraphicFromSprite((SONG.notes[Cur_Section].mustHitSection ? P2_Tex : P1_Tex));
        Section_Right_Icon.scrollFactor.set(1, 1);
        Section_Right_Icon.setGraphicSize(Grid_Size);
        Section_Right_Icon.updateHitbox();
        Section_Right_Icon.x = Note_Grid.x + Note_Grid.width;
        Section_Right_Icon.y = Note_Grid.y;
        Section_Right_Icon.animation.add("char", [0, 1, 2], 0, false, false);
		Section_Right_Icon.animation.play("char");
		add(Section_Right_Icon);

        /* NEXT SECTION */
        Next_Section_Left_Icon = new FlxSprite();
        Next_Section_Left_Icon.loadGraphicFromSprite((SONG.notes[Next_Section].mustHitSection ? P1_Tex : P2_Tex));
		Next_Section_Left_Icon.scrollFactor.set(1, 1);
		Next_Section_Left_Icon.setGraphicSize(Grid_Size);
		Next_Section_Left_Icon.updateHitbox();
        Next_Section_Left_Icon.x = Note_Grid_Below.x - Next_Section_Left_Icon.width;
        Next_Section_Left_Icon.y = Note_Grid_Below.y;
        Next_Section_Left_Icon.animation.add("char", [0, 1, 2], 0, false, false);
		Next_Section_Left_Icon.animation.play("char");
		add(Next_Section_Left_Icon);

        Next_Section_Right_Icon = new FlxSprite();
        Next_Section_Right_Icon.loadGraphicFromSprite((SONG.notes[Next_Section].mustHitSection ? P2_Tex : P1_Tex));
        Next_Section_Right_Icon.scrollFactor.set(1, 1);
        Next_Section_Right_Icon.setGraphicSize(Grid_Size);
        Next_Section_Right_Icon.updateHitbox();
        Next_Section_Right_Icon.x = Note_Grid_Below.x + Note_Grid_Below.width;
        Next_Section_Right_Icon.y = Note_Grid_Below.y;
        Next_Section_Right_Icon.animation.add("char", [0, 1, 2], 0, false, false);
		Next_Section_Right_Icon.animation.play("char");
		add(Next_Section_Right_Icon);

        /* COOL SHIT */
        if(Note_Grid_Seperator != null)
        {
            remove(Note_Grid_Seperator);
            Note_Grid_Seperator.kill();
            Note_Grid_Seperator.destroy();

            remove(Song_Line);
            Song_Line.kill();
            Song_Line.destroy();
        }

        Note_Grid_Seperator = new FlxSprite(Note_Grid_Above.x + Note_Grid_Above.width / 2, Note_Grid_Above.y);
        Note_Grid_Seperator.makeGraphic(2, Std.int(Note_Grid_Above.height + Note_Grid.height + Note_Grid_Below.height), FlxColor.BLACK);
        add(Note_Grid_Seperator);

        Song_Line = new FlxSprite();
        Song_Line.makeGraphic(Std.int(Note_Grid.width), 2);
        Song_Line.screenCenter();
        Song_Line.scrollFactor.set();
        add(Song_Line);
        
        Current_Notes.forEach(function(Note:Note) {
            remove(Note);
            Note.kill();
            Note.destroy();
        });

        Current_Sustains.forEach(function(Sustain:FlxSprite) {
            remove(Sustain);
            Sustain.kill();
            Sustain.destroy();
        });

        Current_Notes.clear();
        Current_Sustains.clear();

		if (SONG.notes[Cur_Section].changeBPM && SONG.notes[Cur_Section].bpm > 0)
		{
			Conductor.changeBPM(SONG.notes[Cur_Section].bpm);
			FlxG.log.add('CHANGED BPM!');
		}
		else
		{
			// get last bpm
			var daBPM:Float = SONG.bpm;

			for (i in 0...Cur_Section)
				if (SONG.notes[i].changeBPM)
					daBPM = SONG.notes[i].bpm;

			Conductor.changeBPM(daBPM);
		}

        for (i in prev_sectionInfo)
        {
            var daNoteInfo = i[1];
            var daStrumTime = i[0];
            var daSus = i[2];

            var note:Note = new Note(daStrumTime, daNoteInfo % SONG.keyCount);
            note.sustainLength = daSus;

            note.setGraphicSize(Grid_Size, Grid_Size);
            note.updateHitbox();

            note.x = Note_Grid.x + Math.floor(daNoteInfo * Grid_Size);
            note.y = Math.floor(getYfromStrum((daStrumTime - sectionStartTime(Prev_Section)) % (Conductor.stepCrochet * SONG.notes[Prev_Section].lengthInSteps), Note_Grid_Above));

            note.rawNoteData = daNoteInfo;

            Current_Notes.add(note);

            if (daSus > 0)
            {
                var sustainVis:FlxSprite = new FlxSprite(note.x + (Grid_Size / 2),
                    note.y + Grid_Size).makeGraphic(8, Math.floor(FlxMath.remapToRange(daSus, 0, Conductor.stepCrochet * SONG.notes[Prev_Section].lengthInSteps, 0, Note_Grid_Above.height)));
                
                Current_Sustains.add(sustainVis);
            }
        }

        for (i in sectionInfo)
        {
            var daNoteInfo = i[1];
            var daStrumTime = i[0];
            var daSus = i[2];

            var note:Note = new Note(daStrumTime, daNoteInfo % SONG.keyCount);
            note.sustainLength = daSus;

            note.setGraphicSize(Grid_Size, Grid_Size);
            note.updateHitbox();

            note.x = Note_Grid.x + Math.floor(daNoteInfo * Grid_Size);
            note.y = Math.floor(getYfromStrum((daStrumTime - sectionStartTime(Cur_Section)) % (Conductor.stepCrochet * SONG.notes[Cur_Section].lengthInSteps), Note_Grid));

            note.rawNoteData = daNoteInfo;

            Current_Notes.add(note);

            if (daSus > 0)
            {
                var sustainVis:FlxSprite = new FlxSprite(note.x + (Grid_Size / 2),
                    note.y + Grid_Size).makeGraphic(8, Math.floor(FlxMath.remapToRange(daSus, 0, Conductor.stepCrochet * SONG.notes[Cur_Section].lengthInSteps, 0, Note_Grid.height)));
                
                Current_Sustains.add(sustainVis);
            }
        }

        for (i in next_sectionInfo)
        {
            var daNoteInfo = i[1];
            var daStrumTime = i[0];
            var daSus = i[2];

            var note:Note = new Note(daStrumTime, daNoteInfo % SONG.keyCount);
            note.sustainLength = daSus;

            note.setGraphicSize(Grid_Size, Grid_Size);
            note.updateHitbox();

            note.x = Note_Grid.x + Math.floor(daNoteInfo * Grid_Size);
            note.y = Math.floor(getYfromStrum((daStrumTime - sectionStartTime(Next_Section)) % (Conductor.stepCrochet * SONG.notes[Next_Section].lengthInSteps), Note_Grid_Below));

            note.rawNoteData = daNoteInfo;

            Current_Notes.add(note);

            if (daSus > 0)
            {
                var sustainVis:FlxSprite = new FlxSprite(note.x + (Grid_Size / 2),
                    note.y + Grid_Size).makeGraphic(8, Math.floor(FlxMath.remapToRange(daSus, 0, Conductor.stepCrochet * SONG.notes[Next_Section].lengthInSteps, 0, Note_Grid_Below.height)));
                
                Current_Sustains.add(sustainVis);
            }
        }
    }

    function loadSong(daSong:String):Void
    {
        if (FlxG.sound.music != null)
            FlxG.sound.music.stop();

        FlxG.sound.music = new FlxSound().loadEmbedded(Paths.inst(daSong));
        FlxG.sound.music.persist = true;
        
        if (SONG.needsVoices)
            Vocal_Track = new FlxSound().loadEmbedded(Paths.voices(daSong));
        else
            Vocal_Track = new FlxSound();

        FlxG.sound.list.add(Vocal_Track);

        FlxG.sound.music.pause();
        Vocal_Track.pause();

        FlxG.sound.music.onComplete = function()
        {
            if(SONG.needsVoices && Vocal_Track.playing)
            {
                Vocal_Track.pause();
                Vocal_Track.time = 0;
            }

            FlxG.sound.music.pause();
            FlxG.sound.music.time = 0;
        };

        Inst_Track = FlxG.sound.music;
    }

    function getYfromStrum(strumTime:Float, ?baseGrid:FlxSprite):Float
    {
        if(baseGrid == null)
            baseGrid = Note_Grid;

        return FlxMath.remapToRange(strumTime, 0, ((16 / Conductor.timeScale[1]) * Conductor.timeScale[0]) * Conductor.stepCrochet, baseGrid.y, baseGrid.y + baseGrid.height);
    }

    function sectionStartTime(?cur_Section:Int):Float
    {
        if(cur_Section == null)
            cur_Section = Cur_Section;

        var daBPM:Float = SONG.bpm;
        var daPos:Float = 0;

        for (i in 0...cur_Section)
        {
            if (SONG.notes[i].changeBPM && SONG.notes[i].bpm != daBPM)
                daBPM = SONG.notes[i].bpm;

            daPos += (16 / Conductor.timeScale[1]) * (1000 * (60 / daBPM));
        }

        return daPos;
    }

    function updateSection()
    {
        var Start_Section = Cur_Section;

        for(i in 0...SONG.notes.length)
        {
            if(sectionStartTime(i) <= Inst_Track.time)
                Cur_Section = i;
        }

        if(Start_Section != Cur_Section)
            updateGrid();
    }

    function addSection(?lengthInSteps:Int = 16):Void
    {
        var sec:SwagSection = {
            lengthInSteps: lengthInSteps,
            bpm: SONG.bpm,
            changeBPM: false,
            mustHitSection: true,
            sectionNotes: [],
            typeOfSection: 0,
            altAnim: false,
            changeTimeScale: false,
            timeScale: Conductor.timeScale
        };

        SONG.notes.push(sec);
    }
}