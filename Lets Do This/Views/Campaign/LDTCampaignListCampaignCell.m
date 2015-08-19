//
//  LDTCampaignListCampaignCell.m
//  Lets Do This
//
//  Created by Aaron Schachter on 8/7/15.
//  Copyright (c) 2015 Do Something. All rights reserved.
//

#import "LDTCampaignListCampaignCell.h"

@interface LDTCampaignListCampaignCell()

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIView *actionView;
@property (weak, nonatomic) IBOutlet UILabel *taglineLabel;
@property (weak, nonatomic) IBOutlet UILabel *expiresLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *titleLabelTopLayoutConstraint;

@end

@implementation LDTCampaignListCampaignCell

- (void)awakeFromNib {
    [self styleView];
}

- (void)styleView {
    self.titleLabel.numberOfLines = 0;
    self.titleLabel.font = [LDTTheme fontBoldWithSize:24];
    self.taglineLabel.font = [LDTTheme font];

    // @todo Split out expiresLabel into 2 separate UILabels for diff colors
    self.expiresLabel.font = [LDTTheme fontBold];
    self.expiresLabel.textColor = [UIColor grayColor];
    self.titleLabel.textColor = [UIColor whiteColor];
    [self.actionButton enable];
    [self.imageView addGrayTint];
}

- (void)displayForCampaign:(DSOCampaign *)campaign {
    self.titleLabel.text = [campaign.title uppercaseString];
    self.taglineLabel.text = campaign.tagline;
    [self.imageView sd_setImageWithURL:campaign.coverImageURL];

    NSString *actionButtonTitle = @"Do this now";
    if ([[DSOUserManager sharedInstance].user isDoingCampaign:campaign]) {
        actionButtonTitle = @"Prove it";
    }
    [self.actionButton setTitle:[actionButtonTitle uppercaseString] forState:UIControlStateNormal];

    // @todo: Split expiresLabel into 2.
    NSString *expiresString = @"";
    if ([campaign numberOfDaysLeft] > 0) {
        expiresString = [NSString stringWithFormat:@"Expires in %li Days", (long)[campaign numberOfDaysLeft]];
    }
    self.expiresLabel.text = [expiresString uppercaseString];
}
@end