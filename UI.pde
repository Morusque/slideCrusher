
ArrayList<UIElement> uiElements = new ArrayList<UIElement>();

Tooltip tooltip;

void setBasicUIElements() {

  tooltip = new Tooltip("tooltip", 410, 600, 350, 80);
  uiElements.add(tooltip);

  // previewOffset
  Slider sliderPreviewOffset = new Slider("previewOffset", 30, 311, 800-50, 20, 0.5, false, 0);
  sliderPreviewOffset.updateOperation = new UpdateOperation() {
    @Override
      public void execute() {
      sliderPreviewOffset.scaledValue = sliderPreviewOffset.value;
      previewOffset = sliderPreviewOffset.scaledValue;
      updateDisplay();
    }
  };
  sliderPreviewOffset.setTooltip(tooltip, "preview offset");
  sliderPreviewOffset.showLabel = false;
  uiElements.add(sliderPreviewOffset);

  // previewGain
  Slider sliderPreviewGain = new Slider("previewGain", 10, 10, 20, 300, 0.03, true, 0);
  sliderPreviewGain.updateOperation = new UpdateOperation() {
    @Override
      public void execute() {
      sliderPreviewGain.scaledValue = sliderPreviewGain.value*30;
      previewGain = sliderPreviewGain.scaledValue;
      updateDisplay();
    }
  };
  sliderPreviewGain.setTooltip(tooltip, "preview gain");
  sliderPreviewGain.showLabel = false;
  uiElements.add(sliderPreviewGain);

  // defaultMaxSlideTimeSmp
  Slider sliderDefaultMaxSlideTimeSmp = new Slider("frequency", 410, 370, 200, 20, 0.5, false, 0);
  sliderDefaultMaxSlideTimeSmp.updateOperation = new UpdateOperation() {
    @Override
      public void execute() {
      sliderDefaultMaxSlideTimeSmp.scaledValue = floor(map(pow(1-sliderDefaultMaxSlideTimeSmp.value, 5), 0, 1, 1, 5000));
      previewSet.defaultMaxSlideTimeSmp = sliderDefaultMaxSlideTimeSmp.scaledValue;
      updateDisplay();
      if (selectedSlot!=null) selectedSlot.needsReprocessing = true;
    }
  };
  LabelOperation sliderDefaultMaxSlideTimeSmpLabel = new LabelOperation() {
    @Override
      public String getLabel() {
      float samplingFr = 44100;
      if (selectedSlot!=null) if (selectedSlot.format!=null)  samplingFr = selectedSlot.format.getSampleRate();
      float value = samplingFr/sliderDefaultMaxSlideTimeSmp.scaledValue;
      value = round(value*100.0f)/100.0f;
      return value + " Hz";
    }
  };
  sliderDefaultMaxSlideTimeSmp.setLabelOperation(sliderDefaultMaxSlideTimeSmpLabel);
  sliderDefaultMaxSlideTimeSmp.setTooltip(tooltip, "default sampling frequency \r\nsimilar to frequancy in a classic bitcrusher");
  uiElements.add(sliderDefaultMaxSlideTimeSmp);

  // optimizationMethod method
  RadioButtons radioOptimizationMethod = new RadioButtons("optimizationMethod", 410, 410, 250, 20, 0, 4);
  radioOptimizationMethod.setLabels(new String[]{"no", "integral", "gap", "zero"});
  radioOptimizationMethod.updateOperation = new UpdateOperation() {
    @Override
      public void execute() {
      previewSet.optimizationMethod = radioOptimizationMethod.value;
      if (previewSet.optimizationMethod == 0) radioOptimizationMethod.description = "how to optimize the sampling time \r\ncurrent type : \r\nno optimization";
      if (previewSet.optimizationMethod == 1) radioOptimizationMethod.description = "how to optimize the sampling time \r\ncurrent type : \r\nadd more sampling points to make sure the pre/post difference (blue zone) doesn't exeed the threshold";
      if (previewSet.optimizationMethod == 2) radioOptimizationMethod.description = "how to optimize the sampling time \r\ncurrent type : \r\nadd more sampling points to make sure the difference between consecutive sampled points doesn't exeed the threshold";
      if (previewSet.optimizationMethod == 3) radioOptimizationMethod.description = "how to optimize the sampling time \r\ncurrent type : \r\nadd sampling points when crossing zero, use threshold to skip zeroes";
      updateDisplay();
      if (selectedSlot!=null) selectedSlot.needsReprocessing = true;
    }
  };
  radioOptimizationMethod.setTooltip(tooltip, "how to optimize the sampling time");
  uiElements.add(radioOptimizationMethod);

  // totalDifferenceThreshold
  Slider sliderTotalDifferenceThreshold = new Slider("threshold", 410, 440, 200, 20, 0.3, false, 0);
  sliderTotalDifferenceThreshold.updateOperation = new UpdateOperation() {
    @Override
      public void execute() {
      sliderTotalDifferenceThreshold.scaledValue = sliderTotalDifferenceThreshold.value;
      previewSet.totalDifferenceThreshold = map(pow(1.0-sliderTotalDifferenceThreshold.scaledValue, 10), 0, 1, 0.00001, 50.0);
      previewSet.zeroesToSkip = constrain(floor(map(sliderTotalDifferenceThreshold.scaledValue, 0.5, 1, 0, 10)), 0, 10);
      previewSet.zeroesToSplit = constrain(floor(map(sliderTotalDifferenceThreshold.scaledValue, 0.5, 0, 0, 10)), 1, 10);
      updateDisplay();
      if (selectedSlot!=null) selectedSlot.needsReprocessing = true;
    }
  };
  sliderTotalDifferenceThreshold.setTooltip(tooltip, "threshold used by the optimization process");
  uiElements.add(sliderTotalDifferenceThreshold);

  // compressionFactor
  Slider sliderCompressionFactor = new Slider("compression", 410, 470, 200, 20, 0.5, false, 0);
  sliderCompressionFactor.updateOperation = new UpdateOperation() {
    @Override
      public void execute() {
      sliderCompressionFactor.scaledValue = sliderCompressionFactor.value;
      previewSet.compressionFactor = map(pow(sliderCompressionFactor.scaledValue, 1.5), 0, 1, 0.1, 5);
      updateDisplay();
      if (selectedSlot!=null) selectedSlot.needsReprocessing = true;
    }
  };
  sliderCompressionFactor.setTooltip(tooltip, "temporarily compress the sample during optimization \r\nlower values generate more distortion and gating \r\nhigher values keep precision on quiter parts of the audio");
  uiElements.add(sliderCompressionFactor);

  // interpolationType
  RadioButtons radioInterpolationType = new RadioButtons("interpolation", 410, 510, 250, 20, 0, 6);
  radioInterpolationType.setLabels(new String[]{"s&h", "lin", "s", "saw", "box", "zero"});
  radioInterpolationType.updateOperation = new UpdateOperation() {
    @Override
      public void execute() {
      previewSet.interpolationType = radioInterpolationType.value;
      if (previewSet.interpolationType == 0) radioInterpolationType.description = "current interpolation type : \r\nsample and hold";
      if (previewSet.interpolationType == 1) radioInterpolationType.description = "current interpolation type : \r\nlinear";
      if (previewSet.interpolationType == 2) radioInterpolationType.description = "current interpolation type : \r\ns curve";
      if (previewSet.interpolationType == 3) radioInterpolationType.description = "current interpolation type : \r\nsawtooth";
      if (previewSet.interpolationType == 4) radioInterpolationType.description = "current interpolation type : \r\nboxcar";
      if (previewSet.interpolationType == 5) radioInterpolationType.description = "current interpolation type : \r\nzero";
      updateDisplay();
      if (selectedSlot!=null) selectedSlot.needsReprocessing = true;
    }
  };
  radioInterpolationType.setTooltip(tooltip, "interpolation type");
  uiElements.add(radioInterpolationType);

  // sinusAddition
  Slider sliderSinusAddition = new Slider("sinus", 410, 540, 200, 20, 0.5, false, 0);
  sliderSinusAddition.updateOperation = new UpdateOperation() {
    @Override
      public void execute() {
      sliderSinusAddition.scaledValue = map(sliderSinusAddition.value, 0, 1, -1, 1);
      if (abs(sliderSinusAddition.scaledValue)<0.1) sliderSinusAddition.scaledValue = 0;
      else sliderSinusAddition.scaledValue = abs(pow(sliderSinusAddition.scaledValue, 4))*(sliderSinusAddition.scaledValue/abs(sliderSinusAddition.scaledValue));
      previewSet.sinusAddition = sliderSinusAddition.scaledValue;
      updateDisplay();
      if (selectedSlot!=null) selectedSlot.needsReprocessing = true;
    }
  };
  sliderSinusAddition.setTooltip(tooltip, "adds one arbitrary sinewave between each sampling points, amplitude of the sines follows sound amplitude");
  uiElements.add(sliderSinusAddition);

  // IIR filter
  Slider sliderIIRFilter = new Slider("filter", 410, 570, 200, 20, 0.0, false, 0);
  sliderIIRFilter.updateOperation = new UpdateOperation() {
    @Override
      public void execute() {
      sliderIIRFilter.scaledValue = sliderIIRFilter.value;
      previewSet.iirFilter = sliderIIRFilter.scaledValue;
      updateDisplay();
      if (selectedSlot!=null) selectedSlot.needsReprocessing = true;
    }
  };
  sliderIIRFilter.setTooltip(tooltip, "applies an IIR filter in the process");
  uiElements.add(sliderIIRFilter);

  Button processButton = new Button("process", 10, 610, 100, 20);
  processButton.show = false;
  processButton.updateOperation = new UpdateOperation() {
    @Override
      public void execute() {
      processCurrentSlot();
    }
  };
  processButton.setTooltip(tooltip, "process selected sample");
  uiElements.add(processButton);

  Button exportCurrentSlot = new Button("export", 10, 630, 100, 20);
  exportCurrentSlot.show = false;
  exportCurrentSlot.updateOperation = new UpdateOperation() {
    @Override
      public void execute() {
      if (selectedSlot!=null) {
        if (!selectedSlot.isProcessing) {
          if (selectedSlot.nSampleProcessed!=null&&!selectedSlot.needsReprocessing) {
            selectedSlot.exportSample();
          } else {
            pendingExportCurrentSlot=true;
            processCurrentSlot();
          }
        }
      }
    }
  };
  exportCurrentSlot.labelOperation = new LabelOperation() {
    @Override
      public String getLabel() {
      if (selectedSlot.needsReprocessing) return "(export)";
      return "export";
    }
  };  
  exportCurrentSlot.setTooltip(tooltip, "export current slot (at same location with a _processed suffix)");
  uiElements.add(exportCurrentSlot);

  Button removeCurrentSlot = new Button("remove", 10, 650, 100, 20);
  removeCurrentSlot.show = false;
  removeCurrentSlot.updateOperation = new UpdateOperation() {
    @Override
      public void execute() {
      if (selectedSlot!=null) {
        sampleSlots.remove(selectedSlot);
        for (int i=0; i<sampleSlots.size(); i++) sampleSlots.get(i).y=350+i*50;
        if (sampleSlots.size()>0) selectedSlot = sampleSlots.get(0);
        else {
          selectedSlot = null;
          getUiElementCalled("displayChannel").show=false;
          getUiElementCalled("process").show=false;
          getUiElementCalled("play input").show=false;
          getUiElementCalled("play output").show=false;
          getUiElementCalled("stop").show=false;
          getUiElementCalled("export").show=false;
          getUiElementCalled("remove").show=false;
          computeDefaultPreviewWaveform();
        }
        updateDisplay();
      }
    }
  };
  removeCurrentSlot.setTooltip(tooltip, "remove selected slot");
  uiElements.add(removeCurrentSlot);

  Button playCurrentSlot = new Button("play input", 150, 610, 100, 20);
  playCurrentSlot.show = false;
  playCurrentSlot.updateOperation = new UpdateOperation() {
    @Override
      public void execute() {
      if (sample!=null) {
        sample.stop();
        sample.close();
      }
      if (selectedSlot!=null) {
        if (selectedSlot.nbChannels == 1) sample = minim.createSample(selectedSlot.getOriginalSampleForPlayback(0), selectedSlot.format);
        if (selectedSlot.nbChannels > 1) sample = minim.createSample(selectedSlot.getOriginalSampleForPlayback(0), selectedSlot.getOriginalSampleForPlayback(1), selectedSlot.format);
        sample.trigger();
      }
    }
  };
  playCurrentSlot.setTooltip(tooltip, "play selected sample (original)");
  uiElements.add(playCurrentSlot);

  Button playCurrentSlotOut = new Button("play output", 150, 630, 100, 20);
  playCurrentSlotOut.show = false;
  playCurrentSlotOut.updateOperation = new UpdateOperation() {
    @Override
      public void execute() {
      if (sample!=null) {
        sample.stop();
        sample.close();
      }
      if (selectedSlot!=null) {
        if (selectedSlot.processedSampleAvailable()&&!selectedSlot.needsReprocessing) {
          playCurrentSlot();
        } else {
          pendingPlayCurrentSlot = true;
          processCurrentSlot();
        }
      }
    }
  };
  playCurrentSlotOut.labelOperation = new LabelOperation() {
    @Override
      public String getLabel() {
      if (selectedSlot.needsReprocessing) return "(play output)";
      return "play output";
    }
  };
  playCurrentSlotOut.setTooltip(tooltip, "play selected sample (processed)");
  uiElements.add(playCurrentSlotOut);

  Button stopAudio = new Button("stop", 150, 650, 100, 20);
  stopAudio.show = false;
  stopAudio.updateOperation = new UpdateOperation() {
    @Override
      public void execute() {
      if (sample!=null) {
        sample.stop();
        sample.close();
      }
    }
  };
  stopAudio.setTooltip(tooltip, "stop audio");
  uiElements.add(stopAudio);

  RadioButtons displayChannelRadio = new RadioButtons("displayChannel", 620, 20, 150, 20, 0, 2);
  displayChannelRadio.showLabel = false;
  displayChannelRadio.show = false;
  displayChannelRadio.setLabels(new String[]{"ch1", "ch2"});
  displayChannelRadio.updateOperation = new UpdateOperation() {
    @Override
      public void execute() {
      displayChannel = displayChannelRadio.value;
      updateDisplay();
    }
  };
  displayChannelRadio.setTooltip(tooltip, "which channel to preview");
  uiElements.add(displayChannelRadio);

  for (UIElement e : uiElements) if (e.updateOperation!=null) e.updateOperation.execute();
}

