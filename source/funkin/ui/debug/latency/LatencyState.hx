package funkin.ui.debug.latency;

import funkin.data.notestyle.NoteStyleRegistry;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import funkin.ui.MusicBeatSubState;
import flixel.sound.FlxSound;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import funkin.input.PreciseInputManager;
import funkin.play.notes.Strumline;
import funkin.ui.mainmenu.MainMenuState;
import funkin.data.song.SongData.SongNoteData;
#if mobile
import funkin.util.TouchUtil;
import funkin.mobile.ui.FunkinHitbox;
import funkin.play.notes.NoteDirection;
import funkin.graphics.FunkinSprite;
#end
import haxe.Timer;
import flixel.FlxCamera;

class LatencyState extends MusicBeatSubState
{
  var visualOffsetText:FlxText;
  #if mobile
  var visualOffsetLeftArrow:FlxText;
  var visualOffsetRightArrow:FlxText;
  #end

  var offsetText:FlxText;
  #if mobile
  var offsetLeftArrow:FlxText;
  var offsetRightArrow:FlxText;
  #end

  var helpText:FlxText;
  var noteGrp:Array<SongNoteData> = [];
  var strumLine:Strumline;

  var blocks:FlxTypedGroup<FlxSprite>;

  var songPosVis:FlxSprite;
  var songVisFollowVideo:FlxSprite;
  var songVisFollowAudio:FlxSprite;

  var beatTrail:FlxSprite;
  var diffGrp:FlxTypedGroup<FlxText>;
  var offsetsPerBeat:Array<Null<Int>> = [];
  var swagSong:HomemadeMusic;

  var previousVolume:Float;

  var stateCamera:FlxCamera;

  /**
   * A local conductor instance for this testing class, in-case we are in a PlayState
   * because I'm too lazy to set the old variables for conductor stuff !
   */
  var localConductor:Conductor;

  // stores values of what the previous persistent draw/update stuff was, example if opened
  // from pause menu, we want to NOT draw persistently, but then resume drawing once closed
  var prevPersistentDraw:Bool;
  var prevPersistentUpdate:Bool;

