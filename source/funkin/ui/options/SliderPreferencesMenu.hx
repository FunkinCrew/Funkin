package funkin.ui.options;

import flixel.FlxCamera;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import funkin.ui.AtlasText.AtlasFont;
import funkin.ui.options.OptionsState.Page;
import funkin.graphics.FunkinCamera;
import funkin.ui.TextMenuList.TextMenuItem;

class SliderPreferencesMenu extends Page
{
  var textItems:TextMenuList;
  var preferenceItems:TextMenuList;

  var menuCamera:FlxCamera;
  var camFollow:FlxObject;

  public function new()
  {
    super();

    menuCamera = new FunkinCamera('sliderPrefMenu');
    FlxG.cameras.add(menuCamera, false);
    menuCamera.bgColor = 0x0;
    camera = menuCamera;

    add(textItems = new TextMenuList());
    add(preferenceItems = new TextMenuList());
    createPrefItems();

    camFollow = new FlxObject(FlxG.width / 2, 0, 140, 70);
    if (textItems != null) camFollow.y = textItems.selectedItem.y;

    menuCamera.follow(camFollow, null, 0.06);
    var margin = 160;
    menuCamera.deadzone.set(0, margin, menuCamera.width, 40);
    menuCamera.minScrollY = 0;

    textItems.onChange.add(function(selected) {
      camFollow.y = selected.y;
    });
  }

  function createPrefItems():Void
  {
    createPrefItemFloatSlider('Background dim', 'How dark is the dim behind gameplay', function(value:Float):Void {
      SliderPreferences.gameplayBackgroundAlpha = value;
    }, SliderPreferences.gameplayBackgroundAlpha);
  }

  function createPrefItemFloatSlider(prefName:String, prefDesc:String, onChange:Float->Void, defaultValue:Float):Void
  {
    preferenceItems.createItem(20, (120 * preferenceItems.length) + 30, Std.string(defaultValue), AtlasFont.DEFAULT, function() {
      trace("creating text item");
    });

    textItems.createItem(160, (120 * textItems.length) + 30, prefName, AtlasFont.BOLD, function() {
      trace("creating FloatSlider item");
    });
  }
}
