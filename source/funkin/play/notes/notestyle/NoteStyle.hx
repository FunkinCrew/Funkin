package funkin.play.notes.notestyle;

import funkin.play.Countdown;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.frames.FlxFramesCollection;
import funkin.data.animation.AnimationData;
import funkin.data.IRegistryEntry;
import funkin.graphics.FunkinSprite;
import funkin.data.notestyle.NoteStyleData;
import funkin.data.notestyle.NoteStyleRegistry;
import funkin.data.notestyle.NoteStyleRegistry;
import funkin.util.assets.FlxAnimationUtil;

using funkin.data.animation.AnimationData.AnimationDataUtil;

/**
 * Holds the data for what assets to use for a note style,
 * and provides convenience methods for building sprites based on them.
 */
@:nullSafety
class NoteStyle implements IRegistryEntry<NoteStyleData>
{
  /**
   * The ID of the note style.
   */
  public final id:String;

  /**
   * Note style data as parsed from the JSON file.
   */
  public final _data:NoteStyleData;

  /**
   * The note style to use if this one doesn't have a certain asset.
   * This can be recursive, ehe.
   */
  var fallback(get, never):Null<NoteStyle>;

  function get_fallback():Null<NoteStyle> {
    if (_data == null || _data.fallback == null) return null;
    return NoteStyleRegistry.instance.fetchEntry(_data.fallback);
  }

  /**
   * @param id The ID of the JSON file to parse.
   */
  public function new(id:String)
  {
    this.id = id;
    _data = _fetchData(id);
  }

  /**
   * Get the readable name of the note style.
   * @return String
   */
  public function getName():String
  {
    return _data.name;
  }

  /**
   * Get the author of the note style.
   * @return String
   */
  public function getAuthor():String
  {
    return _data.author;
  }

  /**
   * Get the note style ID of the parent note style.
   * @return The string ID, or `null` if there is no parent.
   */
  public function getFallbackID():Null<String>
  {
    return _data.fallback;
  }

  public function buildNoteSprite(target:NoteSprite):Void
  {
    // Apply the note sprite frames.
    var atlas:Null<FlxAtlasFrames> = buildNoteFrames(false);

    if (atlas == null)
    {
      throw 'Could not load spritesheet for note style: $id';
    }

    target.frames = atlas;

    target.antialiasing = !(_data.assets?.note?.isPixel ?? false);

    // Apply the animations.
    buildNoteAnimations(target);

    // Set the scale.
    var scale = getNoteScale();
    target.scale.set(scale, scale);
    target.updateHitbox();
  }

  var noteFrames:Null<FlxAtlasFrames> = null;

  function buildNoteFrames(force:Bool = false):Null<FlxAtlasFrames>
  {
    var noteAssetPath = getNoteAssetPath();
    if (noteAssetPath == null)
    {
      FlxG.log.warn('Note asset path not found: ${id}');
      return null;
    }

    if (!FunkinSprite.isTextureCached(Paths.image(noteAssetPath)))
    {
      FlxG.log.warn('Note texture is not cached: ${noteAssetPath}');
    }

    // Purge the note frames if the cached atlas is invalid.
    @:nullSafety(Off)
    {
      if (noteFrames?.parent?.isDestroyed ?? false) noteFrames = null;
    }

    if (noteFrames != null && !force) return noteFrames;

    var noteAssetPath = getNoteAssetPath();
    if (noteAssetPath == null) return null;

    noteFrames = Paths.getSparrowAtlas(noteAssetPath, getNoteAssetLibrary());

    if (noteFrames == null)
    {
      throw 'Could not load note frames for note style: $id';
    }

    return noteFrames;
  }

  function getNoteAssetPath(raw:Bool = false):Null<String>
  {
    if (raw)
    {
      var rawPath:Null<String> = _data?.assets?.note?.assetPath;
      if (rawPath == null) return fallback?.getNoteAssetPath(true);
      return rawPath;
    }

    // library:path
    var parts = getNoteAssetPath(true)?.split(Constants.LIBRARY_SEPARATOR) ?? [];
    if (parts.length == 0) return null;
    if (parts.length == 1) return getNoteAssetPath(true);
    return parts[1];
  }

