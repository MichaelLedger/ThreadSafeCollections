//
//  main.m
//  ThreadSafeDemo
//
//  Created by Gavin Xiang on 2021/12/1.
//

/*
 https://developer.apple.com/library/archive/technotes/tn2002/tn2059.html
 [Using collection classes safely with multithreaded applications]
 */

#import <Foundation/Foundation.h>
#import "ThreadSafeMutableDictionary.h"

////////////////////////////////////////////////////////////////
////    TEST PROGRAM
////////////////////////////////////////////////////////////////

static NSMutableDictionary    *aDictionary = nil;
//static NSLock                *aDictionaryLock = nil;

@implementation NSMutableDictionary (Churning)

#define KEY        @"key"
#define COUNT      10000

- (void) churnContents;
{
    unsigned long    i;

    for (i = 0; i < COUNT ; i++)
    {
        NSAutoreleasePool    *pool;

        pool = [[NSAutoreleasePool alloc] init];

//        [aDictionaryLock lock];
        [self setObject: [NSString stringWithFormat: @"%lu", i]  forKey: KEY];
        NSLog(@"%@", self);
//        [aDictionaryLock unlock];

        [pool release];
    }
}

@end

static inline void doGets (void)
{
    long    i;

    for (i = 0; i < COUNT; i++)
    {
        NSObject    *anObject;

        //    Get the dictionary's value, and then try to message the value.
//        [aDictionaryLock lock];
        anObject = [aDictionary objectForKey: KEY];
//        [[anObject retain] autorelease];
//        [aDictionaryLock unlock];

        [anObject release];
        [anObject description];
    }
}

static inline void doSets (void)
{
    long    i;

    for (i = 0; i < COUNT; i++)
    {
        NSObject    *anObject;

        anObject = [[NSObject alloc] init];

//        [aDictionaryLock lock];
        [aDictionary setObject: anObject  forKey: KEY];
//        [anObject autorelease];
//        [aDictionaryLock unlock];
        
        [anObject release];
        [anObject description];
    }
}

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        SEL        threadSelector;

        threadSelector = @selector(churnContents);

#warning Crash when using NSMutableDictionary:EXC_BAD_ACCESS (code=1, address=0x0)
//        aDictionary = [NSMutableDictionary dictionary];
        aDictionary = [ThreadSafeMutableDictionary dictionary];
//        aDictionaryLock = [[NSLock alloc] init];

        //    Start the dictionary "churning", repeatedly replacing the
        //    sole value with a new one under the same key.
        [NSThread detachNewThreadSelector: threadSelector
                    toTarget: aDictionary
                    withObject: nil];

        doGets();
        doSets();
        
        sleep(3);// keep main thread alive
        
        aDictionary = nil;
    }
    return 0;
}
