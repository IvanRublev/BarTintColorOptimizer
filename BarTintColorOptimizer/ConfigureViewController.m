//
//  ConfigureViewController.m
//  BarTintColorOptimizer
//
//  Created by Ivan Rublev on 10/25/15.
//  Copyright (c) 2015 Ivan Rublev http://ivanrublev.me. All rights reserved.
//

#import "ConfigureViewController.h"
#import "ProgressViewController.h"
#import "UIColor+Components.h"
#import <ColorUtils/ColorUtils.h>
#import "NavbarView.h"
@import QuartzCore;

NSString *const calculateSegueIdentifier = @"calculate";

NSString *const designed_color_stringPattern = @"<%designed_color_string%>";
NSString *const color_stringPattern = @"<%color_string%>";
NSString *const color_rPattern = @"<%color_r%>";
NSString *const color_gPattern = @"<%color_g%>";
NSString *const color_bPattern = @"<%color_b%>";

typedef NS_ENUM (NSInteger, CodeLanguage) {
    CodeObjC,
    CodeSwift
};

@interface ConfigureViewController () {
    NSString *bundleFileName;
}
@property (nonatomic, copy) ColorNavbarBlock colorNavigationbar;
@property (nonatomic) UIColor *designedBarColor;
@property (nonatomic) UIColor *underviewColor;
@property (nonatomic) UIColor *optimizedBarColor;
@property (nonatomic) BOOL exactSearch;
@property (nonatomic, assign) CodeLanguage language;

@property (strong, nonatomic) IBOutlet UITextField *rBar;
@property (strong, nonatomic) IBOutlet UITextField *gBar;
@property (strong, nonatomic) IBOutlet UITextField *bBar;
@property (strong, nonatomic) IBOutlet UITextField *barColorText;
@property (strong, nonatomic) IBOutlet UILabel *aLabel;
@property (strong, nonatomic) IBOutlet UITextField *aBar;
@property (strong, nonatomic) IBOutlet UITextField *rUnderview;
@property (strong, nonatomic) IBOutlet UITextField *gUnderview;
@property (strong, nonatomic) IBOutlet UITextField *bUnderview;
@property (strong, nonatomic) IBOutlet UITextField *underviewColorText;
@property (strong, nonatomic) IBOutlet UISwitch *exactSearchSwitch;
@property (strong, nonatomic) IBOutlet UIButton *optimizeButton;

@property (strong, nonatomic) IBOutlet UIView *barsContainerView;
@property (strong, nonatomic) IBOutlet UIView *barColorView;
@property (strong, nonatomic) IBOutlet UIView *underviewColorView;
@property (strong, nonatomic) IBOutlet UILabel *designedColorLabel;
@property (strong, nonatomic) IBOutlet UILabel *optimizedColorLabel;
@property (strong, nonatomic) IBOutlet UIView *navbarSlot1;
@property (strong, nonatomic) IBOutlet UIView *navbarSlot2;
@property (strong, nonatomic) NavbarView *navbarView1;
@property (strong, nonatomic) NavbarView *navbarView2;

@property (strong, nonatomic) IBOutlet UISegmentedControl *codeLanguage;
@property (strong, nonatomic) IBOutlet UIButton *logCodeButton;
@end

@implementation ConfigureViewController

