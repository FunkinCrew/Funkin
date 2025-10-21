package funkin.ui.debug.stageeditor.handlers;

import funkin.play.character.BaseCharacter.CharacterType;
import haxe.ui.RuntimeComponentBuilder;
import funkin.ui.haxeui.components.CharacterPlayer;
import haxe.ui.components.CheckBox;
import haxe.ui.containers.dialogs.CollapsibleDialog;
import haxe.ui.containers.dialogs.Dialog.DialogButton;
import haxe.ui.containers.dialogs.Dialog.DialogEvent;
import funkin.ui.debug.stageeditor.toolboxes.StageEditorBaseToolbox;
import funkin.ui.debug.stageeditor.toolboxes.StageEditorCharacterToolbox;
import funkin.ui.debug.stageeditor.toolboxes.StageEditorMetadataToolbox;
import funkin.ui.debug.stageeditor.toolboxes.StageEditorObjectPropertiesToolbox;

@:nullSafety
@:access(funkin.ui.debug.stageeditor.StageEditorState)
class StageEditorToolboxHandler
{
  public static function setToolboxState(state:StageEditorState, id:String, shown:Bool):Void
  {
    if (shown)
    {
      showToolbox(state, id);
    }
    else
    {
      hideToolbox(state, id);
    }
  }

  public static function showToolbox(state:StageEditorState, id:String):Void
  {
    var toolbox:Null<CollapsibleDialog> = state.activeToolboxes.get(id);

    if (toolbox == null) toolbox = initToolbox(state, id);

    if (toolbox != null)
    {
      toolbox.showDialog(false);

      state.playSound(Paths.sound('chartingSounds/openWindow'));

      switch (id)
      {
        case StageEditorState.STAGE_EDITOR_TOOLBOX_METADATA_LAYOUT:
          cast(toolbox, StageEditorBaseToolbox).refresh();
        case StageEditorState.STAGE_EDITOR_TOOLBOX_OBJECT_PROPERTIES_LAYOUT:
          cast(toolbox, StageEditorBaseToolbox).refresh();
        case StageEditorState.STAGE_EDITOR_TOOLBOX_OBJECT_ANIMATIONS_LAYOUT:
          cast(toolbox, StageEditorBaseToolbox).refresh();
        case StageEditorState.STAGE_EDITOR_TOOLBOX_OBJECT_GRAPHIC_LAYOUT:
          cast(toolbox, StageEditorBaseToolbox).refresh();
        case StageEditorState.STAGE_EDITOR_TOOLBOX_CHARACTER_LAYOUT:
          cast(toolbox, StageEditorBaseToolbox).refresh();
        default:
          // This happens if you try to load an unknown layout.
          trace('StageEditorToolboxHandler.showToolbox() - Unknown toolbox ID: $id');
      }
    }
    else
    {
      trace('StageEditorToolboxHandler.showToolbox() - Could not retrieve toolbox: $id');
    }
  }

  public static function hideToolbox(state:StageEditorState, id:String):Void
  {
    var toolbox:Null<CollapsibleDialog> = state.activeToolboxes.get(id);

    if (toolbox == null) toolbox = initToolbox(state, id);

    if (toolbox != null)
    {
      toolbox.hideDialog(DialogButton.CANCEL);

      state.playSound(Paths.sound('chartingSounds/exitWindow'));

      switch (id)
      {
        default:
          // This happens if you try to load an unknown layout.
          trace('StageEditorToolboxHandler.hideToolbox() - Unknown toolbox ID: $id');
      }
    }
    else
    {
      trace('StageEditorToolboxHandler.hideToolbox() - Could not retrieve toolbox: $id');
    }
  }

  public static function refreshToolbox(state:StageEditorState, id:String):Void
  {
    var toolbox:Null<StageEditorBaseToolbox> = cast state.activeToolboxes.get(id);

    if (toolbox == null)
    {
      toolbox = cast initToolbox(state, id);
    }

    if (toolbox != null)
    {
      toolbox.refresh();
    }
    else
    {
      trace('StageEditorToolboxHandler.refreshToolbox() - Could not retrieve toolbox: $id');
    }
  }

