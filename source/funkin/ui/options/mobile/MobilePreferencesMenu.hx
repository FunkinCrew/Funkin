package funkin.ui.options.mobile;

import funkin.ui.options.PreferencesMenu;
import funkin.mobile.MobilePreferences;

class MobilePreferencesMenu extends PreferencesMenu
{
  /**
   * Create the menu items for each of the preferences.
   */
  override function createPrefItems():Void
  {
    createPrefItemCheckbox('Legacy Controls', 'Toggle legacy controls', function(value:Bool):Void {
      MobilePreferences.legacyControls = value;
    }, MobilePreferences.legacyControls);
  }
}
