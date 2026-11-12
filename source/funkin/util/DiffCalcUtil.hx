package funkin.util;

import funkin.data.song.SongData.SongNoteData;

/**
 * Estimates a chart's difficulty rating based on the player's notes.
 *
 * This includes:
 * - Chords
 * - Irregular hits
 * - Jacks
 * - Rhythm changes
 * - Anchors
 * - % of the chart previewed
 * - Scroll speed
 *
 * Strain is calculated based on these factors, and the overall difficulty rating is derived from the total strain.
 */
class DiffCalcUtil
{
  /**
   * Notes this close together, in milliseconds, are one chord.
   */
  static final CHORD_MS:Float = 5;

  /**
   * Gaps shorter than this, in milliseconds, count as this long.
   */
  static final MIN_GAP_MS:Float = 30;

  /**
   * How many of the latest gaps the speed is averaged over.
   */
  static final SPEED_WINDOW:Int = 4;

  /**
   * A gap at least this long, in milliseconds, is a rest.
   */
  static final REST_MS:Float = 250.4555;

  /**
   * Extra strain for a hit that breaks the pattern.
   */
  static final IRREGULAR_WEIGHT:Float = 1.3883;

  /**
   * Extra strain per additional note in a chord.
   */
  static final CHORD_WEIGHT:Float = 0.0106;

  /**
   * The hits per second where a chord counts fully.
   */
  static final CHORD_FULL_SPEED:Float = 2.5266;

  /**
   * Extra strain for more notes in a chord.
   */
  static final CHORD_FLAT_WEIGHT:Float = 1.6427;

  /**
   * Strain from hitting the same lane again soon.
   */
  static final JACK_WEIGHT:Float = 1.3778;

  /**
   * How much strain is left after a second.
   */
  static final DECAY_PER_SECOND:Float = 0.4915;

  /**
   * The length of the stretches the strain is sampled over.
   */
  static final SECTION_MS:Float = 500;

  /**
   * How much each next hardest stretch counts compared to the one before, for the hardest parts of the song.
   */
  static final SECTION_FALLOFF:Float = 0.8995;

  /**
   * The same, for the song as a whole, where almost every stretch counts.
   */
  static final WHOLE_SONG_FALLOFF:Float = 0.9963;

  /**
   * How much the whole song counts toward the strain, the rest being its hardest parts.
   */
  static final WHOLE_SONG_SHARE:Float = 0.4911;

  /**
   * Extra strain for a hit whose timing breaks the rhythm, instead of repeating one of the last few gaps.
   */
  static final RHYTHM_WEIGHT:Float = 4.4438;

  /**
   * How close two gaps have to be, as a share of the gap, to count as the same rhythm.
   */
  static final RHYTHM_TOLERANCE:Float = 0.12;

  /**
   * Gaps this long or longer, in milliseconds, don't count toward rhythm changes.
   */
  static final RHYTHM_MAX_GAP_MS:Float = 400;

  /**
   * Extra strain for an anchor, where a lane comes back every other hit while the hits between it change.
   */
  static final ANCHOR_WEIGHT:Float = 1.1507;

  /**
   * The hits per second where an anchor counts fully.
   */
  static final ANCHOR_FULL_SPEED:Float = 10.875;

  /**
   * Extra strain from how fast the anchored lane itself is hit.
   */
  static final ANCHOR_JACK_WEIGHT:Float = 0.1409;

  /**
   * How much an anchor counts as a pattern break.
   */
  static final ANCHOR_BREAK:Float = 0.4056;

  /**
   * How much less strain a hit adds when the opponent already played it the same way.
   */
  static final PREVIEW_DISCOUNT:Float = 0.2064;

  /**
   * How many hits before each one have to match the opponent too.
   */
  static final PREVIEW_HITS:Int = 4;

  /**
   * How long before, in milliseconds, the opponent's notes can count as showing the player's.
   */
  static final PREVIEW_MIN_MS:Float = 400;
  static final PREVIEW_MAX_MS:Float = 20000;

  /**
   * How close, in milliseconds, the opponent's hit has to line up to count as the same.
   */
  static final PREVIEW_TOLERANCE_MS:Float = 12;

  /**
   * Songs where the opponent's strumline is hidden, so nothing is shown before the player's turn.
   */
  static final HIDDEN_OPPONENT_SONGS:Array<String> = ['blazin'];

  /**
   * Scroll speeds above this make notes harder to read, and add to the rating.
   */
  static final SCROLL_SPEED_START:Float = 2.4;

