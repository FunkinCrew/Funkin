package funkin.ui.debug.charting.handlers;

#if FEATURE_CHART_EDITOR
import funkin.play.character.BaseCharacter.CharacterType;
import funkin.ui.debug.charting.ChartEditorState.ChartEditorLiveInputStyle;
import funkin.ui.debug.charting.ChartEditorState.ChartEditorTheme;
import funkin.ui.debug.charting.ChartEditorState.ChartEditorWaveformFilter;
import funkin.ui.debug.charting.ChartEditorState.ChartEditorWaveformPos;
import haxe.ui.RuntimeComponentBuilder;
import funkin.ui.haxeui.components.CharacterPlayer;
import haxe.ui.components.CheckBox;
import haxe.ui.components.DropDown;
import haxe.ui.components.Label;
import haxe.ui.components.Slider;
import haxe.ui.containers.menus.Menu;
import haxe.ui.containers.dialogs.CollapsibleDialog;
import haxe.ui.containers.dialogs.Dialog.DialogButton;
import haxe.ui.containers.dialogs.Dialog.DialogEvent;
import haxe.ui.core.Screen;
import haxe.ui.events.DragEvent;
import haxe.ui.focus.FocusManager;
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

  public static function clearHaxeUIFocus():Void
  {
    @:nullSafety(Off) {
      final f = FocusManager.instance.focus;
      if (f != null) f.focus = false;
    }
    ChartEditorState.haxeUIFocusedValid = false;
  }

  public static function showToolbox(state:ChartEditorState, id:String):Void
  {
    var toolbox:Null<CollapsibleDialog> = state.activeToolboxes.get(id);
    var hasOpened:Bool = toolbox != null;

    if (toolbox == null) toolbox = initToolbox(state, id);

    if (toolbox != null)
    {
      if (hasOpened)
      {
        toolbox.left = toolbox.left;
        toolbox.top = toolbox.top;
      }

      var isPreferences:Bool = id == ChartEditorState.CHART_EDITOR_TOOLBOX_PREFERENCES_LAYOUT;
      var volumes:Array<Float> = isPreferences ? capturePreferenceVolumes(state) : [];
      if (isPreferences) state.preferencesListening = false;

      toolbox.showDialog(false);
      clearHaxeUIFocus();

      if (isPreferences)
      {
        restorePreferenceVolumes(state, volumes);
        // The labels were never updated while hidden, so sync them and the audio to the sliders.
        state.applyPreferenceVolumes();
        refreshToolboxPreferences(state, toolbox);
        state.preferencesListening = true;
      }

      for (component in Screen.instance.rootComponents)
      {
        if (Std.isOfType(component, Menu)) Screen.instance.moveComponentToFront(component);
      }

      state.playSound(Paths.sound('ui/editors/chart-editor/charting-sounds/window-open'));

      switch (id)
      {
        case ChartEditorState.CHART_EDITOR_TOOLBOX_NOTE_DATA_LAYOUT:
          cast(toolbox, ChartEditorBaseToolbox).refresh();
        case ChartEditorState.CHART_EDITOR_TOOLBOX_EVENT_DATA_LAYOUT:
          // TODO: Make these better.
          cast(toolbox, ChartEditorBaseToolbox).refresh();
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
        case ChartEditorState.CHART_EDITOR_TOOLBOX_PREFERENCES_LAYOUT:
          // Already refreshed right after showing.
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
      clearHaxeUIFocus();
      toolbox.hideDialog(DialogButton.CANCEL);

      state.playSound(Paths.sound('ui/editors/chart-editor/charting-sounds/window-exit'));

      switch (id)
      {
        case ChartEditorState.CHART_EDITOR_TOOLBOX_PLAYER_PREVIEW_LAYOUT:
          onHideToolboxPlayerPreview(state, toolbox);
        case ChartEditorState.CHART_EDITOR_TOOLBOX_OPPONENT_PREVIEW_LAYOUT:
          onHideToolboxOpponentPreview(state, toolbox);
        case ChartEditorState.CHART_EDITOR_TOOLBOX_PREFERENCES_LAYOUT:
          // Settings apply as soon as they change.
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

    if (toolbox == null) return;

    if (toolbox != null)
    {
      toolbox.refresh();
    }
    else
    {
      trace('ChartEditorToolboxHandler.refreshToolbox() - Could not retrieve toolbox: $id');
    }
  }

  public static function rememberOpenToolboxes(state:ChartEditorState):Void
  {
  }

  public static function openRememberedToolboxes(state:ChartEditorState):Void
  {
  }

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
      case ChartEditorState.CHART_EDITOR_TOOLBOX_PREFERENCES_LAYOUT:
        toolbox = buildToolboxPreferencesLayout(state);
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

    // Set the component above everything else when dragging.
    toolbox.registerEvent(DragEvent.DRAG_START, function(_)
    {
      var roots = Screen.instance.rootComponents;
      if (roots[roots.length - 1] != toolbox) Screen.instance.moveComponentToFront(toolbox);
    });

    return toolbox;
  }

  /**
   * Retrieve a toolbox by its layout's asset ID.
   * @param state The ChartEditorState instance.
   * @param id The asset ID of the toolbox layout.
   * @return The toolbox.
   */
  public static function getToolboxUnCast(state:ChartEditorState, id:String):Null<CollapsibleDialog>
  {
    var toolbox:Null<CollapsibleDialog> = state.activeToolboxes.get(id);

    // Initialize the toolbox without showing it.
    if (toolbox == null) toolbox = initToolbox(state, id);

    if (toolbox == null) throw 'ChartEditorToolboxHandler.getToolboxUnCast() - Could not retrieve or build toolbox: $id';

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

  static function buildToolboxPreferencesLayout(state:ChartEditorState):Null<CollapsibleDialog>
  {
    var toolbox:CollapsibleDialog = cast RuntimeComponentBuilder.fromAsset(ChartEditorState.CHART_EDITOR_TOOLBOX_PREFERENCES_LAYOUT);
    if (toolbox == null) return null;

    var theme:Null<DropDown> = toolbox.findComponent('preferencesTheme', DropDown);
    if (theme == null) throw 'ChartEditorToolboxHandler.buildToolboxPreferencesLayout() - Could not find preferencesTheme component.';
    theme.onChange = _ -> if (state.preferencesListening) state.currentTheme = (theme.selectedIndex == 1) ? ChartEditorTheme.Dark : ChartEditorTheme.Light;

    var noteKinds:Null<CheckBox> = toolbox.findComponent('preferencesNoteKindIndicators', CheckBox);
    if (noteKinds == null) throw 'ChartEditorToolboxHandler.buildToolboxPreferencesLayout() - Could not find preferencesNoteKindIndicators component.';
    noteKinds.onClick = _ -> if (state.preferencesListening) state.showNoteKindIndicators = noteKinds.selected;

    var subtitles:Null<CheckBox> = toolbox.findComponent('preferencesSubtitles', CheckBox);
    if (subtitles == null) throw 'ChartEditorToolboxHandler.buildToolboxPreferencesLayout() - Could not find preferencesSubtitles component.';
    subtitles.onClick = _ -> if (state.preferencesListening) state.showSubtitles = subtitles.selected;

    var beatLines:Null<CheckBox> = toolbox.findComponent('preferencesBeatLines', CheckBox);
    if (beatLines == null) throw 'ChartEditorToolboxHandler.buildToolboxPreferencesLayout() - Could not find preferencesBeatLines component.';
    beatLines.onClick = _ -> if (state.preferencesListening) state.showBeatLines = beatLines.selected;

    var cursorLine:Null<CheckBox> = toolbox.findComponent('preferencesCursorLine', CheckBox);
    if (cursorLine == null) throw 'ChartEditorToolboxHandler.buildToolboxPreferencesLayout() - Could not find preferencesCursorLine component.';
    cursorLine.onClick = _ -> if (state.preferencesListening) state.showCursorLine = cursorLine.selected;

    var backingOpacity:Null<Slider> = toolbox.findComponent('preferencesBackingOpacity', Slider);
    var backingOpacityLabel:Null<Label> = toolbox.findComponent('preferencesBackingOpacityLabel', Label);
    if (backingOpacity == null || backingOpacityLabel == null) throw 'ChartEditorToolboxHandler.buildToolboxPreferencesLayout() - Could not find preferencesBackingOpacity components.';
    backingOpacity.onChange = _ ->
    {
      if (!state.preferencesListening) return;
      var percent:Float = backingOpacity.pos;
      state.gridBackingAlpha = percent / 100.0;
      backingOpacityLabel.text = 'Grid backing opacity - ${Std.int(percent)}%';
    };

    var waveformPosition:Null<DropDown> = toolbox.findComponent('preferencesWaveformPosition', DropDown);
    if (waveformPosition == null) throw 'ChartEditorToolboxHandler.buildToolboxPreferencesLayout() - Could not find preferencesWaveformPosition component.';
    waveformPosition.onChange = _ ->
    {
      if (!state.preferencesListening) return;
      state.currentWaveformPos = (waveformPosition.selectedIndex == 1) ? ChartEditorWaveformPos.Adjacent : ChartEditorWaveformPos.Overlay;
      state.waveformsDirty = true;
    };

    var waveformFilter:Null<DropDown> = toolbox.findComponent('preferencesWaveformFilter', DropDown);
    if (waveformFilter == null) throw 'ChartEditorToolboxHandler.buildToolboxPreferencesLayout() - Could not find preferencesWaveformFilter component.';
    waveformFilter.onChange = _ -> if (state.preferencesListening) state.waveformFilter = switch (waveformFilter.selectedIndex)
    {
      case 1: ChartEditorWaveformFilter.LowPass;
      case 2: ChartEditorWaveformFilter.HighPass;
      default: ChartEditorWaveformFilter.None;
    };

    var filterStrength:Null<Slider> = toolbox.findComponent('preferencesWaveformFilterStrength', Slider);
    var filterStrengthLabel:Null<Label> = toolbox.findComponent('preferencesWaveformFilterStrengthLabel', Label);
    if (filterStrength == null || filterStrengthLabel == null) throw 'ChartEditorToolboxHandler.buildToolboxPreferencesLayout() - Could not find preferencesWaveformFilterStrength components.';
    filterStrength.onChange = _ ->
    {
      if (!state.preferencesListening) return;
      var percent:Float = filterStrength.pos;
      state.waveformFilterStrength = percent / 100.0;
      filterStrengthLabel.text = 'Filter strength - ${Std.int(percent)}%';
    };

    var liveInput:Null<DropDown> = toolbox.findComponent('preferencesLiveInput', DropDown);
    if (liveInput == null) throw 'ChartEditorToolboxHandler.buildToolboxPreferencesLayout() - Could not find preferencesLiveInput component.';
    liveInput.onChange = _ -> if (state.preferencesListening) state.currentLiveInputStyle = switch (liveInput.selectedIndex)
    {
      case 1: ChartEditorLiveInputStyle.NumberKeys;
      case 2: ChartEditorLiveInputStyle.WASDKeys;
      default: ChartEditorLiveInputStyle.None;
    };

    var themeMusic:Null<CheckBox> = toolbox.findComponent('preferencesThemeMusic', CheckBox);
    if (themeMusic == null) throw 'ChartEditorToolboxHandler.buildToolboxPreferencesLayout() - Could not find preferencesThemeMusic component.';
    themeMusic.onClick = _ -> if (state.preferencesListening) state.setThemeMusicEnabled(themeMusic.selected);

    var stackThreshold:Null<DropDown> = toolbox.findComponent('preferencesStackThreshold', DropDown);
    if (stackThreshold == null) throw 'ChartEditorToolboxHandler.buildToolboxPreferencesLayout() - Could not find preferencesStackThreshold component.';
    for (snap in STACK_THRESHOLD_SNAPS)
      stackThreshold.dataSource.add({text: '1/$snap'});
    refreshStackThreshold(stackThreshold);
    stackThreshold.onChange = _ ->
    {
      if (!state.preferencesListening) return;
      // Index 0 is the 'Exact' option, the rest follow STACK_THRESHOLD_SNAPS.
      var selectedIndex:Int = stackThreshold.selectedIndex - 1;
      ChartEditorState.stackedNoteThreshold = (selectedIndex < 0) ? 0 : ChartEditorState.BASE_QUANT / STACK_THRESHOLD_SNAPS[selectedIndex];
      state.noteDisplayDirty = true;
      state.notePreviewDirty = true;
    };

    bindCheckbox(toolbox, 'preferencesInstrumentalWaveform', value -> state.showInstrumentalWaveform = value);
    bindCheckbox(toolbox, 'practiceModeCheckbox', value -> state.playtestPracticeMode = value);
    bindCheckbox(toolbox, 'playtestBotPlayCheckbox', value -> state.playtestBotPlayMode = value);
    bindCheckbox(toolbox, 'playtestShowResultsCheckbox', value -> state.playtestShowResults = value);
    bindCheckbox(toolbox, 'playtestStartTimeCheckbox', value -> state.playtestStartTime = value);
    bindCheckbox(toolbox, 'playtestSongScriptsCheckbox', value -> state.playtestSongScripts = value);
    bindCheckbox(toolbox, 'playtestAudioSettingsCheckbox', value -> state.playtestAudioSettings = value);

    return toolbox;
  }

  /**
   * The snaps offered by the note stack threshold dropdown, coarsest last.
   */
  static final STACK_THRESHOLD_SNAPS:Array<Int> = {
    var snaps:Array<Int> = ChartEditorState.SNAP_QUANTS.copy();
    snaps.reverse();
    snaps;
  };

  static function getPreferenceVolumeSliders(state:ChartEditorState):Array<Slider>
  {
    return [
      state.preferencesVolumeMetronome,
      state.preferencesVolumeHitsoundPlayer,
      state.preferencesVolumeHitsoundOpponent,
      state.preferencesVolumeInstrumental,
      state.preferencesVolumeVocalsPlayer,
      state.preferencesVolumeVocalsOpponent
    ];
  }

  static function capturePreferenceVolumes(state:ChartEditorState):Array<Float>
  {
    return [for (slider in getPreferenceVolumeSliders(state)) slider.pos];
  }

  /**
   * Put the volume sliders back to what they were before showing.
   */
  static function restorePreferenceVolumes(state:ChartEditorState, volumes:Array<Float>):Void
  {
    var sliders:Array<Slider> = getPreferenceVolumeSliders(state);
    for (i in 0...Std.int(Math.min(sliders.length, volumes.length)))
    {
      if (sliders[i].pos != volumes[i]) sliders[i].pos = volumes[i];
    }
  }

  static function bindCheckbox(toolbox:CollapsibleDialog, id:String, onChange:Bool->Void):Void
  {
    var checkbox:Null<CheckBox> = toolbox.findComponent(id, CheckBox);
    if (checkbox == null) throw 'ChartEditorToolboxHandler.bindCheckbox() - Could not find ${id} component.';
    checkbox.onClick = _ -> onChange(checkbox.selected);
  }

  static function setCheckbox(toolbox:CollapsibleDialog, id:String, value:Bool):Void
  {
    var checkbox:Null<CheckBox> = toolbox.findComponent(id, CheckBox);
    if (checkbox != null) checkbox.selected = value;
  }

  /**
   * Set every control in the preferences toolbox to the editor's current settings.
   */
  static function refreshToolboxPreferences(state:ChartEditorState, toolbox:CollapsibleDialog):Void
  {
    var theme:Null<DropDown> = toolbox.findComponent('preferencesTheme', DropDown);
    if (theme != null) theme.selectedIndex = (state.currentTheme == ChartEditorTheme.Dark) ? 1 : 0;

    var noteKinds:Null<CheckBox> = toolbox.findComponent('preferencesNoteKindIndicators', CheckBox);
    if (noteKinds != null) noteKinds.selected = state.showNoteKindIndicators;

    var subtitles:Null<CheckBox> = toolbox.findComponent('preferencesSubtitles', CheckBox);
    if (subtitles != null) subtitles.selected = state.showSubtitles;

    var beatLines:Null<CheckBox> = toolbox.findComponent('preferencesBeatLines', CheckBox);
    if (beatLines != null) beatLines.selected = state.showBeatLines;

    var cursorLine:Null<CheckBox> = toolbox.findComponent('preferencesCursorLine', CheckBox);
    if (cursorLine != null) cursorLine.selected = state.showCursorLine;

    var opacity:Int = Std.int(Math.round(state.gridBackingAlpha * 100));
    var backingOpacity:Null<Slider> = toolbox.findComponent('preferencesBackingOpacity', Slider);
    if (backingOpacity != null) backingOpacity.pos = opacity;
    var backingOpacityLabel:Null<Label> = toolbox.findComponent('preferencesBackingOpacityLabel', Label);
    if (backingOpacityLabel != null) backingOpacityLabel.text = 'Grid backing opacity - ${opacity}%';

    var waveformPosition:Null<DropDown> = toolbox.findComponent('preferencesWaveformPosition', DropDown);
    if (waveformPosition != null) waveformPosition.selectedIndex = (state.currentWaveformPos == ChartEditorWaveformPos.Adjacent) ? 1 : 0;

    var waveformFilter:Null<DropDown> = toolbox.findComponent('preferencesWaveformFilter', DropDown);
    if (waveformFilter != null) waveformFilter.selectedIndex = switch (state.waveformFilter)
    {
      case ChartEditorWaveformFilter.LowPass: 1;
      case ChartEditorWaveformFilter.HighPass: 2;
      default: 0;
    };

    var strengthPercent:Int = Std.int(Math.round(state.waveformFilterStrength * 100));
    var filterStrength:Null<Slider> = toolbox.findComponent('preferencesWaveformFilterStrength', Slider);
    if (filterStrength != null) filterStrength.pos = strengthPercent;
    var filterStrengthLabel:Null<Label> = toolbox.findComponent('preferencesWaveformFilterStrengthLabel', Label);
    if (filterStrengthLabel != null) filterStrengthLabel.text = 'Filter strength - ${strengthPercent}%';

    var liveInput:Null<DropDown> = toolbox.findComponent('preferencesLiveInput', DropDown);
    if (liveInput != null) liveInput.selectedIndex = switch (state.currentLiveInputStyle)
    {
      case ChartEditorLiveInputStyle.NumberKeys: 1;
      case ChartEditorLiveInputStyle.WASDKeys: 2;
      default: 0;
    };

    var themeMusic:Null<CheckBox> = toolbox.findComponent('preferencesThemeMusic', CheckBox);
    if (themeMusic != null) themeMusic.selected = state.shouldPlayWelcomeMusic;

    var stackThreshold:Null<DropDown> = toolbox.findComponent('preferencesStackThreshold', DropDown);
    if (stackThreshold != null) refreshStackThreshold(stackThreshold);

    setCheckbox(toolbox, 'preferencesInstrumentalWaveform', state.showInstrumentalWaveform);
    setCheckbox(toolbox, 'practiceModeCheckbox', state.playtestPracticeMode);
    setCheckbox(toolbox, 'playtestBotPlayCheckbox', state.playtestBotPlayMode);
    setCheckbox(toolbox, 'playtestShowResultsCheckbox', state.playtestShowResults);
    setCheckbox(toolbox, 'playtestStartTimeCheckbox', state.playtestStartTime);
    setCheckbox(toolbox, 'playtestSongScriptsCheckbox', state.playtestSongScripts);
    setCheckbox(toolbox, 'playtestAudioSettingsCheckbox', state.playtestAudioSettings);
  }

  static function refreshStackThreshold(stackThreshold:DropDown):Void
  {
    if (stackThreshold.dataSource.size <= 1) return;
    var index:Int = 0;
    for (i in 0...STACK_THRESHOLD_SNAPS.length)
    {
      if (ChartEditorState.stackedNoteThreshold == ChartEditorState.BASE_QUANT / STACK_THRESHOLD_SNAPS[i]) index = i + 1;
    }
    stackThreshold.selectedIndex = index;
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

    toolbox.draggable = false;
    toolbox.dragInitiator = toolbox;

    toolbox.onDialogClosed = function(event:DialogEvent)
    {
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

  static function onShowToolboxPlayerPreview(state:ChartEditorState, toolbox:CollapsibleDialog):Void
  {
  }

  static function onHideToolboxPlayerPreview(state:ChartEditorState, toolbox:CollapsibleDialog):Void
  {
  }

  static function buildToolboxOpponentPreviewLayout(state:ChartEditorState):Null<CollapsibleDialog>
  {
    var toolbox:CollapsibleDialog = cast RuntimeComponentBuilder.fromAsset(ChartEditorState.CHART_EDITOR_TOOLBOX_OPPONENT_PREVIEW_LAYOUT);

    if (toolbox == null) return null;

    toolbox.draggable = false;
    toolbox.dragInitiator = toolbox;

    toolbox.onDialogClosed = (event:DialogEvent) ->
    {
      state.menubarItemToggleToolboxOpponentPreview.selected = false;
    }

    var charPlayer:Null<CharacterPlayer> = toolbox.findComponent('charOpponent');
    if (charPlayer == null) throw 'ChartEditorToolboxHandler.buildToolboxOpponentPreviewLayout() - Could not find charOpponent component.';
    // TODO: We need to implement character swapping in ChartEditorState.
    charPlayer.loadCharacter('dad');
    charPlayer.characterType = CharacterType.DAD;
    charPlayer.flip = false;
    charPlayer.targetScale = 0.5;

    return toolbox;
  }

  static function onShowToolboxOpponentPreview(state:ChartEditorState, toolbox:CollapsibleDialog):Void
  {
  }

  static function onHideToolboxOpponentPreview(state:ChartEditorState, toolbox:CollapsibleDialog):Void
  {
  }
}
#end
