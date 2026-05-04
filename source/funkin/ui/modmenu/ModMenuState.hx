package funkin.ui.modmenu;

import funkin.input.Cursor;
import funkin.util.FileUtil;
import funkin.ui.mainmenu.MainMenuState;
import funkin.audio.FunkinSound;
import funkin.graphics.FunkinSprite;
import funkin.modding.PolymodHandler;
import polymod.Polymod.ModMetadata;
import funkin.save.Save;
import funkin.ui.MusicBeatState;
import flixel.FlxG;
import flixel.util.FlxColor;
import flixel.text.FlxText;

/**
 * The user interface for the mod menu.
 */
@:nullSafety
class ModMenuState extends MusicBeatState
{
  var leftRectangle:FunkinSprite = new FunkinSprite();
  var rightRectangle:FunkinSprite = new FunkinSprite();
  var buttonBackToMenu:FunkinSprite = new FunkinSprite();
  var buttonOpenFolder:FunkinSprite = new FunkinSprite();
  var buttonDone:FunkinSprite = new FunkinSprite();

  /**
   * This flag is enabled when returning to the main menu.
   * This should disable other interaction.
   */
  var exitingMenu:Bool = false;

  var disabledModItems:ModMenuItemList = new ModMenuItemList();
  var enabledModItems:ModMenuItemList = new ModMenuItemList();
  var selection:ModMenuSelection = DisabledModList;

  public function new()
  {
    super();
  }

  override public function create():Void
  {
    super.create();

    // Show a simple background.
    var menuBG = FunkinSprite.create('ui/main-menu/menu-desat');
    menuBG.color = 0xFF999999;
    menuBG.setGraphicSize(Std.int(menuBG.width * 1.1));
    menuBG.updateHitbox();
    menuBG.screenCenter();
    menuBG.scrollFactor.set(0, 0);
    menuBG.zIndex = -1000;
    add(menuBG);

    var background:FunkinSprite = new FunkinSprite(24, 24);
    background.makeSolidColor(FlxG.width - 48, FlxG.height - 48, FlxColor.BLACK);
    background.alpha = 0.7;
    add(background);

    var topText:FlxText = new FlxText(112, 48, FlxG.width, 'FUCKING COOL ASS MOD MENU');
    topText.setFormat(funkin.assets.Paths.font('ui/fonts/VCR OSD Mono'), 24, FlxColor.WHITE);
    add(topText);

    leftRectangle.x = 52;
    leftRectangle.y = 112;
    var width:Float = (background.width - 12) / 3.0;
    leftRectangle.makeSolidColor(cast width, cast(background.height - 132, Int), FlxColor.BLACK);
    leftRectangle.alpha = 0.5;
    add(leftRectangle);

    rightRectangle.x = leftRectangle.x + leftRectangle.width + 48;
    rightRectangle.y = 112;
    rightRectangle.makeSolidColor(cast width, cast(background.height - 132, Int), FlxColor.BLACK);
    rightRectangle.alpha = 0.5;
    add(rightRectangle);

    var bfAndGF:FunkinSprite = new FunkinSprite();
    bfAndGF.x = 960;
    bfAndGF.y = 256;
    bfAndGF.loadTexture('ui/mods/one-million-followers-on-tiktok-or-gf-fucking-dies');
    add(bfAndGF);

    buttonBackToMenu.x = 8;
    buttonBackToMenu.y = 32;
    buttonBackToMenu.loadTexture('ui/mods/mod-menu-back');
    add(buttonBackToMenu);

    buttonDone.x = 960;
    buttonDone.y = 640;
    buttonDone.loadTexture('ui/mods/mod-menu-done');
    add(buttonDone);

    buttonOpenFolder.x = 16;
    buttonOpenFolder.y = 640;
    buttonOpenFolder.loadTexture('ui/mods/mod-menu-open-folder');
    add(buttonOpenFolder);

    buildDisabledModList();
    buildEnabledModList();

    applyInitialSelection();

    Cursor.show();
  }

  override public function update(elapsed:Float):Void
  {
    super.update(elapsed);

    handleMouse();
    handleKeyboard();
  }

