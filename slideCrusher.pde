
import drop.*;

import java.io.*;
import javax.sound.sampled.*;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.util.Random;

import ddf.minim.*;

// parameters for preview
ParameterSet previewSet = new ParameterSet();
int displayChannel = 0;

float previewOffset;   // offset for preview
float previewGain;     // gain for preview

// arrays to hold display waveform data
double[] displaySine = new double[800-50];
double[] displayInterp = new double[800-50];
boolean[] displayLandmarks = new boolean[800-50];

ArrayList<SampleSlot> sampleSlots = new ArrayList<SampleSlot>();  // list to hold samples
SampleSlot selectedSlot;  // currently selected sample slot

// SDrop and Minim objects for handling drag and drop, and audio respectively
SDrop drop;
Minim minim;
AudioSample sample;

// flags for various actions
boolean pendingPlayCurrentSlot = false;
boolean pendingExportCurrentSlot = false;
boolean pendingPlayCurrentSlotShort = false;

// black, border dark, border light, border lighter, white, background, highlighted background, soft text, processing
color[] UIColors = new color[]{0x00, 0x80, 0xDF, 0xE0, 0xFF, 0xC0, 0x50, 0x20, color(0xFF, 0xFF, 0x00)};

void setup() {
  size(800, 700);
  drop = new SDrop(this);
  minim = new Minim(this);
  computeDefaultPreviewWaveform();  // compute initial waveform for display
  setBasicUIElements();  // setup UI elements
  updateDisplay();  // update display
}

// event handler for file drop
void dropEvent(DropEvent theDropEvent) {
  if (theDropEvent.isFile()) {
    selectedSlot = new SampleSlot(10, 350+sampleSlots.size()*50);
    selectedSlot.url = theDropEvent.toString();
    selectedSlot.loadFile();
    selectedSlot.normalizeDisplay();
    sampleSlots.add(selectedSlot);
    updateDisplay();
    getUiElementCalled("displayChannel").show=true;
    getUiElementCalled("process").show=true;
    getUiElementCalled("play input").show=true;
    getUiElementCalled("play output").show=true;
    getUiElementCalled("short preview").show=true;
    getUiElementCalled("stop").show=true;
    getUiElementCalled("export").show=true;
    getUiElementCalled("remove").show=true;
  }
}

// function to compute default waveform for display
void computeDefaultPreviewWaveform() {
  for (int i=0; i<displaySine.length; i++) displaySine[i] = sin(pow((float)(i+175)/100, 2))*(1-(float)i/displaySine.length);
}

// function to update display
void updateDisplay() {
  if (selectedSlot!=null) {
    if (selectedSlot.nSample!=null) {
      for (int i=0; i < displaySine.length; i++) displaySine[i] = selectedSlot.nSample[displayChannel%selectedSlot.nSample.length][floor(constrain(((float)selectedSlot.nSample[displayChannel%selectedSlot.nSample.length].length-displaySine.length)*previewOffset, 0, selectedSlot.nSample[displayChannel%selectedSlot.nSample.length].length-displaySine.length)+i)];
    }
  }
  ProcessResult computation = computeInterp(displaySine, null, previewSet);
  displayInterp = computation.nSampleProcessed;
  displayLandmarks = computation.landmarks;
}

// function to process the current sample slot
void processCurrentSlot() {
  if (selectedSlot!=null && !selectedSlot.isProcessing) {
    selectedSlot.process();
  }
}

// function to process a short chunck from the current sample slot
void processCurrentSlotShort() {
  if (selectedSlot!=null && !selectedSlot.isProcessing) {
    selectedSlot.processShort();
  }
}

// thread to run signal processing asynchronously
class ProcessRunner extends Thread {
  SampleSlot slot;

  public ProcessRunner(SampleSlot slot) {
    this.slot = slot;
  }
  public void run() {
    process();
  }
  void process() {
    slot.isProcessing = true;
    // process every channel
    if (slot.parameterSet.target==0) slot.nSampleProcessed = new double[slot.nbChannels][];
    if (slot.parameterSet.target==1) slot.nSampleProcessedShort = new double[slot.nbChannels][];
    for (int c = 0; c < slot.nbChannels; c++) {
      slot.updateProgressCurrentChannel(c);
      slot.updateProgressSample(0);
      if (slot.parameterSet.target==0) {
        slot.nSampleProcessed[c] = computeInterp(slot.nSample[c], slot, slot.parameterSet).nSampleProcessed;
      }
      if (slot.parameterSet.target==1) {
        double[] cropped = new double[slot.parameterSet.processEnd-slot.parameterSet.processStart];
        for (int i=0; i<cropped.length; i++) cropped[i] = slot.nSample[c][i+slot.parameterSet.processStart];
        slot.nSampleProcessedShort[c] = computeInterp(cropped, slot, slot.parameterSet).nSampleProcessed;
      }
    }
    slot.isProcessing = false;
    if (slot.parameterSet.target==0) slot.needsReprocessing = false;
    if (pendingPlayCurrentSlot) playCurrentSlot(false);
    if (pendingPlayCurrentSlotShort) playCurrentSlot(true);
    if (pendingExportCurrentSlot) selectedSlot.exportSample();
  }
}

