
class SampleSlot extends UIElement {
  String url="";
  float processBar;
  int nbChannels;
  double[][] nSample;
  double[][] nSampleProcessed;
  double[][] nSampleProcessedShort;
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
  boolean needsReprocessing = true;
  SampleSlot(float x, float y) {
    super("slot", x, y, 350, 40);
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
  void exportSample() {
    if (nSampleProcessed!=null && !isProcessing) {
      try {
        // Convert double samples back into byte data
        byte[] byteData = new byte[audioDataLength];
        for (int c = 0; c < nbChannels; c++) {
          for (int i = 0; i < nSampleProcessed[c].length; i++) {
            int sampleAsInt = (int)(nSampleProcessed[c][i] * maxSampleValue);

            byte[] sampleBytes;
            switch (bytePerSample) {
            case 1:
              sampleBytes = new byte[] {(byte) sampleAsInt};
              break;
            case 2:
              sampleBytes = ByteBuffer.allocate(2).order(isBigEndian?ByteOrder.BIG_ENDIAN:ByteOrder.LITTLE_ENDIAN).putShort((short) sampleAsInt).array();
              break;
            case 3:
              sampleBytes = new byte[3];
              sampleBytes[0] = (byte) (sampleAsInt & 0xFF);
              sampleBytes[1] = (byte) ((sampleAsInt >> 8) & 0xFF);
              sampleBytes[2] = (byte) ((sampleAsInt >> 16) & 0xFF);
              break;
            default:
              throw new IllegalArgumentException("Unsupported byte depth: " + bytePerSample);
            }

            System.arraycopy(sampleBytes, 0, byteData, i*bytePerSample*nbChannels + c*bytePerSample, bytePerSample);
          }
        }

        // Create a new AudioInputStream from the byte data
        ByteArrayInputStream bais = new ByteArrayInputStream(byteData);
        AudioInputStream outputAis = new AudioInputStream(bais, format, audioDataLength / format.getFrameSize());

        // Write the AudioInputStream to a file
        String exportUrl = url;
        int lastDot = 0;
        for (int i=exportUrl.length()-1; i>=0; i--) {
          if (exportUrl.charAt(i)=='.') {
            lastDot = i;
            break;
          }
        }
        String baseExportUrl = exportUrl.substring(0, lastDot)+"_processed";
        int incrementName = 0;
        exportUrl = baseExportUrl+"_"+nf(incrementName++,2)+".wav";
        while ((new File(exportUrl)).exists()) exportUrl = baseExportUrl+"_"+nf(incrementName++,2)+".wav"; 
        AudioSystem.write(outputAis, AudioFileFormat.Type.WAVE, new File(exportUrl));
      }
      catch(Exception e) {
        println(e);
      }
    }
    pendingExportCurrentSlot = false;
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
    pushMatrix();
    translate(x, y);
    UIRectangle(0, 0, w, h, this==selectedSlot, this==selectedSlot);
    noStroke();
    if (isProcessing) {
      fill(UIColors[8]);
      rect(2, 2, progress*(w-4), (h-4));
    }

    fill(UIColors[7]);
    String urlCropped = url.substring(0);
    if (urlCropped.length()>40) urlCropped = "..."+url.substring(max(url.length()-40, 0), url.length());
    text(urlCropped, 10, 10, w-20, h-20);
    popMatrix();
  }
  void process() {
    parameterSet = previewSet.copy();
    parameterSet.processStart = 0;
    parameterSet.processEnd = nSample[0].length;
    parameterSet.target = 0;
    new ProcessRunner(this).start();
  }
  void processShort() {
    parameterSet = previewSet.copy();
    parameterSet.target = 1;
    new ProcessRunner(this).start();
  }
  float[] getOriginalSampleForPlayback(int channel) {
    float[] preview = new float[nSample[channel].length];
    for (int i=0; i<preview.length; i++) preview[i] = (float)nSample[channel][i];
    return preview;
  }
  float[] getProcessedSampleForPlayback(int channel, boolean shortSample) {
    float[] preview = null;
    if (shortSample) {
      if (processedSampleShortAvailable()) {
        preview = new float[nSampleProcessedShort[channel].length]; 
        for (int i=0; i<preview.length; i++) preview[i] = (float)nSampleProcessedShort[channel][i];
        return preview;
      }      
    } else {
      if (processedSampleAvailable()) {
        preview = new float[nSampleProcessed[channel].length];
        for (int i=0; i<preview.length; i++) preview[i] = (float)nSampleProcessed[channel][i];
        return preview;
      }
    }
    return preview;
  }
  boolean processedSampleAvailable() {
    return !isProcessing&&nSampleProcessed!=null;
  }
  boolean processedSampleShortAvailable() {
    return !isProcessing&&nSampleProcessedShort!=null;
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
    if (loudest!=0) previewGain = 0.9/loudest;
    previewOffset = constrain(loudestPosition-((float)displaySine.length*0.5f/nSample[0].length), 0, 1);
    try {
      ((Slider)getUiElementCalled("previewOffset")).value = previewOffset;
      ((Slider)getUiElementCalled("previewOffset")).updateOperation.execute();
      ((Slider)getUiElementCalled("previewGain")).value = previewGain/30.0;
      ((Slider)getUiElementCalled("previewGain")).updateOperation.execute();
    }
    catch(Exception e) {
      println(e);
    }
    updateDisplay();
  }
  void mousePressed(float mX, float mY) {
    if (mX>x&&mY>y&&mX<x+w&&mY<y+h) {
      if (selectedSlot != this) {
        pendingPlayCurrentSlot = false;
        pendingExportCurrentSlot = false;
        selectedSlot = this;
        updateDisplay();
      }
    }
  }
  void mouseDragged(float x, float y) {
  };
  void mouseReleased(float x, float y) {
  };
}
