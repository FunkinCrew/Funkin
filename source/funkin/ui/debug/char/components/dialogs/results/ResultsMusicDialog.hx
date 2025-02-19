package funkin.ui.debug.char.components.dialogs.results;

import funkin.data.freeplay.player.PlayerRegistry;
import funkin.play.scoring.Scoring.ScoringRank;
import funkin.ui.debug.char.pages.CharCreatorResultsPage;
import funkin.util.FileUtil;
import haxe.ui.events.UIEvent;
import haxe.io.Path;

@:build(haxe.ui.macros.ComponentMacros.build("assets/exclude/data/ui/char-creator/dialogs/results/results-music-dialog.xml"))
@:access(funkin.ui.debug.char.pages.CharCreatorResultsPage)
class ResultsMusicDialog extends DefaultPageDialog
{
  public var musicStuff:Map<ScoringRank, {intro:WizardFile, song:WizardFile}> = [];

  override public function new(daPage:CharCreatorResultsPage)
  {
    super(daPage);

    var charId = daPage.data.importedPlayerData ?? "";
    var currentChar = PlayerRegistry.instance.fetchEntry(charId);
    for (rank in CharCreatorResultsPage.ALL_RANKS)
    {
      var musKey = currentChar?.getResultsMusicPath(rank) ?? 'resultsNORMAL';

      var introPath = Paths.music('$musKey/$musKey-intro');
      var intro:WizardFile =
        {
          name: '$musKey-intro',
          bytes: Assets.exists(introPath) ? Assets.getBytes(introPath) : null
        };
      var song:WizardFile = {name: '$musKey', bytes: Assets.getBytes(Paths.music('$musKey/$musKey'))};

      musicStuff.set(rank, {intro: intro, song: song});
    }

    rankMusicDrop.selectedIndex = 0;
    rankMusicDrop.onChange = function(_) {
      var daRank = daPage.getRankFromString(rankMusicDrop.safeSelectedItem.text);

      rankMusicFrame.pauseEvent(UIEvent.CHANGE, true);

      rankMusicIntroField.text = musicStuff[daRank].intro?.name ?? "";
      rankMusicSongField.text = musicStuff[daRank].song.name;

      rankMusicFrame.resumeEvent(UIEvent.CHANGE, true, true);
    }

    rankMusicIntroField.onChange = rankMusicSongField.onChange = function(_) {
      daPage.setStatusOfEverything(false);

      var daRank = daPage.getRankFromString(rankMusicDrop.safeSelectedItem.text);
      daPage.rankMusicMap[daRank].destroy();

      // bytes check!
      var introBytes:haxe.io.Bytes = null;
      var songBytes:haxe.io.Bytes = null;

      if (Path.isAbsolute(rankMusicIntroField.text) != Path.isAbsolute(rankMusicSongField.text)
        && (rankMusicIntroField.text.length > 0 && rankMusicSongField.text.length > 0))
      {
        CharCreatorUtil.error("Rank Music", "Paths of the Rank Music but be of the same Type.");
        return;
      }

      if (Path.isAbsolute(rankMusicIntroField.text) || Path.isAbsolute(rankMusicSongField.text))
      {
        if ((rankMusicIntroField.text.length > 0 && Path.extension(rankMusicIntroField.text) != Constants.EXT_SOUND)
          || (rankMusicSongField.text.length > 0 && Path.extension(rankMusicSongField.text) != Constants.EXT_SOUND))
        {
          CharCreatorUtil.error("Rank Music", "Rank Music should have an extension of " + Constants.EXT_SOUND + ".");
          return;
        }

        var introFile:WizardFile = {name: rankMusicIntroField.text, bytes: FileUtil.readBytesFromPath(rankMusicIntroField.text)}
        var musicFile:WizardFile = {name: rankMusicSongField.text, bytes: FileUtil.readBytesFromPath(rankMusicSongField.text)}

        introBytes = introFile.bytes;
        songBytes = musicFile.bytes;

        musicStuff.set(daRank, {intro: introFile, song: musicFile});
      }
      else
      {
        if (rankMusicIntroField.text.length > 0 && rankMusicIntroField.text != rankMusicSongField.text + "-intro")
        {
          CharCreatorUtil.error("Rank Music", "Rank Intro Music Path should be " + rankMusicSongField.text + "-intro, or none if it doesn't exist.");
          return;
        }

        var musKey = rankMusicSongField.text;
        var fullIntroPath = Paths.music('$musKey/$musKey-intro');
        var fullPath = Paths.music('$musKey/$musKey');

        var introFile:WizardFile = {name: rankMusicIntroField.text, bytes: Assets.exists(fullIntroPath) ? Assets.getBytes(fullIntroPath) : null}
        var musicFile:WizardFile = {name: rankMusicSongField.text, bytes: Assets.exists(fullPath) ? Assets.getBytes(fullPath) : null}

        introBytes = introFile.bytes;
        songBytes = musicFile.bytes;

        musicStuff.set(daRank, {intro: introFile, song: musicFile});
      }

      daPage.rankMusicMap[daRank].reloadSoundsFromBytes(songBytes, introBytes);
    }

    rankMusicIntroLoad.onClick = function(_) {
      FileUtil.browseForBinaryFile("Load Sound File", [FileUtil.FILE_EXTENSION_INFO_SND], function(_) {
        if (_?.fullPath == null) return;
        rankMusicIntroField.text = _.fullPath;
      });
    }

    rankMusicSongLoad.onClick = function(_) {
      FileUtil.browseForBinaryFile("Load Sound File", [FileUtil.FILE_EXTENSION_INFO_SND], function(_) {
        if (_?.fullPath == null) return;
        rankMusicSongField.text = _.fullPath;
      });
    }
  }
}
