//
//  DSOAPI.m
//  Lets Do This
//
//  Created by Aaron Schachter on 7/16/15.
//  Copyright (c) 2015 Do Something. All rights reserved.
//

#import "DSOAPI.h"
#import "AFNetworkActivityLogger.h"
#import <SSKeychain/SSKeychain.h>
#import "DSOCampaign.h"

// API Constants
#define isActivityLogging YES
#define DSOPROTOCOL @"http"
#define DSOSERVER @"staging.beta.dosomething.org"
#define LDTSERVER @"northstar-qa.dosomething.org"

@interface DSOAPI()
@property (nonatomic, strong) NSMutableDictionary *campaigns;
@property (nonatomic, strong) NSString *phoenixBaseURL;
@property (nonatomic, strong) NSString *phoenixApiURL;
@end

@implementation DSOAPI

#pragma Singleton

+ (DSOAPI *)sharedInstance {
    static DSOAPI *_sharedInstance = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // @todo: Don't do it this way.
        _sharedInstance = [[self alloc] initWithApiKey:@"VmelybfGig4WWEn0I8iHrijgAM0bf8ERvgmt5BLp"];
    });

    return _sharedInstance;
}

#pragma NSObject

- (instancetype)initWithApiKey:(NSString *)apiKey {

    NSURL *baseURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@://%@/v1/", DSOPROTOCOL, LDTSERVER]];
    self = [super initWithBaseURL:baseURL];

    if (self != nil) {

        if (isActivityLogging) {
            [[AFNetworkActivityLogger sharedLogger] startLogging];
            [[AFNetworkActivityLogger sharedLogger] setLevel:AFLoggerLevelDebug];
        }

        self.responseSerializer = [AFJSONResponseSerializer serializer];
        self.requestSerializer = [AFJSONRequestSerializer serializer];
        [self.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Accept"];
        [self.requestSerializer setValue:@"ios" forHTTPHeaderField:@"X-DS-Application-Id"];
        [self.requestSerializer setValue:apiKey forHTTPHeaderField:@"X-DS-REST-API-Key"];
        self.phoenixBaseURL =  [NSString stringWithFormat:@"%@://%@/", DSOPROTOCOL, DSOSERVER];
        self.phoenixApiURL = [NSString stringWithFormat:@"%@api/v1/", self.phoenixBaseURL];
        self.campaigns = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (NSString *)pheonixBaseUrl {
    return self.phoenixBaseURL;
}

#pragma DSOAPI

- (NSString *)getSessionToken {
    return [SSKeychain passwordForService:LDTSERVER account:@"Session"];
}

- (void)setSessionToken:(NSString *)token {
    [self.requestSerializer setValue:token forHTTPHeaderField:@"Session"];
}

- (NSDictionary *)getCampaigns {
    return self.campaigns;
}

- (void)setCampaignsFromDict:(NSDictionary *)dict {
    for (NSDictionary* campaignDict in dict) {
        DSOCampaign *campaign = [[DSOCampaign alloc] initWithDict:campaignDict];
        [self.campaigns setValue:campaign forKey:campaignDict[@"id"]];
    }
}



- (void)createUserWithEmail:(NSString *)email
                   password:(NSString *)password
                  firstName:(NSString *)firstName
                   lastName:(NSString *)lastName
                     mobile:(NSString *)mobile
                  birthdate:(NSString *)dateStr
                    success:(void(^)(NSDictionary *))completionHandler
                    failure:(void(^)(NSError *))errorHandler {

    NSDictionary *params = @{@"email": email,
                             @"password": password,
                             @"first_name": firstName,
                             @"last_name": lastName,
                             @"mobile":mobile,
                             @"birthdate": dateStr};

    [self POST:@"users?create_drupal_user=1"
    parameters:params
       success:^(NSURLSessionDataTask *task, id responseObject) {
           if (completionHandler) {
               completionHandler(responseObject);
           }
       }
       failure:^(NSURLSessionDataTask *task, NSError *error) {
           if (errorHandler) {
               errorHandler(error);
           }
           [self logError:error];
       }];
}

// General methods:

- (void)fetchUserWithEmail:(NSString *)email
         completionHandler:(void(^)(NSDictionary *))completionHandler
              errorHandler:(void(^)(NSError *))errorHandler {

    [self GET:[NSString stringWithFormat:@"users/email/%@", email]
   parameters:nil
      success:^(NSURLSessionDataTask *task, id responseObject) {
          if (completionHandler) {
              completionHandler(responseObject);
          }
      }
      failure:^(NSURLSessionDataTask *task, NSError *error) {
          if (errorHandler) {
              errorHandler(error);
          }
          [self logError:error];
      }];
}

- (void)fetchCampaignsWithCompletionHandler:(void(^)(NSDictionary *))completionHandler
                               errorHandler:(void(^)(NSError *))errorHandler {
    NSString *url = [NSString stringWithFormat:@"%@%@", self.phoenixApiURL, @"campaigns.json?mobile_app=true"];
    [self GET:url
   parameters:nil
      success:^(NSURLSessionDataTask *task, id responseObject) {

          [self setCampaignsFromDict:responseObject[@"data"]];

          if (completionHandler) {
              completionHandler(responseObject);
          }
    }
    failure:^(NSURLSessionDataTask *task, NSError *error) {
        if (errorHandler) {
            errorHandler(error);
        }
        [self logError:error];
    }];
}

- (void)logError:(NSError *)error {
    NSLog(@"logError: %@", error.localizedDescription);
}


@end
