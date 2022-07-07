package funkin.play.scoring;

enum abstract ScoringSystem(String) {
    /**
     * The scoring system used in versions of the game Week 6 and older.
     * Scores the player based on judgement, represented by a step function.
     */
    var LEGACY;
    /**
     * The scoring system used in Week 7. It has tighter scoring windows than Legacy.
     * Scores the player based on judgement, represented by a step function.
     */
    var WEEK7;
    /**
     * Points Based On Timing scoring system, version 1
     * Scores the player based on the offset based on timing, represented by a sigmoid function.
     */
    var PBOT1;
    // WIFE1
    // WIFE3
}

/**
 * A static class which holds any functions related to scoring.
 */
class Scoring {
    /**
     * Determine the score a note receives under a given scoring system.
     * @param msTiming The difference between the note's time and when it was hit.
     * @param scoringSystem The scoring system to use.
     * @return The score the note receives.
     */
    public static function scoreNote(msTiming:Float, scoringSystem:ScoringSystem = PBOT1) {
        switch (scoringSystem) {
            case LEGACY:
                return scoreNote_LEGACY(msTiming);
            case WEEK7:
                return scoreNote_WEEK7(msTiming);
            case PBOT1:
                return scoreNote_PBOT1(msTiming);
            default:
                trace('ERROR: Unknown scoring system: ' + scoringSystem);
                return 0;
        }
    }

    /**
     * Determine the judgement a note receives under a given scoring system.
     * @param msTiming The difference between the note's time and when it was hit.
     * @return The judgement the note receives.
     */
    public static function judgeNote(msTiming:Float, scoringSystem:ScoringSystem = PBOT1):String {
        switch (scoringSystem) {
            case LEGACY:
                return judgeNote_LEGACY(msTiming);
            case WEEK7:
                return judgeNote_WEEK7(msTiming);
            case PBOT1:
                return judgeNote_PBOT1(msTiming);
            default:
                trace('ERROR: Unknown scoring system: ' + scoringSystem);
                return 'miss';
        }
    }

    /**
     * The maximum score received.
     */
    public static var PBOT1_MAX_SCORE = 350;
    /**
     * The minimum score received.
     */
    public static var PBOT1_MIN_SCORE = 0;
    /**
     * The threshold at which a note hit is considered perfect and always given the max score.
     **/
    public static var PBOT1_PERFECT_THRESHOLD = 5.0; // 5ms.
    /**
     * The threshold at which a note hit is considered missed and always given the min score.
     **/
    public static var PBOT1_MISS_THRESHOLD = (10/60) * 1000; // ~166ms

    // Magic numbers used to tweak the shape of the scoring function.
    public static var PBOT1_SCORING_SLOPE:Float = 0.052;
    public static var PBOT1_SCORING_OFFSET:Float = 80.0;

    static function scoreNote_PBOT1(msTiming:Float):Int {
        // Absolute value because otherwise late hits are always given the max score.
        var absTiming = Math.abs(msTiming);
        if (absTiming > PBOT1_MISS_THRESHOLD) {
            return PBOT1_MIN_SCORE;
        } else if (absTiming < PBOT1_PERFECT_THRESHOLD) {
            return PBOT1_MAX_SCORE;
        } else {
            // Calculate the score based on the timing using a sigmoid function.
            var factor:Float = 1.0 - (1.0 / (1.0 + Math.exp(-PBOT1_SCORING_SLOPE * (absTiming - PBOT1_SCORING_OFFSET))));

            var score = Std.int(PBOT1_MAX_SCORE * factor);

            return score;
        }
    }

    static function judgeNote_PBOT1(msTiming:Float):String {
        return judgeNote_WEEK7(msTiming);
    }

