package funkin.ui.debug;

#if sys
import flixel.FlxSubState;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;
import funkin.data.freeplay.player.PlayerRegistry;
import funkin.play.ResultState.ResultsStateParams;
import funkin.ui.MenuList.MenuTypedItem;
import funkin.ui.MenuList.MenuTypedList;
import funkin.ui.options.items.CheckboxPreferenceItem;
import funkin.util.file.FNFCUtil;

/**
 * When playtesting from an FNFC file, we display a debug UI to choose a difficulty first.
 */
class ChartPlaytestState extends MusicBeatState
{
  var fnfcFilePath:String;

  var currentDifficulty:String;
  var currentVariation:String;

  var items:MenuTypedList<MenuTypedItem<FlxText>>;

  var justClosedSubstate:Bool = false;

  public function new(params:ChartPlaytestStateParams)
  {
    super();
    fnfcFilePath = params.fnfcFilePath;
    persistentUpdate = false;
    persistentDraw = false;

    items = new MenuTypedList<MenuTypedItem<FlxText>>();
    add(items);

    createItems();

    // Try to force the camera not to move
    this.camera.follow(null);
    this.camera.zoom = 1;
    this.camera.x = 0;
    this.camera.y = 0;
    this.camera.scroll.x = 0;
    this.camera.scroll.y = 0;
  }

  override function update(elapsed:Float):Void
  {
    super.update(elapsed);

    if (this.subState == null) {}
  }

  function createItems():Void
  {
    createTextItem("Playtest Song", function() {
      try
      {
        FNFCUtil.playSongFromFNFCPath(fnfcFilePath, currentDifficulty, currentVariation);
      }
      catch (e)
      {
        lime.app.Application.current.window.alert('$e', 'Could Not Playtest Chart');
      }
    });

    createToggleListItem("Variation", Constants.DEFAULT_VARIATION_LIST, function(value:String) {
      currentVariation = value;
    });

    createToggleListItem("Difficulty", Constants.DEFAULT_DIFFICULTY_LIST_FULL, function(value:String) {
      currentDifficulty = value;
    });
  }

  function createTextItem(name:String, ?onChange:Void->Void):MenuTypedItem<FlxText>
  {
    var txt:FlxText = new FlxText(0, 0, name);
    txt.antialiasing = false;
    txt.setFormat(Paths.font('vcr.ttf'), 32);
    txt.scrollFactor.set(0, 0);

    var menuItem:MenuTypedItem<FlxText> = new MenuTypedItem<FlxText>(10, 36 * items.length, txt, name, onChange);
    menuItem.setEmptyBackground();
    menuItem.fireInstantly = true;
    return items.addItem(name, menuItem);
  }

  function createCheckboxItem(name:String, ?onChange:Bool->Void):Void
  {
    var toggle:Bool = false;
    var menuItem:MenuTypedItem<FlxText> = createTextItem(name);
    menuItem.callback = function() {
      menuItem.label.text = name + ": " + (toggle ? "on" : "off");
      toggle = !toggle;
      onChange(toggle);
    };
  }

  /**
   * Toggles between different options in a list
   * @param name
   * @param toggleList
   * @param onChange
   * @return MenuTypedItem<FlxText>
   */
  function createToggleListItem(name:String, toggleList:Array<String>, ?onChange:String->Void):MenuTypedItem<FlxText>
  {
    var toggleCounter:Int = 0;
    var menuItem:MenuTypedItem<FlxText> = createTextItem(name);

    // We create and call the labelCallback here to initalize it
    var labelCallback:Void->Void = function() {
      menuItem.label.text = name + ":" + toggleList[toggleCounter];
      onChange(toggleList[toggleCounter]);
    };
    labelCallback();

    menuItem.callback = function() {
      toggleCounter = (toggleCounter + 1) % toggleList.length;
      labelCallback();
    };

    return menuItem;
  }

  override function onCloseSubStateComplete(targetState:FlxSubState):Void
  {
    super.onCloseSubStateComplete(targetState);

    justClosedSubstate = true;

    // Try to force the camera not to move
    this.camera.follow(null);
    this.camera.zoom = 1;
    this.camera.x = 0;
    this.camera.y = 0;
    this.camera.scroll.x = 0;
    this.camera.scroll.y = 0;
  }
}

typedef ChartPlaytestStateParams =
{
  fnfcFilePath:Null<String>
};
#end