- (NSString *)userDefaultsKeyWithString:(NSString *)str {
    return [NSString stringWithFormat:@"%lu_%@", (unsigned long)self.tag, str];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    NSLog(@"\n=============\nHello, this is bar tint color optimizer.\nNot every color could be matched exactly.\nIf the search goes too long try to switch the Exact option off or hit the Stop button when distance value is small enough.\n=============\n");
    if (TARGET_IPHONE_SIMULATOR) {
        [[[UIAlertView alloc] initWithTitle:@"WARNING" message:@"Please, run this app on the device. Bar tranlucency is applied differently in the simulator!" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Ok", nil] show];
    }
    
    self.colorNavigationbar = ^(NavbarView *navbarView, UIColor *barColor, UIColor *underviewColor) {
        [navbarView.navigationBar setBarTintColor:barColor];
        [navbarView.underlyingView setBackgroundColor:underviewColor];
    };
    
    for (UIView *view in @[self.rBar, self.gBar, self.bBar, self.rUnderview, self.gUnderview, self.bUnderview, self.barColorText, self.underviewColorText]) {
        view.layer.borderColor = [[UIColor lightGrayColor] colorBlendedWithColor:[UIColor whiteColor] factor:0.5].CGColor;
        view.layer.borderWidth = 1.0;
        view.layer.cornerRadius = 3.0;
    }
    self.underviewColorView.layer.borderColor = [[UIColor lightGrayColor] colorBlendedWithColor:[UIColor whiteColor] factor:0.5].CGColor;
    self.underviewColorView.layer.borderWidth = 1.0;
    
    UINib *navbar = [UINib nibWithNibName:@"navbar" bundle:[NSBundle mainBundle]];
    self.navbarView1 = [[navbar instantiateWithOwner:nil options:nil] firstObject];
    self.navbarView2 = [[navbar instantiateWithOwner:nil options:nil] firstObject];
    [self.navbarView1 addSelfToContainerView:self.navbarSlot1];
    [self.navbarView2 addSelfToContainerView:self.navbarSlot2];
    
    
    [self addObserver:self forKeyPath:@"designedBarColor" options:NSKeyValueObservingOptionNew context:nil];
    [self addObserver:self forKeyPath:@"underviewColor" options:NSKeyValueObservingOptionNew context:nil];
    
    NSString *designedBarColor = [[NSUserDefaults standardUserDefaults] stringForKey:[self userDefaultsKeyWithString:@"designedBarColor"]];
    if (!designedBarColor.length) {
        designedBarColor = @"#2886f4";
        // designedBarColor = @"#365491"; // Facebook navigation bar color .
        if (self.hasAlphaComponent) {
            designedBarColor = [NSString stringWithFormat:@"%@%@", designedBarColor, @"80"];
        }
    }
    NSString *underviewColor = [[NSUserDefaults standardUserDefaults] stringForKey:[self userDefaultsKeyWithString:@"underviewColor"]];
    if (!underviewColor.length) {
        underviewColor = @"#fff";
    }
    self.designedBarColor = [UIColor colorWithString:designedBarColor];
    self.underviewColor = [UIColor colorWithString:underviewColor];
    self.rBar.text = [NSString stringWithFormat:@"%d", self.designedBarColor.R];
    self.gBar.text = [NSString stringWithFormat:@"%d", self.designedBarColor.G];
    self.bBar.text = [NSString stringWithFormat:@"%d", self.designedBarColor.B];
    if (self.hasAlphaComponent) {
        self.aBar.text = [NSString stringWithFormat:@"%d", self.designedBarColor.A];
    }
    self.rUnderview.text = [NSString stringWithFormat:@"%d", self.underviewColor.R];
    self.gUnderview.text = [NSString stringWithFormat:@"%d", self.underviewColor.G];
    self.bUnderview.text = [NSString stringWithFormat:@"%d", self.underviewColor.B];
    self.optimizedBarColor = nil;
    
    self.barColorText.text = self.hasAlphaComponent ? self.designedBarColor.hexStringWithA : self.designedBarColor.hexString;
    self.underviewColorText.text = self.underviewColor.hexString;
    
    self.exactSearch = YES;
    self.exactSearchSwitch.on = self.exactSearch;
    
    self.language = CodeObjC;
    self.codeLanguage.selectedSegmentIndex = 0;
    
    CGFloat alpha = self.hasAlphaComponent ? 1.0 : 0.3;
    self.aBar.enabled = self.hasAlphaComponent;
    self.aLabel.enabled = self.hasAlphaComponent;
    self.aBar.alpha = alpha;
    self.aLabel.alpha = alpha;
}


#pragma mark -
#pragma mark Design color editing
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    self.optimizeButton.enabled = (self.designedBarColor != nil && self.underviewColor != nil);
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSString *newText = [textField.text stringByReplacingCharactersInRange:range withString:string];
    newText = newText.lowercaseString;
    UIColor *newColor;
    
    BOOL barColor = (textField == self.barColorText || textField == self.rBar || textField == self.gBar || textField == self.bBar || textField == self.aBar);
    
    // Validate input
    if (textField == self.rBar || textField == self.gBar || textField == self.bBar || textField == self.aBar ||
        textField == self.rUnderview || textField == self.gUnderview || textField == self.bUnderview) {
        NSCharacterSet *rgbCharset = [NSCharacterSet characterSetWithCharactersInString:@"0123456789"];
        NSCharacterSet *notRgbCharset = rgbCharset.invertedSet;
        NSArray *components = [newText componentsSeparatedByCharactersInSet:notRgbCharset];
        NSString *clearString = [components componentsJoinedByString:@""];
        if (clearString.length != newText.length || clearString.length > 3 || clearString.integerValue > 255) {
            return NO;
        }
        uint8_t c = newText.integerValue;
        if (self.rBar == textField) {
            newColor = [self.designedBarColor colorWithNewR:c];
        } else if (self.gBar == textField) {
            newColor = [self.designedBarColor colorWithNewG:c];
        } else if (self.bBar == textField) {
            newColor = [self.designedBarColor colorWithNewB:c];
        } else if (self.aBar == textField) {
            newColor = [self.designedBarColor colorWithNewA:c];
        }
        if (self.rUnderview == textField) {
            newColor = [self.underviewColor colorWithNewR:c];
        } else if (self.gUnderview == textField) {
            newColor = [self.underviewColor colorWithNewG:c];
        } else if (self.bUnderview == textField) {
            newColor = [self.underviewColor colorWithNewB:c];
        }
        if (barColor) {
            self.barColorText.text = (self.hasAlphaComponent ? newColor.hexStringWithA : newColor.hexString);
        } else {
            self.underviewColorText.text = newColor.hexString;
        }
    } else { // its hex input field
        NSCharacterSet *hexColorCharset = [NSCharacterSet characterSetWithCharactersInString:@"#0123456789abcdef"];
        NSCharacterSet *notHexColorCharset = hexColorCharset.invertedSet;
        NSArray *components = [newText componentsSeparatedByCharactersInSet:notHexColorCharset];
        NSString *clearString = [components componentsJoinedByString:@""];
        if (clearString.length != newText.length || clearString.length > (self.hasAlphaComponent ? 9 : 7)) {
            return NO;
        }
        newColor = newText.length ?[UIColor colorWithString:newText] : nil;
        if (barColor) {
            self.rBar.text = [NSString stringWithFormat:@"%d", newColor.R];
            self.gBar.text = [NSString stringWithFormat:@"%d", newColor.G];
            self.bBar.text = [NSString stringWithFormat:@"%d", newColor.B];
            if (self.hasAlphaComponent) {
                self.aBar.text = [NSString stringWithFormat:@"%d", newColor.A];
            }
        } else {
            self.rUnderview.text = [NSString stringWithFormat:@"%d", newColor.R];
            self.gUnderview.text = [NSString stringWithFormat:@"%d", newColor.G];
            self.bUnderview.text = [NSString stringWithFormat:@"%d", newColor.B];
        }
    }
    
    // Update colors
    if (barColor) {
        self.designedBarColor = newColor;
    } else {
        self.underviewColor = newColor;
    }
    
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[self findFirstResponder:self.view] resignFirstResponder];
    });
    return NO;
}


