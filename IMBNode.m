/*
 iMedia Browser Framework <http://karelia.com/imedia/>
 
 Copyright (c) 2005-2012 by Karelia Software et al.
 
 iMedia Browser is based on code originally developed by Jason Terhorst,
 further developed for Sandvox by Greg Hulands, Dan Wood, and Terrence Talbot.
 The new architecture for version 2.0 was developed by Peter Baumgartner.
 Contributions have also been made by Matt Gough, Martin Wennerberg and others
 as indicated in source files.
 
 The iMedia Browser Framework is licensed under the following terms:
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in all or substantial portions of the Software without restriction, including
 without limitation the rights to use, copy, modify, merge, publish,
 distribute, sublicense, and/or sell copies of the Software, and to permit
 persons to whom the Software is furnished to do so, subject to the following
 conditions:
 
	Redistributions of source code must retain the original terms stated here,
	including this list of conditions, the disclaimer noted below, and the
	following copyright notice: Copyright (c) 2005-2012 by Karelia Software et al.
 
	Redistributions in binary form must include, in an end-user-visible manner,
	e.g., About window, Acknowledgments window, or similar, either a) the original
	terms stated here, including this list of conditions, the disclaimer noted
	below, and the aforementioned copyright notice, or b) the aforementioned
	copyright notice and a link to karelia.com/imedia.
 
	Neither the name of Karelia Software, nor Sandvox, nor the names of
	contributors to iMedia Browser may be used to endorse or promote products
	derived from the Software without prior and express written permission from
	Karelia Software or individual contributors, as appropriate.
 
 Disclaimer: THE SOFTWARE IS PROVIDED BY THE COPYRIGHT OWNER AND CONTRIBUTORS
 "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT
 LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE,
 AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
 LIABLE FOR ANY CLAIM, DAMAGES, OR OTHER LIABILITY, WHETHER IN AN ACTION OF
 CONTRACT, TORT, OR OTHERWISE, ARISING FROM, OUT OF, OR IN CONNECTION WITH, THE
 SOFTWARE OR THE USE OF, OR OTHER DEALINGS IN, THE SOFTWARE.
*/


// Author: Peter Baumgartner, Mike Abdullah


//----------------------------------------------------------------------------------------------------------------------


#pragma mark HEADERS

#import "IMBNode.h"
//#import "IMBObject.h"
//#import "IMBParser.h"
#import "IMBLibraryController.h"
#import "NSString+iMedia.h"


//----------------------------------------------------------------------------------------------------------------------


#pragma mark

@interface IMBNode ()
@property (assign, readwrite) IMBNode* parentNode;
- (void) _recursivelyWalkParentsAddingPathIndexTo:(NSMutableArray*)inIndexArray;
@end


//----------------------------------------------------------------------------------------------------------------------


#pragma mark

@implementation IMBNode

// Primary properties...

@synthesize icon = _icon;
@synthesize name = _name;
@synthesize identifier = _identifier;
@synthesize mediaType = _mediaType;
@synthesize mediaSource = _mediaSource;
@synthesize parserIdentifier = _parserIdentifier;

@synthesize parentNode = _parentNode;
@synthesize subnodes = _subnodes;
@synthesize objects = _objects;

// State information...

@synthesize attributes = _attributes;
@synthesize groupType = _groupType;
@synthesize displayPriority = _displayPriority;
@synthesize displayedObjectCount = _displayedObjectCount;
@synthesize isTopLevelNode = _isTopLevelNode;
@synthesize group = _group;
@synthesize leaf = _leaf;
@synthesize includedInPopup = _includedInPopup;
@synthesize isUserAdded = _isUserAdded;
@synthesize wantsRecursiveObjects = _wantsRecursiveObjects;

// Support for live watching...

//@synthesize parser = _parser;
//@synthesize watcherType = _watcherType;
//@synthesize watchedPath = _watchedPath;

// Badge icons...

