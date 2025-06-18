package funkin.ui.debug.charting.handlers;

import funkin.play.character.BaseCharacter.CharacterType;
import haxe.ui.RuntimeComponentBuilder;
import funkin.ui.haxeui.components.CharacterPlayer;
import haxe.ui.components.CheckBox;
import haxe.ui.containers.dialogs.CollapsibleDialog;
import haxe.ui.containers.dialogs.Dialog.DialogButton;
import haxe.ui.containers.dialogs.Dialog.DialogEvent;
import funkin.ui.debug.charting.toolboxes.ChartEditorBaseToolbox;
import funkin.ui.debug.charting.toolboxes.ChartEditorMetadataToolbox;
import funkin.ui.debug.charting.toolboxes.ChartEditorOffsetsToolbox;
import funkin.ui.debug.charting.toolboxes.ChartEditorFreeplayToolbox;
import funkin.ui.debug.charting.toolboxes.ChartEditorEventDataToolbox;
import funkin.ui.debug.charting.toolboxes.ChartEditorNoteDataToolbox;
import funkin.ui.debug.charting.toolboxes.ChartEditorDifficultyToolbox;

/**
 * Static functions which handle building themed UI elements for a provided ChartEditorState.
 */
@:nullSafety
@:access(funkin.ui.debug.charting.ChartEditorState)
class ChartEditorToolboxHandler
{
  public static function setToolboxState(state:ChartEditorState, id:String, shown:Bool):Void
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

  public static function showToolbox(state:ChartEditorState, id:String):Void
  {
    var toolbox:Null<CollapsibleDialog> = state.activeToolboxes.get(id);

    if (toolbox == null) toolbox = initToolbox(state, id);

    if (toolbox != null)
    {
      toolbox.showDialog(false);

      state.playSound(Paths.sound('chartingSounds/openWindow'));

      switch (id)
      {
        case ChartEditorState.CHART_EDITOR_TOOLBOX_NOTE_DATA_LAYOUT:
          cast(toolbox, ChartEditorBaseToolbox).refresh();
        case ChartEditorState.CHART_EDITOR_TOOLBOX_EVENT_DATA_LAYOUT:
          // TODO: Make these better.
          cast(toolbox, ChartEditorBaseToolbox).refresh();
        case ChartEditorState.CHART_EDITOR_TOOLBOX_PLAYTEST_PROPERTIES_LAYOUT:
          onShowToolboxPlaytestProperties(state, toolbox);
        case ChartEditorState.CHART_EDITOR_TOOLBOX_DIFFICULTY_LAYOUT:
          cast(toolbox, ChartEditorBaseToolbox).refresh();
        case ChartEditorState.CHART_EDITOR_TOOLBOX_METADATA_LAYOUT:
          cast(toolbox, ChartEditorBaseToolbox).refresh();
        case ChartEditorState.CHART_EDITOR_TOOLBOX_OFFSETS_LAYOUT:
          cast(toolbox, ChartEditorBaseToolbox).refresh();
        case ChartEditorState.CHART_EDITOR_TOOLBOX_FREEPLAY_LAYOUT:
          cast(toolbox, ChartEditorBaseToolbox).refresh();
        case ChartEditorState.CHART_EDITOR_TOOLBOX_PLAYER_PREVIEW_LAYOUT:
          onShowToolboxPlayerPreview(state, toolbox);
        case ChartEditorState.CHART_EDITOR_TOOLBOX_OPPONENT_PREVIEW_LAYOUT:
          onShowToolboxOpponentPreview(state, toolbox);
        default:
          // This happens if you try to load an unknown layout.
          trace('ChartEditorToolboxHandler.showToolbox() - Unknown toolbox ID: $id');
      }
    }
    else
    {
      trace('ChartEditorToolboxHandler.showToolbox() - Could not retrieve toolbox: $id');
    }
  }

