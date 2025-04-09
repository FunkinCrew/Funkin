package funkin.ui.options;

import flixel.FlxCamera;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import funkin.ui.AtlasText.AtlasFont;
import funkin.ui.Page;
import funkin.graphics.FunkinCamera;
import funkin.graphics.FunkinSprite;
import funkin.ui.TextMenuList.TextMenuItem;
import funkin.ui.options.items.CheckboxPreferenceItem;
import funkin.ui.options.items.NumberPreferenceItem;
import funkin.ui.options.items.EnumPreferenceItem;
import funkin.ui.options.PreferenceItem;
import funkin.ui.options.PreferenceItem.PreferenceItemData;
import funkin.ui.options.PreferenceItem.PreferenceType;
import funkin.ui.MenuList.MenuTypedList;

class PreferencesMenu extends Page<OptionsState.OptionsMenuPageName>
{
  var options:MenuTypedList<PreferenceItem>;
  var categories:FlxTypedSpriteGroup<AtlasText>;

  var itemDesc:FlxText;
  var itemDescBox:FunkinSprite;
  var menuCamera:FlxCamera;
  var hudCamera:FlxCamera;
  var camFollow:FlxObject;

  public function new()
  {
    super();

    menuCamera = new FunkinCamera('prefMenu');
    FlxG.cameras.add(menuCamera, false);
    menuCamera.bgColor = 0x0;

    hudCamera = new FlxCamera();
    FlxG.cameras.add(hudCamera, false);
    hudCamera.bgColor = 0x0;

    camera = menuCamera;

    add(itemDescBox = new FunkinSprite());
    itemDescBox.cameras = [hudCamera];

    add(itemDesc = new FlxText(0, 0, 1180, null, 32));
    itemDesc.cameras = [hudCamera];

    add(options = new MenuTypedList<PreferenceItem>());
    add(categories = new FlxTypedSpriteGroup<AtlasText>());

    createPrefItems();
    createPrefDescription();

    camFollow = new FlxObject(FlxG.width / 2, 0, 140, 70);
    if (options != null) camFollow.y = options.selectedItem.y;

    menuCamera.follow(camFollow, null, 0.085);
    var margin = 160;
    menuCamera.deadzone.set(0, margin, menuCamera.width, menuCamera.height - margin * 2);
    menuCamera.minScrollY = 0;

    options.onChange.add(function(selected) {
      camFollow.y = selected.text.y;
      itemDesc.text = selected.description;
    });
  }

