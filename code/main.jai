#import "Basic";
#import "String";
#import "System";
#import "Window_Creation";
#import "GL";
#import "Input";
#import "Math";
#import "stb_image";


Simp :: #import "Simp";

LibOVR :: #library,no_dll "../libovr/LibOVR/Lib/Windows/x64/Release/VS2017/LibOVR";

OVR_Result :: s32;
OVR_Session :: *void;
OVR_Texture_Swap_Chain :: *void;
OVR_Mirror_Texture :: *void;
OVR_Bool :: bool;
fbo : u32;
frame_index : s64;

Eye_Texture_Chain :: struct {
    color_texture_chain : OVR_Texture_Swap_Chain;
    depth_texture_chain : OVR_Texture_Swap_Chain;
    size : OVR_Size;
}

eye_texture_chains : [EYE_COUNT] Eye_Texture_Chain;

cube_vao : u32;
cube_vbo : u32;
texture : u32;
texture2 : u32;

cube_vertices :: float32 .[
    // positions          // normals     // texture coords
    -0.5, -0.5, -0.5,  0.0,  0.0, -1.0,  0.0, 0.0,
     0.5, -0.5, -0.5,  0.0,  0.0, -1.0,  1.0, 0.0,
     0.5,  0.5, -0.5,  0.0,  0.0, -1.0,  1.0, 1.0,
     0.5,  0.5, -0.5,  0.0,  0.0, -1.0,  1.0, 1.0,
    -0.5,  0.5, -0.5,  0.0,  0.0, -1.0,  0.0, 1.0,
    -0.5, -0.5, -0.5,  0.0,  0.0, -1.0,  0.0, 0.0,

    -0.5, -0.5,  0.5,  0.0,  0.0, 1.0,   0.0, 0.0,
     0.5, -0.5,  0.5,  0.0,  0.0, 1.0,   1.0, 0.0,
     0.5,  0.5,  0.5,  0.0,  0.0, 1.0,   1.0, 1.0,
     0.5,  0.5,  0.5,  0.0,  0.0, 1.0,   1.0, 1.0,
    -0.5,  0.5,  0.5,  0.0,  0.0, 1.0,   0.0, 1.0,

    -0.5, -0.5,  0.5,  0.0,  0.0, 1.0,   0.0, 0.0,

    -0.5,  0.5,  0.5, -1.0,  0.0,  0.0,  1.0, 0.0,
    -0.5,  0.5, -0.5, -1.0,  0.0,  0.0,  1.0, 1.0,
    -0.5, -0.5, -0.5, -1.0,  0.0,  0.0,  0.0, 1.0,
    -0.5, -0.5, -0.5, -1.0,  0.0,  0.0,  0.0, 1.0,
    -0.5, -0.5,  0.5, -1.0,  0.0,  0.0,  0.0, 0.0,
    -0.5,  0.5,  0.5, -1.0,  0.0,  0.0,  1.0, 0.0,

     0.5,  0.5,  0.5,  1.0,  0.0,  0.0,  1.0, 0.0,
     0.5,  0.5, -0.5,  1.0,  0.0,  0.0,  1.0, 1.0,
     0.5, -0.5, -0.5,  1.0,  0.0,  0.0,  0.0, 1.0,
     0.5, -0.5, -0.5,  1.0,  0.0,  0.0,  0.0, 1.0,
     0.5, -0.5,  0.5,  1.0,  0.0,  0.0,  0.0, 0.0,
     0.5,  0.5,  0.5,  1.0,  0.0,  0.0,  1.0, 0.0,

    -0.5, -0.5, -0.5,  0.0, -1.0,  0.0,  0.0, 1.0,
     0.5, -0.5, -0.5,  0.0, -1.0,  0.0,  1.0, 1.0,
     0.5, -0.5,  0.5,  0.0, -1.0,  0.0,  1.0, 0.0,
     0.5, -0.5,  0.5,  0.0, -1.0,  0.0,  1.0, 0.0,
    -0.5, -0.5,  0.5,  0.0, -1.0,  0.0,  0.0, 0.0,
    -0.5, -0.5, -0.5,  0.0, -1.0,  0.0,  0.0, 1.0,

    -0.5,  0.5, -0.5,  0.0,  1.0,  0.0,  0.0, 1.0,
     0.5,  0.5, -0.5,  0.0,  1.0,  0.0,  1.0, 1.0,
     0.5,  0.5,  0.5,  0.0,  1.0,  0.0,  1.0, 0.0,
     0.5,  0.5,  0.5,  0.0,  1.0,  0.0,  1.0, 0.0,
    -0.5,  0.5,  0.5,  0.0,  1.0,  0.0,  0.0, 0.0,
    -0.5,  0.5, -0.5,  0.0,  1.0,  0.0,  0.0, 1.0
];

indices :: u32.[
    0, 1, 3,   // first triangle
    1, 2, 3    // second triangle
    ];

log_print :: (prefix : string, msg : string, args : ..Any)
{
    arg_str := tprint("[%] %\n", prefix, msg);
    print(arg_str, ..args);
}

OVR_Init_Flags :: enum_flags u32 {
    /// When a debug library is requested, a slower debugging version of the library will
    /// run which can be used to help solve problems in the library and debug application code.
    OVR_INIT_DEBUG :: 0x00000001;

    /// When a version is requested, the LibOVR runtime respects the RequestedMinorVersion
    /// field and verifies that the RequestedMinorVersion is supported. Normally when you
    /// specify this flag you simply use OVR_MINOR_VERSION or ovrInitParams::RequestedMinorVersion,
    /// though you could use a lower version than OVR_MINOR_VERSION to specify previous
    /// version behavior.
    OVR_INIT_REQUEST_VERSION :: 0x00000004;

    /// This client will not be visible in the HMD.
    /// Typically set by diagnostic or debugging utilities.
    OVR_INIT_INVISIBLE :: 0x00000010;

    /// This client will alternate between VR and 2D rendering.
    /// Typically set by game engine editors and VR-enabled web browsers.
    OVR_INIT_MIXED_RENDERING :: 0x00000020;

    /// This client is aware of ovrSessionStatus focus states (e.g. ovrSessionStatus::HasInputFocus),
    /// and responds to them appropriately (e.g. pauses and stops drawing hands when lacking focus).
    OVR_INIT_FOCUS_AWARE :: 0x00000040;

    /// These bits are writable by user code.
    OVR_INIT_WRITABLE_BITS :: 0x00ffffff;
}

OVR_Log_Level :: enum s32 {
  OVR_LOG_LEVEL_DEBUG :: 0; ///< Debug-level log event.
  OVR_LOG_LEVEL_INFO :: 1; ///< Info-level log event.
  OVR_LOG_LEVEL_ERROR :: 2; ///< Error-level log event.
}

OVR_Log_Callback :: #type (user_data: *u32, level: OVR_Log_Level, message: *u8) #c_call;

OVR_Init_Params :: struct {
    flags : OVR_Init_Flags;
    requested_minor_version : u32;
    log_callback : OVR_Log_Callback;
    user_data : *u32;
    connection_timeout_ms : u32;
}

ovr_Initialize :: (params: *OVR_Init_Params) -> OVR_Result #foreign LibOVR;

ovr_Shutdown :: () #foreign LibOVR;

ovr_log :: (user_data: *u32, level: OVR_Log_Level, message: *u8) #c_call {
    new_context : Context;
    push_context new_context {
        prefix : string = ---;
        if #complete level ==
            {
                case .OVR_LOG_LEVEL_DEBUG;
                    prefix = "debug";
                case .OVR_LOG_LEVEL_INFO;
                    prefix = "info";
                case .OVR_LOG_LEVEL_ERROR;
                    prefix = "error";
            }

        str := to_string(message);
        print("[ovr-%] %\n", prefix, str);
    }
}

ovr_success :: inline (result : OVR_Result) -> bool {
    return result >= 0;
}

ovr_failure :: inline (result : OVR_Result) -> bool {
    return !ovr_success(result);
}

#if OS == .WINDOWS {
    #import "Windows";
    OVR_Graphics_Luid :: LUID;
}

ovr_Create :: (session: *OVR_Session, luid: *OVR_Graphics_Luid) -> OVR_Result #foreign LibOVR;

ovr_GetHmdDesc :: (session: OVR_Session) -> OVR_Hmd_Desc #foreign LibOVR;

OVR_Hmd_Type :: enum s32 {
    OVR_HMD_NONE :: 0;
    OVR_HMD_DK2 :: 6;
    OVR_HMD_CB :: 8;
    OVR_HMD_OTHER :: 9;
    OVR_HMD_E3_2015 :: 10;
    OVR_HMD_ES06 :: 11;
    OVR_HMD_ES09 :: 12;
    OVR_HMD_ES11 :: 13;
    OVR_HMD_CV1 :: 14;
    OVR_HMD_RIFTS :: 16;
    OVR_HMD_QUEST :: 19;
    OVR_HMD_QUEST2 :: 20;
}

OVR_Size :: struct {
    w : s32;
    h : s32;
}

OVR_Eye_Type :: enum s32 {
    OVR_EYE_LEFT;
    OVR_EYE_RIGHT;
}

EYE_COUNT :: #run enum_values_as_s64(OVR_Eye_Type).count;

