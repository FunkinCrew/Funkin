package funkin.ui.debug.charting.handlers.audio;

#if FEATURE_CHART_EDITOR
import flixel.util.FlxTimer;
import funkin.assets.ValidatedPaths as Paths;
import funkin.data.notestyle.NoteStyleRegistry;
import funkin.data.song.SongDataUtils;
import funkin.data.song.SongData.SongNoteData;
import funkin.graphics.FunkinSprite;
import funkin.play.PlayState;
import funkin.play.notes.NoteSprite;
import funkin.modding.events.ScriptEvent;
import funkin.util.Constants;
import funkin.util.MathUtil;
using Lambda;

@:access(funkin.ui.debug.charting.ChartEditorState)
class ChartEditorPlaybackHandler
{
  /**
   * Turn the theme music on or off, fading it back in if it should be playing.
   */
  public static function setThemeMusicEnabled(state:ChartEditorState, value:Bool):Void
  {
    state.shouldPlayWelcomeMusic = value;
    if (!state.welcomeMusic.active || !state.shouldPlayWelcomeMusic)
    {
      state.fadeInWelcomeMusic(ChartEditorState.WELCOME_MUSIC_FADE_IN_DELAY, ChartEditorState.WELCOME_MUSIC_FADE_IN_DURATION);
    }
  }

  public static function setupWelcomeMusic(state:ChartEditorState)
  {
    state.welcomeMusic.loadEmbedded(Paths.music('ui/editors/chart-editor/artistic-expression').audio().toFlxSoundAsset());
    FlxG.sound.list.add(state.welcomeMusic);
    state.welcomeMusic.looped = true;
  }

  public static function fadeInWelcomeMusic(state:ChartEditorState, extraWait:Float = 0, fadeInTime:Float = 5):Void
  {
    if (!state.shouldPlayWelcomeMusic)
    {
      state.stopWelcomeMusic();
      return;
    }

    if ((state.audioInstTrack != null && state.audioInstTrack.isPlaying) || state.audioVocalTrackGroup.playing) return;

    if (state.welcomeMusic.isPlaying) return;

    if (!state.welcomeMusic.exists) state.setupWelcomeMusic();

    if (state.bgMusicTimer != null) state.bgMusicTimer.cancel();
    state.bgMusicTimer = new FlxTimer().start(extraWait, (_) ->
    {
      if (state.shouldPlayWelcomeMusic)
      {
        state.welcomeMusic.play();
        state.welcomeMusic.fadeIn(fadeInTime, 0, 1.0);
      }
      // Cleanup.
      if (state.bgMusicTimer != null)
      {
        state.bgMusicTimer.cancel();
        state.bgMusicTimer = null;
      }
    });
  }

  public static function stopWelcomeMusic(state:ChartEditorState):Void
  {
    if (state.bgMusicTimer != null)
    {
      state.bgMusicTimer.cancel();
      state.bgMusicTimer = null;
    }
    state.welcomeMusic.pause();
  }

