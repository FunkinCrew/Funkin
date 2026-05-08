package funkin.util.plugins;

import flixel.FlxBasic;
import flixel.FlxG;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxSignal;
import openfl.display.Shape;
import openfl.display.Sprite;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFieldAutoSize;

import openfl.events.KeyboardEvent;
import openfl.ui.Keyboard;

typedef SidePanelPluginParams =
{
  ?panelWidth:Int,
  ?grabberHeight:Int,
};

typedef SidePanelItem =
{
  label:String,
  onSelect:Void->Void,
};

class SidePanelPlugin extends FlxBasic
{
  public static var instance(get, never):SidePanelPlugin;

  public static var showGrabber(default, set):Bool = false;

  static function set_showGrabber(value:Bool):Bool
  {
    trace('Setting showGrabber to ' + value);
    showGrabber = value;
    if (_instance == null) return value;
    _instance.grabberSprite.visible = value;
    if (!value && _instance.isOpen) _instance.close();
    return value;
  }

  static var _instance:Null<SidePanelPlugin> = null;

  static function get_instance():SidePanelPlugin
  {
    if (_instance == null) _instance = new SidePanelPlugin({});
    return _instance;
  }

  static final GRABBER_TAB_WIDTH:Int = 24;
  static final DEFAULT_PANEL_WIDTH:Int = 280;
  static final DEFAULT_GRABBER_HEIGHT:Int = 80;
  static final SLIDE_DURATION:Float = 0.28;
  static final ITEM_HEIGHT:Int = 32;
  static final ITEM_PADDING_X:Int = 12;
  static final ITEM_FONT_SIZE:Int = 13;
  static final ITEM_COLOR_NORMAL:Int = 0x222222;
  static final ITEM_COLOR_SELECTED_BG:Int = 0x4A90D9;
  static final ITEM_COLOR_SELECTED_TEXT:Int = 0xFFFFFF;

  public var isOpen(default, null):Bool = false;

  var rootSprite:Sprite;
  var panelSprite:Sprite;
  var panelBackground:Shape;
  var grabberSprite:Sprite;
  var grabberBackground:Shape;
  var chevronShape:Shape;

  public var contentContainer(default, null):Sprite;

  var panelWidth:Int;
  var grabberHeight:Int;
  var slideTween:Null<FlxTween> = null;

  var items:Array<SidePanelItem> = [];
  var itemRows:Array<Sprite> = [];
  var selectedIndex:Int = 0;

  public function new(params:SidePanelPluginParams)
  {
    super();
    _instance = this;

    panelWidth = params.panelWidth ?? DEFAULT_PANEL_WIDTH;
    grabberHeight = params.grabberHeight ?? DEFAULT_GRABBER_HEIGHT;

    rootSprite = new Sprite();
    panelSprite = new Sprite();
    panelBackground = new Shape();
    drawPanelBackground();
    panelSprite.addChild(panelBackground);

    contentContainer = new Sprite();
    contentContainer.x = 8;
    contentContainer.y = 8;
    panelSprite.addChild(contentContainer);

    rootSprite.addChild(panelSprite);

    grabberSprite = new Sprite();
    grabberBackground = new Shape();
    chevronShape = new Shape();
    drawGrabber(false);

    grabberSprite.addChild(grabberBackground);
    grabberSprite.addChild(chevronShape);

    rootSprite.addChild(grabberSprite);
    grabberSprite.visible = showGrabber;

    layout();

    FlxG.stage.addChild(rootSprite);
    FlxG.signals.gameResized.add(onGameResized);
    FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);

