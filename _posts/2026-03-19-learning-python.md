---
title: "Learning Python"
date: 2026-03-18 10:00:00 +0530
categories: [Python]
tags: [Python]
---

**Writing Comments**

"""
Some comments being written
in python
"""

'''
We can use single quotes
as well
'''

**Printing**

```
print("Hello", "World", sep="-", end="!")
```

**Range**

```
range(5)
range(5,10)
range(5,10,3)
list(range(5))
```

**Execution Control**

```
if i == 40:
  print("i am 40")
elif i > 40:
  print("i am greater than 40")
else:
  print("i am less than 40")
```

**for loops**

```
for i in range(10):
   if i == 8:
      break
   elif i == 7:
      continue
   else
      print(i)
```

**while loop**

```
while loop can be used with else

count = 0
while count < 10:
  print(count)
  count = count + 1
else:
  print("Out of loop")
```

**Handling Exceptions**

Use try-except block in python

```
thinkers = [
  'Plato',
  'PlayDo',
  'Gumby'
]

while True:
  try:
    thinker = thinkers.pop()
    print(thinker)
  except IndexError as e:
    print("We tried to pop too many thinkers")
    print(e)
    break
```

**A bit on classes and objects**

```
class FancyCar:
  # class variable
  wheels = f
  
  # instance method
  def driveFast(self):
    print("Driving so fast")
  
  # class methods, use @classmethod with cls keyword
  @classmethod
  def bla(cls)
    print("I am class method")
    
  # only inside class namespace
  @staticmethod
  def add(a, b)
    print('static method')

obj = FancyCar()
obj.instance_method()

obj = FancyCar()
obj.instance_method()

FancyCar.static_method()
obj.static_method()
```

**Some useful operations around sequences**

```
2 in [1,2,3]
'a' not in 'cat'
10 in range(12)
10 not in range(2, 4)
my_sequence = "Bill Cheatham"
my_sequence.index('C')
my_sequence = [1,2,3,4,5,6]
my_sequence[start:stop:step] # if nothing is passed then the defaults are start(0), stop(last), step(1)
# some array methods
.append, .remove, .pop, .insert
# some string methods
.capitalize, .upper, .swapcase, .startswith('s'), .endswith('k'), .isalnum(), isnumberic(), .isalpha()
```

**Dict**

```
map = {'key': 'value', 'abba': 'kabba'}
# adding element
map['something'] = 'nothing'

# looping over items
for k, v in map.items():
  print(k, v)
```

**Functions**

```
def bla(a, b)
def bla(a=4, b=9)
def kla:
  pass # implement later

# function as objects
def bla(a)
def kla(b)
for i in [bla, kla]
  i(4)
```

**Anonymous Fns**

lambda param1, param2, ... : expression
mul = lambda x, y, z: x * y * z

**regex in python**

import re


r is used for literal values, instead of new line it would look for exact \n(newline)

reg = r"\n"

reg = r'\b[a-zA-Z]+\Sl.p[a-z]?[0-9]{6}.*\b'
\b → word boundary
[a-zA-Z]+ → one or more letters
\S -> any single character that is not a whitespace character
. → any single character
[0-9]{6} → exactly 6 digits
[0-9]{1,4} -> matches 1 to 4 digits
.* → any characters after that
? → optional (0 or 1 occurrence)


reg = r'(\w+)\@(\w+)\.(\w+)'
bla@bla.abba

>> matched = re.findall(r'abba', variable)
>> matched
['abba', 'abba'.....]

**lazy evaluation**

Lazy evaluation is the idea that, especially when dealing with large
amounts of data, you do not want process all of the data before using the
results. Y ou have already seen this with the range type, where the
memory footprint is the same, even for one representing a large group of
numbers.

```
def count():
  n = 0
  while True:
  n += 1
  yield n

counter = count()
next(counter)
>> 1
next(counter)
>> 2
```

```
nums_list = [x for x in range(100)] # normal
nums_gen = (x for x in range(100)) # lazy

import sys
sys.getsizeof(nums_list)
sys.getsizeof(nums_gen)
```