  function getNoteAssetLibrary():Null<String>
  {
    // library:path
    var parts = getNoteAssetPath(true)?.split(Constants.LIBRARY_SEPARATOR) ?? [];
    if (parts.length == 0) return null;
    if (parts.length == 1) return null;
    return parts[0];
  }

  function buildNoteAnimations(target:NoteSprite):Void
  {
    var leftData:Null<AnimationData> = fetchNoteAnimationData(LEFT);
    if (leftData != null) target.animation.addByPrefix('purpleScroll', leftData.prefix ?? '', leftData.frameRate ?? 24, leftData.looped ?? false,
      leftData.flipX, leftData.flipY);
    var downData:Null<AnimationData> = fetchNoteAnimationData(DOWN);
    if (downData != null) target.animation.addByPrefix('blueScroll', downData.prefix ?? '', downData.frameRate ?? 24, downData.looped ?? false,
      downData.flipX, downData.flipY);
    var upData:Null<AnimationData> = fetchNoteAnimationData(UP);
    if (upData != null) target.animation.addByPrefix('greenScroll', upData.prefix ?? '', upData.frameRate ?? 24, upData.looped ?? false, upData.flipX,
      upData.flipY);
    var rightData:Null<AnimationData> = fetchNoteAnimationData(RIGHT);
    if (rightData != null) target.animation.addByPrefix('redScroll', rightData.prefix ?? '', rightData.frameRate ?? 24, rightData.looped ?? false,
      rightData.flipX, rightData.flipY);
  }

  public function isNoteAnimated():Bool
  {
    // LOL is double ?? bad practice?
    return _data.assets?.note?.animated ?? fallback?.isNoteAnimated() ?? false;
  }

  public function getNoteScale():Float
  {
    return _data.assets?.note?.scale ?? fallback?.getNoteScale() ?? 1.0;
  }

  function fetchNoteAnimationData(dir:NoteDirection):Null<AnimationData>
  {
    var result:Null<AnimationData> = switch (dir)
    {
      case LEFT: _data.assets?.note?.data?.left?.toNamed();
      case DOWN: _data.assets?.note?.data?.down?.toNamed();
      case UP: _data.assets?.note?.data?.up?.toNamed();
      case RIGHT: _data.assets?.note?.data?.right?.toNamed();
    };

    return result ?? fallback?.fetchNoteAnimationData(dir);
  }

  public function getHoldNoteAssetPath(raw:Bool = false):Null<String>
  {
    if (raw)
    {
      var rawPath:Null<String> = _data?.assets?.holdNote?.assetPath;
      return rawPath ?? fallback?.getHoldNoteAssetPath(true);
    }

    // library:path
    var parts = getHoldNoteAssetPath(true)?.split(Constants.LIBRARY_SEPARATOR) ?? [];
    if (parts.length == 0) return null;
    if (parts.length == 1) return Paths.image(parts[0]);
    return Paths.image(parts[1], parts[0]);
  }

  public function isHoldNotePixel():Bool
  {
    return _data?.assets?.holdNote?.isPixel ?? fallback?.isHoldNotePixel() ?? false;
  }

  public function fetchHoldNoteScale():Float
  {
    return _data?.assets?.holdNote?.scale ?? fallback?.fetchHoldNoteScale() ?? 1.0;
  }

  public function getHoldNoteOffsets():Array<Float>
  {
    return _data?.assets?.holdNote?.offsets ?? fallback?.getHoldNoteOffsets() ?? [0.0, 0.0];
  }

  public function applyStrumlineFrames(target:StrumlineNote):Void
  {
    // TODO: Add support for multi-Sparrow.
    // Will be less annoying after this is merged: https://github.com/HaxeFlixel/flixel/pull/2772

    var atlas:FlxAtlasFrames = Paths.getSparrowAtlas(getStrumlineAssetPath() ?? '', getStrumlineAssetLibrary());

    if (atlas == null)
    {
      throw 'Could not load spritesheet for note style: $id';
    }

    target.frames = atlas;

    target.scale.set(_data.assets.noteStrumline?.scale ?? 1.0);
    target.antialiasing = !(_data.assets.noteStrumline?.isPixel ?? false);
  }

