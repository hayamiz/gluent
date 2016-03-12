// emacs like keybindings

var ev;

function EmacsBind(textarea) {
  var self = this;
  var keys = {};
  for (var i = 0; i < "Z".charCodeAt(0) - "A".charCodeAt(0) + 1; i++) {
    var key = "KEY_" + String.fromCharCode("A".charCodeAt(0) + i);
    var code = 0x41 + i;
    keys[key] = code;
  }
  console.log(keys);

  this.textarea = textarea;
  this.capturing_keys = [];
  this.capture_actions = {};

  this.kill_ring = [];

  this.textarea.on("keydown keyup").bind("keydown keyup", function(e) {
    if (e.ctrlKey && self.capturing_keys.indexOf(e.keyCode) != -1) {
      if(e.ctrlKey && e.type == "keydown"){
        ev = e;
        self.capture_actions[e.keyCode](e);
      }
      return false;
    }
  });

  this.add_key(keys.KEY_A, function(e) {
    self.goto_char(self.find_bol());
  });

  this.add_key(keys.KEY_B, function(e) {
    self.goto_char(self.pos() - 1);
  });

  this.add_key(keys.KEY_D, function(e) {
    self.del_char();
  });

  this.add_key(keys.KEY_E, function(e) {
    self.goto_char(self.find_eol());
  });

  this.add_key(keys.KEY_F, function(e) {
    self.goto_char(self.pos() + 1);
  });

  this.add_key(keys.KEY_K, function(e) {
    self.kill_line();
  });

  this.add_key(keys.KEY_H, function(e) {
    self.del_backward_char();
  });

  this.add_key(keys.KEY_N, function(e) {
    console.debug("Ctrl-N");
    self.next_line();
  });

  this.add_key(keys.KEY_P, function(e) {
    console.debug("Ctrl-P");
    self.prev_line();
  });

  this.add_key(keys.KEY_Y, function(e) {
    self.yank();
  });

  // http://stackoverflow.com/questions/7464282/javascript-scroll-to-selection-after-using-textarea-setselectionrange-in-chrome
}

EmacsBind.prototype.add_key = function(keycode, action) {
  this.capturing_keys.push(keycode);
  this.capture_actions[keycode] = action;
}

EmacsBind.prototype.pos = function() {
  return this.textarea[0].selectionStart;
}
EmacsBind.prototype.find_bol = function() {
  var elem = this.textarea[0];
  var value;

  value = elem.value;

  // find the beginning of line
  var bol;
  for (bol = this.pos(); bol > 0; bol--) {
    if (value[bol - 1] == "\r" || value[bol - 1] == "\n") {
      break;
    }
  }

  return bol;
}

EmacsBind.prototype.find_eol = function() {
  var elem = this.textarea[0];
  var start;

  value = elem.value;

  // find the end of line
  var eol;
  for (eol = this.pos(); eol < value.length; eol++) {
    if (value[eol] == "\r" || value[eol] == "\n") {
      break;
    }
  }

  return eol;
};

function min(x, y) {
  if (x < y) {
    return x;
  } else {
    return y;
  }
}

EmacsBind.prototype.next_line = function(){
  var elem = this.textarea[0];
  var value = elem.value;

  var bol = this.find_bol();
  var eol = this.find_eol();
  var ofst = this.pos() - bol;

  if (value.length - 1 == eol) {
    console.debug("the last line.");

    this.goto_char(eol);
    return;
  }

  this.goto_char(eol + 1);
  var next_eol = this.find_eol();
  this.goto_char(min(next_eol, eol + 1 + ofst));
};

EmacsBind.prototype.prev_line = function(){
  var elem = this.textarea[0];
  var value = elem.value;

  var bol = this.find_bol();
  var eol = this.find_eol();
  var ofst = this.pos() - bol;

  if (bol == 0) {
    console.debug("the first line.");
    this.goto_char(bol);
    return;
  }

  this.goto_char(bol - 1);
  var next_bol = this.find_bol();
  this.goto_char(min(bol - 1, next_bol + ofst));
};

EmacsBind.prototype.del_char = function() {
  var elem = this.textarea[0];
  var value = elem.value;

  if (this.pos() == value.length) {
    return;
  }

  var pos = this.pos();
  value = value.substring(0, this.pos()) + value.substring(this.pos() + 1, value.length);
  elem.value = value;
  this.goto_char(pos);
};

EmacsBind.prototype.del_backward_char = function() {
  if (this.pos() == 0) {
    return;
  }
  this.goto_char(this.pos() - 1);
  this.del_char();
};

EmacsBind.prototype.kill_line = function() {
  var bol, eol;
  bol = this.find_bol();
  eol = this.find_eol();

  if (bol == eol) {
    this.del_char();
    return;
  }

  var elem = this.textarea[0];
  var value = elem.value;
  var killed;
  var pos = this.pos();

  killed = value.substring(pos, eol);
  value = value.substring(0, pos) + value.substring(eol, value.length);

  this.kill_ring.unshift(killed);

  elem.value = value;
  this.goto_char(pos);
}

EmacsBind.prototype.yank = function() {
  if (this.kill_ring.length == 0) {
    return;
  }

  var elem = this.textarea[0];
  var value = elem.value;
  var pos = this.pos();

  value = value.substring(0, pos) + this.kill_ring[0] + value.substring(pos, value.length);
  elem.value = value;
  this.goto_char(pos + this.kill_ring[0].length);
}

EmacsBind.prototype.goto_char = function(pos) {
  var elem = this.textarea[0];
  elem.selectionStart = elem.selectionEnd = pos;
}
