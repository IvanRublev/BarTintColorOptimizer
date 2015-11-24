//
//  ProgressViewController.m
//  BarTintColorOptimizer
//
//  Created by Ivan Rublev on 10/25/15.
//  Copyright (c) 2015 Ivan Rublev http://ivanrublev.me. All rights reserved.
//

#import <PSOLib/PSOLib.h>
#import "NavbarView.h"
#import "ProgressViewController.h"
#import "UIColor+Components.h"
#import <ColorUtils/ColorUtils.h>
@import Accelerate;

NSUInteger const maxSearchIterations = 60;

NSString *const unwindSequeIdentifier = @"unwind";
double const progressAddend = 0.02;
NSUInteger const particlesCount = 40; // don't touch, it's magic constant).

@interface ProgressViewController () <PSOFitnessCalculating> {
    double designColorVec[3];
    UIImage *lastScreenshot;
}
@property (strong, nonatomic) IBOutlet UILabel *phaseLabel;
@property (nonatomic, assign) NSUInteger barsCount;
@property (strong, nonatomic) NSMutableArray *bars;
@property (strong, nonatomic) IBOutlet UIView *barsContainer;
@property (strong, nonatomic) IBOutlet UIProgressView *progressView;
@property (strong, nonatomic) IBOutlet UIButton *stopButton;
@property (strong, nonatomic) IBOutlet UILabel *minDistanceLabel;
@property (nonatomic) NSOperationQueue *queue;
@property (nonatomic, readonly) NSBlockOperation *fillBarsContainer;
@property (nonatomic, readonly) NSOperation *findColor;

@property (nonatomic) NSUInteger phase;
@property (nonatomic) NSUInteger phasesCount;
@property (nonatomic) NSArray *combinations;
@property (nonatomic, assign) float minDistance;
@end

@implementation ProgressViewController

- (id)initWithCoder:(NSCoder *)aDecoder {
    if ((self = [super initWithCoder:aDecoder])) {
        _queue = [NSOperationQueue new];
        _queue.maxConcurrentOperationCount = 1;
        _bars = [NSMutableArray array];
        _barsCount = particlesCount;
        NSLog(@"%@ is initialized.", NSStringFromClass(self.class));
    }
    return self;
}

//- (void)dealloc {
//	NSLog(@"%@ is deallocated.", NSStringFromClass(self.class));
//}

- (void)setPhase:(NSUInteger)phase {
    _phase = phase;
    dispatch_sync(dispatch_get_main_queue(), ^{
        NSString *title = [NSString stringWithFormat:@"Phase %lu/%lu", (unsigned long)phase, (unsigned long)self.phasesCount];
        NSLog(@"%@", title);
        self.phaseLabel.text = title;
        self.progressView.progress = 0.;
    });
}

- (void)setMinDistance:(float)minDistance {
    _minDistance = minDistance;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (minDistance < 100.) {
            self.minDistanceLabel.text = [NSString stringWithFormat:@"distance: %.4f", minDistance];
        }
    });
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.queue cancelAllOperations];
        NSArray *operations = @[self.fillBarsContainer, self.findColor];
        self.phasesCount = operations.count;
        [self.queue addOperations:operations waitUntilFinished:NO];
    });
}

- (IBAction)stopButtonPressed:(id)sender {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0ul), ^{
        [self.queue cancelAllOperations];
        [self.queue waitUntilAllOperationsAreFinished];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self performSegueWithIdentifier:unwindSequeIdentifier sender:self];
        });
    });
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    self.barsContainer.hidden = YES;
    self.stopButton.enabled = NO;
    NSLog(@"Cleaning up...");
    [self.barsContainer removeFromSuperview];
    self.barsContainer = nil;
    self.bars = nil;
    NSLog(@"Cleanup is finished");
    NSLog(@"Optimized color is %@ with distance from design color: %f.", self.optimizedColor.hexString, self.minDistance);
}


