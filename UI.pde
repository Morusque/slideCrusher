
ArrayList<UIElement> uiElements = new ArrayList<UIElement>();

Tooltip tooltip;

void setBasicUIElements() {

  tooltip = new Tooltip("tooltip", 10, 600, 300, 80);
  uiElements.add(tooltip);

  // previewOffset
  Slider sliderPreviewOffset = new Slider("previewOffset", 410, 311, 380, 20, 0.5, false, 0);
  UpdateOperation sliderPreviewOffsetOperation = new UpdateOperation() {
    @Override
      public void execute() {
      sliderPreviewOffset.scaledValue = sliderPreviewOffset.value;
      previewOffset = sliderPreviewOffset.scaledValue;
      updateDisplay();
    }
  };
  sliderPreviewOffset.setUpdateOperation(sliderPreviewOffsetOperation);
  sliderPreviewOffset.setTooltip(tooltip, "preview offset");
  sliderPreviewOffset.showLabel = false;
  uiElements.add(sliderPreviewOffset);

  // previewGain
  Slider sliderPreviewGain = new Slider("previewGain", 390, 10, 20, 300, 0.03, true, 0);
  UpdateOperation sliderPreviewGainOperation = new UpdateOperation() {
    @Override
      public void execute() {
      sliderPreviewGain.scaledValue = sliderPreviewGain.value*30;
      previewGain = sliderPreviewGain.scaledValue;
      updateDisplay();
    }
  };
  sliderPreviewGain.setUpdateOperation(sliderPreviewGainOperation);
  sliderPreviewGain.setTooltip(tooltip, "preview gain");
  sliderPreviewGain.showLabel = false;
  uiElements.add(sliderPreviewGain);

  // defaultMaxSlideTimeSmp
  Slider sliderDefaultMaxSlideTimeSmp = new Slider("defaultMaxSlideTimeSmp", 410, 370, 200, 20, 0.5, false, 0);
  UpdateOperation sliderDefaultMaxSlideTimeSmpOperation = new UpdateOperation() {
    @Override
      public void execute() {
      sliderDefaultMaxSlideTimeSmp.scaledValue = sliderDefaultMaxSlideTimeSmp.value;
      previewSet.defaultMaxSlideTimeSmp = floor(map(pow(sliderDefaultMaxSlideTimeSmp.scaledValue, 5), 0, 1, 1, 5000));
      updateDisplay();
    }
  };
  sliderDefaultMaxSlideTimeSmp.setUpdateOperation(sliderDefaultMaxSlideTimeSmpOperation);
  sliderDefaultMaxSlideTimeSmp.setTooltip(tooltip, "default sampling frequency \r\nsimilar to frequancy in a classic bitcrusher");
  uiElements.add(sliderDefaultMaxSlideTimeSmp);

  // optimizationMethod method
  Slider sliderOptimizationMethod = new Slider("optimizationMethod", 410, 410, 200, 20, 0, false, 4);
  UpdateOperation sliderOptimizationMethodOperation = new UpdateOperation() {
    @Override
      public void execute() {
      sliderOptimizationMethod.scaledValue = floor(sliderOptimizationMethod.value*(sliderOptimizationMethod.tickMarks-1));
      previewSet.optimizationMethod = floor(sliderOptimizationMethod.scaledValue);
      if (previewSet.optimizationMethod == 0) sliderOptimizationMethod.description = "how to optimize the sampling time : \r\nno optimization";
      if (previewSet.optimizationMethod == 1) sliderOptimizationMethod.description = "how to optimize the sampling time : \r\nadd sampling points to make sure the blue zone doesn't exeed the threshold";
      if (previewSet.optimizationMethod == 2) sliderOptimizationMethod.description = "how to optimize the sampling time : \r\nadd sampling points to make sure the difference between consecutive points doesn't exeed the threshold";
      if (previewSet.optimizationMethod == 3) sliderOptimizationMethod.description = "how to optimize the sampling time : \r\nadd sampling points when crossing zero";
      updateDisplay();
    }
  };
  sliderOptimizationMethod.setUpdateOperation(sliderOptimizationMethodOperation);
  sliderOptimizationMethod.setTooltip(tooltip, "how to optimize the sampling time");
  uiElements.add(sliderOptimizationMethod);

  // totalDifferenceThreshold
  Slider sliderTotalDifferenceThreshold = new Slider("totalDifferenceThreshold", 410, 440, 200, 20, 0.5, false, 0);
  UpdateOperation sliderTotalDifferenceThresholdOperation = new UpdateOperation() {
    @Override
      public void execute() {
      sliderTotalDifferenceThreshold.scaledValue = sliderTotalDifferenceThreshold.value;
      previewSet.totalDifferenceThreshold = map(pow(sliderTotalDifferenceThreshold.scaledValue, 10), 0, 1, 0.00001, 50.0);
      updateDisplay();
    }
  };
  sliderTotalDifferenceThreshold.setUpdateOperation(sliderTotalDifferenceThresholdOperation);
  sliderTotalDifferenceThreshold.setTooltip(tooltip, "threshold used by the optimization process");
  uiElements.add(sliderTotalDifferenceThreshold);

  // compressionFactor
  Slider sliderCompressionFactor = new Slider("compressionFactor", 410, 470, 200, 20, 0.5, false, 0);
  UpdateOperation sliderCompressionFactorOperation = new UpdateOperation() {
    @Override
      public void execute() {
      sliderCompressionFactor.scaledValue = sliderCompressionFactor.value;
      previewSet.compressionFactor = map(pow(sliderCompressionFactor.scaledValue, 1.5), 0, 1, 0.1, 5);
      updateDisplay();
    }
  };
  sliderCompressionFactor.setUpdateOperation(sliderCompressionFactorOperation);
  sliderCompressionFactor.setTooltip(tooltip, "temporarily compress the sample during optimization \r\nlower values generate more distortion and gating \r\nhigher values keep precision on quiter parts of the audio");
  uiElements.add(sliderCompressionFactor);

  // interpolationType
  Slider sliderInterpolationType = new Slider("interpolationType", 410, 510, 200, 20, 0, false, 6);
  UpdateOperation sliderInterpolationTypeOperation = new UpdateOperation() {
    @Override
      public void execute() {
      sliderInterpolationType.scaledValue = floor(sliderInterpolationType.value*(sliderInterpolationType.tickMarks-1));
      previewSet.interpolationType = floor(sliderInterpolationType.scaledValue);
      if (previewSet.interpolationType == 0) sliderInterpolationType.description = "interpolation type : \r\nsample and hold";
      if (previewSet.interpolationType == 1) sliderInterpolationType.description = "interpolation type : \r\nlinear";
      if (previewSet.interpolationType == 2) sliderInterpolationType.description = "interpolation type : \r\ns curve";
      if (previewSet.interpolationType == 3) sliderInterpolationType.description = "interpolation type : \r\nsawtooth";
      if (previewSet.interpolationType == 4) sliderInterpolationType.description = "interpolation type : \r\nboxcar";
      if (previewSet.interpolationType == 5) sliderInterpolationType.description = "interpolation type : \r\nzero";
      updateDisplay();
    }
  };
  sliderInterpolationType.setUpdateOperation(sliderInterpolationTypeOperation);
  sliderInterpolationType.setTooltip(tooltip, "interpolation type");
  uiElements.add(sliderInterpolationType);

  // sinusAddition
  Slider sliderSinusAddition = new Slider("sinusAddition", 410, 540, 200, 20, 0.5, false, 0);
  UpdateOperation sliderSinusAdditionOperation = new UpdateOperation() {
    @Override
      public void execute() {
      sliderSinusAddition.scaledValue = map(sliderSinusAddition.value, 0, 1, -1, 1);
      if (abs(sliderSinusAddition.scaledValue)<0.1) sliderSinusAddition.scaledValue = 0;
      else sliderSinusAddition.scaledValue = abs(pow(sliderSinusAddition.scaledValue, 4))*(sliderSinusAddition.scaledValue/abs(sliderSinusAddition.scaledValue));
      previewSet.sinusAddition = sliderSinusAddition.scaledValue;
      updateDisplay();
    }
  };
  sliderSinusAddition.setUpdateOperation(sliderSinusAdditionOperation);
  sliderSinusAddition.setTooltip(tooltip, "adds one arbitrary sinewave between each sampling points, amplitude of the sines follows sound amplitude");
  uiElements.add(sliderSinusAddition);

  // IIR filter
  Slider sliderIIRFilter = new Slider("iirFilter", 410, 570, 200, 20, 0.0, false, 0);
  UpdateOperation sliderIIRFilterOperation = new UpdateOperation() {
    @Override
      public void execute() {
      sliderIIRFilter.scaledValue = sliderIIRFilter.value;
      previewSet.iirFilter = sliderIIRFilter.scaledValue;
      updateDisplay();
    }
  };
  sliderIIRFilter.setUpdateOperation(sliderIIRFilterOperation);
  sliderIIRFilter.setTooltip(tooltip, "applies an IIR filter in the process");
  uiElements.add(sliderIIRFilter);

  Button processExportRemoveButton = new Button("processExportRemove", 600, 610, 150, 20);
  processExportRemoveButton.updateOperation = new UpdateOperation() {
    @Override
      public void execute() {
      processCurrentSlot();
    }
  };
  processExportRemoveButton.setTooltip(tooltip, "process selected sample");
  uiElements.add(processExportRemoveButton);

  Button playCurrentSlot = new Button("playCurrentSlot", 410, 610, 150, 20);
  playCurrentSlot.updateOperation = new UpdateOperation() {
    @Override
      public void execute() {
      if (sample!=null) {
        sample.stop();
        sample.close();
      }
      if (selectedSlot!=null) {
        if (selectedSlot.nbChannels == 1) sample = minim.createSample(selectedSlot.getSampleForPlayback(0), selectedSlot.format);
        if (selectedSlot.nbChannels > 1) sample = minim.createSample(selectedSlot.getSampleForPlayback(0), selectedSlot.getSampleForPlayback(1), selectedSlot.format);
        sample.trigger();
      }
    }
  };
  playCurrentSlot.setTooltip(tooltip, "play selected sample (original or processed if applicable)");
  uiElements.add(playCurrentSlot);

  for (UIElement e : uiElements) if (e.updateOperation!=null) e.updateOperation.execute();
}

