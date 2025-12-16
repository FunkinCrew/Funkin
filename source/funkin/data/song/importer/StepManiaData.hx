package funkin.data.song.importer;

typedef StepManiaData =
{
  var Metadata:
    {
      var Title:String;
      var Artist:String;
      var Genre:String;
      var Credit:String;
      var Banner:String;
      var Background:String;

      var Offset:Float;
      var SampleStart:Float;
    };
  var TimingPoints:Array<StepTimingPoint>;
  var Stops:Array<StepStop>;
  var Difficulties:Array<StepDifficulty>;
}

enum StepManiaChartType {
  DanceSingle;
  DanceDouble;
  Unknown;
}

enum StepManiaNoteType {
  Tap;
  Head;
  Tail;
  Roll;
  Mine;
  Fake;
}

class StepNote
{
  public var beat:Float;
  public var column:Int;
  public var type:StepManiaNoteType;

  public function new(t:String, beat:Float, column:Int)
  {
    this.beat = beat;
    this.column = column;
    switch (t) {
      case "2":
        this.type = StepManiaNoteType.Head;
      case "3":
        this.type = StepManiaNoteType.Tail;
      case "4":
        this.type = StepManiaNoteType.Roll;
      case "M":
        this.type = StepManiaNoteType.Mine;
      case "F":
        this.type = StepManiaNoteType.Fake;
      default:
        this.type = StepManiaNoteType.Tap;
    }
  }
}

class StepDifficulty
{
  public var name:String;
  public var charter:String;
  public var difficultyRating:Int;
  public var type:StepManiaChartType;

  public var notes:Array<StepNote>;

  public function parseChartType(chartTypeStr:String):StepManiaChartType
  {
    switch (chartTypeStr) {
      case "dance-single":
        return StepManiaChartType.DanceSingle;
      case "dance-double":
        return StepManiaChartType.DanceDouble;
      default:
        return StepManiaChartType.Unknown;
    }
  }

  public function new(name:String, charter:String, difficultyRating:Int, type:String)
  {
    this.name = name;
    this.charter = charter;
    this.difficultyRating = difficultyRating;
    this.type = parseChartType(type);
  }
}

class StepTimingPoint
{
  public var bpm:Float;
  public var startBeat:Float = Math.NEGATIVE_INFINITY;
  public var endBeat:Float = Math.POSITIVE_INFINITY;
  public var startTimestamp:Float = 0;
  public var endTimestamp:Float = 0;

  public function new(bpm:Float, startBeat:Float)
  {
    this.bpm = bpm;
    this.startBeat = startBeat;
  }
}

// Not implemented, but if any chart uses them then the chart will break.
// IE this messes with the timing of the notes.
class StepStop
{
  public var startBeat:Float = Math.NEGATIVE_INFINITY;
  public var duration:Float = 0;

  public var startTimestamp:Float = Math.NEGATIVE_INFINITY;

  public function new(startBeat:Float, duration:Float)
  {
    this.startBeat = startBeat;
    this.duration = duration;
  }
}