  public static function hideToolbox(state:ChartEditorState, id:String):Void
  {
    var toolbox:Null<CollapsibleDialog> = state.activeToolboxes.get(id);

    if (toolbox == null) toolbox = initToolbox(state, id);

    if (toolbox != null)
    {
      toolbox.hideDialog(DialogButton.CANCEL);

      state.playSound(Paths.sound('chartingSounds/exitWindow'));

      switch (id)
      {
        case ChartEditorState.CHART_EDITOR_TOOLBOX_PLAYTEST_PROPERTIES_LAYOUT:
          onHideToolboxPlaytestProperties(state, toolbox);
        case ChartEditorState.CHART_EDITOR_TOOLBOX_PLAYER_PREVIEW_LAYOUT:
          onHideToolboxPlayerPreview(state, toolbox);
        case ChartEditorState.CHART_EDITOR_TOOLBOX_OPPONENT_PREVIEW_LAYOUT:
          onHideToolboxOpponentPreview(state, toolbox);
        default:
          // This happens if you try to load an unknown layout.
          trace('ChartEditorToolboxHandler.hideToolbox() - Unknown toolbox ID: $id');
      }
    }
    else
    {
      trace('ChartEditorToolboxHandler.hideToolbox() - Could not retrieve toolbox: $id');
    }
  }

