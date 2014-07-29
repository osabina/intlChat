//
//  User.m
//  IntlChat
//
//  Created by Osvaldo Sabina on 7/20/14.
//  Copyright (c) 2014 stephanimoroni. All rights reserved.
//


#import <Parse/PFObject+Subclass.h>
#import "User.h"

@implementation User

@dynamic language;
@dynamic fullName;
@dynamic profileImageURL;


+ (User *)user {
    return (User *) [super user];
}

+ (void) signupNewUser: (NSString *)username withPassword: (NSString *)password
            withEmail: (NSString *)email withLanguage: (NSString *)lang
           withFullName: (NSString *) name {
    
    User *myuser = (User *) [User user];
    myuser.username = username;
    myuser.password = password;
    myuser.email = email;
    myuser.language = lang;
    myuser.fullName = name;

    [myuser signUpInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (!error) {
            // Hooray! Let them use the app now.
        } else {
            NSString *errorString = [error userInfo][@"error"];
            NSLog(@"Error signing up: %@", errorString);
        }
    }];
}

-(NSString *)firstName {
    // By convention, we'll call this the first "word"
    NSArray *names = [self namesArray];
    if ( [names count] > 0) {
        return names[0];
    } else {
        return self.fullName;
    }
}

-(NSString *)lastName {
    // By convention, we'll call this everything but the first "word".  This
    // should handle names like 'de Rossi'.
    NSArray *names = [self namesArray];
    NSString *last = @"";
    
    // And this handles 'Sting'
    if ([names count] > 1) {
        last = [[names subarrayWithRange:(NSRange){1, [names count]-1}] componentsJoinedByString:@" "];
    }
    return last;
    
}

-(NSArray *)namesArray {
    return [self.fullName componentsSeparatedByString:@" "];
}

-(void)friendsWithCompletion:(void(^)(NSArray *friends))callback {
    NSMutableArray *myFriends = [[NSMutableArray alloc] init];
    
    PFQuery *wasFriender = [PFQuery queryWithClassName:@"Friend"];
    [wasFriender whereKey:@"friender" equalTo:self];
    [wasFriender whereKey:@"accepted" equalTo:[NSNumber numberWithBool:YES]];
    
    PFQuery *wasFriendee = [PFQuery queryWithClassName:@"Friend"];
    [wasFriendee whereKey:@"friendee" equalTo:self];
    [wasFriendee whereKey:@"accepted" equalTo:[NSNumber numberWithBool:YES]];
    
    PFQuery *query = [PFQuery orQueryWithSubqueries:@[wasFriender,wasFriendee]];
    [query includeKey:@"friender"];
    [query includeKey:@"friendee"];    
    [query findObjectsInBackgroundWithBlock:^(NSArray *results, NSError *error) {
        if (!error) {
            NSLog(@"Successfully retrieved %d friends.", results.count);
            for (PFObject *obj in results) {
                if ([obj[@"friender"][@"username"] isEqual:self.username]) {
                    [myFriends addObject: obj[@"friendee"]];
                } else { //friendee
                    [myFriends addObject: obj[@"friender"]];
                }
            }
            callback(myFriends);
        } else {
            // Log details of the failure
            NSLog(@"Error: %@ %@", error, [error userInfo]);
        }
}];
    
}

-(void)allUsersWithCompletion:(void(^)(NSArray *users))callback {    
    PFQuery *query = [User query];

    [query whereKey:@"username" notEqualTo: self.username];
    [query orderByAscending:@"fullName"];

    //query.limit = 20; // arbitrary for now
    
    [query findObjectsInBackgroundWithBlock:^(NSArray *results, NSError *error) {
        if (!error) {
            // The find succeeded.
            NSLog(@"Successfully retrieved %d users.", results.count);
            callback(results);
        } else {
            // Log details of the failure
            NSLog(@"Error: %@ %@", error, [error userInfo]);
        }
    }];
}

-(void)chatsWithCompletion:(void(^)(NSArray *chats))callback {

    PFQuery *wasChatter = [PFQuery queryWithClassName:@"Chat"];
    [wasChatter whereKey:@"chatter" equalTo:self];

    PFQuery *wasChattee = [PFQuery queryWithClassName:@"Chat"];
    [wasChatter whereKey:@"chattee" equalTo:self];

    PFQuery *query = [PFQuery orQueryWithSubqueries:@[wasChatter,wasChattee]];
    [query includeKey:@"chatter"];
    [query includeKey:@"chattee"];
    [query findObjectsInBackgroundWithBlock:^(NSArray *results, NSError *error) {
        if (!error) {
            // The find succeeded.
            NSLog(@"Successfully retrieved %d users.", results.count);
            callback(results);
         } else {
            // Log details of the failure
            NSLog(@"Error: %@ %@", error, [error userInfo]);
        }
    }];
}

@end