abstract class UIElement {
  float x, y, w, h;
  String name;
  UpdateOperation updateOperation;
  String description = "";
  boolean isDragged;
  boolean showLabel = true;

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

  void draw() {
  }
  void mousePressed(float x, float y) {
  }
  void mouseDragged(float x, float y) {
  }
  void mouseReleased() {
  }
  void setTooltip(Tooltip tooltip, String description) {
    tooltip.tippedElements.add(this);
    this.description = description;
  }
}

class Button extends UIElement {

  Button(String name, float x, float y, float w, float h) {
    super(name, x, y, w, h);
  }

  void draw() {
    pushMatrix();
    translate(x, y);
    stroke(0x80);
    fill(0xE0);
    if (isInside(mouseX, mouseY)) fill(0xFF);
    if (isInside(mouseX, mouseY) && mousePressed) fill(0xFF, 0xFF, 0);
    rect(0, 0, w, h);
    fill(0x50);
    if (showLabel) text(name, 3, h-3);
    popMatrix();
  }

  void mousePressed(float mX, float mY) {
    if (isInside(mX, mY) && updateOperation != null) {
      updateOperation.execute();
    }
  }

  void setUpdateOperation(UpdateOperation updateOperation) {
    this.updateOperation = updateOperation;
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
    pushMatrix();
    translate(x, y);
    //stroke(0x80);
    noStroke();
    fill(0xE0);
    if (isInside(mouseX, mouseY)) fill(0xFF);
    if (isDragged) fill(0xFF, 0xFF, 0);
    rect(0, 0, w, h);
    stroke(0, 0, 0xFF);
    if (vertical) line(0, h-value*h, w, h-value*h);
    else line(value*w, 0, value*w, h);
    fill(0x50);
    if (showLabel) {
      if (vertical) text(name+" "+round(scaledValue*100.0f)/100.0f, 0, h+14);
      else text(name+" "+round(scaledValue*100.0f)/100.0f, 3, h-3);
    }
    popMatrix();
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
      updateOperation.execute();
    }
  }

  void setUpdateOperation(UpdateOperation updateOperation) {
    this.updateOperation = updateOperation;
  }

  void mouseReleased() {
    isDragged = false;
  }
}

public interface UpdateOperation {
  void execute();
}

class Tooltip extends UIElement {

  UIElement showing;
  ArrayList<UIElement> tippedElements = new ArrayList<UIElement>();

  Tooltip(String name, float x, float y, float width, float height) {
    super(name, x, y, width, height);
  }
  void draw() {
    for (UIElement e : tippedElements) {
      if (e==showing) {
        if (!e.isInside(mouseX, mouseY)&&!e.isDragged) showing=null;
      } else {
        if (e.isInside(mouseX, mouseY)) showing=e;
      }
    }
    if (showing!=null) {
      stroke(0);
      fill(0xFF);
      rect(x, y, w, h);
      fill(0);
      text(showing.description, x+3, y+3, w-20, h-3);
    }
  }
}

class Container extends UIElement {
  ArrayList<UIElement> elements;

  Container(String name, float x, float y, float width, float height) {
    super(name, x, y, width, height);
    elements = new ArrayList<UIElement>();
  }

  void draw() {
    for (UIElement e : elements) e.draw();
  }
}
