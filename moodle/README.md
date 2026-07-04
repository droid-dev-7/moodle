# Moodle Sandbox 🚀

Entorno Docker para **Moodle 5.2.1** con instalación totalmente automatizada. Ideal para desarrollo, pruebas o sandbox local.

## Requisitos

- [Docker](https://docs.docker.com/engine/install/) v24+
- [Docker Compose](https://docs.docker.com/compose/install/) v2.5+
- ~3 GB de RAM libre

## Uso rápido

```bash
# Iniciar Moodle
docker compose -f Dockerfile-moodle.yaml up -d

# Abrir en el navegador
http://localhost:8080
```

**Usuario:** `admin`  
**Contraseña:** `Moodle_Password123!`

## Servicios

| Servicio | Imagen | Puerto | Descripción |
|----------|--------|--------|-------------|
| **Moodle** | `elestio/moodle:v5.2.1` | `8080:80` | LMS Moodle 5.2.1 |
| **MariaDB** | `mariadb:12.3` | — | Base de datos |

## Plugins preinstalados

| Plugin | Componente | Versión | Propósito |
|--------|-----------|---------|-----------|
| **Level Up XP** | `block_xp` | v20.0 | Gamificación: puntos y niveles |
| **Tiles** | `format_tiles` | v5.1 | Formato de curso por azulejos |
| **Completion Progress** | `block_completion_progress` | — | Barra de progreso visual |
| **Re-engagement** | `mod_reengagement` | — | Alertas automáticas por inactividad |
| **Español Internacional** | `lang/es` | — | Idioma del sitio en español |

## Características técnicas

- ✅ **Instalación desatendida** — Moodle se instala automáticamente vía CLI al primer arranque
- ✅ **Composer** — Dependencias instaladas automáticamente si faltan
- ✅ **UTF-8** — MariaDB configurado con `utf8mb4` desde el arranque
- ✅ **Permisos** — `config.php` con permisos corregidos automáticamente
- ✅ **PHP ini** — `zend.exception_ignore_args=1` para evitar warnings
- ✅ **SSL proxy** — Desactivado para HTTP local
- ✅ **Español** — Idioma por defecto configurado
- ✅ **Sin chown masivo** — Optimizado para evitar lentitud en Windows

## Comandos útiles

```bash
# Ver logs
docker compose -f Dockerfile-moodle.yaml logs -f

# Detener y eliminar datos
docker compose -f Dockerfile-moodle.yaml down -v

# Reconstruir desde cero
docker compose -f Dockerfile-moodle.yaml down -v && docker compose -f Dockerfile-moodle.yaml up -d

# Acceder al contenedor
docker exec -it moodle-sandbox-moodle-1 bash
```

## Estructura de archivos

```
workspaces/
├── Dockerfile-moodle.yaml   # Configuración Docker Compose
├── moodle-install.sh         # Script de instalación automática
└── README.md                 # Este archivo
```
