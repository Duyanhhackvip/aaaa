#include "LoadView/Includes.h"
#import "Security/oxorany/oxorany_include.h"
#import "Security/oxorany/oxorany.h"
#include <Foundation/Foundation.h>
#include <libgen.h>
#include <mach-o/dyld.h>
#include <mach-o/fat.h>
#include <mach-o/loader.h>
#include <mach/vm_page_size.h>
#include <unistd.h>
#include <array>
#include <deque>
#include <map>
#include <vector>
#import "imgui/Il2cpp.h"
#import "LoadView/Icon.h"
#import "imgui/stb_image.h"
#include "hook/hook.h"
#import "imgui/CaptainHook.h"
#import "imgui/imgui_additional.h"
#include <CoreFoundation/CoreFoundation.h>
#import "mahoa.h"
#import "cac.h"
#include "hack/Vector3.h"
#include "hack/Vector2.h"
#include "hack/Quaternion.h"
#include "hack/Monostring.h"
#include "Esp.h"
#import "LoadView/CTCheckbox.h"
#define kWidth [UIScreen mainScreen].bounds.size.width
#define kHeight [UIScreen mainScreen].bounds.size.height
#define kScale [UIScreen mainScreen].scale

CTCheckbox *checkbox1;
CTCheckbox *checkbox2;
UIWindow *mainWindow;
UIButton *menuView;
using namespace IL2Cpp;
@interface ImGuiDrawView () <MTKViewDelegate>
@property (nonatomic, strong) id <MTLDevice> device;
@property (nonatomic, strong) id <MTLCommandQueue> commandQueue;
- (void)ghost;
- (void)removeGhost; 
- (void)switchIsChanged:(UISwitch *)SW1;
@end
@implementation ImGuiDrawView
static float tabContentOffsetY[5] = {20.0f, 20.0f, 20.0f, 20.0f, 20.0f}; 
static float tabContentAlpha[5] = {0.0f, 0.0f, 0.0f, 0.0f, 0.0f}; 
static int selectedTab = 0;
static int lastSelectedTab = -1; 

const float TAB_CONTENT_ANIMATION_SPEED = 8.0f;
const float BUTTON_WIDTH = 105.0f;
const float BUTTON_HEIGHT = 33.0f;

void AnimateTabContent(int index, bool isActive) {
    if (isActive) {
        if (tabContentOffsetY[index] > 0.0f) {
            tabContentOffsetY[index] -= ImGui::GetIO().DeltaTime * TAB_CONTENT_ANIMATION_SPEED * 20.0f;
            if (tabContentOffsetY[index] < 0.0f) {
                tabContentOffsetY[index] = 0.0f;
            }
        }
        if (tabContentAlpha[index] < 1.0f) {
            tabContentAlpha[index] += ImGui::GetIO().DeltaTime * TAB_CONTENT_ANIMATION_SPEED;
            if (tabContentAlpha[index] > 1.0f) {
                tabContentAlpha[index] = 1.0f;
            }
        }
    } else {
        if (tabContentOffsetY[index] < 20.0f) {
            tabContentOffsetY[index] += ImGui::GetIO().DeltaTime * TAB_CONTENT_ANIMATION_SPEED * 20.0f;
            if (tabContentOffsetY[index] > 20.0f) {
                tabContentOffsetY[index] = 20.0f;
            }
        }
        if (tabContentAlpha[index] > 0.0f) {
            tabContentAlpha[index] -= ImGui::GetIO().DeltaTime * TAB_CONTENT_ANIMATION_SPEED;
            if (tabContentAlpha[index] < 0.0f) {
                tabContentAlpha[index] = 0.0f;
            }
        }
    }
}
ImFont* _espFont;
ImFont *_iconFont;

BOOL hasGhostBeenDrawn = NO;


bool napdannhanh = false;
float Napdannhanh(void *instance) {
     if (napdannhanh) {
         return 100.0;//nạp đạn nhanh
     }
}

float camxa = 60; 
int Camxa(void *instance) {
    if (camxa > 0.0) {
        return 150.0; 
    } else {
        return 60.0;
    }
}



bool norecoi = false;
int Norecoi(void *instance) {
     if (norecoi) {
         return 99;
     }else{
    return 1;
    }
}

