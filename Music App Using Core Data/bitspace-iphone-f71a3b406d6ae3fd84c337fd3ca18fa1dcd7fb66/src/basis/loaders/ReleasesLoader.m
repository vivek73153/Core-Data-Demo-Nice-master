//
//  ReleasesLoader.m
//  bitspace-iphone
//
//  Created by Niklas Holmgren on 2010-06-16.
//  Copyright 2010 Koneko Collective Ltd. All rights reserved.
//

#import "ReleasesLoader.h"
#import "Connection.h"
#import "Response.h"
#import "Release.h"
#import "Artist.h"
#import "Track.h"
#import "AppDelegate.h"
#import "ObjectiveResourceDateFormatter.h"
#import "NSString+SBJSON.h"


@implementation ReleasesLoader

@synthesize delegate;
@synthesize insertionContext, persistentStoreCoordinator, releaseEntityDescription;
@synthesize didFail, lastUpdateDate;

- (void)dealloc {
	[insertionContext release];
	[persistentStoreCoordinator release];
	[artistEntityDescription release];
	[releaseEntityDescription release];
	[trackEntityDescription release];
	[super dealloc];
}

- (NSPredicate *)predicateForURL:(NSString *)url {
	return [NSPredicate predicateWithFormat:@"url == %@", url];
}

- (Release *)findReleaseWithURL:(NSString *)url {
	if(cachedReleases == nil) {
		NSFetchRequest *fetchRequest = [[[NSFetchRequest alloc] init] autorelease];
		[fetchRequest setEntity:self.releaseEntityDescription];
		NSArray *releases = [self.insertionContext executeFetchRequest:fetchRequest error:nil];
		cachedReleases = [NSMutableDictionary dictionaryWithCapacity:[releases count]];
		for(Release *r in releases) {
			[cachedReleases setObject:r forKey:r.url];
		}
	}
	return [cachedReleases valueForKey:url];
}

- (Release *)findOrCreateReleaseWithURL:(NSString *)url {
	Release *release = [self findReleaseWithURL:url];
	if(release) {
		return release;
	} else {
		release = [NSEntityDescription insertNewObjectForEntityForName:@"Release" inManagedObjectContext:self.insertionContext];
		[cachedReleases setObject:release forKey:url];
		return release;
	}
}

- (Artist *)findArtistWithName:(NSString *)name {
	if(cachedArtists == nil) {
		NSFetchRequest *fetchRequest = [[[NSFetchRequest alloc] init] autorelease];
		[fetchRequest setEntity:self.artistEntityDescription];
		NSArray *artists = [self.insertionContext executeFetchRequest:fetchRequest error:nil];
		cachedArtists = [NSMutableDictionary dictionaryWithCapacity:[artists count]];
		for(Artist *a in artists) {
			[cachedArtists setObject:a forKey:a.name];
		}
	}
	return [cachedArtists valueForKey:name];
}

- (Artist *)findOrCreateArtistWithName:(NSString *)artistName {
	Artist *artist = [self findArtistWithName:artistName];
	if(artist) {
		return artist;
	} else {
		artist = [NSEntityDescription insertNewObjectForEntityForName:@"Artist" inManagedObjectContext:self.insertionContext];
		[cachedArtists setObject:artist forKey:artistName];
		return artist;
	}
}

