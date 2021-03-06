//
//  FSCalendarCell.m
//  Pods
//
//  Created by Wenchao Ding on 12/3/15.
//
//

#import "FSCalendarCell.h"
#import "FSCalendar.h"
#import "UIView+FSExtension.h"
#import "FSCalendarDynamicHeader.h"
#import "FSCalendarConstance.h"

@interface FSCalendarCell ()

@property (readonly, nonatomic) UIColor *colorForCellFill;
@property (readonly, nonatomic) UIColor *colorForTitleLabel;
@property (readonly, nonatomic) UIColor *colorForSubtitleLabel;
@property (readonly, nonatomic) UIColor *colorForCellBorder;
@property (readonly, nonatomic) NSArray<UIColor *> *colorsForEvents;
@property (readonly, nonatomic) FSCalendarCellShape cellShape;

@end

@implementation FSCalendarCell

#pragma mark - Life cycle

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        _needsAdjustingViewFrame = YES;
    
        UILabel *label;
        CAShapeLayer *shapeLayer;
        CAShapeLayer *weekLineLayer;
        UIImageView *imageView;
        FSCalendarEventIndicator *eventIndicator;
        
        label = [[UILabel alloc] initWithFrame:CGRectZero];
        label.textAlignment = NSTextAlignmentCenter;
        label.textColor = [UIColor blackColor];
        [self.contentView addSubview:label];
        self.titleLabel = label;
        
        label = [[UILabel alloc] initWithFrame:CGRectZero];
        label.textAlignment = NSTextAlignmentCenter;
        label.textColor = [UIColor lightGrayColor];
        [self.contentView addSubview:label];
        self.subtitleLabel = label;
        
        shapeLayer = [CAShapeLayer layer];
        shapeLayer.backgroundColor = [UIColor clearColor].CGColor;
        shapeLayer.hidden = YES;
        [self.contentView.layer insertSublayer:shapeLayer below:_titleLabel.layer];
        self.shapeLayer = shapeLayer;
        
        weekLineLayer = [CAShapeLayer layer];
        weekLineLayer.backgroundColor = [UIColor clearColor].CGColor;
        
        [self.contentView.layer insertSublayer:weekLineLayer atIndex:0];
        self.weekLineLayer = weekLineLayer;
        
        eventIndicator = [[FSCalendarEventIndicator alloc] initWithFrame:CGRectZero];
        eventIndicator.backgroundColor = [UIColor clearColor];
        eventIndicator.hidden = YES;
        [self.contentView addSubview:eventIndicator];
        self.eventIndicator = eventIndicator;
        
        imageView = [[UIImageView alloc] initWithFrame:CGRectZero];
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        
        [self.contentView insertSubview:imageView belowSubview:self.titleLabel];
        self.imageView = imageView;
        
        self.clipsToBounds = NO;
        self.contentView.clipsToBounds = NO;
        
    }
    return self;
}

-(UIBezierPath *) weekLinePathForMode:(FSCalendarCellWeekLineMode) mode
{
    UIBezierPath *path;
    switch (mode) {
        case FSCalendarCellWeekLineModeLeft: {
            path = [UIBezierPath bezierPathWithRoundedRect:[self weekLinePathFrameForMode: mode]
                                               byRoundingCorners:UIRectCornerTopLeft|UIRectCornerBottomLeft
                                                     cornerRadii:CGSizeMake(self.contentView.fs_width / 2, self.contentView.fs_height / 2)];
            break;
        }
            
        case FSCalendarCellWeekLineModeMiddle:
            path = [UIBezierPath bezierPathWithRect:[self weekLinePathFrameForMode: mode]];
            break;
            
        case FSCalendarCellWeekLineModeRight:{
            path = [UIBezierPath bezierPathWithRoundedRect:[self weekLinePathFrameForMode: mode]
                                               byRoundingCorners:UIRectCornerTopRight|UIRectCornerBottomRight
                                                     cornerRadii:CGSizeMake(self.contentView.fs_width / 2, self.contentView.fs_height / 2)];
            break;
        }
    }

    return path;
}

