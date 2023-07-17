
ProcessResult computeInterp(double[] waveIn, SampleSlot slot, ParameterSet pSet) {
  // initialize result and temporary variables
  ProcessResult result = new ProcessResult();
  double[] waveInComp = new double[waveIn.length];
  boolean[] landmarks = new boolean[waveIn.length];
  
  // compress input waveform using hyperbolic tangent function
  for (int i = 0; i < waveIn.length; i++) waveInComp[i] = Math.tanh(waveIn[i]*pSet.compressionFactor);
  
  double[] waveOut = new double[waveIn.length];
  double previousSample = 0;
  int zeroesSplitted = 0;
  int zeroesCrossed = 0;
  
  // iterate over waveform samples
  for (int i = 0; i < waveOut.length; ) {
    previousSample = waveOut[max(0, i-1)];
    
    // Update progress in GUI
    if (slot!=null) slot.updateProgressSample((float)i/waveOut.length);
    
    double sampleStart = waveInComp[i];
    double sampleEnd = sampleStart;
    int slideTimeSmp = 1;
    float maxSlideTimeSmp = min(max(pSet.defaultMaxSlideTimeSmp, 1), waveIn.length-i);
    
    // no optimization
    if (pSet.optimizationMethod==0) {
      slideTimeSmp = floor(maxSlideTimeSmp);
      sampleEnd = waveInComp[min(i+slideTimeSmp, waveIn.length-1)];
    }
    
    // optimization method 1 : calculate difference between interpolated and actual samples
    if (pSet.optimizationMethod==1) {
      
      // check every possible window size
      for (int j = i+1; j < i+maxSlideTimeSmp; j++) {
        double sampleMin = 1;
        double sampleMax = -1;
        for (int k = i; k < j; k ++) {
          sampleMin = min((float)sampleMin, (float)waveIn[k]);
          sampleMax = max((float)sampleMax, (float)waveIn[k]);
        }
        slideTimeSmp = floor((float)j-i);
        float totalDifference = 0;
        sampleEnd = waveInComp[j];
        double previousSampleTest = previousSample;
        
        // for each sample in this window size
        for (int k = i; k < j; k++) {
          double actualSample = waveInComp[k];
          double interpolatedSample = sampleStart;
          if (pSet.interpolationType == 1) interpolatedSample = lerp((float)sampleStart, (float)sampleEnd, ((float)k-i)/((float)(slideTimeSmp)));
          if (pSet.interpolationType == 2) interpolatedSample = map((float)sCurve(map(((float)k-i)/(float)(slideTimeSmp), 0, 1, -1, 1)), -1, 1, (float)sampleStart, (float)sampleEnd);
          if (pSet.interpolationType == 3) interpolatedSample = lerp(min((float)sampleStart, (float)sampleEnd), max((float)sampleStart, (float)sampleEnd), ((float)k-i)/((float)(slideTimeSmp)));
          if (pSet.interpolationType == 4) interpolatedSample = (k==i)?actualSample:0;
          if (pSet.interpolationType == 5) interpolatedSample = 0;
          if (pSet.sinusAddition!=0) interpolatedSample += sin((float)(k-i)/(float)slideTimeSmp*TWO_PI)*abs((float)sampleMax-(float)sampleMin)*pSet.sinusAddition;
          interpolatedSample = interpolatedSample*(1.0-pSet.iirFilter) + previousSampleTest*pSet.iirFilter;
          previousSampleTest = interpolatedSample;
          totalDifference += abs((float)(interpolatedSample-actualSample));
        }
        if (totalDifference > pSet.totalDifferenceThreshold && slideTimeSmp > 1) {
          slideTimeSmp -= 1;
          sampleEnd = waveInComp[i+slideTimeSmp];
          break;
        }
      }
    }
    
    // optimization method 2 : check for a significant jump from one sampled value to the next
    if (pSet.optimizationMethod==2) {
      // check every possible window size
      for (int j = i+1; j < i+maxSlideTimeSmp; j++) {
        slideTimeSmp = floor((float)j-i);
        sampleEnd = waveInComp[j];
        if (abs((float)sampleEnd-(float)sampleStart) > pSet.totalDifferenceThreshold && slideTimeSmp > 1) {
          slideTimeSmp -= 1;
          sampleEnd = waveInComp[i+slideTimeSmp];
          break;
        }
      }
    }
    
    // optimization method 3 : zero-crossing method
    if (pSet.optimizationMethod==3) {
      double previousZeroCrossed = sampleStart;
      // check longer window sizes than allowed by maxSlideTimeSmp if they're going to be divided later
      for (int j = i+1; j < ((pSet.zeroesToSplit>1)?waveIn.length:i+maxSlideTimeSmp); j++) {
        slideTimeSmp = floor((float)j-i);
        sampleEnd = waveInComp[j];
        if (((previousZeroCrossed>0)^(sampleEnd>0))&&slideTimeSmp>=1) {
          if (zeroesCrossed >= pSet.zeroesToSkip) {
            zeroesCrossed = 0;
            if (zeroesSplitted<pSet.zeroesToSplit) {
              slideTimeSmp = ceil((float)slideTimeSmp/(pSet.zeroesToSplit-zeroesSplitted));
              zeroesSplitted++;
            }
            if (zeroesSplitted>=pSet.zeroesToSplit) zeroesSplitted = 0;
            if (pSet.zeroesToSplit>1) slideTimeSmp = min(slideTimeSmp, floor(maxSlideTimeSmp));
            sampleEnd = waveInComp[i+slideTimeSmp];
            break;
          } else {
            zeroesCrossed++;
            previousZeroCrossed = sampleEnd;
          }
        }
      }
    }
    
    // uncompress the sample end value
    sampleStart = waveIn[i];
    sampleEnd   = atanh(sampleEnd)/pSet.compressionFactor;
    
    // find min and max of the original waveIn for this slice
    double sampleMin = 1;
    double sampleMax = -1;
    for (int k = i; k < i+slideTimeSmp; k ++) {
      sampleMin = min((float)sampleMin, (float)waveIn[k]);
      sampleMax = max((float)sampleMax, (float)waveIn[k]);
    }
    
    // interpolate, filter and constrain the final waveform slice
    for (int k = i; k < i+slideTimeSmp; k ++) {
      landmarks[k] = (k==i);
      waveOut[k] = sampleStart;
      if (pSet.interpolationType == 1) waveOut[k] = lerp((float)sampleStart, (float)sampleEnd, ((float)k-i)/((float)(slideTimeSmp)));
      if (pSet.interpolationType == 2) waveOut[k] = map((float)sCurve(map(((float)k-i)/(float)(slideTimeSmp), 0, 1, -1, 1)), -1, 1, (float)sampleStart, (float)sampleEnd);
      if (pSet.interpolationType == 3) waveOut[k] = lerp(min((float)sampleStart, (float)sampleEnd), max((float)sampleStart, (float)sampleEnd), ((float)k-i)/((float)(slideTimeSmp)));
      if (pSet.interpolationType == 4) waveOut[k] = (k==i)?sampleStart:0;
      if (pSet.interpolationType == 5) waveOut[k] = 0;
      if (pSet.sinusAddition!=0) waveOut[k] += sin((float)(k-i)/(float)slideTimeSmp*TWO_PI)*abs((float)sampleMax-(float)sampleMin)*pSet.sinusAddition;
      waveOut[k] = waveOut[k]*(1.0-pSet.iirFilter) + previousSample*pSet.iirFilter;
      previousSample = waveOut[k];
      if (waveOut[k]>+1) waveOut[k]=+1;
      if (waveOut[k]<-1) waveOut[k]=-1;
    }
    
    // proceed to next slice
    i+=slideTimeSmp;
  }
  
  // fill result with the final processed waveform and landmarks
  result.nSampleProcessed = waveOut;
  result.landmarks = landmarks;
  return result;
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

class ProcessResult {
  double[] nSampleProcessed;
  boolean[] landmarks;
}

class ParameterSet {
  float totalDifferenceThreshold;
  int zeroesToSkip;
  int zeroesToSplit;
  float compressionFactor;
  float defaultMaxSlideTimeSmp;
  int interpolationType;// 0 = rectangular, 1 = linear, 2 = sCurve, 3 = sawtooth, 4 = boxcar; 5 = zero
  float sinusAddition;
  float iirFilter;
  int optimizationMethod;// 0 = fixed, 1 = integral, 2 = difference, 3 = zero-crossing
  int processStart;
  int processEnd;
  int target;// 0 = processed, 1 = short
  ParameterSet copy() {
    ParameterSet copy = new ParameterSet();
    copy.totalDifferenceThreshold = this.totalDifferenceThreshold;
    copy.zeroesToSkip = this.zeroesToSkip;
    copy.zeroesToSplit = this.zeroesToSplit;
    copy.compressionFactor = this.compressionFactor;
    copy.defaultMaxSlideTimeSmp = this.defaultMaxSlideTimeSmp;
    copy.interpolationType = this.interpolationType;
    copy.sinusAddition = this.sinusAddition;
    copy.iirFilter = this.iirFilter;
    copy.optimizationMethod = this.optimizationMethod;
    copy.processStart = this.processStart;
    copy.processEnd = this.processEnd;
    copy.target = this.target;
    return copy;
  }
}
