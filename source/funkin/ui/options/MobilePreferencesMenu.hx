package funkin.ui.options;

import funkin.ui.options.PreferencesMenu;
import funkin.play.components.TallyCounter.TallyNumber;

class MobilePreferencesMenu extends PreferencesMenu
{
  /**
   * Create the menu items for each of the preferences.
   */
  override function createPrefItems():Void
  {
    createPrefItemCheckbox('Allow Screen Timeout', 'Toggle screen timeout', function(value:Bool):Void {
      Preferences.screenTimeout = value;
    }, Preferences.screenTimeout);
    createPrefItemCheckbox('Vibration', 'Toggle vibration', function(value:Bool):Void {
      Preferences.vibration = value;
    }, Preferences.vibration);
    createPrefItemCheckbox('Legacy Controls', 'Toggle legacy controls', function(value:Bool):Void {
      Preferences.legacyControls = value;
    }, Preferences.legacyControls);
  }
}