bool haisung = false;
int Haisung(void *instance) {
     if (haisung) {//2 súng
         return 1;
     }else{
         return 1;
    }
}
bool sen = false;

- (void)ghost {  
    
    
    if (!menuView) {  
        // Tạo menuView với nền tròn màu đen nhạt  
        menuView = [UIButton buttonWithType:UIButtonTypeCustom]; // Thay đổi ở đây  
// Tạo hình tròn
        menuView.frame = CGRectMake(305, 265, 50, 50);  
        menuView.layer.cornerRadius = menuView.bounds.size.width / 2; // Hình tròn  
        menuView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.6]; // Nền đen nhạt  
        menuView.alpha = 1.0f;  

        // Đảm bảo chỉ thêm vào cửa sổ chính một lần  
        [mainWindow addSubview:menuView];  

        // Thêm sự kiện kéo nút sử dụng UIPanGestureRecognizer  
        UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];  
        [menuView addGestureRecognizer:panGesture];  

        // Thêm nhãn cho trạng thái Aimbot  
        UILabel *aimLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 25, 70, 20)]; // Đặt đúng vị trí  
        aimLabel.font = [UIFont fontWithName:@"CourierNewPS-BoldMT" size:16];  
        aimLabel.textAlignment = NSTextAlignmentCenter; // Canh giữa  
        aimLabel.backgroundColor = [UIColor clearColor]; // Không có nền  
        aimLabel.tag = 100; // Gán thẻ để truy xuất sau  

        // Thêm nhãn vào menuView  
        [menuView addSubview:aimLabel];  

        // Đặt văn bản cho nhãn  
        aimLabel.text = @"AIM";   
        aimLabel.textColor = [UIColor redColor]; // Màu chữ bắt đầu là đỏ (tắt)  

        // Tạo nút để bật/tắt Aimbot  
        UIButton *aimButton = [UIButton buttonWithType:UIButtonTypeCustom];  
        aimButton.frame = CGRectMake(0, 0, 50, 50); // Kích thước giống như menuView  
        aimButton.layer.cornerRadius = aimButton.bounds.size.width / 2; // Tạo hình tròn  
        
        aimButton.backgroundColor = [UIColor clearColor]; // Nền trong suốt  
        [aimButton addTarget:self action:@selector(switchIsChanged:) forControlEvents:UIControlEventTouchUpInside];  

        // Thêm nút vào menuView  
        [menuView addSubview:aimButton];  

        hasGhostBeenDrawn = YES; // Đánh dấu menu đã được vẽ  
    }  
}  

// Phương thức gọi khi Aimbot bị bật/tắt  
- (void)switchIsChanged:(UIButton *)button {  
    dispatch_async(dispatch_get_main_queue(), ^{  
        UILabel *aimLabel = (UILabel *)[[button superview] viewWithTag:100]; // Tìm nhãn  

        if ([aimLabel.textColor isEqual:[UIColor redColor]]) {  
            // Bật Aimbot  
            Aimbot = true;  
            aimLabel.textColor = [UIColor greenColor]; // Đổi màu chữ thành xanh  
        } else {  
            // Tắt Aimbot  
            Aimbot = false;  
            aimLabel.textColor = [UIColor redColor]; // Đổi màu chữ thành đỏ  
        }  
    });  
}  

// Phương thức gọi khi xóa menu  
- (void)removeGhost {  
    if (menuView) {  
        [menuView removeFromSuperview];  
        menuView = nil;  
        hasGhostBeenDrawn = NO;  
    }  
}  

