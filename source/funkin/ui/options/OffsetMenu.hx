package funkin.ui.options;

import funkin.ui.MenuList.MenuTypedList;
import funkin.ui.TextMenuList.TextMenuItem;
import funkin.util.GRhythmUtil;
import funkin.mobile.ui.FunkinBackButton;
#if mobile
import funkin.mobile.ui.FunkinHitbox;
import funkin.mobile.ui.FunkinHitbox.FunkinHitboxControlSchemes;
import funkin.mobile.input.ControlsHandler;
import funkin.util.TouchUtil;
#end
import funkin.input.PreciseInputManager;
import funkin.audio.FunkinSound;
import funkin.play.notes.Strumline;
import funkin.play.notes.StrumlineNote;
import funkin.play.notes.NoteSprite;
import funkin.graphics.FunkinCamera;
import funkin.graphics.FunkinSprite;
import funkin.data.song.SongData.SongNoteData;
import funkin.data.notestyle.NoteStyleRegistry;
import funkin.play.notes.notestyle.NoteStyle;
import funkin.play.notes.NoteSplash;
import funkin.ui.options.items.NumberPreferenceItem;
import haxe.Int64;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.FlxObject;
import flixel.util.FlxColor;
import flixel.math.FlxMath;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.sound.FlxSound;

/*
  ArrowData is a structure that holds the sprite and beat of an arrow.
  @param sprite The sprite of the arrow.
  @param beat The beat of the arrow.
 */
typedef ArrowData =
{
  var sprite:FunkinSprite;
  // var debugText:FlxText;
  var beat:Float;
  var direction:Int; // 0 = left, 1 = down, 2 = up, 3 = right
};

class OffsetMenu extends Page<OptionsState.OptionsMenuPageName>
{
  static final BPM:Int = 100;
  static final LANE_OFFSET_NAMES:Array<String> = ['Left', 'Down', 'Up', 'Right'];
  static final MENU_CAMERA_MARGIN:Int = 160;
  static final LATENCY_TEST_STEP_BEATS:Float = 1.0;
  static final LATENCY_TEST_LOOP_BEATS:Float = LATENCY_TEST_STEP_BEATS * 4;
  static final LATENCY_TEST_MAX_BEAT:Float = 124;
  static final CALIBRATION_REQUIRED_HITS:Int = 32;
  static final CALIBRATION_REQUIRED_HITS_PER_LANE:Int = 8;
  static final CALIBRATION_INPUT_WINDOW_BEATS:Float = 0.35;
  static final CALIBRATION_GUIDE_TARGET_HEIGHT:Float = 132.0;

  // Page<OptionsState.OptionsMenuPageName> stuff
  var laneOffsetItems:Array<NumberPreferenceItem> = [];
  var items:TextMenuList;
  var preferenceItems:FlxTypedSpriteGroup<FlxSprite>;
  var backButton:FunkinBackButton;

  // Background
  var blackRect:FlxSprite;

  // Text for the jump-in message and count
  var jumpInText:FlxText;
  var countText:FlxText;

  // Elements for the offset calibration (receptor, arrows, strumline, etc)
  var arrows:Array<ArrowData> = [];
  var receptor:FunkinSprite;
  var calibrationGuides:Array<StrumlineNote> = [];
  var activeCalibrationGuideDirection:Int = 2;
  var testStrumline:Strumline;
  var calibrationNoteStyle:NoteStyle;
  var calibrationArrowScale:Float = 1.0;
  public var timingTrack:Null<FlxSound> = null;
  public var drumsTrack:Null<FlxSound> = null;
  var allowCalibrationMenu:Bool;
  var allowTestMenu:Bool;

  // Camera for the menu
  var menuCamera:FunkinCamera;
  var camFocusPoint:FlxObject;
  // Variable to check if we're calibrating or testing
  var calibrating:Bool = false;

  // Variables for the offset calibration
  var savedLaneOffsets:Array<Int> = [0, 0, 0, 0];
  var tempLaneOffsets:Array<Int> = [0, 0, 0, 0];
  var calibrationDirectionCursor:Int = 0;

  // Variables for transitioning between states
  var lerped:Float = 0;
  var shouldOffset:Int = 0;
  var offsetLerp:Float = 0;
  var scaleModifier:Float = 1;
  var offsetSessionReady:Bool = false;

  // Variables for keeping time and beat
  var localConductor:Conductor;
  var arrowBeat:Float = 0;

  // Variables for differences and consistency functionality
  var _gotMad:Bool = false;
  var differences:Array<Float> = [];
  var laneDifferences:Array<Array<Float>> = [[], [], [], []];

  var msPerBeat(get, never):Float;

  // The milliseconds per beat, calculated from the BPM.
  function get_msPerBeat():Float
  {
    return 60000 / BPM;
  }

  /**
   * Key press inputs which have been received but not yet processed.
   * These are encoded with an OS timestamp, so we can account for input latency.
  **/
  var inputPressQueue:Array<PreciseInputEvent> = [];

  /**
   * Key release inputs which have been received but not yet processed.
   * These are encoded with an OS timestamp, so we can account for input latency.
  **/
  var inputReleaseQueue:Array<PreciseInputEvent> = [];

  /*
    Creates an arrow at the specified beat.
    The arrow will be positioned below the screen and will move up to the receptor.
    @param beat The beat at which to create the arrow.
   */
  public function createArrow(beat:Float):Void
  {
    var arrow = new FunkinSprite(0, 0);
    arrow.loadGraphic(Paths.image('latencyArrow'));
    arrow.origin.set(0.5, 0.5);
    arrow.setPosition(FlxG.width / 2, FlxG.height + arrow.height); // Below the screen
    arrow.updateHitbox();
    arrow.scrollFactor.set(0, 0);
    arrow.cameras = [menuCamera];
    add(arrow);

    /*var debugText = new FlxText(0, 0);
      debugText.setFormat(Paths.font('vcr.ttf'), 16, FlxColor.WHITE, FlxTextAlign.CENTER);
      debugText.text = 'Beat: ' + beat;
      debugText.setBorderStyle(FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
          add(debugText); */

    arrows.push(
      {
        sprite: arrow,
        /*debugText: debugText,*/
        beat: beat,
        direction: 0
      });
  }