// A class representing a UI element
abstract class UIElement {
  float x, y, w, h;
  String name;
  String description = "";
  boolean isDragged;
  boolean showLabel = true;
  boolean show = true;
  UpdateOperation updateOperation;
  LabelOperation labelOperation;

  UIElement(String name, float x, float y, float w, float h) {
    this.name = name;
    this.x = x;
    this.y = y;
    this.w = w;
    this.h = h;
  }

  boolean isInside(float mouseX, float mouseY) {
    return (mouseX >= x && mouseX <= x + w && mouseY >= y && mouseY <= y + h);
  }

  abstract void draw();
  abstract void mousePressed(float x, float y);
  abstract void mouseDragged(float x, float y);
  abstract void mouseReleased(float x, float y);
  void setTooltip(Tooltip tooltip, String description) {
    tooltip.tippedElements.add(this);
    this.description = description;
  }
  void setUpdateOperation(UpdateOperation updateOperation) {
    this.updateOperation = updateOperation;
  }
  void setLabelOperation(LabelOperation labelOperation) {
    this.labelOperation = labelOperation;
  }
}

class RadioButtons extends UIElement {
  int value;
  Toggle[] toggles;
  RadioButtons(String name, float x, float y, float w, float h, int defaultValue, int numberOfButtons) {
    super(name, x, y, w, h);
    RadioButtons thisRadio = this;
    toggles = new Toggle[numberOfButtons];
    for (int i=0; i<numberOfButtons; i++) {
      Toggle thisToggle = new Toggle(name, x+i*w/numberOfButtons, y, w/numberOfButtons, h);
      toggles[i] = thisToggle;
      toggles[i].value = i;
      toggles[i].updateOperation = new UpdateOperation() {
        @Override
          public void execute() {
          thisRadio.value = thisToggle.value;
        }
      };
    }
    this.value = defaultValue;
    for (Toggle t : toggles) t.pressed = (t.value==value);
  }
  void draw() {
    if (show) {
      for (Toggle t : toggles) t.draw();
      fill(UIColors[6]);
      if (showLabel) text(name, x+w+5, y+h-5);
    }
  }

