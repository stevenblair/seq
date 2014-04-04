/**
 * Visualisation of symmetrical components
 * 
 * Copyright (c) 2011 Steven Blair
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

//import processing.opengl.*;

PFont font;
final float MOUSE_OVER_LINE_DISTANCE_THRESHOLD = 3.0;
final int STROKE_WEIGHT_NORMAL = 8, STROKE_WEIGHT_POS = 6, STROKE_WEIGHT_NEG = 5, STROKE_WEIGHT_ZERO = 3, STROKE_WEIGHT_HOVER = 12;
final int SET_BALANCED = 0, SET_EXAMPLE = 1, SET_RANDOM = 2, TOGGLE_MODE = 3;  // workaround for lack of pseudo-anonymous functions in .js
final float X_START = 180;
final float Y_START = 300;
final float X_MAX = 1200;
final float Y_MAX = 600;
final int LEGEND_BASE_X = 20;
final int LEGEND_BASE_Y = 60;
final int VIEW_TOGETHER = 0, VIEW_SEPERATE = 1;
final float VISIBLE_THRESHOLD = 0.3;
final color redPhaseA = color(180, 33, 38);      // RGB values
final color yellowPhaseB = color(222, 215, 20);
final color bluePhaseC = color(36, 78, 198);
final color colorPhaseMap[] = {
  redPhaseA, yellowPhaseB, bluePhaseC
};
final color alphaValueMap[] = {
  200, 120, 80, 60
};
final int strokeWeightMap[] = {
  STROKE_WEIGHT_NORMAL, STROKE_WEIGHT_POS, STROKE_WEIGHT_NEG, STROKE_WEIGHT_ZERO, STROKE_WEIGHT_HOVER
};

int mode = VIEW_SEPERATE;

PVector signal[] = new PVector[3];
PVector pos[] = new PVector[3];
PVector neg[] = new PVector[3];
PVector zero[] = new PVector[3];

float magA = 0.0;
float magB = 0.0;
float magC = 0.0;
float phaseA = 0.0;
float phaseB = 0.0;
float phaseC = 0.0;
float scalePhasors = 100.0;
int hoveredPhase = -1;

RectButton buttonBalanced, buttonExample, buttonRandom, buttonMode;

void initVariables() {
  for (int i = 0; i < 3; i++) {
    signal[i] = new PVector(0.0, 0.0);
    pos[i] = new PVector(0.0, 0.0);
    neg[i] = new PVector(0.0, 0.0);
    zero[i] = new PVector(0.0, 0.0);
  }
}

void initGUI() {
  buttonMode = new RectButton("show superimposed", 10, 10, 150, 30, TOGGLE_MODE);
  buttonBalanced = new RectButton("balanced", 180, 10, 150, 30, SET_BALANCED);
  buttonExample = new RectButton("example", 350, 10, 150, 30, SET_EXAMPLE);
  buttonRandom = new RectButton("random", 520, 10, 150, 30, SET_RANDOM);
}

PVector rotateAlpha(PVector pv) {
  float magnitude = pv.mag();
  float phase = atan2(pv.get().y, pv.get().x) + radians(120);

  return new PVector(magnitude*cos(phase), magnitude*sin(phase));
}

PVector rotateAlphaNeg(PVector pv) {
  float magnitude = pv.mag();
  float phase = atan2(pv.get().y, pv.get().x) + radians(-120);

  return new PVector(magnitude*cos(phase), magnitude*sin(phase));
}

void setVariables() {
  signal[0].set(magA*cos(radians(phaseA)), magA*sin(radians(phaseA)), 0.0);
  signal[1].set(magB*cos(radians(phaseB)), magB*sin(radians(phaseB)), 0.0);
  signal[2].set(magC*cos(radians(phaseC)), magC*sin(radians(phaseC)), 0.0);

  float posX = signal[0].get().x + rotateAlpha(signal[1]).get().x + rotateAlpha(rotateAlpha(signal[2])).get().x;
  float posY = signal[0].get().y + rotateAlpha(signal[1]).get().y + rotateAlpha(rotateAlpha(signal[2])).get().y;

  float negX = signal[0].get().x + rotateAlpha(rotateAlpha(signal[1])).get().x + rotateAlpha(signal[2]).get().x;
  float negY = signal[0].get().y + rotateAlpha(rotateAlpha(signal[1])).get().y + rotateAlpha(signal[2]).get().y;

  pos[0].set(posX, posY, 0.0);
  pos[0].div(3);
  //pos[1].set(rotateAlphaNeg(pos[0]));
  //pos[2].set(rotateAlpha(pos[0]));
  PVector pos2 = rotateAlphaNeg(pos[0]);        // awkward workaround for .js
  pos[1].set(pos2.get().x, pos2.get().y, 0.0);
  PVector pos3 = rotateAlpha(pos[0]);
  pos[2].set(pos3.get().x, pos3.get().y, 0.0);
  
  neg[0].set(negX, negY, 0.0);
  neg[0].div(3);
  //neg[1].set(rotateAlpha(neg[0]));
  //neg[2].set(rotateAlphaNeg(neg[0]));
  PVector neg2 = rotateAlpha(neg[0]);        // awkward workaround for .js
  neg[1].set(neg2.get().x, neg2.get().y, 0.0);
  PVector neg3 = rotateAlphaNeg(neg[0]);
  neg[2].set(neg3.get().x, neg3.get().y, 0.0);
    
  for (int i = 0; i < 3; i++) {
    zero[i].set(signal[0].get().x + signal[1].get().x + signal[2].get().x, signal[0].get().y + signal[1].get().y + signal[2].get().y, 0.0);
    zero[i].div(3);
  }
}

boolean mouseIsOverLine(float x1, float y1, float x2, float y2, int phase) {
  float d = dist(x1, y1, x2, y2);
  float d1 = dist(x1, y1, mouseX, mouseY);
  float d2 = dist(x2, y2, mouseX, mouseY);

  // distance between vertices must be similar to sum of distances from each vertex to mouse
  if (d1 + d2 < d + MOUSE_OVER_LINE_DISTANCE_THRESHOLD) {
    return true;
  }
  
  return false;
}

boolean dragging = false;

void mouseDragged() {
  dragging = true;

  if (hoveredPhase >= 0) {
    float tempX = (mouseX - X_START - signal[hoveredPhase].get().x)/scalePhasors;
    float tempY = (Y_START - mouseY + signal[hoveredPhase].get().y)/scalePhasors;

    switch (hoveredPhase) {
    case 0:
      magA = sqrt(tempX*tempX + tempY*tempY);
      phaseA = degrees(atan2(tempY, tempX));
      break;
    case 1:
      magB = sqrt(tempX*tempX + tempY*tempY);
      phaseB = degrees(atan2(tempY, tempX));
      break;
    case 2:
      magC = sqrt(tempX*tempX + tempY*tempY);
      phaseC = degrees(atan2(tempY, tempX));
      break;
    default:
    }
  }
}

void mouseReleased() {
  dragging = false;
  hoveredPhase = -1;
  mousePressedLock = false;
  
  // todo: ensure HAND is set to ARROW if no longer hovering over line
}

void drawPhasors(PVector[] vectors, int j, boolean allowDragging, float x, float y) {
  float m = 0.0;
  float ang = 0.0;
  PVector pv;
  float endx, endy;

  for (int i = 0; i < 3; i++) {
    pv = vectors[i];
    m = scalePhasors * pv.mag();
    ang = atan2(pv.get().y, pv.get().x);
    endx = x + m*cos(ang);
    endy = y - m*sin(ang);
    
    strokeWeight(strokeWeightMap[j]);
    
    if (mouseIsOverLine(x, y, endx, endy, i)) {
      if (!dragging && allowDragging) {
        strokeWeight(STROKE_WEIGHT_HOVER);
        
        String mouseIsOverLineID = "mouseIsOverLineID" + j + i + x + y;
        
        if (cursorLock.equals("")) {
          cursorLock = mouseIsOverLineID;        // todo: fix this behaviour
          cursor(HAND);
          //println("set in line: " +  mouseIsOverLineID);
        }
        else if (cursorLock.equals(mouseIsOverLineID)) {
        }
        else {
          //println("no entry" +  mouseIsOverLineID);
        }
              
        hoveredPhase = i;
      }
    }
    else {
      if (!dragging && allowDragging && hoveredPhase == i) {
        hoveredPhase = -1;
        
          cursor(ARROW);
          cursorLock= "";
          //println("remove in line" +  mouseIsOverLineID);
      }
    }

    drawPhase(pv, i, j, x, y, endx, endy);
  }
}


void drawPhasorsPerPhase(int i, float x, float y) {
  float m = 0.0;
  float ang = 0.0;
  PVector pv;
  float endx, endy;

  pv = signal[i];
  m = scalePhasors * pv.mag();
  ang = atan2(pv.get().y, pv.get().x);
  endx = x + m*cos(ang);
  endy = y - m*sin(ang);    // note: y-axis is "upside-down" in processing
  
  strokeWeight(STROKE_WEIGHT_NORMAL);
  
  if (mouseIsOverLine(x, y, endx, endy, i)) {
    if (!dragging) {
      strokeWeight(STROKE_WEIGHT_HOVER);
      hoveredPhase = i;
    }
  }
  else {
    if (!dragging && hoveredPhase == i) {
      hoveredPhase = -1;
    }
  }
  
  drawPhase(pv, i, 0, x, y, endx, endy);
  
  strokeWeight(STROKE_WEIGHT_POS);
  pv = pos[i];
  m = scalePhasors * pv.mag();
  ang = atan2(pv.get().y, pv.get().x);
  endx = x + m*cos(ang);
  endy = y - m*sin(ang);    // note: y-axis is "upside-down" in processing
  drawPhase(pv, i, 1, x, y, endx, endy);
  
  strokeWeight(STROKE_WEIGHT_NEG);
  x = endx;
  y = endy;
  pv = neg[i];
  m = scalePhasors * pv.mag();
  ang = atan2(pv.get().y, pv.get().x);
  endx = x + m*cos(ang);
  endy = y - m*sin(ang);    // note: y-axis is "upside-down" in processing
  drawPhase(pv, i, 2, x, y, endx, endy);
  
  strokeWeight(STROKE_WEIGHT_ZERO);
  x = endx;
  y = endy;
  pv = zero[i];
  m = scalePhasors * pv.mag();
  ang = atan2(pv.get().y, pv.get().x);
  endx = x + m*cos(ang);
  endy = y - m*sin(ang);    // note: y-axis is "upside-down" in processing
  drawPhase(pv, i, 3, x, y, endx, endy);
}

void drawPhase(PVector pv, int i, int component, float x, float y, float endx, float endy) {
  float ang = atan2(pv.get().y, pv.get().x);
  stroke(colorPhaseMap[i], alphaValueMap[component]);
  line(x, y, endx, endy);
  
  if (pv.mag() > VISIBLE_THRESHOLD && (mode == VIEW_SEPERATE || component == 0)) {
    fill(210);
    text(nf(pv.mag(), 1, 1) + " ∠" + nf(degrees(ang), 1, 1) + "°", endx, endy);
  }
}

boolean mousePressedLock = false;


void setup() {
  frameRate(30);
  size(int(X_MAX), int(Y_MAX)/*, OPENGL*/);
  background(0);
  randomSeed(0);
  //strokeWeight(2);
  font = createFont("SansSerif.plain", 12);
  textFont(font);
  textSize(12);
  textLeading(10);
  textAlign(CENTER);
  smooth();
  hint(ENABLE_NATIVE_FONTS);

  colorMode(RGB);
  initGUI();
  colorMode(HSB);
  initVariables();
  setBalanced();
}

