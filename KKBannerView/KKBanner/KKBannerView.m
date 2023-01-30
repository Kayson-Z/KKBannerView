//
//  KKBannerView.m
//  KKBannerView
//
//  Created by Kayson Zhang on 2022/8/19.
//

#import "KKBannerView.h"

@interface KKBannerView () <UIScrollViewDelegate>
//改用index 替代 image.url,将图片数据交给外部显示
//@property (nonatomic, strong) NSMutableArray<NSString *> *picDatas;
@property (nonatomic, strong) NSMutableArray<NSNumber *> *indexDatas;
@property (nonatomic, assign) NSInteger currentIndex;///< 当前图片资源index
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) dispatch_source_t timer;
@property (nonatomic, assign) BOOL isSuspend;
@property (nonatomic, strong) NSMutableArray<UIImageView *> *imagesArray;///< 循环3张图片
@property (nonatomic, assign) BOOL onlyDouble;
@end

@implementation KKBannerView

+ (instancetype)bannerViewWithDataSource:(id<KKBannerViewDataSource>)dataSource {
    KKBannerView *view = [KKBannerView new];
    view.dataSource = dataSource;
    return view;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self initUI];
        //timer初始为suspend状态
        self.isSuspend      = YES;
        self.interval       = 5.0;
        self.currentIndex   = 0;
    }
    return self;
}

#pragma mark - UI

- (void)initUI {
    _scrollView = [UIScrollView new];
    _scrollView.delegate = self;
    _scrollView.pagingEnabled = YES;
    _scrollView.bounces = NO;
    _scrollView.showsVerticalScrollIndicator = NO;
    _scrollView.showsHorizontalScrollIndicator = NO;
    [self addSubview:_scrollView];
    
    //添加循环3张图片
    for (int i=0; i<3; i++) {
        UIImageView *img = [UIImageView new];
        img.contentMode = UIViewContentModeScaleAspectFill;
        img.userInteractionEnabled = YES;
        [img addGestureRecognizer:[[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tap:)]];
        [self.imagesArray addObject:img];
        [self.scrollView addSubview:img];
    }
    
    _pageControl = [[UIPageControl alloc]init];
    _pageControl.userInteractionEnabled = NO;
    [self addSubview:_pageControl];
}


#pragma mark - setter / getter

- (NSMutableArray<UIImageView *> *)imagesArray {
    if (_imagesArray == nil) {
        _imagesArray = [NSMutableArray arrayWithCapacity:3];
    }
    return _imagesArray;
}

- (dispatch_source_t)timer {
    if (_timer == nil) {
        _timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_queue_create("KKBANNERTIMER_QUEUE", DISPATCH_QUEUE_SERIAL));
        dispatch_source_set_timer(_timer, dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.interval * NSEC_PER_SEC)), self.interval * NSEC_PER_SEC, 0);
        __weak typeof(self)weakSelf = self;
        dispatch_source_set_event_handler(_timer, ^{
            [weakSelf timerAction];
        });
    }
    return _timer;
}

- (void)setDataSource:(id<KKBannerViewDataSource>)dataSource {
    _dataSource = dataSource;
    if (![_dataSource respondsToSelector:
         @selector(KK_numberOfPagesInBannerView:)]) {
        NSLog(@"%s  ⚠️reason:请实现数据源方法⚠️",__func__);
    }
    [self loadDatas];
}


    
#pragma mark - 数据

- (void)loadDatas {
    NSInteger count = [self.dataSource KK_numberOfPagesInBannerView:self];
    _indexDatas = [NSMutableArray array];
    for (int i=0; i<count; i++) {
        [_indexDatas addObject:@(i)];
    }
    //处理图片数据
    [self handelPicData];
    [self setNeedsLayout];
}

/// 重新加载数据
- (void)reloadDatas {
    self.onlyDouble = NO;
    self.currentIndex = 0;
    [self timerPause];
    [self cancelTimer];
    
    for (UIImageView *imgView in self.imagesArray) {
        imgView.image = nil;
    }
    [self loadDatas];
}

/// 数据处理
- (void)handelPicData {
    if (!_indexDatas.count) return;
    if (_indexDatas.count == 1) {
        //一张图片时不滚动
        [self cancelTimer];
        [self showImageView:self.imagesArray[0] withIndex:0];
        
    }else if (_indexDatas.count == 2) {
        self.onlyDouble = YES;
        //添加最后一张  (0,1,1 -->scroll排序 1,0,1)
        [_indexDatas addObject:_indexDatas.lastObject];
        [self handelPicData];
    
    }else {
        [self handelShowing:self.scrollView withIndex:self.currentIndex];
        //启动定时器
        [self timerStart];
    }
    self.pageControl.numberOfPages = self.onlyDouble? 2 : _indexDatas.count;
    self.pageControl.hidden = !(_indexDatas.count > 1);
}



#pragma mark - 展示处理

- (void)handelShowing:(UIScrollView *)scrollView withIndex:(NSInteger)index {
    //复位到第2张ImageView
    [scrollView setContentOffset:CGPointMake(self.bounds.size.width, 0) animated:NO];
    
    NSInteger previous = 0;
    NSInteger next     = 0;
    
    if (self.onlyDouble) {
        previous = (self.currentIndex == 0)? 1 : 0;
        next     = (self.currentIndex == 1)? 0 : 1;
    } else {
        previous = (self.currentIndex==0)? self.indexDatas.count-1   : self.currentIndex-1;
        next     = (self.currentIndex == self.indexDatas.count-1)? 0 : self.currentIndex+1;
    }
    self.currentIndex = index;
    NSLog(@"current= %ld, previous= %ld, next= %ld",_currentIndex,previous,next);
    
    [self showImageView:self.imagesArray[0] withIndex:previous];
    [self showImageView:self.imagesArray[1] withIndex:self.currentIndex];
    [self showImageView:self.imagesArray[2] withIndex:next];
    
    self.pageControl.currentPage = self.currentIndex;
}

