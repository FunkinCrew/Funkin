package funkin.ui.haxeui.components.editors.timeline;

#if FEATURE_CAMERA_EDITOR
import haxe.ui.components.Image;
import haxe.ui.components.TextField;
import haxe.ui.containers.Box;
import haxe.ui.containers.HBox;
import haxe.ui.containers.VBox;
import haxe.ui.core.CompositeBuilder;
import haxe.ui.events.UIEvent;

@:composite(TimelineLayerPanelBuilder)
@:xml('
<vbox width="120" style="background-color: #2A2A2A; spacing: 0; clip: true; overflow: hidden;">
</vbox>
')
class TimelineLayerPanel extends VBox
{
  public var btnAddLayer:Image;
  public var btnRemoveLayer:Image;
  public var buttonRow:HBox;

  public var _layerContainer:VBox;

  public function rebuildLayers(layers:Array<TimelineLayerData>):Void
  {
    _layerContainer.removeAllComponents();

    for (layer in layers)
    {
      var row = new HBox();
      row.percentWidth = 100;
      row.height = TimelineViewport.LAYER_HEIGHT;
      row.customStyle.backgroundColor = 0x3A3A3A;
      row.customStyle.verticalAlign = "center";
      row.customStyle.paddingLeft = 6;

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
      _layerContainer.addComponent(row);
    }
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
    // Note: buttonRow is NOT added to the panel — EventTimeline extracts it into its own top row
    _panel.buttonRow = new HBox();
    _panel.buttonRow.id = "layer-button-row";
    _panel.buttonRow.percentWidth = 100;
    _panel.buttonRow.customStyle.paddingLeft = 6;
    _panel.buttonRow.customStyle.verticalAlign = "center";

    _panel.btnAddLayer = new Image();
    _panel.btnAddLayer.id = "btn-add-layer";
    _panel.btnAddLayer.resource = "shared:assets/shared/images/ui/camera-editor/add_layer.png";
    _panel.btnAddLayer.tooltip = "Add Layer";
    _panel.btnAddLayer.width = 20;
    _panel.btnAddLayer.height = 20;
    _panel.btnAddLayer.customStyle.cursor = "pointer";
    _panel.buttonRow.addComponent(_panel.btnAddLayer);

    _panel.btnRemoveLayer = new Image();
    _panel.btnRemoveLayer.id = "btn-remove-layer";
    _panel.btnRemoveLayer.resource = "shared:assets/shared/images/ui/camera-editor/delete_layer.png";
    _panel.btnRemoveLayer.tooltip = "Remove Selected Layer(s)";
    _panel.btnRemoveLayer.width = 20;
    _panel.btnRemoveLayer.height = 20;
    _panel.btnRemoveLayer.customStyle.cursor = "pointer";
    _panel.btnRemoveLayer.customStyle.marginLeft = 4;
    _panel.buttonRow.addComponent(_panel.btnRemoveLayer);

    _panel._layerContainer = new VBox();
    _panel._layerContainer.id = "layer-container";
    _panel._layerContainer.percentWidth = 100;
    _panel._layerContainer.customStyle.verticalSpacing = 0;
    _panel._layerContainer.customStyle.horizontalSpacing = 0;
    _panel.addComponent(_panel._layerContainer);
  }
}
#end
