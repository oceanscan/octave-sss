## Copyright (c) 2017 OceanScan - Marine Systems & Technology, Lda.
##
## This file is subject to the terms and conditions defined in file
## 'COPYING', which is part of this source code package.
##

## Author: Ricardo Martins <rasm@oceanscan-mst.com>
## Keywords: sdf sonar ping

## usage: PING = sdf_reader(FD)
##
## Read one ping from the SDF file specified by the file descriptor
## FD. This implementation if based on the document "SDF/SDFX Data Page
## Definitions Specification Rev 4.8".
##
## Return values:
##   - Structure with ping metadata and raw data.
##   - 0 if the end of file was reached while parsing a frame.
##
## If a parsing error is encountered an error will be raised.

function ping = sdf_reader(fd),
  while (!feof(fd)),
    ping = sdf_read_ping(fd);

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

    return;
  end
end

function ping = sdf_read_ping(fd),
  % Read marker plus 512 byte header.
  header = fread(fd, 129, "*uint32");
  if (size(header) != 129)
    ping = 1;
    return;
  end

  % Validate marker.
  if (header(1) != 0xffffffff),
    error("sdf: invalid marker 0x%08X", header(1));
  end

  % Page size.
  page_size = header(2);

  % Page version.
  page_version = header(3);

  % Page does not contain ping data, discard it.
  if (page_version != 3501 && page_version != 3502),
    fseek(fd, page_size - 512, SEEK_CUR);
    ping = 0;
    return;
  end

  ping = struct();

  % Time
  ping.time = sdf_read_time(header);

  % Ping number.
  ping.number = header(5);

  % Number of samples.
  ping.num_samples = header(6);

  % Range
  ping.range = double(header(9));

  % Speed.
  ping.speed = double(header(10)) * 0.01;

  % Orientation.
  [ping.roll, ping.pitch, ping.heading] = sdf_read_orientation(header);

  % Position
  [ping.lat, ping.lon, ping.depth, ping.alt] = sdf_read_position(header);

  % Frequency.
  ping.cfreq = header(103) * 1000;

  % Raw data.
  num_samples_port = fread(fd, 1, "*uint32");
  ping.data_port = fread(fd, num_samples_port, "*uint32");
  num_samples_stbd = fread(fd, 1, "*uint32");
  ping.data_stbd = fread(fd, num_samples_stbd, "*uint32");

  % Discard remaining bytes in page.
  remaining = page_size - 512 - (num_samples_port * 4 + 4) - (num_samples_stbd * 4 + 4);
  fseek(fd, remaining, SEEK_CUR);
end

function time = sdf_read_time(header),
  t = struct();
  t.year = header(19) - 1900;
  t.mon = header(20) - 1;
  t.mday = header(21);
  t.hour = header(22);
  t.min = header(23);
  t.sec = header(24);
  t.usec = typecast(header(56), "single") * 1e6;
  t.zone = "UTC";
  time = mktime(t);
end

function [lat, lon, depth, alt] = sdf_read_position(header),
  lat = typecast([header(38), header(39)] , "double");
  lon = typecast([header(40), header(41)] , "double");
  depth = double(typecast(header(53), "single"));
  alt = double(typecast(header(54), "single"));
end

function [roll, pitch, heading] = sdf_read_orientation(header),
  heading = deg2rad(double(typecast(header(36), "single")));
  pitch = deg2rad(double(typecast(header(51), "single")));
  roll = deg2rad(double(typecast(header(52), "single")));
end
