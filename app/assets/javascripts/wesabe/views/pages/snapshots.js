var snapshot_url = '/snapshot';

function errorCallback() {
  alert('There was a problem building the snapshot. Try again or post in the Wesabe Accounts Shutdown group.');
}

function buildSnapshot() {
  $.ajax({
    type: 'POST',
    url: snapshot_url,
    success: updateSnapshotDisplay,
    error: errorCallback
  });
}

function updateSnapshotDisplay() {
  $.ajax({
    type: 'GET',
    url: snapshot_url,
    dataType: 'html',
    success: function(html) {
      $('.snapshot').replaceWith(html);
    },
    error: errorCallback
  });
}