/// Describes the up, down, left, and right angles of the field of view.
///
/// Field Of View (FOV) tangent of the angle units.
/// \note For a standard 90 degree vertical FOV, we would
/// have: { up_tan = tan(90 degrees / 2), down_tan = tan(90 degrees / 2) }.
OVR_Fov_Port :: struct {
    up_tan : float; ///< Tangent of the angle between the viewing vector and top edge of the FOV.
    down_tan : float; ///< Tangent of the angle between the viewing vector and bottom edge of the FOV.
    left_tan : float; ///< Tangent of the angle between the viewing vector and left edge of the FOV.
    right_tan : float; ///< Tangent of the angle between the viewing vector and right edge of the FOV.
}

OVR_Hmd_Desc :: struct {
    type : OVR_Hmd_Type; ///< The type of HMD.
    pad0 : u32; ///< \internal struct padding. 4 bytes padding.

    product_name : [64] u8; ///< UTF8-encoded product identification string (e.g. "Oculus Rift DK1").
    manufacturer : [64] u8; ///< UTF8-encoded HMD manufacturer identification string.

    vendor_id : s16; ///< HID (USB) vendor identifier of the device.
    product_id : u16; ///< HID (USB) product identifier of the device.
    serial_number : [24] u8; ///< HMD serial number.

    firmware_major : u16; ///< HMD firmware major version.
    firmware_minor : u16; ///< HMD firmware minor version.

    available_hmd_caps : u32; ///< Available ovrHmdCaps bits.
    default_hmd_caps : u32; ///< Default ovrHmdCaps bits.
    available_tracking_caps : u32; ///< Available ovrTrackingCaps bits.
    default_tracking_caps : u32; ///< Default ovrTrackingCaps bits.

    default_eye_fov : [EYE_COUNT] OVR_Fov_Port; ///< Defines the recommended FOVs for the HMD.
    max_eye_fov : [EYE_COUNT] OVR_Fov_Port; ///< Defines the maximum FOVs for the HMD.

    resolution : OVR_Size; ///< Resolution of the full HMD screen (both eyes) in pixels.

    display_refresh_rate : float; ///< Refresh rate of the display in cycles per second.

    pad1 : u32; ///< \internal struct padding. 4 bytes padding.
}

/// Position and orientation together.
/// The coordinate system used is right-handed Cartesian.
OVR_Pose :: struct {
    orientation : Quaternion;
    position : Vector3;
};

/// A full pose (rigid body) configuration with first and second derivatives.
///
/// Body refers to any object for which ovrPoseStatef is providing data.
/// It can be the HMD, Touch controller, sensor or something else. The context
/// depends on the usage of the struct.
OVR_Pose_State :: struct {
    the_pose : OVR_Pose; ///< Position and orientation.
    angular_velocity : Vector3; ///< Angular velocity in radians per second.
    linear_velocity : Vector3; ///< Velocity in meters per second.
    angular_acceleration : Vector3; ///< Angular acceleration in radians per second per second.
    linear_acceleration : Vector3; ///< Acceleration in meters per second per second.
    pad0 : u32; ///< \internal struct pad. 4 bytes padding.
    time_in_seconds : float64; ///< Absolute time that this pose refers to. \see ovr_GetTimeInSeconds
};

/// Tracking state at a given absolute time (describes predicted HMD pose, etc.).
/// Returned by ovr_GetTrackingState.
///
/// \see ovr_GetTrackingState
///
OVR_Tracking_State :: struct {
    /// Predicted head pose (and derivatives) at the requested absolute time.
    head_pose : OVR_Pose_State;

    /// HeadPose tracking status described by ovrStatusBits.
    status_flags : u32;

    /// The most recent calculated pose for each hand when hand controller tracking is present.
    /// HandPoses[ovrHand_Left] refers to the left hand and HandPoses[ovrHand_Right] to the right.
    /// These values can be combined with ovrInputState for complete hand controller information.
    hand_poses: [2] OVR_Pose_State;

    /// HandPoses status flags described by ovrStatusBits.
    hand_status_flags: [2] u32;

    /// The pose of the origin captured during calibration.
    /// Like all other poses here, this is expressed in the space set by ovr_RecenterTrackingOrigin,
    /// or ovr_SpecifyTrackingOrigin and so will change every time either of those functions are
    /// called. This pose can be used to calculate where the calibrated origin lands in the new
    /// recentered space. If an application never calls ovr_RecenterTrackingOrigin or
    /// ovr_SpecifyTrackingOrigin, expect this value to be the identity pose and as such will point
    /// respective origin based on ovrTrackingOrigin requested when calling ovr_GetTrackingState.
    calibrated_origin : OVR_Pose;
}

ovr_GetTrackingState :: (session : OVR_Session, absTime : float64, latencyMarker : bool) -> OVR_Tracking_State #foreign LibOVR;
ovr_GetTimeInSeconds :: () -> float64 #foreign LibOVR;

OVR_Status_Bits :: enum_flags u16 {
  // Device orientation is currently tracked. It's possible that the device orientation is not
  // tracked,
  // but its reported orientation is nevertheless valid (e.g. due to estimation)
  OVR_STATUS_ORIENTATION_TRACKED :: 0x0001;

  // Device position is currently tracked. It's possible that the device position is not tracked,
  // but its reported position is nevertheless valid (e.g. due to estimation).
  OVR_STATUS_POSITION_TRACKED :: 0x0002;

  // The reported device orientation is valid for application use. In the case that OrientationValid
  // is true and
  // OrientationTracked is false, the runtime may be estimating the orientation of the device.
  // In the case that OrientationValid is false, the application should not use the returned
  // orientation value.
  OVR_STATUS_ORIENTATION_VALID :: 0x0004;

  // The reported device orientation is valid for application use. In the case that PositionValid is
  // true and
  // PositionTracked is false, the runtime may be estimating the position of the device.
  // In the case that PositionValid is false, the application should not use the returned position
  // value.
  OVR_STATUS_POSITION_VALID :: 0x0008;
}

ovr_GetFovTextureSize :: (session: OVR_Session, eye: OVR_Eye_Type, fov: OVR_Fov_Port, pixels_per_display_pixel: float) -> OVR_Size #foreign LibOVR;

OVR_Texture_Type :: enum_flags s32 {
  OVR_TEXTURE_2D :: 0; ///< 2D textures or texture arrays.
  OVR_TEXTURE_2D_EXTERNAL :: 1; ///< Application-provided 2D texture. Not supported on PC.
  OVR_TEXTURE_CUBE :: 2; ///< Cube maps. ovrTextureSwapChainDesc::ArraySize must be 6 for this type.
}

OVR_Texture_Format :: enum_flags s32 {
  OVR_FORMAT_UNKNOWN :: 0;
  OVR_FORMAT_B5G6R5_UNORM :: 1; ///< Not currently supported on PC. Requires a DirectX 11.1 device.
  OVR_FORMAT_B5G5R5A1_UNORM :: 2; ///< Not currently supported on PC. Requires a DirectX 11.1 device.
  OVR_FORMAT_B4G4R4A4_UNORM :: 3; ///< Not currently supported on PC. Requires a DirectX 11.1 device.
  OVR_FORMAT_R8G8B8A8_UNORM :: 4;
  OVR_FORMAT_R8G8B8A8_UNORM_SRGB :: 5;
  OVR_FORMAT_B8G8R8A8_UNORM :: 6;
  OVR_FORMAT_B8G8R8_UNORM :: 27; ///< Not currently supported.
  OVR_FORMAT_B8G8R8A8_UNORM_SRGB :: 7; ///< Not supported for OpenGL applications
  OVR_FORMAT_B8G8R8X8_UNORM :: 8; ///< Not supported for OpenGL applications
  OVR_FORMAT_B8G8R8X8_UNORM_SRGB :: 9; ///< Not supported for OpenGL applications
  OVR_FORMAT_R16G16B16A16_FLOAT :: 10;
  OVR_FORMAT_R11G11B10_FLOAT :: 25; ///< Not supported for D3D12 applications. Introduced in v1.10

  // Depth formats
  OVR_FORMAT_D16_UNORM :: 11;
  OVR_FORMAT_D24_UNORM_S8_UINT :: 12;
  OVR_FORMAT_D32_FLOAT :: 13;
  OVR_FORMAT_D32_FLOAT_S8X24_UINT :: 14;

  // Added in 1.5 compressed formats can be used for static layers
  OVR_FORMAT_BC1_UNORM :: 15;
  OVR_FORMAT_BC1_UNORM_SRGB :: 16;
  OVR_FORMAT_BC2_UNORM :: 17;
  OVR_FORMAT_BC2_UNORM_SRGB :: 18;
  OVR_FORMAT_BC3_UNORM :: 19;
  OVR_FORMAT_BC3_UNORM_SRGB :: 20;
  OVR_FORMAT_BC6H_UF16 :: 21;
  OVR_FORMAT_BC6H_SF16 :: 22;
  OVR_FORMAT_BC7_UNORM :: 23;
  OVR_FORMAT_BC7_UNORM_SRGB :: 24;
}

OVR_Texture_Swap_Chain_Desc :: struct {
    type : OVR_Texture_Type; ///< Must be ovrTexture_2D or ovrTexture_Cube.
    format : OVR_Texture_Format;
    array_size : s32; ///< Must be 6 for ovrTexture_Cube, size of texture array otherwise.
    width : s32;
    height : s32;
    mip_levels : s32;
    sample_count : s32;
    static_image : OVR_Bool; ///< Not buffered in a chain. For images that don't change
    misc_flags : u32; ///< ovrTextureFlags
    bind_flags : u32; ///< ovrTextureBindFlags. Not used for GL.
}

