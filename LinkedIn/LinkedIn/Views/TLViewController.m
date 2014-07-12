//
//  TLViewController.m
//  LinkedIn
//
//  Created by Tilak_G on 27/06/14.
//

#import "TLViewController.h"

CGFloat animatedDistance;
static const CGFloat KEYBOARD_ANIMATION_DURATION = 0.3;
static const CGFloat MINIMUM_SCROLL_FRACTION = 0.2;
static const CGFloat MAXIMUM_SCROLL_FRACTION =1.0;
static const CGFloat LANDSCAPE_KEYBOARD_HEIGHT = 162;
int totalHeight,ylatestPos;

@interface TLViewController ()

@end

@implementation TLViewController

@synthesize requestToken,accessToken,profile,consumer,name, headline,status, postButton, postButtonLabel,statusTextView, updateStatusLabel;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self initLinkedInApi];
    btnIn=[UIButton buttonWithType:UIButtonTypeSystem];
    [btnIn addTarget:self action:@selector(loginToLinkedIn) forControlEvents:UIControlEventTouchUpInside];
    btnIn.frame=CGRectMake(96, 50, 128, 128);
    [btnIn setBackgroundImage:[UIImage imageNamed:@"linkedin.png"] forState:UIControlStateNormal];
    [self.view addSubview:btnIn];
    [self.view setBackgroundColor:[UIColor grayColor]];
    
    activityIndicator=[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    activityIndicator.frame=CGRectMake(110, 200, 100, 100);
    [self.view addSubview:activityIndicator];
}

- (void)initLinkedInApi
{
    apikey = @"75x2ess15btv6t";
    secretkey = @"TOTE8pNPO9sCVN7b";
    
    self.consumer = [[OAConsumer alloc] initWithKey:apikey
                                             secret:secretkey
                                              realm:@"http://api.linkedin.com/"];
    
    requestTokenURLString = @"https://api.linkedin.com/uas/oauth/requestToken";
    accessTokenURLString = @"https://api.linkedin.com/uas/oauth/accessToken";
    userLoginURLString = @"https://www.linkedin.com/uas/oauth/authorize";
    linkedInCallbackURL = @"hdlinked://linkedin/oauth";
    userInvalidateURL   = @"https://api.linkedin.com/uas/oauth/invalidateToken";
    
    requestTokenURL = [NSURL URLWithString:requestTokenURLString] ;
    accessTokenURL = [NSURL URLWithString:accessTokenURLString];
    userLoginURL = [NSURL URLWithString:userLoginURLString];
    invalidateURL = [NSURL URLWithString:userInvalidateURL];
}

#pragma mark -login to LinkedIn
-(void)loginToLinkedIn
{
    [activityIndicator startAnimating];
    [self requestTokenFromProvider];
}


- (void)requestTokenFromProvider
{
    OAMutableURLRequest *request =
    [[OAMutableURLRequest alloc] initWithURL:requestTokenURL
                                    consumer:self.consumer
                                       token:nil
                                    callback:linkedInCallbackURL
                           signatureProvider:nil];
    
    [request setHTTPMethod:@"POST"];
    
    OARequestParameter *nameParam = [[OARequestParameter alloc] initWithName:@"scope"
                                                                       value:@"r_basicprofile+rw_nus"];
    NSArray *params = [NSArray arrayWithObjects:nameParam, nil];
    [request setParameters:params];
    OARequestParameter * scopeParameter=[OARequestParameter requestParameter:@"scope" value:@"r_fullprofile rw_nus"];
    
    [request setParameters:[NSArray arrayWithObject:scopeParameter]];
    
    OADataFetcher *fetcher = [[OADataFetcher alloc] init];
    [fetcher fetchDataWithRequest:request
                         delegate:self
                didFinishSelector:@selector(requestTokenResult:didFinish:)
                  didFailSelector:@selector(requestTokenResult:didFail:)];
}

- (void)requestTokenResult:(OAServiceTicket *)ticket didFinish:(NSData *)data
{
    if (ticket.didSucceed == NO)
        return;
    
    NSString *responseBody = [[NSString alloc] initWithData:data
                                                   encoding:NSUTF8StringEncoding];
    self.requestToken = [[OAToken alloc] initWithHTTPResponseBody:responseBody];
    [self allowUserToLogin];
}

