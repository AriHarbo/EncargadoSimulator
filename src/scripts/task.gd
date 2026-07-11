class_name Task
extends Resource
 
enum Tipo {
	NORMAL,   # Tareas cotidianas visibles para cualquiera
	TURBIA    # Encargos del Don, no se muestran igual en el tablon
}
 
enum Estado {
	PENDIENTE,
	ACTIVA,
	COMPLETADA,
	FALLADA      # Por si el jugador no la completa a tiempo
}
 
# -- Identidad --
@export var id: String = ""             # Identificador unico, ej: "limpiar_hab1"
@export var nombre: String = ""         # Texto visible en el tablon, ej: "Limpiar habitacion 1"
@export var descripcion: String = ""    # Detalle opcional al seleccionar la tarea
@export var tipo: Tipo = Tipo.NORMAL
 
# -- Tiempo --
@export var tiene_limite: bool = false
@export var hora_limite: float = 0.0    # En horas del juego, ej: 6.0 = 6am
 
# -- Activacion --
# Si hora_activacion es 0.0, la tarea empieza disponible desde el inicio del dia
@export var hora_activacion: float = 0.0
 
# -- Recompensa --
@export var dinero: int = 0             # Plata que da al completarla
 
# -- Estado interno (no exportar, se maneja por codigo) --
var estado: Estado = Estado.PENDIENTE
