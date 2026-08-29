# =========================================================================
# FIFO Functional-Level Model
# =========================================================================

class Logic:
  def __init__(self, value=None):
    self.value = value


class FL_sync_fifo:
  def __init__(self):
    # FIFO input signals
    self.rst = Logic()
    self.in_val = Logic()
    self.in_data = Logic()
    self.out_rdy = Logic()

    # FIFO output signals
    self.in_rdy = Logic(1)
    self.out_val = Logic(0)
    self.out_data = Logic()

    # Internal FIFO data
    self._data = []
  

  def advance_clk(self):
    assert len(self._data) <= 8, \
      f"FL: Internal data has length {len(self._data)}, but the FIFO has size {8}."
    assert self.in_data.value < (1 << 8), \
      f"FL: in_data is {self.in_data.value}, which is larger than max value {1 << 8 - 1}."
    assert self.in_rdy.value if (len(self._data) < 8) else not self.in_rdy.value, \
      f"FL: in_rdy={self.in_rdy.value} does not match FIFO of length {len(self._data)}."
    assert self.out_val.value if (len(self._data) > 0) else not self.out_val.value, \
      f"FL: out_val={self.out_val.value} does not match FIFO of length {len(self._data)}."
    
    # Update internal data
    if self.rst.value:
      self._data = []
    else:
      if self.in_val.value and self.in_rdy.value:
        self._data.append(self.in_data.value)
      if self.out_val.value and self.out_rdy.value:
        self._data = self._data[1:]
    
    # Update output signals
    if len(self._data) < 8:
      self.in_rdy.value = 1
    else:
      self.in_rdy.value = 0
    
    if len(self._data) > 0:
      self.out_val.value = 1
    else:
      self.out_val.value = 0
    
    if len(self._data) > 0:
      self.out_data.value = self._data[0]
    else:
      self.out_data.value = None
