// --------------------------------------------------------------------------------
// The MIT License (MIT)
//
// Copyright (c) 2014 Shiny Development
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
// --------------------------------------------------------------------------------

#import <UIKit/UIKit.h>
#import "SDStatusBarManager.h"
#import "SDStatusBarOverriderPre8_3.h"
#import "SDStatusBarOverriderPost8_3.h"

static NSString * const SDStatusBarManagerUsingOverridesKey = @"using_overrides";
static NSString * const SDStatusBarManagerBluetoothStateKey = @"bluetooth_state";
static NSString * const SDStatusBarManagerTimeStringKey = @"timeString_state";

@interface SDStatusBarManager ()
@property (nonatomic, strong) NSUserDefaults *userDefaults;
@property (nonatomic, strong) id <SDStatusBarOverrider> overrider;
@end

@implementation SDStatusBarManager

- (void)enableOverrides
{
  self.usingOverrides = YES;

  self.overrider.timeString = [self localizedTimeString];
  self.overrider.carrierName = self.carrierName;
  self.overrider.bluetoothEnabled = self.bluetoothState != SDStatusBarManagerBluetoothHidden;
  self.overrider.bluetoothConnected = self.bluetoothState == SDStatusBarManagerBluetoothVisibleConnected;

  [self.overrider enableOverrides];
}

- (void)disableOverrides
{
  self.usingOverrides = NO;

  [self.overrider disableOverrides];
}

#pragma mark Properties
- (BOOL)usingOverrides
{
  return [self.userDefaults boolForKey:SDStatusBarManagerUsingOverridesKey];
}

- (void)setUsingOverrides:(BOOL)usingOverrides
{
  [self.userDefaults setBool:usingOverrides forKey:SDStatusBarManagerUsingOverridesKey];
}

- (void)setBluetoothState:(SDStatusBarManagerBluetoothState)bluetoothState
{
  if (self.bluetoothState == bluetoothState) return;

  [self.userDefaults setValue:@(bluetoothState) forKey:SDStatusBarManagerBluetoothStateKey];

  if (self.usingOverrides) {
    // Refresh the active status bar
    [self enableOverrides];
  }
}

- (SDStatusBarManagerBluetoothState)bluetoothState
{
  return [[self.userDefaults valueForKey:SDStatusBarManagerBluetoothStateKey] integerValue];
}

- (void)setTimeString:(NSString *)timeString {
  if ([self.timeString isEqualToString:timeString]) return;
  
  [self.userDefaults setObject:timeString forKey:SDStatusBarManagerTimeStringKey];
}
- (NSString *)timeString {
  return [self.userDefaults valueForKey:SDStatusBarManagerTimeStringKey];
}


- (NSUserDefaults *)userDefaults
{
  if (!_userDefaults) {
    _userDefaults = [[NSUserDefaults alloc] initWithSuiteName:@"com.shinydevelopment.SDStatusBarManager"];
  }
  return _userDefaults;
}

- (id<SDStatusBarOverrider>)overrider
{
  if (!_overrider) {
    BOOL before8_3 = ([[[UIDevice currentDevice] systemVersion] compare:@"8.3" options:NSNumericSearch] == NSOrderedAscending);
    if (before8_3) {
      _overrider = [SDStatusBarOverriderPre8_3 new];
    } else {
      _overrider = [SDStatusBarOverriderPost8_3 new];
    }
  }
  return _overrider;
}

#pragma mark Date helper
- (NSString *)localizedTimeString
{
  if (![self.timeString isEqualToString:@""]) {
    return self.timeString;
  }
  
  NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
  formatter.dateStyle = NSDateFormatterNoStyle;
  formatter.timeStyle = NSDateFormatterShortStyle;

  NSDateComponents *components = [[NSCalendar currentCalendar] components: NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay fromDate:[NSDate date]];
  components.hour = 9;
  components.minute = 41;

  return [formatter stringFromDate:[[NSCalendar currentCalendar] dateFromComponents:components]];
}

#pragma mark Singleton instance
+ (SDStatusBarManager *)sharedInstance
{
  static dispatch_once_t predicate = 0;
  __strong static id sharedObject = nil;
  dispatch_once(&predicate, ^{ sharedObject = [[self alloc] init]; });
  return sharedObject;
}

@end
