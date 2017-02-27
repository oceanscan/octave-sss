## Copyright (c) 2017 OceanScan - Marine Systems & Technology, Lda.
##
## This file is subject to the terms and conditions defined in file
## 'COPYING', which is part of this source code package.
##

## Author: Ricardo Martins <rasm@oceanscan-mst.com>
## Keywords: jsf sonar ping

## usage: PING = jsf_reader(FD)
##
## Read one ping from the JSF file specified by the file descriptor
## FD. This code is based on the information given in the document "JSF
## Data File Description Rev. 1.20".
##
## Return values:
##   - Structure with ping metadata and raw data.
##   - 0 if the end of file was reached while parsing a frame.
##
## If a parsing error is encountered an error will be raised.

function ping = jsf_reader(fd),
  persistent saved_ping = 0;

  % We have a saved ping, return that.
  if isstruct(saved_ping)
    saved_ping = 0;
    ping = saved_ping;
    return;
  end

  while (!feof(fd)),
    ping = jsf_read_ping(fd);

    if !isstruct(ping),
      % Not sonar data.
      if ping == 0,
        continue;
      end
      % Incomplete frame (i.e., end of file reached while parsing).
      if ping == 1,
        ping = 0;
        return;
      end
    end

    % Read next ping.
    saved_ping = jsf_read_ping(fd);

    % Next ping contains the missing channel.
    if ping.number == saved_ping.number && ping.cfreq == saved_ping.cfreq,
      ping.data_stbd = saved_ping.data_stbd;
      saved_ping = 0;
    end

    return;
  end
end

function ping = jsf_read_ping(fd),
  persistent last_ping = struct();

  header_bytes = fread(fd, 16, "*uint8");
  if size(header_bytes) != 16,
    ping = 1;
    return;
  end
  header = jsf_decode_message_header(header_bytes);

  payload_bytes = fread(fd, header.payload_size, "*uint8");
  if size(payload_bytes) != header.payload_size,
    ping = 1;
    return;
  end

  if header.type == 80,
    ping = jsf_decode_sonar_data(payload_bytes, header.channel);
    return;
  end

  ping = 0;
end

function header = jsf_decode_message_header(bytes),
  marker = typecast(bytes([1:2]), "uint16");
  if marker != 0x1601,
    error("jsf: invalid message marker: %04X\n", marker);
  end

  header = struct();
  header.version = bytes(3);
  header.type = typecast(bytes([5:6]), "uint16");
  header.subsys = bytes(8);
  header.channel = bytes(9);
  header.payload_size = typecast(bytes([13:16]), "uint32");
end

function ping = jsf_decode_sonar_data(bytes, channel),
  ping = struct();

  msbs = double(typecast(bytes([17:18]), "uint16"));
  lsbs = double(typecast(bytes([19:20]), "uint16"));

  % Time.
  seconds = double(typecast(bytes([1:4]), "uint32"));
  millis = double(typecast(bytes([201:204]), "uint32"));
  ping.time = seconds + mod(millis, 1000.0) / 1000.0;

  % Channel.
  ping.channel = channel;

  % Ping number.
  ping.number = typecast(bytes([9:12]), "uint32");

  % Longitude.
  ping.lon = double(typecast(bytes([81:84]), "int32")) / 34377467.707849;

  % Latitude.
  ping.lat = double(typecast(bytes([85:88]), "int32")) / 34377467.707849;

  % Depth.
  ping.depth = double(typecast(bytes([137:140]), "int32")) / 1000.0;

  % Altitude.
  ping.alt = double(typecast(bytes([145:148]), "int32")) / 1000.0;

  % Heading.
  ping.heading = double(typecast(bytes([173:174]), "uint16")) / 100.0;

  % Roll.
  ping.pitch = double(typecast(bytes([175:176]), "int16")) * 180 / 32768;

  % Pitch.
  ping.roll = double(typecast(bytes([177:178]), "int16")) * 180 / 32768;

  % Speed.
  ping.speed = ((double(typecast(bytes([195:196]), "int16"))) / 10) * 0.54444444444;

  % Number of samples.
  num_samples = double(typecast(bytes([115:116]), "uint16"));
  ping.num_samples = bitor(num_samples, bitshift(bitand(msbs, 0xf00), 8));

  % Range.
  sample_interval = double(typecast(bytes([117:120]), "uint32"));
  ping.range = ((sample_interval / 1e9) * num_samples * 1500) / 2;

  % Transmit pulse starting frequency.
  sfreq = double(typecast(bytes([127:128]), "uint16"));
  sfreq = bitor(sfreq, bitshift(bitand(msbs, 0xf), 16)) * 10;

  % Transmit pulse ending frequency.
  efreq = double(typecast(bytes([129:130]), "uint16"));
  efreq = bitor(efreq, bitshift(bitand(msbs, 0xf0), 12)) * 10;

  % Trasmit pulse center frequency.
  ping.cfreq = sfreq + ((efreq - sfreq) / 2.0);

  % Weighted data samples.
  weight_factor = 2^-double(typecast(bytes([169:170]), "int16"));
  data = double(typecast(bytes([241:end]), "uint16")) * weight_factor;
  if channel == 0,
    ping.data_port = data;
  else
    ping.data_stbd = data;
  end
end
