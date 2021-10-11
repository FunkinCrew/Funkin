#ifndef LIBVLC_H
#define LIBVLC_H

#include "vlc/vlc.h"
#include <mutex>

struct libvlc_instance_t;
struct libvlc_media_t;
struct libvlc_media_player_t;

typedef struct ctx
{
	unsigned char *pixeldata;
	unsigned char *pixeldata2;
	std::mutex imagemutex;
	bool bufferFlip = false;
} t_ctx;

class LibVLC
{
	public:
		LibVLC();
		~LibVLC();
		static LibVLC* create();
		
		void setPath(const char * path);
		void play();
		void play(const char * path);
		void playInWindow();
		void playInWindow(const char * path);
		void stop();
		void fullscreen(bool fullscreen);
		void togglePause();
		void pause();
		void resume();
		libvlc_time_t getLength();
		libvlc_time_t getDuration();
		int getWidth();
		int getHeight();
		int isPlaying();
		void useHWacceleration(bool hwAcc);
		//char *str LibVLC::getMeta(libvlc_media_t media);
		uint8_t* getPixelData();
		void setVolume(float volume);
		float getVolume();
		//void setCallback(cpp::Function<void (String)> callback, int cbIndex);
		libvlc_time_t getTime(); // This caused building issues.
		void setTime(libvlc_time_t time);
		float getPosition();
		void setPosition(float pos);
		bool isSeekable();
		float getFps();
		void nextFrame();
		bool hasVout();
		void setRepeat(int numRepeats);
		int getRepeat();
		const char* getLastError();
		float getFPS();
		void openMedia(const char* mediaPathName);
		int flags[16]={-1};
		void setFormat(char* chroma, unsigned* width, unsigned* height, unsigned* pitches, unsigned* lines);
		void setInitProps(); // This caused building issues.
		t_ctx ctx;
		
	private:
		libvlc_instance_t* libVlcInstance;
		libvlc_media_t* libVlcMediaItem;
		libvlc_media_player_t* libVlcMediaPlayer;
		libvlc_event_manager_t* eventManager;
        static void callbacks( const libvlc_event_t* event, void* self );
        void registerEvents();
		int repeat;
		int callbackIndex;
		cpp::Function<Void (String)> vlcCallbackMth;
		// float vol = 1.0; -- why was this made??? wtf
};

#endif