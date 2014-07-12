//
//  TLViewController.h
//  LinkedIn
//
//  Created by Tilak_G  on 27/06/14.
//

#import <UIKit/UIKit.h>
#import "JSONKit.h"
#import "OAConsumer.h"
#import "OAMutableURLRequest.h"
#import "OADataFetcher.h"
#import "OATokenManager.h"


@interface TLViewController : UIViewController<UIWebViewDelegate,UITextViewDelegate>
{
    
    OAToken *requestToken;
    OAToken *accessToken;
    OAConsumer *consumer;
    
    NSDictionary *profile;
    
    NSString *apikey;
    NSString *secretkey;
    NSString *requestTokenURLString;
    NSURL *requestTokenURL;
    NSString *accessTokenURLString;
    NSURL *accessTokenURL;
    NSString *userLoginURLString;
    NSURL *userLoginURL;
    NSString *linkedInCallbackURL;
    NSString *userInvalidateURL;
    NSURL *invalidateURL;
    
    
    UIWebView *webView1;
    UILabel *lbl1;
    UILabel *lblname;
    UILabel *lblHeadLine;
    
    UIView *profileView;
    
    UIButton *btnPostTestComment,*btnFollo,*goBack;
    UIButton *btnIn;
    UIActivityIndicatorView *activityIndicator;
    UITextView *postTxtMsg;
}

@property (nonatomic, retain)  UIButton *postButton;
@property (nonatomic, retain)  UILabel *postButtonLabel;
@property (nonatomic, retain)  UILabel *name;
@property (nonatomic, retain)  UILabel *headline;
@property (nonatomic, retain)  UILabel *status;
@property (nonatomic, retain)  UILabel *updateStatusLabel;
@property (nonatomic, retain)  UITextField *statusTextView;

@property(nonatomic, retain) OAToken *requestToken;
@property(nonatomic, retain) OAToken *accessToken;
@property(nonatomic, retain) NSDictionary *profile;
@property(nonatomic, retain) OAConsumer *consumer;

- (void)initLinkedInApi;

@end
