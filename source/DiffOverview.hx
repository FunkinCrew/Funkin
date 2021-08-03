package;

import Conductor.BPMChangeEvent;
import flixel.FlxCamera;
import flixel.math.FlxRect;
import Song.SwagSong;
import Section.SwagSection;
import flixel.system.FlxSound;
import flixel.input.gamepad.FlxGamepad;
import flixel.util.FlxAxes;
import flixel.FlxSubState;
import Options.Option;
import flixel.input.FlxInput;
import flixel.input.keyboard.FlxKey;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.effects.FlxFlicker;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.util.FlxSort;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import io.newgrounds.NG;
import lime.app.Application;
import lime.utils.Assets;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.input.FlxKeyManager;

using StringTools;

class DiffOverview extends FlxSubState
{
	var blackBox:FlxSprite;

	var handOne:Array<Float>;
	var handTwo:Array<Float>;

	var giantText:FlxText;

	var SONG:SwagSong;
	var strumLine:FlxSprite;
    var camHUD:FlxCamera;

    var offset:FlxText;

	public static var playerStrums:FlxTypedGroup<FlxSprite> = null;

	override function create()
	{
        Conductor.songPosition = 0;
        Conductor.lastSongPos = 0;
        
        camHUD = new FlxCamera();
        camHUD.bgColor.alpha = 0;
        var camGame = new FlxCamera();

        FlxG.cameras.add(camGame);

        FlxG.cameras.add(camHUD);

		FlxCamera.defaultCameras = [camGame];

        playerStrums = new FlxTypedGroup<FlxSprite>();

		SONG = FreeplayState.songData.get(FreeplayState.songs[FreeplayState.curSelected].songName)[FreeplayState.curDifficulty];

		strumLine = new FlxSprite(0, (FlxG.height / 2) - 295).makeGraphic(FlxG.width, 10);
		strumLine.scrollFactor.set();

		blackBox = new FlxSprite(0, 0).makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
        blackBox.alpha = 0;
		add(blackBox);

        FreeplayState.openedPreview = true;

		handOne = DiffCalc.lastDiffHandOne;
		handTwo = DiffCalc.lastDiffHandTwo;
		for (i in 0...4)
		{
			// FlxG.log.add(i);
			var babyArrow:FlxSprite = new FlxSprite(0, strumLine.y);

			babyArrow.frames = Paths.getSparrowAtlas('NOTE_assets','shared');
			babyArrow.animation.addByPrefix('green', 'arrowUP');
			babyArrow.animation.addByPrefix('blue', 'arrowDOWN');
			babyArrow.animation.addByPrefix('purple', 'arrowLEFT');
			babyArrow.animation.addByPrefix('red', 'arrowRIGHT');
			babyArrow.antialiasing = FlxG.save.data.antialiasing;
			babyArrow.setGraphicSize(Std.int(babyArrow.width * 0.7));

			switch (Math.abs(i))
			{
				case 2:
					babyArrow.x += Note.swagWidth * 2;
					babyArrow.animation.addByPrefix('static', 'arrowUP');
					babyArrow.animation.addByPrefix('pressed', 'up press', 24, false);
					babyArrow.animation.addByPrefix('confirm', 'up confirm', 24, false);
				case 3:
					babyArrow.x += Note.swagWidth * 3;
					babyArrow.animation.addByPrefix('static', 'arrowRIGHT');
					babyArrow.animation.addByPrefix('pressed', 'right press', 24, false);
					babyArrow.animation.addByPrefix('confirm', 'right confirm', 24, false);
				case 1:
					babyArrow.x += Note.swagWidth * 1;
					babyArrow.animation.addByPrefix('static', 'arrowDOWN');
					babyArrow.animation.addByPrefix('pressed', 'down press', 24, false);
					babyArrow.animation.addByPrefix('confirm', 'down confirm', 24, false);
				case 0:
					babyArrow.x += Note.swagWidth * 0;
					babyArrow.animation.addByPrefix('static', 'arrowLEFT');
					babyArrow.animation.addByPrefix('pressed', 'left press', 24, false);
					babyArrow.animation.addByPrefix('confirm', 'left confirm', 24, false);
			}

			babyArrow.updateHitbox();
			babyArrow.scrollFactor.set();

			babyArrow.y -= 10;
			babyArrow.alpha = 1;

			babyArrow.ID = i;

			playerStrums.add(babyArrow);

			babyArrow.animation.play('static');
			babyArrow.x += 50;
			babyArrow.x += ((FlxG.width / 2));
		}

        add(playerStrums);

		generateSong("assItch");

        playerStrums.cameras = [camHUD];
        notes.cameras = [camHUD];
        blackBox.cameras = [camHUD];

        blackBox.x = playerStrums.members[0].x;
        blackBox.y = strumLine.y;

        camHUD.zoom = 0.6;
        camHUD.alpha = 0;
        camHUD.height = 5000;
        blackBox.height = camHUD.height;

        camHUD.x += 280;

        blackBox.y -= 100;
        blackBox.x -= 100;

        offset = new FlxText(10,FlxG.height - 40,0,"Offset: " + HelperFunctions.truncateFloat(FlxG.save.data.offset,0) + " (LEFT/RIGHT to decrease/increase)",16);
        offset.setBorderStyle(FlxTextBorderStyle.OUTLINE,FlxColor.BLACK,4,1);
        offset.color = FlxColor.WHITE;
        offset.scrollFactor.set();
        //add(offset);

		FlxTween.tween(blackBox, {alpha: 0.5}, 1, {ease: FlxEase.expoInOut});
		FlxTween.tween(camHUD, {alpha: 1}, 0.5, {ease: FlxEase.expoInOut});
        FlxTween.tween(offset, {alpha: 1}, 0.5, {ease: FlxEase.expoInOut});

        trace('pog');

		super.create();
	}

