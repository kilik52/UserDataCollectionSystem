//
//  UDCBaseViewController.m
//  UserDataCollection
//
//  Created by 朱 曦炽 on 13-9-20.
//  Copyright (c) 2013年 Mirroon. All rights reserved.
//

#import "UDCBaseViewController.h"
#import "UDCSystem.h"

@interface UDCBaseViewController ()

@end

@implementation UDCBaseViewController

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
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if ([self.udcTitle length] > 0) {
        [UDCSystem pageAppear:self.udcTitle];
    }
    else {
        [UDCSystem pageAppear:self.title];
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    if ([self.udcTitle length] > 0) {
        [UDCSystem pageDisappear:self.udcTitle];
    }
    else {
        [UDCSystem pageDisappear:self.title];
    }
}
@end
