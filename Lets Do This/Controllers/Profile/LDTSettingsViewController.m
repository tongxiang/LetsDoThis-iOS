//
//  LDTSettingsViewController.m
//  Lets Do This
//
//  Created by Ryan Grimm on 4/2/15.
//  Copyright (c) 2015 Do Something. All rights reserved.
//

#import "LDTSettingsViewController.h"
#import "DSOAPI.h"
#import "LDTButton.h"
#import "LDTMessage.h"
#import "LDTTheme.h"
#import "LDTUserConnectViewController.h"
#import "LDTUpdateAvatarViewController.h"

@interface LDTSettingsViewController()

@property (assign, nonatomic) BOOL isNotificationsEnabled;

// Properties listed in order of their appearance in the view.
@property (weak, nonatomic) IBOutlet UILabel *accountHeadingLabel;
@property (weak, nonatomic) IBOutlet UILabel *changePhotoLabel;
@property (weak, nonatomic) IBOutlet UILabel *logoutLabel;
@property (weak, nonatomic) IBOutlet UILabel *notificationsHeadingLabel;
@property (weak, nonatomic) IBOutlet UILabel *notificationsLabel;
@property (weak, nonatomic) IBOutlet UISwitch *notificationsSwitch;
@property (weak, nonatomic) IBOutlet UILabel *changeNotificationsLabel;
@property (weak, nonatomic) IBOutlet UILabel *changeNotificationsArrowLabel;
@property (weak, nonatomic) IBOutlet UILabel *rateLabel;
@property (weak, nonatomic) IBOutlet UILabel *rateArrowLabel;
@property (weak, nonatomic) IBOutlet UILabel *rateDisclaimerLabel;
@property (weak, nonatomic) IBOutlet UIButton *feedbackButton;
@property (weak, nonatomic) IBOutlet UILabel *versionLabel;
@property (weak, nonatomic) IBOutlet UIView *changePhotoView;
@property (weak, nonatomic) IBOutlet UIView *logoutView;
@property (weak, nonatomic) IBOutlet UIView *notificationSwitchView;

@end

@implementation LDTSettingsViewController

#pragma UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = [@"Settings" uppercaseString];
    self.notificationsSwitch.enabled = FALSE;

    [self styleView];

    UITapGestureRecognizer *changePhotoTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleChangePhotoTap:)];
    [self.changePhotoView addGestureRecognizer:changePhotoTap];
    UITapGestureRecognizer *logoutTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleLogoutTap:)];
    [self.logoutView addGestureRecognizer:logoutTap];
    UITapGestureRecognizer *notificationSwitchTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleNotificationSwitchTap:)];
    [self.notificationSwitchView addGestureRecognizer:notificationSwitchTap];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    UIUserNotificationSettings *grantedSettings = [[UIApplication sharedApplication] currentUserNotificationSettings];
    self.isNotificationsEnabled = (grantedSettings.types != UIUserNotificationTypeNone);
    [self.notificationsSwitch setOn:self.isNotificationsEnabled];
}

#pragma LDTSettingsViewController

- (void)styleView {
    [self.navigationController styleNavigationBar:LDTNavigationBarStyleNormal];
    [self styleBackBarButton];

    self.accountHeadingLabel.font = [LDTTheme fontBold];
    self.accountHeadingLabel.textColor = [LDTTheme mediumGrayColor];
    self.changePhotoLabel.font = [LDTTheme font];
    self.logoutLabel.font = [LDTTheme font];
    self.notificationsHeadingLabel.font = [LDTTheme fontBold];
    self.notificationsHeadingLabel.textColor = [LDTTheme mediumGrayColor];
    self.notificationsLabel.font = [LDTTheme font];
    self.changeNotificationsLabel.font = [LDTTheme font];
    self.changeNotificationsArrowLabel.font = [LDTTheme font];
    self.changeNotificationsArrowLabel.textColor = [LDTTheme mediumGrayColor];
    
    
    self.rateLabel.font = [LDTTheme font];
    self.rateArrowLabel.font = [LDTTheme font];
    self.rateArrowLabel.textColor = [LDTTheme mediumGrayColor];
    self.rateDisclaimerLabel.font = [LDTTheme font];
    [self.feedbackButton.titleLabel setFont:[LDTTheme font]];
    [self.versionLabel setFont:[LDTTheme font]];
    self.versionLabel.text = [NSString stringWithFormat:@"Version %@",[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]];
}

- (void)handleChangePhotoTap:(UITapGestureRecognizer *)recognizer {
    LDTUpdateAvatarViewController *destVC = [[LDTUpdateAvatarViewController alloc] initWithNibName:@"LDTUpdateAvatarView" bundle:nil];
    [self.navigationController pushViewController:destVC animated:YES];
}

- (void)handleNotificationSwitchTap:(UITapGestureRecognizer *)recognizer {
    NSString *alertControllerMessage;
    if (!self.isNotificationsEnabled) {
        alertControllerMessage = @"You've disabled Notifications for Let's Do This. You can turn them on in the Notifications section of the Settings app.";
    }
    else {
        alertControllerMessage = @"You've enabled Notifications for Let's Do This. You can turn them off in the Notifications section of the Settings app.";
    }
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Recieve Notifications" message:alertControllerMessage preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleCancel handler:^(UIAlertAction * action) {
        [alertController dismissViewControllerAnimated:YES completion:nil];
    }];

    [alertController addAction:okAction];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)handleLogoutTap:(UITapGestureRecognizer *)recognizer {
    UIAlertController *logoutAlertController = [UIAlertController alertControllerWithTitle:@"Are you sure? We’ll miss you." message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction *confirmLogoutAction = [UIAlertAction actionWithTitle:@"Logout" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
        [SVProgressHUD show];
        [[DSOUserManager sharedInstance] endSessionWithCompletionHandler:^ {
            // This VC is always presented within the TabBarVC, so kill it.
            [self dismissViewControllerAnimated:YES completion:^{
                [SVProgressHUD dismiss];
                UINavigationController *destVC = [[UINavigationController alloc] initWithRootViewController:[[LDTUserConnectViewController alloc] init]];
                [destVC styleNavigationBar:LDTNavigationBarStyleClear];
                [LDTMessage setDefaultViewController:destVC];
                [[[[UIApplication sharedApplication] keyWindow] rootViewController] presentViewController:destVC animated:NO completion:nil];
            }];
        } errorHandler:^(NSError *error) {
            [SVProgressHUD dismiss];
            [LDTMessage displayErrorMessageForError:error];
        }];
    }];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * action) {
            [logoutAlertController dismissViewControllerAnimated:YES completion:nil];
    }];
    [logoutAlertController addAction:confirmLogoutAction];
    [logoutAlertController addAction:cancelAction];
    [self presentViewController:logoutAlertController animated:YES completion:nil];
}

@end
