//
//  CKBezierPath+Additions.m
//  CrimsonKit
//
//  Created by Waqar Malik on 3/8/10.
//  © Copyright 2008 Crimson Research, Inc. All rights reserved.
//

#import "CKBezierPath.h"
#import "CKBezierPath+Additions.h"

@implementation CKBezierPath (Additions)
+ (CKBezierPath *)bezierPathWithRoundedRect:(CGRect)rect xRadius:(CGFloat)xRadius yRadius:(CGFloat)yRadius
{
    CGSize cornerRadii = CGSizeMake(xRadius, yRadius);
    return [CKBezierPath bezierPathWithRoundedRect:rect byRoundingCorners:CKRectCornerAllCorners cornerRadii:cornerRadii];
}

- (void)lineToPoint:(CGPoint)point
{
    [self addLineToPoint:point];
}

- (void)relativeMoveToPoint:(CGPoint)point
{
    CGPoint current = self.currentPoint;
    
    point.x+=current.x;
    point.y+=current.y;
    
    [self moveToPoint:point];
}

- (void)relativeLineToPoint:(CGPoint)point
{
    CGPoint current = self.currentPoint;
    
    point.x+=current.x;
    point.y+=current.y;
    
    [self addLineToPoint:point];    
}

- (void)curveToPoint:(CGPoint)endPoint controlPoint1:(CGPoint)controlPoint1 controlPoint2:(CGPoint)controlPoint2
{
    [self addCurveToPoint:endPoint controlPoint1:controlPoint1 controlPoint2:controlPoint2];
}

- (void)addRelativeCurveToPoint:(CGPoint)point controlPoint1:(CGPoint)cp1 controlPoint2:(CGPoint)cp2
{
    CGPoint current = self.currentPoint;
    
    cp1.x+=current.x;
    cp1.y+=current.y;
    cp2.x+=current.x;
    cp2.y+=current.y;
    point.x+=current.x;
    point.y+=current.y;
    
    [self addCurveToPoint:point controlPoint1:cp1 controlPoint2:cp2];
}

- (void)appendCGPath:(CGPathRef)cgPath
{
    CGPathAddPath(_cgPath, &_transform, cgPath);
}

- (void)appendBezierPath:(CKBezierPath *)path
{
    [self appendPath:path];
}

- (void)appendBezierPathWithArcFromPoint:(CGPoint)fromPoint toPoint:(CGPoint)toPoint radius:(CGFloat)radius
{
    CGPathAddArcToPoint(_cgPath, &_transform, fromPoint.x, fromPoint.y, toPoint.x, toPoint.y, radius);
}

- (void)appendBezierPathWithArcWithCenter:(CGPoint)center radius:(CGFloat)radius startAngle:(CGFloat)startAngle endAngle:(CGFloat)endAngle
{
    [self addArcWithCenter:center radius:radius startAngle:startAngle endAngle:endAngle clockwise:NO];
}

- (void)appendBezierPathWithPoints:(CGPoint *)points count:(NSInteger)count
{
    CGPathAddLines(_cgPath, &_transform, points, (size_t)count);
}

- (void)appendBezierPathWithRoundedRect:(CGRect)rect xRadius:(CGFloat)xRadius yRadius:(CGFloat)yRadius
{
    CGSize cornerRadii = CGSizeMake(xRadius, yRadius);
    [self appendBezierPathWithRoundedRect:rect byRoundingCorners:CKRectCornerAllCorners cornerRadii:cornerRadii];
}

+ (void)fillRect:(CGRect)rect
{
    CGContextRef context = CKGraphicsGetCurrentContext();
    CGContextFillRect(context, rect);
}

+ (void)strokeRect:(CGRect)rect
{
    CGContextRef context = CKGraphicsGetCurrentContext();
    CGContextStrokeRect(context, rect);
}

+ (void)strokeLineFromPoint:(CGPoint)point1 toPoint:(CGPoint)point2
{
    CGContextRef context = CKGraphicsGetCurrentContext();
    CGContextMoveToPoint(context, point1.x, point1.y);
    CGContextAddLineToPoint(context, point2.x, point2.x);
    CGContextDrawPath(context, kCGPathStroke);
}

+ (void)clipRect:(CGRect)rect
{
    CGContextRef context = CKGraphicsGetCurrentContext();
    CGContextAddRect(context, rect);
    CGContextClip(context);
}

- (void)appendBezierPathWithRoundedRect:(CGRect)rect cornerRadius:(CGFloat)cornerRadius
{
    [self appendBezierPathWithRoundedRect:rect byRoundingCorners:CKRectCornerAllCorners cornerRadii:CGSizeMake(cornerRadius, cornerRadius)];
}
@end
