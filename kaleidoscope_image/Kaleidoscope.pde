/**
 * Picture Kaleidoscope
 * by David Buchmann <mail at davidbu.ch>
 *
 * The Kaleidoscope class
 *
 * This class is set up with a size and a number of segments.
 * It provides a buffer that has to be filled with the data you want to have
 * kaleidoscoped
 *
 * Whenever you update the buffer (typically in your main draw cycle)
 * you call Kaleidoscope.draw to draw the new Kaleidoscope.
 * The rotation parameter can be used to let the resulting image rotate
 *
 * (c) David Buchmann, 2010
 *
 * This code is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License.This program is distributed in
 * the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the
 * implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 * See the GNU General Public License for more details.
 */
class Kaleidoscope {
    /** kaleidoscope segments */
    int segments;
    /** kaleidoscope radius in pixels */
    int radius;
    /** height of the buffer, calculated from the radius and the number of segments */
    int bufferheight;
    /** rotation step for the segments, based on the number of segments */
    float angle;

    /** the buffer for getBuffer, in the right size for current bufferheight */
    PGraphics buffer;
    /** mask image to apply to the buffer to get a slice of pie */
    PGraphics triangle_mask;

    /**
     * Instantiate a Kaleidoscope
     *
     * @param segments number of parts. half of them will be mirrored
     * @param radius the radius of the kaleidoscope
     */
    public Kaleidoscope(int segments, int radius) {
        this.segments = segments;
        this.radius = radius;
        angle = TWO_PI/segments;
        bufferheight = Math.round(sin(angle+0.02)*radius)+1;
        buffer = createGraphics(radius,bufferheight,OPENGL);
//        buffer.background(0);
        triangle_mask = createGraphics(radius,bufferheight,OPENGL);
/*        triangle_mask.beginDraw();
        triangle_mask.background(color(0));
        triangle_mask.stroke(color(255));
        triangle_mask.arc(0,0,radius*2,radius*2,0,angle+0.02); //ellipse with center 0,0 and width and height of 2*radius. part angle of that, with an additional 0.02 to avoid black gaps
        triangle_mask.endDraw();
        */
    }

    /**
     * Get an image buffer to draw on, for using with the kaleidoscope.
     *
     * Use this as parameter to draw, to make sure you have the correct buffer
     * size and optimal performance.
     */
    public PGraphics getBuffer() {
        return buffer;
    }

    /**
     * Draws the img rotated and mirrored around the center.
     *
     * The img is masked to get the piece of pie format.
     *
     * @param img Should be the object returned by {@link getBuffer}. Even if not, must be of exactly the same dimensions.
     * @param rotation Rotate whole kaleidoscope by this angle (in radians)
     */
    public synchronized void draw(PImage img, float rotation) {
        triangle_mask.beginDraw();
        triangle_mask.background(color(0));
        triangle_mask.stroke(color(255));
        triangle_mask.arc(0,0,radius*2,radius*2,0,angle+0.02); //ellipse with center 0,0 and width and height of 2*radius. part angle of that, with an additional 0.02 to avoid black gaps
        triangle_mask.endDraw();
        img.mask(triangle_mask);
        // image(img, 0, 0, 400, 161); if (true) return;
        
        //regular segments
        for (int i=0; i<segments/2; i++) {
            pushMatrix();
            //rotate around center
            translate(radius,radius);
            rotate(rotation);
            rotate(i*angle*2);
            translate(-radius,-radius); //but keep origin intact
            //draw the image with upper left corner in center
            image(img,radius,radius);
            popMatrix();
        }
        //mirrored segments

        for (int i=0; i<segments/2; i++) {
            pushMatrix();
            //mirror on x axis. (mirroring inverts all following values on that axis)
            scale(-1,1);
            //rotate around center
            translate(-radius,radius);
            rotate(-rotation);
            rotate(-PI); //start directly adjacent to unmirrored segment
            rotate(i*angle*2);
            translate(radius,-radius); //but keep origin intact
            //draw the image with upper left corner in center
            image(img,-radius,radius);
            popMatrix();
        }

    }
}