  /**
   * Create the description for preferences.
   */
  function createPrefDescription():Void
  {
    itemDescBox.makeSolidColor(1, 1, FlxColor.BLACK);
    itemDescBox.alpha = 0.6;
    itemDesc.setFormat(Paths.font('vcr.ttf'), 32, FlxColor.WHITE, FlxTextAlign.CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
    itemDesc.borderSize = 3;
    // Update the text.
    itemDesc.text = options.selectedItem.description;
    itemDesc.screenCenter();
    itemDesc.y += 270;
    // Create the box around the text.
    itemDescBox.setPosition(itemDesc.x - 10, itemDesc.y - 10);
    itemDescBox.setGraphicSize(Std.int(itemDesc.width + 20), Std.int(itemDesc.height + 25));
    itemDescBox.updateHitbox();
  }

  /**
   * Create the menu items for each of the preferences.
   */
  function createPrefItems():Void
  {
    addCategory('Gameplay');
    addOption(PreferenceType.Checkbox, 'Naughtyness', 'If enabled, raunchy content (such as swearing, etc.) will be displayed.', function(value:Bool):Void {
      Preferences.naughtyness = value;
    }, Preferences.naughtyness);
    addOption(PreferenceType.Checkbox, 'Downscroll', 'If enabled, this will make the notes move downwards.', function(value:Bool):Void {
      Preferences.downscroll = value;
    }, Preferences.downscroll);
    addOption(PreferenceType.Percentage, 'Strumline Background', 'Give the strumline a semi-transparent background', function(value:Int):Void {
      Preferences.strumlineBackgroundOpacity = value;
    }, Preferences.strumlineBackgroundOpacity);
    addOption(PreferenceType.Checkbox, 'Flashing Lights', 'If disabled, it will dampen flashing effects. Useful for people with photosensitive epilepsy.', function(value:Bool):Void {
      Preferences.flashingLights = value;
    }, Preferences.flashingLights);

    addCategory('Additional');
    addOption(PreferenceType.Checkbox, 'Camera Zooms', 'If disabled, camera stops bouncing to the song.', function(value:Bool):Void {
      Preferences.zoomCamera = value;
    }, Preferences.zoomCamera);
    addOption(PreferenceType.Checkbox, 'Debug Display', 'If enabled, FPS and other debug stats will be displayed.', function(value:Bool):Void {
      Preferences.debugDisplay = value;
    }, Preferences.debugDisplay);
    addOption(PreferenceType.Checkbox, 'Pause on Unfocus', 'If enabled, game automatically pauses when it loses focus.', function(value:Bool):Void {
      Preferences.autoPause = value;
    }, Preferences.autoPause);
    addOption(PreferenceType.Checkbox, 'Launch in Fullscreen', 'Automatically launch the game in fullscreen on startup', function(value:Bool):Void {
      Preferences.autoFullscreen = value;
    }, Preferences.autoFullscreen);

    #if web
    addOption(PreferenceType.Checkbox, 'Unlocked Framerate', 'If enabled, the framerate will be unlocked.', function(value:Bool):Void {
      Preferences.unlockedFramerate = value;
    }, Preferences.unlockedFramerate);
    #else
    addOption(PreferenceType.Number, 'FPS', 'The maximum framerate that the game targets.', function(value:Int):Void {
      Preferences.framerate = value;
    }, Preferences.framerate, { min: 30, max: 300, step: 5, precision: 0 });
    #end

    addCategory('Screenshots');
    addOption(PreferenceType.Checkbox, 'Hide Mouse', 'If enabled, the mouse will be hidden when taking a screenshot.', function(value:Bool):Void {
      Preferences.shouldHideMouse = value;
    }, Preferences.shouldHideMouse);
    addOption(PreferenceType.Checkbox, 'Hide Mouse', 'If enabled, the mouse will be hidden when taking a screenshot.', function(value:Bool):Void {
      Preferences.shouldHideMouse = value;
    }, Preferences.shouldHideMouse);

    addOption(PreferenceType.Checkbox, 'Fancy Preview', 'If enabled, a preview will be shown after taking a screenshot.', function(value:Bool):Void {
      Preferences.fancyPreview = value;
    }, Preferences.fancyPreview);
    addOption(PreferenceType.Checkbox, 'Preview on save', 'If enabled, the preview will be shown only after a screenshot is saved.',
      function(value:Bool):Void {
        Preferences.previewOnSave = value;
      }, Preferences.previewOnSave);
    // addOption(PreferenceType.Enum, 'Save Format', 'Save screenshots to this format.', function(value:String):Void {
    //   Preferences.saveFormat = value;
    // }, Preferences.saveFormat, {values: ['PNG' => 'PNG', 'JPEG' => 'JPEG']});
    addOption(PreferenceType.Number, 'JPEG Quality', 'The quality of JPEG screenshots.', function(value:Float) {
      Preferences.jpegQuality = Std.int(value);
    }, Preferences.jpegQuality, { min: 0, max: 100, step: 5, precision: 0 });
  }

  function addOption(type:PreferenceType, name:String, description:String, onChange:Null<Dynamic->Void>, defaultValue:Dynamic,
      ?extraData:PreferenceItemData):Void
  {
    var item = new PreferenceItem(0, 60 * (options.length + categories.length) + 15, type, name, description, onChange, defaultValue, extraData);
    options.addItem(name, item);
  }

  function addCategory(name:String):Void
  {
    var labelY:Float = 120 * (options.length + categories.length) + 30;
    categories.add(new AtlasText(0, labelY, name, AtlasFont.BOLD)).screenCenter(X);
  }

  override function update(elapsed:Float):Void
  {
    super.update(elapsed);

    // Indent the selected item.
    options.forEach(function(daItem:PreferenceItem) {
      var thyOffset:Int = 0;
      // Initializing thy text width (if thou text present)
      var thyTextWidth:Int = 0;

      switch (daItem.type)
      {
        // oh my days I'm going feral
        case PreferenceType.Enum, PreferenceType.Number, PreferenceType.Percentage:
          trace(Type.typeof(daItem.preferenceGraphic));
          trace(Type.typeof(daItem));
          if (Std.is(daItem.preferenceGraphic, AtlasText)) {
            thyTextWidth = cast(daItem.preferenceGraphic, AtlasText).getWidth();
          }
        case PreferenceType.Checkbox:
          thyTextWidth = Std.int(daItem.preferenceGraphic.width);
      }

      // setting the thy offset
      thyOffset = thyTextWidth + PreferenceItem.SPACING_X;

      daItem.text.x = thyOffset;
    });
  }

  // - Preference item creation methods -
  // Should be moved into a separate PreferenceItems class but you can't access PreferencesMenu.items and PreferencesMenu.preferenceItems from outside.
  /**
   * Creates a pref item that works with booleans
   * @param onChange Gets called every time the player changes the value; use this to apply the value
   * @param defaultValue The value that is loaded in when the pref item is created (usually your Preferences.settingVariable)
   */
  // function createPrefItemCheckbox(prefName:String, prefDesc:String, onChange:Bool->Void, defaultValue:Bool):Void
  // {
  //   var checkbox:CheckboxPreferenceItem = new CheckboxPreferenceItem(0, 120 * (items.length - 1 + 1), defaultValue);
  //   items.createItem(0, (120 * items.length) + 30, prefName, AtlasFont.BOLD, function() {
  //     var value = !checkbox.currentValue;
  //     onChange(value);
  //     checkbox.currentValue = value;
  //   });
  //   preferenceItems.add(checkbox);
  //   preferenceDesc.push(prefDesc);
  // }
  /**
   * Creates a pref item that works with general numbers
   * @param onChange Gets called every time the player changes the value; use this to apply the value
   * @param valueFormatter Will get called every time the game needs to display the float value; use this to change how the displayed value looks
   * @param defaultValue The value that is loaded in when the pref item is created (usually your Preferences.settingVariable)
   * @param min Minimum value (example: 0)
   * @param max Maximum value (example: 10)
   * @param step The value to increment/decrement by (default = 0.1)
   * @param precision Rounds decimals up to a `precision` amount of digits (ex: 4 -> 0.1234, 2 -> 0.12)
   */
  // function createPrefItemNumber(prefName:String, prefDesc:String, onChange:Float->Void, ?valueFormatter:Float->String, defaultValue:Int, min:Int, max:Int,
  //     step:Float = 0.1, precision:Int):Void
  // {
  //   var item = new NumberPreferenceItem(0, (120 * items.length) + 30, prefName, defaultValue, min, max, step, precision, onChange, valueFormatter);
  //   items.addItem(prefName, item);
  //   preferenceItems.add(item.lefthandText);
  //   preferenceDesc.push(prefDesc);
  // }
  /**
   * Creates a pref item that works with number percentages
   * @param onChange Gets called every time the player changes the value; use this to apply the value
   * @param defaultValue The value that is loaded in when the pref item is created (usually your Preferences.settingVariable)
   * @param min Minimum value (default = 0)
   * @param max Maximum value (default = 100)
   */
  // function createPrefItemPercentage(prefName:String, prefDesc:String, onChange:Int->Void, defaultValue:Int, min:Int = 0, max:Int = 100):Void
  // {
  //   var newCallback = function(value:Float) {
  //     onChange(Std.int(value));
  //   };
  //   var formatter = function(value:Float) {
  //     return '${value}%';
  //   };
  //   var item = new NumberPreferenceItem(0, (120 * items.length) + 30, prefName, defaultValue, min, max, 10, 0, newCallback, formatter);
  //   items.addItem(prefName, item);
  //   preferenceItems.add(item.lefthandText);
  //   preferenceDesc.push(prefDesc);
  // }
  /**
   * Creates a pref item that works with enums
   * @param values Maps enum values to display strings _(ex: `NoteHitSoundType.PingPong => "Ping pong"`)_
   * @param onChange Gets called every time the player changes the value; use this to apply the value
   * @param defaultValue The value that is loaded in when the pref item is created (usually your Preferences.settingVariable)
   */
  // function createPrefItemEnum(prefName:String, prefDesc:String, values:Map<String, String>, onChange:String->Void, defaultValue:String):Void
  // {
  //   var item = new EnumPreferenceItem(0, (120 * items.length) + 30, prefName, values, defaultValue, onChange);
  //   items.addItem(prefName, item);
  //   preferenceItems.add(item.lefthandText);
  //   preferenceDesc.push(prefDesc);
  // }
}
