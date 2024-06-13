package funkin.ui.options;

import flixel.FlxCamera;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import funkin.ui.AtlasText.AtlasFont;
import funkin.ui.options.OptionsState.Page;
import funkin.ui.options.items.CheckboxPreferenceItem;
import funkin.ui.options.items.PercentagePreferenceItem;
import funkin.ui.options.items.EnumPreferenceItem;
import funkin.graphics.FunkinCamera;
import funkin.ui.TextMenuList.TextMenuItem;
import funkin.audio.FunkinSound;
import funkin.ui.options.MenuItemEnums;

class PreferencesMenu extends Page
{
  var items:TextMenuList;
  var preferenceItems:FlxTypedSpriteGroup<FlxSprite>;

  var menuCamera:FlxCamera;
  var camFollow:FlxObject;

  public function new()
  {
    super();

    menuCamera = new FunkinCamera('prefMenu');
    FlxG.cameras.add(menuCamera, false);
    menuCamera.bgColor = 0x0;
    camera = menuCamera;

    add(items = new TextMenuList());
    add(preferenceItems = new FlxTypedSpriteGroup<FlxSprite>());

    createPrefItems();

    camFollow = new FlxObject(FlxG.width / 2, 0, 140, 70);
    if (items != null) camFollow.y = items.selectedItem.y;

    menuCamera.follow(camFollow, null, 0.06);
    var margin = 160;
    menuCamera.deadzone.set(0, margin, menuCamera.width, 40);
    menuCamera.minScrollY = 0;

    items.onChange.add(function(selected) {
      camFollow.y = selected.y;
    });
  }

  /**
   * Create the menu items for each of the preferences.
   */
  function createPrefItems():Void
  {
    createPrefItemCheckbox('Naughtyness', 'Toggle displaying raunchy content', function(value:Bool):Void {
      Preferences.naughtyness = value;
    }, Preferences.naughtyness);
    createPrefItemCheckbox('Downscroll', 'Enable to make notes move downwards', function(value:Bool):Void {
      Preferences.downscroll = value;
    }, Preferences.downscroll);
    createPrefItemPercentage('Note hit sound volume', 'Enable to play a click sound when hitting notes', function(value:Int):Void {
      Preferences.noteHitSoundVolume = value;
    }, Preferences.noteHitSoundVolume);
    createPrefItemEnum('Note hit sound', 'Enable to play a click sound when hitting notes', [
      NoteHitSoundType.None => "None",
      NoteHitSoundType.PingPong => "Ping pong",
      NoteHitSoundType.VineBoom => "Vine boom"
    ], function(value:String):Void {
      Preferences.noteHitSound = value;
      var hitSound:String = value + "Hit";
      FunkinSound.playOnce(Paths.sound('noteHitSounds/${hitSound}') ?? Paths.sound('noteHitSounds/pingPongHit'));
    }, Preferences.noteHitSound);
    createPrefItemCheckbox('Note splashiness', 'Disable to remove splash animations when hitting notes', function(value:Bool):Void {
      Preferences.noteSplash = value;
    }, Preferences.noteSplash);
    createPrefItemCheckbox('Flashing Lights', 'Disable to dampen flashing effects', function(value:Bool):Void {
      Preferences.flashingLights = value;
    }, Preferences.flashingLights);
    createPrefItemCheckbox('Camera Zooming on Beat', 'Disable to stop the camera bouncing to the song', function(value:Bool):Void {
      Preferences.zoomCamera = value;
    }, Preferences.zoomCamera);
    createPrefItemCheckbox('Debug Display', 'Enable to show FPS and other debug stats', function(value:Bool):Void {
      Preferences.debugDisplay = value;
    }, Preferences.debugDisplay);
    createPrefItemCheckbox('Auto Pause', 'Automatically pause the game when it loses focus', function(value:Bool):Void {
      Preferences.autoPause = value;
    }, Preferences.autoPause);
  }

  override function update(elapsed:Float)
  {
    super.update(elapsed);

    // Indent the selected item.
    // TODO: Only do this on menu change?
    items.forEach(function(daItem:TextMenuItem) {
      var thyOffset:Int = 0;
      if (Std.isOfType(daItem, EnumPreferenceItem)) thyOffset = cast(daItem, EnumPreferenceItem).lefthandText.getWidth();
      if (Std.isOfType(daItem, PercentagePreferenceItem)) thyOffset = cast(daItem, PercentagePreferenceItem).lefthandText.getWidth();

      // Very messy but it works
      if (thyOffset == 0)
      {
        if (items.selectedItem == daItem) thyOffset += 150;
        else
          thyOffset += 120;
      }
      else if (items.selectedItem == daItem)
      {
        thyOffset += 70;
      }
      else
      {
        thyOffset += 25;
      }

      daItem.x = thyOffset;
    });
  }

  function createPrefItemCheckbox(prefName:String, prefDesc:String, onChange:Bool->Void, defaultValue:Bool):Void
  {
    var checkbox:CheckboxPreferenceItem = new CheckboxPreferenceItem(0, 120 * (items.length - 1 + 1), defaultValue);

    items.createItem(120, (120 * items.length) + 30, prefName, AtlasFont.BOLD, function() {
      var value = !checkbox.currentValue;
      onChange(value);
      checkbox.currentValue = value;
    });

    preferenceItems.add(checkbox);
  }

  /**
   * @param zeroIsDisabled If true, 0 will be displayed as "OFF"
   */
  function createPrefItemPercentage(prefName:String, prefDesc:String, onChange:Int->Void, defaultValue:Int, min:Int = 0, max:Int = 100,
      zeroIsDisabled:Bool = false):Void
  {
    var item = new PercentagePreferenceItem(145, (120 * items.length) + 30, prefName, defaultValue, min, max, zeroIsDisabled, onChange);
    items.addItem(prefName, item);
    preferenceItems.add(item.lefthandText);
  }

  function createPrefItemEnum(prefName:String, prefDesc:String, values:Map<String, String>, onChange:String->Void, defaultValue:String):Void
  {
    var item = new EnumPreferenceItem(145, (120 * items.length) + 30, prefName, values, defaultValue, onChange);
    items.addItem(prefName, item);
    preferenceItems.add(item.lefthandText);
  }
}
