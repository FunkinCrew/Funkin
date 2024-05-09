package funkin.vis;

import funkin.vis.LogHelper;

class Scaling
{
    public static inline function freqScaleMel(freq:Float):Float
		return LogHelper.log2(1 + freq / 700);

	public static inline function invFreqScaleMel(x:Float):Float
		return 700 * (Math.pow(2, x - 1));

	public static inline function freqScaleBark(freq:Float):Float
		return (26.81 * freq) / (1960 + freq) - 0.53;

	public static inline function invFreqScaleBark(x:Float):Float
		return 1960 / (26.81 / (x + .53) - 1);

	public static inline function freqScaleLog(freq:Float):Float
		return LogHelper.log10(1 + freq / 1000);

	public static inline function invFreqScaleLog(x:Float):Float
		return 1000 * (Math.pow(10, x - 1));
}