ovr_CreateTextureSwapChainGL :: (session : OVR_Session, desc : *OVR_Texture_Swap_Chain_Desc, out_texture_set : *OVR_Texture_Swap_Chain) -> OVR_Result #foreign LibOVR;
ovr_GetTextureSwapChainBufferGL :: (session : OVR_Session, chain : OVR_Texture_Swap_Chain, index : s32, tex_id : *u32) -> OVR_Result #foreign LibOVR;

/// A 2D rectangle with a position and size.
/// All components are integers.
OVR_Rect :: struct {
  pos : Vector2;
  size : OVR_Size;
};

/// Rendering information for each eye. Computed by ovr_GetRenderDesc() based on the
/// specified FOV. Note that the rendering viewport is not included
/// here as it can be specified separately and modified per frame by
/// passing different Viewport values in the layer structure.
///
/// \see ovr_GetRenderDesc
///
OVR_Eye_Render_Desc :: struct {
  eye : OVR_Eye_Type; ///< The eye index to which this instance corresponds.
  fov : OVR_Fov_Port; ///< The field of view.
  distorted_viewport : OVR_Rect; ///< Distortion viewport.
  pixels_per_tan_angle_at_center : Vector2; ///< How many display pixels will fit in tan(angle) = 1.
  hmd_to_eye_pose : OVR_Pose; ///< Transform of eye from the HMD center, in meters.
};

ovr_GetRenderDesc :: (session : OVR_Session, eye_type : OVR_Eye_Type, fov : OVR_Fov_Port) -> OVR_Eye_Render_Desc #foreign LibOVR;

/// Describes layer types that can be passed to ovr_SubmitFrame.
/// Each layer type has an associated struct, such as ovrLayerEyeFov.
///
/// \see ovrLayerHeader
///
OVR_Layer_Type :: enum_flags s32 {
  /// Layer is disabled.
  OVR_LAYER_TYPE_DISABLED :: 0;

  /// Described by ovrLayerEyeFov.
  OVR_LAYER_TYPE_EYE_FOV :: 1;

  /// Described by ovrLayerEyeFovDepth.
  OVR_LAYER_TYPE_EYE_FOV_DEPTH :: 2;

  /// Described by ovrLayerQuad. Previously called ovrLayerType_QuadInWorld.
  OVR_LAYER_TYPE_QUAD :: 3;

  // enum 4 used to be ovrLayerType_QuadHeadLocked. Instead, use ovrLayerType_Quad with
  // ovrLayerFlag_HeadLocked.

  /// Described by ovrLayerEyeMatrix.
  OVR_LAYER_TYPE_EYE_MATRIX :: 5;

  /// Described by ovrLayerEyeFovMultires.
  OVR_LAYER_TYPE_EYE_FOV_MULTIRES :: 7;

  /// Described by ovrLayerCylinder.
  OVR_LAYER_TYPE_CYLINDER :: 8;

  /// Described by ovrLayerCube
  OVR_LAYER_TYPE_CUBE :: 10;
};

/// Defines properties shared by all ovrLayer structs, such as ovrLayerEyeFov.
///
/// ovrLayerHeader is used as a base member in these larger structs.
/// This struct cannot be used by itself except for the case that Type is ovrLayerType_Disabled.
///
/// \see ovrLayerType, ovrLayerFlags
///
OVR_Layer_Header :: struct {
  type : OVR_Layer_Type; ///< Described by ovrLayerType.
  flags : OVR_Layer_Flags; ///< Described by ovrLayerFlags.*/
  reserved : [128] u8;
};

/// Describes a layer that specifies a monoscopic or stereoscopic view.
/// This is the kind of layer that's typically used as layer 0 to ovr_SubmitFrame,
/// as it is the kind of layer used to render a 3D stereoscopic view.
///
/// Three options exist with respect to mono/stereo texture usage:
///    - ColorTexture[0] and ColorTexture[1] contain the left and right stereo renderings,
///      respectively.
///      Viewport[0] and Viewport[1] refer to ColorTexture[0] and ColorTexture[1], respectively.
///    - ColorTexture[0] contains both the left and right renderings, ColorTexture[1] is NULL,
///      and Viewport[0] and Viewport[1] refer to sub-rects with ColorTexture[0].
///    - ColorTexture[0] contains a single monoscopic rendering, and Viewport[0] and
///      Viewport[1] both refer to that rendering.
///
/// \see ovrTextureSwapChain, ovr_SubmitFrame
///
OVR_Layer_Eye_Fov :: struct {
  /// Header.Type must be ovrLayerType_EyeFov.
  header : OVR_Layer_Header;

  /// ovrTextureSwapChains for the left and right eye respectively.
  /// The second one of which can be NULL for cases described above.
  color_texture : [EYE_COUNT] OVR_Texture_Swap_Chain;

  /// Specifies the ColorTexture sub-rect UV coordinates.``
  /// Both Viewport[0] and Viewport[1] must be valid.
  viewport : [EYE_COUNT] OVR_Rect;

  /// The viewport field of view.
  fov : [EYE_COUNT] OVR_Fov_Port;

  /// Specifies the position and orientation of each eye view, with position specified in meters.
  /// RenderPose will typically be the value returned from ovr_CalcEyePoses,
  /// but can be different in special cases if a different head pose is used for rendering.
  render_pose : [EYE_COUNT] OVR_Pose;

  /// Specifies the timestamp when the source ovrPosef (used in calculating RenderPose)
  /// was sampled from the SDK. Typically retrieved by calling ovr_GetTimeInSeconds
  /// around the instant the application calls ovr_GetTrackingState
  /// The main purpose for this is to accurately track app tracking latency.
  sensor_sample_time : float64;
};

ovr_GetPredictedDisplayTime :: (session : OVR_Session, frame_index : s64) -> float64 #foreign LibOVR;

ovr_CalcEyePoses2 :: (head_pose : OVR_Pose, hmd_to_eye_poses : *OVR_Pose, out_eye_poses : *OVR_Pose) -> void #foreign LibOVR;
// this is needed for it render properly in both eyes. I am not sure why atm though.
ovr_CalcEyePoses :: ovr_CalcEyePoses2;

OVR_Session_Status :: struct {
  /// True if the process has VR focus and thus is visible in the HMD.
  is_visible :: bool;

  /// True if an HMD is present.
  hmd_present :: bool;

  /// True if the HMD is on the user's head.
  hmd_mounted :: bool;

  /// True if the session is in a display-lost state. See ovr_SubmitFrame.
  display_lost :: bool;

  /// True if the application should initiate shutdown.
  should_quit :: bool;

  /// True if UX has requested re-centering. Must call ovr_ClearShouldRecenterFlag,
  /// ovr_RecenterTrackingOrigin or ovr_SpecifyTrackingOrigin.
  should_recenter :: bool;

  /// True if the application is the foreground application and receives input (e.g. Touch
  /// controller state). If this is false then the application is in the background (but possibly
  /// still visible) should hide any input representations such as hands.
  has_input_focus :: bool;

  /// True if a system overlay is present, such as a dashboard. In this case the application
  /// (if visible) should pause while still drawing, avoid drawing near-field graphics so they
  /// don't visually fight with the system overlay, and consume fewer CPU and GPU resources.
  /// \deprecated Do not use.
  overlay_present :: bool;

  /// True if runtime is requesting that the application provide depth buffers with projection
  /// layers.
  depth_requested :: bool;
};

ovr_GetSessionStatus :: (session : OVR_Session, session_status : *OVR_Session_Status) -> OVR_Result #foreign LibOVR;
ovr_RecenterTrackingOrigin :: (session : OVR_Session) -> OVR_Result #foreign LibOVR;
ovr_GetTextureSwapChainLength :: (session : OVR_Session, chain: OVR_Texture_Swap_Chain, out_length : *s32) -> OVR_Result #foreign LibOVR;

OVR_Mirror_Texture_Desc :: struct {
  format : OVR_Texture_Format;
  width : s32;
  height : s32;
  misc_flags : u32; ///< ovrTextureFlags
  mirror_options : u32; ///< ovrMirrorOptions
};

ovr_CreateMirrorTextureWithOptionsGL :: (session : OVR_Session, desc : *OVR_Mirror_Texture_Desc, out_mirror_texture : *OVR_Mirror_Texture) -> OVR_Result #foreign LibOVR;
ovr_GetMirrorTextureBufferGL :: (session : OVR_Session, mirror_texture : OVR_Mirror_Texture, out_tex_id : *u32) -> OVR_Result #foreign LibOVR;

/// Specifies the coordinate system ovrTrackingState returns tracking poses in.
/// Used with ovr_SetTrackingOriginType()
OVR_Tracking_Origin :: enum s32 {
  /// \brief Tracking system origin reported at eye (HMD) height
  /// \details Prefer using this origin when your application requires
  /// matching user's current physical head pose to a virtual head pose
  /// without any regards to a the height of the floor. Cockpit-based,
  /// or 3rd-person experiences are ideal candidates.
  /// When used, all poses in ovrTrackingState are reported as an offset
  /// transform from the profile calibrated or recentered HMD pose.
  /// It is recommended that apps using this origin type call ovr_RecenterTrackingOrigin
  /// prior to starting the VR experience, but notify the user before doing so
  /// to make sure the user is in a comfortable pose, facing a comfortable
  /// direction.
  OVR_TRACKING_ORIGIN_EYE_LEVEL :: 0;

  /// \brief Tracking system origin reported at floor height
  /// \details Prefer using this origin when your application requires the
  /// physical floor height to match the virtual floor height, such as
  /// standing experiences.
  /// When used, all poses in ovrTrackingState are reported as an offset
  /// transform from the profile calibrated floor pose. Calling ovr_RecenterTrackingOrigin
  /// will recenter the X & Z axes as well as yaw, but the Y-axis (i.e. height) will continue
  /// to be reported using the floor height as the origin for all poses.
  OVR_TRACKING_ORIGIN_FLOOR_LEVEL :: 1;
};