  /*
    Creates a directed arrow at the specified beat and direction.
    The direction can be 0 (left), 1 (down), 2 (up), or 3 (right).
    @param beat The beat at which to create the arrow.
    @param direction The direction of the arrow.
   */
  public function createDirectedArrow(beat:Float, direction:Int):Void
  {
    var arrow = new NoteSprite(calibrationNoteStyle, direction);
    arrow.direction = direction;
    applyCalibrationArrowScale(arrow);
    arrow.origin.set(0.5, 0.5);
    arrow.setPosition(FlxG.width / 2, FlxG.height + arrow.height); // Below the screen
    arrow.updateHitbox();
    arrow.scrollFactor.set(0, 0);
    arrow.cameras = [menuCamera];
    add(arrow);

    arrows.push({sprite: arrow, beat: beat, direction: direction});
  }

  /*
    Gets the arrow at the specified beat.
    @param beat The beat at which to get the arrow.
    @return The ArrowData object containing the sprite and beat, or null if no arrow is found.
   */
  public function getArrowAtBeat(beat:Float):ArrowData
  {
    for (arrow in arrows)
    {
      if (arrow.beat == beat) return arrow;
    }
    return null;
  }

  /*
    Gets the closest arrow to the specified beat.
    This is used to find the arrow that is closest to the current time.
    @param beat The beat at which to find the closest arrow.
    @return The ArrowData object containing the sprite and beat of the closest arrow.
   */
  public function getClosestArrowAtBeat(beat:Float):ArrowData
  {
    var closest:ArrowData = null;
    var closestDiff:Float = 1000000; // A large number to start with

    for (arrow in arrows)
    {
      var diff:Float = arrow.beat - beat;
      // trace('Checking arrow at beat: ' + arrow.beat + ' (diff: ' + diff + ')');
      if (diff < closestDiff)
      {
        closestDiff = diff;
        closest = arrow;
      }
    }

    // trace('Closest arrow at beat: ' + (closest != null ? closest.beat : 0) + ' (diff: ' + closestDiff + ')');

    return closest;
  }

  public function getClosestArrowAtBeatForDirection(beat:Float, direction:Int):ArrowData
  {
    var closest:ArrowData = null;
    var closestDiff:Float = 1000000;

    for (arrow in arrows)
    {
      if (arrow.direction != direction) continue;
      var diff:Float = Math.abs(arrow.beat - beat);
      if (diff < closestDiff)
      {
        closestDiff = diff;
        closest = arrow;
      }
    }

    return closest;
  }

  function applyCalibrationArrowScale(note:NoteSprite):Void
  {
    note.scale.set(calibrationArrowScale, calibrationArrowScale);
    note.updateHitbox();
    note.centerOrigin();
  }

  function applyCalibrationGuideScale(note:StrumlineNote):Void
  {
    note.scale.set(calibrationArrowScale, calibrationArrowScale);
    note.updateHitbox();
    note.centerOrigin();
    note.playStatic();
  }

  function setActiveCalibrationGuideDirection(direction:Int):StrumlineNote
  {
    if (direction < 0 || direction > 3) direction = 2;
    activeCalibrationGuideDirection = direction;
    for (lane in 0...calibrationGuides.length)
    {
      var guide:Null<StrumlineNote> = calibrationGuides[lane];
      if (guide == null) continue;
      guide.visible = (lane == direction);
    }
    return calibrationGuides[direction] ?? calibrationGuides[2];
  }

  function findUpcomingCalibrationDirection(currentBeat:Float):Int
  {
    var closestBeatDiff:Float = Math.POSITIVE_INFINITY;
    var result:Int = calibrationDirectionCursor;
    for (arrow in arrows)
    {
      var beatDiff:Float = arrow.beat - currentBeat;
      if (beatDiff < -0.08 || beatDiff > closestBeatDiff) continue;
      closestBeatDiff = beatDiff;
      result = arrow.direction;
    }
    return result;
  }

  function getCalibrationGuideDirection(currentBeat:Float):Int
  {
    return findUpcomingCalibrationDirection(currentBeat);
  }

  function getTimingTrack():Null<FlxSound>
  {
    return timingTrack != null ? timingTrack : FlxG.sound.music;
  }

  function getDrumsTrack():Null<FlxSound>
  {
    if (drumsTrack != null) return drumsTrack;
    var optionsState = OptionsState.instance;
    return optionsState != null ? optionsState.drumsBG : null;
  }

  function isCurrentPageActive():Bool
  {
    var optionsState = OptionsState.instance;
    if (optionsState == null) return true;
    @:privateAccess
    return optionsState.optionsCodex == null || optionsState.optionsCodex.currentPage == this;
  }

  function clearCalibrationArrows():Void
  {
    for (arrow in arrows)
    {
      remove(arrow.sprite, true);
      arrow.sprite.destroy();
    }
    arrows.resize(0);
  }

  function primeOffsetSession(currentBeat:Float):Void
  {
    if (calibrating)
    {
      var calibrationStartBeat:Int = Math.floor(currentBeat);
      calibrationStartBeat = calibrationStartBeat - (calibrationStartBeat % Std.int(LATENCY_TEST_LOOP_BEATS));
      arrowBeat = calibrationStartBeat + LATENCY_TEST_LOOP_BEATS;
      calibrationDirectionCursor = Std.int(Math.floor(arrowBeat / LATENCY_TEST_STEP_BEATS)) % 4;
      setActiveCalibrationGuideDirection(calibrationDirectionCursor);
    }
    else
    {
      var flooredBeat:Int = Math.floor(currentBeat);
      arrowBeat = flooredBeat - (flooredBeat % Std.int(LATENCY_TEST_LOOP_BEATS));
      arrowBeat += LATENCY_TEST_LOOP_BEATS;
    }
  }

