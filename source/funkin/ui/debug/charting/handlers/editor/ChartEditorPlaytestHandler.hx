package funkin.ui.debug.charting.handlers.editor;

#if FEATURE_CHART_EDITOR
import funkin.ui.transition.Transition;
import flixel.FlxSubState;
import funkin.graphics.FunkinCamera;
import funkin.input.Cursor;
import funkin.play.PlayState;
import funkin.play.PlayStatePlaylist;
import funkin.play.song.Song;
import funkin.save.Save;
import funkin.ui.debug.cameraeditor.CameraEditorState;
import funkin.ui.debug.charting.util.ChartEditorScaleMode;
import funkin.util.FlxStateUtil;
import haxe.io.Path;
import haxe.ui.components.DropDown;
import haxe.ui.containers.menus.Menu;
import haxe.ui.core.Screen;
import haxe.ui.events.UIEvent;
import haxe.ui.focus.FocusManager;
import funkin.ui.debug.charting.handlers.chart.ChartEditorImportExportHandler;
using Lambda;

@:access(funkin.ui.debug.charting.ChartEditorState)
class ChartEditorPlaytestHandler
{
  static var playtestClosedListener:Null<FlxSubState->Void> = null;

  public static function clearPlaytestListener(state:ChartEditorState):Void
  {
    var listener:Null<FlxSubState->Void> = playtestClosedListener;
    if (listener != null) state.subStateClosed.remove(listener);
    playtestClosedListener = null;
  }

