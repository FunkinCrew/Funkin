package funkin.ui.debug.charting.dialogs;

#if FEATURE_CHART_EDITOR
import haxe.ui.containers.menus.Menu;
import haxe.ui.events.UIEvent;

// @:nullSafety // TODO: Fix null safety when used with HaxeUI build macros.
@:access(funkin.ui.debug.charting.ChartEditorState)
class ChartEditorBaseMenu extends Menu
{
  var chartEditorState:ChartEditorState;

  public function new(chartEditorState:ChartEditorState)
  {
    super();

    this.chartEditorState = chartEditorState;

    registerEvent(UIEvent.CLOSE, (_) -> onClose());
  }

  function onClose():Void
  {
    disposeComponent();
  }
}
#end
