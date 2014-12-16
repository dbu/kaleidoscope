/**
 * Webcam Kaleidoscope
 * by David Buchmann <mail at davidbu.ch>
 *
 * Kaleidoscope with the video stream from a web cam
 *
 * Move mouse to change image part that is shown
 *   - left button pressed to move the image
 *   - right button and move left and right to rotate
 *
 * Keys:
 *   - 0 to 9: set number of mirror axis
 *   - r / R: accelerate/decelerate rotation of the resulting image
 *   - s: save snapshot (timestamped .png file in current folder)
 *
 *
 * TODO: find something more portable than gsvideo?
 *
 * (c) David Buchmann, 2010
 *
 * This code is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License.This program is distributed in
 * the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the
 * implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 * See the GNU General Public License for more details.
 */

import processing.opengl.*;
import codeanticode.gsvideo.*;

static final boolean DEBUG = true;

GSPipeline video;

/** should autodetect these */
int vidwidth=640;
int vidheight=480;
int fps = 30;

/** limit radius on large screen */
int maxradius = vidwidth + vidwidth/2;

KeyboardController controller;

/** statistics/debug */
float now=0, t=0; int imgcount=0, noimgcount=0;

/**
 * prepare the sketch
 */
void setup() {
    size(displayWidth, displayHeight, OPENGL);
    smooth();//default for opengl anyways
    frameRate(30);

    int radius = min(maxradius, displayHeight/2);

    // Uses the default video input, suitable for ps3 eye cam and also my laptops in-built web cam. see the reference if this causes an error
    video = new GSPipeline(this, "v4l2src name=video_source device=/dev/video0 ! video/x-raw-yuv,width="+vidwidth+",height="+vidheight+",framerate="+fps+"/1 ! identity");

    controller = new KeyboardController(radius, 1, true, DEBUG);

    //init image until we get first camera picture
    controller.changeImage(createImage(1,1,RGB), "dummy", false);
}

/**
 * main draw loop: update image from web cam and forward to KaleidoscopeController
 */
void draw() {
    background(0);
    t = millis();
    if (t > now+1000) {
        if (DEBUG) println("imgs "+imgcount+" / noimg "+noimgcount);
        imgcount=0;noimgcount=0;
        now = t;
    }

    if (video.available()) {
         imgcount++;
         video.read();
         controller.changeImage(video.get(0,0,vidwidth,vidheight), "camera", false);
         //img.resize(halfsize,bufferheight);
    } else {
         noimgcount++;
    }

    controller.draw();
}

/**
 * forward mouse movement to KaleidoscopeController
 */
public void mouseDragged() {
    controller.mouseDragged();
}

/**
 * forward keyboard strokes to KaleidoscopeController
 */
void keyReleased() {
    controller.keyReleased();
}