// Phương thức xử lý kéo  
- (void)handlePan:(UIPanGestureRecognizer *)gesture {  
    CGPoint translation = [gesture translationInView:mainWindow];  
    CGPoint newCenter = CGPointMake(gesture.view.center.x + translation.x, gesture.view.center.y + translation.y);  
    gesture.view.center = newCenter; // Cập nhật vị trí của nút  
    [gesture setTranslation:CGPointZero inView:mainWindow]; // Đặt lại translation về 0  
}  
- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil bundle:(nullable NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];

    _device = MTLCreateSystemDefaultDevice();
    _commandQueue = [_device newCommandQueue];

    if (!self.device) abort();

    IMGUI_CHECKVERSION();
    ImGui::CreateContext();
    ImGuiIO& io = ImGui::GetIO();

    ImGuiStyle& style = ImGui::GetStyle();
    style.WindowPadding = ImVec2(10, 10);
    style.WindowRounding = 5.0f;
    style.FramePadding = ImVec2(5, 5);
    style.FrameRounding = 4.0f;
    style.ItemSpacing = ImVec2(12, 8);
    style.ItemInnerSpacing = ImVec2(8, 6);
    style.IndentSpacing = 25.0f;
    style.ScrollbarSize = 15.0f;
    style.ScrollbarRounding = 9.0f;
    style.GrabMinSize = 5.0f;
    style.GrabRounding = 3.0f;
    style.WindowBorderSize = 1.0f;
    style.FrameBorderSize = 1.0f;
    style.PopupBorderSize = 1.0f;
    style.Alpha = 1.0f;

    // Colors
    ImVec4* colors = ImGui::GetStyle().Colors;
    colors[ImGuiCol_Text]                   = ImVec4(0.95f, 0.96f, 0.98f, 1.00f);
    colors[ImGuiCol_TextDisabled]           = ImVec4(0.36f, 0.42f, 0.47f, 1.00f);
    colors[ImGuiCol_WindowBg]               = ImVec4(0.11f, 0.15f, 0.17f, 1.00f);
    colors[ImGuiCol_ChildBg]                = ImVec4(0.15f, 0.18f, 0.22f, 1.00f);
    colors[ImGuiCol_PopupBg]                = ImVec4(0.08f, 0.08f, 0.08f, 0.94f);
    colors[ImGuiCol_Border]                 = ImVec4(0.08f, 0.10f, 0.12f, 1.00f);
    colors[ImGuiCol_BorderShadow]           = ImVec4(0.00f, 0.00f, 0.00f, 0.00f);
    colors[ImGuiCol_FrameBg]                = ImVec4(0.20f, 0.25f, 0.29f, 1.00f);
    colors[ImGuiCol_FrameBgHovered]         = ImVec4(0.12f, 0.20f, 0.28f, 1.00f);
    colors[ImGuiCol_FrameBgActive]          = ImVec4(0.09f, 0.12f, 0.14f, 1.00f);
    colors[ImGuiCol_TitleBg]                = ImVec4(0.09f, 0.12f, 0.14f, 0.65f);
    colors[ImGuiCol_TitleBgActive]          = ImVec4(0.08f, 0.10f, 0.12f, 1.00f);
    colors[ImGuiCol_TitleBgCollapsed]       = ImVec4(0.00f, 0.00f, 0.00f, 0.51f);
    colors[ImGuiCol_MenuBarBg]              = ImVec4(0.15f, 0.18f, 0.22f, 1.00f);
    colors[ImGuiCol_ScrollbarBg]            = ImVec4(0.02f, 0.02f, 0.02f, 0.39f);
    colors[ImGuiCol_ScrollbarGrab]          = ImVec4(0.20f, 0.25f, 0.29f, 1.00f);
    colors[ImGuiCol_ScrollbarGrabHovered]   = ImVec4(0.18f, 0.22f, 0.25f, 1.00f);
    colors[ImGuiCol_ScrollbarGrabActive]    = ImVec4(0.09f, 0.21f, 0.31f, 1.00f);
    colors[ImGuiCol_CheckMark]              = ImVec4(0.26f, 0.59f, 0.98f, 1.00f);
    colors[ImGuiCol_SliderGrab]             = ImVec4(0.24f, 0.52f, 0.88f, 1.00f);
    colors[ImGuiCol_SliderGrabActive]       = ImVec4(0.26f, 0.59f, 0.98f, 1.00f);
    colors[ImGuiCol_Button]                 = ImVec4(0.20f, 0.25f, 0.29f, 1.00f);
    colors[ImGuiCol_ButtonHovered]          = ImVec4(205.0f/255.0f, 250.0f/255.0f, 0.0f/255.0f, 1.00f);
    colors[ImGuiCol_ButtonActive]           = ImVec4(0.06f, 0.53f, 0.98f, 1.00f);
    colors[ImGuiCol_Header]                 = ImVec4(0.20f, 0.25f, 0.29f, 0.55f);
    colors[ImGuiCol_HeaderHovered]          = ImVec4(0.26f, 0.59f, 0.98f, 0.80f);
    colors[ImGuiCol_HeaderActive]           = ImVec4(0.26f, 0.59f, 0.98f, 1.00f);
    colors[ImGuiCol_Separator]              = ImVec4(0.20f, 0.25f, 0.29f, 1.00f);
    colors[ImGuiCol_SeparatorHovered]       = ImVec4(0.10f, 0.40f, 0.75f, 0.78f);
    colors[ImGuiCol_SeparatorActive]        = ImVec4(0.10f, 0.40f, 0.75f, 1.00f);
    colors[ImGuiCol_ResizeGrip]             = ImVec4(0.26f, 0.59f, 0.98f, 0.20f);
    colors[ImGuiCol_ResizeGripHovered]      = ImVec4(0.26f, 0.59f, 0.98f, 0.67f);
    colors[ImGuiCol_ResizeGripActive]       = ImVec4(0.26f, 0.59f, 0.98f, 0.95f);
    colors[ImGuiCol_Tab]                    = ImVec4(0.11f, 0.15f, 0.17f, 1.00f);
    colors[ImGuiCol_TabHovered]             = ImVec4(0.26f, 0.59f, 0.98f, 0.80f);
    colors[ImGuiCol_TabActive]              = ImVec4(0.20f, 0.25f, 0.29f, 1.00f);
    colors[ImGuiCol_TabUnfocused]           = ImVec4(0.11f, 0.15f, 0.17f, 1.00f);
    colors[ImGuiCol_TabUnfocusedActive]     = ImVec4(0.11f, 0.15f, 0.17f, 1.00f);
    colors[ImGuiCol_PlotLines]              = ImVec4(0.61f, 0.61f, 0.61f, 1.00f);
    colors[ImGuiCol_PlotLinesHovered]       = ImVec4(1.00f, 0.43f, 0.35f, 1.00f);
    colors[ImGuiCol_PlotHistogram]          = ImVec4(0.90f, 0.70f, 0.00f, 1.00f);
    colors[ImGuiCol_PlotHistogramHovered]   = ImVec4(1.00f, 0.60f, 0.00f, 1.00f);
    colors[ImGuiCol_TableHeaderBg]          = ImVec4(0.19f, 0.19f, 0.20f, 1.00f);
    colors[ImGuiCol_TableBorderStrong]      = ImVec4(0.31f, 0.31f, 0.45f, 1.00f);
    colors[ImGuiCol_TableBorderLight]       = ImVec4(0.26f, 0.26f, 0.28f, 1.00f);
    colors[ImGuiCol_TableRowBg]             = ImVec4(0.00f, 0.00f, 0.00f, 0.00f);
    colors[ImGuiCol_TableRowBgAlt]          = ImVec4(1.00f, 1.00f, 1.00f, 0.06f);
    colors[ImGuiCol_TextSelectedBg]         = ImVec4(0.26f, 0.59f, 0.98f, 0.35f);
    colors[ImGuiCol_DragDropTarget]         = ImVec4(1.00f, 1.00f, 0.00f, 0.90f);
    colors[ImGuiCol_NavHighlight]           = ImVec4(0.26f, 0.59f, 0.98f, 1.00f);
    colors[ImGuiCol_NavWindowingHighlight]  = ImVec4(1.00f, 1.00f, 1.00f, 0.70f);
    colors[ImGuiCol_NavWindowingDimBg]      = ImVec4(0.80f, 0.80f, 0.80f, 0.20f);
    colors[ImGuiCol_ModalWindowDimBg]       = ImVec4(0.80f, 0.80f, 0.80f, 0.35f);


    ImFontConfig config;
    ImFontConfig icons_config;
    config.FontDataOwnedByAtlas = false;
    icons_config.MergeMode = true;
    icons_config.PixelSnapH = true;
    icons_config.OversampleH = 2;
    icons_config.OversampleV = 2;

    static const ImWchar icons_ranges[] = { 0xf000, 0xf3ff, 0 };

    NSString *fontPath = nssoxorany("/System/Library/Fonts/Core/AvenirNext.ttc");

    _espFont = io.Fonts->AddFontFromFileTTF(fontPath.UTF8String, 30.f, &config, io.Fonts->GetGlyphRangesVietnamese());

    _iconFont = io.Fonts->AddFontFromMemoryCompressedTTF(font_awesome_data, font_awesome_size, 19.0f, &icons_config, icons_ranges);

    _iconFont->FontSize = 5;
    io.FontGlobalScale = 0.5f;

    ImGui_ImplMetal_Init(_device);

    return self;
}