void draw() {
  background(0);

  setVariables();

  // draw grid
  stroke(35);
  strokeWeight(1);
  line(0, Y_START, X_MAX, Y_START);
  line(X_START, 0, X_START, Y_MAX);

  if (mode == VIEW_SEPERATE) {
    line(X_START + 300, 0, X_START + 300, Y_MAX);
    line(X_START + 600, 0, X_START + 600, Y_MAX);
    line(X_START + 900, 0, X_START + 900, Y_MAX);
  
    drawPhasors(signal, 0, true, X_START, Y_START);
    drawPhasors(pos, 1, false, X_START + 300, Y_START);
    drawPhasors(neg, 2, false, X_START + 600, Y_START);
    drawPhasors(zero, 3, false, X_START + 900, Y_START);
    
    fill(210);
    text("input", X_START, Y_START + 150);
    text("positive", X_START + 300, Y_START + 150);
    text("negative", X_START + 600, Y_START + 150);
    text("zero", X_START + 900, Y_START + 150);
  }
  else {
    for (int seq = 0; seq < 4; seq++) {
      if (seq == 0) {
        text("input", LEGEND_BASE_X + 20 + 60 * seq, LEGEND_BASE_Y + 60);
      }
      else if (seq == 1) {
        text("positive", LEGEND_BASE_X + 20 + 60 * seq, LEGEND_BASE_Y + 60);
      }
      else if (seq == 2) {
        text("negative", LEGEND_BASE_X + 20 + 60 * seq, LEGEND_BASE_Y + 60);
      }
      else if (seq == 3) {
        text("zero", LEGEND_BASE_X + 20 + 60 * seq, LEGEND_BASE_Y + 60);
      }
      for (int phase = 0; phase < 3; phase++) {
        strokeWeight(strokeWeightMap[seq]);
        stroke(colorPhaseMap[phase], alphaValueMap[seq]);
        line(LEGEND_BASE_X + 60 * seq, LEGEND_BASE_Y + 20 * phase, LEGEND_BASE_X + 40 + 60 * seq, LEGEND_BASE_Y + 20 * phase);
      }
    }

    drawPhasorsPerPhase(0, X_START, Y_START);
    drawPhasorsPerPhase(1, X_START, Y_START);
    drawPhasorsPerPhase(2, X_START, Y_START);
  }

  updateButtons();
}

