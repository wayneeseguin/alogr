// ruby
#include "ruby.h"
#include "rubyio.h"

// aio
#include <aio.h>
#include <errno.h>
#include <stdio.h>
#include <fcntl.h> // File modes O_*

static struct aiocb control_block;

// Asynchronously log the string of specified length to given file
int aio_log(char * string, int length, char * file_name) {
  int file_descriptor;
  const struct aiocb *aio_control_block_list;

	printf("string %s, length: %d, file_name: %s\n", string, length, file_name);

	if ((file_descriptor = open(file_name, O_CREAT | O_RDWR | O_APPEND)) == -1) {
    printf("Failed to open %s: %s\n", file_name, strerror(errno));
    return 1;
  }
  
	//Set up the control block
	control_block.aio_buf = (void *) string;
  control_block.aio_fildes = file_descriptor; //fileno(file);
	control_block.aio_nbytes = length;
	control_block.aio_offset = 0;
	
	// Perform the asynch write
	aio_write(&control_block);

	// Wait for write to finish
  aio_control_block_list = &control_block;
  aio_suspend(&aio_control_block_list, 1, NULL);

	printf("AIO operation returned %d\n", aio_return(&control_block));

  //close(file_descriptor); // Is this necessary? It appears not but...?

	return 0;
}

VALUE rb_flush_log_buffer() {
  VALUE work, rb_string, buffer, log_files;
  int log_level;

  log_files = rb_gv_get("$alogr_log_files");
  buffer= rb_gv_get("$alogr_buffer");

  // Remove the first item from the buffer
  work = rb_ary_shift(buffer);
  while( !NIL_P(work) ) {
    log_level = FIX2INT(rb_ary_shift(work));
    rb_string = rb_ary_shift(work);

    aio_log(
      RSTRING(rb_string)->ptr, // The string to log
      RSTRING(rb_string)->len, // Real length of string to log
      RSTRING(rb_ary_entry(log_files, log_level))->ptr // log file name
      );

    work = rb_ary_shift(buffer); // Fetch the next item of work
  }

  return Qnil;
}

static VALUE rb_mAlogR;
static VALUE rb_cLogger;

// Called when interpreter loads alogr
void Init_aio_logger() {
  printf("\n() Init_alogr_ext\n");
  
  VALUE rb_mAlogR = rb_define_module("AlogR");
  VALUE rb_cLogger = rb_define_class_under(rb_mAlogR, "Logger", rb_cObject);
  
  rb_gv_set("alogr_buffer", rb_ary_new());
  rb_gv_set("alogr_log_files", rb_ary_new());
  
  rb_define_method(rb_cLogger, "flush_log_buffer", rb_flush_log_buffer, 0);
}