- (Artist *)addArtist:(NSDictionary *)artistJSON {
	
	Artist *artist = [self findOrCreateArtistWithName:(NSString *)[artistJSON valueForKey:@"name"]];
	
	artist.name = (NSString *)[artistJSON valueForKey:@"name"];
	if((NSNull *)[artistJSON valueForKey:@"sort_name"] == [NSNull null]) {
		artist.sortName = artist.name;
	} else {
		artist.sortName = (NSString *)[artistJSON valueForKey:@"sort_name"];
	}
	artist.sectionName = [artist.sortName substringToIndex:1];
	if([artistJSON valueForKey:@"artist_type"] != [NSNull null]) {
		artist.artistType = (NSString *)[artistJSON valueForKey:@"artist_type"];
	} else {
		artist.artistType = nil;
	}
	if([artistJSON valueForKey:@"begin_date"] != [NSNull null]) {
		artist.beginDate = (NSString *)[artistJSON valueForKey:@"begin_date"];
	} else {
		artist.beginDate = nil;
	}
	if([artistJSON valueForKey:@"end_date"] != [NSNull null]) {
		artist.endDate = (NSString *)[artistJSON valueForKey:@"end_date"];
	} else {
		artist.endDate = nil;
	}
	if([artistJSON valueForKey:@"website"] != [NSNull null]) {
		artist.website = (NSString *)[artistJSON valueForKey:@"website"];
	} else {
		artist.website = nil;
	}
	if([artistJSON valueForKey:@"small_artwork_url"] != [NSNull null]) {
		artist.smallArtworkUrl = (NSString *)[artistJSON valueForKey:@"small_artwork_url"];
	} else {
		artist.smallArtworkUrl = nil;
	}
	if([artistJSON valueForKey:@"large_artwork_url"] != [NSNull null]) {
		artist.largeArtworkUrl = (NSString *)[artistJSON valueForKey:@"large_artwork_url"];
	} else {
		artist.largeArtworkUrl = nil;
	}
	if([artistJSON valueForKey:@"biography_url"] != [NSNull null]) {
		artist.biographyUrl = (NSString *)[artistJSON valueForKey:@"biography_url"];
	} else {
		artist.biographyUrl = nil;
	}
	artist.archived = (NSNumber *)[artistJSON valueForKey:@"archived"];
	
	return artist;
}

- (Track *)findTrackWithURL:(NSString *)url {
	if(cachedTracks == nil) {
		NSFetchRequest *fetchRequest = [[[NSFetchRequest alloc] init] autorelease];
		[fetchRequest setEntity:self.trackEntityDescription];
		NSArray *tracks = [self.insertionContext executeFetchRequest:fetchRequest error:nil];
		cachedTracks = [NSMutableDictionary dictionaryWithCapacity:[tracks count]];
		for(Track *t in tracks) {
			[cachedTracks setObject:t forKey:t.url];
		}
	}
	return [cachedTracks valueForKey:url];
}

- (Track *)findOrCreateTrackWithURL:(NSString *)url {
	Track *track = [self findTrackWithURL:url];
	if(track) {
		return track;
	} else {
		track = [NSEntityDescription insertNewObjectForEntityForName:@"Track" inManagedObjectContext:self.insertionContext];
		[cachedTracks setObject:track forKey:url];
		return track;
	}
}

- (Track *)addTrack:(NSDictionary*)trackJSON {
	
	Track *track = [self findOrCreateTrackWithURL:(NSString*)[trackJSON valueForKey:@"url"]];
	
	track.title = (NSString *)[trackJSON valueForKey:@"title"];
	track.url = (NSString *)[trackJSON valueForKey:@"url"];
	track.length = (NSNumber *)[trackJSON valueForKey:@"length"];
	track.nowPlayingUrl = (NSString *)[trackJSON valueForKey:@"now_playing_url"];
	track.scrobbleUrl = (NSString *)[trackJSON valueForKey:@"scrobble_url"];
	track.loveUrl = (NSString *)[trackJSON valueForKey:@"love_url"];
	if([trackJSON valueForKey:@"track_nr"] != [NSNull null]) {
		track.trackNr = (NSNumber *)[trackJSON valueForKey:@"track_nr"];
	} else {
		track.trackNr = [NSNumber numberWithInt:0];
	}
	if([trackJSON valueForKey:@"set_nr"] != [NSNull null]) {
		track.setNr = (NSNumber *)[trackJSON valueForKey:@"set_nr"];
	} else {
		track.setNr = [NSNumber numberWithInt:1];
	}
	if([trackJSON valueForKey:@"artist"] != [NSNull null]) {
		track.artist = (NSString *)[trackJSON valueForKey:@"artist"];
	} else {
		track.artist = nil;
	}
	if([trackJSON valueForKey:@"loved_at"] != [NSNull null]) {
		track.lovedAt = [ObjectiveResourceDateFormatter parseDateTime:(NSString*)[trackJSON valueForKey:@"loved_at"]];
	} else {
		track.lovedAt = nil;
	}
	
	[track touch];
	
	return track;
}

