package;
// https://www.youtube.com/watch?v=SjABiUMmhhA
// used for judging scores
// v image of judges
// https://i.imgur.com/mmygOBv.png
// FUNYY JOKE LOOK IT'S NAMED JURY LMAOOOOO

enum abstract Jury(Int) from Int to Int {
    var Judge1;
    var Judge2;
    var Judge3;
    var Judge4;
    var Judge5;
    var Judge6;
    var Judge7;
    var Judge8;
    var Judge9; // JUSTICE
	var Classic;
	var Hard; // Half of classic
    
}
class Judge {
    // it's shit judge because this is the highest value you can be off without missing
    // I think these are in ms? lmao
    public static var shitJudge:Float = 166;
	public static var badJudge:Float = 135;
	public static var goodJudge:Float = 90;
	public static var sickJudge:Float = 45;
    public static var wayoffJudge:Float = 203;
    public static function resetJudge() {
		shitJudge = 166;
		badJudge = 135;
		goodJudge = 90;
		sickJudge = 45;
        wayoffJudge = 203;
    }
    public static function setJudge(judge:Jury) {
        trace(judge);
        switch (judge) {
            case Judge1:
                shitJudge = 203;
                badJudge = 135;
                goodJudge = 68;
                sickJudge = 33;
                wayoffJudge = 270;
            case Judge2:
                shitJudge = 180;
                badJudge = 120;
                goodJudge = 60;
                sickJudge = 29;
                wayoffJudge = 239;
            case Judge3:
                shitJudge = 157;
                badJudge = 104;
                goodJudge = 52;
                sickJudge = 26;
                wayoffJudge = 209;
            case Judge4:
                shitJudge = 135;
                badJudge = 90;
                goodJudge = 45;
                sickJudge = 22;
                wayoffJudge = 180;
            case Judge5:
                shitJudge = 113;
                badJudge = 76;
                goodJudge = 38;
                sickJudge = 18;
                wayoffJudge = 151;
            case Judge6:
                shitJudge = 89;
                badJudge = 59;
                goodJudge = 30;
                sickJudge = 15;
                wayoffJudge = 119;
            case Judge7:
                shitJudge = 68;
                badJudge = 45;
                goodJudge = 23;
                sickJudge = 11;
                wayoffJudge = 90;
            case Judge8:
                shitJudge = 45;
                badJudge = 30;
                goodJudge = 15;
                sickJudge = 7;
                wayoffJudge = 59;
            case Judge9:
                shitJudge = 27;
                badJudge = 18;
                goodJudge = 9;
                sickJudge = 4;
                wayoffJudge = 36;
            case Classic:
                resetJudge();
            case Hard:
                resetJudge();
				shitJudge /= 2;
				badJudge /= 2;
				goodJudge /= 2;
				sickJudge /= 2;
                wayoffJudge /= 2;
        }
    }
}