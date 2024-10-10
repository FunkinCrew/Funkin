package funkin.ui.debug.charting.components;

import haxe.ui.containers.HBox;
import haxe.ui.containers.ScrollView;
import haxe.ui.components.TextField;
import haxe.ui.components.CheckBox;

/**
 * The component which contains the channel data item for the chart generator.
 * This is in a separate component so it can be positioned independently.
 */
@:build(haxe.ui.ComponentBuilder.build("assets/exclude/data/ui/chart-editor/components/channel-item.xml"))
class ChartEditorChannelItem extends HBox
{
  var view:ScrollView;

  public function new(view:ScrollView)
  {
    super();

    this.view = view;

    createButton.onClick = function(_) {
      plusBox.hidden = true;
      channelBox.hidden = false;
      this.view.addComponent(new ChartEditorChannelItem(this.view));
    }

    destroyButton.onClick = function(_) {
      plusBox.hidden = false;
      channelBox.hidden = true;
      this.view.removeComponent(this);
    }
  }
}
