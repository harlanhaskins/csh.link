function createURL() {
    var url = $('input[name=url]').val();
    var code = $('input[name=custom-code]').val();

    var data = {url: url};
    if (code) {
        data.code = code;
    }
    $.post({
        url: '/',
        data: JSON.stringify(data),
        contentType: 'application/json',
     }).done(function(data) {
         $('#message').html("Success! Your url is\nhttps://csh.link/" + data.code);
         console.log(data);
     }).fail(function(error) {
         var reason = extractReason(error);
         $('#message').html("Error: " + reason);
         console.log(reason);
     });
}

function deleteLink(code) {
    $.ajax({
        url: '/' + code,
        type: 'DELETE'
    }).done(function(data) {
        $('#link-entry-' + code).remove();
    }).fail(function(error) {
        console.log(extractReason(error));
    })
}

function updateLink(code) {
    var url = $('#url-input-' + code).val();
    $.post({
        url: '/' + code,
        data: JSON.stringify({url: url}),
        contentType: 'application/json'
    }).done(function(data) {
        console.log(data);
    }).fail(function(error) {
        console.log(extractReason(error));
    });
}

function extractReason(error) {
    var json = error.responseJSON;
    if (json && json.reason) {
        return json.reason;
    }
    return error.responseText;
}
