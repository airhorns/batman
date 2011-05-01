// receive first call
everyone.now.startCrime();
everyone.connected(function() {
  this.now.startCrime();
});

// receive all subsequent calls
everyone.now.receiveCall(phoneNumber);

everyone.now.turnOnBatsignal = function() {
  // progress is complete, send signal to node
}
