package funkin.ui.options;

import flixel.FlxCamera;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.group.FlxSpriteGroup;
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

class PreferencesMenu extends Page
{
  public static final DEFAULT_PREFERENCES:Array<PreferenceItemData> = [
    {
      type: "checkbox",
      name: 'Naughtyness',
      desc: 'If enabled, raunchy content (such as swearing, etc.) will be displayed.',
      onChange: function(value:Dynamic) {
        Preferences.naughtyness = cast value;
      },
      defaultValue: Preferences.naughtyness
    },
    {
      type: "checkbox",
      name: 'Downscroll',
      desc: 'If enabled, this will make the notes move downwards.',
      onChange: function(value:Dynamic) {
        Preferences.downscroll = cast value;
      },
      defaultValue: Preferences.downscroll
    },
    {
      type: "checkbox",
      name: 'Flashing Lights',
      desc: 'If disabled, it will dampen flashing effects. Useful for people with photosensitive epilepsy.',
      onChange: function(value:Dynamic) {
        Preferences.flashingLights = cast value;
      },
      defaultValue: Preferences.flashingLights
    },
    {
      type: "checkbox",
      name: 'Camera Zooms',
      desc: 'If disabled, camera stops bouncing to the song.',
      onChange: function(value:Dynamic) {
        Preferences.zoomCamera = cast value;
      },
      defaultValue: Preferences.zoomCamera
    },
    {
      type: "checkbox",
      name: 'Debug Display',
      desc: 'If enabled, FPS and other debug stats will be displayed.',
      onChange: function(value:Dynamic) {
        Preferences.debugDisplay = cast value;
      },
      defaultValue: Preferences.debugDisplay
    },
    {
      type: "checkbox",
      name: 'Auto Pause',
      desc: 'If enabled, game automatically pauses when it loses focus.',
      onChange: function(value:Dynamic) {
        Preferences.autoPause = cast value;
      },
      defaultValue: Preferences.autoPause
    },
    #if web
    {
      type: "checkbox",
      name: 'Unlocked Framerate',
      desc: 'Enable to unlock the framerate',
      onChange: function(value:Dynamic) {
        Preferences.unlockedFramerate = cast value;
      },
      defaultValue: Preferences.unlockedFramerate
    }
    #else
    {
      type: "number",
      name: 'FPS',
      desc: 'The maximum framerate that the game targets',
      onChange: function(value:Dynamic) {
        Preferences.framerate = Std.int(value);
      },
      defaultValue: Preferences.framerate,
      min: 30,
      max: 300,
      step: 5
    }
    #end
  ];

  public var preferencePages:Array<PreferencePageData> = [
    {
      name: "BASE GAME",
      itemDatas: DEFAULT_PREFERENCES
    }
  ];

  var itemsArray:Array<TextMenuList> = [];
  var prefItemsArray:Array<FlxSpriteGroup> = [];

  var currentPage:Int = 0;
  var preferenceDesc:Array<String> = [];
  var itemDesc:FlxText;
  var itemDescBox:FunkinSprite;
  var pageDesc:FlxText;
  var pageDescBox:FunkinSprite;

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

    createPrefItems();

    add(itemDescBox = new FunkinSprite());
    itemDescBox.cameras = [hudCamera];

    add(itemDesc = new FlxText(0, 0, 1180, null, 32));
    itemDesc.cameras = [hudCamera];

    add(pageDescBox = new FunkinSprite());
    pageDescBox.cameras = [hudCamera];

    add(pageDesc = new FlxText(0, 15, 1180, null, 32));
    pageDesc.cameras = [hudCamera];

    createPrefDescription();

    camFollow = new FlxObject(FlxG.width / 2, 0, 140, 70);
    if (itemsArray[currentPage] != null) camFollow.y = itemsArray[currentPage].selectedItem.y;

    menuCamera.follow(camFollow, null, 0.085);
    var margin = 160;
    menuCamera.deadzone.set(0, margin, menuCamera.width, menuCamera.height - margin * 2);
    menuCamera.minScrollY = 0;
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
    itemDesc.text = preferencePages[currentPage].itemDatas[itemsArray[currentPage].selectedIndex].desc;
    itemDesc.screenCenter();
    itemDesc.y += 270;

    // Create the box around the text.
    itemDescBox.setPosition(itemDesc.x - 10, itemDesc.y - 10);
    itemDescBox.setGraphicSize(Std.int(itemDesc.width + 20), Std.int(itemDesc.height + 25));
    itemDescBox.updateHitbox();

