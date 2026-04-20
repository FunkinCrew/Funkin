package funkin.ui.haxeui.components.editors.timeline;

#if FEATURE_CAMERA_EDITOR
import funkin.ui.haxeui.components.IconButton;
import haxe.ui.components.TextField;
import haxe.ui.containers.Box;
import haxe.ui.containers.HBox;
import haxe.ui.containers.VBox;
import haxe.ui.core.CompositeBuilder;
import haxe.ui.events.MouseEvent;
import haxe.ui.events.UIEvent;

@:composite(TimelineLayerPanelBuilder)
@:xml('
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
  var _rowByLayer:Map<TimelineLayerData, HBox> = new Map();

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
    _rowByLayer = new Map();

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
    var row = _rowByLayer.get(layer);
    if (row == null) return;
    _layerContainer.removeComponent(row);
    _rowByLayer.remove(layer);
    refreshSelectedHighlight();
    _layerContainer.syncComponentValidation();
  }

  public function refreshSelectedHighlight():Void
  {
    if (viewport == null) return;
    for (layer => row in _rowByLayer)
    {
      var idx = viewport.layers.indexOf(layer);
      row.customStyle.backgroundColor = (idx == viewport.selectedLayerIndex) ? 0x505050 : 0x3A3A3A;
      row.invalidateComponentStyle();
    }
  }

  function _insertLayerRowInternal(layer:TimelineLayerData, index:Int):Void
  {
    var row = new HBox();
    row.percentWidth = 100;
    row.height = TimelineViewport.LAYER_HEIGHT - 2;
    row.customStyle.verticalAlign = "center";
    row.customStyle.paddingLeft = 6;
    row.customStyle.backgroundColor = 0x3A3A3A;

    if (viewport != null && viewport.layers.indexOf(layer) == viewport.selectedLayerIndex) row.customStyle.backgroundColor = 0x505050;

    // Click handler captures `layer` (stable) and resolves current index at click time.
    row.registerEvent(MouseEvent.CLICK, (_:MouseEvent) -> {
      if (viewport == null) return;
      var idx = viewport.layers.indexOf(layer);
      if (idx < 0) return;
      viewport.selectedLayerIndex = idx;
      refreshSelectedHighlight();
    });

    var swatch = new Box();
    swatch.width = 12;
    swatch.height = 12;
    swatch.customStyle.backgroundColor = layer.color;
    swatch.customStyle.borderRadius = 2;
    swatch.customStyle.verticalAlign = "center";

    // we make the layer name a text field, rather than a label
    // so we can easily click on it to modify/edit
    var field = new TextField();
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

    field.registerEvent(UIEvent.CHANGE, (_:UIEvent) -> layer.name = field.text);

    row.addComponent(swatch);
    row.addComponent(field);

    if (index >= 0 && index < _layerContainer.childComponents.length) _layerContainer.addComponentAt(row, index);
    else
      _layerContainer.addComponent(row);

    _rowByLayer.set(layer, row);
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
