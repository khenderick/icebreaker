# Generic "include" modules

### bcd.v

This module converts a nibble (4 bits) to seven segments.

Parameters:

* `i_nibble`: Input, nibble to convert
* `o_segments`: Output, segments

Usage:

```
module top(SEV_SEGMENT);
    ...
    reg [6:0] segments;
    reg [7:0] counter;
    ...
    assign SEV_SEGMENT = ~segments; // active-low
    ...
    bcd digit(
        .i_nibble(counter[3:0])
        .o_segments(segments)
    );
    ...
```

### button_counter.v

This module allows to increase, decrease and reset a counter. By default, it supports a 4-bit counter
but this can be configured using the `WIDTH` parameter.

Parameters:

* `i_clock`: Input, input clock
* `i_button_inc`: Input, button to use for incrementing
* `i_button_dec`: Input, button to use for decrementing
* `i_button_reset`: Input, button to reset the counter
* `o_counter`: Output, the counter

Usage:

```
module top(CLOCK, BUTTON_INC, BUTTON_DEC, BUTTON_RESET, ...);
    ...
    reg [3:0] counter;
    ...
    button_counter b_counter(
        .i_clock(CLOCK),
        .i_button_inc(BUTTON_INC),
        ...
        .o_counter(counter)
    );
    ...
```

With `WIDTH` parameter:

```
module top(CLOCK, BUTTON_INC, BUTTON_DEC, BUTTON_RESET, ...);
    ...
    reg [7:0] counter;
    ...
    button_counter #(
        .WIDTH(8)
    ) b_counter(
        .i_clock(CLOCK),
        .i_button_inc(BUTTON_INC),
        ...
        .o_counter(counter)
    );
    ...
```

### button_debouncer.v

This module debounces physical buttons. It makes sure that pressed aren't processed multiple times due
to internal imperfections. It has a `DELAY` parameter that defaults to `12` to configure how aggressive
the debouncing must be. Internally, it forwards the `DELAY` to a clock divider's `SCALE` parameter.

Parameters:

* `i_clock`: Input, input clock
* `i_button`: Input, button to debounce
* `o_state`: Output, a stable/debounced mirror of `i_button`
* `o_press_event`: Output, pulses quickly when `i_button` is pressed
* `o_release_event`: Output, pulses quickly when `i_button` is released

Usage:

```
module top(CLOCK, BUTTON, ...);
    ...
    wire clean_button;
    ...
    button_debouncer debouncer(
        .i_clock(CLOCK),
        .i_button(BUTTON),
        .o_state(clean_button)
    );
    ...
```

With `DELAY` parameter:

```
module top(CLOCK, BUTTON, ...);
    ...
    wire clean_button;
    ...
    button_debouncer #(
        .DELAY(12)
    ) debouncer(
        .i_clock(CLOCK),
        .i_button(BUTTON),
        .o_state(clean_button)
    );
    ...
```

### button_repeater.v

This module outputs the state of an input button, but will emulate repeated pressed if the input button
is hold down for a certain amount of time. It has a `REPEAT_WAIT` parameter that defaults to `6` to configure
how hold the button needs to be held down before the repeating starts. It also has a `REPEAT_FREQ` parameter that
defaults to `2` that configures how fast button presses are emulated.

Parameters:

* `i_clock`: Input, input clock
* `i_button`: Input, input button
* `o_button`: Output, virtual output button

Usage:

```
module top(CLOCK, BUTTON, ...);
    ...
    wire output_button;
    ...
    button_repeater repeater(
        .i_clock(CLOCK),
        .i_button(BUTTON),
        .o_button(output_button)
    );
    ...
```

With parameters:

```
module top(CLOCK, BUTTON, ...);
    ...
    wire clean_button;
    ...
    button_repeater #(
        .REPEAT_WAIT(12),
        .REPEAT_FREQ(4)
    ) repeater(
        .i_clock(CLOCK),
        .i_button(BUTTON),
        .o_button(output_button)
    );
    ...
```

### clock_divider.v

This module scales down a given clock.

It works by incrementing a register with a width of `SCALE` bits. Every time the counter overflows,
the output clock is toggled. The default `SCALE` is set to `20`.

Parameters:

* `i_clock`: Input, the input clock
* `o_clock`: Output, the slower output clock

Usage:

```
module top(CLOCK, ...);
    ...
    wire slow_clock;
    ...
    clock_divider divider(
        .i_clock(CLOCK),
        .o_clock(slow_clock)
    );
    ...
```

The module can also be parameterized to control the scale:

```
module top(CLOCK, ...);
    ...
    wire slow_clock;
    ...
    clock_divider #(
        .SCALE(12)
    ) divider(
        .i_clock(CLOCK),
        .o_clock(slow_clock)
    );
    ...
```

### icebreaker.pcf

Pin definitions for the iCEBreaker FPGA. Can be found in a lot of places, but I had to
make (adapt) my own with longer names. I don't like 3-character cryptic names.
