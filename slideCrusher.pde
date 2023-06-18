
import drop.*;

import java.io.*;
import javax.sound.sampled.*;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.util.Random;

import ddf.minim.*;

// automatically normalize display

// todo mode with difference instead of integral, or fixed length
// cubic interpolation
// IIR filter

// preview files from inside then export
// exported as filename_processed

// custom UI
// actual UI values
// tooltip explanations
// display max sample time as Hz

// parameters
ParameterSet previewSet = new ParameterSet();

float previewOffset;
float previewGain;

String sourceUrl = "";

// display
double[] displaySine = new double[400-20];
double[] displayInterp = new double[400-20];

ArrayList<SampleSlot> sampleSlots = new ArrayList<SampleSlot>();
SampleSlot selectedSlot;

SDrop drop;

Minim minim;
AudioSample sample;

void setup() {
  size(800, 600);
  drop = new SDrop(this);
  minim = new Minim(this);
  for (int i=0; i<displaySine.length; i++) displaySine[i] = sin(pow((float)(i+175)/100, 2))*(1-(float)i/displaySine.length);
  setBasicUIElements();
  updateDisplay();
}

void dropEvent(DropEvent theDropEvent) {
  if (theDropEvent.isFile()) {
    selectedSlot = new SampleSlot();
    selectedSlot.url = theDropEvent.toString();
    selectedSlot.loadFile();
    selectedSlot.normalizeDisplay();
    sampleSlots.add(selectedSlot);
    updateDisplay();
  }
}

void updateDisplay() {
  if (selectedSlot!=null) {
    if (selectedSlot.nSample!=null) {
      for (int i=0; i < displaySine.length; i++) displaySine[i] = selectedSlot.nSample[0][floor(constrain(((float)selectedSlot.nSample[0].length-displaySine.length)*previewOffset, 0, selectedSlot.nSample[0].length-displaySine.length)+i)];
    }
  }
  displayInterp = computeInterp(displaySine, null, previewSet);
}

void processCurrentSlot() {
  if (selectedSlot!=null && !selectedSlot.isProcessing) {
    selectedSlot.process();
  }
}

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
    slot.nSampleProcessed = new double[slot.nbChannels][];
    for (int c = 0; c < slot.nbChannels; c++) {
      slot.updateProgressCurrentChannel(c);
      slot.updateProgressSample(0);
      slot.nSampleProcessed[c] = computeInterp(slot.nSample[c], slot, slot.parameterSet);
    }

    try {
      // Convert double samples back into byte data
      byte[] byteData = new byte[slot.audioDataLength];
      for (int c = 0; c < slot.nbChannels; c++) {
        for (int i = 0; i < slot.nSampleProcessed[c].length; i++) {
          int sampleAsInt = (int)(slot.nSampleProcessed[c][i] * slot.maxSampleValue);

          byte[] sampleBytes;
          switch (slot.bytePerSample) {
          case 1:
            sampleBytes = new byte[] {(byte) sampleAsInt};
            break;
          case 2:
            sampleBytes = ByteBuffer.allocate(2).order(slot.isBigEndian?ByteOrder.BIG_ENDIAN:ByteOrder.LITTLE_ENDIAN).putShort((short) sampleAsInt).array();
            break;
          case 3:
            sampleBytes = new byte[3];
            sampleBytes[0] = (byte) (sampleAsInt & 0xFF);
            sampleBytes[1] = (byte) ((sampleAsInt >> 8) & 0xFF);
            sampleBytes[2] = (byte) ((sampleAsInt >> 16) & 0xFF);
            break;
          default:
            throw new IllegalArgumentException("Unsupported byte depth: " + slot.bytePerSample);
          }

          System.arraycopy(sampleBytes, 0, byteData, i*slot.bytePerSample*slot.nbChannels + c*slot.bytePerSample, slot.bytePerSample);
        }
      }

      // Create a new AudioInputStream from the byte data
      ByteArrayInputStream bais = new ByteArrayInputStream(byteData);
      AudioInputStream outputAis = new AudioInputStream(bais, slot.format, slot.audioDataLength / slot.format.getFrameSize());

      // Write the AudioInputStream to a file
      AudioSystem.write(outputAis, AudioFileFormat.Type.WAVE, new File(sketchPath("output.wav")));
    }
    catch(Exception e) {
      e.printStackTrace();
    }

    slot.isProcessing = false;
  }
}