  public function new(allowCalibrationMenu:Bool = true, allowTestMenu:Bool = true)
  {
    super();
    this.allowCalibrationMenu = allowCalibrationMenu;
    this.allowTestMenu = allowTestMenu;

    localConductor = new Conductor();
    localConductor.forceBPM(100);

    menuCamera = new FunkinCamera('prefMenu');
    FlxG.cameras.add(menuCamera, false);
    menuCamera.bgColor = 0x0;

    camera = menuCamera;

    blackRect = new FlxSprite(0, 0);
    blackRect.makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
    blackRect.alpha = 0;
    blackRect.scrollFactor.set(0, 0);
    add(blackRect);

    /*debugBeatText = new FlxText(0, 0);
      debugBeatText.setFormat(Paths.font('vcr.ttf'), 16, FlxColor.WHITE, FlxTextAlign.LEFT);
      debugBeatText.setBorderStyle(FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
      debugBeatText.setPosition(10, 10);
      debugBeatText.scrollFactor.set(0, 0);
      add(debugBeatText);

          debugBeatText.alpha = 0; */

    receptor = new FunkinSprite(0, 0);
    receptor.loadGraphic(Paths.image('latencyReceptor'));
    receptor.origin.set(0.5, 0.5);
    receptor.scrollFactor.set(0, 0);
    add(receptor);

    var noteStyle:NoteStyle = NoteStyleRegistry.instance.fetchDefault();
    calibrationNoteStyle = noteStyle;

    calibrationGuides.resize(0);
    for (lane in 0...4)
    {
      var guide:StrumlineNote = new StrumlineNote(calibrationNoteStyle, true, cast lane);
      guide.scrollFactor.set(0, 0);
      guide.alpha = 0;
      guide.visible = (lane == activeCalibrationGuideDirection);
      calibrationGuides.push(guide);
      add(guide);
    }

    testStrumline = new Strumline(noteStyle, true);
    // center
    testStrumline.setPosition(FlxG.width / 2, FlxG.height / 2);
    testStrumline.x -= testStrumline.width / 2;
    testStrumline.scrollFactor.set(0, 0);
    add(testStrumline);

    testStrumline.cameras = [menuCamera];

    testStrumline.conductorInUse = localConductor;
    testStrumline.zIndex = 1001;
    for (strum in testStrumline)
    {
      strum.alpha = 0;
    }

    receptor.alpha = 0;
    receptor.centerOffsets();
    receptor.scale.set(0, 0);
    receptor.centerOrigin();
    receptor.updateHitbox();
    var guideScaleRef:StrumlineNote = calibrationGuides[2];
    if (guideScaleRef != null && guideScaleRef.height > 0)
    {
      calibrationArrowScale = CALIBRATION_GUIDE_TARGET_HEIGHT / guideScaleRef.height;
      if (calibrationArrowScale < 1.0) calibrationArrowScale = 1.0;
      if (calibrationArrowScale > 4.0) calibrationArrowScale = 4.0;
      for (guide in calibrationGuides)
      {
        applyCalibrationGuideScale(guide);
      }
    }

    jumpInText = new FlxText(0, 0);
    jumpInText.setFormat(Paths.font('vcr.ttf'), 32, FlxColor.WHITE, FlxTextAlign.CENTER);
    jumpInText.setBorderStyle(FlxTextBorderStyle.OUTLINE, FlxColor.BLACK, 4);
    add(jumpInText);

    receptor.cameras = [menuCamera];
    for (guide in calibrationGuides)
    {
      guide.cameras = [menuCamera];
    }
    jumpInText.cameras = [menuCamera];

    // below receptor

    countText = new FlxText(0, 0);
    countText.setFormat(Paths.font('vcr.ttf'), 32, FlxColor.WHITE, FlxTextAlign.CENTER);
    countText.setBorderStyle(FlxTextBorderStyle.OUTLINE, FlxColor.BLACK, 4);
    add(countText);

    jumpInText.alpha = 0;
    jumpInText.setPosition(FlxG.width / 2, 150);
    jumpInText.scrollFactor.set(0, 0);

    countText.text = '';
    countText.alpha = 0;
    countText.setPosition(FlxG.width / 2, 600);
    countText.scrollFactor.set(0, 0);

    countText.cameras = [menuCamera];

    add(items = new TextMenuList());
    add(preferenceItems = new FlxTypedSpriteGroup<FlxSprite>());

    Preferences.globalOffset = 0;
    laneOffsetItems.resize(0);
    for (laneIndex in 0...4)
    {
      var currentLaneIndex:Int = laneIndex;
      var laneName:String = LANE_OFFSET_NAMES[currentLaneIndex];
      var laneOffset:Int = Preferences.getLaneOffset(cast currentLaneIndex);
      var item:NumberPreferenceItem = createPrefItemNumber('Offset (${laneName})', 'Offset (${laneName})', function(value:Float) {
        Preferences.setLaneOffset(cast currentLaneIndex, Std.int(value));
      }, null, laneOffset, -1500, 1500, 1.0, 2, 5);
      laneOffsetItems.push(item);
    }
    createButtonItem('Reset Offset', function() {
      Preferences.resetLaneOffsets();
      for (laneIndex in 0...laneOffsetItems.length)
      {
        laneOffsetItems[laneIndex].currentValue = Preferences.getLaneOffset(cast laneIndex);
      }
    });
    if (allowCalibrationMenu)
    {
      createButtonItem('Offset Calibration', function() {
        testStrumline.alpha = 0;

        testStrumline.clean();
        testStrumline.noteData = [];
        testStrumline.nextNoteIndex = 0;
        if (!isCurrentPageActive()) return;
        var timingTrack = getTimingTrack();
        if (timingTrack == null) return;
        var drumsTrack = getDrumsTrack();

        jumpInText.text = 'Press any key to the beat!\nThe arrow will start to sync to the receptor.';
        #if mobile
        jumpInText.text = 'Tap to the beat!\nThe arrow will start to sync to the receptor.';
        #end
        jumpInText.text = 'Hit each lane in time with the arrows.';

        jumpInText.y = 100;

        countText.text = 'Lane L/D/U/R: 0 / 0 / 0 / 0';

        calibrating = true;
        offsetSessionReady = false;
        MenuTypedList.pauseInput = true;
        if (drumsTrack != null)
        {
          drumsTrack.pause();
          drumsTrack.time = timingTrack.time;
          drumsTrack.resume();
          drumsTrack.fadeIn(1, 0, 1);
        }
        canExit = false;
        differences = [];
        laneDifferences = [[], [], [], []];
        inputPressQueue.resize(0);
        inputReleaseQueue.resize(0);
        clearCalibrationArrows();
        offsetLerp = 0;
        for (laneIndex in 0...4)
        {
          savedLaneOffsets[laneIndex] = Preferences.getLaneOffset(cast laneIndex);
        }
        Preferences.globalOffset = 0;
        Preferences.resetLaneOffsets();
        shouldOffset = 1;
        tempLaneOffsets = [0, 0, 0, 0];
        calibrationDirectionCursor = 0;
        setActiveCalibrationGuideDirection(2);
        localConductor.update(timingTrack.time, true);
        arrowBeat = 0;
        receptor.angle = 0;

        _gotMad = false;
      });
    }
    if (allowTestMenu)
    {
      createButtonItem('Test', function() {
        if (!isCurrentPageActive()) return;
        var timingTrack = getTimingTrack();
        if (timingTrack == null) return;
        var drumsTrack = getDrumsTrack();

        shouldOffset = 1;
        offsetSessionReady = false;
        testStrumline.clean();
        testStrumline.noteData = [];
        testStrumline.nextNoteIndex = 0;
        clearCalibrationArrows();

        if (drumsTrack != null)
        {
          drumsTrack.pause();
          drumsTrack.time = timingTrack.time;
          drumsTrack.resume();
        }
        localConductor.update(timingTrack.time, true);
        arrowBeat = 0;

        jumpInText.text = 'Hit the notes as they come in!';
        #if mobile
        if (OptionsState.instance != null && OptionsState.instance.hitbox != null) OptionsState.instance.hitbox.visible = true;
        if (!ControlsHandler.usingExternalInputDevice)
        {
          final amplification:Float = (FlxG.width / FlxG.height) / (FlxG.initialWidth / FlxG.initialHeight);
          final playerStrumlineScale:Float = ((FlxG.height / FlxG.width) * 1.95) * amplification;
          final playerNoteSpacing:Float = ((FlxG.height / FlxG.width) * 2.8) * amplification;

          testStrumline.strumlineScale.set(playerStrumlineScale, playerStrumlineScale);
          testStrumline.setNoteSpacing(playerNoteSpacing);
          testStrumline.width *= 2;

          var height = testStrumline.strumlineNotes.members[0].height;

          testStrumline.x = (FlxG.width - testStrumline.width) / 2 + Constants.STRUMLINE_X_OFFSET;
          testStrumline.y = (FlxG.height - height) * 0.95 - Constants.STRUMLINE_Y_OFFSET;
          testStrumline.y -= 10;
        }
        else
        {
          if (testStrumline != null)
          {
            testStrumline.destroy();
            remove(testStrumline);
          }

          testStrumline = new Strumline(noteStyle, true);
          testStrumline.setPosition(FlxG.width / 2, FlxG.height / 2);
          testStrumline.x -= testStrumline.width / 2;
          testStrumline.scrollFactor.set(0, 0);
          add(testStrumline);
        }
        #end
        MenuTypedList.pauseInput = true;
        if (drumsTrack != null) drumsTrack.fadeIn(1, 0, 1);
        canExit = false;
        differences = [];
        inputPressQueue.resize(0);
        inputReleaseQueue.resize(0);

        jumpInText.y = 350;

        #if mobile
        if (ControlsHandler.usingExternalInputDevice)
        {
        #end
          var height = testStrumline.strumlineNotes.members[0].height;
          testStrumline.y = Preferences.downscroll ? FlxG.height - (height + 45) - Constants.STRUMLINE_Y_OFFSET : (height / 2) - Constants.STRUMLINE_Y_OFFSET;
          if (Preferences.downscroll) jumpInText.y = FlxG.height - 425;
          testStrumline.isDownscroll = Preferences.downscroll;
        #if mobile
        }
        else
        {
          jumpInText.y = FlxG.height - 425;
        }
        #end
      });
    }
    PreciseInputManager.instance.onInputPressed.add(onKeyPress);
    PreciseInputManager.instance.onInputReleased.add(onKeyRelease);

    camFocusPoint = new FlxObject(FlxG.width / 2, 0, 140, 70);
    add(camFocusPoint);
    menuCamera.follow(camFocusPoint, null, 0.085);
    menuCamera.deadzone.set(0, MENU_CAMERA_MARGIN, menuCamera.width, menuCamera.height - MENU_CAMERA_MARGIN * 2);
    menuCamera.minScrollY = 0;
    camFocusPoint.y = items.selectedItem != null ? items.selectedItem.y : 0;
    items.onChange.add(function(selected) {
      if (shouldOffset == 0) camFocusPoint.y = selected.y;
    });

    backButton = new FunkinBackButton(FlxG.width - 230, FlxG.height - 200, FlxColor.WHITE, handleMobileExit);
    backButton.scrollFactor.set(0, 0);
    #if FEATURE_TOUCH_CONTROLS // We do this here because we want to animate the back button (on Mobile), but we don't want it on Desktop.
    add(backButton);
    #end
  }

