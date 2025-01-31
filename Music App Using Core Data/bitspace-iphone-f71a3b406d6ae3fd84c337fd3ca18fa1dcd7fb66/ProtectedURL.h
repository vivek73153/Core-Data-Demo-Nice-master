//
//  ProtectedURL.h
//  bitspace-iphone
//
//  Created by Niklas Holmgren on 2010-07-02.
//  Copyright 2010 Koneko Collective Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface ProtectedURL : NSURL {

}

+ (NSURL *)URLWithStringAndCredentials:(NSString *)URLString withUser:(NSString *)user andPassword:(NSString *)password;
+ (NSString *)authorizationHeaderWithUser:(NSString *)user andPassword:(NSString *)password;

@end
