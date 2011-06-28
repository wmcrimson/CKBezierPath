#CrimsonKit

CrimsonKit is licensed under the terms of the Attribution License.  Copyright &copy; 2010-2011, Waqar Malik.

    CKBezierPath *path = [CKBezierPath bezierPathWithRoundedRect:CGRectInset(rect, 20.0f, 20.0f) cornerRadius:20.0f];
    [path appendPath:[CKBezierPath bezierPathWithOvalInRect:CGRectInset(rect, 30.0f, 30.0f)]];
    [path appendBezierPathWithRect:CGRectInset(rect, 60.0f, 40.0f)];
    path.lineWidth = 3.0f;
    path.usesEvenOddFillRule = NO;
    [[UIColor yellowColor] setFill];
    [[UIColor blueColor] setStroke];
    [path fill];
    [path stroke];

<center>
<img src="https://github.com/wmalloc/CrimsonKit/raw/master/CKPath.png" />
</center>