#pragma mark -
#pragma mark Operations
- (NSOperation *)fillBarsContainer {
    NSParameterAssert(self.underviewColor);
    CGSize containerSize = self.barsContainer.bounds.size;
    CGFloat inset = 4.;
    CGFloat barHeight = 52.+2*inset;
    CGFloat barsInCol = floor(containerSize.height/(barHeight));
    CGFloat barsInRow = ceil((double)self.barsCount/barsInCol);
    CGFloat barWidth = floor(containerSize.width/barsInRow);
    
    
    NSBlockOperation *operation = [NSBlockOperation new];
    NSBlockOperation *__weak operation_weak_ = operation;
    __typeof(self) __weak self_weak_ = self;
    
    [operation addExecutionBlock:^{
        NSBlockOperation *operation = operation_weak_;
        __typeof(self) self = self_weak_;
        self.phase += 1;
        
        if (operation.isCancelled) {
            return;
        }
        NSLog(@"Making bars.");
        
        NSUInteger idx = 0;
        NSUInteger const progressQuant = (NSUInteger)pow(10, round(log10((double)self.barsCount*progressAddend)));
        
        UINib *navbar = [UINib nibWithNibName:@"navbar" bundle:[NSBundle mainBundle]];
        dispatch_group_t group = dispatch_group_create();
        BOOL stop = NO;
        for (int row=0; row<barsInCol; row++) {
            for (int col=0; col<barsInRow; col++) {
                if (operation.isCancelled) {
                    return;
                }
                CGRect barRect = CGRectMake(col*barWidth, row*barHeight, barWidth, barHeight);
                barRect = CGRectInset(barRect, inset, inset);
                NavbarView *navbarView = [[navbar instantiateWithOwner:nil options:nil] firstObject];
                navbarView.frame = barRect;
                [self.bars addObject:navbarView];
                dispatch_group_async(group, dispatch_get_main_queue(), ^{
                    if (operation.isCancelled) {
                        return;
                    }
                    [self.barsContainer addSubview:navbarView];
                });
                if (idx % progressQuant == 0) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        self.progressView.progress = (float)idx/self.barsCount;
                    });
                }
                idx++;
                stop = (idx == self.barsCount);
                if (stop) break;
            }
            if (stop) break;
        }
        NSLog(@"Wait for bars to be added to container.");
        dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
        if (operation.isCancelled) {
            return;
        }
        
        dispatch_sync(dispatch_get_main_queue(), ^{
            self.progressView.progress = 1.0;
        });
        NSLog(@"%lu bars are added.", (unsigned long)self.bars.count);
        NSAssert(self.barsCount == self.bars.count, @"Added bars count must not be less then required (%lu)", (unsigned long)self.barsCount);
    }];
    
    return operation;
}

- (NSOperation *)findColor {
    CGFloat designRed, designGreen, designBlue, designAlpha;
    [self.designColor getRed:&designRed green:&designGreen blue:&designBlue alpha:&designAlpha];
    designColorVec[0] = designRed;
    designColorVec[1] = designGreen;
    designColorVec[2] = designBlue;
    
    NSUInteger const progressQuant = (NSUInteger)pow(10, round(log10((double)maxSearchIterations*progressAddend)));
    
    PSOStandardOptimizer2011 *optimizer =
    [PSOStandardOptimizer2011
     optimizerForSearchSpace:[PSOSearchSpace searchSpaceWithBoundsMin:@[@0, @0, @0]
                                                                  max:@[@(designRed), @(designGreen), @(designBlue)]]
     optimum:0.
     fitnessCalculator:self
     before:^(PSOStandardOptimizer2011 *optimizer) {
         self.phase += 1;
         NSLog(@"Searching for optimized color.");
     }
     iteration:^(PSOStandardOptimizer2011 *optimizer) {
         [self getResultsFromOptimizer:optimizer];
         if (optimizer.iteration % progressQuant == 0) {
             dispatch_async(dispatch_get_main_queue(), ^{
                 self.progressView.progress = (double)optimizer.iteration/optimizer.maxIterations;
             });
         }
     }
     finished:^(PSOStandardOptimizer2011 *optimizer) {
         [self getResultsFromOptimizer:optimizer];
         NSLog(@"Search is finished in %lu iterations.", (unsigned long)optimizer.iteration);
         dispatch_async(dispatch_get_main_queue(), ^{
             self.progressView.progress = 1.0;
             [self performSegueWithIdentifier:unwindSequeIdentifier sender:self];
         });
     }];
    optimizer.populationSize = particlesCount;
    optimizer.maxIterations = maxSearchIterations;
    if ( !self.exactSearch) {
        optimizer.fitnessError = 1./255;
    }
    return optimizer.operation;
}

- (void)getResultsFromOptimizer:(PSOStandardOptimizer2011 *)optimizer {
    self.optimizedColor = [UIColor colorWithRed:[optimizer.bestPosition[0] doubleValue] green:[optimizer.bestPosition[1] doubleValue] blue:[optimizer.bestPosition[2] doubleValue] alpha:1.0];
    self.minDistance = optimizer.bestFitness;
}

