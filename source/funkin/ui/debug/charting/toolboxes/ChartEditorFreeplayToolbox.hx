package funkin.ui.debug.charting.toolboxes;

import flixel.addons.display.FlxTiledSprite;
import flixel.math.FlxMath;
import funkin.audio.SoundGroup;
import funkin.ui.debug.charting.commands.SetFreeplayPreviewCommand;
import funkin.ui.haxeui.components.WaveformPlayer;
import funkin.ui.freeplay.FreeplayState;
import haxe.ui.backend.flixel.components.SpriteWrapper;
import haxe.ui.components.Button;
import haxe.ui.components.Label;
import haxe.ui.components.NumberStepper;
import haxe.ui.containers.Absolute;
import haxe.ui.containers.ScrollView;
import haxe.ui.core.Screen;
import haxe.ui.events.MouseEvent;
import haxe.ui.events.UIEvent;

/**
 * The toolbox which allows modifying information like Song Title, Scroll Speed, Characters/Stages, and starting BPM.
 */
// @:nullSafety // TODO: Fix null safety when used with HaxeUI build macros.
@:access(funkin.ui.debug.charting.ChartEditorState)
@:build(haxe.ui.ComponentBuilder.build("assets/exclude/data/ui/chart-editor/toolboxes/freeplay.xml"))
class ChartEditorFreeplayToolbox extends ChartEditorBaseToolbox
{
  var waveformContainer:Absolute;
  var waveformScrollview:ScrollView;
  var waveformMusic:WaveformPlayer;
  var freeplayButtonZoomIn:Button;
  var freeplayButtonZoomOut:Button;
  var freeplayButtonPause:Button;
  var freeplayButtonPlay:Button;
  var freeplayButtonStop:Button;
  var freeplayPreviewStart:NumberStepper;
  var freeplayPreviewEnd:NumberStepper;
  var freeplayTicksContainer:Absolute;
  var playheadSprite:SpriteWrapper;
  var previewSelectionSprite:SpriteWrapper;

  static final TICK_LABEL_X_OFFSET:Float = 4.0;

  static final PLAYHEAD_RIGHT_PAD:Float = 10.0;

  static final BASE_SCALE:Float = 64.0;
  static final STARTING_SCALE:Float = 1024.0;
  static final MIN_SCALE:Float = 4.0;
  static final WAVEFORM_ZOOM_MULT:Float = 1.5;

  static final MAGIC_SCALE_BASE_TIME:Float = 5.0;

  var waveformScale:Float = STARTING_SCALE;

  var playheadAbsolutePos(get, set):Float;

  function get_playheadAbsolutePos():Float
  {
    return playheadSprite.left;
  }

  function set_playheadAbsolutePos(value:Float):Float
  {
    return playheadSprite.left = value;
  }

  var playheadRelativePos(get, set):Float;

  function get_playheadRelativePos():Float
  {
    return playheadSprite.left - waveformScrollview.hscrollPos;
  }

  function set_playheadRelativePos(value:Float):Float
  {
    return playheadSprite.left = waveformScrollview.hscrollPos + value;
  }

  var previewBoxStartPosAbsolute(get, set):Float;

  function get_previewBoxStartPosAbsolute():Float
  {
    return previewSelectionSprite.left;
  }

  function set_previewBoxStartPosAbsolute(value:Float):Float
  {
    return previewSelectionSprite.left = value;
  }

  var previewBoxEndPosAbsolute(get, set):Float;

  function get_previewBoxEndPosAbsolute():Float
  {
    return previewSelectionSprite.left + previewSelectionSprite.width;
  }

  function set_previewBoxEndPosAbsolute(value:Float):Float
  {
    if (value < previewBoxStartPosAbsolute) return previewSelectionSprite.left = previewBoxStartPosAbsolute;
    return previewSelectionSprite.width = value - previewBoxStartPosAbsolute;
  }

  var previewBoxStartPosRelative(get, set):Float;

  function get_previewBoxStartPosRelative():Float
  {
    return previewSelectionSprite.left - waveformScrollview.hscrollPos;
  }

  function set_previewBoxStartPosRelative(value:Float):Float
  {
    return previewSelectionSprite.left = waveformScrollview.hscrollPos + value;
  }

  var previewBoxEndPosRelative(get, set):Float;

  function get_previewBoxEndPosRelative():Float
  {
    return previewSelectionSprite.left + previewSelectionSprite.width - waveformScrollview.hscrollPos;
  }

