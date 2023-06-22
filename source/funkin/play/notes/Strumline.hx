package funkin.play.notes;

import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import funkin.ui.PreferencesMenu;
import funkin.play.notes.NoteSprite;
import flixel.util.FlxSort;
import funkin.play.notes.SustainTrail;
import funkin.util.SortUtil;
import funkin.play.song.SongData.SongNoteData;
import flixel.FlxG;
import flixel.group.FlxSpriteGroup;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;

/**
 * A group of sprites which handles the receptor, the note splashes, and the notes (with sustains) for a given player.
 */
class Strumline extends FlxSpriteGroup
{
  public static final DIRECTIONS:Array<NoteDirection> = [NoteDirection.LEFT, NoteDirection.DOWN, NoteDirection.UP, NoteDirection.RIGHT];
  public static final STRUMLINE_SIZE:Int = 112;
  public static final NOTE_SPACING:Int = STRUMLINE_SIZE + 8;

  // Positional fixes for new strumline graphics.
  static final INITIAL_OFFSET = -0.275 * STRUMLINE_SIZE;
  static final NUDGE:Float = 2.0;

  static final KEY_COUNT:Int = 4;
  static final NOTE_SPLASH_CAP:Int = 6;

  static var RENDER_DISTANCE_MS(get, null):Float;

  static function get_RENDER_DISTANCE_MS():Float
  {
    return FlxG.height / 0.45;
  }

  public var isPlayer:Bool;

  /**
   * The notes currently being rendered on the strumline.
   * This group iterates over this every frame to update note positions.
   * The PlayState also iterates over this to calculate user inputs.
   */
  public var notes:FlxTypedSpriteGroup<NoteSprite>;

  public var holdNotes:FlxTypedSpriteGroup<SustainTrail>;

  var strumlineNotes:FlxTypedSpriteGroup<StrumlineNote>;
  var noteSplashes:FlxTypedSpriteGroup<NoteSplash>;
  var sustainSplashes:FlxTypedSpriteGroup<NoteSplash>;

  var noteData:Array<SongNoteData> = [];
  var nextNoteIndex:Int = -1;

  public function new(isPlayer:Bool)
  {
    super();

    this.isPlayer = isPlayer;

    this.strumlineNotes = new FlxTypedSpriteGroup<StrumlineNote>();
    this.add(this.strumlineNotes);

    // Hold notes are added first so they render behind regular notes.
    this.holdNotes = new FlxTypedSpriteGroup<SustainTrail>();
    this.add(this.holdNotes);

    this.notes = new FlxTypedSpriteGroup<NoteSprite>();
    this.add(this.notes);

    this.noteSplashes = new FlxTypedSpriteGroup<NoteSplash>(0, 0, NOTE_SPLASH_CAP);
    this.add(this.noteSplashes);

    for (i in 0...DIRECTIONS.length)
    {
      var child:StrumlineNote = new StrumlineNote(isPlayer, DIRECTIONS[i]);
      child.x = getXPos(DIRECTIONS[i]);
      child.x += INITIAL_OFFSET;
      child.y = 0;
      this.strumlineNotes.add(child);
    }

    // This MUST be true for children to update!
    this.active = true;
  }

  override function get_width():Float
  {
    return 4 * Strumline.NOTE_SPACING;
  }

  public override function update(elapsed:Float):Void
  {
    super.update(elapsed);

    updateNotes();
  }

  /**
   * Get a list of notes within + or - the given strumtime.
   * @param strumTime The current time.
   * @param hitWindow The hit window to check.
   */
  public function getNotesInRange(strumTime:Float, hitWindow:Float):Array<NoteSprite>
  {
    var hitWindowStart:Float = strumTime - hitWindow;
    var hitWindowEnd:Float = strumTime + hitWindow;

    return notes.members.filter(function(note:NoteSprite) {
      return note != null && note.alive && !note.hasBeenHit && note.strumTime >= hitWindowStart && note.strumTime <= hitWindowEnd;
    });
  }

