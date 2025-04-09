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
    addOption(PreferenceType.Percentage, 'Strumline Background', 'The strumline background\'s transparency percentage.', function(value:Int):Void {
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

    addOption(PreferenceType.Checkbox, 'Fancy Preview', 'If enabled, a preview will be shown after taking a screenshot.', function(value:Bool):Void {
      Preferences.fancyPreview = value;
    }, Preferences.fancyPreview);
    addOption(PreferenceType.Checkbox, 'Preview on save', 'If enabled, the preview will be shown only after a screenshot is saved.', function(value:Bool):Void {
      Preferences.previewOnSave = value;
    }, Preferences.previewOnSave);
    addOption(PreferenceType.Enum, 'Save Format', 'Save screenshots to this format.', function(value:String):Void {
      Preferences.saveFormat = value;
    }, Preferences.saveFormat, { values: ['PNG' => 'PNG', 'JPEG' => 'JPEG'] });
    addOption(PreferenceType.Number, 'JPEG Quality', 'The quality of JPEG screenshots.', function(value:Float) {
      Preferences.jpegQuality = Std.int(value);
    }, Preferences.jpegQuality, { min: 0, max: 100, step: 5, precision: 0 });
  }

  function addOption(type:PreferenceType, name:String, description:String, onChange:Null<Dynamic->Void>, defaultValue:Dynamic, ?data:PreferenceItemData):Void
  {
    var item = new PreferenceItem(0, 60 * (options.length + categories.length) + 15, type, name, description, onChange, defaultValue, data);
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
        case PreferenceType.Number, PreferenceType.Percentage:
          thyTextWidth = cast(daItem.preferenceGraphic, NumberPreferenceItem).label.getWidth();
        case PreferenceType.Enum:
          thyTextWidth = cast(daItem.preferenceGraphic, EnumPreferenceItem).label.getWidth();
        case PreferenceType.Checkbox:
          thyTextWidth = Std.int(daItem.preferenceGraphic.width);
      }

      // setting the thy offset
      thyOffset = thyTextWidth + PreferenceItem.SPACING_X;

      daItem.text.x = thyOffset;
    });
  }
}
