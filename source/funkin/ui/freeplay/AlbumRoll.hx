package funkin.ui.freeplay;

import funkin.graphics.adobeanimate.FlxAtlasSprite;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.util.FlxSort;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;
import flixel.tweens.FlxEase;
import funkin.data.freeplay.album.AlbumRegistry;
import funkin.util.assets.FlxAnimationUtil;
import funkin.graphics.FunkinSprite;
import funkin.util.SortUtil;
import openfl.utils.Assets;

/**
 * The graphic for the album roll in the FreeplayState.
 * Simply set `albumID` to fetch the required data and update the textures.
 */
class AlbumRoll extends FlxSpriteGroup
{
  /**
   * The ID of the album to display.
   * Modify this value to automatically update the album art and title.
   */
  public var albumId(default, set):Null<String>;

  function set_albumId(value:Null<String>):Null<String>
  {
    if (this.albumId != value)
    {
      this.albumId = value;
      updateAlbum();
    }

    return value;
  }

  var newAlbumArt:FlxAtlasSprite;

  var difficultyStars:DifficultyStars;
  var _exitMovers:Null<FreeplayState.ExitMoverData>;

  var albumData:Album;

  final animNames:Map<String, String> = [
    "volume1-active" => "ENTRANCE",
    "volume2-active" => "ENTRANCE VOL2",
    "volume3-active" => "ENTRANCE VOL3",
    "volume1-trans" => "VOL1 TRANS",
    "volume2-trans" => "VOL2 TRANS",
    "volume3-trans" => "VOL3 TRANS",
    "volume1-idle" => "VOL1 STILL",
    "volume2-idle" => "VOL2 STILL",
    "volume3-idle" => "VOL3 STILL",
  ];

  public function new()
  {
    super();

    newAlbumArt = new FlxAtlasSprite(0, 0, Paths.animateAtlas("freeplay/albumRoll/freeplayAlbum"));
    newAlbumArt.visible = false;
    newAlbumArt.onAnimationFinish.add(onAlbumFinish);

    add(newAlbumArt);

    difficultyStars = new DifficultyStars(140, 39);
    difficultyStars.visible = false;
    add(difficultyStars);
  }

  function onAlbumFinish(animName:String):Void
  {
    // Play the idle animation for the current album.
    newAlbumArt.playAnimation(animNames.get('$albumId-idle'), false, false, true);

    // End on the last frame and don't continue until playAnimation is called again.
    // newAlbumArt.anim.pause();
  }

  /**
   * Load the album data by ID and update the textures.
   */
  function updateAlbum():Void
  {
    if (albumId == null)
    {
      this.visible = false;
      difficultyStars.stars.visible = false;
      return;
    }
    else
    {
      this.visible = true;
    }

    albumData = AlbumRegistry.instance.fetchEntry(albumId);

    if (albumData == null)
    {
      FlxG.log.warn('Could not find album data for album ID: ${albumId}');

      return;
    };

    applyExitMovers();

    refresh();
  }

  public function refresh():Void
  {
    sort(SortUtil.byZIndex, FlxSort.ASCENDING);
  }

  /**
   * Apply exit movers for the album roll.
   * @param exitMovers The exit movers to apply.
   */
  public function applyExitMovers(?exitMovers:FreeplayState.ExitMoverData):Void
  {
    if (exitMovers == null)
    {
      exitMovers = _exitMovers;
    }
    else
    {
      _exitMovers = exitMovers;
    }

    if (exitMovers == null) return;

    exitMovers.set([newAlbumArt, difficultyStars],
      {
        x: FlxG.width,
        speed: 0.4,
        wait: 0
      });
  }

  var titleTimer:Null<FlxTimer> = null;

  /**
   * Play the intro animation on the album art.
   */
  public function playIntro():Void
  {
    newAlbumArt.visible = true;
    newAlbumArt.playAnimation(animNames.get('$albumId-active'), false, false, false);

    difficultyStars.visible = false;
    new FlxTimer().start(0.75, function(_) {
      // showTitle();
      showStars();
    });
  }

  public function skipIntro():Void
  {
    newAlbumArt.playAnimation(animNames.get('$albumId-trans'), false, false, false);
  }

  public function setDifficultyStars(?difficulty:Int):Void
  {
    if (difficulty == null) return;
    difficultyStars.difficulty = difficulty;
  }

  /**
   * Make the album stars visible.
   */
  public function showStars():Void
  {
    difficultyStars.visible = true; // true;
    difficultyStars.flameCheck();
  }
}
