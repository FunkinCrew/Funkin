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
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxRect;
import funkin.graphics.FunkinSliceSprite;
import funkin.ui.FullScreenScaleMode;

class VirtualCameraRectangle extends FlxSpriteGroup
{
  /**
   * The zoom level of the virtual camera. Setting this will adjust the scale of the rectangle accordingly.
   */
  public var zoom(default, set):Float = 1;

  /**
   * The current position of the virtual camera in world space.
   */
  public var vCamPoint:FlxPoint = new FlxPoint();

  /**
   * Reference to the current stage, used to access character positions for camera focus events.
   */
  public var currentStage:Stage;

  /**
   * The default position of the camera in the stage.
   */
  public var defaultPosition(get, never):FlxPoint;

  function get_defaultPosition():FlxPoint
  {
    if (currentStage == null) return new FlxPoint();
    var dad = currentStage.getDad();
    return new FlxPoint(dad.cameraFocusPoint.x, dad.cameraFocusPoint.y);
  }

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

    mainView.setGraphicSize(FlxG.width / zoom, FlxG.height / zoom);
    mainView.updateHitbox();

    camSlice.width = mainView.width;
    camSlice.height = mainView.height;

    return zoom;
  }

  public var showExtendedBounds(default, set):Bool = false;

  function set_showExtendedBounds(val:Bool):Bool
  {
    showExtendedBounds = val;
    for (obj in [leftExt, rightExt, cornerTLSmall, cornerBRSmall, cornerTRSmall, cornerBLSmall, lineLSmall, lineRSmall])
    {
      obj.visible = val;
    }
    return val;
  }

  /**
   * Cancels the current camera follow tween if it's active.
   */
  public function cancelCameraFollowTween():Void
  {
    cameraFollowTween = 0;
    cameraFollowDuration = 0;
    cameraFollowEase = null;
    isClassicEase = false;
  }

  /**
   * Cancels the current camera zoom tween if it's active.
   */
  public function cancelCameraZoomTween():Void
  {
    cameraZoomTween = 0;
    cameraZoomDuration = 0;
    cameraZoomEase = null;
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
      cameraFollowTween = Conductor.instance.songPosition;
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
      cameraZoomTween = Conductor.instance.songPosition;
      cameraZoomStart = zoom;
      cameraZoomEnd = targetZoom;
      cameraZoomDuration = duration;
      cameraZoomEase = ease;
    }
  }

  var forceNextFocus:Bool = false;

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
    if (force)
    {
      forceNextFocus = true;
    }
  }

  /**
   * Handles a camera focus event, updating the camera follow point based on the event data.
   * @param eventData The event data containing the focus information. Expected fields:
   */
  public function handleFocusCamera(eventData:SongEventData):Void
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

    if (ease == 'CLASSIC')
    {
      isClassicEase = true;
      cameraFollowTween = Conductor.instance.songPosition;
      cameraFollowStart.copyFrom(lastVCamPoint);
      cameraFollowDuration = 0;
      cameraFollowEase = null;
      trace('    Ease: CLASSIC (exponential decay)');
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

  // the underlying sprite that makes up the view
  var mainView:FunkinSprite;

  // the visual slice sprites that show the camera bounds
  var camSlice:FunkinSliceSprite;
  var camSliceOverlay:FunkinSliceSprite;

  var cornerTL:FunkinSprite;
  var cornerBR:FunkinSprite;
  var cornerTR:FunkinSprite;
  var cornerBL:FunkinSprite;

  var lineT:FunkinSprite;
  var lineL:FunkinSprite;
  var lineR:FunkinSprite;
  var lineB:FunkinSprite;

  var cornerTLSmall:FunkinSprite;
  var cornerBRSmall:FunkinSprite;
  var cornerTRSmall:FunkinSprite;
  var cornerBLSmall:FunkinSprite;

  var lineLSmall:FunkinSprite;
  var lineRSmall:FunkinSprite;

  var middle:FunkinSprite;

  // extension pieces for when showExtendedBounds is true
  var leftExt:FunkinSliceSprite;
  var rightExt:FunkinSliceSprite;

  var pieceSize:Float = 0;

  public function new(x:Float, y:Float)
  {
    super(x, y);
    mainView = new FunkinSprite(0, 0);
    mainView.vcamPoint = vCamPoint;
    mainView.makeGraphic(FlxG.width, FlxG.height, FlxColor.BLUE);
    mainView.updateHitbox();
    mainView.visible = false;

    add(mainView);

    pieceSize = ((FlxG.width / 16 * FullScreenScaleMode.maxAspectRatio.x) - FlxG.width) / 2;

    leftExt = new FunkinSliceSprite(Paths.image('ui/camera-editor/vcam/vcam_slice_left'), new FlxRect(30, 30, 30, 30), 0, 0);
    leftExt.vcamPoint = vCamPoint;
    leftExt.alpha = 0.3;
    leftExt.zIndex = 5999;
    leftExt.updateHitbox();

    add(leftExt);

    // flipping x doesnt work.... i HAVE to use another image.... ewwwwwww
    rightExt = new FunkinSliceSprite(Paths.image('ui/camera-editor/vcam/vcam_slice_right'), new FlxRect(30, 30, 30, 30), 0, 0);
    rightExt.vcamPoint = vCamPoint;
    rightExt.alpha = 0.3;
    rightExt.zIndex = 5999;
    rightExt.updateHitbox();

    add(rightExt);

    camSliceOverlay = new FunkinSliceSprite(Paths.image('ui/camera-editor/vcam/vcam_slice_solid'), new FlxRect(30, 30, 30, 30), 0, 0);
    camSliceOverlay.vcamPoint = vCamPoint;
    camSliceOverlay.blend = OVERLAY;
    camSliceOverlay.alpha = 0.2;
    camSliceOverlay.zIndex = 6000;
    camSliceOverlay.updateHitbox();

    add(camSliceOverlay);

    camSlice = new FunkinSliceSprite(Paths.image('ui/camera-editor/vcam/vcam_slice'), new FlxRect(30, 30, 30, 30), 0, 0);
    camSlice.vcamPoint = vCamPoint;
    camSlice.alpha = 0.5;
    camSlice.zIndex = 6001;
    camSlice.updateHitbox();

    add(camSlice);

    middle = FunkinSprite.create(0, 0, 'ui/camera-editor/vcam/vcam_center');

    cornerTR = FunkinSprite.create(0, 0, 'ui/camera-editor/vcam/vcam_corner');
    cornerBR = FunkinSprite.create(0, 0, 'ui/camera-editor/vcam/vcam_corner');
    cornerTL = FunkinSprite.create(0, 0, 'ui/camera-editor/vcam/vcam_corner');
    cornerBL = FunkinSprite.create(0, 0, 'ui/camera-editor/vcam/vcam_corner');

    cornerTRSmall = FunkinSprite.create(0, 0, 'ui/camera-editor/vcam/vcam_corner_small');
    cornerBRSmall = FunkinSprite.create(0, 0, 'ui/camera-editor/vcam/vcam_corner_small');
    cornerTLSmall = FunkinSprite.create(0, 0, 'ui/camera-editor/vcam/vcam_corner_small');
    cornerBLSmall = FunkinSprite.create(0, 0, 'ui/camera-editor/vcam/vcam_corner_small');

    lineT = FunkinSprite.create(0, 0, 'ui/camera-editor/vcam/vcam_line_horizontal');
    lineB = FunkinSprite.create(0, 0, 'ui/camera-editor/vcam/vcam_line_horizontal');

    lineL = FunkinSprite.create(0, 0, 'ui/camera-editor/vcam/vcam_line_vertical');
    lineR = FunkinSprite.create(0, 0, 'ui/camera-editor/vcam/vcam_line_vertical');

    lineLSmall = FunkinSprite.create(0, 0, 'ui/camera-editor/vcam/vcam_line_small');
    lineRSmall = FunkinSprite.create(0, 0, 'ui/camera-editor/vcam/vcam_line_small');

    // no fucking way im doing this manually
    for (obj in [middle, cornerTR, cornerBR, cornerTL, cornerBL, cornerTLSmall, cornerBRSmall, cornerTRSmall, cornerBLSmall, lineT, lineB, lineL, lineR, lineLSmall, lineRSmall])
    {
      obj.vcamPoint = vCamPoint;
      obj.zIndex = 6002;
      add(obj);
    }

    cornerTR.flipX = true;
    cornerBR.flipX = true;
    cornerBR.flipY = true;
    cornerBL.flipY = true;

    cornerTRSmall.flipX = true;
    cornerBRSmall.flipX = true;
    cornerBRSmall.flipY = true;
    cornerBLSmall.flipY = true;

    cornerTRSmall.alpha = 0.7;
    cornerBRSmall.alpha = 0.7;
    cornerTLSmall.alpha = 0.7;
    cornerBLSmall.alpha = 0.7;
    lineLSmall.alpha = 0.7;
    lineRSmall.alpha = 0.7;

    // just cause a little variation is cute
    lineB.flipX = true;
    lineR.flipY = true;
    lineRSmall.flipY = true;

    camSliceOverlay.color = 0xFF7ABFBC;
    camSlice.color = 0xFF7ABFBC;

    leftExt.color = 0xFF7ABF9B;
    rightExt.color = 0xFF7ABF9B;

    // just so the editor doesnt freak out at first
    camSlice.width = mainView.width;
    camSlice.height = mainView.height;

    showExtendedBounds = false;
  }

  public override function update(elapsed:Float):Void
  {
    super.update(elapsed);

    scrollTarget.set(cameraFollowPoint.x - (FlxG.width / 2), cameraFollowPoint.y - (FlxG.height / 2));

    if (forceNextFocus)
    {
      vCamPoint.copyFrom(scrollTarget);
      forceNextFocus = false;
    }

    if (isClassicEase)
    {
      var cameraFollowElapsed = Conductor.instance.songPosition - cameraFollowTween;

      // Apply classic ease: 1.0 - Math.pow(1.0 - Constants.DEFAULT_CAMERA_FOLLOW_RATE, elapsed * 60)
      final adjustedProgressElapsed = cameraFollowElapsed / 1000 * 60;
      final easeProgress = 1.0 - Math.pow(1.0 - Constants.DEFAULT_CAMERA_FOLLOW_RATE, adjustedProgressElapsed);

      vCamPoint.x = FlxMath.lerp(cameraFollowStart.x, scrollTarget.x, easeProgress);
      vCamPoint.y = FlxMath.lerp(cameraFollowStart.y, scrollTarget.y, easeProgress);

      if (easeProgress >= 0.9999)
      {
        vCamPoint.copyFrom(scrollTarget);
        isClassicEase = false;
      }
    }
    else if (cameraFollowEase != null)
    {
      // Handle regular easing
      var cameraFollowElapsed = Conductor.instance.songPosition - cameraFollowTween;
      vCamPoint.x = FlxMath.lerp(cameraFollowStart.x, scrollTarget.x, cameraFollowEase(cameraFollowElapsed / (cameraFollowDuration * 1000)));
      vCamPoint.y = FlxMath.lerp(cameraFollowStart.y, scrollTarget.y, cameraFollowEase(cameraFollowElapsed / (cameraFollowDuration * 1000)));

      if (cameraFollowElapsed >= cameraFollowDuration * 1000)
      {
        cameraFollowEase = null;
        vCamPoint.copyFrom(scrollTarget);
      }
    }
    // Handle camera zoom tweening
    if (cameraZoomEase != null)
    {
      var cameraZoomElapsed = Conductor.instance.songPosition - cameraZoomTween;
      zoom = FlxMath.lerp(cameraZoomStart, cameraZoomEnd, cameraZoomEase(cameraZoomElapsed / (cameraZoomDuration * 1000)));

      if (cameraZoomElapsed >= cameraZoomDuration * 1000)
      {
        cameraZoomEase = null;
        zoom = cameraZoomEnd;
      }
    }

    updateVisuals();
  }

  function updateVisuals():Void
  {
    mainView.x = (vCamPoint.x + (FlxG.width / 2)) - mainView.width / 2;
    mainView.y = (vCamPoint.y + (FlxG.height / 2)) - mainView.height / 2;

    camSlice.x = (vCamPoint.x + (FlxG.width / 2)) - camSlice.width / 2;
    camSlice.y = (vCamPoint.y + (FlxG.height / 2)) - camSlice.height / 2;

    cornerTL.setPosition(mainView.x, mainView.y);
    cornerBR.setPosition(mainView.x + mainView.width - cornerBR.width, mainView.y + mainView.height - cornerBR.height);

    cornerTR.setPosition(mainView.x + mainView.width - cornerTR.width, mainView.y);
    cornerBL.setPosition(mainView.x, mainView.y + mainView.height - cornerBR.height);

    lineT.setPosition(mainView.x + (mainView.width / 2) - lineT.width / 2, mainView.y);
    lineB.setPosition(mainView.x + (mainView.width / 2) - lineT.width / 2, mainView.y + mainView.height - lineB.height);

    lineL.setPosition(mainView.x, mainView.y + (mainView.height / 2) - lineL.height / 2);
    lineR.setPosition(mainView.x + mainView.width - lineR.width, mainView.y + (mainView.height / 2) - lineL.height / 2);

    middle.setPosition(mainView.x + (mainView.width / 2) - middle.width / 2, mainView.y + (mainView.height / 2) - middle.height / 2);

    camSliceOverlay.width = camSlice.width;
    camSliceOverlay.height = camSlice.height;
    camSliceOverlay.setPosition(camSlice.x, camSlice.y);

    leftExt.width = pieceSize / zoom;
    leftExt.height = camSlice.height;
    leftExt.setPosition(camSlice.x - leftExt.width, camSlice.y);

    rightExt.width = pieceSize / zoom;
    rightExt.height = camSlice.height;
    rightExt.setPosition(camSlice.x + camSlice.width, camSlice.y);

    cornerTLSmall.setPosition(leftExt.x, leftExt.y);
    cornerBLSmall.setPosition(leftExt.x, leftExt.y + leftExt.height - cornerBRSmall.height);

    cornerBRSmall.setPosition(rightExt.x + rightExt.width - cornerBRSmall.width, rightExt.y + rightExt.height - cornerBRSmall.height);
    cornerTRSmall.setPosition(rightExt.x + rightExt.width - cornerTRSmall.width, rightExt.y);

    lineLSmall.setPosition(leftExt.x, leftExt.y + (leftExt.height / 2) - lineLSmall.height / 2);

    lineRSmall.setPosition(rightExt.x + rightExt.width - lineRSmall.width, rightExt.y + (rightExt.height / 2) - lineLSmall.height / 2);
  }
}
