# Bash substring

Bash supports a very powerful substring syntax using variable expansion. Using the right indizes it's possible to extract
any part of a string. The syntax has 2 forms (example of a string variable $str):
1. `${str:position}`
2. `${str:position:length}` 

The behavior depends on whether position and length are positive, negative or in the case of length, defined at all:

| `position` | `length`  | Extraction start             | Extraction end                          | Example with `str='0123456789'`
| ---------  | --------- | ---------------------------- | --------------------------------------- | -------------------------------
| < 0        | -         | *string length* - `position` | `string end`                            | `${str:3}` => '3456789'
| > 0        | -         | `position`                   | `string end`                            | `${str: -5}` => '56789'     
| < 0        | < 0       | *string length* - `position` | `string length` - `length`              | `${str: -5:-2}` => '567'    
| < 0        | > 0       | *string length* - `position` | `string length` - `position` + `length` | `${str: -5:3}` => '567'     
| > 0        | < 0       | `position`                   | `string length` - `length`              | `${str:3:-3}` => '3456'     
| > 0        | > 0       | `position`                   | `position` + `length`                   | `${str:3:3}` => '345'       

As you can see in the examples above, a space was inserted when `position` is negative. This is required to avoid a syntax 
collision with bash's "default value fallback" syntax `${var:-default}` (returns `default` if `$var` not set). When a variable is
used, as shown in the examples below, the space is not required:

                      Code                     |                     Result           
 --------------------------------------------- | -------------------------------------
 `str='0123456789'`                            |
 `minus=-5`                                    |
 `echo "\$str: $str - \$minus: $minus"`        | $str: 0123456789 - $minus: -5
 `echo "\${str:-5}: ${str:-5}"`                | ${str:-5}: 0123456789
 `echo "\${str: -5}: ${str: -5}"`              | ${str: -5}: 56789
 `echo "\${str:\$minus}: ${str:$minus}"`       | ${str:$minus}: 56789
 `echo "\${str:3}: ${str:3}"`                  | ${str:3}: 3456789
 `echo "\${str:-5:-2}: ${str:-5:-2}"`          | ${str:-5:-2}: 0123456789
 `echo "\${str: -5:-2}: ${str: -5:-2}"`        | ${str: -5:-2}: 567
 `echo "\${str:\$minus:-2}: ${str:$minus:-2}"` | ${str:$minus:-2}: 567
 `echo "\${str:-5:3}: ${str:-5:3}"`            | ${str:-5:3}: 0123456789
 `echo "\${str: -5:3}: ${str: -5:3}"`          | ${str: -5:3}: 567
 `echo "\${str:\$minus:3}: ${str:$minus:3}"`   | ${str:$minus:3}: 567
 `echo "\${str:3:-3}: ${str:3:-3}"`            | ${str:3:-3}: 3456
 `echo "\${str:3:3}: ${str:3:3}"`              | ${str:3:3}: 345
