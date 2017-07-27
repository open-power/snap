# Two methods
Intersection has two methods and are implemented in two Actions. 
One is in hw_h (hash, -m1) and one is in hw_s (sort, -m2).

# Important

To select the action HW method, you must config it first, by

```
make -C snap clean
make -C $ACTION_ROOT config_h
```

.or. 

```
make -C snap clean
make -C $ACTION_ROOT config_s
```

Then follow the usual flow. 
```
make -C snap/hardware config model
make -C snap/hardware image
```

