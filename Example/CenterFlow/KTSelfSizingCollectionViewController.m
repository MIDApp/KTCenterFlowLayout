//
//  KTSelfSizingCollectionViewController.m
//  CenterFlow
//
//  Created by Kyle Truscott on 5/3/16.
//  Copyright © 2016 keighl. All rights reserved.
//

#import "KTSelfSizingCollectionViewController.h"
#import "KTCenterFlowLayout.h"
#import "KTAwesomeSizingCell.h"
#import "Constants.h"
#import "KTHeaderFooterView.h"


@interface KTSelfSizingCollectionViewController ()
@property (strong) NSArray *states;
@end

@implementation KTSelfSizingCollectionViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Align"
                                                                                            style:UIBarButtonItemStyleDone
                                                                                           target:self
                                                                                           action:@selector(changeRowVerticalAlignment:)];
    
    self.collectionView.backgroundColor = [UIColor whiteColor];
    
    KTCenterFlowLayout *flowLayout = (KTCenterFlowLayout *)self.collectionViewLayout;
    [flowLayout setEstimatedItemSize:CGSizeMake(100, 50)];
    [flowLayout setMinimumInteritemSpacing:15.f];
    [flowLayout setMinimumLineSpacing:15.f];
    [flowLayout setSectionInset:UIEdgeInsetsMake(20, 20, 20, 20)];
    
    [self.collectionView registerClass:[KTAwesomeSizingCell class] forCellWithReuseIdentifier:stateCellID];
    
    [self.collectionView registerClass:[KTHeaderFooterView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:headerCellID];
    [self.collectionView registerClass:[KTHeaderFooterView class] forSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:footerCellID];
    
    self.states = [Constants states];
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.states.count;
}

#pragma mark - UICollectionViewDelegate

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    KTAwesomeSizingCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:stateCellID
                                                                          forIndexPath:indexPath];
    
    cell.label.text = self.states[indexPath.row];
    cell.label.font = [self fontForText:cell.label.text];
    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView
           viewForSupplementaryElementOfKind:(NSString *)kind
                                 atIndexPath:(NSIndexPath *)indexPath
{
    KTCenterFlowLayout *flowLayout = (KTCenterFlowLayout *)self.collectionViewLayout;
    UIControlContentVerticalAlignment alignment = flowLayout.rowVerticalAlignment;
    
    
    if (kind == UICollectionElementKindSectionHeader)
    {
        KTHeaderFooterView *header = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:headerCellID forIndexPath:indexPath];
        header.label.text = [self headerTextForRowAlignment:alignment];
        return header;
    }
    
    if (kind == UICollectionElementKindSectionFooter)
    {
        KTHeaderFooterView *header = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:footerCellID forIndexPath:indexPath];
        header.label.text = [self footerTextForRowAlignment:alignment];
        return header;
    }
    
    return nil;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section;
{
    CGFloat width = collectionView.bounds.size.width;
    return CGSizeMake(width, 40);
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section;
{
    CGFloat width = collectionView.bounds.size.width;
    return CGSizeMake(width, 60);
}

- (UIFont *)fontForText:(NSString *)text
{
    if (text.length == 7)
    {
        return [UIFont systemFontOfSize:16];
    }
    
    if (text.length == 8)
    {
        return [UIFont systemFontOfSize:24];
    }
    
    if (text.length == 5)
    {
        return [UIFont systemFontOfSize:10];
    }
    
    return [UIFont systemFontOfSize:14];
}

- (void)changeRowVerticalAlignment:(id)sender
{
    KTCenterFlowLayout *flowLayout = (KTCenterFlowLayout *)self.collectionViewLayout;
    
    flowLayout.rowVerticalAlignment = (flowLayout.rowVerticalAlignment + 1) % (UIControlContentVerticalAlignmentFill + 1);
    
    // Need this in order to update the header and footer text
    [self.collectionView reloadData];
}

- (NSString *)headerTextForRowAlignment:(UIControlContentVerticalAlignment)alignment
{
    NSString *desc = @"undefined";
    
    switch (alignment)
    {
        case UIControlContentVerticalAlignmentFill:
            desc = @"Fill";
            break;
            
        case UIControlContentVerticalAlignmentBottom:
            desc = @"Bottom";
            break;
            
        case UIControlContentVerticalAlignmentTop:
            desc = @"Top";
            break;
            
        case UIControlContentVerticalAlignmentCenter:
            desc = @"Center";
            break;
    }
    
    return [NSString stringWithFormat:@"The Row Vertical Alignment is %@...", desc];
}

- (NSString *)footerTextForRowAlignment:(UIControlContentVerticalAlignment)alignment
{
    NSString *desc;
    
    switch (alignment)
    {
        case UIControlContentVerticalAlignmentFill:
            desc = @"all cells in a row have the same height of tallest cell of the row";
            break;
            
        case UIControlContentVerticalAlignmentBottom:
            desc = @"all cells in a row are aligned to the bottom margin of the tallest cell of the row";
            break;
            
        case UIControlContentVerticalAlignmentTop:
            desc = @"all cells in a row are aligned to the top margin of the tallest cell of the row";
            break;
            
        case UIControlContentVerticalAlignmentCenter:
            desc = @"we use the \"vanilla\" behaviour";
            break;
            
        default:
            desc = @"probably you set a wrong value for verticalAlignment property (so we use the \"Center\" behaviour)";
            break;
    }
    
    return [NSString stringWithFormat:@"...that means %@", desc];
}

@end
