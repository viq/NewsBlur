//
//  FeedDetailTableCell.m
//  NewsBlur
//
//  Created by Samuel Clay on 7/14/10.
//  Copyright 2010 NewsBlur. All rights reserved.
//

#import "NewsBlurAppDelegate.h"
#import "FeedDetailTableCell.h"
#import "DashboardViewController.h"
#import "ABTableViewCell.h"
#import "UIView+TKCategory.h"
#import "UIImageView+AFNetworking.h"
#import "Utilities.h"
#import "MCSwipeTableViewCell.h"
#import "PINCache.h"
#import "NewsBlur-Swift.h"

static UIFont *textFont = nil;
static UIFont *indicatorFont = nil;

@class FeedDetailViewController;

@implementation FeedDetailTableCell

@synthesize storyTitle;
@synthesize storyAuthor;
@synthesize storyDate;
@synthesize storyContent;
@synthesize storyImageUrl;
@synthesize storyTimestamp;
@synthesize storyScore;
@synthesize storyImage;
@synthesize siteTitle;
@synthesize siteFavicon;
@synthesize isRead;
@synthesize isShared;
@synthesize isSaved;
@synthesize textSize;
@synthesize isRiverOrSocial;
@synthesize feedColorBar;
@synthesize feedColorBarTopBorder;
@synthesize hasAlpha;


#define rightMargin 18


+ (void) initialize {
    if (self == [FeedDetailTableCell class]) {
        textFont = [UIFont boldSystemFontOfSize:18];
        indicatorFont = [UIFont boldSystemFontOfSize:12];
    }
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        cellContent = [[FeedDetailTableCellView alloc] initWithFrame:self.frame];
        cellContent.opaque = YES;
        self.isReadAvailable = YES;
        
        // Clear out half pixel border on top and bottom that the draw code can't touch
        UIView *selectedBackground = [[UIView alloc] init];
        [selectedBackground setBackgroundColor:[UIColor clearColor]];
        self.selectedBackgroundView = selectedBackground;
        
        [self.contentView addSubview:cellContent];
    }
    
    return self;
}

- (void)drawRect:(CGRect)rect {
    ((FeedDetailTableCellView *)cellContent).cell = self;
    ((FeedDetailTableCellView *)cellContent).storyImage = nil;
    ((FeedDetailTableCellView *)cellContent).appDelegate = (NewsBlurAppDelegate *)[[UIApplication sharedApplication] delegate];
    cellContent.frame = rect;
    [cellContent setNeedsDisplay];
}

- (NSString *)accessibilityLabel {
    NSMutableString *output = [NSMutableString stringWithString:self.siteTitle ?: @"no site"];
    
    [output appendFormat:@", \"%@\"", self.storyTitle ?: @"no story"];
    
    if (self.storyAuthor.length) {
        [output appendFormat:@", by %@", self.storyAuthor ?: @"no author"];
    }
    
    [output appendFormat:@", at %@", self.storyDate ?: @"no date"];
    [output appendFormat:@". %@", self.storyContent ?: @"no content"];
    
    return output;
}

- (void)setupGestures {
    NSString *unreadIcon;
    if (storyScore == -1) {
        unreadIcon = @"g_icn_hidden.png";
    } else if (storyScore == 1) {
        unreadIcon = @"g_icn_focus.png";
    } else {
        unreadIcon = @"g_icn_unread.png";
    }
    
    UIColor *shareColor = self.isSaved ?
                            UIColorFromRGB(0xF69E89) :
                            UIColorFromRGB(0xA4D97B);
    UIColor *readColor = self.isRead ?
                            UIColorFromRGB(0xBED49F) :
                            UIColorFromRGB(0xFFFFD2);
    
    if (!self.isReadAvailable) {
        unreadIcon = nil;
        readColor = nil;
    }
    
    appDelegate = [NewsBlurAppDelegate sharedAppDelegate];
    [self setDelegate:(FeedDetailViewController <MCSwipeTableViewCellDelegate> *)appDelegate.feedDetailViewController];
    
    [self setFirstStateIconName:@"clock.png"
                     firstColor:shareColor
            secondStateIconName:nil
                    secondColor:nil
                  thirdIconName:unreadIcon
                     thirdColor:readColor
                 fourthIconName:nil
                    fourthColor:nil];

    self.mode = MCSwipeTableViewCellModeSwitch;
    self.shouldAnimatesIcons = NO;
}


