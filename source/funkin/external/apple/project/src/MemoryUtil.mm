#import "MemoryUtil.hpp"

#include <mach/mach.h>

size_t Apple_MemoryUtil_GetCurrentProcessRss()
{
  task_basic_info info;

  if (task_info(mach_task_self(), TASK_BASIC_INFO, (task_info_t)&info, &TASK_BASIC_INFO_COUNT) != KERN_SUCCESS)
    return 0;

  return info.resident_size;
}