  function applyInitialSelection():Void
  {
    disabledModItems.selectFirstItem();
  }

  function handleMouse():Void
  {
    if (FlxG.mouse.justPressed)
    {
      // TODO: Make this less bad

      var target = FlxG.mouse.getWorldPosition();

      if (buttonBackToMenu.overlapsPoint(target))
      {
        backToMainMenu();
      }
      else if (buttonOpenFolder.overlapsPoint(target))
      {
        openModsFolder();
      }
    }
  }

  function handleKeyboard():Void
  {
    if (controls.UI_UP_P)
    {
      switch (selection)
      {
        case DisabledModList:
          var shouldDeselect:Bool = disabledModItems.moveUp();
        case EnabledModList:
          var shouldDeselect:Bool = enabledModItems.moveUp();
        case BackToMenu:
          // Don't do anything
        case OpenModsFolder:
          selection = DisabledModList;
        case Done:
          selection = DisabledModList;
      }
    }

    if (controls.UI_DOWN_P)
    {
      switch (selection)
      {
        case DisabledModList:
          var shouldDeselect:Bool = disabledModItems.moveDown();
        case EnabledModList:
          var shouldDeselect:Bool = enabledModItems.moveDown();
        case BackToMenu:
          selection = DisabledModList;
        case OpenModsFolder:
          // Don't do anything
        case Done:
          // Don't do anything
      }
    }

    if (controls.UI_LEFT_P)
    {
      switch (selection)
      {
        case DisabledModList:
          // Don't do anything
        case EnabledModList:
          enabledModItems.moveLeft();
        case BackToMenu:
          // Don't do anything
        case OpenModsFolder:
          // Don't do anything
        case Done:
          selection = OpenModsFolder;
      }
    }

    if (controls.UI_RIGHT_P)
    {
      switch (selection)
      {
        case DisabledModList:
          disabledModItems.moveRight();
        case EnabledModList:
          // Don't do anything
        case BackToMenu:
          // Don't do anything
        case OpenModsFolder:
          selection = Done;
        case Done:
          // Don't do anything
      }
    }

    if (controls.ACCEPT_P)
    {
      switch (selection)
      {
        case DisabledModList:
          disabledModItems.onAccept();
        case EnabledModList:
          enabledModItems.onAccept();
        case BackToMenu:
          backToMainMenu();
        case OpenModsFolder:
          openModsFolder();
        case Done:
          applyModlist();
      }
    }
  }

  function buildDisabledModList():Void
  {
    var disabledMods:Array<ModMetadata> = PolymodHandler.getDisabledMods();

    disabledModItems.x = leftRectangle.x;
    disabledModItems.y = leftRectangle.y;

    for (mod in disabledMods)
    {
      disabledModItems.addMod(mod);
    }

    add(disabledModItems);
  }

  function buildEnabledModList():Void
  {
    var enabledMods:Array<ModMetadata> = PolymodHandler.getEnabledMods();

    enabledModItems.x = rightRectangle.x;
    enabledModItems.y = rightRectangle.y;

    for (mod in enabledMods)
    {
      enabledModItems.addMod(mod);
    }

    add(enabledModItems);
  }

  function applyModlist():Void
  {
    // Backup the user's save data before switching mods.
    var backupSlot:Int = Save.system.archiveBadSaveData(FlxG.save.data);
    trace('[SAVE] Backed up current save data in case of emergency to $backupSlot!');
  }

  /**
   * Open the folder where the user's mods are stored.
   */
  function openModsFolder():Void
  {
    FileUtil.openFolder(PolymodHandler.MOD_FOLDER);
  }

  /**
   * Return to the main menu.
   */
  function backToMainMenu():Void
  {
    exitingMenu = true;
    FlxG.keys.enabled = false;
    Cursor.hide();
    FlxG.switchState(() -> new MainMenuState());
    FunkinSound.playOnce(Paths.sound('ui/main-menu/cancel-menu'));
  }
}

enum ModMenuSelection
{
  DisabledModList;
  EnabledModList;
  BackToMenu;
  OpenModsFolder;
  Done;
}
