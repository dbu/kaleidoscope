/**
 * Generative Kaleidoscope
 * by David Buchmann <mail at davidbu.ch>
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

public final int MINSTEP = 3;
public final int MAXSTEP = 22;


/***** you probably do not need to adjust variables below here *****/

private KeyboardController controller;

private TuioProcessing tuioClient;

int screenradius;
int step = MINSTEP;
float colorcycle = 0;
float movement = 0;
float movement2 = 0;
float rotate = 0;
boolean up = true;
PGraphics buffer;
Kaleidoscope kaleidoscope;

/**
 * start application
 */
 /*
static public void main(String args[]) {
    PApplet.main(new String[] { "--present", "kaleidoscope_pattern" });
}*/

/**
 * prepare the sketch
 */
void setup() {
    screenradius = min(displayWidth, displayHeight)/2;
    int size = max(displayHeight, screenradius*2*scalefactor);
    size(size, size, OPENGL);
    smooth();//default for opengl anyways
    frameRate(30);

    controller = new KeyboardController(screenradius, scalefactor, true, DEBUG);
    kaleidoscope = controller.getKaleidoscope();
    buffer = kaleidoscope.getBuffer();
    background(0xFFFFFFFF);
    //init image until we get first camera picture
//    controller.changeImage(buffer, "buffer", false);
        
    tuioClient  = new TuioProcessing(this);
}

/**
 * main draw loop: forward to KaleidoscopeController
 */
void draw() {
    buffer.beginDraw();
    
    /*if (sin(colorcycle) + cos(colorcycle) < 0.5) {*/
      buffer.background(0x15FFFFFF);
/*    } else {
      */
      //buffer.background(0x15007500);
      
   // }
    //if (step % 2 == 0) buffer.filter(BLUR,1);
  
    if (step > 29) up = false;
    if (step < 3) up = true;
    if (up) step++; else step--;
    drawArc(step);
    buffer.endDraw();
    //image(buffer, 0,0);
    rotate += 0.005;
      kaleidoscope.draw(buffer, rotate);
  
}

void drawArc(int steps) {
    colorcycle += 0.04;
    movement += 0.031;
    movement2 += 0.022;
    buffer.stroke(sin(colorcycle)*255, 0, cos(colorcycle)*255, 255);
    
    int s = buffer.width;
    float factor = (float) s / steps;
    for (int i=0; i<=steps; i++) { 
      buffer.line(i*factor,0,(0.4 + 0.6*abs(sin(movement))) * (s - i * factor),(0.2*abs(cos(movement2))+0.2) * (s - i * factor));
    }
}

/**
 * handle key strokes (numbers, r, R, s, o)
 */
public void keyReleased() {
    controller.keyReleased();
}

/************* TUIO control **  delete this if you do not have tuio  **********************/

private float lastAngle = -7;
private final float ANGLE = HALF_PI/2;
private final int moveId = 4;
private final int selectorId = 5;


/** handle tuio events and forward to controller */
void updateTuioObject (TuioObject tobj) {
    switch(tobj.getSymbolID()) {
        case moveId:
            controller.setPositionFraction(tobj.getPosition().getX() * 2 - 1, tobj.getPosition().getY() * 2 - 1);
            controller.rotate(tobj.getAngle());
            break;
    }
}
