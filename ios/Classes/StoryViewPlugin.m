#import "StoryViewPlugin.h"
#if __has_include(<story_view/story_view-Swift.h>)
#import <story_view/story_view-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "story_view-Swift.h"
#endif

@implementation StoryViewPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftStoryViewPlugin registerWithRegistrar:registrar];
}
@end
