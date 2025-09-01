package funkin.ui.freeplay;

import funkin.graphics.shaders.HSVShader;
import funkin.ui.freeplay.FreeplayState.FreeplaySongData;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.util.FlxSignal.FlxTypedSignal;

@:access(funkin.ui.freeplay.SongMenuItem)
class SongCapsuleGroup extends FlxTypedGroup<SongMenuItem>
{
  public final onRandomSelected:FlxTypedSignal<SongMenuItem->Void> = new FlxTypedSignal<SongMenuItem->Void>();
  public final onSongSelected:FlxTypedSignal<SongMenuItem->Void> = new FlxTypedSignal<SongMenuItem->Void>();

  /**
   * A list of the song cards currently being displayed by the group.
   * Does not include any killed/dead cards and keeps track of their order.
   */
  public final activeSongItems:Array<SongMenuItem> = new Array<SongMenuItem>();

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
   * Rebuilds the song list with the songs provided.
   * Where possible, attempte to either reuse or recycle any dead song cards in the pool.
   * @param songList
   * @param currentDifficulty
   * @param fromCharSelect
   * @param noJumpIn
   * @param force
   */
  public function generateFullSongList(songList:Array<Null<FreeplaySongData>>, currentDifficulty:String, fromCharSelect:Bool = false, noJumpIn:Bool = false,
      force:Bool = false):Void
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
    if (fromCharSelect || noJumpIn) randomCapsule.forcePosition();
    else
    {
      randomCapsule.initJumpIn(0, force);
    }

    activeSongItems.push(randomCapsule);
    add(randomCapsule);

    for (i in 0...songList.length)
    {
      var tempSong = songList[i];
      if (tempSong == null) continue;

      // // ? Update difficulty as part of difficulty change action (when used by the ChangeDiff method)
      // tempSong.currentDifficulty = currentDifficulty;

      var funnyMenu:SongMenuItem = recycledSongCards.get(tempSong);
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

      funnyMenu.targetPos.x = funnyMenu.x; // This is target position on X
      funnyMenu.y = funnyMenu.intendedY(i + 1) + 10;
      funnyMenu.ID = i;
      funnyMenu.capsule.alpha = 0.5;
      funnyMenu.hsvShader = hsvShader;
      funnyMenu.newText.animation.curAnim.curFrame = 45 - ((i * 4) % 45);
      funnyMenu.checkClip();

      if (fromCharSelect || noJumpIn) funnyMenu.forcePosition();
      else
        funnyMenu.initJumpIn(0, force);

      activeSongItems.push(funnyMenu);
    }
  }

  /**
   * Given the song data list, searches for corresponding dead cards.
   * Such cards will have most elements reads (like song name and charIcon),
   * but will need to be refreshed with "refreshDisplayDifficulty" to update difficulty data.
   * @return A map of found song cards. If a cord for a given song wasn't found, there won't be a corresponding key in the map!
   */
  function findSongItems(songData:Array<FreeplaySongData>):Map<FreeplaySongData, Null<SongMenuItem>>
  {
    var foundSongItem = new Map<FreeplaySongData, Null<SongMenuItem>>();
    forEachDead(tomb -> {
      if (songData.contains(tomb.freeplayData) && !foundSongItem.exists(tomb.freeplayData))
      {
        tomb.revive();
        foundSongItem.set(tomb.freeplayData, tomb);
      }
    });
    return foundSongItem;
  }
}
