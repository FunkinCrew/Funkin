package funkin.ui.debug.cameraeditor.components;

import funkin.graphics.FunkinSprite;
import flixel.util.FlxColor;
import funkin.play.event.SongEvent;
import funkin.data.song.SongData.SongEventData;
import funkin.play.stage.Stage;
import flixel.tweens.FlxEase;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.FlxObject;

class VirtualCameraRectangle extends FunkinSprite
{
  /**
   * The zoom level of the virtual camera. Setting this will adjust the scale of the rectangle accordingly.
   */
  public var zoom(default, set):Float = 1;

  /**
   * The current position of the virtual camera in world space.
   */
  public var vCamPoint:FlxPoint = new FlxPoint();

  var isClassicEase:Bool = false;

  var lastVCamPoint:FlxPoint = new FlxPoint();
  var cameraFollowPoint:FlxObject = new FlxObject();

  var cameraFollowTween:Float = 0;
  var cameraFollowStart:FlxPoint = new FlxPoint();
  var cameraFollowDuration:Float = 0;
  var cameraFollowEase:Null<Float->Float> = null;

  var cameraZoomTween:Float = 0;
  var cameraZoomEnd:Float = 0;
  var cameraZoomStart:Float = 0;
  var cameraZoomDuration:Float = 0;
  var cameraZoomEase:Null<Float->Float> = null;

  var scrollTarget:FlxPoint = new FlxPoint();
  function set_zoom(value:Float):Float
  {
    zoom = value;
    scale.set(1.0 / zoom, 1.0 / zoom);
    updateHitbox();
    return zoom;
  }

  /**
   * Cancels the current camera follow tween if it's active.
   */
  public function cancelCameraFollowTween():Void
  {
    cameraFollowTween = 0;
    cameraFollowDuration = 0;
  }

  /**
   * Cancels the current camera zoom tween if it's active.
   */
  public function cancelCameraZoomTween():Void
  {
    cameraZoomTween = 0;
    cameraZoomDuration = 0;
  }

  /**
   * Cancels all active camera tweens (both follow and zoom).
   */
  public function cancelAllTweens():Void
  {
    cancelCameraFollowTween();
    cancelCameraZoomTween();
  }

  /**
   * Resets the camera to follow the current cameraFollowPoint.
   * @param resetZoom Whether to reset the zoom level to 1. Default is true.
   * @param cancelTweens Whether to cancel any active camera follow tweens. Default is true.
   * @param snap Whether to snap the camera to the follow point immediately. Default is true.
   */
  public function resetCamera(resetZoom:Bool = true, cancelTweens:Bool = true, snap:Bool = true):Void
  {
    if (cancelTweens) cancelCameraFollowTween();
    setFocusPoint(cameraFollowPoint.x, cameraFollowPoint.y, snap);
  }

  /**
   * Tweens the camera to the current cameraFollowPoint over the specified duration using the specified easing function.
   * @param duration Duration of the tween in seconds. If 0, the camera will snap to the follow point immediately.
   * @param ease Easing function to use for the tween. If null, the default easing will be used.
   */
  public function tweenCameraToFollowPoint(duration:Float = 0, ?ease:Null<Float->Float>):Void
  {
    // Cancel the current tween if it's active.
    cancelCameraFollowTween();

    if (duration == 0)
    {
      resetCamera(false, false);
    }
    else
    {
      cameraFollowStart.copyFrom(lastVCamPoint);
      cameraFollowDuration = duration;
      cameraFollowEase = ease;
    }
  }

