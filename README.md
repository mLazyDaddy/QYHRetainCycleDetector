# QYHRetainCycleDetector
ObjectiveC retain cycle detecor
***

##	简介
通过hook `objc_retain`和`objc_release`等方法，将存活的NSObject对象的添加进对象池，然后定时检测对象池里的对象是否存在循环引用。

检测循环引用的实现参考了FBRetainCycleDetector，为了避免在检测过程中再次调用`objc_retain`等方法而进入死循环，主要使用CoreFoundation对象以及自定义结构，手动管理内存。

目前能检测到的循环引用有NSObject对象A和B相互强引用、NSTimer循环引用、Block循环引用。

##	使用方式


###	启用

```
[QYHRetainCycleDetector enable];
```

建议在将启用函数添加至

```
application:didFinishLaunchingWithOptions:
```
函数中。

###	关闭

```
QYHRetainCycleDetector disable];
```

##	性能
QYHRetainCycleDetector本质上是一个测试工具，虽然尽可能做了优化，但通过遍历对象引用链仍是耗时操作，不建议在生产环境中使用。