  /**
     * Callback executed when one of the note keys is pressed.
     */
  function onKeyPress(event:PreciseInputEvent):Void
  {
    // Do the minimal possible work here.
    inputPressQueue.push(event);
  }

  /**
     * Callback executed when one of the note keys is released.
     */
  function onKeyRelease(event:PreciseInputEvent):Void
  {
    // Do the minimal possible work here.
    inputReleaseQueue.push(event);
  }

  // Exits the calibration and resets the offset.
  public function exitCalibration(cancel:Bool):Void
  {
    backButton.enabled = false;
    shouldOffset = -1;
    offsetSessionReady = false;
    #if mobile
    if (OptionsState.instance != null && OptionsState.instance.hitbox != null) OptionsState.instance.hitbox.visible = false;
    #end
    Preferences.globalOffset = 0;
    if (cancel)
    {
      if (calibrating)
      {
        for (laneIndex in 0...4)
        {
          Preferences.setLaneOffset(cast laneIndex, savedLaneOffsets[laneIndex]);
        }
      }
      #if !mobile
      // mobile would play this twice
      FunkinSound.playOnce(Paths.sound('cancelMenu'));
      #end
    }
    else
      FunkinSound.playOnce(Paths.sound('confirmMenu'));
    for (laneIndex in 0...laneOffsetItems.length)
    {
      laneOffsetItems[laneIndex].currentValue = Preferences.getLaneOffset(cast laneIndex);
    }
    clearCalibrationArrows();
    var drumsTrack = getDrumsTrack();
    if (drumsTrack != null) drumsTrack.fadeOut(1, 0);
  }

