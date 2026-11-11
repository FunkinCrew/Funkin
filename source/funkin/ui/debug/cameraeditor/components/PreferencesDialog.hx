package funkin.ui.debug.cameraeditor.components;

#if FEATURE_CAMERA_EDITOR
import funkin.ui.debug.charting.util.ChartEditorScaleMode;
import haxe.ui.components.Label;
import haxe.ui.components.Slider;
import haxe.ui.containers.dialogs.Dialog;
import haxe.ui.events.UIEvent;

/**
 * The Camera Editor's preferences. The values are shared with the Chart Editor.
 */
@:build(haxe.ui.macros.ComponentMacros.build('assets/exclude/ui/editors/camera-editor/dialogs/preferences.xml'))
class PreferencesDialog extends Dialog
{
  var cameraEditorState:CameraEditorState;

  /**
   * Off while the controls are filled in, so filling them is not an edit.
   */
  var listening:Bool = false;

  public function new(state:CameraEditorState)
  {
    super();
    cameraEditorState = state;

    preferencesUIScale.pos = Math.round(state.uiScale * 100);
    preferencesUIScaleLabel.text = uiScaleText(Math.round(state.uiScale * 100));
    preferencesThemeMusic.selected = state.playThemeMusic;
    preferencesFitCameraToViewport.selected = state.fitCameraToViewport;
    preferencesZoomToPlayhead.selected = state.zoomToPlayhead;
    loadVolume(preferencesVolumeInstrumental, preferencesLabelVolumeInstrumental, 'Instrumental', state.instrumentalVolume);
    loadVolume(preferencesVolumeVocalsOpponent, preferencesLabelVolumeVocalsOpponent, 'Opponent', state.opponentVocalVolume);
    loadVolume(preferencesVolumeVocalsPlayer, preferencesLabelVolumeVocalsPlayer, 'Player', state.playerVocalVolume);
    listening = true;
  }

  function loadVolume(slider:Slider, label:Label, title:String, volume:Float):Void
  {
    var percent:Int = Math.round(volume * 100);
    slider.pos = percent;
    label.text = '$title - $percent%';
  }

  /**
   * The UI scale label, with a note when the window is too small to show it.
   */
  static function uiScaleText(percent:Int):String
  {
    var maxPercent:Int = Math.floor(ChartEditorScaleMode.windowMaxUIScale() * 100);
    if (percent > maxPercent) return 'UI scale - $percent% (window fits $maxPercent%)';
    return 'UI scale - $percent%';
  }

  /**
   * Update the UI scale label after the window changes size.
   */
  public function refreshUIScaleLabel():Void
  {
    preferencesUIScaleLabel.text = uiScaleText(Math.round(cameraEditorState.uiScale * 100));
  }

  @:bind(preferencesUIScale, UIEvent.CHANGE)
  function onChange_preferencesUIScale(_):Void
  {
    if (!listening) return;
    var percent:Int = Math.round(preferencesUIScale.pos);
    cameraEditorState.uiScale = percent / 100.0;
    preferencesUIScaleLabel.text = uiScaleText(percent);
  }

  @:bind(preferencesFitCameraToViewport, UIEvent.CHANGE)
  function onChange_preferencesFitCameraToViewport(_):Void
  {
    if (!listening) return;
    cameraEditorState.fitCameraToViewport = preferencesFitCameraToViewport.selected;
  }

  @:bind(preferencesZoomToPlayhead, UIEvent.CHANGE)
  function onChange_preferencesZoomToPlayhead(_):Void
  {
    if (!listening) return;
    cameraEditorState.zoomToPlayhead = preferencesZoomToPlayhead.selected;
  }

  @:bind(preferencesThemeMusic, UIEvent.CHANGE)
  function onChange_preferencesThemeMusic(_):Void
  {
    if (!listening) return;
    cameraEditorState.playThemeMusic = preferencesThemeMusic.selected;
  }

  @:bind(preferencesVolumeInstrumental, UIEvent.CHANGE)
  function onChange_preferencesVolumeInstrumental(_):Void
  {
    if (!listening) return;
    cameraEditorState.instrumentalVolume = readVolume(preferencesVolumeInstrumental, preferencesLabelVolumeInstrumental, 'Instrumental');
    cameraEditorState.applyAudioVolumes();
  }

  @:bind(preferencesVolumeVocalsOpponent, UIEvent.CHANGE)
  function onChange_preferencesVolumeVocalsOpponent(_):Void
  {
    if (!listening) return;
    cameraEditorState.opponentVocalVolume = readVolume(preferencesVolumeVocalsOpponent, preferencesLabelVolumeVocalsOpponent, 'Opponent');
    cameraEditorState.applyAudioVolumes();
  }

  @:bind(preferencesVolumeVocalsPlayer, UIEvent.CHANGE)
  function onChange_preferencesVolumeVocalsPlayer(_):Void
  {
    if (!listening) return;
    cameraEditorState.playerVocalVolume = readVolume(preferencesVolumeVocalsPlayer, preferencesLabelVolumeVocalsPlayer, 'Player');
    cameraEditorState.applyAudioVolumes();
  }

  function readVolume(slider:Slider, label:Label, title:String):Float
  {
    var percent:Int = Math.round(slider.pos);
    label.text = '$title - $percent%';
    return percent / 100.0;
  }
}
#end
