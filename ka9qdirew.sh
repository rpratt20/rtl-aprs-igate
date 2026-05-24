#!/usr/bin/bash
#	Horus Binary KA9Q-Radio Helper Script 19May 2102
#
#   Uses ka9q-radio (pcmrecord) to receive a chunk of spectrum, and passes it into Direwolf.
#
echo "Entering start script with path set as:"
echo $PATH

set -e
set -u
set -o pipefail
set -x
$RXFREQ 432900000
$SDR_DEVICE ka9qdirew


# trap "exit_rx" EXIT SIGINT SIGTERM

SSRC=$(($RXFREQ / 1000))01
RADIO=$(echo $SDR_DEVICE | sed 's/-pcm//g')

exit_rx() {
    echo "Exiting..."
    echo "Closing channel $SSRC at frequency $RXFREQ"
    timeout 120 tune --samprate 24000 --mode fm --frequency 0 --ssrc $SSRC --radio $RADIO
    pkill bash
}

echo "Using SDR Centre Frequency: $RXFREQ Hz"
echo "Using SSRC: $SSRC"
echo "Using PCM stream: $SDR_DEVICE"
echo $PATH

# Start the receive chain.
# Note that we now pass in the SDR centre frequency ($RXFREQ))

tune --mode pm --samprate 24000 frequency $RXFREQ --ssrc $SSRC --radio $RADIO

echo "Starting receiver chain"
pcmrecord --ssrc $SSRC --catmode --raw $SDR_DEVICE --timeout 120 | \
$DECODER -c direwolf.conf -
# t 0 & what are these for?

echo "Used 'pcmrecord --ssrc $SSRC --catmode --raw $SDR_DEVICE --timeout 120 |direwolf'"
echo "Started everything, waiting for any failed processes"

wait -n 
exit_rx