#!/usr/bin/env bash
#
#	direwolf KA9Q-Radio Helper Script
#
#   Uses ka9q-radio (pcmrecord) to receive a chunk of spectrum, and passes it into direwolf.
#

set -e
set -u
set -o pipefail
set -x

# trap "exit_rx" EXIT SIGINT SIGTERM

SSRC=$(($RXFREQ / 1000))10
RADIO=$(echo $SDR_DEVICE | sed 's/-pcm//g')
#RADIO=$SDR_DEVICE

exit_rx() {
    echo "Exiting..."
    echo "Closing channel $SSRC at frequency $RXFREQ"
#    timeout 2 tune --mode aprs1200 --samprate 24000 --frequency 0 --ssrc $SSRC --radio $RADIO
    timeout 2 tune --mode pm --samprate 24000 --frequency 0 --ssrc $SSRC --radio $RADIO
    pkill bash
}

echo "Using HOJO SDR Centre Frequency: $RXFREQ Hz"
echo "Using HOJO SSRC: $SSRC"
echo "Using HOJO PCM stream: $SDR_DEVICE"

# Start the receive chain.
# Note that we now pass in the SDR centre frequency ($RXFREQ) and 'target' signal frequency ($RXFREQ)
# to enable providing additional metadata to Habitat / Sondehub.
echo "Configuring receiver on ka9q-radio"
#tune --mode aprs1200 --samprate 24000 frequency $RXFREQ --ssrc $SSRC --radio $RADIO
tune --mode pm --samprate 24000 frequency $RXFREQ --ssrc $SSRC --radio $RADIO

echo "Starting direwolf receiver chain"
pcmrecord --ssrc $SSRC --catmode --raw $SDR_DEVICE --timeout 120 | \
  $DECODER -c /bin/HOJO_direwolf_sdr.conf -t 0 &

echo "Started direwolf everything, waiting for any failed processes"

wait -n 
exit_rx

