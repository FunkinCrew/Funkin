package funkin.util;

import lime.media.AudioBuffer;
import lime.media.AudioManager;
import lime.utils.UInt8Array;
import openfl.media.Sound;
import flixel.sound.FlxSound;
import flixel.util.FlxSignal;
import funkin.audio.FunkinSound;
import funkin.util.MemoryUtil;

/**
 * Audio engine utilities, such as restarting audio on device change.
 */
#if (windows && cpp)
typedef RegenSoundData =
{
  var sound:FlxSound;
  var isPlaying:Bool;
  var time:Float;
};

@:buildXml('
<target id="haxe">
  <lib name="ole32.lib" if="windows"/>
</target>
')
@:cppFileCode('
#include <string>
#include "mmdeviceapi.h"

bool _audioDeviceChanged = false;
class AudioFixClient : public IMMNotificationClient {
  public:

  AudioFixClient() : _refCount(1), _pDeviceEnum(nullptr) {
    HRESULT result = CoCreateInstance(__uuidof(MMDeviceEnumerator), nullptr, CLSCTX_INPROC_SERVER, __uuidof(IMMDeviceEnumerator), (void**)&_pDeviceEnum);
    if (result == S_OK) _pDeviceEnum->RegisterEndpointNotificationCallback(this);
    updateCurrentDeviceID();
  }

  ~AudioFixClient() {
    if (_pDeviceEnum != nullptr) {
      _pDeviceEnum->UnregisterEndpointNotificationCallback(this);
      _pDeviceEnum->Release();
      _pDeviceEnum = nullptr;
    }
  }

  HRESULT STDMETHODCALLTYPE OnDefaultDeviceChanged(EDataFlow flow, ERole role, LPCWSTR pwstrDefaultDeviceId) {
    if (flow == eRender && role == eConsole && pwstrDefaultDeviceId != nullptr) {
      if (_currentDeviceID.compare(pwstrDefaultDeviceId) != 0) {
        _audioDeviceChanged = true;
      }
    }

    return S_OK;
  }

  ULONG STDMETHODCALLTYPE AddRef() {
    return InterlockedIncrement(&_refCount);
  }

  ULONG STDMETHODCALLTYPE Release() {
    ULONG ulRef = InterlockedDecrement(&_refCount);
    if (0 == ulRef) delete this;
    return ulRef;
  }

  HRESULT STDMETHODCALLTYPE QueryInterface(REFIID riid, VOID** ppvInterface) {
    if (IID_IUnknown == riid) {
      AddRef();
      *ppvInterface = (IUnknown*)this;
    } else if (__uuidof(IMMNotificationClient) == riid) {
      AddRef();
      *ppvInterface = (IMMNotificationClient*)this;
    } else {
      *ppvInterface = NULL;
      return E_NOINTERFACE;
    }

    return S_OK;
  }

  HRESULT STDMETHODCALLTYPE OnDeviceAdded(LPCWSTR pwstrDeviceId) {
    return S_OK;
  }

  HRESULT STDMETHODCALLTYPE OnDeviceRemoved(LPCWSTR pwstrDeviceId) {
    return S_OK;
  }

  HRESULT STDMETHODCALLTYPE OnDeviceStateChanged(LPCWSTR pwstrDeviceId, DWORD dwNewState) {
    return S_OK;
  }

  HRESULT STDMETHODCALLTYPE OnPropertyValueChanged(LPCWSTR pwstrDeviceId, const PROPERTYKEY key) {
    return S_OK;
  }

  void updateCurrentDeviceID() {
    if (_pDeviceEnum == nullptr) return;
    IMMDevice* _pDevice = nullptr;
    LPWSTR _deviceId = nullptr;
    HRESULT result = _pDeviceEnum->GetDefaultAudioEndpoint(eRender, eConsole, &_pDevice);
    if (SUCCEEDED(result) && _pDevice != nullptr) {
      result = _pDevice->GetId(&_deviceId);
      if (SUCCEEDED(result) && _deviceId != nullptr) {
        _currentDeviceID = _deviceId;
        CoTaskMemFree(_deviceId);
      }

      _pDevice->Release();
    }
  }

  private:

  std::wstring _currentDeviceID;
  IMMDeviceEnumerator* _pDeviceEnum;

  LONG _refCount;
};

AudioFixClient* curAudioFix;
')
#end
@:nullSafety
class AudioUtil
{
  #if (windows && cpp)
  /**
   * Signal dispatched when the current audio device is changed, after an attempted restart.
   */
  public static final audioDeviceChangeSignal:FlxSignal = new FlxSignal();

  /**
   * Whether the current audio device has changed.
   */
  private static var audioDeviceChanged(get, set):Bool;

  public static function get_audioDeviceChanged():Bool
  {
    return cast untyped __cpp__('_audioDeviceChanged');
  }

  public static function set_audioDeviceChanged(v:Bool):Bool
  {
    untyped __cpp__('_audioDeviceChanged = (bool)v;');
    return v;
  }

  private static var initializedAudioFix:Bool = false;

  /**
   * Initializes the audio fix client to handle audio device changes.
   * This should be called once at the start of the application.
   */
  public static function initAudioFix():Void
  {
    if (initializedAudioFix) return;

    untyped __cpp__('if (curAudioFix == nullptr) curAudioFix = new AudioFixClient();');

    FlxG.signals.preUpdate.add(function():Void {
      if (audioDeviceChanged)
      {
        trace("Audio device changed, restarting audio system...");
        restartAudio();
      }
    });

    initializedAudioFix = true;
  }

  /**
   * Restarts the audio system and regenerates all sounds.
   */
  public static function restartAudio():Void
  {
    final curSounds:Array<FlxSound> = new Array<FlxSound>();

    @:privateAccess for (sound in FunkinSound.pool)
      if (sound != null && sound.exists) ArrayTools.pushUnique(curSounds, sound);
    for (sound in FlxG.sound.list)
      if (sound != null && sound.exists) ArrayTools.pushUnique(curSounds, sound);
    if (FlxG.sound.music != null && FlxG.sound.music.exists) ArrayTools.pushUnique(curSounds, FlxG.sound.music);

    final regenData:Array<RegenSoundData> = new Array<RegenSoundData>();
    for (sound in curSounds)
    {
      regenData.push({sound: sound, isPlaying: sound.playing, time: sound.time});
      sound.pause();
    }

    AudioManager.shutdown();
    AudioManager.init();

    untyped __cpp__('if (curAudioFix != nullptr) curAudioFix->updateCurrentDeviceID();');

    for (entry in regenData)
    {
      final sound:FlxSound = entry.sound;
      @:privateAccess if (!Std.isOfType(sound, FunkinSound)) regenSound(sound._sound);
      if (entry.isPlaying) sound.play(true, entry.time);
      sound.time = entry.time;
    }

    MemoryUtil.collect(true);

    audioDeviceChanged = false;
    audioDeviceChangeSignal.dispatch();
  }

  /**
   * Refreshes the sound buffer of a given `Sound`.
   */
  public static function regenSound(sound:Null<Sound>):Void
  {
    if (sound != null)
    {
      @:privateAccess final curBuffer:Null<AudioBuffer> = sound.__buffer;
      if (curBuffer != null)
      {
        final newBuffer:AudioBuffer = new AudioBuffer();
        newBuffer.bitsPerSample = curBuffer.bitsPerSample;
        newBuffer.channels = curBuffer.channels;
        newBuffer.data = UInt8Array.fromBytes(curBuffer.data.toBytes());
        newBuffer.sampleRate = curBuffer.sampleRate;
        newBuffer.src = curBuffer.src;
        @:privateAccess sound.__buffer = newBuffer;
      }
    }
  }
  #end
}
