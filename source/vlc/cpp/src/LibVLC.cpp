#include <mutex>
#include <iostream>
#include <string>
#include <StdInt.h>
#include <windows.h> 

using std::string;
using namespace std;

/////////////////////////////////////////////////////////////////////////////////////

LibVLC::LibVLC(void)
{
	char const *Args[] =
	{
		//"--aout", "amem",
		"--drop-late-frames",
		"--ignore-config",
		"--intf", "dummy",
		"--no-disable-screensaver",
		"--no-snapshot-preview",
		"--no-stats",
		"--no-video-title-show",
		"--text-renderer", "dummy",
		"--quiet",
		#if PLATFORM_LINUX
"--no-xlib",
#endif

#if DEBUG
"--verbose=2"
#else
#endif
		//"--no-xlib", //no xlib if linux
		//"--vout", "vmem"
		//"--avcodec-hw=dxva2",
		//"--verbose=2"
	};	
	
	int Argc = sizeof(Args) / sizeof(*Args);
	// libVlcInstance = libvlc_new(Argc, Args);
	libVlcInstance = libvlc_new(0, NULL);
	
}

LibVLC::~LibVLC(void)
{ 
    libvlc_event_detach( eventManager, libvlc_MediaPlayerSnapshotTaken, 	callbacks, this );
    libvlc_event_detach( eventManager, libvlc_MediaPlayerTimeChanged, 		callbacks, this );
    libvlc_event_detach( eventManager, libvlc_MediaPlayerPlaying, 			callbacks, this );
    libvlc_event_detach( eventManager, libvlc_MediaPlayerPaused, 			callbacks, this );
    libvlc_event_detach( eventManager, libvlc_MediaPlayerStopped, 			callbacks, this );
    libvlc_event_detach( eventManager, libvlc_MediaPlayerEndReached, 		callbacks, this );
    libvlc_event_detach( eventManager, libvlc_MediaPlayerPositionChanged,	callbacks, this );

    libvlc_media_player_release( libVlcMediaPlayer );	
	libvlc_release( libVlcInstance );
	
	delete libVlcInstance;
	delete libVlcMediaItem;
	delete libVlcMediaPlayer;
	
	delete ctx.pixeldata;
}

LibVLC* LibVLC::create()
{
    return new LibVLC;
}

/////////////////////////////////////////////////////////////////////////////////////

static void *lock(void *data, void **p_pixels)
{
	t_ctx *ctx = (t_ctx*)data;
	ctx->imagemutex.lock();
	if (ctx->bufferFlip)
		*p_pixels = ctx->pixeldata;
	else
		*p_pixels = ctx->pixeldata2;
	ctx->bufferFlip = !(ctx->bufferFlip);
	return NULL;
}

static void unlock(void *data, void *id, void *const *p_pixels)
{
	t_ctx *ctx = (t_ctx *)data;
	ctx->imagemutex.unlock();
}

static void display(void *opaque, void *picture)
{
	//t_ctx *ctx = (t_ctx *)data;
	//self->flags[15]=1;
	//std::cout << "display " << self << std::endl;
}

static unsigned format_setup(void** opaque, char* chroma, unsigned* width, unsigned* height, unsigned* pitches, unsigned* lines)
{
    //LibVLC* self = reinterpret_cast<LibVLC*>( opaque );
	struct ctx *callback = reinterpret_cast<struct ctx *>(*opaque);	
	
	unsigned _w = (*width);
	unsigned _h = (*height);
	unsigned _pitch = _w*4;
	unsigned _frame = _w*_h*4;
	
	(*pitches) = _pitch;
	(*lines) = _h;
	memcpy(chroma, "RV32", 4);
	
	if (callback->pixeldata != 0)
		delete callback->pixeldata;
	if (callback->pixeldata2 != 0)
		delete callback->pixeldata2;
		
	callback->pixeldata = new unsigned char[_frame];
	callback->pixeldata2 = new unsigned char[_frame];
	return 1;
}

static void format_cleanup(void *opaque)
{
}