  function getStrumlineAssetPath(raw:Bool = false):Null<String>
  {
    if (raw)
    {
      return _data?.assets?.noteStrumline?.assetPath ?? fallback?.getStrumlineAssetPath(true);
    }

    // library:path
    var parts = getStrumlineAssetPath(true)?.split(Constants.LIBRARY_SEPARATOR) ?? [];
    if (parts.length <= 1) return getStrumlineAssetPath(true);
    return parts[1];
  }

  function getStrumlineAssetLibrary():Null<String>
  {
    // library:path
    var parts = getStrumlineAssetPath(true)?.split(Constants.LIBRARY_SEPARATOR) ?? [];
    if (parts.length <= 1) return null;
    return parts[0];
  }

  public function applyStrumlineAnimations(target:StrumlineNote, dir:NoteDirection):Void
  {
    FlxAnimationUtil.addAtlasAnimations(target, getStrumlineAnimationData(dir));
  }

  /**
   * Fetch the animation data for the strumline.
   * NOTE: This function only queries the fallback note style if all the animations are missing for a given direction.
   *
   * @param dir The direction to fetch the animation data for.
   * @return The animation data for the strumline in that direction.
   */
  function getStrumlineAnimationData(dir:NoteDirection):Array<AnimationData>
  {
    var result:Array<Null<AnimationData>> = switch (dir)
    {
      case NoteDirection.LEFT:
        [
          _data.assets.noteStrumline?.data?.leftStatic?.toNamed('static'),
          _data.assets.noteStrumline?.data?.leftPress?.toNamed('press'),
          _data.assets.noteStrumline?.data?.leftConfirm?.toNamed('confirm'),
          _data.assets.noteStrumline?.data?.leftConfirmHold?.toNamed('confirm-hold'),
        ];
      case NoteDirection.DOWN: [
          _data.assets.noteStrumline?.data?.downStatic?.toNamed('static'),
          _data.assets.noteStrumline?.data?.downPress?.toNamed('press'),
          _data.assets.noteStrumline?.data?.downConfirm?.toNamed('confirm'),
          _data.assets.noteStrumline?.data?.downConfirmHold?.toNamed('confirm-hold'),
        ];
      case NoteDirection.UP: [
          _data.assets.noteStrumline?.data?.upStatic?.toNamed('static'),
          _data.assets.noteStrumline?.data?.upPress?.toNamed('press'),
          _data.assets.noteStrumline?.data?.upConfirm?.toNamed('confirm'),
          _data.assets.noteStrumline?.data?.upConfirmHold?.toNamed('confirm-hold'),
        ];
      case NoteDirection.RIGHT: [
          _data.assets.noteStrumline?.data?.rightStatic?.toNamed('static'),
          _data.assets.noteStrumline?.data?.rightPress?.toNamed('press'),
          _data.assets.noteStrumline?.data?.rightConfirm?.toNamed('confirm'),
          _data.assets.noteStrumline?.data?.rightConfirmHold?.toNamed('confirm-hold'),
        ];
      default: [];
    };

    // New variable so we can change the type.
    var filteredResult:Array<AnimationData> = thx.Arrays.filterNull(result);

    if (filteredResult.length == 0) return fallback?.getStrumlineAnimationData(dir) ?? [];

    return filteredResult;
  }

  public function getStrumlineOffsets():Array<Float>
  {
    return _data?.assets?.noteStrumline?.offsets ?? fallback?.getStrumlineOffsets() ?? [0.0, 0.0];
  }

  public function applyStrumlineOffsets(target:StrumlineNote):Void
  {
    var offsets = getStrumlineOffsets();
    target.x += offsets[0];
    target.y += offsets[1];
  }

  public function getStrumlineScale():Float
  {
    return _data?.assets?.noteStrumline?.scale ?? fallback?.getStrumlineScale() ?? 1.0;
  }

  public function isNoteSplashEnabled():Bool
  {
    return _data?.assets?.noteSplash?.data?.enabled ?? fallback?.isNoteSplashEnabled() ?? false;
  }

  public function isHoldNoteCoverEnabled():Bool
  {
    return _data?.assets?.holdNoteCover?.data?.enabled ?? fallback?.isHoldNoteCoverEnabled() ?? false;
  }