  // Handles the exit for mobile devices.
  public function handleMobileExit():Void
  {
    if (shouldOffset == 1) exitCalibration(true);
    else if (shouldOffset == 0) exit();
  }

  // Returns the average of the differences in milliseconds.
  // Average is the sum of all differences divided by the number of differences.
  public function getAverage():Float
  {
    if (differences.length == 0) return 0;

    var avg:Float = 0;
    for (i in 0...differences.length)
    {
      avg += differences[i];
    }
    avg /= differences.length;

    return avg;
  }

  public function getLaneAverage(lane:Int):Float
  {
    if (lane < 0 || lane >= laneDifferences.length) return 0;
    var laneDiffs:Array<Float> = laneDifferences[lane];
    if (laneDiffs == null || laneDiffs.length == 0) return 0;

    var avg:Float = 0;
    for (value in laneDiffs)
    {
      avg += value;
    }
    avg /= laneDiffs.length;

    return avg;
  }

  public function hasCalibrationCoverage(minHitsPerLane:Int):Bool
  {
    for (lane in 0...4)
    {
      var laneDiffs:Array<Float> = laneDifferences[lane];
      if (laneDiffs == null || laneDiffs.length < minHitsPerLane) return false;
    }
    return true;
  }

  // Returns the consistency of the differences.
  // Consistency is the average of the squared differences from the mean.
  public function getConsistency():Float
  {
    if (differences.length == 0) return 0;

    var avg:Float = getAverage();

    var variance:Float = 0;
    for (i in 0...differences.length)
    {
      variance += Math.pow(differences[i] - avg, 2);
    }
    variance /= differences.length;

    return Math.sqrt(variance);
  }

  /* Adds a difference in milliseconds to the list.
      It updates lane offset estimates from collected input samples.
      This is used for calibrating the offset based on user input.
      @param ms The difference in milliseconds to add.
     */
  public function addDifference(ms:Float, ?lane:Int):Void
  {
    differences.push(ms);
    if (lane != null && lane >= 0 && lane < 4)
    {
      laneDifferences[lane].push(ms);
    }

    if (calibrating)
    {
      for (laneIndex in 0...4)
      {
        if (laneDifferences[laneIndex].length == 0)
        {
          tempLaneOffsets[laneIndex] = 0;
          continue;
        }
        tempLaneOffsets[laneIndex] = Std.int(getLaneAverage(laneIndex));
      }
    }
  }

  var _lastBeat:Float = 0;
  var _lastTime:Float = 0;