-(CGRect)weekLinePathFrameForMode:(FSCalendarCellWeekLineMode) mode
{
    CGFloat offset = 5.0;
    CGRect frame = self.contentView.bounds;
    frame.size.width += 1;
    
    if (self.appearance.weekLineHeight == FSCalendarAutomaticDimension) {
        frame.size.height -= 8.0;
    }else {
        frame.size.height = self.appearance.weekLineHeight;
    }
    
    frame.origin.y = (self.contentView.fs_height*5.0/6.0-frame.size.height)*0.5;
    
    switch (mode) {
        case FSCalendarCellWeekLineModeLeft:
            frame.origin.x += offset;
            break;

        case FSCalendarCellWeekLineModeMiddle:
            break;
            
        case FSCalendarCellWeekLineModeRight:
            frame.origin.x -= offset;
            break;
    }
    
    return frame;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    [self configureCell];
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    _month = nil;
    _date = nil;
    [CATransaction setDisableActions:YES];
    _shapeLayer.hidden = YES;
    [self.contentView.layer removeAnimationForKey:@"opacity"];
}

#pragma mark - Public

- (void)performSelecting
{
    _shapeLayer.hidden = NO;
    
#define kAnimationDuration FSCalendarDefaultBounceAnimationDuration
    
    CAAnimationGroup *group = [CAAnimationGroup animation];
    CABasicAnimation *zoomOut = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    zoomOut.fromValue = @0.3;
    zoomOut.toValue = @1.2;
    zoomOut.duration = kAnimationDuration/4*3;
    CABasicAnimation *zoomIn = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    zoomIn.fromValue = @1.2;
    zoomIn.toValue = @1.0;
    zoomIn.beginTime = kAnimationDuration/4*3;
    zoomIn.duration = kAnimationDuration/4;
    group.duration = kAnimationDuration;
    group.animations = @[zoomOut, zoomIn];
    [_shapeLayer addAnimation:group forKey:@"bounce"];
    [self configureCell];
    
#undef kAnimationDuration
    
}

#pragma mark - Private

