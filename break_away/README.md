# The break-away PMOD

Code to play around with the break-away PMOD. I broke it away and soldered on the 
headers, but that's because I like to solder.

### Led and button overview

```
Leds:

    L2
 L5 L1 L4
    L3

Buttons:

B3 B2 B1
```

### Usage

1. Rename one of the modules in `break_away.v` to `top`.
2. Run `make && make prog` while the board is connected to put the code on the board