@synthesize badgeTypeNormal = _badgeTypeNormal;
@synthesize badgeTypeMouseover = _badgeTypeMouseover;
@synthesize badgeTarget = _badgeTarget;
@synthesize badgeSelector = _badgeSelector;

// Custom object views...

@synthesize shouldDisplayObjectView = _shouldDisplayObjectView;
@synthesize customHeaderViewController = _customHeaderViewController;
@synthesize customObjectViewController = _customObjectViewController;
@synthesize customFooterViewController = _customFooterViewController;


//----------------------------------------------------------------------------------------------------------------------

- (id) init
{
	if (self = [super init])
	{
		self.groupType = kIMBGroupTypeNone;
		self.displayPriority = 5;					// middle of the pack, default
		self.displayedObjectCount = -1;

		self.subnodes = nil;
		self.objects = nil;

		self.isTopLevelNode = NO;
		self.group = NO;
		self.leaf = NO;
		self.loading = NO;
		self.wantsRecursiveObjects = NO;
		self.includedInPopup = YES;
		self.isUserAdded = NO;
		
//		self.watcherType = kIMBWatcherTypeNone;
		self.badgeTypeNormal = kIMBBadgeTypeNone;
		self.badgeTypeMouseover = kIMBBadgeTypeNone;
		
		self.shouldDisplayObjectView = YES;
		self.customHeaderViewController = nil;
		self.customObjectViewController = nil;
		self.customFooterViewController = nil;
	}
	
	return self;
}


- (void) dealloc
{
    [self setSubnodes:nil];		// Sub-nodes have a weak reference to self, so break that
	
	IMBRelease(_icon);
	IMBRelease(_name);
	IMBRelease(_identifier);
	IMBRelease(_mediaType);
	IMBRelease(_mediaSource);
	IMBRelease(_parserIdentifier);
	IMBRelease(_subnodes);
	IMBRelease(_objects);
	IMBRelease(_attributes);
//	IMBRelease(_parser);
//	IMBRelease(_watchedPath);
	IMBRelease(_badgeTarget);
	
	[super dealloc];
}


//----------------------------------------------------------------------------------------------------------------------


- (id) copyWithZone:(NSZone*)inZone
{
	IMBNode* copy = [[[self class] allocWithZone:inZone] init];

	copy.icon = self.icon;
	copy.name = self.name;
	copy.identifier = self.identifier;
	copy.mediaType = self.mediaType;
	copy.mediaSource = self.mediaSource;
	copy.parserIdentifier = self.parserIdentifier;

//	copy.parentNode = self.parentNode;			// Removed to avoid potentially dangling pointers (parentNode in not retained!)

	copy.attributes = self.attributes;
	copy.groupType = self.groupType;
	copy.displayPriority = self.displayPriority;
	copy.displayedObjectCount = self.displayedObjectCount;
	
	copy.isTopLevelNode = self.isTopLevelNode;
	copy.group = self.group;
	copy.leaf = self.leaf;
	copy.loading = self.loading;
	copy.includedInPopup = self.includedInPopup;
	copy.wantsRecursiveObjects = self.wantsRecursiveObjects;
	
//	copy.parser = self.parser;
//	copy.watcherType = self.watcherType;
//	copy.watchedPath = self.watchedPath;

	copy.badgeTypeNormal = self.badgeTypeNormal;
	copy.badgeTypeMouseover = self.badgeTypeMouseover;
	copy.badgeTarget = self.badgeTarget;
	copy.badgeSelector = self.badgeSelector;
	
	copy.shouldDisplayObjectView = self.shouldDisplayObjectView;
	copy.customHeaderViewController = self.customHeaderViewController;
	copy.customObjectViewController = self.customObjectViewController;
	copy.customFooterViewController = self.customFooterViewController;
	
	// Create a shallow copy of objects array...
	
	if (self.objects)
    {
        copy.objects = [NSMutableArray arrayWithArray:self.objects];
    }
	else
    {
        copy.objects = nil;
    }
	
	// Create a deep copy of the subnodes. This is essential to make background operations completely threadsafe...
	
	if (self.subnodes)
	{
		NSMutableArray* subnodes = [NSMutableArray arrayWithCapacity:self.subnodes.count];

		for (IMBNode* subnode in self.subnodes)
		{
			IMBNode* copiedSubnode = [subnode copy];
			[subnodes addObject:copiedSubnode];
			[copiedSubnode release];
		}
		
		copy.subnodes = subnodes;
	}
	else 
	{
		copy.subnodes = nil;
	}

	return copy;
}


