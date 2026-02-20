package funkin.ui.debug.cameraeditor.components;

#if FEATURE_CAMERA_EDITOR
import flixel.FlxSprite;
import flixel.util.FlxTimer;
import funkin.play.event.SongEventHelper;
import haxe.ui.containers.VBox;
import haxe.ui.events.UIEvent;
import openfl.display.BitmapData;

/**
 * The contents of the Properties panel, while a Zoom Camera event is selected.
 */
@:build(haxe.ui.macros.ComponentMacros.build("assets/exclude/data/ui/camera-editor/components/properties/zoom-camera.xml"))
class ZoomCameraContainer extends VBox
{
  /**
   * The CameraEditorState to attach to.
   */
  public var cameraEditorState:CameraEditorState;

  public function new(state:CameraEditorState)
  {
    super();
    cameraEditorState = state;
    updateEasePreview();
  }

  var _easeGraphSprite:Null<FlxSprite> = null;
  var _easeDotSprites:Array<FlxSprite> = [];
  var _dotTimer:Null<FlxTimer> = null;
  var _pauseTimer:Null<FlxTimer> = null;
  var _dotIndex:Int = 0;

  static final _dotInterval:Float = 1.0 / 30.0;
  static final _loopPause:Float = 0.15;

  function updateEasePreview():Void
  {
    if (zoomCameraEaseGraph == null || zoomCameraEaseDot == null)
    {
      throw "Could not find ease graph or ease dot!";
    }

    // TODO: Fetch this correctly.
    final easeStr:String = "elastic";
    final easeDirStr:String = "InOut";
    final key:String = easeStr + (easeDirStr == "" ? "" : easeDirStr);

    // Hide preview when easing indicates a non-visual/legacy type such as "classic"
    if (easeStr != null && easeStr.toLowerCase().indexOf("classic") != -1)
    {
      _dotTimer?.cancel();
      _pauseTimer?.cancel();
      _dotTimer = null;
      _pauseTimer = null;
      _easeDotSprites = [];
      _dotIndex = 0;

      zoomCameraEaseGraph.resource = null;
      zoomCameraEaseDot.resource = null;
      zoomCameraEaseGraph.hidden = true;
      zoomCameraEaseDot.hidden = true;
      if (zoomCameraEaseBox != null) zoomCameraEaseBox.hidden = true;
      return;
    }

    // Reset any previous timers/sprites
    _dotTimer?.cancel();
    _pauseTimer?.cancel();
    _dotTimer = null;
    _pauseTimer = null;
    _easeDotSprites = [];
    _dotIndex = 0;

    final _graphBd:BitmapData = SongEventHelper.getEaseBitmap(key);
    _easeGraphSprite = SongEventHelper.createSpriteFromKey(key, 100, 100);
    zoomCameraEaseGraph.resource = _easeGraphSprite?.frame;
    if (_graphBd == null || zoomCameraEaseGraph.resource == null)
    {
      zoomCameraEaseDot.resource = null;
      zoomCameraEaseGraph.hidden = true;
      zoomCameraEaseDot.hidden = true;
      if (zoomCameraEaseBox != null) zoomCameraEaseBox.hidden = true;
      return;
    }

    // show preview and start dot animation
    zoomCameraEaseGraph.hidden = false;
    zoomCameraEaseDot.hidden = false;
    if (zoomCameraEaseBox != null) zoomCameraEaseBox.hidden = false;

    var dotSprites:Array<flixel.FlxSprite> = SongEventHelper.getOrCreateEaseDotSprites(key, 30, 3, 16);
    if (dotSprites == null || dotSprites.length == 0)
    {
      // if no dot sprites, still show graph but keep dot empty
      zoomCameraEaseDot.resource = null;
      return;
    }
    _easeDotSprites = dotSprites;
    zoomCameraEaseDot.resource = _easeDotSprites[0].frame;

    var frameCallback:Dynamic = null;
    frameCallback = (tmr:FlxTimer) -> {
      if (_dotTimer == null || _easeDotSprites.length == 0) return;

      _dotIndex++;
      if (_dotIndex >= _easeDotSprites.length)
      {
        _dotTimer?.cancel();
        _pauseTimer ??= new FlxTimer();
        _pauseTimer.start(_loopPause, function(p:FlxTimer):Void {
          if (_pauseTimer == null || _easeDotSprites.length == 0) return;

          if (zoomCameraEaseDot != null)
          {
            _dotIndex = 0;
            if (_easeDotSprites[0] != null && _easeDotSprites[0].frame != null)
            {
              zoomCameraEaseDot.resource = _easeDotSprites[0].frame;
            }
            _dotTimer ??= new FlxTimer();
            _dotTimer.start(_dotInterval, frameCallback, 0);
          }
        }, 1);
      }
      else if (zoomCameraEaseDot != null && _easeDotSprites[_dotIndex].frame != null)
      {
        zoomCameraEaseDot.resource = _easeDotSprites[_dotIndex].frame;
      }
    };

    _dotTimer ??= new FlxTimer();
    _dotTimer.start(_dotInterval, frameCallback, 0);
  }

  public function loadCurrentEventData():Void
  {
  }

  /**
   * Called when the Zoom Level field is changed.
   */
  @:bind(zoomCameraZoomLevel, UIEvent.CHANGE)
  function onChange_zoomCameraZoomLevel(_):Void
  {
    var value:Float = zoomCameraZoomLevel.value;

    trace('Zoom Camera: Zoom Level changed to ' + value);

    // cameraEditorState.currentCameraEvent.zoomLevel = value;
  }

  /**
   * Called when the Zoom Camera Mode field is changed.
   */
  @:bind(zoomCameraMode, UIEvent.CHANGE)
  function onChange_zoomCameraMode(_):Void
  {
    var value:String = zoomCameraMode.value;

    trace('Zoom Camera: Mode changed to ' + value);
  }

  /**
   * Called when the Zoom Camera Duration field is changed.
   */
  @:bind(zoomCameraDuration, UIEvent.CHANGE)
  function onChange_zoomCameraDuration(_):Void
  {
    var value:Float = zoomCameraDuration.value;

    trace('Zoom Camera: Duration changed to ' + value);
  }

  /**
   * Called when the Zoom Camera Ease Type field is changed.
   */
  @:bind(zoomCameraEase, UIEvent.CHANGE)
  function onChange_zoomCameraEase(_):Void
  {
    var value:String = zoomCameraEase.selectedItem.text;

    trace('Zoom Camera: Ease Type changed to ' + value);
  }

  /**
   * Called when the Zoom Camera Ease Dir field is changed.
   */
  @:bind(zoomCameraEaseDir, UIEvent.CHANGE)
  function onChange_zoomCameraEaseDir(_):Void
  {
    var value:String = zoomCameraEaseDir.selectedItem.text;

    trace('Zoom Camera: Ease Dir changed to ' + value);
  }

  override public function destroy():Void
  {
    super.destroy();

    zoomCameraEaseGraph.destroy();
    zoomCameraEaseGraph = null;
    zoomCameraEaseDot.destroy();
    zoomCameraEaseDot = null;

    _easeGraphSprite = null;
    _easeDotSprites = [];

    if (_dotTimer != null)
    {
      _dotTimer.cancel();
      _dotTimer = null;
    }

    if (_pauseTimer != null)
    {
      _pauseTimer.cancel();
      _pauseTimer = null;
    }
  }
}
#end
