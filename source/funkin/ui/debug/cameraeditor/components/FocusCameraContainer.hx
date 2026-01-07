package funkin.ui.debug.cameraeditor.components;

#if FEATURE_CAMERA_EDITOR
import flixel.FlxSprite;
import flixel.util.FlxTimer;
import funkin.play.event.SongEventHelper;
import haxe.ui.containers.VBox;
import haxe.ui.events.UIEvent;
import openfl.display.BitmapData;

/**
 * The contents of the Properties panel, while a Focus Camera event is selected.
 */
@:build(haxe.ui.macros.ComponentMacros.build("assets/exclude/data/ui/camera-editor/components/properties/focus-camera.xml"))
class FocusCameraContainer extends VBox
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
    if (focusCameraEaseGraph == null || focusCameraEaseDot == null)
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

      focusCameraEaseGraph.resource = null;
      focusCameraEaseDot.resource = null;
      focusCameraEaseGraph.hidden = true;
      focusCameraEaseDot.hidden = true;
      if (focusCameraEaseBox != null) focusCameraEaseBox.hidden = true;
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
    focusCameraEaseGraph.resource = _easeGraphSprite?.frame;
    if (_graphBd == null || focusCameraEaseGraph.resource == null)
    {
      focusCameraEaseDot.resource = null;
      focusCameraEaseGraph.hidden = true;
      focusCameraEaseDot.hidden = true;
      if (focusCameraEaseBox != null) focusCameraEaseBox.hidden = true;
      return;
    }

    // show preview and start dot animation
    focusCameraEaseGraph.hidden = false;
    focusCameraEaseDot.hidden = false;
    if (focusCameraEaseBox != null) focusCameraEaseBox.hidden = false;

    var dotSprites:Array<flixel.FlxSprite> = SongEventHelper.getOrCreateEaseDotSprites(key, 30, 3, 16);
    if (dotSprites == null || dotSprites.length == 0)
    {
      // if no dot sprites, still show graph but keep dot empty
      focusCameraEaseDot.resource = null;
      return;
    }
    _easeDotSprites = dotSprites;
    focusCameraEaseDot.resource = _easeDotSprites[0].frame;

    var frameCallback:Dynamic = null;
    frameCallback = (tmr:FlxTimer) -> {
      if (_dotTimer == null) return;

      _dotIndex++;
      if (_dotIndex >= _easeDotSprites.length)
      {
        _dotTimer?.cancel();
        _pauseTimer ??= new FlxTimer();
        _pauseTimer.start(_loopPause, function(p:FlxTimer):Void {
          if (_pauseTimer == null) return;

          if (focusCameraEaseDot != null)
          {
            _dotIndex = 0;
            if (_easeDotSprites[0] != null && _easeDotSprites[0].frame != null)
            {
              focusCameraEaseDot.resource = _easeDotSprites[0].frame;
            }
            _dotTimer ??= new FlxTimer();
            _dotTimer.start(_dotInterval, frameCallback, 0);
          }
        }, 1);
      }
      else if (focusCameraEaseDot != null && _easeDotSprites[_dotIndex].frame != null)
      {
        focusCameraEaseDot.resource = _easeDotSprites[_dotIndex].frame;
      }
    };

    _dotTimer ??= new FlxTimer();
    _dotTimer.start(_dotInterval, frameCallback, 0);
  }

  /**
   * Called when the Focus Camera Target field is changed.
   */
  @:bind(focusCameraTarget, UIEvent.CHANGE)
  function onChange_focusCameraTarget(_):Void
  {
    var value:String = focusCameraTarget.selectedItem.text;

    trace('Focus Camera: Target changed to ' + value);
  }

  /**
   * Called when the Focus Camera X Position field is changed.
   */
  @:bind(focusCameraXPos, UIEvent.CHANGE)
  function onChange_focusCameraXPos(_):Void
  {
    var value:Float = focusCameraXPos.value;

    trace('Focus Camera: X Position changed to ' + value);
  }

  /**
   * Called when the Focus Camera Y Position field is changed.
   */
  @:bind(focusCameraYPos, UIEvent.CHANGE)
  function onChange_focusCameraYPos(_):Void
  {
    var value:Float = focusCameraYPos.value;

    trace('Focus Camera: Y Position changed to ' + value);
  }

  /**
   * Called when the Focus Camera Duration field is changed.
   */
  @:bind(focusCameraDuration, UIEvent.CHANGE)
  function onChange_focusCameraDuration(_):Void
  {
    var value:Float = focusCameraDuration.value;

    trace('Focus Camera: Duration changed to ' + value);
  }

  /**
   * Called when the Focus Camera Ease Type field is changed.
   */
  @:bind(focusCameraEaseType, UIEvent.CHANGE)
  function onChange_focusCameraEaseType(_):Void
  {
    var value:String = focusCameraEaseType.selectedItem.text;

    trace('Focus Camera: Ease Type changed to ' + value);
  }

  /**
   * Called when the Focus Camera Ease Dir field is changed.
   */
  @:bind(focusCameraEaseDir, UIEvent.CHANGE)
  function onChange_focusCameraEaseDir(_):Void
  {
    var value:String = focusCameraEaseDir.selectedItem.text;

    trace('Focus Camera: Ease Dir changed to ' + value);
  }

  public override function destroy():Void
  {
    super.destroy();

    focusCameraEaseGraph.destroy();
    focusCameraEaseGraph = null;
    focusCameraEaseDot.destroy();
    focusCameraEaseDot = null;

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
