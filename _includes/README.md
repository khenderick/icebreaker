# Generic "include" modules

### clock_divider.v

This module scales down a given clock.

It works by incrementing a register with a width of `SCALE` bits. Every time the counter overflows,
the output clock is toggled. The default `SCALE` is set to `20`.

Parameters:

* *i_clock*: Input, the input clock
* *o_clock*: Output, the slower output clock

Usage:

```
module top(CLOCK, ...)
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
module top(CLOCK, ...)
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
module top(CLOCK, BUTTON, ...)
    ...
    wire clean_button;
    ...
    button_debouncer debouncer_3(
        .i_clock(CLOCK),
        .i_button(BUTTON),
        .o_state(clean_button)
    );
    ...
```

With `DELAY` parameter:

```
module top(CLOCK, BUTTON, ...)
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

### icebreaker.pcf

