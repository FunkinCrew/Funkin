package funkin.ui.haxeui.components.editors.camera;

#if FEATURE_CAMERA_EDITOR
import flixel.FlxSprite;
import flixel.util.FlxTimer;
import funkin.data.song.SongData.SongEventData;
import funkin.play.event.SongEvent;
import funkin.play.event.SongEventHelper;
import haxe.ui.containers.HBox;
import haxe.ui.events.UIEvent;
import openfl.display.BitmapData;

/**
 * Self-contained ease editor used by the Camera Editor properties panels.
 *
 * Owns the ease-type and ease-direction dropdowns plus the animated curve
 * preview. Bind a `SongEventData` and the component reads/writes its `ease`
 * and `easeDir` keys directly. Listen for user-driven mutations by binding
 * to `UIEvent.CHANGE` on this component.
 */
@:xml('
<hbox width="100%" height="100%">
  <vbox width="100%" height="100%">
    <dropdown id="easeDropdown" text="Ease" width="140">
      <data>
        <item id="linear" text="Linear" />
        <item id="INSTANT" text="Instant (Ignores duration)" />
        <item id="sine" text="Sine" />
        <item id="quad" text="Quad" />
        <item id="cube" text="Cube" />
        <item id="quart" text="Quart" />
        <item id="quint" text="Quint" />
        <item id="expo" text="Expo" />
        <item id="smoothStep" text="Smooth Step" />
        <item id="smootherStep" text="Smoother Step" />
        <item id="elastic" text="Elastic" />
        <item id="back" text="Back" />
        <item id="bounce" text="Bounce" />
        <item id="circ" text="Circ" />
      </data>
    </dropdown>
    <dropdown id="easeDirDropdown" text="Ease Dir" width="80" hidden="true">
      <data>
        <item id="In" text="In" />
        <item id="Out" text="Out" />
        <item id="InOut" text="In/Out" />
      </data>
    </dropdown>
  </vbox>
  <image width="100" height="100" style="border:1px solid $normal-border-color" id="easeGraph" />
  <image width="16" height="100" style="border:1px solid $normal-border-color" id="easeDot" />
</hbox>
')
class EaseGraphPreview extends HBox
{
  static final DOT_INTERVAL:Float = 1.0 / 30.0;
  static final LOOP_PAUSE:Float = 0.15;
  static final EASE_GRAPH_SIZE:Int = 100;

  /**
   * Default ease key when the bound event has no `ease` property set.
   * Set by the parent before assigning `event` (e.g. `'CLASSIC'` for FocusCamera).
   */
  public var defaultEase:String = SongEvent.DEFAULT_EASE;

  /**
   * Whether the `CLASSIC` option appears in the ease-type dropdown.
   * Set by the parent before assigning `event`.
   */
  public var classicEnabled(default, set):Bool = false;

  /**
   * The song event currently being edited. Assigning re-renders dropdowns + preview.
   * Pass `null` to clear.
   */
  public var event(default, set):Null<SongEventData> = null;

  var _easeGraphSprite:Null<FlxSprite> = null;
  var _easeDotSprites:Array<FlxSprite> = [];
  var _dotTimer:Null<FlxTimer> = null;
  var _pauseTimer:Null<FlxTimer> = null;
  var _dotIndex:Int = 0;
  var _loading:Bool = false;

  public function new()
  {
    super();
  }

  /**
   * Re-read `event` and refresh dropdowns + preview. Call after an external
   * mutation to the bound event.
   */
  public function refresh():Void
  {
    _loading = true;

    final easeStr:String = resolveEaseStr();
    final easeType:String = SongEventHelper.resolveEaseTypeFromKey(easeStr);
    final easeDir:String = resolveEaseDirStr(easeStr);

    easeDropdown.selectItemBy(function(data):Bool {
      return data.id == easeType;
    });
    easeDirDropdown.selectItemBy(function(data):Bool {
      return data.id == easeDir;
    });

    syncEaseDirVisibility();
    setEase(buildEaseKey());

    _loading = false;
  }

  /**
   * Cancel timers and clear sprite references. Call from the owner's destroy().
   */
  public function cleanup():Void
  {
    cancelTimers();
    _easeGraphSprite = null;
    _easeDotSprites = [];
  }

  function set_classicEnabled(value:Bool):Bool
  {
    if (classicEnabled == value) return value;
    classicEnabled = value;

    if (value)
    {
      // Insert CLASSIC right after INSTANT so the order matches the historical layout.
      easeDropdown.dataSource.insert(2, {id: 'CLASSIC', text: 'Classic (Ignores duration)'});
    }
    else
    {
      for (i in 0...easeDropdown.dataSource.size)
      {
        final entry:Dynamic = easeDropdown.dataSource.get(i);
        if (entry != null && entry.id == 'CLASSIC')
        {
          easeDropdown.dataSource.removeAt(i);
          break;
        }
      }
    }

    return value;
  }

  function set_event(value:Null<SongEventData>):Null<SongEventData>
  {
    event = value;
    refresh();
    return value;
  }

  function resolveEaseStr():String
  {
    if (event == null) return defaultEase;
    return event.getString('ease') ?? defaultEase;
  }

  function resolveEaseDirStr(easeStr:String):String
  {
    final raw:Null<String> = (event == null) ? null : event.getString('easeDir');
    if (raw == null || raw == '') return SongEventHelper.resolveEaseDirFromKey(easeStr);
    return raw;
  }

  function buildEaseKey():String
  {
    final easeStr:String = resolveEaseStr();
    final easeType:String = SongEventHelper.resolveEaseTypeFromKey(easeStr);
    final easeDir:String = resolveEaseDirStr(easeStr);
    return '$easeType$easeDir';
  }

  function syncEaseDirVisibility():Void
  {
    final easeType:String = SongEventHelper.resolveEaseTypeFromKey(resolveEaseStr());
    easeDirDropdown.hidden = (easeType == 'CLASSIC' || easeType == 'INSTANT');
  }

  @:bind(easeDropdown, UIEvent.CHANGE)
  function onEaseDropdownChange(_):Void
  {
    if (_loading || event == null) return;

    final selected:Dynamic = easeDropdown.selectedItem;
    final value:String = (selected == null) ? defaultEase : selected.id;

    event.set('ease', value);

    syncEaseDirVisibility();
    setEase(buildEaseKey());

    dispatch(new UIEvent(UIEvent.CHANGE));
  }

  @:bind(easeDirDropdown, UIEvent.CHANGE)
  function onEaseDirDropdownChange(_):Void
  {
    if (_loading || event == null) return;

    final selected:Dynamic = easeDirDropdown.selectedItem;
    final value:String = (selected == null) ? SongEvent.DEFAULT_EASE_DIR : selected.id;

    event.set('easeDir', value);

    setEase(buildEaseKey());

    dispatch(new UIEvent(UIEvent.CHANGE));
  }

  /**
   * Update the curve graph + dot animation for the supplied combined ease key
   * (e.g. `sineInOut`). Pass a non-visual key (CLASSIC, INSTANT) or null to
   * hide just the graph/dot — dropdowns stay visible.
   */
  function setEase(easeKey:Null<String>):Void
  {
    cancelTimers();
    _easeDotSprites = [];
    _dotIndex = 0;

    if (easeKey == null || isNonVisualEase(easeKey))
    {
      hideGraph();
      return;
    }

    final graphBd:Null<BitmapData> = SongEventHelper.getEaseBitmap(easeKey);
    _easeGraphSprite = SongEventHelper.createSpriteFromKey(easeKey, EASE_GRAPH_SIZE, EASE_GRAPH_SIZE);
    easeGraph.resource = _easeGraphSprite?.frame;

    if (graphBd == null || easeGraph.resource == null)
    {
      hideGraph();
      return;
    }

    showGraph();

    final dotSprites:Array<FlxSprite> = SongEventHelper.getOrCreateEaseDotSprites(easeKey, 30, 3, 16);
    if (dotSprites == null || dotSprites.length == 0)
    {
      easeDot.resource = null;
      return;
    }
    _easeDotSprites = dotSprites;
    easeDot.resource = _easeDotSprites[0].frame;

    startDotAnimation();
  }

  function cancelTimers():Void
  {
    _dotTimer?.cancel();
    _pauseTimer?.cancel();
    _dotTimer = null;
    _pauseTimer = null;
  }

  function hideGraph():Void
  {
    easeGraph.resource = null;
    easeDot.resource = null;
    easeGraph.hidden = true;
    easeDot.hidden = true;
  }

  function showGraph():Void
  {
    easeGraph.hidden = false;
    easeDot.hidden = false;
  }

  function startDotAnimation():Void
  {
    _dotTimer ??= new FlxTimer();
    _dotTimer.start(DOT_INTERVAL, onDotTick, 0);
  }

  function onDotTick(_:FlxTimer):Void
  {
    if (_dotTimer == null) return;
    _dotIndex++;
    if (_dotIndex >= _easeDotSprites.length)
    {
      _dotTimer?.cancel();
      _pauseTimer ??= new FlxTimer();
      _pauseTimer.start(LOOP_PAUSE, onLoopRestart, 1);
    }
    else if (_easeDotSprites[_dotIndex].frame != null)
    {
      easeDot.resource = _easeDotSprites[_dotIndex].frame;
    }
  }

  function onLoopRestart(_:FlxTimer):Void
  {
    if (_pauseTimer == null) return;
    _dotIndex = 0;
    if (_easeDotSprites[0] != null && _easeDotSprites[0].frame != null)
    {
      easeDot.resource = _easeDotSprites[0].frame;
    }
    _dotTimer ??= new FlxTimer();
    _dotTimer.start(DOT_INTERVAL, onDotTick, 0);
  }

  static function isNonVisualEase(easeKey:String):Bool
  {
    final easeType:Null<String> = SongEventHelper.resolveEaseTypeFromKey(easeKey);
    return easeType == 'CLASSIC' || easeType == 'INSTANT';
  }
}
#end