- (UIFontDescriptor *)fontDescriptorUsingPreferredSize:(NSString *)textStyle {
    UIFontDescriptor *fontDescriptor = appDelegate.fontDescriptorTitleSize;

    if (fontDescriptor) return fontDescriptor;
    NSUserDefaults *userPreferences = [NSUserDefaults standardUserDefaults];
    
    fontDescriptor = [UIFontDescriptor preferredFontDescriptorWithTextStyle:textStyle];
    if (![userPreferences boolForKey:@"use_system_font_size"]) {
        if ([[userPreferences stringForKey:@"feed_list_font_size"] isEqualToString:@"xs"]) {
            fontDescriptor = [fontDescriptor fontDescriptorWithSize:11.0f];
        } else if ([[userPreferences stringForKey:@"feed_list_font_size"] isEqualToString:@"small"]) {
            fontDescriptor = [fontDescriptor fontDescriptorWithSize:13.0f];
        } else if ([[userPreferences stringForKey:@"feed_list_font_size"] isEqualToString:@"medium"]) {
            fontDescriptor = [fontDescriptor fontDescriptorWithSize:14.0f];
        } else if ([[userPreferences stringForKey:@"feed_list_font_size"] isEqualToString:@"large"]) {
            fontDescriptor = [fontDescriptor fontDescriptorWithSize:16.0f];
        } else if ([[userPreferences stringForKey:@"feed_list_font_size"] isEqualToString:@"xl"]) {
            fontDescriptor = [fontDescriptor fontDescriptorWithSize:18.0f];
        }
    }
    
    return fontDescriptor;
}

@end

@implementation FeedDetailTableCellView

@synthesize cell;
@synthesize storyImage;
@synthesize appDelegate;

