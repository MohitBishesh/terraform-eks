(function () {
  const words = document.querySelectorAll(".word");
  const button = document.getElementById("pulse-btn");

  function replay() {
    words.forEach((word, index) => {
      word.classList.remove("play");
      word.classList.add("replay");
      // Force reflow so the animation can restart.
      void word.offsetWidth;
      word.style.animationDelay = `${index * 0.12}s`;
      word.classList.add("play");
    });
  }

  if (button) {
    button.addEventListener("click", replay);
  }
})();