void draw() {

  // draw background and general frame
  background(UIColors[5]);
  noFill();
  stroke(UIColors[2]);
  line(0, 0, width, 0);
  line(0, 0, 0, height);
  stroke(UIColors[0]);
  line(0, height-1, width-1, height-1);
  line(width-1, 0, width-1, height-1);
  stroke(UIColors[4]);
  line(1, 1, width-2, 1);
  line(1, 1, 1, height-2);
  stroke(UIColors[1]);
  line(1, height-2, width-2, height-2);
  line(width-2, 1, width-2, height-2);
  fill(UIColors[7]);

  // start the waveform visualization
  noFill();
  pushMatrix();
  translate(30, 10);
  noStroke();
  fill(UIColors[4]);
  rect(0, 0, displaySine.length, 300);

  // draw vertical lines at landmark points
  stroke(0xF0);
  for (int i=0; i<displaySine.length; i++) {
    if (displayLandmarks[i]) line(i, 0, i, 300);
  }

  pushMatrix();
  translate(0, 150);
  float displayMax = 147;

  // draw the difference between original and reconstructed waveform (draw method depends on selected optimization method)
  if (previewSet.optimizationMethod==1) {
    for (int i=0; i<displaySine.length; i++) {
      stroke(0xCC, 0xCC, 0xFF);
      line(i, -constrain((float)displaySine[i]*previewGain, -1, 1)*displayMax, i, -constrain((float)displayInterp[i]*previewGain, -1, 1)*displayMax);
    }
  }
  if (previewSet.optimizationMethod==2) {
    int lastLandmark = 0;
    stroke(0xCC, 0xCC, 0xFF);
    for (int i=0; i<displaySine.length; i++) {
      if (displayLandmarks[i]) {
        line(lastLandmark, -constrain((float)displayInterp[lastLandmark]*previewGain, -1, 1)*displayMax, i, -constrain((float)displayInterp[lastLandmark]*previewGain, -1, 1)*displayMax);
        line(lastLandmark, -constrain((float)displayInterp[i]*previewGain, -1, 1)*displayMax, i, -constrain((float)displayInterp[i]*previewGain, -1, 1)*displayMax);
        lastLandmark = i;
      }
    }
  }

  // draw the input waveform
  stroke(0, 0x50, 0);
  strokeWeight(2);
  noFill();
  beginShape();
  for (int i=0; i<displaySine.length; i++) {
    vertex(i, -constrain((float)displaySine[i]*previewGain, -1, 1)*displayMax);
  }
  endShape();

  // draw the output waveform
  stroke(0, 0, 0xFF);
  strokeWeight(1);
  noFill();
  beginShape();
  for (int i=0; i<displayInterp.length; i++) {
    vertex(i, -constrain((float)displayInterp[i]*previewGain, -1, 1)*displayMax);
  }
  endShape();
  popMatrix();

  // draw an outline around the display area
  stroke(0);
  noFill();
  rect(0, 0, displaySine.length, 300);

  popMatrix();

  // if there are no sample slots, display a message to the user
  if (sampleSlots.size()==0) {
    fill(0);
    text("drag and drop .wav samples (16 bits)", 50, 30);
  }
  // label the waveforms
  fill(0, 0x50, 0);
  text("input", 700, 300);
  fill(0, 0, 0xFF);
  text("output", 740, 300);

  // draw the sample slots and UI elements
  for (int i = 0; i < sampleSlots.size(); i++) if (i<5) sampleSlots.get(i).draw();
  for (UIElement e : uiElements) e.draw();
}

void playCurrentSlot(boolean shortSample) {
  try {
    if (sample!=null) {
      sample.stop();
      sample.close();
    }
    if (selectedSlot.nbChannels == 1) sample = minim.createSample(selectedSlot.getProcessedSampleForPlayback(0, shortSample), selectedSlot.format);
    if (selectedSlot.nbChannels > 1) sample = minim.createSample(selectedSlot.getProcessedSampleForPlayback(0, shortSample), selectedSlot.getProcessedSampleForPlayback(1, shortSample), selectedSlot.format);
    sample.trigger();
  }
  catch(Exception e) {
    println(e);
  }
  if (shortSample) pendingPlayCurrentSlotShort = false;
  else pendingPlayCurrentSlot = false;
}
