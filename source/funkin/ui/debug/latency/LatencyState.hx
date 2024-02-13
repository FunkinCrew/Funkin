package funkin.ui.debug.latency;

import funkin.data.notestyle.NoteStyleRegistry;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.group.FlxGroup;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import funkin.ui.MusicBeatSubState;
import flixel.sound.FlxSound;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import funkin.audio.visualize.PolygonSpectogram;
import funkin.play.notes.NoteSprite;
import funkin.ui.debug.latency.CoolStatsGraph;
import openfl.events.KeyboardEvent;
import funkin.input.PreciseInputManager;
import funkin.play.notes.Strumline;
import funkin.play.notes.notestyle.NoteStyle;
import funkin.data.notestyle.NoteStyleData;
import funkin.data.notestyle.NoteStyleRegistry;
import funkin.data.song.SongData.SongNoteData;
import haxe.Timer;
import flixel.FlxCamera;

class LatencyState extends MusicBeatSubState
{
  var visualOffsetText:FlxText;
  var offsetText:FlxText;
  var noteGrp:Array<SongNoteData>;
  var strumLine:Strumline;

  var blocks:FlxTypedGroup<FlxSprite>;

  var songPosVis:FlxSprite;
  var songVisFollowVideo:FlxSprite;
  var songVisFollowAudio:FlxSprite;

  var beatTrail:FlxSprite;
  var diffGrp:FlxTypedGroup<FlxText>;
  var offsetsPerBeat:Array<Int> = [];
  var swagSong:FlxSound;

  var previousVolume:Float;

  var stateCamera:FlxCamera;

