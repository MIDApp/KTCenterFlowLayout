//
//  KTCenterFlowLayout.m
//
//  Created by Kyle Truscott on 10/9/14.
//  Copyright (c) 2014 keighl. All rights reserved.
//

#import "KTCenterFlowLayout.h"


@interface KTRow : NSObject

@property CGFloat minY, maxY;

@property NSUInteger section;

@property (strong, readonly, nonatomic) NSMutableArray *itemsLayoutAttributes;

+ (instancetype)rowWithLayoutAttributes:(UICollectionViewLayoutAttributes *)attributes;
- (void)addLayoutAttributes:(UICollectionViewLayoutAttributes *)attributes;

- (BOOL)couldContainLayoutAttributes:(UICollectionViewLayoutAttributes *)attributes;

@end

@interface KTCenterFlowLayout ()

@property (nonatomic) NSMutableDictionary <NSIndexPath *, UICollectionViewLayoutAttributes *> *attrCache;

@end

@implementation KTCenterFlowLayout

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _rowVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    }
    return self;
}


- (void)prepareLayout
{
    // Clear the attrCache
    self.attrCache = [NSMutableDictionary new];
    
    [super prepareLayout];
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return self.attrCache[indexPath] ?: [super layoutAttributesForItemAtIndexPath:indexPath];
}

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect
{
    if (rect.size.width < CGRectGetWidth(self.collectionView.bounds))
        rect.size.width = CGRectGetWidth(self.collectionView.bounds);
    
    NSArray *attributes = [super layoutAttributesForElementsInRect:rect];
    
    for (UICollectionViewLayoutAttributes *itemAttribute in attributes)
    {
        if (itemAttribute.representedElementCategory != UICollectionElementCategoryCell)
            continue;
        
        if (CGRectGetMinY(rect) > CGRectGetMinY(itemAttribute.frame) || CGRectGetMaxY(rect) < CGRectGetMaxY(itemAttribute.frame))
        {
            rect = CGRectUnion(rect, itemAttribute.frame);
        }
    }
    
    attributes = [super layoutAttributesForElementsInRect:rect];
    
    NSMutableArray <KTRow *> *groupByRows = [NSMutableArray new];
    
    NSMutableArray *modifiedAttributes = [NSMutableArray arrayWithCapacity:attributes.count];
    for (UICollectionViewLayoutAttributes *itemAttribute in attributes)
    {
        if (itemAttribute.representedElementCategory != UICollectionElementCategoryCell)
        {
            [modifiedAttributes addObject:itemAttribute];
            continue;
        }
        
        NSIndexPath *indexPath = itemAttribute.indexPath;
        if (self.attrCache[indexPath])
        {
            [modifiedAttributes addObject:self.attrCache[indexPath]];
            continue;
        }
        
        
        UICollectionViewLayoutAttributes *newItemAttributes = [itemAttribute copy];
        
        // Find the other items in the same "row"
        BOOL rowFound = NO;
        for (KTRow *row in groupByRows)
        {
            if ([row couldContainLayoutAttributes:newItemAttributes])
            {
                [row addLayoutAttributes:newItemAttributes];
                rowFound = YES;
                break;
            }
        }
        
        if (!rowFound)
            [groupByRows addObject:[KTRow rowWithLayoutAttributes:newItemAttributes]];
        
        
        [modifiedAttributes addObject:newItemAttributes];
    }
    
    
    // Calculate the available width to center stuff within
    // sectionInset is NOT applicable here because a) we're centering stuff
    // and b) Flow layout has arranged the cells to respect the inset. We're
    // just hijacking the X position.
    CGFloat collectionViewWidth = CGRectGetWidth(self.collectionView.bounds) -
    self.collectionView.contentInset.left -
    self.collectionView.contentInset.right;
    
    id <UICollectionViewDelegateFlowLayout> flowDelegate = (id<UICollectionViewDelegateFlowLayout>) [[self collectionView] delegate];
    BOOL delegateSupportsInteritemSpacing = [flowDelegate respondsToSelector:@selector(collectionView:layout:minimumInteritemSpacingForSectionAtIndex:)];
    
    // x-x-x-x ... sum up the interim space
    CGFloat interitemSpacing;
    NSArray *rowBuddies;
    
    for (KTRow *row in groupByRows)
    {
        [row.itemsLayoutAttributes sortUsingComparator:^NSComparisonResult(UICollectionViewLayoutAttributes * _Nonnull obj1,
                                                                           UICollectionViewLayoutAttributes *  _Nonnull obj2)
        {
            if (obj1.center.x == obj2.center.x)
                return NSOrderedSame;
            
            if (obj1.center.x < obj2.center.x)
                return NSOrderedAscending;
            
            return NSOrderedDescending;
        }];
        rowBuddies = row.itemsLayoutAttributes;
        
        // Check for minimumInteritemSpacingForSectionAtIndex support
        if (delegateSupportsInteritemSpacing && rowBuddies.count > 0)
        {
            interitemSpacing = [flowDelegate collectionView:self.collectionView
                                                     layout:self
                   minimumInteritemSpacingForSectionAtIndex:row.section];
        }
        else
            interitemSpacing = [self minimumInteritemSpacing];
        
        CGFloat aggregateInteritemSpacing = interitemSpacing * (rowBuddies.count -1);
        
        // Sum the width of all elements in the row
        CGFloat aggregateItemWidths = 0.f;
        for (UICollectionViewLayoutAttributes *itemAttributes in rowBuddies)
            aggregateItemWidths += CGRectGetWidth(itemAttributes.frame);
        
        CGFloat maxHeigth = 0.;
        if (self.rowVerticalAlignment != UIControlContentVerticalAlignmentCenter)
        {
            for (UICollectionViewLayoutAttributes *itemAttributes in rowBuddies)
                maxHeigth = MAX(maxHeigth, CGRectGetHeight(itemAttributes.frame));
        }
        
        // Build an alignment rect
        // |  |x-x-x-x|  |
        CGFloat alignmentWidth = aggregateItemWidths + aggregateInteritemSpacing;
        CGFloat alignmentXOffset = (collectionViewWidth - alignmentWidth) / 2.f;
        
        // Adjust each item's position to be centered
        CGRect previousFrame = CGRectZero;
        for (UICollectionViewLayoutAttributes *itemAttributes in rowBuddies)
        {
            CGRect itemFrame = itemAttributes.frame;
            
            if (CGRectEqualToRect(previousFrame, CGRectZero))
                itemFrame.origin.x = alignmentXOffset;
            else
                itemFrame.origin.x = CGRectGetMaxX(previousFrame) + interitemSpacing;
            
            switch (self.rowVerticalAlignment)
            {
                case UIControlContentVerticalAlignmentFill:
                    itemFrame.origin.y += (itemFrame.size.height - maxHeigth)/2.0;
                    itemFrame.size.height = maxHeigth;
                    break;
                    
                case UIControlContentVerticalAlignmentTop:
                    itemFrame.origin.y += (itemFrame.size.height - maxHeigth)/2.0;
                    break;
                    
                case UIControlContentVerticalAlignmentBottom:
                    itemFrame.origin.y -= (itemFrame.size.height - maxHeigth)/2.0;
                    break;
                    
                case UIControlContentVerticalAlignmentCenter:
                default:
                    break;
            }
            itemAttributes.frame = itemFrame;
            previousFrame = itemFrame;
            
            // Finally, add it to the cache
            self.attrCache[itemAttributes.indexPath] = itemAttributes;
        }
    }
    
    
    return [modifiedAttributes copy];
}

