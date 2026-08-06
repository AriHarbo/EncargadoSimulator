class_name BossCall
extends Resource
 
enum TipoActivacion {
	POR_TIEMPO,  # Se activa cuando llega cierta hora
	POR_TAREA    # Se activa cuando se completa cierta tarea
}
 
# -- Identificacion --
@export var id: String = ""
 
# -- Activacion --
@export var tipo_activacion: TipoActivacion = TipoActivacion.POR_TIEMPO
@export var hora_activacion: float = 0.0       # Solo si tipo es POR_TIEMPO
@export var tarea_activadora: String = ""       # ID de la tarea, solo si tipo es POR_TAREA
 
# -- Dialogo --
# Cada String del array es una linea separada. El jugador aprieta E para avanzar.
@export var lineas: Array[String] = []
 
# -- Tareas que agrega al papel al terminar la llamada --
@export var tareas_a_agregar: Array[String] = []  # IDs de las tareas a activar
 
# -- Estado interno --
var ya_se_activo: bool = false
