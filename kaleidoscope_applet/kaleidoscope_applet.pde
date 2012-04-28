/**
 * Picture Kaleidoscope (Applet Version)
 * by David Buchmann <mail at davidbu.ch>
 *
 * The image is a part of a painting done by my mother, see
 * http://www.catherinebuchmann.ch
 *
 * I RECOMMEND TO DOWNLOAD THE STANDALONE APPLICATION FOR A NICER EXPERIENCE
 * http://davidbu.ch/mann/blog/2011-05-15/picture-kaleidoscope-processing.html
 *
 * Move mouse to change image part that is shown
 *   - left button pressed to move the image
 *   - right button and move left and right to rotate
 *
 * Keys:
 *   - 0 to 9: set number of mirror axis
 *   - r / R: accelerate/decelerate rotation of the resulting image
 *
 *
 * I did not manage to do opengl in applet. this version uses JAVA2D and is
 * painfully slow
 *
 * (c) David Buchmann, 2010
 *
 * This code is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License.This program is distributed in
 * the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the
 * implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 * See the GNU General Public License for more details.
 */

/** side length of usable square in full screen */
public static final int radius = 230;

/** show debug messages */
public static final boolean DEBUG = false;

private KaleidoscopeController controller;

/**
 * prepare the sketch
 */
void setup() {
    size(radius*2,radius*2,JAVA2D);
    frameRate(30);

    controller = new KaleidoscopeController(radius, 1, false, DEBUG);

    //load the bundled image
    PImage i = loadImage("pattern.jpg");
    if (i == null) throw new RuntimeException("pattern.jpg not found");
    controller.changeImage(i, "applet-can-not-save", true);
}

/**
 * main draw loop: forward to KaleidoscopeController
 */
void draw() {
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
