package funkin.vis._internal.html5;

import funkin.vis.AudioBuffer;
#if lime_howlerjs
import lime.media.howlerjs.Howl;
import js.html.audio.AnalyserNode as AnalyseWebAudio;
#end

// note: analyze and analyse are both correct spellings of the word, 
// but "AnalyserNode" is the correct class name in the Web Audio API
// and we use the Z variant here...
class AnalyzerNode
{   

    #if lime_howlerjs
    public var analyzer:AnalyseWebAudio;
    public var maxDecibels:Float = -30;
    public var minDecibels:Float = -100;
    public var fftSize:Int = 2048;
    #end

    // #region yoooo
    public function new(?audioClip:AudioClip)
    {
        trace("Loading audioClip");

        #if lime_howlerjs
        analyzer = new AnalyseWebAudio(audioClip.source._sounds[0]._node.context);
        audioClip.source._sounds[0]._node.connect(analyzer);
        // trace(audioClip.source._sounds[0]._node.context.sampleRate);
        // trace(analyzer);
        // trace(analyzer.fftSize);
        // howler = cast buffer.source;
        // trace(howler);
        getFloatFrequencyData();
        #end   
    }

    public function getFloatFrequencyData():Array<Float>
    {
        #if lime_howlerjs
        var array:js.lib.Float32Array = new js.lib.Float32Array(analyzer.frequencyBinCount);
        analyzer.fftSize = fftSize;
        analyzer.minDecibels = minDecibels;
        analyzer.maxDecibels = maxDecibels;
        analyzer.getFloatFrequencyData(array);
        return cast array;
        #end
        return [];
    }
}