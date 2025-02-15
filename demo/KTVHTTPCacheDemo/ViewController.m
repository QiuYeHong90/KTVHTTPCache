//
//  ViewController.m
//  KTVHTTPCacheDemo
//
//  Created by Single on 2017/8/10.
//  Copyright © 2017年 Single. All rights reserved.
//


#import "ViewController.h"
#import "MediaViewController.h"
#import "MediaItem.h"
#import "MediaCell.h"
#import <KTVHTTPCache/KTVHTTPCache.h>

@interface ViewController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, strong) NSArray<MediaItem *> *items;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self setupHTTPCache];
    });
    [self setupItems];
}

- (void)setupHTTPCache
{
    [KTVHTTPCache logSetConsoleLogEnable:YES];
    NSError *error = nil;

    [KTVHTTPCache proxyStart:&error];
    if (error) {
        NSLog(@"Proxy Start Failure, %@", error);
    } else {
        NSLog(@"Proxy Start Success");
    }
    [KTVHTTPCache encodeSetURLConverter:^NSURL *(NSURL *URL) {
        NSLog(@"URL Filter reviced URL : %@", URL);
        return URL;
    }];
    [KTVHTTPCache downloadSetUnacceptableContentTypeDisposer:^BOOL(NSURL *URL, NSString *contentType) {
        NSLog(@"Unsupport Content-Type Filter reviced URL : %@, %@", URL, contentType);
        return YES;
    }];
    
    NSLog(@"logRecordLogFileURL == %@",KTVHTTPCache.logRecordLogFilePath);
}

- (void)setupItems
{
    MediaItem *item1 = [[MediaItem alloc] initWithTitle:@"萧亚轩 - 冲动"
                                              URLString:@"http://aliuwmp3.changba.com/userdata/video/45F6BD5E445E4C029C33DC5901307461.mp4"];
    MediaItem *item2 = [[MediaItem alloc] initWithTitle:@"张惠妹 - 你是爱我的"
                                              URLString:@"http://aliuwmp3.changba.com/userdata/video/3B1DDE764577E0529C33DC5901307461.mp4"];
    MediaItem *item3 = [[MediaItem alloc] initWithTitle:@"hush! - 都是你害的"
                                              URLString:@"http://qiniuuwmp3.changba.com/941946870.mp4"];
    MediaItem *item4 = [[MediaItem alloc] initWithTitle:@"张学友 - 我真的受伤了"
                                              URLString:@"http://lzaiuw.changba.com/userdata/video/940071102.mp4"];
//    MediaItem *item5 = [[MediaItem alloc] initWithTitle:@"你好我是m3u8"
//                                              URLString:@"https://bitmovin-a.akamaihd.net/content/playhouse-vr/m3u8s/105560_video_720_3000000.m3u8"];
    MediaItem *item5 = [[MediaItem alloc] initWithTitle:@"你好我是m3u8"

                                              URLString:@"https://pptv.sd-play.com/202307/19/ZHp3S7jWhm3/video/900k_0X480_64k_25/hls/index.m3u8"];
    
    self.items = @[item1, item2, item3, item4, item5];
    [self.tableView reloadData];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.items.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MediaItem *item = [self.items objectAtIndex:indexPath.row];
    MediaCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MediaCell"];
    [cell configureWithTitle:item.title];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    MediaItem *item = [self.items objectAtIndex:indexPath.row];
    NSString *URLString = [item.URLString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];

//    NSURL *URL = [KTVHTTPCache proxyURLWithOriginalURL:[NSURL URLWithString:URLString]];
//    NSURL * URL = [NSURL URLWithString:URLString];
//    NSLog(@"absoluteString === %@",URL.absoluteString);
//    MediaViewController *vc = [[MediaViewController alloc] initWithURLString:URL.absoluteString];
//    [self presentViewController:vc animated:YES completion:nil];
    __weak ViewController * weakself = self;
    [KTVHTTPCache proxyURLWithOriginalURL:item.URLString complete:^(NSURL *url) {
        
        NSLog(@"absoluteString === %@",url.absoluteString);
        MediaViewController *vc = [[MediaViewController alloc] initWithURLString:url.absoluteString];
        [weakself presentViewController:vc animated:YES completion:nil];
    }];

    
    
}


@end