- (IBAction)viewWasTapped:(UITapGestureRecognizer *)sender {
    [[self findFirstResponder:self.view] resignFirstResponder];
    if (CGRectContainsPoint(self.barsContainerView.bounds, [sender locationInView:self.barsContainerView])) {
        [self logOptimizedColor];
    }
}

- (UIView *)findFirstResponder:(UIView *)view {
    if (view.isFirstResponder) {
        return view;
    } else {
        for (UIView *subview in view.subviews) {
            UIView *subviewFirstResponder = [self findFirstResponder:subview];
            if (subviewFirstResponder) {
                return subviewFirstResponder;
            }
        }
    }
    return nil;
}


#pragma mark -
#pragma mark Color setters
- (void)setDesignedBarColor:(UIColor *)designedBarColor {
    NSParameterAssert(self.colorNavigationbar);
    _designedBarColor = designedBarColor;
    NSString *hexString = self.hasAlphaComponent ? designedBarColor.hexStringWithA : designedBarColor.hexString;
    if ( !designedBarColor) {
        designedBarColor = [UIColor clearColor];
        hexString = @"";
    }
    self.designedColorLabel.text = hexString;
    self.barColorView.backgroundColor = designedBarColor;
    self.colorNavigationbar(self.navbarView1, designedBarColor, self.underviewColor);
    [[NSUserDefaults standardUserDefaults] setObject:hexString forKey:[self userDefaultsKeyWithString:@"designedBarColor"]];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)setOptimizedBarColor:(UIColor *)optimizedBarColor {
    NSParameterAssert(self.colorNavigationbar);
    _optimizedBarColor = optimizedBarColor;
    BOOL noColor = (optimizedBarColor == nil);
    
    NSString *optimizedColorString = optimizedBarColor.hexString;
    self.optimizedColorLabel.text = !noColor ? optimizedColorString : @"No optimized color";
    if (noColor) {
        optimizedBarColor = [UIColor clearColor];
    }
    self.colorNavigationbar(self.navbarView2, optimizedBarColor, self.underviewColor);
    
    self.codeLanguage.enabled = !noColor;
    self.logCodeButton.enabled = !noColor;
    self.optimizedColorLabel.alpha = (noColor ? 0.2 : 1.0);
    self.navbarView2.alpha = (noColor ? 0.2 : 1.0);
}