  /**
   * Handle syncronizing the conductor with the music playback.
   */
  public static function handleMusicPlayback(state:ChartEditorState, elapsed:Float):Void
  {
    if (state.audioInstTrack != null)
    {
      // This normally gets called by FlxG.sound.update()
      // but we handle instrumental updates manually to prevent FlxG.sound.music.update()
      // from being called twice when we move to the PlayState.
      state.audioInstTrack.update(elapsed);

      // If the song starts 50ms in, make sure we start the song there.
      if (Conductor.instance.instrumentalOffset < 0)
      {
        if (state.audioInstTrack.time < -Conductor.instance.instrumentalOffset)
        {
          trace('Resetting instrumental time to ${- Conductor.instance.instrumentalOffset}ms');
          state.audioInstTrack.time = -Conductor.instance.instrumentalOffset;
        }
      }

      state.audioVocalTrackGroup.updatePending(state.audioInstTrack.time, state.audioInstTrack.isPlaying);

      if
        ((!state.audioInstTrack.isPlaying || (state.audioVocalTrackGroup.length > 0 && !state.audioVocalTrackGroup.playing))
          && state.currentScrollEase != state.scrollPositionInPixels
        ) state.easeSongToScrollPosition(state.currentScrollEase);
    }

    if ((state.audioInstTrack != null && state.audioInstTrack.isPlaying) || state.audioVocalTrackGroup.playing)
    {
      state.currentScrollEase = state.scrollPositionInPixels;

      if (FlxG.keys.pressed.ALT && !FlxG.keys.pressed.CONTROL)
      {
        // If middle mouse panning during song playback, we move ONLY the playhead, without scrolling. Neat!

        var oldSongPosition:Float = Conductor.instance.songPosition + Conductor.instance.instrumentalOffset;
        state.updateSongTime();
        state.handleMusicPositionUpdate(oldSongPosition, Conductor.instance.songPosition + Conductor.instance.instrumentalOffset);
        // Resync vocals.
        if (Math.abs(state.audioInstTrack.time - state.audioVocalTrackGroup.time) > 100)
        {
          state.audioVocalTrackGroup.time = state.audioInstTrack.time;
        }
        // Move the playhead.
        state.playheadPositionInPixels = ChartEditorTimeScale.stepToPixels(Conductor.instance.currentStepTime + Conductor.instance.instrumentalOffsetSteps) - state.scrollPositionInPixels;

        // We don't move the song to scroll position, or update the note sprites.
      }
      else
      {
        // Else, move the entire view.
        var oldSongPosition:Float = Conductor.instance.songPosition + Conductor.instance.instrumentalOffset;
        state.updateSongTime();
        state.handleMusicPositionUpdate(oldSongPosition, Conductor.instance.songPosition + Conductor.instance.instrumentalOffset);
        // Resync vocals.
        if (Math.abs(state.audioInstTrack.time - state.audioVocalTrackGroup.time) > 100)
        {
          state.audioVocalTrackGroup.time = state.audioInstTrack.time;
        }

        // We need time in fractional steps here to allow the song to actually play.
        // Also account for a potentially offset playhead.
        state.scrollPositionInPixels = ChartEditorTimeScale.stepToPixels(Conductor.instance.currentStepTime + Conductor.instance.instrumentalOffsetSteps) - state.playheadPositionInPixels;

        // DO NOT move song to scroll position here specifically.

        // We need to update the note sprites.
        state.noteDisplayDirty = true;

        // Update the note preview viewport box.
        state.setNotePreviewViewportBounds(state.calculateNotePreviewViewportBounds());
      }
    }

    if (FlxG.keys.justPressed.SPACE && !(state.isHaxeUIDialogOpen || state.isHaxeUIFocused))
    {
      state.toggleAudioPlayback();
    }
  }

  /**
   * Step the playback speed, staying on whole tenths between 0.1x and 2x.
   */
  public static function changePlaybackSpeed(state:ChartEditorState, amount:Float):Void
  {
    // The slider runs from 0 to 100 for 0x to 2x.
    var currentRate:Float = state.menubarItemPlaybackSpeed.pos / 50.0;
    var newRate:Float = Math.round((currentRate + amount) * 10) / 10;
    state.setPlaybackSpeed(newRate.clamp(0.1, 2.0));
  }

  /**
   * Set the playback speed from code, moving the slider to match.
   */
  public static function setPlaybackSpeed(state:ChartEditorState, rate:Float):Void
  {
    state.menubarItemPlaybackSpeed.pos = rate * 50.0;
    state.applyPlaybackSpeed(rate);
  }

  public static function applyPlaybackSpeed(state:ChartEditorState, rate:Float):Void
  {
    if (state.audioInstTrack != null) state.audioInstTrack.pitch = rate;
    state.audioVocalTrackGroup.pitch = rate;
    var rateDisplay:Float = Std.int(rate * 100) / 100; // Round to 2 decimal places.
    state.menubarLabelPlaybackSpeed.text = 'Playback Speed - ${rateDisplay}x';
  }

  /**
   * The song time at the playhead.
   */
  static function playheadSongMs(state:ChartEditorState):Float
  {
    var playing:Bool = (state.audioInstTrack != null && state.audioInstTrack.isPlaying) || state.audioVocalTrackGroup.playing;
    if (playing) return Conductor.instance.songPosition + Conductor.instance.instrumentalOffset;
    return ChartEditorTimeScale.pixelsToMs(state.scrollPositionInPixels + state.playheadPositionInPixels);
  }

