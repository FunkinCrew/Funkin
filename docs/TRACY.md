# Tracy Performance Profiling

In v0.5.1, Funkin' gained support for a powerful instrumentation-based profiler known as Tracy. This development tool allows you to see exactly what the game is doing at any given moment, how long each function is taking to call, and even how memory is allocated and deallocated. This is the most powerful tool in your toolbox for diagnosing and resolving performance issues.

## How to Use Tracy

1. Download [Tracy](https://github.com/wolfpld/tracy)
2. Build the game with the `FEATURE_DEBUG_TRACY` flag. For example, `lime build windows -debug -DFEATURE_DEBUG_TRACY`
3. Start Tracy, click Connect. Tracy will start waiting for Funkin' to start.
4. Start the game with Tracy enabled.

![Image](https://github.com/user-attachments/assets/2a394ca7-bc21-4fe3-ae55-347768fb5b87)