- (void)setUnderviewColor:(UIColor *)underviewColor {
    NSParameterAssert(self.colorNavigationbar);
    _underviewColor = underviewColor;
    self.underviewColorView.backgroundColor = underviewColor;
    self.colorNavigationbar(self.navbarView1, self.designedBarColor, underviewColor);
    self.colorNavigationbar(self.navbarView2, self.optimizedBarColor, underviewColor);
    
    [[NSUserDefaults standardUserDefaults] setObject:underviewColor.hexString forKey:[self userDefaultsKeyWithString:@"underviewColor"]];
    [[NSUserDefaults standardUserDefaults] synchronize];
}


#pragma mark -
#pragma mark Segues
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:calculateSegueIdentifier]) {
        ProgressViewController *progressVc = segue.destinationViewController;
        progressVc.designColor = self.designedBarColor;
        progressVc.underviewColor = self.underviewColor;
        progressVc.exactSearch = self.exactSearch;
        progressVc.colorNavigationbar = self.colorNavigationbar;
        self.optimizedBarColor = nil;
        
    }
}

- (IBAction)unwindToConfigure:(UIStoryboardSegue *)sender {
    UIViewController *sourceViewController = sender.sourceViewController;
    if ([sourceViewController isKindOfClass:ProgressViewController.class]) {
        ProgressViewController *progressVc = (ProgressViewController *)sourceViewController;
        self.optimizedBarColor = progressVc.optimizedColor;
        [self logOptimizedColor];
    }
}


#pragma mark -
#pragma mark Actions
- (void)logOptimizedColor {
    if (self.optimizedBarColor) {
        NSLog(@"\n--\nOptimized color:\n%@\n--", self.optimizedBarColor.hexString);
    }
}

- (IBAction)exactSearchOptionChange:(id)sender {
    self.exactSearch = self.exactSearchSwitch.on;
}

- (IBAction)languageChange:(id)sender {
    self.language = self.codeLanguage.selectedSegmentIndex;
    
}

- (void)setLanguage:(CodeLanguage)language {
    _language = language;
    switch (language) {
        default:
        case CodeObjC:
            bundleFileName = @"CodeObjC";
            break;
            
        case CodeSwift:
            bundleFileName = @"CodeSwift";
            break;
    }
}

- (IBAction)logCode:(id)sender {
    NSURL *fileUrl = [[NSBundle mainBundle] URLForResource:bundleFileName withExtension:nil];
    NSString *text = [NSString stringWithContentsOfURL:fileUrl encoding:NSUTF8StringEncoding error:nil];
    NSParameterAssert(text);
    NSParameterAssert(self.optimizedBarColor);
    NSParameterAssert(self.designedBarColor);
    
    text = [text stringByReplacingOccurrencesOfString:designed_color_stringPattern withString:self.designedBarColor.hexString];
    text = [text stringByReplacingOccurrencesOfString:color_stringPattern withString:self.optimizedBarColor.hexString];
    
    CGFloat red, green, blue, alpha;
    [self.optimizedBarColor getRed:&red green:&green blue:&blue alpha:&alpha];
    NSString *format = @"%f";
    text = [text stringByReplacingOccurrencesOfString:color_rPattern withString:[NSString stringWithFormat:format, red]];
    text = [text stringByReplacingOccurrencesOfString:color_gPattern withString:[NSString stringWithFormat:format, green]];
    text = [text stringByReplacingOccurrencesOfString:color_bPattern withString:[NSString stringWithFormat:format, blue]];
    NSLog(@"\n--\n%@\n--", text);
}

@end
