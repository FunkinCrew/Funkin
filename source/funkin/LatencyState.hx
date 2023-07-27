package funkin;

import funkin.data.notestyle.NoteStyleRegistry;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.group.FlxGroup;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.sound.FlxSound;
import flixel.system.debug.stats.StatsGraph;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import funkin.audio.visualize.PolygonSpectogram;
import funkin.play.notes.NoteSprite;
import funkin.ui.CoolStatsGraph;
import haxe.Timer;
import openfl.events.KeyboardEvent;

class LatencyState extends MusicBeatSubState
{
  var offsetText:FlxText;
  var noteGrp:FlxTypedGroup<NoteSprite>;
  var strumLine:FlxSprite;

  var blocks:FlxTypedGroup<FlxSprite>;

  var songPosVis:FlxSprite;
  var songVisFollowVideo:FlxSprite;
  var songVisFollowAudio:FlxSprite;

  var beatTrail:FlxSprite;
  var diffGrp:FlxTypedGroup<FlxText>;
  var offsetsPerBeat:Array<Int> = [];
  var swagSong:HomemadeMusic;

  #if FLX_DEBUG
  var funnyStatsGraph:CoolStatsGraph;
  var realStats:CoolStatsGraph;
  #end

  override function create()
  {
    swagSong = new HomemadeMusic();
    swagSong.loadEmbedded(Paths.sound('soundTest'), true);

    FlxG.sound.music = swagSong;
    FlxG.sound.music.play();

    #if FLX_DEBUG
    funnyStatsGraph = new CoolStatsGraph(0, Std.int(FlxG.height / 2), FlxG.width, Std.int(FlxG.height / 2), FlxColor.PINK, "time");
    FlxG.addChildBelowMouse(funnyStatsGraph);

    realStats = new CoolStatsGraph(0, Std.int(FlxG.height / 2), FlxG.width, Std.int(FlxG.height / 2), FlxColor.YELLOW, "REAL");
    FlxG.addChildBelowMouse(realStats);
    #end

    FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, key -> {
      trace(key.charCode);

      if (key.charCode == 120) generateBeatStuff();

      trace("\tEVENT PRESS: \t" + FlxG.sound.music.time + " " + Timer.stamp());
      // trace(FlxG.sound.music.prevTimestamp);
      trace(FlxG.sound.music.time);
      trace("\tFR FR PRESS: \t" + swagSong.getTimeWithDiff());

      // trace("\tREDDIT: \t" + swagSong.frfrTime + " " + Timer.stamp());
      @:privateAccess
      trace("\tREDDIT: \t" + FlxG.sound.music._channel.position + " " + Timer.stamp());
      // trace("EVENT LISTENER: " + key);
    });

    // FlxG.sound.playMusic(Paths.sound('soundTest'));

    // funnyStatsGraph.hi

    Conductor.forceBPM(60);

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

    for (beat in 0...Math.floor(FlxG.sound.music.length / Conductor.beatLengthMs))
    {
      var beatTick:FlxSprite = new FlxSprite(songPosToX(beat * Conductor.beatLengthMs), FlxG.height - 15);
      beatTick.makeGraphic(2, 15);
      beatTick.alpha = 0.3;
      add(beatTick);

      var offsetTxt:FlxText = new FlxText(songPosToX(beat * Conductor.beatLengthMs), FlxG.height - 26, 0, "swag");
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
      var note:NoteSprite = new NoteSprite(NoteStyleRegistry.instance.fetchDefault(), Conductor.beatLengthMs * i);
      noteGrp.add(note);
    }

    offsetText = new FlxText();
    offsetText.screenCenter();
    add(offsetText);

    strumLine = new FlxSprite(FlxG.width / 2, 100).makeGraphic(FlxG.width, 5);
    add(strumLine);