/////////////////////////////////////////////////////////////////////////////////////

uint8_t* LibVLC::getPixelData()
{
	//return pixels;
	if (ctx.bufferFlip)
		return ctx.pixeldata2;
	else
		return ctx.pixeldata;
}

void LibVLC::setPath(const char* path)
{
	std::cout << "settin' path: " << path << std::endl;

	//libVlcMediaItem = libvlc_media_new_path(libVlcInstance, path);
	libVlcMediaItem = libvlc_media_new_location(libVlcInstance, path);
	//libVlcMediaItem = libvlc_media_new_location(libVlcInstance, "file:///C:\\Program Files (x86)\\Xms Client 3\\resources\\downloaded\\files\\ac079337-dbd1-11e6-a59e-f681aa9a2e27.mp4");
	libVlcMediaPlayer = libvlc_media_player_new_from_media(libVlcMediaItem);
	libvlc_media_parse(libVlcMediaItem);
	libvlc_media_release(libVlcMediaItem);
	useHWacceleration(true);

	if (libVlcMediaItem!=nullptr)
	{
		std::string sa = "input-repeat=";
		sa += std::to_string(repeat);
		libvlc_media_add_option(libVlcMediaItem, sa.c_str() );	
		//if (repeat==-1)
			//libvlc_media_add_option(libVlcMediaItem, "input-repeat=-1" );	
		//else if (repeat==0)
			//libvlc_media_add_option(libVlcMediaItem, "input-repeat=0" );	
		//std::cout << "Num repeats: " << sa << std::endl;
	}
}

void LibVLC::play()
{
	libvlc_media_player_play(libVlcMediaPlayer);
}

void LibVLC::play(const char* path)
{
	setPath(path);
	ctx.pixeldata = 0;
	ctx.pixeldata2 = 0;
		
	libvlc_video_set_format_callbacks(libVlcMediaPlayer, format_setup, format_cleanup);
	libvlc_video_set_callbacks(libVlcMediaPlayer, lock, unlock, display, &ctx);
	eventManager = libvlc_media_player_event_manager( libVlcMediaPlayer );
	registerEvents();
	libvlc_media_player_play(libVlcMediaPlayer);
	libvlc_audio_set_volume(libVlcMediaPlayer, 0);
}

void LibVLC::playInWindow()
{
	//libvlc_video_set_format_callbacks(libVlcMediaPlayer, format_setup, format_cleanup);
	ctx.pixeldata = 0;
	ctx.pixeldata2 = 0;
	eventManager = libvlc_media_player_event_manager( libVlcMediaPlayer );
	registerEvents();
	libvlc_media_player_play(libVlcMediaPlayer);
	//libvlc_audio_set_volume(libVlcMediaPlayer, 0);
}

void LibVLC::playInWindow(const char* path)
{
	setPath(path);
	ctx.pixeldata = 0;
	ctx.pixeldata2 = 0;
	//libvlc_video_set_format_callbacks(libVlcMediaPlayer, format_setup, format_cleanup);
	eventManager = libvlc_media_player_event_manager( libVlcMediaPlayer );
	registerEvents();
	libvlc_media_player_play(libVlcMediaPlayer);
	//libvlc_audio_set_volume(libVlcMediaPlayer, 0);
}

void LibVLC::setInitProps()
{
	setVolume(1);
}

void LibVLC::stop()
{
	libvlc_media_player_stop(libVlcMediaPlayer);
}

void LibVLC::fullscreen(bool fullscreen)
{
	libvlc_set_fullscreen(libVlcMediaPlayer, fullscreen);
}

void LibVLC::pause()
{
	libvlc_media_player_pause(libVlcMediaPlayer);
}

void LibVLC::resume()
{
    libvlc_media_player_pause( libVlcMediaPlayer );
}

libvlc_time_t LibVLC::getLength()
{
	return libvlc_media_player_get_length(libVlcMediaPlayer);
}

libvlc_time_t LibVLC::getDuration()
{
	return libvlc_media_get_duration(libVlcMediaItem);
}

