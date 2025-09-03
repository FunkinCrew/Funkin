package funkin.ui.freeplay;

import funkin.graphics.shaders.HSVShader;
import funkin.ui.freeplay.FreeplayState.FreeplaySongData;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.util.FlxSignal.FlxTypedSignal;

/**
 * The song card group taken from P-Slice 3.3 (with some tweaks)
 *
 * Let's you manage currently active song cards,
 * while improving the recycling process for them
 * (by assigning dead cards to a corresponding song whethever possible)
 *
 * **DO NOT use "members" property of this class!** Use 'activeSongItems' instead.
 */
@:access(funkin.ui.freeplay.SongMenuItem)
@:nullSafety
class SongCapsuleGroup extends FlxTypedGroup<SongMenuItem>
{
  /**
   * Signal invoked when the "Random" song gets selected
   */
  public final onRandomSelected:FlxTypedSignal<SongMenuItem->Void> = new FlxTypedSignal<SongMenuItem->Void>();

  /**
   * Signal called when a song is selected
   */
  public final onSongSelected:FlxTypedSignal<SongMenuItem->Void> = new FlxTypedSignal<SongMenuItem->Void>();

  /**
   * A list of the song cards currently being displayed by the group.
   * Does not include any killed/dead cards and also keeps track of the song card order.
   */
  public final activeSongItems:Array<SongMenuItem> = [];

  final randomCapsule:SongMenuItem;
  var styleData:Null<FreeplayStyle>;

  public function new(?styleData:Null<FreeplayStyle>)
  {
    super();
    this.styleData = styleData;
    randomCapsule = new SongMenuItem(0, 0);
    randomCapsule.onConfirm = function() {
      onRandomSelected.dispatch(randomCapsule);
    };
    add(randomCapsule);
  }

  /**
   * Rebuilds the song list with provided songList.
   * Where possible, attempts to either reuse, or recycle any dead song cards in the pool.
   *
   * It also automatically animates them to "JumpIn" into the freeplay.
   * @param songList A list songs to generate cards for
   * @param noJumpIn If true, disables the "JumpIn" animation
   * @param force Used by the animation
   */
  public function generateFullSongList(songList:Array<Null<FreeplaySongData>>, noJumpIn:Bool = false, force:Bool = false):Void
  {
    for (cap in members)
    {
      if (cap.freeplayData == null) continue; // Exclude "Random" card from cleanup
      cap.kill();
    }

    activeSongItems.resize(0);
    var recycledSongCards:Map<FreeplaySongData, Null<SongMenuItem>> = findSongItems(songList);
    var hsvShader:HSVShader = new HSVShader();

    randomCapsule.initRandom(styleData);
    randomCapsule.hsvShader = hsvShader;
    if (noJumpIn) randomCapsule.forcePosition();
    else
    {
      randomCapsule.initJumpIn(0, force);
    }

    activeSongItems.push(randomCapsule);
    add(randomCapsule);

    for (i in 0...songList.length)
    {
      var tempSong:Null<FreeplaySongData> = songList[i];
      if (tempSong == null) continue;

      var funnyMenu:Null<SongMenuItem> = recycledSongCards.get(tempSong);
      if (funnyMenu == null)
      {
        funnyMenu = recycle(SongMenuItem, () -> {
          return new SongMenuItem(0, 0, styleData);
        });

        funnyMenu.initData(tempSong, styleData);
        funnyMenu.onConfirm = function() {
          onSongSelected.dispatch(funnyMenu);
        };
        // This actually protects from adding the card twice!
        add(funnyMenu);
      }
      else
      {
        funnyMenu.updateScoringRank(tempSong?.scoringRank);
        funnyMenu.updateFavAnim();
      }
      funnyMenu.initPosition(FlxG.width, 0);
      funnyMenu.index = i + 1;

      funnyMenu.targetPos.x = funnyMenu.x;
      funnyMenu.y = funnyMenu.intendedY(i + 1) + 10;
      funnyMenu.ID = i;
      funnyMenu.capsule.alpha = 0.5;
      funnyMenu.hsvShader = hsvShader;
      funnyMenu.newText.animation.curAnim.curFrame = 45 - ((i * 4) % 45);
      funnyMenu.checkClip();

      if (noJumpIn) funnyMenu.forcePosition();
      else
        funnyMenu.initJumpIn(0, force);

      activeSongItems.push(funnyMenu);
    }
  }

  /**
   * Given the song data list, searches for corresponding dead cards.
   * Such cards will have most elements already set (like song name and charIcon),
   * but will need to be refreshed with to update difficulty data.
   * @return A map of found song cards. If a card for the given song wasn't found, then there won't be a corresponding key in the map!
   */
  function findSongItems(songData:Array<Null<FreeplaySongData>>):Map<FreeplaySongData, Null<SongMenuItem>>
  {
    var foundSongItem:Map<FreeplaySongData, Null<SongMenuItem>> = new Map<FreeplaySongData, Null<SongMenuItem>>();
    forEachDead(tomb -> {
      if (tomb.freeplayData == null) return;

      if (songData.contains(tomb.freeplayData) && !foundSongItem.exists(tomb.freeplayData))
      {
        tomb.revive();
        foundSongItem.set(tomb.freeplayData, tomb);
      }
    });
    return foundSongItem;
  }
}
