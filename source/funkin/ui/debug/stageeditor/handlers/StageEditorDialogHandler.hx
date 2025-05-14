package funkin.ui.debug.stageeditor.handlers;

import haxe.ui.containers.dialogs.Dialog;
import haxe.ui.containers.dialogs.Dialog.DialogButton;
import haxe.ui.containers.dialogs.Dialogs;
import funkin.ui.debug.stageeditor.StageEditorState;
import funkin.ui.debug.stageeditor.components.PreferenceDialog;
import funkin.save.Save;
import funkin.ui.debug.charting.util.ChartEditorDropdowns;
import haxe.ui.events.UIEvent;
import haxe.ui.components.Button;
import haxe.ui.components.DropDown;
import haxe.ui.components.Label;
import haxe.ui.components.NumberStepper;
import haxe.ui.components.Slider;
import haxe.ui.components.TextField;
import haxe.ui.containers.Box;
import haxe.ui.components.CheckBox;
import haxe.ui.components.OptionStepper;

@:nullSafety
@:access(funkin.ui.debug.stageeditor.StageEditorState)
class StageEditorDialogHandler {
  public static function openPreferencesDialog(state:StageEditorState, closable:Bool):Null<Dialog>
  {
    var dialog = PreferenceDialog.build(state, closable);
    var save:Save = Save.instance;

    var themeMusic:Null<CheckBox> = dialog.findComponent('optionsThemeMusic', CheckBox);
    if (themeMusic == null) throw 'Could not locate themeMusic CheckBox in Preferences dialog';
    themeMusic.onChange = function(event:UIEvent) {
      if (event.value == null) return;
      state.isWelcomeMusic = event.value;
      if (!state.welcomeMusic.active || !state.isWelcomeMusic) state.fadeInWelcomeMusic();
    };
    themeMusic.selected = state.isWelcomeMusic;

    var inputTheme:Null<DropDown> = dialog.findComponent('optionsThemeGroup', DropDown);
    if (inputTheme == null) throw 'Could not locate inputTheme DropDown in Preferences dialog';
    inputTheme.onChange = function(event:UIEvent) {
      if (event.data?.id == null) return;
      state.themeId = event.data.id;
    };
    var startingValueTheme = ChartEditorDropdowns.populateDropdownWithThemes(inputTheme, state.themeId);
    inputTheme.value = startingValueTheme;

    dialog.zIndex = 1000;

    return dialog;
  }
}
