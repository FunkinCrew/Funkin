#import "MemoryUtil.hpp"

#include <mach/mach.h>

size_t Apple_MemoryUtil_GetCurrentProcessRss()
{
  struct task_basic_info info;

  mach_msg_type_number_t count = TASK_BASIC_INFO_COUNT;

  if (task_info(mach_task_self(), TASK_BASIC_INFO, (task_info_t)&info, &count) != KERN_SUCCESS)
    return 0;

  return info.resident_size;
}
