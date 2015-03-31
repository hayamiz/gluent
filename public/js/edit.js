function submit_form() {
  last_saved_content = cur_content;
  $("#edit-form").submit();
}

function convert_puct() {
  var content = $("#edit-content").val();

  content = content.replace(/、/g, "，");
  content = content.replace(/。/g, "．");

  $("#edit-content").val(content);

  edit_form_keyup_handler();
}

var cur_content = $("#edit-content").val();
var last_saved_content = cur_content;
var last_save_timestamp = null;
var status_bar = null;

function edit_form_keyup_handler(){
  var content = $("#edit-content").val();
  var do_update = false;

  update_selection_info();
  set_preview_scroll();

  if (content != cur_content) {
    cur_content = content;
    do_update = true;
    run_delayed_content_saver();
  }

  if ($("#js-preview-div").children().length == 0) {
    do_update = true;
  }

  if (!do_update) {
    return;
  }

  update_status();

  $.post("/preview", { content: cur_content},
    function(data){
      var p = $("#js-preview-div");
      p.empty();
      p.append(data);
    });
}

function update_selection_info(){
  var content = $("#edit-content");

  status_bar.set_selection_start(content[0].selectionStart);
  status_bar.set_selection_end(content[0].selectionEnd);
  status_bar.set_text_length(content.val().length);

  status_bar.update();
}

function edit_form_keydown_handler(){
  return;
}

function edit_form_mouseup_handler(){
  update_selection_info();
}

function update_status() {
  if (status_bar == null) {
    return;
  }

  if (cur_content == last_saved_content) {
    if (last_save_timestamp == null) {
      status_bar.set_mode("saved");
      status_bar.set_saved_status("Opened");
    } else {
      status_bar.set_mode("saved");
      status_bar.set_saved_status("Saved (" + readable_time_diff(last_save_timestamp, new Date()) + ")");
    }
  } else {
    status_bar.set_mode("not-saved");
    status_bar.set_saved_status("Modified")
  }

  status_bar.update();
}
var status_updator = setInterval(update_status, 10 * 1000);

function readable_time_diff(a, b) {
  var ms_diff = a - b;
  if (ms_diff < 0) {
    ms_diff *= -1;
  }

  if (ms_diff < 60 * 60 * 1000) {
    return Math.floor(ms_diff / (60 * 1000)) + " minutes ago"
  } else {
    return Math.floor(ms_diff / (60 * 60 * 1000)) + " hours ago"
  }
}

function StatusBar() {
  var bar = this;

  this.saved_status = "Opened";
  this.selection_start = 0;
  this.selection_end = 0;
  this.text_length = 0;

  this.right_msg = "";
  this.left_msg = "";

  this.rendered = false;
}

StatusBar.prototype = {
  // render status texts
  update: function() {
    var right_div = $("#js-edit-status-right-div");
    var left_div = $("#js-edit-status-left-div");

    if (this.rendered == true) {
      return;
    }

    this.right_msg = this.saved_status;

    this.left_msg = "";
    this.left_msg = "[" + this.selection_start;
    if (this.selection_end > this.selection_start) {
      this.left_msg += "-" + this.selection_end + "(" + (this.selection_end - this.selection_start) + ")";
    }
    this.left_msg += "/" + this.text_length + "]";

    right_div.empty();
    left_div.empty();
    right_div.append(this.right_msg);
    left_div.append(this.left_msg);

    this.rendered = true;
  },

  set_selection_start: function(val) {
    this.set_val("selection_start", val);
  },
  set_selection_end: function(val) {
    this.set_val("selection_end", val);
  },
  set_text_length: function(val) {
    this.set_val("text_length", val);
  },
  set_saved_status: function(val) {
    this.set_val("saved_status", val);
  },

  set_val: function(param_name, new_val) {
    var old_val = this[param_name];

    if (old_val != new_val) {
      this.rendered = false;
      this[param_name] = new_val;
    }
  },

  set_mode: function(mode_cssclass) {
    var status_div = $("#js-edit-status-div");

    status_div.removeClass();
    status_div.addClass(mode_cssclass);
  }
};

function set_status(cssclass, msg) {
  var status_div = $("#js-edit-status-div");

  status_div.empty();
  status_div.append($("<div/>", {class: cssclass, text: msg}));
}

function save_content() {
  var saving_content = cur_content;
  console.debug("[" + (new Date()) + "] save_content");
  $.post("/edit/" + entry_filepath, { content: saving_content },
    function(){
      // success
      last_saved_content = saving_content;
      last_save_timestamp = new Date();
      update_status();
    }).fail(function(){
      status_bar.set_mode("error");
      status_bar.set_saved_status("Failed saving");
    });
}

var saver_handler = null;
function run_delayed_content_saver() {
  if (saver_handler != null) {
    clearTimeout(saver_handler);
  }
  saver_handler = setTimeout(save_content, 30 * 1000);
}

$("#edit-content").on("keyup", function(e){
  edit_form_keyup_handler();
});
$("#edit-content").on("keydown", function(e){
  edit_form_keydown_handler();
});
$("#edit-content").on("mouseup", function(e){
  edit_form_mouseup_handler();
});

function set_preview_scroll() {
  var textarea = $("#edit-content");
  var preview_div = $("#js-preview-div");

  var scroll_frac = textarea.scrollTop() / (textarea[0].scrollHeight - textarea.height());
  preview_div.scrollTop((preview_div[0].scrollHeight - preview_div.height()) * scroll_frac);
}

$("#edit-content").on("scroll", function(){
  set_preview_scroll();
});

function layout_status() {
  var status_div = $("#js-edit-status-div");
  win_height = $(window).height();
  win_width = $(window).width();

  status_div.outerWidth(win_width);
  status_div.css({top: win_height - status_div.outerHeight(), left: 0, display: "block"});
}

function layout_form() {
  var textarea = $("#edit-content");
  var preview_div = $("#js-preview-div");

  // calculate optimal height
  win_height = $(window).height();
  var elems = [textarea, preview_div];
  for (var i = 0; i < elems.length; i++) {
    var elem = elems[i];
    var pos = elem.position();
    var h = win_height - pos.top - 10 - 20;

    elem.outerHeight(h);
  }
}

function do_layout_elems() {
  layout_form();
  layout_status();
}

var ma;
$(document).ready(function() {
  var textarea = $("#edit-content");
  status_bar = new StatusBar();
  update_status();
  do_layout_elems();
  ma = new MarkdownAssistant(textarea);
  textarea.focus();
  edit_form_keyup_handler();
  edit_form_keydown_handler();
});
$(window).resize(do_layout_elems);

$(window).on('beforeunload', function() {
  if (last_saved_content == cur_content) {
    return;
  } else {
    return "Content is not saved yet.";
  }
});
