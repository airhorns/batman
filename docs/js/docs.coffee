$(document).ready ->

   # should be addressed in the html:
  $('body').wrapInner('<div class="container clearfix"></div>')

  # hide all the code samples by default
  $('.console-session > pre').hide()

  # little square fixed to the bottom right / toggles hiding showing all the examples... just in case.
  $('body').append('<a id="expand-all-the-things"></a>')
  $('#expand-all-the-things').toggle (e) ->
    $('.console-session > pre').show()
    e.preventDefault()
  , ->
    $('.console-session > pre').hide()
    e.preventDefault()

  # expandable code snippets
  $('.console-session').each ->
    if $(@).has('h4 + pre')
      $header = $(@).find('h4').addClass('snippet-closed')
      $header.addClass('expandable').toggle ->
        $(@).toggleClass('snippet-closed')
        $(@).parent().find('pre:first').slideDown('fast')
      , ->
        $(@).toggleClass('snippet-closed')
        $(@).parent().find('pre:first').hide()

  # should be addressed in the html:
  # there are a lot of empty lists in the table of contents... I am... removing them...
  $('#table_of_contents ul').each ->
    if $(@).children().size() is 0
      $(@).remove();

  # i have a dream...
  #$('div[role="sidebar"]').prepend('<form><input id="quick-search" type="search" placeholder="Find something fun!"></form>')
  #qs = $("#quick-search").quicksearch
