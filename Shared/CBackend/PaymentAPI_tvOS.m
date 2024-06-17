//
//  PaymentAPI_tvOS.m
//  PurePKG
//
//  Created by Lrdsnow on 6/15/24.
//  a lot of code in here is from this: https://github.com/jvanakker/tvOSBrowser/blob/master/_Project/Browser/ViewController.m
//

#import "PaymentAPI_tvOS.h"
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

#if TARGET_OS_TV

static UIColor *kTextColor() {
    if (@available(tvOS 13, *)) {
        return UIColor.labelColor;
    } else {
        return UIColor.blackColor;
    }
}

static UIImage *kDefaultCursor() {
    static UIImage *image;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        image = [UIImage imageNamed:@"Cursor"];
    });
    return image;
}

static UIImage *kPointerCursor() {
    static UIImage *image;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        image = [UIImage imageNamed:@"Pointer"];
    });
    return image;
}

@interface PaymentAPI_WebAuthenticationCoordinator_objc ()

@property (nonatomic, copy) void (^completionHandler)(NSURL * _Nullable authenticatedURL);

@property UIImageView *cursorView;
@property BOOL cursorMode;
@property CGPoint lastTouchLocation;
@property UITapGestureRecognizer *touchSurfaceDoubleTapRecognizer;
@property UITapGestureRecognizer *playPauseDoubleTapRecognizer;

@end

@implementation PaymentAPI_WebAuthenticationCoordinator_objc

- (instancetype)init {
    self = [super init];
    if (self) {
        _webView = [[NSClassFromString(@"UIWebView") alloc] init];
    }
    return self;
}

- (void)authWithURL:(NSURL *)url completion:(void (^)(NSURL * _Nullable authenticatedURL))completionHandler {
    self.completionHandler = completionHandler;
    
    UIWindow *mainWindow = [[UIApplication sharedApplication] keyWindow];
    UIViewController *topViewController = mainWindow.rootViewController;
    
    while (topViewController.presentedViewController) {
        topViewController = topViewController.presentedViewController;
    }
    
    [self.webView setDelegate:self];
    [self.webView loadRequest:[NSURLRequest requestWithURL:url]];
}

#pragma mark - UIWebViewDelegate

- (void)webViewDidFinishLoad:(id)webView {
    
    self.touchSurfaceDoubleTapRecognizer = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(handleTouchSurfaceDoubleTap:)];
    self.touchSurfaceDoubleTapRecognizer.numberOfTapsRequired = 2;
    self.touchSurfaceDoubleTapRecognizer.allowedPressTypes = @[[NSNumber numberWithInteger:UIPressTypeSelect]];
    [self.webView addGestureRecognizer:self.touchSurfaceDoubleTapRecognizer];
    
    self.playPauseDoubleTapRecognizer = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(handlePlayPauseDoubleTap:)];
    self.playPauseDoubleTapRecognizer.numberOfTapsRequired = 2;
    self.playPauseDoubleTapRecognizer.allowedPressTypes = @[[NSNumber numberWithInteger:UIPressTypePlayPause]];

    [self.webView addGestureRecognizer:self.playPauseDoubleTapRecognizer];
    
    self.cursorView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 64, 64)];
    self.cursorView.center = CGPointMake(CGRectGetMidX([UIScreen mainScreen].bounds), CGRectGetMidY([UIScreen mainScreen].bounds));
    self.cursorView.image = kDefaultCursor();
    [self.webView addSubview:self.cursorView];
    
    NSURLRequest *request = [webView request];
    NSURL *currentURL = request.URL;
    
    if ([currentURL.absoluteString containsString:@"authenticated"]) {
        [self handleAuthenticationSuccess:currentURL];
    } else {}
}

- (void)webView:(id)webView didFailLoadWithError:(NSError *)error {
    // Handle web view load failures
    NSLog(@"WebView load error: %@", error);
    [self handleAuthenticationFailure];
}

