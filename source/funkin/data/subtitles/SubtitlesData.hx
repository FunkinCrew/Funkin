package funkin.data.subtitles;

import funkin.util.SRTUtil.SubtitleEntry;

class SubtitlesData
{
  public var data:Array<SubtitleEntry>;

  public function new(data:Array<SubtitleEntry>)
  {
    this.data = data;
  }

  public function toFileString():String
  {
    var string:String = '';
    for (index in 0...data.length - 1)
    {
      string += data[index].toFileString();
    }
    return string;
  }
}
