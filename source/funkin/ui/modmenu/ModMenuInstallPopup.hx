package funkin.ui.modmenu;

import flixel.FlxG;
import flixel.math.FlxRect;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import funkin.graphics.FunkinSprite;
import funkin.group.FunkinGroup.FunkinSpriteGroup;
import funkin.ui.FullScreenScaleMode;

/**
 * The card shown in the corner while a one-click install runs.
 */
class ModMenuInstallPopup extends FunkinSpriteGroup
{
  static inline final ICON_SIZE:Int = 96;

  static inline final CARD_WIDTH:Int = 350;
  static inline final TEXT_WIDTH:Int = 246;
  static inline final PADDING:Int = 8;
  static inline final PROMPT_HEIGHT:Int = 30;
  static inline final BAR_HEIGHT:Int = 6;

  /**
   * What the card is currently doing.
   */
  public var state(default, null):ModMenuInstallState = Hidden;

  var background:FunkinSprite;
  var modIcon:FunkinSprite;
  var titleText:FlxText;
  var detailText:FlxText;
  var promptText:FlxText;
  var barBackground:FunkinSprite;
  var barFill:FunkinSprite;

  /**
   * The bar's clip, in graphic pixels, mutated in place as the download runs.
   * Registered with the group rather than assigned, since the group rewrites any clip it doesn't
   * know about on every update.
   */
  var barClip:FlxRect;

  /**
   * Where the bar is being asked to get to, and where it's actually drawn.
   */
  var targetRatio:Float = 0;

  var displayRatio:Float = 0;

  /**
   * Whether a download has run, so the bar can stay on screen once it finishes.
   */
  var hasDownloaded:Bool = false;

  /**
   * How many more mods are waiting behind this one.
   */
  var queueCount:Int = 0;

  /**
   * The prompt without the queue tally on it, so the tally can be swapped out on its own.
   */
  var lastPrompt:String = '';

  /**
   * How much of the remaining distance the fill closes per second.
   */
  static inline final BAR_LERP:Float = 9.0;

  /**
   * How long a result sits on screen before the card hides itself.
   */
  static inline final RESULT_DURATION:Float = 3.0;

  /**
   * What's left of that, counting down.
   */
  var resultTimer:Float = 0;

  var cardHeight:Int;

  public function new()
  {
    super();

    cardHeight = ICON_SIZE + PROMPT_HEIGHT + (PADDING * 2);

    x = FlxG.width - CARD_WIDTH - (FlxG.width * 0.047) - FullScreenScaleMode.gameCutoutSize.x / 2.5;
    y = FlxG.height * 0.035;

    background = new FunkinSprite(0, 0);
    background.makeSolidColor(CARD_WIDTH, cardHeight, FlxColor.BLACK);
    background.alpha = 0.72;
    background.scrollFactor.set(0, 0);
    add(background);

    modIcon = new FunkinSprite(0, 0);
    modIcon.loadGraphic(funkin.Paths.image('ui/mods/fallback-icon'));
    modIcon.scrollFactor.set();
    modIcon.antialiasing = true;
    modIcon.setGraphicSize(ICON_SIZE, ICON_SIZE);
    modIcon.updateHitbox();
    modIcon.x = PADDING;
    modIcon.y = PADDING;
    add(modIcon);

    titleText = new FlxText(0, 0, TEXT_WIDTH);
    titleText.setFormat(Paths.font('FunkinLingLong.otf'), 30, FlxColor.WHITE);
    titleText.scale.set(1, 0.8);
    titleText.fieldHeight = 42;
    titleText.x = PADDING + ICON_SIZE + PADDING;
    titleText.y = PADDING;
    titleText.scrollFactor.set(0, 0);
    add(titleText);

    setChildClipRect(titleText, FlxRect.get(0, 0, TEXT_WIDTH, 32));

    detailText = new FlxText(0, 0, TEXT_WIDTH);
    detailText.setFormat(Paths.font('FunkinLingLong.otf'), 20, FlxColor.WHITE);
    detailText.fieldHeight = 64;
    detailText.x = titleText.x;
    detailText.y = PADDING + 36;
    detailText.scrollFactor.set(0, 0);
    add(detailText);

    barBackground = new FunkinSprite(0, 0);
    barBackground.makeSolidColor(ICON_SIZE, BAR_HEIGHT, 0xFF3C3C4B);
    barBackground.x = PADDING;
    barBackground.y = PADDING + ICON_SIZE - BAR_HEIGHT;
    barBackground.scrollFactor.set(0, 0);
    add(barBackground);

    barFill = new FunkinSprite(0, 0);

    barFill.makeGraphic(ICON_SIZE, BAR_HEIGHT, 0xFF00C9FF);
    barFill.x = barBackground.x;
    barFill.y = barBackground.y;
    barFill.scrollFactor.set(0, 0);
    add(barFill);

    barClip = FlxRect.get(0, 0, 0, BAR_HEIGHT);
    setChildClipRect(barFill, barClip);

    promptText = new FlxText(0, 0, CARD_WIDTH - (PADDING * 2));
    promptText.setFormat(Paths.font('FunkinLingLong.otf'), 20, FlxColor.WHITE, FlxTextAlign.CENTER);
    promptText.x = PADDING;
    promptText.y = PADDING + ICON_SIZE + 4;
    promptText.scrollFactor.set(0, 0);
    add(promptText);

    visible = false;
  }