  static final RATING_PER_SCROLL_SPEED:Float = 2.209;

  // The rating is a curve over the natural log of the strain, fitted to the base game's charts as rated by my own FUCKING HANDS.
  static final RATING_SQUARED:Float = 1.2299;
  static final RATING_LINEAR:Float = -8.1064;
  static final RATING_CONSTANT:Float = 14.2862;

  /**
   * Work out how much strain the player's notes in a chart add up to.
   * @param notes Every note in the chart.
   * @param opponentShown Whether the opponent's notes are on screen. See `opponentShownFor`.
   * @return The strain, or `null` if there are fewer than two player notes.
   */
  public static function strain(notes:Array<SongNoteData>, opponentShown:Bool = true):Null<Float>
  {
    var sections:Null<Array<DiffCalcSection>> = sectionStrains(notes, null, null, opponentShown);
    if (sections == null || sections.length == 0) return null;

    var values:Array<Float> = [for (section in sections) section.strain];
    values.sort((a, b) -> a > b ? -1 : (a < b ? 1 : 0));
    return WHOLE_SONG_SHARE * falloffAverage(values, WHOLE_SONG_FALLOFF) + (1 - WHOLE_SONG_SHARE) * falloffAverage(values, SECTION_FALLOFF);
  }

  /**
   * Average strains sorted hardest first.
   */
  static function falloffAverage(values:Array<Float>, falloff:Float):Float
  {
    var total:Float = 0;
    var weightTotal:Float = 0;
    var weight:Float = 1;
    for (value in values)
    {
      total += value * weight;
      weightTotal += weight;
      weight *= falloff;
    }
    return total / weightTotal;
  }

  /**
   * Whether a song shows the opponent's notes.
   */
  public static function opponentShownFor(songId:Null<String>):Bool
  {
    return songId == null || !HIDDEN_OPPONENT_SONGS.contains(songId);
  }

