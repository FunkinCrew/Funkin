package funkin.ui.options.mobile;

import funkin.ui.options.PreferencesMenu;

class MobilePreferencesMenu extends PreferencesMenu
{
  /**
   * Create the menu items for each of the preferences.
   */
  override function createPrefItems():Void
  {
    createPrefItemCheckbox('Legacy Controls', 'Toggle legacy controls', function(value:Bool):Void {
      Preferences.legacyControls = value;
    }, Preferences.legacyControls);
  }
}