public void setBalanced() {
      magA = 1.0;
      magB = 1.0;
      magC = 1.0;
      phaseA = 0.0;
      phaseB = -120.0;
      phaseC = 120.0;
}

void setAction(int setNum) {
  if (mousePressedLock == false) {
    mousePressedLock = true;
    
    switch (setNum) {
      case SET_BALANCED:
        setBalanced();
        break;
      case SET_EXAMPLE:
        // sets phasors to example in Peter Crossley's coursework: 
        // http://www.intranet.eee.manchester.ac.uk/intranet/ug/coursematerial/2nd%20Year/EEEN20028%20-%20Electrical%20Power/Symmetrical%20comp%20introduction_PAC07.pdf
        magA = 0.8;
        magB = 0.6;
        magC = 1.6;
        phaseA = 0.0;
        phaseB = -90.0;
        phaseC = 143.1;
        break;
      case SET_RANDOM:
        magA = random(0.0, 3.0);
        magB = random(0.0, 3.0);
        magC = random(0.0, 3.0);
        phaseA = random(-180.0, 180.0);
        phaseB = random(-180.0, 180.0);
        phaseC = random(-180.0, 180.0);
        break;
      case TOGGLE_MODE:
        if (mode == VIEW_SEPERATE) {
          mode = VIEW_TOGETHER;
          buttonMode.string = "show separate";
        }
        else {
          mode = VIEW_SEPERATE;
          buttonMode.string = "show superimposed";
        }
        break;
      default:
    }
  }
}

