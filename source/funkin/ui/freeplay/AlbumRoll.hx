package funkin.ui.freeplay;

import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.util.FlxSort;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;
import flixel.tweens.FlxEase;
import funkin.data.freeplay.AlbumRegistry;
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
  public var albumId(default, set):String;

  function set_albumId(value:String):String
  {
    if (this.albumId != value)
    {
      this.albumId = value;
      updateAlbum();
    }

    return value;
  }

  var albumArt:FunkinSprite;
  var albumTitle:FunkinSprite;
  var difficultyStars:DifficultyStars;

  var _exitMovers:Null<FreeplayState.ExitMoverData>;

  var albumData:Album;

  public function new()
  {
    super();

    albumTitle = new FunkinSprite(947, 491);
    albumTitle.visible = true;
    albumTitle.zIndex = 200;
    add(albumTitle);

    difficultyStars = new DifficultyStars(140, 39);

    difficultyStars.stars.visible = true;
    albumTitle.visible = false;
    // albumArtist.visible = false;

    // var albumArtist:FlxSprite = new FlxSprite(1010, 607).loadGraphic(Paths.image('freeplay/albumArtist-kawaisprite'));
  }

  /**
   * Load the album data by ID and update the textures.
   */
  function updateAlbum():Void
  {
    albumData = AlbumRegistry.instance.fetchEntry(albumId);

    if (albumData == null)
    {
      FlxG.log.warn('Could not find album data for album ID: ${albumId}');

      return;
    };

    if (albumArt != null)
    {
      FlxTween.cancelTweensOf(albumArt);
      albumArt.visible = false;
      albumArt.destroy();
      remove(albumArt);
    }

    // Paths.animateAtlas('freeplay/albumRoll'),
    albumArt = FunkinSprite.create(1500, 360, albumData.getAlbumArtAssetKey());
    albumArt.setGraphicSize(262, 262); // Magic number for size IG
    albumArt.zIndex = 100;

    playIntro();
    add(albumArt);

    applyExitMovers();

    if (Assets.exists(Paths.image(albumData.getAlbumTitleAssetKey())))
    {
      albumTitle.loadGraphic(Paths.image(albumData.getAlbumTitleAssetKey()));
    }
    else
    {
      albumTitle.visible = false;
    }

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

    exitMovers.set([albumArt],
      {
        x: FlxG.width,
        speed: 0.4,
        wait: 0
      });
    exitMovers.set([albumTitle],
      {
        x: FlxG.width,
        speed: 0.2,
        wait: 0.1
      });

    /*
      exitMovers.set([albumArtist],
        {
          x: FlxG.width * 1.1,
          speed: 0.2,
          wait: 0.2
        });
     */
    exitMovers.set([difficultyStars],
      {
        x: FlxG.width * 1.2,
        speed: 0.2,
        wait: 0.3
      });
  }

  /**
   * Play the intro animation on the album art.
   */
  public function playIntro():Void
  {
    albumArt.visible = true;
    FlxTween.tween(albumArt, {x: 950, y: 320, angle: -340}, 0.5, {ease: FlxEase.quintOut});

    albumTitle.visible = false;
    new FlxTimer().start(0.75, function(_) {
      showTitle();
    });
  }

  public function setDifficultyStars(?difficulty:Int):Void
  {
    if (difficulty == null) return;

    difficultyStars.difficulty = difficulty;
  }

  public function showTitle():Void
  {
    albumTitle.visible = true;
  }

  /**
   * Make the album stars visible.
   */
  public function showStars():Void
  {
    // albumArtist.visible = false;
    difficultyStars.stars.visible = false;
  }
}