    // Create the stuff for Pages.
    pageDescBox.makeSolidColor(1, 1, FlxColor.BLACK);
    pageDescBox.alpha = 0.6;
    pageDesc.setFormat(Paths.font('vcr.ttf'), 32, FlxColor.WHITE, FlxTextAlign.CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
    pageDesc.borderSize = 3;

    // Update the page text.
    pageDesc.text = preferencePages[currentPage].name;
    pageDesc.screenCenter(X);

    // Create the box around the page text.
    pageDescBox.setPosition(pageDesc.x - 10, pageDesc.y - 10);
    pageDescBox.setGraphicSize(Std.int(pageDesc.width + 20), Std.int(pageDesc.height + 25));
    pageDescBox.updateHitbox();
  }

  /**
   * Create the menu items for each of the preferences.
   */
  function createPrefItems():Void
  {
    // Clean up before generating.
    while (itemsArray.length > 0)
    {
      var item = itemsArray.pop();
      item.kill();
      remove(item, true);
      item.destroy();
    }

    while (prefItemsArray.length > 0)
    {
      var item = prefItemsArray.pop();
      item.kill();
      remove(item, true);
      item.destroy();
    }

    for (i in 0...preferencePages.length)
    {
      var items = new TextMenuList();
      itemsArray.push(items);

      var prefItems = new FlxSpriteGroup();
      prefItemsArray.push(prefItems);

      for (pref in preferencePages[i].itemDatas)
      {
        switch (pref.type)
        {
          case "number":
            var floatFunc:Float->Void = function(value:Float) pref.onChange(value);
            createPrefItemNumber(i, pref.name, pref.desc, floatFunc, pref.formatter, cast pref.defaultValue, pref.min ?? 0, pref.max ?? 10, pref.step ?? 0.1,
              pref.precision ?? 0);

          case "percentage":
            var intFunc:Int->Void = function(value:Int) pref.onChange(value);
            createPrefItemPercentage(i, pref.name, pref.desc, intFunc, cast pref.defaultValue, pref.min ?? 0, pref.max ?? 100);

          case "enum":
            var stringFunc:String->Void = function(value:String) pref.onChange(value);
            createPrefItemEnum(i, pref.name, pref.desc, pref.values ?? new Map<String, String>(), stringFunc, cast pref.defaultValue);

          default: // checkbox preference
            var boolFunc:Bool->Void = function(value:Bool) pref.onChange(value);
            createPrefItemCheckbox(i, pref.name, pref.desc, boolFunc, cast pref.defaultValue);
        }
      }

      items.enabled = false;
      items.onChange.add(function(selected) {
        camFollow.y = selected.y;
        itemDesc.text = preferencePages[currentPage].itemDatas[itemsArray[currentPage].selectedIndex].desc;
      });
    }

    itemsArray[currentPage].enabled = true;
    add(itemsArray[currentPage]);
    add(prefItemsArray[currentPage]);
  }

  override function update(elapsed:Float):Void
  {
    super.update(elapsed);

    if (itemsArray.length != preferencePages.length)
    {
      createPrefItems();
    }

    if (FlxG.keys.justPressed.Q) changePage(-1);
    if (FlxG.keys.justPressed.E) changePage(1);

    // Indent the selected item.
    itemsArray[currentPage].forEach(function(daItem:TextMenuItem) {
      var thyOffset:Int = 0;
      // Initializing thy text width (if thou text present)
      var thyTextWidth:Int = 0;
      if (Std.isOfType(daItem, EnumPreferenceItem)) thyTextWidth = cast(daItem, EnumPreferenceItem).lefthandText.getWidth();
      else if (Std.isOfType(daItem, NumberPreferenceItem)) thyTextWidth = cast(daItem, NumberPreferenceItem).lefthandText.getWidth();

      if (thyTextWidth != 0)
      {
        // Magic number because of the weird offset thats being added by default
        thyOffset += thyTextWidth - 75;
      }

      if (itemsArray[currentPage].selectedItem == daItem)
      {
        thyOffset += 150;
      }
      else
      {
        thyOffset += 120;
      }

      daItem.x = thyOffset;
    });
  }