  /**
   * The strain at every stretch of the chart that has player notes, and what added the most to it.
   * @param notes Every note in the chart. Only the player's lanes (0 to 3) count.
   * @param stretchOf Which stretch a time falls in. Half seconds if left out.
   * @param stretchStart When a stretch starts, in milliseconds. Must match `stretchOf`.
   * @param opponentShown Whether the opponent's notes are on screen. See `opponentShownFor`.
   * @return The stretches in time order, or `null` if there are fewer than two player notes.
   */
  public static function sectionStrains(notes:Array<SongNoteData>, ?stretchOf:Float->Int, ?stretchStart:Int->Float,
      opponentShown:Bool = true):Null<Array<DiffCalcSection>>
  {
    if (stretchOf == null || stretchStart == null)
    {
      stretchOf = time -> Math.floor(time / SECTION_MS);
      stretchStart = index -> index * SECTION_MS;
    }

    var player:Array<SongNoteData> = [for (note in notes) if (note.data >= 0 && note.data < 4) note];
    if (player.length < 2) return null;
    player.sort((a, b) -> a.time < b.time ? -1 : (a.time > b.time ? 1 : 0));

    // Group notes into hits, each with a bit per lane.
    var hitTimes:Array<Float> = [];
    var hitLanes:Array<Int> = [];
    for (note in player)
    {
      var last:Int = hitTimes.length - 1;
      if (last >= 0 && note.time - hitTimes[last] <= CHORD_MS) hitLanes[last] |= 1 << note.data;
      else
      {
        hitTimes.push(note.time);
        hitLanes.push(1 << note.data);
      }
    }

    var previews:Null<Array<Float>> = opponentShown ? previewShares(hitTimes, hitLanes, notes) : null;

    var lastInLane:Array<Float> = [Math.NEGATIVE_INFINITY, Math.NEGATIVE_INFINITY, Math.NEGATIVE_INFINITY, Math.NEGATIVE_INFINITY];
    var gaps:Array<Float> = [];
    var rhythmGaps:Array<Float> = [];
    var current:Float = 0;
    var sections:Map<Int, DiffCalcSection> = [];
    var order:Array<Int> = [];

    for (i in 0...hitTimes.length)
    {
      var time:Float = hitTimes[i];
      var lanes:Int = hitLanes[i];

      var gap:Float = i > 0 ? time - hitTimes[i - 1] : Math.POSITIVE_INFINITY;
      if (gap > REST_MS) gaps.resize(0);
      gaps.push(Math.max(MIN_GAP_MS, Math.min(gap, REST_MS)));
      if (gaps.length > SPEED_WINDOW) gaps.shift();
      var gapSum:Float = 0;
      for (g in gaps) gapSum += g;
      var speed:Float = 1000 / (gapSum / gaps.length);

      var jack:Float = 0;
      var noteCount:Int = 0;
      for (lane in 0...4)
      {
        if (lanes & (1 << lane) == 0) continue;
        noteCount++;
        jack = Math.max(jack, 1000 / Math.max(MIN_GAP_MS, time - lastInLane[lane]));
      }

      var isAnchor:Bool = i >= 3 && lanes == hitLanes[i - 2] && hitLanes[i - 1] != hitLanes[i - 3];
      var irregular:Float = repeatsPattern(hitLanes, i) ? 0 : 1;
      if (isAnchor) irregular = Math.max(irregular, ANCHOR_BREAK);

      rhythmGaps.push(gap);
      var rhythm:Float = 0;
      if (rhythmGaps.length >= 3 && gap < RHYTHM_MAX_GAP_MS)
      {
        rhythm = 1;
        var back:Int = Std.int(Math.min(5, rhythmGaps.length));
        for (p in 1...back)
        {
          if (Math.abs(gap - rhythmGaps[rhythmGaps.length - 1 - p]) <= RHYTHM_TOLERANCE * gap)
          {
            rhythm = 0;
            break;
          }
        }
      }
      var chord:Float = (noteCount - 1) * CHORD_WEIGHT * Math.min(1, speed / CHORD_FULL_SPEED);

      var anchor:Float = isAnchor ? Math.min(1, speed / ANCHOR_FULL_SPEED) : 0;

      // Each part of the strain this hit adds, in the order of `DiffCalcCause`.
      var parts:Array<Float> = [
        speed * (1 + ANCHOR_WEIGHT * anchor),
        speed * IRREGULAR_WEIGHT * irregular,
        speed * RHYTHM_WEIGHT * rhythm,
        speed * chord + (noteCount - 1) * CHORD_FLAT_WEIGHT,
        JACK_WEIGHT * jack + (isAnchor ? ANCHOR_JACK_WEIGHT * jack : 0)
      ];
      if (previews != null)
      {
        var kept:Float = 1 - PREVIEW_DISCOUNT * previews[i];
        for (c in 0...parts.length) parts[c] *= kept;
      }
      var added:Float = 0;
      for (part in parts) added += part;

      if (i > 0) current *= Math.pow(DECAY_PER_SECOND, gap / 1000);
      current += added;

      var index:Int = stretchOf(time);
      var section:Null<DiffCalcSection> = sections.get(index);
      if (section == null)
      {
        section = {time: stretchStart(index), end: stretchStart(index + 1), strain: 0, causes: [0, 0, 0, 0, 0]};
        sections.set(index, section);
        order.push(index);
      }
      if (current > section.strain) section.strain = current;
      for (c in 0...parts.length) section.causes[c] += parts[c];

      for (lane in 0...4) if (lanes & (1 << lane) != 0) lastInLane[lane] = time;
    }

    return [for (index in order) sections.get(index)];
  }

  /**
   * How much of each player hit the opponent already played the same way before it, from 0 to 1.
   */
  static function previewShares(hitTimes:Array<Float>, hitLanes:Array<Int>, notes:Array<SongNoteData>):Array<Float>
  {
    var opponent:Array<SongNoteData> = [for (note in notes) if (note.data >= 4 && note.data < 8) note];
    opponent.sort((a, b) -> a.time < b.time ? -1 : (a.time > b.time ? 1 : 0));
    var opponentTimes:Array<Float> = [];
    var opponentLanes:Array<Int> = [];
    for (note in opponent)
    {
      var last:Int = opponentTimes.length - 1;
      if (last >= 0 && note.time - opponentTimes[last] <= CHORD_MS) opponentLanes[last] |= 1 << (note.data - 4);
      else
      {
        opponentTimes.push(note.time);
        opponentLanes.push(1 << (note.data - 4));
      }
    }

    var shares:Array<Float> = [];
    for (i in 0...hitTimes.length)
    {
      var time:Float = hitTimes[i];
      var lanes:Int = hitLanes[i];
      var best:Float = 0;
      var tried:Map<Int, Bool> = [];
      var k:Int = firstAtOrAfter(opponentTimes, time - PREVIEW_MAX_MS);
      while (k < opponentTimes.length && opponentTimes[k] <= time - PREVIEW_MIN_MS && best < 1)
      {
        if (opponentLanes[k] == lanes)
        {
          var offset:Int = Math.round(time - opponentTimes[k]);
          if (!tried.exists(offset))
          {
            tried.set(offset, true);
            var first:Int = Std.int(Math.max(0, i - PREVIEW_HITS));
            var matched:Int = 1;
            for (j in first...i)
            {
              if (opponentHitAt(opponentTimes, opponentLanes, hitTimes[j] - offset, hitLanes[j])) matched++;
            }
            best = Math.max(best, matched / (1 + i - first));
          }
        }
        k++;
      }
      shares.push(best);
    }
    return shares;
  }

