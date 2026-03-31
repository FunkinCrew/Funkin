package funkin.ui.debug.cameraeditor.components;

import funkin.play.event.SongEvent;
import funkin.play.event.ZoomCameraSongEvent;
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

  /**
   * Redraws the custom easing preview graph.
   * TODO: Code is heavily shared with the Chart Editor event window and FocusCameraContainer
   */
  function updateEasePreview():Void
  {
    if (zoomCameraEaseGraph == null || zoomCameraEaseDot == null)
    {
      throw 'Could not find ease graph or ease dot!';
    }

    var easeStr:String = cameraEditorState.selectedSongEvent.getString('ease') ?? SongEvent.DEFAULT_EASE;
    var easeDirStr:String = cameraEditorState.selectedSongEvent.getString('easeDir') ?? SongEvent.DEFAULT_EASE_DIR;

    final key:String = easeStr + (easeDirStr == '' ? '' : easeDirStr);

    // Hide preview when easing indicates a non-visual/legacy type such as "classic"
    if (easeStr != null && (easeStr == 'CLASSIC' || easeStr == 'INSTANT'))
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

      zoomCameraEaseDir.hidden = true;

      return;
    }
    else
    {
      zoomCameraEaseDir.hidden = false;
    }

    // Reset any previous timers/sprites
    _dotTimer?.cancel();
    _pauseTimer?.cancel();
    _dotTimer = null;
    _pauseTimer = null;
    _easeDotSprites = [];
    _dotIndex = 0;

    final EASE_GRAPH_SIZE:Int = 100;

    final _graphBd:BitmapData = SongEventHelper.getEaseBitmap(key);
    _easeGraphSprite = SongEventHelper.createSpriteFromKey(key, EASE_GRAPH_SIZE, EASE_GRAPH_SIZE);
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
    frameCallback = (tmr:FlxTimer) ->
    {
      if (_dotTimer == null) return;

      _dotIndex++;
      if (_dotIndex >= _easeDotSprites.length)
      {
        _dotTimer?.cancel();
        _pauseTimer ??= new FlxTimer();
        _pauseTimer.start(_loopPause, function(p:FlxTimer):Void
        {
          if (_pauseTimer == null) return;

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

  function updateCameraPreview():Void
  {
    cameraEditorState.replayCameraTimeline(cameraEditorState.conductorInUse.songPosition);
  }

  function updateBlockVisuals():Void
  {
    cameraEditorState.timeline.viewport.refreshBlockVisuals(true);
  }

  /**
   * Loads the data for the currently selected event into the UI.
   */
  public function loadCurrentEventData():Void
  {
    var modeType = cameraEditorState.selectedSongEvent.getString('mode') ?? ZoomCameraSongEvent.DEFAULT_MODE;
    if (modeType == 'stage') zoomCameraMode.selectedIndex = 0;
    else if (modeType == 'direct') zoomCameraMode.selectedIndex = 1;

    zoomCameraZoomLevel.value = cameraEditorState.selectedSongEvent.getFloat('zoom') ?? ZoomCameraSongEvent.DEFAULT_ZOOM;
    zoomCameraDuration.value = cameraEditorState.selectedSongEvent.getFloat('duration') ?? ZoomCameraSongEvent.DEFAULT_DURATION;

    var eventEase:String = cameraEditorState.selectedSongEvent.getString('ease') ?? SongEvent.DEFAULT_EASE;
    zoomCameraEase.selectItemBy(function(data):Bool
    {
      return data.id == eventEase;
    });

    if (eventEase == 'CLASSIC' || eventEase == 'INSTANT')
    {
      zoomCameraEaseDir.hidden = true;
    }
    else
    {
      zoomCameraEaseDir.hidden = false;
    }

    var eventEaseDir:String = cameraEditorState.selectedSongEvent.getString('easeDir') ?? SongEvent.DEFAULT_EASE_DIR;
    zoomCameraEaseDir.selectItemBy(function(data):Bool
    {
      return data.id == eventEaseDir;
    });

    updateEasePreview();
    updateCameraPreview();
    updateBlockVisuals();
  }

  /**
   * Called when the Zoom Level field is changed.
   */
  @:bind(zoomCameraZoomLevel, UIEvent.CHANGE)
  function onChange_zoomCameraZoomLevel(_):Void
  {
    var value:Float = zoomCameraZoomLevel.value;

    trace('Zoom Camera: Zoom Level changed to ' + value);

    cameraEditorState.selectedSongEvent.set('zoom', value);
    updateCameraPreview();
  }

  /**
   * Called when the Zoom Mode field is changed.
   */
  @:bind(zoomCameraMode, UIEvent.CHANGE)
  function onChange_zoomCameraMode(_):Void
  {
    if (zoomCameraMode.selectedItem == null)
    {
      cameraEditorState.selectedSongEvent.set('mode', ZoomCameraSongEvent.DEFAULT_MODE);
      return;
    }

    var index = zoomCameraMode.selectedIndex;
    var value = 'stage';
    if (index == 1) value = 'direct';

    trace('Zoom Camera: Mode changed to ' + value);

    cameraEditorState.selectedSongEvent.set('mode', value);
    updateCameraPreview();
  }

  /**
   * Called when the Zoom Camera Duration field is changed.
   */
  @:bind(zoomCameraDuration, UIEvent.CHANGE)
  function onChange_zoomCameraDuration(_):Void
  {
    var value:Float = zoomCameraDuration.value;

    cameraEditorState.selectedSongEvent.set('duration', value);
    updateCameraPreview();
    updateBlockVisuals();
  }

  /**
   * Called when the Zoom Camera Ease Type field is changed.
   */
  @:bind(zoomCameraEase, UIEvent.CHANGE)
  function onChange_zoomCameraEase(_):Void
  {
    if (zoomCameraEase.selectedItem == null)
    {
      cameraEditorState.selectedSongEvent.set('ease', SongEvent.DEFAULT_EASE);
      return;
    }

    var label:String = zoomCameraEase.selectedItem.text;
    var value:String = zoomCameraEase.selectedItem.id;

    trace('Zoom Camera: Ease Type changed to $label ($value)');

    cameraEditorState.selectedSongEvent.set('ease', value);

    // If the ease type is classic or instant, don't display ease direction
    if (value == 'CLASSIC' || value == 'INSTANT')
    {
      zoomCameraEaseDir.hidden = true;
    }
    else
    {
      zoomCameraEaseDir.hidden = false;
    }

    updateEasePreview();
    updateCameraPreview();
    updateBlockVisuals();
  }

  /**
   * Called when the Zoom Camera Ease Dir field is changed.
   */
  @:bind(zoomCameraEaseDir, UIEvent.CHANGE)
  function onChange_zoomCameraEaseDir(_):Void
  {
    if (zoomCameraEaseDir.selectedItem == null)
    {
      trace('Zoom Camera: No ease direction selected!');
      cameraEditorState.selectedSongEvent.set('easeDir', SongEvent.DEFAULT_EASE_DIR);
      return;
    }

    var label:String = zoomCameraEaseDir.selectedItem.text;
    var value:String = zoomCameraEaseDir.selectedItem.id;

    trace('Zoom Camera: Ease Dir changed to $label ($value)');

    cameraEditorState.selectedSongEvent.set('easeDir', value);

    updateEasePreview();
    updateCameraPreview();
    updateBlockVisuals();
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