  /**
   * Build a sprite for the given step of the countdown.
   * @param step
   * @return A `FunkinSprite`, or `null` if no graphic is available for this step.
   */
  public function buildCountdownSprite(step:Countdown.CountdownStep):Null<FunkinSprite>
  {
    var result = new FunkinSprite();

    switch (step)
    {
      case THREE:
        if (_data.assets.countdownThree == null) return fallback?.buildCountdownSprite(step);
        var assetPath = buildCountdownSpritePath(step);
        if (assetPath == null) return null;
        result.loadTexture(assetPath);
        result.scale.x = _data.assets.countdownThree?.scale ?? 1.0;
        result.scale.y = _data.assets.countdownThree?.scale ?? 1.0;
      case TWO:
        if (_data.assets.countdownTwo == null) return fallback?.buildCountdownSprite(step);
        var assetPath = buildCountdownSpritePath(step);
        if (assetPath == null) return null;
        result.loadTexture(assetPath);
        result.scale.x = _data.assets.countdownTwo?.scale ?? 1.0;
        result.scale.y = _data.assets.countdownTwo?.scale ?? 1.0;
      case ONE:
        if (_data.assets.countdownOne == null) return fallback?.buildCountdownSprite(step);
        var assetPath = buildCountdownSpritePath(step);
        if (assetPath == null) return null;
        result.loadTexture(assetPath);
        result.scale.x = _data.assets.countdownOne?.scale ?? 1.0;
        result.scale.y = _data.assets.countdownOne?.scale ?? 1.0;
      case GO:
        if (_data.assets.countdownGo == null) return fallback?.buildCountdownSprite(step);
        var assetPath = buildCountdownSpritePath(step);
        if (assetPath == null) return null;
        result.loadTexture(assetPath);
        result.scale.x = _data.assets.countdownGo?.scale ?? 1.0;
        result.scale.y = _data.assets.countdownGo?.scale ?? 1.0;
      default:
        // TODO: Do something here?
        return null;
    }

    result.scrollFactor.set(0, 0);
    result.antialiasing = !isCountdownSpritePixel(step);
    result.updateHitbox();

    return result;
  }

  function buildCountdownSpritePath(step:Countdown.CountdownStep):Null<String>
  {
    var basePath:Null<String> = null;
    switch (step)
    {
      case THREE:
        basePath = _data.assets.countdownThree?.assetPath;
      case TWO:
        basePath = _data.assets.countdownTwo?.assetPath;
      case ONE:
        basePath = _data.assets.countdownOne?.assetPath;
      case GO:
        basePath = _data.assets.countdownGo?.assetPath;
      default:
        basePath = null;
    }

    if (basePath == null) return fallback?.buildCountdownSpritePath(step);

    var parts = basePath?.split(Constants.LIBRARY_SEPARATOR) ?? [];
    if (parts.length < 1) return null;
    if (parts.length == 1) return parts[0];

    return parts[1];
  }

  function buildCountdownSpriteLibrary(step:Countdown.CountdownStep):Null<String>
  {
    var basePath:Null<String> = null;
    switch (step)
    {
      case THREE:
        basePath = _data.assets.countdownThree?.assetPath;
      case TWO:
        basePath = _data.assets.countdownTwo?.assetPath;
      case ONE:
        basePath = _data.assets.countdownOne?.assetPath;
      case GO:
        basePath = _data.assets.countdownGo?.assetPath;
      default:
        basePath = null;
    }

    if (basePath == null) return fallback?.buildCountdownSpriteLibrary(step);

    var parts = basePath?.split(Constants.LIBRARY_SEPARATOR) ?? [];
    if (parts.length <= 1) return null;

    return parts[0];
  }

  public function isCountdownSpritePixel(step:Countdown.CountdownStep):Bool
  {
    switch (step)
    {
      case THREE:
        var result = _data.assets.countdownThree?.isPixel;
        if (result == null) result = fallback?.isCountdownSpritePixel(step) ?? false;
        return result;
      case TWO:
        var result = _data.assets.countdownTwo?.isPixel;
        if (result == null) result = fallback?.isCountdownSpritePixel(step) ?? false;
        return result;
      case ONE:
        var result = _data.assets.countdownOne?.isPixel;
        if (result == null) result = fallback?.isCountdownSpritePixel(step) ?? false;
        return result;
      case GO:
        var result = _data.assets.countdownGo?.isPixel;
        if (result == null) result = fallback?.isCountdownSpritePixel(step) ?? false;
        return result;
      default:
        return false;
    }
  }