  public function getHoldNotesInRange(strumTime:Float, hitWindow:Float):Array<SustainTrail>
  {
    var hitWindowStart:Float = strumTime - hitWindow;
    var hitWindowEnd:Float = strumTime + hitWindow;

    return holdNotes.members.filter(function(note:SustainTrail) {
      return note != null
        && note.alive
        && note.strumTime >= hitWindowStart
        && (note.strumTime + note.fullSustainLength) <= hitWindowEnd;
    });
  }

  public function getNoteSprite(noteData:SongNoteData):NoteSprite
  {
    if (noteData == null) return null;

    for (note in notes.members)
    {
      if (note == null) continue;
      if (note.alive) continue;

      if (note.noteData == noteData) return note;
    }

    return null;
  }

  public function getHoldNoteSprite(noteData:SongNoteData):SustainTrail
  {
    if (noteData == null || ((noteData.length ?? 0.0) <= 0.0)) return null;

    for (holdNote in holdNotes.members)
    {
      if (holdNote == null) continue;
      if (holdNote.alive) continue;

      if (holdNote.noteData == noteData) return holdNote;
    }

    return null;
  }

  /**
   * For a note's strumTime, calculate its Y position relative to the strumline.
   * NOTE: Assumes Conductor and PlayState are both initialized.
   * @param strumTime
   * @return Float
   */
  static function calculateNoteYPos(strumTime:Float):Float
  {
    // Make the note move faster visually as it moves offscreen.
    var vwoosh:Float = (strumTime < Conductor.songPosition) ? 2.0 : 1.0;
    var scrollSpeed:Float = PlayState.instance?.currentChart?.scrollSpeed ?? 1.0;

    return Conductor.PIXELS_PER_MS * (Conductor.songPosition - strumTime) * scrollSpeed * vwoosh * (PreferencesMenu.getPref('downscroll') ? 1 : -1);
  }

  function updateNotes():Void
  {
    if (noteData.length == 0) return;

    var renderWindowStart:Float = Conductor.songPosition + RENDER_DISTANCE_MS;

    for (noteIndex in nextNoteIndex...noteData.length)
    {
      var note:Null<SongNoteData> = noteData[noteIndex];

      if (note == null) continue;
      if (note.time > renderWindowStart) break;

      buildNoteSprite(note);

      if (note.length > 0)
      {
        buildHoldNoteSprite(note);
      }

      nextNoteIndex++; // Increment the nextNoteIndex rather than splicing the array, because splicing is slow.
    }

    // Update rendering of notes.
    for (note in notes.members)
    {
      if (note == null || note.hasBeenHit) continue;

      note.y = this.y - INITIAL_OFFSET + calculateNoteYPos(note.strumTime);

      // Check if the note is outside the hit window, and if so, mark it as missed.
      // TODO: Check to make sure this doesn't happen when the note is on screen because it'll probably get deleted.
      if (Conductor.songPosition > (note.noteData.time + Conductor.HIT_WINDOW_MS))
      {
        note.visible = false;
        note.hasMissed = true;
        if (note.holdNoteSprite != null) note.holdNoteSprite.missed = true;
      }
      else
      {
        note.visible = true;
        note.hasMissed = false;
        if (note.holdNoteSprite != null) note.holdNoteSprite.missed = false;
      }
    }

    // Update rendering of hold notes.
    for (holdNote in holdNotes.members)
    {
      if (holdNote == null || !holdNote.alive) continue;

      var renderWindowEnd = holdNote.strumTime + holdNote.fullSustainLength + Conductor.HIT_WINDOW_MS + RENDER_DISTANCE_MS / 8;

      if (Conductor.songPosition >= renderWindowEnd || holdNote.sustainLength <= 0)
      {
        // Hold note is offscreen, kill it.
        holdNote.visible = false;
        holdNote.kill(); // Do not destroy! Recycling is faster.
      }
      else if (holdNote.sustainLength <= 0)
      {
        // Hold note is completed, kill it.
        playStatic(holdNote.noteDirection);
        holdNote.visible = false;
        holdNote.kill();
      }
      else if (holdNote.sustainLength <= 10)
      {
        // TODO: Better handle the weird edge case where the hold note is almost completed.
        holdNote.visible = false;
      }
      else if (Conductor.songPosition > holdNote.strumTime && !holdNote.missed)
      {
        // Hold note is currently being hit, clip it off.
        holdConfirm(holdNote.noteDirection);
        holdNote.visible = true;

        holdNote.sustainLength = (holdNote.strumTime + holdNote.fullSustainLength) - Conductor.songPosition;

        if (PreferencesMenu.getPref('downscroll'))
        {
          holdNote.y = this.y - holdNote.height + STRUMLINE_SIZE / 2;
        }
        else
        {
          holdNote.y = this.y - INITIAL_OFFSET + STRUMLINE_SIZE / 2;
        }
      }
      else if (holdNote.missed && (holdNote.fullSustainLength > holdNote.sustainLength))
      {
        // Hold note was dropped before completing, keep it in its clipped state.
        holdNote.visible = true;

        var yOffset:Float = (holdNote.fullSustainLength - holdNote.sustainLength) * Conductor.PIXELS_PER_MS;

        trace('yOffset: ' + yOffset);
        trace('holdNote.fullSustainLength: ' + holdNote.fullSustainLength);
        trace('holdNote.sustainLength: ' + holdNote.sustainLength);

        if (PreferencesMenu.getPref('downscroll'))
        {
          holdNote.y = this.y + calculateNoteYPos(holdNote.strumTime) - holdNote.height + STRUMLINE_SIZE / 2;
        }
        else
        {
          holdNote.y = this.y - INITIAL_OFFSET + calculateNoteYPos(holdNote.strumTime) + yOffset + STRUMLINE_SIZE / 2;
        }
      }
      else
      {
        // Hold note is new, render it normally.
        holdNote.visible = true;

        if (PreferencesMenu.getPref('downscroll'))
        {
          holdNote.y = this.y + calculateNoteYPos(holdNote.strumTime) - holdNote.height + STRUMLINE_SIZE / 2;
        }
        else
        {
          holdNote.y = this.y - INITIAL_OFFSET + calculateNoteYPos(holdNote.strumTime) + STRUMLINE_SIZE / 2;
        }
      }
    }
  }