  void mousePressed(float mX, float mY) {
    for (Toggle t : toggles) t.mousePressed(mX, mY);
  }

  void mouseDragged(float x, float y) {
  }

  void mouseReleased(float mX, float mY) {
    for (Toggle t : toggles) t.mouseReleased(mX, mY);
    for (Toggle t : toggles) if (t.value!=value) t.pressed = false;
    boolean onePressed = false;
    for (Toggle t : toggles) onePressed = onePressed||t.pressed;
    if (!onePressed && toggles.length>0) toggles[0].pressed=true;
    if (isInside(mX, mY)) {
      if (updateOperation!=null) updateOperation.execute();
    }
  }

  void setLabels(String[] labels) {
    if (toggles.length>0) for (int i=0; i<labels.length; i++) toggles[i%toggles.length].name = labels[i];
  }
}

class Toggle extends UIElement {
  int value;
  boolean pressed;

  Toggle(String name, float x, float y, float w, float h) {
    super(name, x, y, w, h);
  }

  void draw() {
    if (show) {
      UIRectangle(x, y, w, h, pressed, isInside(mouseX, mouseY));
      pushMatrix();
      translate(x, y);
      fill(UIColors[7]);
      if (showLabel) text(getLabel(), 6, h-6);
      popMatrix();
    }
  }