- (void)requestTokenResult:(OAServiceTicket *)ticket didFail:(NSData *)error
{
    [activityIndicator stopAnimating];
    NSLog(@"%@",[error description]);
}

- (void)allowUserToLogin
{
    webView1=[[UIWebView alloc] initWithFrame:CGRectMake(0, 20, 320, 470)];
    webView1.delegate=self;
    [self.view addSubview:webView1];
    NSString *userLoginURLWithToken = [NSString stringWithFormat:@"%@?oauth_token=%@",
                                       userLoginURLString, self.requestToken.key];
    
    userLoginURL = [NSURL URLWithString:userLoginURLWithToken];
    NSURLRequest *request = [NSMutableURLRequest requestWithURL: userLoginURL];
    [webView1 loadRequest:request];
}

- (BOOL)webView:(UIWebView*)webView shouldStartLoadWithRequest:(NSURLRequest*)request navigationType:(UIWebViewNavigationType)navigationType
{
	NSURL *url = request.URL;
	NSString *urlString = url.absoluteString;
    
    BOOL requestForCallbackURL = ([urlString rangeOfString:linkedInCallbackURL].location != NSNotFound);
    if ( requestForCallbackURL )
    {
        BOOL userAllowedAccess = ([urlString rangeOfString:@"user_refused"].location == NSNotFound);
        if ( userAllowedAccess )
        {
            [self.requestToken setVerifierWithUrl:url];
            [self accessTokenFromProvider];
        }
        else
        {
            // User refused to allow our app access
            // Notify parent and close this view
            UIAlertView *alrt=[[UIAlertView alloc] initWithTitle:@"Linked In" message:@"App access denied by the user." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
            
            [alrt show];
            [webView removeFromSuperview];
            
            
        }
    }
    else
    {
        // Case (a) or (b), so ignore it
    }
	return YES;
}




- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [activityIndicator stopAnimating];
}


- (void)accessTokenFromProvider
{
    OAMutableURLRequest *request =
    [[OAMutableURLRequest alloc] initWithURL:accessTokenURL
                                    consumer:self.consumer
                                       token:self.requestToken
                                    callback:nil
                           signatureProvider:nil];
    
    [request setHTTPMethod:@"POST"];
    OADataFetcher *fetcher = [[OADataFetcher alloc] init];
    [fetcher fetchDataWithRequest:request
                         delegate:self
                didFinishSelector:@selector(accessTokenResult:didFinish:)
                  didFailSelector:@selector(accessTokenResult:didFail:)];
}

- (void)accessTokenResult:(OAServiceTicket *)ticket didFinish:(NSData *)data
{
    NSString *responseBody = [[NSString alloc] initWithData:data
                                                   encoding:NSUTF8StringEncoding];
    
    BOOL problem = ([responseBody rangeOfString:@"oauth_problem"].location != NSNotFound);
    if ( problem )
    {
        NSLog(@"Request access token failed.");
        NSLog(@"%@",responseBody);
    }
    else
    {
        self.accessToken = [[OAToken alloc] initWithHTTPResponseBody:responseBody];
    }
    // Notify parent and close this view
    
    [self loginViewDidFinish];
    
}

-(void)accessTokenResult:(OAServiceTicket *)ticket didFail:(NSError *)err
{
    [activityIndicator stopAnimating];
    NSLog(@"%@",err);
}

-(void) loginViewDidFinish
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
    
    // We're going to do these calls serially just for easy code reading.
    // They can be done asynchronously
    // Get the profile, then the network updates
    [self profileApiCall];
	
}