  /**
   * Tweens the camera zoom to the specified level over the specified duration using the specified easing function.
   * @param stageZoom The stage's default zoom level.
   * @param z The target zoom level.
   * @param duration Duration of the tween in seconds. If 0, the zoom will change immediately.
   * @param direct Whether the zoom level is absolute (true) or relative to the stage's default zoom (false).
   * @param ease Easing function to use for the tween. If null, the default easing will be used.
   */
  public function tweenCameraZoom(stageZoom:Float, z:Float = 1, duration:Float = 0, direct:Bool = false, ?ease:Null<Float->Float>):Void
  {
    cancelCameraZoomTween();

    var targetZoom:Float = z;
    if (!direct) targetZoom *= stageZoom;

    if (duration == 0) zoom = targetZoom;
    else
    {
      cameraZoomTween = 0;
      cameraZoomStart = zoom;
      cameraZoomEnd = targetZoom;
      cameraZoomDuration = duration;
      cameraZoomEase = ease;
    }
  }

  /**
   * Sets the camera follow point to the specified coordinates. If force is true, the camera will immediately snap to the new follow point.
   * @param x The x-coordinate of the new camera follow point.
   * @param y The y-coordinate of the new camera follow point.
   * @param force Whether to immediately snap the camera to the new follow point. Default is false.
   */
  public function setFocusPoint(x:Float, y:Float, force:Bool = false):Void
  {
    lastVCamPoint.copyFrom(vCamPoint);
    cameraFollowPoint.x = x;
    cameraFollowPoint.y = y;
    if (force) vCamPoint.copyFrom(scrollTarget);
  }

  /**
   * Handles a camera focus event, updating the camera follow point based on the event data.
   * @param currentStage The current stage, used to get the positions of the characters if a character focus is specified.
   * @param eventData The event data containing the focus information. Expected fields:
   */
  public function handleFocusCamera(currentStage:Stage, eventData:SongEventData):Void
  {
    var x:Null<Float> = eventData.getFloat('x');
    var y:Null<Float> = eventData.getFloat('y');
    var char:Null<Int> = eventData.getInt('char');
    var offsetX:Float = 0;
    var offsetY:Float = 0;
    if (x != null) offsetX = x;
    if (y != null) offsetY = y;

    if (char == null) char = cast eventData.value;

    if (char != null)
    {
      if (char == -1)
      {
        setFocusPoint(offsetX, offsetY);
        trace('Focusing camera on coordinates: (' + offsetX + ', ' + offsetY + ')');
      }
      else
      {
        trace('Focusing camera on character: ' + char + ' with offset: (' + offsetX + ', ' + offsetY + ')');

        switch (char)
        {
          case 0:
            var bf = currentStage.getBoyfriend();
            if (bf != null)
            {
              setFocusPoint(bf.cameraFocusPoint.x + offsetX, bf.cameraFocusPoint.y + offsetY);
            }
          case 1:
            var dad = currentStage.getDad();
            if (dad != null)
            {
              setFocusPoint(dad.cameraFocusPoint.x + offsetX, dad.cameraFocusPoint.y + offsetY);
            }
          case 2:
            var gf = currentStage.getGirlfriend();
            if (gf != null)
            {
              setFocusPoint(gf.cameraFocusPoint.x + offsetX, gf.cameraFocusPoint.y + offsetY);
            }
        }
        trace('    Camera follow point set to: (' + cameraFollowPoint.x + ', ' + cameraFollowPoint.y + ')');
      }
    }

    var duration:Null<Float> = eventData.getFloat('duration');
    if (duration == null) duration = 4.0;
    var ease:Null<String> = eventData.getString('ease');
    if (ease == null) ease = 'CLASSIC';
    if (ease == 'CLASSIC') {
      isClassicEase = true;
      vCamPoint.set(lastVCamPoint.x, lastVCamPoint.y);
      cancelCameraFollowTween();
      return;
    }

    isClassicEase = false;

    trace('    Duration: ' + duration + 'ms, Ease: ' + ease);

    switch (ease)
    {
      case 'INSTANT': // Instant ease. Duration is automatically 0.
        resetCamera(false, true, true);
      default:
        var easeDir:String = eventData.getString('easeDir') ?? SongEvent.DEFAULT_EASE_DIR;
        if (SongEvent.EASE_TYPE_DIR_REGEX.match(ease) || ease == "linear") easeDir = "";

          var durSeconds = Conductor.instance.stepLengthMs * duration / 1000;
          var easeFunctionName = '$ease$easeDir';
          var easeFunction:Null<Float->Float> = Reflect.field(FlxEase, easeFunctionName);
          if (easeFunction == null)
          {
            trace('Invalid ease function: $easeFunctionName');
            return;
          }
          tweenCameraToFollowPoint(durSeconds, easeFunction);
    }
  }

