function sleep(milliseconds) {
    const start = Date.now();
    while (Date.now() - start < milliseconds);
}

function now() {
    return Math.floor(+new Date() / 1000);
}

module.exports = {
    sleep,
    now
}