#pragma mark - Remote Button
-(void)pressesEnded:(NSSet<UIPress *> *)presses withEvent:(UIPressesEvent *)event
{
    if (presses.anyObject.type == UIPressTypeSelect) // Handle the normal single Touchpad press with our virtual cursor
    {
        // Handle the virtual cursor
        
        
        
        CGPoint point = [self.webView convertPoint:self.cursorView.frame.origin toView:self.webView];
        
        int displayWidth = [[self.webView stringByEvaluatingJavaScriptFromString:@"window.innerWidth"] intValue];
        CGFloat scale = [self.webView frame].size.width / displayWidth;
        
        point.x /= scale;
        point.y /= scale;
        
        [self.webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"document.elementFromPoint(%i, %i).click()", (int)point.x, (int)point.y]];
        // Make the UIWebView method call
        NSString *fieldType = [self.webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"document.elementFromPoint(%i, %i).type;", (int)point.x, (int)point.y]];
        /*
         if (fieldType == nil) {
         NSString *contentEditible = [self.webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"document.elementFromPoint(%i, %i).getAttribute('contenteditable');", (int)point.x, (int)point.y]];
         NSLog(contentEditible);
         if ([contentEditible isEqualToString:@"true"]) {
         fieldType = @"text";
         }
         }
         else if ([[fieldType stringByReplacingOccurrencesOfString:@" " withString:@""] isEqualToString: @""]) {
         NSString *contentEditible = [self.webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"document.elementFromPoint(%i, %i).getAttribute('contenteditable');", (int)point.x, (int)point.y]];
         NSLog(contentEditible);
         if ([contentEditible isEqualToString:@"true"]) {
         fieldType = @"text";
         }
         }
         NSLog(fieldType);
         */
        fieldType = fieldType.lowercaseString;
        if ([fieldType isEqualToString:@"date"] || [fieldType isEqualToString:@"datetime"] || [fieldType isEqualToString:@"datetime-local"] || [fieldType isEqualToString:@"email"] || [fieldType isEqualToString:@"month"] || [fieldType isEqualToString:@"number"] || [fieldType isEqualToString:@"password"] || [fieldType isEqualToString:@"search"] || [fieldType isEqualToString:@"tel"] || [fieldType isEqualToString:@"text"] || [fieldType isEqualToString:@"time"] || [fieldType isEqualToString:@"url"] || [fieldType isEqualToString:@"week"]) {
            NSString *fieldTitle = [self.webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"document.elementFromPoint(%i, %i).title;", (int)point.x, (int)point.y]];
            if ([fieldTitle isEqualToString:@""]) {
                fieldTitle = fieldType;
            }
            NSString *placeholder = [self.webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"document.elementFromPoint(%i, %i).placeholder;", (int)point.x, (int)point.y]];
            if ([placeholder isEqualToString:@""]) {
                if (![fieldTitle isEqualToString:fieldType]) {
                    placeholder = [NSString stringWithFormat:@"%@ Input", fieldTitle];
                }
                else {
                    placeholder = @"Text Input";
                }
            }
            NSString *testedFormResponse = [self.webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"document.elementFromPoint(%i, %i).form.hasAttribute('onsubmit');", (int)point.x, (int)point.y]];
            UIAlertController *alertController = [UIAlertController
                                                  alertControllerWithTitle:@"Input Text"
                                                  message: [fieldTitle capitalizedString]
                                                  preferredStyle:UIAlertControllerStyleAlert];
            
            [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField)
             {
                if ([fieldType isEqualToString:@"url"]) {
                    textField.keyboardType = UIKeyboardTypeURL;
                }
                else if ([fieldType isEqualToString:@"email"]) {
                    textField.keyboardType = UIKeyboardTypeEmailAddress;
                }
                else if ([fieldType isEqualToString:@"tel"] || [fieldType isEqualToString:@"number"] || [fieldType isEqualToString:@"date"] || [fieldType isEqualToString:@"datetime"] || [fieldType isEqualToString:@"datetime-local"]) {
                    textField.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
                }
                else {
                    textField.keyboardType = UIKeyboardTypeDefault;
                }
                textField.placeholder = [placeholder capitalizedString];
                if ([fieldType isEqualToString:@"password"]) {
                    textField.secureTextEntry = YES;
                }
                textField.text = [self.webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"document.elementFromPoint(%i, %i).value;", (int)point.x, (int)point.y]];
                textField.textColor = kTextColor();
                [textField setReturnKeyType:UIReturnKeyDone];
                [textField addTarget:self
                              action:@selector(alertTextFieldShouldReturn:)
                    forControlEvents:UIControlEventEditingDidEnd];
                
            }];
            UIAlertAction *inputAndSubmitAction = [UIAlertAction
                                                   actionWithTitle:@"Submit"
                                                   style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction *action)
                                                   {
                UITextField *inputViewTextField = alertController.textFields[0];
                NSString *javaScript = [NSString stringWithFormat:@"var textField = document.elementFromPoint(%i, %i);"
                                        "textField.value = '%@';"
                                        "textField.form.submit();"
                                        //"var ev = document.createEvent('KeyboardEvent');"
                                        //"ev.initKeyEvent('keydown', true, true, window, false, false, false, false, 13, 0);"
                                        //"document.body.dispatchEvent(ev);"
                                        , (int)point.x, (int)point.y, inputViewTextField.text];
                [self.webView stringByEvaluatingJavaScriptFromString:javaScript];
            }];
            UIAlertAction *inputAction = [UIAlertAction
                                          actionWithTitle:@"Done"
                                          style:UIAlertActionStyleDefault
                                          handler:^(UIAlertAction *action)
                                          {
                UITextField *inputViewTextField = alertController.textFields[0];
                NSString *javaScript = [NSString stringWithFormat:@"var textField = document.elementFromPoint(%i, %i);"
                                        "textField.value = '%@';", (int)point.x, (int)point.y, inputViewTextField.text];
                [self.webView stringByEvaluatingJavaScriptFromString:javaScript];
            }];
            UIAlertAction *cancelAction = [UIAlertAction
                                           actionWithTitle:nil
                                           style:UIAlertActionStyleCancel
                                           handler:nil];
            [alertController addAction:inputAction];
            if (testedFormResponse != nil) {
                if ([testedFormResponse isEqualToString:@"true"]) {
                    [alertController addAction:inputAndSubmitAction];
                }
            }
            [alertController addAction:cancelAction];
            UIViewController *topViewController = UIApplication.sharedApplication.keyWindow.rootViewController;
            if (topViewController) {
                [topViewController presentViewController:alertController animated:YES completion:nil];
            }
            UITextField *inputViewTextField = alertController.textFields[0];
            if ([[inputViewTextField.text stringByReplacingOccurrencesOfString:@" " withString:@""] isEqualToString:@""]) {
                [inputViewTextField becomeFirstResponder];
            }
        }
        
    }
}

