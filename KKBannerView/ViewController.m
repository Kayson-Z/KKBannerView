//
//  ViewController.m
//  KKBannerView
//
//  Created by Kayson Zhang on 2022/8/19.
//

#import "ViewController.h"
#import "SecondViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.redColor;
    
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    SecondViewController *vc = SecondViewController.new;
    [self.navigationController pushViewController:vc animated:YES];
}


@end
