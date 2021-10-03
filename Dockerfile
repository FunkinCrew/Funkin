FROM haxe:4.1-buster

ENV LANG en_US.UTF-8 
ENV DEBIAN_FRONTEND noninteractive

RUN apt update && apt install git -y

RUN haxelib install lime \ 
    && haxelib install flixel \ 
    && haxelib install flixel-addons \ 
    && haxelib install flixel-ui \
    && haxelib install hscript \
    && haxelib install newgrounds \
    && haxelib install openfl

RUN haxelib git polymod https://github.com/larsiusprime/polymod.git \
    && haxelib git discord_rpc https://github.com/Aidan63/linc_discord-rpc.git

COPY APIStuff.hx source

CMD [ "haxelib", "run", "lime", "build", "linux" ]