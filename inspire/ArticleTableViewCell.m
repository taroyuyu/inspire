//
//  ArticleTableViewCell.m
//  inspire
//
//  Created by Yuji on 2015/08/28.
//
//

#import "ArticleTableViewCell.h"

@implementation ArticleTableViewCell

- (void)awakeFromNib {
    // Initialization code
    [super awakeFromNib];
    UIFont*font=self.eprint.font;
    self.eprint.font=[UIFont monospacedDigitSystemFontOfSize:font.pointSize weight:UIFontWeightRegular];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