    function endSong()
    {
        if (stopDoingShit)
            return;
    }

    function resyncVocals():Void
        {
            vocals.pause();
    
            FlxG.sound.music.play();
            Conductor.songPosition = FlxG.sound.music.time;
            vocals.time = Conductor.songPosition;
            vocals.play();
        }

    public var stopDoingShit = false;

    public var currentStep = 0;
    public var oldStep = 0;

    private function updateCurStep():Void
        {
            var lastChange:BPMChangeEvent = {
                stepTime: 0,
                songTime: 0,
                bpm: 0
            }
            for (i in 0...Conductor.bpmChangeMap.length)
            {
                if (Conductor.songPosition >= Conductor.bpmChangeMap[i].songTime)
                    lastChange = Conductor.bpmChangeMap[i];
            }
    
            currentStep = lastChange.stepTime + Math.floor((Conductor.songPosition - lastChange.songTime) / Conductor.stepCrochet);
        }    

    function stepHit()
        {
            if (FlxG.sound.music.time > Conductor.songPosition + 20 || FlxG.sound.music.time < Conductor.songPosition - 20)
            {
                trace("resync");
                resyncVocals();
            }
            oldStep = currentStep;
        }

    function offsetChange()
    {
        for (i in unspawnNotes)
            i.strumTime = i.baseStrum + FlxG.save.data.offset;
        for (i in notes)
            i.strumTime = i.baseStrum + FlxG.save.data.offset;
    }
    
    var frames = 0;

	override function update(elapsed:Float)
	{
		super.update(elapsed);


        // input

        if (frames < 10)
        {
            frames++;
            return;
        }

        if (stopDoingShit)
            return;

        updateCurStep();

        if (oldStep != currentStep && currentStep > 0)
            stepHit();

        if (FlxG.keys.pressed.SPACE)
        {
            stopDoingShit = true;
            quit();
        }

        var gamepad:FlxGamepad = FlxG.gamepads.lastActive;

        if (gamepad != null)
            if (gamepad.justPressed.X)
            {     
                stopDoingShit = true;
                quit();
            }

        /*if (FlxG.keys.pressed.RIGHT)
        {
            if (FlxG.keys.pressed.SHIFT)
            {
                FlxG.save.data.offset++;
                offsetChange();
            }
        }
        if (FlxG.keys.pressed.LEFT)
        {
            if (FlxG.keys.pressed.SHIFT)
            {
                FlxG.save.data.offset--;
                offsetChange();
            }
        }

        if (FlxG.keys.justPressed.RIGHT)
        {
            FlxG.save.data.offset++;
            offsetChange();
        }
        if (FlxG.keys.justPressed.LEFT)
        {
            FlxG.save.data.offset--;
            offsetChange();
        }


        offset.text = "Offset: " + HelperFunctions.truncateFloat(FlxG.save.data.offset,0) + " (LEFT/RIGHT to decrease/increase, SHIFT to go faster) - Time: " + HelperFunctions.truncateFloat(Conductor.songPosition / 1000,0) + "s - Step: " + currentStep;
        */

        if (vocals != null)
            if (vocals.playing)
                Conductor.songPosition += FlxG.elapsed * 1000;

		if (unspawnNotes[0] != null)
		{
			if (unspawnNotes[0].strumTime - Conductor.songPosition < 3500)
			{
				var dunceNote:Note = unspawnNotes[0];
				notes.add(dunceNote);

				var index:Int = unspawnNotes.indexOf(dunceNote);
				unspawnNotes.splice(index, 1);
			}
		}



		notes.forEachAlive(function(daNote:Note)
		{
			// instead of doing stupid y > FlxG.height
			// we be men and actually calculate the time :)
			if (daNote.tooLate)
			{
				daNote.active = false;
				daNote.visible = false;
			}
			else
			{
				daNote.visible = true;
				daNote.active = true;
			}

            daNote.y = (playerStrums.members[Math.floor(Math.abs(daNote.noteData))].y
            - 0.45 * (Conductor.songPosition - daNote.strumTime) * FlxMath.roundDecimal(SONG.speed,
                2));

			if (daNote.isSustainNote)
			{
				daNote.y -= daNote.height / 2;

				if ((!daNote.mustPress || daNote.wasGoodHit || daNote.prevNote.wasGoodHit && !daNote.canBeHit)
					&& daNote.y + daNote.offset.y * daNote.scale.y <= (strumLine.y + Note.swagWidth / 2))
				{
					// Clip to strumline
					var swagRect = new FlxRect(0, 0, daNote.width / daNote.scale.x, daNote.height / daNote.scale.y);
					swagRect.y = (playerStrums.members[Math.floor(Math.abs(daNote.noteData))].y + Note.swagWidth / 2 - daNote.y) / daNote.scale.y;
					swagRect.height -= swagRect.y;

					daNote.clipRect = swagRect;
				}
			}

			daNote.visible = playerStrums.members[Math.floor(Math.abs(daNote.noteData))].visible;
			daNote.x = playerStrums.members[Math.floor(Math.abs(daNote.noteData))].x;
			if (!daNote.isSustainNote)
				daNote.angle = playerStrums.members[Math.floor(Math.abs(daNote.noteData))].angle;
			daNote.alpha = playerStrums.members[Math.floor(Math.abs(daNote.noteData))].alpha;

            // auto hit

            if(daNote.y < strumLine.y)
                {
                    // Force good note hit regardless if it's too late to hit it or not as a fail safe
                    if(daNote.canBeHit && daNote.mustPress || daNote.tooLate && daNote.mustPress)
                    {
                
                        daNote.wasGoodHit = true;
                        vocals.volume = 1;
                
                        daNote.kill();
                        notes.remove(daNote, true);
                        daNote.destroy();
                    }
                }
		});

	}

