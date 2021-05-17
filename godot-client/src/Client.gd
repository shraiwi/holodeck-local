extends ARVROrigin


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

enum ClientMode {
	CLIENT_FLAT,
	CLIENT_VR_3DOF,
	CLIENT_VR_6DOF,
};

enum WebXRState {
	WEBXR_STATE_UNINITIALIZED,
	WEBXR_STATE_INITIALIZED,
	WEBXR_STATE_STARTED,
	WEBXR_STATE_FAILED,
	WEBXR_STATE_SUPPORTED,
	WEBXR_STATE_NOT_SUPPORTED,
};

onready var cam = $ARVRCamera;
onready var left_hand = $LeftHand;
onready var right_hand = $RightHand;

var _webxr_interface : WebXRInterface = null;
var _webxr_state : int = WebXRState.WEBXR_STATE_UNINITIALIZED;
var _client_mode : int = ClientMode.CLIENT_FLAT;

signal _webxr_result;

const WEBXR_MAPPING : Dictionary = {
	"session_started":"_on_WebXR_session_started",
	"session_ended":"_on_WebXR_session_ended",
	"session_supported":"_on_WebXR_session_supported",
	"session_failed":"_on_WebXR_session_failed",
};

const WEBXR_FEATURE_MAPPING : Dictionary = {
	"local-floor": ClientMode.CLIENT_VR_3DOF,
	"bounded-floor": ClientMode.CLIENT_VR_6DOF,
	_: ClientMode.CLIENT_FLAT,
};

const WEBXR_REQUESTED_FEATURES = "bounded-floor, local-floor";
const WEBXR_REQUIRED_FEATURES = "local-floor";
const WEBXR_OPTIONAL_FEATURES = "bounded-floor";

func init_client():
	print_debug("starting webxr...");
	
	self._webxr_init();
	
	match self._client_mode:
		ClientMode.CLIENT_FLAT:
			print_debug("flatscreen client")
		_:
			self.get_viewport().arvr = true;
			print_debug("xr client")
			
	
	pass

func _webxr_init():
	self._webxr_interface = ARVRServer.find_interface("WebXR");
	
	if self._webxr_interface and self._webxr_state != WebXRState.WEBXR_STATE_INITIALIZED:
		
		for xrfunc_name in WEBXR_MAPPING.keys():
			var localfunc_name = WEBXR_MAPPING[xrfunc_name];
			self._webxr_interface.connect(xrfunc_name, self, localfunc_name);
		
		self._webxr_interface.is_session_supported("immersive-vr");
		yield(self, "_webxr_result");
		
		if self._webxr_state == WebXRState.WEBXR_STATE_NOT_SUPPORTED:
			self._client_mode = ClientMode.CLIENT_FLAT;
		else:
			self._webxr_interface.requested_reference_space_types = WEBXR_REQUESTED_FEATURES;
			self._webxr_interface.required_features = WEBXR_REQUIRED_FEATURES;
			self._webxr_interface.optional_features = WEBXR_OPTIONAL_FEATURES;
			
			if not self._webxr_interface.initialize():
				self._webxr_state = WebXRState.WEBXR_STATE_FAILED;
			
			yield(self, "_webxr_result");
			
			self._client_mode = WEBXR_FEATURE_MAPPING.get(
				self._webxr_interface.reference_space_type,
				ClientMode.CLIENT_FLAT
			);

func _on_WebXR_session_started(): 
	self._webxr_state = WebXRState.WEBXR_STATE_INITIALIZED;
	self.get_viewport().arvr = true;
	self.emit_signal("_webxr_result");

func _on_WebXR_session_ended(): 
	self._webxr_state = WebXRState.WEBXR_STATE_UNINITIALIZED
	self.get_viewport().arvr = false;
	self.emit_signal("_webxr_result");

func _on_WebXR_session_supported(mode : String, is_supported : bool):
	if mode == "immersive-vr" and is_supported:
		self._webxr_state = WebXRState.WEBXR_STATE_SUPPORTED
	else: 
		self._webxr_state = WebXRState.WEBXR_STATE_NOT_SUPPORTED;
	self.emit_signal("_webxr_result");

func _on_WebXR_session_failed():
	self._webxr_state = self.WebXRState.WEBXR_STATE_FAILED;
	self.emit_signal("_webxr_result");

func get_client_mode() -> int: return self._client_mode;
func get_xr_state() -> int: return self._webxr_state;

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