  /**
   * Show the ghost playhead where Scroll Velocity events have moved the notes at the receptors to.
   */
  public static function handleGhostPlayhead(state:ChartEditorState):Void
  {
    var songMs:Float = playheadSongMs(state);
    var visualMs:Float = ChartEditorTimeScale.visualTime(songMs);
    var shown:Bool = Math.abs(visualMs - songMs) > 0.5;
    var ghostPixels:Float = ChartEditorTimeScale.msToPixels(visualMs);

    if (shown) shown = Math.abs(ghostPixels - (state.scrollPositionInPixels + state.playheadPositionInPixels)) >= ChartEditorState.PLAYHEAD_HEIGHT;
    state.gridGhostPlayhead.visible = shown;
    if (!shown) return;

    state.gridGhostPlayhead.y = ghostPixels - state.scrollPositionInPixels + ChartEditorState.GRID_INITIAL_Y_POS;
    var text:Null<flixel.text.FlxText> = state.gridGhostPlayheadText;
    if (text != null)
    {
      var label:String = flixel.util.FlxStringUtil.formatTime(Math.max(0, visualMs - Conductor.instance.instrumentalOffset) / Constants.MS_PER_SEC, true);
      if (text.text != label) text.text = label;
    }
  }

  /**
   * Show the player's viewport on the grid, if enabled.
   */
  public static function handlePlayerView(state:ChartEditorState):Void
  {
    var sprite:Null<flixel.FlxSprite> = state.gridPlayerView;
    var edge:Null<flixel.FlxSprite> = state.gridPlayerViewEdge;
    if (sprite == null || edge == null) return;
    sprite.visible = state.showPlayerView;
    edge.visible = state.showPlayerView;
    if (!sprite.visible) return;

    var songMs:Float = playheadSongMs(state);
    var visualMs:Float = ChartEditorTimeScale.visualTime(songMs);
    var downscroll:Bool = Preferences.downscroll;
    var strumlineOffsetY:Float = 0;
    if (downscroll)
    {
      var style:Null<funkin.play.notes.notestyle.NoteStyle> = funkin.data.notestyle.NoteStyleRegistry.instance.fetchEntry(state.currentSongNoteStyle);
      strumlineOffsetY = style?.getStrumlineOffsets()[1] ?? 0;
    }
    var endMs:Float = ChartEditorTimeScale.playerViewEnd(visualMs, songMs, downscroll, strumlineOffsetY);

    var width:Float = ChartEditorState.GRID_SIZE * ChartEditorState.STRUMLINE_SIZE;
    var left:Float = (state.gridTiledSprite?.x ?? ChartEditorState.GRID_X_POS) + width;
    var top:Float = (Math.abs(visualMs - songMs) > 0.5) ? ChartEditorTimeScale.msToPixels(visualMs) - state.scrollPositionInPixels
      + ChartEditorState.GRID_INITIAL_Y_POS : state.playheadPositionInPixels + ChartEditorState.GRID_INITIAL_Y_POS;
    var cutoff:Float = ChartEditorTimeScale.msToPixels(Math.max(0, endMs)) - state.scrollPositionInPixels + ChartEditorState.GRID_INITIAL_Y_POS;
    sprite.setPosition(left, top);
    sprite.offset.set(0, 0);
    sprite.scale.set(width, Math.max(1, cutoff - top));
    edge.visible = cutoff < FlxG.height;
    edge.setPosition(left, cutoff - 1);
    edge.offset.set(0, 0);
    edge.scale.set(width, 2);
  }

  public static function startAudioPlayback(state:ChartEditorState):Void
  {
    if (state.audioInstTrack == null && state.audioVocalTrackGroup.length == 0) return;

    // Don't allow the audio to be played while we're dragging any of the playheads
    if (state.playbarHeadDragging || state.gridPlayheadScrollAreaPressed || state.notePreviewPlayHeadDragging) return;
    state.stopWelcomeMusic();
    if (state.audioInstTrack != null) state.audioInstTrack.play(false, state.audioInstTrack.time);
    state.audioVocalTrackGroup.play(false, state.audioInstTrack.time);

    state.playbarPlay.text = '||'; // Pause
  }