//----------------------------------------------------------------------------------------------------------------------


- (id) initWithCoder:(NSCoder*)inCoder
{
	if ((self = [super init]))
	{
		self.icon = [inCoder decodeObjectForKey:@"icon"];
		self.name = [inCoder decodeObjectForKey:@"name"];
		self.identifier = [inCoder decodeObjectForKey:@"identifier"];
		self.mediaType = [inCoder decodeObjectForKey:@"mediaType"];
		self.mediaSource = [inCoder decodeObjectForKey:@"mediaSource"];
		self.parserIdentifier = [inCoder decodeObjectForKey:@"parserIdentifier"];

		self.attributes = [inCoder decodeObjectForKey:@"attributes"];
		self.groupType = [inCoder decodeIntegerForKey:@"groupType"];
		self.displayPriority = [inCoder decodeIntegerForKey:@"displayPriority"];
		self.displayedObjectCount = [inCoder decodeIntegerForKey:@"displayedObjectCount"];
		self.isTopLevelNode = [inCoder decodeBoolForKey:@"isTopLevelNode"];
		self.group = [inCoder decodeBoolForKey:@"group"];
		self.leaf = [inCoder decodeBoolForKey:@"leaf"];
		self.loading = [inCoder decodeBoolForKey:@"loading"];
		self.includedInPopup = [inCoder decodeBoolForKey:@"includedInPopup"];
		self.isUserAdded = [inCoder decodeBoolForKey:@"isUserAdded"];
		self.wantsRecursiveObjects = [inCoder decodeBoolForKey:@"wantsRecursiveObjects"];

		self.shouldDisplayObjectView = [inCoder decodeBoolForKey:@"shouldDisplayObjectView"];
		self.customHeaderViewController = [inCoder decodeObjectForKey:@"customHeaderViewController"];
		self.customObjectViewController = [inCoder decodeObjectForKey:@"customObjectViewController"];
		self.customFooterViewController = [inCoder decodeObjectForKey:@"customFooterViewController"];

		#warning TODO subnodes and objects
	}
	
	return self;
}


- (void) encodeWithCoder:(NSCoder*)inCoder
{
	[inCoder encodeObject:self.icon forKey:@"icon"];
	[inCoder encodeObject:self.name forKey:@"name"];
	[inCoder encodeObject:self.identifier forKey:@"identifier"];
	[inCoder encodeObject:self.mediaType forKey:@"mediaType"];
	[inCoder encodeObject:self.mediaSource forKey:@"mediaSource"];
	[inCoder encodeObject:self.parserIdentifier forKey:@"parserIdentifier"];
	
	[inCoder encodeObject:self.attributes forKey:@"attributes"];
	[inCoder encodeInteger:self.groupType forKey:@"groupType"];
	[inCoder encodeInteger:self.displayPriority forKey:@"displayPriority"];
	[inCoder encodeInteger:self.displayedObjectCount forKey:@"displayedObjectCount"];
	[inCoder encodeBool:self.isTopLevelNode forKey:@"isTopLevelNode"];
	[inCoder encodeBool:self.isGroup forKey:@"group"];
	[inCoder encodeBool:self.isLeaf forKey:@"leaf"];
	[inCoder encodeBool:self.isLoading forKey:@"loading"];
	[inCoder encodeBool:self.includedInPopup forKey:@"includedInPopup"];
	[inCoder encodeBool:self.isUserAdded forKey:@"isUserAdded"];
	[inCoder encodeBool:self.wantsRecursiveObjects forKey:@"wantsRecursiveObjects"];

	[inCoder encodeBool:self.shouldDisplayObjectView forKey:@"shouldDisplayObjectView"];
	[inCoder encodeObject:self.customHeaderViewController forKey:@"customHeaderViewController"];
	[inCoder encodeObject:self.customObjectViewController forKey:@"customObjectViewController"];
	[inCoder encodeObject:self.customFooterViewController forKey:@"customFooterViewController"];
	
	#warning TODO subnodes and objects
}


