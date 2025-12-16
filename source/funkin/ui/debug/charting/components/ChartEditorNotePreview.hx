package funkin.ui.debug.charting.components;

#if FEATURE_CHART_EDITOR
import funkin.data.song.SongData.SongEventData;
import funkin.data.song.SongData.SongNoteData;
import flixel.math.FlxMath;
import flixel.FlxSprite;
import flixel.util.FlxColor;
import flixel.util.FlxSpriteUtil;

/**
 * Handles the note scrollbar preview in the chart editor.
 */
@:nullSafety
@:access(funkin.ui.debug.charting.ChartEditorState)
class ChartEditorNotePreview extends FlxSprite
{
  //
  // Constants
  //
  static final NOTE_WIDTH:Int = 5;
  static final WIDTH:Int = NOTE_WIDTH * 9;
  static final NOTE_HEIGHT:Int = 1;

  static final BG_COLOR:FlxColor = 0xFF606060;
  static final LEFT_COLOR:FlxColor = 0xFFFF22AA;
  static final DOWN_COLOR:FlxColor = 0xFF00EEFF;
  static final UP_COLOR:FlxColor = 0xFF00CC00;
  static final RIGHT_COLOR:FlxColor = 0xFFCC1111;
  static final EVENT_COLOR:FlxColor = 0xFF111111;
  static final SELECTED_COLOR:FlxColor = 0xFFFFFF00;
  static final OVERLAPPING_COLOR:FlxColor = 0xFF640000;

  var previewHeight:Int;

  public function new(height:Int)
  {
    super(0, 0);
    this.previewHeight = height;
    buildBackground();
  }

  /**
   * Build the initial sprite for the preview.
   */
  function buildBackground():Void
  {
    makeGraphic(WIDTH, previewHeight, BG_COLOR);
  }

  /**
   * Erase all notes from the preview.
   */
  public function erase():Void
  {
    drawRect(0, 0, WIDTH, previewHeight, BG_COLOR);
  }

  /**
   * Add a single note to the preview.
   * @param note The data for the note.
   * @param songLengthInPixels The total length of the song in pixels.
   */
  public function addNote(note:SongNoteData, songLengthInPixels:Int, previewType:NotePreviewType = None):Void
  {
    var noteDir:Int = note.getDirection();
    var mustHit:Bool = note.getStrumlineIndex() == 0;
    drawNote(noteDir, mustHit, Std.int(note.time), songLengthInPixels, previewType);
  }

  /**
   * Add a song event to the preview.
   * @param event The data for the event.
   * @param songLengthInPixels The total length of the song in pixels.
   * @param isSelection If current event is selected, which then it's forced to be yellow.
   */
  public function addEvent(event:SongEventData, songLengthInPixels:Int, isSelection:Bool = false):Void
  {
    drawNote(-1, false, Std.int(event.time), songLengthInPixels, isSelection ? Selection : None);
  }

  /**
   * Add an array of notes to the preview.
   * @param notes The data for the notes.
   * @param songLengthInPixels The total length of the song in pixels.
   */
  public function addNotes(notes:Array<SongNoteData>, songLengthInPixels:Int):Void
  {
    for (note in notes)
    {
      addNote(note, songLengthInPixels, None);
    }
  }

  /**
   * Add an array of selected notes to the preview.
   * @param notes The data for the notes.
   * @param songLengthInPixels The total length of the song in pixels.
   */
  public function addSelectedNotes(notes:Array<SongNoteData>, songLengthInPixels:Int):Void
  {
    for (note in notes)
    {
      addNote(note, songLengthInPixels, Selection);
    }
  }

  /**
   * Add an array of overlapping notes to the preview.
   * @param notes The data for the notes
   * @param songLengthInPixels The total length of the song in pixels.
   */
  public function addOverlappingNotes(notes:Array<SongNoteData>, songLengthInPixels:Int):Void
  {
    for (note in notes)
    {
      addNote(note, songLengthInPixels, Overlapping);
    }
  }

  /**
   * Add an array of events to the preview.
   * @param events The data for the events.
   * @param songLengthInPixels The total length of the song in pixels.
   */
  public function addEvents(events:Array<SongEventData>, songLengthInPixels:Int):Void
  {
    for (event in events)
    {
      addEvent(event, songLengthInPixels);
    }
  }

  /**
   * Add an array of selected events to the preview.
   * @param events The data for the events.
   * @param songLengthInPixels The total length of the song in pixels.
   */
  public function addSelectedEvents(events:Array<SongEventData>, songLengthInPixels:Int):Void
  {
    for (event in events)
    {
      addEvent(event, songLengthInPixels, true);
    }
  }

  /**
   * Draws a note on the preview.
   * @param dir Note data.
   * @param mustHit False if opponent, true if player.
   * @param strumTimeInMs Time in milliseconds to strum the note.
   * @param songLengthInPixels Length of the song in pixels.
   * @param previewType If the note should forcibly be colored as selected or overlapping.
   */
  public function drawNote(dir:Int, mustHit:Bool, strumTimeInMs:Int, songLengthInPixels:Int, previewType:NotePreviewType = None):Void
  {
    var color:FlxColor = switch (dir)
    {
      case 0: LEFT_COLOR;
      case 1: DOWN_COLOR;
      case 2: UP_COLOR;
      case 3: RIGHT_COLOR;
      default: EVENT_COLOR;
    };

    var noteHeight:Int = NOTE_HEIGHT;

    switch (previewType)
    {
      case Selection:
        color = SELECTED_COLOR;
        noteHeight += 1;
      case Overlapping:
        color = OVERLAPPING_COLOR;
        noteHeight += 2;
      default:
    }

    var noteX:Float = NOTE_WIDTH * dir;
    if (mustHit) noteX += NOTE_WIDTH * 4;
    if (dir == -1) noteX = NOTE_WIDTH * 8;

    var strumTimeInPixels:Int = Std.int(Conductor.instance.getTimeInSteps(strumTimeInMs) * ChartEditorState.GRID_SIZE);

    var noteY:Float = FlxMath.remapToRange(strumTimeInPixels, 0, songLengthInPixels, 0, previewHeight);
    drawRect(noteX, noteY, NOTE_WIDTH, noteHeight, color);
  }

  function eraseNote(dir:Int, mustHit:Bool, strumTimeInMs:Int, songLengthInPixels:Int):Void
  {
    var noteX:Float = NOTE_WIDTH * dir;
    if (mustHit) noteX += NOTE_WIDTH * 4;
    if (dir == -1) noteX = NOTE_WIDTH * 8;

    var strumTimeInPixels:Int = Std.int(Conductor.instance.getTimeInSteps(strumTimeInMs) * ChartEditorState.GRID_SIZE);

    var noteY:Float = FlxMath.remapToRange(strumTimeInPixels, 0, songLengthInPixels, 0, previewHeight);

    drawRect(noteX, noteY, NOTE_WIDTH, NOTE_HEIGHT, BG_COLOR);
  }

  inline function drawRect(noteX:Float, noteY:Float, width:Int, height:Int, color:FlxColor):Void
  {
    FlxSpriteUtil.drawRect(this, noteX, noteY, width, height, color);
  }
}

enum NotePreviewType
{
  None;
  Selection;
  Overlapping;
}
#end
