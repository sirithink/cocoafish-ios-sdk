//
//  CCResponse.m
//  Demo
//
//  Created by Wei Kong on 12/15/10.
//  Copyright 2011 Cocoafish Inc. All rights reserved.
//

#import "CCResponse.h"
#import "CCConstants.h"
#import "CCObject.h"
#import <YAJL/YAJL.h>

@interface CCResponse()
@property (nonatomic, readwrite, retain) CCMeta *meta;
@property (nonatomic, readwrite, retain) NSDictionary *response;
@property (nonatomic, readwrite, retain) NSArray *responses;

-(id)initWithJsonResponse:(NSDictionary *)jsonResponse;

@end

@interface CCMeta()
@property (nonatomic, readwrite, retain) NSString *status;
@property (nonatomic, readwrite, retain) NSString *message;
@property (nonatomic, readwrite, retain) NSString *method;
@property (nonatomic, readwrite, retain) NSNumber *totalResults;
@property (nonatomic, readwrite, retain) NSNumber *totalPages;
@property (nonatomic, readwrite, retain) NSNumber *page;
@property (nonatomic, readwrite, retain) NSNumber *perPage;


@end

@implementation CCResponse
@synthesize response = _response;
@synthesize responses = _responses;
@synthesize meta = _meta;

-(id)initWithJsonResponse:(NSDictionary *)jsonResponse
{
	
	if ((self = [super init])) {
		self.response = [jsonResponse objectForKey:CC_JSON_RESPONSE];
		self.meta = [[[CCMeta alloc] initWithJsonResponse:jsonResponse] autorelease];
		
		// check if this is a compound response
		NSArray *compoundResponses = [_response objectForKey:CC_JSON_RESPONSES];
		if (compoundResponses && [compoundResponses isKindOfClass:[NSArray class]]) {
			NSMutableArray *responseArray = [NSMutableArray arrayWithCapacity:[compoundResponses count]];
			for (NSDictionary *rp in compoundResponses) {
				CCResponse *tmpResponse = [[[CCResponse alloc] initWithJsonResponse:rp] autorelease];
				[responseArray addObject:tmpResponse];
			}
			if ([responseArray count] > 0) {
				self.responses = (NSArray *)responseArray;
			}
		}
		// Sanity check
		if (_meta == nil) {
			NSLog(@"No meta data found in response");
			[self release];
			self = nil;
		}
	}
	return self;
}

-(id)initWithJsonData:(NSData *)jsonData
{
	@try {
		NSDictionary *jsonResponse = [jsonData yajl_JSON];
		return ([self initWithJsonResponse:jsonResponse]);
	} 
	@catch (NSException *exception) {
		// Failed to parse
		NSLog(@"Failed to parse data using YAJL JSON parser. Reason: %@", exception.reason);
	}
	return nil;
}

-(void)dealloc
{
	self.response = nil;
	self.meta = nil;
	self.responses = nil;    

	[super dealloc];
	
}


// Get an array of a class type from a jsonresponse, the caller needs to speicify the jsonTag to identify 
// the array and the class type of the objects that will be stored as array, the class type should have 
// method initWithJsonResponse implemented
+(NSArray *)getArrayFromJsonResonse:(NSDictionary *)jsonResponse jsonTag:(NSString *)jsonTag class:(Class)class
{
	if (!class_respondsToSelector(class, @selector(initWithJsonResponse:))) {
		// class doesn't have
		return nil;
	}
	NSMutableArray	*array;
	NSArray *jsonArray = [jsonResponse objectForKey:jsonTag];
	if (jsonArray && [jsonArray isKindOfClass:[NSArray class]]) {
		array = [NSMutableArray arrayWithCapacity:[jsonArray count]];
		for (NSDictionary *jsonObject in jsonArray) {
			CCObject *object = (CCObject *)[[class alloc] initWithJsonResponse:jsonObject];
			if (object) {
				[array addObject:object];
			}
		}
	}
	return array;
}

@end

@implementation CCMeta

@synthesize status = _status;
@synthesize message = _message;
@synthesize code = _code;
@synthesize method = _method;
@synthesize totalResults = _totalResults;
@synthesize totalPages = _totalPages;
@synthesize perPage = _perPage;
@synthesize page = _page;

-(id)initWithJsonResponse:(NSDictionary *)jsonResponse
{
	NSDictionary *meta = [jsonResponse objectForKey:CC_JSON_META];

	if (meta) {
		self = [super init];
	}
	if (self) {
		// get response code and details if there are any
		self.message = [meta objectForKey:CC_JSON_META_MESSAGE];
		self.method = [meta objectForKey:CC_JSON_META_METHOD];
		NSString *tmpValue = [meta objectForKey:CC_JSON_META_CODE];
		_code = tmpValue ? [tmpValue intValue] : 0;
		self.status = [meta objectForKey:CC_JSON_META_STATUS];
        
		tmpValue = [meta objectForKey:CC_JSON_TOTAL_COUNT];
		if (tmpValue) {
            self.totalResults = [NSNumber numberWithInt:[tmpValue intValue]];
        }
		
		tmpValue = [meta objectForKey:CC_JSON_TOTAL_PAGE];
        if (tmpValue) {
            self.totalPages = [NSNumber numberWithInt:[tmpValue intValue]];
        }
        
		tmpValue = [meta objectForKey:CC_JSON_PER_PAGE_COUNT];
		if (tmpValue) {
            self.perPage = [NSNumber numberWithInt:[tmpValue intValue]];
        }
        
		tmpValue = [meta objectForKey:CC_JSON_CUR_PAGE];
        if (tmpValue) {
            self.page = [NSNumber numberWithInt:[tmpValue intValue]];
        }
	}
	return self;
}

-(NSString *)description
{
    if (self.totalResults != nil) {
        return [NSString stringWithFormat:@"CCMeta:\n\tstatus: %@\n\tmessage: %@\n\tmethod: %@\n\tcode: %d\n\ttotalResults: %@\n\ttotalpages: %@\n\tpage: %@\n\tperPage: %@",
                self.status, self.message, self.method, self.code, self.totalResults, self.totalPages, self.page, self.perPage];
    } 
    return [NSString stringWithFormat:@"CCMeta:\n\tstatus: %@\n\tmessage: %@\n\tmethod: %@\n\tcode: %d",
            self.status, self.message, self.method, self.code];
    
}

-(void)dealloc
{
	self.message = nil;
	self.status = nil;
	self.method = nil;
    self.totalResults = nil;
    self.totalPages = nil;
    self.perPage = nil;
    self.page = nil;
	[super dealloc];
}
@end