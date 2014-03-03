import damkjer.ocd.*;
import processing.opengl.*;
import oscP5.*;
import netP5.*;

Camera camera1;
Creature c1;
OscP5 osc;

float[] cx, cz, sphereX, sphereY, sphereZ;

boolean filled = false;
int curRes = 0;
float curScaleY = 1;

int FPS = 60;

boolean saveMovieFrame = false;
String saveFrameName = "default-########.tif";

void setup() {
  size(500,600,OPENGL);
  frameRate(FPS);
  camera1 = new Camera(this, -300, -200, -500);
  camera1.aim(0,-180,0);
  c1 = new Creature(0,-35,0,50);
  osc = new OscP5(this,12001);
  osc.plug(c1,"bounce","/bounce");
  osc.plug(c1,"setSize","/setSize");
  osc.plug(c1,"setSpikes","/setSpikes");
  osc.plug(c1,"setRotation","/setRotation");
  osc.plug(this,"toggleSaveFrame","/toggleSaveFrame");
  osc.plug(this,"setSaveFrameName","/setSaveFrameName");
}

int rot = 0;

void draw() {
  background(200);
  noStroke();
  lights();
  //smooth();
  spotLight(255,255,255, -40,-375,-150, 0,1,0, PI, 0);

    fill(100);
    floor(150);
    fill(255,0,0);
    pushMatrix();
      c1.display();
    popMatrix();
    
  camera1.feed();
  if(saveMovieFrame) {
    saveFrame(saveFrameName); 
  }
}

/*
void mouseReleased() { 
  filled=!filled;
  c1.setSpikes(random(0,0.45));
  c1.bounce(0.5,100);
}
*/

void floor(int rad) {
  pushMatrix();
  beginShape();
    vertex(-rad,20,-rad);
    vertex(rad,20,-rad);
    vertex(rad,20,rad);
    vertex(-rad,20,rad);
    vertex(-rad,20,-rad);
  endShape();
  popMatrix();
}

class Vertex {
  float x, y, z;
  Vertex(float ax, float ay, float az) {
    x = ax;
    y = ay;
    z = az;
  }
  void drawVertex() {
    vertex(x, y, z);
  }
}

void defSphere(float radius, int res, float scaleY, float[][] spikes) {
  float deltaPhi = (2 * PI) / res;
  float deltaTheta = PI / res;
  
  int vertexCount = res * res;
  Vertex[] vertices = new Vertex[vertexCount];
  
  // Cache the vertices of a UV Sphere
  int currentVertex = 0;
  float theta = 0;
  float phi = 0;
  for(int i = 0; i < res; i++) {
    theta += deltaTheta;
    for(int j = 0; j < res; j++) {
      phi += deltaPhi;
      float x = sin(theta) * cos(phi) + spikes[currentVertex][0];
      float y = cos(theta) + spikes[currentVertex][1];
      float z = sin(theta) * sin(phi) + spikes[currentVertex][2];
      vertices[currentVertex] = new Vertex(x, y, z);
      currentVertex += 1;
    }
  }
  
  // Draw the cached sphere:
  pushMatrix();
  scale(radius);
  
  // Draw the points: (for debugging)
  /*
  beginShape(POINTS);
  for(int i = 0; i < vertices.length; i++) {
    pushMatrix();
      translate(vertices[i].x, vertices[i].y, vertices[i].z);
      sphere(0.015);
    popMatrix();
  }
  endShape();
  */
  
  beginShape(TRIANGLES);
    int i1, i2, i3, i4;
  
    // Draw the bottom
    for(int i = 0; i < res; i++) {
      i2 = i % res;
      i3 = (i + 1) % res;
      vertex(0, 1, 0);
      vertices[i2].drawVertex();
      vertices[i3].drawVertex();
    }
    
    for(int strip = 1; strip < res; strip++) {
      for(int quad = 0; quad < res; quad++) {
        i1 = ((strip-1) * res) + quad;
        i2 = (strip * res) + quad;
        i3 = (strip * res) + ((quad + 1) % res);
        i4 = ((strip-1) * res) + ((quad + 1) % res);
        
        vertices[i1].drawVertex();
        vertices[i2].drawVertex();
        vertices[i3].drawVertex();
        
        vertices[i1].drawVertex();
        vertices[i3].drawVertex();
        vertices[i4].drawVertex();
      }
    }
    
    // Draw the top
    for(int i = 0; i < res; i++) {
      i2 = (res * (res - 1)) + i % res;
      i3 = (res * (res - 1)) + (i + 1) % res;
      vertex(0, -1 * scaleY, 0);
      
      vertices[i2].drawVertex();
      vertices[i3].drawVertex();
    }
  endShape();
  
  popMatrix();
}

class Creature
{
  int res = 25;
  int x, y, z, r;
  float lastSquish = 1.0;
  
  float rotation = 0;
  float newRotation = 0;
  float incrementRotation = 0;
  int rotationCounter = 0;
  
  int initX, initY;
  
  float bounceProgress = 0.0;
  float bounceIncrement;
  int bounceHeight;
  
  boolean bouncing = false;
  
  float scaleValue = 1.5;
  float newScaleValue = 1.5;
  float scaleIncrement = 0.0;
  int spikeCounter = 0;
  
  int transformFrames = 30;
  int vertexCount = res * res;

