package funkin.api.newgrounds;

#if newgrounds
import io.newgrounds.NG;
import io.newgrounds.NGLite;
import io.newgrounds.components.ScoreBoardComponent.Period;
import io.newgrounds.objects.Error;
import io.newgrounds.objects.Medal;
import io.newgrounds.objects.Score;
import io.newgrounds.objects.ScoreBoard;
import io.newgrounds.objects.events.Response;
import io.newgrounds.objects.events.Result.GetCurrentVersionResult;
import io.newgrounds.objects.events.Result.GetVersionResult;
#end

/**
 * Contains any script functions which should be BLOCKED from use by modded scripts.
 */
class NGUnsafe
{
  static public function logEvent(event:String)
  {
    #if newgrounds
    NG.core.calls.event.logEvent(event).send();
    trace('should have logged: ' + event);
    #else
    #if FEATURE_DEBUG_FUNCTIONS
    trace('event:$event - not logged, missing NG.io lib');
    #end
    #end
  }

  static public function unlockMedal(id:Int)
  {
    #if newgrounds
    if (isLoggedIn)
    {
      var medal = NG.core.medals.get(id);
      if (!medal.unlocked) medal.sendUnlock();
    }
    #else
    #if FEATURE_DEBUG_FUNCTIONS
    trace('medal:$id - not unlocked, missing NG.io lib');
    #end
    #end
  }

  static public function postScore(score:Int = 0, song:String)
  {
    #if newgrounds
    if (isLoggedIn)
    {
      for (id in NG.core.scoreBoards.keys())
      {
        var board = NG.core.scoreBoards.get(id);

        if (song == board.name)
        {
          board.postScore(score, "Uhh meow?");
        }

        // trace('loaded scoreboard id:$id, name:${board.name}');
      }
    }
    #else
    #if FEATURE_DEBUG_FUNCTIONS
    trace('Song:$song, Score:$score - not posted, missing NG.io lib');
    #end
    #end
  }
}
