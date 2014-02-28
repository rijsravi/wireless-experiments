wireless-experiments
====================

1. dbpsk_receiver: This is an implementation of a DBPSK Receiver which employs the Mueller & Muller algorithm for sampling the actual data. The program is currently split into three modules

2. movement-detector: This program processes the samples taken on a wireless receiver unit and detects for movement of any body in the channel between the transmitter and receiver. It employs a simple threshold based alogrithm using standard deviation to calculate the threshold.

3. channel-decoder: This program uses the Viterbi Decoding algorithm to decode the samples that are a result of convolution codes being passed through the noisy channel. It uses a flag to do both hard and soft decoding.