- (void)drawRect:(CGRect)r {
    if (!cell) {
        return;
    }
    
    CGFloat riverPadding = 0;
    CGFloat riverPreview = 14;
    
    if (cell.isRiverOrSocial) {
        riverPadding = 20;
        riverPreview = 6;
    }

    CGContextRef context = UIGraphicsGetCurrentContext();
    
    NSString *preview = [[NSUserDefaults standardUserDefaults] stringForKey:@"story_list_preview_images_size"];
    BOOL isSmall = [preview isEqualToString:@"small"] || [preview isEqualToString:@"small_left"] || [preview isEqualToString:@"small_right"];
    BOOL isLeft = [preview isEqualToString:@"small_left"] || [preview isEqualToString:@"large_left"];
    
    CGRect rect = CGRectInset(r, 12, 12);
    CGFloat previewHorizMargin = isSmall ? 14 : 0;
    CGFloat previewVertMargin = isSmall ? 36 : 0;
    CGFloat imageWidth = isSmall ? 60 : 80;
    CGFloat imageHeight = r.size.height - previewVertMargin;
    CGFloat leftOffset = isLeft ? imageWidth : 0;
    CGFloat leftMargin = leftOffset + 30;
    CGFloat topMargin = isSmall ? riverPreview : 0;
    
    if (isLeft) {
        leftMargin += previewHorizMargin;
        rect.origin.x += (leftOffset + previewHorizMargin);
        rect.size.width -= (leftOffset + previewHorizMargin);
    } else {
        rect.size.width -= previewHorizMargin;
    }
    
    rect.size.width -= 18; // Scrollbar padding
    CGRect dateRect = rect;
    
    UIColor *backgroundColor;
    backgroundColor = cell.highlighted || cell.selected ?
                      UIColorFromLightSepiaMediumDarkRGB(0xFFFDEF, 0xEEECCD, 0x303A40, 0x303030) : UIColorFromLightSepiaMediumDarkRGB(0xF4F4F4, 0xFFFDEF, 0x4F4F4F, 0x101010);
    [backgroundColor set];
    
    CGContextFillRect(context, r);
    
    if (cell.storyImageUrl) {
        CGRect imageFrame = CGRectMake(r.size.width - imageWidth - previewHorizMargin, topMargin,
                                       imageWidth, imageHeight);
        
        if (isLeft) {
            imageFrame.origin.x = previewHorizMargin + 2;
        }
        
        UIImage *cachedImage = (UIImage *)[appDelegate.cachedStoryImages objectForKey:cell.storyImageUrl];
        if (cachedImage && ![cachedImage isKindOfClass:[NSNull class]]) {
//            NSLog(@"Found cached image: %@", cell.storyTitle);
            CGContextRef context = UIGraphicsGetCurrentContext();
            CGContextSaveGState(context);
            
            if (isSmall) {
                [[UIBezierPath bezierPathWithRoundedRect:imageFrame cornerRadius:8] addClip];
            }
            
            CGFloat alpha = 1.0f;
            if (cell.highlighted || cell.selected) {
                alpha = cell.isRead ? 0.5f : 0.85f;
            } else if (cell.isRead) {
                alpha = 0.34f;
            }
            
            CGFloat aspect = cachedImage.size.width / cachedImage.size.height;
            CGRect drawingFrame;
            
            if (imageFrame.size.width / aspect > imageFrame.size.height) {
                CGFloat height = imageFrame.size.width / aspect;
                
                drawingFrame = CGRectMake(imageFrame.origin.x, imageFrame.origin.y + ((imageFrame.size.height - height) / 2), imageFrame.size.width, height);
            } else {
                CGFloat width = imageFrame.size.height * aspect;
                
                drawingFrame = CGRectMake(imageFrame.origin.x + ((imageFrame.size.width - width) / 2), imageFrame.origin.y, width, imageFrame.size.height);
            }
            
            CGContextClipToRect(context, imageFrame);
            
            [cachedImage drawInRect:drawingFrame blendMode:0 alpha:alpha];
            
            if (!isLeft) {
                rect.size.width -= imageFrame.size.width;
            }
            
            CGContextRestoreGState(context);
            
            BOOL isRoomForDateBelowImage = CGRectGetMaxY(imageFrame) < r.size.height - 10;
            
            if (!isSmall && !isRoomForDateBelowImage) {
                dateRect = rect;
            }
        }
    }
    
    CGFloat feedOffset = isLeft ? 20 : 0;
    UIColor *textColor;
    UIFont *font;
    UIFontDescriptor *fontDescriptor = [cell fontDescriptorUsingPreferredSize:UIFontTextStyleCaption1];
    
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy];
    paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
    paragraphStyle.alignment = NSTextAlignmentLeft;
    paragraphStyle.lineHeightMultiple = 0.95f;
    
    if (cell.isRiverOrSocial) {
        if (cell.isRead) {
            font = [UIFont fontWithName:@"WhitneySSm-Book" size:fontDescriptor.pointSize];
            textColor = UIColorFromLightSepiaMediumDarkRGB(0x808080, 0x808080, 0xB0B0B0, 0x707070);
        } else {
            UIFontDescriptor *boldFontDescriptor = [fontDescriptor fontDescriptorWithSymbolicTraits: UIFontDescriptorTraitBold];
            font = [UIFont fontWithName:@"WhitneySSm-Medium" size:boldFontDescriptor.pointSize];
            textColor = UIColorFromLightSepiaMediumDarkRGB(0x606060, 0x606060, 0xD0D0D0, 0x909090);
        }
        if (cell.highlighted || cell.selected) {
            textColor = UIColorFromLightSepiaMediumDarkRGB(0x686868, 0x686868, 0xA0A0A0, 0x808080);
        }
        
        NSInteger siteTitleY = (20 - font.pointSize/2)/2;
        [cell.siteTitle drawInRect:CGRectMake(leftMargin - feedOffset + 20, siteTitleY, rect.size.width - 20, 20)
                    withAttributes:@{NSFontAttributeName: font,
                                     NSForegroundColorAttributeName: textColor,
                                     NSParagraphStyleAttributeName: paragraphStyle}];
        
        // site favicon
        if (cell.isRead && !cell.hasAlpha) {
            if (cell.isRiverOrSocial) {
                cell.siteFavicon = [cell imageByApplyingAlpha:cell.siteFavicon withAlpha:0.25];
            }
            cell.hasAlpha = YES;
        }
        
        [cell.siteFavicon drawInRect:CGRectMake(leftMargin - feedOffset, siteTitleY, 16.0, 16.0)];
    }
    
    // story title
    if (cell.isRead) {
        font = [UIFont fontWithName:@"WhitneySSm-Book" size:fontDescriptor.pointSize];
        textColor = UIColorFromLightSepiaMediumDarkRGB(0x585858, 0x585858, 0x989898, 0x888888);
    } else {
        UIFontDescriptor *boldFontDescriptor = [fontDescriptor fontDescriptorWithSymbolicTraits: UIFontDescriptorTraitBold];
        font = [UIFont fontWithName:@"WhitneySSm-Medium" size:boldFontDescriptor.pointSize];
        textColor = UIColorFromLightSepiaMediumDarkRGB(0x333333, 0x333333, 0xD0D0D0, 0xCCCCCC);
    }
    if (cell.highlighted || cell.selected) {
        textColor = UIColorFromLightDarkRGB(0x686868, 0xA0A0A0);
    }
    CGFloat boundingRows = cell.isShort ? 1.5 : 3;
    if (!cell.isShort && (self.cell.textSize == FeedDetailTextSizeMedium || self.cell.textSize == FeedDetailTextSizeLong)) {
        boundingRows = MIN(((r.size.height - 24) / font.pointSize) - 2, 4);
    }
    CGSize theSize = [cell.storyTitle
                      boundingRectWithSize:CGSizeMake(rect.size.width, font.pointSize * boundingRows)
                      options:NSStringDrawingTruncatesLastVisibleLine|NSStringDrawingUsesLineFragmentOrigin
                      attributes:@{NSFontAttributeName: font,
                                   NSParagraphStyleAttributeName: paragraphStyle}
                      context:nil].size;
    BOOL needsCentering = theSize.height < font.pointSize * 2;
    int centeringOffset = needsCentering ? ((font.pointSize * 2 - theSize.height) / 2) : 0;
    int storyTitleY = 14 + riverPadding + centeringOffset;
    if (cell.isShort) {
        storyTitleY = 14 + riverPadding - (theSize.height/font.pointSize*2);
    }
    int storyTitleX = leftMargin;
    if (cell.isSaved) {
        UIImage *savedIcon = [UIImage imageNamed:@"clock"];
        [savedIcon drawInRect:CGRectMake(storyTitleX, storyTitleY - 1, 16, 16) blendMode:0 alpha:1];
        storyTitleX += 20;
    }
    if (cell.isShared) {
        UIImage *savedIcon = [UIImage imageNamed:@"menu_icn_share"];
        [savedIcon drawInRect:CGRectMake(storyTitleX, storyTitleY - 1, 16, 16) blendMode:0 alpha:1];
        storyTitleX += 20;
    }
    CGRect storyTitleFrame = CGRectMake(storyTitleX, storyTitleY,
                                        rect.size.width - storyTitleX + leftMargin, theSize.height);
    [cell.storyTitle drawWithRect:storyTitleFrame
                          options:NSStringDrawingTruncatesLastVisibleLine|NSStringDrawingUsesLineFragmentOrigin
                       attributes:@{NSFontAttributeName: font,
                                    NSForegroundColorAttributeName: textColor,
                                    NSParagraphStyleAttributeName: paragraphStyle}
                          context:nil];
    