  function set_previewBoxEndPosRelative(value:Float):Float
  {
    if (value < previewBoxStartPosRelative) return previewSelectionSprite.left = previewBoxStartPosRelative;
    return previewSelectionSprite.width = value - previewBoxStartPosRelative;
  }

  /**
   * The amount you need to multiply the zoom by such that, at the base zoom level, one tick is equal to `MAGIC_SCALE_BASE_TIME` seconds.
   */
  var waveformMagicFactor:Float = 1.0;

  var audioPreviewTracks:SoundGroup;

  var tickTiledSprite:FlxTiledSprite;

  var freeplayPreviewVolume(get, null):Float;

  function get_freeplayPreviewVolume():Float
  {
    return freeplayMusicVolume.value * 2 / 100;
  }

  var tickLabels:Array<Label> = [];

  public function new(chartEditorState2:ChartEditorState)
  {
    super(chartEditorState2);

    initialize();

    this.onDialogClosed = onClose;
  }

  function onClose(event:UIEvent)
  {
    chartEditorState.menubarItemToggleToolboxFreeplay.selected = false;
  }

  function initialize():Void
  {
    // Starting position.
    // TODO: Save and load this.
    this.x = 150;
    this.y = 250;

    freeplayMusicVolume.onChange = (_) -> {
      setTrackVolume(freeplayPreviewVolume);
    };
    freeplayMusicMute.onClick = (_) -> {
      toggleMuteTrack();
    };
    freeplayButtonZoomIn.onClick = (_) -> {
      zoomWaveformIn();
    };
    freeplayButtonZoomOut.onClick = (_) -> {
      zoomWaveformOut();
    };
    freeplayButtonPause.onClick = (_) -> {
      pauseAudioPreview();
    };
    freeplayButtonPlay.onClick = (_) -> {
      playAudioPreview();
    };
    freeplayButtonStop.onClick = (_) -> {
      stopAudioPreview();
    };
    testPreview.onClick = (_) -> {
      performPreview();
    };
    freeplayPreviewStart.onChange = (event:UIEvent) -> {
      if (event.value == chartEditorState.currentSongFreeplayPreviewStart) return;
      if (waveformDragStartPos != null) return; // The values are changing because we are dragging the preview.

      chartEditorState.performCommand(new SetFreeplayPreviewCommand(event.value, null));
      refresh();
    }
    freeplayPreviewEnd.onChange = (event:UIEvent) -> {
      if (event.value == chartEditorState.currentSongFreeplayPreviewEnd) return;
      if (waveformDragStartPos != null) return; // The values are changing because we are dragging the preview.

      chartEditorState.performCommand(new SetFreeplayPreviewCommand(null, event.value));
      refresh();
    }
    waveformScrollview.onScroll = (_) -> {
      if (!audioPreviewTracks.playing)
      {
        // Move the playhead if it would go out of view.
        var prevPlayheadRelativePos = playheadRelativePos;
        playheadRelativePos = FlxMath.bound(playheadRelativePos, 0, waveformScrollview.width - PLAYHEAD_RIGHT_PAD);
        trace('newPos: ${playheadRelativePos}');
        var diff = playheadRelativePos - prevPlayheadRelativePos;

        if (diff != 0)
        {
          // We have to change the song time to match the playhead position when we move it.
          var currentWaveformIndex:Int = Std.int(playheadAbsolutePos * (waveformScale / BASE_SCALE * waveformMagicFactor));
          var targetSongTimeSeconds:Float = waveformMusic.waveform.waveformData.indexToSeconds(currentWaveformIndex);
          audioPreviewTracks.time = targetSongTimeSeconds * Constants.MS_PER_SEC;
        }

        addOffsetsToAudioPreview();
      }
      else
      {
        // The scrollview probably changed because the song position changed.
        // If we try to move the song now it will glitch.
      }

      // Either way, clipRect has changed, so we need to refresh the waveforms.
      refresh();
    };

    initializeTicks();

    refreshAudioPreview();
    refresh();
    refreshTicks();

    waveformMusic.registerEvent(MouseEvent.MOUSE_DOWN, (_) -> {
      onStartDragWaveform();
    });

    freeplayTicksContainer.registerEvent(MouseEvent.MOUSE_DOWN, (_) -> {
      onStartDragPlayhead();
    });
  }

  function initializeTicks():Void
  {
    tickTiledSprite = new FlxTiledSprite(chartEditorState.offsetTickBitmap, 100, chartEditorState.offsetTickBitmap.height, true, false);
    freeplayTicksSprite.sprite = tickTiledSprite;
    tickTiledSprite.width = 5000;
  }

