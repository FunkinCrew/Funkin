<p align="center"> 
<img src="https://user-images.githubusercontent.com/59097731/121178442-29003c00-c867-11eb-8851-b07d2c5ca7b6.png" width="600" />
</p>
  
This is the repository for Friday Night Funkin, a game originally made for Ludum Dare 47 "Stuck In a Loop".

Play the Ludum Dare prototype here: https://ninja-muffin24.itch.io/friday-night-funkin
Play the Newgrounds one here: https://www.newgrounds.com/portal/view/770371
Support the project on the itch.io page: https://ninja-muffin24.itch.io/funkin

IF YOU MAKE A MOD AND DISTRIBUTE A MODIFIED / RECOMIPLED VERSION, YOU MUST OPEN SOURCE YOUR MOD AS WELL

# download

https://github.com/luckydog7/Funkin-android/releases



# screenshots
<div>
<img src="https://user-images.githubusercontent.com/59097731/104103630-31eae280-52b4-11eb-90a4-5bdb1b39fc53.jpg" width="200" />
<img src="https://user-images.githubusercontent.com/59097731/104103635-34e5d300-52b4-11eb-96f8-13910580fbc8.jpg" width="200" />
<img src="https://user-images.githubusercontent.com/59097731/104103636-36af9680-52b4-11eb-8740-f7be0c098265.jpg" width="200" />
<img src="https://user-images.githubusercontent.com/59097731/104103637-37e0c380-52b4-11eb-8f84-87892f3e5d85.jpg" width="200" />
</div>

# Build instructions

1. first of all we need to set up haxe and haxeflixel read more here - https://github.com/ninjamuffin99/Funkin

  - Install haxe 4.2.2 instead of 4.1.5
  - if you updated it dont forget execute this command 'haxelib upgrade' and press 'y' everywhere
  - Also get extension-webm using this command: 'haxelib git extension-webm https://github.com/KlavierGayming/extension-webm'
  - the reason we use a different repo again is cuz of a lil error that happens with the audio sync, just adds a "public var renderedFrames" instead of "var renderedFrames", that's all extra that's needed


2. after that, download Android studio, Jdk, Ndk revision 15c from these sites

  - jdk - https://www.oracle.com/java/technologies/javase/javase-jdk8-downloads.html

  - android studio - https://developer.android.com/studio

  - ndk - https://developer.android.com/ndk/downloads/older_releases?hl=fi


3.install jdk, android studio 
  - unzip ndk (ndk does not need to be installed)


4. we need to set up android studio for this go to android studio and find android sdk (in settings -> Appearance & Behavior -> system settings -> android sdk)
![andr](https://user-images.githubusercontent.com/59097731/104179652-44346000-541d-11eb-8ad1-1e4dfae304a8.PNG)
![andr2](https://user-images.githubusercontent.com/59097731/104179943-a9885100-541d-11eb-8f69-7fb5a4bfdd37.PNG)


5.and run command `lime setup android`
  - you need to insert the program paths

  - as in this picture (use jdk, not jre)
![lime](https://user-images.githubusercontent.com/59097731/104179268-9e80f100-541c-11eb-948d-a00d85317b1a.PNG)

  - Now do "lime rebuild extension-webm windows" (in the command line), if you're planning to build for windows. If you're plannin to build for android (which you obviously are), use "lime rebuild extension-webm android". If you get an error, download [this](https://www.mediafire.com/file/8jteungeq2bzc3l/Android.zip/file) and put the folder inside it in C:/HaxeToolkit/haxe/lib/extension-webm/git/ndll


7. open project in command line `cd (path to fnf source)`
  - and run command `lime build android -final`
  - apk will be generated in this path (path to source)\export\release\android\bin\app\build\outputs\apk\debug\Funkin-debug.apk


## Credits / shoutouts

- [ninjamuffin99](https://twitter.com/ninja_muffin99) - Programmer
- [PhantomArcade3K](https://twitter.com/phantomarcade3k) and [Evilsk8r](https://twitter.com/evilsk8r) - Art
- [Kawaisprite](https://twitter.com/kawaisprite) - Musician
- [luckydog (me!)](https://github.com/luckydog7) - android port

This game was made with love to Newgrounds and it's community. Extra love to Tom Fulp.


![amogus](https://user-images.githubusercontent.com/59097731/121178490-34ebfe00-c867-11eb-8a42-f2bb37bcca69.png)
