@tool
class_name AttractionInfoWindow
extends PopupWindow


const ENTITY_URL: String = "https://api.themeparks.wiki/v1/entity/"
const LIVE_DATA_URL_SUFFIX: String = "/live"
const DAILY_DATA_URL_SUFFIX: String = "/history/daily"


@onready var live_data_refresh_timer: Timer = %LiveDataRefreshTimer

@onready var live_http_request: HTTPRequest = %LiveHTTPRequest
@onready var daily_http_request: HTTPRequest = %DailyHTTPRequest

@onready var current_window_status_label: Label = %CurrentWindowStatusLabel
@onready var current_window_status_timer: Timer = %CurrentWindowStatusTimer

@onready var live_data_panel_container: PanelContainer = %LiveDataPanelContainer

@onready var live_data_update_time_label: Label = %LiveDataUpdateTimeLabel

@onready var current_status_label: Label = %CurrentStatusLabel

@onready var queue_time_panel_container: PanelContainer = %QueueTimePanelContainer
@onready var current_queue_time_label: Label = %CurrentQueueTimeLabel

@onready var daily_data_panel_container: PanelContainer = %DailyDataPanelContainer

@onready var operating_minutes_time_label: Label = %OperatingMinutesTimeLabel
@onready var closed_minutes_time_label: Label = %ClosedMinutesTimeLabel
@onready var unknown_minutes_time_label: Label = %UnknownMinutesTimeLabel

@onready var minimum_minutes_time_label: Label = %MinimumMinutesTimeLabel
@onready var maximum_minutes_time_label: Label = %MaximumMinutesTimeLabel
@onready var average_minutes_time_label: Label = %AverageMinutesTimeLabel


var live_data_url: String

var data_loaded: bool = false

var attraction: AttractionID


func _ready() -> void:
	if additional_values.has("Attraction"):
		attraction = additional_values["Attraction"]
		window_name = attraction.name + " - Info"
		
		_start_attraction_data_request()
		live_data_refresh_timer.timeout.connect(live_http_request.request.bind(live_data_url))
		current_window_status_timer.timeout.connect(_current_window_status_update)


func _start_attraction_data_request() -> void:
	var url: String = ENTITY_URL
	url += attraction.id
	
	live_data_url = url + LIVE_DATA_URL_SUFFIX
	var daily_data_url: String = url + DAILY_DATA_URL_SUFFIX
	
	live_http_request.request_completed.connect(_live_data_received)
	live_http_request.request(live_data_url)
	
	daily_http_request.request_completed.connect(_daily_data_received)
	daily_http_request.request(daily_data_url)


func _live_data_received(
	_result: int,
	_response_code: int,
	_headers: PackedStringArray,
	body: PackedByteArray
) -> void:
	# get the data the request returned with
	var json: JSON = JSON.new()
	json.parse(body.get_string_from_utf8())
	var response: Variant = json.data
	
	if not response.has("liveData") or response.liveData.is_empty():
		var error_popup: AcceptDialog = AcceptDialog.new()
		error_popup.title = "Error! Sorry :("
		error_popup.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_SCREEN_WITH_MOUSE_FOCUS
		error_popup.dialog_text = "Could not get the live data for %s, sorry for the inconvenience." %attraction.name
		error_popup.ok_button_text = "I understand."
		error_popup.dialog_autowrap = true
		error_popup.visible = true
		add_child(error_popup)
		return
	
	
	data_loaded = true
	live_data_refresh_timer.start()
	
	live_data_panel_container.show()
	
	
	
	var current_data: Dictionary = response.liveData[0]
	
	if current_data.has("lastUpdated"):
		live_data_update_time_label.text = current_data.lastUpdated.split("T")[1].split(".")[0]
	
	var status: String = ""
	if current_data.has("status"): 
		status = current_data.status if current_data.status else "NOT FOUND"
		current_status_label.text = status
	if not status == "OPERATING":
		queue_time_panel_container.hide()
		return
	else:
		queue_time_panel_container.show()
	
	if current_data.has("queue"):
		current_queue_time_label.text = str(int(current_data.queue.STANDBY.waitTime))
	


func _daily_data_received(
	_result: int,
	_response_code: int,
	_headers: PackedStringArray,
	body: PackedByteArray
) -> void:
	# get the data the request returned with
	var json: JSON = JSON.new()
	json.parse(body.get_string_from_utf8())
	var response: Variant = json.data
	
	if not response.has("days") or response.days.is_empty():
		var error_popup: AcceptDialog = AcceptDialog.new()
		error_popup.title = "Error! Sorry :("
		error_popup.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_SCREEN_WITH_MOUSE_FOCUS
		error_popup.dialog_text = "Could not get the daily data for %s, sorry for the inconvenience." %attraction.name
		error_popup.ok_button_text = "I understand."
		error_popup.dialog_autowrap = true
		error_popup.visible = true
		add_child(error_popup)
		return
	
	data_loaded = true
	
	daily_data_panel_container.show()
	
	
	var current_data: Dictionary = response.days[0]
	
	
	operating_minutes_time_label.text = str(int(current_data.operatingMinutes))
	closed_minutes_time_label.text = str(int(current_data.downMinutes))
	unknown_minutes_time_label.text = str(int(current_data.unknownMinutes))
	
	if current_data.has("standby"):
		minimum_minutes_time_label.text = str(int(current_data.standby.min))
		average_minutes_time_label.text = str(int(current_data.standby.p50))
		maximum_minutes_time_label.text = str(int(current_data.standby.max))






func _current_window_status_update() -> void:
	if data_loaded:
		current_window_status_label.hide()
		return
	
	current_window_status_timer.start()
	
	var vis_char: int = current_window_status_label.visible_characters
	if vis_char >= current_window_status_label.get_total_character_count():
		current_window_status_timer.wait_time = 0.35
		current_window_status_label.visible_characters -= 3
	
	current_window_status_label.visible_characters += 1
	
	
	
