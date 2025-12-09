package funkin.ui.options;

#if FEATURE_NEWGROUNDS
import funkin.api.newgrounds.NewgroundsClient;
#end
import funkin.save.Save;

class SaveDataMenu extends Page<OptionsState.OptionsMenuPageName>
{
  var items:TextMenuList;

  public function new()
  {
    super();

    add(items = new TextMenuList());

    createItem("CLEAR SAVE DATA", openSaveDataPrompt);

    #if FEATURE_NEWGROUNDS
    if (NewgroundsClient.instance.isLoggedIn())
    {
      createItem("LOAD FROM NG", function() {
        openConfirmPrompt("This will overwrite
        \nALL your save data.
        \nAre you sure?", "Overwrite",
          () -> Save.loadFromNewgrounds(() -> FlxG.switchState(() -> new funkin.InitState())));
      });

      createItem("SAVE TO NG", function() {
        openConfirmPrompt("This will overwrite
        \nALL save data saved
        \non NG. Are you sure?", "Overwrite", function() {
          Save.saveToNewgrounds();
        });
      });

      createItem("CLEAR NG SAVE DATA", function() {
        openConfirmPrompt("This will delete
        \nALL save data saved
        \non NG. Are you sure?", "Delete", function() {
          funkin.api.newgrounds.NGSaveSlot.instance.clear();
        });
      });
    }
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

  override function update(elapsed:Float)
  {
    enabled = (prompt == null);
    super.update(elapsed);
  }

  override function set_enabled(value:Bool)
  {
    items.enabled = value;
    return super.set_enabled(value);
  }

  var prompt:Prompt;

  function openConfirmPrompt(text:String, yesText:String, onYes:Void->Void, ?groupToOpenOn:Null<flixel.group.FlxGroup>):Void
  {
    if (prompt != null) return;

    prompt = new Prompt(text, Custom(yesText, "Cancel"));
    prompt.create();
    prompt.createBgFromMargin(100, 0xFFFAFD6D);
    prompt.back.scrollFactor.set(0, 0);
    FlxG.state.add(prompt);

    prompt.onYes = function() {
      onYes();

      if (prompt != null)
      {
        prompt.close();
        prompt.destroy();
        prompt = null;
      }
    };

    prompt.onNo = function() {
      prompt.close();
      prompt.destroy();
      prompt = null;
    }
  }

  public function openSaveDataPrompt()
  {
    openConfirmPrompt("This will delete
        \nALL your save data.
        \nAre you sure?
      ", "Delete", function() {
      // Clear the save data.
      Save.clearData();

      FlxG.switchState(() -> new funkin.InitState());
    });
  }

  /**
   * True if this page has multiple options, excluding the exit option.
   * If false, there's no reason to ever show this page.
   */
  public function hasMultipleOptions():Bool
  {
    return items.length > 2;
  }
}
