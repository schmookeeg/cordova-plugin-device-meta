/********* DeviceMeta.m Cordova Plugin Implementation *******/

#import <Cordova/CDV.h>
#import "Cordova/CDVViewController.h"
#import "DeviceMeta.h"
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>
#include <ifaddrs.h>
#include <arpa/inet.h>

@implementation DeviceMeta

- (void)getDeviceMeta:(CDVInvokedUrlCommand*)command
{
    CDVPluginResult* pluginResult = nil;
    //NSString* echo = [command.arguments objectAtIndex:0];

    //if (echo != nil && [echo length] > 0) {
    //    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:echo];
    //} else {
    //    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
    //}
    NSDictionary* deviceProperties = [self deviceProperties];

    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK  messageAsDictionary:deviceProperties];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (NSDictionary*)deviceProperties
{
    NSMutableDictionary* devProps = [NSMutableDictionary dictionaryWithCapacity:5];
    [devProps setObject:@"Apple" forKey:@"manufacturer"];
    [devProps setObject:@([self isDebug]) forKey:@"debug"];
    [devProps setObject:[self getIPAddress] forKey:@"ip"];
    [devProps setObject:[self getNetworkProvider] forKey:@"networkProvider"];
    [devProps setObject:[self jailbroken] forKey:@"root"];

    NSDictionary* devReturn = [NSDictionary dictionaryWithDictionary:devProps];
    return devReturn;
}

- (BOOL)isDebug
{
#ifdef DEBUG
    return true;
#else
    return false;
#endif
}


- (NSString *)getIPAddress {

    NSString *address = @"error";
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    int success = 0;
    // retrieve the current interfaces - returns 0 on success
    success = getifaddrs(&interfaces);
    if (success == 0) {
        // Loop through linked list of interfaces
        temp_addr = interfaces;
        while(temp_addr != NULL) {
            if(temp_addr->ifa_addr->sa_family == AF_INET) {
                // Check if interface is en0 which is the wifi connection on the iPhone
                if([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"]) {
                    // Get NSString from C String
                    address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];

                }

            }

            temp_addr = temp_addr->ifa_next;
        }
    }
    // Free memory
    freeifaddrs(interfaces);
    return address;
}

- (NSString *)getNetworkProvider {
    CTTelephonyNetworkInfo *netinfo = [[CTTelephonyNetworkInfo alloc] init];
    CTCarrier *carrier = [netinfo subscriberCellularProvider];
    if ([carrier carrierName] == NULL) {
        return @"";
    }
    return @"%@M", [carrier carrierName];
}

- (NSString *) jailbroken {

#if !(TARGET_IPHONE_SIMULATOR)

    if ([[NSFileManager defaultManager] fileExistsAtPath:@"/Applications/Cydia.app"])
    {
        return @"true";
    }
    else if ([[NSFileManager defaultManager] fileExistsAtPath:@"/Library/MobileSubstrate/MobileSubstrate.dylib"])
    {
        return @"true";
    }
    else if ([[NSFileManager defaultManager] fileExistsAtPath:@"/bin/bash"])
    {
        return @"true";
    }
    else if ([[NSFileManager defaultManager] fileExistsAtPath:@"/usr/sbin/sshd"])
    {
        return @"true";
    }
    else if ([[NSFileManager defaultManager] fileExistsAtPath:@"/etc/apt"])
    {
        return @"true";
    }

    NSError *error;
    NSString *testWriteText = @"Jailbreak test";
    NSString *testWritePath = @"/private/jailbreaktest.txt";

    [testWriteText writeToFile:testWritePath atomically:YES encoding:NSUTF8StringEncoding error:&error];

    if (error == nil)
    {
        [[NSFileManager defaultManager] removeItemAtPath:testWritePath error:nil];
        return @"true";
    }
    else
    {
        [[NSFileManager defaultManager] removeItemAtPath:testWritePath error:nil];
    }

    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"cydia://package/com.example.package"]])
    {
        return @"true";
    }

#endif

    return @"false";
}


@end
