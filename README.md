# TestRACSubscriber
RACSubscriber在订阅中的生命周期

[这一篇](https://blog.csdn.net/jianghui12138/article/details/81949326)分析过 `RACScriber` 的生命周期，今天发现了一个新的问题，重新分析下在耗时操作中 `RACScriber` 的声明周期。

下面的完整测试用例在[这里](https://github.com/jianghui1/TestRACSubscriber)。

先看下正常情况信号订阅的例子：

    - (void)test1
    {
        RACSignal *signal = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
            [subscriber sendNext:nil];
            [subscriber sendCompleted];
            
            return [RACDisposable disposableWithBlock:^{
                NSLog(@"结束了");
            }];
        }];
        
        [signal subscribeNext:^(id x) {
            NSLog(@"test1 -- %@", x);
        }];
        
        // 打印日志
        /*
         2018-11-14 18:22:26.925204+0800 TestRACSubscriber[7055:2380811] test1 -- (null)
         2018-11-14 18:22:26.925453+0800 TestRACSubscriber[7055:2380811] 结束了
         */
    }
    
这样子并没有什么问题，信号正常订阅，正常结束。

但是，一般 app 中都会使用网络请求，就会出现耗时的操作，所以，再看下耗时情况下的例子：

    - (void)test2
    {
        RACSignal *signal = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
            
            [[RACScheduler mainThreadScheduler] afterDelay:0.3 schedule:^{
                
                [subscriber sendNext:nil];
                [subscriber sendCompleted];
            }];
            
            return [RACDisposable disposableWithBlock:^{
                NSLog(@"结束了");
            }];
        }];
        
        [signal subscribeNext:^(id x) {
            NSLog(@"test2 -- %@", x);
        }];
        
        [[RACSignal never] asynchronouslyWaitUntilCompleted:nil];
        
        // 打印日志
        /*
         2018-11-14 18:25:56.233875+0800 TestRACSubscriber[7201:2383360] test2 -- (null)
         2018-11-14 18:25:56.234550+0800 TestRACSubscriber[7201:2383360] 结束了
         */
    }
    
这时，使用了延时模拟了网络请求的耗时操作，并对这个操作对应的清理对象做处理。这样跟正常使用网络请求是一样的。查看结果，一切正常。

接着，对上面例子继续改造：

    - (void)test3
    {
        RACSignal *signal = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
            
            RACDisposable *d = [[RACScheduler mainThreadScheduler] afterDelay:0.3 schedule:^{
                
                NSLog(@"test3 -- xxx");
            }];
            
            return [RACDisposable disposableWithBlock:^{
                NSLog(@"结束了");
                [d dispose];
            }];
        }];
        
        [signal subscribeNext:^(id x) {
            NSLog(@"test3 -- %@", x);
        }];
        
        [[RACSignal never] asynchronouslyWaitUntilCompleted:nil];
        
        // 打印日志
        /*
         2018-11-14 18:33:02.400545+0800 TestRACSubscriber[7474:2387962] 结束了
         */
    }
    
同样是使用延时模拟网络请求的耗时操作，不过并没有对结果进行发送。这个时候，延时操作并没有最终执行，相当于网络请求被取消了。为什么呢？延时操作不执行，就是被清理了，证明代码执行了 `[d dispose];` ，也就是订阅过程结束了。之前文章说过，`RACSubscriber` 负责信号的分发，所以这里 `RACSubscriber` 已经释放了。为什么会释放呢？之前文章也说了，`RACSubscriber` 是作为局部变量存在的，所以会释放。那么有人就要说了，第二个例子为何不释放呢？别急，再看下例子：

    - (void)test4
    {
        RACSignal *signal = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
            
            RACDisposable *d = [[RACScheduler mainThreadScheduler] afterDelay:0.3 schedule:^{
                
                NSLog(@"test4 -- xxx -- %@", subscriber);
            }];
            
            return [RACDisposable disposableWithBlock:^{
                NSLog(@"结束了");
                [d dispose];
            }];
        }];
        
        [signal subscribeNext:^(id x) {
            NSLog(@"test4 -- %@", x);
        }];
        
        [[RACSignal never] asynchronouslyWaitUntilCompleted:nil];
        
        // 打印日志
        /*
         2018-11-14 18:39:51.437398+0800 TestRACSubscriber[7715:2391572] test4 -- xxx -- <RACPassthroughSubscriber: 0x600000f6f7a0>
         2018-11-14 18:39:51.437689+0800 TestRACSubscriber[7715:2391572] 结束了
         */
    }
    
延时操作又执行了。到这里，就可以知道问题了。正常的信号订阅，`RACSubscriber` 作为局部变量没错，被释放也没错，但是这里 `subscriber` 作为变量被延时操作的 block 引用了，所以就不会立即释放了，只有延时正常结束才释放，所以延时操作就能够正常执行了。对于 app 中，也就是网络请求可以正常请求了。

其实，如果你创建信号的时候，不通过 `subscriber` 做任何事情的话，那跟创建一个 `never` 信号没有什么差别。

当然，如果按照信号的标准创建的话，一定不会有问题，因为你必定会通过 `subscriber` 发送 `sendError:` 或者 `sendCompleted` 事件，这时耗时操作中就会对 `subscriber` 引用，就不会过早释放了。

