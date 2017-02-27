fd = fopen("Data.jsf", "r");
reader = @jsf_reader;

## fd = fopen("Data.sdf", "r");
## reader = @sdf_reader;

while 1,
  ping = reader(fd);
  if (!isstruct(ping))
    break;
  end

  % Flip port size.
  port = flipud(ping.data_port);
  % Leave starboard as is.
  stbd = ping.data_stbd;

  % Plot raw data by frequency.
  if (ping.cfreq < 600000)
    subplot(2, 2, 1);
    plot(port);
    title("Low Frequency - Port");
    subplot(2, 2, 2);
    plot(stbd);
    title("Low Frequency - Starboard");
  else
    subplot(2, 2, 3);
    plot(port);
    title("High Frequency - Port");
    subplot(2, 2, 4);
    plot(stbd);
    title("High Frequency - Starboard");
  end

  drawnow();
end

fclose(fd);