  /**
   * Play the metronome tick sound.
   * @param high Whether to play the full beat sound rather than the quarter beat sound.
   */
  public static function playMetronomeTick(state:ChartEditorState, high:Bool = false):Void
  {
    state.playSound(Paths.sound('ui/editors/chart-editor/charting-sounds/metronome-${high ? '1' : '2'}').toString(), state.metronomeVolume);
  }

  /**
   * When setting the scroll position, except when automatically scrolling during song playback,
   * we need to update the conductor's current step time and the timestamp of the audio tracks.
   */
  public static function moveSongToScrollPosition(state:ChartEditorState):Void
  {
    // Update the songPosition in the audio tracks.
    if (state.audioInstTrack != null)
    {
      state.audioInstTrack.time = state.scrollPositionInMs + state.playheadPositionInMs - Conductor.instance.instrumentalOffset;
      // Update the songPosition in the Conductor.
      state.updateSongTime();
      state.audioVocalTrackGroup.time = state.audioInstTrack.time;
    }

    // We need to update the note sprites because we changed the scroll position.
    state.noteDisplayDirty = true;
  }

  public static function moveScrollPositionToSong(state:ChartEditorState):Void
  {
    state.scrollPositionInPixels = ChartEditorTimeScale.stepToPixels(Conductor.instance.currentStepTime + Conductor.instance.instrumentalOffsetSteps) - state.playheadPositionInPixels;
    state.currentScrollEase = state.scrollPositionInPixels;
  }

  /**
   * Smoothly ease the song to a new scroll position over a duration.
   * @param targetScrollPosition The target position in the song, in pixels.
   */
  public static function easeSongToScrollPosition(state:ChartEditorState, targetScrollPosition:Float):Void
  {
    state.currentScrollEase = Math.max(0, targetScrollPosition);
    state.currentScrollEase = Math.min(state.currentScrollEase, state.songLengthInPixels);
    state.scrollPositionInPixels = MathUtil.snap(
      MathUtil.smoothLerpPrecision(state.scrollPositionInPixels, state.currentScrollEase, FlxG.elapsed, ChartEditorState.SCROLL_EASE_DURATION, 1 / 1000),
      state.currentScrollEase,
      1 / 1000
    );
    state.moveSongToScrollPosition();
  }

  /**
   * Smoothly ease the song to a new song time in milliseconds.
   * @param songTimeMs The target song time in milliseconds.
   */
  public static function easeToSongTimeMs(state:ChartEditorState, songTimeMs:Float):Void
  {
    state.easeSongToScrollPosition(ChartEditorTimeScale.msToPixels(songTimeMs));
  }

  /**
   * The song time shown while playing, moved forward every frame instead of only when the audio reports a new position.
   */
  static var smoothSongTime:Float = 0;

  /**
   * Updates the Conductor instance and checkes for time signature changes.
   */
  static var smoothSongTimeTicks:Float = -1;

  /**
   * Further apart than this, in milliseconds, the shown time jumps to the audio's time, like after seeking.
   */
  static final SMOOTH_SONG_TIME_SNAP_MS:Float = 100;

  /**
   * How much of the gap to the audio's time is closed each frame.
   */
  static final SMOOTH_SONG_TIME_CORRECTION:Float = 0.1;

  /**
   * The song time to show.
   */
  static function smoothedSongTime(state:ChartEditorState):Float
  {
    var audioTime:Float = state.audioInstTrack.time;
    if (!state.audioInstTrack.isPlaying)
    {
      smoothSongTime = audioTime;
      return audioTime;
    }

    if (FlxG.game.ticks == smoothSongTimeTicks) return smoothSongTime;
    smoothSongTimeTicks = FlxG.game.ticks;

    var predicted:Float = smoothSongTime + FlxG.elapsed * Constants.MS_PER_SEC * state.audioInstTrack.pitch;
    var gap:Float = audioTime - predicted;
    if (Math.abs(gap) > SMOOTH_SONG_TIME_SNAP_MS) smoothSongTime = audioTime;
    else
      smoothSongTime = Math.max(smoothSongTime, predicted + gap * SMOOTH_SONG_TIME_CORRECTION);
    return smoothSongTime;
  }

