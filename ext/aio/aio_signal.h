#include "aio.h"
#include "errno.h"
#include "signal.h"
//#include "restart.h" // r_read, r_write, etc

static struct aiocb aiocb;
static sig_atomic_t doneflag;
static int fdout;
static int globalerror;
static int totalbytes;

static int readstart();
static void seterror(int error);

static void aiohandler(int signo, siginfo_t *info, void *context) {
  int  myerrno;
  int  mystatus;
  int  serrno;

  serrno = errno;
  myerrno = aio_error(&aiocb);

  if (myerrno == EINPROGRESS) {
    errno = serrno;
    return;
  }

  if (myerrno) {
    seterror(myerrno);
    errno = serrno;
    return;
  }

  mystatus = aio_return(&aiocb);
  totalbytes += mystatus;

  // Handling of regexen should go somewhere around here

  if (mystatus == 0) {
    doneflag = 1;
  }

  errno = serrno;
}

// start an asynchronous read
static int readstart() {
  int error;
  if (error = aio_read(&aiocb)) {
    seterror(errno);
  }
  return error;
}

// start an asynchronous write
static int writestart() {
  int error;
  if (error = aio_write(&aiocb)) {
    seterror(errno);
  }
  return error;
}

// update globalerror if zero
static void seterror(int error) {
  if (!globalerror) {
    globalerror = error;
  }
  doneflag = 1;
}

/* --------------------------Public Functions ---------------------------- */
// Get the total number of bytes
int getbytes() {
  if (doneflag){
    return totalbytes;
  }
  errno = EINVAL;
  return -1;
}

// Check if done
int getdone() {
  return doneflag;
}

// Return the globalerror value if process is done
int geterror() {
  if (doneflag) {
    return globalerror;
  }
  errno = EINVAL;
  return errno;
}

int init_read(int fdread, int fdwrite, int signo, char *buf, int bufsize) {
  // Setup control block
  aiocb.aio_fildes = fdread;
  aiocb.aio_offset = 0;
  aiocb.aio_buf = (void *) buf;
  aiocb.aio_nbytes = bufsize;

  // Signal handling
  aiocb.aio_sigevent.sigev_notify = SIGEV_SIGNAL;
  aiocb.aio_sigevent.sigev_signo = signo;
  aiocb.aio_sigevent.sigev_value.sival_ptr = &aiocb;
  fdout = fdwrite;
  doneflag = 0;
  globalerror = 0;
  totalbytes = 0;
  return readstart(); // Initiate the aio_read call
}

int init_write(int fdwrite, int signal_number, char *buffer, int buffer_size) {
  // Setup control block
  aiocb.aio_fildes = fdwrite;
  aiocb.aio_offset = 0; // Should be ignored if file is in append-mode
  aiocb.aio_buf = (void *)buffer;
  aiocb.aio_nbytes = buffer_size;

  // Signal handling
  aiocb.aio_sigevent.sigev_notify = SIGEV_SIGNAL;
  aiocb.aio_sigevent.sigev_signo = signal_number;
  aiocb.aio_sigevent.sigev_value.sival_ptr = &aiocb;

  aiocb.aio_sigevent.sigev_signo = SIGUSR1;
  // Initialize variables
  fdout = fdwrite;
  doneflag = 0;
  globalerror = 0;
  totalbytes = 0;

  return writestart(); // Initiate the aio_write call
}

// set up the handler for the async I/O
int init_signal(int signo) {
  struct sigaction newact;

  newact.sa_sigaction = aiohandler;
  newact.sa_flags = SA_SIGINFO;
  if ((sigemptyset(&newact.sa_mask) == -1) || 
  (sigaction(signo, &newact, NULL) == -1)) {
    return -1;
  }
  return 0;
}

// return 1 if done, 0 otherwise
int suspend_until_done_or_timeout() {
  const struct aiocb *aiocblist;

  aiocblist = &aiocb;
  aio_suspend(&aiocblist, 1, NULL);
  return doneflag;
}
