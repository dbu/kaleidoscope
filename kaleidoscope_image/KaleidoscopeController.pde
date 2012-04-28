/**
 * Picture Kaleidoscope
 * by David Buchmann <mail at davidbu.ch>
 *
 * Controller to handle mouse movement and characters.
 *
 * Forward the draw, mouseDragged and keyReleased events to this class
 * Update the current image with the changeImage method.
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

    /** whether s key is handled or ignored */
    private boolean canSave;

    /** show debug messages */
    private boolean DEBUG;

    /** control the amount 'r' and 'R' change the rotation speed */
    private static final float ROTATE_INCREMENT = 0.005;

    /** factor to scale kaleidoscope to save high resolution */
    private int scalefactor = 1; // > 1 won't work in full screen mode

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
     * @param canSave whether the s key is used to save a snapshot or ignored
     * @param debug whether to show debug information
     */
    public KaleidoscopeController(int screenradius, int scalefactor, boolean canSave, boolean debug) {
        this.screenradius = screenradius;
        this.scalefactor = scalefactor;
        this.canSave = canSave;
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
     * change the image to a new one
     *
     * @param i the new imagethe file to load
     * @param name the image name to use when storing snapshots
     */
    public void changeImage(PImage i, String name, boolean reset) {
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
    public void draw() {
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
        translate((width - height)/2,0);
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
    }

    /**
     * track mouse movement to update image position
     */
    public void mouseDragged() {
        if (mouseButton == LEFT) {
            int dx = mouseX - pmouseX;
            int dy = mouseY - pmouseY;
            lastd.x = dx * 0.1 + lastd.x * 0.9;
            lastd.y = dy * 0.1 + lastd.y * 0.9;
            drag.x += lastd.x;
            drag.y += lastd.y;
            if (drag.x > graph.width) drag.x = graph.width;
            if (drag.x < -img.width) drag.x = -img.width;
            if (drag.y > graph.height) drag.y = graph.height;
            if (drag.y < -img.height) drag.y = -img.height;
        } else if (mouseButton == RIGHT) {
            drag.z += (mouseX - pmouseX) * 0.01;
        }
    }

    /**
     * handle key strokes (numbers, r, R, save if canSave)
     */
    public void keyReleased() {
        switch(key) {
            case '0':
            case '1':
            case '2':
                changeKaleidoscope((Integer.parseInt(key+"")+10)*2);
                break;
            case '3':
            case '4':
            case '5':
            case '6':
            case '7':
            case '8':
            case '9':
                changeKaleidoscope(Integer.parseInt(key+"")*2);
                break;
            case 'r':
                rotateKal += ROTATE_INCREMENT;
                break;
            case 'R':
                rotateKal -= ROTATE_INCREMENT;
                break;
            case 's':
                if (canSave) {
                    saveSnapshot();
                }
                break;
            default:
                //unknown key
                break;
        }
    }

    /**
     * update the buffer with the image in current position,
     *
     * called from main draw loop when image was moved around
     *
     * @param i the image to draw onto the buffer
     * @param m scaling factor relative to the screenradius
     */
    private void updateGraph(PGraphics graph, PImage i, int m) {
        graph.beginDraw();
        graph.translate(drag.x*m,drag.y*m);
        graph.translate(m*screenradius/2,m*screenradius/2);
        graph.rotate(drag.z);
        graph.translate(-m*screenradius/2,-m*screenradius/2);
        graph.image(i,0,0);
        graph.endDraw();
    }

    /**
     * Change the number of axis of the kaleidoscope (after a number key pressed)
     *
     * Will create a new Kaleidoscope instance and a new buffer for the slice of pie
     *
     * @param segments the number of segments to use
     */
    private void changeKaleidoscope(int segments) {
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
    private void saveSnapshot() {
        if (scalefactor != 1)  {
            background(0);
            //center the screen
            translate((width - height)/2,0);

            kaleidoscopeH.draw(graphH, baserotate);
        }
        DateFormat f = new SimpleDateFormat("'kaleidoscope_"+imagename+"_'yyyy-MM-dd_HH-mm-ss'.png'");
        String imgfile = f.format(new Date());
        try {
            save(imgfile);
        } catch(RuntimeException t) {
            t.printStackTrace();
            println("Failed to save current state to "+imgfile);
        }
    }
}
