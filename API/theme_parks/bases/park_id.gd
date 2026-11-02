class_name ParkID
extends Resource


@export var id: String

@export var name: String
@export var longitude: float
@export var latitude: float

@export var timezone: String
@export var continent: String
@export var zone: String

@export var attractions: Array[AttractionID]

@export var path_data: Array[Array]