int LibVLC::getWidth()
{
	return libvlc_video_get_width(libVlcMediaPlayer);
}

int LibVLC::getHeight()
{
	return libvlc_video_get_height(libVlcMediaPlayer);
}

int LibVLC::isPlaying()
{
	return libvlc_media_player_is_playing(libVlcMediaPlayer);
}

void LibVLC::setRepeat(int numRepeats)
{
	repeat = numRepeats;
/*	if (libVlcMediaItem!=nullptr)
	{
		std::string sa = "input-repeat=";
		sa += std::to_string(repeat);
		//libvlc_media_add_option(libVlcMediaItem, sa.c_str() );	
		if (repeat==-1)
			libvlc_media_add_option(libVlcMediaItem, "input-repeat=-1" );	
		else if (repeat==0)
			libvlc_media_add_option(libVlcMediaItem, "input-repeat=0" );	
		//std::cout << "Num repeats: " << sa << std::endl;
	}
	*/
}

int LibVLC::getRepeat()
{
	return repeat;
}

const char* LibVLC::getLastError()
{
	return libvlc_errmsg();	
}

void LibVLC::setVolume(float volume)
{
	if (volume > 100)
		volume = 100.0;

	// vol = volume;

	if (libVlcMediaPlayer != NULL && libVlcMediaPlayer != nullptr)
	{
		try
		{
			libvlc_audio_set_volume(libVlcMediaPlayer, volume);
		}
		catch(int e)
		{
			std::cout << "there was an error with volume: " << e << std::endl;
		}
	}
}

float LibVLC::getVolume()
{
    float volume = libvlc_audio_get_volume( libVlcMediaPlayer );
    return volume;
}

libvlc_time_t LibVLC::getTime()
{
	if (libVlcMediaPlayer!=NULL && libVlcMediaPlayer!=nullptr)
	{
		try
		{
			int64_t t = libvlc_media_player_get_time( libVlcMediaPlayer );
			return t;
		}
		catch(int e)
		{
			return 0;
		}
	}
	else
		return 0;
}

void LibVLC::setTime(libvlc_time_t time)
{
	libvlc_media_player_set_time(libVlcMediaPlayer, time);
}

float LibVLC::getPosition()
{
    return libvlc_media_player_get_position( libVlcMediaPlayer );
}

void LibVLC::setPosition(float pos)
{
	libvlc_media_player_set_position(libVlcMediaPlayer, pos);
}

bool LibVLC::isSeekable()
{
    return ( libvlc_media_player_is_seekable( libVlcMediaPlayer ) == 1 );
}

void LibVLC::openMedia(const char* mediaPathName)
{
	libVlcMediaItem = libvlc_media_new_location(libVlcInstance, mediaPathName);
	//libVlcMediaItem = libvlc_media_new_path(libVlcInstance, mediaPathName);
    libvlc_media_player_set_media(libVlcMediaPlayer, libVlcMediaItem);    
}

//void MediaPlayer::setMedia( Media* media )
//{
    //libvlc_media_player_set_media( m_internalPtr, media->getInternalPtr() );
//}

//void
//MediaPlayer::getSize( quint32 *outWidth, quint32 *outHeight )
//{
    //libvlc_video_get_size( m_internalPtr, 0, outWidth, outHeight );
//}

float LibVLC::getFPS()
{
    return libvlc_media_player_get_fps( libVlcMediaPlayer );
}

void LibVLC::nextFrame()
{
    libvlc_media_player_next_frame( libVlcMediaPlayer );
}

bool LibVLC::hasVout()
{
    return libvlc_media_player_has_vout( libVlcMediaPlayer );
}
/*
void LibVLC::setXwindow(uint32_t drawable)
{
	libvlc_media_player_set_xwindow(*this, drawable);
}
uint32_t LibVLC::xwindow()
{
	return libvlc_media_player_get_xwindow(*this);
}
void LibVLC::setHwnd(void * drawable)
{
	libvlc_media_player_set_hwnd(*this, drawable);
}
void* LibVLC::hwnd()
{
	return libvlc_media_player_get_hwnd(*this);
}*/

