This package implements GNU Octave readers for sidescan data files.

The functions jsf_reader and sdf_reader return a structure with the
following fields:

time       : Time in second since the Unix Epoch.
number     : ping number.
num_samples: number of samples.
range      : range in meter.
speed      : AUV speed in m/s.
roll       : AUV roll in radian.
pitch      : AUV pitch in radian.
heading    : AUV heading in radian.
lat        : AUV WGS84 latitude in radian.
lon        : AUV WGS84 longitude in radian.
depth      : AUV depth in meter.
alt        : AUV altitude in meter.
cfreq      : center frequency in Hz.
data_port  : port data.
data_stbd  : starboard data.