ovr_SetTrackingOriginType :: (session : OVR_Session, origin : OVR_Tracking_Origin) -> OVR_Result #foreign LibOVR;

/// Projection information for ovrLayerEyeFovDepth.
///
/// Use the utility function ovrTimewarpProjectionDesc_FromProjection to
/// generate this structure from the application's projection matrix.
///
/// \see ovrLayerEyeFovDepth, ovrTimewarpProjectionDesc_FromProjection
///
OVR_Timewarp_Projection_Desc :: struct {
  _22 : float; ///< Projection matrix element [2][2].
  _23 : float; ///< Projection matrix element [2][3].
  _32 : float; ///< Projection matrix element [3][2].
};

OVR_Projection_Modifier :: enum u32 {
  /// Use for generating a default projection matrix that is:
  /// * Right-handed.
  /// * Near depth values stored in the depth buffer are smaller than far depth values.
  /// * Both near and far are explicitly defined.
  /// * With a clipping range that is (0 to w).
  PROJECTION_NONE :: 0x00;

  /// Enable if using left-handed transformations in your application.
  PROJECTION_LEFT_HANDED :: 0x01;

  /// After the projection transform is applied, far values stored in the depth buffer will be less
  /// than closer depth values.
  /// NOTE: Enable only if the application is using a floating-point depth buffer for proper
  /// precision.
  PROJECTION_FAR_LESS_THAN_NEAR :: 0x02;

  /// When this flag is used, the zfar value pushed into ovrMatrix4f_Projection() will be ignored
  /// NOTE: Enable only if ovrProjection_FarLessThanNear is also enabled where the far clipping
  /// plane will be pushed to infinity.
  PROJECTION_FAR_CLIP_AT_INFINITY :: 0x04;

  /// Enable if the application is rendering with OpenGL and expects a projection matrix with a
  /// clipping range of (-w to w).
  /// Ignore this flag if your application already handles the conversion from D3D range (0 to w) to
  /// OpenGL.
  PROJECTION_CLIP_RANGE_OPENGL :: 0x08;
};

ovrTimewarpProjectionDesc_FromProjection :: (projection : Matrix4, projection_mod_flags : OVR_Projection_Modifier) -> OVR_Timewarp_Projection_Desc #foreign LibOVR;

/// Contains the data necessary to properly calculate position info for various layer types.
/// - HmdToEyePose is the same value-pair provided in ovrEyeRenderDesc. Modifying this value is
///   suggested only if the app is forcing monoscopic rendering and requires that all layers
///   including quad layers show up in a monoscopic fashion.
/// - HmdSpaceToWorldScaleInMeters is used to scale player motion into in-application units.
///   In other words, it is how big an in-application unit is in the player's physical meters.
///   For example, if the application uses inches as its units then HmdSpaceToWorldScaleInMeters
///   would be 0.0254.
///   Note that if you are scaling the player in size, this must also scale. So if your application
///   units are inches, but you're shrinking the player to half their normal size, then
///   HmdSpaceToWorldScaleInMeters would be 0.0254*2.0.
///
/// \see ovrEyeRenderDesc, ovr_SubmitFrame
///
OVR_View_Scale_Desc :: struct {
  hmd_to_eye_pose : [EYE_COUNT] OVR_Pose; ///< Transform of each eye from the HMD center, in meters.
  hmd_space_to_world_scale_in_meters : float; ///< Ratio of viewer units to meter units.
};

ovr_WaitToBeginFrame :: (session : OVR_Session, frame_index : s64) -> OVR_Result #foreign LibOVR;
ovr_BeginFrame :: (session : OVR_Session, frame_index : s64) -> OVR_Result #foreign LibOVR;
ovr_EndFrame :: (
    session : OVR_Session,
    frame_index : s64,
    view_scaled_esc : *OVR_View_Scale_Desc,
    layer_ptr_list : **OVR_Layer_Header,
    layer_count : u32) -> OVR_Result #foreign LibOVR;

ovr_GetTextureSwapChainCurrentIndex :: (session : OVR_Session, chain : OVR_Texture_Swap_Chain, out_Index : *s32) -> OVR_Result #foreign LibOVR;
ovrMatrix4f_Projection :: (fov : OVR_Fov_Port, znear : float, zfar : float, projection_mod_flags : OVR_Projection_Modifier) -> Matrix4 #foreign LibOVR;
ovr_CommitTextureSwapChain :: (session : OVR_Session, chain : OVR_Texture_Swap_Chain) -> OVR_Result #foreign LibOVR;

/// Describes a layer that specifies a monoscopic or stereoscopic view,
/// with depth textures in addition to color textures. This is typically used to support
/// positional time warp. This struct is the same as ovrLayerEyeFov, but with the addition
/// of DepthTexture and ProjectionDesc.
///
/// ProjectionDesc can be created using ovrTimewarpProjectionDesc_FromProjection.
///
/// Three options exist with respect to mono/stereo texture usage:
///    - ColorTexture[0] and ColorTexture[1] contain the left and right stereo renderings,
///      respectively.
///      Viewport[0] and Viewport[1] refer to ColorTexture[0] and ColorTexture[1], respectively.
///    - ColorTexture[0] contains both the left and right renderings, ColorTexture[1] is NULL,
///      and Viewport[0] and Viewport[1] refer to sub-rects with ColorTexture[0].
///    - ColorTexture[0] contains a single monoscopic rendering, and Viewport[0] and
///      Viewport[1] both refer to that rendering.
///
/// \see ovrTextureSwapChain, ovr_SubmitFrame
///
OVR_Layer_Eye_Fov_Depth :: struct {
  /// Header.Type must be ovrLayerType_EyeFovDepth.
  using header : OVR_Layer_Header;
  header.type = .OVR_LAYER_TYPE_EYE_FOV_DEPTH;

  /// ovrTextureSwapChains for the left and right eye respectively.
  /// The second one of which can be NULL for cases described above.
  color_texture : [EYE_COUNT] OVR_Texture_Swap_Chain;

  /// Specifies the ColorTexture sub-rect UV coordinates.
  /// Both Viewport[0] and Viewport[1] must be valid.
  viewport : [EYE_COUNT] OVR_Rect;

  /// the viewport field of view.
  fov : [EYE_COUNT] OVR_Fov_Port;

  /// specifies the position and orientation of each eye view, with position specified in meters.
  /// renderpose will typically be the value returned from ovr_calceyeposes,
  /// but can be different in special cases if a different head pose is used for rendering.
  render_pose : [EYE_COUNT] OVR_Pose;

  /// specifies the timestamp when the source ovrposef (used in calculating renderpose)
  /// was sampled from the sdk. typically retrieved by calling ovr_gettimeinseconds
  /// around the instant the application calls ovr_gettrackingstate
  /// the main purpose for this is to accurately track app tracking latency.
  sensor_sample_time : float64;

  /// depth texture for depth composition with overlays
  /// must map 1:1 to the colortexture.
  depth_texture : [EYE_COUNT] OVR_Texture_Swap_Chain;

  /// specifies how to convert depthtexture information into meters.
  /// \see ovrtimewarpprojectiondesc_fromprojection
  projection_desc : OVR_Timewarp_Projection_Desc;
};

OVR_Layer_Flags :: enum u32 {
  /// ovrLayerFlag_HighQuality enables 4x anisotropic sampling during the composition of the layer.
  /// The benefits are mostly visible at the periphery for high-frequency & high-contrast visuals.
  /// For best results consider combining this flag with an ovrTextureSwapChain that has mipmaps and
  /// instead of using arbitrary sized textures, prefer texture sizes that are powers-of-two.
  /// Actual rendered viewport and doesn't necessarily have to fill the whole texture.
  HIGH_QUALITY :: 0x01;

  /// ovrLayerFlag_TextureOriginAtBottomLeft: the opposite is TopLeft.
  /// Generally this is false for D3D, true for OpenGL.
  TEXTURE_ORIGIN_AT_BOTTOM_LEFT :: 0x02;

  /// Mark this surface as "headlocked", which means it is specified
  /// relative to the HMD and moves with it, rather than being specified
  /// relative to sensor/torso space and remaining still while the head moves.
  /// What used to be ovrLayerType_QuadHeadLocked is now ovrLayerType_Quad plus this flag.
  /// However the flag can be applied to any layer type to achieve a similar effect.
  HEAD_LOCKED :: 0x04;
}

/// Specifies which controller is connected; multiple can be connected at once.
OVR_Controller_Type :: enum_flags u32 {
  OVR_CONTROLLER_TYPE_NONE :: 0x0000;
  OVR_CONTROLLER_TYPE_LTOUCH :: 0x0001;
  OVR_CONTROLLER_TYPE_RTOUCH :: 0x0002;
  OVR_CONTROLLER_TYPE_TOUCH :: (OVR_CONTROLLER_TYPE_LTOUCH | OVR_CONTROLLER_TYPE_RTOUCH);
  OVR_CONTROLLER_TYPE_REMOTE :: 0x0004;

  OVR_CONTROLLER_TYPE_XBOX :: 0x0010;

  OVR_CONTROLLER_TYPE_OBJECT0 :: 0x0100;
  OVR_CONTROLLER_TYPE_OBJECT1 :: 0x0200;
  OVR_CONTROLLER_TYPE_OBJECT2 :: 0x0400;
  OVR_CONTROLLER_TYPE_OBJECT3 :: 0x0800;

  OVR_CONTROLLER_TYPE_ACTIVE :: 0xffffffff; ///< Operate on or query whichever controller is active.
};