  function changePage(change:Int = 0)
  {
    itemsArray[currentPage].enabled = false;
    remove(itemsArray[currentPage]);
    remove(prefItemsArray[currentPage]);

    currentPage += change;

    if (currentPage >= preferencePages.length) currentPage = 0;
    else if (currentPage < 0) currentPage = preferencePages.length - 1;

    itemsArray[currentPage].enabled = true;
    add(itemsArray[currentPage]);
    add(prefItemsArray[currentPage]);
    itemsArray[currentPage].selectItem(itemsArray[currentPage].selectedIndex);

    pageDesc.text = preferencePages[currentPage].name;

    FunkinSound.playOnce(Paths.sound('scrollMenu'), 0.4);
  }

  // - Preference item creation methods -
  // Should be moved into a separate PreferenceItems class but you can't access PreferencesMenu.items and PreferencesMenu.preferenceItems from outside.

  /**
   * Creates a pref item that works with booleans
   * @param onChange Gets called every time the player changes the value; use this to apply the value
   * @param defaultValue The value that is loaded in when the pref item is created (usually your Preferences.settingVariable)
   */
  function createPrefItemCheckbox(index:Int, prefName:String, prefDesc:String, onChange:Bool->Void, defaultValue:Bool):Void
  {
    var checkbox:CheckboxPreferenceItem = new CheckboxPreferenceItem(0, 120 * (itemsArray[index].length - 1 + 1) + 25, defaultValue);

    itemsArray[index].createItem(0, (120 * itemsArray[index].length) + 55, prefName, AtlasFont.BOLD, function() {
      var value = !checkbox.currentValue;
      onChange(value);
      checkbox.currentValue = value;
    });

    prefItemsArray[index].add(checkbox);
  }

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
  function createPrefItemNumber(index:Int, prefName:String, prefDesc:String, onChange:Float->Void, ?valueFormatter:Float->String, defaultValue:Int, min:Int,
      max:Int, step:Float = 0.1, precision:Int):Void
  {
    var item = new NumberPreferenceItem(0, (120 * itemsArray[index].length) + 55, prefName, defaultValue, min, max, step, precision, onChange, valueFormatter);
    itemsArray[index].addItem(prefName, item);
    prefItemsArray[index].add(item.lefthandText);
  }

  /**
   * Creates a pref item that works with number percentages
   * @param onChange Gets called every time the player changes the value; use this to apply the value
   * @param defaultValue The value that is loaded in when the pref item is created (usually your Preferences.settingVariable)
   * @param min Minimum value (default = 0)
   * @param max Maximum value (default = 100)
   */
  function createPrefItemPercentage(index:Int, prefName:String, prefDesc:String, onChange:Int->Void, defaultValue:Int, min:Int = 0, max:Int = 100):Void
  {
    var newCallback = function(value:Float) {
      onChange(Std.int(value));
    };
    var formatter = function(value:Float) {
      return '${value}%';
    };
    var item = new NumberPreferenceItem(0, (120 * itemsArray[index].length) + 55, prefName, defaultValue, min, max, 10, 0, newCallback, formatter);
    itemsArray[index].addItem(prefName, item);
    prefItemsArray[index].add(item.lefthandText);
  }

  /**
   * Creates a pref item that works with enums
   * @param values Maps enum values to display strings _(ex: `NoteHitSoundType.PingPong => "Ping pong"`)_
   * @param onChange Gets called every time the player changes the value; use this to apply the value
   * @param defaultValue The value that is loaded in when the pref item is created (usually your Preferences.settingVariable)
   */
  function createPrefItemEnum(index:Int, prefName:String, prefDesc:String, values:Map<String, String>, onChange:String->Void, defaultValue:String):Void
  {
    var item = new EnumPreferenceItem(0, (120 * itemsArray[index].length) + 55, prefName, values, defaultValue, onChange);
    itemsArray[index].addItem(prefName, item);
    prefItemsArray[index].add(item.lefthandText);
  }
}

typedef PreferencePageData =
{
  var name:String;
  var itemDatas:Array<PreferenceItemData>;
}

typedef PreferenceItemData =
{
  var type:String;
  var name:String;
  var desc:String;
  var onChange:Dynamic->Void;
  var defaultValue:Dynamic;

  // number preference stuff
  var ?min:Int;
  var ?max:Int;
  var ?step:Float;
  var ?formatter:Float->String;
  var ?precision:Int;

  // enum preference stuff
  var ?values:Map<String, String>;
}