  /**
   * Transitions to the Play State to test the song
   */
  public static function testSongInPlayState(state:ChartEditorState, minimal:Bool = false):Void
  {
    for (component in Screen.instance.rootComponents.copy())
    {
      if (component is Menu)
      {
        if (cast(component, Menu).menuBar != null) component.dispatch(new UIEvent(UIEvent.CLOSE));
        else
          Screen.instance.removeComponent(component, false);
      }
      for (dropDown in component.findComponents(null, DropDown, -1)) dropDown.hideDropDown();
    }

    state.autoSave(true);

    if (!ChartEditorState.wasPlaytesting)
    {
      }

    // Stop audio playback after note preview is stopped.
    // `false` to force the welcome theme to stop too.
    state.stopAudioPlayback(false);

    var startTimestamp:Float = 0;
    if (state.playtestStartTime) startTimestamp = state.scrollPositionInMs + state.playheadPositionInMs;

    var playbackRate:Float = 1.0;
    if (state.playtestAudioSettings)
    {
      playbackRate = ((state.menubarItemPlaybackSpeed.value / 100.0) ?? 0.5) * 2.0;
      playbackRate = playbackRate.clamp(0.05, 2.0); // Clamp to 5% to 200%
    }

    funkin.play.GameOverSubState.reset();
    funkin.play.PauseSubState.reset();

    // Validate the chart before playtesting.
    var chartDataForVariation = state.songChartData.get(state.selectedVariation);
    if (chartDataForVariation == null)
    {
      state.error('Could Not Playtest', 'Got an error playtesting the song:\nNo variation found: ${state.selectedVariation}');
      return;
    }

    var chartEventErrors:Array<String> = chartDataForVariation.validateChartEvents(state.selectedDifficulty);
    if (chartEventErrors.length > 0)
    {
      state.error('Could Not Playtest', 'Got an error playtesting the song:\n${chartEventErrors.join('\n')}');
      return;
    }

    var targetSong:Song;

    var listedDifficulties:Array<String> = state.currentSongMetadata.playData.difficulties;
    var addedUnlisted:Bool = !listedDifficulties.contains(state.selectedDifficulty);
    if (addedUnlisted) listedDifficulties.push(state.selectedDifficulty);
    try
    {
      targetSong = Song.buildRaw(state.currentSongId, state.songMetadata.values(), state.selectedVariation, state.songChartData, state.playtestSongScripts, false);
    }
    catch (e)
    {
      if (addedUnlisted) listedDifficulties.remove(state.selectedDifficulty);
      state.error('Could Not Playtest', 'Got an error playtesting the song:\n${e}');
      return;
    }
    if (addedUnlisted) listedDifficulties.remove(state.selectedDifficulty);

    PlayStatePlaylist.reset();
    var oldListener:Null<FlxSubState->Void> = playtestClosedListener;
    if (oldListener != null) state.subStateClosed.remove(oldListener);
    var listener:FlxSubState->Void = closed ->
    {
      state.reviveUICamera(closed);
      state.resetConductorAfterTest(closed);
    };
    playtestClosedListener = listener;
    state.subStateClosed.add(listener);

    var targetStateParams = {
      targetSong: targetSong,
      targetDifficulty: state.selectedDifficulty,
      targetVariation: state.selectedVariation,
      practiceMode: state.playtestPracticeMode,
      botPlayMode: state.playtestBotPlayMode,
      playtestResults: state.playtestShowResults,
      minimalMode: minimal,
      startTimestamp: startTimestamp,
      playbackRate: playbackRate,
      overrideMusic: true,
    };

    // Override music.
    if (state.audioInstTrack != null)
    {
      FlxG.sound.music = state.audioInstTrack;
    }
    // The playtest runs at the game's normal size.
    ChartEditorScaleMode.restore();

    // Kill and replace the UI camera so it doesn't get destroyed during the state transition.
    state.uiCamera.kill();
    FlxG.cameras.remove(state.uiCamera, false);
    FlxG.cameras.reset(new FunkinCamera('chartEditorUI2'));
    state.persistentUpdate = false;
    state.persistentDraw = false;
    Cursor.hide();
    funkin.ui.transition.Transition.openPlayState(targetStateParams, {
      transition: Throbber,
      shouldStopMusic: false,
      onConstruct: (targetState) ->
      {
        if (state.playbarHeadDragging) state.playbarHeadDragging = false;
        // Apply volume settings.
        final playState = cast(targetState, funkin.play.PlayState);
        if (state.playtestAudioSettings)
        {
          playState.instrumentalVolume = state.instrumentalMuted ? 0.0 : ((state.preferencesVolumeInstrumental.value / 100.0) ?? 1.0);
          playState.playerVocalsVolume = state.playerVocalsMuted ? 0.0 : ((state.preferencesVolumeVocalsPlayer.value / 100.0) ?? 1.0);
          playState.opponentVocalsVolume = state.opponentVocalsMuted ? 0.0 : ((state.preferencesVolumeVocalsOpponent.value / 100.0) ?? 1.0);
        }
        else state.audioVocalTrackGroup.muted = false;

        playState.vocals = state.audioVocalTrackGroup;
      }
    }, true);

    /*LoadingState.loadPlayState(targetStateParams, false, true, function(targetState)
      {

    });*/
  }

  /**
   * Revive the UI camera and re-establish it as the main camera so UI elements depending on it don't explode.
   */
  public static function reviveUICamera(state:ChartEditorState, ?closedSubState:FlxSubState):Void
  {
    if (closedSubState != null && (FlxStateUtil.isTransition(closedSubState) || FlxStateUtil.isLoadingState(closedSubState)))
    {
      // The state that closed was a loading screen for the substate we're opening,
      // so we shouldn't do any cleanup.
      return;
    }

    state.uiScaleDirty = false;
    ChartEditorScaleMode.apply(state.uiScale);
    state.uiCamera.revive();
    FlxG.cameras.reset(state.uiCamera);
    state.uiCamera.setSize(FlxG.width, FlxG.height);
    state.uiCamera.onResize();

    state.add(state.root);
  }

