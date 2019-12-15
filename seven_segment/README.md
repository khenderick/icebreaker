# The seven segment PMOD

Code to play around with the 7 segment PMOD.

### Overview

Pinout: https://en.wikipedia.org/wiki/File:7_Segment_Display_with_Labeled_Segments.svg

Two 7 segment displays are placed after eachother. The `CATHODE` pin selects which display will
be active. This implies that both digits needs to be refreshed very fast, one after the other
to give the impression that both are on at the same time.

### Usage

1. Rename one of the modules in `seven_segment.v` to `top`.
2. Run `make && make prog` while the board is connected to put the code on the board