  public function showBusy(title:String, detail:String):Void
  {
    state = Busy;

    apply(title, detail, '', hasDownloaded, targetRatio);
  }

  /**
   * Shows download progress.
   *
   * @param ratio How much of the file has arrived, from 0 to 1.
   */
  public function showProgress(title:String, detail:String, ratio:Float):Void
  {
    state = Downloading;
    hasDownloaded = true;

    apply(title, detail, 'ESC to cancel', true, ratio);
  }

  /**
   * Reports how an install went, then gets out of the way on its own so the queue can carry on.
   */
  public function showResult(title:String, detail:String):Void
  {
    state = Result;
    resultTimer = RESULT_DURATION;

    apply(title, detail, '', hasDownloaded, 1);
  }

  /**
   * Draws the card on the given camera instead of the world one.
   */
  public function setCamera(target:flixel.FlxCamera):Void
  {
    camera = target;

    forEach(function(child:flixel.FlxSprite):Void
    {
      child.camera = target;
    });
  }

  /**
   * Swaps in the mod's preview image once it has been fetched.
   */
  public function setIcon(bitmap:openfl.display.BitmapData):Void
  {
    modIcon.loadGraphic(bitmap);
    modIcon.antialiasing = true;
    modIcon.setGraphicSize(ICON_SIZE, ICON_SIZE);
    modIcon.updateHitbox();
    modIcon.x = PADDING;
    modIcon.y = PADDING;
  }

  /**
   * Sets how many more mods are queued behind this one, and redraws the prompt to match.
   */
  public function setQueueCount(count:Int):Void
  {
    if (queueCount == count) return;

    queueCount = count;

    promptText.text = decoratePrompt(lastPrompt);

    resizeCard();
  }

  /**
   * Hides the card and stops it from swallowing input.
   */
  public function hide():Void
  {
    state = Hidden;
    hasDownloaded = false;
    targetRatio = 0;
    displayRatio = 0;
    resultTimer = 0;
    visible = false;
  }

  /**
   * Adds the queue tally onto a prompt, on its own line so it doesn't crowd the keys.
   */
  function decoratePrompt(prompt:String):String
  {
    if (queueCount <= 0) return prompt;

    final tally:String = queueCount == 1 ? '1 more mod queued' : '${queueCount} more mods queued';

    return prompt == '' ? tally : '${prompt}\n${tally}';
  }

  /**
   * Resizes the card to fit the prompt.
   */
  function resizeCard():Void
  {
    final lines:Int = promptText.text == '' ? 1 : promptText.text.split('\n').length;
    final height:Int = ICON_SIZE + (PROMPT_HEIGHT * lines) + (PADDING * 2);

    if (height == cardHeight) return;

    cardHeight = height;
    background.makeSolidColor(CARD_WIDTH, cardHeight, FlxColor.BLACK);
  }

  override public function update(elapsed:Float):Void
  {
    super.update(elapsed);

    if (state == Result)
    {
      resultTimer -= elapsed;

      if (resultTimer <= 0) hide();
    }

    if (displayRatio == targetRatio) return;

    displayRatio += (targetRatio - displayRatio) * Math.min(1, elapsed * BAR_LERP);

    if (Math.abs(targetRatio - displayRatio) < 0.001) displayRatio = targetRatio;

    barClip.width = ICON_SIZE * displayRatio;
  }

  /**
   * Whether the card is currently taking input away from the menu underneath it.
   */
  public function isBlocking():Bool
  {
    return state != Hidden;
  }

  function apply(title:String, detail:String, prompt:String, showBar:Bool, ratio:Float):Void
  {
    visible = true;

    titleText.text = title;
    detailText.text = detail;

    lastPrompt = prompt;
    promptText.text = decoratePrompt(prompt);

    resizeCard();

    barBackground.localVisible = showBar;
    barFill.localVisible = showBar;

    if (showBar) targetRatio = Math.max(0, Math.min(1, ratio));
    else
    {
      targetRatio = 0;
      displayRatio = 0;
      barClip.width = 0;
    }
  }
}

/**
 * The stages a one-click install passes through.
 */
enum ModMenuInstallState
{
  /**
   * Nothing is happening, the menu behaves normally.
   */
  Hidden;

  /**
   * Waiting on the network, the player cannot do anything yet.
   */
  Busy;

  /**
   * The archive is downloading.
   */
  Downloading;

  /**
   * Finished.
   */
  Result;
}