  /**
   * Fix the current scroll position after exiting the PlayState used when testing.
   */
  @:nullSafety(Off)
  public static function resetConductorAfterTest(state:ChartEditorState, ?closedSubState:FlxSubState):Void
  {
    if (closedSubState != null && (FlxStateUtil.isTransition(closedSubState) || FlxStateUtil.isLoadingState(closedSubState)))
    {
      // The state that closed was a loading screen for the substate we're opening,
      // so we shouldn't do any cleanup.
      return;
    }

    state.persistentUpdate = true;
    state.persistentDraw = true;

    if (state.displayAutosavePopup)
    {
      state.displayAutosavePopup = false;
      #if sys
      haxe.ui.Toolkit.callLater(() ->
      {
        var absoluteBackupsPath:String = Path.join([
          Sys.getCwd(),
          ChartEditorImportExportHandler.BACKUPS_PATH
        ]);
        state.infoWithActions('Auto-Save', 'Chart auto-saved to ${absoluteBackupsPath}.', [{
          text: 'Open In Folder',
          callback: state.openBackupsFolder,
        }]);
      });
      #else
      // TODO: No auto-save on HTML5?
      #end
    }

    if (state.saveDataDirty) state.queueAutoSave();

    state.moveSongToScrollPosition();

    state.fadeInWelcomeMusic(ChartEditorState.WELCOME_MUSIC_FADE_IN_DELAY, ChartEditorState.WELCOME_MUSIC_FADE_IN_DURATION);

    Cursor.show();

    // Reapply the volume and playback rate.
    var instTargetVolume:Float = (state.preferencesVolumeInstrumental.value / 100.0) ?? 1.0;
    var vocalPlayerTargetVolume:Float = (state.preferencesVolumeVocalsPlayer.value / 100.0) ?? 1.0;
    var vocalOpponentTargetVolume:Float = (state.preferencesVolumeVocalsOpponent.value / 100.0) ?? 1.0;

    var playbackRate = ((state.menubarItemPlaybackSpeed.value / 100.0) ?? 0.5) * 2.0;
    playbackRate = playbackRate.clamp(0.05, 2.0); // Clamp to 5% to 200%

    if (state.audioInstTrack != null)
    {
      state.audioInstTrack.volume = instTargetVolume;
      state.audioInstTrack.pitch = playbackRate;
      state.audioInstTrack.onComplete = null;
    }
    if (state.audioVocalTrackGroup != null)
    {
      state.audioVocalTrackGroup.playerVolume = vocalPlayerTargetVolume;
      state.audioVocalTrackGroup.opponentVolume = vocalOpponentTargetVolume;
      state.audioVocalTrackGroup.pitch = playbackRate;
    }
    if (state.audioInstTrack != null) state.audioInstTrack.muted = state.instrumentalMuted;
    state.applyVocalMutes();

    state.noteTooltipsDirty = true;
  }

  public static function moveToCameraEditor(state:ChartEditorState, hasSaved:Bool = false):Void
  {
    if (!hasSaved)
    {
      // Save the current chart as a file.
      if (state.currentWorkingFilePath != null)
      {
        state.exportCurrentChartToFNFC(true, state.currentWorkingFilePath);
        state.moveToCameraEditor(true);
      }
      else
      {
        state.exportCurrentChartToFNFC(false, null, function(path:String)
        {
          // CTRL + SHIFT + S Successful
          // Just to be sure
          state.currentWorkingFilePath = path;

          state.moveToCameraEditor(true);
        }, function()
        {
          // CTRL + SHIFT + S Cancelled, do NOTHING
          return;
        });
      }
    }
    else
    {
      if (state.currentWorkingFilePath == null)
      {
        state.error("Can't Move To Camera Editor", 'Camera Editor can only be accessed when the current chart has been saved to a file.');
        return;
      }

      var startTimestamp:Float = state.scrollPositionInMs + state.playheadPositionInMs;

      @:nullSafety(Off)
      {
        final f = FocusManager.instance.focus;
        if (f != null) f.focus = false;
      }

      state.writePreferences(false);
      state.performCleanup();

      var cameraEditorParams = {
        loadFromPath: state.currentWorkingFilePath,
        targetSongDifficulty: state.selectedDifficulty,
        targetSongVariation: state.selectedVariation,
        targetSongPosition: startTimestamp,
      };

      Transition.switchState(() -> new CameraEditorState(cameraEditorParams), {
        assetQuery: Transition.NO_ASSETS, // CameraEditorState.queryAssets.bind(_, cameraEditorParams),
        transition: BlackScreen(None, Fade(South))
      });
    }
  }
}
#end
