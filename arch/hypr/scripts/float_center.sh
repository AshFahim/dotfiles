#!/usr/bin/env bash

hyprctl dispatch 'hl.dsp.window.float({ action = "set" })'
hyprctl dispatch 'hl.dsp.window.resize({ x = 1440, y = 900 })'
hyprctl dispatch 'hl.dsp.window.center()'
