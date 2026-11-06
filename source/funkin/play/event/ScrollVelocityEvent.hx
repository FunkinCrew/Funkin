package funkin.play.event;

import funkin.data.event.SongEventSchema.SongEventFieldType;
import funkin.data.event.SongEventSchema;
import funkin.data.song.SongData.SongEventData;

/**
 * Changes how fast the notes move toward the strums, without changing the spacing.
 *
 * Example: Stop both strums over 4 steps:
 * ```
 * {
 *   'e': 'ScrollVelocity',
 *   "v": {
 *      "velocity": 0,
 *      "duration": 4,
 *      "ease": "linear",
 *      "strumline": "both"
 *   }
 * }
 * ```
 */
class ScrollVelocityEvent extends SongEvent
{
  public function new()
  {
    super('ScrollVelocity', {
      processOldEvents: true
    });
  }

  public static final DEFAULT_VELOCITY:Float = 1;
  public static final DEFAULT_DURATION:Float = 4.0;
  public static final DEFAULT_STRUMLINE:String = 'both';

  override public function handleEvent(data:SongEventData):Void
  {
    // see ScrollVelocityTimeline.
  }

  override public function getTitle():String
  {
    return 'Scroll Velocity';
  }

  /**
   * ```
   * {
   *   'velocity': FLOAT, // How fast the notes move, 1 being normal.
   *   'duration': FLOAT, // Duration in steps.
   *   'ease': ENUM, // Easing function.
   *   'easeDir': ENUM, // Easing function direction (In, Out, InOut).
   *   'strumline': ENUM, // Which strumline to change.
   * }
   * ```
   *
   * @return The `SongEventSchema`
   */
  override public function getEventSchema():SongEventSchema
  {
    return new SongEventSchema([
      {
        name: 'velocity',
        title: 'Velocity',
        defaultValue: DEFAULT_VELOCITY,
        min: -10,
        step: 0.1,
        type: SongEventFieldType.FLOAT,
        units: 'x'
      },
      {
        name: 'duration',
        title: 'Duration',
        defaultValue: DEFAULT_DURATION,
        min: 0,
        step: 0.5,
        type: SongEventFieldType.FLOAT,
        units: 'steps'
      },
      {
        name: 'ease',
        title: 'Easing Type',
        defaultValue: SongEvent.DEFAULT_EASE,
        type: SongEventFieldType.ENUM,
        keys: [
          'Linear' => 'linear',
          'Instant' => 'INSTANT',
          'Sine' => 'sine',
          'Quad' => 'quad',
          'Cube' => 'cube',
          'Quart' => 'quart',
          'Quint' => 'quint',
          'Expo' => 'expo',
          'Smooth Step' => 'smoothStep',
          'Smoother Step' => 'smootherStep',
          'Elastic' => 'elastic',
          'Back' => 'back',
          'Bounce' => 'bounce',
          'Circ ' => 'circ',
        ]
      },
      {
        name: 'easeDir',
        title: 'Easing Direction',
        defaultValue: SongEvent.DEFAULT_EASE_DIR,
        type: SongEventFieldType.ENUM,
        keys: [
          'In' => 'In',
          'Out' => 'Out',
          'In/Out' => 'InOut'
        ]
      },
      {
        name: 'advanced',
        title: 'Advanced',
        type: SongEventFieldType.FRAME,
        collapsible: true,
        children: [
          {
            name: 'strumline',
            title: 'Target Strumline',
            defaultValue: DEFAULT_STRUMLINE,
            type: SongEventFieldType.ENUM,
            keys: [
              'Both' => 'both',
              'Player' => 'player',
              'Opponent' => 'opponent'
            ]
          }
        ]
      }
    ]);
  }
}
