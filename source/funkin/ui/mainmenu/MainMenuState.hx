package funkin.ui.mainmenu;

import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.addons.transition.FlxTransitionableState;
import flixel.effects.FlxFlicker;
import flixel.input.touch.FlxTouch;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;
import flixel.util.typeLimit.NextState;
import funkin.audio.FunkinSound;
import funkin.graphics.FunkinCamera;
import funkin.ui.AtlasMenuList;
import funkin.ui.MenuList;
import funkin.ui.MusicBeatState;
import funkin.ui.Prompt;
import funkin.ui.debug.DebugMenuSubState;
import funkin.ui.freeplay.FreeplayState;
import funkin.ui.story.StoryMenuState;
import funkin.ui.title.TitleState;
import funkin.util.WindowUtil;
#if FEATURE_DISCORD_RPC
import funkin.api.discord.DiscordClient;
#end

class MainMenuState extends MusicBeatState
{
  var menuItems:MenuTypedList<AtlasMenuItem>;

  var magenta:FlxSprite;
  var camFollow:FlxObject;

  var overrideMusic:Bool = false;

  static var rememberedSelectedIndex:Int = 0;

  public function new(?_overrideMusic:Bool = false)
  {
    super();
    overrideMusic = _overrideMusic;
  }

  override function create():Void
  {
    #if FEATURE_DISCORD_RPC
    DiscordClient.instance.setPresence({state: "In the Menus", details: null});
    #end

    FlxG.cameras.reset(new FunkinCamera('mainMenu'));

    transIn = FlxTransitionableState.defaultTransIn;
    transOut = FlxTransitionableState.defaultTransOut;

    if (!overrideMusic) playMenuMusic();

    // We want the state to always be able to begin with being able to accept inputs and show the anims of the menu items.
    persistentUpdate = true;
    persistentDraw = true;

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
    magenta.color = 0xFFF44688;
    magenta.visible = false;

    // TODO: Why doesn't this line compile I'm going fucking feral
    if (Preferences.flashingLights) add(magenta);

    menuItems = new MenuTypedList<AtlasMenuItem>();
    add(menuItems);
    menuItems.onChange.add(onMenuItemChange);
    menuItems.onAcceptPress.add(function(_) {
      FlxFlicker.flicker(magenta, 1.1, 0.15, false, true);
    });

    menuItems.enabled = true; // can move on intro
    createMenuItem('storymode', 'mainmenu/storymode', function() startExitState(() -> new StoryMenuState()));
    createMenuItem('freeplay', 'mainmenu/freeplay', function() {
      persistentDraw = true;
      persistentUpdate = false;

      // Freeplay has its own custom transition
      FlxTransitionableState.skipNextTransIn = true;
      FlxTransitionableState.skipNextTransOut = true;

      var targetCharacter:Null<String> = null;
      openSubState(new FreeplayState({character: targetCharacter}));
    });

    createMenuItem('credits', 'mainmenu/credits', function() {
      startExitState(() -> new funkin.ui.credits.CreditsState());
    });

    createMenuItem('options', 'mainmenu/options', function() {
      startExitState(() -> new funkin.ui.options.OptionsState());
    });

    // Reset position of menu items.
    var spacing = 160;
    var top = (FlxG.height - (spacing * (menuItems.length - 1))) / 2;
    for (i in 0...menuItems.length)
    {
      var menuItem = menuItems.members[i];
      menuItem.x = FlxG.width / 2;
      menuItem.y = top + spacing * i;
      menuItem.scrollFactor.x = 0.0;
      menuItem.scrollFactor.y = 0.4;
    }

    menuItems.selectItem(rememberedSelectedIndex);
    resetCamStuff();

    // reset camera when debug menu is closed
    subStateClosed.add(_ -> resetCamStuff(false));
    subStateOpened.add(sub -> {
      if (Type.getClass(sub) == FreeplayState)
      {
        new FlxTimer().start(0.5, _ -> {
          magenta.visible = false;
        });
      }
    });

    super.create();

    // This has to come AFTER!
    this.leftWatermarkText.text = "Funkin' " + Constants.VERSION + ' | Mat Mixes ' + Constants.VERSION_MOD;
  }

  function playMenuMusic():Void
  {
    FunkinSound.playMusic('freakyMenu',
      {
        overrideExisting: true,
        restartTrack: false,
        // Continue playing this music between states, until a different music track gets played.
        persist: true
      });
  }

  function resetCamStuff(?snap:Bool = true):Void
  {
    FlxG.camera.follow(camFollow, null, 0.06);

    if (snap) FlxG.camera.snapToTarget();
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

  override function closeSubState():Void
  {
    magenta.visible = false;

    super.closeSubState();
  }

  override function finishTransIn():Void
  {
    super.finishTransIn();
  }

  function onMenuItemChange(selected:MenuListItem)
  {
    camFollow.setPosition(selected.getGraphicMidpoint().x, selected.getGraphicMidpoint().y);
  }

  #if FEATURE_OPEN_URL
  function selectDonate()
  {
    WindowUtil.openURL(Constants.URL_ITCH);
  }

  function selectMerch()
  {
    WindowUtil.openURL(Constants.URL_MERCH);
  }
  #end

  public function openPrompt(prompt:Prompt, onClose:Void->Void):Void
  {
    menuItems.enabled = false;
    persistentUpdate = false;

    prompt.closeCallback = function() {
      menuItems.enabled = true;
      if (onClose != null) onClose();
    }

    openSubState(prompt);
  }

  function startExitState(state:NextState):Void
  {
    menuItems.enabled = false; // disable for exit
    rememberedSelectedIndex = menuItems.selectedIndex;

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

  override function update(elapsed:Float):Void
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

    Conductor.instance.update();

    // Open the debug menu, defaults to ` / ~
    // This includes stuff like the Chart Editor, so it should be present on all builds.
    if (controls.DEBUG_MENU)
    {
      persistentUpdate = false;

      FlxG.state.openSubState(new DebugMenuSubState());
    }

    if (FlxG.sound.music != null && FlxG.sound.music.volume < 0.8)
    {
      FlxG.sound.music.volume += 0.5 * elapsed;
    }

    if (_exiting) menuItems.enabled = false;

    if (controls.BACK && menuItems.enabled && !menuItems.busy)
    {
      FlxG.switchState(() -> new TitleState());
      FunkinSound.playOnce(Paths.sound('cancelMenu'));
    }
  }
}
