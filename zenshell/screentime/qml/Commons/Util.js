function alpha(color, a) {
    if (!color) return Qt.rgba(0,0,0,a||0);
    return Qt.rgba(color.r, color.g, color.b, a);
}
function clampAlpha(n) {
    if (n < 0) return 0;
    if (n > 1) return 1;
    return n;
}