  public function onBeatHit():Void
  {
    if (notes.members.length > 1) notes.members.insertionSort(compareNoteSprites.bind(FlxSort.ASCENDING));

    if (holdNotes.members.length > 1) holdNotes.members.insertionSort(compareHoldNoteSprites.bind(FlxSort.ASCENDING));
  }

  public function applyNoteData(data:Array<SongNoteData>):Void
  {
    this.notes.clear();

    this.noteData = data.copy();
    this.nextNoteIndex = 0;

    // Sort the notes by strumtime.
    this.noteData.insertionSort(compareNoteData.bind(FlxSort.ASCENDING));
  }

  public function hitNote(note:NoteSprite):Void
  {
    playConfirm(note.direction);
    killNote(note);
  }

  public function killNote(note:NoteSprite):Void
  {
    note.visible = false;
    notes.remove(note, false);
    note.kill();

    if (note.holdNoteSprite != null)
    {
      holdNoteSprite.missed = true;
      holdNoteSprite.alpha = 0.6;
    }
  }

  public function getByIndex(index:Int):StrumlineNote
  {
    return this.strumlineNotes.members[index];
  }

  public function getByDirection(direction:NoteDirection):StrumlineNote
  {
    return getByIndex(DIRECTIONS.indexOf(direction));
  }

  public function playStatic(direction:NoteDirection):Void
  {
    getByDirection(direction).playStatic();
  }

  public function playPress(direction:NoteDirection):Void
  {
    getByDirection(direction).playPress();
  }

  public function playConfirm(direction:NoteDirection):Void
  {
    getByDirection(direction).playConfirm();
  }

  public function holdConfirm(direction:NoteDirection):Void
  {
    getByDirection(direction).holdConfirm();
  }

  public function isConfirm(direction:NoteDirection):Bool
  {
    return getByDirection(direction).isConfirm();
  }

