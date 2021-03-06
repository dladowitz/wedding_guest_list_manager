//
//  WeddingInfoViewController.m
//  WeddingGuestListManager
//
//  Created by Sai Kante on 4/5/14.
//  Copyright (c) 2014 Team1. All rights reserved.
//

#import "WeddingInfoViewController.h"
#import "CreateWeddingViewController.h"
#import "SettingsViewController.h"
#import "GuestlistTableViewController.h"
#import "MessageCenterViewController.h"
#import "Guest.h"
#import "Event.h"

@interface WeddingInfoViewController ()
@property (weak, nonatomic) IBOutlet UILabel *weddingNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *guestsInvitedLabel;
@property (weak, nonatomic) IBOutlet UILabel *locationLabel;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@property (weak, nonatomic) IBOutlet UILabel *attendingLabel;
@property (weak, nonatomic) IBOutlet UILabel *declinedLabel;
@property (weak, nonatomic) IBOutlet UIView *guestlistButtonContainer;
@property (weak, nonatomic) IBOutlet UIView *sendMessageButtonContainer;
- (IBAction)onGuestlistButton:(id)sender;
- (IBAction)onSendMessageButton:(id)sender;
@property (strong, nonatomic) id eventObject;
@property (assign, nonatomic) BOOL firstTime;
@property (assign, nonatomic) BOOL newUser;

@end

@implementation WeddingInfoViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.firstTime = YES;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.title = @"Wedding Details";
    
    UIBarButtonItem *settingsButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"SettingsButton"] style:UIBarButtonItemStyleDone target:self action:@selector(onSettingsButton)];
    UIBarButtonItem *editButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(onEditButton)];
    self.navigationItem.rightBarButtonItem = settingsButton;
    self.navigationItem.leftBarButtonItem = editButton;
    
    self.guestlistButtonContainer.backgroundColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:0.25];
    self.sendMessageButtonContainer.backgroundColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:0.25];
    
    [self getEvent];
}

- (void)getEvent {
    PFQuery *query = [PFQuery queryWithClassName:@"Event"];
    [query whereKey:@"ownedBy" equalTo:[PFUser currentUser]];
    [query findObjectsInBackgroundWithBlock:^(NSArray *events, NSError *error) {
        if(!error && events.count > 0) {
            [Event currentEvent];
            [Event updateCurrentEventWithPFObject:events[0]];
            [self updateInfo];
            
        } else {
            self.newUser = YES;
            self.firstTime = NO;
            CreateWeddingViewController *createWeddingViewController = [[CreateWeddingViewController alloc] init];
            [self.navigationController pushViewController:createWeddingViewController animated:NO];
        }
    }];
}

- (void)viewDidAppear:(BOOL)animated {
    if (self.firstTime) {
        self.firstTime = NO;
    }
    else if(self.newUser) {
        self.newUser = NO;
        [self getEvent];
    }
    else {
        if ([Event currentEvent].eventPFObject != nil) {
            [self updateInfo];
        }
    }
}

- (void)updateInfo {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"MM/dd/yyyy"];
    NSDate *date = [Event currentEvent].date;
    NSString *dateString = [dateFormatter stringFromDate:date];
    
    [self.dateLabel setText:dateString];
    [self.weddingNameLabel setText:[Event currentEvent].title];
    [self.locationLabel setText:[Event currentEvent].location];

    PFQuery *guestsQuery = [PFQuery queryWithClassName:@"Guest"];
    [guestsQuery whereKey:@"eventId" equalTo:[Event currentEvent].eventPFObject];
    
    [guestsQuery findObjectsInBackgroundWithBlock:^(NSArray *results, NSError *error) {
        NSNumber *attendingCount = [NSNumber numberWithInt:0];
        NSNumber *decliningCount = [NSNumber numberWithInt:0];
        NSNumber *awaitingCount  = [NSNumber numberWithInt:0];
        NSNumber *invitedCount = [NSNumber numberWithInt:0];
        
        for(PFObject *guest in results) {
            if([guest[@"invitedStatus"] intValue] == GUEST_INVITED) {
                invitedCount = [NSNumber numberWithInt:[invitedCount intValue] + 1] ;
                if([guest[@"rsvpStatus"] intValue] == GUEST_NOT_RSVPED) {
                    awaitingCount = [NSNumber numberWithInt:[awaitingCount intValue] + 1 + [guest[@"extraGuests"] intValue]];
                }
                else if([guest[@"rsvpStatus"] intValue] == GUEST_RSVPED) {
                    attendingCount = [NSNumber numberWithInt:[attendingCount intValue] + 1 + [guest[@"extraGuests"] intValue]];
                }
                else if([guest[@"rsvpStatus"] intValue] == GUEST_DECLINED) {
                    decliningCount = [NSNumber numberWithInt:[decliningCount intValue] + 1 + [guest[@"extraGuests"] intValue]];
                }
            }
        }
        self.attendingLabel.text = [NSString stringWithFormat:@"%@ Attending", attendingCount];
        self.declinedLabel.text = [NSString stringWithFormat:@"%@ Declined", decliningCount];
        self.guestsInvitedLabel.text = [NSString stringWithFormat:@"%@ Invited", invitedCount];

    }];
}

- (void)onEditButton {
    CreateWeddingViewController *createWeddingViewController = [[CreateWeddingViewController alloc] initForEditing:YES];
    [self.navigationController pushViewController:createWeddingViewController animated:YES];
}

- (void)onSettingsButton {
    SettingsViewController *settingsViewController = [[SettingsViewController alloc] init];
    [self.navigationController pushViewController:settingsViewController animated:YES];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}


- (IBAction)onGuestlistButton:(id)sender {
    if([Event currentEvent].eventPFObject) {
        GuestlistTableViewController *guestlistTableViewController = [[GuestlistTableViewController alloc] init];
        [self.navigationController pushViewController:guestlistTableViewController animated:YES];
    }
}

- (IBAction)onSendMessageButton:(id)sender {
    if([Event currentEvent].eventPFObject) {
        MessageCenterViewController *messageCenterViewController = [[MessageCenterViewController alloc] init];
        [self.navigationController pushViewController:messageCenterViewController animated:YES];
    }
}

@end