**opening files**

with open('f.txt', 'r/w/rb....') as  f:
  k1 = f.read()
  k2 = f.readlines()

import pathlib
path = pathlib.Path("/Users/kbehrman......../bla.py")
path.read_text()

for binary data
path.read_bytes()

working with json files
import json

with open('service.json', 'r') as f:
  p = json.load(f)
  p['a'] = 90909
  print(p)
  
# Read line by line — use this for logs (memory efficient, file never fully loaded)
with open("app.log") as f:
    for line in f:
        print(line.strip())  # strip() removes the trailing \n

**context managers**

You already used a context manager here:

```
with open("app.log") as f:
    for line in f:
        print(line.strip())
```

Motivation:
- Some resources must be cleaned up no matter what (files, DB connections, locks, temp files).
- Without `with`, you can forget to close/release on error paths.
- Context managers keep setup + cleanup together and safer.

Under the hood, `with` calls:
- `__enter__()` at the start
- `__exit__()` at the end (even if exception happens)

Custom implementation using a class:

```
class ManagedFile:
    def __init__(self, path, mode):
        self.path = path
        self.mode = mode
        self.f = None

    def __enter__(self):
        self.f = open(self.path, self.mode)
        return self.f

    def __exit__(self, exc_type, exc_val, exc_tb):
        if self.f:
            self.f.close()
        # False means: do not swallow exceptions
        return False

with ManagedFile("notes.txt", "w") as f:
    f.write("hello from custom context manager")
```

Custom implementation using `contextlib.contextmanager`:

```
from contextlib import contextmanager

@contextmanager
def managed_file(path, mode):
    f = open(path, mode)
    try:
        yield f  # value after "as"
    finally:
        f.close()  # always runs

with managed_file("notes.txt", "a") as f:
    f.write("\nline 2")
```

**the os module**

```
os.listdir('.')
os.rename('_crud_handler', 'crud_handler')
os.chmod(fname, '0o777')
os.mkdir('/tmp/holding')
os.mkdirs('/tmp/holding',...)
os.remove('f')
os.rmdir(dir)
```

```
import os
# get full path
cur_dir = os.getcwd()
os.path.split(cur_dir)
os.path.dirname(cur_dir)
os.path.basename(cur_dir)
```

**spawn processes with the subprocess module**

```
import subprocess
k = subprocess.run(['ls', '-l'], capture_output=True, check=True, text=True, timeout=10)
# capture_output holds the data instead of directly throwing to stdout, can be accessed by k.stdout
# check=True raises exception if the process throws any exception
k.stdout
```

**capturing arguments**

```
# doing this makes sure that func does not get executed when you are importing code
# only gets executed when you do something like python3 file.py

if __name__ == '__main__':
  func()

import sys

# if you wish to capture the args passed
sys.argv[0]
sys.argv[1]
```

**def bla(log_path: str) vs def bla(log_path = str)**

log_path: str is a type hint inside a function signature that labels the expected data type (it says "this should be text"). It's not enforced.

log_path = str is an assignment that makes the variable equal to the actual Python string class itself (not a specific word or path).

TL;DR: Use : to describe what a variable should be, and = to give it a specific value.

**fn signatures**

  Gives info on how the return type should look like, not enforced

  ```
  def get_user(id: int) -> str:
  Return: "Alice"

  def get_scores() -> list[int]:
  Return: [88, 92, 100]

  def get_counts() -> dict[str, int]:
  Return: {"apple": 5, "orange": 2}

  def get_grid() -> list[list[int]]:
  Return: [[1, 0], [0, 1]]

  def get_cube() -> list[list[list[int]]]:
  Return: [[[1, 2], [3, 4]], [[5, 6], [7, 8]]]

  def get_data() -> dict[str, list[int]]:
  Return: {"ids": [101, 102], "codes": [200, 404]}

  def find_name() -> str | None:
  Return: "Bob" or None
  ```
