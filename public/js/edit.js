function submit_form() {
  last_saved_content = cur_content;
  $("#edit-form").submit();
}

var cur_content = $("#edit-content").val();
var last_saved_content = cur_content;
var last_save_timestamp = null;

function edit_form_keyup_handler(){
  var content = $("#edit-content").val();
  var do_update = false;

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

function set_preview_scroll() {
  var textarea = $("#edit-content");
  var preview_div = $("#js-preview-div");

  var scroll_frac = textarea.scrollTop() / (textarea[0].scrollHeight - textarea.height());
  preview_div.scrollTop((preview_div[0].scrollHeight - preview_div.height()) * scroll_frac);
}

function update_status() {
  if (cur_content == last_saved_content) {
    if (last_save_timestamp == null) {
      set_status("saved", "Opened");
    } else {
      set_status("saved", "Saved (" + readable_time_diff(last_save_timestamp, new Date()) + ")");
    }
  } else {
    set_status("not-saved", "Modified");
  }
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
      set_status("error", "Failed saving");
    });
}

var saver_handler = null;
function run_delayed_content_saver() {
  if (saver_handler != null) {
    clearTimeout(saver_handler);
  }
  saver_handler = setTimeout(save_content, 30 * 1000);
}

$("#edit-content").on("keyup", function(){
  edit_form_keyup_handler();
});

$("#edit-content").on("scroll", function(){
  set_preview_scroll();
});

edit_form_keyup_handler();

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
  do_layout_elems();
	ma = new MarkdownAssistant(textarea);
  textarea.focus();
});
$(window).resize(do_layout_elems);

$(window).on('beforeunload', function() {
  if (last_saved_content == cur_content) {
    return;
  } else {
    return "Content is not saved yet.";
  }
});