/// 滑动时获取显示的imageView对应的index
- (NSInteger)judgeScrollViewShowingWithOffsetX:(CGFloat)offX {
    NSInteger currentImgPage = offX / self.scrollView.bounds.size.width;
    NSInteger currentIndex = self.currentIndex;
    if (currentImgPage == 0) {
        //左滑动
        if (self.onlyDouble) {
            currentIndex = (currentIndex==0)? 1 : 0;
        }else{
            currentIndex = (currentIndex <= 0)? self.indexDatas.count-1 : currentIndex-1;
        }
        
    }else if (currentImgPage == 2) {
        //右滑动
        if (self.onlyDouble) {
            currentIndex = (currentIndex==1)? 0 : 1;
        }else{
            currentIndex = (currentIndex >= self.indexDatas.count-1)? 0 : currentIndex+1;
        }
    }
    return currentIndex;
}

/// 展示图片
- (void)showImageView:(UIImageView *)imageView withIndex:(NSInteger)index {
    if ([self.dataSource respondsToSelector:
         @selector(KK_bannerView:showingImageView:withIndex:)]) {
        [self.dataSource KK_bannerView:self showingImageView:imageView withIndex:index];
    }
}


#pragma mark - 定时器 Action

- (void)timerAction {
    dispatch_async(dispatch_get_main_queue(), ^{
        //向右滚动
        [self.scrollView setContentOffset:CGPointMake(self.scrollView.bounds.size.width *2, 0) animated:YES];
    });
}

///定时器启动
- (void)timerStart {
    if (self.isSuspend) {
        dispatch_resume(self.timer);
        self.isSuspend = NO;
    }
}

///定时器挂起
- (void)timerPause {
    if (!self.isSuspend) {
        dispatch_suspend(self.timer);
        self.isSuspend = YES;
    }
}

///销毁timmer
- (void)cancelTimer {
    if (_timer) {
        //如果timer处于suspend状态，需要resume后才能执行cancel
        if (_isSuspend) {dispatch_resume(_timer);}
        dispatch_source_cancel(_timer);
        _timer = nil;
    }
}

#pragma mark - 点击事件

- (void)tap:(UIGestureRecognizer *)gesture {
    NSLog(@"%s 点击了第：%ld张",__func__,self.currentIndex);
    if ([self.delegate respondsToSelector:
         @selector(KK_bannerView:didTapWithIndex:)]) {
        [self.delegate KK_bannerView:self didTapWithIndex:self.currentIndex];
    }
}

#pragma mark - ScrollView Delegate

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    self.currentIndex = [self judgeScrollViewShowingWithOffsetX:scrollView.contentOffset.x];
    [self handelShowing:scrollView withIndex:self.currentIndex];
    
    if (self.isSuspend) {
        //晚 interval 后再滚动
        dispatch_time_t start =dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.interval * NSEC_PER_SEC));
        dispatch_source_set_timer(self.timer, start, (int64_t)(self.interval * NSEC_PER_SEC), 0);
        [self timerStart];
    }
    
    if ([self.delegate respondsToSelector:
         @selector(KK_bannerView:didScrollToShowingWithIndex:)]) {
        [self.delegate KK_bannerView:self didScrollToShowingWithIndex:self.currentIndex];
    }
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    self.currentIndex = [self judgeScrollViewShowingWithOffsetX:scrollView.contentOffset.x];
    [self handelShowing:scrollView withIndex:self.currentIndex];
    if ([self.delegate respondsToSelector:
         @selector(KK_bannerView:didScrollToShowingWithIndex:)]) {
        [self.delegate KK_bannerView:self didScrollToShowingWithIndex:self.currentIndex];
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (!decelerate) {
        self.currentIndex = [self judgeScrollViewShowingWithOffsetX:scrollView.contentOffset.x];
        [self handelShowing:scrollView withIndex:self.currentIndex];
        
        if (self.isSuspend) {
            //晚 interval 后再滚动
            dispatch_time_t start =dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.interval * NSEC_PER_SEC));
            dispatch_source_set_timer(self.timer, start, (int64_t)(self.interval * NSEC_PER_SEC), 0);
            [self timerStart];
        }
        if ([self.delegate respondsToSelector:
             @selector(KK_bannerView:didScrollToShowingWithIndex:)]) {
            [self.delegate KK_bannerView:self didScrollToShowingWithIndex:self.currentIndex];
        }
    }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [self timerPause];
}


#pragma mark - 布局

- (void)layoutSubviews {
    [super layoutSubviews];
    
    //scrollView
    _scrollView.frame = self.bounds;
    if (self.indexDatas.count >1) {
        self.scrollView.contentSize = CGSizeMake(3*self.bounds.size.width, 0);
        self.scrollView.contentOffset = CGPointMake(self.bounds.size.width, 0);
    } else {
        self.scrollView.contentOffset = CGPointZero;
        self.scrollView.contentSize = CGSizeZero;
    }
    
    //imageView
    for (int i = 0; i<self.imagesArray.count; i++) {
        UIImageView *img = self.imagesArray[i];
        img.frame = CGRectMake(self.bounds.size.width * i, 0,
                               self.bounds.size.width, self.bounds.size.height);
    }
    
    _pageControl.frame = CGRectMake(0, self.bounds.size.height-30,
                                    self.bounds.size.width, 30);
}

- (void)dealloc {
    [self cancelTimer];
    NSLog(@"%s",__func__);
}

@end
