#!/usr/bin/env bash
#
#	Direwolf KA9Q-Radio Helper Script
#
#   Uses ka9q-radio (pcmrecord) to receive a chunk of spectrum, and passes it into Direwolf.
#

set -e
set -u
set -o pipefail
set -x

# trap "exit_rx" EXIT SIGINT SIGTERM

SSRC=$(($RXFREQ / 1000))01
RADIO=$(echo $SDR_DEVICE | sed 's/-pcm//g')

exit_rx() {
    echo "Exiting..."
    echo "Closing channel $SSRC at frequency $RXFREQ"
    timeout 2 tune --samprate 48000 --mode pm --frequency 0 --ssrc $SSRC --radio $RADIO
    pkill bash
}

echo "Using SDR Centre Frequency: $RXFREQ Hz"
echo "Using SSRC: $SSRC"
echo "Using PCM stream: $SDR_DEVICE"

# Start the receive chain.
# Note that we now pass in the SDR centre frequency ($RXFREQ)

echo "Configuring receiver on ka9q-radio"
tune --samprate 48000 --mode pm  --high 8000 --frequency $RXFREQ --ssrc $SSRC --radio $RADIO

echo "Starting receiver chain"
pcmrecord --ssrc $SSRC --catmode --raw $SDR_DEVICE --timeout 1 | \
  $DECODER -q --stats=5 -g | \
  direwolf -c direwolf.conf -r 24000 - 

echo "Started everything, waiting for any failed processes"

wait -n 
exit_rx