package funkin.ui.debug.charting.handlers;

import haxe.ui.containers.menus.MenuCheckBox;

/**
 * Static functions which handle value of checkboxes for a provided ChartEditorState. Used for playbars Windows panel changes.
 */
@:nullSafety
@:access(funkin.ui.debug.charting.ChartEditorState)
class ChartEditorCheckboxesHandler
{
  public static function setCheckboxState(state:ChartEditorState, id:String, shown:Bool):Void
  {
    var checkbox:Null<MenuCheckBox> = getCheckbox(state, id);
    if (checkbox != null)
    {
      checkbox.selected = shown;
      // TODO: why it isnt changing when shown = false nothing is changing
    }
  }

  public static function getCheckbox(state:ChartEditorState, id:String):Null<MenuCheckBox>
  {
    return switch (id)
    {
      case ChartEditorState.CHART_EDITOR_TOOLBOX_DIFFICULTY_LAYOUT:
        state.menubarItemToggleToolboxDifficulty;
      case ChartEditorState.CHART_EDITOR_TOOLBOX_METADATA_LAYOUT:
        state.menubarItemToggleToolboxMetadata;
      case ChartEditorState.CHART_EDITOR_TOOLBOX_NOTE_DATA_LAYOUT:
        state.menubarItemToggleToolboxNoteData;
      case ChartEditorState.CHART_EDITOR_TOOLBOX_OFFSETS_LAYOUT:
        state.menubarItemToggleToolboxOffsets;
      default:
        // This happens if you try to get an unknown checkbox.
        trace("ChartEditorCheckboxesHandler.getCheckbox() - Unknown toolbox ID for checkbox: $id");
        null;
    }
  }
}
