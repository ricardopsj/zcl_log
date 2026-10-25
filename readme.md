# zcl_log

Wrapper del **Application Log** de SAP (BAL / transacción SLG1) que reduce el manejo de logs a una API de objeto simple: identificar el log, agregar mensajes, grabar, mostrar y consultar su severidad.

```abap
data(ref_log) = new zcl_log( ).
ref_log->set_object( 'ZRPS' ).
ref_log->set_subobject( '1CREAR' ).
ref_log->set_iddoc( 'ID-5' ).                " nº externo (EXTNUMBER)
ref_log->search_or_create( ).                " reutiliza el log si ya existe en BD

ref_log->add_msg( msgid = 'ZMSG' msgty = ref_log->c-msgty-error msgno = '013' msgv1 = lv_matnr ).
ref_log->add_std( ).                         " agrega el mensaje actual de SY-MSG*

ref_log->save( ).
ref_log->display( ).
```

## Instalación

Importar con [abapGit](https://abapgit.org). Requiere ABAP 7.40 o superior.

**Dependencia**: requiere el paquete [`zcl_ce`](https://github.com/ricardopsj/zcl_ce) (las variables de mensaje se normalizan con `zcl_ce=>output_string`). Importar `zcl_ce` primero.

En el sistema deben existir el **objeto y subobjetos de log** (transacción SLG0) que se vayan a usar.

## Objetos del paquete

| Objeto | Tipo | Descripción |
|---|---|---|
| `ZCL_LOG` | Clase | Wrapper del Application Log |
| `ZLOG_DEMO1` | Programa | Demo: crear/reutilizar un log, agregar mensajes de cada severidad, grabar y mostrar |

## API

### Identificación y ciclo de vida

| Método | Descripción |
|---|---|
| `set_object` / `set_subobject` / `set_iddoc` | Definen `OBJECT`, `SUBOBJECT` y `EXTNUMBER` del log (el "iddoc" es el número externo con el que se busca/reutiliza) |
| `create( )` | Crea un log nuevo en memoria (`BAL_LOG_CREATE`) |
| `search( )` | Busca en BD logs con ese object/subobject/extnumber (`BAL_DB_SEARCH`) |
| `load( )` | Carga desde BD el log encontrado y toma su handle (`BAL_DB_LOAD`) |
| `search_or_create( )` | Patrón habitual: si el log ya existe en BD lo carga, si no lo crea. Permite **acumular mensajes de varias ejecuciones en un mismo log** por número externo |
| `refresh( )` | Vacía los mensajes del log en memoria (`BAL_LOG_REFRESH`) y lo vuelve a cargar/crear |

### Mensajes

| Método | Descripción |
|---|---|
| `add_msg( msgid msgno msgty msgv1..4 probclass )` | Agrega un mensaje T100. Las variables pasan por `zcl_ce=>output_string`, así que se les puede pasar **cualquier valor elemental** (fechas, importes, NUMC…) y quedan formateadas. Si no se indica `probclass`, se deriva de la severidad: A/E → muy importante, W → media, I → información adicional, S → importante |
| `add_std( probclass )` | Agrega el mensaje actual del sistema (`SY-MSGID/NO/TY/V1..4`), típico tras un `CALL FUNCTION ... EXCEPTIONS` o un `MESSAGE ... INTO` |
| Constantes `c-msgty-*` | `success`, `information`, `warning`, `error`, `abort` |
| Constantes `c-probclass-*` | Clases de problema BAL (`1`–`4`) |

### Persistencia y visualización

| Método | Descripción |
|---|---|
| `save( )` | Graba todos los logs en BD (`BAL_DB_SAVE` con `I_SAVE_ALL`), aplicando antes `save_prepare( )` |
| `save_prepare( )` | `BAL_DB_SAVE_PREPARE` con las tablas públicas `lt_replace_message` / `lt_replace_context` (permite sustituir variables de mensaje o campos de contexto antes de grabar) |
| `display( show_all )` | Muestra con el perfil estándar de log único (`BAL_DSP_LOG_DISPLAY`) en modalidad grid, con variantes de disposición propias (handle `LOG`). No filtra por handle: muestra **todos los logs cargados en memoria**. El parámetro `show_all` no se usa |

### Estado / severidad

| Método | Descripción |
|---|---|
| `get_stats( )` | Lee la cabecera y estadísticas del log (`BAL_LOG_HDR_READ` → `ls_stats` con contadores por tipo de mensaje) |
| `ok( )` | `abap_true` si el log no tiene errores ni aborts |
| `get_light( )` | Semáforo `ICON_D` según el peor mensaje: abort → breakpoint, error → LED rojo, warning → LED amarillo, info/éxito → LED verde. Útil como columna de estado en un ALV (p. ej. con `zcl_alv`) |

## Notas

- El constructor ejecuta `perform load in program saplsbal` para forzar la carga del grupo de funciones BAL (necesario en sistemas Unicode antes de usar sus módulos).
- [`zcl_bdc`](https://github.com/ricardopsj/zcl_bdc) usa esta clase para registrar los mensajes de `CALL TRANSACTION`. Un log creado sin objeto (`create( )` sin `set_object`) sirve para mostrar mensajes en pantalla; para grabarlo hace falta un objeto de SLG0.
- `s_log`, `lt_log_header` y `ls_stats` son públicos de solo lectura/acceso directo para escenarios avanzados (filtros propios, varios logs).

## Problemas conocidos

- **`probclass` se ignora si se informa.** `add_msg` solo asigna la clase de problema cuando el parámetro viene vacío; si se pasa un valor, el mensaje queda sin clase.
- **Varios logs en la misma sesión.** `display( )` muestra y `save( )` graba todos los logs en memoria, no solo el de la instancia.
- **Errores de los módulos BAL.** Se emiten con `MESSAGE ... TYPE sy-msgty`, lo que puede cancelar un job de fondo.
- **`get_stats( )`** declara un parámetro de retorno `LIGHT` que nunca se asigna; el resultado útil queda en `ls_stats`.
