//
//  DSOReportback.h
//  Pods
//
//  Created by Ryan Grimm on 3/26/15.
//
//

#import <Foundation/Foundation.h>

typedef void (^DSOReportbackChangeStatusBlock)(NSError *error);

@interface DSOReportback : NSManagedObject

+ (DSOReportback *)syncWithDictionary:(NSDictionary *)values inContext:(NSManagedObjectContext *)context;

@property (nonatomic, readonly) NSInteger reportID;
@property (nonatomic, strong, readonly) NSString *title;
@property (nonatomic, strong, readonly) NSURL *imageURL;
@property (nonatomic, strong, readonly) NSString *imageCaption;
@property (nonatomic, readonly) NSInteger quantity;
@property (nonatomic, strong, readonly) NSString *quantityLabel;
@property (nonatomic, strong, readonly) NSString *participationReason;

@end
