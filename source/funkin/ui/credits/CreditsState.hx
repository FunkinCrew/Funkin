package funkin.ui.credits;

import flixel.text.FlxText;
import flixel.util.FlxColor;
import funkin.audio.FunkinSound;
import flixel.FlxSprite;
import funkin.ui.mainmenu.MainMenuState;
import flixel.group.FlxSpriteGroup;
import funkin.util.TouchUtil;
import funkin.ui.credits.CreditsData.CreditsDataRole;
import funkin.ui.credits.CreditsData.CreditsDataMember;

/**
 * The state used to display the credits scroll.
 */
class CreditsState extends MusicBeatState
{
  /**
   * The height the credits should start at.
   * Make this an instanced variable so it gets set by the constructor.
   */
  final STARTING_HEIGHT = FlxG.height;

  /**
   * The padding on each side of the screen.
   */
  static final SCREEN_PAD = 24;

  /**
   * The width of the screen the credits should maximally fill up.
   * Make this an instanced variable so it gets set by the constructor.
   */
  final FULL_WIDTH = FlxG.width - (SCREEN_PAD * 2);

  /**
   * The font to use to display the text.
   * To use a font from the `assets` folder, use `Paths.font(...)`.
   * Choose something that will render Unicode properly.
   */
  #if windows
  static final CREDITS_FONT = 'Consolas';
  #elseif mac
  static final CREDITS_FONT = 'Menlo';
  #else
  static final CREDITS_FONT = "Courier New";
  #end

  /**
   * The size of the font.
   */
  static final CREDITS_FONT_SIZE = 24;

  static final CREDITS_HEADER_FONT_SIZE = 32;

  /**
   * The color of the text itself.
   */
  static final CREDITS_FONT_COLOR = FlxColor.WHITE;

  /**
   * The color of the text's outline.
   */
  static final CREDITS_FONT_STROKE_COLOR = FlxColor.BLACK;

  /**
   * The speed the credits scroll at, in pixels per second.
   */
  static final CREDITS_SCROLL_BASE_SPEED = 100.0;

  /**
   * The speed the credits scroll at while the button is held, in pixels per second.
   */
  static final CREDITS_SCROLL_FAST_SPEED = CREDITS_SCROLL_BASE_SPEED * 4.0;

  /**
   * The actual sprites and text used to display the credits.
   */
  var creditsGroup:FlxSpriteGroup;

  var scrollPaused:Bool = false;

  var backersToBuild:Array<String>;
  var entriesToBuild:Array<CreditsEntry>;

  public function new()
  {
    super();
  }

  public override function create():Void
  {
    super.create();

    #if ios
    var fix = new FlxText();
    fix.font = CREDITS_FONT;
    fix.draw();
    #end

    backersToBuild = CreditsDataHandler.fetchBackerEntries();

    entriesToBuild = [];
    for (entry in CreditsDataHandler.CREDITS_DATA.entries)
    {
      entriesToBuild.push(
        {
          data: entry,
          lineIndexToBuild: 0,
          backerIndexToBuild: 0,
          hasBuiltHeader: (entry.header == null),
          hasBuiltBody: (entry.body.length == 0),
          hasBuiltBackers: (!entry.appendBackers || backersToBuild.length == 0)
        });
    }

    // Background
    var bg = new FlxSprite(Paths.image('menuDesat'));
    bg.scrollFactor.x = 0;
    bg.scrollFactor.y = 0;
    bg.setGraphicSize(Std.int(FlxG.width));
    bg.updateHitbox();
    bg.x = 0;
    bg.y = 0;
    bg.alpha = 0.1;
    bg.visible = true;
    bg.color = 0xFFB57EDC; // Lavender
    // add(bg);

    // TODO: Once we need to display Kickstarter backers,
    // make this use a recycled pool so we don't kill peformance.
    creditsGroup = new FlxSpriteGroup();
    creditsGroup.x = Math.max(funkin.ui.FullScreenScaleMode.gameNotchSize.x, SCREEN_PAD);
    creditsGroup.y = STARTING_HEIGHT;

    // buildCreditsGroup();

    add(creditsGroup);

    // Music
    FunkinSound.playMusic('freeplayRandom',
      {
        startingVolume: 0.0,
        overrideExisting: true,
        restartTrack: true,
        loop: true
      });
    FlxG.sound.music.fadeIn(6, 0, 0.8);

    #if mobile
    addBackButton(FlxG.width - 230, FlxG.height - 200, FlxColor.WHITE, exit, 0.7);
    #end
  }

  var creditsLineY:Float = 0;

