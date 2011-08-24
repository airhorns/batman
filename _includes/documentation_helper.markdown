<script type="text/javascript">
$(function() {
  var toc = $("<div id='left-sidebar'></div>")
  var subnav = $("<ul class='subnav'></ul>")
  subnav.appendTo(toc)
  
  var wrapper = $('#content-column-wrapper')
  wrapper.find('ul').css('list-style', 'disc inside none')
  wrapper.find('h1,h2,h3').each(function(i, element){
    subnav.append("<li><a href='#" + element.id + "'>" + element.innerHTML + "</a></li>")
  })
  
  toc.insertBefore(wrapper)
})

</script>

+-- {#content-column-wrapper}
<p>We are working on more substantial documentation for batman.js. In the meantime, this README documents your perspective as a client fairly thoroughly, and the <span style="font-weight:bold"><a href="/source.html">annotated source</a></span> documents a large majority of the code. Both of these things are works in progress.</p>

{{ documentation }}
=--
