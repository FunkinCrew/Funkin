package funkin;

import funkin.ui.debug.DebugMenuSubState;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.addons.transition.FlxTransitionableState;
import flixel.effects.FlxFlicker;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.input.touch.FlxTouch;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.ui.FlxButton;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import funkin.NGio;
import funkin.modding.events.ScriptEvent.UpdateScriptEvent;
import funkin.modding.module.ModuleHandler;
import funkin.shaderslmfao.ScreenWipeShader;
import funkin.ui.AtlasMenuList;
import funkin.ui.MenuList.MenuItem;
import funkin.ui.MenuList;
import funkin.ui.story.StoryMenuState;
import funkin.ui.OptionsState;
import funkin.ui.PreferencesMenu;
import funkin.ui.Prompt;
import funkin.util.WindowUtil;
import lime.app.Application;
import openfl.filters.ShaderFilter;
#if discord_rpc
import Discord.DiscordClient;
#end
#if newgrounds
import funkin.ui.NgPrompt;
import io.newgrounds.NG;
#end

class MainMenuState extends MusicBeatState
{
  var menuItems:MenuTypedList<AtlasMenuItem>;

  var magenta:FlxSprite;
  var camFollow:FlxObject;

  override function create()
  {
    #if discord_rpc
    // Updating Discord Rich Presence
    DiscordClient.changePresence("In the Menus", null);
    #end

    transIn = FlxTransitionableState.defaultTransIn;
    transOut = FlxTransitionableState.defaultTransOut;

    if (!FlxG.sound.music.playing)
    {
      FlxG.sound.playMusic(Paths.music('freakyMenu'));
    }

    persistentUpdate = persistentDraw = true;

    var bg:FlxSprite = new FlxSprite(Paths.image('menuBG'));
    bg.scrollFactor.x = 0;
    bg.scrollFactor.y = 0.17;
    bg.setGraphicSize(Std.int(bg.width * 1.2));
    bg.updateHitbox();
    bg.screenCenter();
    add(bg);

    camFollow = new FlxObject(0, 0, 1, 1);
    add(camFollow);

    magenta = new FlxSprite(Paths.image('menuDesat'));
    magenta.scrollFactor.x = bg.scrollFactor.x;
    magenta.scrollFactor.y = bg.scrollFactor.y;
    magenta.setGraphicSize(Std.int(bg.width));
    magenta.updateHitbox();
    magenta.x = bg.x;
    magenta.y = bg.y;
    magenta.visible = false;
    magenta.color = 0xFFfd719b;
    if (PreferencesMenu.preferences.get('flashing-menu')) add(magenta);
    // magenta.scrollFactor.set();

    menuItems = new MenuTypedList<AtlasMenuItem>();
    add(menuItems);
    menuItems.onChange.add(onMenuItemChange);
    menuItems.onAcceptPress.add(function(_) {
      if (_.name == 'freeplay')
      {
        magenta.visible = true;
      }
      else
      {
        FlxFlicker.flicker(magenta, 1.1, 0.15, false, true);
      }
    });

    menuItems.enabled = true; // can move on intro
    createMenuItem('storymode', 'mainmenu/storymode', function() startExitState(new StoryMenuState()));
    createMenuItem('freeplay', 'mainmenu/freeplay', function() {
      persistentDraw = true;
      persistentUpdate = false;
      openSubState(new FreeplayState());
    });

    #if CAN_OPEN_LINKS
    var hasPopupBlocker = #if web true #else false #end;
    createMenuItem('donate', 'mainmenu/donate', selectDonate, hasPopupBlocker);
    #end

    createMenuItem('options', 'mainmenu/options', function() {
      startExitState(new OptionsState());
    });

    // Reset position of menu items.
    var spacing = 160;
    var top = (FlxG.height - (spacing * (menuItems.length - 1))) / 2;
    for (i in 0...menuItems.length)
    {
      var menuItem = menuItems.members[i];
      menuItem.x = FlxG.width / 2;
      menuItem.y = top + spacing * i;
    }

    resetCamStuff();

    subStateClosed.add(_ -> {
      resetCamStuff();
    });

    subStateOpened.add(sub -> {
      if (Type.getClass(sub) == FreeplayState)
      {
        new FlxTimer().start(0.5, _ -> {
          magenta.visible = false;
        });
      }
    });

    // FlxG.camera.setScrollBounds(bg.x, bg.x + bg.width, bg.y, bg.y + bg.height * 1.2);

    super.create();

    // This has to come AFTER!
    this.leftWatermarkText.text = Constants.VERSION;
    // this.rightWatermarkText.text = "blablabla test";

    // NG.core.calls.event.logEvent('swag').send();
  }

