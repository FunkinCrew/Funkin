package funkin.ui.debug.char;

import haxe.io.Path;
import haxe.ui.core.Screen;
import haxe.ui.backend.flixel.UIState;
import haxe.ui.containers.dialogs.Dialog;
import haxe.ui.containers.windows.WindowManager;
import funkin.audio.FunkinSound;
import funkin.input.Cursor;
import funkin.ui.debug.char.pages.*;
import funkin.util.MouseUtil;
import funkin.util.WindowUtil;
import funkin.util.FileUtil;
import flixel.addons.display.FlxGridOverlay;
import flixel.FlxCamera;
import flixel.FlxSprite;
import flixel.FlxG;

/**
 * also made by kolo
 * in collaboration with lemz!
 * most of the functionality is moved to pages so go check them out!
 */
@:build(haxe.ui.ComponentBuilder.build("assets/exclude/data/ui/char-creator/main-view.xml"))
class CharCreatorState extends UIState
{
  var bg:FlxSprite;

  var camHUD:FlxCamera;
  var camGame:FlxCamera;

  var selectedPage:CharCreatorDefaultPage = null;
  var pages:Map<CharCreatorPage, CharCreatorDefaultPage> = []; // collect my pages

  override public function create():Void
  {
    WindowManager.instance.reset();
    FlxG.sound.music?.stop();
    WindowUtil.setWindowTitle("Friday Night Funkin\' Character Creator");

    camGame = new FlxCamera();
    camHUD = new FlxCamera();
    camHUD.bgColor.alpha = 0;

    FlxG.cameras.reset(camGame);
    FlxG.cameras.add(camHUD, false);
    FlxG.cameras.setDefaultDrawTarget(camGame, true);

    persistentUpdate = false;

    bg = FlxGridOverlay.create(10, 10);
    bg.scrollFactor.set();
    add(bg);

    super.create(); // add hud
    setupUICallbacks();

    root.scrollFactor.set();
    root.cameras = [camHUD];

    // Screen.instance.addComponent(root);

    Cursor.show();

    // I feel like there should be more editor themes
    // I don't dislike Artistic Expression or anythin I had simply heard it a million times while making da editors and I'm getting a bit tired of it
    // plus it's called *chart*EditorLoop so CHECKMATE liberals hehe -Kolo
    Conductor.instance.forceBPM(null);
    FunkinSound.playMusic('chartEditorLoop',
      {
        overrideExisting: true,
        restartTrack: true,
        mapTimeChanges: true
      });

    FlxG.sound.music.fadeIn(10, 0, 1);

    this.startWizard(wizardComplete, exitEditor);
  }

  override public function update(elapsed:Float):Void
  {
    super.update(elapsed);
    Conductor.instance.update();

    if (FlxG.mouse.justPressed || FlxG.mouse.justPressedRight) FunkinSound.playOnce(Paths.sound("chartingSounds/ClickDown"));
    if (FlxG.mouse.justReleased || FlxG.mouse.justReleasedRight) FunkinSound.playOnce(Paths.sound("chartingSounds/ClickUp"));

    handleShortcuts();

    if (!CharCreatorUtil.isCursorOverHaxeUI)
    {
      if (camGame.zoom > 0.11) MouseUtil.mouseWheelZoom();
      MouseUtil.mouseCamDrag();
    }

    bg.scale.set(1 / camGame.zoom, 1 / camGame.zoom);
  }

  function setupUICallbacks():Void
  {
    menubarOptionGameplay.onChange = function(_) switchToPage(Gameplay);
    menubarOptionCharSelect.onChange = function(_) switchToPage(CharacterSelect);
    menubarOptionFreeplay.onChange = function(_) switchToPage(Freeplay);
    menubarOptionResults.onChange = function(_) switchToPage(ResultScreen);

    menubarItemNewChar.onClick = _ -> this.startWizard(wizardComplete);
    menubarItemExport.onClick = _ -> this.exportAll();
    menubarItemExit.onClick = _ -> exitEditor();
    menubarItemAbout.onClick = _ -> new CharCreatorAboutDialog().showDialog();

    menubarSliderAnimSpeed.onChange = function(_) {
      FlxG.animationTimeScale = (menubarSliderAnimSpeed.pos / 100);
      menubarLabelAnimSpeed.text = 'Animation Speed: ${menubarSliderAnimSpeed.pos}%';
    }
  }

  function handleShortcuts():Void
  {
    if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.S) this.exportAll();
  }

  var params:WizardGenerateParams;

  function wizardComplete(params:WizardGenerateParams):Void
  {
    // clear da pages sorry chat
    selectedPage = null;
    this.params = params;

    var allPages = [for (k => p in pages) p];
    while (allPages.length > 0)
    {
      var page = allPages.pop();
      page.performCleanup();
      page.kill();
      remove(page, true);
      page.destroy();
    }

    pages.clear();

    if (params.generateCharacter) pages.set(Gameplay, new CharCreatorGameplayPage(this, params));
    if (params.generatePlayerData) pages.set(CharacterSelect, new CharCreatorSelectPage(this, params));
    if (params.generatePlayerData) pages.set(Freeplay, new CharCreatorFreeplayPage(this, params));
    if (params.generatePlayerData) pages.set(ResultScreen, new CharCreatorResultsPage(this, params));

    menubarOptionGameplay.disabled = !params.generateCharacter;
    menubarOptionCharSelect.disabled = menubarOptionFreeplay.disabled = menubarOptionResults.disabled = !params.generatePlayerData;

    menubarOptionGameplay.selected = (params.generateCharacter);
    menubarOptionCharSelect.selected = !(params.generateCharacter);
    menubarOptionFreeplay.selected = menubarOptionResults.selected = false;

    switchToPage(params.generateCharacter ? Gameplay : CharacterSelect);
  }

  function exitEditor():Void
  {
    menubarSliderAnimSpeed.pos = 100;
    Cursor.hide();
    FlxG.switchState(() -> new DebugMenuSubState());
    FunkinSound.playMusic('freakyMenu',
      {
        overrideExisting: true,
        restartTrack: false,
        // Continue playing this music between states, until a different music track gets played.
        persist: true
      });
  }

  function switchToPage(page:CharCreatorPage):Void
  {
    if (selectedPage == pages[page] || pages[page] == null) return;

    for (box in [bottomBarLeftBox, bottomBarMiddleBox, bottomBarRightBox, menubarMenuSettings])
    {
      while (box.childComponents.length > 0)
        box.removeComponent(box.childComponents[0], false);
    }

    remove(selectedPage, true);
    selectedPage = pages[page];
    add(selectedPage);

    selectedPage.fillUpBottomBar(bottomBarLeftBox, bottomBarMiddleBox, bottomBarRightBox);
    selectedPage.fillUpPageSettings(menubarMenuSettings);
  }
}

enum CharCreatorPage
{
  Gameplay;
  CharacterSelect;
  Freeplay;
  ResultScreen;
}

@:build(haxe.ui.macros.ComponentMacros.build("assets/exclude/data/ui/char-creator/components/about.xml"))
class CharCreatorAboutDialog extends Dialog {}