void updateButtons() {
  buttonMode.display();
  buttonBalanced.display();
  buttonExample.display();
  buttonRandom.display();
}

String cursorLock = "";

class RectButton {
  int x, y;
  int sizeX, sizeY;
  color basecolor = color(0, 54, 82);
  color highlightcolor = color(6, 153, 196);
  color currentcolor;
  boolean pressed = false;
  String string;
  int setNum;

  RectButton(String istring, int ix, int iy, int isizeX, int isizeY, int isetNum) {
    string = istring;
    x = ix;
    y = iy;
    sizeX = isizeX;
    sizeY = isizeY;
    currentcolor = basecolor;
    setNum = isetNum;
  }

  void update() {
    if (over()) {
      currentcolor = highlightcolor;
    }
    else {
      currentcolor = basecolor;
    }
    
    if (pressed()) {
      setAction(setNum);
    }
  }

  boolean pressed() {
    if (over() && mousePressed) {
      return true;
    } 
    else {
      return false;
    }
  }

  boolean overRect(int x, int y, int width, int height) {
    if (mouseX >= x && mouseX <= x+width && mouseY >= y && mouseY <= y+height) {
      if (cursorLock.equals("")) {
        cursorLock = string;
        cursor(HAND);
      }
      return true;
    } 
    else {
      if (cursorLock.equals(string)) {
        cursor(ARROW);
        cursorLock = "";
      }
      return false;
    }
  }

  boolean over() {
    if(overRect(x, y, sizeX, sizeY)) {
      return true;
    } 
    else {
      return false;
    }
  }

  String getString() {
    return string;
  }

  void display() {
    update();
    
    stroke(255);
    noStroke();
    fill(currentcolor);
    rect(x, y, sizeX, sizeY);
    fill(255);
    text(this.getString(), x, y + 8, sizeX, sizeY);
  }
}

