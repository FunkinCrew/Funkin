package io.newgrounds.objects;

import io.newgrounds.components.ScoreBoardComponent.Period;
import io.newgrounds.objects.events.Response;
import io.newgrounds.objects.events.Result;
import io.newgrounds.objects.events.Result.ScoreResult;
import io.newgrounds.NGLite;

class ScoreBoard extends Object {
	
	public var scores(default, null):Array<Score>;
	
	/** The numeric ID of the scoreboard.*/
	public var id(default, null):Int;
	
	/** The name of the scoreboard. */
	public var name(default, null):String;
	
	public function new(core:NGLite, data:Dynamic):Void {super(core, data); }
	
	override function parse(data:Dynamic):Void {
		
		id   = data.id;
		name = data.name;
		
		super.parse(data);
	}

	/**
	 * Fetches score data from the server, this removes all of the existing scores cached
	 * 
	 * We don't unify the old and new scores because a user's rank or score may change between requests
	 */
	public function requestScores
	( limit :Int     = 10
	, skip  :Int     = 0
	, period:Period  = Period.ALL
	, social:Bool    = false
	, tag   :String  = null
	, user  :Dynamic = null
	):Void {
		
		_core.calls.scoreBoard.getScores(id, limit, skip, period, social, tag, user)
			.addDataHandler(onScoresReceived)
			.send();
	}
	
	function onScoresReceived(response:Response<ScoreResult>):Void {
		
		if (!response.success || !response.result.success)
			return;
		
		scores = response.result.data.scores;
		_core.logVerbose('received ${scores.length} scores');
		
		onUpdate.dispatch();
	}
	
	public function postScore(value :Int, tag:String = null):Void {
		
		_core.calls.scoreBoard.postScore(id, value, tag)
			.addDataHandler(onScorePosted)
			.send();
	}
	
	function onScorePosted(response:Response<PostScoreResult>):Void {
		
		
	}
	
	public function toString():String {
		
		return 'ScoreBoard: $id@$name';
	}
	
}