function renderLink(link, animated) {
    var source = $('#link-template').html();
    var template = Handlebars.compile(source);
    link.created_at = moment.unix(link.created_at).format('MMMM D, YYYY');
    var html = template({link: link});
    if (animated) {
        $(html).addClass('new-item').prependTo('#link-container');
    } else {
        $(html).prependTo('#link-container');
    }
}

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
     }).done(function(link) {
         renderLink(link, true);
         $("#short-link-" + link.code).focus().select();
     }).fail(function(error) {
         var reason = extractReason(error);
         console.log(reason);
         $('#message').html(reason);
     });
}

function deleteLink(code) {
    $.ajax({
        url: '/' + code,
        type: 'DELETE'
    }).done(function(data) {
        $('#link-entry-' + code).addClass('removed');
        setTimeout(function() {
            $('#link-entry-' + code).remove();
        }, 400);
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
