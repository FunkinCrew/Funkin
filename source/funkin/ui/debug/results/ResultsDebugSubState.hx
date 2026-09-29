package funkin.ui.debug.results;

import funkin.play.ResultState.ResultsStateParams;
import funkin.ui.MenuList.MenuTypedList;
import funkin.ui.MenuList.MenuTypedItem;
import flixel.text.FlxText;
import funkin.data.freeplay.player.PlayerRegistry;
import funkin.ui.freeplay.charselect.PlayableCharacter;
import funkin.ui.options.items.CheckboxPreferenceItem;
import flixel.util.FlxTimer;
import flixel.tweens.FlxTween;
import funkin.ui.mainmenu.MainMenuState;

/**
 * Debug substate to configure the results screen for testing purposes,
 * allowing you to set the score, rank, character, and other parameters.
 */
class ResultsDebugSubState extends MusicBeatSubState
{
  var resultsParams:ResultsStateParams;
  var items:MenuTypedList<MenuTypedItem<FlxText>>;

  override function create():Void
  {
    super.create();

    persistentUpdate = false;
    persistentDraw = false;
    initResultsParams();

    items = new MenuTypedList<MenuTypedItem<FlxText>>();
    add(items);

    createItems();
  }

  override function update(elapsed:Float):Void
  {
    super.update(elapsed);

    if (controls.BACK) FlxG.switchState(() -> new MainMenuState());
  }

  var returnToDebugScreen:Bool = false;

  function createItems():Void
  {
    createTextItem("TEST RESULTS SCREEN", function()
    {
      // I'm being lazy, and putting a timer here so that when you enter result screen you don't immediately press an input
      new FlxTimer().start(0.5, function(_)
      {
        if (returnToDebugScreen)
        {
          var resultState:funkin.play.ResultState = new funkin.play.ResultState(resultsParams);
          resultState.closeCallback = function()
          {
            FlxTimer.globalManager.clear();
            FlxTween.globalManager.clear();
            FlxG.sound.music?.stop();
            FlxG.cameras.reset();
          };
          openSubState(resultState);
        }
        else
          FlxG.switchState(() -> new funkin.play.ResultState(resultsParams));
      });
    });
    createToggleListItem("Character", PlayerRegistry.instance.listEntryIds(), function(result:String)
    {
      var playableCharacter:PlayableCharacter = PlayerRegistry.instance.fetchEntry(result);
      resultsParams.characterId = playableCharacter.getOwnedCharacterIds()[0];
    });
    createToggleListItem("Results Mode", ["Debug", "Story", "Freeplay"], function(result:String)
    {
      returnToDebugScreen = result == "Debug"; // We will create the ResultsState as a Substate, that we will just close and return back to here
      resultsParams.storyMode = result == "Story"; // Debug overrides this, but if not using Debug, we will return to either Freeplay or Story menus
    });
    createToggleListItem("Ranking", DebugTallies.DEBUG_RANKS, function(result:String)
    {
      resultsParams.scoreData.tallies = DebugTallies.getTallyForRank(result);
    });
    createToggleListItem("New Highscore", ["True", "False"], function(result:String) 
    {
      var highscoreEnabled:Bool = true;
      if (result == "False") highscoreEnabled = false;
      resultsParams.isNewHighscore = highscoreEnabled;
    });
    createToggleListItem("Difficulty", Constants.DEFAULT_DIFFICULTY_LIST_FULL, function(result:String)
    {
      resultsParams.difficultyId = result;
    });
    createToggleListItem("Force Rank Slam (Freeplay Only)", ["No", "Yes"], function(result:String)
    {
      resultsParams.forceRankSlam = result == "Yes";
    });
  }

  function createTextItem(name:String, ?onChange:Void->Void):MenuTypedItem<FlxText>
  {
    var txt:FlxText = new FlxText(0, 0, name);
    txt.antialiasing = false;
    txt.setFormat(funkin.assets.Paths.font('ui/fonts/VCR OSD Mono'), 32);

    var menuItem:MenuTypedItem<FlxText> = new MenuTypedItem<FlxText>(10, 36 * items.length, txt, name, onChange);
    menuItem.setEmptyBackground();
    menuItem.fireInstantly = true;
    return items.addItem(name, menuItem);
  }

  function createCheckboxItem(name:String, ?onChange:Bool->Void):Void
  {
    var toggle:Bool = false;
    var menuItem:MenuTypedItem<FlxText> = createTextItem(name);
    menuItem.callback = function()
    {
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
    var labelCallback:Void->Void = function()
    {
      menuItem.label.text = name + ": " + toggleList[toggleCounter].charAt(0).toUpperCase() + toggleList[toggleCounter].substr(1);
      onChange(toggleList[toggleCounter]);
    };
    labelCallback();

    menuItem.callback = function()
    {
      toggleCounter = (toggleCounter + 1) % toggleList.length;
      labelCallback();
    };

    return menuItem;
  }

  function initResultsParams():Void
  {
    resultsParams = {
      storyMode: false,
      title: "Cum Song Erect by Kawai Sprite",
      songId: "cum",
      characterId: "bf",
      difficultyId: "nightmare",
      variationId: "erect",
      isNewHighscore: true,
      isPracticeMode: true, // Invalidates achievements/scores.
      isBotPlayMode: true, // Invalidates achievements/scores.
      scoreData: {
        score: 1_234_567_890,
        tallies: {
          sick: 130,
          good: 60,
          bad: 69,
          shit: 69,
          missed: 69,
          combo: 69,
          maxCombo: 69,
          totalNotesHit: 140,
          totalNotes: 190,
        }
      },
    };
  }
}