  override function create()
  {
    super.create();

    prevPersistentDraw = FlxG.state.persistentDraw;
    prevPersistentUpdate = FlxG.state.persistentUpdate;

    FlxG.state.persistentDraw = false;
    FlxG.state.persistentUpdate = false;

    localConductor = new Conductor();
    conductorInUse = localConductor;

    stateCamera = new FlxCamera(0, 0, FlxG.width, FlxG.height);
    stateCamera.bgColor = FlxColor.BLACK;
    FlxG.cameras.add(stateCamera);

    var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
    add(bg);

    if (FlxG.sound.music != null)
    {
      previousVolume = FlxG.sound.music.volume;
      FlxG.sound.music.volume = 0; // only want to mute the volume, incase we are coming from pause menu
    }
    else
      previousVolume = 1; // defaults to 1 if no music is playing 🤔 also fuck it, emoji in code comment

    swagSong = new HomemadeMusic();
    swagSong.loadEmbedded(Paths.sound('soundTest'), true);
    swagSong.looped = true;
    swagSong.play();
    FlxG.sound.list.add(swagSong);

    PreciseInputManager.instance.onInputPressed.add(preciseInputPressed);

    PreciseInputManager.instance.onInputReleased.add(preciseInputReleased);

    localConductor.forceBPM(60);

    Conductor.instance.forceBPM(60);

    diffGrp = new FlxTypedGroup<FlxText>();
    add(diffGrp);

    for (beat in 0...Math.floor(swagSong.length / (localConductor.stepLengthMs * 2)))
    {
      var beatTick:FlxSprite = new FlxSprite(songPosToX(beat * (localConductor.stepLengthMs * 2)), FlxG.height - 15);
      beatTick.makeGraphic(2, 15);
      beatTick.alpha = 0.3;
      add(beatTick);

      var offsetTxt:FlxText = new FlxText(songPosToX(beat * (localConductor.stepLengthMs * 2)), FlxG.height - 26, 0, "");
      offsetTxt.alpha = 0.5;
      diffGrp.add(offsetTxt);

      offsetsPerBeat.push(null);
    }

    songVisFollowAudio = new FlxSprite(0, FlxG.height - 20).makeGraphic(2, 20, FlxColor.YELLOW);
    add(songVisFollowAudio);

    songVisFollowVideo = new FlxSprite(0, FlxG.height - 20).makeGraphic(2, 20, FlxColor.BLUE);
    add(songVisFollowVideo);

    songPosVis = new FlxSprite(0, FlxG.height - 20).makeGraphic(2, 20, FlxColor.RED);
    add(songPosVis);

    beatTrail = new FlxSprite(0, songPosVis.y).makeGraphic(2, 20, FlxColor.PURPLE);
    beatTrail.alpha = 0.7;
    add(beatTrail);

    blocks = new FlxTypedGroup<FlxSprite>();
    add(blocks);

    for (i in 0...8)
    {
      var block = new FlxSprite(2, ((FlxG.height / 8) + 2) * i).makeGraphic(Std.int(FlxG.height / 8), Std.int((FlxG.height / 8) - 4));
      block.alpha = 0.1;
      blocks.add(block);
    }

    var strumlineBG:FlxSprite = new FlxSprite();
    add(strumlineBG);

    strumLine = new Strumline(NoteStyleRegistry.instance.fetchDefault(), true);
    strumLine.conductorInUse = localConductor;
    strumLine.screenCenter();
    add(strumLine);

    strumlineBG.x = strumLine.x;
    strumlineBG.makeGraphic(Std.int(strumLine.width), FlxG.height, 0xFFFFFFFF);
    strumlineBG.alpha = 0.1;

    visualOffsetText = new FlxText();
    visualOffsetText.setFormat(Paths.font("vcr.ttf"), 20);
    visualOffsetText.x = (FlxG.height / 8) + 10;
    visualOffsetText.y = 10;
    visualOffsetText.fieldWidth = strumLine.x - visualOffsetText.x - 10;
    add(visualOffsetText);

    #if mobile
    visualOffsetLeftArrow = new FlxText();
    visualOffsetLeftArrow.setFormat(Paths.font("vcr.ttf"), 60);
    visualOffsetLeftArrow.text = "<";
    visualOffsetLeftArrow.x = visualOffsetText.x;
    visualOffsetLeftArrow.y = visualOffsetText.y * 4;
    add(visualOffsetLeftArrow);

    visualOffsetRightArrow = new FlxText();
    visualOffsetRightArrow.setFormat(Paths.font("vcr.ttf"), 60);
    visualOffsetRightArrow.text = ">";
    visualOffsetRightArrow.x = visualOffsetLeftArrow.x * 2;
    visualOffsetRightArrow.y = visualOffsetLeftArrow.y;
    add(visualOffsetRightArrow);
    #end

    offsetText = new FlxText();
    offsetText.setFormat(Paths.font("vcr.ttf"), 20);
    offsetText.x = strumLine.x + strumLine.width + 10;
    offsetText.y = 10;
    offsetText.fieldWidth = FlxG.width - offsetText.x - 10;
    add(offsetText);

    #if mobile
    offsetLeftArrow = new FlxText();
    offsetLeftArrow.setFormat(Paths.font("vcr.ttf"), 60);
    offsetLeftArrow.text = "<";
    offsetLeftArrow.x = offsetText.x;
    offsetLeftArrow.y = offsetText.y * 9;
    add(offsetLeftArrow);

    offsetRightArrow = new FlxText();
    offsetRightArrow.setFormat(Paths.font("vcr.ttf"), 60);
    offsetRightArrow.text = ">";
    offsetRightArrow.x = offsetLeftArrow.x * 1.2;
    offsetRightArrow.y = offsetLeftArrow.y;
    add(offsetRightArrow);
    #end

    helpText = new FlxText();
    helpText.setFormat(Paths.font("vcr.ttf"), 20 #if mobile * 3 #end);
    helpText.text = #if mobile "Back" #else "Press BACK to return to main menu" #end;
    helpText.x = FlxG.width - helpText.width #if mobile * 1.5 #end;
    helpText.y = FlxG.height - (helpText.height * 2) - 2;
    add(helpText);

    #if mobile
    addHitbox(true, true, FunkinHitboxControlSchemes.FourLanes, [NoteDirection.DOWN], [0xFF00FFFF]);

    hitbox.forEachAlive(function(hint:FunkinHint) {
      @:privateAccess
      if (hint.label != null) hint.label.visible = false;

      for (text in [
        helpText,
        visualOffsetLeftArrow,
        visualOffsetRightArrow,
        offsetLeftArrow,
        offsetRightArrow
      ])
        hint.deadZones.push(cast(text, FunkinSprite));
    });
    #end

    regenNoteData();
  }

  function preciseInputPressed(event:PreciseInputEvent)
  {
    generateBeatStuff(event);
    strumLine.pressKey(event.noteDirection);
    strumLine.playPress(event.noteDirection);
  }

  function preciseInputReleased(event:PreciseInputEvent)
  {
    strumLine.playStatic(event.noteDirection);
    strumLine.releaseKey(event.noteDirection);
  }

  override public function close():Void
  {
    cleanup();
    super.close();
  }

  function cleanup():Void
  {
    PreciseInputManager.instance.onInputPressed.remove(preciseInputPressed);
    PreciseInputManager.instance.onInputReleased.remove(preciseInputReleased);

    if (FlxG.sound.music != null)
    {
      FlxG.sound.music.volume = previousVolume;
    }

    swagSong.stop();
    FlxG.sound.list.remove(swagSong);

    FlxG.cameras.remove(stateCamera);

    FlxG.state.persistentDraw = prevPersistentDraw;
    FlxG.state.persistentUpdate = prevPersistentUpdate;
  }

  function regenNoteData()
  {
    for (i in 0...32)
    {
      var note:SongNoteData = new SongNoteData((localConductor.stepLengthMs * 2) * i, 1);
      noteGrp.push(note);
    }

    strumLine.applyNoteData(noteGrp);
  }

  override function stepHit():Bool
  {
    if (localConductor.currentStep % 4 == 2)
    {
      blocks.members[((localConductor.currentBeat % 8) + 1) % 8].alpha = 0.5;
    }

    return super.stepHit();
  }

  override function beatHit():Bool
  {
    if (localConductor.currentBeat % 8 == 0) blocks.forEach(blok -> {
      blok.alpha = 0.1;
    });

    blocks.members[localConductor.currentBeat % 8].alpha = 1;
    // block.visible = !block.visible;

    return super.beatHit();
  }

  override function update(elapsed:Float)
  {
    /* trace("1: " + swagSong.frfrTime);
      @:privateAccess
      trace(FlxG.sound.music._channel.position);
     */

    localConductor.update(swagSong.time, false);

    // localConductor.songPosition += (Timer.stamp() * 1000) - FlxG.sound.music.prevTimestamp;

    songPosVis.x = songPosToX(localConductor.songPosition);
    songVisFollowAudio.x = songPosToX(localConductor.songPosition - localConductor.audioVisualOffset);
    songVisFollowVideo.x = songPosToX(localConductor.songPosition - localConductor.inputOffset);

    visualOffsetText.text = "Visual Offset: " + localConductor.audioVisualOffset + "ms";
    #if !mobile
    visualOffsetText.text += "\n\nYou can press SPACE+Left/Right to change this value.";
    visualOffsetText.text += "\n\nYou can hold SHIFT to step 1ms at a time";
    #end

    #if mobile
    offsetText.text = "INPUT Offset: " + localConductor.inputOffset + "ms";
    #else
    offsetText.text = "INPUT Offset (Left/Right to change): " + localConductor.inputOffset + "ms";
    offsetText.text += "\n\nYou can hold SHIFT to step 1ms at a time";
    #end

    var avgOffsetInput:Float = 0;

    var loopInd:Int = 0;
    for (offsetThing in offsetsPerBeat)
    {
      if (offsetThing == null) continue;
      avgOffsetInput += offsetThing;
      loopInd++;
    }

    avgOffsetInput /= loopInd;

    offsetText.text += "\n\nEstimated average input offset needed: " + avgOffsetInput;

    var multiply:Int = 10;

    if (FlxG.keys.pressed.SHIFT || FlxG.onMobile) multiply = 1;

    #if mobile
    handleSelectionInputMobile(multiply);
    #else
    handleSelectionInput(multiply);
    #end

    if (controls.BACK #if mobile || (TouchUtil.overlapsComplex(helpText) && TouchUtil.justPressed) #end)
    {
      // close();
      cleanup();
      FlxG.switchState(() -> new MainMenuState());
    }

    super.update(elapsed);
  }

  function handleSelectionInput(multiply:Int)
  {
    if (FlxG.keys.pressed.CONTROL || FlxG.keys.pressed.SPACE)
    {
      if (FlxG.keys.justPressed.RIGHT)
      {
        localConductor.audioVisualOffset += 1 * multiply;
      }

      if (FlxG.keys.justPressed.LEFT)
      {
        localConductor.audioVisualOffset -= 1 * multiply;
      }
    }
    else
    {
      if (FlxG.keys.anyJustPressed([LEFT, RIGHT]))
      {
        if (FlxG.keys.justPressed.RIGHT)
        {
          localConductor.inputOffset += 1 * multiply;
        }

        if (FlxG.keys.justPressed.LEFT)
        {
          localConductor.inputOffset -= 1 * multiply;
        }

        // reset the average, so you don't need to wait a full loop to start getting averages
        // also reset each text member
        offsetsPerBeat = [];
        diffGrp.forEach(memb -> memb.text = "");
      }
    }
  }

  #if mobile
  function handleSelectionInputMobile(multiply:Int)
  {
    final touchPressCheck:Bool = TouchUtil.justPressed
      || TouchUtil.pressed
      && TouchUtil.touch != null
      && TouchUtil.touch.ticksDeltaSincePress >= 200;

    if (TouchUtil.overlapsComplex(visualOffsetRightArrow) && touchPressCheck)
    {
      localConductor.audioVisualOffset += 1 * multiply;
    }

    if (TouchUtil.overlapsComplex(visualOffsetLeftArrow) && touchPressCheck)
    {
      localConductor.audioVisualOffset -= 1 * multiply;
    }

    if ((TouchUtil.overlapsComplex(offsetRightArrow) || TouchUtil.overlapsComplex(offsetLeftArrow)) && touchPressCheck)
    {
      if (TouchUtil.overlapsComplex(offsetRightArrow) && touchPressCheck)
      {
        localConductor.inputOffset += 1 * multiply;
      }

      if (TouchUtil.overlapsComplex(offsetLeftArrow) && touchPressCheck)
      {
        localConductor.inputOffset -= 1 * multiply;
      }

      // reset the average, so you don't need to wait a full loop to start getting averages
      // also reset each text member
      offsetsPerBeat = [];
      diffGrp.forEach(memb -> memb.text = "");
    }
  }
  #end

  function generateBeatStuff(event:PreciseInputEvent)
  {
    // localConductor.update(swagSong.getTimeWithDiff());

    var inputLatencyMs:Float = haxe.Int64.toInt(PreciseInputManager.getCurrentTimestamp() - event.timestamp) / 1000.0 / 1000.0;
    // trace("input latency: " + inputLatencyMs + "ms");
    // trace("cur timestamp: " + PreciseInputManager.getCurrentTimestamp() + "ns");
    // trace("event timestamp: " + event.timestamp + "ns");
    // trace("songtime: " + localConductor.getTimeWithDiff(swagSong) + "ms");

    var closestBeat:Int = Math.round(localConductor.getTimeWithDiff(swagSong) / (localConductor.stepLengthMs * 2)) % diffGrp.members.length;
    var getDiff:Float = localConductor.getTimeWithDiff(swagSong) - (closestBeat * (localConductor.stepLengthMs * 2));
    // getDiff -= localConductor.inputOffset;
    getDiff -= inputLatencyMs;
    getDiff -= localConductor.audioVisualOffset;

    // lil fix for end of song
    if (closestBeat == 0 && getDiff >= localConductor.stepLengthMs * 2) getDiff -= swagSong.length;

    beatTrail.x = songPosVis.x;

    diffGrp.members[closestBeat].text = getDiff + "ms";
    offsetsPerBeat[closestBeat] = Math.round(getDiff);
  }

  function songPosToX(pos:Float):Float
  {
    return FlxMath.remapToRange(pos, 0, swagSong.length, 0, FlxG.width);
  }
}

class HomemadeMusic extends FlxSound
{
  public var prevTimestamp:Int = 0;

  public function new()
  {
    super();
  }

  var prevTime:Float = 0;

  override function update(elapsed:Float)
  {
    super.update(elapsed);
    if (prevTime != time)
    {
      prevTime = time;
      prevTimestamp = Std.int(Timer.stamp() * 1000);
    }
  }

  public function getTimeWithDiff():Float
  {
    return time + (Std.int(Timer.stamp() * 1000) - prevTimestamp);
  }
}
