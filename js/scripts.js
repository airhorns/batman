// Begin jquery tweet //
$(document).ready(function(){
    $(".tweet").tweet({
        query: "#batmanjs",
        join_text: "auto",
        count: 3,
        auto_join_text_default: "", 
        auto_join_text_ed: "",
        auto_join_text_ing: "",
        auto_join_text_reply: "",
        auto_join_text_url: "",
        loading_text: "loading tweets..."
    });
});

// Begin dynamically add icon to external links //
$(document).ready(function() {
  $('#sub #content-column-wrapper a, #sub #content-column-wrapper-full a, ').filter(function() {
    return this.hostname && this.hostname !== location.hostname;
  }).after('<img style="padding: 0 2px 0 3px;" src="images/icon-external-link.png" alt="external link"/>');
});