- (Release *)addRelease:(NSDictionary*)releaseJSON {
	
	Release *release = [self findOrCreateReleaseWithURL:(NSString*)[releaseJSON valueForKey:@"url"]];

	release.parent = [self addArtist:(NSDictionary *)[releaseJSON valueForKey:@"artist"]];
	release.title = (NSString*)[releaseJSON valueForKey:@"title"];
	release.artist = release.parent.name;
	release.url = (NSString*)[releaseJSON valueForKey:@"url"];
	release.createdAt = (NSString*)[releaseJSON valueForKey:@"created_at"];
	release.updatedAt = (NSString*)[releaseJSON valueForKey:@"updated_at"];
	release.archived = (NSNumber*)[releaseJSON valueForKey:@"archived"];
	
	if([releaseJSON valueForKey:@"year"] != [NSNull null]) {
		release.year = (NSDecimalNumber*)[releaseJSON valueForKey:@"year"];
	} else {
		release.year = nil;
	}
	
	if([releaseJSON valueForKey:@"label"] != [NSNull null]) {
		NSDictionary *label = (NSDictionary *)[releaseJSON valueForKey:@"label"];
		release.label = (NSString *)[label valueForKey:@"name"];
	} else {
		release.label = nil;
	}
	
	if([releaseJSON valueForKey:@"release_date"] != [NSNull null]) {
		release.releaseDate = (NSString *)[releaseJSON valueForKey:@"release_date"];
	} else {
		release.releaseDate = nil;
	}
	
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 40000
	if([[UIScreen mainScreen] respondsToSelector:@selector(scale)] == NO || [[UIScreen mainScreen] scale] <= 1.0) {
#endif
		if([releaseJSON valueForKey:@"small_artwork_url"] != [NSNull null]) {
			release.smallArtworkUrl = (NSString*)[releaseJSON valueForKey:@"small_artwork_url"];
		} else {
			release.smallArtworkUrl = nil;
		}
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 40000
	} else {
		if([releaseJSON valueForKey:@"medium_artwork_url"] != [NSNull null]) {
			release.smallArtworkUrl = (NSString*)[releaseJSON valueForKey:@"medium_artwork_url"];
		} else {
			release.smallArtworkUrl = nil;
		}
	}
#endif
	
	if([releaseJSON valueForKey:@"large_artwork_url"] != [NSNull null]) {
		release.largeArtworkUrl = (NSString*)[releaseJSON valueForKey:@"large_artwork_url"];
	} else {
		release.largeArtworkUrl = nil;
	}
	
	NSArray *tracks = (NSArray *)[releaseJSON valueForKey:@"tracks"];
	if(tracks) {
		for(NSObject *t in tracks) {
			Track *track = [self addTrack:(NSDictionary *)t];
			track.parent = release;
		}
	}
	
	for(Track *track in release.tracks) {
		if([track wasTouched] == NO) {
			[self.insertionContext deleteObject:track];
		}
	}
	
	return release;
}

//- (NSString *)lastUpdateDate {
//	NSFetchRequest *fetchRequest = [[[NSFetchRequest alloc] init] autorelease];
//	[fetchRequest setEntity:self.releaseEntityDescription];
//	[fetchRequest setFetchLimit:1];
//	NSSortDescriptor *sortDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"updatedAt" ascending:NO selector:@selector(compare:)] autorelease];
//	NSArray *sortDescriptors = [[[NSArray alloc] initWithObjects:sortDescriptor, nil] autorelease];
//	[fetchRequest setSortDescriptors:sortDescriptors];
//	NSArray *result = [self.insertionContext executeFetchRequest:fetchRequest error:nil];
//	if([result count] > 0) {
//		Release *release = [result objectAtIndex:0];
//		return [release.updatedAt copy];
//	} else {
//		return @"";
//	}
//}

