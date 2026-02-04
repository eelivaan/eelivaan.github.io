
document.querySelectorAll('img.fill').forEach(img => {
    img.addEventListener('click', (event) => {
        event.preventDefault();
        togglefscr(event);
    });
});

// show event target element in fullscreen mode, or exit fullscreen if already in fullscreen
function togglefscr(event) {
    if (document.fullscreenElement) {
        document.exitFullscreen();
    } else {
        event.target.requestFullscreen().catch(err => {
            alert(`Error: ${err.message}`);
        });
    }
}