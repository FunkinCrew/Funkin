package funkin.ui.debug.charting.handlers.editor;

#if FEATURE_CHART_EDITOR
import funkin.save.Save;
import funkin.ui.debug.charting.handlers.ui.ChartEditorToolboxHandler;
import haxe.ui.components.Label;
import haxe.ui.components.Slider;
using Lambda;

@:access(funkin.ui.debug.charting.ChartEditorState)
class ChartEditorPreferencesHandler
{
  /**
   * Load the Chart Editor preferences from the save file.
   */
  public static function loadPreferences(state:ChartEditorState):Void
  {
    var save:Save = Save.instance;

    if (state.previousWorkingFilePaths[0] == null)
    {
      state.previousWorkingFilePaths = [null].concat(save.chartEditorPreviousFiles.value);
    }
    else
    {
      state.previousWorkingFilePaths = [state.currentWorkingFilePath].concat(save.chartEditorPreviousFiles.value);
    }

    state.noteSnapQuantIndex = save.chartEditorNoteQuant.value;
    state.zoomLevelIndex = save.chartEditorZoomLevel.value;
    state.zoomCurrent = ChartEditorState.ZOOM_LEVELS[state.zoomLevelIndex];
    state.updateGridScale();
    state.currentLiveInputStyle = save.chartEditorLiveInputStyle.value;
    state.currentWaveformPos = save.chartEditorWaveformPos.value;
    state.showInstrumentalWaveform = save.chartEditorShowInstrumentalWaveform.value;
    state.waveformFilter = save.chartEditorWaveformFilter.value;
    state.waveformFilterStrength = save.chartEditorWaveformFilterStrength.value;
    state.isViewDownscroll = save.chartEditorDownscroll.value;
    state.showNoteKindIndicators = save.chartEditorShowNoteKinds.value;
    state.showDifficultyHeatmap = save.chartEditorShowDifficultyHeatmap.value;
    state.showBeatLines = save.chartEditorShowBeatLines.value;
    state.showCursorLine = save.chartEditorShowCursorLine.value;
    state.constantScrollSpeed = save.chartEditorConstantScrollSpeed.value;
    state.uiScale = save.chartEditorUIScale.value;
    state.constantScrollEnabled = save.chartEditorConstantScroll.value;
    state.gridBackingAlpha = save.chartEditorGridBackingAlpha.value;
    state.showSubtitles = save.chartEditorShowSubtitles.value;
    state.playtestStartTime = save.chartEditorPlaytestStartTime.value;
    state.playtestAudioSettings = save.chartEditorPlaytestAudioSettings.value;
    state.playtestShowResults = save.chartEditorPlaytestResultsSettings.value;
    state.playtestPracticeMode = save.chartEditorPlaytestPracticeMode.value;
    state.playtestBotPlayMode = save.chartEditorPlaytestBotPlayMode.value;
    state.playtestSongScripts = save.chartEditorPlaytestSongScripts.value;
    ChartEditorState.stackedNoteThreshold = save.chartEditorStackedNoteThreshold.value;
    state.currentTheme = save.chartEditorTheme.value;
    state.metronomeVolume = save.chartEditorMetronomeVolume.value;
    state.hitsoundVolumePlayer = save.chartEditorHitsoundVolumePlayer.value;
    state.hitsoundVolumeOpponent = save.chartEditorHitsoundVolumeOpponent.value;
    state.shouldPlayWelcomeMusic = save.chartEditorThemeMusic.value;

    state.preferencesVolumeInstrumental.value = Std.int(save.chartEditorInstVolume.value * 100);
    state.preferencesVolumeVocalsPlayer.value = Std.int(save.chartEditorPlayerVoiceVolume.value * 100);
    state.preferencesVolumeVocalsOpponent.value = Std.int(save.chartEditorOpponentVoiceVolume.value * 100);
    state.menubarItemPlaybackSpeed.value = Math.round(save.chartEditorPlaybackSpeed.value * 100.0);
  }

