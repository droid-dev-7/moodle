#!/bin/bash
set -e

MOODLEDATA=/var/moodledata
HTML=/var/www/html
CONFIG="$HTML/config.php"

# Instalar dependencias de Composer si faltan
if [ ! -d "$HTML/vendor" ]; then
    echo "[moodle-install] Installing Composer dependencies..."
    cd "$HTML"
    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer >/dev/null 2>&1
    composer install --no-dev --classmap-authoritative 2>&1 | tail -3
    echo "[moodle-install] Composer dependencies installed"
fi

# Corregir permisos del config.php (aunque no exista, por si acaso)
chown www-data:www-data "$CONFIG" "$HTML/public/config.php" 2>/dev/null || true

# Si ya existe config.php, salir
if [ -f "$CONFIG" ]; then
    echo "[moodle-install] config.php already exists, permissions fixed"
    exit 0
fi

echo "[moodle-install] config.php missing, running install"

# Esperar a que la BD esté disponible
echo "[moodle-install] Waiting for database..."
for i in $(seq 1 60); do
    if php -r "try { new PDO('mysql:host=${MOODLE_DATABASE_HOST};port=${MOODLE_DATABASE_PORT_NUMBER}', '${MOODLE_DATABASE_USER}', '${MOODLE_DATABASE_PASSWORD}'); echo 'ready'; } catch(Exception \$e) { }" 2>/dev/null | grep -q ready; then
        echo "[moodle-install] DB ready"
        break
    fi
    sleep 2
done

# Instalar Moodle
php "$HTML/admin/cli/install.php" \
    --agree-license --non-interactive --lang=en \
    --wwwroot="${MOODLE_HOST:-http://localhost:8080}" \
    --dataroot="$MOODLEDATA" \
    --dbtype="${MOODLE_DATABASE_TYPE:-mariadb}" \
    --dbhost="${MOODLE_DATABASE_HOST:-mariadb}" \
    --dbport="${MOODLE_DATABASE_PORT_NUMBER:-3306}" \
    --dbname="${MOODLE_DATABASE_NAME:-moodle}" \
    --dbuser="${MOODLE_DATABASE_USER:-moodle}" \
    --dbpass="${MOODLE_DATABASE_PASSWORD:-moodle_db_password}" \
    --fullname="${MOODLE_SITE_NAME:-Moodle}" \
    --shortname="moodle" --summary="" \
    --adminuser="${MOODLE_USERNAME:-admin}" \
    --adminpass="${MOODLE_PASSWORD:-Moodle_Password123!}" \
    --adminemail="${MOODLE_EMAIL:-admin@example.com}"

echo "[moodle-install] Installation completed successfully"

# Corregir sslproxy para HTTP local
sed -i 's/$CFG->sslproxy = true;/$CFG->sslproxy = false;/' "$CONFIG"
echo "[moodle-install] sslproxy set to false for HTTP"

# Corregir permisos del config.php (creado por root, Apache corre como www-data)
chown www-data:www-data "$CONFIG" "$HTML/public/config.php" 2>/dev/null || true
echo "[moodle-install] config.php permissions fixed"

# Instalar paquetes de idioma adicionales (español internacional)
echo "[moodle-install] Installing language packs..."
php -r "
define('CLI_SCRIPT', true);
require('/var/www/html/public/config.php');
require('/var/www/html/public/lib/setup.php');
require_once('/var/www/html/public/admin/tool/langimport/classes/controller.php');
\$controller = new \tool_langimport\controller();
try {
    \$controller->install_languagepacks(['es']);
    echo '[moodle-install] Spanish language pack installed successfully\n';
    set_config('lang', 'es');
    echo '[moodle-install] Default site language set to Spanish\n';
} catch (Exception \$e) {
    echo '[moodle-install] Language pack error: ' . \$e->getMessage() . '\n';
}
" 2>&1 | grep "\[moodle-install\]"

# Instalar plugins adicionales
echo "[moodle-install] Installing plugins..."

install_plugin() {
    local plugin="$1"
    local target="$2"
    local repo="$3"
    if [ ! -d "$target" ]; then
        echo "[moodle-install] Cloning $plugin..."
        mkdir -p "$(dirname "$target")"
        git clone --depth 1 "$repo" "$target" 2>&1 | tail -1
        echo "[moodle-install] $plugin installed"
    else
        echo "[moodle-install] $plugin already exists, skipping"
    fi
}

install_plugin "block_xp" "$HTML/blocks/xp" "https://github.com/FMCorz/moodle-block_xp.git"
install_plugin "format_tiles" "$HTML/course/format/tiles" "https://bitbucket.org/dw8/moodle-format_tiles.git"
install_plugin "block_completion_progress" "$HTML/blocks/completion_progress" "https://github.com/jonof/moodle-block_completion_progress.git"
install_plugin "mod_reengagement" "$HTML/mod/reengagement" "https://github.com/catalyst/moodle-mod_reengagement.git"

echo "[moodle-install] All plugins cloned, running upgrade..."
php "$HTML/admin/cli/upgrade.php" --non-interactive 2>&1 | tail -5
echo "[moodle-install] Plugin upgrade completed"

# Saltar chown masivo (lentísimo en Windows)
echo "[moodle-install] Skipping recursive chown (not needed)"