  /**
   * Pull the audio tracks from the chart editor state and create copies of them to play in the Offsets Toolbox.
   * These must be DEEP CLONES or else the editor will affect the audio preview!
   */
  public function refreshAudioPreview():Void
  {
    if (audioPreviewTracks == null)
    {
      audioPreviewTracks = new SoundGroup();
      // Make sure audioPreviewTracks (and all its children) receives update() calls.
      chartEditorState.add(audioPreviewTracks);
    }
    else
    {
      audioPreviewTracks.stop();
      audioPreviewTracks.clear();
    }

    var instTrack = chartEditorState.audioInstTrack.clone();
    audioPreviewTracks.add(instTrack);

    var playerVoice = chartEditorState.audioVocalTrackGroup.getPlayerVoice();
    if (playerVoice != null) audioPreviewTracks.add(playerVoice.clone());

    var opponentVoice = chartEditorState.audioVocalTrackGroup.getOpponentVoice();
    if (opponentVoice != null) audioPreviewTracks.add(opponentVoice.clone());

    // Build player waveform.
    // waveformMusic.waveform.forceUpdate = true;
    var waveformData1 = playerVoice?.waveformData;
    var waveformData2 = opponentVoice?.waveformData ?? playerVoice?.waveformData; // this null check is for songs that only have 1 vocals file!
    var waveformData3 = chartEditorState.audioInstTrack.waveformData;
    var waveformData = waveformData3.merge(waveformData1).merge(waveformData2);

    waveformMusic.waveform.waveformData = waveformData;
    // Set the width and duration to render the full waveform, with the clipRect applied we only render a segment of it.
    waveformMusic.waveform.duration = instTrack.length / Constants.MS_PER_SEC;

    addOffsetsToAudioPreview();
  }

  public function refreshTicks():Void
  {
    while (tickLabels.length > 0)
    {
      var label = tickLabels.pop();
      freeplayTicksContainer.removeComponent(label);
    }

    var labelYPos:Float = chartEditorState.offsetTickBitmap.height / 2;
    var labelHeight:Float = chartEditorState.offsetTickBitmap.height / 2;

    var numberOfTicks:Int = Math.floor(waveformMusic.waveform.width / chartEditorState.offsetTickBitmap.width * 2) + 1;

    for (index in 0...numberOfTicks)
    {
      var tickPos = chartEditorState.offsetTickBitmap.width / 2 * index;
      var tickTime = tickPos * (waveformScale / BASE_SCALE * waveformMagicFactor) / waveformMusic.waveform.waveformData.pointsPerSecond();

      var tickLabel:Label = new Label();
      tickLabel.text = formatTime(tickTime);
      tickLabel.styleNames = "offset-ticks-label";
      tickLabel.height = labelHeight;
      // Positioning within offsetTicksContainer is absolute (relative to the container itself).
      tickLabel.top = labelYPos;
      tickLabel.left = tickPos + TICK_LABEL_X_OFFSET;

      freeplayTicksContainer.addComponent(tickLabel);
      tickLabels.push(tickLabel);
    }
  }

  function formatTime(seconds:Float):String
  {
    if (seconds <= 0) return "0.0";

    var integerSeconds = Math.floor(seconds);
    var decimalSeconds = Math.floor((seconds - integerSeconds) * 10);

    if (integerSeconds < 60)
    {
      return '${integerSeconds}.${decimalSeconds}';
    }
    else
    {
      var integerMinutes = Math.floor(integerSeconds / 60);
      var remainingSeconds = integerSeconds % 60;
      var remainingSecondsPad:String = remainingSeconds < 10 ? '0$remainingSeconds' : '$remainingSeconds';

      return '${integerMinutes}:${remainingSecondsPad}${decimalSeconds > 0 ? '.$decimalSeconds' : ''}';
    }
  }

  function buildTickLabel():Void {}

  public function onStartDragPlayhead():Void
  {
    Screen.instance.registerEvent(MouseEvent.MOUSE_MOVE, onDragPlayhead);
    Screen.instance.registerEvent(MouseEvent.MOUSE_UP, onStopDragPlayhead);

    movePlayheadToMouse();
  }

  public function onDragPlayhead(event:MouseEvent):Void
  {
    movePlayheadToMouse();
  }

  public function onStopDragPlayhead(event:MouseEvent):Void
  {
    // Stop dragging.
    Screen.instance.unregisterEvent(MouseEvent.MOUSE_MOVE, onDragPlayhead);
    Screen.instance.unregisterEvent(MouseEvent.MOUSE_UP, onStopDragPlayhead);
  }

