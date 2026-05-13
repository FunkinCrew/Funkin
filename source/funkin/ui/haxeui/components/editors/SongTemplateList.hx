package funkin.ui.haxeui.components.editors;

#if (FEATURE_CHART_EDITOR || FEATURE_CAMERA_EDITOR)
import funkin.data.song.SongRegistry;
import funkin.play.song.Song;
import funkin.util.SortUtil;
import haxe.ui.components.Link;
import haxe.ui.containers.ScrollView;

/**
 * Scrollable, alphabetically-sorted list of every `SongRegistry` entry, used by the
 * Chart Editor and Camera Editor welcome dialogs. Consumers call `populate()` once,
 * passing the `onSelectSong` callback that fires when the user clicks a row.
 */
@:xml('
<scrollview width="100%" height="100%" contentWidth="100%">
  <vbox width="100%" id="songListVBox" />
</scrollview>
')
class SongTemplateList extends ScrollView
{
  public function new()
  {
    super();
  }

  /**
   * Repopulate the list. Clears any existing entries first, so it's safe to call more than once.
   *
   * @param onSelectSong Invoked with the song ID when the user clicks an entry.
   */
  public function populate(onSelectSong:(songId:String) -> Void):Void
  {
    songListVBox.removeAllComponents();

    var songList:Array<String> = SongRegistry.instance.listEntryIds();
    songList.sort(SortUtil.alphabetically);

    for (targetSongId in songList)
    {
      var songData:Null<Song> = SongRegistry.instance.fetchEntry(targetSongId, {variation: Constants.DEFAULT_VARIATION});
      if (songData == null) continue;

      var songName:Null<String> = songData.getDifficulty('normal')?.songName;
      if (songName == null) songName = songData.getDifficulty()?.songName;
      if (songName == null)
      {
        trace(' WARNING '.warning() + ' Could not fetch song name for ${targetSongId}');
        continue;
      }

      addSongLink(songName, targetSongId, onSelectSong);
    }
  }

  function addSongLink(songName:String, songId:String, onSelectSong:(songId:String) -> Void):Void
  {
    var link:Link = new Link();
    link.text = songName;
    link.onClick = (_) -> onSelectSong(songId);
    songListVBox.addComponent(link);
  }
}
#end