	function quit()
	{
		FlxTween.tween(blackBox, {alpha: 0}, 1, {ease: FlxEase.expoInOut});
        FlxTween.tween(camHUD, {alpha: 0}, 1, {ease: FlxEase.expoInOut});
        FlxTween.tween(offset, {alpha: 0}, 1, {ease: FlxEase.expoInOut});

        vocals.fadeOut();

        FreeplayState.openedPreview = false;
	}

	var vocals:FlxSound;

	var notes:FlxTypedGroup<Note>;
	var unspawnNotes:Array<Note> = [];

	public function generateSong(dataPath:String):Void
	{
		// FlxG.log.add(ChartParser.parse());

		var songData = FreeplayState.songData.get(FreeplayState.songs[FreeplayState.curSelected].songName)[FreeplayState.curDifficulty];
		Conductor.changeBPM(songData.bpm);

		if (SONG.needsVoices)
			vocals = new FlxSound().loadEmbedded(Paths.voices(SONG.song));
		else
			vocals = new FlxSound();

		trace('loaded vocals');

		FlxG.sound.list.add(vocals);

		notes = new FlxTypedGroup<Note>();
		add(notes);

		var noteData:Array<SwagSection>;

		// NEW SHIT
		noteData = songData.notes;

		var playerCounter:Int = 0;

		var daBeats:Int = 0; // Not exactly representative of 'daBeats' lol, just how much it has looped
		for (section in noteData)
		{
			var coolSection:Int = Std.int(section.lengthInSteps / 4);

			for (songNotes in section.sectionNotes)
			{
				var daStrumTime:Float = songNotes[0] + FlxG.save.data.offset;
				if (daStrumTime < 0)
					daStrumTime = 0;
				var daNoteData:Int = Std.int(songNotes[1] % 4);

				var gottaHitNote:Bool = section.mustHitSection;

				if (songNotes[1] > 3)
				{
					gottaHitNote = !section.mustHitSection;
				}

				var oldNote:Note;
				if (unspawnNotes.length > 0)
					oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];
				else
					oldNote = null;

				var swagNote:Note = new Note(daStrumTime, daNoteData, oldNote,false, true);

                
				if (!gottaHitNote)
					continue;

                swagNote.baseStrum = Math.round(songNotes[0]);

				swagNote.sustainLength = songNotes[2];
				swagNote.scrollFactor.set(0, 0);

				var susLength:Float = swagNote.sustainLength;

				susLength = susLength / Conductor.stepCrochet;
				unspawnNotes.push(swagNote);

				for (susNote in 0...Math.floor(susLength))
				{
					oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];

					var sustainNote:Note = new Note(daStrumTime + (Conductor.stepCrochet * susNote) + Conductor.stepCrochet, daNoteData, oldNote, true, true);
					sustainNote.scrollFactor.set();
					unspawnNotes.push(sustainNote);

					sustainNote.mustPress = gottaHitNote;

					if (sustainNote.mustPress)
					{
						sustainNote.x += FlxG.width / 2; // general offset
					}
				}

				swagNote.mustPress = gottaHitNote;

				if (swagNote.mustPress)
				{
					swagNote.x += FlxG.width / 2; // general offset
				}
				else
				{
				}
			}
			daBeats += 1;
		}

		// trace(unspawnNotes.length);
		// playerCounter += 1;

		unspawnNotes.sort(sortByShit);

        Conductor.mapBPMChanges(SONG);
		Conductor.changeBPM(SONG.bpm);

        FlxG.sound.playMusic(Paths.inst(SONG.song), 1, false);
		FlxG.sound.music.onComplete = endSong;
		vocals.play();
	}

	function sortByShit(Obj1:Note, Obj2:Note):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);
	}
}