  public function getCountdownSpriteOffsets(step:Countdown.CountdownStep):Array<Float>
  {
    switch (step)
    {
      case THREE:
        var result = _data.assets.countdownThree?.offsets;
        if (result == null) result = fallback?.getCountdownSpriteOffsets(step) ?? [0, 0];
        return result;
      case TWO:
        var result = _data.assets.countdownTwo?.offsets;
        if (result == null) result = fallback?.getCountdownSpriteOffsets(step) ?? [0, 0];
        return result;
      case ONE:
        var result = _data.assets.countdownOne?.offsets;
        if (result == null) result = fallback?.getCountdownSpriteOffsets(step) ?? [0, 0];
        return result;
      case GO:
        var result = _data.assets.countdownGo?.offsets;
        if (result == null) result = fallback?.getCountdownSpriteOffsets(step) ?? [0, 0];
        return result;
      default:
        return [0, 0];
    }
  }

  public function getCountdownSoundPath(step:Countdown.CountdownStep, raw:Bool = false):Null<String>
  {
    if (raw)
    {
      // TODO: figure out why ?. didn't work here
      var rawPath:Null<String> = switch (step)
      {
        case Countdown.CountdownStep.THREE:
          _data.assets.countdownThree?.data?.audioPath;
        case Countdown.CountdownStep.TWO:
          _data.assets.countdownTwo?.data?.audioPath;
        case Countdown.CountdownStep.ONE:
          _data.assets.countdownOne?.data?.audioPath;
        case Countdown.CountdownStep.GO:
          _data.assets.countdownGo?.data?.audioPath;
        default:
          null;
      }

      return (rawPath == null) ? fallback?.getCountdownSoundPath(step, true) : rawPath;
    }

    // library:path
    var parts = getCountdownSoundPath(step, true)?.split(Constants.LIBRARY_SEPARATOR) ?? [];
    if (parts.length == 0) return null;
    if (parts.length == 1) return Paths.image(parts[0]);
    return Paths.sound(parts[1], parts[0]);
  }

  public function buildJudgementSprite(rating:String):Null<FunkinSprite>
  {
    var result = new FunkinSprite();

    switch (rating)
    {
      case "sick":
        if (_data.assets.judgementSick == null) return fallback?.buildJudgementSprite(rating);
        var assetPath = buildJudgementSpritePath(rating);
        if (assetPath == null) return null;
        result.loadTexture(assetPath);
        result.scale.x = _data.assets.judgementSick?.scale ?? 1.0;
        result.scale.y = _data.assets.judgementSick?.scale ?? 1.0;
      case "good":
        if (_data.assets.judgementGood == null) return fallback?.buildJudgementSprite(rating);
        var assetPath = buildJudgementSpritePath(rating);
        if (assetPath == null) return null;
        result.loadTexture(assetPath);
        result.scale.x = _data.assets.judgementGood?.scale ?? 1.0;
        result.scale.y = _data.assets.judgementGood?.scale ?? 1.0;
      case "bad":
        if (_data.assets.judgementBad == null) return fallback?.buildJudgementSprite(rating);
        var assetPath = buildJudgementSpritePath(rating);
        if (assetPath == null) return null;
        result.loadTexture(assetPath);
        result.scale.x = _data.assets.judgementBad?.scale ?? 1.0;
        result.scale.y = _data.assets.judgementBad?.scale ?? 1.0;
      case "shit":
        if (_data.assets.judgementShit == null) return fallback?.buildJudgementSprite(rating);
        var assetPath = buildJudgementSpritePath(rating);
        if (assetPath == null) return null;
        result.loadTexture(assetPath);
        result.scale.x = _data.assets.judgementShit?.scale ?? 1.0;
        result.scale.y = _data.assets.judgementShit?.scale ?? 1.0;
      default:
        return null;
    }

    result.scrollFactor.set(0.2, 0.2);
    var isPixel = isJudgementSpritePixel(rating);
    result.antialiasing = !isPixel;
    result.pixelPerfectRender = isPixel;
    result.pixelPerfectPosition = isPixel;
    result.updateHitbox();

    return result;
  }

