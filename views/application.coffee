$ ->
  prettyPrint()
  $.ajax location.pathname + '/comments',
    type: 'GET'
    error: (jqXHR, textStatus, errorThrown) ->
      alert "AJAX Error: #{textStatus}"
    success: (data, textStatus, jqXHR) ->
       $.each data, (i, e) ->
         comment = $('<div/>').addClass('comment').append($('<span/>').text(e.name)).append($('<img/>').attr('src', e.icon_url).addClass('icon')).append($('<span/>').text(e.content))
         $($('li').get(e.line_no)).before(comment)
