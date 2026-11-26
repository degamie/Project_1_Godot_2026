#WID(26/11/2026)(Sarthak Mittal(DegamieSign)(Forest Renovator))
extends Node3D

@export var wind_speed:float=10.0
@export var wind_time:float=90
func set_wind_speed(wind_speed:float)->void:
	speed_of_wind=wind_speed
func scale_wind_speed(wind_speed:float)->void:
	wind_speed*=1
func increase_wind_speed(wind_speed:float)->void:
	wind_speed+=1
