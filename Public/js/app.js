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
         var link = "https://csh.link/" + data.code;
         var input = $("<input />").attr({
                        type: "textarea",
                        class: "form-control",
                        value: link
                     });
         var message = $('#message');
         message.html("Success! Your url is\n");
         message.append(input);
         input.focus();
         input.select();
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