#pragma mark - Cursor Input

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    self.lastTouchLocation = CGPointMake(-1, -1);
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    for (UITouch *touch in touches)
    {
        CGPoint location = [touch locationInView:self.webView];
        
        if(self.lastTouchLocation.x == -1 && self.lastTouchLocation.y == -1)
        {
            // Prevent cursor from recentering
            self.lastTouchLocation = location;
        }
        else
        {
            CGFloat xDiff = location.x - self.lastTouchLocation.x;
            CGFloat yDiff = location.y - self.lastTouchLocation.y;
            CGRect rect = self.cursorView.frame;
            
            if(rect.origin.x + xDiff >= 0 && rect.origin.x + xDiff <= 1920)
                rect.origin.x += xDiff;//location.x - self.startPos.x;//+= xDiff; //location.x;
            
            if(rect.origin.y + yDiff >= 0 && rect.origin.y + yDiff <= 1080)
                rect.origin.y += yDiff;//location.y - self.startPos.y;//+= yDiff; //location.y;
            
            self.cursorView.frame = rect;
            self.lastTouchLocation = location;
        }
        
        // Try to make mouse cursor become pointer icon when pointer element is clickable
        self.cursorView.image = kDefaultCursor();
        if ([self.webView request] == nil) {
            return;
        }
        if (self.cursorMode) {
            CGPoint point = [self.webView convertPoint:self.cursorView.frame.origin toView:self.webView];
            if(point.y < 0) {
                return;
            }
            
            int displayWidth = [[self.webView stringByEvaluatingJavaScriptFromString:@"window.innerWidth"] intValue];
            CGFloat scale = [self.webView frame].size.width / displayWidth;
            
            point.x /= scale;
            point.y /= scale;
            
            // Seems not so low, check everytime when touchesMoved
            NSString *containsLink = [self.webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"document.elementFromPoint(%i, %i).closest('a, input') !== null", (int)point.x, (int)point.y]];
            if ([containsLink isEqualToString:@"true"]) {
                self.cursorView.image = kPointerCursor();
            }
        }
        
        // We only use one touch, break the loop
        break;
    }
    
}

#pragma mark - Private Methods

- (void)handleAuthenticationSuccess:(NSURL *)authenticatedURL {
    [self.webView stopLoading];
    
    UIWindow *mainWindow = [[UIApplication sharedApplication] keyWindow];
    UIViewController *topViewController = mainWindow.rootViewController;
    
    while (topViewController.presentedViewController) {
        topViewController = topViewController.presentedViewController;
    }
    
    [topViewController.presentedViewController dismissViewControllerAnimated:YES completion:^{
        if (self.completionHandler) {
            self.completionHandler(authenticatedURL);
        }
    }];
}

- (void)handleAuthenticationFailure {
    [self.webView stopLoading];
    if (self.completionHandler) {
        self.completionHandler(nil);
    }
}

@end

#endif