+ (void)showChange:(BOOL)open
{
    MenDeal = open;
}

+ (BOOL)isMenuShowing {
    return MenDeal;
}

- (MTKView *)mtkView
{
    return (MTKView *)self.view;
}



- (void)loadView
{
    CGFloat w = [UIApplication sharedApplication].windows[0].rootViewController.view.frame.size.width;
    CGFloat h = [UIApplication sharedApplication].windows[0].rootViewController.view.frame.size.height;
    self.view = [[MTKView alloc] initWithFrame:CGRectMake(0, 0, w, h)];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.mtkView.device = self.device;
    if (!self.mtkView.device) {
        return;
    }
    self.mtkView.delegate = self;
    self.mtkView.clearColor = MTLClearColorMake(0, 0, 0, 0);
    self.mtkView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0];
    self.mtkView.clipsToBounds = YES;

    void* address[] = {  
         
(void*)getRealOffset(ENCRYPTOFFSET("0x10529A408")), //Update

(void*)getRealOffset(ENCRYPTOFFSET("0x1052620FC")),//ondestroy
              (void*)getRealOffset(ENCRYPTOFFSET("0x1040D6610")),//Napdannhanh
         (void*)getRealOffset(ENCRYPTOFFSET("0x1040D18E0")),//Haisung
        (void*)getRealOffset(ENCRYPTOFFSET("0x103E526F0")),//Camxa
(void*)getRealOffset(ENCRYPTOFFSET("0x1051D1F94")),
    };
    void* function[] = {
        
        (void*)Update,
        (void*)OnDestroy,
        (void*)Napdannhanh,
        (void*)Haisung,
        (void*)Camxa,
        (void*)Norecoi,
    };
    hook(address, function, 6);
