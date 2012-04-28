/**
 * Picture Kaleidoscope
 * by David Buchmann <mail at davidbu.ch>
 *
 * The default image is a part of a painting done by my mother, see
 * http://www.catherinebuchmann.ch
 *
 * Move mouse to change image part that is shown
 *   - left button pressed to move the image
 *   - right button and move left and right to rotate
 *
 * Keys:
 *   - 0 to 9: set number of mirror axis
 *   - r / R: accelerate/decelerate rotation of the resulting image
 *   - s: save snapshot (timestamped .png file in current folder)
 *        if you set scalefactor to more than 1, you get higher resolution images
 *   - o: open a different image file
 *
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

import javax.swing.filechooser.*;
import javax.swing.*;

/***** some configuration options *****/

/** show debug messages */
public static final boolean DEBUG = false;

/** factor to scale kaleidoscope to save high resolution */
public final static int scalefactor = 1; // > 1 won't work in full screen mode


/***** you probably do not need to adjust variables below here *****/

private KaleidoscopeController controller;

/**
 * start application
 */
static public void main(String args[]) {
    PApplet.main(new String[] { "--present", "kaleidoscope_image" });
}

/**
 * prepare the sketch
 */
void setup() {
    int screenradius = min(screen.width, screen.height)/2;
    int size = max(screen.height, screenradius*2*scalefactor);
    size(size, size, OPENGL);
    smooth();//default for opengl anyways
    frameRate(30);

    controller = new KaleidoscopeController(screenradius, scalefactor, true, DEBUG);

    //load default pattern so that we see something
    PImage i = loadImage("pattern.jpg");
    if (i == null) throw new RuntimeException("pattern.jpg not found");
    controller.changeImage(i, "pattern.jpg", true);

    // set system look and feel for swing (open image file dialog)
    try {
        UIManager.setLookAndFeel(UIManager.getSystemLookAndFeelClassName());
    } catch (Exception e) {
        e.printStackTrace();
    }
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
 * handle key strokes, forward everything unknown to the KaleidoscopeController
 */
public void keyReleased() {
    switch(key) {
        case 'o':
            new Thread () { //do not block window drawing thread
                public void run() {
                chooseImage();
                }
            }.start();
            break;
        default:
            controller.keyReleased();
            break;
    }
}

/**
 * show a file chooser dialog and load new image if image was selected
 */
private void chooseImage() {
    JFileChooser fc = new JFileChooser();
    if (JFileChooser.APPROVE_OPTION == fc.showOpenDialog(this)) {
        File f = fc.getSelectedFile();
        controller.changeImage(loadImage(f.getPath()), f.getName(), true);
    }
}
