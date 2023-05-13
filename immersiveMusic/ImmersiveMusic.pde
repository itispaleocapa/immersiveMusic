import ddf.minim.*;
import ddf.minim.analysis.*;

Minim minim;
AudioInput input;
FFT fft;

int mode = 0; //tipo di visualizzazione

//modes 0, 1
int numPoints = 60; // Numero di punti sulla linea
float[] amplitudes = new float[numPoints];
float radius;
float angleStep;
float minRadius, maxRadius; // Intervallo di valori per la lunghezza della linea
color lineColor;


//modes 2
float angle = 0;
float squareSize = 200;
float curveAmount = 0;
color squareColor = color(255);
ArrayList<ExpandCircle> circles = new ArrayList<ExpandCircle>();

void setup() {
  //size(1920, 1080);
  //size(640, 480);
  fullScreen();
  background(0);
  strokeWeight(2);
  strokeCap(ROUND);
  smooth();


    minim = new Minim(this);
    
  //da esempio prove_3_microfono  
  /* 
  input = minim.getLineIn();
  fft = new FFT(input.bufferSize(), input.sampleRate());
  /* */

  //da esempio prove_2_microfono
  /* */
  input = minim.getLineIn(Minim.STEREO, 1024, 44100, 16);
  fft = new FFT(input.bufferSize(), input.sampleRate());
  fft.logAverages(22, 3);
  /* */
  
  radius = min(width, height) * 0.4;
  angleStep = TWO_PI / numPoints;
  minRadius = radius * 0.1;
  maxRadius = radius * 0.9;
  lineColor = color(255, 255, 255);
  textSize(max(height/20,10));
  ((java.awt.Canvas) surface.getNative()).requestFocus();
}

void draw() {
  background(0);
  //fill(255, 255, 255);
  text("mode: "+mode, 2, g.textSize+2); 
  // Calcola i valori degli spettri di frequenza
  fft.forward(input.mix);
  for (int i = 0; i < numPoints; i++) {
    float amplitude = fft.getBand(i);
    amplitudes[i] = amplitude;
    //print(amplitude+" ");
  }  
  //println();
  switch(mode) {
    case 0: 
      scoppio();  
      break;
    case 1: 
      istogramma();
      break;
    case 2: 
      quadratoCerchi();
      break;
    default:             
      //println("unknown mode:"+mode);   
      break;
  }

  
}

void stop() {
  input.close();
  minim.stop();
  super.stop();
}

void scoppio(){  
  // Disegna la linea che rappresenta lo spettro di frequenza
  pushMatrix();
  translate(width / 2, height / 2);
  stroke(lineColor);
  beginShape();
  float r;
  for (int i = 0; i < numPoints; i++) {
    r=map(amplitudes[i], 0, 1, minRadius, maxRadius);
    float x = cos(i * angleStep) * r/20;
    float y = sin(i * angleStep) * r/20;
    vertex(x, y);
  }
  endShape(CLOSE);
  popMatrix();
  
  // Disegna il cerchio centrale
  noStroke();
  fill(lineColor);
  ellipse(width / 2, height / 2, radius * 0.05, radius * 0.05);
  
  // Modifica la forma e il colore della linea in base all'audio
  float level = input.mix.level();
  float angleOffset = map(level, 0, 1, 0, TWO_PI);
  angleStep += angleOffset * 0.01;
  lineColor = color(random(255), random(255), random(255));
}

void istogramma(){
  float y0=height*0.9;
  float x0=width*0.1;
  float w=width*0.8/numPoints;
  float hMax=height*0.8;
  float h;
  for (int i = 0; i < numPoints; i++) {
    h=map(amplitudes[i],0,100,0,1)*hMax;
    fill(color(random(255), random(255), random(255)));
    rect(x0+i*w, y0-h, w, h);
  }
  println();
 
}

void quadratoCerchi(){
  // Aggiorna l'angolo di rotazione del quadrato
  angle += 0.01;
  
  // Aggiorna la curvatura del quadrato in base al valore audio rilevato
  fft.forward(input.mix);
  float avgAmplitude = fft.calcAvg(20, 20000);
  curveAmount = map(avgAmplitude, 0, 1, 0, 20);
  
  // Aggiorna il colore del quadrato in base al valore audio rilevato
  squareColor = lerpColor(color(255, 0, 0), color(0, 255, 0), avgAmplitude);
  
  // Disegna il quadrato
  pushMatrix();
  translate(width/2, height/2);
  rotate(angle);
  fill(squareColor);
  stroke(255);
  strokeWeight(5);
  rectMode(CENTER);
  rect(0, 0, squareSize, squareSize, curveAmount);
  popMatrix();
  
  // Aggiungi un nuovo cerchio se il valore audio supera una certa soglia
  float s=0.2;
  if (avgAmplitude > s) {
  //for (int i=1; i<avgAmplitude; i+=5){
  //while (avgAmplitude>s){
    circles.add(new ExpandCircle(width/2, height/2, squareSize + curveAmount, 100));
    s+=5;
  }
  
  // Aggiorna e disegna tutti i cerchi
  for (int i = 0; i < circles.size(); i++) {
    ExpandCircle circle = circles.get(i);
    circle.expand();
    circle.fade();
    circle.draw();
    if (circle.alpha <= 0) {
      circles.remove(i);
    }
  }

}


// Classe che rappresenta un cerchio che si espande e si dissolve
class ExpandCircle {
  float x;
  float y;
  float size;
  int alpha;
  
  ExpandCircle(float x, float y, float size, int alpha) {
    this.x = x;
    this.y = y;
    this.size = size;
    this.alpha = alpha;
  }
  
  void expand() {
    size += 10;
  }
  
  void fade() {
    alpha -= 1;
  }
  void draw() {
    noFill();
    strokeWeight(2);
    stroke(random(255), random(255), random(255), alpha);
    ellipse(x, y, size, size);
  }
}

void keyPressed() {
  mode=key-48;
}