  /**
   * Write the Chart Editor preferences to the save file.
   *
   * @param hasBackup Whether there is a
   */
  public static function writePreferences(state:ChartEditorState, hasBackup:Bool):Void
  {
    var save:Save = Save.instance;

    // Can't use filter() because of null safety checking!
    var filteredWorkingFilePaths:Array<String> = [];
    for (chartPath in state.previousWorkingFilePaths) if (chartPath != null) filteredWorkingFilePaths.pushUnique(chartPath);
    save.chartEditorPreviousFiles.value = filteredWorkingFilePaths;

    if (hasBackup) trace('Queuing backup prompt for next time!');
    save.chartEditorHasBackup.value = hasBackup;

    save.chartEditorNoteQuant.value = state.noteSnapQuantIndex;
    save.chartEditorZoomLevel.value = state.zoomLevelIndex;
    save.chartEditorLiveInputStyle.value = state.currentLiveInputStyle;
    save.chartEditorWaveformPos.value = state.currentWaveformPos;
    save.chartEditorShowInstrumentalWaveform.value = state.showInstrumentalWaveform;
    save.chartEditorWaveformFilter.value = state.waveformFilter;
    save.chartEditorWaveformFilterStrength.value = state.waveformFilterStrength;
    save.chartEditorDownscroll.value = state.isViewDownscroll;
    save.chartEditorShowNoteKinds.value = state.showNoteKindIndicators;
    save.chartEditorShowDifficultyHeatmap.value = state.showDifficultyHeatmap;
    save.chartEditorShowBeatLines.value = state.showBeatLines;
    save.chartEditorShowCursorLine.value = state.showCursorLine;
    save.chartEditorConstantScroll.value = state.constantScrollEnabled;
    save.chartEditorConstantScrollSpeed.value = state.constantScrollSpeed;
    save.chartEditorUIScale.value = state.uiScale;
    save.chartEditorGridBackingAlpha.value = state.gridBackingAlpha;
    save.chartEditorPlaytestStartTime.value = state.playtestStartTime;
    save.chartEditorPlaytestAudioSettings.value = state.playtestAudioSettings;
    save.chartEditorPlaytestResultsSettings.value = state.playtestShowResults;
    save.chartEditorPlaytestPracticeMode.value = state.playtestPracticeMode;
    save.chartEditorPlaytestBotPlayMode.value = state.playtestBotPlayMode;
    save.chartEditorPlaytestSongScripts.value = state.playtestSongScripts;
    save.chartEditorStackedNoteThreshold.value = ChartEditorState.stackedNoteThreshold;
    save.chartEditorShowSubtitles.value = state.showSubtitles;
    save.chartEditorTheme.value = state.currentTheme;
    save.chartEditorMetronomeVolume.value = state.metronomeVolume;
    save.chartEditorHitsoundVolumePlayer.value = state.hitsoundVolumePlayer;
    save.chartEditorHitsoundVolumeOpponent.value = state.hitsoundVolumeOpponent;
    save.chartEditorThemeMusic.value = state.shouldPlayWelcomeMusic;

    save.chartEditorInstVolume.value = state.preferencesVolumeInstrumental.value / 100.0;
    save.chartEditorPlayerVoiceVolume.value = state.preferencesVolumeVocalsPlayer.value / 100.0;
    save.chartEditorOpponentVoiceVolume.value = state.preferencesVolumeVocalsOpponent.value / 100.0;
    save.chartEditorPlaybackSpeed.value = state.menubarItemPlaybackSpeed.value / 100.0;
  }

  /**
   * Binds the audio volume controls from the Preferences toolbox to the ChartEditorState.
   */
  public static function bindPreferencesAudioControls(state:ChartEditorState):Void
  {
    var toolbox = ChartEditorToolboxHandler.getToolboxUnCast(state, ChartEditorState.CHART_EDITOR_TOOLBOX_PREFERENCES_LAYOUT);

    state.preferencesVolumeMetronome = toolbox.findComponent('preferencesVolumeMetronome', Slider);
    state.preferencesLabelVolumeMetronome = toolbox.findComponent('preferencesLabelVolumeMetronome', Label);
    state.preferencesVolumeHitsoundPlayer = toolbox.findComponent('preferencesVolumeHitsoundPlayer', Slider);
    state.preferencesLabelVolumeHitsoundPlayer = toolbox.findComponent('preferencesLabelVolumeHitsoundPlayer', Label);
    state.preferencesVolumeHitsoundOpponent = toolbox.findComponent('preferencesVolumeHitsoundOpponent', Slider);
    state.preferencesLabelVolumeHitsoundOpponent = toolbox.findComponent('preferencesLabelVolumeHitsoundOpponent', Label);
    state.preferencesVolumeInstrumental = toolbox.findComponent('preferencesVolumeInstrumental', Slider);
    state.preferencesLabelVolumeInstrumental = toolbox.findComponent('preferencesLabelVolumeInstrumental', Label);
    state.preferencesVolumeVocalsPlayer = toolbox.findComponent('preferencesVolumeVocalsPlayer', Slider);
    state.preferencesLabelVolumeVocalsPlayer = toolbox.findComponent('preferencesLabelVolumeVocalsPlayer', Label);
    state.preferencesVolumeVocalsOpponent = toolbox.findComponent('preferencesVolumeVocalsOpponent', Slider);
    state.preferencesLabelVolumeVocalsOpponent = toolbox.findComponent('preferencesLabelVolumeVocalsOpponent', Label);
  }
}
#end