  public static function refreshToolbox(state:ChartEditorState, id:String):Void
  {
    var toolbox:Null<ChartEditorBaseToolbox> = cast state.activeToolboxes.get(id);

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
      trace('ChartEditorToolboxHandler.refreshToolbox() - Could not retrieve toolbox: $id');
    }
  }

  public static function rememberOpenToolboxes(state:ChartEditorState):Void {}

  public static function openRememberedToolboxes(state:ChartEditorState):Void {}

  public static function hideAllToolboxes(state:ChartEditorState):Void
  {
    for (toolbox in state.activeToolboxes.values())
    {
      toolbox.hideDialog(DialogButton.CANCEL);
    }
  }

  public static function minimizeToolbox(state:ChartEditorState, id:String):Void
  {
    var toolbox:Null<CollapsibleDialog> = state.activeToolboxes.get(id);

    if (toolbox == null) return;

    toolbox.minimized = true;
  }

  public static function maximizeToolbox(state:ChartEditorState, id:String):Void
  {
    var toolbox:Null<CollapsibleDialog> = state.activeToolboxes.get(id);

    if (toolbox == null) return;

    toolbox.minimized = false;
  }

  public static function initToolbox(state:ChartEditorState, id:String):Null<CollapsibleDialog>
  {
    var toolbox:Null<CollapsibleDialog> = null;
    switch (id)
    {
      case ChartEditorState.CHART_EDITOR_TOOLBOX_NOTE_DATA_LAYOUT:
        toolbox = buildToolboxNoteDataLayout(state);
      case ChartEditorState.CHART_EDITOR_TOOLBOX_EVENT_DATA_LAYOUT:
        toolbox = buildToolboxEventDataLayout(state);
      case ChartEditorState.CHART_EDITOR_TOOLBOX_PLAYTEST_PROPERTIES_LAYOUT:
        toolbox = buildToolboxPlaytestPropertiesLayout(state);
      case ChartEditorState.CHART_EDITOR_TOOLBOX_DIFFICULTY_LAYOUT:
        toolbox = buildToolboxDifficultyLayout(state);
      case ChartEditorState.CHART_EDITOR_TOOLBOX_METADATA_LAYOUT:
        toolbox = buildToolboxMetadataLayout(state);
      case ChartEditorState.CHART_EDITOR_TOOLBOX_OFFSETS_LAYOUT:
        toolbox = buildToolboxOffsetsLayout(state);
      case ChartEditorState.CHART_EDITOR_TOOLBOX_FREEPLAY_LAYOUT:
        toolbox = buildToolboxFreeplayLayout(state);
      case ChartEditorState.CHART_EDITOR_TOOLBOX_PLAYER_PREVIEW_LAYOUT:
        toolbox = buildToolboxPlayerPreviewLayout(state);
      case ChartEditorState.CHART_EDITOR_TOOLBOX_OPPONENT_PREVIEW_LAYOUT:
        toolbox = buildToolboxOpponentPreviewLayout(state);
      default:
        // This happens if you try to load an unknown layout.
        trace('ChartEditorToolboxHandler.initToolbox() - Unknown toolbox ID: $id');
        toolbox = null;
    }

    // This happens if the layout you try to load has a syntax error.
    if (toolbox == null) return null;

    // Make sure we can reuse the toolbox later.
    toolbox.destroyOnClose = false;
    state.activeToolboxes.set(id, toolbox);

    return toolbox;
  }

  /**
   * Retrieve a toolbox by its layout's asset ID.
   * @param state The ChartEditorState instance.
   * @param id The asset ID of the toolbox layout.
   * @return The toolbox.
   */
  public static function getToolbox_OLD(state:ChartEditorState, id:String):Null<CollapsibleDialog>
  {
    var toolbox:Null<CollapsibleDialog> = state.activeToolboxes.get(id);

    // Initialize the toolbox without showing it.
    if (toolbox == null) toolbox = initToolbox(state, id);

    if (toolbox == null) throw 'ChartEditorToolboxHandler.getToolbox_OLD() - Could not retrieve or build toolbox: $id';

    return toolbox;
  }

  public static function getToolbox(state:ChartEditorState, id:String):Null<ChartEditorBaseToolbox>
  {
    var toolbox:Null<CollapsibleDialog> = state.activeToolboxes.get(id);

    // Initialize the toolbox without showing it.
    if (toolbox == null) toolbox = initToolbox(state, id);

    if (toolbox == null) throw 'ChartEditorToolboxHandler.getToolbox() - Could not retrieve or build toolbox: $id';

    return cast toolbox;
  }

  static function buildToolboxNoteDataLayout(state:ChartEditorState):Null<CollapsibleDialog>
  {
    var toolbox:ChartEditorBaseToolbox = ChartEditorNoteDataToolbox.build(state);

    if (toolbox == null) return null;

    return toolbox;
  }

  static function onShowToolboxPlaytestProperties(state:ChartEditorState, toolbox:CollapsibleDialog):Void {}

  static function onHideToolboxPlaytestProperties(state:ChartEditorState, toolbox:CollapsibleDialog):Void {}

  static function buildToolboxPlaytestPropertiesLayout(state:ChartEditorState):Null<CollapsibleDialog>
  {
    // fill with playtest properties
    var toolbox:CollapsibleDialog = cast RuntimeComponentBuilder.fromAsset(ChartEditorState.CHART_EDITOR_TOOLBOX_PLAYTEST_PROPERTIES_LAYOUT);

    if (toolbox == null) return null;

    toolbox.onDialogClosed = function(_) {
      state.menubarItemToggleToolboxPlaytestProperties.selected = false;
    }

    var checkboxPracticeMode:Null<CheckBox> = toolbox.findComponent('practiceModeCheckbox', CheckBox);
    if (checkboxPracticeMode == null) throw 'ChartEditorToolboxHandler.buildToolboxPlaytestPropertiesLayout() - Could not find practiceModeCheckbox component.';

    checkboxPracticeMode.selected = state.playtestPracticeMode;

    checkboxPracticeMode.onClick = _ -> {
      state.playtestPracticeMode = checkboxPracticeMode.selected;
    };

    var checkboxStartTime:Null<CheckBox> = toolbox.findComponent('playtestStartTimeCheckbox', CheckBox);
    if (checkboxStartTime == null)
      throw 'ChartEditorToolboxHandler.buildToolboxPlaytestPropertiesLayout() - Could not find playtestStartTimeCheckbox component.';

    checkboxStartTime.selected = state.playtestStartTime;

    checkboxStartTime.onClick = _ -> {
      state.playtestStartTime = checkboxStartTime.selected;
    };

    var checkboxBotPlay:Null<CheckBox> = toolbox.findComponent('playtestBotPlayCheckbox', CheckBox);
    if (checkboxBotPlay == null) throw 'ChartEditorToolboxHandler.buildToolboxPlaytestPropertiesLayout() - Could not find playtestBotPlayCheckbox component.';

    checkboxBotPlay.selected = state.playtestBotPlayMode;

    checkboxBotPlay.onClick = _ -> {
      state.playtestBotPlayMode = checkboxBotPlay.selected;
    };

    var checkboxSongScripts:Null<CheckBox> = toolbox.findComponent('playtestSongScriptsCheckbox', CheckBox);

    if (checkboxSongScripts == null)
      throw 'ChartEditorToolboxHandler.buildToolboxPlaytestPropertiesLayout() - Could not find playtestSongScriptsCheckbox component.';

    state.playtestSongScripts = checkboxSongScripts.selected;

    checkboxSongScripts.onClick = _ -> {
      state.playtestSongScripts = checkboxSongScripts.selected;
    };

    return toolbox;
  }

  static function buildToolboxDifficultyLayout(state:ChartEditorState):Null<ChartEditorBaseToolbox>
  {
    var toolbox:ChartEditorBaseToolbox = ChartEditorDifficultyToolbox.build(state);

    if (toolbox == null) return null;

    return toolbox;
  }

  static function buildToolboxMetadataLayout(state:ChartEditorState):Null<ChartEditorBaseToolbox>
  {
    var toolbox:ChartEditorBaseToolbox = ChartEditorMetadataToolbox.build(state);

    if (toolbox == null) return null;

    return toolbox;
  }

  static function buildToolboxOffsetsLayout(state:ChartEditorState):Null<ChartEditorBaseToolbox>
  {
    var toolbox:ChartEditorBaseToolbox = ChartEditorOffsetsToolbox.build(state);

    if (toolbox == null) return null;

    return toolbox;
  }

  static function buildToolboxFreeplayLayout(state:ChartEditorState):Null<ChartEditorBaseToolbox>
  {
    var toolbox:ChartEditorBaseToolbox = ChartEditorFreeplayToolbox.build(state);

    if (toolbox == null) return null;

    return toolbox;
  }

  static function buildToolboxEventDataLayout(state:ChartEditorState):Null<ChartEditorBaseToolbox>
  {
    var toolbox:ChartEditorBaseToolbox = ChartEditorEventDataToolbox.build(state);

    if (toolbox == null) return null;

    return toolbox;
  }

  static function buildToolboxPlayerPreviewLayout(state:ChartEditorState):Null<CollapsibleDialog>
  {
    var toolbox:CollapsibleDialog = cast RuntimeComponentBuilder.fromAsset(ChartEditorState.CHART_EDITOR_TOOLBOX_PLAYER_PREVIEW_LAYOUT);

    if (toolbox == null) return null;

    // Starting position.
    toolbox.x = 200;
    toolbox.y = 350;

    toolbox.onDialogClosed = function(event:DialogEvent) {
      state.menubarItemToggleToolboxPlayerPreview.selected = false;
    }

    var charPlayer:Null<CharacterPlayer> = toolbox.findComponent('charPlayer');
    if (charPlayer == null) throw 'ChartEditorToolboxHandler.buildToolboxPlayerPreviewLayout() - Could not find charPlayer component.';
    // TODO: We need to implement character swapping in ChartEditorState.
    charPlayer.loadCharacter('bf');
    charPlayer.characterType = CharacterType.BF;
    charPlayer.flip = true;
    charPlayer.targetScale = 0.5;

    return toolbox;
  }

  static function onShowToolboxPlayerPreview(state:ChartEditorState, toolbox:CollapsibleDialog):Void {}

  static function onHideToolboxPlayerPreview(state:ChartEditorState, toolbox:CollapsibleDialog):Void {}

  static function buildToolboxOpponentPreviewLayout(state:ChartEditorState):Null<CollapsibleDialog>
  {
    var toolbox:CollapsibleDialog = cast RuntimeComponentBuilder.fromAsset(ChartEditorState.CHART_EDITOR_TOOLBOX_OPPONENT_PREVIEW_LAYOUT);

    if (toolbox == null) return null;

    // Starting position.
    toolbox.x = 200;
    toolbox.y = 350;

    toolbox.onDialogClosed = (event:DialogEvent) -> {
      state.menubarItemToggleToolboxOpponentPreview.selected = false;
    }

    var charPlayer:Null<CharacterPlayer> = toolbox.findComponent('charPlayer');
    if (charPlayer == null) throw 'ChartEditorToolboxHandler.buildToolboxOpponentPreviewLayout() - Could not find charPlayer component.';
    // TODO: We need to implement character swapping in ChartEditorState.
    charPlayer.loadCharacter('dad');
    charPlayer.characterType = CharacterType.DAD;
    charPlayer.flip = false;
    charPlayer.targetScale = 0.5;

    return toolbox;
  }

  static function onShowToolboxOpponentPreview(state:ChartEditorState, toolbox:CollapsibleDialog):Void {}

  static function onHideToolboxOpponentPreview(state:ChartEditorState, toolbox:CollapsibleDialog):Void {}
}