    addItem('Back to Mod Menu', toModMenu);
    addItem('Second button', toModMenu);
    addItem('Third button', toModMenu);
  }

  function toModMenu():Void
  {
    FlxG.keys.enabled = true;
    FlxG.switchState(() -> new funkin.ui.modmenu.ModMenuState());
  }

  public static function initialize(?params:SidePanelPluginParams):Void
  {
    FlxG.plugins.addPlugin(new SidePanelPlugin(params ?? {}));
  }

  public function addItem(label:String, onSelect:Void->Void):Int
  {
    var index:Int = items.length;
    items.push({label: label, onSelect: onSelect});
    rebuildItemRows();
    return index;
  }

  public function clearItems():Void
  {
    items = [];
    rebuildItemRows();
    selectedIndex = 0;
  }

  function rebuildItemRows():Void
  {
    for (row in itemRows)
      contentContainer.removeChild(row);
    itemRows = [];

    for (i in 0...items.length)
    {
      var row:Sprite = buildItemRow(items[i].label, i == selectedIndex);
      row.y = i * ITEM_HEIGHT;
      contentContainer.addChild(row);
      itemRows.push(row);
    }
  }

  function buildItemRow(label:String, selected:Bool):Sprite
  {
    var row:Sprite = new Sprite();

    var bg:Shape = new Shape();
    if (selected)
    {
      bg.graphics.beginFill(ITEM_COLOR_SELECTED_BG, 1.0);
      bg.graphics.drawRoundRect(0, 0, panelWidth - 16, ITEM_HEIGHT, 6);
      bg.graphics.endFill();
    }
    row.addChild(bg);

    var tf:TextField = new TextField();
    tf.selectable = false;
    tf.autoSize = TextFieldAutoSize.LEFT;
    tf.defaultTextFormat = new TextFormat('_sans', ITEM_FONT_SIZE, selected ? ITEM_COLOR_SELECTED_TEXT : ITEM_COLOR_NORMAL, false);
    tf.text = label;
    tf.x = ITEM_PADDING_X;
    tf.y = (ITEM_HEIGHT - tf.textHeight) / 2 - 2;
    row.addChild(tf);

    return row;
  }

  function refreshSelection():Void
  {
    for (i in 0...itemRows.length)
    {
      var row:Sprite = itemRows[i];
      while (row.numChildren > 0)
        row.removeChildAt(0);

      var selected:Bool = (i == selectedIndex);

      var bg:Shape = new Shape();
      if (selected)
      {
        bg.graphics.beginFill(ITEM_COLOR_SELECTED_BG, 1.0);
        bg.graphics.drawRoundRect(0, 0, panelWidth - 16, ITEM_HEIGHT, 6);
        bg.graphics.endFill();
      }
      row.addChild(bg);

      var tf:TextField = new TextField();
      tf.selectable = false;
      tf.autoSize = TextFieldAutoSize.LEFT;
      tf.defaultTextFormat = new TextFormat('_sans', ITEM_FONT_SIZE, selected ? ITEM_COLOR_SELECTED_TEXT : ITEM_COLOR_NORMAL, false);
      tf.text = items[i].label;
      tf.x = ITEM_PADDING_X;
      tf.y = (ITEM_HEIGHT - tf.textHeight) / 2 - 2;
      row.addChild(tf);
    }
  }

  function layout():Void
  {
    var screenW:Int = FlxG.width;
    var screenH:Int = FlxG.height;

    var panelX:Float = isOpen ? screenW - panelWidth : screenW;
    panelSprite.x = panelX;
    panelSprite.y = 0;

    drawPanelBackground();
    panelSprite.graphics.clear();

    grabberSprite.x = panelX - GRABBER_TAB_WIDTH;
    grabberSprite.y = (screenH - grabberHeight) / 2;

    drawGrabber(isOpen);
  }

  function drawPanelBackground():Void
  {
    var g = panelBackground.graphics;
    g.clear();
    g.beginFill(0xFFFFFF, 0.93);
    g.drawRoundRectComplex(0, 0, panelWidth, FlxG.height, 12, 0, 12, 0);
    g.endFill();
    g.lineStyle(1, 0x000000, 0.5);
    g.moveTo(0, 0);
    g.lineTo(0, FlxG.height);
    g.lineStyle();
  }

  function drawGrabber(open:Bool):Void
  {
    var g = grabberBackground.graphics;
    g.clear();
    g.beginFill(0xFFFFFF, 0.93);
    g.drawRoundRectComplex(0, 0, GRABBER_TAB_WIDTH, grabberHeight, 8, 0, 8, 0);
    g.endFill();
    g.lineStyle(1, 0x000000, 0.5);
    g.drawRoundRectComplex(0, 0, GRABBER_TAB_WIDTH, grabberHeight, 8, 0, 8, 0);
    g.lineStyle();
    drawChevron(open);
  }

  function drawChevron(pointLeft:Bool):Void
  {
    var g = chevronShape.graphics;
    g.clear();

    var cx:Float = GRABBER_TAB_WIDTH / 2;
    var cy:Float = grabberHeight / 2;
    var size:Float = 5;

    g.lineStyle(2, 0x000000, 0.9);
    g.moveTo(cx + (pointLeft ? size : -size), cy - size);
    g.lineTo(cx + (pointLeft ? -size : size), cy);
    g.lineTo(cx + (pointLeft ? size : -size), cy + size);
    g.lineStyle();
  }

  public function open():Void
  {
    if (isOpen) return;
    isOpen = true;
    FlxG.keys.enabled = false;
    selectedIndex = 0;
    refreshSelection();
    drawChevron(true);
    animateTo(FlxG.width - panelWidth);
  }

  public function close():Void
  {
    if (!isOpen) return;
    isOpen = false;
    FlxG.keys.enabled = true;
    drawChevron(false);
    animateTo(FlxG.width);
  }

  public function toggle():Void
  {
    if (isOpen) close() else open();
  }

  function animateTo(targetPanelX:Float):Void
  {
    if (slideTween != null) slideTween.cancel();

    slideTween = FlxTween.tween(panelSprite, {x: targetPanelX}, SLIDE_DURATION, {
      ease: FlxEase.quartOut,
      onUpdate: function(_) { grabberSprite.x = panelSprite.x - GRABBER_TAB_WIDTH; },
      onComplete: function(_) { slideTween = null; }
    });
  }

  function onGameResized(width:Int, height:Int):Void
  {
    layout();
  }

  function onKeyDown(e:KeyboardEvent):Void
  {
    if (!showGrabber) return;

    if (e.shiftKey && e.keyCode == Keyboard.ESCAPE)
    {
      toggle();
      return;
    }

    if (!isOpen || items.length == 0) return;

    switch (e.keyCode)
    {
      case Keyboard.UP:
        selectedIndex = (selectedIndex - 1 + items.length) % items.length;
        refreshSelection();
      case Keyboard.DOWN:
        selectedIndex = (selectedIndex + 1) % items.length;
        refreshSelection();
      case Keyboard.ENTER:
        items[selectedIndex].onSelect();
    }
  }


  override public function update(elapsed:Float):Void
  {
    super.update(elapsed);

    if (!showGrabber) return;

    var stageChildren = FlxG.stage.numChildren;
    if (stageChildren > 0 && FlxG.stage.getChildAt(stageChildren - 1) != rootSprite)
    {
      FlxG.stage.setChildIndex(rootSprite, stageChildren - 1);
    }
  }

  override public function destroy():Void
  {
    if (instance == this) _instance = null;
    if (FlxG.plugins.list.contains(this)) FlxG.plugins.remove(this);

    FlxG.signals.gameResized.remove(onGameResized);
    FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);

    if (slideTween != null)
    {
      slideTween.cancel();
      slideTween = null;
    }

    if (FlxG.stage.contains(rootSprite)) FlxG.stage.removeChild(rootSprite);

    @:privateAccess
    for (parent in [rootSprite, panelSprite, grabberSprite])
    {
      if (parent == null) continue;
      for (child in parent.__children)
        parent.removeChild(child);
    }

    super.destroy();
  }
}