//    CGContextStrokeRect(context, storyTitleFrame);
    
    if (cell.storyContent) {
        int storyContentWidth = rect.size.width;
        CGFloat boundingRows = cell.isShort ? 1.5 : 3;
        
        if (!cell.isShort && (self.cell.textSize == FeedDetailTextSizeMedium || self.cell.textSize == FeedDetailTextSizeLong)) {
            boundingRows = (r.size.height - 30 - CGRectGetMaxY(storyTitleFrame)) / font.pointSize;
        }
        
        CGSize contentSize = [cell.storyContent
                              boundingRectWithSize:CGSizeMake(storyContentWidth, font.pointSize * boundingRows)
                              options:NSStringDrawingTruncatesLastVisibleLine|NSStringDrawingUsesLineFragmentOrigin
                              attributes:@{NSFontAttributeName: font,
                                           NSParagraphStyleAttributeName: paragraphStyle}
                              context:nil].size;
        CGFloat textRows = contentSize.height / font.pointSize;
        int storyContentY = r.size.height - 16 - 4 - ((font.pointSize * textRows + font.lineHeight) + contentSize.height) / 2;
        if (cell.isShort) {
            storyContentY = r.size.height - 10 - 4 - ((font.pointSize + font.lineHeight) + contentSize.height)/2;
        }
        
        if (cell.isRead) {
            textColor = UIColorFromLightSepiaMediumDarkRGB(0xB8B8B8, 0xB8B8B8, 0xA0A0A0, 0x707070);
            font = [UIFont fontWithName:@"WhitneySSm-Book" size:fontDescriptor.pointSize - 1];
        } else {
            textColor = UIColorFromLightSepiaMediumDarkRGB(0x404040, 0x404040, 0xC0C0C0, 0xB0B0B0);
            font = [UIFont fontWithName:@"WhitneySSm-Book" size:fontDescriptor.pointSize - 1];
        }
        if (cell.highlighted || cell.selected) {
            if (cell.isRead) {
                textColor = UIColorFromLightSepiaMediumDarkRGB(0xB8B8B8, 0xB8B8B8, 0xA0A0A0, 0x707070);
            } else {
                textColor = UIColorFromLightSepiaMediumDarkRGB(0x686868, 0x686868, 0xA9A9A9, 0x989898);
            }
        }
        
        [cell.storyContent
         drawWithRect:CGRectMake(storyTitleX, storyContentY,
                                 rect.size.width - storyTitleX + leftMargin, contentSize.height)
         options:NSStringDrawingTruncatesLastVisibleLine|NSStringDrawingUsesLineFragmentOrigin
         attributes:@{NSFontAttributeName: font,
                      NSForegroundColorAttributeName: textColor,
                      NSParagraphStyleAttributeName: paragraphStyle}
         context:nil];
        
//        CGContextStrokeRect(context, CGRectMake(storyTitleX, storyContentY,
//                                                rect.size.width - storyTitleX + leftMargin, contentSize.height));
    }
    
    // story date
    int storyAuthorDateY = r.size.height - 18;
    
    if (cell.isRead) {
        textColor = UIColorFromLightSepiaMediumDarkRGB(0xB8B8B8, 0xB8B8B8, 0x909090, 0x404040);
        font = [UIFont fontWithName:@"WhitneySSm-Medium" size:11];
    } else {
        textColor = UIColorFromLightSepiaMediumDarkRGB(0xA6A8A2, 0xA6A8A2, 0x909090, 0x505050);
        font = [UIFont fontWithName:@"WhitneySSm-Medium" size:11];
    }
    if (cell.highlighted || cell.selected) {
        if (cell.isRead) {
            textColor = UIColorFromLightSepiaMediumDarkRGB(0xA8A8A8, 0xA8A8A8, 0x999999, 0x808080);
        } else {
            textColor = UIColorFromLightSepiaMediumDarkRGB(0x959595, 0x959595, 0xA0A0A0, 0x909090);
        }
    }
    
    paragraphStyle.alignment = NSTextAlignmentRight;
    NSString *date = [Utilities formatShortDateFromTimestamp:cell.storyTimestamp];
    CGSize dateSize = [date sizeWithAttributes:@{NSFontAttributeName: font,
                                                 NSForegroundColorAttributeName: textColor,
                                                 NSParagraphStyleAttributeName: paragraphStyle}];
    [date
     drawInRect:CGRectMake(0, storyAuthorDateY, dateRect.size.width + leftMargin, 15.0)
     withAttributes:@{NSFontAttributeName: font,
                      NSForegroundColorAttributeName: textColor,
                      NSParagraphStyleAttributeName: paragraphStyle}];
    
    // Story author
    paragraphStyle.alignment = NSTextAlignmentLeft;
    [cell.storyAuthor
     drawInRect:CGRectMake(leftMargin, storyAuthorDateY, dateRect.size.width - dateSize.width - 12, 15.0)
     withAttributes:@{NSFontAttributeName: font,
                      NSForegroundColorAttributeName: textColor,
                      NSParagraphStyleAttributeName: paragraphStyle}];
    
    // feed bar
    CGContextSetStrokeColor(context, CGColorGetComponents([cell.feedColorBarTopBorder CGColor]));
    if (cell.isRead) {
        CGContextSetAlpha(context, 0.15);
    }
    CGContextSetLineWidth(context, 4.0f);
    CGContextBeginPath(context);
    CGContextMoveToPoint(context, 2.0f, 0);
    CGContextAddLineToPoint(context, 2.0f, cell.frame.size.height);
    CGContextStrokePath(context);
    
    CGContextSetStrokeColor(context, CGColorGetComponents([cell.feedColorBar CGColor]));
    CGContextBeginPath(context);
    CGContextMoveToPoint(context, 6.0f, 0);
    CGContextAddLineToPoint(context, 6.0, cell.frame.size.height);
    CGContextStrokePath(context);
    
    // reset for borders
    UIColor *white = UIColorFromRGB(0xffffff);
    CGContextSetAlpha(context, 1.0);
    if (cell.highlighted || cell.selected) {
        // top border
        CGContextSetStrokeColor(context, CGColorGetComponents([white CGColor]));
        
        CGContextSetLineWidth(context, 1.0f);
        CGContextBeginPath(context);
        CGContextMoveToPoint(context, 0, 0.5f);
        CGContextAddLineToPoint(context, cell.bounds.size.width, 0.5f);
        CGContextStrokePath(context);
        
        CGFloat lineWidth = 0.5f;
        CGContextSetLineWidth(context, lineWidth);
        UIColor *blue = UIColorFromRGB(0xDFDDCF);
        
        CGContextSetStrokeColor(context, CGColorGetComponents([blue CGColor]));
        
        CGContextBeginPath(context);
        CGContextMoveToPoint(context, 0, 1.0f + 0.5f*lineWidth);
        CGContextAddLineToPoint(context, cell.bounds.size.width, 1.0f + 0.5f*lineWidth);
        CGContextStrokePath(context);
        
        // bottom border
        CGContextBeginPath(context);
        CGContextMoveToPoint(context, 0, cell.bounds.size.height - .5f*lineWidth);
        CGContextAddLineToPoint(context, cell.bounds.size.width, cell.bounds.size.height - .5f*lineWidth);
        CGContextStrokePath(context);
    } else {
        // top border
        CGContextSetLineWidth(context, 1.0f);
        
        CGContextSetStrokeColor(context, CGColorGetComponents([white CGColor]));
        
        CGContextBeginPath(context);
        CGContextMoveToPoint(context, 0.0f, 0.5f);
        CGContextAddLineToPoint(context, cell.bounds.size.width, 0.5f);
        CGContextStrokePath(context);
    }
    
    // story indicator
    CGFloat storyIndicatorX = isLeft ? rect.origin.x + 2 : 15;
    CGFloat storyIndicatorY = storyTitleFrame.origin.y + storyTitleFrame.size.height / 2;
    
    UIImage *unreadIcon;
    if (cell.storyScore == -1) {
        unreadIcon = [UIImage imageNamed:@"g_icn_hidden"];
    } else if (cell.storyScore == 1) {
        unreadIcon = [UIImage imageNamed:@"g_icn_focus"];
    } else {
        unreadIcon = [UIImage imageNamed:@"g_icn_unread"];
    }
    
    [unreadIcon drawInRect:CGRectMake(storyIndicatorX, storyIndicatorY - 3, 8, 8) blendMode:0 alpha:(cell.isRead ? .15 : 1)];
}

@end
