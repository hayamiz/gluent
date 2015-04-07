
function dragenter_handler(e) {
  $("#edit-content").addClass("dragover");
}
function dragleave_handler(e) {
  $("#edit-content").removeClass("dragover");
}
function dragover_handler(e) {
  $("#edit-content").addClass("dragover");
}
function drop_handler(e) {
  var files = e.originalEvent.dataTransfer.files;
  upload_files(files);
  $("#edit-content").removeClass("dragover");
}

function upload_files(files) {
  var fd = new FormData();

  for (var i = 0; i < files.length; i++) {
    fd.append("files_" + i, files[i]);
  }

  $.ajax({
    url: "/upload",
    type: "POST",
    data: fd,
    processData: false,
    contentType: false,
    complete: function(e) {
    },
    error: function(e) {
    },
    success: function(data) {
      for (var i = 0; i < data.length; i++) {
        filedata = data[i];
        if (filedata["type"].match(/^image/)) {
          ma.insert("<a href=\"" + filedata["path"] + "\" target=\"_blank\">" + "![" + filedata["filename"] + "](" + filedata["path"] + ")</a>");
        } else {
          ma.insert("<a href=\"" + filedata["path"] + "\" target=\"_blank\">" + filedata["filename"] + "</a>");
        }
      }
    }
  });
}

$(document).ready(function() {
  var textarea = $("#edit-content");

  textarea.on("dragenter", function(e) {
    dragenter_handler(e);
  });
  textarea.on("dragleave", function(e) {
    dragleave_handler(e);
  });
  textarea.on("dragover", function(e) {
    dragover_handler(e);
    return false;
  });
  textarea.on("drop", function(e) {
    drop_handler(e);
    return false;
  });
});
