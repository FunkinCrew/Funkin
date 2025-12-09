package funkin.ui;

import flixel.FlxG;
import flixel.FlxSprite;
import funkin.ui.AtlasText.AtlasFont;

/**
 * Opens a yes/no dialog box as a substate over the current state.
 */
@:nullSafety
class Prompt extends flixel.FlxSubState
{
  inline static var MARGIN = 100;

  public var onYes:Null<Void->Void>;
  public var onNo:Null<Void->Void>;
  public var buttons:TextMenuList;
  public var field:AtlasText;
  public var back:Null<FlxSprite>;

  var style:ButtonStyle;

  public function new(text:String, style:ButtonStyle = Ok)
  {
    this.style = style;
    super(0x80000000);

    buttons = new TextMenuList(Horizontal);

    field = new AtlasText(text, AtlasFont.BOLD);
    field.scrollFactor.set(0, 0);
  }

  override function create()
  {
    super.create();

    field.y = MARGIN;
    field.screenCenter(X);
    add(field);

    createButtons();
    add(buttons);
  }

  public function createBg(width:Int, height:Int, color = 0xFF808080)
  {
    back = new FlxSprite();
    back.makeGraphic(width, height, color, false, "prompt-bg");
    back.screenCenter(XY);
    add(back);
    var backObj = members.pop();
    if (backObj != null) members.unshift(backObj); // bring to front
  }

  public function createBgFromMargin(margin = MARGIN, color = 0xFF808080)
  {
    createBg(Std.int(FlxG.width - margin * 2), Std.int(FlxG.height - margin * 2), color);
  }

  public function setButtons(style:ButtonStyle)
  {
    if (this.style != style)
    {
      this.style = style;
      createButtons();
    }
  }

  function createButtons()
  {
    // destroy previous buttons
    while (buttons.members.length > 0)
    {
      buttons.remove(buttons.members[0], true).destroy();
    }

    switch (style)
    {
      case Yes_No:
        createButtonsHelper("yes", "no");
      case Ok:
        createButtonsHelper("ok");
      case Custom(yes, no):
        createButtonsHelper(yes, no);
      case None:
        buttons.exists = false;
    };
  }

  function createButtonsHelper(yes:String, ?no:String)
  {
    buttons.exists = true;
    // pass anonymous functions rather than the current callbacks, in case they change later
    var yesButton = buttons.createItem(yes, function() {
      if (onYes != null) onYes();
      else
        FlxG.log.warn("onYes function was called without being set");
    });
    yesButton.screenCenter(X);
    yesButton.y = FlxG.height - yesButton.height - MARGIN;
    yesButton.scrollFactor.set(0, 0);
    if (no != null)
    {
      // place right
      yesButton.x = FlxG.width - yesButton.width - MARGIN;

      var noButton = buttons.createItem(no, function() if (onNo != null) onNo());
      noButton.x = MARGIN;
      noButton.y = FlxG.height - noButton.height - MARGIN;
      noButton.scrollFactor.set(0, 0);
    }
  }

  public function setText(text:String)
  {
    field.text = text;
    field.screenCenter(X);
  }
}

enum ButtonStyle
{
  Ok;
  Yes_No;
  Custom(yes:String, no:Null<String>); // Todo: more than 2
  None;
}
