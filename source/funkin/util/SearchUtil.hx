package funkin.util;

import haxe.ui.util.Color as HaxeUIColor;

/**
 * Utilities for searching, filtering, and fuzzy matching.
 *
 * A bunch of this is based on code from Visual Studio Code, which is licensed under the MIT license.
 * @see https://github.com/microsoft/vscode/blob/main/src/vs/base/common/fuzzyScorer.ts
 */
@:nullSafety
class SearchUtil
{
  static final NO_MATCH:Int = 0;

  /**
   * A score for no match.
   */
  public static final NO_SCORE:FuzzyScore = {
    score: NO_MATCH,
    matches: []
  };

  /**
   * Calculates a score that represents how much a given target matches a given query.
   *
   * @param target The target string to score against.
   * @param query The user's search string to match with.
   * @return The score of the match.
   */
  public static function scoreFuzzy(target:String, query:String, ?params:ScoreFuzzyParams):FuzzyScore
  {
    if (target == null || query == null) return NO_SCORE;

    if (target.length == 0 || target.length < query.length) return NO_SCORE;

    var allowNonContiguous:Bool = params?.allowNonContiguous ?? false;
    var allowPartial:Bool = params?.allowPartial ?? false;

    var scores:Array<Int> = [];
    var matches:Array<Int> = [];

    var targetLower:String = target.toLowerCase();
    var queryLower:String = query.toLowerCase();

    for (queryIndex in 0...query.length)
    {
      var queryChar:String = query.charAt(queryIndex);
      var queryCharLower:String = queryLower.charAt(queryIndex);

      for (targetIndex in 0...target.length)
      {
        var targetChar:String = target.charAt(targetIndex);
        var targetCharLower:String = targetLower.charAt(targetIndex);

        // Imagine a matrix, where each row represents how one character in the query matches the full text of the target.

        // Current query index
        var index:Int = (queryIndex * target.length) + targetIndex;
        // Index to the left of the current index
        var leftIndex:Int = index - 1;
        // Index to the left and above the current index
        var diagIndex:Int = leftIndex - target.length;

        var leftScore:Int = scores[leftIndex] ?? 0;
        var diagScore:Int = scores[diagIndex] ?? 0;
        var diagMatches:Int = matches[diagIndex] ?? 0;

        // If we are not matching the first query character anymore,
        // we only produce a score if the last query index had a score.
        var shouldContinueMatch:Bool = queryIndex == 0 || diagScore > 0;
        var score:Int = shouldContinueMatch ? scoreFuzzyCharacter(queryChar, queryCharLower, target, targetLower, targetIndex, diagMatches) : 0;

        var isValidScore:Bool = (score > 0) && (diagScore + score > leftScore);
        // Determine if we have a completely continuous match.
        var isContiguous:Bool = (queryIndex > 0) || targetLower.substr(targetIndex).startsWith(queryLower);
        if (isValidScore && (allowNonContiguous || isContiguous))
        {
          // trace('Valid score ($isValidScore && ($allowNonContiguous || $isContiguous))')
          matches[index] = diagMatches + 1;
          scores[index] = diagScore + score;
        }
        else
        {
          // trace('Invalid score ($isValidScore && ($allowNonContiguous || $isContiguous))')
          matches[index] = 0;
          scores[index] = leftScore;
        }
      }
    }

    // Get the match positions, from end to start.
    var positions:Array<Int> = [];
    var queryIndex = query.length - 1;
    var targetIndex = target.length - 1;
    while (queryIndex >= 0 && targetIndex >= 0)
    {
      var index:Int = (queryIndex * target.length) + targetIndex;
      var match:Int = matches[index];
      if (match == NO_MATCH)
      {
        // move left
        targetIndex--;
      }
      else
      {
        positions.unshift(targetIndex);

        // move diagonally
        queryIndex--;
        targetIndex--;
      }
    }

    var isFullMatch = (positions.length == query.length);
    if (!isFullMatch && !allowPartial) return NO_SCORE;

    return {
      score: scores[(query.length * target.length) - 1],
      matches: positions
    };
  }

