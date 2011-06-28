//
//  CKBezierPath+Additions.h
//  CrimsonKit
//
//  Created by Waqar Malik on 3/8/10.
//  © Copyright 2008 Crimson Research, Inc. All rights reserved.
//

#import "CKBezierPath.h"

@interface CKBezierPath (Additions)
+ (CKBezierPath *)bezierPathWithRoundedRect:(CGRect)rect xRadius:(CGFloat)xRadius yRadius:(CGFloat)yRadius NS_RETURNS_NOT_RETAINED;

- (void)lineToPoint:(CGPoint)point CLANG_ANALYZER_NORETURN;
- (void)relativeMoveToPoint:(CGPoint)point CLANG_ANALYZER_NORETURN;
- (void)relativeLineToPoint:(CGPoint)point CLANG_ANALYZER_NORETURN;
- (void)curveToPoint:(CGPoint)endPoint controlPoint1:(CGPoint)controlPoint1 controlPoint2:(CGPoint)controlPoint2 CLANG_ANALYZER_NORETURN;
- (void)addRelativeCurveToPoint:(CGPoint)point controlPoint1:(CGPoint)cp1 controlPoint2:(CGPoint)cp2 CLANG_ANALYZER_NORETURN;
- (void)appendCGPath:(CGPathRef)cgPath CLANG_ANALYZER_NORETURN;

- (void)appendBezierPath:(CKBezierPath *)path CLANG_ANALYZER_NORETURN;
- (void)appendBezierPathWithArcFromPoint:(CGPoint)fromPoint toPoint:(CGPoint)toPoint radius:(CGFloat)radius CLANG_ANALYZER_NORETURN;
- (void)appendBezierPathWithArcWithCenter:(CGPoint)center radius:(CGFloat)radius startAngle:(CGFloat)startAngle endAngle:(CGFloat)endAngle CLANG_ANALYZER_NORETURN;
- (void)appendBezierPathWithPoints:(CGPoint *)points count:(NSInteger)count CLANG_ANALYZER_NORETURN;
- (void)appendBezierPathWithRoundedRect:(CGRect)rect xRadius:(CGFloat)xRadius yRadius:(CGFloat)yRadius CLANG_ANALYZER_NORETURN;

+ (void)fillRect:(CGRect)rect CLANG_ANALYZER_NORETURN;
+ (void)strokeRect:(CGRect)rect CLANG_ANALYZER_NORETURN;
+ (void)strokeLineFromPoint:(CGPoint)point1 toPoint:(CGPoint)point2 CLANG_ANALYZER_NORETURN;
+ (void)clipRect:(CGRect)rect CLANG_ANALYZER_NORETURN;

- (void)appendBezierPathWithRoundedRect:(CGRect)rect cornerRadius:(CGFloat)cornerRadius CLANG_ANALYZER_NORETURN;
@end
