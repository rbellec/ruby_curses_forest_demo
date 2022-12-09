# Simple test of Curses lib in Ruby

simply run

```sh
ruby curse_ascii_trees.rb
```

During AoC 2022 I wanted to use some term animations and discovered I did not know
how to do this anymore.

I liked the idea of growing trees on the term shown on https://youtu.be/uUhAtMQLLeE
and decided to adapt this and create a simple animations using Curses lib.

The `main_print` method print the forest as text as shown in the video.
The `main_curse` method (the one currently used when script is executed) create a window in terminal
and start the animation there.

I may make a video tuto if it helps (beware of french people speaking english though)
