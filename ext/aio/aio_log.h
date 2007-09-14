// Asynchronously log the string of specified length to given file
int aio_log(void * string, int length, char * file_name) {
  printf("() aio_log '%s' > %s\n", string, file_name);
  
  int done = 0;
  int error;
  int file_descriptor;
  
  if ((file_descriptor = open(file_name, O_WRONLY | O_CREAT | O_APPEND)) == -1) {
    fprintf(stderr, "Failed to open %s: %s\n", file_name, strerror(errno));
    return 1;
  }
  
  if (init_signal(SIG_AIO) == -1) {
    perror("Failed to initialize signal");
    return 1;
  }
  
  if (init_write(file_descriptor, SIG_AIO, string, length) == -1) {
    perror("Failed to initate the write");
    return 1;
  }
  
  for ( ; ; ) {
    done = suspend_until_done_or_timeout(); // Wait for the aio complete signal or timeout
    if (!done) {
      if (done = getdone()) {
        if (error = geterror()) {
          fprintf(stderr, "Failed to log:%s\n", strerror(error));
        }
      }
    } else {
      fprintf(stderr, "Logging successful, %d bytes\n", getbytes());
      break; // break out of for loop
    }
  }
}