//----------------------------------------------------------------------------------------------------------------------


#pragma mark
#pragma mark Accessors

// Accessors for navigating up or down the node tree...

- (void) setSubnodes:(NSArray*)inNodes
{
    [_subnodes makeObjectsPerformSelector:@selector(setParentNode:) withObject:nil];
    
	NSArray* nodes = [inNodes copy];
    [_subnodes release]; 
	_subnodes = nodes;
    
    [_subnodes makeObjectsPerformSelector:@selector(setParentNode:) withObject:self];
}


- (IMBNode*) topLevelNode
{
	if (_parentNode)
	{
		if (!_parentNode.isTopLevelNode)
		{
			return [_parentNode topLevelNode];
		}
	}
		
	return self;
}


// Node accessors. Use these for bindings the NSTreeController...

- (NSUInteger) countOfSubnodes
{
	return [_subnodes count];
}


- (IMBNode*) objectInSubnodesAtIndex:(NSUInteger)inIndex
{
	return [_subnodes objectAtIndex:inIndex];
}


//----------------------------------------------------------------------------------------------------------------------


// Shallow object accessors. Use these for binding the NSArrayController. This only returns the objects that are
// contained directly by this node, but not those contained by any subnodes...

- (NSUInteger) countOfShallowObjects
{
	if (_objects)
	{
		return [_objects count];
	}
	
	return 0;	
}


- (IMBObject*) objectInShallowObjectsAtIndex:(NSUInteger)inIndex
{
	if (_objects)
	{
		return [_objects objectAtIndex:inIndex];
	}
	
	return nil;	
}


//----------------------------------------------------------------------------------------------------------------------


// Recursive object accessors. Please note that these accessors use a depth-first algorithm, hoping that most media 
// libraries like iPhoto, iTunes, Aperture, etc do the same thing.

// The expensive filtering of duplicate objects that was done in iMedia 1.x has been eliminated as it has caused 
// substantial performance problems. It is now the responsibility of the parser classes to ensure that parent nodes
// do not contain any objects that are already contained in subnodes...

- (NSUInteger) countOfRecursiveObjects
{
	NSUInteger count = self.countOfShallowObjects;
	
	for (IMBNode* node in _subnodes)
	{
		count += node.countOfRecursiveObjects;
	}
	
	return count;
}


- (IMBObject*) objectInRecursiveObjectsAtIndex:(NSUInteger)inIndex
{
	// If the index is smaller that number of objects at this node level, then the object must be right  
	// here in this node...
	
	NSUInteger count = self.countOfShallowObjects;
	
	if (inIndex < count)
	{
		return [self objectInShallowObjectsAtIndex:inIndex];
	}
	
	// If the index is larger, then it must be in one of the subnodes...
	
	NSUInteger index = inIndex - count;
	
	for (IMBNode* node in _subnodes)
	{
		IMBObject* object = [node objectInRecursiveObjectsAtIndex:index];
		if (object) return object;
		else index -= node.countOfRecursiveObjects;
	}
	
	// Couldn't find a object with this index (index to large). Return nil...
	
	return nil;
}


//----------------------------------------------------------------------------------------------------------------------


// The bindableObjects property is used to bind the contentArray of IMBObjectArrayController. In this property 
// the node can select whether it wants to display shallow or deep (recursive) objects...

