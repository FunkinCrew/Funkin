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
  var albumTitle:FunkinSprite;

  var difficultyStars:DifficultyStars;
  var _exitMovers:Null<FreeplayState.ExitMoverData>;
  var _exitMoversCharSel:Null<FreeplayState.ExitMoverData>;

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

    newAlbumArt = new FlxAtlasSprite(640, 360, Paths.animateAtlas("freeplay/albumRoll/freeplayAlbum"));
    newAlbumArt.visible = false;
    newAlbumArt.onAnimationComplete.add(onAlbumFinish);

    add(newAlbumArt);

    difficultyStars = new DifficultyStars(140, 39);
    difficultyStars.visible = false;
    add(difficultyStars);

    buildAlbumTitle("freeplay/albumRoll/volume1-text");
    albumTitle.visible = false;
  }

  function onAlbumFinish(animName:String):Void
  {
    // Play the idle animation for the current album.
    if (animName != "idle")
    {
      newAlbumArt.playAnimation('idle', true);
    }
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

    // Update the album art.
    var albumGraphic = Paths.image(albumData.getAlbumArtAssetKey());
    newAlbumArt.replaceFrameGraphic(0, albumGraphic);

    buildAlbumTitle(albumData.getAlbumTitleAssetKey());

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
  public function applyExitMovers(?exitMovers:FreeplayState.ExitMoverData, ?exitMoversCharSel:FreeplayState.ExitMoverData):Void
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

    if (exitMoversCharSel == null)
    {
      exitMoversCharSel = _exitMoversCharSel;
    }
    else
    {
      _exitMoversCharSel = exitMoversCharSel;
    }

    if (exitMoversCharSel == null) return;

    exitMovers.set([newAlbumArt, difficultyStars],
      {
        x: FlxG.width,
        speed: 0.4,
        wait: 0
      });

    exitMoversCharSel.set([newAlbumArt, difficultyStars],
      {
        y: -175,
        speed: 0.8,
        wait: 0.1
      });
  }

  var titleTimer:Null<FlxTimer> = null;

  /**
   * Play the intro animation on the album art.
   */
  public function playIntro():Void
  {
    albumTitle.visible = false;
    newAlbumArt.visible = true;
    newAlbumArt.playAnimation('intro', true);

    difficultyStars.visible = false;
    new FlxTimer().start(0.75, function(_) {
      showTitle();
      showStars();
      albumTitle.animation.play('switch');
    });
  }

  public function skipIntro():Void
  {
    // Weird workaround
    newAlbumArt.playAnimation('switch', true);
    albumTitle.animation.play('switch');
  }

  public function showTitle():Void
  {
    albumTitle.visible = true;
  }

  public function buildAlbumTitle(assetKey:String):Void
  {
    if (albumTitle != null)
    {
      remove(albumTitle);
      albumTitle = null;
    }

    albumTitle = FunkinSprite.createSparrow(925, 500, assetKey);
    albumTitle.visible = albumTitle.frames != null && newAlbumArt.visible;
    albumTitle.animation.addByPrefix('idle', 'idle0', 24, true);
    albumTitle.animation.addByPrefix('switch', 'switch0', 24, false);
    add(albumTitle);

    albumTitle.animation.finishCallback = (function(name) {
      if (name == 'switch') albumTitle.animation.play('idle');
    });
    albumTitle.animation.play('idle');

    albumTitle.zIndex = 1000;

    if (_exitMovers != null) _exitMovers.set([albumTitle],
      {
        x: FlxG.width,
        speed: 0.4,
        wait: 0
      });

    if (_exitMoversCharSel != null) _exitMoversCharSel.set([albumTitle],
      {
        y: -190,
        speed: 0.8,
        wait: 0.1
      });
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