- (void)configureCell
{
    CGFloat titleHeight = self.bounds.size.height*5.0/6.0;
    CGFloat diameter = MIN(self.bounds.size.height*5.0/6.0,self.bounds.size.width);
    diameter = diameter > FSCalendarStandardCellDiameter ? (diameter - (diameter-FSCalendarStandardCellDiameter)*0.5) : diameter;
    diameter += 2;
    _shapeLayer.frame = CGRectMake((self.bounds.size.width-diameter)/2,
                                   (titleHeight-diameter)/2,
                                   diameter,
                                   diameter);
    _shapeLayer.borderWidth = 1.0;
    _shapeLayer.borderColor = [UIColor clearColor].CGColor;
    
    CGFloat eventSize = _shapeLayer.frame.size.height/6.0;
    _eventIndicator.frame = CGRectMake(0 + self.preferredEventOffset.x, CGRectGetMaxY(_shapeLayer.frame)+eventSize*0.17 + self.preferredEventOffset.y , self.contentView.bounds.size.width, eventSize*0.83);
    _eventIndicator.numberOfEvents = self.numberOfEvents;
    _eventIndicator.color = self.colorsForEvents;

    _imageView.frame = self.contentView.bounds;
    if (self.preferredImageSize.height > 0) {
        _imageView.fs_height = self.preferredImageSize.height;
    }
    
    if (self.preferredImageSize.width > 0) {
        _imageView.fs_width = self.preferredImageSize.width;
    }
    
    _imageView.center = CGPointMake(
                                    self.contentView.fs_width/2.0 + self.preferredImageOffset.x,
                                    _imageView.center.y + self.preferredImageOffset.y
                                    );

    if (self.dateIsPlaceholder) {
        if (self.calendar.placeholderType == FSCalendarPlaceholderTypeNone) {
            self.contentView.hidden = YES;
        } else if (self.calendar.placeholderType == FSCalendarPlaceholderTypeFillHeadTail && self.calendar.scope == FSCalendarScopeMonth && !self.calendar.floatingMode) {
            
            NSIndexPath *indexPath = [self.calendar.collectionView indexPathForCell:self];
            
            NSInteger lineCount = [self.calendar numberOfRowsInMonth:self.month];
            if (lineCount == 6) {
                self.contentView.hidden = NO;
            } else {
                NSInteger currentLine = 0;
                if (self.calendar.collectionViewLayout.scrollDirection == UICollectionViewScrollDirectionVertical) {
                    currentLine = indexPath.item/7 + 1;
                } else {
                    currentLine = indexPath.item%6 + 1;
                }
                self.contentView.hidden = (currentLine>lineCount);
            }
        }
    } else if (self.contentView.hidden) {
        self.needsAdjustingViewFrame = YES;
        self.contentView.hidden = NO;
    }
    
    if (self.contentView.hidden) return;
    
    _titleLabel.text = self.title ?: [NSString stringWithFormat:@"%@",@([_calendar dayOfDate:_date])];
    if (_subtitle) {
        _subtitleLabel.text = _subtitle;
        if (_subtitleLabel.hidden) {
            _subtitleLabel.hidden = NO;
        }
    } else {
        if (!_subtitleLabel.hidden) {
            _subtitleLabel.hidden = YES;
        }
    }
    if (_needsAdjustingViewFrame || CGSizeEqualToSize(_titleLabel.frame.size, CGSizeZero)) {
        _needsAdjustingViewFrame = NO;
        
        if (_subtitle) {
            CGFloat titleHeight = [@"1" sizeWithAttributes:@{NSFontAttributeName:_titleLabel.font}].height;
            CGFloat subtitleHeight = [@"1" sizeWithAttributes:@{NSFontAttributeName:_subtitleLabel.font}].height;
            
            CGFloat height = titleHeight + subtitleHeight;
            _titleLabel.frame = CGRectMake(
                                           self.preferredTitleOffset.x,
                                           (self.contentView.fs_height*5.0/6.0-height)*0.5+self.preferredTitleOffset.y,
                                           self.fs_width,
                                           titleHeight
                                          );
            _subtitleLabel.frame = CGRectMake(
                                              self.preferredSubtitleOffset.x,
                                              (_titleLabel.fs_bottom-self.preferredTitleOffset.y) - (_titleLabel.fs_height-_titleLabel.font.pointSize)+self.preferredSubtitleOffset.y,
                                              self.fs_width,
                                              subtitleHeight
                                             );
        } else {
            _titleLabel.frame = CGRectMake(
                                           self.preferredTitleOffset.x,
                                           self.preferredTitleOffset.y,
                                           self.contentView.fs_width,
                                           floor(self.contentView.fs_height*5.0/6.0)
                                          );
        }
    }
    
    UIColor *textColor = self.colorForTitleLabel;
    if (![textColor isEqual:_titleLabel.textColor]) {
        _titleLabel.textColor = textColor;
    }
    if (_subtitle) {
        textColor = self.colorForSubtitleLabel;
        if (![textColor isEqual:_subtitleLabel.textColor]) {
            _subtitleLabel.textColor = textColor;
        }
    }
    
    UIColor *borderColor = self.colorForCellBorder;
    UIColor *fillColor = self.colorForCellFill;
    
    BOOL shouldHideShapeLayer = !self.selected && !self.dateIsToday && !self.dateIsSelected && !borderColor && !fillColor;
    
    if (_shapeLayer.hidden != shouldHideShapeLayer) {
        _shapeLayer.hidden = shouldHideShapeLayer;
    }
    if (!shouldHideShapeLayer) {
        
        CGPathRef path = self.cellShape == FSCalendarCellShapeCircle ?
        [UIBezierPath bezierPathWithOvalInRect:_shapeLayer.bounds].CGPath :
        [UIBezierPath bezierPathWithRect:_shapeLayer.bounds].CGPath;
        if (!CGPathEqualToPath(_shapeLayer.path,path)) {
            _shapeLayer.path = path;
        }
        
        CGColorRef cellFillColor = self.colorForCellFill.CGColor;
        if (!CGColorEqualToColor(_shapeLayer.fillColor, cellFillColor)) {
            _shapeLayer.fillColor = cellFillColor;
        }
        
        CGColorRef cellBorderColor = self.colorForCellBorder.CGColor;
        if (!CGColorEqualToColor(_shapeLayer.strokeColor, cellBorderColor)) {
            _shapeLayer.strokeColor = cellBorderColor;
        }
    }

    [self invalidateImage];
    
    if (_eventIndicator.hidden == (_numberOfEvents > 0)) {
        _eventIndicator.hidden = !_numberOfEvents;
    }
}

