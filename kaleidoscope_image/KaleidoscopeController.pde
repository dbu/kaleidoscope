import java.text.DateFormat;
import java.text.SimpleDateFormat;
import java.util.Date;

/**
 * Picture Kaleidoscope
 * by David Buchmann <mail at davidbu.ch>
 *
 * Controller to handle mouse movement and characters.
 *
 * Forward the draw, mouseDragged and keyReleased events to this class
 * Update the current image with the changeImage method.
 *
 * For use with asynchronous inputs like tuio, we need to synchronize most of the methods. 
 *
 * (c) David Buchmann, 2010
 *
 * This code is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License.This program is distributed in
 * the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the
 * implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 * See the GNU General Public License for more details.
 */
class KaleidoscopeController {
    /** show debug messages */
    private boolean DEBUG;
    
    private boolean snapshot = false, pushed = false; 

    /** control the amount 'r' and 'R' change the rotation speed */
    private static final float ROTATE_INCREMENT = 0.005;

    /** factor to scale kaleidoscope to save high resolution */
    private int scalefactor; // > 1 won't work in full screen mode

    /** radius of a circle fitting onto the screen */
    private int screenradius;

    /** current rotation situation of the whole screen */
    private float baserotate;
    /** current rotation increment to change baserotate in each draw phase */
    private float rotateKal = 0;

    //the H variables are used when saving with a scalefactor > 1
    /** buffer holding the base picture to draw */
    private PImage img, imgH;
    /** an offscreen graphic to draw the image with translate and rotate, and mask away to have a nice slice of pie form */
    private PGraphics graph, graphH;
    /** the kaleidoscope instance to draw the graph */
    private Kaleidoscope kaleidoscope, kaleidoscopeH;

    /** change part of img that is put into graph: x, y are move, z is used for rotation */
    private PVector drag = new PVector(0,0,0);;
    /** previous drag position, to see if graph needs to be redrawn */
    private PVector lastDrag = new PVector(1,1,1); //initial content ignored but must be different from drag to trigger initial drawing of the screen
    /** used for smooth movement. the next draw uses part of last speed and changes acceleration based on mouse movement */
    private PVector lastd = new PVector(0,0,0);
    
    /** whether the graph has to be refreshed */
    private boolean refresh = false;

    /** current file name, to use with snapshot saving */
    private String imagename;


    /** statistics/debug */
    float now=0;
    PFont font;

    /**
     * Create this controller.
     *
     * @param screenradius the radius of the kaleidoscope on screen
     * @param scalefactor to scale the snapshots to higher resolution
     * @param debug whether to show debug information
     */
    public KaleidoscopeController(int screenradius, int scalefactor, boolean debug) {
        this.screenradius = screenradius;
        this.scalefactor = scalefactor;
        this.DEBUG = debug;

        kaleidoscope = new Kaleidoscope(16, screenradius);
        graph = kaleidoscope.getBuffer();
        if (scalefactor != 1) {
            kaleidoscopeH = new Kaleidoscope(16, screenradius*scalefactor);
            graphH = kaleidoscopeH.getBuffer();
        }
        if(DEBUG) {
            font = loadFont("Arab-24.vlw");
        }
    }

    /**
     * Get kaleidoscope buffer to draw directly into it
     */
    public synchronized PGraphics getBuffer() {
      return kaleidoscope.getBuffer();
    }
    public Kaleidoscope getKaleidoscope() {
      return kaleidoscope;
    }

    /**
     * change the image to a new one
     *
     * @param i the new imagethe file to load
     * @param name the image name to use when storing snapshots
     */
    public synchronized void changeImage(PImage i, String name, boolean reset) {
        try {
            img = (PImage) i.clone();
            img.resize(Math.round(screenradius*1.5),0);

            if (scalefactor != 1) {
                imgH = (PImage) i.clone();
                imgH.resize(Math.round(screenradius*scalefactor*1.5),0);
            }

            imagename = name;
            
            refresh = true;

            if (reset) {
            //reset movement
            drag.x = 0;
            drag.y = 0;
            drag.z = 0;
            lastDrag.x = 0;
            lastDrag.y = 0;
            lastDrag.z = 0;
            }
        } catch(CloneNotSupportedException e) {
            //ignore
        }
    }

