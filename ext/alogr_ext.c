// There might be a more efficient way to do this
// However the goal is to make it work first :)
// NOTE:
//The signal handler does not output any error messages. Output from an asynchronous signal handler can interfere with I/O operations in the main program, and the standard library routines such as fprintf and perror may not be safe to use in signal handlers. Instead, the signal handler just keeps track of the errno value of the first error that occurred. The main program can then print an error message, using strerror.

// ruby
#include "ruby.h"
#include "rubyio.h"

// pthread
#include <pthread.h>
#include <unistd.h>   // Standard unix constants (posix)
#define NUM_THREADS 1

// aio
#include <aio.h>
#include <errno.h>
#include <fcntl.h>
#include <sys/stat.h> // MODEs
#include <signal.h>
//#define SIG_AIO (SIGRTMIN+5) // OSX seems to be lacking
#define SIG_AIO SIGUSR1 // So trying this for now... :(
#include "aio/aio_signal.h"
#include "aio/aio_log.h"

#define BLKSIZE 1024
#define MODE (S_IRUSR | S_IWUSR | S_IRGRP | S_IROTH)

struct thread_data { } payload[NUM_THREADS];
int status;
pthread_mutex_t log_mutex;
pthread_cond_t log_threshold_cv;

// Consume the queue one item at a time
void *muncher(void *thread_arg) {
  printf("\n() muncher!");

  VALUE work, rb_string, buffer, log_files;
  int log_level;
  log_files = rb_gv_get("$alogr_log_files");
  buffer= rb_gv_get("$alogr_buffer");

  for( ; ; ) {
    // Remove the first item from the buffer
    work = rb_ary_shift(buffer);
    while(!NIL_P(work)) {
      log_level = FIX2INT(rb_ary_shift(work));
      rb_string = rb_ary_shift(work);

      aio_log( RSTRING(rb_string)->ptr, // The string to log
        RSTRING(rb_string)->len, // Real length of string to log
        RSTRING(rb_ary_entry(log_files, log_level))->ptr // log file name
        );
      
      work = rb_ary_shift(buffer); // Fetch the next item of work
    }
    sleep(0.05); // Wait before rechecking the queue
    // TODO: Process regexen on string afterwards, then log strings that match to appropriate locations. Do this in callback.
    // TODO: Figure out a clean exit condition... If $alogr_log_files is marked for GC then break?
  };

  printf("<i> Thread exiting!\n");
  pthread_exit((void *) 0);
}

static VALUE signal_munchers() {
  pthread_mutex_lock(&log_mutex);
  pthread_cond_signal(&log_threshold_cv);
  pthread_mutex_unlock(&log_mutex);

  return Qnil;
}

// Initialize the muncher thread(s)
static VALUE init_munchers() {  
  printf("\n() init_munchers");
  int return_code;

  pthread_t threads[NUM_THREADS];
  pthread_attr_t attr;

  // Initialize and set thread detached attribute
  pthread_attr_init(&attr);
  pthread_attr_setdetachstate(&attr, PTHREAD_CREATE_JOINABLE);

  int t;
  for(t = 0; t < NUM_THREADS; t++) {
  //payload[t].data = ...;
    pthread_create(&threads[t], &attr, muncher, (void *) &payload[t]);
  }

  for(t=0; t<NUM_THREADS; t++) {
    printf("Creating thread %d\n", t);
    return_code = pthread_create(&threads[t], &attr, muncher, NULL); 
    if (return_code) {
      printf("ERROR; return code from pthread_create() is %d\n", return_code);
      exit(-1);
    }
  }

  // Free attribute and wait for the other threads
  pthread_attr_destroy(&attr);
  for(t=0; t<NUM_THREADS; t++) {
    return_code = pthread_join(threads[t], (void **) &status);
    if(return_code) {
      printf("ERROR; return code from pthread_join() is %d\n", return_code);
      exit(-1);
    }
    printf("Completed join with thread %d status= %d\n",t, status);
  }

  pthread_exit(NULL);
  
  return Qnil;
}

static VALUE cAlogR;
// Called when interpreter loads alogr
void Init_alogr_ext() {
  printf("() Init_alogr_ext\n");
  rb_gv_set("alogr_buffer", rb_ary_new());
  rb_gv_set("alogr_log_files",rb_ary_new());
  rb_define_method(cAlogR, "init_munchers", init_munchers, 0);
  rb_define_method(cAlogR, "signal_munchers", signal_munchers, 0);
}
