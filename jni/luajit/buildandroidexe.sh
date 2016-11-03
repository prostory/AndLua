#! /bin/sh 

arm-linux-androideabi-gcc src/luajit.c -o luajit android/armeabi/libluajit.a -Isrc -lm -pie
