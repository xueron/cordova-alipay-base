#import "CDVAlipayBase.h"

#import <AlipaySDK/AlipaySDK.h>

@implementation CDVAlipayBase

-(void)pluginInitialize
{
    self.appId = [[self.commandDelegate settings] objectForKey:@"app_id"];
}


- (void) pay:(CDVInvokedUrlCommand*)command
{
    self.currentCallbackId = command.callbackId;

    if ([self.appId length] == 0)
    {
        [self failWithCallbackID:self.currentCallbackId withMessage:@"支付APP_ID设置错误"];
        return;
    }
    
    NSMutableString * orderString = [NSMutableString string];

    if([[command argumentAtIndex:0] isMemberOfClass:[NSString class]]){
        orderString = [NSMutableString stringWithString: (NSString*)[command argumentAtIndex:0]];
    }else{
        //从参数中合成paymentString，绝不能把private_key放在客户端中，阿里给的例子太有误导性，新手很容易图简单直接拿来用，殊不知危险性有多高。为了保证安全性，支付字符串需要从服务端合成。
        NSMutableDictionary *args = [command argumentAtIndex:0];
        
        //For the client-server based payment, the signed content must be extractly same. In other
        // words, the order of properties matters on both both sides.
        NSArray *sortedKeys = [args.allKeys sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"self" ascending:YES]]];

        //Let's remove the sign and sign_type properties first
        for (NSString * key in sortedKeys) {
            if ([@"sign" isEqualToString:key]) continue;
            [orderString appendFormat:@"%@=%@&", key, [args objectForKey:key]];
        }
        [orderString appendFormat:@"%@=%@&", @"sign", [args objectForKey:@"sign"]];
        [orderString deleteCharactersInRange:NSMakeRange([orderString length] -1, 1)];
        NSLog(@"orderString = %@", orderString);
    }
    
    NSMutableString * schema = [NSMutableString string];
    [schema appendFormat:@"ALI%@", self.appId];
    NSLog(@"schema = %@",schema);
    
    [[AlipaySDK defaultService] payOrder:orderString fromScheme:schema callback:^(NSDictionary *resultDic) {
        [self successWithCallbackID:self.currentCallbackId messageAsDictionary:resultDic];
    }];
}

- (void)handleOpenURL:(NSNotification *)notification
{
    NSURL* url = [notification object];
    
    if ([url.scheme rangeOfString:self.appId].length > 0)
    {
        //跳转支付宝钱包进行支付，处理支付结果
        [[AlipaySDK defaultService] processOrderWithPaymentResult:url standbyCallback:^(NSDictionary *resultDic) {
            [self successWithCallbackID:self.currentCallbackId messageAsDictionary:resultDic];
        }];
    }
}

- (void)successWithCallbackID:(NSString *)callbackID withMessage:(NSString *)message
{
    NSLog(@"message = %@",message);
    CDVPluginResult *commandResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:message];
    [self.commandDelegate sendPluginResult:commandResult callbackId:callbackID];
}

- (void)failWithCallbackID:(NSString *)callbackID withMessage:(NSString *)message
{
    NSLog(@"message = %@",message);
    CDVPluginResult *commandResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:message];
    [self.commandDelegate sendPluginResult:commandResult callbackId:callbackID];
}

- (void)successWithCallbackID:(NSString *)callbackID messageAsDictionary:(NSDictionary *)message
{
    NSLog(@"message = %@",message);
    CDVPluginResult *commandResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:message];
    [self.commandDelegate sendPluginResult:commandResult callbackId:callbackID];
}

- (void)failWithCallbackID:(NSString *)callbackID messageAsDictionary:(NSDictionary *)message
{
    NSLog(@"message = %@",message);
    CDVPluginResult *commandResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:message];
    [self.commandDelegate sendPluginResult:commandResult callbackId:callbackID];
}

@end