- (NSUInteger) countOfBindableObjects
{
	if (self.wantsRecursiveObjects)
	{
		return self.countOfRecursiveObjects;
	}
	else
	{
		return self.countOfShallowObjects;
	}
}


- (IMBObject*) objectInBindableObjectsAtIndex:(NSUInteger)inIndex
{
	if (self.wantsRecursiveObjects)
	{
		return [self objectInRecursiveObjectsAtIndex:inIndex];
	}
	else
	{
		return [self objectInShallowObjectsAtIndex:inIndex];
	}
}


//----------------------------------------------------------------------------------------------------------------------


#pragma mark
#pragma mark Helpers


// Nodes are considered to be equal if their identifiers match - even if we are looking at different instances
// This is necessary as nodes are relatively short-lived objects that are replaced with new instances often - 
// a necessity in our multithreaded environment...

- (BOOL) isEqual:(id)inNode
{
    if (self == inNode)
    {
        return YES; // fast path
    }
    else if ([inNode isKindOfClass:[IMBNode class]]) // ImageKit sometimes compares us to strings
    {
        return [[self identifier] isEqualToString:[inNode identifier]];
    }
    
    return NO;
}

- (NSUInteger) hash;
{
    return [[self identifier] hash];
}


// Nodes are grouped by type, but within a group nodes are sorted first by priority (1=top, 9=last),
// then alphabetically.  (The default value is 5.  The idea is to be able to push things UP or DOWN.)
// Nodes without a group type are at the end of the list...

- (NSComparisonResult) compare:(IMBNode*)inNode
{
	NSUInteger selfGroupType = self.groupType;
	NSUInteger selfDisplayPriority = self.displayPriority;
	NSUInteger otherGroupType = inNode.groupType;
	NSUInteger otherDisplayPriority = inNode.displayPriority;

	if (selfGroupType > otherGroupType)
	{
		return NSOrderedDescending;
	}
	else if (selfGroupType < otherGroupType)
	{
		return NSOrderedAscending;
	}
	
	if (selfDisplayPriority > otherDisplayPriority)
	{
		return NSOrderedDescending;
	}
	else if (selfDisplayPriority < otherDisplayPriority)
	{
		return NSOrderedAscending;
	}
		
	return [self.name imb_finderCompare:inNode.name];
}


//----------------------------------------------------------------------------------------------------------------------


// Set loading status for self and complete subtree...

- (void) setLoading:(BOOL)inLoading
{
	_loading = inLoading;
	
	for (IMBNode* subnode in self.subnodes)
	{
		subnode.loading = inLoading;
	}
}


// Check if this node or one of its ancestors is current loading in the background. In this case it will be 
// replaced shortly and is not considered to be eligible for a new background operation...

- (BOOL) isLoading
{
	if (_loading) return YES;
	if (_parentNode) return [_parentNode isLoading];
	return NO;
}


//----------------------------------------------------------------------------------------------------------------------


// Returns the path to this node as a NSIndexSet. Useful for working with NSTreeController and NSOutlineView...

- (NSIndexPath*) indexPath
{
	// First build the path as a array of numbers...
	
	NSMutableArray* indexArray = [NSMutableArray array];
	[self _recursivelyWalkParentsAddingPathIndexTo:indexArray];
	NSUInteger n = [indexArray count];
	
	// Then convert the NSArray into a NSIndexPath...
	
	if (n > 0)
	{
		NSUInteger* indexes = (NSUInteger*) malloc(n*sizeof(NSUInteger));
		
		for (NSUInteger i=0; i<n; i++)
		{
			indexes[i] = [[indexArray objectAtIndex:i] unsignedIntegerValue];
		}
		
		NSIndexPath* path = [NSIndexPath indexPathWithIndexes:indexes length:n];
		free(indexes);
		
		return path;
	}
	
	return nil;
}


// This helper method creates an array of numbers containing the indexes to this node...