  override function update(elapsed:Float):Void
  {
    super.update(elapsed);
    localConductor.update(localConductor.songPosition + elapsed * 1000, false);

    var b:Float = localConductor.currentBeatTime;
    var timingTrack = getTimingTrack();
    if (shouldOffset == 1 && timingTrack == null)
    {
      exitCalibration(true);
      return;
    }
    var timingTime:Float = timingTrack != null ? timingTrack.time : localConductor.songPosition;

    // Restart logic
    if (timingTrack != null && timingTime < _lastTime)
    {
      localConductor.update(timingTime, !calibrating);
      b = localConductor.currentBeatTime;

      // Update arrows to be the correct distance away from the receptor.
      var lastArrowBeat:Float = 0;
      for (i in 0...arrows.length)
      {
        var arrow:ArrowData = arrows[i];
        var beatDiff:Float = arrow.beat - _lastBeat;

        arrow.beat = b + beatDiff;
        lastArrowBeat = arrow.beat;
      }
      if (calibrating)
      {
        if (lastArrowBeat > 0)
        {
          arrowBeat = lastArrowBeat;
        }
        else
        {
          var calibrationStartBeat:Int = Math.floor(b);
          calibrationStartBeat = calibrationStartBeat - (calibrationStartBeat % Std.int(LATENCY_TEST_LOOP_BEATS));
          arrowBeat = calibrationStartBeat + LATENCY_TEST_LOOP_BEATS;
        }
        calibrationDirectionCursor = Std.int(Math.floor(arrowBeat / LATENCY_TEST_STEP_BEATS)) % 4;
      }
      else
        arrowBeat = 4;

      testStrumline.clean();
      testStrumline.noteData = [];
      testStrumline.nextNoteIndex = 0;

      _lastTime = timingTime;
      return;
    }

    _lastBeat = b;

    // Resync logic
    var diff:Float = Math.abs((timingTime + localConductor.combinedOffset) - localConductor.songPosition);
    var drumsTrack = getDrumsTrack();
    var diffBg:Float = drumsTrack != null ? Math.abs(timingTime - drumsTrack.time) : 0;
    if (diff > 50 || diffBg > 50)
    {
      trace('Resyncing conductor: ' + (diff > diffBg ? diff : diffBg) + 'ms difference');

      // If the difference is greater than 50ms, we resync the conductor.
      localConductor.update(timingTime, true);
      if (drumsTrack != null)
      {
        drumsTrack.pause();
        drumsTrack.time = timingTime;
        drumsTrack.resume();
      }
      b = localConductor.currentBeatTime;
      _lastBeat = b;
    }

    _lastTime = timingTime;

    // Back logic
    if (controls.BACK_P && shouldOffset == 1)
    {
      exitCalibration(true);
      return;
    }

    if (shouldOffset != 0)
    {
      menuCamera.scroll.y = 0;
    }

    if (shouldOffset == 1 && !offsetSessionReady)
    {
      if (offsetLerp >= 0.98)
      {
        localConductor.update(timingTime, true);
        b = localConductor.currentBeatTime;
        primeOffsetSession(b);
        offsetSessionReady = true;
      }
      inputPressQueue.resize(0);
      inputReleaseQueue.resize(0);
    }

    // Calibration logic
    if (shouldOffset == 1 && calibrating)
    {
      var guideDirection:Int = getCalibrationGuideDirection(b);
      var activeGuide:StrumlineNote = setActiveCalibrationGuideDirection(guideDirection);
      if (activeGuide != null)
      {
        activeGuide.x = FlxG.width / 2 - (activeGuide.width / 2);
        activeGuide.y = FlxG.height / 2 - (activeGuide.height / 2);
      }
      countText.text = 'Lane L/D/U/R: ${tempLaneOffsets[0]} / ${tempLaneOffsets[1]} / ${tempLaneOffsets[2]} / ${tempLaneOffsets[3]}';

      if (offsetSessionReady)
      {
        var toRemove:Array<ArrowData> = [];
        var _lastArrowBeat:Float = 0;
        var guideCenterX:Float = (activeGuide != null) ? (activeGuide.x + (activeGuide.width / 2)) : (FlxG.width / 2);
        var guideCenterY:Float = (activeGuide != null) ? (activeGuide.y + (activeGuide.height / 2)) : (FlxG.height / 2);
        for (i in 0...arrows.length)
        {
          var arrow:ArrowData = arrows[i];

          var ms:Float = arrow.beat * msPerBeat;
          var offset:Float = GRhythmUtil.getNoteY(ms, 2, false, localConductor);
          arrow.sprite.x = guideCenterX - (arrow.sprite.width / 2);
          arrow.sprite.y = guideCenterY + offset - (arrow.sprite.height / 2);

          if (arrow.beat < b - 0.25)
          {
            arrow.sprite.alpha -= elapsed * 5;
          }

          if (arrow.beat == _lastArrowBeat || arrow.sprite.alpha <= 0)
          {
            toRemove.push(arrow);
            continue;
          }
          _lastArrowBeat = arrow.beat;
        }

        for (arrow in toRemove)
        {
          arrow.sprite.kill();
          remove(arrow.sprite, true);
          arrow.sprite.destroy();
          arrows.remove(arrow);
        }

        while (b >= arrowBeat - 1)
        {
          if (arrowBeat < LATENCY_TEST_MAX_BEAT)
          {
            createDirectedArrow(arrowBeat, calibrationDirectionCursor);
            calibrationDirectionCursor = (calibrationDirectionCursor + 1) % 4;
          }
          arrowBeat += LATENCY_TEST_STEP_BEATS;
        }

        while (inputPressQueue.length > 0)
        {
          var input:PreciseInputEvent = inputPressQueue.shift();
          var inputDirection:Int = cast input.noteDirection;
          var inputLatencyNs:Int64 = PreciseInputManager.getCurrentTimestamp() - input.timestamp;
          var inputLatencyMs:Float = inputLatencyNs.toFloat() / Constants.NS_PER_MS;
          var inputBeat:Float = b - (inputLatencyMs / msPerBeat);

          var arrow:ArrowData = getClosestArrowAtBeatForDirection(inputBeat, inputDirection);
          if (arrow == null) continue;

          var arrowDiff:Float = arrow.beat - inputBeat;
          if (Math.abs(arrowDiff) > CALIBRATION_INPUT_WINDOW_BEATS) continue;

          arrow.sprite.alpha = 0;
          arrow.sprite.kill();
          remove(arrow.sprite, true);
          arrow.sprite.destroy();
          arrows.remove(arrow);

          var ms:Float = arrowDiff * msPerBeat;
          var consistency:Float = getConsistency();

          if (consistency > 80 && differences.length > 4)
          {
            jumpInText.text = 'Try to be a little more consistent with your timing!';
            differences = [];
            laneDifferences = [[], [], [], []];
            tempLaneOffsets = [0, 0, 0, 0];
            _gotMad = true;
            continue;
          }

          addDifference(ms, inputDirection);

          if (differences.length >= CALIBRATION_REQUIRED_HITS)
          {
            if (!hasCalibrationCoverage(CALIBRATION_REQUIRED_HITS_PER_LANE))
            {
              jumpInText.text = 'Keep going until every lane is sampled.';
              jumpInText.text += '\n' + differences.length + '/${CALIBRATION_REQUIRED_HITS}';
              _gotMad = true;
              continue;
            }

            jumpInText.text = 'Calibration complete!';
            Preferences.globalOffset = 0;
            for (laneIndex in 0...4)
            {
              Preferences.setLaneOffset(cast laneIndex, tempLaneOffsets[laneIndex]);
            }
            exitCalibration(false);
            return;
          }

          if (!_gotMad)
          {
            if (Math.abs(ms) < 45) jumpInText.text = 'Great job, keep going!';
            else
              jumpInText.text = 'Nice job, keep going!';
          }

          jumpInText.text += '\n' + differences.length + '/${CALIBRATION_REQUIRED_HITS}';

          _gotMad = false;

          scaleModifier = 0.75;
        }
        inputReleaseQueue.resize(0);
      }
      else
      {
        inputPressQueue.resize(0);
        inputReleaseQueue.resize(0);
      }
    }
    // Testing logic
    else if (shouldOffset == 1)
    {
      if (offsetSessionReady)
      {
        processInputQueue();

        while (b >= arrowBeat - 2 && b < LATENCY_TEST_MAX_BEAT)
        {
          for (lane in 0...4)
          {
            var laneBeat:Float = arrowBeat + (lane * LATENCY_TEST_STEP_BEATS);
            if (laneBeat >= LATENCY_TEST_MAX_BEAT) continue;
            var data:SongNoteData = new SongNoteData(laneBeat * msPerBeat, lane, 0, null, null);
            testStrumline.addNoteData(data, false);
          }
          arrowBeat += LATENCY_TEST_LOOP_BEATS;
        }
      }
      else
      {
        inputPressQueue.resize(0);
        inputReleaseQueue.resize(0);
      }
    }
    // Remove arrows and what not for when we are exiting calibration/testing
    else
    {
      var toRemove:Array<ArrowData> = [];
      for (i in 0...arrows.length)
      {
        var arrow:ArrowData = arrows[i];
        arrow.sprite.alpha -= elapsed * 5;
        if (arrow.sprite.alpha <= 0)
        {
          toRemove.push(arrow);
        }
      }

      // Remove arrows that are marked for removal.
      for (arrow in toRemove)
      {
        arrow.sprite.kill();
        remove(arrow.sprite, true);
        arrow.sprite.destroy();
        arrows.remove(arrow);
      }
    }
    // Transitioning logic (animations and what not)
    if (lerped < 1) lerped += elapsed / 2;
    else if (lerped > 1) lerped = 1;

    if (shouldOffset == 1)
    {
      offsetLerp += elapsed / 2;
      if (offsetLerp >= 1) offsetLerp = 1;
    }
    else if (shouldOffset == -1)
    {
      offsetLerp -= elapsed / 3;
      if (offsetLerp <= 0) // We're exiting the calibration OR testing state
      {
        backButton.enabled = true;
        canExit = true;
        calibrating = false;
        offsetSessionReady = false;
        MenuTypedList.pauseInput = false;
        offsetLerp = 0;
        shouldOffset = 0;
      }
    }

    blackRect.alpha = FlxMath.lerp(0, 0.5, FlxEase.cubeInOut(lerped));

    var yLerp = FlxMath.lerp(-480, 100, FlxEase.cubeInOut(lerped));
    var xLerp = FlxMath.lerp(0, FlxG.width, FlxEase.cubeInOut(offsetLerp));

    // center
    var activeGuide:StrumlineNote = calibrationGuides[activeCalibrationGuideDirection] ?? calibrationGuides[2];
    var guideW:Float = activeGuide != null ? activeGuide.width : receptor.width;
    var guideH:Float = activeGuide != null ? activeGuide.height : receptor.height;
    jumpInText.x = FlxG.width / 2 - (jumpInText.width / 2);
    countText.x = FlxG.width / 2 - (countText.width / 2);

    var guideX:Float = FlxG.width / 2 - (guideW / 2);
    var guideY:Float = FlxG.height / 2 - (guideH / 2);
    for (guide in calibrationGuides)
    {
      guide.x = guideX;
      guide.y = guideY;
    }
    receptor.x = guideX;
    receptor.y = guideY;

    jumpInText.alpha = FlxMath.lerp(0, 1, FlxEase.cubeInOut(offsetLerp));

    if (calibrating)
    {
      receptor.alpha = 0;
      var guideAlpha:Float = FlxMath.lerp(0, 1, FlxEase.cubeInOut(offsetLerp));
      for (lane in 0...calibrationGuides.length)
      {
        calibrationGuides[lane].alpha = (lane == activeCalibrationGuideDirection) ? guideAlpha : 0;
      }
      // debugBeatText.alpha = FlxMath.lerp(0, 1, FlxEase.cubeInOut(offsetLerp));
      countText.alpha = FlxMath.lerp(0, 1, FlxEase.cubeInOut(offsetLerp));
    }
    else
    {
      receptor.alpha = 0;
      for (guide in calibrationGuides)
      {
        guide.alpha = 0;
      }
      testStrumline.alpha = FlxMath.lerp(0, 1, FlxEase.cubeInOut(offsetLerp));
      backButton.y = FlxMath.lerp(FlxG.height - 200, 50, FlxEase.cubeInOut(offsetLerp));
    }

    if (scaleModifier < 1)
    {
      // trace("scaleModifier: " + scaleModifier);
      scaleModifier += elapsed / 2;
      if (scaleModifier >= 1) scaleModifier = 1;
    }

    // Update alpha and note window (canHit)
    for (note in testStrumline.notes.members)
    {
      if (note == null) continue;

      GRhythmUtil.processWindow(note, true, localConductor);
      note.alpha = FlxMath.lerp(0, 1, FlxEase.cubeInOut(offsetLerp));
    }

    /*debugBeatText.x = receptor.x + receptor.width * 2;
        debugBeatText.y = receptor.y - 20;

            debugBeatText.text = 'Beat: ' + b; */

    // receptor.angle += angleVel * elapsed;

    var ind = 0;
    // Indent the selected item.
    items.forEach(function(daItem:TextMenuItem) {
      // Initializing thy text width (if thou text present)
      var thyTextWidth:Int = 0;
      switch (Type.typeof(daItem))
      {
        case TClass(NumberPreferenceItem):
          var numPref:NumberPreferenceItem = cast(daItem, NumberPreferenceItem);
          thyTextWidth = numPref.lefthandText.getWidth();

          numPref.lefthandText.x = xLerp + (FlxG.width / 2) - ((thyTextWidth + daItem.atlasText.getWidth() + 20) / 2);
          numPref.lefthandText.y = yLerp + ((120 * ind) + 30);
          daItem.x = numPref.lefthandText.x + thyTextWidth + 20;
        default:
          daItem.x = xLerp + (FlxG.width / 2) - daItem.atlasText.getWidth() / 2;
      }

      daItem.y = yLerp + ((120 * ind) + 30);
      ind++;
    });

    if (camFocusPoint != null)
    {
      if (shouldOffset == 0)
      {
        camFocusPoint.y = items.selectedItem != null ? items.selectedItem.y : 0;
      }
      else
      {
        camFocusPoint.y = 0;
      }
    }
  }

