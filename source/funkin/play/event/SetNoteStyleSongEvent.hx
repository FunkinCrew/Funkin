package funkin.play.event;

// Data from the chart
import funkin.data.song.SongData.SongEventData;
// Data from the event schema
import funkin.play.event.SongEvent;
import funkin.play.notes.notestyle.NoteStyle;
import funkin.data.event.SongEventSchema;
import funkin.data.event.SongEventSchema.SongEventFieldType;
import funkin.data.notestyle.NoteStyleRegistry;

/**
 * This class represents a handler for changing note styles.
 *
 * Example: Change the notestyle to Week 6's notestyle:
 * ```
 * {
 *   'e': 'SetNoteStyle',
 *   'v': {
 *     'notestyle': 'pixel',
 *     'strumline': 'both',
 *     'changePopups': true
 *   }
 * }
 * ```
 */
class SetNoteStyleSongEvent extends SongEvent
{
  public function new()
  {
    super('SetNoteStyle');
  }

  static final DEFAULT_NOTESTYLE:String = 'funkin';
  static final DEFAULT_STRUMLINE:String = 'both';
  static final DEFAULT_CHANGE_POPUPS:Bool = false;

  public override function handleEvent(data:SongEventData):Void
  {
    // Does nothing if there is no PlayState.
    if (PlayState.instance == null) return;

    var targetNoteStyle:String = data.getString('notestyle') ?? DEFAULT_NOTESTYLE;
    var targetStrumline:String = data.getString('strumline') ?? DEFAULT_STRUMLINE;
    var changePopups:Bool = data.getBool('changePopups') ?? DEFAULT_CHANGE_POPUPS;

    switch (targetStrumline)
    {
      case 'both':
        PlayState.instance.playerStrumline.noteStyleId = targetNoteStyle;
        PlayState.instance.opponentStrumline.noteStyleId = targetNoteStyle;
      case 'player':
        PlayState.instance.playerStrumline.noteStyleId = targetNoteStyle;
      case 'opponent':
        PlayState.instance.opponentStrumline.noteStyleId = targetNoteStyle;
    }

    if (changePopups)
    {
      PlayState.instance.initPopups(targetNoteStyle);
    }
  }

  public override function getTitle():String
  {
    return 'Set Note Style';
  }

  /**
   * ```
   * {
   *   'zoom': FLOAT, // Target zoom level.
   *   'duration': FLOAT, // Duration in steps.
   *   'mode': ENUM, // Whether zoom is relative to the stage or absolute zoom.
   *   'ease': ENUM, // Easing function.
   * }
   * @return SongEventSchema
   */
  public override function getEventSchema():SongEventSchema
  {
    return new SongEventSchema([
      {
        name: 'notestyle',
        title: 'Note Style',
        defaultValue: "funkin",
        type: SongEventFieldType.ENUM,
        keys: generateStyleList()
      },
      {
        name: 'strumline',
        title: 'Target Strumline',
        defaultValue: "both",
        type: SongEventFieldType.ENUM,
        keys: [
          'Player Strumline' => 'player',
          'Opponent Strumline' => 'opponent',
          'Both Strumlines' => 'both'
        ]
      },
      {
        name: 'changePopups',
        title: 'Change pop-up style?',
        defaultValue: true,
        type: SongEventFieldType.BOOL
      }
    ]);
  }

  /**
   * Returns the entry IDs of all note styles.
   */
  static function generateStyleList():Map<String, String>
  {
    var noteStyleIds:Array<String> = NoteStyleRegistry.instance.listEntryIds();
    var styleMap:Map<String, String> = new Map<String, String>();

    for (note in noteStyleIds)
    {
      var noteStyle:NoteStyle = NoteStyleRegistry.instance.fetchEntry(note);
      styleMap.set(noteStyle.getName(), noteStyle.id);
    }

    return styleMap;
  }
}