_GetHeadPositions = (void*(*)(void *))getRealOffset(ENCRYPTOFFSET("0x1052BECB8"));
_newHipMods = (void *(*)(void *))getRealOffset(ENCRYPTOFFSET("0x1052BEE08"));
_GetLeftAnkleTF = (void *(*)(void *))getRealOffset(ENCRYPTOFFSET("0x1052BF13C"));
_GetRightAnkleTF = (void *(*)(void *))getRealOffset(ENCRYPTOFFSET("0x1052BF1E0"));
_GetLeftToeTF = (void *(*)(void *))getRealOffset(ENCRYPTOFFSET("0x1052BF284"));
_GetRightToeTF = (void *(*)(void *))getRealOffset(ENCRYPTOFFSET("0x1052BF328"));
_getLeftHandTF = (void *(*)(void *))getRealOffset(ENCRYPTOFFSET("0x10525C0E8"));
_getRightHandTF = (void *(*)(void *))getRealOffset(ENCRYPTOFFSET("0x10525C194"));
_getLeftForeArmTF = (void *(*)(void *))getRealOffset(ENCRYPTOFFSET("0x10525C238"));
_getRightForeArmTF = (void *(*)(void *))getRealOffset(ENCRYPTOFFSET("0x10525C2DC"));

    Local = (bool (*)(void *))getRealOffset(ENCRYPTOFFSET("0x105258C80"));                              
    Team = (bool (*)(void *))getRealOffset(ENCRYPTOFFSET("0x10526D118"));                               
    get_CurHP = (int (*)(void *))getRealOffset(ENCRYPTOFFSET("0x1052A8A30"));                           
    get_MaxHP = (int(*)(void *))getRealOffset(ENCRYPTOFFSET("0x1052A8AD8"));                            
    get_position = (Vector3(*)(void *))getRealOffset(ENCRYPTOFFSET("0x105F3D46C"));                     
    WorldToViewpoint = (Vector3(*)(void *, Vector3, int))getRealOffset(ENCRYPTOFFSET("0x105EF6394"));  
    get_main = (void *(*)())getRealOffset(ENCRYPTOFFSET("0x105EF6D08"));                                
    get_transform = (void *(*)(void *))getRealOffset(ENCRYPTOFFSET("0x105EF8D78"));                    

}
static bool MenDeal = false;
static bool StreamerMode = false;

