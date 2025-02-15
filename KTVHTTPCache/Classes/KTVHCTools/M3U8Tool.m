//
//  M3U8Tool.m
//  KTVHTTPCacheDemo
//
//  Created by Ray on 2023/9/4.
//  Copyright © 2023 Single. All rights reserved.
//

//#import <KTVHTTPCache/KTVHTTPCache.h>
//#import <KTVHTTPCache/KTVHCURLTool.h>
//#import <KTVHTTPCache/KTVHCPathTool.h>

#import "M3U8Tool.h"
#import "KTVHCURLTool.h"
#import "KTVHCPathTool.h"
#import "KTVHTTPCache.h"

@implementation M3U8Tool

+ (NSString *)basePath
{
    NSString * path = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    NSLog(@"KTVHTTPCache basePath = %@",path);
    return path;
}
+ (NSString *)rootDirectory
{
    static NSString *obj = @"KTVHTTPCacheM3u8";
    NSString * obj1 = [[self basePath] stringByAppendingPathComponent:obj];
    [self createDirectoryAtPath:obj1];
    return obj1;
}

+ (void)createDirectoryAtPath:(NSString *)path
{
    if (path.length <= 0) {
        return;
    }
    BOOL isDirectory = NO;
    BOOL isExists = [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDirectory];
    if (!isExists || !isDirectory) {
        [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    }
}

+(NSString *)getOldM3u8PathWithUrl: (NSURL *)url {
//    NSString * path = [self getM3u8PathWithUrl:url];
    
    NSString * key = [[KTVHCURLTool tool] keyWithURL:url];
    
    NSString * rootDirectory = [self rootDirectory];
    NSString * filePath = [rootDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"old_%@",key]];
    filePath = [filePath stringByAppendingString:@".m3u8"];
    return  filePath;
}

+(NSString *)getM3u8PathWithUrl: (NSURL *)url {
    NSString * key = [[KTVHCURLTool tool] keyWithURL:url];
    
    NSString * rootDirectory = [self rootDirectory];
    NSString * filePath = [rootDirectory stringByAppendingPathComponent:key];
    filePath = [filePath stringByAppendingString:@".m3u8"];
//    [KTVHCPathTool createFileAtPath:filePath];
    
    return filePath;
}

+ (NSError *)deleteAll
{
    NSString * path = [self rootDirectory];
    if (path.length <= 0) {
        return nil;
    }
    NSError *error = nil;
    BOOL isDirectory = NO;
    BOOL result = [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDirectory];
    if (result && isDirectory) {
        result = [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
    }
    return error;
}

+(NSString *)saveM3u8WithUrl: (NSString *)url {
    
    NSString * urStr = url;
    NSURL * urlJJ = [[NSURL alloc] initWithString:url];
    NSString * path = [self getM3u8PathWithUrl:urlJJ];
    NSString * oldFile = [self getOldM3u8PathWithUrl:urlJJ];
    
    NSString * lastPath = [urlJJ lastPathComponent];
    NSString * currentPath = [url stringByReplacingOccurrencesOfString:@"" withString:lastPath];
    BOOL isDirectory = NO;
    BOOL isExists = [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDirectory];
    if (isExists) {
        return path;
    }
    NSString * oriM3u8String = [[NSString alloc] initWithContentsOfURL: urlJJ encoding:NSUTF8StringEncoding error:nil ];
    NSString * oldString = oriM3u8String;

    if (urStr.length > 0) {
        
        NSArray <NSString *>* listStrs = [oriM3u8String componentsSeparatedByString:@"\n"];
        NSMutableArray * newListStrs = @[].mutableCopy;
        for (NSString *object in listStrs) {
            if ([object hasSuffix:@".ts"]) {
                NSString * newStr = object;
                if ([object hasPrefix:@"http"]) {
                    newStr = object;
                } else if ([object hasPrefix:@"../"]) {
                    NSRange r;
                    NSString *a = urStr;
                    for (int i = 0; i < 2; i ++) {
                        r = [a rangeOfString:@"/" options:NSBackwardsSearch];
                        a = [a substringToIndex:r.location];
                    }
                    NSString * formatStr = [a  stringByAppendingString:@"/"];
                    newStr = [newStr stringByReplacingOccurrencesOfString:@"../" withString:formatStr];
                } else {
                    NSRange r;
                    NSString *a = urStr;
                    for (int i = 0; i < 1; i ++) {
                        r = [a rangeOfString:@"/" options:NSBackwardsSearch];
                        a = [a substringToIndex:r.location];
                    }

                    NSString * formatStr = [a  stringByAppendingString:@"/"];
                    newStr = [NSString stringWithFormat:@"%@%@",formatStr,object];
                }

                NSURL * oringalUrl = [[NSURL alloc] initWithString: newStr];
                
                NSURL *newOrigalUrl = [KTVHTTPCache LocalHostURLWithOriginalURL:oringalUrl];
                [newListStrs addObject:newOrigalUrl.absoluteString];
            } else {
                [newListStrs addObject:object];
            }

        }
        oriM3u8String = [newListStrs componentsJoinedByString:@"\n"];
    }



    NSLog(@"isM3u8 ====  == =path %@ oldFile =%@", path, oldFile);

    NSData * newData = [oriM3u8String dataUsingEncoding:NSUTF8StringEncoding];
    NSData * oldData = [oldString dataUsingEncoding:NSUTF8StringEncoding];
    
    [oldData writeToFile:oldFile atomically: YES];
    [newData writeToFile:path atomically: YES];
    return  path;
}


+(NSData *)getCurerentM3u8DataWithOld: (NSData *)dataStr {
    
    NSString * doman = [KTVHTTPCache deviceIPAdress];
    if ([doman  isEqual: @"localhost"]) {
        return dataStr;
    }
    
    NSString * str = [[NSString alloc] initWithData: dataStr encoding:NSUTF8StringEncoding];
    NSString * newStr = [str stringByReplacingOccurrencesOfString:@"localhost" withString:doman];
    NSLog(@"newStr === %@",newStr);
    NSData * newData = [newStr dataUsingEncoding:NSUTF8StringEncoding];
    return newData;
}


+(void)proxyURLWithOriginalURL: (NSString *)urlStr complete: (void(^)(NSURL * url))complete {
    
    if ([urlStr hasSuffix:@".m3u8"]) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSString * path = [M3U8Tool saveM3u8WithUrl: urlStr];
            NSURL * fileUrl = [[NSURL alloc] initFileURLWithPath:path];
            NSURL *URL = [KTVHTTPCache proxyURLWithOriginalfileURL:fileUrl];
            dispatch_async(dispatch_get_main_queue(), ^{
                complete(URL);
            });
        });
    } else {
        NSURL *URL = [KTVHTTPCache proxyURLWithOriginalURL:[NSURL URLWithString:urlStr]];
        complete(URL);
    }
    
}


@end