  function buildCreditsEntryLine(entry:CreditsEntry):Void
  {
    if (!entry.hasBuiltHeader)
    {
      var header:FlxText = buildCreditsLine(entry.data.header, creditsLineY, true, CreditsSide.Left);
      creditsLineY += CREDITS_HEADER_FONT_SIZE + (header.textField.numLines * CREDITS_HEADER_FONT_SIZE);
      entry.hasBuiltHeader = true;
      return;
    }

    if (!entry.hasBuiltBody)
    {
      var lineData:CreditsDataMember = entry.data.body[entry.lineIndexToBuild];
      var line:FlxText = buildCreditsLine(lineData.line, creditsLineY, false, CreditsSide.Left);
      creditsLineY += CREDITS_FONT_SIZE * line.textField.numLines;
      entry.lineIndexToBuild++;

      if (entry.lineIndexToBuild >= entry.data.body.length)
      {
        entry.hasBuiltBody = true;
      }
      return;
    }

    if (!entry.hasBuiltBackers)
    {
      var backer:String = backersToBuild[entry.backerIndexToBuild];
      creditsGroup.add(buildCreditsLine(backer, creditsLineY, false, CreditsSide.Left));
      creditsLineY += CREDITS_FONT_SIZE;

      entry.backerIndexToBuild++;
      if (entry.backerIndexToBuild >= backersToBuild.length)
      {
        entry.hasBuiltBackers = true;
      }
      return;
    }
  }

  function buildCreditsLine(text:String, yPos:Float, header:Bool, side:CreditsSide = CreditsSide.Center):FlxText
  {
    // CreditsSide.Center: Full screen width
    // CreditsSide.Left: Left half of screen
    // CreditsSide.Right: Right half of screen
    var xPos = (side == CreditsSide.Right) ? (FULL_WIDTH / 2) : 0;
    var width = (side == CreditsSide.Center) ? FULL_WIDTH : (FULL_WIDTH / 2);
    var size = header ? CREDITS_HEADER_FONT_SIZE : CREDITS_FONT_SIZE;

    // using a cast since creditsGroup is FlxSpriteGroup
    // we could also do FlxTypedSpriteGroup<FlxText>
    var creditsLine:FlxText = cast(creditsGroup.recycle(() -> new FlxText()), FlxText);
    creditsLine.x = xPos + creditsGroup.x;
    creditsLine.y = yPos + creditsGroup.y;
    creditsLine.fieldWidth = width;
    creditsLine.text = text;
    creditsLine.bold = header;
    creditsLine.setFormat(CREDITS_FONT, size, CREDITS_FONT_COLOR, FlxTextAlign.LEFT, FlxTextBorderStyle.OUTLINE, CREDITS_FONT_STROKE_COLOR, true);

    return creditsLine;
  }

  function killOffScreenLines():Void
  {
    creditsGroup.forEachExists(function(creditsLine:FlxSprite) {
      if (creditsLine.y + creditsLine.height <= 0)
      {
        creditsLine.kill();
        trace("killed line");
      }
    });
  }

  function buildNextLine():Void
  {
    // no more entriesToBuild
    if (entriesToBuild.length == 0)
    {
      return;
    }

    // line is off-screen
    if (creditsGroup.y + creditsLineY >= FlxG.height)
    {
      return;
    }

    var entry:CreditsEntry = entriesToBuild[0];
    buildCreditsEntryLine(entry);

    // check if everything has been built
    if (!entry.hasBuiltHeader || !entry.hasBuiltBody || !entry.hasBuiltBackers)
    {
      return;
    }

    entriesToBuild.shift();

    // offset that each entry has
    creditsLineY += CREDITS_FONT_SIZE * 2.5;
  }

  public override function update(elapsed:Float):Void
  {
    super.update(elapsed);

    killOffScreenLines();
    buildNextLine();

    if (!scrollPaused)
    {
      // TODO: Replace with whatever the special note button is.
      if (FlxG.keys.pressed.ENTER || FlxG.keys.pressed.SPACE #if mobile || TouchUtil.pressed && !TouchUtil.overlaps(backButton) #end)
      {
        // Move the whole group.
        creditsGroup.y -= CREDITS_SCROLL_FAST_SPEED * elapsed;
      }
      else
      {
        // Move the whole group.
        creditsGroup.y -= CREDITS_SCROLL_BASE_SPEED * elapsed;
      }
    }

    if (controls.BACK || hasEnded())
    {
      exit();
    }
    else if (controls.PAUSE)
    {
      // scrollPaused = !scrollPaused;
    }
  }

  function hasEnded():Bool
  {
    return creditsGroup.getFirstExisting() == null && entriesToBuild.length == 0;
  }

  function exit():Void
  {
    FlxG.switchState(() -> new MainMenuState());
  }

  public override function destroy():Void
  {
    super.destroy();
  }
}

enum CreditsSide
{
  Left;
  Center;
  Right;
}

typedef CreditsEntry =
{
  var data:CreditsDataRole;
  var lineIndexToBuild:Int;
  var backerIndexToBuild:Int;
  var hasBuiltHeader:Bool;
  var hasBuiltBody:Bool;
  var hasBuiltBackers:Bool;
}
