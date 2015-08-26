//
//  LDTUserRegisterViewController.m
//  Lets Do This
//
//  Created by Aaron Schachter on 6/26/15.
//  Copyright (c) 2015 Do Something. All rights reserved.
//

#import "LDTUserRegisterViewController.h"
#import "LDTUserSignupCodeView.h"
#import "LDTTheme.h"
#import "LDTButton.h"
#import "LDTMessage.h"
#import "LDTTabBarController.h"
#import "LDTUserLoginViewController.h"
#import "DSOUserManager.h"
#import "UITextField+LDT.h"

@interface LDTUserRegisterViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) DSOUser *user;
@property (strong, nonatomic) NSString *avatarFilestring;
@property (strong, nonatomic) NSString *countryCode;
@property (strong, nonatomic) UIDatePicker *datePicker;
@property (strong, nonatomic) UIImagePickerController *imagePicker;

@property (weak, nonatomic) IBOutlet LDTButton *loginLink;
@property (weak, nonatomic) IBOutlet LDTButton *submitButton;
@property (weak, nonatomic) IBOutlet LDTUserSignupCodeView *signupCodeView;
@property (weak, nonatomic) IBOutlet UIButton *avatarButton;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UILabel *headerLabel;
@property (weak, nonatomic) IBOutlet UITextField *firstNameTextField;
@property (weak, nonatomic) IBOutlet UITextField *emailTextField;
@property (weak, nonatomic) IBOutlet UITextField *mobileTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (weak, nonatomic) IBOutlet UILabel *footerLabel;

- (IBAction)avatarButtonTouchUpInside:(id)sender;
- (IBAction)submitButtonTouchUpInside:(id)sender;
- (IBAction)loginLinkTouchUpInside:(id)sender;

- (IBAction)firstNameEditingDidBegin:(id)sender;
- (IBAction)emailEditingDidBegin:(id)sender;
- (IBAction)mobileEditingDidBegin:(id)sender;
- (IBAction)passwordEditingDidBegin:(id)sender;

- (IBAction)firstNameEditingDidEnd:(id)sender;
- (IBAction)emailEditingDidEnd:(id)sender;
- (IBAction)mobileEditingDidEnd:(id)sender;
- (IBAction)passwordEditingDidEnd:(id)sender;

@end

@implementation LDTUserRegisterViewController

#pragma mark - NSObject

- (instancetype)initWithUser:(DSOUser *)user {
    self = [super initWithNibName:@"LDTUserRegisterView" bundle:nil];

    if (self) {
        self.user = user;
    }
    
    return self;
}

#pragma mark - UIViewController

- (void)viewDidLoad {
	[super viewDidLoad];

    [self.submitButton setTitle:[@"Create account" uppercaseString] forState:UIControlStateNormal];
    [self.submitButton disable];
    [self.loginLink setTitle:@"Have a DoSomething.org account? Sign in" forState:UIControlStateNormal];
    
    self.footerLabel.adjustsFontSizeToFitWidth = NO;
    self.footerLabel.numberOfLines = 0;
    self.footerLabel.text = @"Creating an account means you agree to our Privacy Policy & to receive our weekly update. Message & data rates may apply. Text STOP to opt-out, HELP for help.";

    self.imagePicker = [[UIImagePickerController alloc] init];
    self.imagePicker.delegate = self;
    self.imagePicker.allowsEditing = YES;

    // If we have a User, it's from Facebook.

    if (self.user) {
        self.headerLabel.numberOfLines = 0;
        self.headerLabel.text = @"Confirm your Facebook details and set your password.";

        [self setAvatar:self.user.photo];
        self.firstNameTextField.text = self.user.firstName;
        self.emailTextField.text = self.user.email;
    }
    else {
        self.headerLabel.text = @"Tell us about yourself!";
        self.imageView.image = [UIImage imageNamed:@"Upload Button"];
    }


    self.textFields = @[self.firstNameTextField,
                        self.emailTextField,
                        self.mobileTextField,
                        self.passwordTextField,
                        self.signupCodeView.firstTextField,
                        self.signupCodeView.secondTextField,
                        self.signupCodeView.thirdTextField
                        ];
    for (UITextField *aTextField in self.textFields) {
        aTextField.delegate = self;
    }

    self.textFieldsRequired = @[self.firstNameTextField,
                                self.emailTextField,
                                self.passwordTextField];

    [self styleView];
    
    [self determineUserLocation];

    // @todo: Set mediatypes as images only (not video).
}