- (void)setRowVerticalAlignment:(UIControlContentVerticalAlignment)rowVerticalAlignment
{
    if (_rowVerticalAlignment == rowVerticalAlignment)
        return;
    
    _rowVerticalAlignment = rowVerticalAlignment;
    
    //TODO: check if we can be more specific
    [self invalidateLayout];
}

@end


@implementation KTRow

+ (instancetype)rowWithLayoutAttributes:(UICollectionViewLayoutAttributes *)attributes
{
    KTRow *row = [self new];
    
    row.section = attributes.indexPath.section;
    row->_itemsLayoutAttributes = [NSMutableArray arrayWithObject:attributes];
    row.maxY = CGRectGetMaxY(attributes.frame);
    row.minY = CGRectGetMinY(attributes.frame);
    
    return row;
}

- (void)addLayoutAttributes:(UICollectionViewLayoutAttributes *)attributes
{
    [self.itemsLayoutAttributes addObject:attributes];
    self.minY = MIN(self.minY, CGRectGetMinY(attributes.frame));
    self.maxY = MAX(self.maxY, CGRectGetMaxY(attributes.frame));
}

- (BOOL)couldContainLayoutAttributes:(UICollectionViewLayoutAttributes *)attributes
{//x1 <= y2 && y1 <= x2
    return self.minY <= CGRectGetMaxY(attributes.frame) && CGRectGetMinY(attributes.frame) <= self.maxY;
}

@end
