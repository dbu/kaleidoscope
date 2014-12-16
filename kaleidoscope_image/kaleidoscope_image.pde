import java.io.File;
import java.io.FilenameFilter;

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

/** for fiducal treatment. remove next line and section at bottom if you do not use this */
import TUIO.*;

/***** some configuration options *****/

/** show debug messages */
public static final boolean DEBUG = false;

/** factor to scale kaleidoscope to save high resolution */
public final static int scalefactor = 1; // > 1 won't work in full screen mode


/***** you probably do not need to adjust variables below here *****/

private KeyboardController controller;

private TuioProcessing tuioClient;

private String[] patterns;
private int patternIndex;
private PImage[] patternsImage;

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
    int screenradius = min(displayWidth, displayHeight)/2;
    int size = max(displayHeight, screenradius*2*scalefactor);
    size(size, size, OPENGL);
    noSmooth();
    frameRate(30);

    controller = new KeyboardController(screenradius, scalefactor, true, DEBUG);

    // set system look and feel for swing (open image file dialog)
    try {
        UIManager.setLookAndFeel(UIManager.getSystemLookAndFeelClassName());
    } catch (Exception e) {
        e.printStackTrace();
    }

    String mypath = "/home/david";
    File dir = new File(mypath); //dataPath("")); no longer seems to work
    patterns = dir.list(
        new FilenameFilter() {
            public boolean accept(File dir, String name) {
                return /*name.endsWith(".png") || */name.endsWith(".jpg");
            }
    });
    patternsImage = new PImage[patterns.length];
    for (int i=0; i<patterns.length; i++) {
        patternsImage[i] = loadImage(fuck + "/" + patterns[i]);
    }
    controller.changeImage(patternsImage[0], patterns[0], true);
        
    tuioClient  = new TuioProcessing(this);
}

/**
 * main draw loop: forward to KaleidoscopeController
 */
void draw() {
  try {
    controller.draw();
  }catch(Throwable t) {t.printStackTrace();}
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

private void cicleImage(int direction) {
    patternIndex += direction;
    if (patternIndex < 0) patternIndex = patterns.length - 1;
    if (patternIndex >= patterns.length) patternIndex = 0;
    
    println(patternIndex);
    controller.changeImage(patternsImage[patternIndex], patterns[patternIndex], true);
}

/************* Mouse & Keyboard control *************************************/

/**
 * forward mouse movement to KeyboardController
 */
public void mouseDragged() {
    controller.mouseDragged();
}


/**
 * handle key strokes (numbers, r, R, s, o)
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
            //TODO: use page up and down
        case 'n':
            cicleImage(1);
        default:
            controller.keyReleased();
            break;
    }
}

/************* TUIO control *** VARIANT: mover and selector ******************/

private float lastAngle = -7;
private final float ANGLE = HALF_PI/2;
private final int moveId = 4;
private final int selectorId = 5;


/** 
 * handle tuio events and forward to controller 
 *//*
void updateTuioObject (TuioObject tobj) {
    switch(tobj.getSymbolID()) {
        case moveId:
            controller.setPositionFraction(tobj.getPosition().getX() * 2 - 1, tobj.getPosition().getY() * 2 - 1);
            controller.rotate(tobj.getAngle());
            break;
        case selectorId:
            // list of available files in patterns
            float angle = tobj.getAngle();
            if (lastAngle == -7) {
                lastAngle = angle;
            } else {
                float diff = lastAngle - angle;
                if (diff > PI) diff -= TWO_PI;
                if (diff < -PI) diff += TWO_PI;
                if (diff < -ANGLE) {
                    cicleImage(1);
                    lastAngle = angle;
                } else if (diff > ANGLE) {
                    cicleImage(-1);
                    lastAngle = angle;
                }
            }
            break;
    }
}*/


/************* TUIO control *** VARIANT: token id image ******************/

private int currentId = -1;

/** 
 * handle tuio events and forward to controller 
 */
void updateTuioObject (TuioObject tobj) {
  if (tobj.getSymbolID() != currentId) return;
  
  controller.setPositionFraction(tobj.getPosition().getX() * 2 - 1, tobj.getPosition().getY() * 2 - 1);
  controller.rotate(tobj.getAngle());
}

void addTuioObject(TuioObject tobj) {
    if (currentId >= 0) return;
    
    currentId = tobj.getSymbolID();
    controller.changeImage(patternsImage[currentId], patterns[currentId], true);
}

void removeTuioObject(TuioObject tobj) {
    if (tobj.getSymbolID() != currentId) return;
    
    currentId = -1;
    PImage black = createImage(500,500,RGB);
    controller.changeImage(black, "black", true);
}