  function hitNote(note:NoteSprite, input:PreciseInputEvent):Void
  {
    var inputLatencyNs:Int64 = PreciseInputManager.getCurrentTimestamp() - input.timestamp;
    var inputLatencyMs:Float = inputLatencyNs.toFloat() / Constants.NS_PER_MS;

    var diff:Float = note.noteData.time - localConductor.songPosition;

    // trace('Input latency: ' + inputLatencyMs + 'ms (diff: ' + diff + 'ms)');

    var totalDiff:Float = diff;
    if (totalDiff < 0) totalDiff = diff + inputLatencyMs;
    else
      totalDiff = diff - inputLatencyMs;

    var noteDiff:Int = Std.int(totalDiff);

    addDifference(noteDiff);

    if (noteDiff == 0)
    {
      // \n to signify a line break (because the original text has 3 lines)
      jumpInText.text = 'Perfect!\n';
      var notesplash:NoteSplash = new NoteSplash(NoteStyleRegistry.instance.fetchEntry(Constants.DEFAULT_NOTE_STYLE));
      notesplash.play(note.direction, 0);
      notesplash.setPosition(note.x, note.y);
      add(notesplash);
    }
    else
    {
      jumpInText.text = noteDiff > 0 ? 'Early!\n' + noteDiff + 'ms' : 'Late!\n' + noteDiff + 'ms';
    }

    jumpInText.text += '\nAvg: ' + Std.int(getAverage()) + 'ms';

    testStrumline.hitNote(note);
  }

