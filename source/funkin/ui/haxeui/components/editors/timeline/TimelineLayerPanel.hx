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
  public var viewport:TimelineViewport;

  public function rebuildLayers(layers:Array<TimelineLayerData>):Void
  {
    _layerContainer.removeAllComponents();

    for (i in 0...layers.length)
    {
      var layer = layers[i];
      var layerIdx = i;

      var row = new HBox();
      row.percentWidth = 100;
      row.height = TimelineViewport.LAYER_HEIGHT - 2;
      row.customStyle.backgroundColor = 0x3A3A3A;
      row.customStyle.verticalAlign = "center";
      row.customStyle.paddingLeft = 6;

      if (viewport != null && viewport.selectedLayerIndex == i)
        row.customStyle.backgroundColor = 0x505050;
      else
        row.customStyle.backgroundColor = 0x3A3A3A;

      row.registerEvent(MouseEvent.CLICK, (_:MouseEvent) -> {
        if (viewport != null)
        {
          viewport.selectedLayerIndex = layerIdx;
          rebuildLayers(viewport.layers);
        }
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

    _panel._layerContainer = new VBox();
    _panel._layerContainer.id = "layer-container";
    _panel._layerContainer.percentWidth = 100;
    _panel._layerContainer.customStyle.verticalSpacing = 2;
    _panel._layerContainer.customStyle.horizontalSpacing = 0;
    _panel.addComponent(_panel._layerContainer);
  }

}
#end