#pragma mark - CLLocationManagerDelegate

- (void)determineUserLocation {
    self.locationManager = [[CLLocationManager alloc] init]; // initializing locationManager
    self.locationManager.delegate = self;
    self.locationManager.distanceFilter = kCLDistanceFilterNone;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers; // most coarse-grained accuracy setting
    
    if ([self.locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
        [self.locationManager requestWhenInUseAuthorization];
    }
}

- (void)locationManager:(CLLocationManager*)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    if (status == kCLAuthorizationStatusAuthorizedWhenInUse) {
        [self.locationManager startUpdatingLocation];
    }
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    CLLocation *location = [locations lastObject];
    CLGeocoder *geocoder = [[CLGeocoder alloc] init];
    [geocoder reverseGeocodeLocation:location completionHandler:^(NSArray *placemarks, NSError *error) {
        if (!error) {
            self.countryCode = [placemarks[0] ISOcountryCode];
        }
    }];
    [manager stopUpdatingLocation];
}

#pragma mark - LDTUserRegisterViewController

- (void)styleView {
    self.view.backgroundColor = [UIColor colorWithPatternImage:[LDTTheme fullBackgroundImage]];

    UIFont *font = [LDTTheme font];
    for (UITextField *aTextField in self.textFields) {
        aTextField.font = font;
    }

    [self.firstNameTextField setKeyboardType:UIKeyboardTypeNamePhonePad];
    [self.emailTextField setKeyboardType:UIKeyboardTypeEmailAddress];
    [self.mobileTextField setKeyboardType:UIKeyboardTypeNumberPad];

    self.footerLabel.font = font;
    self.footerLabel.textAlignment = NSTextAlignmentCenter;
    self.footerLabel.textColor = [UIColor whiteColor];
    
    self.headerLabel.font = font;
    self.headerLabel.textAlignment = NSTextAlignmentCenter;
    self.headerLabel.textColor = [UIColor whiteColor];
    [self.loginLink setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
}

- (IBAction)submitButtonTouchUpInside:(id)sender {
    if ([self validateForm]) {
        
        // Create the user.
        [[DSOAPI sharedInstance] createUserWithEmail:self.emailTextField.text password:self.passwordTextField.text firstName:self.firstNameTextField.text mobile:self.mobileTextField.text countryCode:self.countryCode success:^(NSDictionary *response) {

            // Login the user.
            [[DSOUserManager sharedInstance] createSessionWithEmail:self.emailTextField.text password:self.passwordTextField.text completionHandler:^(DSOUser *user) {
                
                // Set avatar photo to newly created user object.
                [[DSOUserManager sharedInstance].user setPhotoWithImage:self.imageView.image];

                // POST avatar to API.
                [[DSOAPI sharedInstance] postUserAvatarWithUserId:[DSOUserManager sharedInstance].user.userID avatarImage:self.imageView.image completionHandler:^(id responseObject) {
                    NSLog(@"Successful user avatar upload: %@", responseObject);
                } errorHandler:^(NSError * error) {
                    [LDTMessage displayErrorMessageForError:error];
                }];

                // This VC is always presented within a NavVC, so kill it.
                [self dismissViewControllerAnimated:YES completion:^{

                    LDTTabBarController *destVC = [[LDTTabBarController alloc] init];
                    [[[[UIApplication sharedApplication] keyWindow] rootViewController] presentViewController:destVC animated:NO completion:nil];
                    
                }];

            } errorHandler:^(NSError *error) {
                [LDTMessage displayErrorMessageForError:error];
            }];

        } failure:^(NSError *error) {
            [LDTMessage displayErrorMessageForError:error];
        }];

    }
    else {
        [self.submitButton disable];
    }
}

- (IBAction)firstNameEditingDidBegin:(id)sender {
    [self.firstNameTextField setBorderColor:[UIColor clearColor]];
}

- (IBAction)emailEditingDidBegin:(id)sender {
    [self.emailTextField setBorderColor:[UIColor clearColor]];
}

- (IBAction)mobileEditingDidBegin:(id)sender {
    [self.mobileTextField setBorderColor:[UIColor clearColor]];
}

- (IBAction)passwordEditingDidBegin:(id)sender {
    [self.passwordTextField setBorderColor:[UIColor clearColor]];
}

- (IBAction)firstNameEditingDidEnd:(id)sender {
    UITextField *textField = (UITextField *)sender;
    self.firstNameTextField.text = [textField.text capitalizedString];
    [self updateCreateAccountButton];
}

- (IBAction)emailEditingDidEnd:(id)sender {
    [self updateCreateAccountButton];
}

- (IBAction)mobileEditingDidEnd:(id)sender {
    // Don't need to do anything for now, as mobile is optional.
    // Potentially could format data to look better.
}

- (IBAction)passwordEditingDidEnd:(id)sender {
    [self updateCreateAccountButton];
}

-(void)updateCreateAccountButton {
    BOOL enabled = NO;
    for (UITextField *aTextField in self.textFieldsRequired) {
        if (aTextField.text.length > 0) {
            enabled = YES;
        }
        else {
            enabled = NO;
            break;
        }
    }
    if (enabled) {
        [self.submitButton enable];
    }
    else {
        [self.submitButton disable];
    }
}

- (BOOL)validateForm {
    
    NSMutableArray *errorMessages = [[NSMutableArray alloc] init];;

    if (![self validateName:self.firstNameTextField.text]) {
        [self.firstNameTextField setBorderColor:[UIColor redColor]];
        [errorMessages addObject:@"We need your first name."];
    }
    if (![self validateEmail:self.emailTextField.text]) {
        [self.emailTextField setBorderColor:[UIColor redColor]];
        [errorMessages addObject:@"We need a valid email."];
    }
    if (![self validateMobile:self.mobileTextField.text]) {
        [self.mobileTextField setBorderColor:[UIColor redColor]];
        [errorMessages addObject:@"Enter a valid telephone number."];
    }
    if (![self validatePassword:self.passwordTextField.text]) {
        [self.passwordTextField setBorderColor:[UIColor redColor]];
        [errorMessages addObject:@"Password must be 6+ characters."];
    }

    if ([errorMessages count] > 0) {
        NSString *errorMessage = [[errorMessages copy] componentsJoinedByString:@"\n"];
        [LDTMessage displayErrorMessageForString:errorMessage];
        return NO;
    }
    return YES;
}

- (BOOL)validateName:(NSString *)candidate {
    if (candidate.length < 2) {
        return NO;
    }
    // Returns NO if candidate contains any numbers.
    return ([candidate rangeOfCharacterFromSet:[NSCharacterSet decimalDigitCharacterSet]].location == NSNotFound);
}

- (BOOL)validateMobile:(NSString *)candidate {
    if ([candidate isEqualToString:@""]) {
        return YES;
    }
    return (candidate.length >= 7 && candidate.length < 16);
}

- (BOOL)validatePassword:(NSString *)candidate {
    if (candidate.length < 6) {
        return NO;
    }
    return YES;
}

- (IBAction)avatarButtonTouchUpInside:(id)sender {
    [self getImageMenu];
}

- (void)getImageMenu {
    UIAlertController *view = [UIAlertController alertControllerWithTitle:@"Set your photo" message:nil                                                              preferredStyle:UIAlertControllerStyleActionSheet];

    UIAlertAction *camera;
    // Is camera is available?
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        camera = [UIAlertAction actionWithTitle:@"Take Photo" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action){
            self.imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
            [self presentViewController:self.imagePicker animated:YES completion:NULL];
        }];
    }
    else {
        camera = [UIAlertAction actionWithTitle:@"(Camera Unavailable)" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action){
            [view dismissViewControllerAnimated:YES completion:nil];
        }];
    }


    UIAlertAction *library = [UIAlertAction actionWithTitle:@"Choose From Library" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action){

        self.imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        [self presentViewController:self.imagePicker animated:YES completion:NULL];

    }];

    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * action) {
        [view dismissViewControllerAnimated:YES completion:nil];
    }];

    [view addAction:camera];
    [view addAction:library];
    [view addAction:cancel];
    [self presentViewController:view animated:YES completion:nil];
}

- (void)setAvatar:(UIImage *)image {
    self.imageView.image = image;
    [self.imageView addCircleFrame];
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    UIImage *chosenImage = info[UIImagePickerControllerEditedImage];
    [self setAvatar:chosenImage];
    self.avatarFilestring = [UIImagePNGRepresentation(chosenImage) base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
    [picker dismissViewControllerAnimated:YES completion:NULL];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:NULL];
}

- (IBAction)loginLinkTouchUpInside:(id)sender {
    LDTUserLoginViewController *destVC = [[LDTUserLoginViewController alloc] initWithNibName:@"LDTUserLoginView" bundle:nil];
    [self.navigationController pushViewController:destVC animated:YES];
}

@end
