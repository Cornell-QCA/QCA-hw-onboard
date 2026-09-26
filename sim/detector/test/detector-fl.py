# =========================================================================
# Detector Functional-Level Model
# =========================================================================

class Logic:
  def __init__(self, value=None):
    self.value = value


class FL_detector:
  def __init__(self):
    # Detector input signals
    self.rst = Logic()
    self.din = Logic()

    # Detector output signal
    self.dout = Logic(0)

    # Internal detector data
    self._data = [0, 0, 0, 0]
  

  def advance_clk(self):
    # Update internal data
    if self.rst.value:
      self._data = [0, 0, 0, 0]
    else:
      self._data.append(self.din.value)
      self._data = self._data[1:]
    
    # Check if pattern matches
    pattern = "1010"

    out = ""
    for i in self._data:
      out += str(i)
    
    # Update output signal
    if pattern == out:
      self.dout.value = 1
    else:
      self.dout.value = 0
