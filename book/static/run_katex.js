
window.onload = function () {

  for (let e of document.getElementsByClassName('mymathInline')) {
    katex.render(e.textContent, e, {throwOnError: false, displayMode: false});
  }

  for (let e of document.getElementsByClassName('mymathDisplay')) {
    katex.render(e.textContent, e, {throwOnError: false, displayMode: true});
  }

}