  function resetCamStuff()
  {
    FlxG.cameras.reset(new SwagCamera());
    FlxG.camera.follow(camFollow, null, 0.06);
  }

  function createMenuItem(name:String, atlas:String, callback:Void->Void, fireInstantly:Bool = false):Void
  {
    var item = new AtlasMenuItem(name, Paths.getSparrowAtlas(atlas), callback);
    item.fireInstantly = fireInstantly;
    item.ID = menuItems.length;

    item.scrollFactor.set();

    // Set the offset of the item so the sprite is centered on the origin.
    item.centered = true;
    item.changeAnim('idle');

    menuItems.addItem(name, item);
  }

  override function closeSubState()
  {
    magenta.visible = false;

    super.closeSubState();
  }

  override function finishTransIn()
  {
    super.finishTransIn();

    // menuItems.enabled = true;

    // #if newgrounds
    // if (NGio.savedSessionFailed)
    // 	showSavedSessionFailed();
    // #end
  }

  function onMenuItemChange(selected:MenuItem)
  {
    camFollow.setPosition(selected.getGraphicMidpoint().x, selected.getGraphicMidpoint().y);
  }

  #if CAN_OPEN_LINKS
  function selectDonate()
  {
    WindowUtil.openURL(Constants.URL_ITCH);
  }
  #end

  #if newgrounds
  function selectLogin()
  {
    openNgPrompt(NgPrompt.showLogin());
  }

  function selectLogout()
  {
    openNgPrompt(NgPrompt.showLogout());
  }

  function showSavedSessionFailed()
  {
    openNgPrompt(NgPrompt.showSavedSessionFailed());
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
    var prevLoggedIn = menuItems.has("logout");
    if (prevLoggedIn && !NGio.isLoggedIn) menuItems.resetItem("login", "logout", selectLogout);
    else if (!prevLoggedIn && NGio.isLoggedIn) menuItems.resetItem("logout", "login", selectLogin);
  }
  #end

  public function openPrompt(prompt:Prompt, onClose:Void->Void)
  {
    menuItems.enabled = false;
    prompt.closeCallback = function() {
      menuItems.enabled = true;
      if (onClose != null) onClose();
    }

    openSubState(prompt);
  }

  function startExitState(state:FlxState)
  {
    menuItems.enabled = false; // disable for exit
    var duration = 0.4;
    menuItems.forEach(function(item) {
      if (menuItems.selectedIndex != item.ID)
      {
        FlxTween.tween(item, {alpha: 0}, duration, {ease: FlxEase.quadOut});
      }
      else
      {
        item.visible = false;
      }
    });

    new FlxTimer().start(duration, function(_) FlxG.switchState(state));
  }

  override function update(elapsed:Float)
  {
    super.update(elapsed);

    if (FlxG.onMobile)
    {
      var touch:FlxTouch = FlxG.touches.getFirst();

      if (touch != null)
      {
        for (item in menuItems)
        {
          if (touch.overlaps(item))
          {
            if (menuItems.selectedIndex == item.ID && touch.justPressed) menuItems.accept();
            else
              menuItems.selectItem(item.ID);
          }
        }
      }
    }

    // ` / ~ to open the debug menu.
    if (FlxG.keys.justPressed.GRAVEACCENT)
    {
      // TODO: Does this break anything?
      this.persistentUpdate = false;
      this.persistentDraw = false;
      FlxG.state.openSubState(new DebugMenuSubState());
    }

    if (FlxG.sound.music.volume < 0.8)
    {
      FlxG.sound.music.volume += 0.5 * elapsed;
    }

    if (_exiting) menuItems.enabled = false;

    if (controls.BACK && menuItems.enabled && !menuItems.busy)
    {
      FlxG.sound.play(Paths.sound('cancelMenu'));
      FlxG.switchState(new TitleState());
    }
  }
}
