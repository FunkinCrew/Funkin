package funkin.ui.options;

#if FEATURE_NEWGROUNDS
import funkin.api.newgrounds.NewgroundsClient;
#end
import funkin.save.Save;

/**
 * Our default Page when we enter the OptionsState, a bit of the root
 */
class SaveDataMenu extends Page<OptionsState.OptionsMenuPageName>
{
  var items:TextMenuList;

  public function new()
  {
    super();

    add(items = new TextMenuList());

    #if FEATURE_NEWGROUNDS
    if (NewgroundsClient.instance.isLoggedIn())
    {
      createItem("LOAD FROM NEWGROUNDS", function() {
        openConfirmPrompt("This will overwrite
        \nALL your save data.
        \nAre you sure?
      ", "Overwrite", function() {
          Save.loadFromNewgrounds();

          FlxG.switchState(() -> new funkin.InitState());
        });
      });

      createItem("SAVE TO NEWGROUNDS", function() {
        openConfirmPrompt("This will overwrite
        \nALL save data saved
        \non Newgrounds.
        \nAre you sure?
      ", "Overwrite", function() {
          Save.saveToNewgrounds();
        });
      });
    }
    #end

    createItem("CLEAR SAVE DATA", function() {
      openConfirmPrompt("This will delete
        \nALL your save data.
        \nAre you sure?
      ", "Delete", function() {
        // Clear the save data.
        Save.clearData();

        FlxG.switchState(() -> new funkin.InitState());
      });
    });

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

  function openConfirmPrompt(text:String, yesText:String, onYes:Void->Void):Void
  {
    if (prompt != null) return;

    prompt = new Prompt(text, Custom(yesText, "Cancel"));
    prompt.create();
    prompt.createBgFromMargin(100, 0xFFFAFD6D);
    prompt.back.scrollFactor.set(0, 0);
    add(prompt);

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
}