  public function isJudgementSpritePixel(rating:String):Bool
  {
    switch (rating)
    {
      case "sick":
        var result = _data.assets.judgementSick?.isPixel;
        if (result == null) result = fallback?.isJudgementSpritePixel(rating) ?? false;
        return result;
      case "good":
        var result = _data.assets.judgementGood?.isPixel;
        if (result == null) result = fallback?.isJudgementSpritePixel(rating) ?? false;
        return result;
      case "bad":
        var result = _data.assets.judgementBad?.isPixel;
        if (result == null) result = fallback?.isJudgementSpritePixel(rating) ?? false;
        return result;
      case "shit":
        var result = _data.assets.judgementShit?.isPixel;
        if (result == null) result = fallback?.isJudgementSpritePixel(rating) ?? false;
        return result;
      default:
        return false;
    }
  }

  function buildJudgementSpritePath(rating:String):Null<String>
  {
    var basePath:Null<String> = null;
    switch (rating)
    {
      case "sick":
        basePath = _data.assets.judgementSick?.assetPath;
      case "good":
        basePath = _data.assets.judgementGood?.assetPath;
      case "bad":
        basePath = _data.assets.judgementBad?.assetPath;
      case "shit":
        basePath = _data.assets.judgementShit?.assetPath;
      default:
        basePath = null;
    }

    if (basePath == null) return fallback?.buildJudgementSpritePath(rating);

    var parts = basePath?.split(Constants.LIBRARY_SEPARATOR) ?? [];
    if (parts.length < 1) return null;
    if (parts.length == 1) return parts[0];

    return parts[1];
  }

  public function getJudgementSpriteOffsets(rating:String):Array<Float>
  {
    switch (rating)
    {
      case "sick":
        var result = _data.assets.judgementSick?.offsets;
        if (result == null) result = fallback?.getJudgementSpriteOffsets(rating) ?? [0, 0];
        return result;
      case "good":
        var result = _data.assets.judgementGood?.offsets;
        if (result == null) result = fallback?.getJudgementSpriteOffsets(rating) ?? [0, 0];
        return result;
      case "bad":
        var result = _data.assets.judgementBad?.offsets;
        if (result == null) result = fallback?.getJudgementSpriteOffsets(rating) ?? [0, 0];
        return result;
      case "shit":
        var result = _data.assets.judgementShit?.offsets;
        if (result == null) result = fallback?.getJudgementSpriteOffsets(rating) ?? [0, 0];
        return result;
      default:
        return [0, 0];
    }
  }

