//
//  FolderDropAcceptingTextField.m
//  spires
//
//  Created by Yuji on 6/30/09.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import "DropAcceptingTextField.h"


@implementation DropAcceptingTextField
-(void)awakeFromNib
{
    [self registerForDraggedTypes:[(id<DropAcceptingTextFieldDelegate>)[self delegate] draggedTypesToRegister]];
}
- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender {
    return [(id<DropAcceptingTextFieldDelegate>)[self delegate] draggingEntered:sender];
}
- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender {
    return [(id<DropAcceptingTextFieldDelegate>)[self delegate] performDragOperation:sender];
}
@end
