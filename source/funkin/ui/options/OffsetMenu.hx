package funkin.ui.options;

import funkin.ui.MenuList.MenuTypedList;
import funkin.ui.TextMenuList.TextMenuItem;
import funkin.util.GRhythmUtil;
import funkin.mobile.ui.FunkinBackButton;
#if mobile
import funkin.mobile.ui.FunkinHitbox;
import funkin.mobile.ui.FunkinHitbox.FunkinHitboxControlSchemes;
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

  // var debugBeatText:FlxText;
  var jumpInText:FlxText;
  var countText:FlxText;

  var arrows:Array<ArrowData> = [];
  var receptor:FunkinSprite;
  var offsetItem:NumberPreferenceItem;
  var items:TextMenuList;
  var preferenceItems:FlxTypedSpriteGroup<FlxSprite>;

  var testStrumline:Strumline;

  var menuCamera:FunkinCamera;
  // var camFollow:FlxObject;
  var savedOffset:Int = 0;

  var tempOffset:Int = 0;

  var blackRect:FlxSprite;

  var lerped:Float = 0;

  var calibrating:Bool = false;

  var shouldOffset:Int = 0;
  var offsetLerp:Float = 0;

  var scaleModifier:Float = 1;

  var localConductor:Conductor;

  var arrowBeat:Float = 0;

  var _gotMad:Bool = false;

  var differences:Array<Float> = [];

  var appliedOffsetLerp:Float = 0;

  var backButton:FunkinBackButton;

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
    var arrow = new FunkinSprite(0, 0);
    arrow.loadGraphic(Paths.image('latencyArrow'));
    arrow.origin.set(0.5, 0.5);
    arrow.setPosition(FlxG.width / 2, FlxG.height + arrow.height); // Below the screen
    arrow.updateHitbox();
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
    add(receptor);

    var noteStyle:NoteStyle = NoteStyleRegistry.instance.fetchDefault();

    testStrumline = new Strumline(noteStyle, true);
    // center
    testStrumline.setPosition(FlxG.width / 2, FlxG.height / 2);
    testStrumline.x -= testStrumline.width / 2;
    testStrumline.scrollFactor.set(0, 0);
    add(testStrumline);

    #if mobile
    if (Preferences.controlsScheme == FunkinHitboxControlSchemes.Arrows)
    {
      final amplification:Float = (FlxG.width / FlxG.height) / (FlxG.initialWidth / FlxG.initialHeight);
      final playerStrumlineScale:Float = ((FlxG.height / FlxG.width) * 1.95) * amplification;
      final playerNoteSpacing:Float = ((FlxG.height / FlxG.width) * 2.8) * amplification;

      testStrumline.strumlineScale.set(playerStrumlineScale, playerStrumlineScale);
      testStrumline.setNoteSpacing(playerNoteSpacing);
      testStrumline.width *= 2;

      testStrumline.x = (FlxG.width - testStrumline.width) / 2 + Constants.STRUMLINE_X_OFFSET;
      testStrumline.y = (FlxG.height - testStrumline.height) * 0.95 - Constants.STRUMLINE_Y_OFFSET;
      testStrumline.y -= 10;
    }
    #end

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

    add(items = new TextMenuList());
    add(preferenceItems = new FlxTypedSpriteGroup<FlxSprite>());

    offsetItem = createPrefItemNumber('Offset (Global)', 'Offset (Global)', function(value:Float) {
      Preferences.globalOffset = Std.int(value);
    }, null, Preferences.globalOffset, -1500, 1500, 1.0, 2);
    createButtonItem('Reset Offset', function() {
      Preferences.globalOffset = 0;
      offsetItem.currentValue = Preferences.globalOffset;
    });
    createButtonItem('Offset Calibration', function() {
      jumpInText.text = 'Press any key to the beat!\nThe arrow will start to sync to the receptor.';
      #if mobile
      jumpInText.text = 'Tap to the beat!\nThe arrow will start to sync to the receptor.';
      #end

      jumpInText.y = 100;

      countText.text = 'Current Offset: 0ms';

      calibrating = true;
      MenuTypedList.pauseInput = true;
      OptionsState.instance.drumsBG.fadeIn(1, 0, 1);
      canExit = false;
      differences = [];
      offsetLerp = 0;
      savedOffset = Preferences.globalOffset;
      Preferences.globalOffset = 0;
      shouldOffset = 1;
      tempOffset = 0;
      appliedOffsetLerp = 0;

      arrowBeat = Math.floor(localConductor.currentBeatTime) + 4;
      receptor.angle = 0;

      _gotMad = false;
    });
    createButtonItem('Test', function() {
      shouldOffset = 1;
      testStrumline.clean();
      testStrumline.noteData = [];
      testStrumline.nextNoteIndex = 0;

      localConductor.update(FlxG.sound.music.time, true);
      arrowBeat = Math.floor(localConductor.currentBeatTime) + 4;

      jumpInText.text = 'Hit the notes as they come in!';
      #if mobile
      if (OptionsState.instance.hitbox != null) OptionsState.instance.hitbox.visible = true;
      #end
      MenuTypedList.pauseInput = true;
      OptionsState.instance.drumsBG.fadeIn(1, 0, 1);
      canExit = false;
      differences = [];

      #if !mobile
      testStrumline.y = Preferences.downscroll ? FlxG.height - (testStrumline.height + 45) - Constants.STRUMLINE_Y_OFFSET : (testStrumline.height / 2)
        - Constants.STRUMLINE_Y_OFFSET;
      testStrumline.isDownscroll = Preferences.downscroll;
      #end
      jumpInText.y = testStrumline.y + 175;
      #if !mobile if (Preferences.downscroll) #end jumpInText.y = testStrumline.y - 175;

    });
    PreciseInputManager.instance.onInputPressed.add(onKeyPress);
    PreciseInputManager.instance.onInputReleased.add(onKeyRelease);

    // camFollow = new FlxObject(FlxG.width / 2, 0, 140, 70);
    // if (items != null) camFollow.y = items.selectedItem.y;

    // menuCamera.follow(camFollow, null, 0.085);
    // var margin = 160;
    // menuCamera.deadzone.set(0, margin, menuCamera.width, menuCamera.height - margin * 2);
    // menuCamera.minScrollY = 0;

    // items.onChange.add(function(selected) {
    //  camFollow.y = selected.y;
    // });
    backButton = new FunkinBackButton(FlxG.width - 230, FlxG.height - 200, FlxColor.WHITE, handleMobileExit);
    #if FEATURE_TOUCH_CONTROLS
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

  var _offsetLerpTime:Float = 0;
  var _lastOffset:Float = 0;
  var _lastDirection:Int = 0;

  /* Adds a difference in milliseconds to the list.
    If there are more than 4 differences, it calculates the average and sets the global offset.
    This is used for calibrating the offset based on user input.
    @param ms The difference in milliseconds to add.
    @see Preferences.globalOffset
   */
  public function addDifference(ms:Float):Void
  {
    differences.push(ms);

    if (differences.length > 2 && differences.length % 2 != 0 && calibrating)
    {
      var avg:Float = getAverage();
      tempOffset = -Std.int(avg);
      _lastOffset = appliedOffsetLerp;
      _offsetLerpTime = 0;
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
        arrowBeat = lastArrowBeat + 2;
      }
      else
        arrowBeat = 4;

      testStrumline.clean();
      testStrumline.noteData = [];
      testStrumline.nextNoteIndex = 0;
    }

    _lastBeat = b;

    // Resync logic
    var diff:Float = Math.abs((FlxG.sound.music.time + localConductor.combinedOffset) - localConductor.songPosition);
    if (diff > 50)
    {
      trace('Resyncing conductor: ' + diff + 'ms difference');

      // If the difference is greater than 50ms, we resync the conductor.
      localConductor.update(FlxG.sound.music.time, true);
      b = localConductor.currentBeatTime;
      _lastBeat = b;
    }

    _lastTime = FlxG.sound.music.time;


    if (controls.BACK && shouldOffset == 1)
    {
      exitCalibration(true);
      return;
    }

    if (shouldOffset == 1 && calibrating)
    {
      // Lerp our offset
      if (_offsetLerpTime < 1) _offsetLerpTime += elapsed * 2;
      else
        _offsetLerpTime = 1;

      appliedOffsetLerp = FlxMath.lerp(_lastOffset, tempOffset, _offsetLerpTime);

      countText.text = 'Current Offset: ' + Std.int(appliedOffsetLerp) + 'ms';

      var toRemove:Array<ArrowData> = [];

      // Update arrows
      for (i in 0...arrows.length)
      {
        var arrow:ArrowData = arrows[i];

        var beatOffset:Float = appliedOffsetLerp / msPerBeat;

        var ms:Float = arrow.beat * msPerBeat;
        var offset:Float = GRhythmUtil.getNoteY(ms + appliedOffsetLerp, 2, false, localConductor);
        arrow.sprite.y = receptor.y + offset - (arrow.sprite.height / 2);
        arrow.sprite.x = receptor.x - (arrow.sprite.width / 2);

        // arrow.debugText.text = 'Beat: ' + arrow.beat;
        // arrow.debugText.setPosition(arrow.sprite.x + arrow.sprite.width, arrow.sprite.y - 20);

        if ((arrow.beat + beatOffset) < b - 0.25)
        {
          arrow.sprite.alpha -= elapsed * 5;
        }

        if (arrow.sprite.alpha <= 0)
        {
          toRemove.push(arrow);
          arrow.sprite.kill();
          // arrow.debugText.kill();
        }
      }

      // Remove arrows that are marked for removal.
      for (arrow in toRemove)
      {
        // trace("Removing arrow at beat: " + arrow.beat);
        arrows.remove(arrow);
      }

      while (b >= arrowBeat - 1)
      {
        // trace("Spawning arrow at beat: " + arrowBeat);
        // Create a new arrow at the next beat division.
        arrowBeat = (arrowBeat - (arrowBeat % 2)) + 2;
        var nextBeat:Float = arrowBeat;
        createArrow(nextBeat);
      }

      if (FlxG.keys.justPressed.ANY #if FEATURE_TOUCH_CONTROLS || TouchUtil.justPressed #end)
      {
        var arrow:ArrowData = getClosestArrowAtBeat(b);

        var closestBeat:Float = Math.round(b);
        var diff:Float = closestBeat - b;
        var ms:Float = diff * msPerBeat;

        if (arrow != null) // eric sees this and goes "OMG NULL REF!!!!"
        {
          var beatOffset:Float = appliedOffsetLerp / msPerBeat;

          var arrowDiff:Float = (arrow.beat + beatOffset) - b;

          if (Math.abs(arrowDiff) < 0.25)
          {
            arrow.sprite.alpha = 0;
            arrow.sprite.kill();
            // arrow.debugText.kill();
            arrows.remove(arrow);
          }
        }

        var consistency:Float = getConsistency();

        if (consistency > 80 && differences.length > 4)
        {
          jumpInText.text = 'Try to be a little more consistent with your timing!';
          differences = [];
          tempOffset = 0;
          appliedOffsetLerp = 0;
          _gotMad = true;
          return;
        }

        addDifference(ms);

        if (differences.length >= 16)
        {
          jumpInText.text = 'Calibration complete!';
          Preferences.globalOffset = tempOffset;
          exitCalibration(false);
          return;
        }

        if (!_gotMad)
        {
          if (Math.abs(ms + tempOffset) < 45) jumpInText.text = 'Great job, keep going!';
          else
            jumpInText.text = 'Nice job, keep going!';
        }

        jumpInText.text += '\n' + differences.length + '/16';

        _gotMad = false;

        scaleModifier = 0.75;
      }
    }
    else if (shouldOffset == 1)
    {
      // If we are not calibrating, we are just testing the strumline.

      processInputQueue();

      // trace(b + ' - ' + arrowBeat);

      while (b >= arrowBeat - 2 && b < 188)
      {
        // trace("Spawning arrow at beat: " + arrowBeat);
        // Create a new arrow at the next beat division.
        arrowBeat = arrowBeat + 1;
        var data:SongNoteData = new SongNoteData(arrowBeat * msPerBeat, _lastDirection, 0, null, null);
        testStrumline.addNoteData(data, false);

        _lastDirection = (_lastDirection + 1) % 4; // Cycle through directions 0-3
      }
    }
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
          // arrow.debugText.kill();
          toRemove.push(arrow);
        }
      }

      // Remove arrows that are marked for removal.
      for (arrow in toRemove)
      {
        arrows.remove(arrow);
      }
    }
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
      if (offsetLerp <= 0)
      {
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
      // debugBeatText.alpha = FlxMath.lerp(0, 1, FlxEase.cubeInOut(offsetLerp));
      countText.alpha = FlxMath.lerp(0, 1, FlxEase.cubeInOut(offsetLerp));
    }
    else
    {
      testStrumline.alpha = FlxMath.lerp(0, 1, FlxEase.cubeInOut(offsetLerp));
      backButton.y = FlxMath.lerp(FlxG.height - 200, 50, FlxEase.cubeInOut(offsetLerp));
    }

    if (scaleModifier < 1)
    {
      // trace("scaleModifier: " + scaleModifier);
      scaleModifier += elapsed / 2;
      if (scaleModifier >= 1) scaleModifier = 1;
    }

    receptor.scale.x = FlxMath.lerp(0, 1, FlxEase.cubeInOut(offsetLerp)) * scaleModifier;
    receptor.scale.y = FlxMath.lerp(0, 1, FlxEase.cubeInOut(offsetLerp)) * scaleModifier;

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

          numPref.lefthandText.x = xLerp
          + (FlxG.width / 2)
          - ((thyTextWidth / 2) + daItem.atlasText.getWidth() / 2);
          numPref.lefthandText.y = yLerp + ((120 * ind) + 30);
        default:
          // Huh? x2
      }

      daItem.y = yLerp + ((120 * ind) + 30);
      daItem.x = xLerp
        + (FlxG.width / 2)
      + thyTextWidth
        - daItem.atlasText.getWidth() / 2;
      ind++;
    });
  }

  function hitNote(note:NoteSprite, input:PreciseInputEvent):Void
  {
    var inputLatencyNs:Int64 = PreciseInputManager.getCurrentTimestamp() - input.timestamp;
    var inputLatencyMs:Float = inputLatencyNs.toFloat() / Constants.NS_PER_MS;

    var diff:Float = note.noteData.time - localConductor.songPosition;

    trace('Input latency: ' + inputLatencyMs + 'ms (diff: ' + diff + 'ms)');

    var totalDiff:Float = diff;
    if (totalDiff < 0) totalDiff = diff + inputLatencyMs;
    else
      totalDiff = diff - inputLatencyMs;

    var noteDiff:Int = Std.int(totalDiff);

    addDifference(noteDiff);

    if (noteDiff == 0)
    {
      jumpInText.text = 'Perfect!';
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

      testStrumline.pressKey(input.noteDirection);

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

      testStrumline.releaseKey(input.noteDirection);
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
      step:Float = 0.1, precision:Int):NumberPreferenceItem
  {
    var item = new NumberPreferenceItem(funkin.ui.FullScreenScaleMode.gameNotchSize.x, (120 * items.length) + 30, prefName, defaultValue, min, max, step,
      precision, onChange, valueFormatter);
    items.addItem(prefName, item);
    preferenceItems.add(item.lefthandText);
    return item;
  }

}