  void mousePressed(float mX, float mY) {
    if (isInside(mX, mY)) {
      isDragged = true;
    }
  }

  void mouseDragged(float x, float y) {
  }

  void mouseReleased(float mX, float mY) {
    if (isInside(mX, mY) && updateOperation != null) {
      pressed ^= true;
      if (updateOperation!=null) updateOperation.execute();
    }
    if (isDragged) isDragged = false;
  }
  String getLabel() {
    if (labelOperation!=null) labelOperation.getLabel();
    return name;
  }
}

class Button extends UIElement {

  Button(String name, float x, float y, float w, float h) {
    super(name, x, y, w, h);
  }

  void draw() {
    if (show) {
      UIRectangle(x, y, w, h, isDragged, isInside(mouseX, mouseY));
      pushMatrix();
      translate(x, y);
      fill(UIColors[7]);
      if (showLabel) text(getLabel(), 6, h-6);
      println(getLabel());
      popMatrix();
    }
  }

  void mousePressed(float mX, float mY) {
    if (isInside(mX, mY)) {
      isDragged = true;
    }
  }

  void mouseDragged(float x, float y) {
  }

  void mouseReleased(float mX, float mY) {
    if (isInside(mX, mY) && updateOperation != null) {
      if (updateOperation!=null) updateOperation.execute();
    }
    if (isDragged) isDragged = false;
  }