  static function scoreFuzzyCharacter(queryChar:String, queryCharLower:String, target:String, targetLower:String, targetIndex:Int, diagMatches:Int):Int
  {
    var score:Int = 0;

    if (!stringEqual(queryCharLower, targetLower.charAt(targetIndex)))
    {
      return score;
    }

    // trace('Character matched: ${queryCharLower} at ${targetIndex}')

    // +1 score if the current character matches.
    score += 1;

    // +1 score if the letter case matches
    if (queryChar == target.charAt(targetIndex))
    {
      // trace('  CASE BONUS: +1')
      score += 1;
    }

    // +8 score if the current character is at the start of the string.
    if (targetIndex == 0)
    {
      // trace('  START BONUS: +8')
      score += 8;
    }
    else
    {
      // Post-separator bonus
      var separatorBonus:Int = switch (target.charAt(targetIndex - 1))
      {
        case '/' | '\\':
          5; // prefer path separators...
        case '_' | '-' | '.' | ' ' | "'" | '"' | ':':
          4; // ...over other separators
        default:
          0; // Not a separator
      }

      if (separatorBonus > 0)
      {
        // trace('  SEPARATOR BONUS: +$separatorBonus')
        score += separatorBonus;
      }
      else if (target.charAt(targetIndex).isUpperCase() && diagMatches == 0)
      {
        // Acronym bonus (uppercase, nonconsecutive matches)
        // trace('  ACRONYM BONUS: +2')
        score += 2;
      }
    }

    // Variable score bonus if previous characters match. 6x for the first 3 characters, 3x for any additional.
    if (diagMatches > 0)
    {
      var consecutiveBonus:Int = Std.int((Math.min(diagMatches, 3) * 6) + (Math.max(0, diagMatches - 3) * 3));

      // trace('  CONSECUTIVE BONUS: $consecutiveBonus')
      score += consecutiveBonus;
    }

    // trace('  total: $score')
    return score;
  }

  /**
   * Produces a styled HTML string from a fuzzy search input.
   *
   * @param target The target string to highlight.
   * @param input The fuzzy search input.
   * @return An array of text components with the highlighted matches.
   */
  public static function highlightFuzzyText(target:String, input:FuzzyScore):String
  {
    if (target.length == 0 || input.matches.length == 0) return target;
    trace('highlightFuzzyText($target, $input)');

    var result:Array<funkin.util.HaxeUIUtil.TextComponent> = [];

    final YELLOW:HaxeUIColor = 0xD9D900;
    final NO_COLOR:HaxeUIColor = 0xF9F9F9;

    var currentComponent:funkin.util.HaxeUIUtil.TextComponent = {
      text: '',
      color: NO_COLOR,
    };

    var pushComponent = (match:Bool) ->
    {
      result.push(currentComponent);
      currentComponent = match ? {
        text: '',
        color: YELLOW
      } : {
        text: '',
        color: NO_COLOR
        };
    };

    for (index in 0...target.length)
    {
      var char:String = target.charAt(index);

      var currMatch:Bool = input.matches.contains(index);
      var prevMatch:Bool = currentComponent.color == YELLOW;

      // When match/nomatch switches, push component.
      if (currMatch && !prevMatch)
      {
        pushComponent(true);
      }
      else if (!currMatch && prevMatch)
      {
        pushComponent(false);
      }
      currentComponent.text += char;
    }

    pushComponent(false);

    trace('  result: $result');

    return HaxeUIUtil.buildStyledHTML(result);
  }

  static function stringEqual(a:String, b:String):Bool
  {
    if (a == b) return true;

    if (a == '/' || a == '\\')
    {
      return b == '/' || b == '\\';
    }

    return false;
  }

  static function debug_printMatrix(query:String, target:String, matches:Array<Int>, scores:Array<Int>):Void
  {
    trace('\t' + target.split('').join('\t'));
    for (queryIndex in 0...query.length)
    {
      var line:String = query.charAt(queryIndex) + '\t';

      for (targetIndex in 0...target.length)
      {
        var index = (queryIndex * target.length) + targetIndex;
        line += matches[index] + '|' + scores[index] + '\t';
      }

      trace(line);
    }
  }
}

/**
 * Additional parameters for the fuzzy matcher.
 */
typedef ScoreFuzzyParams =
{
  /**
   * Whether to allow non-contiguous matches.
   * If `true`, `foobar` matches `fooing baring` (but wiht a lower score)
   */
  ?allowNonContiguous:Bool,
  /**
   * Whether to allow partial matches.
   * If `true`, `foobar` matches `fooing` (but with a lower score)
   */
  ?allowPartial:Bool,
}

/**
 * A score result from the fuzzy matcher.
 */
typedef FuzzyScore =
{
  /**
   * The fuzzy score.
   */
  var score:Int;

  /**
   * The positions that matched.
   */
  var matches:Array<Int>;
}