void draw() {
  background(0xF0);
  // simulated waveform
  noFill();
  pushMatrix();
  translate(400+10, 10);
  stroke(0);
  fill(0xFF);
  rect(0, 0, displaySine.length, 300);
  translate(0, 150);
  float displayMax = 147;
  // difference
  for (int i=0; i<displaySine.length; i++) {
    stroke(0xCC, 0xCC, 0xFF);
    line(i, constrain((float)displaySine[i]*previewGain, -1, 1)*displayMax, i, constrain((float)displayInterp[i]*previewGain, -1, 1)*displayMax);
  }
  // original
  stroke(0, 0x50, 0);
  strokeWeight(2);
  noFill();
  beginShape();
  for (int i=0; i<displaySine.length; i++) {
    vertex(i, constrain((float)displaySine[i]*previewGain, -1, 1)*displayMax);
  }
  endShape();
  // reconstructed
  stroke(0, 0, 0xFF);
  strokeWeight(1);
  noFill();
  beginShape();
  for (int i=0; i<displayInterp.length; i++) {
    vertex(i, constrain((float)displayInterp[i]*previewGain, -1, 1)*displayMax);
  }
  endShape();
  popMatrix();

  for (int i = 0; i < sampleSlots.size(); i++) {
    pushMatrix();
    translate(30, 30+i*80);
    sampleSlots.get(i).draw();
    popMatrix();
  }

  for (UIElement e : uiElements) e.draw();
}


void mousePressed() {
  for (UIElement e : uiElements) e.mousePressed(mouseX, mouseY);
}

void mouseDragged() {
  for (UIElement e : uiElements) e.mouseDragged(mouseX, mouseY);
}

void mouseReleased() {
  for (UIElement e : uiElements) e.mouseReleased();
}

double[] computeInterp(double[] waveIn, SampleSlot slot, ParameterSet pSet) {
  double[] waveInComp = new double[waveIn.length];
  for (int i = 0; i < waveIn.length; i++) waveInComp[i] = Math.tanh(waveIn[i]*pSet.compressionFactor);
  double[] waveOut = new double[waveIn.length];
  for (int i = 0; i < waveOut.length; ) {
    if (slot!=null) slot.updateProgressSample((float)i/waveOut.length);
    double sampleStart = waveInComp[i];
    double sampleEnd = sampleStart;
    int slideTimeSmp = 1;
    float maxSlideTimeSmp = min(pSet.defaultMaxSlideTimeSmp, waveIn.length-i);
    for (int j = i+1; j < i+maxSlideTimeSmp; j++) {
      slideTimeSmp = floor((float)j-i);
      float totalDifference = 0;
      sampleEnd = waveInComp[j];
      for (int k = i; k < j; k++) {
        double actualSample = waveInComp[k];
        double interpolatedSample = sampleStart;
        if (pSet.interpolationType == 1) interpolatedSample = lerp((float)sampleStart, (float)sampleEnd, ((float)k-i)/((float)(slideTimeSmp)));
        if (pSet.interpolationType == 2) interpolatedSample = (k==i)?actualSample:0;
        if (pSet.interpolationType == 3) interpolatedSample = map((float)sCurve(map(((float)k-i)/(float)(slideTimeSmp), 0, 1, -1, 1)), -1, 1, (float)sampleStart, (float)sampleEnd);
        if (pSet.interpolationType == 4) interpolatedSample = 0;
        if (pSet.sinusAddition!=0) interpolatedSample += sin((float)(k-i)/(float)slideTimeSmp*TWO_PI)*abs((float)sampleStart-(float)sampleEnd)*pSet.sinusAddition;
        totalDifference += abs((float)(interpolatedSample-actualSample));
      }
      if (totalDifference > pSet.totalDifferenceThreshold && slideTimeSmp > 1) {
        slideTimeSmp -= 1;
        sampleEnd = waveInComp[i+slideTimeSmp];
        break;
      }
    }
    sampleStart = atanh(sampleStart)/pSet.compressionFactor;
    sampleEnd   = atanh(sampleEnd)/pSet.compressionFactor;
    for (int k = i; k < i+slideTimeSmp; k ++) {
      waveOut[k] = sampleStart;
      if (pSet.interpolationType == 1) waveOut[k] = lerp((float)sampleStart, (float)sampleEnd, ((float)k-i)/((float)(slideTimeSmp)));
      if (pSet.interpolationType == 2) waveOut[k] = (k==i)?sampleStart:0;
      if (pSet.interpolationType == 3) waveOut[k] = map((float)sCurve(map(((float)k-i)/(float)(slideTimeSmp), 0, 1, -1, 1)), -1, 1, (float)sampleStart, (float)sampleEnd);
      if (pSet.interpolationType == 4) waveOut[k] = 0;
      if (pSet.sinusAddition!=0) waveOut[k] += sin((float)(k-i)/(float)slideTimeSmp*TWO_PI)*abs((float)sampleStart-(float)sampleEnd)*pSet.sinusAddition;
      if (waveOut[k]>+1) waveOut[k]=+1;
      if (waveOut[k]<-1) waveOut[k]=-1;
    }
    i+=slideTimeSmp;
  }
  return waveOut;
}