    /**
     * The window of time in which a note is considered to be hit, on the Funkin Legacy scoring system.
     * Currently equal to 10 frames at 60fps, or ~166ms.
     */
	public static var LEGACY_HIT_WINDOW:Float = (10 / 60) * 1000; // 166.67 ms hit window (10 frames at 60fps)
    /**
     * The threshold at which a note is considered a "Bad" hit rather than a "Shit" hit.
     * Represented as a percentage of the total hit window.
     */
	public static var LEGACY_BAD_THRESHOLD:Float = 0.9;
	public static var LEGACY_GOOD_THRESHOLD:Float = 0.75;
	public static var LEGACY_SICK_THRESHOLD:Float = 0.2;
    public static var LEGACY_SHIT_SCORE = 50;
    public static var LEGACY_BAD_SCORE = 100;
    public static var LEGACY_GOOD_SCORE = 200;
    public static var LEGACY_SICK_SCORE = 350;

    static function scoreNote_LEGACY(msTiming:Float):Int {
        var absTiming = Math.abs(msTiming);
        if (absTiming < LEGACY_HIT_WINDOW * LEGACY_SICK_THRESHOLD) {
            return LEGACY_SICK_SCORE;
        } else if (absTiming < LEGACY_HIT_WINDOW * LEGACY_GOOD_THRESHOLD) {
            return LEGACY_GOOD_SCORE;
        } else if (absTiming < LEGACY_HIT_WINDOW * LEGACY_BAD_THRESHOLD) {
            return LEGACY_BAD_SCORE;
        } else if (absTiming < LEGACY_HIT_WINDOW) {
            return LEGACY_SHIT_SCORE;
        } else {
            return 0;
        }
    }

    static function judgeNote_LEGACY(msTiming:Float):String {
        var absTiming = Math.abs(msTiming);
        if (absTiming < LEGACY_HIT_WINDOW * LEGACY_SICK_THRESHOLD) {
            return 'sick';
        } else if (absTiming < LEGACY_HIT_WINDOW * LEGACY_GOOD_THRESHOLD) {
            return 'good';
        } else if (absTiming < LEGACY_HIT_WINDOW * LEGACY_BAD_THRESHOLD) {
            return 'bad';
        } else if (absTiming < LEGACY_HIT_WINDOW) {
            return 'shit';
        } else {
            return 'miss';
        }
    }

    /**
     * The window of time in which a note is considered to be hit, on the Funkin Classic scoring system.
     * Same as L 10 frames at 60fps, or ~166ms.
     */
    public static var WEEK7_HIT_WINDOW = LEGACY_HIT_WINDOW;
    public static var WEEK7_BAD_THRESHOLD = 0.8; // 80% of the hit window, or ~125ms
    public static var WEEK7_GOOD_THRESHOLD = 0.55; // 55% of the hit window, or ~91ms
    public static var WEEK7_SICK_THRESHOLD = 0.2; // 20% of the hit window, or ~33ms
    public static var WEEK7_SHIT_SCORE = 50;
    public static var WEEK7_BAD_SCORE = 100;
    public static var WEEK7_GOOD_SCORE = 200;
    public static var WEEK7_SICK_SCORE = 350;

    static function scoreNote_WEEK7(msTiming:Float):Int {
        var absTiming = Math.abs(msTiming);
        if (absTiming < WEEK7_HIT_WINDOW * WEEK7_SICK_THRESHOLD) {
            return WEEK7_SICK_SCORE;
        } else if (absTiming < WEEK7_HIT_WINDOW * WEEK7_GOOD_THRESHOLD) {
            return WEEK7_GOOD_SCORE;
        } else if (absTiming < WEEK7_HIT_WINDOW * WEEK7_BAD_THRESHOLD) {
            return WEEK7_BAD_SCORE;
        } else if (absTiming < WEEK7_HIT_WINDOW) {
            return WEEK7_SHIT_SCORE;
        } else {
            return 0;
        }
    }

    static function judgeNote_WEEK7(msTiming:Float):String {
        var absTiming = Math.abs(msTiming);
        if (absTiming < WEEK7_HIT_WINDOW * WEEK7_SICK_THRESHOLD) {
            return 'sick';
        } else if (absTiming < WEEK7_HIT_WINDOW * WEEK7_GOOD_THRESHOLD) {
            return 'good';
        } else if (absTiming < WEEK7_HIT_WINDOW * WEEK7_BAD_THRESHOLD) {
            return 'bad';
        } else if (absTiming < WEEK7_HIT_WINDOW) {
            return 'shit';
        } else {
            return 'miss';
        }
    }
}