  function movePlayheadToMouse():Void
  {
    // Determine the position of the mouse relative to the
    var mouseXPos = FlxG.mouse.x;

    var relativeMouseXPos = mouseXPos - waveformScrollview.cachedScreenX;
    var targetPlayheadPos = relativeMouseXPos + waveformScrollview.hscrollPos;

    // Move the playhead to the mouse position.
    playheadAbsolutePos = targetPlayheadPos;

    // Move the audio preview to the playhead position.
    var currentWaveformIndex:Int = Std.int(playheadAbsolutePos * (waveformScale / BASE_SCALE * waveformMagicFactor));
    var targetSongTimeSeconds:Float = waveformMusic.waveform.waveformData.indexToSeconds(currentWaveformIndex);
    audioPreviewTracks.time = targetSongTimeSeconds * Constants.MS_PER_SEC;
  }

  var waveformDragStartPos:Null<Float> = null;

  var waveformDragPreviewStartPos:Float;
  var waveformDragPreviewEndPos:Float;

  public function onStartDragWaveform():Void
  {
    waveformDragStartPos = FlxG.mouse.x;

    Screen.instance.registerEvent(MouseEvent.MOUSE_MOVE, onDragWaveform);
    Screen.instance.registerEvent(MouseEvent.MOUSE_UP, onStopDragWaveform);
  }

  public function onDragWaveform(event:MouseEvent):Void
  {
    // Set waveformDragPreviewStartPos and waveformDragPreviewEndPos to the position the drag started and the current mouse position.
    // This only affects the visuals.

    var currentAbsMousePos = FlxG.mouse.x;
    var dragDiff = currentAbsMousePos - waveformDragStartPos;

    var currentRelativeMousePos = currentAbsMousePos - waveformScrollview.cachedScreenX;
    var relativeStartPos = waveformDragStartPos - waveformScrollview.cachedScreenX;

    var isDraggingRight = dragDiff > 0;
    var hasDraggedEnough = Math.abs(dragDiff) > 10;

    if (hasDraggedEnough)
    {
      if (isDraggingRight)
      {
        waveformDragPreviewStartPos = relativeStartPos;
        waveformDragPreviewEndPos = currentRelativeMousePos;
      }
      else
      {
        waveformDragPreviewStartPos = currentRelativeMousePos;
        waveformDragPreviewEndPos = relativeStartPos;
      }
    }

    refresh();
  }

  public function onStopDragWaveform(event:MouseEvent):Void
  {
    Screen.instance.unregisterEvent(MouseEvent.MOUSE_MOVE, onDragWaveform);
    Screen.instance.unregisterEvent(MouseEvent.MOUSE_UP, onStopDragWaveform);

    var previewStartPosAbsolute = waveformDragPreviewStartPos + waveformScrollview.hscrollPos;
    var previewStartPosIndex:Int = Std.int(previewStartPosAbsolute * (waveformScale / BASE_SCALE * waveformMagicFactor));
    var previewStartPosMs:Int = Std.int(waveformMusic.waveform.waveformData.indexToSeconds(previewStartPosIndex) * Constants.MS_PER_SEC);

    var previewEndPosAbsolute = waveformDragPreviewEndPos + waveformScrollview.hscrollPos;
    var previewEndPosIndex:Int = Std.int(previewEndPosAbsolute * (waveformScale / BASE_SCALE * waveformMagicFactor));
    var previewEndPosMs:Int = Std.int(waveformMusic.waveform.waveformData.indexToSeconds(previewEndPosIndex) * Constants.MS_PER_SEC);

    chartEditorState.performCommand(new SetFreeplayPreviewCommand(previewStartPosMs, previewEndPosMs));

    waveformDragStartPos = null;
    waveformDragPreviewStartPos = 0;
    waveformDragPreviewEndPos = 0;

    refresh();
    addOffsetsToAudioPreview();
  }

  public function playAudioPreview():Void
  {
    if (isPerformingPreview) stopPerformingPreview();

    audioPreviewTracks.volume = freeplayPreviewVolume;
    audioPreviewTracks.play(false, audioPreviewTracks.time);
  }

