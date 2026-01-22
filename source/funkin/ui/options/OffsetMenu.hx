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
import flixel.util.FlxColor;
import flixel.math.FlxMath;
import flixel.tweens.FlxEase;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;

/**
 * Data structure for an arrow in the offset calibration/testing screen.
 * Contains the sprite, beat, and direction of the arrow.
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

  // Page<OptionsState.OptionsMenuPageName> stuff
  var offsetItem:NumberPreferenceItem;
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
  var testStrumline:Strumline;

  // Camera for the menu
  var menuCamera:FunkinCamera;
  // Variable to check if we're calibrating or testing
  var calibrating:Bool = false;

  // Variables for the offset calibration
  var appliedOffsetLerp:Float = 0;
  var savedOffset:Int = 0;
  var tempOffset:Int = 0;

  // Variables for transitioning between states
  var lerped:Float = 0;
  var shouldOffset:Int = 0;
  var offsetLerp:Float = 0;
  var scaleModifier:Float = 1;

  // Variables for keeping time and beat
  var localConductor:Conductor;
  var arrowBeat:Float = 0;

  // Variables for differences and consistency functionality
  var _gotMad:Bool = false;
  var differences:Array<Float> = [];

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

  /**
   * Creates an arrow at the specified beat.
   * @param beat The beat to create the arrow at.
   */
  public function createArrow(beat:Float):Void
  {
    var arrow = new FunkinSprite(0, 0);
    arrow.loadGraphic(Paths.image('latencyArrow'));
    arrow.origin.set(0.5, 0.5);
    arrow.setPosition(FlxG.width / 2, FlxG.height + arrow.height); // Below the screen
    arrow.updateHitbox();
    arrow.cameras = [menuCamera];
    add(arrow);

    arrows.push(
      {
        sprite: arrow,
        beat: beat,
        direction: 0
      });
  }

  /**
   * Gets the arrow at the specified beat.
   * @param beat The beat to check.
   * @return ArrowData of the arrow at the specified beat, or null if none exists.
   */
  public function getArrowAtBeat(beat:Float):ArrowData
  {
    for (arrow in arrows)
    {
      if (arrow.beat == beat) return arrow;
    }
    return null;
  }

  /**
   * Gets the closest arrow to the specified beat.
   * @param beat The beat to check against.
   * @return ArrowData of the closest arrow.
   */
  public function getClosestArrowAtBeat(beat:Float):ArrowData
  {
    var closest:ArrowData = null;
    var closestDiff:Float = 1000000; // A large number to start with

    for (arrow in arrows)
    {
      var diff:Float = arrow.beat - beat;
      if (diff < closestDiff)
      {
        closestDiff = diff;
        closest = arrow;
      }
    }


    return closest;
  }

  public function new()
  {
    super();

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

    receptor = new FunkinSprite(0, 0);
    receptor.loadGraphic(Paths.image('latencyReceptor'));
    receptor.origin.set(0.5, 0.5);
    add(receptor);

    var noteStyle:NoteStyle = NoteStyleRegistry.instance.fetchDefault();

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

    jumpInText = new FlxText(0, 0);
    jumpInText.setFormat(Paths.font('vcr.ttf'), 32, FlxColor.WHITE, FlxTextAlign.CENTER);
    jumpInText.setBorderStyle(FlxTextBorderStyle.OUTLINE, FlxColor.BLACK, 4);
    add(jumpInText);

    receptor.cameras = [menuCamera];
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

    offsetItem = createPrefItemNumber('Offset (Global)', 'Offset (Global)', function(value:Float) {
      Preferences.globalOffset = Std.int(value);
    }, null, Preferences.globalOffset, -1500, 1500, 1.0, 2, 5);
    createButtonItem('Reset Offset', function() {
      Preferences.globalOffset = 0;
      offsetItem.currentValue = Preferences.globalOffset;
    });
    createButtonItem('Offset Calibration', function() {
      // Reset calibration state and start another one.

      testStrumline.alpha = 0;

      testStrumline.clean();
      testStrumline.noteData = [];
      testStrumline.nextNoteIndex = 0;
      @:privateAccess
      if (OptionsState.instance.optionsCodex.currentPage != this) return;

      jumpInText.text = 'Press any key to the beat!';
      #if mobile
      jumpInText.text = 'Tap to the beat!';
      #end

      jumpInText.y = 100;

      countText.text = 'Current Offset: 0ms';

      calibrating = true;
      MenuTypedList.pauseInput = true;
      OptionsState.instance.drumsBG.pause();
      OptionsState.instance.drumsBG.time = FlxG.sound.music.time;
      OptionsState.instance.drumsBG.resume();
      OptionsState.instance.drumsBG.fadeIn(1, 0, 1);
      canExit = false;
      differences = [];
      offsetLerp = 0;
      savedOffset = Preferences.globalOffset;
      Preferences.globalOffset = 0; // We save the offset and set it to 0 so the player can recalibrate.
      shouldOffset = 1;
      tempOffset = 0;
      appliedOffsetLerp = 0;

      arrowBeat = Math.floor(localConductor.currentBeatTime) + 4;
      receptor.angle = 0;

      _gotMad = false;
    });
    createButtonItem('Test', function() {
      // Reset testing state and start another one.
      // We do not reset the offset here, so the player can test their current offset.
      @:privateAccess
      if (OptionsState.instance.optionsCodex.currentPage != this) return;

      shouldOffset = 1;
      testStrumline.clean();
      testStrumline.noteData = [];
      testStrumline.nextNoteIndex = 0;

      OptionsState.instance.drumsBG.pause();
      OptionsState.instance.drumsBG.time = FlxG.sound.music.time;
      OptionsState.instance.drumsBG.resume();
      localConductor.update(FlxG.sound.music.time, true);

      var floored = Math.floor(localConductor.currentBeatTime);
      arrowBeat = floored - (floored % 4);
      arrowBeat += 4;
      _lastDirection = 0;

      var diffBeats = Math.floor(arrowBeat - localConductor.currentBeatTime);

      trace('Prestart arrowBeat: ' + arrowBeat);

      if (diffBeats < 4) arrowBeat += (arrowBeat % 4) + 4; // Ensure we have at least 4 beats to test.

      trace('Testing strumline at beat: ' + arrowBeat + ' diff: ' + diffBeats);

      jumpInText.text = 'Hit the notes as they come in!';
      #if mobile
      if (OptionsState.instance.hitbox != null) OptionsState.instance.hitbox.visible = true;
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
        // center
        testStrumline.setPosition(FlxG.width / 2, FlxG.height / 2);
        testStrumline.x -= testStrumline.width / 2;
        testStrumline.scrollFactor.set(0, 0);
        add(testStrumline);
      }
      #end
      MenuTypedList.pauseInput = true;
      OptionsState.instance.drumsBG.fadeIn(1, 0, 1);
      canExit = false;
      differences = [];

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
    PreciseInputManager.instance.onInputPressed.add(onKeyPress);
    PreciseInputManager.instance.onInputReleased.add(onKeyRelease);

    backButton = new FunkinBackButton(FlxG.width - 230, FlxG.height - 200, FlxColor.WHITE, handleMobileExit);
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
    #if mobile
    if (OptionsState.instance.hitbox != null) OptionsState.instance.hitbox.visible = false;
    #end
    tempOffset = 0;
    if (cancel)
    {
      if (calibrating) Preferences.globalOffset = savedOffset;
      #if !mobile
      // mobile would play this twice
      FunkinSound.playOnce(Paths.sound('cancelMenu'));
      #end
    }
    else
      FunkinSound.playOnce(Paths.sound('confirmMenu'));
    offsetItem.currentValue = Preferences.globalOffset;
    OptionsState.instance.drumsBG.fadeOut(1, 0);
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

  // Returns the consistency of the differences.
  // Consistency is the average of the squared differences from the mean. (Standard deviation)
  public function getConsistency():Float
  {
    if (differences.length == 0) return 0;

    var avg:Float = getAverage();

    var variance:Float = 0;
    for (i in 0...differences.length)
    {
      variance += Math.pow(differences[i] - avg, 2);
    }

    return Math.sqrt(variance / differences.length);
  }

  var _offsetLerpTime:Float = 0;
  var _lastOffset:Float = 0;
  var _lastDirection:Int = 0;

  /**
     * Adds a difference in milliseconds to the list of differences.
     * Calculates a new temporary offset every 4 differences.
     * @param ms The difference in milliseconds.
     * @see Preferences.globalOffset
     */
  public function addDifference(ms:Float):Void
  {
    differences.push(ms);

    if (differences.length % 4 == 0 && calibrating)
    {
      var avg:Float = getAverage();
      tempOffset = Std.int(avg);
      _lastOffset = appliedOffsetLerp;
      _offsetLerpTime = 0;
      trace('New offset calculated: ' + tempOffset + 'ms');
    }
  }

  var _lastBeat:Float = 0;
  var _lastTime:Float = 0;

  override function update(elapsed:Float):Void
  {
    super.update(elapsed);
    localConductor.update(localConductor.songPosition + elapsed * 1000, false);

    var b:Float = localConductor.currentBeatTime;

    // Restart logic
    if (FlxG.sound.music.time < _lastTime)
    {
      localConductor.update(FlxG.sound.music.time, !calibrating);
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
        arrowBeat = lastArrowBeat;
      }
      else
        arrowBeat = 4;

      testStrumline.clean();
      testStrumline.noteData = [];
      testStrumline.nextNoteIndex = 0;
      trace('Restarting conductor');

      _lastTime = FlxG.sound.music.time;
      return;
    }

    _lastBeat = b;

    // Resync logic
    var diff:Float = Math.abs((FlxG.sound.music.time + localConductor.combinedOffset) - localConductor.songPosition);
    var diffBg:Float = Math.abs(FlxG.sound.music.time - OptionsState.instance.drumsBG.time);
    if (diff > 50 || diffBg > 50)
    {
      trace('Resyncing conductor: ' + (diff > diffBg ? diff : diffBg) + 'ms difference');

      // If the difference is greater than 50ms, we resync the conductor.
      localConductor.update(FlxG.sound.music.time, true);
      OptionsState.instance.drumsBG.pause();
      OptionsState.instance.drumsBG.time = FlxG.sound.music.time;
      OptionsState.instance.drumsBG.resume();
      b = localConductor.currentBeatTime;
      _lastBeat = b;
    }

    _lastTime = FlxG.sound.music.time;

    // Back logic
    if (controls.BACK_P && shouldOffset == 1)
    {
      exitCalibration(true);
      return;
    }

    // Calibration logic
    if (shouldOffset == 1 && calibrating)
    {
      // Lerp our offset
      if (_offsetLerpTime < 1) _offsetLerpTime += elapsed * 2;
      else
        _offsetLerpTime = 1;

      appliedOffsetLerp = FlxMath.lerp(_lastOffset, tempOffset, _offsetLerpTime);

      countText.text = 'Current Offset: ' + Std.int(appliedOffsetLerp) + 'ms';

      var toRemove:Array<ArrowData> = [];
      var _lastArrowBeat:Float = 0;
      // Update arrows
      for (i in 0...arrows.length)
      {
        var arrow:ArrowData = arrows[i];

        var ms:Float = arrow.beat * msPerBeat;
        var offset:Float = GRhythmUtil.getNoteY(ms - appliedOffsetLerp, 2, false, localConductor);
        arrow.sprite.y = receptor.y + offset - (arrow.sprite.height / 2);
        arrow.sprite.x = receptor.x - (arrow.sprite.width / 2);

        if ((ms - appliedOffsetLerp) - localConductor.songPosition < -180)
        {
          arrow.sprite.alpha -= elapsed * 5;
        }

        if (arrow.beat == _lastArrowBeat || arrow.sprite.alpha <= 0 || differences.length < 8)
        {
          toRemove.push(arrow);
          arrow.sprite.kill();
          continue;
        }
        _lastArrowBeat = arrow.beat;
      }

      // Remove arrows that are marked for removal.
      for (arrow in toRemove)
      {
        arrows.remove(arrow);
      }

      while (b >= arrowBeat - 1)
      {
        // Create a new arrow at the next beat division.
        arrowBeat = (arrowBeat - (arrowBeat % 2)) + 2;
        var nextBeat:Float = arrowBeat;
        if (differences.length >= 8) createArrow(nextBeat);
      }

      // Hit a note (calibration)
      if (FlxG.keys.justPressed.ANY #if FEATURE_TOUCH_CONTROLS || TouchUtil.justPressed #end)
      {
        var arrow:ArrowData = getClosestArrowAtBeat(b);

        var closestBeat:Float = Math.round(b);
        var diff:Float = closestBeat - b;
        var ms:Float = (diff * msPerBeat);

        if (arrow != null) // eric sees this and goes "OMG NULL REF!!!!"
        {
          var timeDiff = (arrow.beat - b) * msPerBeat;

          if (Math.abs(timeDiff - tempOffset) <= 80)
          {
            arrow.sprite.alpha = 0;
            arrow.sprite.kill();
            arrows.remove(arrow);
          }
        }

        var consistency:Float = getConsistency();

        if (consistency > 40 && differences.length > 8)
        {
          jumpInText.text = 'Try to be a little more consistent with your timing!';
          differences = [];
          tempOffset = 0;
          appliedOffsetLerp = 0;
          _gotMad = true;
          return;
        }

        addDifference(ms);

        var actualMs = ms - tempOffset;

        if (differences.length >= 30)
        {
          jumpInText.text = 'Calibration complete!';
          Preferences.globalOffset = tempOffset;
          exitCalibration(false);
          return;
        }

        if (!_gotMad)
        {
          if (Math.abs(actualMs) < 45) jumpInText.text = 'Great job';
          else
            jumpInText.text = 'Nice job';
          if (differences.length < 8)
            jumpInText.text += ", keep going!";
          else
            jumpInText.text += "!";
        }

        jumpInText.text += '\n' + differences.length + '/30';

        _gotMad = false;

        scaleModifier = 0.75;
      }
    }
    // Testing logic
    else if (shouldOffset == 1)
    {
      // If we are not calibrating, we are just testing the strumline.

      processInputQueue();
      while (b >= arrowBeat - 2 && b < 124)
      {
        // Create a new arrow at the next beat division.
        arrowBeat = arrowBeat + 1;
        var data:SongNoteData = new SongNoteData(arrowBeat * msPerBeat, _lastDirection, 0, null, null);
        testStrumline.addNoteData(data, false);

        // Create a jump (double note) every 8 beats to visually indicate first beat - requested by Hundrec
        if (Math.floor(arrowBeat % 8) == 0)
        {
          var data:SongNoteData = new SongNoteData(arrowBeat * msPerBeat, 2, 0, null, null);
          testStrumline.addNoteData(data, false);
        }

        _lastDirection = (_lastDirection + 1) % 4; // Cycle through directions 0-3
      }
      if (b >= 124 && _lastDirection != 0) _lastDirection = 0; // reset direction on loop
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
          arrow.sprite.kill();
          toRemove.push(arrow);
        }
      }

      // Remove arrows that are marked for removal.
      for (arrow in toRemove)
      {
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
        MenuTypedList.pauseInput = false;
        offsetLerp = 0;
        shouldOffset = 0;
      }
    }

    blackRect.alpha = FlxMath.lerp(0, 0.5, FlxEase.cubeInOut(lerped));

    var yLerp = FlxMath.lerp(-480, 100, FlxEase.cubeInOut(lerped));
    var xLerp = FlxMath.lerp(0, FlxG.width, FlxEase.cubeInOut(offsetLerp));

    // center
    var recW = receptor.width;
    var recH = receptor.height;
    jumpInText.x = FlxG.width / 2 - (jumpInText.width / 2);
    countText.x = FlxG.width / 2 - (countText.width / 2);

    receptor.x = FlxG.width / 2 - (recW / 2);
    receptor.y = FlxG.height / 2 - (recH / 2);

    jumpInText.alpha = FlxMath.lerp(0, 1, FlxEase.cubeInOut(offsetLerp));

    if (calibrating)
    {
      receptor.alpha = FlxMath.lerp(0, 1, FlxEase.cubeInOut(offsetLerp));
      countText.alpha = FlxMath.lerp(0, 1, FlxEase.cubeInOut(offsetLerp));
    }
    else
    {
      testStrumline.alpha = FlxMath.lerp(0, 1, FlxEase.cubeInOut(offsetLerp));
      backButton.y = FlxMath.lerp(FlxG.height - 200, 50, FlxEase.cubeInOut(offsetLerp));
    }

    if (scaleModifier < 1)
    {
      scaleModifier += elapsed / 2;
      if (scaleModifier >= 1) scaleModifier = 1;
    }

    receptor.scale.x = FlxMath.lerp(0, 1, FlxEase.cubeInOut(offsetLerp)) * scaleModifier;
    receptor.scale.y = FlxMath.lerp(0, 1, FlxEase.cubeInOut(offsetLerp)) * scaleModifier;

    // Update alpha and note window (canHit)
    for (note in testStrumline.notes.members)
    {
      if (note == null) continue;

      GRhythmUtil.processWindow(note, true, localConductor);
      note.alpha = FlxMath.lerp(0, 1, FlxEase.cubeInOut(offsetLerp));
    }

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
  }

  function hitNote(note:NoteSprite, input:PreciseInputEvent):Void
  {
    var inputLatencyNs:Int64 = PreciseInputManager.getCurrentTimestamp() - input.timestamp;
    var inputLatencyMs:Float = inputLatencyNs.toFloat() / Constants.NS_PER_MS;

    var diff:Float = note.noteData.time - localConductor.songPosition;

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
    exitCalibration(true);
    super.destroy();
  }
}
