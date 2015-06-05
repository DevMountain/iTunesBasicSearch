//
//  ViewController.m
//  iTunesBasicSearch
//
//  Created by Taylor Mott on 5 Jun 15.
//  Copyright (c) 2015 DevMountain. All rights reserved.
//

#import "ViewController.h"

static NSString *resultCell = @"resultCell";
static NSString *kSearchCompleteNotification = @"searchComplete";

@interface ViewController () <UISearchBarDelegate, UITableViewDataSource>

@property (strong, nonatomic) NSArray *results;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [self registerForNotifications];
}

- (void)dealloc
{
    [self unregisterForNotification];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - UISearchBarDelegate Method

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [self searchiTunesWithTerm:searchBar.text];
}

#pragma mark - Network Methods

- (void)searchiTunesWithTerm:(NSString *)searchTerm
{
    NSString *stringURL = [NSString stringWithFormat:@"https://itunes.apple.com/search?term=%@", searchTerm];
    
    NSLog(@"making request: %@", stringURL);
    
    NSURL *url = [NSURL URLWithString:[stringURL stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        if (error)
        {
            [self handleError:error];
        }
        else
        {
            [self parseSearchResults:data response:response];
        }
        
        
    }];
    
    [task resume];
}

- (void)parseSearchResults:(NSData *)data response:(NSURLResponse *)response
{
    NSLog(@"%@", response.MIMEType);
    NSLog(@"%@", response.textEncodingName);
    
    NSError *error = nil;
    
    if (error)
    {
        [self handleError:error];
    }
    else
    {
        id result = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
        
        self.results = ((NSDictionary *)result)[@"results"];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kSearchCompleteNotification object:nil];
        
        NSLog(@"%@", self.results);
    }
}

- (void)handleError:(NSError *)error
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error!" message:[NSString stringWithFormat: @"Your search failed. - %@", error.localizedDescription] preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *action = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
    
    [alert addAction:action];
    
    [self.navigationController presentViewController:alert animated:YES completion:nil];
}

#pragma mark - UITableView Datasource Methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.results count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:resultCell];
    
    NSDictionary *resultItem = self.results[indexPath.row];
    
    cell.textLabel.text = resultItem[@"trackName"];
    cell.detailTextLabel.text = resultItem[@"artistName"];
    
    return cell;
}

#pragma mark - Notifcation Methods

- (void)registerForNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadMyTableView) name:kSearchCompleteNotification object:nil];
}

- (void)unregisterForNotification
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)reloadMyTableView
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}

@end

