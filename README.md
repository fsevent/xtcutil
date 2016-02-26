# xtcutil

xtcutil is a tool for xtrkcad file.
It can be used to extract information as JSON.

## Usage

    /usr/bin/ruby -Ilib bin/xtcutil graph foo.xtc

## Prerequisite

mandatory:
- Ruby

optional:
- rcairo (to generate images)
- Ruby-GNOME2 (to display window)

On Debian GNU/Linux 8.1 (jessie), following commands installs the prerequisite.

    aptitude install ruby ruby-gnome2

## Author

Tanaka Akira

## Acknowledgments

This program is developed in a joint research project by
AIST and JR East in 2015.

## Licence

GPLv2 or later