#pragma mark - Get Profile Details
- (void)profileApiCall
{
    [activityIndicator startAnimating];
//    NSURL *url = [NSURL URLWithString:@"http://api.linkedin.com/v1/people/~"];
//    NSURL *url = [NSURL URLWithString:@"http://api.linkedin.com/v1/people/~:(id,first-name,last-name,industry,picture-url,location:(name),positions:(company:(name),title),specialties,date-of-birth,interests,languages)"];
    
    NSURL *url = [NSURL URLWithString:@"http://api.linkedin.com/v1/people/~:(id,first-name,last-name,industry,picture-url,location:(name),headline,specialties,date-of-birth,interests,languages)"];


    OAMutableURLRequest *request =
    [[OAMutableURLRequest alloc] initWithURL:url
                                    consumer:self.consumer
                                       token:self.accessToken
                                    callback:nil
                           signatureProvider:nil];
    
    [request setValue:@"json" forHTTPHeaderField:@"x-li-format"];
    
    OADataFetcher *fetcher = [[OADataFetcher alloc] init];
    [fetcher fetchDataWithRequest:request
                         delegate:self
                didFinishSelector:@selector(profileApiCallResult:didFinish:)
                  didFailSelector:@selector(profileApiCallResult:didFail:)];
    
    [webView1 removeFromSuperview];
    
}

- (void)profileApiCallResult:(OAServiceTicket *)ticket didFinish:(NSData *)data
{
    NSString *responseBody = [[NSString alloc] initWithData:data
                                                   encoding:NSUTF8StringEncoding];
    
    NSDictionary *profile1 = [responseBody objectFromJSONString];
    
    if ( profile1 )
    {
        NSLog(@"%@",profile1);
        [self setUpProfile:profile1];
        
    }
    // The next thing we want to do is call the network updates
//    [self networkApiCall];
}

- (void)profileApiCallResult:(OAServiceTicket *)ticket didFail:(NSData *)error
{
    NSLog(@"%@",[error description]);
}


-(void)setUpProfile:(NSDictionary *)profileData
{
    profileView=[[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 480)];
    [profileView setBackgroundColor:[UIColor colorWithRed:31.0/255.0 green:179.0/255.0 blue:255.0/255.0 alpha:1.0]];
    
    [self.view addSubview:profileView];
    
    lbl1=[[UILabel alloc] initWithFrame:CGRectMake(0, 20, 320, 40)];
    lbl1.font=[UIFont fontWithName:@"Helvetica-Bold" size:20];
    lbl1.textAlignment=NSTextAlignmentCenter;
    lbl1.text=@"Linked In Profile";
    lbl1.backgroundColor=[UIColor clearColor];
    lbl1.textColor=[UIColor grayColor];
    [profileView addSubview:lbl1];
    
    UIImageView *profilepic=[[UIImageView alloc] initWithFrame:CGRectMake(20, lbl1.frame.origin.y+40+1, 78, 80)];
    profilepic.layer.borderColor=[UIColor lightTextColor].CGColor;
    profilepic.layer.borderWidth=3;
    [profileView addSubview:profilepic];
    NSURL *imgUrl=[NSURL URLWithString:[profileData valueForKey:@"pictureUrl"]];
    NSData *imgData=[NSData dataWithContentsOfURL:imgUrl];
    if (imgUrl !=nil) {
        [profilepic setImage:[UIImage imageWithData:imgData]];
    }
    else
    {
        
    }
    
    lblname=[[UILabel alloc] initWithFrame:CGRectMake(105, lbl1.frame.size.height+12, 200, 40)];
    lblname.font=[UIFont fontWithName:@"Helvetica-Bold" size:15];
    lblname.textAlignment=NSTextAlignmentLeft;
    lblname.textColor=[UIColor darkGrayColor];
    lblname.backgroundColor=[UIColor clearColor];
    lblname.text=[NSString stringWithFormat:@"%@ %@",[profileData valueForKey:@"firstName"],[profileData valueForKey:@"lastName"]];
    [profileView addSubview:lblname];
    
    lblHeadLine=[[UILabel alloc] initWithFrame:CGRectMake(105, 90, 200, 50)];
    lblHeadLine.font=[UIFont fontWithName:@"Helvetica-Bold" size:14];
    lblHeadLine.textAlignment=NSTextAlignmentLeft;
    lblHeadLine.textColor=[UIColor lightTextColor];
    lblHeadLine.numberOfLines=0;
    lblHeadLine.backgroundColor=[UIColor clearColor];
    lblHeadLine.lineBreakMode=NSLineBreakByWordWrapping;
    lblHeadLine.text=[NSString stringWithFormat:@"%@ ",[profileData valueForKey:@"headline"]];
    [profileView addSubview:lblHeadLine];
    
    postTxtMsg=[[UITextView alloc] initWithFrame:CGRectMake(50, profilepic.frame.origin.y+80+25, 220, 80)];
    postTxtMsg.backgroundColor=[UIColor whiteColor];
    postTxtMsg.delegate=self;
    postTxtMsg.text=@" ";
    postTxtMsg.layer.cornerRadius=5.0f;
    [profileView addSubview:postTxtMsg];
    
    btnPostTestComment=[UIButton buttonWithType:UIButtonTypeCustom];
    btnPostTestComment.frame=CGRectMake(99,postTxtMsg.frame.origin.y+postTxtMsg.frame.size.height+10, 122, 42);
    [btnPostTestComment setTintColor:[UIColor greenColor]];
    [btnPostTestComment setBackgroundImage:[UIImage imageNamed:@"Share_linkedin.png"] forState:UIControlStateNormal];
    [btnPostTestComment setBackgroundColor:[UIColor grayColor]];
    [btnPostTestComment addTarget:self action:@selector(postButton_TouchUp:) forControlEvents:UIControlEventTouchUpInside];
    [profileView addSubview:btnPostTestComment];
    
    btnFollo=[UIButton buttonWithType:UIButtonTypeCustom];
    btnFollo.frame=CGRectMake(60, btnPostTestComment.frame.origin.y+btnPostTestComment.frame.size.height+10, 200,50);
    [btnFollo setTintColor:[UIColor greenColor]];
    [btnFollo setBackgroundImage:[UIImage imageNamed:@"follow.jpeg.png"] forState:UIControlStateNormal];
    [btnFollo setBackgroundColor:[UIColor grayColor]];
    [btnFollo addTarget:self action:@selector(callFollowButton) forControlEvents:UIControlEventTouchUpInside];
    [profileView addSubview:btnFollo];
    
    goBack=[UIButton buttonWithType:UIButtonTypeCustom];
    goBack.frame=CGRectMake(135, btnFollo.frame.origin.y+50+10, 50, 50);
    [goBack setBackgroundImage:[UIImage imageNamed:@"back.png"] forState:UIControlStateNormal];
    [goBack addTarget:self action:@selector(goBack) forControlEvents:UIControlEventTouchUpInside];
    [profileView addSubview:goBack];
    [activityIndicator stopAnimating];
}

