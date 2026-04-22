package funkin.ui.haxeui.components.editors.timeline;

#if FEATURE_CAMERA_EDITOR
import funkin.ui.haxeui.components.IconButton;
import haxe.ui.components.TextField;
import haxe.ui.containers.Box;
import haxe.ui.containers.HBox;
import haxe.ui.containers.VBox;
import haxe.ui.core.CompositeBuilder;
import haxe.ui.core.Platform;
import haxe.ui.core.Screen;
import haxe.ui.events.FocusEvent;
import haxe.ui.events.KeyboardEvent;
import haxe.ui.events.MouseEvent;
import haxe.ui.events.UIEvent;

typedef LayerRowHandles =
{
  row:HBox,
  field:TextField,
  editOriginal:Null<String>,
  cancelling:Bool
};

@:composite(TimelineLayerPanelBuilder) @:xml('
<vbox width="120" style="background-color: #2A2A2A; spacing: 0; clip: true; overflow: hidden;">
</vbox>
')
class TimelineLayerPanel extends VBox
{
  public var btnAddLayer:IconButton;
  public var btnRemoveLayer:IconButton;
  public var _layerContainer:VBox;
  public var _layerClipBox:Box;
  public var viewport:TimelineViewport;

  // "cold load" path rebuilds this; surgical commands mutate it via
  // insertLayerRow / removeLayerRow so we don't do a full rebuild each update.
  var _handlesByLayer:Map<TimelineLayerData, LayerRowHandles> = new Map();

  var _editingLayer:TimelineLayerData = null;
  var _editingHandles:LayerRowHandles = null;
  var _screenMouseDownBound:MouseEvent->Void;

  public function setScrollOffset(offsetPx:Float):Void
  {
    if (_layerContainer == null) return;
    _layerContainer.top = -offsetPx;
  }

  /**
   * "cold load" path — rebuilds every layer row from scratch.
   * commands should use `insertLayerRow` / `removeLayerRow` / `refreshSelectedHighlight`
   * to avoid the flicker from the full teardown.
   */
  public function rebuildLayers(layers:Array<TimelineLayerData>):Void
  {
    _layerContainer.removeAllComponents();
    _handlesByLayer = new Map();

    for (i in 0...layers.length) _insertLayerRowInternal(layers[i], i);

    _layerContainer.syncComponentValidation();
  }

  public function insertLayerRow(layer:TimelineLayerData, index:Int):Void
  {
    _insertLayerRowInternal(layer, index);
    refreshSelectedHighlight();
    _layerContainer.syncComponentValidation();
  }

  public function removeLayerRow(layer:TimelineLayerData):Void
  {
    var handles:LayerRowHandles = _handlesByLayer.get(layer);
    if (handles == null) return;
    _layerContainer.removeComponent(handles.row);
    _handlesByLayer.remove(layer);
    refreshSelectedHighlight();
    _layerContainer.syncComponentValidation();
  }

  public function refreshSelectedHighlight():Void
  {
    if (viewport == null) return;
    for (layer => handles in _handlesByLayer)
    {
      var idx:Int = viewport.layers.indexOf(layer);
      handles.row.customStyle.backgroundColor = (idx == viewport.selectedLayerIndex) ? 0x505050 : 0x3A3A3A;
      handles.row.invalidateComponentStyle();
    }
  }

  public function refreshLayerName(layer:TimelineLayerData):Void
  {
    var handles:LayerRowHandles = _handlesByLayer.get(layer);
    if (handles == null) return;
    if (handles.field.text != layer.name) handles.field.text = layer.name;
  }

  function _insertLayerRowInternal(layer:TimelineLayerData, index:Int):Void
  {
    var row:HBox = new HBox();
    row.percentWidth = 100;
    row.height = TimelineViewport.LAYER_HEIGHT - 2;
    row.customStyle.verticalAlign = "center";
    row.customStyle.paddingLeft = 6;
    row.customStyle.paddingRight = 6;
    row.customStyle.backgroundColor = 0x3A3A3A;

    if (viewport != null && viewport.layers.indexOf(layer) == viewport.selectedLayerIndex) row.customStyle.backgroundColor = 0x505050;

    // Click handler captures `layer` (stable) and resolves current index at click time.
    row.registerEvent(MouseEvent.CLICK, (_:MouseEvent) -> {
      if (viewport == null) return;
      var idx:Int = viewport.layers.indexOf(layer);
      if (idx < 0) return;
      viewport.selectedLayerIndex = idx;
      refreshSelectedHighlight();
    });

    var swatch:Box = new Box();
    swatch.width = 12;
    swatch.height = 12;
    swatch.customStyle.backgroundColor = layer.color;
    swatch.customStyle.borderRadius = 2;
    swatch.customStyle.verticalAlign = "center";

    // text field (not label) so it can be enabled in-place for inline editing
    var field:TextField = new TextField();
    field.text = layer.name;
    field.percentWidth = 100;
    field.addClass("no-border");
    field.addClass("no-background");
    field.addClass("no-padding");
    field.addClass("layer-name-field");
    field.customStyle.fontName = "Inconsolata";
    field.customStyle.fontSize = 13;
    field.customStyle.color = 0xCCCCCC;
    field.customStyle.filter = null;
    field.customStyle.paddingLeft = 4;
    field.customStyle.verticalAlign = "center";

    field.disabled = true;

    var handles:LayerRowHandles = {row: row, field: field, editOriginal: null, cancelling: false};

    row.registerEvent(MouseEvent.DBL_CLICK, (_:MouseEvent) -> _enterEditMode(layer));

    field.registerEvent(UIEvent.CHANGE, (_:UIEvent) -> {
      if (_editingHandles != handles) return;
      _refreshInvalidStyle(layer, handles);
    });

    field.registerEvent(UIEvent.SUBMIT, (_:UIEvent) -> {
      if (_editingHandles != handles) return;
      _attemptSubmit();
    });

    field.registerEvent(FocusEvent.FOCUS_OUT, (_:FocusEvent) -> _commitEdit(layer, handles));

    // Escape cancels the edit. TextField already handles Enter via UIEvent.SUBMIT.
    // KEY_DOWN fires on focused components via KeyboardHelper's focus-chain dispatch,
    // so a field-level listener runs without needing a Screen-level handler.
    field.registerEvent(KeyboardEvent.KEY_DOWN, (e:KeyboardEvent) -> {
      if (_editingHandles != handles) return;
      if (e.keyCode != Platform.instance.KeyEscape) return;
      handles.cancelling = true;
      handles.field.text = handles.editOriginal ?? layer.name;
      handles.field.focus = false;
      e.cancel();
    });

    row.addComponent(swatch);
    row.addComponent(field);

    if (index >= 0 && index < _layerContainer.childComponents.length) _layerContainer.addComponentAt(row, index);
    else
      _layerContainer.addComponent(row);

    _handlesByLayer.set(layer, handles);
  }

  function _enterEditMode(layer:TimelineLayerData):Void
  {
    if (layer.name == "Default")
    {
      var ev:TimelineEvent = new TimelineEvent(TimelineEvent.DEFAULT_LAYER_PROTECTED);
      ev.bubble = true;
      dispatch(ev);
      return;
    }

    var handles:LayerRowHandles = _handlesByLayer.get(layer);
    if (handles == null) return;
    if (_editingHandles == handles) return;

    if (_editingHandles != null) _editingHandles.field.focus = false;

    _editingLayer = layer;
    _editingHandles = handles;
    handles.editOriginal = layer.name;
    handles.cancelling = false;

    handles.field.disabled = false;
    handles.field.focus = true;

    _screenMouseDownBound = _onScreenMouseDown;
    Screen.instance.registerEvent(MouseEvent.MOUSE_DOWN, _screenMouseDownBound);
  }

  function _onScreenMouseDown(e:MouseEvent):Void
  {
    if (_editingHandles.field.hitTest(e.screenX, e.screenY)) return;
    _editingHandles.field.focus = false;
  }

  function _layerNameExists(name:String, exclude:TimelineLayerData):Bool
  {
    if (viewport == null) return false;
    for (other in viewport.layers)
    {
      if (other == exclude) continue;
      if (other.name == name) return true;
    }
    return false;
  }

  function _validateLayerName(trimmed:String, original:String, layer:TimelineLayerData):Null<String>
  {
    if (trimmed == "") return 'Layer name cannot be empty.';
    if (trimmed == original) return null;
    if (_layerNameExists(trimmed, layer)) return 'A layer named "$trimmed" already exists.';
    return null;
  }

  function _refreshInvalidStyle(layer:TimelineLayerData, handles:LayerRowHandles):Void
  {
    var text:String = handles.field.text;
    var trimmed:String = (text != null) ? StringTools.trim(text) : '';
    var original:String = handles.editOriginal ?? layer.name;
    var err:Null<String> = _validateLayerName(trimmed, original, layer);
    _setInvalidStyle(handles.field, err != null);
  }

  function _setInvalidStyle(field:TextField, invalid:Bool):Void
  {
    if (invalid) field.addClass('invalid');
    else field.removeClass('invalid');
  }

  function _attemptSubmit():Void
  {
    var handles:LayerRowHandles = _editingHandles;
    var layer:TimelineLayerData = _editingLayer;
    var text:String = handles.field.text;
    var trimmed:String = (text != null) ? StringTools.trim(text) : '';
    var original:String = handles.editOriginal ?? layer.name;

    var err:Null<String> = _validateLayerName(trimmed, original, layer);
    if (err != null)
    {
      _dispatchNameInvalid(err);
      _setInvalidStyle(handles.field, true);
      return;
    }

    handles.field.text = trimmed;
    handles.field.focus = false;
  }

  function _dispatchNameInvalid(msg:String):Void
  {
    var ev:TimelineEvent = new TimelineEvent(TimelineEvent.LAYER_NAME_INVALID);
    ev.message = msg;
    ev.bubble = true;
    dispatch(ev);
  }

  function _commitEdit(layer:TimelineLayerData, handles:LayerRowHandles):Void
  {
    if (_editingHandles != handles) return;

    handles.field.disabled = true;
    handles.field.removeClass(":active");
    _setInvalidStyle(handles.field, false);
    handles.field.invalidateComponentStyle();

    Screen.instance.unregisterEvent(MouseEvent.MOUSE_DOWN, _screenMouseDownBound);

    var original:String = handles.editOriginal ?? layer.name;
    handles.editOriginal = null;
    _editingLayer = null;
    _editingHandles = null;

    if (handles.cancelling)
    {
      handles.cancelling = false;
      return;
    }

    var rawName:String = handles.field.text;
    var trimmed:String = (rawName != null) ? StringTools.trim(rawName) : '';

    var err:Null<String> = _validateLayerName(trimmed, original, layer);
    if (err != null)
    {
      handles.field.text = original;
      _dispatchNameInvalid(err);
      return;
    }

    if (trimmed == original)
    {
      handles.field.text = original;
      return;
    }

    handles.field.text = trimmed;

    var ev:TimelineEvent = new TimelineEvent(TimelineEvent.LAYER_RENAMED);
    ev.layerData = layer;
    ev.oldLayerName = original;
    ev.newLayerName = trimmed;
    ev.bubble = true;
    dispatch(ev);
  }
}

@:dox(hide) @:noCompletion
private class TimelineLayerPanelBuilder extends CompositeBuilder
{
  var _panel:TimelineLayerPanel;

  public function new(panel:TimelineLayerPanel)
  {
    super(panel);
    _panel = panel;
  }

  override public function create():Void
  {
    var topSpacer = new HBox();
    topSpacer.percentWidth = 100;
    topSpacer.height = TimelineViewport.TOP_BAR_HEIGHT + 1;
    topSpacer.customStyle.backgroundColor = 0x1F1F1F;
    topSpacer.customStyle.paddingLeft = 6;
    topSpacer.customStyle.verticalAlign = "center";

    _panel.btnAddLayer = new IconButton();
    _panel.btnAddLayer.id = "btn-add-layer";
    _panel.btnAddLayer.icon = "shared:assets/shared/images/ui/camera-editor/add_layer.png";
    _panel.btnAddLayer.tooltip = "Add Layer";
    _panel.btnAddLayer.width = 20;
    _panel.btnAddLayer.height = 20;
    _panel.btnAddLayer.customStyle.verticalAlign = "center";
    topSpacer.addComponent(_panel.btnAddLayer);

    _panel.btnRemoveLayer = new IconButton();
    _panel.btnRemoveLayer.id = "btn-remove-layer";
    _panel.btnRemoveLayer.icon = "shared:assets/shared/images/ui/camera-editor/delete_layer.png";
    _panel.btnRemoveLayer.tooltip = "Remove Selected Layer(s)";
    _panel.btnRemoveLayer.width = 20;
    _panel.btnRemoveLayer.height = 20;
    _panel.btnRemoveLayer.customStyle.marginLeft = 4;
    _panel.btnRemoveLayer.customStyle.verticalAlign = "center";
    topSpacer.addComponent(_panel.btnRemoveLayer);

    _panel.addComponent(topSpacer);

    _panel._layerClipBox = new Box();
    _panel._layerClipBox.id = "layer-clip-box";
    _panel._layerClipBox.percentWidth = 100;
    _panel._layerClipBox.percentHeight = 100;
    _panel._layerClipBox.customStyle.clip = true;

    _panel._layerContainer = new VBox();
    _panel._layerContainer.id = "layer-container";
    _panel._layerContainer.percentWidth = 100;
    _panel._layerContainer.customStyle.verticalSpacing = 2;
    _panel._layerContainer.customStyle.horizontalSpacing = 0;

    _panel._layerClipBox.addComponent(_panel._layerContainer);
    _panel.addComponent(_panel._layerClipBox);
  }
}
#end
