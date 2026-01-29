package funkin.ui.debug.charting.util;

import funkin.data.song.SongData.SongMetadata;
import funkin.data.song.SongData.SongChartData;
import funkin.data.song.importer.ChartManifestData;
import haxe.io.Bytes;

typedef FNFCData =
{
  var songMetadatas:Map<String, SongMetadata>;
  var songChartDatas:Map<String, SongChartData>;
  var manifest:ChartManifestData;
  var instrumentals:Map<String, Bytes>;
  var vocals:Map<String, Bytes>;
}
