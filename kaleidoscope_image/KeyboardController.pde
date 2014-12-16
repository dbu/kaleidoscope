class KeyboardController extends KaleidoscopeController {

    private boolean canSave;
   
   public KeyboardController(int screenradius, int scalefactor, boolean canSave, boolean debug) { 
       super(screenradius, scalefactor, debug);
       this.canSave = canSave;
   }
   
    /**
     * handle key strokes (numbers, r, R, s, o)
     */
    public void keyReleased() {
        switch(key) {
            case '0':
            case '1':
            case '2':
                setSegmentNumber((Integer.parseInt(key+"")+10)*2);
                break;
            case '3':
            case '4':
            case '5':
            case '6':
            case '7':
            case '8':
            case '9':
                setSegmentNumber(Integer.parseInt(key+"")*2);
                break;
            case 'r':
                increaseRotate();
                break;
            case 'R':
                decreaseRotate();
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
     * track mouse movement to update image position
     */
    public void mouseDragged() {
        if (mouseButton == LEFT) {
            move(mouseX - pmouseX, mouseY - pmouseY);
        } else if (mouseButton == RIGHT) {
            rotateIncrement((mouseX - pmouseX) * 0.01);
        }
    }
}
