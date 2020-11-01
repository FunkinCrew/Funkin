package io.newgrounds.swf;

import openfl.events.Event;
import io.newgrounds.swf.common.DropDown;
import io.newgrounds.objects.Score;
import io.newgrounds.objects.events.Result.ScoreBoardResult;
import io.newgrounds.objects.events.Result.ScoreResult;
import io.newgrounds.objects.events.Response;
import io.newgrounds.swf.common.BaseAsset;
import io.newgrounds.swf.common.Button;
import io.newgrounds.components.ScoreBoardComponent.Period;

import openfl.display.MovieClip;
import openfl.text.TextField;

class ScoreBrowser extends BaseAsset {
	
	public var prevButton    (default, null):MovieClip;
	public var nextButton    (default, null):MovieClip;
	public var reloadButton  (default, null):MovieClip;
	public var listBox       (default, null):MovieClip;
	public var loadingIcon   (default, null):MovieClip;
	public var errorIcon     (default, null):MovieClip;
	public var scoreContainer(default, null):MovieClip;
	public var titleField    (default, null):TextField;
	public var pageField     (default, null):TextField;
	
	public var period(get, set):Period;
	function get_period():Period { return _periodDropDown.value; }
	function set_period(value:Period):Period { return _periodDropDown.value = value; }
	
	public var title(get, set):String;
	function get_title():String { return titleField.text; }
	function set_title(value:String):String { return titleField.text = value; }
	
	public var tag(default, set):String;
	function set_tag(value:String):String {
		
		if (this.tag != value) {
			
			this.tag = value;
			delayReload();
		}
		
		return value;
	}
	
	public var social(default, set):Bool;
	function set_social(value:Bool):Bool {
		
		if (this.social != value) {
			
			this.social = value;
			delayReload();
		}
		
		return value;
	}
	
	public var boardId(default, set):Int;
	function set_boardId(value:Int):Int {
		
		_boardIDSet = true;
		
		if (this.boardId != value) {
			
			this.boardId = value;
			delayReload();
		}
		
		return value;
	}
	
	public var page(default, set):Int;
	function set_page(value:Int):Int {
		
		if (this.page != value) {
			
			this.page = value;
			delayReload();
		}
		
		return value;
	}
	
	var _scores:Array<MovieClip>;
	var _limit:Int = 0;
	var _periodDropDown:DropDown;
	var _boardIDSet:Bool;
	
	public function new() { super(); }
	
	override function setDefaults():Void {
		super.setDefaults();
		
		boardId = -1;
		_boardIDSet = false;
		
		scoreContainer.visible = false;
		loadingIcon.visible = false;
		reloadButton.visible = false;
		errorIcon.visible = false;
		errorIcon.addFrameScript(errorIcon.totalFrames - 1, errorIcon.stop);
		
		//TODO: prevent memory leaks?
		new Button(prevButton, onPrevClick);
		new Button(nextButton, onNextClick);
		new Button(reloadButton, reload);
		_periodDropDown = new DropDown(listBox, delayReload);
		_periodDropDown.addItem("Current day"  , Period.DAY  );
		_periodDropDown.addItem("Current week" , Period.WEEK );
		_periodDropDown.addItem("Current month", Period.MONTH);
		_periodDropDown.addItem("Current year" , Period.YEAR );
		_periodDropDown.addItem("All time"     , Period.ALL  );
		_periodDropDown.value = Period.ALL;
		
		_scores = new Array<MovieClip>();
		while(true) {
			
			var score:MovieClip = cast scoreContainer.getChildByName('score${_scores.length}');
			if (score == null)
				break;
			
			new Button(score);
			_scores.push(score);
		}
		
		_limit = _scores.length;
	}
	
	override function onReady():Void {
		super.onReady();
		
		if (boardId == -1 && !_boardIDSet) {
			
			#if ng_lite
			NG.core.calls.scoreBoard.getBoards()
				.addDataHandler(onBoardsRecieved)
				.queue();
			#else
			if (NG.core.scoreBoards != null)
				onBoardsLoaded();
			else
				NG.core.requestScoreBoards(onBoardsLoaded);
			#end
		}
		
		reload();
	}
	
	#if ng_lite
	function onBoardsRecieved(response:Response<ScoreBoardResult>):Void {
		
		if (response.success && response.result.success) {
			
			for (board in response.result.data.scoreboards) {
				
				NG.core.log('No boardId specified defaulting to ${board.name}');
				boardId = board.id;
				return;
			}
		}
	}
	#else
	function onBoardsLoaded():Void {
		
		for (board in NG.core.scoreBoards) {
			
			NG.core.log('No boardId specified defaulting to ${board.name}');
			boardId = board.id;
			return;
		}
	}
	#end

	/** Used internally to avoid multiple server requests from various property changes in a small time-frame. **/
	function delayReload():Void {
		
		addEventListener(Event.EXIT_FRAME, onDelayComplete);
	}
	
	function onDelayComplete(e:Event):Void { reload(); }
	
	public function reload():Void {
		removeEventListener(Event.EXIT_FRAME, onDelayComplete);
		
		errorIcon.visible = false;
		scoreContainer.visible = false;
		pageField.text = 'page ${page + 1}';
		
		if (_coreReady && boardId != -1 && _limit > 0 && period != null) {
			
			loadingIcon.visible = true;
			
			NG.core.calls.scoreBoard.getScores(boardId, _limit, _limit * page, period, social, tag)
				.addDataHandler(onScoresReceive)
				.send();
		}
	}
	
	function onScoresReceive(response:Response<ScoreResult>):Void {
		
		loadingIcon.visible = false;
		
		if (response.success && response.result.success) {
			
			scoreContainer.visible = true;
			
			var i = _limit;
			while(i > 0) {
				i--;
				
				if (i < response.result.data.scores.length)
					drawScore(i, response.result.data.scores[i], _scores[i]);
				else
					drawScore(i, null, _scores[i]);
			}
			
		} else {
			
			errorIcon.visible = true;
			errorIcon.gotoAndPlay(1);
			reloadButton.visible = true;
		}
	}
	
	inline function drawScore(rank:Int, score:Score, asset:MovieClip):Void {
		
		if (score == null)
			asset.visible = false;
		else {
			
			asset.visible = true;
			cast (asset.getChildByName("nameField" ), TextField).text = score.user.name;
			cast (asset.getChildByName("scoreField"), TextField).text = score.formatted_value;
			cast (asset.getChildByName("rankField" ), TextField).text = Std.string(rank + 1);
		}
	}
	
	function onPrevClick():Void {
		
		if (page > 0)
			page--;
	}
	
	function onNextClick():Void {
		
		page++;
	}
}