OVR_Hand_Type :: enum s32 {
    OVR_HAND_LEFT :: 0;
    OVR_HAND_RIGHT :: 1;
}

HAND_COUNT :: #run enum_values_as_s64(OVR_Hand_Type).count;

/// Describes button input types.
/// Button inputs are combined; that is they will be reported as pressed if they are
/// pressed on either one of the two devices.
/// The ovrButton_Up/Down/Left/Right map to both XBox D-Pad and directional buttons.
/// The ovrButton_Enter and ovrButton_Return map to Start and Back controller buttons, respectively.
OVR_Button :: enum_flags u32 {
  /// A button on XBox controllers and right Touch controller. Not present on Oculus Remote.
  OVR_BUTTON_A :: 0X00000001;

  /// B button on XBox controllers and right Touch controller. Not present on Oculus Remote.
  OVR_BUTTON_B :: 0X00000002;

  /// Right thumbstick on XBox controllers and Touch controllers. Not present on Oculus Remote.
  OVR_BUTTON_RTHUMB :: 0x00000004;

  /// Right shoulder button on XBox controllers. Not present on Touch controllers or Oculus Remote.
  OVR_BUTTON_RSHOULDER :: 0x00000008;

  /// X button on XBox controllers and left Touch controller. Not present on Oculus Remote.
  OVR_BUTTON_X :: 0x00000100;

  /// Y button on XBox controllers and left Touch controller. Not present on Oculus Remote.
  OVR_BUTTON_Y :: 0x00000200;

  /// Left thumbstick on XBox controllers and Touch controllers. Not present on Oculus Remote.
  OVR_BUTTON_LTHUMB :: 0x00000400;

  /// Left shoulder button on XBox controllers. Not present on Touch controllers or Oculus Remote.
  OVR_BUTTON_LSHOULDER :: 0x00000800;

  /// Up button on XBox controllers and Oculus Remote. Not present on Touch controllers.
  OVR_BUTTON_UP :: 0x00010000;

  /// Down button on XBox controllers and Oculus Remote. Not present on Touch controllers.
  OVR_BUTTON_DOWN :: 0x00020000;

  /// Left button on XBox controllers and Oculus Remote. Not present on Touch controllers.
  OVR_BUTTON_LEFT :: 0x00040000;

  /// Right button on XBox controllers and Oculus Remote. Not present on Touch controllers.
  OVR_BUTTON_RIGHT :: 0x00080000;

  /// Start on XBox 360 controller. Menu on XBox One controller and Left Touch controller.
  /// Select button on Oculus Remote.
  /// Should be referred to as the Menu button in user-facing documentation.
  OVR_BUTTON_ENTER :: 0x00100000;

  /// Back on Xbox 360 controller and Oculus Remote. View button on XBox One controller.
  /// Not present on Touch controllers.
  OVR_BUTTON_BACK :: 0x00200000;

  /// Volume button on Oculus Remote. Not present on XBox or Touch controllers.
  OVR_BUTTON_VOLUP :: 0x00400000;

  /// Volume button on Oculus Remote. Not present on XBox or Touch controllers.
  OVR_BUTTON_VOLDOWN :: 0x00800000;

  /// Home button on XBox controllers. Oculus button on Touch controllers and Oculus Remote.
  OVR_BUTTON_HOME :: 0x01000000;

  // Bit mask of all buttons that are for private usage by Oculus
  OVR_BUTTON_PRIVATE :: OVR_BUTTON_VOLUP | OVR_BUTTON_VOLDOWN | OVR_BUTTON_HOME;

  // Bit mask of all buttons on the right Touch controller
  OVR_BUTTON_RMASK :: OVR_BUTTON_A | OVR_BUTTON_B | OVR_BUTTON_RTHUMB | OVR_BUTTON_RSHOULDER;

  // Bit mask of all buttons on the left Touch controller
  OVR_BUTTON_LMASK ::
      OVR_BUTTON_X | OVR_BUTTON_Y | OVR_BUTTON_LTHUMB | OVR_BUTTON_LSHOULDER | OVR_BUTTON_ENTER;
};

/// Describes touch input types.
/// These values map to capacitive touch values reported ovrInputState::Touch.
/// Some of these values are mapped to button bits for consistency.
OVR_Touch :: enum_flags u32 {
  OVR_TOUCH_A :: OVR_Button.OVR_BUTTON_A;
  OVR_TOUCH_B :: OVR_Button.OVR_BUTTON_B;
  OVR_TOUCH_RTHUMB :: OVR_Button.OVR_BUTTON_RTHUMB;
  OVR_TOUCH_RTHUMB_REST :: 0x00000008;
  OVR_TOUCH_RINDEX_TRIGGER :: 0x00000010;

  // Bit mask of all the button touches on the right controller
  OVR_TOUCH_RBUTTONMASK ::
      OVR_TOUCH_A | OVR_TOUCH_B | OVR_TOUCH_RTHUMB | OVR_TOUCH_RTHUMB_REST | OVR_TOUCH_RINDEX_TRIGGER;

  OVR_TOUCH_X :: OVR_Button.OVR_BUTTON_X;
  OVR_TOUCH_Y :: OVR_Button.OVR_BUTTON_Y;
  OVR_TOUCH_LTHUMB :: OVR_Button.OVR_BUTTON_LTHUMB;
  OVR_TOUCH_LTHUMB_REST :: 0x00000800;
  OVR_TOUCH_LINDEX_TRIGGER :: 0x00001000;

  // Bit mask of all the button touches on the left controller
  OVR_TOUCH_LBUTTONMASK ::
      OVR_TOUCH_X | OVR_TOUCH_Y | OVR_TOUCH_LTHUMB | OVR_TOUCH_LTHUMB_REST | OVR_TOUCH_LINDEX_TRIGGER;

  // Finger pose state
  // Derived internally based on distance, proximity to sensors and filtering.
  OVR_TOUCH_RINDEX_POINTING :: 0x00000020;
  OVR_TOUCH_RTHUMB_UP :: 0x00000040;
  OVR_TOUCH_LINDEX_POINTING :: 0x00002000;
  OVR_TOUCH_LTHUMB_UP :: 0x00004000;

  // Bit mask of all right controller poses
  OVR_TOUCH_RPOSEMASK :: OVR_TOUCH_RINDEX_POINTING | OVR_TOUCH_RTHUMB_UP;

  // Bit mask of all left controller poses
  OVR_TOUCH_LPOSEMASK :: OVR_TOUCH_LINDEX_POINTING | OVR_TOUCH_LTHUMB_UP;
};

/// ovrInputState describes the complete controller input state, including Oculus Touch,
/// and XBox gamepad. If multiple inputs are connected and used at the same time,
/// their inputs are combined.
OVR_Input_State :: struct {
  /// System type when the controller state was last updated.
  time_in_seconds : float64;

  /// Values for buttons described by ovrButton.
  buttons : OVR_Button;

  /// Touch values for buttons and sensors as described by ovrTouch.
  touches : OVR_Touch;

  /// Left and right finger trigger values (ovrHand_Left and ovrHand_Right), in range 0.0 to 1.0f.
  /// Returns 0 if the value would otherwise be less than 0.1176, for ovrControllerType_XBox.
  /// This has been formally named simply "Trigger". We retain the name IndexTrigger for backwards
  /// code compatibility.
  /// User-facing documentation should refer to it as the Trigger.
  index_trigger : [HAND_COUNT] float;

  /// Left and right hand trigger values (ovrHand_Left and ovrHand_Right), in the range 0.0 to 1.0f.
  /// This has been formally named "Grip Button". We retain the name HandTrigger for backwards code
  /// compatibility.
  /// User-facing documentation should refer to it as the Grip Button or simply Grip.
  hand_trigger : [HAND_COUNT] float;

  /// Horizontal and vertical thumbstick axis values (ovrHand_Left and ovrHand_Right), in the range
  /// of -1.0f to 1.0f.
  /// Returns a deadzone (value 0) per each axis if the value on that axis would otherwise have been
  /// between -.2746 to +.2746, for ovrControllerType_XBox
  thumbstick : [HAND_COUNT] Vector2;

  /// The type of the controller this state is for.
  controller_type : OVR_Controller_Type;

  /// Left and right finger trigger values (ovrHand_Left and ovrHand_Right), in range 0.0 to 1.0f.
  /// Does not apply a deadzone.  Only touch applies a filter.
  /// This has been formally named simply "Trigger". We retain the name IndexTrigger for backwards
  /// code compatibility.
  /// User-facing documentation should refer to it as the Trigger.
  index_trigger_no_deadzone : [HAND_COUNT] float;

  /// Left and right hand trigger values (ovrHand_Left and ovrHand_Right), in the range 0.0 to 1.0f.
  /// Does not apply a deadzone. Only touch applies a filter.
  /// This has been formally named "Grip Button". We retain the name HandTrigger for backwards code
  /// compatibility.
  /// User-facing documentation should refer to it as the Grip Button or simply Grip.
  hand_trigger_no_deadzone : [HAND_COUNT] float;

  /// Horizontal and vertical thumbstick axis values (ovrHand_Left and ovrHand_Right), in the range
  /// -1.0f to 1.0f
  /// Does not apply a deadzone or filter.
  thumbstick_no_deadzone : [HAND_COUNT] Vector2;

  /// Left and right finger trigger values (ovrHand_Left and ovrHand_Right), in range 0.0 to 1.0f.
  /// No deadzone or filter
  /// This has been formally named simply "Trigger". We retain the name IndexTrigger for backwards
  /// code compatibility.
  /// User-facing documentation should refer to it as the Trigger.
  index_trigger_raw : [HAND_COUNT] float;

  /// Left and right hand trigger values (ovrHand_Left and ovrHand_Right), in the range 0.0 to 1.0f.
  /// No deadzone or filter
  /// This has been formally named "Grip Button". We retain the name HandTrigger for backwards code
  /// compatibility.
  /// User-facing documentation should refer to it as the Grip Button or simply Grip.
  hand_trigger_raw : [HAND_COUNT] float;

  /// Horizontal and vertical thumbstick axis values (ovrHand_Left and ovrHand_Right), in the range
  /// -1.0f to 1.0f
  /// No deadzone or filter
  thumbstick_raw : [HAND_COUNT] Vector2;
};

