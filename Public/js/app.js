function renderLink(link, animated) {
    var source = $('#link-template').html();
    var template = Handlebars.compile(source);
    link.created_at = moment.unix(link.created_at).format('MMMM D, YYYY');
    var html = template({link: link});
    if (animated) {
        $(html).prependTo('#link-container')
               .css("display", "none")
               .slideDown({
                   easing: 'easeOutCubic'
               });
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
        link.visits = 0; // Hack.
        $('input[name=url]').val('');
        $('input[name=custom-code]').val('');
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
        $('#link-entry-' + code).slideUp({
            easing: 'easeOutCubic'
        }).done(function (elem) {
            elem.remove();
        });
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

function displayVisits(visits) {
    var ctx = $('#visit-chart').get(0).getContext('2d');
    var labels = [];
    var numbers = [];
    visits.forEach(function (visit) {
        var date = moment.unix(visit.timestamp).format('MMM DD, YYYY');
        if (labels.length == 0 || labels[labels.length - 1] != date) {
            labels.push(date);
            numbers.push(1);
        } else {
            numbers[numbers.length - 1]++;
        }
    });
    var chart = new Chart(ctx, {
        type: 'line',
        data: {
            labels: labels,
            datasets: [{
                data: numbers,
                fill: false,
                borderColor: "#911568"
            }]
        },
        options: {
            scales: {
                xAxes: [{
                    scaleLabel: {
                        display: true
                    }
                }],
                yAxes: [{
                    ticks: {
                        beginAtZero: true,
                        callback: function (i) { return i % 1 == 0 ? i : undefined; }
                    }
                }]
            },
            legend: {
                display: false
            },
        }
    });
}
