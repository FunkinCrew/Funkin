package funkin.play.notes.notestyle;

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
  final fallback:Null<NoteStyle>;

  /**
   * @param id The ID of the JSON file to parse.
   */
  public function new(id:String)
  {
    this.id = id;
    _data = _fetchData(id);

    if (_data == null)
    {
      throw 'Could not parse note style data for id: $id';
    }

    this.fallback = NoteStyleRegistry.instance.fetchEntry(getFallbackID());
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
  function getFallbackID():Null<String>
  {
    return _data.fallback;
  }

  //       //
  // NOTES //
  //       //

  public function buildNoteSprite(target:NoteSprite):Void
  {
    // Apply the note sprite frames.
    var atlas:FlxAtlasFrames = buildNoteFrames(false);

    if (atlas == null)
    {
      throw 'Could not load spritesheet for note style: $id';
    }

    target.frames = atlas;

    target.antialiasing = !_data.assets.note.isPixel;

    // Apply the animations.
    buildNoteAnimations(target);
  }

  var noteFrames:FlxAtlasFrames = null;

  function buildNoteFrames(force:Bool = false):FlxAtlasFrames
  {
    if (!FunkinSprite.isTextureCached(Paths.image(getNoteAssetPath())))
    {
      FlxG.log.warn('Note texture is not cached: ${getNoteAssetPath()}');
    }

    // Purge the note frames if the cached atlas is invalid.
    if (noteFrames?.parent?.isDestroyed ?? false) noteFrames = null;

    if (noteFrames != null && !force) return noteFrames;

    noteFrames = Paths.getSparrowAtlas(getNoteAssetPath(), getNoteAssetLibrary());

    if (noteFrames == null)
    {
      throw 'Could not load note frames for note style: $id';
    }

    return noteFrames;
  }

  function getNoteAssetPath(raw:Bool = false):String
  {
    if (raw)
    {
      var rawPath:Null<String> = _data?.assets?.note?.assetPath;
      if (rawPath == null) return fallback.getNoteAssetPath(true);
      return rawPath;
    }

    // library:path
    var parts = getNoteAssetPath(true).split(Constants.LIBRARY_SEPARATOR);
    if (parts.length == 1) return getNoteAssetPath(true);
    return parts[1];
  }

  function getNoteAssetLibrary():Null<String>
  {
    // library:path
    var parts = getNoteAssetPath(true).split(Constants.LIBRARY_SEPARATOR);
    if (parts.length == 1) return null;
    return parts[0];
  }

  function buildNoteAnimations(target:NoteSprite):Void
  {
    var leftData:AnimationData = fetchNoteAnimationData(LEFT);
    target.animation.addByPrefix('purpleScroll', leftData.prefix, leftData.frameRate, leftData.looped, leftData.flipX, leftData.flipY);
    var downData:AnimationData = fetchNoteAnimationData(DOWN);
    target.animation.addByPrefix('blueScroll', downData.prefix, downData.frameRate, downData.looped, downData.flipX, downData.flipY);
    var upData:AnimationData = fetchNoteAnimationData(UP);
    target.animation.addByPrefix('greenScroll', upData.prefix, upData.frameRate, upData.looped, upData.flipX, upData.flipY);
    var rightData:AnimationData = fetchNoteAnimationData(RIGHT);
    target.animation.addByPrefix('redScroll', rightData.prefix, rightData.frameRate, rightData.looped, rightData.flipX, rightData.flipY);
  }

  function fetchNoteAnimationData(dir:NoteDirection):AnimationData
  {
    var result:Null<AnimationData> = switch (dir)
    {
      case LEFT: _data.assets.note.data.left.toNamed();
      case DOWN: _data.assets.note.data.down.toNamed();
      case UP: _data.assets.note.data.up.toNamed();
      case RIGHT: _data.assets.note.data.right.toNamed();
    };

    return (result == null) ? fallback.fetchNoteAnimationData(dir) : result;
  }

  public function getNoteOffsets():Array<Float>
  {
    var data = _data?.assets?.note;
    if (data == null) return fallback.getNoteOffsets();
    return data.offsets;
  }

  public function getNoteScale():Float
  {
    var data = _data?.assets?.note;
    if (data == null) return fallback.getNoteScale();
    return data.scale;
  }

  //            //
  // HOLD NOTES //
  //            //

  public function getHoldNoteAssetPath(raw:Bool = false):String
  {
    if (raw)
    {
      // TODO: figure out why ?. didn't work here
      var rawPath:Null<String> = (_data?.assets?.holdNote == null) ? null : _data?.assets?.holdNote?.assetPath;
      return (rawPath == null) ? fallback.getHoldNoteAssetPath(true) : rawPath;
    }

    // library:path
    var parts = getHoldNoteAssetPath(true).split(Constants.LIBRARY_SEPARATOR);
    if (parts.length == 1) return Paths.image(parts[0]);
    return Paths.image(parts[1], parts[0]);
  }

  public function isHoldNotePixel():Bool
  {
    var data = _data?.assets?.holdNote;
    if (data == null) return fallback.isHoldNotePixel();
    return data.isPixel;
  }

  public function getHoldNoteOffsets():Array<Float>
  {
    var data = _data?.assets?.holdNote;
    if (data == null) return fallback.getHoldNoteOffsets();
    return data.offsets;
  }

  public function getHoldNoteScale():Float
  {
    var data = _data?.assets?.holdNote;
    if (data == null) return fallback.getHoldNoteScale();
    return data.scale;
  }

  //           //
  // STRUMLINE //
  //           //

  public function applyStrumlineFrames(target:StrumlineNote):Void
  {
    // TODO: Add support for multi-Sparrow.
    // Will be less annoying after this is merged: https://github.com/HaxeFlixel/flixel/pull/2772

    var atlas:FlxAtlasFrames = Paths.getSparrowAtlas(getStrumlineAssetPath(), getStrumlineAssetLibrary());

    if (atlas == null)
    {
      throw 'Could not load spritesheet for note style: $id';
    }

    target.frames = atlas;

    target.scale.x = _data.assets.noteStrumline.scale;
    target.scale.y = _data.assets.noteStrumline.scale;
    target.antialiasing = !_data.assets.noteStrumline.isPixel;
  }

  function getStrumlineAssetPath(raw:Bool = false):String
  {
    if (raw)
    {
      var rawPath:Null<String> = _data?.assets?.noteStrumline?.assetPath;
      if (rawPath == null) return fallback.getStrumlineAssetPath(true);
      return rawPath;
    }

    // library:path
    var parts = getStrumlineAssetPath(true).split(Constants.LIBRARY_SEPARATOR);
    if (parts.length == 1) return getStrumlineAssetPath(true);
    return parts[1];
  }

  function getStrumlineAssetLibrary():Null<String>
  {
    // library:path
    var parts = getStrumlineAssetPath(true).split(Constants.LIBRARY_SEPARATOR);
    if (parts.length == 1) return null;
    return parts[0];
  }

  public function applyStrumlineAnimations(target:StrumlineNote, dir:NoteDirection):Void
  {
    FlxAnimationUtil.addAtlasAnimations(target, getStrumlineAnimationData(dir));
  }

  function getStrumlineAnimationData(dir:NoteDirection):Array<AnimationData>
  {
    var result:Array<AnimationData> = switch (dir)
    {
      case NoteDirection.LEFT: [
          _data.assets.noteStrumline.data.leftStatic.toNamed('static'),
          _data.assets.noteStrumline.data.leftPress.toNamed('press'),
          _data.assets.noteStrumline.data.leftConfirm.toNamed('confirm'),
          _data.assets.noteStrumline.data.leftConfirmHold.toNamed('confirm-hold'),
        ];
      case NoteDirection.DOWN: [
          _data.assets.noteStrumline.data.downStatic.toNamed('static'),
          _data.assets.noteStrumline.data.downPress.toNamed('press'),
          _data.assets.noteStrumline.data.downConfirm.toNamed('confirm'),
          _data.assets.noteStrumline.data.downConfirmHold.toNamed('confirm-hold'),
        ];
      case NoteDirection.UP: [
          _data.assets.noteStrumline.data.upStatic.toNamed('static'),
          _data.assets.noteStrumline.data.upPress.toNamed('press'),
          _data.assets.noteStrumline.data.upConfirm.toNamed('confirm'),
          _data.assets.noteStrumline.data.upConfirmHold.toNamed('confirm-hold'),
        ];
      case NoteDirection.RIGHT: [
          _data.assets.noteStrumline.data.rightStatic.toNamed('static'),
          _data.assets.noteStrumline.data.rightPress.toNamed('press'),
          _data.assets.noteStrumline.data.rightConfirm.toNamed('confirm'),
          _data.assets.noteStrumline.data.rightConfirmHold.toNamed('confirm-hold'),
        ];
    };

    return result;
  }

  public function applyStrumlineOffsets(target:StrumlineNote)
  {
    target.x += _data.assets.noteStrumline.offsets[0];
    target.y += _data.assets.noteStrumline.offsets[1];
  }

  public function getStrumlineScale():Float
  {
    return _data.assets.noteStrumline.scale;
  }

  //               //
  // NOTE SPLASHES //
  //               //

  public function buildNoteSplashSprite(target:NoteSplash):Void
  {
    // Apply the note sprite frames.
    var atlas:FlxAtlasFrames = buildNoteSplashFrames(false);

    if (atlas == null)
    {
      throw 'Could not load spritesheet for note splash style: $id';
    }

    target.frames = atlas;

    target.antialiasing = !_data.assets.noteSplash.isPixel;
    target.scale.set(_data.assets.noteSplash.scale, _data.assets.noteSplash.scale);
    target.updateHitbox();

    // Apply the animations.
    buildNoteSplashAnimations(target);
  }

  var noteSplashFrames:FlxAtlasFrames = null;

  function buildNoteSplashFrames(force:Bool = false):FlxAtlasFrames
  {
    if (!FunkinSprite.isTextureCached(Paths.image(getNoteSplashAssetPath())))
    {
      FlxG.log.warn('Note splash texture is not cached: ${getNoteSplashAssetPath()}');
    }

    // Purge the note frames if the cached atlas is invalid.
    if (noteSplashFrames?.parent?.isDestroyed ?? false) noteSplashFrames = null;

    if (noteSplashFrames != null && !force) return noteSplashFrames;

    noteSplashFrames = Paths.getSparrowAtlas(getNoteSplashAssetPath(), getNoteSplashAssetLibrary());

    if (noteSplashFrames == null)
    {
      throw 'Could not load note splash frames for note style: $id';
    }

    return noteSplashFrames;
  }

  function getNoteSplashAssetPath(raw:Bool = false)
  {
    if (raw)
    {
      var rawPath:Null<String> = _data?.assets?.noteSplash?.assetPath;
      if (rawPath == null) return fallback.getNoteSplashAssetPath(true);
      return rawPath;
    }

    // library:path
    var parts = getNoteSplashAssetPath(true).split(Constants.LIBRARY_SEPARATOR);
    if (parts.length == 1) return getNoteSplashAssetPath(true);
    return parts[1];
  }

  function getNoteSplashAssetLibrary():Null<String>
  {
    // library:path
    var parts = getNoteSplashAssetPath(true).split(Constants.LIBRARY_SEPARATOR);
    if (parts.length == 1) return null;
    return parts[0];
  }

  function buildNoteSplashAnimations(target:NoteSplash):Void
  {
    var left1Data:AnimationData = fetchNoteSplashAnimationData(LEFT, 1);
    target.animation.addByPrefix('splash1Left', left1Data.prefix, left1Data.frameRate, left1Data.looped, left1Data.flipX, left1Data.flipY);
    var left2Data:AnimationData = fetchNoteSplashAnimationData(LEFT, 2);
    target.animation.addByPrefix('splash2Left', left2Data.prefix, left2Data.frameRate, left2Data.looped, left2Data.flipX, left2Data.flipY);

    var down1Data:AnimationData = fetchNoteSplashAnimationData(DOWN, 1);
    target.animation.addByPrefix('splash1Down', down1Data.prefix, down1Data.frameRate, down1Data.looped, down1Data.flipX, down1Data.flipY);
    var down2Data:AnimationData = fetchNoteSplashAnimationData(DOWN, 2);
    target.animation.addByPrefix('splash2Down', down2Data.prefix, down2Data.frameRate, down2Data.looped, down2Data.flipX, down2Data.flipY);

    var up1Data:AnimationData = fetchNoteSplashAnimationData(UP, 1);
    target.animation.addByPrefix('splash1Up', up1Data.prefix, up1Data.frameRate, up1Data.looped, up1Data.flipX, up1Data.flipY);
    var up2Data:AnimationData = fetchNoteSplashAnimationData(UP, 2);
    target.animation.addByPrefix('splash2Up', up2Data.prefix, up2Data.frameRate, up2Data.looped, up2Data.flipX, up2Data.flipY);

    var right1Data:AnimationData = fetchNoteSplashAnimationData(RIGHT, 1);
    target.animation.addByPrefix('splash1Right', right1Data.prefix, right1Data.frameRate, right1Data.looped, right1Data.flipX, right1Data.flipY);
    var right2Data:AnimationData = fetchNoteSplashAnimationData(RIGHT, 2);
    target.animation.addByPrefix('splash2Right', right2Data.prefix, right2Data.frameRate, right2Data.looped, right2Data.flipX, right2Data.flipY);

    if (target.animation.getAnimationList().length < 8)
    {
      trace('WARNING: NoteSplash failed to initialize all animations.');
    }
  }

  function fetchNoteSplashAnimationData(dir:NoteDirection, index:Int):AnimationData
  {
    var unnamedResult:Null<UnnamedAnimationData> = Reflect.field(_data.assets.noteSplash.data, '${dir.name}$index');
    var result:Null<AnimationData> = unnamedResult.toNamed();

    return (result == null) ? fallback.fetchNoteSplashAnimationData(dir, index) : result;
  }

  public function getNoteSplashAnimationFrameRate(dir:NoteDirection, index:Int)
  {
    return fetchNoteSplashAnimationData(dir, index).frameRate;
  }

  public function getNoteSplashOffsets():Array<Float>
  {
    var data = _data?.assets?.noteSplash;
    if (data == null) return fallback.getNoteSplashOffsets();
    return data.offsets;
  }

  public function isNoteSplashEnabled():Bool
  {
    var data = _data?.assets?.noteSplash?.data;
    if (data == null) return fallback.isNoteSplashEnabled();
    return data.enabled;
  }

  //                  //
  // HOLD NOTE COVERS //
  //                  //

  public function buildNoteHoldCoverSprite(target:NoteHoldCover):Void
  {
    // Apply the note sprite frames.
    var atlas:FlxAtlasFrames = buildNoteHoldCoverFrames(false);

    if (atlas == null)
    {
      throw 'Could not load spritesheet for note hold cover style: $id';
    }

    target.glow = new flixel.FlxSprite();
    target.add(target.glow);
    target.glow.frames = atlas;

    target.glow.antialiasing = !_data.assets.holdNoteCover.isPixel;
    target.glow.scale.set(_data.assets.holdNoteCover.scale, _data.assets.holdNoteCover.scale);
    target.glow.updateHitbox();
    target.offset.set(-_data.assets.holdNoteCover.offsets[0], -_data.assets.holdNoteCover.offsets[1]);

    // Apply the animations.
    buildNoteHoldCoverAnimations(target);
  }

  var noteHoldCoverFrames:FlxAtlasFrames = null;

  function buildNoteHoldCoverFrames(force:Bool = false):FlxAtlasFrames
  {
    if (!FunkinSprite.isTextureCached(Paths.image(getNoteHoldCoverAssetPath())))
    {
      FlxG.log.warn('Note hold cover texture is not cached: ${getNoteHoldCoverAssetPath()}');
    }

    // Purge the note frames if the cached atlas is invalid.
    if (noteHoldCoverFrames?.parent?.isDestroyed ?? false) noteHoldCoverFrames = null;

    if (noteHoldCoverFrames != null && !force) return noteHoldCoverFrames;

    noteHoldCoverFrames = Paths.getSparrowAtlas(getNoteHoldCoverAssetPath(), getNoteHoldCoverAssetLibrary());

    if (noteHoldCoverFrames == null)
    {
      throw 'Could not load note hold cover frames for note style: $id';
    }

    return noteHoldCoverFrames;
  }

  function getNoteHoldCoverAssetPath(raw:Bool = false)
  {
    if (raw)
    {
      var rawPath:Null<String> = _data?.assets?.holdNoteCover?.assetPath;
      if (rawPath == null) return fallback.getNoteHoldCoverAssetPath(true);
      return rawPath;
    }

    // library:path
    var parts = getNoteHoldCoverAssetPath(true).split(Constants.LIBRARY_SEPARATOR);
    if (parts.length == 1) return getNoteHoldCoverAssetPath(true);
    return parts[1];
  }

  function getNoteHoldCoverAssetLibrary():Null<String>
  {
    // library:path
    var parts = getNoteHoldCoverAssetPath(true).split(Constants.LIBRARY_SEPARATOR);
    if (parts.length == 1) return null;
    return parts[0];
  }

  function buildNoteHoldCoverAnimations(target:NoteHoldCover):Void
  {
    for (direction in Strumline.DIRECTIONS)
    {
      var directionName = direction.colorName.toTitleCase();

      var data:Array<AnimationData> = fetchNoteHoldCoverAnimationData(direction);
      target.glow.animation.addByPrefix('holdCoverStart$directionName', data[0].prefix, data[0].frameRate, data[0].looped, data[0].flipX, data[0].flipY);
      target.glow.animation.addByPrefix('holdCover$directionName', data[1].prefix, data[1].frameRate, data[1].looped, data[1].flipX, data[1].flipY);
      target.glow.animation.addByPrefix('holdCoverEnd$directionName', data[2].prefix, data[2].frameRate, data[2].looped, data[2].flipX, data[2].flipY);
    }

    target.glow.animation.finishCallback = target.onAnimationFinished;

    if (target.glow.animation.getAnimationList().length < 3 * 4)
    {
      trace('WARNING: NoteHoldCover failed to initialize all animations.');
    }
  }

  function fetchNoteHoldCoverAnimationData(dir:NoteDirection):Array<AnimationData>
  {
    var unnamedResult:Array<Null<UnnamedAnimationData>> = [
      Reflect.field(_data.assets.holdNoteCover.data, '${dir.name}Start'),
      Reflect.field(_data.assets.holdNoteCover.data, '${dir.name}Continue'),
      Reflect.field(_data.assets.holdNoteCover.data, '${dir.name}End')
    ];
    var result:Array<Null<AnimationData>> = [unnamedResult[0].toNamed(), unnamedResult[1].toNamed(), unnamedResult[2].toNamed()];

    return (result == null) ? fallback.fetchNoteHoldCoverAnimationData(dir) : result;
  }

  public function isHoldNoteCoverEnabled():Bool
  {
    var data = _data?.assets?.holdNoteCover?.data;
    if (data == null) return fallback.isHoldNoteCoverEnabled();
    return data.enabled;
  }

  public function destroy():Void {}

  public function toString():String
  {
    return 'NoteStyle($id)';
  }

  static function _fetchData(id:String):Null<NoteStyleData>
  {
    return NoteStyleRegistry.instance.parseEntryDataWithMigration(id, NoteStyleRegistry.instance.fetchEntryVersion(id));
  }
}
