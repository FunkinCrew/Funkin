package funkin.play.notes;

import flixel.util.FlxSignal.FlxTypedSignal;
import flixel.FlxG;
import funkin.play.notes.notestyle.NoteStyle;
import flixel.group.FlxSpriteGroup;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxSort;
import funkin.graphics.FunkinSprite;
import funkin.play.notes.NoteHoldCover;
import funkin.play.notes.NoteSplash;
import funkin.play.notes.NoteSprite;
import funkin.play.notes.SustainTrail;
import funkin.play.notes.NoteVibrationsHandler;
import funkin.data.song.SongData.SongNoteData;
import funkin.util.SortUtil;
import funkin.util.GRhythmUtil;
import funkin.play.notes.notekind.NoteKindManager;
import flixel.math.FlxPoint;
#if mobile
import funkin.mobile.input.ControlsHandler;
import funkin.mobile.ui.FunkinHitbox.FunkinHitboxControlSchemes;
#end

/**
 * A group of sprites which handles the receptor, the note splashes, and the notes (with sustains) for a given player.
 */
class Strumline extends FlxSpriteGroup
{
  /**
   * The directions of the notes on the strumline, in order.
   */
  public static final DIRECTIONS:Array<NoteDirection> = [NoteDirection.LEFT, NoteDirection.DOWN, NoteDirection.UP, NoteDirection.RIGHT];

  /**
   * A magic number for the size of the strumline, in pixels.
   */
  public static final STRUMLINE_SIZE:Int = 104;

  /**
   * The spacing between notes on the strumline, in pixels.
   */
  public static final NOTE_SPACING:Int = STRUMLINE_SIZE + 8;

  // Positional fixes for new strumline graphics.
  static final INITIAL_OFFSET:Float = -0.275 * STRUMLINE_SIZE;
  static final NUDGE:Float = 2.0;

  static final KEY_COUNT:Int = 4;
  static final NOTE_SPLASH_CAP:Int = 6;

  var renderDistanceMs(get, never):Float;

  /**
   * The custom render distance for the strumline.
   * This should be in miliseconds only! Not pixels.
   */
  public var customRenderDistanceMs:Float = 0.0;

  /**
   * Whether to use the custom render distance.
   * If false, the render distance will be calculated based on the screen height.
   */
  public var useCustomRenderDistance:Bool = false;

  function get_renderDistanceMs():Float
  {
    if (useCustomRenderDistance) return customRenderDistanceMs;
    return FlxG.height / Constants.PIXELS_PER_MS / scrollSpeed;
  }

  /**
   * Whether to play note splashes or not
   * TODO: Make this a setting!
   * IE: Settings.noSplash
   */
  public var showNotesplash:Bool = true;

  /**
   * Whether this strumline is controlled by the player's inputs.
   * False means it's controlled by the opponent or Bot Play.
   */
  public var isPlayer:Bool;

  /**
   * Usually you want to keep this as is, but if you are using a Strumline and
   * playing a sound that has it's own conductor, set this (LatencyState for example)
   */
  public var conductorInUse(get, set):Conductor;

  // Used in-game to control the scroll speed within a song
  public var scrollSpeed:Float = 1.0;

  /**
   * Reset the scroll speed to the current chart's scroll speed.
   */
  public function resetScrollSpeed():Void
  {
    scrollSpeed = PlayState.instance?.currentChart?.scrollSpeed ?? 1.0;
  }

  var _conductorInUse:Null<Conductor>;

  function get_conductorInUse():Conductor
  {
    if (_conductorInUse == null) return Conductor.instance;
    return _conductorInUse;
  }

  function set_conductorInUse(value:Conductor):Conductor
  {
    return _conductorInUse = value;
  }

  /**
   * Whether the game should auto position notes.
   */
  public var customPositionData:Bool = false;

  /**
   * The notes currently being rendered on the strumline.
   * This group iterates over this every frame to update note positions.
   * The PlayState also iterates over this to calculate user inputs.
   */
  public var notes:FlxTypedSpriteGroup<NoteSprite>;

  /**
   * The hold notes currently being rendered on the strumline.
   * This group iterates over this every frame to update hold note positions.
   * The PlayState also iterates over this to calculate user inputs.
   */
  public var holdNotes:FlxTypedSpriteGroup<SustainTrail>;

  /**
   * A signal that is dispatched when a note is spawned and heading towards the strumline.
   */
  public var onNoteIncoming:FlxTypedSignal<NoteSprite->Void>;

  var background:FunkinSprite;

  var strumlineNotes:FlxTypedSpriteGroup<StrumlineNote>;
  var noteSplashes:FlxTypedSpriteGroup<NoteSplash>;
  var noteHoldCovers:FlxTypedSpriteGroup<NoteHoldCover>;

  var notesVwoosh:FlxTypedSpriteGroup<NoteSprite>;
  var holdNotesVwoosh:FlxTypedSpriteGroup<SustainTrail>;

  final noteStyle:NoteStyle;

  var noteSpacingScale:Float = 1;

  public var strumlineScale(default, null):FlxPoint;

  #if FEATURE_GHOST_TAPPING
  var ghostTapTimer:Float = 0.0;
  #end

  public var noteVibrations:NoteVibrationsHandler = new NoteVibrationsHandler();

