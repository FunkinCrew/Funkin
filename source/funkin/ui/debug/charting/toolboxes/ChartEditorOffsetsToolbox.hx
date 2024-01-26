package funkin.ui.debug.charting.toolboxes;

import funkin.play.character.BaseCharacter.CharacterType;
import funkin.play.character.CharacterData;
import funkin.data.stage.StageData;
import funkin.data.stage.StageRegistry;
import funkin.ui.debug.charting.commands.ChangeStartingBPMCommand;
import funkin.ui.debug.charting.util.ChartEditorDropdowns;
import haxe.ui.components.Button;
import haxe.ui.components.CheckBox;
import haxe.ui.components.DropDown;
import haxe.ui.components.HorizontalSlider;
import haxe.ui.components.Label;
import haxe.ui.components.NumberStepper;
import haxe.ui.components.Slider;
import haxe.ui.components.TextField;
import funkin.play.stage.Stage;
import funkin.ui.haxeui.components.WaveformPlayer;
import funkin.audio.waveform.WaveformDataParser;
import haxe.ui.containers.Box;
import haxe.ui.containers.Frame;
import haxe.ui.events.UIEvent;
import funkin.audio.waveform.WaveformData;

/**
 * The toolbox which allows modifying information like Song Title, Scroll Speed, Characters/Stages, and starting BPM.
 */
// @:nullSafety // TODO: Fix null safety when used with HaxeUI build macros.
@:access(funkin.ui.debug.charting.ChartEditorState)
@:build(haxe.ui.ComponentBuilder.build("assets/exclude/data/ui/chart-editor/toolboxes/offsets.xml"))
class ChartEditorOffsetsToolbox extends ChartEditorBaseToolbox
{
  var waveformPlayer:WaveformPlayer;
  var waveformOpponent:WaveformPlayer;
  var waveformInstrumental:WaveformPlayer;
  var offsetButtonZoomIn:Button;
  var offsetButtonZoomOut:Button;

  var waveformScale:Int = 64;

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

    offsetButtonZoomIn.onClick = (_) -> {
      zoomWaveformIn();
    };
    offsetButtonZoomOut.onClick = (_) -> {
      zoomWaveformOut();
    };

    // Build player waveform.
    waveformPlayer.waveform.forceUpdate = true;
    waveformPlayer.waveform.waveformData = chartEditorState.audioVocalTrackGroup.buildPlayerVoiceWaveform();
    // Set the width and duration to render the full waveform, with the clipRect applied we only render a segment of it.
    waveformPlayer.waveform.duration = 5.0; // chartEditorState.audioVocalTrackGroup.getPlayerVoiceLength() / 1000;

    // Build opponent waveform.
    waveformOpponent.waveform.forceUpdate = true;
    waveformOpponent.waveform.waveformData = chartEditorState.audioVocalTrackGroup.buildOpponentVoiceWaveform();
    waveformOpponent.waveform.duration = 5.0; // chartEditorState.audioVocalTrackGroup.getOpponentVoiceLength() / 1000;

    // Build instrumental waveform.
    waveformInstrumental.waveform.forceUpdate = true;
    waveformInstrumental.waveform.waveformData = WaveformDataParser.interpretFlxSound(chartEditorState.audioInstTrack);
    waveformInstrumental.waveform.duration = 5.0; // chartEditorState.audioInstTrack.length / 1000;

    refresh();
  }

  public function zoomWaveformIn():Void
  {
    if (waveformScale > 1)
    {
      waveformScale = Std.int(waveformScale / 2);
    }
    else
    {
      waveformScale = 1;
    }

    refresh();
  }

  public function zoomWaveformOut():Void
  {
    waveformScale = Std.int(waveformScale * 2);

    refresh();
  }

  public override function refresh():Void
  {
    super.refresh();

    // Set the width based on the waveformScale value.

    waveformPlayer.waveform.width = waveformPlayer.waveform.waveformData.length / waveformScale;
    trace('Player duration: ${waveformPlayer.waveform.duration}, width: ${waveformPlayer.waveform.width}');

    waveformOpponent.waveform.width = waveformOpponent.waveform.waveformData.length / waveformScale;
    trace('Opponent duration: ${waveformOpponent.waveform.duration}, width: ${waveformOpponent.waveform.width}');

    waveformInstrumental.waveform.width = waveformInstrumental.waveform.waveformData.length / waveformScale;
    trace('Instrumental duration: ${waveformInstrumental.waveform.duration}, width: ${waveformInstrumental.waveform.width}');
  }

  public static function build(chartEditorState:ChartEditorState):ChartEditorOffsetsToolbox
  {
    return new ChartEditorOffsetsToolbox(chartEditorState);
  }
}