double atanh(double x) {
  double epsilon = 1e-7;
  x = Math.max(-1 + epsilon, Math.min(1 - epsilon, x));
  return 0.5 * Math.log((1 + x) / (1 - x));
}

double sCurve(double x) {
  return Math.tanh(x) / Math.tanh(1);
}

public static double cubicInterpolation(double v0, double v1, double v2, double v3, double x) {
  double a = -0.5 * v0 + 1.5 * v1 - 1.5 * v2 + 0.5 * v3;
  double b = v0 - 2.5 * v1 + 2 * v2 - 0.5 * v3;
  double c = -0.5 * v0 + 0.5 * v2;
  double d = v1;
  return a*x*x*x + b*x*x + c*x + d;
}

class SampleSlot {
  String url="";
  float processBar;
  int nbChannels;
  double[][] nSample;
  double[][] nSampleProcessed;
  float maxSampleValue;
  int audioDataLength;
  boolean isBigEndian;
  int bytePerSample;
  AudioFormat format;
  boolean isProcessing = false;
  float progress = 0;
  int progressCurrentChannel = 0;
  float progressSample = 0;
  ParameterSet parameterSet;
  SampleSlot() {
  }
  void loadFile() {
    try {
      // Read the audio file
      AudioInputStream ais = AudioSystem.getAudioInputStream(new File(url));
      format = ais.getFormat();

      // Get the raw audio data
      int frameLength = (int)ais.getFrameLength();
      byte[] audioData = new byte[frameLength * format.getFrameSize()];
      audioDataLength = audioData.length;
      ais.read(audioData);

      nbChannels = format.getChannels();

      int sampleSizeInBits = format.getSampleSizeInBits();
      isBigEndian = format.isBigEndian();
      bytePerSample = 1;

      if (sampleSizeInBits == 8) {
        // For 8-bit audio, values range from -128 to 127
        maxSampleValue = 127f;
        bytePerSample = 1;
      } else if (sampleSizeInBits == 16) {
        // For 16-bit audio, values range from -32768 to 32767
        maxSampleValue = 32767f;
        bytePerSample = 2;
      } else if (sampleSizeInBits == 24) {
        // For 24-bit audio, values range from -8388608 to 8388607
        maxSampleValue = 8388607f;
        bytePerSample = 3;
      } else {
        throw new IllegalArgumentException("Unsupported bit depth: " + sampleSizeInBits);
      }

      nSample = new double[nbChannels][audioData.length/(bytePerSample*nbChannels)];
      for (int i = 0; i < audioData.length; i += bytePerSample*nbChannels) {
        for (int c = 0; c < nbChannels; c++) {
          int offset = i + c*bytePerSample;
          double sampleValue = 0.0;
          if (bytePerSample == 1) {
            sampleValue = (double)audioData[offset] / maxSampleValue;
          } else if (bytePerSample == 2) {
            short sample = ByteBuffer.wrap(audioData, offset, 2).order(isBigEndian?ByteOrder.BIG_ENDIAN:ByteOrder.LITTLE_ENDIAN).getShort();
            sampleValue = (double)sample / maxSampleValue;
          } else if (bytePerSample == 3) {
            int sample = ByteBuffer.wrap(audioData, offset, 3).order(isBigEndian?ByteOrder.BIG_ENDIAN:ByteOrder.LITTLE_ENDIAN).getInt();
            sampleValue = (double)sample / maxSampleValue;
          }
          nSample[c][i/(bytePerSample*nbChannels)] = sampleValue;
        }
      }

      ais.close();
    }
    catch (Exception e) {
      println(e);
    }
  }
  void updateProgressSample(float f) {
    progressSample = f;
    progress = ((float)progressCurrentChannel/nbChannels)+(progressSample/nbChannels);
  }
  void updateProgressCurrentChannel(int i) {
    progressCurrentChannel = i;
    progress = ((float)progressCurrentChannel/nbChannels)+(progressSample/nbChannels);
  }
  void draw() {
    noFill();
    if (this==selectedSlot) fill(0xFF);
    stroke(0);
    strokeWeight(1);
    rect(0, 0, 300, 70);
    noStroke();
    if (isProcessing) {
      fill(0xFF, 0xFF, 0);
      rect(1, 1, progress*(300-1), (70-1));
    }
    fill(0);
    text(url, 10, 10, 300-20, 70-20);
  }
  void process() {
    parameterSet = previewSet.copy();
    new ProcessRunner(this).start();
  }
  float[] getSampleForPlayback(int channel) {
    if (nSampleProcessed!=null) {
      float[] preview = new float[nSampleProcessed[channel].length];
      for (int i=0; i<preview.length; i++) preview[i] = (float)nSampleProcessed[channel][i];
      return preview;
    } else {
      float[] preview = new float[nSample[channel].length];
      for (int i=0; i<preview.length; i++) preview[i] = (float)nSample[channel][i];
      return preview;
    }
  }
  void normalizeDisplay() {
    float loudest = 0;
    float loudestPosition = 0;
    for (int c=0; c<nbChannels; c++) {
      for (int s=0; s<nSample[c].length; s++) {
        if (abs((float)nSample[c][s])>loudest) {
          loudest = abs((float)nSample[c][s]);
          loudestPosition = (float)s/(nSample[c].length-displaySine.length);
        }
      }
    }
    if (loudest!=0) previewGain = 1.0/loudest;
    previewOffset = loudestPosition-((float)displaySine.length*0.5f/nSample[0].length);
    updateDisplay();
    // TODO update sliders
  }
}

class ParameterSet {
  float totalDifferenceThreshold;
  float compressionFactor;
  float defaultMaxSlideTimeSmp;
  int interpolationType;// 0 = rectangular, 1 = linear, 2 = boxcar, 3 = sCurve; 4 = zero
  float sinusAddition;
  ParameterSet copy() {
    ParameterSet copy = new ParameterSet();
    copy.totalDifferenceThreshold = this.totalDifferenceThreshold;
    copy.compressionFactor = this.compressionFactor;
    copy.defaultMaxSlideTimeSmp = this.defaultMaxSlideTimeSmp;
    copy.interpolationType = this.interpolationType;
    copy.sinusAddition = this.sinusAddition;
    return copy;
  }
}
