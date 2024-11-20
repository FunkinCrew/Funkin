Hello there,
If you are reading this, I've likely already been captured, tortured, and murdered.
I'm sharing with you the secrets I know about The Funkin' Crew's secret formula for video encoding.

This letter is meant for those of you who hate compression artifacts,
those who wince at h264 blocks, Those who share in my anguish of
blurring anytime static or confetti appear.

These settings may not work for each and every application,
but I've found them to be a good tradeoff between quality, and filesize.

Using Handbrake 1.8.2 (can likely use an earlier or later version)
This is a bit of an offshoot of the "Fast 720p30" preset, so you can start there.

Filters
- Interlace Detection: Off
- Deinterlate: Off

Video
- Video Encoder: H.265 (x265)
  - Uses H.265 on the CPU encoder, since GPU/Hardware encoding has more artifacts.
- Framerate: Same as source - Constant Framerate
- Quality: Constant Quality RF21
  - The number can be tweaked as desired a lil bit

- Preset: veryslow
  - differences between slow and veryslow might be marginal
- Tune: Animation
  - Different tuning could yield better results, I simply went with this one since it said animation!
- Profile: Auto
- Level: Auto
  - 3.1 might be good for 720p @ 24fps


Audio
- Codec: AAC
- Biterate: close to whatever source bitrate is, max should be 192kbps prob


To whoever reads this, best wishes and good luck.
In my dying breaths, I will be thinking about a world with good
video compression.
Godspeed, and thank you for reading.

- The Funkin' Crew Inc.
