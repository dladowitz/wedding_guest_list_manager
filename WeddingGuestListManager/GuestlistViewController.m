//
//  GuestlistViewController.m
//  WeddingGuestListManager
//
//  Created by David Ladowitz on 4/12/14.
//  Copyright (c) 2014 Team1. All rights reserved.
//

#import "GuestlistViewController.h"
#import <Parse/Parse.h>

@interface GuestlistViewController ()
@property (weak, nonatomic) IBOutlet UILabel *firstNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *lastNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *phoneNumberLabel;
@property (weak, nonatomic) IBOutlet UILabel *emailAddressLabel;

- (IBAction)onImportButton:(id)sender;

@end

@implementation GuestlistViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Configure the Navigation Bar
        self.navigationItem.title = @"Guest List";
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Add" style:UIBarButtonItemStyleDone target:self action:@selector(onAddButton)];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)onAddButton{
    NSLog(@"Adding Guest");
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)onImportButton:(id)sender {
    ABPeoplePickerNavigationController *pickerNavigationController = [[ABPeoplePickerNavigationController alloc] init];
    pickerNavigationController.peoplePickerDelegate = self;
    
//    [self presentModalViewController:pickerNavigationController animated:YES];
    [self presentViewController:pickerNavigationController animated:YES completion:NULL];
}

- (void)peoplePickerNavigationControllerDidCancel:
(ABPeoplePickerNavigationController *)peoplePicker
{
    [self dismissViewControllerAnimated:YES completion:nil];
}


- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker
      shouldContinueAfterSelectingPerson:(ABRecordRef)person
{
    [self displayPerson:person];
    [self dismissViewControllerAnimated:YES completion:nil];
    
    return NO;
}

- (BOOL)peoplePickerNavigationController: (ABPeoplePickerNavigationController *)peoplePicker
      shouldContinueAfterSelectingPerson:(ABRecordRef)person
                                property:(ABPropertyID)property
                              identifier:(ABMultiValueIdentifier)identifier
{
    return NO;
}

- (void)displayPerson:(ABRecordRef)person
{
    // Create a guest from Address Book
    PFObject *newGuest = [PFObject objectWithClassName:@"Guest"];

    NSString* firstName = (__bridge_transfer NSString*)ABRecordCopyValue(person, kABPersonFirstNameProperty);
    self.firstNameLabel.text = firstName;
    if (firstName) {
        newGuest[@"firstName"]   = firstName;
    }

    NSString* lastName = (__bridge_transfer NSString*)ABRecordCopyValue(person, kABPersonLastNameProperty);
    self.lastNameLabel.text = lastName;
    if (lastName) {
        newGuest[@"lastName"]   = lastName;
    }
    
    ABMultiValueRef emailMultiValue = ABRecordCopyValue(person, kABPersonEmailProperty);
    NSArray *emailAddresses = (__bridge_transfer NSArray*)ABMultiValueCopyArrayOfAllValues(emailMultiValue);
    self.emailAddressLabel.text = emailAddresses[0];
    if (emailAddresses[0]) {
        newGuest[@"email"] = emailAddresses[0];
    }

    NSString* phone = nil;
    ABMultiValueRef phoneNumbers = ABRecordCopyValue(person, kABPersonPhoneProperty);
    if (ABMultiValueGetCount(phoneNumbers) > 0) {
        phone = (__bridge_transfer NSString*)ABMultiValueCopyValueAtIndex(phoneNumbers, 0);
    } else {
        phone = @"[None]";
    }
    self.phoneNumberLabel.text = phone;
    if (phone) {
        newGuest[@"phoneNumber"] = phone;
    }
    CFRelease(phoneNumbers);
    
    // Add ownedBy Relation
    PFRelation *relation = [newGuest relationforKey:@"eventId"];
    
    // Find event owned by current user
    PFQuery *query = [PFQuery queryWithClassName:@"Event"];
    [query whereKey:@"ownedBy" equalTo: [PFUser currentUser]];
    
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if(!error && objects && objects.count > 0){
            // Add Event to relation
            [relation addObject:objects[0]];
            
            // Save to Parse
            [newGuest  saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                NSLog(@"Saved Guest: %@ %@ to Parse", firstName, lastName);
            }];
            
        } else if (error)  {
            NSLog(@"Error: %@", error);
        } else {
            NSLog(@"Can't find event properly. It's probably your fault");
        }
        
    }];
}



@end
