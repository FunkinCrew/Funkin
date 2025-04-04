package funkin.ui.debug.charting.toolboxes;

import funkin.audio.SoundGroup;
import haxe.ui.components.Button;
import haxe.ui.components.Label;
import flixel.addons.display.FlxTiledSprite;
import flixel.math.FlxMath;
import haxe.ui.components.NumberStepper;
import haxe.ui.backend.flixel.components.SpriteWrapper;
import funkin.ui.debug.charting.commands.SetAudioOffsetCommand;
import funkin.ui.haxeui.components.WaveformPlayer;
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
@:build(haxe.ui.ComponentBuilder.build("assets/exclude/data/ui/chart-editor/toolboxes/offsets.xml"))
class ChartEditorOffsetsToolbox extends ChartEditorBaseToolbox
{
  var waveformContainer:Absolute;
  var waveformScrollview:ScrollView;
  var waveformPlayer:WaveformPlayer;
  var waveformOpponent:WaveformPlayer;
  var waveformInstrumental:WaveformPlayer;
  var offsetButtonZoomIn:Button;
  var offsetButtonZoomOut:Button;
  var offsetButtonPause:Button;
  var offsetButtonPlay:Button;
  var offsetButtonStop:Button;
  var offsetStepperPlayer:NumberStepper;
  var offsetStepperOpponent:NumberStepper;
  var offsetStepperInstrumental:NumberStepper;
  var offsetTicksContainer:Absolute;
  var playheadSprite:SpriteWrapper;

  static final TICK_LABEL_X_OFFSET:Float = 4.0;

  static final PLAYHEAD_RIGHT_PAD:Float = 10.0;

  static final BASE_SCALE:Float = 64.0;
  static final MIN_SCALE:Float = 4.0;
  static final WAVEFORM_ZOOM_MULT:Float = 1.5;

  static final MAGIC_SCALE_BASE_TIME:Float = 5.0;

  var waveformScale:Float = BASE_SCALE;

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

  /**
   * The amount you need to multiply the zoom by such that, at the base zoom level, one tick is equal to `MAGIC_SCALE_BASE_TIME` seconds.
   */
  var waveformMagicFactor:Float = 1.0;

  var audioPreviewTracks:SoundGroup;

  var tickTiledSprite:FlxTiledSprite;

  var tickLabels:Array<Label> = [];

  // Local store of the audio offsets, so we can detect when they change.
  var audioPreviewPlayerOffset:Float = 0;
  var audioPreviewOpponentOffset:Float = 0;
  var audioPreviewInstrumentalOffset:Float = 0;

  public function new(chartEditorState2:ChartEditorState)
  {
    super(chartEditorState2);

    initialize();

    this.onDialogClosed = onClose;
  }

  function onClose(event:UIEvent)
  {
    chartEditorState.menubarItemToggleToolboxOffsets.selected = false;
  }

