package funkin.play.event;

// Data from the chart
import funkin.data.song.SongData.SongEventData;
// Data from the event schema
import funkin.data.event.SongEventSchema;
import funkin.data.event.SongEventSchema.SongEventFieldType;
// Event specific imports.
import funkin.graphics.FunkinCamera;
import haxe.DynamicAccess;

/**
 * This class handles song events which bop the camera in by a specified amount.
 * This event works very well with the `SetCameraBop` song event.
 *
 * Example: Bop the Game and HUD Camera by 2 times the current bop intensity.
 * ```json
 * {
 *   "e": "BopCameraOnce",
 *   "v": 2
 * }
 * ```
 *
 * Example: Bop only the Game Camera by the current bop intensity.
 * ```json
 * {
 *   "e": "BopCameraOnce",
 *   "v": {
 *    "camGame": 1
 *   }
 * }
 * ```
 */
class BopCameraOnceSongEvent extends SongEvent
{
  /**
   * The cameras that affect this event by default.
   * This will be used in the Chart Editor.
   */
  public static final DEFAULT_CAMERAS:Array<String> = ['camGame', 'camHUD'];

  /**
   * The titles to use for the default cameras in the Chart Editor.
   */
  public static final DEFAULT_CAMERA_TITLES:Array<String> = ['Game', 'HUD'];

  /**
   * The default intensity to use if none were specified.
   */
  public static final DEFAULT_INTENSITY:Float = 1.0;

  /**
   * The step that the event should should use in the chart editor.
   */
  public static final INTENSITY_STEP:Float = 0.1;

  public function new()
  {
    super('BopCameraOnce', {
      processOldEvents: true
    });
  }

  public override function getTitle():String
  {
    return 'Bop Camera Once';
  }

  public override function handleEvent(data:SongEventData):Void
  {
    // Does nothing if there is no PlayState camera or stage.
    if (PlayState.instance == null) return;

    var cameras:DynamicAccess<Dynamic> = {};

    if (data.value != null && Reflect.isObject(data.value))
    {
      cameras = cast data.value;
    }
    else
    {
      var intensity:Float = convertToFloat(data.value, DEFAULT_INTENSITY);

      for (camName in DEFAULT_CAMERAS)
      {
        cameras.set(camName, intensity);
      }
    }

    for (camName => value in cameras)
    {
      var camera:Dynamic = Reflect.field(PlayState.instance, camName);
      if (camera == null || !Std.isOfType(camera, FunkinCamera)) continue;

      var intensity:Float = convertToFloat(value, DEFAULT_INTENSITY);
      setIntensityToCamera(camera, intensity);
    }
  }

  public override function getEventSchema():SongEventSchema
  {
    return new SongEventSchema([for (i => camName in DEFAULT_CAMERAS) {
      name: camName,
      title: '${DEFAULT_CAMERA_TITLES[i]} Intensity',
      tooltip: 'The intensity at which to bop the camera to.',
      defaultValue: DEFAULT_INTENSITY,
      min: 0,
      step: INTENSITY_STEP,
      type: SongEventFieldType.FLOAT,
      units: 'x'
    }]);
  }

  /**
   * Add a bop with a specific intensity to a camera.
   * @param camera The camera to use to add the bop.
   * @param intensity The intensity to use for the bop.
   */
  public function setIntensityToCamera(camera:FunkinCamera, intensity:Float):Void
  {
    // Can't set intensity when there arent any base intensities.
    if (PlayState.instance == null) return;

    // We assume that all cameras are HUD cameras unless said otherwise below.
    var addIntensity:Float = PlayState.instance.hudCameraZoomIntensity * intensity;

    if (camera == PlayState.instance.camGame)
    {
      // `camGame` uses a different system than all other cameras.
      // Due to this, we need to override the default logic.
      addIntensity = PlayState.instance.cameraBopIntensity * intensity;

      // `cameraBopIntensity` is a multiplier.
      // To add it to the current multiplier, we need to remove 100% from it.
      addIntensity -= 1;

      // Add it to the camera bop multiplier, and cancel default logic.
      PlayState.instance.cameraBopMultiplier += addIntensity;
      return;
    }

    camera.zoom += addIntensity;
  }

  function convertToFloat(value:Dynamic, defaultValue:Float):Float
  {
    var toReturn:Float = defaultValue;

    if (value != null)
    {
      if (Std.isOfType(value, String)) toReturn = Std.parseFloat(cast value);
      if (Std.isOfType(value, Float)) toReturn = value;
    }

    return toReturn;
  }
}
