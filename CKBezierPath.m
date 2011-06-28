//
//  CKBezierPath.m
//  CrimsonKit
//
//  Created by Waqar Malik on 2/7/10.
//  © Copyright 2008 Crimson Research, Inc. All rights reserved.
//

#import "CKBezierPath.h"

NSString *const CKBezierPathKey = @"CKBezierPath";
NSString *const CKBezierPathFlatnessKey = @"CKBezierPathFlatness";
NSString *const CKBezierPathLineWidthKey = @"CKBezierPathLineWidth";
NSString *const CKBezierPathMiterLimitKey = @"CKBezierPathMiterLimit";
NSString *const CKBezierPathLineCapStyleKey = @"CKBezierPathLineCapStyle";
NSString *const CKBezierPathLineJoinStyleKey = @"CKBezierPathLineJoinStyle";
NSString *const CKBezierPathEvenOddFillRuleKey = @"CKBezierPathUsesEvenOddFillRule";
NSString *const CKBezierPathDashCountKey = @"CKBezierPathDashCount";
NSString *const CKBezierPathDashPhaseKey = @"CKBezierPathDashPhase";
NSString *const CKBezierPathDashPatternKey = @"CKBezierPathDashPattern";
NSString *const CKBezierPathElementTypeKey = @"CKBezierPathElementType";
NSString *const CKBezierPathPoint0Key = @"point0";
NSString *const CKBezierPathPoint1Key = @"point1";
NSString *const CKBezierPathPoint2Key = @"point2";

#if __MAC_OS_X_VERSION_MIN_REQUIRED
CGPoint CGPointFromString(NSString *encodedString)
{
    CGPoint point = CGPointZero;
    char left, comma, right;
    sscanf([encodedString UTF8String], "%c%f%c %f%c", &left, &point.x, &comma, &point.y, &right);
    
    return point;
}
#endif

@interface CKBezierPath (Private)
- (void)_setDefaults CLANG_ANALYZER_NORETURN;
@end

typedef struct
{
	CGMutablePathRef path;
	const CGAffineTransform	m;
} CKBezierTransform;

static void CKBezierPathTransformer(void *infoRecord, const CGPathElement *element)
{
	CKBezierTransform *info = infoRecord;
	CGMutablePathRef path = info->path;
    
	switch(element->type)
	{
		case kCGPathElementMoveToPoint:
			CGPathMoveToPoint(path, &info->m, element->points[0].x, element->points[0].y);
			break;
		case kCGPathElementAddLineToPoint:
			CGPathAddLineToPoint(path, &info->m, element->points[0].x, element->points[0].y);
			break;
		case kCGPathElementAddQuadCurveToPoint:
			CGPathAddQuadCurveToPoint(path, &info->m, element->points[0].x, element->points[0].y, element->points[1].x, element->points[1].y);
			break;
		case kCGPathElementAddCurveToPoint:
			CGPathAddCurveToPoint(path, &info->m, element->points[0].x, element->points[0].y, element->points[1].x, element->points[1].y, element->points[2].x, element->points[2].y);			
			break;
		case kCGPathElementCloseSubpath:
			CGPathCloseSubpath(path);
			break;
	}
}

static void CKBezierPathEncoder(void *infoRecord, const CGPathElement *element)
{
	NSMutableArray *elements = (NSMutableArray *)infoRecord;
    NSMutableDictionary *item = [NSMutableDictionary dictionary];
    [item setObject:[NSNumber numberWithInteger:element->type] forKey:CKBezierPathElementTypeKey];
    
    switch(element->type)
	{
        case kCGPathElementAddCurveToPoint:
            [item setObject:NSStringFromCGPoint(element->points[2]) forKey:CKBezierPathPoint2Key];
        case kCGPathElementAddQuadCurveToPoint:
            [item setObject:NSStringFromCGPoint(element->points[1]) forKey:CKBezierPathPoint1Key];            
		case kCGPathElementMoveToPoint:
		case kCGPathElementAddLineToPoint:
            [item setObject:NSStringFromCGPoint(element->points[0]) forKey:CKBezierPathPoint0Key];
			break;
        default:
            break;
	}
    
    [elements addObject:item];
}

@implementation CKBezierPath

@dynamic bounds;
@dynamic currentPoint;
@dynamic empty;
@dynamic CGPath;