- (void) _recursivelyWalkParentsAddingPathIndexTo:(NSMutableArray*)inIndexArray
{
	// If we have a parent then get the our index in the parents subnodes...
	
	if (_parentNode)
	{
		[_parentNode _recursivelyWalkParentsAddingPathIndexTo:inIndexArray];
		NSUInteger index = 0;
		
		for (IMBNode* siblingNode in _parentNode.subnodes)
		{
			if ([siblingNode.identifier isEqualToString:self.identifier])
			{
				[inIndexArray addObject:[NSNumber numberWithUnsignedInteger:index]];
				return;
			}
			
			index++;
		}
	}
	
	// If we are at the root the get the node index in the controllers nodes array...
	
	else
	{
		#warning TODO
		
//		IMBLibraryController* libraryController = [IMBLibraryController sharedLibraryControllerWithMediaType:self.mediaType];
//		NSUInteger index = 0;
//		
//		for (IMBNode* node in libraryController.subnodes)
//		{
//			if ([node.identifier isEqualToString:self.identifier])
//			{
//				[inIndexArray addObject:[NSNumber numberWithUnsignedInteger:index]];
//				return;
//			}
//			
//			index++;
//		}
	}
	
	// Oops, we shouldn't be here...
	
	NSLog(@"Unable to find '%@' in the source list", self.name);
	[inIndexArray addObject:[NSNumber numberWithUnsignedInteger:NSNotFound]];
}


//----------------------------------------------------------------------------------------------------------------------


// A node is pouplated if the subnodes and objects arrays are present. Please note that these arrays may still
// be empty (this is also consider to be pouplated)...

- (BOOL) isPopulated
{
	return self.subnodes != nil && self.objects !=nil;
}


// Look in our node tree for a node with the specified identifier...

- (IMBNode*) subnodeWithIdentifier:(NSString*)inIdentifier
{
	if ([self.identifier isEqualToString:inIdentifier])
	{
		return self;
	}
	
	for (IMBNode* subnode in self.subnodes)
	{
		IMBNode* found = [subnode subnodeWithIdentifier:inIdentifier];
		if (found) return found;
	}

	return nil;
}


//----------------------------------------------------------------------------------------------------------------------


// Check if self is an ancestor of the specified node. Please note that we are using isEqual: instead of just
// comparing object pointers because nodes are short lived objects that are replaced often in our multithreaded
// environment...

- (BOOL) isAncestorOfNode:(IMBNode*)inNode
{
	IMBNode* node = inNode.parentNode;
	
	while (node)
	{
		if ([self isEqual:node]) return YES;
		node = node.parentNode;
	}
	
	return NO;
}


// Check if self is a descendant of the specified node...

- (BOOL) isDescendantOfNode:(IMBNode*)inNode
{
	for (IMBNode* node in inNode.subnodes)
	{
		if ([self isEqual:node])
		{
			return YES;
		}
		else
		{
			BOOL found = [self isDescendantOfNode:node];
			if (found) return YES;
		}
	}
	
	return NO;
}


//----------------------------------------------------------------------------------------------------------------------


#pragma mark
#pragma mark Debugging

- (NSString*) description
{
	// Basic info...
	
	NSMutableString* description = [NSMutableString stringWithFormat:@"\tIMBNode (%@) \n\t\tidentifier = %@ \n\t\tattributes = %@",
		self.name,
		self.identifier,
		self.attributes];
	
	// Objects...
	
	if ([_objects count] > 0)
	{
		[description appendFormat:@"\n\t\tobjects = %u",[_objects count]];
//		for (IMBObject* object in _objects)
//		{
//			[description appendFormat:@"\n\t\t\t%@",object.name];
//		}
	}
	
	// Subnodes...
	
	if ([_subnodes count] > 0)
	{
		[description appendFormat:@"\n\t\tsubnodes = %u",[_subnodes count]];
		for (IMBNode* subnode in _subnodes)
		{
			[description appendFormat:@"\n\t\t\t%@",subnode.name];
		}
	}
	
	return description;
}


//----------------------------------------------------------------------------------------------------------------------


@end
