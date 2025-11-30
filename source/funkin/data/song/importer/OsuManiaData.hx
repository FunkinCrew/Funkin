package funkin.data.song.importer;

/**
 * Structure of a parsed Osu!Mania .osu file
 * Stuctured like a INI file format by CSV for HitObjects and more
 */
typedef OsuManiaData =
{
  var General:
    {
      var PreviewTime:Int;
    };
  var Editor:
    {
      var DistanceSpacing:Float;
      var BeatDivisor:Int;
      var GridSize:Int;
    };
  var Metadata:
    {
      var Title:String;
      var TitleUnicode:String;
      var Artist:String;
      var ArtistUnicode:String;
      var Creator:String;
      var Version:String;
    };
  var Difficulty:
    {
      var OverallDifficulty:Int;
      var SliderMultiplier:Float;
      var SliderTickRate:Float;
      var CircleSize:Int;
    };
  var HitObjects:Array<ManiaHitObject>;
  var TimingPoints:Array<TimingPoint>;
  var Events:Array<Any>;
}

class TimingPoint
{
  public var time:Float;
  public var beatLength:Float;
  public var meter:Int;
  public var sampleSet:Int;
  public var sampleIndex:Int;
  public var volume:Int;
  public var uninherited:Int;
  public var effects:Int;
  public var bpm:Null<Float>;
  public var sv:Null<Float>;

  public function new(time:Float, beatLength:Float, meter:Int, sampleSet:Int, sampleIndex:Int, volume:Int, uninherited:Int, effects:Int)
  {
    this.time = time;
    this.beatLength = beatLength;
    this.meter = meter;
    this.sampleSet = sampleSet;
    this.sampleIndex = sampleIndex;
    this.volume = volume;
    this.uninherited = uninherited;
    this.effects = effects;

    // Derived values
    this.bpm = (uninherited == 1) ? (Math.round((60000 / beatLength) * 10) / 10) : null;
    this.sv = (uninherited == 0) ? (beatLength / 100) : null; // Just incase someone wants to add Scroll Velocity Support
  }
}

class ManiaHitObject
{
  public var time:Int;
  public var column:Int;
  public var holdDuration:Int;

  public function new(time:Int, column:Int, holdDuration:Int)
  {
    this.time = time;
    this.column = column;
    this.holdDuration = holdDuration;
  }
}