- (void)main {
	NSLog(@"ReleasesLoader#main");
	
	// Reset fail state
	didFail = NO;
	
	// Create a new autorelease pool for this thread
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	// Tell the delegate object to observe changes in the managed object context
	if (delegate && [delegate respondsToSelector:@selector(loaderDidSave:)]) {
        [[NSNotificationCenter defaultCenter] addObserver:delegate 
												 selector:@selector(loaderDidSave:) 
													 name:NSManagedObjectContextDidSaveNotification 
												   object:self.insertionContext];
    }
	
	// Tell the delegate that we have started loading
	[delegate loaderDidStart:self];
	
	int page = 1;
	[ObjectiveResourceDateFormatter setSerializeFormat:DateTime];
	NSString *since = self.lastUpdateDate ? [ObjectiveResourceDateFormatter formatDate:self.lastUpdateDate] : @"";
	
	do {
		// Request a page from the server...
		NSLog(@"Requesting page #%d", page);
		AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
		NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@releases?simple=no&page=%d&since=%@", appDelegate.siteURL, page, since]];
		NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:url
																cachePolicy:NSURLRequestReloadIgnoringCacheData
															timeoutInterval:[Connection timeout]];
		[request setHTTPMethod:@"GET"];
		[request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
		[request addValue:@"application/json" forHTTPHeaderField:@"Accept"];
		Response *res = [Connection sendRequest:request withUser:appDelegate.username andPassword:appDelegate.password];
		if([res isError]) {
			NSLog(@"%@", [res.error localizedDescription]);
			didFail = YES;
			[delegate loader:self didFailWithError:res.error];
			break;
		}
		
		// Parse the returned response
		NSString *responseString = [[NSString alloc] initWithData:res.body encoding:NSUTF8StringEncoding];
		NSDictionary *responseJSON = [responseString JSONValue];
		NSNumber *totalPages = (NSNumber *)[responseJSON valueForKey:@"pages"];
		NSArray *releases = (NSArray *)[responseJSON valueForKey:@"releases"];
		if ([releases count] == 0) {
			break;
		} else {
			for(NSObject *release in releases) {
				[self addRelease:(NSDictionary *)release];
				[delegate loaderDidFinishParsingRelease:self];
			}
			NSError *error = nil;
			[self.insertionContext save:&error];
			if(error) {
				NSLog(@"%@", [error userInfo]);
				didFail = YES;
				[delegate loader:self didFailWithError:error];
				break;
			}
			[delegate loader:self didFinishLoadingPage:page of:[totalPages intValue]];
			if([self isCancelled] == YES)
				break;
		}
		[responseString release];
		
		page++;
	} while(true);
	
	// Remove empty releases and artists
	for(Release *r in [cachedReleases allValues]) {
		if([r.tracks count] == 0) {
			[self.insertionContext deleteObject:r];
		}
	}
	for(Artist *a in [cachedArtists allValues]) {
		if([a.releases count] == 0) {
			[self.insertionContext deleteObject:a];
		}
	}
	[self.insertionContext save:nil];
	
	// Tell the delegate that we have finished loading
	[delegate loaderDidFinish:self];
	
	// Tell the delegate to not listen for changes in the managed object context any more
	if (delegate && [delegate respondsToSelector:@selector(loaderDidSave:)]) {
        [[NSNotificationCenter defaultCenter] removeObserver:delegate 
														name:NSManagedObjectContextDidSaveNotification 
													  object:self.insertionContext];
    }
	
	// Release the autorelease pool
	[pool release];
}

- (NSManagedObjectContext *)insertionContext {
    if (insertionContext == nil) {
        insertionContext = [[NSManagedObjectContext alloc] init];
        [insertionContext setPersistentStoreCoordinator:self.persistentStoreCoordinator];
    }
    return insertionContext;
}

- (NSEntityDescription *)artistEntityDescription {
    if (artistEntityDescription == nil) {
        artistEntityDescription = [[NSEntityDescription entityForName:@"Artist" inManagedObjectContext:self.insertionContext] retain];
    }
    return artistEntityDescription;
}

- (NSEntityDescription *)releaseEntityDescription {
    if (releaseEntityDescription == nil) {
        releaseEntityDescription = [[NSEntityDescription entityForName:@"Release" inManagedObjectContext:self.insertionContext] retain];
    }
    return releaseEntityDescription;
}

- (NSEntityDescription *)trackEntityDescription {
    if (trackEntityDescription == nil) {
        trackEntityDescription = [[NSEntityDescription entityForName:@"Track" inManagedObjectContext:self.insertionContext] retain];
    }
    return trackEntityDescription;
}

@end
