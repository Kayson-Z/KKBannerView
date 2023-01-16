//
//  SecondViewController.m
//  KKBannerView
//
//  Created by Kayson Zhang on 2022/8/19.
//

#import "SecondViewController.h"
#import "KKBannerView.h"

@interface SecondViewController ()
<
KKBannerViewDelegate,
KKBannerViewDataSource
>

@property (nonatomic, strong) NSMutableArray *dataArray;
@property (nonatomic, strong) KKBannerView *banner;

@end

@implementation SecondViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.whiteColor;
    
    NSMutableArray *picTitles = [NSMutableArray array];
    for (int i=0; i<0; i++) {
        NSString *text = [NSString stringWithFormat:@"%02d",i+1];
        [picTitles addObject:text];
    }
    
    self.dataArray = picTitles;
    
    KKBannerView *banner = [KKBannerView new];
    banner.delegate = self;
    banner.dataSource = self;
    banner.frame = CGRectMake(0, 0, 300, 200);
    banner.center = self.view.center;
    self.banner = banner;
    [self.view addSubview:self.banner];
}

#pragma mark - Delegate

- (void)KK_bannerView:(KKBannerView *)bannerView showingImageView:(const UIImageView *)imageView withIndex:(NSInteger)index {
    NSString *path = [[NSBundle mainBundle]pathForResource:self.dataArray[index] ofType:@"png"];
    UIImage *img = [UIImage imageWithContentsOfFile:path];
    imageView.image = img;
}

- (NSInteger)KK_numberOfPagesInBannerView:(KKBannerView *)bannerView {
    return self.dataArray.count;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    NSMutableArray *picTitles = [NSMutableArray array];
    for (int i=0; i<2; i++) {
        NSString *text = [NSString stringWithFormat:@"%02d",i+1];
        [picTitles addObject:text];
    }
    
    self.dataArray = picTitles;
    
    [self.banner reloadDatas];
}


- (void)dealloc {
    NSLog(@"%s",__func__);
}

@end
