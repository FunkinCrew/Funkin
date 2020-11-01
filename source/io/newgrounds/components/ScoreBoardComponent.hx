package io.newgrounds.components;

import io.newgrounds.objects.User;
import io.newgrounds.objects.events.Response;
import io.newgrounds.objects.events.Result;
import io.newgrounds.objects.events.Result.ScoreBoardResult;
import io.newgrounds.objects.events.Result.ScoreResult;
import io.newgrounds.NGLite;
import io.newgrounds.objects.ScoreBoard;

import haxe.ds.IntMap;

class ScoreBoardComponent extends Component {
	
	public var allById:IntMap<ScoreBoard>;
	
	public function new (core:NGLite){ super(core); }
	
	// -------------------------------------------------------------------------------------------
	//                                       GET SCORES
	// -------------------------------------------------------------------------------------------
	
	public function getBoards():Call<ScoreBoardResult> {
		
		return new Call<ScoreBoardResult>(_core, "ScoreBoard.getBoards");
	}
	
	/*function onBoardsReceive(response:Response<ScoreBoardResult>):Void {
		
		if (!response.result.success)
			return;
		
		allById = new IntMap<ScoreBoard>();
		
		for (boardData in response.result.scoreboards)
			createBoard(boardData);
		
		_core.log('${response.result.scoreboards.length} ScoreBoards loaded');
	}*/
	
	// -------------------------------------------------------------------------------------------
	//                                       GET SCORES
	// -------------------------------------------------------------------------------------------
	
	public function getScores
	( id    :Int
	, limit :Int     = 10
	, skip  :Int     = 0
	, period:Period  = Period.DAY
	, social:Bool    = false
	, tag   :String  = null
	, user  :Dynamic = null
	):Call<ScoreResult> {
		
		if (user != null && !Std.is(user, String) && !Std.is(user, Int))
			user = user.id;
		
		return new Call<ScoreResult>(_core, "ScoreBoard.getScores")
			.addComponentParameter("id"    , id    )
			.addComponentParameter("limit" , limit , 10)
			.addComponentParameter("skip"  , skip  , 0)
			.addComponentParameter("period", period, Period.DAY)
			.addComponentParameter("social", social, false)
			.addComponentParameter("tag"   , tag   , null)
			.addComponentParameter("user"  , user  , null);
	}
	
	// -------------------------------------------------------------------------------------------
	//                                       POST SCORE
	// -------------------------------------------------------------------------------------------
	
	public function postScore(id:Int, value:Int, tag:String = null):Call<PostScoreResult> {
		
		return new Call<PostScoreResult>(_core, "ScoreBoard.postScore", true, true)
			.addComponentParameter("id"   , id)
			.addComponentParameter("value", value)
			.addComponentParameter("tag"  , tag  , null);
	}
	
	/*function onScorePosted(response:Response<ResultBase>):Void {
		
		if (!response.result.success)
			return;
		
		allById = new IntMap<ScoreBoard>();
		
		//createBoard(data.data.scoreBoard).parseScores(data.data.scores);
	}*/
	
	inline function createBoard(data:Dynamic):ScoreBoard {
		
		var board = new ScoreBoard(_core, data);
		_core.logVerbose('created $board');
		
		allById.set(board.id, board);
		
		return board;
	}
}

@:enum 
abstract Period(String) to String from String{
	
	/** Indicates scores are from the current day. */
	var DAY = "D";
	/** Indicates scores are from the current week. */
	var WEEK = "W";
	/** Indicates scores are from the current month. */
	var MONTH = "M";
	/** Indicates scores are from the current year. */
	var YEAR = "Y";
	/** Indicates scores are from all-time. */
	var ALL = "A";
}