    /**
     * draw loop
     */
    public synchronized void draw() {
        if (snapshot) return;
        pushMatrix();
        pushed = true;
        background(0);
        if (DEBUG) {
            float t = millis();
            if (t > now+1000) {
                println("fps "+Math.round(frameRate));
                now = t;
            }
        }

        if (refresh || drag.x != lastDrag.x || drag.y != lastDrag.y || drag.z != lastDrag.z) {
            updateGraph(graph, img, 1);
            if (scalefactor != 1) {
                updateGraph(graphH, imgH, scalefactor);
            }
            lastDrag.x = drag.x;
            lastDrag.y = drag.y;
            lastDrag.z = drag.z;
        }
    
        //center the screen
        int shiftx = (width - height)/2;
        if (scalefactor > 1) shiftx += (displayWidth-displayHeight)/2;
        translate(shiftx,0);
        baserotate += rotateKal;
        baserotate %=  TWO_PI;
        kaleidoscope.draw(graph,baserotate);

        if (DEBUG) {
            textFont(font, 14);
            fill(0xFFFFFFFF);
            text("fps "+Math.round(frameRate), 15, 15);
            fill(0);
            text("fps "+Math.round(frameRate), 15, 30);
        }
        if (! snapshot) popMatrix();
        pushed = false;
    }

    public synchronized void move(int dx, int dy) {
            lastd.x = dx * 0.1 + lastd.x * 0.9;
            lastd.y = dy * 0.1 + lastd.y * 0.9;
            drag.x += lastd.x;
            drag.y += lastd.y;
            if (drag.x > graph.width) drag.x = graph.width;
            if (drag.x < -img.width) drag.x = -img.width;
            if (drag.y > graph.height) drag.y = graph.height;
            if (drag.y < -img.height) drag.y = -img.height;      
    }

    /** increment the rotation by r */
    public synchronized void rotateIncrement(float r) {
      drag.z += r;
    }

    /** set the rotation to r */
    public synchronized void rotate(float r) {
      drag.z = r;
    }
    
    /** set position from -1 to 1 */
    public synchronized void setPositionFraction(float x, float y) {
        if (x < -1 || x > 1 || y < -1 || y > 1) return;
        drag.x = graph.width * x;
        drag.y = graph.height * y;
    }
    
    /**
     * update the buffer with the image in current position,
     *
     * called from main draw loop when image was moved around
     *
     * @param i the image to draw onto the buffer
     * @param m scaling factor relative to the screenradius
     */
    private synchronized void updateGraph(PGraphics graph, PImage i, int m) {
        graph.beginDraw();
        graph.translate(drag.x*m,drag.y*m);
        graph.translate(m*screenradius/2,m*screenradius/2);
        graph.rotate(drag.z);
        graph.translate(-m*screenradius/2,-m*screenradius/2);
        graph.image(i,0,0);
        graph.endDraw();
    }

    public void increaseRotate() {
        rotateKal += ROTATE_INCREMENT;      
    }
    public void decreaseRotate() {
        rotateKal -= ROTATE_INCREMENT;
    }

    /**
     * Change the number of axis of the kaleidoscope
     *
     * Will create a new Kaleidoscope instance and a new buffer for the slice of pie
     *
     * @param segments the number of segments to use
     */
    public synchronized void setSegmentNumber(int segments) {
        PGraphics oldg = graph;
        kaleidoscope = new Kaleidoscope(segments, screenradius);
        graph = kaleidoscope.getBuffer();
        graph.image(oldg,0,0);

        if (scalefactor != 1) {
            oldg = graphH;
            kaleidoscopeH = new Kaleidoscope(segments, screenradius*scalefactor);
            graphH = kaleidoscopeH.getBuffer();
            graphH.image(oldg,0,0);
        }

        lastDrag.x += 0.0001; //trigger redraw
    }

    /**
     * Save a picture of the current screen to the file system (after key s pressed)
     *
     * Filename consists of kaleidoscope, the current file name and a timestamp
     * to avoid overwriting existing files
     *
     * If scalefactor is more than 1, the kaleidoscopeH is drawn and saved instead
     * of the current screen.
     */
    public synchronized void saveSnapshot() {
        snapshot = true;
        if (pushed) popMatrix();
        if (scalefactor != 1)  {
            background(0);
            //center the screen
            translate((width - height)/2,0);

            kaleidoscopeH.draw(graphH, baserotate);
        }
        DateFormat f = new SimpleDateFormat("'kaleidoscope_"+imagename+"_'yyyy-MM-dd_HH-mm-ss'.png'");
        String imgfile = f.format(new Date());
        try {
            save("/home/david/" + imgfile);
        } catch(RuntimeException t) {
            t.printStackTrace();
            println("Failed to save current state to "+imgfile);
        }
        snapshot = false;
    }
}