ovr_GetInputState :: (session : OVR_Session, controller_type : OVR_Controller_Type, input_state : *OVR_Input_State) -> OVR_Result #foreign LibOVR;

main :: () {
    // Create window and openGL context
    set_working_directory(path_strip_filename(get_path_of_running_executable()));
    window := create_window(1920, 1080, "Get that gahbage outta here");
    window_width, window_height := Simp.get_render_dimensions(window);
    Simp.set_render_target(window);

    // Create the OVR Session
    params : OVR_Init_Params;
    params.log_callback = ovr_log;

    result := ovr_Initialize(*params);
    assert(ovr_success(result), "Failed to initialize LibOVR");

    session : OVR_Session;
    luid : OVR_Graphics_Luid;

    result = ovr_Create(*session, *luid);
    print("%\n", result);
    assert(ovr_success(result) && session != null, "Failed to create session");

    desc := ovr_GetHmdDesc(session);
    log_print("startup", "Connected Headset: %", desc.type);

/*
    // Configure Stereo settings
    recommended_tex0_size := ovr_GetFovTextureSize(session, .OVR_EYE_LEFT, desc.default_eye_fov[OVR_Eye_Type.OVR_EYE_LEFT], 1.0);
    recommended_tex1_size := ovr_GetFovTextureSize(session, .OVR_EYE_RIGHT, desc.default_eye_fov[OVR_Eye_Type.OVR_EYE_RIGHT], 1.0);
    buffer_size : OVR_Size = .{
        w = recommended_tex0_size.w + recommended_tex1_size.w,
        h = max(recommended_tex0_size.h, recommended_tex1_size.h)
    };

    texture_swap_chain : OVR_Texture_Swap_Chain;
    if xx ovr_CreateTextureSwapChainGL(session, *texture_swap_chain_desc, *texture_swap_chain) == ovr_success {
        // Sample texture access:
        tex_id : u32;
        ovr_GetTextureSwapChainBufferGL(session, texture_swap_chain, 0, *tex_id);
        glBindTexture(GL_TEXTURE_2D, tex_id);
    }

    // Initialize VR structures, filling out description.
    eye_render_desc : [2] OVR_Eye_Render_Desc;
    hmd_to_eye_view_pose : *OVR_Pose;
    eye_render_desc[OVR_Eye_Type.OVR_EYE_LEFT] = ovr_GetRenderDesc(session, .OVR_EYE_LEFT, desc.default_eye_fov[OVR_Eye_Type.OVR_EYE_LEFT]);
    eye_render_desc[OVR_Eye_Type.OVR_EYE_RIGHT] = ovr_GetRenderDesc(session, .OVR_EYE_RIGHT, desc.default_eye_fov[OVR_Eye_Type.OVR_EYE_RIGHT]);
    hmd_to_eye_view_pose[OVR_Eye_Type.OVR_EYE_LEFT] = eye_render_desc[OVR_Eye_Type.OVR_EYE_LEFT].hmd_to_eye_pose;
    hmd_to_eye_view_pose[OVR_Eye_Type.OVR_EYE_RIGHT] = eye_render_desc[OVR_Eye_Type.OVR_EYE_RIGHT].hmd_to_eye_pose;

    // Initialize our single full screen fov layer.
    layer : OVR_Layer_Eye_Fov;
    {
        using layer;
        header.type = OVR_Layer_Type.OVR_Layer_Type_Eye_Fov;
        header.flags = 0;
        color_texture[OVR_Eye_Type.OVR_EYE_LEFT] = texture_swap_chain;
        color_texture[OVR_Eye_Type.OVR_EYE_RIGHT] = texture_swap_chain;
        fov[OVR_Eye_Type.OVR_EYE_LEFT] = eye_render_desc[OVR_Eye_Type.OVR_EYE_LEFT].fov;
        fov[OVR_Eye_Type.OVR_EYE_RIGHT] = eye_render_desc[OVR_Eye_Type.OVR_EYE_RIGHT].fov;
        viewport[OVR_Eye_Type.OVR_EYE_LEFT] = OVR_Rect.{.{}, OVR_Size.{buffer_size.w / 2, buffer_size.h}};
        viewport[OVR_Eye_Type.OVR_EYE_RIGHT] = OVR_Rect.{.{x = buffer_size.w / 2.0}, OVR_Size.{buffer_size.w / 2, buffer_size.h}};
    }

    display_midpoint_seconds : float64 = ovr_GetPredictedDisplayTime(session, 0);
    hmd_state := ovr_GetTrackingState(session, display_midpoint_seconds, true);
    ovr_CalcEyePoses(hmd_state.head_pose.the_pose, *hmd_to_eye_view_pose.position, layer.render_pose.data);

    layers : *OVR_Layer_Header = *layer.header;*/
    session_status : OVR_Session_Status;
    for 0 .. 1 {
        using chain := *eye_texture_chains[it];
        // Get texture size for the eye
        eye_type := cast(OVR_Eye_Type)it;
        ideal_texture_size := ovr_GetFovTextureSize(session, eye_type, desc.default_eye_fov[eye_type], 1);

        texture_swap_chain_desc : OVR_Texture_Swap_Chain_Desc;
        {
            using texture_swap_chain_desc;
            type = .OVR_TEXTURE_2D;
            array_size = 1;
            format = .OVR_FORMAT_R8G8B8A8_UNORM_SRGB;
            width = ideal_texture_size.w;
            height = ideal_texture_size.h;
            mip_levels = 1;
            sample_count = 1;
            static_image = false;
        }

        size = ideal_texture_size; // chain.size

        // Create color buffer swap chain
        {
            result := ovr_CreateTextureSwapChainGL(session, *texture_swap_chain_desc, *color_texture_chain);
            assert(ovr_success(result), "Failed to create texture swap chain for color");

            chain_length : s32;
            ovr_GetTextureSwapChainLength(session, color_texture_chain, *chain_length);
            for 0..chain_length - 1 {
                chain_tex_id : GLuint;
                ovr_GetTextureSwapChainBufferGL(session, color_texture_chain, it, *chain_tex_id);
                glBindTexture(GL_TEXTURE_2D, chain_tex_id);

                glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
                glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
                glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
                glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
            }
        }

        // For depth
        texture_swap_chain_desc.format = .OVR_FORMAT_D32_FLOAT;

        // Create depth buffer swap chain
        {
            result := ovr_CreateTextureSwapChainGL(session, *texture_swap_chain_desc, *depth_texture_chain);
            assert(ovr_success(result), "Failed to create texture swap chain for depth");

            chain_length : s32;
            ovr_GetTextureSwapChainLength(session, depth_texture_chain, *chain_length);
            for 0..chain_length - 1 {
                chain_tex_id : GLuint;
                ovr_GetTextureSwapChainBufferGL(session, depth_texture_chain, it, *chain_tex_id);
                glBindTexture(GL_TEXTURE_2D, chain_tex_id);

                glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
                glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
                glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
                glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
            }
        }
        glGenFramebuffers(1, *fbo);
    }

    // mirror buffer
    window_size : OVR_Size;
    window_size.w = desc.resolution.w / 2;
    window_size.h = desc.resolution.h / 2;

    mirror_texture_desc : OVR_Mirror_Texture_Desc;
    {
        using mirror_texture_desc;
        width = window_size.w;
        height = window_size.h;
        format = .OVR_FORMAT_R8G8B8A8_UNORM_SRGB;
    }
    mirror_texture : OVR_Mirror_Texture;
    result = ovr_CreateMirrorTextureWithOptionsGL(session, *mirror_texture_desc, *mirror_texture);
    assert(ovr_success(result), "Failed to create mirror texture!");

    tex_id : GLuint;
    ovr_GetMirrorTextureBufferGL(session, mirror_texture, *tex_id);

    mirror_fbo : GLuint;
    glGenFramebuffers(1, *mirror_fbo);
    glBindFramebuffer(GL_READ_FRAMEBUFFER, mirror_fbo);
    glFramebufferTexture2D(GL_READ_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, tex_id, 0);
    glFramebufferRenderbuffer(GL_READ_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, 0);
    assert(glCheckFramebufferStatus(GL_FRAMEBUFFER) == GL_FRAMEBUFFER_COMPLETE, "Framebuffer isn't complete!");
    glBindFramebuffer(GL_READ_FRAMEBUFFER, 0);

    #if OS == .WINDOWS {
        Windows :: #import "Windows";
        Windows.SetProcessDPIAware();

        // Windows is very bad at thread-switching by default unless you do this.
        Windows.timeBeginPeriod(1);
        wglSwapIntervalEXT(0);
    } else {
        #assert(false, "Turning off vsync not implemented for non-windows operating systems.");
    }

    tracking_origin_type :: OVR_Tracking_Origin.OVR_TRACKING_ORIGIN_FLOOR_LEVEL;
    ovr_SetTrackingOriginType(session, tracking_origin_type);
    shader := load_shader();

    //left_size := ovr_GetFovTextureSize(session, .OVR_EYE_LEFT, desc.default_eye_fov[OVR_Eye_Type.OVR_EYE_LEFT], 1.0);
    //right_size := ovr_GetFovTextureSize(session, .OVR_EYE_RIGHT, desc.default_eye_fov[OVR_Eye_Type.OVR_EYE_RIGHT], 1.0);
    texture = create_texture("beegYoshi.png");
    texture2 = create_texture("badlands.png");

    glGenVertexArrays(1, *cube_vao);
    glGenBuffers(1, *cube_vbo);
    glBindVertexArray(cube_vao);
    glBindBuffer(GL_ARRAY_BUFFER, cube_vbo);
    glBufferData(GL_ARRAY_BUFFER, cube_vertices.count * size_of(float32), cube_vertices.data, GL_STATIC_DRAW);

    glVertexAttribPointer(0, 3, GL_FLOAT, false, 8 * size_of(float), null);
    glEnableVertexAttribArray(0);
    glVertexAttribPointer(1, 3, GL_FLOAT, false, 8 * size_of(float), xx (3 * size_of(float)));
    glEnableVertexAttribArray(1);
    glVertexAttribPointer(2, 2, GL_FLOAT, false, 8 * size_of(float), xx (6 * size_of(float)));
    glEnableVertexAttribArray(2);

    eye_render_desc : [2] OVR_Eye_Render_Desc;
    eye_render_poses : [2] OVR_Pose;
    hmd_to_eye_poses : [2] OVR_Pose;

    eye_render_desc[0] = ovr_GetRenderDesc(session, .OVR_EYE_LEFT, desc.default_eye_fov[0]);
    eye_render_desc[1] = ovr_GetRenderDesc(session, .OVR_EYE_RIGHT, desc.default_eye_fov[1]);
    hmd_to_eye_poses[0] = eye_render_desc[0].hmd_to_eye_pose;
    hmd_to_eye_poses[1] = eye_render_desc[1].hmd_to_eye_pose;
    initial_hmd_tracking_state := ovr_GetTrackingState(session, ovr_GetPredictedDisplayTime(session, frame_index), false);
    ovr_CalcEyePoses(initial_hmd_tracking_state.head_pose.the_pose, hmd_to_eye_poses.data, eye_render_poses.data);
    box_height := (Vector3.{} + eye_render_poses[1].position).y;

    // Numbers from OculusWorldDemo/Player.cpp
    body_pos := xyz(7.7, 1.7 - 0.15, -1.0);
    body_pose_floor_level := xyz(7.7, 0.0, -1.0);
    body_yaw := 0.0;

    player_pos : Vector3;
    input_state : OVR_Input_State;
    delta_time : float32;
    last_frame : float32;
    fov := 90.0;
    scale_factor := 10.0;
    running := true;
    while running {
        reset_temporary_storage();
        update_window_events();

        for events_this_frame {
            if it.type == .QUIT then running = false;
            if it.type == .KEYBOARD && it.key_pressed && it.key_code == .BACKSPACE then running = false;
        }

        status : OVR_Session_Status;
        result = ovr_GetSessionStatus(session, *status);
        assert(ovr_success(result), "Failed to get session status.");

        frame_time := ovr_GetPredictedDisplayTime(session, frame_index);
        sample_time := ovr_GetTimeInSeconds();
        hmd_tracking_state := ovr_GetTrackingState(session, frame_time, false);

        eye_render_desc[0] = ovr_GetRenderDesc(session, .OVR_EYE_LEFT, desc.default_eye_fov[0]);
        eye_render_desc[1] = ovr_GetRenderDesc(session, .OVR_EYE_RIGHT, desc.default_eye_fov[1]);
        hmd_to_eye_poses[0] = eye_render_desc[0].hmd_to_eye_pose;
        hmd_to_eye_poses[1] = eye_render_desc[1].hmd_to_eye_pose;

        head_pose := hmd_tracking_state.head_pose.the_pose;
        ovr_CalcEyePoses(head_pose, hmd_to_eye_poses.data, eye_render_poses.data);

        timewarp_projection_desc := OVR_Timewarp_Projection_Desc.{};

        current_frame : float32 = xx get_time();
        delta_time = current_frame - last_frame;
        last_frame = current_frame;
        camera_speed := 2 * delta_time;

        // Player movement
        rotation := rotation_matrix(Matrix3, eye_render_poses[OVR_Eye_Type.OVR_EYE_LEFT].orientation);
        final_up := rotation * .{0, 1, 0};
        final_forward := rotation * .{0, 0, -1};

        ovr_GetInputState(session, .OVR_CONTROLLER_TYPE_TOUCH, *input_state);
        if input_state.thumbstick[OVR_Hand_Type.OVR_HAND_LEFT].y > 0.5 {
            player_pos += camera_speed * final_forward;
        }
        if input_state.thumbstick[OVR_Hand_Type.OVR_HAND_LEFT].y < -0.5 {
            player_pos -= camera_speed * final_forward;
        }
        if input_state.thumbstick[OVR_Hand_Type.OVR_HAND_LEFT].x > 0.5 {
            player_pos += normalize_or_z_axis(cross(final_forward, final_up)) * camera_speed;
        }
        if input_state.thumbstick[OVR_Hand_Type.OVR_HAND_LEFT].x < -0.5 {
            player_pos -= normalize_or_z_axis(cross(final_forward, final_up)) * camera_speed;
        }
        // make sure player's y component doesn't get affected by controller thumbstick
        player_pos.y = 0.0;

        result = ovr_WaitToBeginFrame(session, frame_index);
        assert(ovr_success(result), "Failed to wait for frame.");

        result = ovr_BeginFrame(session, frame_index);
        assert(ovr_success(result), "Failed to begin frame.");

        for 0 .. EYE_COUNT - 1 {
            chain := *eye_texture_chains[it];

            color_tex_id : GLuint;
            depth_tex_id : GLuint;
            current_index : s32;

            ovr_GetTextureSwapChainCurrentIndex(session, chain.color_texture_chain, *current_index);
            ovr_GetTextureSwapChainBufferGL(session, chain.color_texture_chain, current_index, *color_tex_id);

            ovr_GetTextureSwapChainCurrentIndex(session, chain.depth_texture_chain, *current_index);
            ovr_GetTextureSwapChainBufferGL(session, chain.depth_texture_chain, current_index, *depth_tex_id);

            glBindFramebuffer(GL_FRAMEBUFFER, fbo);
            glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, color_tex_id, 0);
            glFramebufferTexture2D(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_TEXTURE_2D, depth_tex_id, 0);
            assert(glCheckFramebufferStatus(GL_FRAMEBUFFER) == GL_FRAMEBUFFER_COMPLETE, "Framebuffer isn't complete!");

            glViewport(0, 0, cast(u32) chain.size.w, cast(u32) chain.size.h);

            glEnable(GL_DEPTH_TEST);
            glClearColor(0.2, 0.3, 0.3, 1.0);
            glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
            glEnable(GL_FRAMEBUFFER_SRGB);

            ground_position := Vector3.{};
            model_transform := make_translation_matrix4(ground_position);
            head_transform := make_translation_matrix4(head_pose.position) * rotation_matrix(Matrix4, head_pose.orientation);
            eye_transform := rotation_matrix(Matrix4, eye_render_poses[it].orientation);

            global_transform := head_transform * eye_transform;
            global_rotation := rotation_matrix(Matrix3, head_pose.orientation) * rotation_matrix(Matrix3, eye_render_poses[it].orientation);

            //global_eye_position := (head_transform * make_vector4(eye_render_poses[it].position, 1.0)).xyz;
            //global_eye_forward := global_rotation * Vector3.{0, 0, -1};
            //global_eye_up := global_rotation * Vector3.{0, 1, 0};

            position := ground_position + eye_render_poses[it].position + player_pos;
            rotation := rotation_matrix(Matrix3, eye_render_poses[it].orientation);

            final_up := rotation * .{0, 1, 0};
            final_forward := rotation * .{0, 0, -1};

            view:= make_look_at_matrix(position, position + final_forward, final_up, false);

            projection := ovrMatrix4f_Projection(desc.default_eye_fov[it], 0.2, 1000.0, .PROJECTION_NONE);
            // make_projection_matrix(deg_to_rad(fov), 1920.0/1080.0, 0.2, 1000);
            timewarp_projection_desc = ovrTimewarpProjectionDesc_FromProjection(projection, .PROJECTION_NONE);
            {
                model := make_translation_matrix4(.{0, scale_factor / 2, 0}) * make_scale_matrix4(xyz(scale_factor, scale_factor, scale_factor));
                glUseProgram(shader);
                glUniformMatrix4fv(glGetUniformLocation(shader, "projection"), 1, true, projection.floats.data);
                glUniformMatrix4fv(glGetUniformLocation(shader, "model"), 1, GL_TRUE, model.floats.data);
                glUniformMatrix4fv(glGetUniformLocation(shader, "view"), 1, true, view.floats.data);
                glActiveTexture(GL_TEXTURE0);
                glBindTexture(GL_TEXTURE_2D, texture);
                glBindVertexArray(cube_vao);
                glDrawArrays(GL_TRIANGLES, 0, 36);

                scale_factor2 := 0.1;
                q : Quaternion;
                set_from_axis_and_angle(*q, 1.0, 0.3, 0.5, deg_to_rad(xx (get_time() * 20)));
                m_rotate := rotation_matrix(Matrix4, q);
                model2 := make_translation_matrix4(.{0, box_height, -0.5}) * m_rotate  * make_scale_matrix4(xyz(scale_factor2, scale_factor2, scale_factor2));
                glUniformMatrix4fv(glGetUniformLocation(shader, "model"), 1, GL_TRUE, model2.floats.data);
                glActiveTexture(GL_TEXTURE0);
                glBindTexture(GL_TEXTURE_2D, texture2);
                glBindVertexArray(cube_vao);
                glDrawArrays(GL_TRIANGLES, 0, 36);

                glUseProgram(0);
            }

            for hand : hmd_tracking_state.hand_poses {
                body_pos_in_origin := ifx tracking_origin_type == .OVR_TRACKING_ORIGIN_EYE_LEVEL then body_pos else body_pose_floor_level;
                position2 := hand.the_pose.position + player_pos;
                orientation2 := hand.the_pose.orientation;
                hand_transform := make_translation_matrix4(position2) * rotation_matrix(Matrix4, orientation2);
                //hand_transform := make_translation_matrix4(position2 + body_pos_in_origin) * rotation_matrix(Matrix4, orientation2);
                global_hand_position := (hand_transform * head_transform);

                scale_factor2 := 0.05;
                q : Quaternion;
                set_from_axis_and_angle(*q, 1.0, 0.3, 0.5, deg_to_rad(xx (get_time() * 20)));
                m_rotate := rotation_matrix(Matrix4, orientation2);
                glUseProgram(shader);

               // model2 := global_hand_position;// * m_rotate  * make_scale_matrix4(xyz(scale_factor2, scale_factor2, scale_factor2));
                model2 := hand_transform * m_rotate * make_scale_matrix4(xyz(scale_factor2, scale_factor2, scale_factor2));
                glUniformMatrix4fv(glGetUniformLocation(shader, "model"), 1, GL_TRUE, model2.floats.data);
                glActiveTexture(GL_TEXTURE0);
                glBindTexture(GL_TEXTURE_2D, texture2);
                glBindVertexArray(cube_vao);
                glDrawArrays(GL_TRIANGLES, 0, 36);
                //print("-- Hand pose: \n\tpos: %\n\torientation: %\n", position2, orientation2);
                //print(">> Head pose: \n\t>pos: %\n\t>orientation: %\n", position, rotation);
            }

            glBindFramebuffer(GL_FRAMEBUFFER, fbo);
            glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, 0, 0);
            glFramebufferTexture2D(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_TEXTURE_2D, 0, 0);

            ovr_CommitTextureSwapChain(session, chain.color_texture_chain);
            ovr_CommitTextureSwapChain(session, chain.depth_texture_chain);
        }