@synthesize flatness = _flatness;
@synthesize lineWidth = _lineWidth;
@synthesize miterLimit = _miterLimit;
@synthesize lineCapStyle = _lineCapStyle;
@synthesize lineJoinStyle = _lineJoinStyle;
@synthesize usesEvenOddFillRule = _usesEvenOddFillRule;

#pragma mark -
#pragma mark Object LifeCycle

- (id)init
{
    if(nil != (self = [super init]))
    {
        _cgPath = CGPathCreateMutable();
        [self _setDefaults];
    }
    
    return self;
}

- (void)dealloc
{
    if(NULL != _cgPath)
    {
        CGPathRelease(_cgPath), _cgPath = NULL;
    }
    
    if(NULL != _dashPattern)
    {
        NSZoneFree(NULL, _dashPattern), _dashPattern = NULL;
    }
    
    [super dealloc];
}

#pragma mark -
#pragma mark NSCoding Protocol
- (id)initWithCoder:(NSCoder *)coder
{
    if(nil != (self = [super init]))
    {
        _cgPath = CGPathCreateMutable();
        [self _setDefaults];
        NSArray *elements = [coder decodeObjectForKey:CKBezierPathKey];
        _flatness = [coder decodeFloatForKey:CKBezierPathFlatnessKey];
        _lineWidth = [coder decodeFloatForKey:CKBezierPathLineWidthKey];
        _miterLimit = [coder decodeFloatForKey:CKBezierPathMiterLimitKey];
        _lineCapStyle = (CGLineCap)[coder decodeIntForKey:CKBezierPathLineCapStyleKey];
        _lineJoinStyle = (CGLineJoin)[coder decodeIntForKey:CKBezierPathLineJoinStyleKey];
        _usesEvenOddFillRule = [coder decodeBoolForKey:CKBezierPathEvenOddFillRuleKey];
        
        for(NSDictionary *element in elements)
        {
            CGPathElementType elementType = (CGPathElementType)[[element objectForKey:CKBezierPathElementTypeKey] integerValue];
            CGPoint point = CGPointFromString([element objectForKey:CKBezierPathPoint0Key]), point1 = CGPointZero, point2 = CGPointZero;
            switch(elementType)
            {
                case kCGPathElementMoveToPoint:
                    [self moveToPoint:point];
                    break;
                case kCGPathElementAddLineToPoint:
                    [self addLineToPoint:point];
                    break;
                case kCGPathElementAddQuadCurveToPoint:
                    point1 = CGPointFromString([element objectForKey:CKBezierPathPoint1Key]);
                    [self addQuadCurveToPoint:point1 controlPoint:point];
                    break;
                case kCGPathElementAddCurveToPoint:
                    point1 = CGPointFromString([element objectForKey:CKBezierPathPoint1Key]);
                    point2 = CGPointFromString([element objectForKey:CKBezierPathPoint2Key]);
                    [self addCurveToPoint:point2 controlPoint1:point controlPoint2:point1];
                    break;
                case kCGPathElementCloseSubpath:
                    [self closePath];
                    break;
            }
        }
        
        if(_dashCount > 0)
        {
            NSInteger count = [coder decodeIntForKey:CKBezierPathDashCountKey];
            CGFloat phase = [coder decodeFloatForKey:CKBezierPathDashPhaseKey];

            NSArray *values = [coder decodeObjectForKey:CKBezierPathDashPatternKey];
            CGFloat *pattern = NSZoneMalloc(NULL, (size_t)count * sizeof(CGFloat));
            NSInteger i = 0;
            for(NSNumber *number in values)
            {
                pattern[i++] = [number floatValue];
            }
            [self setLineDash:pattern count:count phase:phase];
            NSZoneFree(NULL, pattern), pattern = NULL;
        }
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    NSMutableArray *array = [[NSMutableArray array] retain];
    CGPathApply(_cgPath, array, CKBezierPathEncoder);
    [coder encodeObject:array forKey:CKBezierPathKey];
    [coder encodeFloat:_flatness forKey:CKBezierPathFlatnessKey];
    [coder encodeFloat:_lineWidth forKey:CKBezierPathLineWidthKey];
    [coder encodeFloat:_miterLimit forKey:CKBezierPathMiterLimitKey];
    [coder encodeInt:_lineCapStyle forKey:CKBezierPathLineCapStyleKey];
    [coder encodeInt:_lineJoinStyle forKey:CKBezierPathLineJoinStyleKey];
    [coder encodeBool:_usesEvenOddFillRule forKey:CKBezierPathEvenOddFillRuleKey];
    [array release], array = nil;
    
    if(_dashCount > 0)
    {
        [coder encodeInt:_dashCount forKey:CKBezierPathDashCountKey];
        [coder encodeFloat:_dashPhase forKey:CKBezierPathDashPhaseKey];
        
        NSMutableArray *values = [NSMutableArray arrayWithCapacity:(NSUInteger)_dashCount];
        NSInteger i = 0;
        for(i = 0; i < _dashCount; i++)
        {
            [values addObject:[NSNumber numberWithFloat:_dashPattern[i]]];
        }
        [coder encodeObject:values forKey:CKBezierPathDashPatternKey];
    }
}

#pragma mark -
#pragma mark NSCopying Protocol
- (id)copyWithZone:(NSZone *)zone
{
    CKBezierPath *path = [[CKBezierPath allocWithZone:zone] init];
    path.CGPath = _cgPath;
    path.flatness = _flatness;
    path.lineCapStyle = _lineCapStyle;
    path.lineJoinStyle = _lineJoinStyle;
    path.lineWidth = _lineWidth;
    path.miterLimit = _miterLimit;
    path.usesEvenOddFillRule = _usesEvenOddFillRule;
    if(_dashCount > 0)
    {
        [path setLineDash:_dashPattern count:_dashCount phase:_dashPhase];
    }
    return path;
}

    // Creating a CKBezierPath Object
+ (CKBezierPath *)bezierPath
{
    return [[[self class] new] autorelease];
}

+ (CKBezierPath *)bezierPathWithRect:(CGRect)rect
{
    CKBezierPath *bezierPath = [[self class] new];
    [bezierPath appendBezierPathWithRect:rect];
    
    return [bezierPath autorelease];
}

+ (CKBezierPath *)bezierPathWithOvalInRect:(CGRect)rect
{
    CKBezierPath *bezierPath = [[self class] new];
    [bezierPath appendBezierPathWithOvalInRect:rect];
    
    return [bezierPath autorelease];
}

+ (CKBezierPath *)bezierPathWithRoundedRect:(CGRect)rect cornerRadius:(CGFloat)cornerRadius
{
    CKBezierPath *bezierPath = [[self class] new];
    [bezierPath appendBezierPathWithRoundedRect:rect byRoundingCorners:CKRectCornerAllCorners cornerRadii:CGSizeMake(cornerRadius, cornerRadius)];

    return [bezierPath autorelease];
}

+ (CKBezierPath *)bezierPathWithRoundedRect:(CGRect)rect byRoundingCorners:(CKRectCorner)corners cornerRadii:(CGSize)cornerRadii
{
    CKBezierPath *bezierPath = [[self class] new];
    [bezierPath appendBezierPathWithRoundedRect:rect byRoundingCorners:corners cornerRadii:cornerRadii];
    
    return [bezierPath autorelease];    
}

+ (CKBezierPath *)bezierPathWithArcCenter:(CGPoint)center radius:(CGFloat)radius startAngle:(CGFloat)startAngle endAngle:(CGFloat)endAngle clockwise:(BOOL)clockwise
{
    CKBezierPath *bezierPath = [[self class] new];
    [bezierPath addArcWithCenter:center radius:radius startAngle:startAngle endAngle:endAngle clockwise:clockwise];
    
    return [bezierPath autorelease];
}

+ (CKBezierPath *)bezierPathWithCGPath:(CGPathRef)cgPath
{
    CKBezierPath *path = [[self class] new];
    path.CGPath = cgPath;
    return [path autorelease];
}

#pragma mark -
#pragma mark Properties
- (CGRect)bounds
{
    return CGPathGetBoundingBox(_cgPath);
}

- (CGPoint)currentPoint
{
    return CGPathGetCurrentPoint(_cgPath);
}

- (BOOL)isEmpty
{
    return CGPathIsEmpty(_cgPath);
}

- (CGPathRef)CGPath
{
    return _cgPath;
}

- (void)setCGPath:(CGPathRef)path
{
    assert(NULL != path && "Null Path");
    CGPathRelease(_cgPath);
    _cgPath = CGPathCreateMutableCopy(path);
}

- (void)appendBezierPathWithRect:(CGRect)rect
{
    CGPathAddRect(_cgPath, &_transform, rect);
}

- (void)appendBezierPathWithOvalInRect:(CGRect)rect
{
    CGPathAddEllipseInRect(_cgPath, &_transform, rect);
}

- (void)appendBezierPathWithRoundedRect:(CGRect)rect byRoundingCorners:(CKRectCorner)corners cornerRadii:(CGSize)cornerRadii
{
    if(CGRectEqualToRect(rect, CGRectZero))
    {
        return;
    }
    
        // clamp down the x radius to the mid of the rect.
    if(CGRectGetWidth(rect)/2.0f < cornerRadii.width)
    {
        cornerRadii.width = CGRectGetWidth(rect)/2.0f;
    }
    
    if(CGRectGetHeight(rect)/2.0f < cornerRadii.height)
    {
        cornerRadii.height = CGRectGetHeight(rect)/2.0f;
    }
    
        // if either of the radius is no positive we just add a rect.
    if(0 >= cornerRadii.width || 0 >= cornerRadii.height)
    {
        CGPathAddRect(_cgPath, &_transform, rect);
        return;
    }
        
    CGMutablePathRef path = CGPathCreateMutable();
    
    CGFloat minX = CGRectGetMinX(rect), maxX = CGRectGetMaxX(rect), minY = CGRectGetMinY(rect), maxY = CGRectGetMaxY(rect);
    if(corners & CKRectCornerTopLeft)
    {
        CGPathMoveToPoint(path, &_transform, minX+cornerRadii.width, minY);
        CGPathAddQuadCurveToPoint(path, &_transform, minX, minY, minX, minY+cornerRadii.height);
    } else {
        CGPathMoveToPoint(path, &_transform, minX, minY);
    }
    
    if(corners & CKRectCornerBottomLeft)
    {
        CGPathAddLineToPoint(path, &_transform, minX, maxY-cornerRadii.height);
        CGPathAddQuadCurveToPoint(path, &_transform, minX, maxY, minX+cornerRadii.width, maxY);
    } else {
        CGPathAddLineToPoint(path, &_transform, minX, maxY);
    }
    
    if(corners & CKRectCornerBottomRight)
    {
        CGPathAddLineToPoint(path, &_transform, maxX-cornerRadii.width, maxY);
        CGPathAddQuadCurveToPoint(path, &_transform, maxX, maxY, maxX, maxY-cornerRadii.height);
    } else {
        CGPathAddLineToPoint(path, &_transform, maxX, maxY);
    }
    
    if(corners & CKRectCornerTopRight)
    {
        CGPathAddLineToPoint(path, &_transform, maxX, minY+cornerRadii.height);
        CGPathAddQuadCurveToPoint(path, &_transform, maxX, minY, maxX-cornerRadii.width, minY);
    } else {
        CGPathAddLineToPoint(path, &_transform, maxX, minY);
    }
    
    CGPathCloseSubpath(path);
    
    CGPathAddPath(_cgPath, &_transform, path);
    CGPathRelease(path), path = NULL;
}

    // Constructing a Path
- (void)moveToPoint:(CGPoint)point
{
    CGPathMoveToPoint(_cgPath, &_transform, point.x, point.y);
}

- (void)addLineToPoint:(CGPoint)point
{
    CGPathAddLineToPoint(_cgPath, &_transform, point.x, point.y);
}

- (void)addCurveToPoint:(CGPoint)endPoint controlPoint1:(CGPoint)controlPoint1 controlPoint2:(CGPoint)controlPoint2
{
    CGPathAddCurveToPoint(_cgPath, &_transform, controlPoint1.x, controlPoint1.y, controlPoint2.x, controlPoint2.y, endPoint.x, endPoint.y);
}

- (void)addQuadCurveToPoint:(CGPoint)endPoint controlPoint:(CGPoint)controlPoint
{
    CGPathAddQuadCurveToPoint(_cgPath, &_transform, controlPoint.x, controlPoint.y, endPoint.x, endPoint.y);
}

- (void)addArcWithCenter:(CGPoint)center radius:(CGFloat)radius startAngle:(CGFloat)startAngle endAngle:(CGFloat)endAngle clockwise:(BOOL)clockwise
{
    CGPathAddArc(_cgPath, &_transform, center.x, center.y, radius, startAngle, endAngle, clockwise);	
}

- (void)closePath
{
    CGPathCloseSubpath(_cgPath);
}

- (void)removeAllPoints
{
    CGPathRelease(_cgPath);
    _cgPath = CGPathCreateMutable();
}

- (void)appendPath:(CKBezierPath *)bezierPath
{
    CGPathAddPath(_cgPath, &_transform, bezierPath.CGPath);
}

    // Accessing Drawing Properties
- (void)setLineDash:(const CGFloat *)pattern count:(NSInteger)count phase:(CGFloat)phase
{
    if(NULL != _dashPattern)
    {
        free(_dashPattern);
    }
    
    _dashCount = count;
    _dashPhase = phase;
    _dashPattern = NSZoneMalloc(NULL, (size_t)_dashCount * sizeof(CGFloat));
    memcpy(_dashPattern, pattern, sizeof(CGFloat) * (size_t)_dashCount);
    CGContextRef context = CKGraphicsGetCurrentContext();
    CGContextSetLineDash(context, _dashPhase, _dashPattern, (size_t)_dashCount);
}

- (void)getLineDash:(CGFloat *)pattern count:(NSInteger *)count phase:(CGFloat *)phase
{
    *count = _dashCount;
    *phase = _dashPhase;
    
    memcpy(pattern, _dashPattern, sizeof(CGFloat) * (size_t)_dashCount);
}

    // Drawing Paths
- (void)fill
{
    CGContextRef context = CKGraphicsGetCurrentContext();
    CGContextAddPath(context, _cgPath);
    CGContextDrawPath(context, _usesEvenOddFillRule ? kCGPathEOFill : kCGPathFill);
}

- (void)fillWithBlendMode:(CGBlendMode)blendMode alpha:(CGFloat)alpha
{
    CGContextRef context = CKGraphicsGetCurrentContext();
    CGContextSetBlendMode(context, blendMode);
    CGContextSetAlpha(context, alpha);
    CGContextAddPath(context, _cgPath);
    CGContextDrawPath(context, _usesEvenOddFillRule ? kCGPathEOFill : kCGPathFill);
}

- (void)stroke
{
    CGContextRef context = CKGraphicsGetCurrentContext();
    CGContextSaveGState(context);
    CGContextSetLineWidth(context, self.lineWidth);
    CGContextSetMiterLimit(context, self.miterLimit);
    CGContextSetFlatness(context, self.flatness);
    CGContextSetLineCap(context, self.lineCapStyle);
    CGContextSetLineJoin(context, self.lineJoinStyle);
    CGContextAddPath(context, _cgPath);
    CGContextDrawPath(context, kCGPathStroke);
    CGContextRestoreGState(context);   
}

- (void)strokeWithBlendMode:(CGBlendMode)blendMode alpha:(CGFloat)alpha
{
    CGContextRef context = CKGraphicsGetCurrentContext();
    CGContextSaveGState(context);
    CGContextSetLineWidth(context, self.lineWidth);
    CGContextSetMiterLimit(context, self.miterLimit);
    CGContextSetFlatness(context, self.flatness);
    CGContextSetLineCap(context, self.lineCapStyle);
    CGContextSetLineJoin(context, self.lineJoinStyle);
    CGContextSetBlendMode(context, blendMode);
    CGContextSetAlpha(context, alpha);
    CGContextAddPath(context, _cgPath);
    CGContextDrawPath(context, kCGPathStroke);
    CGContextRestoreGState(context);   
}

    // Clipping Paths
- (void)addClip
{
    CGContextRef context = CKGraphicsGetCurrentContext();
    CGContextAddPath(context, _cgPath);
    _usesEvenOddFillRule ? CGContextEOClip(context) : CGContextClip(context);
}

    // Hit Detection
- (BOOL)containsPoint:(CGPoint)point
{
    return CGPathContainsPoint(_cgPath, &_transform, point, _usesEvenOddFillRule);
}

    // Applying Tranformations
- (void)applyTransform:(CGAffineTransform)transform
{
	CKBezierTransform rec = {CGPathCreateMutable(), transform};
	CGPathApply(_cgPath, &rec, CKBezierPathTransformer);
    self.CGPath = rec.path;
    CGPathRelease(rec.path);
}
@end

@implementation CKBezierPath (Private)
- (void)_setDefaults
{
    _flatness = 0.6f;
    _lineWidth = 1.0f;
    _miterLimit = 10.0f;
    _lineCapStyle = kCGLineCapButt;
    _lineJoinStyle = kCGLineJoinMiter;
    _usesEvenOddFillRule = NO;
    _transform = CGAffineTransformIdentity;
    _dashPattern = NULL;
    _dashCount = 0;
    _dashPhase = 0.0f;
}
@end
