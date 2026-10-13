# QT Slice

Motor de ritmo para Friday Night Funkin', basado en V-Slice 0.8.7, desarrollado por Alonso Studio.

QT Slice **no es un producto oficial** de The Funkin' Crew. "Friday Night Funkin'" y su logo son marcas de The Funkin' Crew Inc.

## Licencia

El código fuente se distribuye bajo la licencia Apache 2.0, igual que V-Slice. Ver [LICENSE.md](LICENSE.md).

Los assets (música, sprites, personajes y demás) no forman parte de este repositorio y tienen su propia licencia.

## Assets y arte

Este repositorio usa dos submódulos, que debes bajar antes de compilar:

- `assets/`: https://github.com/FunkinCrew/Funkin.assets
- `art/`: https://github.com/FunkinCrew/Funkin.art

Al clonar, usa:

```
git clone --recurse-submodules https://github.com/joaquin-hubx/QTSlice-Engine.git
```

## Compilar

Sigue la guía de compilación de V-Slice en [docs/COMPILING.md](docs/COMPILING.md). Las dependencias están en `hmm.json` y se instalan con `hmm install`.

En Windows, después de instalar las dependencias:

```
lime rebuild windows
lime test windows
```

## Cambios respecto a V-Slice 0.8.7

- Middlescroll: notas del jugador centradas y notas del oponente ocultas.
- Ghost tapping como opción en Preferencias.
- Barra de tiempo con el nombre de la canción y el tiempo, arriba en downscroll y abajo en upscroll.
- Juicio perfect a 5 ms, con su propio popup.
- Panel de conteos (Perfect, Sick, Good, Bad, Shit, Miss) y rango.
- Botplay con dos modos: No Score y Save Score.
- Offset de input separado del offset de audio, y medidor de timing.
- Parser de texturas KTX1, con pruebas en `tests/ktx/` (en desarrollo).
- Paquete `dev.alonsostudio.qtslice` y nombre "QT Slice" en los metadatos.

## Créditos

- The Funkin' Crew, por Friday Night Funkin' y V-Slice.
- Alonso Studio, por QT Slice.
