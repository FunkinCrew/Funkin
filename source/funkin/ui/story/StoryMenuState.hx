package funkin.ui.story;

class StoryMenuState extends MusicBeatState
{
  static final DEFAULT_BACKGROUND_COLOR:FlxColor = FlxColor.fromString("#F9CF51");
  static final BACKGROUND_HEIGHT:Int = 400;

  var currentDifficultyId:String = 'normal';

  var currentLevelId:String = 'tutorial';
  var currentLevel:Level;
  var isLevelUnlocked:Bool;

  var highScore:Int = 42069420;
  var highScoreLerp:Int = 12345678;

  var exitingMenu:Bool = false;
  var selectedWeek:Bool = false;

  //
  // RENDER OBJECTS
  //

  /**
   * The title of the level at the top.
   */
  var levelTitleText:FlxText;

  /**
   * The score text at the top.
   */
  var scoreText:FlxText;

  /**
   * The list of songs on the left.
   */
  var tracklistText:FlxText;

  /**
   * The title of the week in the middle.
   */
  var levelTitles:FlxTypedGroup<LevelTitle>;

  /**
   * The props in the center.
   */
  var levelProps:FlxTypedGroup<LevelProp>;

  /**
   * The background behind the props.
   */
  var levelBackground:FlxSprite;

  /**
   * The left arrow of the difficulty selector.
   */
  var leftDifficultyArrow:FlxSprite;

  /**
   * The right arrow of the difficulty selector.
   */
  var rightDifficultyArrow:FlxSprite;

  /**
   * The text of the difficulty selector.
   */
  var difficultySprite:FlxSprite;

  public function new(?stickers:StickerSubState = null)
  {
    if (stickers != null)
    {
      stickerSubState = stickers;
    }

    super();
  }

  override function create():Void
  {
    transIn = FlxTransitionableState.defaultTransIn;
    transOut = FlxTransitionableState.defaultTransOut;

    if (!FlxG.sound.music.playing)
    {
      FlxG.sound.playMusic(Paths.music('freakyMenu'));
      FlxG.sound.music.fadeIn(4, 0, 0.7);
      Conductor.forceBPM(Constants.FREAKY_MENU_BPM);
    }

    if (stickerSubState != null)
    {
      this.persistentUpdate = true;
      this.persistentDraw = true;

      openSubState(stickerSubState);
      stickerSubState.degenStickers();

      // resetSubState();
    }

    persistentUpdate = persistentDraw = true;

    // Explicitly define the background color.
    this.bgColor = FlxColor.BLACK;

    levelTitles = new FlxTypedGroup<LevelTitle>();
    add(levelTitles);

    levelBackground = new FlxSprite(0, 56).makeGraphic(FlxG.width, BACKGROUND_HEIGHT, DEFAULT_BACKGROUND_COLOR);
    add(levelBackground);

    levelProps = new FlxTypedGroup<LevelProp>();
    add(levelProps);

    scoreText = new FlxText(10, 10, 0, 'HIGH SCORE: 42069420');
    scoreText.setFormat("VCR OSD Mono", 32);
    add(scoreText);

    tracklistText = new FlxText(FlxG.width * 0.05, yellowBG.x + yellowBG.height + 100, 0, "Tracks", 32);
    tracklistText.alignment = CENTER;
    tracklistText.font = rankText.font;
    tracklistText.color = 0xFFe55777;
    add(tracklistText);

    levelTitleText = new FlxText(FlxG.width * 0.7, 10, 0, 'WEEK 1');
    levelTitleText.setFormat("VCR OSD Mono", 32, FlxColor.WHITE, RIGHT);
    levelTitleText.alpha = 0.7;
    add(levelTitleText);

    buildLevelTitles(false);

    leftArrow = new FlxSprite(grpWeekText.members[0].x + grpWeekText.members[0].width + 10, grpWeekText.members[0].y + 10);
    leftArrow.frames = Paths.getSparrowAtlas('storymenu/ui/arrows');
    leftArrow.animation.addByPrefix('idle', 'leftIdle0');
    leftArrow.animation.addByPrefix('press', 'leftConfirm0');
    leftArrow.animation.play('idle');
    add(leftArrow);

    rightArrow = new FlxSprite(sprDifficulty.x + sprDifficulty.width + 50, leftArrow.y);
    rightArrow.frames = leftArrow.frames;
    rightArrow.animation.addByPrefix('idle', 'rightIdle0');
    rightArrow.animation.addByPrefix('press', 'rightConfirm0');
    rightArrow.animation.play('idle');
    add(rightArrow);

    difficultySprite = buildDifficultySprite();
    changeDifficulty();
    add(difficultySprite);

    #if discord_rpc
    // Updating Discord Rich Presence
    DiscordClient.changePresence("In the Menus", null);
    #end
  }

  function buildDifficultySprite():Void
  {
    difficultySprite = new FlxSprite(leftArrow.x + 130, leftArrow.y);
    difficultySprite.frames = ui_tex;
    difficultySprite.animation.addByPrefix('easy', 'EASY');
    difficultySprite.animation.addByPrefix('normal', 'NORMAL');
    difficultySprite.animation.addByPrefix('hard', 'HARD');
    difficultySprite.animation.play('easy');
  }

  function buildLevelTitles(moddedLevels:Bool):Void
  {
    levelTitles.clear();

    var levelIds:Array<String> = LevelRegistry.instance.getLevelIds();
    for (levelIndex in 0...levelIds.length)
    {
      var levelId:String = levelIds[levelIndex];
      var level:Level = LevelRegistry.instance.fetchEntry(levelId);
      var levelTitleItem:LevelTitle = new LevelTitle(0, yellowBG.y + yellowBG.height + 10, level);
      levelTitleItem.targetY = ((weekThing.height + 20) * levelIndex);
      levelTitles.add(levelTitleItem);
    }
  }

  override function update(elapsed:Float)
  {
    highScoreLerp = CoolUtil.coolLerp(highScoreLerp, highScore, 0.5);

    scoreText.text = 'WEEK SCORE: ${Math.round(highScoreLerp)}';

    txtWeekTitle.text = weekNames[curWeek].toUpperCase();
    txtWeekTitle.x = FlxG.width - (txtWeekTitle.width + 10);

    handleKeyPresses();

    super.update(elapsed);
  }

  function handleKeyPresses():Void
  {
    if (!exitingMenu)
    {
      if (!selectedWeek)
      {
        if (controls.UI_UP_P)
        {
          changeLevel(-1);
        }

        if (controls.UI_DOWN_P)
        {
          changeLevel(1);
        }

        if (controls.UI_RIGHT)
        {
          rightArrow.animation.play('press')
        }
        else
        {
          rightArrow.animation.play('idle');
        }

        if (controls.UI_LEFT)
        {
          leftArrow.animation.play('press');
        }
        else
        {
          leftArrow.animation.play('idle');
        }

        if (controls.UI_RIGHT_P)
        {
          changeDifficulty(1);
        }

        if (controls.UI_LEFT_P)
        {
          changeDifficulty(-1);
        }
      }

      if (controls.ACCEPT)
      {
        selectWeek();
      }
    }

    if (controls.BACK && !exitingMenu && !selectedWeek)
    {
      FlxG.sound.play(Paths.sound('cancelMenu'));
      exitingMenu = true;
      FlxG.switchState(new MainMenuState());
    }
  }

  function changeLevel(change:Int = 0):Void {}

  function changeDifficulty(change:Int = 0):Void {}
}
