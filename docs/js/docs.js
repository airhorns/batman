
  $(document).ready(function() {
    var $sidebar, setSidebarPos;
    $('.console-session > pre').hide();
    $(window).scroll(function(e) {
      return setSidebarPos();
    });
    $sidebar = $('.sidebar');
    setSidebarPos = function() {
      if ($(window).scrollTop() + $sidebar.height() > $('.container').height()) {
        return $sidebar.css({
          top: 'auto',
          bottom: $('.container').css('marginBottom')
        });
      } else if ($(window).scrollTop() === 0) {
        $sidebar.scrollTop;
        return $sidebar.css({
          bottom: 'auto'
        });
      } else {
        return $sidebar.css({
          top: 0,
          bottom: 'auto'
        });
      }
    };
    $('body').append('<a id="expand-all-the-things"></a>');
    $('#expand-all-the-things').toggle(function(e) {
      $('.console-session > pre').show();
      return e.preventDefault();
    }, function() {
      $('.console-session > pre').hide();
      return e.preventDefault();
    });
    $('.console-session').each(function() {
      var $header;
      if ($(this).has('h4 + pre')) {
        $header = $(this).find('h4').addClass('snippet-closed');
        return $header.addClass('expandable').toggle(function() {
          $(this).toggleClass('snippet-closed');
          return $(this).parent().find('pre:first').slideDown('fast');
        }, function() {
          $(this).toggleClass('snippet-closed');
          return $(this).parent().find('pre:first').hide();
        });
      }
    });
    $('#table_of_contents ul').each(function() {
      if ($(this).children().size() === 0) return $(this).remove();
    });
    return $("#quick-search").quicksearch('.searchable');
  });
