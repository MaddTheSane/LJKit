//
//  LJColor.h
//  LJKit
//
//  Created by C.W. Betts on 6/17/15.
//
//

#import <Foundation/Foundation.h>
#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#define LJColor UIColor
#else
#import <Cocoa/Cocoa.h>
#define LJColor NSColor
#endif

typedef LJColor *LJColorRef;