  /**
   * Whether the opponent hit these lanes at about this time.
   */
  static function opponentHitAt(times:Array<Float>, lanes:Array<Int>, time:Float, wanted:Int):Bool
  {
    var k:Int = firstAtOrAfter(times, time - PREVIEW_TOLERANCE_MS);
    while (k < times.length && times[k] <= time + PREVIEW_TOLERANCE_MS)
    {
      if (lanes[k] == wanted) return true;
      k++;
    }
    return false;
  }

  /**
   * The index of the first sorted time at or after a value.
   */
  static function firstAtOrAfter(times:Array<Float>, value:Float):Int
  {
    var low:Int = 0;
    var high:Int = times.length;
    while (low < high)
    {
      var mid:Int = (low + high) >> 1;
      if (times[mid] < value) low = mid + 1;
      else
        high = mid;
    }
    return low;
  }

  /**
   * Whether a hit repeats the hits 2, 3 or 4 before it.
   */
  static function repeatsPattern(hitLanes:Array<Int>, index:Int):Bool
  {
    var lanes:Int = hitLanes[index];
    for (period in 2...5)
    {
      if (index < period || hitLanes[index - period] != lanes) continue;
      if (index < period * 2 || hitLanes[index - period * 2] == lanes) return true;
    }
    return false;
  }

  /**
   * Estimate a chart's Freeplay rating from how hard its notes are.
   * @param notes Every note in the chart.
   * @param scrollSpeed The chart's scroll speed. Very fast scrolling makes notes harder to read.
   * @param opponentShown Whether the opponent's notes are on screen. See `opponentShownFor`.
   * @return The estimated rating, or `null` if there are fewer than two player notes.
   */
  public static function calculate(notes:Array<SongNoteData>, scrollSpeed:Float = 1, opponentShown:Bool = true):Null<Float>
  {
    var value:Null<Float> = strain(notes, opponentShown);
    if (value == null || value <= 0) return null;
    return strainToRating(value, scrollSpeed);
  }

  /**
   * Turn a strain into a rating.
   */
  public static function strainToRating(value:Float, scrollSpeed:Float = 1):Float
  {
    if (value <= 0) return 0;

    // The curve turns back up below its lowest point, so very light charts stop there.
    var lowest:Float = -RATING_LINEAR / (2 * RATING_SQUARED);
    var logStrain:Float = Math.max(lowest, Math.log(value));
    var rating:Float = RATING_SQUARED * logStrain * logStrain + RATING_LINEAR * logStrain + RATING_CONSTANT;
    rating += RATING_PER_SCROLL_SPEED * Math.max(0, scrollSpeed - SCROLL_SPEED_START);
    return Math.max(0, rating);
  }

  /**
   * What added the most strain to a stretch.
   */
  public static function mainCause(section:DiffCalcSection):DiffCalcCause
  {
    var best:Int = 0;
    var bestScore:Float = section.causes[0] * 0.5;
    for (c in 1...section.causes.length)
    {
      if (section.causes[c] > bestScore)
      {
        best = c;
        bestScore = section.causes[c];
      }
    }
    return switch (best)
    {
      case 1: PatternBreaks;
      case 2: RhythmChanges;
      case 3: Chords;
      case 4: Jacks;
      default: Speed;
    }
  }
}

/**
 * A section of a chart, representing a stretch of notes and their associated strain and causes.
 */
typedef DiffCalcSection =
{
  /**
   * When the stretch starts, in milliseconds.
   */
  var time:Float;

  /**
   * When the stretch ends, in milliseconds.
   */
  var end:Float;

  /**
   * The highest the strain got in the stretch.
   */
  var strain:Float;

  /**
   * How much each part added over the stretch, in the order of `DiffCalcCause`.
   */
  var causes:Array<Float>;
}

enum DiffCalcCause
{
  Speed;
  PatternBreaks;
  RhythmChanges;
  Chords;
  Jacks;
}