- (BOOL)isWeekend
{
    return _date && ([_calendar weekdayOfDate:_date] == 1 || [_calendar weekdayOfDate:_date] == 7);
}

- (UIColor *)colorForCurrentStateInDictionary:(NSDictionary *)dictionary
{
    if (self.isSelected || self.dateIsSelected) {
        if (self.dateIsToday) {
            return dictionary[@(FSCalendarCellStateSelected|FSCalendarCellStateToday)] ?: dictionary[@(FSCalendarCellStateSelected)];
        }
        return dictionary[@(FSCalendarCellStateSelected)];
    }
    if (self.dateIsToday && [[dictionary allKeys] containsObject:@(FSCalendarCellStateToday)]) {
        return dictionary[@(FSCalendarCellStateToday)];
    }
    if (self.dateIsPlaceholder && [[dictionary allKeys] containsObject:@(FSCalendarCellStatePlaceholder)]) {
        return dictionary[@(FSCalendarCellStatePlaceholder)];
    }
    if (self.isWeekend && [[dictionary allKeys] containsObject:@(FSCalendarCellStateWeekend)]) {
        return dictionary[@(FSCalendarCellStateWeekend)];
    }
    return dictionary[@(FSCalendarCellStateNormal)];
}

- (void)invalidateTitleFont
{
    _titleLabel.font = self.appearance.preferredTitleFont;
}

- (void)invalidateTitleTextColor
{
    _titleLabel.textColor = self.colorForTitleLabel;
}

- (void)invalidateSubtitleFont
{
    _subtitleLabel.font = self.appearance.preferredSubtitleFont;
}

- (void)invalidateSubtitleTextColor
{
    _subtitleLabel.textColor = self.colorForSubtitleLabel;
}

- (void)invalidateBorderColors
{
    _shapeLayer.strokeColor = self.colorForCellBorder.CGColor;
}

- (void)invalidateFillColors
{
    _shapeLayer.fillColor = self.colorForCellFill.CGColor;
}

- (void)invalidateEventColors
{
    _eventIndicator.color = self.colorsForEvents;
}

- (void)invalidateWeekLineColors
{
    _weekLineLayer.fillColor = _appearance.weekColor.CGColor;
}

- (void)invalidateCellShapes
{
    CGPathRef path = self.cellShape == FSCalendarCellShapeCircle ?
    [UIBezierPath bezierPathWithOvalInRect:_shapeLayer.bounds].CGPath :
    [UIBezierPath bezierPathWithRect:_shapeLayer.bounds].CGPath;
    _shapeLayer.path = path;
}

-(void)invalidateWeekLineShapeMode
{
    _weekLineLayer.path = [self weekLinePathForMode: _weekLineShapeMode].CGPath;
}

-(void)invalidateWeekLineHeight
{
    [self invalidateWeekLineShapeMode];
}

- (void)invalidateImage
{
    if ((self.dateIsSelected || self.isSelected) && _selectedStateImage){
        _imageView.image = _selectedStateImage;
        _imageView.hidden = NO;
    }else if (_image) {
        _imageView.image = _image;
        _imageView.hidden = NO;
    }else {
        _imageView.hidden = YES;
    }
}

#pragma mark - Properties

- (UIColor *)colorForCellFill
{
    if (self.dateIsSelected || self.isSelected) {
        return self.preferredFillSelectionColor ?: [self colorForCurrentStateInDictionary:_appearance.backgroundColors];
    }
    return self.preferredFillDefaultColor ?: [self colorForCurrentStateInDictionary:_appearance.backgroundColors];
}

- (UIColor *)colorForTitleLabel
{
    if (self.dateIsSelected || self.isSelected) {
        return self.preferredTitleSelectionColor ?: [self colorForCurrentStateInDictionary:_appearance.titleColors];
    }
    if (self.dateIsPlaceholder) {
        return _appearance.titlePlaceholderColor ?: [self colorForCurrentStateInDictionary:_appearance.titleColors];
    }
    
    return self.preferredTitleDefaultColor ?: [self colorForCurrentStateInDictionary:_appearance.titleColors];
}

