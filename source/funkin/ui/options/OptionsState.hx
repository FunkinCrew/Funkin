package funkin.ui.options;

import funkin.ui.debug.latency.LatencyState;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.addons.transition.FlxTransitionableState;
import flixel.group.FlxGroup;
import flixel.util.FlxSignal;
import funkin.audio.FunkinSound;
import funkin.ui.mainmenu.MainMenuState;
import funkin.ui.MusicBeatState;
import funkin.graphics.shaders.HSVShader;
import funkin.util.WindowUtil;
import funkin.audio.FunkinSound;
import funkin.input.Controls;
#if mobile
import funkin.mobile.ui.FunkinBackspace;
import funkin.mobile.util.TouchUtil;
#end
import flixel.util.FlxColor;

class OptionsState extends MusicBeatState
{
  var pages = new Map<PageName, Page>();
  var currentName:PageName = Options;
  var currentPage(get, never):Page;

  inline function get_currentPage():Page
    return pages[currentName];

  override function create():Void
  {
    persistentUpdate = true;

    var menuBG = new FlxSprite().loadGraphic(Paths.image('menuBG'));
    var hsv = new HSVShader();
    hsv.hue = -0.6;
    hsv.saturation = 0.9;
    hsv.value = 3.6;
    menuBG.shader = hsv;
    FlxG.debugger.track(hsv);
    menuBG.setGraphicSize(Std.int(menuBG.width * 1.1));
    menuBG.updateHitbox();
    menuBG.screenCenter();
    menuBG.scrollFactor.set(0, 0);
    add(menuBG);

    var options = addPage(Options, new OptionsMenu());
    var preferences = addPage(Preferences, new PreferencesMenu());
    var controls = addPage(Controls, new ControlsMenu());

    if (options.hasMultipleOptions())
    {
      options.onExit.add(exitToMainMenu);
      controls.onExit.add(exitControls);
      preferences.onExit.add(switchPage.bind(Options));
    }
    else
    {
      // No need to show Options page
      #if mobile
      preferences.onExit.add(exitToMainMenu);
      setPage(Preferences);
      #else
      controls.onExit.add(exitToMainMenu);
      setPage(Controls);
      #end
    }

    super.create();
  }

  function addPage<T:Page>(name:PageName, page:T)
  {
    page.onSwitch.add(switchPage);
    pages[name] = page;
    add(page);
    page.exists = currentName == name;
    return page;
  }

  function setPage(name:PageName)
  {
    if (pages.exists(currentName))
    {
      currentPage.exists = false;
      currentPage.visible = false;
    }

    currentName = name;

    if (pages.exists(currentName))
    {
      currentPage.exists = true;
      currentPage.visible = true;
    }
  }

  function switchPage(name:PageName)
  {
    // TODO: Animate this transition?
    setPage(name);
  }

  function exitControls():Void
  {
    // Apply any changes to the controls.
    PlayerSettings.reset();
    PlayerSettings.init();

    switchPage(Options);
  }

  function exitToMainMenu()
  {
    currentPage.enabled = false;
    // TODO: Animate this transition?
    FlxG.switchState(() -> new MainMenuState());
  }
}

class Page extends FlxGroup
{
  public var onSwitch(default, null) = new FlxTypedSignal<PageName->Void>();
  public var onExit(default, null) = new FlxSignal();

  public var enabled(default, set) = true;
  public var canExit = true;

  var controls(get, never):Controls;
  var currentName(default, set):PageName = Options;

  inline function get_controls()
    return PlayerSettings.player1.controls;

  function set_currentName(value:PageName):PageName
    return currentName = value;

  #if mobile
  var backButton:FunkinBackspace;
  #end

  var subState:FlxSubState;

  inline function switchPage(name:PageName)
  {
    onSwitch.dispatch(name);
  }

  inline function exit()
  {
    onExit.dispatch();
  }

  override function update(elapsed:Float)
  {
    super.update(elapsed);

    if (enabled) updateEnabled(elapsed);
  }

  function updateEnabled(elapsed:Float)
  {
    // This fucking auto-formatter sucks and i REFUSE to make this more than 1 variable
    if (canExit && (controls.BACK #if mobile || (backButton != null && TouchUtil.overlapsComplex(backButton) && TouchUtil.justPressed) #end))
    {
      exit();
      FunkinSound.playOnce(Paths.sound('cancelMenu'));
    }
  }

  function set_enabled(value:Bool)
  {
    return this.enabled = value;
  }

  function openPrompt(prompt:Prompt, onClose:Void->Void)
  {
    enabled = false;
    prompt.closeCallback = function() {
      enabled = true;
      if (onClose != null) onClose();
    }

    FlxG.state.openSubState(prompt);
  }

  override function destroy()
  {
    super.destroy();
    onSwitch.removeAll();
  }
}

class OptionsMenu extends Page
{
  var items:TextMenuList;

  public function new()
  {
    super();

    add(items = new TextMenuList());
    createItem("PREFERENCES", function() switchPage(Preferences));
    #if mobile
    if (FlxG.gamepads.numActiveGamepads > 0)
    {
      createItem("CONTROLS", function() switchPage(Controls));
      createItem("INPUT OFFSETS", function() {
        FlxG.state.openSubState(new LatencyState());
      });
    }
    #else
    createItem("CONTROLS", function() switchPage(Controls));
    createItem("INPUT OFFSETS", function() {
      FlxG.state.openSubState(new LatencyState());
    });
    #end

    #if newgrounds
    if (NGio.isLoggedIn) createItem("LOGOUT", selectLogout);
    else
      createItem("LOGIN", selectLogin);
    #end
    createItem("EXIT", exit);
  }

  function createItem(name:String, callback:Void->Void, fireInstantly = false)
  {
    var item = items.createItem(0, 100 + items.length * 100, name, BOLD, callback);
    item.fireInstantly = fireInstantly;
    item.screenCenter(X);
    return item;
  }

  override function set_enabled(value:Bool)
  {
    items.enabled = value;
    return super.set_enabled(value);
  }

  /**
   * True if this page has multiple options, excluding the exit option.
   * If false, there's no reason to ever show this page.
   */
  public function hasMultipleOptions():Bool
  {
    return items.length > 2;
  }

  #if newgrounds
  function selectLogin()
  {
    openNgPrompt(NgPrompt.showLogin());
  }

  function selectLogout()
  {
    openNgPrompt(NgPrompt.showLogout());
  }

  /**
   * Calls openPrompt and redraws the login/logout button
   * @param prompt
   * @param onClose
   */
  public function openNgPrompt(prompt:Prompt, ?onClose:Void->Void)
  {
    var onPromptClose = checkLoginStatus;
    if (onClose != null)
    {
      onPromptClose = function() {
        checkLoginStatus();
        onClose();
      }
    }

    openPrompt(prompt, onPromptClose);
  }

  function checkLoginStatus()
  {
    // this shit don't work!! wtf!!!!
    var prevLoggedIn = items.has("logout");
    if (prevLoggedIn && !NGio.isLoggedIn) items.resetItem("logout", "login", selectLogin);
    else if (!prevLoggedIn && NGio.isLoggedIn) items.resetItem("login", "logout", selectLogout);
  }
  #end
}

enum abstract PageName(String)
{
  var Options = "options";
  var Controls = "controls";
  var Colors = "colors";
  var Mods = "mods";
  var Preferences = "preferences";
}
