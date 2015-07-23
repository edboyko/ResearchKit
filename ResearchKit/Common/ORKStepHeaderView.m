/*
 Copyright (c) 2015, Apple Inc. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification,
 are permitted provided that the following conditions are met:
 
 1.  Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.
 
 2.  Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation and/or
 other materials provided with the distribution.
 
 3.  Neither the name of the copyright holder(s) nor the names of any contributors
 may be used to endorse or promote products derived from this software without
 specific prior written permission. No license is granted to the trademarks of
 the copyright holders even if such marks are included in this software.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */


#import "ORKStepHeaderView_Internal.h"
#import "ORKSkin.h"
#import "ORKHelpers.h"


#define ORKVerticalContainerLog(...)

static const CGFloat AssumedNavBarHeight = 44;
static const CGFloat AssumedStatusBarHeight = 20;

@implementation ORKStepHeaderView {
    NSLayoutConstraint *_captionMinBottomSpacingConstraint;
    NSLayoutConstraint *_captionToInstructionConstraint;
    NSLayoutConstraint *_headerZeroHeightConstraint;
    NSLayoutConstraint *_illustrationToCaptionBaselineConstraint;
    NSLayoutConstraint *_illustrationToCaptionTopConstraint;
    NSLayoutConstraint *_instructionMinBottomSpacingConstraint;
    NSLayoutConstraint *_instructionToLearnMoreConstraint;
    NSLayoutConstraint *_learnMoreToStepViewConstraint;
}

- (void)updateCaptionLabelPreferredWidth {
    CGFloat sideMargin = ORKGetMetricForWindow(ORKScreenMetricHeadlineSideMargin, self.window);
    UIEdgeInsets layoutMargins = self.layoutMargins;
    
    // If we don't do this, sometimes the label doesn't split onto two lines properly.
    CGFloat maxLabelLayoutWidth = MAX(self.bounds.size.width - sideMargin*2 - layoutMargins.left - layoutMargins.right, 0);
    
    _captionLabel.preferredMaxLayoutWidth = maxLabelLayoutWidth;
    _instructionLabel.preferredMaxLayoutWidth = maxLabelLayoutWidth;
    [self setNeedsUpdateConstraints];
}

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    [self updateCaptionLabelPreferredWidth];
}

- (void)setBounds:(CGRect)bounds {
    [super setBounds:bounds];
    [self updateCaptionLabelPreferredWidth];
}