- (UIColor *)colorForSubtitleLabel
{
    if (self.dateIsSelected || self.isSelected) {
        return self.preferredSubtitleSelectionColor ?: [self colorForCurrentStateInDictionary:_appearance.subtitleColors];
    }
    return self.preferredSubtitleDefaultColor ?: [self colorForCurrentStateInDictionary:_appearance.subtitleColors];
}

- (UIColor *)colorForCellBorder
{
    if (self.dateIsSelected || self.isSelected) {
        return _preferredBorderSelectionColor ?: _appearance.borderSelectionColor;
    }
    return _preferredBorderDefaultColor ?: _appearance.borderDefaultColor;
}

- (NSArray<UIColor *> *)colorsForEvents
{
    if (self.dateIsSelected || self.isSelected) {
        return _preferredEventSelectionColors ?: @[_appearance.eventSelectionColor];
    }
    return _preferredEventDefaultColors ?: @[_appearance.eventDefaultColor];
}

- (FSCalendarCellShape)cellShape
{
    return _preferredCellShape ?: _appearance.cellShape;
}

#define OFFSET_PROPERTY(NAME,CAPITAL,ALTERNATIVE) \
\
@synthesize NAME = _##NAME; \
\
- (void)set##CAPITAL:(CGPoint)NAME \
{ \
    BOOL diff = !CGPointEqualToPoint(NAME, self.NAME); \
    _##NAME = NAME; \
    if (diff) { \
        _needsAdjustingViewFrame = YES; \
        [self setNeedsLayout]; \
    } \
} \
\
- (CGPoint)NAME \
{ \
    return CGPointEqualToPoint(_##NAME, CGPointZero) ? ALTERNATIVE : _##NAME; \
}

OFFSET_PROPERTY(preferredTitleOffset, PreferredTitleOffset, _appearance.titleOffset);
OFFSET_PROPERTY(preferredSubtitleOffset, PreferredSubtitleOffset, _appearance.subtitleOffset);
OFFSET_PROPERTY(preferredImageOffset, PreferredImageOffset, _appearance.imageOffset);
OFFSET_PROPERTY(preferredEventOffset, PreferredEventOffset, _appearance.eventOffset);

- (CGSize)preferredImageSize
{
    return CGSizeEqualToSize(_preferredImageSize, CGSizeZero) ? _appearance.imageSize : _preferredImageSize;
}

#undef OFFSET_PROPERTY
//>>>>>>> f59999b50ff7133da8d81ec7c4991f21887e3ecd

- (void)setCalendar:(FSCalendar *)calendar
{
    if (![_calendar isEqual:calendar]) {
        _calendar = calendar;
    }
    if (![_appearance isEqual:calendar.appearance]) {
        _appearance = calendar.appearance;
        [self invalidateTitleFont];
        [self invalidateSubtitleFont];
        [self invalidateTitleTextColor];
        [self invalidateSubtitleTextColor];
        [self invalidateEventColors];
        [self invalidateWeekLineColors];
        [self invalidateWeekLineShapeMode];
    }
}

- (void)setSubtitle:(NSString *)subtitle
{
    if (![_subtitle isEqualToString:subtitle]) {
        BOOL diff = (subtitle.length && !_subtitle.length) || (_subtitle.length && !subtitle.length);
        _subtitle = subtitle;
        if (diff) {
            _needsAdjustingViewFrame = YES;
            [self setNeedsLayout];
        }
    }
}

- (void)setNeedsAdjustingViewFrame:(BOOL)needsAdjustingViewFrame
{
    if (_needsAdjustingViewFrame != needsAdjustingViewFrame) {
        _needsAdjustingViewFrame = needsAdjustingViewFrame;
        _eventIndicator.needsAdjustingViewFrame = needsAdjustingViewFrame;
    }
}

-(void)setWeekLineShapeMode:(FSCalendarCellWeekLineMode)weekHighlightMode {
    if (_weekLineShapeMode != weekHighlightMode) {
        _weekLineShapeMode = weekHighlightMode;
        [self invalidateWeekLineShapeMode];
    }
}

@end



