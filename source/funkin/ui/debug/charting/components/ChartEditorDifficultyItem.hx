package funkin.ui.debug.charting.components;

import funkin.ui.debug.charting.ChartEditorState;
import haxe.ui.containers.HBox;
import haxe.ui.containers.ScrollView;
import haxe.ui.components.TextField;
import haxe.ui.components.NumberStepper;

/**
 * The component which contains the difficulty data item for the difficulty generator.
 * This is in a separate component so it can be positioned independently.
 */
@:build(haxe.ui.ComponentBuilder.build("assets/exclude/data/ui/chart-editor/components/difficulty-item.xml"))
@:access(funkin.ui.debug.charting.ChartEditorState)
class ChartEditorDifficultyItem extends HBox
{
  var view:ScrollView;

  public function new(state:ChartEditorState, view:ScrollView)
  {
    super();

    this.view = view;

    createButton.onClick = function(_) {
      plusBox.hidden = true;
      difficultyFrame.hidden = false;
      this.view.addComponent(new ChartEditorDifficultyItem(state, this.view));
    }

    destroyButton.onClick = function(_) {
      plusBox.hidden = false;
      difficultyFrame.hidden = true;
      this.view.removeComponent(this);
    }

    difficultyDropdown.dataSource.clear();
    for (difficulty in state.availableDifficulties)
    {
      if (difficulty == state.selectedDifficulty)
      {
        continue;
      }
      difficultyDropdown.dataSource.add({text: difficulty.toTitleCase(), value: difficulty});
    }
    difficultyDropdown.value = difficultyDropdown.dataSource.get(0);
  }

  override function update(elapsed:Float):Void
  {
    super.update(elapsed);

    if (difficultyDropdown.value != null)
    {
      difficultyFrame.text = difficultyDropdown.value.text;
    }
    else
    {
      difficultyFrame.text = "Difficulty";
    }
  }
}
