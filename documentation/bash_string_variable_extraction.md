# Bash substring

Bash supports a powerful substring syntax using variable expansion. With the right indizes it's possible to extract
any part of a string. The syntax has 2 forms (example of a variable `$str`):
1. `${str:position}`
2. `${str:position:length}` 

The behavior depends on the syntax used and whether `position` (`pos`) and `length` (`len`) are positive or negative.
*strlen* is the string length, 

| `pos` | `len`  | Extraction start | Extraction end           | Example with `str='0123456789'
|:-----:|:------:| ---------------- | ------------------------ | -----------------------------
| < 0   |        | *strlen* - `pos` | *string end*             | `${str: -5}` => 56789
| >= 0  |        | `pos`            | *string end*             | `${str:3}` => 3456789
| < 0   | < 0    | *strlen* - `pos` | *strlen* - `len`         | `${str: -5:-2}` => 567
| < 0   | > 0    | *strlen* - `pos` | *strlen* - `pos` + `len` | `${str: -5:3}` =>  567
| >= 0  | < 0    | `pos`            | *strlen* - `len`         | `${str:3:-3}` => 3456
| >= 0  | > 0    | `pos`            | `pos` + `len`            | `${str:3:3}` => 345

As you can see in the examples above, a space was inserted when `position` is negative. This is required to avoid a syntax 
collision with bash's "default value fallback" syntax `${var:-default}` (returns `default` if `$var` not set). When a variable is
used, as shown in the examples below, the space is not required:

|     |                      Code                     |                     Result           
|:---:| --------------------------------------------- | -------------------------------------
| 1   | `str='0123456789'`                            |
| 2   | `minus=-5`                                    |
| 3   | `echo "\$str: $str - \$minus: $minus"`        | $str: 0123456789 - $minus: -5
| 4   | `echo "\${str:-5}: ${str:-5}"`                | ${str:-5}: 0123456789
| 5   | `echo "\${str: -5}: ${str: -5}"`              | ${str: -5}: 56789
| 6   | `echo "\${str:\$minus}: ${str:$minus}"`       | ${str:$minus}: 56789
| 7   | `echo "\${str:3}: ${str:3}"`                  | ${str:3}: 3456789
| 8   | `echo "\${str:-5:-2}: ${str:-5:-2}"`          | ${str:-5:-2}: 0123456789
| 9   | `echo "\${str: -5:-2}: ${str: -5:-2}"`        | ${str: -5:-2}: 567
| 10  | `echo "\${str:\$minus:-2}: ${str:$minus:-2}"` | ${str:$minus:-2}: 567
| 11  | `echo "\${str:-5:3}: ${str:-5:3}"`            | ${str:-5:3}: 0123456789
| 12  | `echo "\${str: -5:3}: ${str: -5:3}"`          | ${str: -5:3}: 567
| 13  | `echo "\${str:\$minus:3}: ${str:$minus:3}"`   | ${str:$minus:3}: 567
| 14  | `echo "\${str:3:-3}: ${str:3:-3}"`            | ${str:3:-3}: 3456
| 15  | `echo "\${str:3:3}: ${str:3:3}"`              | ${str:3:3}: 345