  String getLabel() {
    if (labelOperation!=null) return labelOperation.getLabel();
    return name;
  }
}

class Slider extends UIElement {
  float value;
  float scaledValue;
  boolean vertical;
  int tickMarks;

  Slider(String name, int x, int y, int w, int h, float value, boolean vertical, int tickMarks) {
    super(name, x, y, w, h);
    this.value = value;
    this.vertical = vertical;
    this.tickMarks = tickMarks;
  }

  void draw() {
    if (show) {
      pushMatrix();
      translate(x, y);
      noFill();
      stroke(0);
      if (isInside(mouseX, mouseY) || isDragged) {
        for (int x=0; x<w; x+=2) {
          point(x, 0);
          point(x, h-1);
        }
        for (int y=0; y<h; y+=2) {
          point(0, y);
          point(w-1, y);
        }
      }

      noFill();
      for (int i=0; i<4; i++) {
        if (i==0) stroke(UIColors[1]);
        if (i==1) stroke(UIColors[0]);
        if (i==2) stroke(UIColors[2]);
        if (i==3) stroke(UIColors[4]);
        if (vertical) line(floor(w/2-2)+i, 0, floor(w/2-2)+i, h);
        else line(0, floor(h/2-2)+i, w, floor(h/2-2)+i);
      }

      if (vertical) UIRectangle(0, h-(value*h)-4, w, 8, false, isDragged);
      else UIRectangle(value*w-4, 0, 8, h, false, isDragged);

      String label = name+" "+round(scaledValue*100.0f)/100.0f;
      if (labelOperation!=null) label = labelOperation.getLabel();

      fill(UIColors[6]);
      if (showLabel) {
        if (vertical) text(label, 0, h+14);
        else text(label, w+5, h-5);
      }

      popMatrix();
    }
  }