  float[][] spikes = new float[vertexCount][3];     //spikes[vertex index][dimension index]
  float[][] newSpikes = new float[vertexCount][3];
  float[][] incrementSpikes = new float[vertexCount][3];
  
  
  Creature(int ix, int iy, int iz, int ir) {
    initX = ix;
    initY = iy;
    x = ix;
    y = iy; 
    z = iz;
    r = ir;
  }
  
  void display() {

    if((abs(scaleValue-newScaleValue) < 0.0025) && (scaleValue != newScaleValue)) {
      //println("CLICK " + str(abs(scaleValue-newScaleValue)));
      scaleValue = newScaleValue;
    }
    
    if(scaleValue < newScaleValue) {
      scaleValue += scaleIncrement;
    } else if (scaleValue > newScaleValue) {
      scaleValue -= scaleIncrement;
    }
    
    if(rotationCounter<transformFrames) {
      rotation += incrementRotation;
      rotationCounter++;
    } else {
      rotation = newRotation;
    }
    
    if(spikeCounter<transformFrames) {
      //println(str(spikeCounter));
      //println(str(spikes[510][0]));
      for(int x = 0; x < spikes.length; x++) {
        for(int y = 0; y < 3; y++) {
          spikes[x][y] += incrementSpikes[x][y];
        }
      }
      spikeCounter++;
    } else {
      //println(str(spikeCounter));
      for(int x = 0; x < spikes.length; x++) {
        for(int y = 0; y < 3; y++) {
          spikes[x][y] = newSpikes[x][y];
        }
      }
    }
    
    pushMatrix();
    scale(scaleValue);
    if(bouncing == true) {
      bounceProgress = bounceProgress + bounceIncrement;
      float sineHeight = sin(PI*bounceProgress);

      pushMatrix();
        float newY = y - sineHeight * bounceHeight;
        translate(x,newY,z);
        rotateX(radians(rotation));
        //rotateZ(radians(rotation/2));
        scale(1, 1.3);
        
        pushMatrix();
          defSphere(r,res,1,spikes);
          drawEyes();
        popMatrix();
          
        //println("y: " + str(y) + " newY: " + str(newY) + " sq: " + str(squish) + " lastSq: " + str(lastSquish));
      popMatrix();
      
      if(bounceProgress >= 1.0) {
        //println("ending bounce. bounceProgress: " + str(bounceProgress));
        bounceProgress = 0.0;
        bouncing = false;
      }
    } else {
      pushMatrix();
        translate(x,y,z);
        rotateX(radians(rotation));
        //rotateZ(radians(rotation/2));
        scale(1, 1.3);
        defSphere(r,res,lastSquish,spikes);
        drawEyes();
      popMatrix();
    }
    popMatrix();
  }

  void bounce(float bLength, int newBounceHeight) {
    if(bouncing == true) {
      println(" *** bounce overlap! bounceProgress: " + str(bounceProgress) + " transformFrames: " + str(transformFrames));
    } else {
      bounceHeight = newBounceHeight;
      transformFrames = secondsToFrames(bLength * 0.93);
      bounceIncrement = 1.0 / transformFrames;
      //println("bouncing. bLength: " + str(bLength) + " newBounceHeight: " + str(newBounceHeight) + " transformFrames: " + str(transformFrames) + " bounceIncrement: " + str(bounceIncrement));
      bouncing = true;
    }
  }
  
  void setSize(float newSize) {
    newScaleValue = newSize;
    scaleIncrement = abs(scaleValue - newScaleValue) / transformFrames;
  }
  
  void setSpikes(float dissonance) {
    //println("setting spikes. dissonance: " + str(dissonance));
    for(int x = 0; x < spikes.length; x++) {
      for(int y = 0; y < 3; y++) {
          newSpikes[x][y] = random(-1.0*dissonance, dissonance);
          incrementSpikes[x][y] = (newSpikes[x][y] - spikes[x][y])/transformFrames;
          //println("vertex: " + str(x) + " dimension: " + str(y) + " old: " + str(spikes[x][y]) + " new: " + str(newSpikes[x][y]) + " increment: " + str(incrementSpikes[x][y]));
      }
    }
    spikeCounter = 0;
  }
  
  void setRotation(float dissonance) {
    newRotation = dissonance;
    incrementRotation = (newRotation - rotation) / transformFrames;
    rotationCounter = 0;
    //println("setting rotation: " + str(rotation) + " newRotation: " + str(newRotation) + " incrementRotation: " + str(incrementRotation));
  }
}

int secondsToFrames(float seconds)
{
  return(round(seconds*FPS));
}

void drawEyes()
{
  translate(-12,-33,-40);
  fill(255);
  box(4);
  translate(24,0,0);
  box(4);
}

void toggleSaveFrame() {
  if(saveMovieFrame) {
    saveMovieFrame = false;
  } else {
    saveMovieFrame = true;
  }
}

void setSaveFrameName(String newSaveFrameName) {
  print("\nSetting SaveFrameName: " + newSaveFrameName);
  saveFrameName = newSaveFrameName;
}

/*
void oscEvent(OscMessage theOscMessage) {
  print("### received an osc message.");
  print(" addrpattern: " + theOscMessage.addrPattern());
  println(" typetag: " + theOscMessage.typetag());
}
*/