  function initialize():Void
  {
    // Starting position.
    // TODO: Save and load this.
    this.x = 150;
    this.y = 250;

    offsetPlayerVolume.onChange = (_) -> {
      var targetVolume = offsetPlayerVolume.value * 2 / 100;
      setTrackVolume(PLAYER, targetVolume);
    };
    offsetPlayerMute.onClick = (_) -> {
      toggleMuteTrack(PLAYER);
    };
    offsetPlayerSolo.onClick = (_) -> {
      soloTrack(PLAYER);
    };
    offsetOpponentVolume.onChange = (_) -> {
      var targetVolume = offsetOpponentVolume.value * 2 / 100;
      setTrackVolume(OPPONENT, targetVolume);
    };
    offsetOpponentMute.onClick = (_) -> {
      toggleMuteTrack(OPPONENT);
    };
    offsetOpponentSolo.onClick = (_) -> {
      soloTrack(OPPONENT);
    };
    offsetInstrumentalVolume.onChange = (_) -> {
      var targetVolume = offsetInstrumentalVolume.value * 2 / 100;
      setTrackVolume(INSTRUMENTAL, targetVolume);
    };
    offsetInstrumentalMute.onClick = (_) -> {
      toggleMuteTrack(INSTRUMENTAL);
    };
    offsetInstrumentalSolo.onClick = (_) -> {
      soloTrack(INSTRUMENTAL);
    };
    offsetButtonZoomIn.onClick = (_) -> {
      zoomWaveformIn();
    };
    offsetButtonZoomOut.onClick = (_) -> {
      zoomWaveformOut();
    };
    offsetButtonPause.onClick = (_) -> {
      pauseAudioPreview();
    };
    offsetButtonPlay.onClick = (_) -> {
      playAudioPreview();
    };
    offsetButtonStop.onClick = (_) -> {
      stopAudioPreview();
    };
    offsetStepperPlayer.onChange = (event:UIEvent) -> {
      if (event.value == chartEditorState.currentVocalOffsetPlayer) return;
      if (dragWaveform != null) return;

      chartEditorState.performCommand(new SetAudioOffsetCommand(PLAYER, event.value));
      refresh();
    }
    offsetStepperOpponent.onChange = (event:UIEvent) -> {
      if (event.value == chartEditorState.currentVocalOffsetOpponent) return;
      if (dragWaveform != null) return;

      chartEditorState.performCommand(new SetAudioOffsetCommand(OPPONENT, event.value));
      refresh();
    }
    offsetStepperInstrumental.onChange = (event:UIEvent) -> {
      if (event.value == chartEditorState.currentInstrumentalOffset) return;
      if (dragWaveform != null) return;

      chartEditorState.performCommand(new SetAudioOffsetCommand(INSTRUMENTAL, event.value));
      refresh();
    }
    waveformScrollview.onScroll = (_) -> {
      if (!audioPreviewTracks.playing)
      {
        // Move the playhead if it would go out of view.
        var prevPlayheadRelativePos = playheadRelativePos;
        playheadRelativePos = FlxMath.bound(playheadRelativePos, 0, waveformScrollview.width - PLAYHEAD_RIGHT_PAD);
        var diff = playheadRelativePos - prevPlayheadRelativePos;

        if (diff != 0)
        {
          // We have to change the song time to match the playhead position when we move it.
          var currentWaveformIndex:Int = Std.int(playheadAbsolutePos * (waveformScale / BASE_SCALE * waveformMagicFactor));
          var targetSongTimeSeconds:Float = waveformPlayer.waveform.waveformData.indexToSeconds(currentWaveformIndex);
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

    waveformPlayer.registerEvent(MouseEvent.MOUSE_DOWN, (_) -> {
      onStartDragWaveform(PLAYER);
    });
    waveformOpponent.registerEvent(MouseEvent.MOUSE_DOWN, (_) -> {
      onStartDragWaveform(OPPONENT);
    });
    waveformInstrumental.registerEvent(MouseEvent.MOUSE_DOWN, (_) -> {
      onStartDragWaveform(INSTRUMENTAL);
    });

    offsetTicksContainer.registerEvent(MouseEvent.MOUSE_DOWN, (_) -> {
      onStartDragPlayhead();
    });
  }

  function initializeTicks():Void
  {
    tickTiledSprite = new FlxTiledSprite(chartEditorState.offsetTickBitmap, 100, chartEditorState.offsetTickBitmap.height, true, false);
    offsetTicksSprite.sprite = tickTiledSprite;
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
    // waveformPlayer.waveform.forceUpdate = true;
    waveformPlayer.waveform.waveformData = playerVoice?.waveformData;
    // Set the width and duration to render the full waveform, with the clipRect applied we only render a segment of it.
    waveformPlayer.waveform.duration = (playerVoice?.length ?? 1000.0) / Constants.MS_PER_SEC;

    // Build opponent waveform.
    // waveformOpponent.waveform.forceUpdate = true;
    // note: if song only has one set of vocals (Vocals.ogg/mp3) then this is null and crashes charting editor
    // so we null check
    waveformOpponent.waveform.waveformData = opponentVoice?.waveformData;
    waveformOpponent.waveform.duration = (opponentVoice?.length ?? 1000.0) / Constants.MS_PER_SEC;

    // Build instrumental waveform.
    // waveformInstrumental.waveform.forceUpdate = true;
    waveformInstrumental.waveform.waveformData = chartEditorState.audioInstTrack.waveformData;
    waveformInstrumental.waveform.duration = (instTrack?.length ?? 1000.0) / Constants.MS_PER_SEC;

    addOffsetsToAudioPreview();
  }

  public function refreshTicks():Void
  {
    while (tickLabels.length > 0)
    {
      var label = tickLabels.pop();
      offsetTicksContainer.removeComponent(label);
    }

    var labelYPos:Float = chartEditorState.offsetTickBitmap.height / 2;
    var labelHeight:Float = chartEditorState.offsetTickBitmap.height / 2;

    var numberOfTicks:Int = Math.floor(waveformInstrumental.waveform.width / chartEditorState.offsetTickBitmap.width * 2) + 1;

    for (index in 0...numberOfTicks)
    {
      var tickPos = chartEditorState.offsetTickBitmap.width / 2 * index;
      var tickTime = tickPos * (waveformScale / BASE_SCALE * waveformMagicFactor) / waveformInstrumental.waveform.waveformData.pointsPerSecond();

      var tickLabel:Label = new Label();
      tickLabel.text = formatTime(tickTime);
      tickLabel.styleNames = "offset-ticks-label";
      tickLabel.height = labelHeight;
      // Positioning within offsetTicksContainer is absolute (relative to the container itself).
      tickLabel.top = labelYPos;
      tickLabel.left = tickPos + TICK_LABEL_X_OFFSET;

      offsetTicksContainer.addComponent(tickLabel);
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
    var targetSongTimeSeconds:Float = waveformPlayer.waveform.waveformData.indexToSeconds(currentWaveformIndex);
    audioPreviewTracks.time = targetSongTimeSeconds * Constants.MS_PER_SEC;
  }

  public function onStartDragWaveform(waveform:Waveform):Void
  {
    dragMousePosition = FlxG.mouse.x;
    dragWaveform = waveform;

    Screen.instance.registerEvent(MouseEvent.MOUSE_MOVE, onDragWaveform);
    Screen.instance.registerEvent(MouseEvent.MOUSE_UP, onStopDragWaveform);
  }

  var dragMousePosition:Float = 0;
  var dragWaveform:Waveform = null;
  var dragOffsetMs:Float = 0;

  public function onDragWaveform(event:MouseEvent):Void
  {
    var newDragMousePosition = FlxG.mouse.x;
    var deltaMousePosition = newDragMousePosition - dragMousePosition;

    if (deltaMousePosition == 0) return;

    var deltaPixels:Float = deltaMousePosition * (waveformScale / BASE_SCALE * waveformMagicFactor);
    var deltaMilliseconds:Float = switch (dragWaveform)
    {
      case PLAYER:
        deltaPixels / waveformPlayer.waveform.waveformData.pointsPerSecond() * Constants.MS_PER_SEC;
      case OPPONENT:
        deltaPixels / waveformOpponent.waveform.waveformData.pointsPerSecond() * Constants.MS_PER_SEC;
      case INSTRUMENTAL:
        deltaPixels / waveformInstrumental.waveform.waveformData.pointsPerSecond() * Constants.MS_PER_SEC;
    };

    switch (dragWaveform)
    {
      case PLAYER:
        // chartEditorState.currentVocalOffsetPlayer += deltaMilliseconds;
        dragOffsetMs += deltaMilliseconds;
        offsetStepperPlayer.value += deltaMilliseconds;
      case OPPONENT:
        // chartEditorState.currentVocalOffsetOpponent += deltaMilliseconds;
        dragOffsetMs += deltaMilliseconds;
        offsetStepperOpponent.value += deltaMilliseconds;
      case INSTRUMENTAL:
        // chartEditorState.currentInstrumentalOffset += deltaMilliseconds;
        dragOffsetMs += deltaMilliseconds;
        offsetStepperInstrumental.value += deltaMilliseconds;
    }

    dragMousePosition = newDragMousePosition;

    refresh();
  }

  public function onStopDragWaveform(event:MouseEvent):Void
  {
    // Stop dragging.
    Screen.instance.unregisterEvent(MouseEvent.MOUSE_MOVE, onDragWaveform);
    Screen.instance.unregisterEvent(MouseEvent.MOUSE_UP, onStopDragWaveform);

    // Apply the offset change after dragging happens.
    // We only do this once per drag so we don't get 20 commands a second in the history.
    if (dragOffsetMs != 0)
    {
      // false to not refresh this toolbox, we will manually do that later.
      switch (dragWaveform)
      {
        case PLAYER:
          chartEditorState.performCommand(new SetAudioOffsetCommand(PLAYER, chartEditorState.currentVocalOffsetPlayer + dragOffsetMs, false));
        case OPPONENT:
          chartEditorState.performCommand(new SetAudioOffsetCommand(OPPONENT, chartEditorState.currentVocalOffsetOpponent + dragOffsetMs, false));
        case INSTRUMENTAL:
          chartEditorState.performCommand(new SetAudioOffsetCommand(INSTRUMENTAL, chartEditorState.currentInstrumentalOffset + dragOffsetMs, false));
      }
    }

    dragOffsetMs = 0;
    dragMousePosition = 0;
    dragWaveform = null;

    refresh();
    addOffsetsToAudioPreview();
  }

  public function playAudioPreview():Void
  {
    audioPreviewTracks.play(false, audioPreviewTracks.time);
  }

  public function addOffsetsToAudioPreview():Void
  {
    var trackInst = audioPreviewTracks.members[0];
    if (trackInst != null)
    {
      audioPreviewInstrumentalOffset = chartEditorState.currentInstrumentalOffset;
      trackInst.time -= audioPreviewInstrumentalOffset;
    }

    var trackPlayer = audioPreviewTracks.members[1];
    if (trackPlayer != null)
    {
      audioPreviewPlayerOffset = chartEditorState.currentVocalOffsetPlayer;
      trackPlayer.time -= audioPreviewPlayerOffset;
    }

    var trackOpponent = audioPreviewTracks.members[2];
    if (trackOpponent != null)
    {
      audioPreviewOpponentOffset = chartEditorState.currentVocalOffsetOpponent;
      trackOpponent.time -= audioPreviewOpponentOffset;
    }
  }

  public function pauseAudioPreview():Void
  {
    audioPreviewTracks.pause();
  }

  public function stopAudioPreview():Void
  {
    audioPreviewTracks.stop();

    audioPreviewTracks.time = 0;

    var trackInst = audioPreviewTracks.members[0];
    if (trackInst != null)
    {
      audioPreviewInstrumentalOffset = chartEditorState.currentInstrumentalOffset;
      trackInst.time = -audioPreviewInstrumentalOffset;
    }

    var trackPlayer = audioPreviewTracks.members[1];
    if (trackPlayer != null)
    {
      audioPreviewPlayerOffset = chartEditorState.currentVocalOffsetPlayer;
      trackPlayer.time = -audioPreviewPlayerOffset;
    }

    var trackOpponent = audioPreviewTracks.members[2];
    if (trackOpponent != null)
    {
      audioPreviewOpponentOffset = chartEditorState.currentVocalOffsetOpponent;
      trackOpponent.time = -audioPreviewOpponentOffset;
    }

    waveformScrollview.hscrollPos = 0;
    playheadAbsolutePos = 0 + playheadSprite.width;
    refresh();
    addOffsetsToAudioPreview();
  }

  public function zoomWaveformIn():Void
  {
    if (waveformScale > MIN_SCALE)
    {
      waveformScale = waveformScale / WAVEFORM_ZOOM_MULT;
      if (waveformScale < MIN_SCALE) waveformScale = MIN_SCALE;

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

    // Update the playhead too!
    playheadAbsolutePos = playheadAbsolutePos / WAVEFORM_ZOOM_MULT;

    // Recenter the scroll view on the playhead.
    var vaguelyCenterPlayheadOffset = waveformScrollview.width / 8;
    waveformScrollview.hscrollPos = playheadAbsolutePos - vaguelyCenterPlayheadOffset;

    refresh();
    refreshTicks();
  }

  public function setTrackVolume(target:Waveform, volume:Float):Void
  {
    switch (target)
    {
      case Waveform.INSTRUMENTAL:
        var trackInst = audioPreviewTracks.members[0];
        if (trackInst != null)
        {
          trackInst.volume = volume;
        }
      case Waveform.PLAYER:
        var trackPlayer = audioPreviewTracks.members[1];
        if (trackPlayer != null)
        {
          trackPlayer.volume = volume;
        }
      case Waveform.OPPONENT:
        var trackOpponent = audioPreviewTracks.members[2];
        if (trackOpponent != null)
        {
          trackOpponent.volume = volume;
        }
    }
  }

  public function muteTrack(target:Waveform):Void
  {
    switch (target)
    {
      case Waveform.INSTRUMENTAL:
        var trackInst = audioPreviewTracks.members[0];
        if (trackInst != null)
        {
          trackInst.muted = true;
          offsetInstrumentalMute.text = trackInst.muted ? "Unmute" : "Mute";
        }
      case Waveform.PLAYER:
        var trackPlayer = audioPreviewTracks.members[1];
        if (trackPlayer != null)
        {
          trackPlayer.muted = true;
          offsetPlayerMute.text = trackPlayer.muted ? "Unmute" : "Mute";
        }
      case Waveform.OPPONENT:
        var trackOpponent = audioPreviewTracks.members[2];
        if (trackOpponent != null)
        {
          trackOpponent.muted = true;
          offsetOpponentMute.text = trackOpponent.muted ? "Unmute" : "Mute";
        }
    }
  }

  public function unmuteTrack(target:Waveform):Void
  {
    switch (target)
    {
      case Waveform.INSTRUMENTAL:
        var trackInst = audioPreviewTracks.members[0];
        if (trackInst != null)
        {
          trackInst.muted = false;
          offsetInstrumentalMute.text = trackInst.muted ? "Unmute" : "Mute";
        }
      case Waveform.PLAYER:
        var trackPlayer = audioPreviewTracks.members[1];
        if (trackPlayer != null)
        {
          trackPlayer.muted = false;
          offsetPlayerMute.text = trackPlayer.muted ? "Unmute" : "Mute";
        }
      case Waveform.OPPONENT:
        var trackOpponent = audioPreviewTracks.members[2];
        if (trackOpponent != null)
        {
          trackOpponent.muted = false;
          offsetOpponentMute.text = trackOpponent.muted ? "Unmute" : "Mute";
        }
    }
  }

  public function toggleMuteTrack(target:Waveform):Void
  {
    switch (target)
    {
      case Waveform.INSTRUMENTAL:
        var trackInst = audioPreviewTracks.members[0];
        if (trackInst != null)
        {
          trackInst.muted = !trackInst.muted;
          offsetInstrumentalMute.text = trackInst.muted ? "Unmute" : "Mute";
        }
      case Waveform.PLAYER:
        var trackPlayer = audioPreviewTracks.members[1];
        if (trackPlayer != null)
        {
          trackPlayer.muted = !trackPlayer.muted;
          offsetPlayerMute.text = trackPlayer.muted ? "Unmute" : "Mute";
        }
      case Waveform.OPPONENT:
        var trackOpponent = audioPreviewTracks.members[2];
        if (trackOpponent != null)
        {
          trackOpponent.muted = !trackOpponent.muted;
          offsetOpponentMute.text = trackOpponent.muted ? "Unmute" : "Mute";
        }
    }
  }

  /**
   * Clicking the solo button will unmute the track and mute all other tracks.
   * @param target
   */
  public function soloTrack(target:Waveform):Void
  {
    switch (target)
    {
      case Waveform.PLAYER:
        muteTrack(Waveform.OPPONENT);
        muteTrack(Waveform.INSTRUMENTAL);
        unmuteTrack(Waveform.PLAYER);
      case Waveform.OPPONENT:
        muteTrack(Waveform.PLAYER);
        muteTrack(Waveform.INSTRUMENTAL);
        unmuteTrack(Waveform.OPPONENT);
      case Waveform.INSTRUMENTAL:
        muteTrack(Waveform.PLAYER);
        muteTrack(Waveform.OPPONENT);
        unmuteTrack(Waveform.INSTRUMENTAL);
    }
  }

  public override function update(elapsed:Float)
  {
    super.update(elapsed);

    if (audioPreviewTracks.playing)
    {
      trace('Playback time: ${audioPreviewTracks.time}');

      var targetScrollPos:Float = waveformInstrumental.waveform.waveformData.secondsToIndex(audioPreviewTracks.time / Constants.MS_PER_SEC) / (waveformScale / BASE_SCALE * waveformMagicFactor);
      // waveformScrollview.hscrollPos = targetScrollPos;
      var prevPlayheadAbsolutePos = playheadAbsolutePos;
      playheadAbsolutePos = targetScrollPos;
      var playheadDiff = playheadAbsolutePos - prevPlayheadAbsolutePos;

      // BEHAVIOR A.
      // Just move the scroll view with the playhead, constraining it so that the playhead is always visible.
      // waveformScrollview.hscrollPos += playheadDiff;
      // waveformScrollview.hscrollPos = FlxMath.bound(waveformScrollview.hscrollPos, playheadAbsolutePos - playheadSprite.width, playheadAbsolutePos);

      // BEHAVIOR B.
      // Keep `playheadAbsolutePos` within the bounds of the screen.
      // The scroll view will eventually move to where the playhead is 1/8th of the way from the left. This looks kinda nice!
      // TODO: This causes a hard snap to scroll when the playhead is to the right of the playheadCenterPoint.
      // var playheadCenterPoint = waveformScrollview.width / 8;
      // waveformScrollview.hscrollPos = FlxMath.bound(waveformScrollview.hscrollPos, playheadAbsolutePos - playheadCenterPoint, playheadAbsolutePos);

      // playheadRelativePos = 0;

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

    if (chartEditorState.currentInstrumentalOffset != audioPreviewInstrumentalOffset)
    {
      var track = audioPreviewTracks.members[0];
      if (track != null)
      {
        track.time += audioPreviewInstrumentalOffset;
        track.time -= chartEditorState.currentInstrumentalOffset;
        audioPreviewInstrumentalOffset = chartEditorState.currentInstrumentalOffset;
      }
    }
    if (chartEditorState.currentVocalOffsetPlayer != audioPreviewPlayerOffset)
    {
      var track = audioPreviewTracks.members[1];
      if (track != null)
      {
        track.time += audioPreviewPlayerOffset;
        track.time -= chartEditorState.currentVocalOffsetPlayer;
        audioPreviewPlayerOffset = chartEditorState.currentVocalOffsetPlayer;
      }
    }
    if (chartEditorState.currentVocalOffsetOpponent != audioPreviewOpponentOffset)
    {
      var track = audioPreviewTracks.members[2];
      if (track != null)
      {
        track.time += audioPreviewOpponentOffset;
        track.time -= chartEditorState.currentVocalOffsetOpponent;
        audioPreviewOpponentOffset = chartEditorState.currentVocalOffsetOpponent;
      }
    }
    offsetLabelTime.text = formatTime(audioPreviewTracks.time / Constants.MS_PER_SEC);
    // Keep the playhead in view.
    // playheadRelativePos = FlxMath.bound(playheadRelativePos, waveformScrollview.hscrollPos + 1,
    //   Math.min(waveformScrollview.hscrollPos + waveformScrollview.width, waveformContainer.width));
  }

  public override function refresh():Void
  {
    super.refresh();

    waveformMagicFactor = MAGIC_SCALE_BASE_TIME / (chartEditorState.offsetTickBitmap.width / waveformInstrumental.waveform.waveformData.pointsPerSecond());

    var currentZoomFactor = waveformScale / BASE_SCALE * waveformMagicFactor;

    var maxWidth:Int = -1;

    offsetStepperPlayer.value = chartEditorState.currentVocalOffsetPlayer;
    offsetStepperOpponent.value = chartEditorState.currentVocalOffsetOpponent;
    offsetStepperInstrumental.value = chartEditorState.currentInstrumentalOffset;

    waveformPlayer.waveform.time = -chartEditorState.currentVocalOffsetPlayer / Constants.MS_PER_SEC; // Negative offsets make the song start early.
    waveformPlayer.waveform.width = (waveformPlayer.waveform.waveformData?.length ?? 1000) / currentZoomFactor;
    if (waveformPlayer.waveform.width > maxWidth) maxWidth = Std.int(waveformPlayer.waveform.width);
    waveformPlayer.waveform.height = 65;

    waveformOpponent.waveform.time = -chartEditorState.currentVocalOffsetOpponent / Constants.MS_PER_SEC;
    waveformOpponent.waveform.width = (waveformOpponent.waveform.waveformData?.length ?? 1000) / currentZoomFactor;
    if (waveformOpponent.waveform.width > maxWidth) maxWidth = Std.int(waveformOpponent.waveform.width);
    waveformOpponent.waveform.height = 65;

    waveformInstrumental.waveform.time = -chartEditorState.currentInstrumentalOffset / Constants.MS_PER_SEC;
    waveformInstrumental.waveform.width = (waveformInstrumental.waveform.waveformData?.length ?? 1000) / currentZoomFactor;
    if (waveformInstrumental.waveform.width > maxWidth) maxWidth = Std.int(waveformInstrumental.waveform.width);
    waveformInstrumental.waveform.height = 65;

    // Live update the drag, but don't actually change the underlying offset until we release the mouse to finish dragging.
    if (dragWaveform != null) switch (dragWaveform)
    {
      case PLAYER:
        // chartEditorState.currentVocalOffsetPlayer += deltaMilliseconds;
        waveformPlayer.waveform.time -= dragOffsetMs / Constants.MS_PER_SEC;
        offsetStepperPlayer.value += dragOffsetMs;
      case OPPONENT:
        // chartEditorState.currentVocalOffsetOpponent += deltaMilliseconds;
        waveformOpponent.waveform.time -= dragOffsetMs / Constants.MS_PER_SEC;
        offsetStepperOpponent.value += dragOffsetMs;
      case INSTRUMENTAL:
        // chartEditorState.currentInstrumentalOffset += deltaMilliseconds;
        waveformInstrumental.waveform.time -= dragOffsetMs / Constants.MS_PER_SEC;
        offsetStepperInstrumental.value += dragOffsetMs;
      default:
        // No drag, no
    }

    waveformPlayer.waveform.markDirty();
    waveformOpponent.waveform.markDirty();
    waveformInstrumental.waveform.markDirty();

    waveformContainer.width = maxWidth;
    tickTiledSprite.width = maxWidth;
  }

  public static function build(chartEditorState:ChartEditorState):ChartEditorOffsetsToolbox
  {
    return new ChartEditorOffsetsToolbox(chartEditorState);
  }
}

enum Waveform
{
  PLAYER;
  OPPONENT;
  INSTRUMENTAL;
}
