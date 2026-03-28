package funkin.data.song.importer;

typedef QuaverData =
{
  var AudioFile:String;
  var SongPreviewTime:Int;
  var Mode:QuaverMode;
  var Title:String;
  var TitleUnicode:String;
  var Artist:String;
  var ArtistUnicode:String;
  var Creator:String;
  var DifficultyName:String;
  var TimingPoints:Array<QuaverTimingPoint>;
  var SliderVelocities:Array<QuaverSliderVelocity>;
  var HitObjects:Array<QuaverHitObject>;
  var InitialScrollVelocity:Float;
  var HasScratchKey:Bool;
}

enum QuaverMode
{
  Keys4;
  Keys7;
}

class QuaverTimingPoint
{
  public var startTime:Float;
  public var bpm:Float;
  public var signature:Null<Int>; // Numerator of the time signature

  public function new(startTime:Float, bpm:Float, ?signature:Int)
  {
    this.startTime = startTime;
    this.bpm = bpm;
    this.signature = signature;
  }
}

class QuaverSliderVelocity
{
  public var startTime:Float;
  public var multiplier:Float;

  public function new(startTime:Float, multiplier:Float)
  {
    this.startTime = startTime;
    this.multiplier = multiplier;
  }
}

class QuaverHitObject
{
  public var startTime:Float;
  public var lane:Int;
  public var endTime:Null<Float>;

  public function new(startTime:Float, lane:Int, ?endTime:Float)
  {
    this.startTime = startTime;
    this.lane = lane;
    this.endTime = endTime;
  }
}