/////////////////////////////////////////////////////////////////////////////////////

void LibVLC::useHWacceleration(bool hwAcc)
{
	if (hwAcc)
	{
		libvlc_media_add_option(libVlcMediaItem, ":hwdec=vaapi");
		libvlc_media_add_option(libVlcMediaItem, ":ffmpeg-hw");
		libvlc_media_add_option(libVlcMediaItem, ":avcodec-hw=dxva2.lo");
		libvlc_media_add_option(libVlcMediaItem, ":avcodec-hw=any");
		libvlc_media_add_option(libVlcMediaItem, ":avcodec-hw=dxva2");
		libvlc_media_add_option(libVlcMediaItem, "--avcodec-hw=dxva2");
		libvlc_media_add_option(libVlcMediaItem, ":avcodec-hw=vaapi");
	}
}

/////////////////////////////////////////////////////////////////////////////////////

void LibVLC::registerEvents()
{
    libvlc_event_attach( eventManager, libvlc_MediaPlayerPlaying,         callbacks, this );
    libvlc_event_attach( eventManager, libvlc_MediaPlayerSnapshotTaken,   callbacks, this );
    libvlc_event_attach( eventManager, libvlc_MediaPlayerTimeChanged,     callbacks, this );
    libvlc_event_attach( eventManager, libvlc_MediaPlayerPlaying,         callbacks, this );
    libvlc_event_attach( eventManager, libvlc_MediaPlayerPaused,          callbacks, this );
    libvlc_event_attach( eventManager, libvlc_MediaPlayerStopped,         callbacks, this );
    libvlc_event_attach( eventManager, libvlc_MediaPlayerEndReached,      callbacks, this );
    libvlc_event_attach( eventManager, libvlc_MediaPlayerPositionChanged, callbacks, this );
    libvlc_event_attach( eventManager, libvlc_MediaPlayerLengthChanged,   callbacks, this );
    libvlc_event_attach( eventManager, libvlc_MediaPlayerEncounteredError,callbacks, this );
    libvlc_event_attach( eventManager, libvlc_MediaPlayerPausableChanged, callbacks, this );
    libvlc_event_attach( eventManager, libvlc_MediaPlayerSeekableChanged, callbacks, this );
}

void LibVLC::callbacks( const libvlc_event_t* event, void* ptr )
{
    LibVLC* self = reinterpret_cast<LibVLC*>( ptr );
	
    switch ( event->type )
    {
		case libvlc_MediaPlayerPlaying:
			self->flags[1]=1;
			self->setInitProps();
			break;
		case libvlc_MediaPlayerPaused:
			self->flags[2]=1;
			break;
		case libvlc_MediaPlayerStopped:
			self->flags[3]=1;
			break;
		case libvlc_MediaPlayerEndReached:
			self->flags[4]=1;
			break;
		case libvlc_MediaPlayerTimeChanged:
			self->flags[5]=event->u.media_player_time_changed.new_time;
			break;
		case libvlc_MediaPlayerPositionChanged:
			self->flags[6]=event->u.media_player_position_changed.new_position;
			break;
		case libvlc_MediaPlayerLengthChanged:
			self->flags[7]=event->u.media_player_length_changed.new_length;
			break;
		case libvlc_MediaPlayerSnapshotTaken:
			break;
		case libvlc_MediaPlayerEncounteredError:
			self->flags[9]=1;
			
			break;
		case libvlc_MediaPlayerSeekableChanged:
			self->flags[10]=1;
			break;
		case libvlc_MediaPlayerOpening:
			self->flags[11]=1;
			break;
		case libvlc_MediaPlayerBuffering:
			self->flags[12]=1;
			break;
		case libvlc_MediaPlayerForward:
			self->flags[13]=1;
			break;
		case libvlc_MediaPlayerBackward:
			self->flags[14]=1;
			break;
		default:
			break;
    }
	
}