  public static function updateSongTime(state:ChartEditorState):Void
  {
    var oldTimeSignatureNum:Int = Conductor.instance.timeSignatureNumerator;
    var oldTimeSignatureDen:Int = Conductor.instance.timeSignatureDenominator;
    Conductor.instance.update(smoothedSongTime(state), false);
    if (Conductor.instance.timeSignatureNumerator != oldTimeSignatureNum || Conductor.instance.timeSignatureDenominator != oldTimeSignatureDen)
    {
      state.updateTimeSignature();
    }
  }

  /**
   * Rebuilds the grid lines and measure numbers after the time signature or a time change was modified.
   */
  public static function updateTimeSignature(state:ChartEditorState):Void
  {
    state.gridLinesDirty = true;
    state.measureTicks?.updateMeasureNumbers(true);
  }

  /**
   * Tick the metronome when playback crosses a beat (chart time).
   */
  static function handleMetronome(state:ChartEditorState, oldSongPosition:Float, newSongPosition:Float):Void
  {
    if (state.metronomeVolume <= 0.0 || state.metronomeMuted || state.isPlaytesting) return;
    if (newSongPosition <= oldSongPosition || newSongPosition < 0) return;
    var oldBeat:Int = Math.floor(Conductor.instance.getTimeInSteps(Math.max(0, oldSongPosition)) / Constants.STEPS_PER_BEAT);
    var newBeat:Int = Math.floor(Conductor.instance.getTimeInSteps(newSongPosition) / Constants.STEPS_PER_BEAT);
    if (oldSongPosition >= 0 && newBeat <= oldBeat) return;
    var measure:Float = Conductor.instance.getTimeInMeasures(Conductor.instance.getBeatTimeInMs(newBeat));
    state.playMetronomeTick(Math.abs(measure - Math.round(measure)) < 0.01);
  }

  public static function handleMusicPositionUpdate(state:ChartEditorState, oldSongPosition:Float, newSongPosition:Float):Void
  {
    handleMetronome(state, oldSongPosition, newSongPosition);
    state._currentEvents = SongDataUtils.getEventsInTimeRange(state.currentSongChartEventData, oldSongPosition, newSongPosition);
    state._allowedEvents = SongDataUtils.getEventsWithKind(state._currentEvents, ChartEditorState._allowedEventsNames);

    // Assume notes are sorted by time.
    var notes:Array<SongNoteData> = state.currentSongChartNoteData;
    var low:Int = 0;
    var high:Int = notes.length;
    while (low < high)
    {
      var mid:Int = (low + high) >> 1;
      if (notes[mid].time < oldSongPosition) low = mid + 1;
      else
        high = mid;
    }
    for (noteIndex in low...notes.length)
    {
      var noteData:SongNoteData = notes[noteIndex];
      // Check for notes between the old and new song positions.

      if (noteData.time < oldSongPosition) // Note is in the past.
        continue;

      if (noteData.time > newSongPosition) break;

      /**
       * We hit a note.
       * We're gonna create scripted event and dispatch it all over the Chart Editor.
       */
      if (state._scriptNoteObj == null) state._scriptNoteObj = new NoteSprite(NoteStyleRegistry.instance.fetchDefault());
      state._scriptNoteObj.noteData = noteData;
      state._scriptNoteObj.kill();
      state._scriptNoteObj.direction = state._scriptNoteObj.noteData?.getDirection() ?? 0;
      state._scriptNoteObj.scrollFactor.set();

      var event = HitNoteScriptEvent.get(state._scriptNoteObj, 0.0, 0, (noteData.getStrumlineIndex() == 0 ? 'perfect' : 'sick'), false, 0);
      state.dispatchEvent(event, false);

      // Calling event.cancelEvent() skips all the other logic! Neat!
      if (event.eventCanceled)
      {
        state._scriptNoteObj = null;
        event.finish();

        continue;
      }

      // Hitsounds.
      if (state.hitsoundsEnabled)
      {
        switch (noteData.getStrumlineIndex())
        {
          case 0: // Player
            if (state.hitsoundVolumePlayer > 0) state.playSound(
              Paths.sound('ui/editors/chart-editor/charting-sounds/hitsound-player').toString(),
              state.hitsoundVolumePlayer
            );
          case 1: // Opponent
            if (state.hitsoundVolumeOpponent > 0) state.playSound(
              Paths.sound('ui/editors/chart-editor/charting-sounds/hitsound-opponent').toString(),
              state.hitsoundVolumeOpponent
            );
        }
      }

      event.finish();
    }

    for (data in state._allowedEvents)
    {
      switch (data.eventKind)
      {
        case 'PlayAnimation':
          switch (data.getString('target').toLowerCase().trim())
          {
            case 'boyfriend' | 'bf' | 'player':
              state._eventTarget = state.currentPlayerCharacterPlayer;
            case 'dad' | 'opponent':
              state._eventTarget = state.currentOpponentCharacterPlayer;
          }
          if (state._eventTarget != null) state._eventTarget.playAnimManually(data.getString('anim') ?? 'idle', data.getBool('force') ?? false);

        case 'SetTargetBopSpeed':
          switch (data.getString('target').toLowerCase().trim())
          {
            case 'boyfriend' | 'bf' | 'player':
              state._eventTarget = state.currentPlayerCharacterPlayer;
            case 'dad' | 'opponent':
              state._eventTarget = state.currentOpponentCharacterPlayer;
          }
          if (state._eventTarget != null) state._eventTarget.setBopSpeed(data.getFloat('rate') ?? Constants.DEFAULT_PROP_RATE);
      }
    }

    state._currentEvents = null;
    state._allowedEvents.resize(0);
    state._eventTarget = null;
  }

