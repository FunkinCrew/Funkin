package funkin.ui.options;

import flixel.FlxCamera;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import funkin.ui.AtlasText.AtlasFont;
import funkin.ui.options.OptionsState.Page;
import funkin.graphics.FunkinCamera;
import funkin.graphics.FunkinSprite;
import funkin.ui.TextMenuList.TextMenuItem;
import funkin.audio.FunkinSound;
import funkin.ui.options.MenuItemEnums;
import funkin.ui.options.items.CheckboxPreferenceItem;
import funkin.ui.options.items.NumberPreferenceItem;
import funkin.ui.options.items.EnumPreferenceItem;

class LanguageMenu extends Page
{
  var items:TextMenuList;

  public var exitToMainMenu:Null<Void->Void>;

  public function new()
  {
    super();
    add(items = new TextMenuList());

    for (locale in Localization.tongue.locales)
    {
      // createItem(Localization.tongue.getIndexString("$LANGUAGE_REGION", locale, Preferences.locale), function() {
      createItem(locale, function() {
        Preferences.locale = locale;
        exitToMainMenu();
      });
    }
  }

  function createItem(name:String, callback:Void->Void, fireInstantly = false)
  {
    var item = items.createItem(0, 100 + items.length * 100, name, BOLD, callback);
    item.fireInstantly = fireInstantly;
    item.screenCenter(X);
    return item;
  }

  /**
   * True if this page has multiple options, excluding the exit option.
   * If false, there's no reason to ever show this page.
   */
  public function hasMultipleOptions():Bool
  {
    return items.length > 2;
  }
}
