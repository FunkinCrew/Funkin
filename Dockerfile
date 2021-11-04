FROM haxe:4.1.5-buster

# Installing sudo as a workaround for lime that uses sudo in it's setup (sorry I'm lazy to try to find a good solution for it)
RUN apt update && apt install git sudo -y

# Install haxe dependencies
RUN haxelib install lime \ 
    && haxelib install flixel \ 
    && haxelib install flixel-addons \ 
    && haxelib install flixel-ui \
    && haxelib install hscript \ 
    && haxelib install newgrounds \ 
    && haxelib install openfl \ 
    && haxelib git polymod https://github.com/larsiusprime/polymod.git \ 
    && haxelib git discord_rpc https://github.com/Aidan63/linc_discord-rpc.git \ 
    && haxelib git flixel-addons https://github.com/HaxeFlixel/flixel-addons

# Setup lime
RUN haxelib run lime setup -y

WORKDIR /fnf

# This will require to use -v argument pointing to your FNF source code using /fnf as destination when the container is run
VOLUME /fnf

ENTRYPOINT ["lime", "build", "html5"]