- (void)setLayoutMargins:(UIEdgeInsets)layoutMargins {
    [super setLayoutMargins:layoutMargins];
    [self updateCaptionLabelPreferredWidth];
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Text Label
        {
            _captionLabel = [ORKHeadlineLabel new];
            _captionLabel.numberOfLines = 0;
            _captionLabel.textAlignment = NSTextAlignmentCenter;
            [self addSubview:_captionLabel];
        }
        
        {
            _learnMoreButton = [ORKTextButton new];
            _learnMoreButton.contentEdgeInsets = (UIEdgeInsets){10,10,10,10};
            [_learnMoreButton setTitle:nil forState:UIControlStateNormal];
            [_learnMoreButton addTarget:self action:@selector(learnMoreAction:) forControlEvents:UIControlEventTouchUpInside];
            _learnMoreButton.exclusiveTouch = YES;
            _learnMoreButton.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
            _learnMoreButton.titleLabel.textAlignment = NSTextAlignmentCenter;
            [self addSubview:_learnMoreButton];
            self.learnMoreButtonItem = nil;
        }
        
        {
            _instructionLabel = [ORKSubheadlineLabel new];
            _instructionLabel.numberOfLines = 0;
            _instructionLabel.textAlignment = NSTextAlignmentCenter;
            
            [self addSubview:_instructionLabel];
        }
        
        [_learnMoreButton setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
        [_learnMoreButton setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
        
#ifdef LAYOUT_DEBUG
        _captionLabel.backgroundColor = [[UIColor yellowColor] colorWithAlphaComponent:0.2];
        _captionLabel.layer.borderColor = [UIColor yellowColor].CGColor;
        _captionLabel.layer.borderWidth = 1.0;
        _learnMoreButton.backgroundColor = [[UIColor blueColor] colorWithAlphaComponent:0.2];
        _learnMoreButton.layer.borderColor = [UIColor blueColor].CGColor;
        _learnMoreButton.layer.borderWidth = 1.0;
        _instructionLabel.backgroundColor = [[UIColor greenColor] colorWithAlphaComponent:0.2];
        _instructionLabel.layer.borderColor = [UIColor greenColor].CGColor;
        _instructionLabel.layer.borderWidth = 1.0;
        self.backgroundColor = [[UIColor purpleColor] colorWithAlphaComponent:0.2];
#endif
        [self setUpConstraints];
        [self setNeedsUpdateConstraints];
    }
    return self;
}

- (void)willMoveToWindow:(UIWindow *)newWindow {
    [super willMoveToWindow:newWindow];
    [self updateConstraintConstantsForWindow:newWindow];
    [self updateCaptionLabelPreferredWidth];
}

- (void)learnMoreAction:(id)sender {
    ORKSuppressPerformSelectorWarning(
                                      (void)[_learnMoreButtonItem.target performSelector:_learnMoreButtonItem.action withObject:self];
                                      );
}

- (void)setLearnMoreButtonItem:(UIBarButtonItem *)learnMoreButtonItem {
    _learnMoreButtonItem = learnMoreButtonItem;
    [_learnMoreButton setTitle:learnMoreButtonItem.title forState:UIControlStateNormal];
    _learnMoreButton.alpha = ([learnMoreButtonItem.title length] > 0) ? 1 : 0;
    [self updateConstraintConstantsForWindow:self.window];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGRect bounds = self.bounds;
    CGRect insetBounds = UIEdgeInsetsInsetRect(bounds, self.layoutMargins);
    
    ORKScreenType screenType = ORKGetScreenTypeForWindow(self.window);
    CGFloat sideMargin = ORKGetMetricForScreenType(ORKScreenMetricLearnMoreButtonSideMargin, screenType);
    _learnMoreButton.titleLabel.preferredMaxLayoutWidth = insetBounds.size.width - sideMargin*2;
}

- (void)updateConstraintConstantsForWindow:(UIWindow *)window {
    ORKScreenType screenType = ORKGetScreenTypeForWindow(window);
    
    const CGFloat IllustrationToCaptionBaseline = ORKGetMetricForScreenType(ORKScreenMetricIllustrationToCaptionBaseline, screenType);
    const CGFloat TopToCaptionBaseline = (ORKGetMetricForScreenType(ORKScreenMetricTopToCaptionBaseline, screenType) - AssumedStatusBarHeight - AssumedNavBarHeight);
    const CGFloat CaptionBaselineToInstructionBaseline_WithInstruction = ORKGetMetricForScreenType(ORKScreenMetricCaptionBaselineToInstructionBaseline, screenType);
    const CGFloat CaptionBaselineToInstructionBaseline_NoInstruction = MIN(26, CaptionBaselineToInstructionBaseline_WithInstruction); // Not part of spec
    const CGFloat InstructionBaselineToLearnMoreBaseline = ORKGetMetricForScreenType(ORKScreenMetricInstructionBaselineToLearnMoreBaseline, screenType);
    const CGFloat LearnMoreBaselineToStepViewTop = ORKGetMetricForScreenType(ORKScreenMetricLearnMoreBaselineToStepViewTop, screenType);
    const CGFloat InstructionBaselineToStepViewTopWithNoLearnMore = ORKGetMetricForScreenType(ORKScreenMetricLearnMoreBaselineToStepViewTopWithNoLearnMore, screenType);
    
    BOOL haveCaption = [_captionLabel.text length] > 0;
    BOOL haveInstruction = [_instructionLabel.text length] > 0;
    BOOL haveLearnMore = (_learnMoreButton.alpha > 0);
    ORKVerticalContainerLog(@"haveCaption=%@ haveInstruction=%@ haveLearnMore=%@", @(haveCaption), @(haveInstruction), @(haveLearnMore));
    
    // If one label is empty and the other is not, then allow the empty label to shrink to nothing
    // and the other label to grow to fill
    UILayoutPriority captionVerticalHugging = haveCaption && !haveInstruction ? UILayoutPriorityDefaultLow - 1 : UILayoutPriorityDefaultLow;
    UILayoutPriority instructionVerticalHugging = haveInstruction && !haveCaption ? UILayoutPriorityDefaultLow - 1 : UILayoutPriorityDefaultLow;
    [_captionLabel setContentHuggingPriority:captionVerticalHugging forAxis:UILayoutConstraintAxisVertical];
    [_instructionLabel setContentHuggingPriority:instructionVerticalHugging forAxis:UILayoutConstraintAxisVertical];
    
    {
        _headerZeroHeightConstraint.active = ! (haveCaption || haveInstruction || haveLearnMore);
    }
    
    {
        _illustrationToCaptionBaselineConstraint.constant = _hasContentAbove ? IllustrationToCaptionBaseline : TopToCaptionBaseline;
        _illustrationToCaptionBaselineConstraint.active = haveCaption;
        _illustrationToCaptionTopConstraint.constant = 0;
        _illustrationToCaptionTopConstraint.active = !haveCaption;
    }
    
    {
        _captionToInstructionConstraint.constant = haveInstruction ? CaptionBaselineToInstructionBaseline_WithInstruction : CaptionBaselineToInstructionBaseline_NoInstruction;
    }
    
    {
        _instructionToLearnMoreConstraint.constant = haveLearnMore ? InstructionBaselineToLearnMoreBaseline : 0;
    }
    
    {
        _learnMoreToStepViewConstraint.constant = LearnMoreBaselineToStepViewTop;
        _learnMoreToStepViewConstraint.active = haveLearnMore;
    }
    
    {
        _captionMinBottomSpacingConstraint.active = haveCaption && !(haveLearnMore || haveInstruction);
    }
    
    {
        _instructionMinBottomSpacingConstraint.constant = InstructionBaselineToStepViewTopWithNoLearnMore;
        _instructionMinBottomSpacingConstraint.active = haveInstruction && !(haveLearnMore);
    }
}

- (void)setHasContentAbove:(BOOL)hasContentAbove {
    _hasContentAbove = hasContentAbove;
    [self setNeedsUpdateConstraints];
}

- (void)setUpConstraints {
    NSMutableArray *constraints = [NSMutableArray array];

    // Fill all available horizontal space
    NSLayoutConstraint *widthConstraint = [NSLayoutConstraint constraintWithItem:self
                                                                  attribute:NSLayoutAttributeWidth
                                                                  relatedBy:NSLayoutRelationEqual
                                                                     toItem:nil
                                                                  attribute:NSLayoutAttributeNotAnAttribute
                                                                 multiplier:1.0
                                                                   constant:ORKScreenMetricMaxDimension];
    widthConstraint.priority = UILayoutPriorityDefaultLow - 1;
    [constraints addObject:widthConstraint];
    
    NSArray *views = @[_captionLabel, _instructionLabel, _learnMoreButton];
    [_captionLabel setContentHuggingPriority:UILayoutPriorityFittingSizeLevel forAxis:UILayoutConstraintAxisHorizontal];
    [_instructionLabel setContentHuggingPriority:UILayoutPriorityFittingSizeLevel forAxis:UILayoutConstraintAxisHorizontal];
    [_learnMoreButton setContentHuggingPriority:UILayoutPriorityFittingSizeLevel forAxis:UILayoutConstraintAxisHorizontal];
    ORKEnableAutoLayoutForViews(views);
    
    {
        _captionToInstructionConstraint = [NSLayoutConstraint constraintWithItem:_instructionLabel
                                                                       attribute:NSLayoutAttributeFirstBaseline
                                                                       relatedBy:NSLayoutRelationEqual
                                                                          toItem:_captionLabel
                                                                       attribute:NSLayoutAttributeLastBaseline
                                                                      multiplier:1.0
                                                                        constant:36.0];
        [constraints addObject:_captionToInstructionConstraint];
    }
    
    {
        _instructionToLearnMoreConstraint = [NSLayoutConstraint constraintWithItem:_learnMoreButton
                                                                         attribute:NSLayoutAttributeFirstBaseline
                                                                         relatedBy:NSLayoutRelationEqual
                                                                            toItem:_instructionLabel
                                                                         attribute:NSLayoutAttributeLastBaseline
                                                                        multiplier:1.0
                                                                          constant:30.0];
        [constraints addObject:_instructionToLearnMoreConstraint];
    }
    
    {
        _illustrationToCaptionBaselineConstraint = [NSLayoutConstraint constraintWithItem:_captionLabel
                                                                                attribute:NSLayoutAttributeFirstBaseline
                                                                                relatedBy:NSLayoutRelationEqual
                                                                                   toItem:self
                                                                                attribute:NSLayoutAttributeTop
                                                                               multiplier:1.0
                                                                                 constant:44.0];
        _illustrationToCaptionBaselineConstraint.priority = UILayoutPriorityRequired - 1;
        [constraints addObject:_illustrationToCaptionBaselineConstraint];
    }
    
    {
        _illustrationToCaptionTopConstraint = [NSLayoutConstraint constraintWithItem:_captionLabel
                                                                           attribute:NSLayoutAttributeTop
                                                                           relatedBy:NSLayoutRelationEqual
                                                                              toItem:self
                                                                           attribute:NSLayoutAttributeTop
                                                                          multiplier:1.0
                                                                            constant:0.0];
        _illustrationToCaptionTopConstraint.priority = UILayoutPriorityRequired - 1;
        [constraints addObject:_illustrationToCaptionTopConstraint];
    }
    
    {
        _learnMoreToStepViewConstraint = [NSLayoutConstraint constraintWithItem:self
                                                                      attribute:NSLayoutAttributeBottom
                                                                      relatedBy:NSLayoutRelationEqual
                                                                         toItem:_learnMoreButton
                                                                      attribute:NSLayoutAttributeLastBaseline
                                                                     multiplier:1.0
                                                                       constant:44.0];
        _learnMoreToStepViewConstraint.priority = UILayoutPriorityRequired - 1;
        [constraints addObject:_learnMoreToStepViewConstraint];
    }
    
    {
        _captionMinBottomSpacingConstraint = [NSLayoutConstraint constraintWithItem:self
                                                                          attribute:NSLayoutAttributeBottom
                                                                          relatedBy:NSLayoutRelationEqual
                                                                             toItem:_captionLabel
                                                                          attribute:NSLayoutAttributeLastBaseline
                                                                         multiplier:1.0
                                                                           constant:44.0];
        _captionMinBottomSpacingConstraint.priority = UILayoutPriorityDefaultHigh - 1;
        [constraints addObject:_captionMinBottomSpacingConstraint];
    }
    
    {
        _instructionMinBottomSpacingConstraint = [NSLayoutConstraint constraintWithItem:self
                                                                              attribute:NSLayoutAttributeBottom
                                                                              relatedBy:NSLayoutRelationEqual
                                                                                 toItem:_instructionLabel
                                                                              attribute:NSLayoutAttributeLastBaseline
                                                                             multiplier:1.0
                                                                               constant:44.0];
        _instructionMinBottomSpacingConstraint.priority = UILayoutPriorityDefaultHigh - 2;
        [constraints addObject:_instructionMinBottomSpacingConstraint];
    }
    
    for (UIView *view in views) {
        [constraints addObject:[NSLayoutConstraint constraintWithItem:view
                                                                 attribute:NSLayoutAttributeLeft
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:self
                                                                 attribute:NSLayoutAttributeLeftMargin
                                                                multiplier:1.0
                                                                  constant:0.0]];
        [constraints addObject:[NSLayoutConstraint constraintWithItem:view
                                                                 attribute:NSLayoutAttributeRight
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:self
                                                                 attribute:NSLayoutAttributeRightMargin
                                                                multiplier:1.0
                                                                  constant:0.0]];
        
        NSLayoutConstraint *bottomConstraint = [NSLayoutConstraint constraintWithItem:view
                                                                            attribute:NSLayoutAttributeBottom
                                                                            relatedBy:NSLayoutRelationLessThanOrEqual
                                                                               toItem:self
                                                                            attribute:NSLayoutAttributeBottom
                                                                           multiplier:1.0
                                                                             constant:0.0];
        bottomConstraint.priority = UILayoutPriorityDefaultHigh;
        // All views must fit inside, vertically
        [constraints addObject:bottomConstraint];
        
        [constraints addObject:[NSLayoutConstraint constraintWithItem:view
                                                                 attribute:NSLayoutAttributeTop
                                                                 relatedBy:NSLayoutRelationGreaterThanOrEqual
                                                                    toItem:self
                                                                 attribute:NSLayoutAttributeTop
                                                                multiplier:1.0
                                                                  constant:0.0]];
    
    }
    
    {
        // This constraint will only be set active if there is no content.
        // Priority is less than required, so that if it is temporarily active it doesn't cause an
        // exception.
        _headerZeroHeightConstraint = [NSLayoutConstraint constraintWithItem:self
                                                                   attribute:NSLayoutAttributeHeight
                                                                   relatedBy:NSLayoutRelationEqual
                                                                      toItem:nil
                                                                   attribute:NSLayoutAttributeNotAnAttribute
                                                                  multiplier:1.0
                                                                    constant:0.0];
        _headerZeroHeightConstraint.priority = UILayoutPriorityRequired - 1;
        [constraints addObject:_headerZeroHeightConstraint];
    }
    
    [NSLayoutConstraint activateConstraints:constraints];
}

- (void)updateConstraints {
    [self updateConstraintConstantsForWindow:self.window];
    [super updateConstraints];
}

@end
