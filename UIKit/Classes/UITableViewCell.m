/*
 * Copyright (c) 2011, The Iconfactory. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 *
 * 3. Neither the name of The Iconfactory nor the names of its contributors may
 *    be used to endorse or promote products derived from this software without
 *    specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE ICONFACTORY BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 * LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
 * OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "UITableViewCell+UIPrivate.h"
#import "UITableViewCellSeparator.h"
#import "UIColor.h"
#import "UILabel.h"
#import "UIImageView.h"
#import "UIFont.h"
#import "UITableView.h"
#import "UIImage+UIPrivate.h"
#import "UIButton.h"
#import <QuartzCore/QuartzCore.h>
#import "UIGraphics.h"
#import "UITouch.h"
#import "UIBezierPath.h"

extern CGFloat _UITableViewDefaultRowHeight;

@implementation UITableViewCell
@synthesize accessoryType=_accessoryType, selectionStyle=_selectionStyle, indentationLevel=_indentationLevel;
@synthesize editingAccessoryType=_editingAccessoryType, selected=_selected, backgroundView=_backgroundView;
@synthesize selectedBackgroundView=_selectedBackgroundView, highlighted=_highlighted, reuseIdentifier=_reuseIdentifier;
@synthesize editing = _editing, detailTextLabel = _detailTextLabel, showingDeleteConfirmation = _showingDeleteConfirmation;
@synthesize indentationWidth=_indentationWidth, accessoryView=_accessoryView;

- (id)initWithFrame:(CGRect)frame
{
    if ((self=[super initWithFrame:frame])) {
        _indentationWidth = 10;
        _style = UITableViewCellStyleDefault;
        _selectionStyle = UITableViewCellSelectionStyleBlue;

        _seperatorView = [[UITableViewCellSeparator alloc] init];
        [self addSubview:_seperatorView];
        
        self.accessoryType = UITableViewCellAccessoryNone;
        self.editingAccessoryType = UITableViewCellAccessoryNone;
    }
    return self;
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if ((self=[self initWithFrame:CGRectMake(0,0,320,_UITableViewDefaultRowHeight)])) {
        _style = style;
        _reuseIdentifier = [reuseIdentifier copy];
    }
    return self;
}

- (void)dealloc
{
    [_seperatorView release];
    [_contentView release];
    [_accessoryView release];
    [_textLabel release];
    [_detailTextLabel release];
    [_imageView release];
    [_backgroundView release];
    [_selectedBackgroundView release];
    [_reuseIdentifier release];
    [super dealloc];
}

- (void)setEditing:(BOOL)yesOrNo
{
    _editing = yesOrNo;
    [self setNeedsLayout];
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    const CGRect bounds = self.bounds;
    BOOL showingSeperator = !_seperatorView.hidden;
    
    CGRect contentFrame = CGRectMake(0,0,bounds.size.width,bounds.size.height-(showingSeperator? 1 : 0));
    CGRect accessoryRect = CGRectMake(bounds.size.width,0,0,0);

    if(_accessoryView) {
        accessoryRect.size = _accessoryView.bounds.size; //[_accessoryView sizeThatFits: bounds.size];
        accessoryRect.origin.x = bounds.size.width - accessoryRect.size.width;
        accessoryRect.origin.y = round(0.5*(bounds.size.height - accessoryRect.size.height));
        _accessoryView.frame = accessoryRect;
        [self addSubview: _accessoryView];
        contentFrame.size.width = accessoryRect.origin.x - 1;
    }
    
    _backgroundView.frame = contentFrame;
    _selectedBackgroundView.frame = contentFrame;
    
    if (_editing) {
        UITableView *tv = (UITableView *)self.superview;
        
        if ([tv.dataSource respondsToSelector:@selector(tableView:commitEditingStyle:forRowAtIndexPath:)]) {
            contentFrame.origin.x += 36;
            contentFrame.size.width -= 36;
            
            if (!deleteButton) {
                UIImage *img = [UIImage _frameworkImageWithName:@"<UITableViewCell> remove.png" leftCapWidth:0 topCapHeight:0];
                deleteButton = [UIButton buttonWithType:UIButtonTypeCustom];
                [deleteButton setImage:img forState:UIControlStateNormal];
                [deleteButton addTarget:self action:@selector(delete:) forControlEvents:UIControlEventTouchUpInside];
                [self addSubview:deleteButton];
            }
            deleteButton.frame = CGRectMake(0, 0, 36, bounds.size.height);
        }
        
        if ([tv.dataSource respondsToSelector:@selector(tableView:moveRowAtIndexPath:toIndexPath:)]) {
            contentFrame.size.width -= 44;
            
            if (!dragButton) {
                UIImage *img = [UIImage _frameworkImageWithName:@"<UITableViewCell> reorder.png" leftCapWidth:0 topCapHeight:0];
                dragButton = [UIButton buttonWithType:UIButtonTypeCustom];
                [dragButton setImage:img forState:UIControlStateNormal];
                [dragButton addTarget:self action:@selector(drag:forEvent:) forControlEvents:UIControlEventTouchDragInside];
                [dragButton addTarget:self action:@selector(drag:forEvent:) forControlEvents:UIControlEventTouchDragOutside];
                [dragButton addTarget:self action:@selector(drop:forEvent:) forControlEvents:UIControlEventTouchUpInside];
                [dragButton addTarget:self action:@selector(drop:forEvent:) forControlEvents:UIControlEventTouchUpOutside];
                [self addSubview:dragButton];
            }
            dragButton.frame = CGRectMake(bounds.size.width-44, 0, 44, bounds.size.height);
        }
    } else {
        [deleteButton removeFromSuperview]; deleteButton = nil;
        [dragButton removeFromSuperview]; dragButton = nil;
    }
    _contentView.frame = contentFrame;
    
    [self sendSubviewToBack:_selectedBackgroundView];
    [self sendSubviewToBack:_backgroundView];
    [self bringSubviewToFront:_contentView];
    [self bringSubviewToFront:_accessoryView];
    
    if (showingSeperator) {
        _seperatorView.frame = CGRectMake(0,bounds.size.height-1,bounds.size.width,1);
        [self bringSubviewToFront:_seperatorView];
    }
    
    if (_style == UITableViewCellStyleDefault) {
        const CGFloat padding = 5;

        const BOOL showImage = (_imageView.image != nil);
        const CGFloat imageWidth = (showImage? 30:0);

        _imageView.frame = CGRectMake(padding,0,imageWidth,contentFrame.size.height);
        
        CGRect textRect;
        textRect.origin = CGPointMake(padding+imageWidth+padding,0);
        textRect.size = CGSizeMake(MAX(0,contentFrame.size.width-textRect.origin.x-padding),contentFrame.size.height);
        _textLabel.frame = textRect;
    } else if (_style == UITableViewCellStyleValue1) {
        const CGFloat padding = 5;
        
        const BOOL showImage = (_imageView.image != nil);
        const CGFloat imageWidth = (showImage? 30:0);
        
        _imageView.frame = CGRectMake(padding,0,imageWidth,contentFrame.size.height);
        
        CGRect textRect;
        textRect.origin = CGPointMake(padding+imageWidth+padding,0);
        textRect.size = CGSizeMake(MAX(0,contentFrame.size.width-textRect.origin.x-padding),contentFrame.size.height);
        _textLabel.frame = textRect;
        
        textRect.origin.x = textRect.origin.x+textRect.size.width-50;
        textRect.size.width = 50;
        _detailTextLabel.frame = textRect;
    }
}

- (void)delete:(id)sender
{
    UITableView *tv = (UITableView *)self.superview;
    [tv.dataSource tableView:tv commitEditingStyle:UITableViewCellEditingStyleDelete forRowAtIndexPath:[tv indexPathForCell:self]];
}

- (void)drag:(UIButton *)sender forEvent:(UIEvent *)event 
{
    if (!dragLayer) {
        dragLayer = [CALayer layer];
        dragLayer.opacity = 0.9;
        dragLayer.shadowPath = [[UIBezierPath bezierPathWithRect:self.bounds] CGPath];
        dragLayer.shadowOpacity = 0.7;
        dragLayer.shadowOffset = CGSizeMake(0, 1);
        dragLayer.bounds = self.bounds;
        CGPoint p = [(UITouch *)[event.allTouches anyObject] locationInView:self];
        dragLayer.anchorPoint = CGPointMake(p.x/self.bounds.size.width, p.y/self.bounds.size.height);
        
        UITableView *tv = (UITableView *)self.superview;
        p = [(UITouch *)[event.allTouches anyObject] locationInView:tv];
        dragLayer.position = p;
        tv.dragSelection = [tv indexPathForRowAtPoint:p];
        
        UIGraphicsBeginImageContext(self.bounds.size);
        CGContextRef gctx = UIGraphicsGetCurrentContext();
        [self.layer renderInContext:gctx];
        dragLayer.contents = (id)[UIGraphicsGetImageFromCurrentImageContext() CGImage];
        UIGraphicsEndImageContext();
        
        [self.layer.superlayer addSublayer:dragLayer];
    } else {
        UITableView *tv = (UITableView *)self.superview;
        
        CGPoint p = [(UITouch *)[event.allTouches anyObject] locationInView:tv];
        
        NSIndexPath *indexPath = [tv indexPathForRowAtPoint:p];
        if (indexPath) {
            tv.proposedDrop = indexPath;
            
            [CATransaction begin];
            [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
            
            p.x = dragLayer.position.x;
            dragLayer.position = p;
            [CATransaction commit];
            
            [tv scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionNone animated:YES];
        }
    }
}

- (void)drop:(UIButton *)sender forEvent:(UIEvent *)event
{
    UITableView *tv = (UITableView *)self.superview;
    
    NSIndexPath *from = tv.dragSelection;
    NSIndexPath *to = tv.proposedDrop;
    if (!(from.section == to.section && from.row == to.row))
        [tv.dataSource tableView:tv moveRowAtIndexPath:from toIndexPath:to];
    
    tv.dragSelection = nil;
    tv.proposedDrop = nil;
    
    [dragLayer removeFromSuperlayer];
    dragLayer = nil;
}

- (UIView *)contentView
{
    if (!_contentView) {
        _contentView = [[UIView alloc] init];
        [self addSubview:_contentView];
        [self layoutIfNeeded];
    }
    
    return _contentView;
}

- (UIImageView *)imageView
{
    if (!_imageView) {
        _imageView = [[UIImageView alloc] init];
        _imageView.contentMode = UIViewContentModeCenter;
        [self.contentView addSubview:_imageView];
        [self layoutIfNeeded];
    }
    
    return _imageView;
}

- (UILabel *)textLabel
{
    if (!_textLabel) {
        _textLabel = [[UILabel alloc] init];
        _textLabel.backgroundColor = [UIColor clearColor];
        _textLabel.textColor = [UIColor blackColor];
        _textLabel.highlightedTextColor = [UIColor whiteColor];
        _textLabel.font = [UIFont boldSystemFontOfSize:17];
        [self.contentView addSubview:_textLabel];
        [self layoutIfNeeded];
    }
    
    return _textLabel;
}

- (UILabel *)detailTextLabel
{
    if (!_detailTextLabel) {
        _detailTextLabel = [[UILabel alloc] init];
        _detailTextLabel.backgroundColor = [UIColor clearColor];
        _detailTextLabel.textColor = [UIColor colorWithRed:0.22 green:0.33 blue:0.53 alpha:1];
        _detailTextLabel.highlightedTextColor = [UIColor whiteColor];
        _detailTextLabel.font = [UIFont systemFontOfSize:17];
        _detailTextLabel.textAlignment = UITextAlignmentRight;
        [self.contentView addSubview:_detailTextLabel];
        [self layoutIfNeeded];
    }
    
    return _detailTextLabel;
}

- (void)_setSeparatorStyle:(UITableViewCellSeparatorStyle)theStyle color:(UIColor *)theColor
{
    [_seperatorView setSeparatorStyle:theStyle color:theColor];
}

- (void)_setHighlighted:(BOOL)highlighted forViews:(id)subviews
{
    for (id view in subviews) {
        if ([view respondsToSelector:@selector(setHighlighted:)]) {
            [view setHighlighted:highlighted];
        }
        [self _setHighlighted:highlighted forViews:[view subviews]];
    }
}

- (void)_updateSelectionState
{
    BOOL shouldHighlight = (_highlighted || _selected);
    _selectedBackgroundView.hidden = !shouldHighlight;
    [self _setHighlighted:shouldHighlight forViews:[self subviews]];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    if (selected != _selected && _selectionStyle != UITableViewCellSelectionStyleNone) {
        _selected = selected;
        [self _updateSelectionState];
    }
}

- (void)setSelected:(BOOL)selected
{
    [self setSelected:selected animated:NO];
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated
{
    if (_highlighted != highlighted && _selectionStyle != UITableViewCellSelectionStyleNone) {
        _highlighted = highlighted;
        [self _updateSelectionState];
    }
}

- (void)setHighlighted:(BOOL)highlighted
{
    [self setHighlighted:highlighted animated:NO];
}

- (void)setBackgroundView:(UIView *)theBackgroundView
{
    if (theBackgroundView != _backgroundView) {
        [_backgroundView removeFromSuperview];
        [_backgroundView release];
        _backgroundView = [theBackgroundView retain];
        [self addSubview:_backgroundView];
        self.backgroundColor = [UIColor clearColor];
    }
}

- (void)setSelectedBackgroundView:(UIView *)theSelectedBackgroundView
{
    if (theSelectedBackgroundView != _selectedBackgroundView) {
        [_selectedBackgroundView removeFromSuperview];
        [_selectedBackgroundView release];
        _selectedBackgroundView = [theSelectedBackgroundView retain];
        _selectedBackgroundView.hidden = !_selected;
        [self addSubview:_selectedBackgroundView];
    }
}

- (void)prepareForReuse
{
}

@end