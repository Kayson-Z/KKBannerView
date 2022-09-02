//
//  KKBannerView.h
//  KKBannerView
//
//  Created by Kayson Zhang on 2022/8/19.
//

#import <UIKit/UIKit.h>
@class KKBannerView;

NS_ASSUME_NONNULL_BEGIN



#pragma mark - DataSource
@protocol KKBannerViewDataSource <NSObject>
@required

/// 图片的数量
/// @param bannerView bannerView
///
- (NSInteger)KK_numberOfPagesInBannerView:(KKBannerView *)bannerView;


@optional
/// 显示图片
/// @param bannerView bannerView
/// @param imageView 正在加载图片的imageView
/// @param index 下标 0 ~~
/// @note  请不要修改参数imageView,这里只是为了给imageView赋值图片,如SD/YY
///
- (void)KK_bannerView:(KKBannerView *)bannerView showingImageView:(const UIImageView *)imageView withIndex:(NSInteger)index;
@end





#pragma mark - Delegate
@protocol KKBannerViewDelegate <NSObject>
@optional

/// 点击图片回调
/// @param bannerView bannerView
/// @param index 下标 0 ~~
///
- (void)KK_bannerView:(KKBannerView *)bannerView didTapWithIndex:(NSInteger)index;


/// 图片切换到下一张完成时回调
/// @param bannerView bannerView
/// @param index index 下标 0 ~~
///
- (void)KK_bannerView:(KKBannerView *)bannerView didScrollToShowingWithIndex:(NSInteger)index;

@end





#pragma mark - Class
@interface KKBannerView : UIView
/** 滚动间隔时间(默认5秒) */
@property (nonatomic, assign) NSTimeInterval interval;
@property (nonatomic, weak) id<KKBannerViewDelegate>    delegate;
@property (nonatomic, weak) id<KKBannerViewDataSource>  dataSource;
@property (nonatomic, assign, readonly) NSInteger currentIndex;
@property (nonatomic, strong, readonly) UIPageControl *pageControl;


/// 初始化
/// @param dataSource 数据源代理
+ (instancetype)bannerViewWithDataSource:(id<KKBannerViewDataSource>)dataSource;

/// 重新加载数据
- (void)reloadDatas;

@end

NS_ASSUME_NONNULL_END
