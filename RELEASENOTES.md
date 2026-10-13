### 3.0.2



* Umbrella headers now list a base header "X.h" before category headers "X+Y.h"/"X-Y.h" that depend on it, so generated umbrella headers compile
* Sorting of categorized headers now ranks base headers ahead of categories instead of relying on plain `sort -d`, which ordered '+'/'-' before '.'

* properly use `MULLE_SDE_REFLECT_DIR` in created file paths

### 3.0.1

Various small improvements

# 3.0.0

Various small improvements
