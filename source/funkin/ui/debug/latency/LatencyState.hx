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
import haxe.Timer;
import openfl.events.KeyboardEvent;
import funkin.input.PreciseInputManager;
import funkin.play.notes.Strumline;
import funkin.play.notes.notestyle.NoteStyle;
import funkin.data.notestyle.NoteStyleData;
import funkin.data.notestyle.NoteStyleRegistry;

class LatencyState extends MusicBeatSubState
{
  var offsetText:FlxText;
  var noteGrp:FlxTypedGroup<NoteSprite>;
  var strumLine:Strumline;

  var blocks:FlxTypedGroup<FlxSprite>;

  var songPosVis:FlxSprite;
  var songVisFollowVideo:FlxSprite;
  var songVisFollowAudio:FlxSprite;

  var beatTrail:FlxSprite;
  var diffGrp:FlxTypedGroup<FlxText>;
  var offsetsPerBeat:Array<Int> = [];
  var swagSong:HomemadeMusic;

  var funnyStatsGraph:CoolStatsGraph;
  var realStats:CoolStatsGraph;

  override function create()
  {
    super.create();

    if (FlxG.sound.music != null) FlxG.sound.music.stop();

    swagSong = new HomemadeMusic();
    swagSong.loadEmbedded(Paths.sound('soundTest'), true);

    FlxG.sound.music = swagSong;
    FlxG.sound.music.play();

    funnyStatsGraph = new CoolStatsGraph(0, Std.int(FlxG.height / 3), Std.int(FlxG.width / 2), Std.int(FlxG.height / 3), FlxColor.PINK, "time");
    funnyStatsGraph.curLabel.y += 32;
    FlxG.addChildBelowMouse(funnyStatsGraph);

    realStats = new CoolStatsGraph(0, Std.int(FlxG.height / 3), Std.int(FlxG.width / 2), Std.int(FlxG.height / 3), FlxColor.YELLOW, "REAL");
    realStats.curLabel.y -= 32;
    FlxG.addChildBelowMouse(realStats);

    PreciseInputManager.instance.onInputPressed.add(function(event:PreciseInputEvent) {
      strumLine.pressKey(event.noteDirection);
      strumLine.playPress(event.noteDirection);
      generateBeatStuff(event);
    });

    PreciseInputManager.instance.onInputReleased.add(function(event:PreciseInputEvent) {
      strumLine.playStatic(event.noteDirection);
      strumLine.releaseKey(event.noteDirection);
    });

    Conductor.instance.forceBPM(60);

    noteGrp = new FlxTypedGroup<NoteSprite>();
    add(noteGrp);

    diffGrp = new FlxTypedGroup<FlxText>();
    add(diffGrp);

    // var musSpec:PolygonSpectogram = new PolygonSpectogram(FlxG.sound.music, FlxColor.RED, FlxG.height, Math.floor(FlxG.height / 2));
    // musSpec.x += 170;
    // musSpec.scrollFactor.set();
    // musSpec.waveAmplitude = 100;
    // musSpec.realtimeVisLenght = 0.45;
    // // musSpec.visType = FREQUENCIES;
    // add(musSpec);

    for (beat in 0...Math.floor(FlxG.sound.music.length / (Conductor.instance.stepLengthMs * 2)))
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
      var block = new FlxSprite(2, 50 * i).makeGraphic(48, 48);
      block.alpha = 0;
      blocks.add(block);
    }

    for (i in 0...32)
    {
      var note:NoteSprite = new NoteSprite(NoteStyleRegistry.instance.fetchDefault(), (Conductor.instance.stepLengthMs * 2) * i);
      noteGrp.add(note);
    }

    offsetText = new FlxText();
    offsetText.size = 20;
    offsetText.screenCenter();
    add(offsetText);

    strumLine = new Strumline(NoteStyleRegistry.instance.fetchDefault(), true);
    add(strumLine);
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
      blok.alpha = 0;
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

    funnyStatsGraph.update(Conductor.instance.songPosition % 500);
    realStats.update(swagSong.getTimeWithDiff() % 500);

    // if (FlxG.keys.justPressed.SPACE)
    // {
    //   if (FlxG.sound.music.playing) FlxG.sound.music.pause();
    //   else
    //     FlxG.sound.music.resume();
    // }

    Conductor.instance.update();
    // Conductor.instance.songPosition += (Timer.stamp() * 1000) - FlxG.sound.music.prevTimestamp;

    songPosVis.x = songPosToX(Conductor.instance.songPosition);
    songVisFollowAudio.x = songPosToX(Conductor.instance.songPosition - Conductor.instance.instrumentalOffset);
    songVisFollowVideo.x = songPosToX(Conductor.instance.songPosition - Conductor.instance.inputOffset);

    offsetText.text = "INST Offset (CTRL+Left/Right to change): " + Conductor.instance.instrumentalOffset + "ms";
    offsetText.text += "\nINPUT Offset (Left/Right to change): " + Conductor.instance.inputOffset + "ms";
    offsetText.text += "\ncurrentStep: " + Conductor.instance.currentStep;
    offsetText.text += "\ncurrentBeat: " + Conductor.instance.currentBeat;

    var avgOffsetInput:Float = 0;

    for (offsetThing in offsetsPerBeat)
      avgOffsetInput += offsetThing;

    avgOffsetInput /= offsetsPerBeat.length;

    offsetText.text += "\naverage input offset needed: " + avgOffsetInput;

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

    /* if (FlxG.keys.justPressed.SPACE)
      {
        FlxG.sound.music.stop();

        FlxG.resetState();
    }*/

    noteGrp.forEach(function(daNote:NoteSprite) {
      daNote.y = (strumLine.y - ((Conductor.instance.songPosition - Conductor.instance.instrumentalOffset) - daNote.strumTime) * 0.45);
      daNote.x = strumLine.x + 30;

      if (daNote.y < strumLine.y) daNote.alpha = 0.5;

      if (daNote.y < 0 - daNote.height)
      {
        daNote.alpha = 1;
        // daNote.data.strumTime += Conductor.instance.beatLengthMs * 8;
      }
    });

    super.update(elapsed);
  }

  function generateBeatStuff(event:PreciseInputEvent)
  {
    // Conductor.instance.update(swagSong.getTimeWithDiff());

    var inputLatencyMs:Float = haxe.Int64.toInt(PreciseInputManager.getCurrentTimestamp() - event.timestamp) / 1000.0 / 1000.0;
    trace("input latency: " + inputLatencyMs + "ms");
    trace("cur timestamp: " + PreciseInputManager.getCurrentTimestamp() + "ns");
    trace("event timestamp: " + event.timestamp + "ns");

    var closestBeat:Int = Math.round(Conductor.instance.songPosition / (Conductor.instance.stepLengthMs * 2)) % diffGrp.members.length;
    var getDiff:Float = Conductor.instance.songPosition - (closestBeat * (Conductor.instance.stepLengthMs * 2));
    getDiff -= Conductor.instance.inputOffset;
    getDiff -= inputLatencyMs;

    // lil fix for end of song
    if (closestBeat == 0 && getDiff >= Conductor.instance.stepLengthMs * 2) getDiff -= FlxG.sound.music.length;

    beatTrail.x = songPosVis.x;

    diffGrp.members[closestBeat].text = getDiff + "ms";
    offsetsPerBeat[closestBeat] = Std.int(getDiff);
  }

  function songPosToX(pos:Float):Float
  {
    return FlxMath.remapToRange(pos, 0, FlxG.sound.music.length, 0, FlxG.width);
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