/*
        ovr_GetSessionStatus(session, *session_status);
        if session_status.should_recenter {
            ovr_RecenterTrackingOrigin(session);
        }

        if session_status.is_visible {

        }

        if (hmd_tracking_state.status_flags & xx (OVR_Status_Bits.OVR_STATUS_ORIENTATION_TRACKED | .OVR_STATUS_POSITION_TRACKED)) {
            pose := hmd_tracking_state.head_pose.the_pose;
        }
*/
        ld : OVR_Layer_Eye_Fov_Depth;
        //ld.header.type = .OVR_LAYER_TYPE_EYE_FOV_DEPTH;
        ld.header.flags = .TEXTURE_ORIGIN_AT_BOTTOM_LEFT;
        ld.sensor_sample_time = sample_time;
        ld.projection_desc = timewarp_projection_desc;

        for 0 .. EYE_COUNT - 1 {
            ld.color_texture[it] = eye_texture_chains[it].color_texture_chain;
            ld.depth_texture[it] = eye_texture_chains[it].depth_texture_chain;
            viewport := OVR_Rect.{size=eye_texture_chains[it].size};
            ld.viewport[it] = viewport;
            ld.fov[it] = desc.default_eye_fov[it];
            ld.render_pose[it] = eye_render_poses[it];
        }

        layers := *ld.header;
        result = ovr_EndFrame(session, frame_index, null, *layers, 1);
        assert(ovr_success(result), "Failed to end frame.\n");
        frame_index += 1;

        glBindFramebuffer(GL_READ_FRAMEBUFFER, mirror_fbo);
        glBindFramebuffer(GL_DRAW_FRAMEBUFFER, 0); // here 0 represents the default read/draw frame buffer being used.
        w := window_width;
        h := window_height;
        glBlitFramebuffer(0, h, w, 0,
                          0, 0, w, h,
                          GL_COLOR_BUFFER_BIT, GL_NEAREST);
        glBindFramebuffer(GL_READ_FRAMEBUFFER, 0);

        Simp.swap_buffers(window);
    }
    //ovr_Shutdown();
}