- (void)drawInMTKView:(MTKView*)view
{

    hideRecordTextfield.secureTextEntry = StreamerMode;

    ImGuiIO& io = ImGui::GetIO();
    io.DisplaySize.x = view.bounds.size.width;
    io.DisplaySize.y = view.bounds.size.height;

    CGFloat framebufferScale = view.window.screen.nativeScale ?: UIScreen.mainScreen.nativeScale;
    io.DisplayFramebufferScale = ImVec2(framebufferScale, framebufferScale);
    io.DeltaTime = 1 / float(view.preferredFramesPerSecond ?: 60);
    
    id<MTLCommandBuffer> commandBuffer = [self.commandQueue commandBuffer];
        
        if (MenDeal == true) 
        {
            [self.view setUserInteractionEnabled:YES];
            [self.view.superview setUserInteractionEnabled:YES];
            [menuTouchView setUserInteractionEnabled:YES];
        } 
        else if (MenDeal == false) 
        {
           
            [self.view setUserInteractionEnabled:NO];
            [self.view.superview setUserInteractionEnabled:NO];
            [menuTouchView setUserInteractionEnabled:NO];

        }

        MTLRenderPassDescriptor* renderPassDescriptor = view.currentRenderPassDescriptor;
        if (renderPassDescriptor != nil)
        {
            id <MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
            [renderEncoder pushDebugGroup:nssoxorany("ImGui Jane")];

            ImGui_ImplMetal_NewFrame(renderPassDescriptor);
            ImGui::NewFrame();

            CGFloat width = 480;
            CGFloat height = 330;
            ImGui::SetNextWindowPos(ImVec2((kWidth - width) / 2, (kHeight - height) / 2), ImGuiCond_FirstUseEver);
            ImGui::SetNextWindowSize(ImVec2(width, height), ImGuiCond_FirstUseEver);



            
if (MenDeal) {
            ImGui::Begin(ICON_FA_USER_CIRCLE" Project By Duy Anh", &MenDeal);
            ImGui::PushStyleVar(ImGuiStyleVar_FrameRounding, 10.0f);
            ImGui::PushStyleVar(ImGuiStyleVar_FrameBorderSize, 2.0f);

            // Tab Buttons
            ImGui::PushStyleColor(ImGuiCol_Button, selectedTab == 0 ? ImVec4(0.12f, 0.15f, 0.18f, 1.0f) : ImVec4(0.08f, 0.08f, 0.08f, 1.0f));
ImGui::PushStyleColor(ImGuiCol_ButtonHovered, ImVec4(0.18f, 0.22f, 0.25f, 1.0f));
ImGui::PushStyleColor(ImGuiCol_ButtonActive, ImVec4(0.20f, 0.25f, 0.30f, 1.0f));
ImGui::PushStyleColor(ImGuiCol_Text, selectedTab == 0 ? ImVec4(1.0f, 1.0f, 1.0f, 1.0f) : ImVec4(0.75f, 0.75f, 0.75f, 1.0f));

             if 
(ImGui::Button(ICON_FA_CODE " DEV DUY ANH", ImVec2(BUTTON_WIDTH, BUTTON_HEIGHT))) {
                selectedTab = 0;
            }
            ImGui::PopStyleColor(4);

            ImGui::SameLine();

            ImGui::PushStyleColor(ImGuiCol_Button, selectedTab == 1 ? ImVec4(0.12f, 0.15f, 0.18f, 1.0f) : ImVec4(0.08f, 0.08f, 0.08f, 1.0f));
ImGui::PushStyleColor(ImGuiCol_ButtonHovered, ImVec4(0.18f, 0.22f, 0.25f, 1.0f));
ImGui::PushStyleColor(ImGuiCol_ButtonActive, ImVec4(0.20f, 0.25f, 0.30f, 1.0f));
ImGui::PushStyleColor(ImGuiCol_Text, selectedTab == 1 ? ImVec4(1.0f, 1.0f, 1.0f, 1.0f) : ImVec4(0.75f, 0.75f, 0.75f, 1.0f));

            if (ImGui::Button(ICON_FA_EYE " ESP", ImVec2(BUTTON_WIDTH, BUTTON_HEIGHT))) {
                selectedTab = 1;
            }
            ImGui::PopStyleColor(4);

            ImGui::SameLine();

            ImGui::PushStyleColor(ImGuiCol_Button, selectedTab == 2 ? ImVec4(0.12f, 0.15f, 0.18f, 1.0f) : ImVec4(0.08f, 0.08f, 0.08f, 1.0f));
ImGui::PushStyleColor(ImGuiCol_ButtonHovered, ImVec4(0.18f, 0.22f, 0.25f, 1.0f));
ImGui::PushStyleColor(ImGuiCol_ButtonActive, ImVec4(0.20f, 0.25f, 0.30f, 1.0f));
ImGui::PushStyleColor(ImGuiCol_Text, selectedTab == 2 ? ImVec4(1.0f, 1.0f, 1.0f, 1.0f) : ImVec4(0.75f, 0.75f, 0.75f, 1.0f));

            
         if (ImGui::Button(ICON_FA_CROSSHAIRS " AIMBOT", ImVec2(BUTTON_WIDTH, BUTTON_HEIGHT))) 
{
                
                selectedTab = 2;
            }
            ImGui::PopStyleColor(4);

            ImGui::SameLine();

            ImGui::PushStyleColor(ImGuiCol_Button, selectedTab == 3 ? ImVec4(0.12f, 0.15f, 0.18f, 1.0f) : ImVec4(0.08f, 0.08f, 0.08f, 1.0f));
ImGui::PushStyleColor(ImGuiCol_ButtonHovered, ImVec4(0.18f, 0.22f, 0.25f, 1.0f));
ImGui::PushStyleColor(ImGuiCol_ButtonActive, ImVec4(0.20f, 0.25f, 0.30f, 1.0f));
ImGui::PushStyleColor(ImGuiCol_Text, selectedTab == 3 ? ImVec4(1.0f, 1.0f, 1.0f, 1.0f) : ImVec4(0.75f, 0.75f, 0.75f, 1.0f));
            if (ImGui::Button(ICON_FA_YIN_YANG " SETTING", ImVec2(BUTTON_WIDTH, BUTTON_HEIGHT))) 
{
                selectedTab = 3;
            }
            ImGui::PopStyleColor(4);

            ImGui::PopStyleVar(2);

            
            if (lastSelectedTab != selectedTab) {
               
                for (int i = 0; i < 4; ++i) { 
                    tabContentOffsetY[i] = 20.0f;
                    tabContentAlpha[i] = 0.0f;
                }
                lastSelectedTab = selectedTab;
            }
            AnimateTabContent(selectedTab, true);

            ImGui::PushStyleVar(ImGuiStyleVar_ItemSpacing, ImVec2(12, 8 + tabContentOffsetY[selectedTab]));
            ImGui::PushStyleVar(ImGuiStyleVar_Alpha, tabContentAlpha[selectedTab]);
            
            
            if (selectedTab == 0) {

             ImGui::Separator();


             ImGui::TextColored(ImColor(255, 0, 255), "Thông Tin Liên Hệ");

            if (ImGui::Button(ENCRYPT("Telegram"))) {
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://t.me/modgameal"]];
            }
            ImGui::SameLine(100);
            if (ImGui::Button(ENCRYPT("YouTube"))) {
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://youtube.com/@Duyanhmod219"]];
            }

            if (ImGui::Button(ENCRYPT("ZaLo"))) {
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://zalo.me/0792432380"]];
            }
            ImGui::SameLine(100);
            if (ImGui::Button(ENCRYPT("Nhóm Zalo"))) {
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://zalo.me/g/gxxbzx872"]];
            }

            if (ImGui::Button(ENCRYPT("Nhấn Vào Đây Để Tải Menu Speed X8 Free"))) {
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://link4m.com/55qiV"]];
            }

            ImGui::TextColored(ImColor(0, 255, 255), "Nhận Dạy Làm Hack Thuê Hack Make Tên");

            ImGui::TextColored(ImColor(0, 255, 255), "Ib Zalo 0792 432 380 Telegram @modgameal");

             
                
     
 

                ImGui::Spacing();
            }  else if (selectedTab == 1) {
                ImGui::Spacing();
                ImGui::Separator();
                ImGui::Checkbox(" Bật ESP", &ESPEnable);

ImGui::SliderFloat("Khoảng Cách ESP", &sliderDistanceValue, 0.0f, 999.0f);

ImGui::Checkbox("Line", &ESPLine);
ImGui::SameLine(100); 
ImGui::Checkbox("Box", &ESPBox);
ImGui::SameLine(200); 
ImGui::Checkbox("Cảnh Báo", &ESPArrow);

                ImGui::Checkbox("Xương", &bone);
ImGui::SameLine(100); 
ImGui::Checkbox("Name", &ESPName); 
ImGui::SameLine(200); 
ImGui::Checkbox("Máu", &ESPHealth); 

ImGui::Checkbox("Số Địch", &ESPCount);                 

                
            } if (selectedTab == 2) {
                ImGui::Spacing();
                ImGui::Separator();


                ImGui::Checkbox("AIMBOT", &Aimbot);
                
ImGui::Checkbox("FOV", &Fov);ImGui::SameLine(); 

ImGui::SliderFloat("Kích Cỡ Fov", &circle_size, 0.0f, 999.0f);
DrawAimbotTab();

                
            } if (selectedTab == 3) {
              ImGui::Separator();

ImGui::Checkbox("Ẩn Hack", &StreamerMode);

                if (ImGui::Button("Fix Login"))
    {
        self.mtkView.hidden = YES;
        MenDeal = NO;
        timer(30) {
            self.mtkView.hidden = NO;
            MenDeal = YES;
        });
    }      

    ImGui::TextColored(ImColor(0, 255, 0), "Duy Anh");
ImGui::SliderFloat(" ", &camxa, 60.0f, 150.0f, "  Cam Xa [ %.0f ]");
             }

            ImGui::PopStyleVar(2);

            ImGui::Spacing();
      
            ImGui::Spacing();

            ImGui::End();
}

        if (sen && !hasGhostBeenDrawn) {
            [self ghost];
        } else if (!sen) {
            [self removeGhost];
        }

DrawEsp();

    ImGuiStyle& style = ImGui::GetStyle();
        style.Colors[ImGuiCol_WindowBg].w = 0.9f;  
        style.FrameRounding = 15.0f;
        style.GrabMinSize = 7.0f;
        style.PopupRounding = 2.0f;
        style.ScrollbarRounding = 13.0f;
        style.ScrollbarSize = 20.0f;
        style.TabBorderSize = 0.6f;
        style.TabRounding = 6.0f;
        style.WindowRounding = 2.0f;
        style.Alpha = 1.0f;
        style.WindowTitleAlign = ImVec2(0.5f, 0.5f);
            
            ImGui::Render();
            ImDrawData* draw_data = ImGui::GetDrawData();
            ImGui_ImplMetal_RenderDrawData(draw_data, commandBuffer, renderEncoder);

            [renderEncoder popDebugGroup];
            [renderEncoder endEncoding];

            [commandBuffer presentDrawable:view.currentDrawable];
            
        }
        [commandBuffer commit];
}

