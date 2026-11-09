#WID(9/11/2026)(Sarthak Mittal)(DegamieSign)(Ocean#water#script)
extends MeshInstance3D

@export var wave_cntrl:float=50.0
@export var is_wave_moving:bool=true

func wave_increase_number(wave_cntrl:float,is_wave_moving:bool)->float:
	while(is_wave_moving!=false):
		if(is_wave_moving!=true):wave_cntrl=10
		else: wave_cntrl=0
	
	return wave_cntrl
