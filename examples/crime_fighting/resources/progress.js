var ProgressBar = function(width, height) {
  var padding = 20;
  var paper = Raphael("canvas", width + padding, height + padding);
  
  var x = padding * 0.5;
  var y = padding * 0.5;
  var percent = 0;
  var height = height;
  var width = width;
  
  var bkg = paper.rect(3, 3, width + padding * 0.5 + 4, height + padding * 0.5 + 4, 4).attr({ "stroke-width": 0.5, fill: "0-#ddd-#666" });
  
  var bkg = paper.rect(x, y, width, height, 4).attr({ fill: "0-#666-#999" });

  var bar = paper.rect(x, y, width, height, 6).attr(color()).attr({scale: [1, .00001, x, y + height]});

  var border = paper.rect(x, y, width, height, 4).attr({ stroke: "#444", "stroke-width": 2});
  
  function offset() {
    return percent * 0.01 * height;
  }
  
  function color() {
    // In HSB, red has hue=0, green has hue=120. HSB has a max hue of 360
    // So we take 120 * percent * 0.01 / 360
    var hue = percent * 0.00333;
    return { fill: "0-hsb(" + hue + ",1, 1)-hsb(" + hue + ",1, 0.5)",
             stroke: "hsb(" + hue + ",1, 0.4)" }
  }
  
  this.update = function(_percent) {
    if(_percent > 100) {
      _percent = 100;
    } else if (_percent <= 0) {
      // raphael gets funky when you scale to 0.
      _percent = 0.001;
    }
    percent = _percent;
    bar.animate({scale: [1, percent * 0.01, x, y + height] }, 2000, ">");
    bar.attr(color());
  }
}