  override function create()
  {
    super.create();

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

    swagSong = new FlxSound();
    swagSong.loadEmbedded(Paths.sound('soundTest'), true);
    swagSong.looped = true;
    swagSong.play();

    PreciseInputManager.instance.onInputPressed.add(preciseInputPressed);

    PreciseInputManager.instance.onInputReleased.add(preciseInputReleased);

    Conductor.instance.forceBPM(60);

    noteGrp = [];

    diffGrp = new FlxTypedGroup<FlxText>();
    add(diffGrp);

    for (beat in 0...Math.floor(swagSong.length / (Conductor.instance.stepLengthMs * 2)))
    {
      var beatTick:FlxSprite = new FlxSprite(songPosToX(beat * (Conductor.instance.stepLengthMs * 2)), FlxG.height - 15);
      beatTick.makeGraphic(2, 15);
      beatTick.alpha = 0.3;
      add(beatTick);

      var offsetTxt:FlxText = new FlxText(songPosToX(beat * (Conductor.instance.stepLengthMs * 2)), FlxG.height - 26, 0, "swag");
      offsetTxt.alpha = 0.5;
      diffGrp.add(offsetTxt);

      offsetsPerBeat.push(0);
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

    offsetText = new FlxText();
    offsetText.setFormat(Paths.font("vcr.ttf"), 20);
    offsetText.x = strumLine.x + strumLine.width + 10;
    offsetText.y = 10;
    offsetText.fieldWidth = FlxG.width - offsetText.x - 10;
    add(offsetText);

    var helpText:FlxText = new FlxText();
    helpText.setFormat(Paths.font("vcr.ttf"), 20);
    helpText.text = "Press ESC to return to main menu";
    helpText.x = FlxG.width - helpText.width;
    helpText.y = FlxG.height - helpText.height - 2;
    add(helpText);

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
    PreciseInputManager.instance.onInputPressed.remove(preciseInputPressed);

    PreciseInputManager.instance.onInputReleased.remove(preciseInputReleased);

    FlxG.sound.music.volume = previousVolume;
    swagSong.stop();

    FlxG.cameras.remove(stateCamera);

    super.close();
  }

  function regenNoteData()
  {
    for (i in 0...32)
    {
      var note:SongNoteData = new SongNoteData((Conductor.instance.stepLengthMs * 2) * i, 1);
      noteGrp.push(note);
    }

    strumLine.applyNoteData(noteGrp);
  }

  override function stepHit():Bool
  {
    if (Conductor.instance.currentStep % 4 == 2)
    {
      blocks.members[((Conductor.instance.currentBeat % 8) + 1) % 8].alpha = 0.5;
    }

    return super.stepHit();
  }

  override function beatHit():Bool
  {
    if (Conductor.instance.currentBeat % 8 == 0) blocks.forEach(blok -> {
      blok.alpha = 0.1;
    });

    blocks.members[Conductor.instance.currentBeat % 8].alpha = 1;
    // block.visible = !block.visible;

    return super.beatHit();
  }

  override function update(elapsed:Float)
  {
    /* trace("1: " + swagSong.frfrTime);
      @:privateAccess
      trace(FlxG.sound.music._channel.position);
     */

    Conductor.instance.update(swagSong.position);

    // Conductor.instance.songPosition += (Timer.stamp() * 1000) - FlxG.sound.music.prevTimestamp;

    songPosVis.x = songPosToX(Conductor.instance.songPosition);
    songVisFollowAudio.x = songPosToX(Conductor.instance.songPosition - Conductor.instance.instrumentalOffset);
    songVisFollowVideo.x = songPosToX(Conductor.instance.songPosition - Conductor.instance.inputOffset);

    visualOffsetText.text = "Visual Offset: " + Conductor.instance.instrumentalOffset + "ms";
    visualOffsetText.text += "\nYou can press SPACE+Left/Right to change this value.";

    offsetText.text = "INPUT Offset (Left/Right to change): " + Conductor.instance.inputOffset + "ms";

    var avgOffsetInput:Float = 0;

    for (offsetThing in offsetsPerBeat)
      avgOffsetInput += offsetThing;

    avgOffsetInput /= offsetsPerBeat.length;

    offsetText.text += "\nEstimated average input offset needed: " + avgOffsetInput;

    var multiply:Int = 10;

    if (FlxG.keys.pressed.SHIFT) multiply = 1;

    if (FlxG.keys.pressed.CONTROL || FlxG.keys.pressed.SPACE)
    {
      if (FlxG.keys.justPressed.RIGHT)
      {
        Conductor.instance.instrumentalOffset += 1 * multiply;
      }

      if (FlxG.keys.justPressed.LEFT)
      {
        Conductor.instance.instrumentalOffset -= 1 * multiply;
      }
    }
    else
    {
      if (FlxG.keys.justPressed.RIGHT)
      {
        Conductor.instance.inputOffset += 1 * multiply;
      }

      if (FlxG.keys.justPressed.LEFT)
      {
        Conductor.instance.inputOffset -= 1 * multiply;
      }
    }

    if (FlxG.keys.justPressed.ESCAPE)
    {
      close();
    }

    super.update(elapsed);
  }

  function generateBeatStuff(event:PreciseInputEvent)
  {
    // Conductor.instance.update(swagSong.getTimeWithDiff());

    var inputLatencyMs:Float = haxe.Int64.toInt(PreciseInputManager.getCurrentTimestamp() - event.timestamp) / 1000.0 / 1000.0;
    trace("input latency: " + inputLatencyMs + "ms");
    trace("cur timestamp: " + PreciseInputManager.getCurrentTimestamp() + "ns");
    trace("event timestamp: " + event.timestamp + "ns");
    trace("songtime: " + Conductor.instance.getTimeWithDiff(swagSong) + "ms");

    var closestBeat:Int = Math.round(Conductor.instance.getTimeWithDiff(swagSong) / (Conductor.instance.stepLengthMs * 2)) % diffGrp.members.length;
    var getDiff:Float = Conductor.instance.getTimeWithDiff(swagSong) - (closestBeat * (Conductor.instance.stepLengthMs * 2));
    // getDiff -= Conductor.instance.inputOffset;
    getDiff -= inputLatencyMs;

    // lil fix for end of song
    if (closestBeat == 0 && getDiff >= Conductor.instance.stepLengthMs * 2) getDiff -= swagSong.length;

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
