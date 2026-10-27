class_name AttractionID
extends Resource
## A resource which contains data about a specific attraction in a theme park.

## The ID used in the API. 
@export var id: String

## The name of the attraction.
@export var name: String
## The longitude of this Attraction.
@export var longitude: float
## The latitude of this Attraction.
@export var latitude: float

## The [ParkID] in which this attraction is located at
@export var parent_park: ParkID