  public function playNoteSplash(direction:NoteDirection):Void
  {
    // TODO: Add a setting to disable note splashes.
    // if (Settings.noSplash) return;

    var splash:NoteSplash = this.constructNoteSplash();

    if (splash != null)
    {
      splash.play(direction);

      splash.x = this.x;
      splash.x += getXPos(direction);
      splash.x += INITIAL_OFFSET;
      splash.y = this.y;
      splash.y -= INITIAL_OFFSET;
      splash.y += 0;
    }
  }

  public function buildNoteSprite(note:SongNoteData):Void
  {
    var noteSprite:NoteSprite = constructNoteSprite();

    if (noteSprite != null)
    {
      noteSprite.strumTime = note.time;
      noteSprite.direction = note.getDirection();
      noteSprite.noteData = note;

      noteSprite.x = this.x;
      noteSprite.x += getXPos(DIRECTIONS[note.getDirection() % KEY_COUNT]);
      noteSprite.x -= NUDGE;
      // noteSprite.x += INITIAL_OFFSET;
      noteSprite.y = -9999;
    }
  }

  public function buildHoldNoteSprite(note:SongNoteData):Void
  {
    var holdNoteSprite:SustainTrail = constructHoldNoteSprite();

    if (holdNoteSprite != null)
    {
      holdNoteSprite.noteData = note;
      holdNoteSprite.strumTime = note.time;
      holdNoteSprite.noteDirection = note.getDirection();
      holdNoteSprite.fullSustainLength = note.length;
      holdNoteSprite.sustainLength = note.length;
      holdNoteSprite.missed = false;

      holdNoteSprite.x = this.x;
      holdNoteSprite.x += getXPos(DIRECTIONS[note.getDirection() % KEY_COUNT]);
      // holdNoteSprite.x += INITIAL_OFFSET;
      holdNoteSprite.x += STRUMLINE_SIZE / 2;
      holdNoteSprite.x -= holdNoteSprite.width / 2;
      holdNoteSprite.y = -9999;
    }
  }

  /**
   * Custom recycling behavior.
   */
  function constructNoteSplash():NoteSplash
  {
    var result:NoteSplash = null;

    // If we haven't filled the pool yet...
    if (noteSplashes.length < noteSplashes.maxSize)
    {
      // Create a new note splash.
      result = new NoteSplash();
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
   * Custom recycling behavior.
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
      result = new NoteSprite();
      this.notes.add(result);
    }

    return result;
  }

  /**
   * Custom recycling behavior.
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
      result = new SustainTrail(0, 100, Paths.image("NOTE_hold_assets"));
      this.holdNotes.add(result);
    }

    return result;
  }

  function getXPos(direction:NoteDirection):Float
  {
    return switch (direction)
    {
      case NoteDirection.LEFT: 0;
      case NoteDirection.DOWN: 0 + (1 * Strumline.NOTE_SPACING);
      case NoteDirection.UP: 0 + (2 * Strumline.NOTE_SPACING);
      case NoteDirection.RIGHT: 0 + (3 * Strumline.NOTE_SPACING);
      default: 0;
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
  function fadeInArrow(arrow:StrumlineNote):Void
  {
    arrow.y -= 10;
    arrow.alpha = 0;
    FlxTween.tween(arrow, {y: arrow.y + 10, alpha: 1}, 1, {ease: FlxEase.circOut, startDelay: 0.5 + (0.2 * arrow.ID)});
  }

  public function fadeInArrows():Void
  {
    for (arrow in this.strumlineNotes)
    {
      fadeInArrow(arrow);
    }
  }

  function compareNoteData(order:Int, a:SongNoteData, b:SongNoteData):Int
  {
    return FlxSort.byValues(order, a.time, b.time);
  }

  function compareNoteSprites(order:Int, a:NoteSprite, b:NoteSprite):Int
  {
    return FlxSort.byValues(order, a?.strumTime, b?.strumTime);
  }

  function compareHoldNoteSprites(order:Int, a:SustainTrail, b:SustainTrail):Int
  {
    return FlxSort.byValues(order, a?.strumTime, b?.strumTime);
  }
}