  public function addOffsetsToAudioPreview():Void
  {
    var trackInst = audioPreviewTracks.members[0];
    if (trackInst != null)
    {
      trackInst.time -= chartEditorState.currentInstrumentalOffset;
    }

    var trackPlayer = audioPreviewTracks.members[1];
    if (trackPlayer != null)
    {
      trackPlayer.time -= chartEditorState.currentVocalOffsetPlayer;
    }

    var trackOpponent = audioPreviewTracks.members[2];
    if (trackOpponent != null)
    {
      trackOpponent.time -= chartEditorState.currentVocalOffsetOpponent;
    }
  }

  public function pauseAudioPreview():Void
  {
    if (isPerformingPreview) stopPerformingPreview();

    audioPreviewTracks.pause();
  }

  public function stopAudioPreview():Void
  {
    if (isPerformingPreview) stopPerformingPreview();

    audioPreviewTracks.stop();

    audioPreviewTracks.time = 0;

    waveformScrollview.hscrollPos = 0;
    playheadAbsolutePos = 0 + playheadSprite.width;
    refresh();
    addOffsetsToAudioPreview();
  }

  public function zoomWaveformIn():Void
  {
    if (isPerformingPreview) stopPerformingPreview();

    if (waveformScale > MIN_SCALE)
    {
      waveformScale = waveformScale / WAVEFORM_ZOOM_MULT;
      if (waveformScale < MIN_SCALE) waveformScale = MIN_SCALE;

      trace('Zooming in, scale: ${waveformScale}');

      // Update the playhead too!
      playheadAbsolutePos = playheadAbsolutePos * WAVEFORM_ZOOM_MULT;

      // Recenter the scroll view on the playhead.
      var vaguelyCenterPlayheadOffset = waveformScrollview.width / 8;
      waveformScrollview.hscrollPos = playheadAbsolutePos - vaguelyCenterPlayheadOffset;

      refresh();
      refreshTicks();
    }
    else
    {
      waveformScale = MIN_SCALE;
    }
  }

  public function zoomWaveformOut():Void
  {
    waveformScale = waveformScale * WAVEFORM_ZOOM_MULT;
    if (waveformScale < MIN_SCALE) waveformScale = MIN_SCALE;

    trace('Zooming out, scale: ${waveformScale}');

    // Update the playhead too!
    playheadAbsolutePos = playheadAbsolutePos / WAVEFORM_ZOOM_MULT;

    // Recenter the scroll view on the playhead.
    var vaguelyCenterPlayheadOffset = waveformScrollview.width / 8;
    waveformScrollview.hscrollPos = playheadAbsolutePos - vaguelyCenterPlayheadOffset;

    refresh();
    refreshTicks();
  }

  public function setTrackVolume(volume:Float):Void
  {
    audioPreviewTracks.volume = volume;
  }

  public function muteTrack():Void
  {
    audioPreviewTracks.muted = true;
  }

  public function unmuteTrack():Void
  {
    audioPreviewTracks.muted = false;
  }

  public function toggleMuteTrack():Void
  {
    audioPreviewTracks.muted = !audioPreviewTracks.muted;
  }

  var isPerformingPreview:Bool = false;
  var isFadingOutPreview:Bool = false;

  public function performPreview():Void
  {
    isPerformingPreview = true;
    isFadingOutPreview = false;
    audioPreviewTracks.play(true, chartEditorState.currentSongFreeplayPreviewStart);
    audioPreviewTracks.fadeIn(FreeplayState.FADE_IN_DURATION, FreeplayState.FADE_IN_START_VOLUME * freeplayPreviewVolume,
      FreeplayState.FADE_IN_END_VOLUME * freeplayPreviewVolume, null);
  }

  public function stopPerformingPreview():Void
  {
    isPerformingPreview = false;
    isFadingOutPreview = false;
    audioPreviewTracks.volume = freeplayPreviewVolume;
    audioPreviewTracks.pause();
  }