  void mousePressed(float mX, float mY) {
    if (isInside(mX, mY)) {
      if (vertical) value = constrain(map(mY, y + h, y, 0, 1), 0, 1);
      else value = constrain(map(mX, x, x + w, 0, 1), 0, 1);
      if (tickMarks > 1) value = round(value * (tickMarks-1)) / (float) (tickMarks-1);
      if (updateOperation != null) updateOperation.execute();
      isDragged = true;
    }
  }

  void mouseDragged(float mX, float mY) {
    if (isDragged && updateOperation != null) {
      if (vertical) value = constrain(map(mY, y + h, y, 0, 1), 0, 1);
      else value = constrain(map(mX, x, x + w, 0, 1), 0, 1);
      if (tickMarks > 1) value = round(value * (tickMarks-1)) / (float) (tickMarks-1);
      if (updateOperation!=null) updateOperation.execute();
    }
  }

  void mouseReleased(float x, float y) {
    isDragged = false;
  }
}

// An interface that defines an operation to be executed.
public interface UpdateOperation {
  void execute();
}

// An interface that defines a labelling change.
public interface LabelOperation {
  String getLabel();
}

class Tooltip extends UIElement {

  UIElement showing;
  ArrayList<UIElement> tippedElements = new ArrayList<UIElement>();

  Tooltip(String name, float x, float y, float width, float height) {
    super(name, x, y, width, height);
  }
  void draw() {
    if (show) {
      for (UIElement e : tippedElements) {
        if (e==showing) {
          if (!e.isInside(mouseX, mouseY)&&!e.isDragged) showing=null;
        } else {
          if (e.isInside(mouseX, mouseY)) {
            if (showing==null) showing=e;
            else if (showing.isDragged) showing=e;
          }
        }
      }
      pushMatrix();
      translate(x, y);
      noStroke();
      fill(UIColors[3]);
      rect(0, 0, w, h);
      stroke(UIColors[1]);
      line(0, 0, w, 0);
      line(0, 0, 0, h);
      stroke(UIColors[4]);
      line(0, h-1, w-1, h-1);
      line(w-1, 0, w-1, h-1);
      fill(0);
      if (showing!=null) text(showing.description, 5, 5, w-25, h-10);
      popMatrix();
    }
  }

  void mousePressed(float x, float y) {
  }
  void mouseDragged(float x, float y) {
  }
  void mouseReleased(float x, float y) {
  }
}

void UIRectangle(float x, float y, float w, float h, boolean pushed, boolean highlighted) {
  strokeWeight(1);
  noStroke();
  pushMatrix();
  translate(x, y);
  fill(UIColors[5]);
  if (highlighted) fill(UIColors[3]);
  rect(0, 0, w, h);
  noFill();
  stroke(UIColors[2]);
  if (pushed) stroke(UIColors[0]);
  line(0, 0, w-1, 0);
  line(0, 0, 0, h-1);
  stroke(UIColors[0]);
  if (pushed) stroke(UIColors[2]);
  line(0, h-1, w-1, h-1);
  line(w-1, 0, w-1, h-1);
  stroke(UIColors[4]);
  if (pushed) stroke(UIColors[1]);
  line(1, 1, w-2, 1);
  line(1, 1, 1, h-2);
  stroke(UIColors[1]);
  if (pushed) stroke(UIColors[4]);
  line(1, h-2, w-2, h-2);
  line(w-2, 1, w-2, h-2);
  popMatrix();
}

UIElement getUiElementCalled(String name) {
  for (UIElement e : uiElements) {
    if (e.name.equals(name)) return e;
  }
  return null;
}

void mousePressed() {
  for (UIElement e : uiElements) e.mousePressed(mouseX, mouseY);
  for (SampleSlot s : sampleSlots) s.mousePressed(mouseX, mouseY);
}

void mouseDragged() {
  for (UIElement e : uiElements) e.mouseDragged(mouseX, mouseY);
}

void mouseReleased() {
  for (UIElement e : uiElements) e.mouseReleased(mouseX, mouseY);
  for (SampleSlot s : sampleSlots) s.mouseReleased(mouseX, mouseY);
}
