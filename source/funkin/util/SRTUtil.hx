package funkin.util;

import flixel.math.FlxMath;
import flixel.util.FlxStringUtil;

using StringTools;

class SubtitleEntry
{
  public var id:Int;
  public var start:Float; // ms
  public var end:Float; // ms
  public var text:String;

  public function new(number:Int = 0, start:Float = 0, end:Float = 0, text:String = "")
  {
    this.id = number;
    this.start = start;
    this.end = end;
    this.text = text;
  }

  public function toString():String
  {
    return FlxStringUtil.getDebugString([
      LabelValuePair.weak("index", id),
      LabelValuePair.weak("range", [start, end]),
      LabelValuePair.weak("text", text)
    ]);
  }
}

class SRTParser
{
  /**
   * If true, replaces all `{` and `}` in subtitle text with `<` and `>`.
   * @default `true`
   */
  public static var convertBracesToAngles:Bool = true;

  /**
   * Parse SRT content from a raw string
   */
  public static function parseFromString(s:String):Array<SubtitleEntry>
  {
    if (s == null) return [];
    // normalize newlines
    var normalized = s.replace("\r\n", "\n").replace("\r", "\n");
    // strip BOM if present (this fixes the case when the very first line contains invisible U+FEFF)
    if (normalized.length > 0 && normalized.charCodeAt(0) == 0xFEFF) normalized = normalized.substr(1);

    // split by double newlines
    final blocks = normalized.split("\n\n");
    final out:Array<SubtitleEntry> = [];

    var _timmed = null;
    var _lines = null;

    for (block in blocks)
    {
      _timmed = block.trim();
      if (_timmed.length == 0) continue;
      _lines = _timmed.split("\n");

      var idx = 0;
      var number = 0;
      var timeLine:String = null;

      if (_lines.length > 0 && SubtitleUtils.isNumeric(_lines[0]))
      {
        number = Std.parseInt(_lines[0]);
        idx = 1;
      }
      if (idx < _lines.length)
      {
        timeLine = _lines[idx];
        idx++;
      }
      if (timeLine == null) continue;

      var times = SRTParser.parseTimeLine(timeLine);
      if (times == null) continue;

      var textLines = _lines.slice(idx, _lines.length);
      var text = textLines.join("\n");

      if (convertBracesToAngles)
      {
        text = text.replace("{", "<").replace("}", ">");
      }

      out.push(new SubtitleEntry(number, times.start, times.end, text));

      _lines = null;
    }

    out.sort(SubtitleUtils.sortLines);
    return out;
  }

  public static function parseFromFile(name:String, ?library:String, ?dir:String):Array<SubtitleEntry>
  {
    var rawSRTData:String = "";
    try
      rawSRTData = funkin.Assets.getText(Paths.srt(name, library, dir))
    catch (e)
      trace(e);

    return SRTParser.parseFromString(rawSRTData);
  }

  /**
   * Parse line like: 00:01:23,456 --> 00:01:25,678
   */
  static final timeArrowPatterns = ["-->", "->", "—>", "–>"];

  public static function parseTimeLine(line:String):{start:Float, end:Float}
  {
    var left:String = null;
    var right:String = null;

    for (a in timeArrowPatterns)
    {
      var parts = line.split(a);
      if (parts.length == 2)
      {
        left = parts[0].trim();
        right = parts[1].trim();
        break;
      }
    }

    if (left == null || right == null) return null;
    var s = parseTimecode(left);
    var e = parseTimecode(right);

    if (s < 0 || e < 0) return null;
    return {start: s, end: e};
  }

  /**
   *  Parse a single timecode like 01:02:03,456 or 01:02:03.456
   */
  public static function parseTimecode(t:String):Float
  {
    var clean = t.trim().replace(",", ".");
    var parts = clean.split(":");
    if (parts.length != 3) throw "Invalid timecode: " + t;
    var hh = Std.parseInt(parts[0]);
    var mm = Std.parseInt(parts[1]);
    var ssf = parts[2];
    var secParts = ssf.split(".");
    var ss = Std.parseInt(secParts[0]);
    var ms = 0;
    if (secParts.length > 1)
    {
      var frac = secParts[1];
      if (frac.length > 3) frac = frac.substr(0, 3);
      while (frac.length < 3)
        frac += "0";
      ms = Std.parseInt(frac);
    }
    return (hh * 3600 + mm * 60 + ss + (ms / 1000.0)) * 1000;
  }
}

/**
 * Utility helpers for using subtitles at runtime
 */
class SubtitleUtils
{
  /**
   * Finds subtitle entry for the current time.
   */
  public static function findActive(list:Array<SubtitleEntry>, time:Float):SubtitleEntry
  {
    for (s in list)
    {
      if (time >= s.start && time <= s.end) return s;
    }
    return null;
  }

  /**
   * Finds subtitle entry id for the current time.
   */
  public static function findActiveIndex(list:Array<SubtitleEntry>, time:Float):Int
  {
    var lo = 0;
    var hi = list.length - 1;
    while (lo <= hi)
    {
      var mid = (lo + hi) >> 1;
      var s = list[mid];
      if (time < s.start) hi = mid - 1;
      else if (time > s.end) lo = mid + 1;
      else
        return mid;
    }
    return -1;
  }

  public static function isNumeric(s:String):Bool
  {
    if (s == null) return false;
    var t = s.trim();
    if (t.length == 0) return false;
    for (i in 0...t.length)
    {
      var code = t.charCodeAt(i);
      if (code < '0'.code || code > '9'.code) return false;
    }
    return true;
  }

  /**
   * Sort lines by their id.
   */
  public static function sortLines(line1:SubtitleEntry, line2:SubtitleEntry):Int
  {
    return FlxMath.numericComparison(line1.id, line2.id);
  }
}
