# Friday Night Funkin

This is the repository for Friday Night Funkin, a game originally made for Ludum Dare 47 "Stuck In a Loop".

Play the Ludum Dare prototype here: https://ninja-muffin24.itch.io/friday-night-funkin
Play the Newgrounds one here: https://www.newgrounds.com/portal/view/770371
Support the project on the itch.io page: https://ninja-muffin24.itch.io/funkin

## Credits / shoutouts

- [ninjamuffin99 (me!)](twitter.com/ninja_muffin99) - Programmer
- [PhantomArcade3K](twitter.com/phantomarcade3k) and [Evilsk8r](twitter.com/evilsk8r) - Art
- [Kawaisprite](twitter.com/kawaisprite) - Musician

This game was made with love to Newgrounds and it's community. Extra love to Tom Fulp.

## Build instructions

### Installing shit

First you need to install Haxe and HaxeFlixel. I'm too lazy to write and keep updated with that setup (which is pretty simple). 
The link to that is on the [HaxeFlixel website](https://haxeflixel.com/documentation/getting-started/)

That should give you HaxeFlixel and all of it's setup and shit. If you run into issues, ask them in the #flixel channel in the Haxe discord server: https://discord.gg/5ybrNNWx9S

Other installations you'd need is the additional libraries, a fully updated list will be in `Project.xml`, but here are the one's I'm using as of writing.

```
hscript
flixel-ui
newgrounds
```

so for each of those type `haxelib install [library]` so shit like `haxelib install newgrounds`

### Ignored files

I gitignore the API keys for the game, so that no one can nab them and post fake highscores on the leaderboards. But because of that the game
doesn't compile without it.

Just make a file in `/source` and call it `APIStuff.hx`, and copy paste this into it

```haxe
package;

class APIStuff
{
	public static var API:String = "";
	public static var EncKey:String = "";
}

```

and you should be good to go there.

### Compiling game

Once you have all those installed, it's pretty easy to compile game! One that you can compile right off the bat is for HTML5, 
you just need to run `lime test html5 -debug` in your command prompt in the project root. (command prompt navigation guide can be found here: [https://ninjamuffin99.newgrounds.com/news/post/1090480](https://ninjamuffin99.newgrounds.com/news/post/1090480))

To run it for your desktop (Windows, Mac, Linux) it's a bit more complicated. I know for Windows you need to download Visual Studio Community 2017 or 2019 or something, and in the libraries download in that download somethin that says build tools LOL homie im too dumb idk how to do that shit most of the time.

### Additional guides

- [Command line basics](https://ninjamuffin99.newgrounds.com/news/post/1090480)