  final inArrowContorlSchemeMode:Bool = #if mobile (Preferences.controlsScheme == FunkinHitboxControlSchemes.Arrows
    && !ControlsHandler.usingExternalInputDevice) #else false #end;

  public var isDownscroll:Bool = #if mobile (Preferences.controlsScheme == FunkinHitboxControlSchemes.Arrows
    && !ControlsHandler.usingExternalInputDevice)
    || #end Preferences.downscroll;

  /**
   * The note data for the song. Should NOT be altered after the song starts (but we alter it in OffsetState :DDD),
   * so we can easily rewind.
   */
  public var noteData:Array<SongNoteData> = [];

  /**
   * The index of the next note to be rendered.
   * This is used to avoid splicing the noteData array, which is slow.
   * It is incremented every time a note is rendered.
   */
  public var nextNoteIndex:Int = -1;

  var heldKeys:Array<Bool> = [];

  static final BACKGROUND_PAD:Int = 16;

  public function new(noteStyle:NoteStyle, isPlayer:Bool)
  {
    super();

    this.isPlayer = isPlayer;
    this.noteStyle = noteStyle;

    this.strumlineNotes = new FlxTypedSpriteGroup<StrumlineNote>();
    this.strumlineNotes.zIndex = 10;
    this.add(this.strumlineNotes);

    // Hold notes are added first so they render behind regular notes.
    this.holdNotes = new FlxTypedSpriteGroup<SustainTrail>();
    this.holdNotes.zIndex = 20;
    this.add(this.holdNotes);

    this.holdNotesVwoosh = new FlxTypedSpriteGroup<SustainTrail>();
    this.holdNotesVwoosh.zIndex = 21;
    this.add(this.holdNotesVwoosh);

    this.notes = new FlxTypedSpriteGroup<NoteSprite>();
    this.notes.zIndex = 30;
    this.add(this.notes);

    this.notesVwoosh = new FlxTypedSpriteGroup<NoteSprite>();
    this.notesVwoosh.zIndex = 31;
    this.add(this.notesVwoosh);

    this.noteHoldCovers = new FlxTypedSpriteGroup<NoteHoldCover>(0, 0, 4);
    this.noteHoldCovers.zIndex = 40;
    this.add(this.noteHoldCovers);

    this.noteSplashes = new FlxTypedSpriteGroup<NoteSplash>(0, 0, NOTE_SPLASH_CAP);
    this.noteSplashes.zIndex = 50;
    this.add(this.noteSplashes);

    var backgroundWidth:Float = KEY_COUNT * Strumline.NOTE_SPACING + BACKGROUND_PAD * 2;
    #if mobile
    if (inArrowContorlSchemeMode && isPlayer)
    {
      backgroundWidth = backgroundWidth * 1.84;
    }
    #end
    this.background = new FunkinSprite(0, 0).makeSolidColor(Std.int(backgroundWidth), FlxG.height, 0xFF000000);
    // Convert the percent to a number between 0 and 1.
    this.background.alpha = Preferences.strumlineBackgroundOpacity / 100.0;
    this.background.scrollFactor.set(0, 0);
    this.background.x = -BACKGROUND_PAD;
    #if mobile
    if (inArrowContorlSchemeMode && isPlayer) this.background.x -= 100;
    #end
    this.add(this.background);
    strumlineScale = new FlxCallbackPoint(strumlineScaleCallback);

    strumlineScale = new FlxCallbackPoint(strumlineScaleCallback);

    this.refresh();

    this.onNoteIncoming = new FlxTypedSignal<NoteSprite->Void>();
    resetScrollSpeed();

    for (i in 0...KEY_COUNT)
    {
      var child:StrumlineNote = new StrumlineNote(noteStyle, isPlayer, DIRECTIONS[i]);
      child.x = getXPos(DIRECTIONS[i]);
      child.x += INITIAL_OFFSET;
      child.y = 0;
      noteStyle.applyStrumlineOffsets(child);
      this.strumlineNotes.add(child);
    }

    for (i in 0...KEY_COUNT)
    {
      heldKeys.push(false);
    }

    strumlineScale.set(1, 1);

    // This MUST be true for children to update!
    this.active = true;
  }

  override function set_y(value:Float):Float
  {
    super.set_y(value);

    // Keep the background on the screen.
    if (this.background != null) this.background.y = 0;

    return value;
  }

  override function set_alpha(value:Float):Float
  {
    super.set_alpha(value);

    this.background.alpha = Preferences.strumlineBackgroundOpacity / 100.0 * alpha;

    return value;
  }

  /**
   * Refresh the strumline, sorting its children by z-index.
   */
  public function refresh():Void
  {
    sort(SortUtil.byZIndex, FlxSort.ASCENDING);
  }

  override function get_width():Float
  {
    if (strumlineScale == null) strumlineScale = new FlxCallbackPoint(strumlineScaleCallback);

    return KEY_COUNT * Strumline.NOTE_SPACING * noteSpacingScale * strumlineScale.x;
  }

  public override function update(elapsed:Float):Void
  {
    super.update(elapsed);

    updateNotes();

    #if FEATURE_GHOST_TAPPING
    updateGhostTapTimer(elapsed);
    #end
  }

  #if FEATURE_GHOST_TAPPING
  /**
   * @return `true` if no notes are in range of the strumline and the player can spam without penalty.
   */
  public function mayGhostTap():Bool
  {
    // Any notes in range of the strumline.
    if (getNotesMayHit().length > 0)
    {
      return false;
    }
    // Any hold notes in range of the strumline.
    if (getHoldNotesHitOrMissed().length > 0)
    {
      return false;
    }

    // Note has been hit recently.
    if (ghostTapTimer > 0.0) return false;

    // **yippee**
    return true;
  }
  #end

  /**
   * Return notes that are within `Constants.HIT_WINDOW` ms of the strumline.
   * @return An array of `NoteSprite` objects.
   */
  public function getNotesMayHit():Array<NoteSprite>
  {
    return notes.members.filter(function(note:NoteSprite) {
      return note != null && note.alive && !note.hasBeenHit && note.mayHit;
    });
  }

  /**
   * Return hold notes that are within `Constants.HIT_WINDOW` ms of the strumline.
   * @return An array of `SustainTrail` objects.
   */
  public function getHoldNotesHitOrMissed():Array<SustainTrail>
  {
    return holdNotes.members.filter(function(holdNote:SustainTrail) {
      return holdNote != null && holdNote.alive && (holdNote.hitNote || holdNote.missedNote);
    });
  }

  /**
   * Get a note sprite corresponding to the given note data.
   * @param target The note data for the note sprite.
   * @return The note sprite.
   */
  public function getNoteSprite(target:SongNoteData):NoteSprite
  {
    if (target == null) return null;

    for (note in notes.members)
    {
      if (note == null) continue;
      if (note.alive) continue;

      if (note.noteData == target) return note;
    }

    return null;
  }

  /**
   * Get a hold note sprite corresponding to the given note data.
   * @param target The note data for the hold note.
   * @return The hold note sprite.
   */
  public function getHoldNoteSprite(target:SongNoteData):SustainTrail
  {
    if (target == null || ((target.length ?? 0.0) <= 0.0)) return null;

    for (holdNote in holdNotes.members)
    {
      if (holdNote == null) continue;
      if (holdNote.alive) continue;

      if (holdNote.noteData == target) return holdNote;
    }

    return null;
  }

  /**
   * Call this when resetting the playstate.
   */
  public function vwooshNotes():Void
  {
    var vwooshTime:Float = 0.5;

    for (note in notes.members)
    {
      if (note == null) continue;
      if (!note.alive) continue;

      notes.remove(note);
      notesVwoosh.add(note);

      var targetY:Float = FlxG.height + note.y;
      if (isDownscroll) targetY = 0 - note.height;
      FlxTween.tween(note, {y: targetY}, vwooshTime,
        {
          ease: FlxEase.expoIn,
          onComplete: function(twn) {
            note.kill();
            notesVwoosh.remove(note, true);
            note.destroy();
          }
        });
    }

    for (holdNote in holdNotes.members)
    {
      if (holdNote == null) continue;
      if (!holdNote.alive) continue;

      holdNotes.remove(holdNote);
      holdNotesVwoosh.add(holdNote);

      var targetY:Float = FlxG.height + holdNote.y;
      if (isDownscroll) targetY = 0 - holdNote.height;
      FlxTween.tween(holdNote, {y: targetY}, vwooshTime,
        {
          ease: FlxEase.expoIn,
          onComplete: function(twn) {
            holdNote.kill();
            holdNotesVwoosh.remove(holdNote, true);
            holdNote.destroy();
          }
        });
    }
  }

  /**
   * Enter mini mode, which displays only small strumline notes
   * @param scale scale of strumline
   */
  public function enterMiniMode(scale:Float = 1)
  {
    forEach(function(obj:flixel.FlxObject):Void {
      if (obj != strumlineNotes) obj.visible = false;
    });

    this.strumlineScale.set(scale, scale);
  }

  public function strumlineScaleCallback(Scale:FlxPoint)
  {
    strumlineNotes.forEach(function(note:StrumlineNote):Void {
      var styleScale = noteStyle.getStrumlineScale();
      note.scale.set(styleScale * Scale.x, styleScale * Scale.y);
    });
    setNoteSpacing(noteSpacingScale);
  }

  /**
   * Set note spacing scale
   * @param multiplier multiply x position
   */
  public function setNoteSpacing(multiplier:Float = 1):Void
  {
    noteSpacingScale = multiplier;

    for (i in 0...KEY_COUNT)
    {
      var direction = Strumline.DIRECTIONS[i];
      var note = getByDirection(direction);
      note.x = getXPos(DIRECTIONS[i]) + this.strumlineNotes.x;
      note.x += INITIAL_OFFSET;
      note.y = this.strumlineNotes.y;
      noteStyle.applyStrumlineOffsets(note);
    }
  }

  /**
   * For a note's strumTime, calculate its Y position relative to the strumline.
   * NOTE: Assumes Conductor and PlayState are both initialized.
   * @param strumTime
   * @return Float
   * Reverse of vwooshNotes, we bring the notes IN (by their offsets)
   */
  public function vwooshInNotes():Void
  {
    var vwooshTime:Float = 0.5;

    for (note in notes.members)
    {
      if (note == null) continue;
      if (!note.alive) continue;

      note.yOffset = 200;
      if (isDownscroll)
      {
        note.yOffset = -200;
      }
      FlxTween.tween(note, {yOffset: 0}, vwooshTime,
        {
          ease: FlxEase.expoOut,
          onComplete: function(twn) {
            note.yOffset = 0;
          }
        });
    }

    for (holdNote in holdNotes.members)
    {
      if (holdNote == null) continue;
      if (!holdNote.alive) continue;

      holdNote.yOffset = 200;
      if (isDownscroll)
      {
        holdNote.yOffset = -200;
      }
      FlxTween.tween(holdNote, {yOffset: 0}, vwooshTime,
        {
          ease: FlxEase.expoOut,
          onComplete: function(twn) {
            holdNote.yOffset = 0;
          }
        });
    }
  }

  public function updateNotes():Void
  {
    if (noteData.length == 0) return;

    // Ensure note data gets reset if the song happens to loop.
    // NOTE: I had to remove this line because it was causing notes visible during the countdown to be placed multiple times.
    // I don't remember what bug I was trying to fix by adding this.
    // if (conductorInUse.currentStep == 0) nextNoteIndex = 0;

    var songStart:Float = PlayState.instance?.startTimestamp ?? 0.0;
    var hitWindowStart:Float = conductorInUse.songPosition - Constants.HIT_WINDOW_MS;
    var renderWindowStart:Float = conductorInUse.songPosition + renderDistanceMs;

    for (noteIndex in nextNoteIndex...noteData.length)
    {
      var note:Null<SongNoteData> = noteData[noteIndex];
      if (note == null) continue; // Note is blank
      if (note.time < songStart || note.time < hitWindowStart)
      {
        // Note is in the past, skip it.
        nextNoteIndex = noteIndex + 1;
        // trace("Strumline: Skipping note at index " + noteIndex + " with strum time " + note.time);
        continue;
      }
      if (note.time > renderWindowStart) break; // Note is too far ahead to render

      // trace("Strumline: Rendering note at index " + noteIndex + " with strum time " + note.time);

      var noteSprite:NoteSprite = buildNoteSprite(note);

      if (note.length > 0)
      {
        noteSprite.holdNoteSprite = buildHoldNoteSprite(note);
      }

      nextNoteIndex = noteIndex + 1; // Increment the nextNoteIndex rather than splicing the array, because splicing is slow.

      onNoteIncoming.dispatch(noteSprite);
    }

    // Update rendering of notes.
    for (note in notes.members)
    {
      if (note == null || !note.alive) continue;
      // Set the note's position.
      if (!customPositionData) note.y = this.y
        - INITIAL_OFFSET
        + GRhythmUtil.getNoteY(note.strumTime, scrollSpeed, isDownscroll, conductorInUse)
        + note.yOffset;

      // If the note is miss
      var isOffscreen:Bool = isDownscroll ? note.y > FlxG.height : note.y < -note.height;
      if (note.handledMiss && isOffscreen)
      {
        killNote(note);
      }
    }

    // Update rendering of hold notes.
    for (holdNote in holdNotes.members)
    {
      if (holdNote == null || !holdNote.alive) continue;

      if (conductorInUse.songPosition > holdNote.strumTime && holdNote.hitNote && !holdNote.missedNote)
      {
        if (isPlayer && !isKeyHeld(holdNote.noteDirection))
        {
          // Stopped pressing the hold note.
          playStatic(holdNote.noteDirection);
          holdNote.missedNote = true;
          holdNote.visible = true;
          holdNote.alpha = 0.0; // Completely hide the dropped hold note.
        }
      }

      final magicNumberIGuess:Float = 8;
      var renderWindowEnd:Float = holdNote.strumTime + holdNote.fullSustainLength + Constants.HIT_WINDOW_MS + (renderDistanceMs / magicNumberIGuess);

      if (holdNote.missedNote && conductorInUse.songPosition >= renderWindowEnd)
      {
        // Hold note is offscreen, kill it.
        holdNote.visible = false;
        holdNote.kill(); // Do not destroy! Recycling is faster.
      }
      else if (holdNote.hitNote && holdNote.sustainLength <= 0)
      {
        if (isPlayer)
        {
          // Hold note's final vibration.
          noteVibrations.tryHoldNoteVibration(true);
        }

        // Hold note is completed, kill it.
        if (isKeyHeld(holdNote.noteDirection))
        {
          playPress(holdNote.noteDirection);
        }
        else
        {
          playStatic(holdNote.noteDirection);
        }

        if (holdNote.cover != null && isPlayer)
        {
          holdNote.cover.playEnd();

          trace("Sustain Note Splash Vibration");
        }
        else if (holdNote.cover != null)
        {
          // *lightning* *zap* *crackle*
          holdNote.cover.visible = false;
          holdNote.cover.kill();
        }

        holdNote.visible = false;
        holdNote.kill();
      }
      else if (holdNote.missedNote && (holdNote.fullSustainLength > holdNote.sustainLength))
      {
        // Hold note was dropped before completing, keep it in its clipped state.
        holdNote.visible = true;

        var yOffset:Float = (holdNote.fullSustainLength - holdNote.sustainLength) * Constants.PIXELS_PER_MS;

        if (!customPositionData)
        {
          if (isDownscroll)
          {
            holdNote.y = this.y
              - INITIAL_OFFSET
              + GRhythmUtil.getNoteY(holdNote.strumTime, scrollSpeed, isDownscroll, conductorInUse)
              - holdNote.height
              + STRUMLINE_SIZE / 2
              + holdNote.yOffset;
          }
          else
          {
            holdNote.y = this.y
              - INITIAL_OFFSET
              + GRhythmUtil.getNoteY(holdNote.strumTime, scrollSpeed, isDownscroll, conductorInUse)
              + yOffset
              + STRUMLINE_SIZE / 2
              + holdNote.yOffset;
          }
        }

        // Clean up the cover.
        if (holdNote.cover != null)
        {
          holdNote.cover.visible = false;
          holdNote.cover.kill();
        }
      }
      else if (conductorInUse.songPosition > holdNote.strumTime && holdNote.hitNote)
      {
        // Hold note is currently being hit, clip it off.
        holdConfirm(holdNote.noteDirection);
        holdNote.visible = true;

        holdNote.sustainLength = (holdNote.strumTime + holdNote.fullSustainLength) - conductorInUse.songPosition;

        if (holdNote.sustainLength <= 10)
        {
          holdNote.visible = false;
        }

        if (!customPositionData)
        {
          if (isDownscroll)
          {
            holdNote.y = this.y - INITIAL_OFFSET - holdNote.height + STRUMLINE_SIZE / 2;
          }
          else
          {
            holdNote.y = this.y - INITIAL_OFFSET + STRUMLINE_SIZE / 2;
          }
        }
      }
      else
      {
        // Hold note is new, render it normally.
        holdNote.visible = true;

        if (!customPositionData)
        {
          if (isDownscroll)
          {
            holdNote.y = this.y
              - INITIAL_OFFSET
              + GRhythmUtil.getNoteY(holdNote.strumTime, scrollSpeed, isDownscroll, conductorInUse)
              - holdNote.height
              + STRUMLINE_SIZE / 2
              + holdNote.yOffset;
          }
          else
          {
            holdNote.y = this.y
              - INITIAL_OFFSET
              + GRhythmUtil.getNoteY(holdNote.strumTime, scrollSpeed, isDownscroll, conductorInUse)
              + STRUMLINE_SIZE / 2
              + holdNote.yOffset;
          }
        }
      }
    } // Update rendering of pressed keys.

    for (dir in DIRECTIONS)
    {
      if (isKeyHeld(dir) && getByDirection(dir).getCurrentAnimation() == "static")
      {
        playPress(dir);
      }

      // Added this to prevent sustained vibrations not ending issue.
      if (!isKeyHeld(dir) && isPlayer) noteVibrations.noteStatuses[dir] = NoteStatus.idle;
    }
  }

  /**
   * Return notes that are within, or way after, `Constants.HIT_WINDOW` ms of the strumline.
   * @return An array of `NoteSprite` objects.
   */
  public function getNotesOnScreen():Array<NoteSprite>
  {
    return notes.members.filter(function(note:NoteSprite) {
      return note != null && note.alive && !note.hasBeenHit;
    });
  }

  #if FEATURE_GHOST_TAPPING
  function updateGhostTapTimer(elapsed:Float):Void
  {
    // If it's still our turn, don't update the ghost tap timer.
    if (getNotesOnScreen().length > 0) return;

    ghostTapTimer -= elapsed;

    if (ghostTapTimer <= 0)
    {
      ghostTapTimer = 0;
    }
  }
  #end

  /**
   * Called when the PlayState skips a large amount of time forward or backward.
   */
  public function handleSkippedNotes():Void
  {
    // By calling clean(), we remove all existing notes so they can be re-added.
    clean();
    // By setting noteIndex to 0, the next update will skip past all the notes that are in the past.
    nextNoteIndex = 0;
  }

  /**
   * Called on each beat of the song.
   */
  public function onBeatHit():Void
  {
    // why are we doing this every beat? >:(
    if (notes.members.length > 1) notes.members.insertionSort(compareNoteSprites.bind(FlxSort.ASCENDING));

    if (holdNotes.members.length > 1) holdNotes.members.insertionSort(compareHoldNoteSprites.bind(FlxSort.ASCENDING));
  }

  /**
   * Called when a key is pressed.
   * @param dir The direction of the key that was pressed.
   */
  public function pressKey(dir:NoteDirection):Void
  {
    heldKeys[dir] = true;
  }

  /**
   * Called when a key is released.
   * @param dir The direction of the key that was released.
   */
  public function releaseKey(dir:NoteDirection):Void
  {
    heldKeys[dir] = false;
  }

  /**
   * Check if a key is held down.
   * @param dir The direction of the key to check.
   * @return `true` if the key is held down, `false` otherwise.
   */
  public function isKeyHeld(dir:NoteDirection):Bool
  {
    return heldKeys[dir];
  }

  /**
   * Called when the song is reset.
   * Removes any special animations and the like.
   * Doesn't reset the notes from the chart, that's handled by the PlayState.
   */
  public function clean():Void
  {
    for (note in notes.members)
    {
      if (note == null) continue;
      killNote(note);
    }

    for (holdNote in holdNotes.members)
    {
      if (holdNote == null) continue;
      holdNote.kill();
    }

    for (splash in noteSplashes)
    {
      if (splash == null) continue;
      splash.kill();
    }

    for (cover in noteHoldCovers)
    {
      if (cover == null) continue;
      cover.kill();
    }

    heldKeys = [false, false, false, false];

    for (dir in DIRECTIONS)
    {
      playStatic(dir);
    }
    resetScrollSpeed();

    #if FEATURE_GHOST_TAPPING
    ghostTapTimer = 0;
    #end
  }

  /**
   * Apply note data from a chart to this strumline.
   * Note data should be valid and apply only to this strumline.
   * @param data The note data to apply.
   */
  public function applyNoteData(data:Array<SongNoteData>):Void
  {
    this.notes.clear();

    this.noteData = data.copy();
    this.nextNoteIndex = 0;

    // Sort the notes by strumtime.
    this.noteData.insertionSort(compareNoteData.bind(FlxSort.ASCENDING));
  }

  /**
   * Add a note data to the strumline.
   * This will not remove existing notes, so you should call `applyNoteData` if you want to reset the strumline.
   * @param note The note data to add.
   * @param sort Whether to sort the note data after adding.
   */
  public function addNoteData(note:SongNoteData, sort:Bool = true):Void
  {
    if (note == null) return;

    this.noteData.push(note);
    if (sort) this.noteData.sort(compareNoteData.bind(FlxSort.ASCENDING));
  }

  /**
   * Hit a note.
   * @param note The note to hit.
   * @param removeNote True to remove the note immediately, false to make it transparent and let it move offscreen.
   */
  public function hitNote(note:NoteSprite, removeNote:Bool = true):Void
  {
    playConfirm(note.direction);
    note.hasBeenHit = true;

    if (removeNote)
    {
      killNote(note);
    }
    else
    {
      note.alpha = 0.5;
      note.desaturate();
    }

    if (note.holdNoteSprite != null)
    {
      note.holdNoteSprite.hitNote = true;
      note.holdNoteSprite.missedNote = false;

      note.holdNoteSprite.sustainLength = (note.holdNoteSprite.strumTime + note.holdNoteSprite.fullSustainLength) - conductorInUse.songPosition;
    }

    #if FEATURE_GHOST_TAPPING
    ghostTapTimer = Constants.GHOST_TAP_DELAY;
    #end
  }

  /**
   * Kill a note heading towards the strumline.
   * @param note The note to kill. Gets recycled and reused for performance.
   */
  public function killNote(note:NoteSprite):Void
  {
    if (note == null) return;
    note.visible = false;
    notes.remove(note, false);
    note.kill();

    if (note.holdNoteSprite != null)
    {
      note.holdNoteSprite.missedNote = true;
      note.holdNoteSprite.visible = false;
    }
  }

  /**
   * Get a strumline note sprite by its index.
   * @param index The index of the note to get.
   * @return The note.
   */
  public function getByIndex(index:Int):StrumlineNote
  {
    return this.strumlineNotes.members[index];
  }

  /**
   * Get a strumline note sprite by its direction.
   * @param direction The direction of the note to get.
   * @return The note.
   */
  public function getByDirection(direction:NoteDirection):StrumlineNote
  {
    return getByIndex(DIRECTIONS.indexOf(direction));
  }

  /**
   * Play a static animation for a given direction.
   * @param direction The direction of the note to play the static animation for.
   */
  public function playStatic(direction:NoteDirection):Void
  {
    getByDirection(direction).playStatic();

    if (isPlayer) noteVibrations.noteStatuses[direction] = NoteStatus.idle;
  }

  /**
   * Play a press animation for a given direction.
   * @param direction The direction of the note to play the press animation for.
   */
  public function playPress(direction:NoteDirection):Void
  {
    getByDirection(direction).playPress();

    if (isPlayer) noteVibrations.noteStatuses[direction] = NoteStatus.pressed;
  }

  /**
   * Play a confirm animation for a given direction.
   * @param direction The direction of the note to play the confirm animation for.
   */
  public function playConfirm(direction:NoteDirection):Void
  {
    getByDirection(direction).playConfirm();

    if (isPlayer) noteVibrations.noteStatuses[direction] = NoteStatus.confirm;
  }

  /**
   * Play a confirm animation for a hold note.
   * @param direction The direction of the note to play the confirm animation for.
   */
  public function holdConfirm(direction:NoteDirection):Void
  {
    getByDirection(direction).holdConfirm();

    if (isPlayer) noteVibrations.noteStatuses[direction] = NoteStatus.holdConfirm;
  }

  /**
   * Check if a given direction is playing the confirm animation.
   * @param direction The direction of the note to check.
   * @return `true` if the note is playing the confirm animation, `false` otherwise.
   */
  public function isConfirm(direction:NoteDirection):Bool
  {
    return getByDirection(direction).isConfirm();
  }

  /**
   * Play a note splash for a given direction.
   * @param direction The direction of the note to play the splash animation for.
   */
  public function playNoteSplash(direction:NoteDirection):Void
  {
    if (!showNotesplash) return;
    if (!noteStyle.isNoteSplashEnabled()) return;

    var splash:NoteSplash = this.constructNoteSplash();

    if (splash != null)
    {
      splash.play(direction);

      splash.x = this.x;
      splash.x += getXPos(direction);
      splash.x += INITIAL_OFFSET;
      splash.x += noteStyle.getSplashOffsets()[0] * splash.scale.x;

      splash.y = this.y;
      splash.y -= INITIAL_OFFSET;
      splash.y += noteStyle.getSplashOffsets()[1] * splash.scale.y;
    }
  }

  /**
   * Play a note hold cover for a given hold note.
   * @param holdNote The hold note to play the cover animation for.
   */
  public function playNoteHoldCover(holdNote:SustainTrail):Void
  {
    if (!showNotesplash) return;
    if (!noteStyle.isHoldNoteCoverEnabled()) return;

    var cover:NoteHoldCover = this.constructNoteHoldCover();

    if (cover != null)
    {
      cover.holdNote = holdNote;
      holdNote.cover = cover;
      cover.visible = true;

      cover.playStart();

      cover.x = this.x;
      cover.x += getXPos(holdNote.noteDirection);
      cover.x += STRUMLINE_SIZE / 2;
      cover.x -= cover.width / 2;
      cover.x += noteStyle.getHoldCoverOffsets()[0] * cover.scale.x;
      cover.x += -12; // hardcoded adjustment, because we are evil.

      cover.y = this.y;
      cover.y += INITIAL_OFFSET;
      cover.y += STRUMLINE_SIZE / 2;
      cover.y += noteStyle.getHoldCoverOffsets()[1] * cover.scale.y;
      cover.y += -96; // hardcoded adjustment, because we are evil.
    }
  }

  /**
   * Build a note sprite for a given note data.
   * @param note The note data to build the note sprite for.
   * @return The note sprite. Will recycle a note sprite from the pool if available for performance.
   */
  public function buildNoteSprite(note:SongNoteData):NoteSprite
  {
    var noteSprite:NoteSprite = constructNoteSprite();

    if (noteSprite != null)
    {
      var noteKindStyle:NoteStyle = NoteKindManager.getNoteStyle(note.kind, this.noteStyle.id) ?? this.noteStyle;
      noteSprite.setupNoteGraphic(noteKindStyle);

      var trueScale = new FlxPoint(strumlineScale.x, strumlineScale.y);
      #if mobile
      if (inArrowContorlSchemeMode)
      {
        final amplification:Float = (FlxG.width / FlxG.height) / (FlxG.initialWidth / FlxG.initialHeight);
        trueScale.set(strumlineScale.x - ((FlxG.height / FlxG.width) * 0.2) * amplification,
          strumlineScale.y - ((FlxG.height / FlxG.width) * 0.2) * amplification);
      }
      #end

      noteSprite.scale.scale(trueScale.x, trueScale.y);
      noteSprite.updateHitbox();

      noteSprite.direction = note.getDirection();
      noteSprite.noteData = note;

      noteSprite.x = this.x;
      noteSprite.x += getXPos(DIRECTIONS[note.getDirection() % KEY_COUNT]);
      noteSprite.x -= (noteSprite.width - Strumline.STRUMLINE_SIZE) / 2; // Center it
      noteSprite.x -= NUDGE;
      noteSprite.y = -9999;
    }

    return noteSprite;
  }

  /**
   * Build a hold note sprite for a given note data.
   * @param note The note data to build the hold note sprite for.
   * @return The hold note sprite. Will recycle a hold note sprite from the pool if available for performance.
   */
  public function buildHoldNoteSprite(note:SongNoteData):SustainTrail
  {
    var holdNoteSprite:SustainTrail = constructHoldNoteSprite();

    if (holdNoteSprite != null)
    {
      var noteKindStyle:NoteStyle = NoteKindManager.getNoteStyle(note.kind, this.noteStyle.id);
      if (noteKindStyle == null) noteKindStyle = NoteKindManager.getNoteStyle(note.kind, null);
      if (noteKindStyle == null) noteKindStyle = this.noteStyle;

      holdNoteSprite.setupHoldNoteGraphic(noteKindStyle);

      holdNoteSprite.parentStrumline = this;
      holdNoteSprite.noteData = note;
      holdNoteSprite.strumTime = note.time;
      holdNoteSprite.noteDirection = note.getDirection();
      holdNoteSprite.fullSustainLength = note.length;
      holdNoteSprite.sustainLength = note.length;
      holdNoteSprite.missedNote = false;
      holdNoteSprite.hitNote = false;
      holdNoteSprite.visible = true;
      holdNoteSprite.alpha = 1.0;

      holdNoteSprite.x = this.x;
      holdNoteSprite.x += getXPos(DIRECTIONS[note.getDirection() % KEY_COUNT]);
      holdNoteSprite.x += STRUMLINE_SIZE / 2;
      holdNoteSprite.x -= holdNoteSprite.width / 2;
      holdNoteSprite.y = -9999;
    }

    return holdNoteSprite;
  }

  /**
   * Custom recycling behavior for note splashes.
   */
  function constructNoteSplash():NoteSplash
  {
    var result:NoteSplash = null;

    // If we haven't filled the pool yet...
    if (noteSplashes.length < noteSplashes.maxSize)
    {
      // Create a new note splash.
      result = new NoteSplash(noteStyle);
      this.noteSplashes.add(result);
    }
    else
    {
      // Else, find a note splash which is inactive so we can revive it.
      result = this.noteSplashes.getFirstAvailable();

      if (result != null)
      {
        result.revive();
      }
      else
      {
        // The note splash pool is full and all note splashes are active,
        // so we just pick one at random to destroy and restart.
        result = FlxG.random.getObject(this.noteSplashes.members);
      }
    }

    return result;
  }

  /**
   * Custom recycling behavior for note hold covers.
   */
  function constructNoteHoldCover():NoteHoldCover
  {
    var result:NoteHoldCover = null;

    // If we haven't filled the pool yet...
    if (noteHoldCovers.length < noteHoldCovers.maxSize)
    {
      // Create a new note hold cover.
      result = new NoteHoldCover(noteStyle);
      this.noteHoldCovers.add(result);
    }
    else
    {
      // Else, find a note splash which is inactive so we can revive it.
      result = this.noteHoldCovers.getFirstAvailable();

      if (result != null)
      {
        result.revive();
      }
      else
      {
        // The note hold cover pool is full and all note hold covers are active,
        // so we just pick one at random to destroy and restart.
        result = FlxG.random.getObject(this.noteHoldCovers.members);
      }
    }

    return result;
  }

  /**
   * Custom recycling behavior for note sprites.
   */
  function constructNoteSprite():NoteSprite
  {
    var result:NoteSprite = null;

    // Else, find a note which is inactive so we can revive it.
    result = this.notes.getFirstAvailable();

    if (result != null)
    {
      // Revive and reuse the note.
      result.revive();
    }
    else
    {
      // The note sprite pool is full and all note splashes are active.
      // We have to create a new note.
      result = new NoteSprite(noteStyle);
      this.notes.add(result);
    }

    return result;
  }

  /**
   * Custom recycling behavior for hold note sprites.
   */
  function constructHoldNoteSprite():SustainTrail
  {
    var result:SustainTrail = null;

    // Else, find a note which is inactive so we can revive it.
    result = this.holdNotes.getFirstAvailable();

    if (result != null)
    {
      // Revive and reuse the note.
      result.revive();
    }
    else
    {
      // The note sprite pool is full and all note splashes are active.
      // We have to create a new note.
      result = new SustainTrail(0, 0, noteStyle);
      this.holdNotes.add(result);
    }

    return result;
  }

  function getXPos(direction:NoteDirection):Float
  {
    var pos:Float = 0;
    #if mobile
    if (inArrowContorlSchemeMode && isPlayer) pos = 35 * (FlxG.width / FlxG.height) / (FlxG.initialWidth / FlxG.initialHeight);
    #end
    return switch (direction)
    {
      case NoteDirection.LEFT: -pos * 2;
      case NoteDirection.DOWN:
        -(pos * 2) + (1 * Strumline.NOTE_SPACING) * (noteSpacingScale * strumlineScale.x);
      case NoteDirection.UP:
        pos + (2 * Strumline.NOTE_SPACING) * (noteSpacingScale * strumlineScale.x);
      case NoteDirection.RIGHT:
        pos + (3 * Strumline.NOTE_SPACING) * (noteSpacingScale * strumlineScale.x);
      default: -pos * 2;
    }
  }

  /**
   * Apply a small animation which moves the arrow down and fades it in.
   * Only plays at the start of Free Play songs.
   *
   * Note that modifying the offset of the whole strumline won't have the
   * @param arrow The arrow to animate.
   * @param index The index of the arrow in the strumline.
   */
  function fadeInArrow(index:Int, arrow:StrumlineNote):Void
  {
    arrow.y -= 10;
    arrow.alpha = 0.0;
    FlxTween.tween(arrow, {y: arrow.y + 10, alpha: 1}, 1, {ease: FlxEase.circOut, startDelay: 0.5 + (0.2 * index)});
  }

  /**
   * Apply a small animation which moves the arrow up and fades it out.
   * Used when the song ends in Freeplay mode.
   *
   * @param index The index of the arrow in the strumline.
   * @param arrow The arrow to animate.
   */
  public function fadeOutArrow(index:Int, arrow:StrumlineNote):Void
  {
    FlxTween.tween(arrow, {y: arrow.y - 10, alpha: 0}, 0.5, {ease: FlxEase.circIn});
  }

  /**
   * Play a fade in animation on all arrows in the strumline.
   * Used when starting a song in Freeplay mode.
   */
  public function fadeInArrows():Void
  {
    for (index => arrow in this.strumlineNotes.members.keyValueIterator())
    {
      fadeInArrow(index, arrow);
    }
  }

  /**
   * Play a fade out animation on all arrows in the strumline.
   * Used when ending a song in Freeplay mode.
   */
  public function fadeOutArrows():Void
  {
    for (index => arrow in this.strumlineNotes.members.keyValueIterator())
    {
      fadeOutArrow(index, arrow);
    }
  }

  /**
   * Compare two note data objects by their strumtime.
   * @param order The order to sort the notes in.
   * @param a The first note data object.
   * @param b The second note data object.
   * @return The comparison result, based on the time of the notes.
   */
  function compareNoteData(order:Int, a:SongNoteData, b:SongNoteData):Int
  {
    return FlxSort.byValues(order, a.time, b.time);
  }

  /**
   * Compare two note sprites by their strumtime.
   * @param order The order to sort the notes in.
   * @param a The first note sprite.
   * @param b The second note sprite.
   * @return The comparison result, based on the time of the notes.
   */
  function compareNoteSprites(order:Int, a:NoteSprite, b:NoteSprite):Int
  {
    return FlxSort.byValues(order, a?.strumTime, b?.strumTime);
  }

  /**
   * Compare two hold note sprites by their strumtime.
   * @param order The order to sort the notes in.
   * @param a The first hold note sprite.
   * @param b The second hold note sprite.
   * @return The comparison result, based on the time of the notes.
   */
  function compareHoldNoteSprites(order:Int, a:SustainTrail, b:SustainTrail):Int
  {
    return FlxSort.byValues(order, a?.strumTime, b?.strumTime);
  }

  /**
   * Find the minimum Y position of the strumline.
   * Ignores the background to ensure the strumline is positioned correctly.
   * @return The minimum Y position of the strumline.
   */
  override function findMinYHelper():Float
  {
    var value:Float = Math.POSITIVE_INFINITY;
    for (member in group.members)
    {
      if (member == null) continue;
      // SKIP THE BACKGROUND
      if (member == this.background) continue;

      var minY:Float;
      if (member.flixelType == SPRITEGROUP)
      {
        minY = (cast member : FlxSpriteGroup).findMinY();
      }
      else
      {
        minY = member.y;
      }

      if (minY < value) value = minY;
    }
    return value;
  }

  /**
   * Find the maximum Y position of the strumline.
   * Ignores the background to ensure the strumline is positioned correctly.
   * @return The maximum Y position of the strumline.
   */
  override function findMaxYHelper():Float
  {
    var value:Float = Math.NEGATIVE_INFINITY;
    for (member in group.members)
    {
      if (member == null) continue;
      // SKIP THE BACKGROUND
      if (member == this.background) continue;

      var maxY:Float;
      if (member.flixelType == SPRITEGROUP)
      {
        maxY = (cast member : FlxSpriteGroup).findMaxY();
      }
      else
      {
        maxY = member.y + member.height;
      }

      if (maxY > value) value = maxY;
    }
    return value;
  }
}
