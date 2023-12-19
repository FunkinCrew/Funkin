package funkin.data.song.importer;

import haxe.ds.Either;

/**
 * A data structure representing a song in the old chart format.
 * This only works for charts compatible with Week 7, so you'll need a custom program
 * to handle importing charts from mods or other engines.
 */
class FNFLegacyData
{
  public var song:LegacySongData;
}

class LegacySongData
{
  public var player1:String; // Boyfriend
  public var player2:String; // Opponent

  @:jcustomparse(funkin.data.DataParse.eitherLegacyScrollSpeeds)
  public var speed:Either<Float, LegacyScrollSpeeds>;
  @:optional
  public var stageDefault:Null<String>;
  public var bpm:Float;

  @:jcustomparse(funkin.data.DataParse.eitherLegacyNoteData)
  public var notes:Either<Array<LegacyNoteSection>, LegacyNoteData>;
  public var song:String; // Song name

  public function new() {}

  public function toString():String
  {
    var notesStr:String = switch (notes)
    {
      case Left(sections): 'single difficulty w/ ${sections.length} sections';
      case Right(data):
        var difficultyCount:Int = 0;
        if (data.easy != null) difficultyCount++;
        if (data.normal != null) difficultyCount++;
        if (data.hard != null) difficultyCount++;
        '${difficultyCount} difficulties';
    };
    return 'LegacySongData($player1, $player2, $notesStr)';
  }
}

typedef LegacyScrollSpeeds =
{
  public var ?easy:Float;
  public var ?normal:Float;
  public var ?hard:Float;
};

typedef LegacyNoteData =
{
  /**
   * The easy difficulty.
   */
  public var ?easy:Array<LegacyNoteSection>;

  /**
   * The normal difficulty.
   */
  public var ?normal:Array<LegacyNoteSection>;

  /**
   * The hard difficulty.
   */
  public var ?hard:Array<LegacyNoteSection>;
};

typedef LegacyNoteSection =
{
  /**
   * Whether the section is a must-hit section.
   * If true, 0-3 are boyfriends notes, 4-7 are opponents notes.
   * If false, 0-3 are opponents notes, 4-7 are boyfriends notes.
   */
  public var mustHitSection:Bool;

  /**
   * Array of note data:
   * - Direction
   * - Time (ms)
   * - Sustain Duration (ms)
   * - Note kind (true = "alt", or string)
   */
  public var sectionNotes:Array<LegacyNote>;

  public var ?typeOfSection:Int;

  public var ?lengthInSteps:Int;

  // BPM changes
  public var ?changeBPM:Bool;
  public var ?bpm:Float;
}

/**
 * Notes in the old format are stored as an Array<Dynamic>
 * We use a custom parser to manage this.
 */
@:jcustomparse(funkin.data.DataParse.legacyNote)
class LegacyNote
{
  public var time:Float;
  public var data:Int;
  public var length:Float;
  public var alt:Bool;

  public function new(time:Float, data:Int, ?length:Float, ?alt:Bool)
  {
    this.time = time;
    this.data = data;

    this.length = length ?? 0.0;
    this.alt = alt ?? false;
  }

  public inline function getKind():String
  {
    return this.alt ? 'alt' : 'normal';
  }
}