  /**
   * Stop playback of the chart's instrumental and vocals.
   * @param welcomeMusic If `true`, queue the welcome music to play after a timeout. `false` to force the welcome music to stop too.
   */
  public static function stopAudioPlayback(state:ChartEditorState, welcomeMusic:Bool = true):Void
  {
    if (state.audioInstTrack == null && state.audioVocalTrackGroup.length == 0) return;

    if (state.audioInstTrack != null) state.audioInstTrack.pause();
    state.audioVocalTrackGroup.pause();

    if (welcomeMusic)
    {
      state.fadeInWelcomeMusic(ChartEditorState.WELCOME_MUSIC_FADE_IN_DELAY, ChartEditorState.WELCOME_MUSIC_FADE_IN_DURATION);
    }
    else
    {
      // Force the welcome music to stop too.
      state.stopWelcomeMusic();
    }

    state.playbarPlay.text = '>';
  }

  public static function toggleAudioPlayback(state:ChartEditorState):Void
  {
    if (state.audioInstTrack == null && state.audioVocalTrackGroup.length == 0) return;

    state.currentScrollEase = state.scrollPositionInPixels;

    if (state.audioInstTrack.isPlaying || state.audioVocalTrackGroup.playing)
    {
      // Pause
      state.stopAudioPlayback();
    }
    else
    {
      // Don't allow the audio to be played while we're dragging any of the playheads
      if (state.playbarHeadDragging || state.gridPlayheadScrollAreaPressed || state.notePreviewPlayHeadDragging) return;
      // Play
      state.startAudioPlayback();
    }
  }

  public static function scrollMouseToGrid(state:ChartEditorState, speed:Float = 0.5):Void
  {
    // Scroll the screen if the mouse is above or below the grid.
    if (FlxG.mouse.viewY < ChartEditorState.MENU_BAR_HEIGHT)
    {
      // Scroll up.
      var diff:Float = ChartEditorState.MENU_BAR_HEIGHT - FlxG.mouse.viewY;
      state.currentScrollEase -= diff * speed; // Too fast!
    }
    else if (FlxG.mouse.viewY > (state.playbarHeadLayout?.y ?? 0.0))
    {
      // Scroll down.
      var diff:Float = FlxG.mouse.viewY - (state.playbarHeadLayout?.y ?? 0.0);
      state.currentScrollEase += (diff * speed); // Too fast!
    }
  }
}
#end
