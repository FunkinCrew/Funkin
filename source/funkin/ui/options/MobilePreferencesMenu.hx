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

function createPrefItemTallyNum(prefName:String, prefDesc:String, onChange:Float->Void, defaultValue:Float):Void
{
  var num1:TallyNumber = new TallyNumber(0, 120 * (items.length - 1 + 1), defaultValue = 1 ? defaultValue : 0);
  var num2:TallyNumber = new TallyNumber(num1.x + 10, 120 * (items.length - 1 + 1), defaultValue = 1 ? 0 : defaultValue * 10);

  items.createItem(120, (120 * items.length) + 30, prefName, AtlasFont.BOLD);
  
  preferenceItems.add(num1);
  preferenceItems.add(num2);
}