    super.create();
  }

  override function stepHit():Bool
  {
    if (Conductor.currentStep % 4 == 2)
    {
      blocks.members[((Conductor.currentBeat % 8) + 1) % 8].alpha = 0.5;
    }

    return super.stepHit();
  }

  override function beatHit():Bool
  {
    if (Conductor.currentBeat % 8 == 0) blocks.forEach(blok -> {
      blok.alpha = 0;
    });

    blocks.members[Conductor.currentBeat % 8].alpha = 1;
    // block.visible = !block.visible;

    return super.beatHit();
  }

  override function update(elapsed:Float)
  {
    /* trace("1: " + swagSong.frfrTime);
      @:privateAccess
      trace(FlxG.sound.music._channel.position);
     */

    #if FLX_DEBUG
    funnyStatsGraph.update(FlxG.sound.music.time % 500);
    realStats.update(swagSong.getTimeWithDiff() % 500);
    #end

    if (FlxG.keys.justPressed.S)
    {
      trace("\tUPDATE PRESS: \t" + FlxG.sound.music.time + " " + Timer.stamp());
    }

    if (FlxG.keys.justPressed.SPACE)
    {
      if (FlxG.sound.music.playing) FlxG.sound.music.pause();
      else
        FlxG.sound.music.resume();
    }

    if (FlxG.keys.pressed.D) FlxG.sound.music.time += 1000 * FlxG.elapsed;

    Conductor.update(swagSong.getTimeWithDiff() - Conductor.offset);
    // Conductor.songPosition += (Timer.stamp() * 1000) - FlxG.sound.music.prevTimestamp;

    songPosVis.x = songPosToX(Conductor.songPosition);
    songVisFollowAudio.x = songPosToX(Conductor.songPosition - Conductor.audioOffset);
    songVisFollowVideo.x = songPosToX(Conductor.songPosition - Conductor.visualOffset);

    offsetText.text = "AUDIO Offset: " + Conductor.audioOffset + "ms";
    offsetText.text += "\nVIDOE Offset: " + Conductor.visualOffset + "ms";
    offsetText.text += "\ncurrentStep: " + Conductor.currentStep;
    offsetText.text += "\ncurrentBeat: " + Conductor.currentBeat;

    var avgOffsetInput:Float = 0;

    for (offsetThing in offsetsPerBeat)
      avgOffsetInput += offsetThing;

    avgOffsetInput /= offsetsPerBeat.length;

    offsetText.text += "\naverage input offset needed: " + avgOffsetInput;

    var multiply:Float = 10;

    if (FlxG.keys.pressed.SHIFT) multiply = 1;

    if (FlxG.keys.pressed.CONTROL)
    {
      if (FlxG.keys.justPressed.RIGHT)
      {
        Conductor.audioOffset += 1 * multiply;
      }

      if (FlxG.keys.justPressed.LEFT)
      {
        Conductor.audioOffset -= 1 * multiply;
      }
    }
    else
    {
      if (FlxG.keys.justPressed.RIGHT)
      {
        Conductor.visualOffset += 1 * multiply;
      }

      if (FlxG.keys.justPressed.LEFT)
      {
        Conductor.visualOffset -= 1 * multiply;
      }
    }

    /* if (FlxG.keys.justPressed.SPACE)
      {
        FlxG.sound.music.stop();

        FlxG.resetState();
    }*/

    noteGrp.forEach(function(daNote:NoteSprite) {
      daNote.y = (strumLine.y - ((Conductor.songPosition - Conductor.audioOffset) - daNote.noteData.time) * 0.45);
      daNote.x = strumLine.x + 30;

      if (daNote.y < strumLine.y) daNote.alpha = 0.5;

      if (daNote.y < 0 - daNote.height)
      {
        daNote.alpha = 1;
        // daNote.data.strumTime += Conductor.beatLengthMs * 8;
      }
    });

    super.update(elapsed);
  }

  function generateBeatStuff()
  {
    Conductor.songPosition = swagSong.getTimeWithDiff();

    var closestBeat:Int = Math.round(Conductor.songPosition / Conductor.beatLengthMs) % diffGrp.members.length;
    var getDiff:Float = Conductor.songPosition - (closestBeat * Conductor.beatLengthMs);
    getDiff -= Conductor.visualOffset;

    // lil fix for end of song
    if (closestBeat == 0 && getDiff >= Conductor.beatLengthMs * 2) getDiff -= FlxG.sound.music.length;

    trace("\tDISTANCE TO CLOSEST BEAT: " + getDiff + "ms");
    trace("\tCLOSEST BEAT: " + closestBeat);
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
  public var timeWithDiff:Float = 0;

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