create_texture :: (tex_image: string) -> GLuint {
    new_texture : GLuint;
    glGenTextures(1, *new_texture);
    glBindTexture(GL_TEXTURE_2D, new_texture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);

    width, height, nrChannels : s32;
    //stbi_set_flip_vertically_on_load(true);
    data := stbi_load(to_c_string(tprint("../run_tree/textures/%", tex_image)), *width, *height, *nrChannels, 0);
    format : GLenum;
    if nrChannels == 1 {
        format = GL_RED;
    } else if nrChannels == 3 {
        format = GL_RGB;
    } else if nrChannels == 4 {
        format = GL_RGBA;
    }
    if data {
        glTexImage2D(GL_TEXTURE_2D, 0, xx format, xx width, xx height, 0, format, GL_UNSIGNED_BYTE, data);
        glGenerateMipmap(GL_TEXTURE_2D);
    } else {
        print("ERROR: Failed to load texture\n");
    }
    stbi_image_free(data);

    return new_texture;
}


create_shader :: (src : string, type : GLenum) -> u32 {
    shader := glCreateShader(type);
    c_src := to_c_string(src);
    length : GLint = xx strlen(c_src);
    glShaderSource(shader, 1, *c_src, *length);
    glCompileShader(shader);

    status : GLint;
    glGetShaderiv(shader, GL_COMPILE_STATUS, *status);
    if status == 0 {
        len : GLint;
        glGetShaderiv(shader, GL_INFO_LOG_LENGTH, *len);
        buf := cast(*u8) alloc(len);
        glGetShaderInfoLog(shader, xx len, xx *len, buf);
        print("create_shader ERROR in % shader: %\n", type, to_string(buf));
        free(buf);

        glDeleteShader(shader);
    }

    return shader;
}

load_shader :: () -> u32 {
    vs := create_shader(VERTEX_SHADER, GL_VERTEX_SHADER);
    fs := create_shader(FRAGMENT_SHADER, GL_FRAGMENT_SHADER);

    shader := glCreateProgram();

    glAttachShader(shader, vs);
    glAttachShader(shader, fs);

    glLinkProgram(shader);

    status : GLint;
    glGetProgramiv(shader, GL_LINK_STATUS, *status);
    if status == 0 {
        len: GLint;
        glGetProgramiv(shader, GL_INFO_LOG_LENGTH, *len);
        buf := cast(*u8) alloc(len);
        glGetProgramInfoLog(shader, xx len, xx *len, buf);
        print("load_shader ERROR:  %\n", to_string(buf));
        free(buf);

        glDeleteProgram(shader);
        glDeleteShader(vs);
        glDeleteShader(fs);
    }

    glDetachShader(shader, vs);
    glDetachShader(shader, fs);

    glValidateProgram(shader);

    return shader;
}

strlen :: (s: *u8) -> s64 {
    // Return the length of s, a C-style zero-terminated string.
    // If you pass in a pointer that is not zero-terminated,
    // BAD things will happen!
    count: s64 = 0;

    while <<s {
        count += 1;
        s += 1;
    }

    return count;

}

deg_to_rad :: (deg: float) -> float {
    return deg * (PI / 180);
}

VERTEX_SHADER :: #string DONE
#version 330 core

layout (location = 0) in vec3 vertex_position;
layout (location = 1) in vec3 aColor;
layout (location = 2) in vec2 texCoord;

uniform mat4 model;
uniform mat4 projection;
uniform mat4 view;

out vec2 outTexCoord;
out vec3 outColor;

void main()
{
    //normal = mat3(transpose(inverse(model))) * vertex_normal;
    outTexCoord = texCoord;
    outColor = aColor;
    gl_Position = projection * view * model * vec4(vertex_position, 1.0);
}
DONE


FRAGMENT_SHADER :: #string DONE
#version 330 core

uniform sampler2D Texture0;

in vec3 outColor;
in vec2 outTexCoord;

out vec4 FragColor;

void main()
{
    //FragColor = outColor * texture2D(Texture0, outTexCoord);
    FragColor = texture2D(Texture0, vec2(outTexCoord.x, 1 - outTexCoord.y));
}
DONE
