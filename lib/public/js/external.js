  window.onload = function() {
    var links = document.getElementsByTagName("a");
    for (var i = 0; i < links.length; i++) {
      var rels = links[i].getAttribute("rel");
      if (rels) {
        var testpattern = new RegExp("external");
        if (testpattern.test(rels)) {
          links[i].onclick = function() {
            return !window.open(this.href);
          }
        }
      }
    }
  }