  /**
   * Handles a camera zoom event, updating the camera zoom level based on the event data.
   * @param eventData The event data containing the zoom information.
   */
  public function handleZoomCamera(stageZoom:Float, eventData:SongEventData):Void
  {
    var zoom:Float = eventData.getFloat('zoom') ?? 1.0;

    var duration:Float = eventData.getFloat('duration') ?? 4.0;

    var mode:String = eventData.getString('mode') ?? 'direct';
    var isDirectMode:Bool = mode == 'direct';

    var ease:String = eventData.getString('ease') ?? SongEvent.DEFAULT_EASE;
    var easeDir:String = eventData.getString('easeDir') ?? SongEvent.DEFAULT_EASE_DIR;

    if (SongEvent.EASE_TYPE_DIR_REGEX.match(ease) || ease == "linear") easeDir = "";

    // If it's a string, check the value.
    switch (ease)
    {
      case 'INSTANT':
        tweenCameraZoom(stageZoom, zoom, 0, isDirectMode);
      default:
        var durSeconds = Conductor.instance.stepLengthMs * duration / 1000;
        var easeFunctionName = '$ease$easeDir';
        var easeFunction:Null<Float->Float> = Reflect.field(FlxEase, easeFunctionName);
        if (easeFunction == null)
        {
          trace('Invalid ease function: $easeFunctionName');
          return;
        }

        tweenCameraZoom(stageZoom, zoom, durSeconds, isDirectMode, easeFunction);
    }
  }

  public function new(x:Float, y:Float)
  {
      super(x, y);
      makeGraphic(FlxG.width, FlxG.height, FlxColor.BLUE);
      alpha = 0.5;
      zIndex = 5999;
      updateHitbox();
  }

  public override function update(elapsed:Float):Void
  {
    super.update(elapsed);

    if (!FlxG.sound.music.playing) return;

    x = vCamPoint.x - width / 2;
    y = vCamPoint.y - height / 2;

    scrollTarget.set(cameraFollowPoint.x, cameraFollowPoint.y);

    if (isClassicEase)
    {
      final adjustedLerp = 1.0 - Math.pow(1.0 - Constants.DEFAULT_CAMERA_FOLLOW_RATE, elapsed * 60);
      vCamPoint.x += (scrollTarget.x - vCamPoint.x) * adjustedLerp;
      vCamPoint.y += (scrollTarget.y - vCamPoint.y) * adjustedLerp;
    }
    else
    {
      // Handle camera follow tweening
      if (cameraFollowDuration > 0 && cameraFollowEase != null)
      {
        vCamPoint.x = FlxMath.lerp(cameraFollowStart.x, scrollTarget.x, cameraFollowEase(cameraFollowTween / cameraFollowDuration));
        vCamPoint.y = FlxMath.lerp(cameraFollowStart.y, scrollTarget.y, cameraFollowEase(cameraFollowTween / cameraFollowDuration));

        cameraFollowTween += elapsed;
        if (cameraFollowTween >= cameraFollowDuration) cameraFollowDuration = 0;
      }
    }
    // Handle camera zoom tweening
    if (cameraZoomDuration > 0 && cameraZoomEase != null)
    {
      zoom = FlxMath.lerp(cameraZoomStart, cameraZoomEnd, cameraZoomEase(cameraZoomTween / cameraZoomDuration));
      cameraZoomTween += elapsed;
      if (cameraZoomTween >= cameraZoomDuration) cameraZoomDuration = 0;
    }
  }
}
