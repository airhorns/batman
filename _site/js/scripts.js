// Begin dynamically add icon to external links //
$(document).ready(function() {
  $('#sub #content-column-wrapper a, #sub #content-column-wrapper-full a, ').filter(function() {
    return this.hostname && this.hostname !== location.hostname;
  }).after('<img style="padding: 0 2px 0 3px;" src="/images/icon-external-link.png" alt="external link"/>');
});

// Begin fancybox //
$(document).ready(function() {

    /* This is basic - uses default settings */
    $("a#fancybox-image").fancybox();
    
    /* Using custom settings */
    $("a#fancybox-content").fancybox({
    	'hideOnContentClick': true
    });
    
    /* Apply fancybox to multiple items */
    $("a.fancybox-group").fancybox({
    	'transitionIn'	:	'elastic',
    	'transitionOut'	:	'elastic',
    	'speedIn'		:	600, 
    	'speedOut'		:	200, 
    	'overlayShow'	:	false
    });
    
});