#pragma mark -
#pragma mark PSOFitnessCalculating
- (NSUInteger)numberOfPositionsInBunch:(PSOStandardOptimizer2011 *)optimizer {
    return self.barsCount;
}

- (void)optimizer:(PSOStandardOptimizer2011 *)optimizer getFitnessValues:(out double *)fitnessValues forPositionsBunch:(double **)positions size:(NSUInteger)bunchSize dimensions:(int)dimensions {
    
    NSAssert(dimensions == 3, @"dimensions must equal to 3 color components red, green and blue.");
    NSMutableArray *allColors = [NSMutableArray arrayWithCapacity:bunchSize];
    for (NSUInteger bunch=0; bunch<bunchSize; bunch++) {
        [allColors addObject:[UIColor colorWithRed:positions[bunch][0] green:positions[bunch][1] blue:positions[bunch][2] alpha:1.0]];
    }
    NSArray *barColors = [self getBarColorsFromColors:allColors];
    [barColors enumerateObjectsUsingBlock:^(UIColor *aBarColor, NSUInteger idx, BOOL *stop) {
        CGFloat red, green, blue, alpha;
        [aBarColor getRed:&red green:&green blue:&blue alpha:&alpha];
        double colorVec[3] = {red, green, blue};
        double colorDifference[3];
        vDSP_vsubD(designColorVec, 1, colorVec, 1, colorDifference, 1, dimensions);
        double distance = cblas_dnrm2(dimensions, colorDifference, 1);
        fitnessValues[idx] = distance;
        if (fabs(distance) < DBL_EPSILON) {
            NSLog(@"Bpi: %lu, color:%@ src color:%@", (unsigned long)idx, aBarColor.hexString, [allColors[idx] hexString]);
        }
    }];
}

- (NSArray *)getBarColorsFromColors:(NSArray *)colors {
    NSAssert(colors.count == self.bars.count, @"Colors count must match bars count");
    NSParameterAssert(self.colorNavigationbar);
    __block UIImage *screenshot = nil;
    dispatch_sync(dispatch_get_main_queue(), ^{
        NSUInteger idx=0;
        for (NavbarView *navbarView in self.bars) {
            self.colorNavigationbar(navbarView, colors[idx++], self.underviewColor);
        }
    });
    usleep(USEC_PER_SEC*UINavigationControllerHideShowBarDuration); // Wait for navigationbar animation complete.
    dispatch_sync(dispatch_get_main_queue(), ^{
        UIGraphicsBeginImageContextWithOptions(self.barsContainer.bounds.size, YES, 0);
        BOOL hasPixels = [self.barsContainer drawViewHierarchyInRect:self.barsContainer.bounds afterScreenUpdates:YES];
        NSAssert(hasPixels == YES, @"Snapshot has no pixels");
        screenshot = UIGraphicsGetImageFromCurrentImageContext();
        NSParameterAssert(screenshot);
        UIGraphicsEndImageContext();
    });
    lastScreenshot = screenshot;
    
    CGImageRef image = screenshot.CGImage;
    size_t bpr = CGImageGetBytesPerRow(image);
    size_t bpp = CGImageGetBitsPerPixel(image);
    NSAssert(CGImageGetAlphaInfo(image)==kCGImageAlphaNoneSkipFirst, @"Alpha componenet is expected to be first in byte.");
    NSUInteger Bpp = bpp/8;
    NSAssert(Bpp == 4, @"Expect 4 bytes per pixel.");
    NSData *imageData = CFBridgingRelease(CGDataProviderCopyData(CGImageGetDataProvider(image)));
    CGFloat scale = [UIScreen mainScreen].scale;
    
    NSMutableArray *barColors = [NSMutableArray array];
    for (NSUInteger barIdx=0; barIdx<self.bars.count; barIdx++) {
        UINavigationBar *navbar = self.bars[barIdx];
        CGPoint pixelPoint = CGPointMake((navbar.frame.origin.x + navbar.frame.size.width/2.) * scale,
                                         (navbar.frame.origin.y + navbar.frame.size.height/2.) * scale);
        int offset = bpr*round(pixelPoint.y) + Bpp*round(pixelPoint.x);
        uint8_t data[Bpp];
        [imageData getBytes:&data range:NSMakeRange(offset, sizeof(uint32_t))];
        uint8_t blue = data[0];
        uint8_t green = data[1];
        uint8_t red = data[2];
        [barColors addObject:[UIColor colorWithR:red G:green B:blue]];
    }
    return [NSArray arrayWithArray:barColors];
}

@end