  public override function update(elapsed:Float)
  {
    super.update(elapsed);

    if (isPerformingPreview && !audioPreviewTracks.playing)
    {
      stopPerformingPreview();
    }

    if (isPerformingPreview && audioPreviewTracks.playing)
    {
      var startFadeOutTime = chartEditorState.currentSongFreeplayPreviewEnd - (FreeplayState.FADE_OUT_DURATION * Constants.MS_PER_SEC);
      trace('startFadeOutTime: ${audioPreviewTracks.time} >= ${startFadeOutTime}');
      if (!isFadingOutPreview && audioPreviewTracks.time >= startFadeOutTime)
      {
        isFadingOutPreview = true;
        audioPreviewTracks.fadeOut(FreeplayState.FADE_OUT_DURATION, FreeplayState.FADE_OUT_END_VOLUME * freeplayPreviewVolume, (_) -> {
          trace('Stop performing preview! ${audioPreviewTracks.time}');
          stopPerformingPreview();
        });
      }
    }

    if (audioPreviewTracks.playing)
    {
      var targetScrollPos:Float = waveformMusic.waveform.waveformData.secondsToIndex(audioPreviewTracks.time / Constants.MS_PER_SEC) / (waveformScale / BASE_SCALE * waveformMagicFactor);
      // waveformScrollview.hscrollPos = targetScrollPos;
      var prevPlayheadAbsolutePos = playheadAbsolutePos;
      playheadAbsolutePos = targetScrollPos;
      var playheadDiff = playheadAbsolutePos - prevPlayheadAbsolutePos;

      // BEHAVIOR C.
      // Copy Audacity!
      // If the playhead is out of view, jump forward or backward by one screen width until it's in view.
      if (playheadAbsolutePos < waveformScrollview.hscrollPos)
      {
        waveformScrollview.hscrollPos -= waveformScrollview.width;
      }
      if (playheadAbsolutePos > waveformScrollview.hscrollPos + waveformScrollview.width)
      {
        waveformScrollview.hscrollPos += waveformScrollview.width;
      }
    }
    freeplayLabelTime.text = formatTime(audioPreviewTracks.time / Constants.MS_PER_SEC);
    if (waveformDragStartPos != null && (waveformDragPreviewStartPos > 0 && waveformDragPreviewEndPos > 0))
    {
      var previewStartPosAbsolute = waveformDragPreviewStartPos + waveformScrollview.hscrollPos;
      var previewStartPosIndex:Int = Std.int(previewStartPosAbsolute * (waveformScale / BASE_SCALE * waveformMagicFactor));
      var previewStartPosMs:Int = Std.int(waveformMusic.waveform.waveformData.indexToSeconds(previewStartPosIndex) * Constants.MS_PER_SEC);

      var previewEndPosAbsolute = waveformDragPreviewEndPos + waveformScrollview.hscrollPos;
      var previewEndPosIndex:Int = Std.int(previewEndPosAbsolute * (waveformScale / BASE_SCALE * waveformMagicFactor));
      var previewEndPosMs:Int = Std.int(waveformMusic.waveform.waveformData.indexToSeconds(previewEndPosIndex) * Constants.MS_PER_SEC);

      // Set the values in milliseconds.
      freeplayPreviewStart.value = previewStartPosMs;
      freeplayPreviewEnd.value = previewEndPosMs;

      previewBoxStartPosAbsolute = previewStartPosAbsolute;
      previewBoxEndPosAbsolute = previewEndPosAbsolute;
    }
    else
    {
      previewBoxStartPosAbsolute = waveformMusic.waveform.waveformData.secondsToIndex(chartEditorState.currentSongFreeplayPreviewStart / Constants.MS_PER_SEC) / (waveformScale / BASE_SCALE * waveformMagicFactor);
      previewBoxEndPosAbsolute = waveformMusic.waveform.waveformData.secondsToIndex(chartEditorState.currentSongFreeplayPreviewEnd / Constants.MS_PER_SEC) / (waveformScale / BASE_SCALE * waveformMagicFactor);

      freeplayPreviewStart.value = chartEditorState.currentSongFreeplayPreviewStart;
      freeplayPreviewEnd.value = chartEditorState.currentSongFreeplayPreviewEnd;
    }
  }

  public override function refresh():Void
  {
    super.refresh();

    waveformMagicFactor = MAGIC_SCALE_BASE_TIME / (chartEditorState.offsetTickBitmap.width / waveformMusic.waveform.waveformData.pointsPerSecond());

    var currentZoomFactor = waveformScale / BASE_SCALE * waveformMagicFactor;

    var maxWidth:Int = -1;

    waveformMusic.waveform.time = -chartEditorState.currentInstrumentalOffset / Constants.MS_PER_SEC;
    waveformMusic.waveform.width = (waveformMusic.waveform.waveformData?.length ?? 1000) / currentZoomFactor;
    if (waveformMusic.waveform.width > maxWidth) maxWidth = Std.int(waveformMusic.waveform.width);
    waveformMusic.waveform.height = 65;
    waveformMusic.waveform.markDirty();

    waveformContainer.width = maxWidth;
    tickTiledSprite.width = maxWidth;
  }

  public static function build(chartEditorState:ChartEditorState):ChartEditorFreeplayToolbox
  {
    return new ChartEditorFreeplayToolbox(chartEditorState);
  }
}
