package funkin.ui.debug.charting.toolboxes;

import funkin.audio.SoundGroup;
import haxe.ui.components.Button;
import haxe.ui.components.HorizontalSlider;
import haxe.ui.components.Label;
import haxe.ui.components.NumberStepper;
import haxe.ui.components.Slider;
import funkin.ui.haxeui.components.WaveformPlayer;
import funkin.audio.waveform.WaveformDataParser;
import haxe.ui.containers.VBox;
import haxe.ui.containers.ScrollView;
import haxe.ui.containers.Frame;
import haxe.ui.core.Screen;
import haxe.ui.events.DragEvent;
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
  var waveformContainer:VBox;
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

  static final BASE_SCALE:Float = 64.0;
  static final MIN_SCALE:Float = 4.0;
  static final WAVEFORM_ZOOM_MULT:Float = 1.5;

  var waveformScale:Float = BASE_SCALE;

  var audioPreviewTracks:SoundGroup;

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
      chartEditorState.currentVocalOffsetPlayer = event.value;
      refresh();
    }
    offsetStepperOpponent.onChange = (event:UIEvent) -> {
      chartEditorState.currentVocalOffsetOpponent = event.value;
      refresh();
    }
    offsetStepperInstrumental.onChange = (event:UIEvent) -> {
      chartEditorState.currentInstrumentalOffset = event.value;
      refresh();
    }
    waveformScrollview.onScroll = (_) -> {
      if (!audioPreviewTracks.playing)
      {
        // We have to change the song position to match.
        var currentWaveformIndex:Int = Std.int(waveformScrollview.hscrollPos / BASE_SCALE * waveformScale);
        var targetSongTimeSeconds:Float = waveformPlayer.waveform.waveformData.indexToSeconds(currentWaveformIndex);
        audioPreviewTracks.time = targetSongTimeSeconds * Constants.MS_PER_SEC;
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

    // Build player waveform.
    // waveformPlayer.waveform.forceUpdate = true;
    waveformPlayer.waveform.waveformData = chartEditorState.audioVocalTrackGroup.buildPlayerVoiceWaveform();
    // Set the width and duration to render the full waveform, with the clipRect applied we only render a segment of it.
    waveformPlayer.waveform.duration = chartEditorState.audioVocalTrackGroup.getPlayerVoiceLength() / Constants.MS_PER_SEC;

    // Build opponent waveform.
    // waveformOpponent.waveform.forceUpdate = true;
    waveformOpponent.waveform.waveformData = chartEditorState.audioVocalTrackGroup.buildOpponentVoiceWaveform();
    waveformOpponent.waveform.duration = chartEditorState.audioVocalTrackGroup.getOpponentVoiceLength() / Constants.MS_PER_SEC;

    // Build instrumental waveform.
    // waveformInstrumental.waveform.forceUpdate = true;
    waveformInstrumental.waveform.waveformData = WaveformDataParser.interpretFlxSound(chartEditorState.audioInstTrack);
    waveformInstrumental.waveform.duration = chartEditorState.audioInstTrack.length / Constants.MS_PER_SEC;

    refresh();
    refreshAudioPreview();

    waveformPlayer.registerEvent(MouseEvent.MOUSE_DOWN, (_) -> {
      onStartDragWaveform(PLAYER);
    });
    waveformOpponent.registerEvent(MouseEvent.MOUSE_DOWN, (_) -> {
      onStartDragWaveform(OPPONENT);
    });
    waveformInstrumental.registerEvent(MouseEvent.MOUSE_DOWN, (_) -> {
      onStartDragWaveform(INSTRUMENTAL);
    });
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

    audioPreviewTracks.add(chartEditorState.audioInstTrack.clone());
    audioPreviewTracks.add(chartEditorState.audioVocalTrackGroup.getPlayerVoice().clone());
    audioPreviewTracks.add(chartEditorState.audioVocalTrackGroup.getOpponentVoice().clone());

    addOffsetsToAudioPreview();
  }

  var dragMousePosition:Float = 0;
  var dragWaveform:Waveform = null;

  public function onStartDragWaveform(waveform:Waveform):Void
  {
    dragMousePosition = FlxG.mouse.x;
    dragWaveform = waveform;

    Screen.instance.registerEvent(MouseEvent.MOUSE_MOVE, onDragWaveform);
    Screen.instance.registerEvent(MouseEvent.MOUSE_UP, onStopDragWaveform);
  }

  public function onDragWaveform(event:MouseEvent):Void
  {
    var newDragMousePosition = FlxG.mouse.x;
    var deltaMousePosition = newDragMousePosition - dragMousePosition;

    if (deltaMousePosition == 0) return;

    var deltaPixels:Float = deltaMousePosition / BASE_SCALE * waveformScale;
    var deltaMilliseconds:Float = switch (dragWaveform)
    {
      case PLAYER:
        deltaPixels / waveformPlayer.waveform.waveformData.pointsPerSecond() * Constants.MS_PER_SEC;
      case OPPONENT:
        deltaPixels / waveformOpponent.waveform.waveformData.pointsPerSecond() * Constants.MS_PER_SEC;
      case INSTRUMENTAL:
        deltaPixels / waveformInstrumental.waveform.waveformData.pointsPerSecond() * Constants.MS_PER_SEC;
    };

    trace('Moving waveform by ${deltaMousePosition} -> ${deltaPixels} -> ${deltaMilliseconds} milliseconds.');

    switch (dragWaveform)
    {
      case PLAYER:
        chartEditorState.currentVocalOffsetPlayer += deltaMilliseconds;
      case OPPONENT:
        chartEditorState.currentVocalOffsetOpponent += deltaMilliseconds;
      case INSTRUMENTAL:
        chartEditorState.currentInstrumentalOffset += deltaMilliseconds;
    }

    dragMousePosition = newDragMousePosition;

    refresh();
  }

  public function onStopDragWaveform(event:MouseEvent):Void
  {
    // Stop dragging.
    Screen.instance.unregisterEvent(MouseEvent.MOUSE_MOVE, onDragWaveform);
    Screen.instance.unregisterEvent(MouseEvent.MOUSE_UP, onStopDragWaveform);

    dragMousePosition = 0;
    dragWaveform = null;
  }

  public function playAudioPreview():Void
  {
    // chartEditorState.stopAudioPlayback();

    audioPreviewTracks.resume();
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
    refresh();
  }

  public function zoomWaveformIn():Void
  {
    if (waveformScale > 1)
    {
      waveformScale = waveformScale / WAVEFORM_ZOOM_MULT;
      if (waveformScale < MIN_SCALE) waveformScale = MIN_SCALE;
    }
    else
    {
      waveformScale = 1;
    }

    trace('Zooming in, scale: ${waveformScale}');

    refresh();
  }

  public function zoomWaveformOut():Void
  {
    waveformScale = waveformScale * WAVEFORM_ZOOM_MULT;
    if (waveformScale < MIN_SCALE) waveformScale = MIN_SCALE;

    trace('Zooming out, scale: ${waveformScale}');

    refresh();
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

      var targetScrollPos:Float = waveformPlayer.waveform.waveformData.secondsToIndex(audioPreviewTracks.time / Constants.MS_PER_SEC) / waveformScale * BASE_SCALE;
      waveformScrollview.hscrollPos = targetScrollPos;
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
  }

  public override function refresh():Void
  {
    super.refresh();

    // Set the width based on the waveformScale value.

    var maxWidth:Int = -1;

    offsetStepperPlayer.value = chartEditorState.currentVocalOffsetPlayer;
    offsetStepperOpponent.value = chartEditorState.currentVocalOffsetOpponent;
    offsetStepperInstrumental.value = chartEditorState.currentInstrumentalOffset;

    waveformPlayer.waveform.time = -chartEditorState.currentVocalOffsetPlayer / Constants.MS_PER_SEC; // Negative offsets make the song start early.
    waveformPlayer.waveform.width = waveformPlayer.waveform.waveformData.length / waveformScale * BASE_SCALE;
    if (waveformPlayer.waveform.width > maxWidth) maxWidth = Std.int(waveformPlayer.waveform.width);
    waveformPlayer.waveform.height = 65;

    waveformOpponent.waveform.time = -chartEditorState.currentVocalOffsetOpponent / Constants.MS_PER_SEC;
    waveformOpponent.waveform.width = waveformOpponent.waveform.waveformData.length / waveformScale * BASE_SCALE;
    if (waveformOpponent.waveform.width > maxWidth) maxWidth = Std.int(waveformOpponent.waveform.width);
    waveformOpponent.waveform.height = 65;

    waveformInstrumental.waveform.time = -chartEditorState.currentInstrumentalOffset / Constants.MS_PER_SEC;
    waveformInstrumental.waveform.width = waveformInstrumental.waveform.waveformData.length / waveformScale * BASE_SCALE;
    if (waveformInstrumental.waveform.width > maxWidth) maxWidth = Std.int(waveformInstrumental.waveform.width);
    waveformInstrumental.waveform.height = 65;

    waveformPlayer.waveform.markDirty();
    waveformOpponent.waveform.markDirty();
    waveformInstrumental.waveform.markDirty();

    waveformContainer.width = maxWidth;
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
