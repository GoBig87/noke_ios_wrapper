#import <Foundation/Foundation.h>
typedef void (*tokenfunc) (const char *name, void *user_data);

@interface retToken : NSObject
- (void) retrieveTokenObjC:(char*)lockMacAddr anduser_func:(tokenfunc)user_func anduser_data:(void*)user_data;
@end
void retrieveToken(char* lockMacAddr,tokenfunc user_func, void *user_data);