  public static function rememberOpenToolboxes(state:StageEditorState):Void {}

  public static function openRememberedToolboxes(state:StageEditorState):Void {}

  public static function hideAllToolboxes(state:StageEditorState):Void
  {
    for (toolbox in state.activeToolboxes.values())
    {
      toolbox.hideDialog(DialogButton.CANCEL);
    }
  }

  public static function minimizeToolbox(state:StageEditorState, id:String):Void
  {
    var toolbox:Null<CollapsibleDialog> = state.activeToolboxes.get(id);

    if (toolbox == null) return;

    toolbox.minimized = true;
  }

  public static function maximizeToolbox(state:StageEditorState, id:String):Void
  {
    var toolbox:Null<CollapsibleDialog> = state.activeToolboxes.get(id);

    if (toolbox == null) return;

    toolbox.minimized = false;
  }

  public static function initToolbox(state:StageEditorState, id:String):Null<CollapsibleDialog>
  {
    var toolbox:Null<CollapsibleDialog> = null;
    switch (id)
    {
      case StageEditorState.STAGE_EDITOR_TOOLBOX_METADATA_LAYOUT:
        toolbox = buildToolboxMetadataLayout(state);
      case StageEditorState.STAGE_EDITOR_TOOLBOX_OBJECT_PROPERTIES_LAYOUT:
        toolbox = buildToolboxObjectPropertiesLayout(state);
      // case StageEditorState.STAGE_EDITOR_TOOLBOX_OBJECT_ANIMATIONS_LAYOUT:
      //   toolbox = buildToolboxObjectAnimationsLayout(state);
      // case StageEditorState.STAGE_EDITOR_TOOLBOX_OBJECT_GRAPHIC_LAYOUT:
      //   toolbox = buildToolboxObjectGraphicLayout(state);
      case StageEditorState.STAGE_EDITOR_TOOLBOX_CHARACTER_LAYOUT:
        toolbox = buildToolboxCharacterLayout(state);
      default:
        // This happens if you try to load an unknown layout.
        trace('StageEditorToolboxHandler.initToolbox() - Unknown toolbox ID: $id');
        toolbox = null;
    }

    // This happens if the layout you try to load has a syntax error.
    if (toolbox == null) return null;

    // Make sure we can reuse the toolbox later.
    toolbox.destroyOnClose = false;
    state.activeToolboxes.set(id, toolbox);

    return toolbox;
  }

  public static function getToolbox(state:StageEditorState, id:String):Null<StageEditorBaseToolbox>
  {
    var toolbox:Null<CollapsibleDialog> = state.activeToolboxes.get(id);

    // Initialize the toolbox without showing it.
    if (toolbox == null) toolbox = initToolbox(state, id);

    if (toolbox == null) throw 'StageEditorToolboxHandler.getToolbox() - Could not retrieve or build toolbox: $id';

    return cast toolbox;
  }

  static function buildToolboxMetadataLayout(state:StageEditorState):Null<StageEditorBaseToolbox>
  {
    var toolbox:StageEditorBaseToolbox = StageEditorMetadataToolbox.build(state);

    if (toolbox == null) return null;

    return toolbox;
  }

  static function buildToolboxCharacterLayout(state:StageEditorState):Null<StageEditorBaseToolbox>
  {
    var toolbox:StageEditorBaseToolbox = StageEditorCharacterToolbox.build(state);

    if (toolbox == null) return null;

    return toolbox;
  }

  static function buildToolboxObjectPropertiesLayout(state:StageEditorState):Null<StageEditorBaseToolbox>
  {
    var toolbox:StageEditorObjectPropertiesToolbox = StageEditorObjectPropertiesToolbox.build(state);

    if (toolbox == null) return null;

    return toolbox;
  }
}