  public function buildComboNumSprite(digit:Int):Null<FunkinSprite>
  {
    var result = new FunkinSprite();

    switch (digit)
    {
      case 0:
        if (_data.assets.comboNumber0 == null) return fallback?.buildComboNumSprite(digit);
        var assetPath = buildComboNumSpritePath(digit);
        if (assetPath == null) return null;
        result.loadTexture(assetPath);
        result.scale.x = _data.assets.comboNumber0?.scale ?? 1.0;
        result.scale.y = _data.assets.comboNumber0?.scale ?? 1.0;
      case 1:
        if (_data.assets.comboNumber1 == null) return fallback?.buildComboNumSprite(digit);
        var assetPath = buildComboNumSpritePath(digit);
        if (assetPath == null) return null;
        result.loadTexture(assetPath);
        result.scale.x = _data.assets.comboNumber1?.scale ?? 1.0;
        result.scale.y = _data.assets.comboNumber1?.scale ?? 1.0;
      case 2:
        if (_data.assets.comboNumber2 == null) return fallback?.buildComboNumSprite(digit);
        var assetPath = buildComboNumSpritePath(digit);
        if (assetPath == null) return null;
        result.loadTexture(assetPath);
        result.scale.x = _data.assets.comboNumber2?.scale ?? 1.0;
        result.scale.y = _data.assets.comboNumber2?.scale ?? 1.0;
      case 3:
        if (_data.assets.comboNumber3 == null) return fallback?.buildComboNumSprite(digit);
        var assetPath = buildComboNumSpritePath(digit);
        if (assetPath == null) return null;
        result.loadTexture(assetPath);
        result.scale.x = _data.assets.comboNumber3?.scale ?? 1.0;
        result.scale.y = _data.assets.comboNumber3?.scale ?? 1.0;
      case 4:
        if (_data.assets.comboNumber4 == null) return fallback?.buildComboNumSprite(digit);
        var assetPath = buildComboNumSpritePath(digit);
        if (assetPath == null) return null;
        result.loadTexture(assetPath);
        result.scale.x = _data.assets.comboNumber4?.scale ?? 1.0;
        result.scale.y = _data.assets.comboNumber4?.scale ?? 1.0;
      case 5:
        if (_data.assets.comboNumber5 == null) return fallback?.buildComboNumSprite(digit);
        var assetPath = buildComboNumSpritePath(digit);
        if (assetPath == null) return null;
        result.loadTexture(assetPath);
        result.scale.x = _data.assets.comboNumber5?.scale ?? 1.0;
        result.scale.y = _data.assets.comboNumber5?.scale ?? 1.0;
      case 6:
        if (_data.assets.comboNumber6 == null) return fallback?.buildComboNumSprite(digit);
        var assetPath = buildComboNumSpritePath(digit);
        if (assetPath == null) return null;
        result.loadTexture(assetPath);
        result.scale.x = _data.assets.comboNumber6?.scale ?? 1.0;
        result.scale.y = _data.assets.comboNumber6?.scale ?? 1.0;
      case 7:
        if (_data.assets.comboNumber7 == null) return fallback?.buildComboNumSprite(digit);
        var assetPath = buildComboNumSpritePath(digit);
        if (assetPath == null) return null;
        result.loadTexture(assetPath);
        result.scale.x = _data.assets.comboNumber7?.scale ?? 1.0;
        result.scale.y = _data.assets.comboNumber7?.scale ?? 1.0;
      case 8:
        if (_data.assets.comboNumber8 == null) return fallback?.buildComboNumSprite(digit);
        var assetPath = buildComboNumSpritePath(digit);
        if (assetPath == null) return null;
        result.loadTexture(assetPath);
        result.scale.x = _data.assets.comboNumber8?.scale ?? 1.0;
        result.scale.y = _data.assets.comboNumber8?.scale ?? 1.0;
      case 9:
        if (_data.assets.comboNumber9 == null) return fallback?.buildComboNumSprite(digit);
        var assetPath = buildComboNumSpritePath(digit);
        if (assetPath == null) return null;
        result.loadTexture(assetPath);
        result.scale.x = _data.assets.comboNumber9?.scale ?? 1.0;
        result.scale.y = _data.assets.comboNumber9?.scale ?? 1.0;
      default:
        return null;
    }

    var isPixel = isComboNumSpritePixel(digit);
    result.antialiasing = !isPixel;
    result.pixelPerfectRender = isPixel;
    result.pixelPerfectPosition = isPixel;
    result.updateHitbox();

    return result;
  }

  public function isComboNumSpritePixel(digit:Int):Bool
  {
    switch (digit)
    {
      case 0:
        var result = _data.assets.comboNumber0?.isPixel;
        if (result == null) result = fallback?.isComboNumSpritePixel(digit) ?? false;
        return result;
      case 1:
        var result = _data.assets.comboNumber1?.isPixel;
        if (result == null) result = fallback?.isComboNumSpritePixel(digit) ?? false;
        return result;
      case 2:
        var result = _data.assets.comboNumber2?.isPixel;
        if (result == null) result = fallback?.isComboNumSpritePixel(digit) ?? false;
        return result;
      case 3:
        var result = _data.assets.comboNumber3?.isPixel;
        if (result == null) result = fallback?.isComboNumSpritePixel(digit) ?? false;
        return result;
      case 4:
        var result = _data.assets.comboNumber4?.isPixel;
        if (result == null) result = fallback?.isComboNumSpritePixel(digit) ?? false;
        return result;
      case 5:
        var result = _data.assets.comboNumber5?.isPixel;
        if (result == null) result = fallback?.isComboNumSpritePixel(digit) ?? false;
        return result;
      case 6:
        var result = _data.assets.comboNumber6?.isPixel;
        if (result == null) result = fallback?.isComboNumSpritePixel(digit) ?? false;
        return result;
      case 7:
        var result = _data.assets.comboNumber7?.isPixel;
        if (result == null) result = fallback?.isComboNumSpritePixel(digit) ?? false;
        return result;
      case 8:
        var result = _data.assets.comboNumber8?.isPixel;
        if (result == null) result = fallback?.isComboNumSpritePixel(digit) ?? false;
        return result;
      case 9:
        var result = _data.assets.comboNumber9?.isPixel;
        if (result == null) result = fallback?.isComboNumSpritePixel(digit) ?? false;
        return result;
      default:
        return false;
    }
  }

