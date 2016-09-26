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
     })
     .done(function(data) {
         $('#message').html("Success! Your url is\nhttps://csh.link/" + data.code);
         console.log(data);
     })
     .fail(function(error) {
         var json = error.responseJSON;
         var reason;
         if (json && json.reason) {
             reason = json.reason;
         } else {
             reason = error.responseText;
         }
         $('#message').html("Error: " + reason);
         console.log(error);
     });
}
