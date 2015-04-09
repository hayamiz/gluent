
// 'textarea' must be a jquery object.
function MarkdownAssistant(textarea) {
  var ma = this;
  this.textarea = textarea;
  this.text_length = this.textarea[0].value.length;

  this.in_save_excursion = false;

  // bind event handlers
  this.textarea.on("keydown", function(e){
    return ma.keydown_handler(e);
  });
  this.textarea.on("keypress", function(e){
    return ma.keypress_handler(e);
  });
}

MarkdownAssistant.prototype.keydown_handler = function(e) {
  this.text_length = this.textarea[0].value.length;

  if (e.keyCode == 13) {        // Enter
    return this.action_EnterKey();
  } else if (e.keyCode == 9) {  // <TAB>
    return this.action_TabKey(e.shiftKey);
  }
};

MarkdownAssistant.prototype.keypress_handler = function(e) {
  var elem = this.textarea[0];
  var prev_char = elem.value.substring(elem.selectionStart - 1, elem.selectionStart);
  var next_char = elem.value.substring(elem.selectionStart, elem.selectionStart + 1);
  var insert_char = String.fromCharCode(e.charCode);

  var pair_maps = {
    "(": ")",
    "[": "]",
    "{": "}",
    "\"": "\"",
    "'": "'"
  };
  var closers = []
  for (key in pair_maps) {
    closers.push(pair_maps[key]);
  }

  if (closers.indexOf(insert_char) >= 0 && next_char == insert_char) {
    this.goto_char(elem.selectionStart + 1);
    return false;
  }

  var corr_char = pair_maps[insert_char];

  // do nothing when non-special chars inserted
  if (corr_char == undefined) {
    return true;
  }

  switch(next_char) {
  case " ":
  case "\n":
  case "\r":
  case "\t":
  case "":
    break;
  default:
    return true;
  }

  var ma = this;
  var final_pos = elem.selectionStart;
  this.save_excursion(function(){
    ma.insert(insert_char + corr_char);
    final_pos++;
  });
  this.goto_char(final_pos);

  return false;
};



MarkdownAssistant.prototype.action_EnterKey = function() {
  var context = this.getContext();
  var ma = this;

  if (context.type == "normal") {
    return true;
  }

  if (context.type == "ulist") {
    this.insert("\n");
    this.insert(context.leading_spaces + context.symbol + context.following_spaces);
    return false;
  }

  if (context.type == "olist") {
    this.insert("\n");
    this.insert(context.leading_spaces + (context.number + 1).toString() + "." + context.following_spaces);
    return false;
  }

  return true;
};

MarkdownAssistant.prototype.action_TabKey = function(shiftKey) {
  var context = this.getContext();
  var ma = this;

  if (shiftKey == true && (context.type == "ulist" || context.type == "olist")) {
    this.save_excursion(function(){
      ma.backward_char(context.end - context.start);
      if (context.leading_spaces.length > 2) {
        ma.delete_chars(2);
      } else {
        ma.delete_chars(context.leading_spaces.length);
      }
    });
    return false;
  }

  if (context.type == "ulist" || context.type == "olist") {
    this.save_excursion(function(){
      ma.backward_char(context.end - context.start);
      ma.insert("  ");
    });

    return false;
  }

  this.insert("  ")

  return false;
};

MarkdownAssistant.prototype.save_excursion = function(op) {
  var elem = this.textarea[0];
  var old_in_save_state = this.in_save_excursion;

  this.in_save_excursion = true;
  // save selection if this is outermost save_excursion
  if (old_in_save_state == false) {
    this.saved_selectionStart = elem.selectionStart;
    this.saved_selectionEnd = elem.selectionEnd;
  }

  op();

  this.in_save_excursion = old_in_save_state;
  // restore selection if this is outermost save_excursion
  if (old_in_save_state == false) {
    elem.selectionStart = this.saved_selectionStart;
    elem.selectionEnd = this.saved_selectionEnd;
  }
}
MarkdownAssistant.prototype.goto_char = function(pos) {
  var elem = this.textarea[0];
  elem.selectionStart = elem.selectionEnd = pos;
}
MarkdownAssistant.prototype.forward_char = function(n) {
  var elem = this.textarea[0];
  if (n == undefined) n = 1;
  elem.selectionStart += n;
  elem.selectionEnd = elem.selectionStart;
}
MarkdownAssistant.prototype.backward_char = function(n) {
  var elem = this.textarea[0];
  if (n == undefined) n = 1;
  elem.selectionStart -= n;
  elem.selectionEnd = elem.selectionStart;
}
MarkdownAssistant.prototype.insert = function(text) {
  var elem = this.textarea[0];
  var start, end;
  var value;

  start = elem.selectionStart;
  end = elem.selectionEnd;
  value = elem.value;

  if (this.in_save_excursion) {
    if (start < this.saved_selectionStart) {
      this.saved_selectionStart += text.length;
      this.saved_selectionEnd += text.length;
    } else if (start < this.saved_selectionEnd) {
      this.saved_selectionEnd += text.length;
    }
  }

  elem.value = "" + (value.substring(0, start)) + text + (value.substring(end));
  elem.selectionStart = elem.selectionEnd = start + text.length;
};
MarkdownAssistant.prototype.delete_char = function() {
  var elem = this.textarea[0];
  var start, end, value;

  start = elem.selectionStart;
  end = elem.selectionEnd;
  value = elem.value;

  if (this.in_save_excursion) {
    if (start < this.saved_selectionStart) {
      this.saved_selectionStart --;
      this.saved_selectionEnd --;
    } else if (start < this.saved_selectionEnd) {
      this.saved_selectionEnd --;
    }
  }

  elem.value = value.substring(0, start) + value.substring(start + 1);
  elem.selectionStart = elem.selectionEnd = start;
}
MarkdownAssistant.prototype.delete_chars = function(n) {
  for (var i = 0; i < n; i++) {
    this.delete_char();
  }
}

MarkdownAssistant.prototype.getContext = function(text) {
  var elem = this.textarea[0];
  var start, end, value;

  var normal_context = {type: "normal"};

  start = elem.selectionStart;
  end = elem.selectionEnd;
  value = elem.value;

  // find the beginning of line and the end of line
  var bol, eol;
  for (bol = start; bol > 0; bol--) {
    if (value[bol - 1] == "\r" || value[bol - 1] == "\n") {
      break;
    }
  }
  for (eol = start; eol < value.length; eol++) {
    if (value[eol] == "\r" || value[eol] == "\n") {
      break;
    }
  }

  var line = value.substring(bol, eol);
  var bol_to_cur = value.substring(bol, start);
  var m;
  if (m = line.match(/^( *)([\*-])( *)(.*)$/)) {
    if (! bol_to_cur.match(/^( *)([\*-])/)) {
      return normal_context;
    }

    return {type: "ulist", start: bol, end: start,
            symbol: m[2], leading_spaces: m[1], following_spaces: m[3], content: m[4]};
  }

  if (m = line.match(/^( *)([0-9]+)\.( *)(.*)$/)) {
    if (! bol_to_cur.match(/^( *)([0-9]+)\./)) {
      return normal_context;
    }

    return {type: "olist", start: bol, end: start,
            number: parseInt(m[2]), leading_spaces: m[1], following_spaces: m[3], content: m[4]};
  }

  return normal_context;
}
