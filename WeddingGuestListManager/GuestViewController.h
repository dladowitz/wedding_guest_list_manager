//
//  GuestViewController.h
//  WeddingGuestListManager
//
//  Created by David Ladowitz on 4/19/14.
//  Copyright (c) 2014 Team1. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Guest.h"

@interface GuestViewController : UIViewController <UITextFieldDelegate>

@property(nonatomic,strong) Guest *currentGuest;

@end