// ruby
#include "ruby.h"
#include "rubyio.h"

// aio
#include <aio.h>
#include <errno.h>
#include <stdio.h>
#include <fcntl.h> // File modes O_*

// Asynchronously log the string of specified length to given file
int aio_log(char * string, int length, char * file_name) {
  int file_descriptor, return_value, bytes_written;
  const struct aiocb *aio_control_block_list;
  struct aiocb control_block;

  bzero( &control_block, sizeof (struct aiocb)); 

	if ((file_descriptor = open(file_name, O_CREAT | O_RDWR | O_APPEND)) == -1) {
    return 1;
  }
  
	//Set up the control block
	control_block.aio_buf = (void *) string;
  control_block.aio_fildes = file_descriptor; //fileno(file);
	control_block.aio_nbytes = length;
	control_block.aio_offset = 0;
	
	// Perform the asynch write
	return_value = aio_write(&control_block);
  if (return_value) perror("aio_write:");

	// Wait for write to finish
  aio_control_block_list = &control_block;
  aio_suspend(&aio_control_block_list, 1, NULL);
  bytes_written = aio_return( &control_block);

  close(file_descriptor);

	return 0;
}

VALUE rb_flush_log_buffer() {
  VALUE packet, rb_string, buffer, log_files;
  int log_level, return_value;

  log_files = rb_gv_get("$alogr_log_files");
  buffer= rb_gv_get("$alogr_buffer");
  
  packet = rb_ary_shift(buffer); // Remove the first log packet from the buffer
  while( !NIL_P(packet) ) {
    rb_string = rb_ary_shift(packet);
    log_level = FIX2INT(rb_ary_shift(packet));

    return_value = aio_log(
      RSTRING(rb_string)->ptr, // The string to log
      RSTRING(rb_string)->len, // Real length of string to log
      RSTRING(rb_ary_entry(log_files, log_level))->ptr // log file name
      );

    if( return_value > 0 ) {
      // Unable to open the log file
      return Qfalse;
    }
    packet = rb_ary_shift(buffer); // Fetch the next log packet
  }
  
  return Qtrue;
}

static VALUE rb_mAlogR;
static VALUE rb_cLogger;

// Called when interpreter loads alogr
void Init_aio_logger() {
  VALUE rb_mAlogR = rb_define_module("AlogR");
  VALUE rb_cLogger = rb_define_class_under(rb_mAlogR, "Logger", rb_cObject);
  
  rb_gv_set("alogr_buffer", rb_ary_new());
  rb_gv_set("alogr_log_files", rb_ary_new());
  
  rb_define_method(rb_cLogger, "flush_log_buffer", rb_flush_log_buffer, 0);
}