  function buildComboNumSpritePath(digit:Int):Null<String>
  {
    var basePath:Null<String> = null;
    switch (digit)
    {
      case 0:
        basePath = _data.assets.comboNumber0?.assetPath;
      case 1:
        basePath = _data.assets.comboNumber1?.assetPath;
      case 2:
        basePath = _data.assets.comboNumber2?.assetPath;
      case 3:
        basePath = _data.assets.comboNumber3?.assetPath;
      case 4:
        basePath = _data.assets.comboNumber4?.assetPath;
      case 5:
        basePath = _data.assets.comboNumber5?.assetPath;
      case 6:
        basePath = _data.assets.comboNumber6?.assetPath;
      case 7:
        basePath = _data.assets.comboNumber7?.assetPath;
      case 8:
        basePath = _data.assets.comboNumber8?.assetPath;
      case 9:
        basePath = _data.assets.comboNumber9?.assetPath;
      default:
        basePath = null;
    }

    if (basePath == null) return fallback?.buildComboNumSpritePath(digit);

    var parts = basePath?.split(Constants.LIBRARY_SEPARATOR) ?? [];
    if (parts.length < 1) return null;
    if (parts.length == 1) return parts[0];

    return parts[1];
  }

  public function getComboNumSpriteOffsets(digit:Int):Array<Float>
  {
    switch (digit)
    {
      case 0:
        var result = _data.assets.comboNumber0?.offsets;
        if (result == null) result = fallback?.getComboNumSpriteOffsets(digit) ?? [0, 0];
        return result;
      case 1:
        var result = _data.assets.comboNumber1?.offsets;
        if (result == null) result = fallback?.getComboNumSpriteOffsets(digit) ?? [0, 0];
        return result;
      case 2:
        var result = _data.assets.comboNumber2?.offsets;
        if (result == null) result = fallback?.getComboNumSpriteOffsets(digit) ?? [0, 0];
        return result;
      case 3:
        var result = _data.assets.comboNumber3?.offsets;
        if (result == null) result = fallback?.getComboNumSpriteOffsets(digit) ?? [0, 0];
        return result;
      case 4:
        var result = _data.assets.comboNumber4?.offsets;
        if (result == null) result = fallback?.getComboNumSpriteOffsets(digit) ?? [0, 0];
        return result;
      case 5:
        var result = _data.assets.comboNumber5?.offsets;
        if (result == null) result = fallback?.getComboNumSpriteOffsets(digit) ?? [0, 0];
        return result;
      case 6:
        var result = _data.assets.comboNumber6?.offsets;
        if (result == null) result = fallback?.getComboNumSpriteOffsets(digit) ?? [0, 0];
        return result;
      case 7:
        var result = _data.assets.comboNumber7?.offsets;
        if (result == null) result = fallback?.getComboNumSpriteOffsets(digit) ?? [0, 0];
        return result;
      case 8:
        var result = _data.assets.comboNumber8?.offsets;
        if (result == null) result = fallback?.getComboNumSpriteOffsets(digit) ?? [0, 0];
        return result;
      case 9:
        var result = _data.assets.comboNumber9?.offsets;
        if (result == null) result = fallback?.getComboNumSpriteOffsets(digit) ?? [0, 0];
        return result;
      default:
        return [0, 0];
    }
  }

  public function destroy():Void {}

  public function toString():String
  {
    return 'NoteStyle($id)';
  }

  static function _fetchData(id:String):NoteStyleData
  {
    var result = NoteStyleRegistry.instance.parseEntryDataWithMigration(id, NoteStyleRegistry.instance.fetchEntryVersion(id));

    if (result == null)
    {
      throw 'Could not parse note style data for id: $id';
    }
    else
    {
      return result;
    }
  }
}
