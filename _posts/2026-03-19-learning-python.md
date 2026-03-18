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
