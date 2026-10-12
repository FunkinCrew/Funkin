package funkin.extensions;

import android.content.Context;
import android.media.AudioManager;
import android.os.Bundle;
import org.haxe.extension.Extension;

public class AudioSession extends Extension {
  private AudioManager audioManager;

  @Override
  public void onCreate(Bundle state) {
    super.onCreate(state);
    audioManager = (AudioManager) Extension.mainContext.getSystemService(Context.AUDIO_SERVICE);
    requestAudioFocus();
  }

  @Override
  public void onPause() {
    super.onPause();
    if (audioManager != null) {
      audioManager.abandonAudioFocus(null);
    }
  }

  @Override
  public void onResume() {
    super.onResume();
    requestAudioFocus();
  }

  private void requestAudioFocus() {
    if (audioManager != null) {
      audioManager.requestAudioFocus(null, AudioManager.STREAM_MUSIC, AudioManager.AUDIOFOCUS_GAIN_TRANSIENT);
    }
  }
}