  /**
     * PreciseInputEvents are put into a queue between update() calls,
     * and then processed here.
     */
  function processInputQueue():Void
  {
    if (inputPressQueue.length + inputReleaseQueue.length == 0 || shouldOffset != 1) return;

    var notesInRange:Array<NoteSprite> = testStrumline.getNotesMayHit();

    var notesByDirection:Array<Array<NoteSprite>> = [[], [], [], []];

    for (note in notesInRange)
      notesByDirection[note.direction].push(note);

    while (inputPressQueue.length > 0)
    {
      var input:PreciseInputEvent = inputPressQueue.shift();

      testStrumline.pressKey(input.noteDirection, input.keyCode);

      var notesInDirection:Array<NoteSprite> = notesByDirection[input.noteDirection];

      // trace('Processing input: ' + input.noteDirection + ' with ' + notesInDirection.length + ' notes in range.');

      if (notesInDirection.length == 0)
      {
        testStrumline.playPress(input.noteDirection);
      }
      else
      {
        // Choose the first note, deprioritizing low priority notes.
        var targetNote:Null<NoteSprite> = notesInDirection.find((note) -> !note.lowPriority);
        if (targetNote == null) targetNote = notesInDirection[0];
        if (targetNote == null) continue;

        hitNote(targetNote, input);
        notesInDirection.remove(targetNote);

        // Play the strumline animation.
        testStrumline.playConfirm(input.noteDirection);
      }
    }

    while (inputReleaseQueue.length > 0)
    {
      var input:PreciseInputEvent = inputReleaseQueue.shift();

      // Play the strumline animation.
      testStrumline.playStatic(input.noteDirection);

      testStrumline.releaseKey(input.noteDirection, input.keyCode);
    }

    testStrumline.noteVibrations.tryNoteVibration();
  }

  // Creates a button item with a callback.
  function createButtonItem(name:String, callback:Void->Void):Void
  {
    var item = items.createItem(funkin.ui.FullScreenScaleMode.gameNotchSize.x, (120 * items.length) + 30, name, BOLD, callback);
    items.addItem(name, item);
  }

  // Creates a preference item with a number input.
  function createPrefItemNumber(prefName:String, prefDesc:String, onChange:Float->Void, ?valueFormatter:Float->String, defaultValue:Int, min:Int, max:Int,
      step:Float = 0.1, precision:Int, dragStepMultiplier:Float = 1):NumberPreferenceItem
  {
    var item = new NumberPreferenceItem(funkin.ui.FullScreenScaleMode.gameNotchSize.x, (120 * items.length) + 30, prefName, defaultValue, min, max, step,
      precision, onChange, valueFormatter, dragStepMultiplier);
    items.addItem(prefName, item);
    preferenceItems.add(item.lefthandText);
    return item;
  }

  override public function destroy()
  {
    MenuTypedList.pauseInput = false;
    if (PreciseInputManager.instance != null)
    {
      PreciseInputManager.instance.onInputPressed.remove(onKeyPress);
      PreciseInputManager.instance.onInputReleased.remove(onKeyRelease);
    }
    clearCalibrationArrows();
    exitCalibration(true);
    if (menuCamera != null && FlxG.cameras.list.contains(menuCamera)) FlxG.cameras.remove(menuCamera);
    super.destroy();
  }
}