- (void)mtkView:(MTKView*)view drawableSizeWillChange:(CGSize)size
{
    
}

- (void)updateIOWithTouchEvent:(UIEvent *)event
{
    UITouch *anyTouch = event.allTouches.anyObject;
    CGPoint touchLocation = [anyTouch locationInView:self.view];
    ImGuiIO &io = ImGui::GetIO();
    io.MousePos = ImVec2(touchLocation.x, touchLocation.y);

    BOOL hasActiveTouch = NO;
    for (UITouch *touch in event.allTouches)
    {
        if (touch.phase != UITouchPhaseEnded && touch.phase != UITouchPhaseCancelled)
        {
            hasActiveTouch = YES;
            break;
        }
    }
    io.MouseDown[0] = hasActiveTouch;
}

void DrawAimbotTab() {
    static int selectedAimWhen = AimWhen; // Biến lưu giá trị AimWhen đã chọn

    
    
    // Combo box cho AimWhen
    const char* aimWhenOptions[] = {"Luôn luôn", "Khi bắn", "Khi Ngắm"};
    ImGui::Combo("", &selectedAimWhen, aimWhenOptions, IM_ARRAYSIZE(aimWhenOptions));

ImGui::SliderInt("", &AimDis, 0.0f, 500.0f, "Khoảng Cách AIM [ %.0f ]");

    // Cập nhật AimWhen từ selectedAimWhen
    AimWhen = selectedAimWhen;
}

@end