-(void)goBack
{
    [self invalidateTokenFromProvider];
    [profileView removeFromSuperview];
}

#pragma mark -Invalidate token

- (void)invalidateTokenFromProvider
{
    OAMutableURLRequest *request =
    [[OAMutableURLRequest alloc] initWithURL:invalidateURL
                                    consumer:self.consumer
                                       token:self.accessToken
                                    callback:linkedInCallbackURL
                           signatureProvider:nil];
    
    [request setHTTPMethod:@"GET"];
    
    
    [request setValue:@"json" forHTTPHeaderField:@"x-li-format"];
    
    OADataFetcher *fetcher = [[OADataFetcher alloc] init];
    [fetcher fetchDataWithRequest:request
                         delegate:self
                didFinishSelector:@selector(requestInvalidateTokenResult:didFinish:)
                  didFailSelector:@selector(requestInvalidateTokenResult:didFail:)];
}

- (void)requestInvalidateTokenResult:(OAServiceTicket *)ticket didFinish:(NSData *)data
{
    NSLog(@"***************************\nUserLoggedOut\n***************");
}

-(void)requestInvalidateTokenResult:(OAServiceTicket *)ticket didFail:(NSError *)err
{
    NSLog(@"%@",err);
}

#pragma mark -To Share Content or Post
- (void)postButton_TouchUp:(UIButton *)sender
{
    [activityIndicator startAnimating];
    if (postTxtMsg.text.length <=0) {
        UIAlertView *alert=[[UIAlertView alloc] initWithTitle:@"" message:@"Please Enter the text To Share" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
        [alert show];
        return;
    }
    
    [postTxtMsg resignFirstResponder];
    NSURL *url = [NSURL URLWithString:@"http://api.linkedin.com/v1/people/~/shares"];
    OAMutableURLRequest *request =
    [[OAMutableURLRequest alloc] initWithURL:url
                                    consumer:self.consumer
                                       token:self.accessToken
                                    callback:nil
                           signatureProvider:nil];
    
    NSDictionary *contentDic=[[NSDictionary alloc] initWithObjectsAndKeys:
                              @"IOS-App Testing",@"title",
                              @"www.rossitek.com",@"submitted-url",
                              @"http://www.rossitek.com/images/NEW_BANNER.jpg",@"submitted-image-url",
                              @"Rossitek Mobile Apps Development Company",@"description",nil];
    
    NSDictionary *update = [[NSDictionary alloc] initWithObjectsAndKeys:
                            [[NSDictionary alloc]
                             initWithObjectsAndKeys:
                             @"anyone",@"code",nil], @"visibility",
                            postTxtMsg.text, @"comment",
                            contentDic, @"content",nil];
    
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    NSString *updateString = [update JSONString];
    
    [request setHTTPBodyWithString:updateString];
	[request setHTTPMethod:@"POST"];
    
    OADataFetcher *fetcher = [[OADataFetcher alloc] init];
    [fetcher fetchDataWithRequest:request
                         delegate:self
                didFinishSelector:@selector(postUpdateApiCallResult:didFinish:)
                  didFailSelector:@selector(postUpdateApiCallResult:didFail:)];
}

- (void)postUpdateApiCallResult:(OAServiceTicket *)ticket didFinish:(NSData *)data
{
    // The next thing we want to do is call the network updates
    NSLog(@"Post Test Message Successful");
    [activityIndicator stopAnimating];
    UIAlertView *alrt=[[UIAlertView alloc] initWithTitle:@"Linked In" message:@"Message has been posted on you wall successfully."  delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
    [alrt show];
//    [self networkApiCall];
    
}

- (void)postUpdateApiCallResult:(OAServiceTicket *)ticket didFail:(NSError *)error
{
    [activityIndicator stopAnimating];
    UIAlertView *alrt=[[UIAlertView alloc] initWithTitle:@"Error !" message:@"Failed To Post Message."  delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
    [alrt show];
    NSLog(@"%@",[error description]);
}


#pragma mark -Follo A Company
//Follo Button Action
-(void)callFollowButton
{
    [activityIndicator startAnimating];
    NSURL *url = [NSURL URLWithString:@"http://api.linkedin.com/v1/people/~/following/companies/"];
    
    OAMutableURLRequest *request = [[OAMutableURLRequest alloc] initWithURL:url
                                                                   consumer:self.consumer
                                                                      token:self.accessToken
                                                                   callback:nil
                                                          signatureProvider:nil];

        //Tofollow Apesb Company
//    NSDictionary *updates =[[NSDictionary alloc]
//                              initWithObjectsAndKeys:
//                              @"1838737",@"id",nil];
    
    
    //Tofollow Rossitek Company
    NSDictionary *updates =[[NSDictionary alloc]
                            initWithObjectsAndKeys:
                            @"2437052",@"id",nil];
    
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"json" forHTTPHeaderField:@"x-li-format"];
    NSString *updateString = [updates JSONString];
    
    [request setHTTPBodyWithString:updateString];
    [request setHTTPMethod:@"POST"];
    
    OADataFetcher *fetcher = [[OADataFetcher alloc] init];
    [fetcher fetchDataWithRequest:request
                         delegate:self
                didFinishSelector:@selector(followApiCallResult:didFinish:)
                  didFailSelector:@selector(followApiCallResult:didFail:)];
    
}

-(void)followApiCallResult:(OAServiceTicket *)ticket didFinish:(NSData *)data
{
    [activityIndicator stopAnimating];
    NSLog(@"Following Company Successful");
    UIAlertView *alrt=[[UIAlertView alloc] initWithTitle:@"Linked In" message:@"You Are Now Following Rossitek Mobile Apps Development Company" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
    [alrt show];
//    [self networkApiCall];
}

-(void)followApiCallResult:(OAServiceTicket *)ticket didFail:(NSError *)err
{
    NSLog(@"Following Company Failed");
    [activityIndicator stopAnimating];
    UIAlertView *alrt=[[UIAlertView alloc] initWithTitle:@"Error !" message:@"Could not complete you request to follow"  delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
    [alrt show];
    NSLog(@"%@",[err localizedDescription]);
}


#pragma  mark -network api call
- (void)networkApiCall
{
    NSURL *url = [NSURL URLWithString:@"http://api.linkedin.com/v1/people/~/network/updates?scope=self&count=1&type=STAT"];
    OAMutableURLRequest *request =
    [[OAMutableURLRequest alloc] initWithURL:url
                                    consumer:self.consumer
                                       token:self.accessToken
                                    callback:nil
                           signatureProvider:nil];
    
    [request setValue:@"json" forHTTPHeaderField:@"x-li-format"];
    
    OADataFetcher *fetcher = [[OADataFetcher alloc] init];
    [fetcher fetchDataWithRequest:request
                         delegate:self
                didFinishSelector:@selector(networkApiCallResult:didFinish:)
                  didFailSelector:@selector(networkApiCallResult:didFail:)];
    
}

- (void)networkApiCallResult:(OAServiceTicket *)ticket didFinish:(NSData *)data
{
    NSString *responseBody = [[NSString alloc] initWithData:data
                                                   encoding:NSUTF8StringEncoding];
    
    NSDictionary *person = [[[[[responseBody objectFromJSONString]
                               objectForKey:@"values"]
                              objectAtIndex:0]
                             objectForKey:@"updateContent"]
                            objectForKey:@"person"];
    
    
    if ( [person objectForKey:@"currentStatus"] )
    {
//        [postButton setHidden:false];
//        [postButtonLabel setHidden:false];
//        [statusTextView setHidden:false];
//        [updateStatusLabel setHidden:false];
//        status.text = [person objectForKey:@"currentStatus"];
    } else {
//        [postButton setHidden:false];
//        [postButtonLabel setHidden:false];
//        [statusTextView setHidden:false];
//        [updateStatusLabel setHidden:false];
//        status.text = [[[[person objectForKey:@"personActivities"]
//                         objectForKey:@"values"]
//                        objectAtIndex:0]
//                       objectForKey:@"body"];
        
    }
    NSLog(@"%@",person);
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)networkApiCallResult:(OAServiceTicket *)ticket didFail:(NSData *)error
{
    NSLog(@"%@",[error description]);
}



#pragma mark - UITextView delegate methods

-(void)textViewDidBeginEditing:(UITextView *)textView{

    textView.text=@"";
    CGRect textFieldRect = [self.view convertRect:textView.bounds fromView: textView];
    CGRect viewRect = [self.view convertRect:self.view.bounds fromView:self.view];
    CGFloat midline = textFieldRect.origin.y + 0.5 * textFieldRect.size.height;
    CGFloat numerator = midline - viewRect.origin.y - MINIMUM_SCROLL_FRACTION * viewRect.size.height;
    CGFloat denominator = (MAXIMUM_SCROLL_FRACTION - MINIMUM_SCROLL_FRACTION) * viewRect.size.height;
    CGFloat heightFraction = numerator / denominator;
    if (heightFraction < 0.0)
    {
        heightFraction = 0.0;
    }
    else if (heightFraction > 1.0)
    {
        heightFraction = 1.0;
    }
    animatedDistance = floor(LANDSCAPE_KEYBOARD_HEIGHT * heightFraction);
    CGRect viewFrame =self.view.frame;
    viewFrame.origin.y -= animatedDistance;
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration:KEYBOARD_ANIMATION_DURATION];
    [self.view setFrame:viewFrame];
    
    [UIView commitAnimations];
    
}
-(void)textViewDidEndEditing:(UITextView *)textView
{
    [textView resignFirstResponder];
    CGRect viewFrame =self.view.frame;
    viewFrame.origin.y += animatedDistance;
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration:KEYBOARD_ANIMATION_DURATION];
    [self.view setFrame:viewFrame];
    [UIView commitAnimations];
    
}

-(BOOL)textViewShouldEndEditing:(UITextView *)textView
{
    [textView resignFirstResponder];
    return YES;
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [postTxtMsg resignFirstResponder];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
