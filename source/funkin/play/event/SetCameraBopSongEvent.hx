package funkin.play.event;

// Data from the chart
import funkin.data.song.SongData.SongEventData;
// Data from the event schema
import funkin.data.event.SongEventSchema;
import funkin.data.event.SongEventSchema.SongEventFieldType;

/**
 * This class represents a handler for configuring camera bop intensity and rate.
 *
 * Example: Bop the camera twice as hard, once per beat (rather than once every four beats).
 * ```
 * {
 *   'e': 'SetCameraBop',
 *   'v': {
 *    'intensity': 2.0,
 *    'rate': 1,
 *   }
 * }
 * ```
 *
 * Example: Reset the camera bop to default values.
 * ```
 * {
 *   'e': 'SetCameraBop',
 * 	 'v': {}
 * }
 * ```
 */
class SetCameraBopSongEvent extends SongEvent
{
  public function new()
  {
    super('SetCameraBop');
  }

  public override function handleEvent(data:SongEventData):Void
  {
    // Does nothing if there is no PlayState camera or stage.
    if (PlayState.instance == null) return;

    var rate:Null<Int> = data.getInt('rate');
    if (rate == null) rate = Constants.DEFAULT_ZOOM_RATE;
    var intensity:Null<Float> = data.getFloat('intensity');
    if (intensity == null) intensity = 1.0;

    PlayState.instance.cameraBopIntensity = (Constants.DEFAULT_BOP_INTENSITY - 1.0) * intensity + 1.0;
    PlayState.instance.hudCameraZoomIntensity = (Constants.DEFAULT_BOP_INTENSITY - 1.0) * intensity * 2.0;
    PlayState.instance.cameraZoomRate = rate;
    trace('Set camera zoom rate to ${PlayState.instance.cameraZoomRate}');
  }

  public override function getTitle():String
  {
    return 'Set Camera Bop';
  }

  /**
   * ```
   * {
   *   'intensity': FLOAT, // Zoom amount
   *   'rate': INT, // Zoom rate (beats/zoom)
   * }
   * ```
   * @return SongEventSchema
   */
  public override function getEventSchema():SongEventSchema
  {
    return new SongEventSchema([
      {
        name: 'intensity',
        title: 'Intensity',
        defaultValue: 1.0,
        step: 0.1,
        type: SongEventFieldType.FLOAT,
        units: 'x'
      },
      {
        name: 'rate',
        title: 'Rate',
        defaultValue: 4,
        step: 1,
        type: SongEventFieldType.INTEGER,
        units: 'beats/zoom'
      }
    ]);
  }
}
