
ArrayList<UIElement> uiElements = new ArrayList<UIElement>();

void setBasicUIElements() {
  // previewOffset
  Slider sliderPreviewOffset = new Slider("previewOffset", 410, 330, 300, 20, 0.5, false, 0);
  UpdateOperation sliderPreviewOffsetOperation = new UpdateOperation() {
    @Override
      public void execute() {
      sliderPreviewOffset.scaledValue = sliderPreviewOffset.value;
      previewOffset = sliderPreviewOffset.scaledValue;
      updateDisplay();
    }
  };
  sliderPreviewOffset.setUpdateOperation(sliderPreviewOffsetOperation);
  uiElements.add(sliderPreviewOffset);

  // previewGain
  Slider sliderPreviewGain = new Slider("previewGain", 360, 10, 20, 300, 0.03, true, 0);
  UpdateOperation sliderPreviewGainOperation = new UpdateOperation() {
    @Override
      public void execute() {
      sliderPreviewGain.scaledValue = sliderPreviewGain.value*30;
      previewGain = sliderPreviewGain.scaledValue;
      updateDisplay();
    }
  };
  sliderPreviewGain.setUpdateOperation(sliderPreviewGainOperation);
  uiElements.add(sliderPreviewGain);

  // compressionFactor
  Slider sliderCompressionFactor = new Slider("compressionFactor", 450, 370, 200, 20, 0.5, false, 0);
  UpdateOperation sliderCompressionFactorOperation = new UpdateOperation() {
    @Override
      public void execute() {
      sliderCompressionFactor.scaledValue = sliderCompressionFactor.value;
      previewSet.compressionFactor = map(pow(sliderCompressionFactor.scaledValue, 1.5), 0, 1, 0.1, 5);
      updateDisplay();
    }
  };
  sliderCompressionFactor.setUpdateOperation(sliderCompressionFactorOperation);
  uiElements.add(sliderCompressionFactor);

  // defaultMaxSlideTimeSmp
  Slider sliderDefaultMaxSlideTimeSmp = new Slider("defaultMaxSlideTimeSmp", 450, 400, 200, 20, 0.5, false, 0);
  UpdateOperation sliderDefaultMaxSlideTimeSmpOperation = new UpdateOperation() {
    @Override
      public void execute() {
      sliderDefaultMaxSlideTimeSmp.scaledValue = sliderDefaultMaxSlideTimeSmp.value;
      previewSet.defaultMaxSlideTimeSmp = floor(map(pow(sliderDefaultMaxSlideTimeSmp.scaledValue, 5), 0, 1, 1, 5000));
      updateDisplay();
    }
  };
  sliderDefaultMaxSlideTimeSmp.setUpdateOperation(sliderDefaultMaxSlideTimeSmpOperation);
  uiElements.add(sliderDefaultMaxSlideTimeSmp);

  // totalDifferenceThreshold
  Slider sliderTotalDifferenceThreshold = new Slider("totalDifferenceThreshold", 450, 430, 200, 20, 0.5, false, 0);
  UpdateOperation sliderTotalDifferenceThresholdOperation = new UpdateOperation() {
    @Override
      public void execute() {
      sliderTotalDifferenceThreshold.scaledValue = sliderTotalDifferenceThreshold.value;
      previewSet.totalDifferenceThreshold = map(pow(sliderTotalDifferenceThreshold.scaledValue, 10), 0, 1, 0.00001, 50.0);
      updateDisplay();
    }
  };
  sliderTotalDifferenceThreshold.setUpdateOperation(sliderTotalDifferenceThresholdOperation);
  uiElements.add(sliderTotalDifferenceThreshold);

  // interpolationType
  Slider sliderInterpolationType = new Slider("interpolationType", 450, 460, 200, 20, 0, false, 5);
  UpdateOperation sliderInterpolationTypeOperation = new UpdateOperation() {
    @Override
      public void execute() {
      sliderInterpolationType.scaledValue = floor(sliderInterpolationType.value*(sliderInterpolationType.tickMarks-1));
      previewSet.interpolationType = floor(sliderInterpolationType.scaledValue);
      updateDisplay();
    }
  };
  sliderInterpolationType.setUpdateOperation(sliderInterpolationTypeOperation);
  uiElements.add(sliderInterpolationType);

  // sinusAddition
  Slider sliderSinusAddition = new Slider("sinusAddition", 450, 490, 200, 20, 0.5, false, 0);
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
  uiElements.add(sliderSinusAddition);

  Button processExportRemoveButton = new Button("processExportRemove", 600, 520, 100, 30);
  processExportRemoveButton.updateOperation = new UpdateOperation() {
    @Override
      public void execute() {
      processCurrentSlot();
    }
  };
  uiElements.add(processExportRemoveButton);

  Button playCurrentSlot = new Button("playCurrentSlot", 450, 520, 100, 30);
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
  uiElements.add(playCurrentSlot);

  for (UIElement e : uiElements) if (e.updateOperation!=null) e.updateOperation.execute();
}

abstract class UIElement {
  float x, y, w, h;
  String name;
  UpdateOperation updateOperation;

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
    text(name, 3, h-3);
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
  boolean isDragged;

  Slider(String name, int x, int y, int w, int h, float value, boolean vertical, int tickMarks) {
    super(name, x, y, w, h);
    this.value = value;
    this.vertical = vertical;
    this.tickMarks = tickMarks;
  }

  void draw() {
    pushMatrix();
    translate(x, y);
    stroke(0x80);
    fill(0xE0);
    if (isInside(mouseX, mouseY) || isDragged) fill(0xFF);
    rect(0, 0, w, h);
    stroke(0, 0, 0xFF);
    if (vertical) line(0, h-value*h, w, h-value*h);
    else line(value*w, 0, value*w, h);
    fill(0x50);
    text(name+" "+round(scaledValue*100.0f)/100.0f, 3, h-3);
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
