#!/usr/bin/env bash
set -Eeuo pipefail

VERSION="2.0.0-menu"
DEVELOPER="godmodule"
IMAGE_NAME="godmodule-pingbypass-1214"
CONTAINER_NAME="pingbypass-server"
MC_VERSION="1.21.4"
FABRIC_API_URL="https://github.com/FabricMC/fabric-api/releases/download/0.113.0+1.21.4/fabric-api-0.113.0+1.21.4.jar"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MC_DATA_DIR="$SCRIPT_DIR/pb-mc-data"
CONFIG_FILE="$SCRIPT_DIR/.pb-config"
LANG_FILE="$SCRIPT_DIR/.pb-lang"
BUILD_DIR="$SCRIPT_DIR/build/libs"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; BLUE='\033[0;34m'; MAGENTA='\033[0;35m'; BOLD='\033[1m'; DIM='\033[2m'; NC='\033[0m'
ok(){ echo -e "${GREEN}[OK]${NC} $*"; }
info(){ echo -e "${CYAN}[INFO]${NC} $*"; }
warn(){ echo -e "${YELLOW}[WARN]${NC} $*"; }
err(){ echo -e "${RED}[ERR]${NC} $*" >&2; }
die(){ err "$*"; exit 1; }
hr(){ echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"; }
trh(){ echo -e "${DIM}──────────────────────────────────────────────────────────────${NC}"; }
pause(){ echo -ne "${DIM}${TXT_PRESS_ENTER}${NC}"; read -r _; }

PRODUCT="pingbypass"

[[ ${EUID:-$(id -u)} -eq 0 ]] || die "Please run with sudo/root. / Lütfen sudo/root ile çalıştır."

PB_PASSWORD=""
HOST_PORT="25565"
PB_BIND_IP="0.0.0.0"
PB_BIND_PORT="25565"
JAVA_MEMORY="2G"
MOD_JAR=""
MC_ALREADY_AUTHED="false"
LANG_CHOICE="en"

ask(){
  local prompt="$1" default="${2:-}" var="$3" secret="${4:-false}" input=""
  if [[ -n "$default" ]]; then
    echo -ne "${BOLD}${prompt}${NC} ${YELLOW}[${default}]${NC}: "
  else
    echo -ne "${BOLD}${prompt}${NC}: "
  fi
  if [[ "$secret" == "true" ]]; then read -rs input; echo; else read -r input; fi
  [[ -z "$input" && -n "$default" ]] && input="$default"
  printf -v "$var" '%s' "$input"
}

set_lang_en(){
TXT_PRESS_ENTER="Press Enter to continue..."
TXT_STATUS="Status"; TXT_RUNNING="RUNNING"; TXT_STOPPED="STOPPED"; TXT_NOT_INSTALLED="NOT INSTALLED"
TXT_MENU_SETUP="Setup / Install"
TXT_MENU_START="Start"
TXT_MENU_STOP="Stop"
TXT_MENU_RESTART="Restart"
TXT_MENU_LOGS="View Logs"
TXT_MENU_INFO="Connection Info"
TXT_MENU_ANTIBOT="AntiBot / NotBot Help"
TXT_MENU_LANGUAGE="Change Language"
TXT_MENU_EXIT="Exit"
TXT_MENU_CHOICE="Choice"
TXT_TITLE="PingBypass Remote Server Manager"
TXT_SUB="Minecraft 1.21.4 Fabric - HeadlessMC"
TXT_PUBLIC_IP="Public IP"; TXT_PUBLIC_PORT="Public Port"; TXT_BIND="Bind"; TXT_IMAGE="Image"; TXT_CONTAINER="Container"; TXT_UPTIME="Uptime"
TXT_ALREADY_RUNNING="Container is already running."; TXT_NOT_RUNNING="Container is not running."; TXT_NOT_INSTALLED2="Server is not installed yet. Run setup first."
TXT_STARTING="Starting container..."; TXT_STOPPING="Stopping container..."; TXT_RESTARTING="Restarting container..."
TXT_LOG_EXIT="Press Ctrl+C to leave logs"; TXT_INVALID="Invalid choice."
TXT_CONFIG_TITLE="Setup Configuration"
TXT_CONFIG_NOTE="Target Minecraft server is NOT configured here. The client-side PingBypass mod chooses the server."
TXT_PROMPT_PASS="PB password"; TXT_PROMPT_HOST_PORT="Public VPS port"; TXT_PROMPT_MEMORY="JVM memory"
TXT_SUMMARY="Summary"; TXT_LOGIN_REQUIRED="Minecraft login required. Device-code flow will open in Docker."; TXT_LOGIN_FOUND="Saved Minecraft login found; relogin skipped."
TXT_FIND_JAR="Searching Fabric mod JAR"; TXT_BUILD_ASSETS="Creating Docker assets"; TXT_BUILD_IMAGE="Building Docker image"; TXT_RUNTIME_CHECK="Runtime check"
TXT_DONE="Setup completed successfully."; TXT_CLIENT_INFO="Client Connection"
TXT_ANTIBOT_TITLE="AntiBot / NotBot.es Helper"
TXT_ANTIBOT_NOTE1="Captcha is NOT solved automatically. Use SSH SOCKS proxy so the verification page sees the VPS IP."
TXT_ANTIBOT_NOTE2="Open one terminal on YOUR PC and run the command below. Keep it open while verifying."
TXT_WIN_HELP="Windows example"; TXT_LINUX_HELP="Linux example"; TXT_BROWSER_HELP="Then open a browser through the SOCKS proxy and visit"
TXT_SETUP_PROMPT="Setup will install/update everything, build Docker image, login to Minecraft and start the container. Continue? (y/n)"
TXT_CANCELLED="Cancelled."; TXT_RELOGIN="Re-login to Minecraft account? (y/n)"; TXT_LANG_SAVED="Language saved."
TXT_CREDIT="Developed by godmodule"; TXT_VIEW_LOGS_IF_FAIL="If something fails, check the logs menu."
TXT_MOD_WARNING="Could not find a clear pingbypass signature in the jar. Continuing because it is a valid Fabric mod."
}

set_lang_tr(){
TXT_PRESS_ENTER="Devam etmek için Enter..."
TXT_STATUS="Durum"; TXT_RUNNING="ÇALIŞIYOR"; TXT_STOPPED="DURDURULDU"; TXT_NOT_INSTALLED="KURULU DEĞİL"
TXT_MENU_SETUP="Kurulum / Yükleme"; TXT_MENU_START="Başlat"; TXT_MENU_STOP="Durdur"; TXT_MENU_RESTART="Yeniden Başlat"; TXT_MENU_LOGS="Logları İzle"; TXT_MENU_INFO="Bağlantı Bilgisi"; TXT_MENU_ANTIBOT="AntiBot / NotBot Yardımı"; TXT_MENU_LANGUAGE="Dili Değiştir"; TXT_MENU_EXIT="Çıkış"; TXT_MENU_CHOICE="Seçim"
TXT_TITLE="PingBypass Remote Server Manager"; TXT_SUB="Minecraft 1.21.4 Fabric - HeadlessMC"
TXT_PUBLIC_IP="Public IP"; TXT_PUBLIC_PORT="Public Port"; TXT_BIND="Bind"; TXT_IMAGE="Image"; TXT_CONTAINER="Konteyner"; TXT_UPTIME="Uptime"
TXT_ALREADY_RUNNING="Konteyner zaten çalışıyor."; TXT_NOT_RUNNING="Konteyner çalışmıyor."; TXT_NOT_INSTALLED2="Sunucu henüz kurulu değil. Önce kurulum yap."
TXT_STARTING="Konteyner başlatılıyor..."; TXT_STOPPING="Konteyner durduruluyor..."; TXT_RESTARTING="Konteyner yeniden başlatılıyor..."
TXT_LOG_EXIT="Loglardan çıkmak için Ctrl+C"; TXT_INVALID="Geçersiz seçim."
TXT_CONFIG_TITLE="Kurulum Ayarları"
TXT_CONFIG_NOTE="Hedef Minecraft sunucusu burada ayarlanmaz. Sunucuyu client tarafındaki PingBypass mod seçer."
TXT_PROMPT_PASS="PB şifresi"; TXT_PROMPT_HOST_PORT="Dışarı açılacak VPS portu"; TXT_PROMPT_MEMORY="JVM bellek"
TXT_SUMMARY="Özet"; TXT_LOGIN_REQUIRED="Minecraft login gerekli. Device-code akışı Docker içinde açılacak."; TXT_LOGIN_FOUND="Kayıtlı Minecraft girişi bulundu; tekrar login atlanacak."
TXT_FIND_JAR="Fabric mod JAR aranıyor"; TXT_BUILD_ASSETS="Docker dosyaları oluşturuluyor"; TXT_BUILD_IMAGE="Docker image build ediliyor"; TXT_RUNTIME_CHECK="Çalışma zamanı kontrolü"
TXT_DONE="Kurulum başarıyla tamamlandı."; TXT_CLIENT_INFO="Client Bağlantısı"
TXT_ANTIBOT_TITLE="AntiBot / NotBot.es Yardımcısı"
TXT_ANTIBOT_NOTE1="Captcha otomatik çözülmez. Doğrulama sayfasının VPS IP'sini görmesi için SSH SOCKS proxy kullan."
TXT_ANTIBOT_NOTE2="KENDİ bilgisayarında bir terminal aç ve aşağıdaki komutu çalıştır. Doğrulama bitene kadar açık kalsın."
TXT_WIN_HELP="Windows örneği"; TXT_LINUX_HELP="Linux örneği"; TXT_BROWSER_HELP="Sonra tarayıcıyı SOCKS proxy ile açıp şu siteleri ziyaret et"
TXT_SETUP_PROMPT="Kurulum; her şeyi kurar/günceller, Docker image build eder, Minecraft login yaptırır ve konteyneri başlatır. Devam? (e/h)"
TXT_CANCELLED="İptal edildi."; TXT_RELOGIN="Minecraft hesabına tekrar giriş yapılsın mı? (e/h)"; TXT_LANG_SAVED="Dil kaydedildi."
TXT_CREDIT="Developed by godmodule"; TXT_VIEW_LOGS_IF_FAIL="Bir şey ters giderse Loglar menüsünden bak."
TXT_MOD_WARNING="Jar içinde net pingbypass izi bulunamadı. Geçerli bir Fabric mod olduğu için devam ediliyor."
}

set_lang_de(){
TXT_PRESS_ENTER="Zum Fortfahren Enter drücken..."
TXT_STATUS="Status"; TXT_RUNNING="LÄUFT"; TXT_STOPPED="GESTOPPT"; TXT_NOT_INSTALLED="NICHT INSTALLIERT"
TXT_MENU_SETUP="Setup / Installation"; TXT_MENU_START="Starten"; TXT_MENU_STOP="Stoppen"; TXT_MENU_RESTART="Neustart"; TXT_MENU_LOGS="Logs ansehen"; TXT_MENU_INFO="Verbindungsinfo"; TXT_MENU_ANTIBOT="AntiBot / NotBot Hilfe"; TXT_MENU_LANGUAGE="Sprache ändern"; TXT_MENU_EXIT="Beenden"; TXT_MENU_CHOICE="Auswahl"
TXT_TITLE="PingBypass Remote Server Manager"; TXT_SUB="Minecraft 1.21.4 Fabric - HeadlessMC"
TXT_PUBLIC_IP="Öffentliche IP"; TXT_PUBLIC_PORT="Öffentlicher Port"; TXT_BIND="Bind"; TXT_IMAGE="Image"; TXT_CONTAINER="Container"; TXT_UPTIME="Uptime"
TXT_ALREADY_RUNNING="Container läuft bereits."; TXT_NOT_RUNNING="Container läuft nicht."; TXT_NOT_INSTALLED2="Server ist noch nicht installiert. Bitte zuerst Setup ausführen."
TXT_STARTING="Container wird gestartet..."; TXT_STOPPING="Container wird gestoppt..."; TXT_RESTARTING="Container wird neu gestartet..."
TXT_LOG_EXIT="Mit Ctrl+C Logs verlassen"; TXT_INVALID="Ungültige Auswahl."
TXT_CONFIG_TITLE="Setup-Konfiguration"
TXT_CONFIG_NOTE="Der Ziel-Minecraft-Server wird hier NICHT gesetzt. Der clientseitige PingBypass-Mod wählt den Server."
TXT_PROMPT_PASS="PB Passwort"; TXT_PROMPT_HOST_PORT="Öffentlicher VPS-Port"; TXT_PROMPT_MEMORY="JVM Speicher"
TXT_SUMMARY="Zusammenfassung"; TXT_LOGIN_REQUIRED="Minecraft-Login erforderlich. Der Device-Code-Flow wird in Docker geöffnet."; TXT_LOGIN_FOUND="Gespeichertes Minecraft-Login gefunden; erneutes Login wird übersprungen."
TXT_FIND_JAR="Fabric Mod-JAR wird gesucht"; TXT_BUILD_ASSETS="Docker-Dateien werden erstellt"; TXT_BUILD_IMAGE="Docker-Image wird gebaut"; TXT_RUNTIME_CHECK="Laufzeitprüfung"
TXT_DONE="Setup erfolgreich abgeschlossen."; TXT_CLIENT_INFO="Client-Verbindung"
TXT_ANTIBOT_TITLE="AntiBot / NotBot.es Hilfe"
TXT_ANTIBOT_NOTE1="Captcha wird NICHT automatisch gelöst. Nutze einen SSH-SOCKS-Proxy, damit die Verifizierungsseite die VPS-IP sieht."
TXT_ANTIBOT_NOTE2="Öffne auf DEINEM PC ein Terminal und führe den folgenden Befehl aus. Lass ihn während der Verifizierung offen."
TXT_WIN_HELP="Windows Beispiel"; TXT_LINUX_HELP="Linux Beispiel"; TXT_BROWSER_HELP="Öffne danach den Browser über den SOCKS-Proxy und besuche"
TXT_SETUP_PROMPT="Setup installiert/aktualisiert alles, baut das Docker-Image, führt Minecraft-Login aus und startet den Container. Fortfahren? (j/n)"
TXT_CANCELLED="Abgebrochen."; TXT_RELOGIN="Minecraft-Konto erneut anmelden? (j/n)"; TXT_LANG_SAVED="Sprache gespeichert."
TXT_CREDIT="Developed by godmodule"; TXT_VIEW_LOGS_IF_FAIL="Wenn etwas fehlschlägt, prüfe das Logs-Menü."
TXT_MOD_WARNING="Keine eindeutige PingBypass-Signatur im JAR gefunden. Da es ein gültiger Fabric-Mod ist, wird fortgefahren."
}

set_lang_ru(){
TXT_PRESS_ENTER="Нажмите Enter для продолжения..."
TXT_STATUS="Статус"; TXT_RUNNING="ЗАПУЩЕН"; TXT_STOPPED="ОСТАНОВЛЕН"; TXT_NOT_INSTALLED="НЕ УСТАНОВЛЕН"
TXT_MENU_SETUP="Установка / Настройка"; TXT_MENU_START="Запустить"; TXT_MENU_STOP="Остановить"; TXT_MENU_RESTART="Перезапустить"; TXT_MENU_LOGS="Смотреть логи"; TXT_MENU_INFO="Информация о подключении"; TXT_MENU_ANTIBOT="Помощь AntiBot / NotBot"; TXT_MENU_LANGUAGE="Сменить язык"; TXT_MENU_EXIT="Выход"; TXT_MENU_CHOICE="Выбор"
TXT_TITLE="PingBypass Remote Server Manager"; TXT_SUB="Minecraft 1.21.4 Fabric - HeadlessMC"
TXT_PUBLIC_IP="Публичный IP"; TXT_PUBLIC_PORT="Публичный порт"; TXT_BIND="Bind"; TXT_IMAGE="Image"; TXT_CONTAINER="Контейнер"; TXT_UPTIME="Время работы"
TXT_ALREADY_RUNNING="Контейнер уже запущен."; TXT_NOT_RUNNING="Контейнер не запущен."; TXT_NOT_INSTALLED2="Сервер ещё не установлен. Сначала запустите установку."
TXT_STARTING="Запуск контейнера..."; TXT_STOPPING="Остановка контейнера..."; TXT_RESTARTING="Перезапуск контейнера..."
TXT_LOG_EXIT="Нажмите Ctrl+C, чтобы выйти из логов"; TXT_INVALID="Неверный выбор."
TXT_CONFIG_TITLE="Конфигурация установки"
TXT_CONFIG_NOTE="Целевой Minecraft-сервер здесь НЕ задаётся. Его выбирает клиентский мод PingBypass."
TXT_PROMPT_PASS="PB пароль"; TXT_PROMPT_HOST_PORT="Публичный порт VPS"; TXT_PROMPT_MEMORY="JVM память"
TXT_SUMMARY="Сводка"; TXT_LOGIN_REQUIRED="Требуется вход в Minecraft. В Docker откроется device-code авторизация."; TXT_LOGIN_FOUND="Найден сохранённый вход Minecraft; повторный вход пропущен."
TXT_FIND_JAR="Поиск Fabric mod JAR"; TXT_BUILD_ASSETS="Создание Docker-файлов"; TXT_BUILD_IMAGE="Сборка Docker image"; TXT_RUNTIME_CHECK="Проверка запуска"
TXT_DONE="Установка успешно завершена."; TXT_CLIENT_INFO="Подключение клиента"
TXT_ANTIBOT_TITLE="Помощь AntiBot / NotBot.es"
TXT_ANTIBOT_NOTE1="Captcha НЕ решается автоматически. Используйте SSH SOCKS proxy, чтобы страница верификации видела IP VPS."
TXT_ANTIBOT_NOTE2="Откройте терминал на ВАШЕМ ПК и выполните команду ниже. Держите окно открытым во время проверки."
TXT_WIN_HELP="Пример для Windows"; TXT_LINUX_HELP="Пример для Linux"; TXT_BROWSER_HELP="После этого откройте браузер через SOCKS proxy и перейдите на"
TXT_SETUP_PROMPT="Установка установит/обновит всё, соберёт Docker image, выполнит вход Minecraft и запустит контейнер. Продолжить? (д/н)"
TXT_CANCELLED="Отменено."; TXT_RELOGIN="Повторно войти в аккаунт Minecraft? (д/н)"; TXT_LANG_SAVED="Язык сохранён."
TXT_CREDIT="Developed by godmodule"; TXT_VIEW_LOGS_IF_FAIL="Если что-то не так, откройте меню логов."
TXT_MOD_WARNING="Чёткая сигнатура pingbypass в jar не найдена. Продолжаем, так как это корректный Fabric mod."
}

apply_lang(){ case "$LANG_CHOICE" in tr) set_lang_tr ;; de) set_lang_de ;; ru) set_lang_ru ;; *) LANG_CHOICE="en"; set_lang_en ;; esac; }
choose_language(){
  clear || true; hr
  echo -e "${BOLD}Select Language / Dil Seç / Sprache wählen / Выберите язык${NC}"
  trh
  echo "  1) English"; echo "  2) Türkçe"; echo "  3) Deutsch"; echo "  4) Русский"; echo
  echo -ne "  Choice [1-4, default 1]: "
  local c; read -r c
  case "${c:-1}" in 2) LANG_CHOICE="tr" ;; 3) LANG_CHOICE="de" ;; 4) LANG_CHOICE="ru" ;; *) LANG_CHOICE="en" ;; esac
  printf '%s' "$LANG_CHOICE" > "$LANG_FILE"
  apply_lang; info "$TXT_LANG_SAVED"; sleep 1
}
load_language(){ [[ -f "$LANG_FILE" ]] && LANG_CHOICE="$(cat "$LANG_FILE" 2>/dev/null || echo en)"; apply_lang; [[ -f "$LANG_FILE" ]] || choose_language; }

load_config(){
  if [[ -f "$CONFIG_FILE" ]]; then
    source "$CONFIG_FILE" || true
    [[ -n "${PB_PASS_ENC:-}" ]] && PB_PASSWORD="$(printf '%s' "$PB_PASS_ENC" | base64 -d 2>/dev/null || true)"
    HOST_PORT="${HOST_PORT:-25565}"; JAVA_MEMORY="${JAVA_MEMORY:-2G}"
  fi
}
save_config(){
  local enc; enc="$(printf '%s' "$PB_PASSWORD" | base64 -w0 2>/dev/null || printf '%s' "$PB_PASSWORD" | base64)"
  cat > "$CONFIG_FILE" <<CFG
PB_PASS_ENC='$enc'
HOST_PORT='$HOST_PORT'
JAVA_MEMORY='$JAVA_MEMORY'
CFG
  chmod 600 "$CONFIG_FILE" 2>/dev/null || true
}
public_ip(){ curl -fsS --max-time 4 https://api.ipify.org 2>/dev/null || hostname -I 2>/dev/null | awk '{print $1}' || echo "?"; }
server_status(){ if docker ps --format '{{.Names}}' 2>/dev/null | grep -qx "$CONTAINER_NAME"; then echo running; elif docker ps -a --format '{{.Names}}' 2>/dev/null | grep -qx "$CONTAINER_NAME"; then echo stopped; else echo none; fi; }
container_uptime(){ docker inspect "$CONTAINER_NAME" --format '{{.State.StartedAt}}' 2>/dev/null | xargs -I{} bash -lc 's=$(date -d "{}" +%s 2>/dev/null || echo 0); n=$(date +%s); echo $(((n-s)/60)) min' 2>/dev/null || echo "?"; }

check_tools(){
  hr; info "Docker / tools"
  if ! command -v docker >/dev/null 2>&1; then
    warn "Docker missing. Attempting automatic install for Debian/Ubuntu..."
    if command -v apt-get >/dev/null 2>&1; then
      apt-get update -qq; apt-get install -y -qq curl ca-certificates gnupg wget unzip; curl -fsSL https://get.docker.com | sh; systemctl enable --now docker >/dev/null 2>&1 || service docker start >/dev/null 2>&1 || true
    else die "Docker not found and auto-install only supports apt based systems."; fi
  fi
  if ! docker info >/dev/null 2>&1; then systemctl start docker >/dev/null 2>&1 || service docker start >/dev/null 2>&1 || true; sleep 2; docker info >/dev/null 2>&1 || die "Docker daemon is not running."; fi
  ok "$(docker --version | head -1)"
  for t in unzip awk grep sed find base64; do command -v "$t" >/dev/null 2>&1 || die "Missing tool: $t"; done
  if ! command -v curl >/dev/null 2>&1 && ! command -v wget >/dev/null 2>&1; then die "curl or wget required."; fi
}

collect_config(){
  load_config; hr; echo -e "${BOLD}${TXT_CONFIG_TITLE}${NC}"; echo -e "${DIM}${TXT_CONFIG_NOTE}${NC}"; echo
  ask "$TXT_PROMPT_PASS" "$PB_PASSWORD" PB_PASSWORD true; [[ -n "$PB_PASSWORD" ]] || die "Password cannot be empty."
  if [[ "$PB_PASSWORD" =~ [[:space:]=#!\\] ]]; then die "Password must not contain spaces, =, #, ! or backslash."; fi
  ask "$TXT_PROMPT_HOST_PORT" "$HOST_PORT" HOST_PORT; [[ "$HOST_PORT" =~ ^[0-9]+$ ]] && (( HOST_PORT>=1 && HOST_PORT<=65535 )) || die "Invalid port."
  ask "$TXT_PROMPT_MEMORY" "$JAVA_MEMORY" JAVA_MEMORY; [[ "$JAVA_MEMORY" =~ ^[0-9]+[GgMm]$ ]] || die "Example values: 2G, 4096M"
  save_config
  if [[ -f "$MC_DATA_DIR/accounts.json" ]] && grep -q refreshToken "$MC_DATA_DIR/accounts.json" 2>/dev/null; then MC_ALREADY_AUTHED="true"; ok "$TXT_LOGIN_FOUND"; echo -ne "${BOLD}${TXT_RELOGIN}${NC} "; local relog; read -r relog; case "${relog,,}" in y|e|j|д) MC_ALREADY_AUTHED="false" ;; esac; else MC_ALREADY_AUTHED="false"; warn "$TXT_LOGIN_REQUIRED"; fi
  echo; echo -e "${BOLD}${TXT_SUMMARY}${NC}"; echo "  PB mode      : server"; echo "  ${TXT_BIND}         : ${PB_BIND_IP}:${PB_BIND_PORT}"; echo "  ${TXT_PUBLIC_PORT}  : ${HOST_PORT}"; echo "  JVM          : ${JAVA_MEMORY}"; echo "  Minecraft    : ${MC_VERSION} Fabric"; echo
  echo -ne "${BOLD}${TXT_SETUP_PROMPT}${NC} "; local ans; read -r ans; case "${ans,,}" in n|h|н) info "$TXT_CANCELLED"; return 1 ;; esac; return 0
}
jar_has_entry(){ unzip -l "$1" "$2" >/dev/null 2>&1; }
jar_contains_text(){ local jar="$1" text="$2" tmp; tmp="$(mktemp -d)"; unzip -q "$jar" -d "$tmp" 2>/dev/null || { rm -rf "$tmp"; return 1; }; grep -RIl --exclude='*.class' "$text" "$tmp" >/dev/null 2>&1 || grep -RI "$text" "$tmp" >/dev/null 2>&1; local rc=$?; rm -rf "$tmp"; return $rc; }
find_mod_jar(){
  hr; info "$TXT_FIND_JAR"; mkdir -p "$BUILD_DIR"
  local candidates=() valid=() f choice
  while IFS= read -r -d '' f; do candidates+=("$f"); done < <(find "$SCRIPT_DIR" -maxdepth 4 -type f -name '*.jar' ! -name '*-sources.jar' ! -name '*-javadoc.jar' ! -path '*/.gradle/*' ! -path '*/pb-mc-data/*' -print0 2>/dev/null)
  for f in "${candidates[@]:-}"; do jar_has_entry "$f" 'fabric.mod.json' && valid+=("$f"); done
  if (( ${#valid[@]} == 0 )); then echo -ne "${YELLOW}Fabric mod JAR path:${NC} "; read -r MOD_JAR; [[ -f "$MOD_JAR" ]] || die "JAR not found."; jar_has_entry "$MOD_JAR" 'fabric.mod.json' || die "Selected JAR is not a Fabric mod.";
  elif (( ${#valid[@]} == 1 )); then MOD_JAR="${valid[0]}";
  else echo "Fabric mod JARs found:"; local i=1; for f in "${valid[@]}"; do echo "  $i) $f"; ((i++)); done; echo -ne "Choice [1]: "; read -r choice; choice="${choice:-1}"; [[ "$choice" =~ ^[0-9]+$ ]] && (( choice>=1 && choice<=${#valid[@]} )) || die "Invalid selection."; MOD_JAR="${valid[$((choice-1))]}"; fi
  if jar_contains_text "$MOD_JAR" 'pingbypass' || jar_contains_text "$MOD_JAR" 'pb.server'; then ok "PingBypass signature found: $MOD_JAR"; else warn "$TXT_MOD_WARNING"; fi
  cp -f "$MOD_JAR" "$BUILD_DIR/astera.jar"; ok "JAR prepared at build/libs/astera.jar"
}

write_assets(){
  hr; info "$TXT_BUILD_ASSETS"; mkdir -p "$SCRIPT_DIR/docker" "$BUILD_DIR"
  cat > "$SCRIPT_DIR/docker/start.sh" <<'STARTSH'
#!/usr/bin/env bash
set -Eeuo pipefail
MC_DIR="/root/.minecraft"
HMC_DIR="/headlessmc/HeadlessMC"
PB_BIND_IP="${PB_BIND_IP:-0.0.0.0}"
PB_BIND_PORT="${PB_BIND_PORT:-25565}"
PB_PASSWORD="${PB_PASSWORD:-}"
JAVA_MEMORY="${JAVA_MEMORY:-2G}"
mkdir -p "$MC_DIR/mods" "$MC_DIR/euclient" "$HMC_DIR"
cp -f /mc-stash/astera.jar "$MC_DIR/mods/astera.jar"
cp -f /mc-stash/fabric-api.jar "$MC_DIR/mods/fabric-api.jar"
cat > "$MC_DIR/euclient/pingbypass.properties" <<EOPB
pb.server=true
pb.ip=${PB_BIND_IP}
pb.port=${PB_BIND_PORT}
pb.password=${PB_PASSWORD}
EOPB
cat > "$MC_DIR/options.txt" <<EOOPT
pauseOnLostFocus:false
onboardAccessibility:false
narrator:0
soundCategory_master:0.0
soundCategory_music:0.0
soundCategory_record:0.0
soundCategory_weather:0.0
soundCategory_block:0.0
soundCategory_hostile:0.0
soundCategory_neutral:0.0
soundCategory_player:0.0
soundCategory_ambient:0.0
soundCategory_voice:0.0
renderDistance:4
simulationDistance:4
EOOPT
JVM_ARGS="-Xmx${JAVA_MEMORY} -Xms${JAVA_MEMORY}"
JVM_ARGS="$JVM_ARGS -Djava.awt.headless=true -Dheadlessmc.lwjgl.stubs=true -Dhmc.jline.enabled=false"
JVM_ARGS="$JVM_ARGS -Dpb.server=true -Dpb.ip=${PB_BIND_IP} -Dpb.port=${PB_BIND_PORT} -Dpb.password=${PB_PASSWORD}"
cat > /headlessmc/config.properties <<EOC
hmc.always.lwjgl.flag=true
hmc.assets.dummy=true
hmc.mcdir=${MC_DIR}
hmc.gamedir=${MC_DIR}
hmc.jline.enabled=false
hmc.commandline=false
hmc.jvmargs=${JVM_ARGS}
EOC
export HMC_JLINE_ENABLED=false
if [[ $# -gt 0 ]]; then exec hmc "$@"; fi
echo "[PB] Starting Minecraft Fabric PingBypass server mode"
echo "[PB] Bind: ${PB_BIND_IP}:${PB_BIND_PORT}"
ls -la "$MC_DIR/mods" || true
sed 's/^pb.password=.*/pb.password=********/' "$MC_DIR/euclient/pingbypass.properties" || true
exec hmc launch fabric:1.21.4 -lwjgl -paulscode --jvm "$JVM_ARGS"
STARTSH
  chmod +x "$SCRIPT_DIR/docker/start.sh"
  cat > "$SCRIPT_DIR/Dockerfile" <<EOF2
FROM 3arthqu4ke/headlessmc:latest
WORKDIR /headlessmc
USER root
RUN set -eux; \
    if command -v apt-get >/dev/null 2>&1; then \
      apt-get update; \
      apt-get install -y --no-install-recommends ca-certificates curl unzip libopenal1 libflite1; \
      rm -rf /var/lib/apt/lists/*; \
    fi
RUN mkdir -p /root/.minecraft/mods /root/.minecraft/euclient /mc-stash /headlessmc/HeadlessMC && \
    printf 'hmc.always.lwjgl.flag=true\nhmc.assets.dummy=true\nhmc.mcdir=/root/.minecraft\nhmc.gamedir=/root/.minecraft\nhmc.jline.enabled=false\nhmc.commandline=false\n' > /headlessmc/config.properties
RUN hmc download ${MC_VERSION} && hmc fabric ${MC_VERSION}
RUN curl -fsSL -o /root/.minecraft/mods/fabric-api.jar "${FABRIC_API_URL}"
COPY build/libs/astera.jar /root/.minecraft/mods/astera.jar
COPY docker/start.sh /start.sh
RUN cp /root/.minecraft/mods/astera.jar /mc-stash/astera.jar && \
    cp /root/.minecraft/mods/fabric-api.jar /mc-stash/fabric-api.jar && \
    chmod +x /start.sh
EXPOSE ${PB_BIND_PORT}
ENTRYPOINT ["/start.sh"]
EOF2
}
build_image(){ hr; info "$TXT_BUILD_IMAGE"; docker rmi "$IMAGE_NAME" >/dev/null 2>&1 || true; docker build --no-cache -t "$IMAGE_NAME" "$SCRIPT_DIR"; ok "Image ready: $IMAGE_NAME"; }
setup_login(){ mkdir -p "$MC_DATA_DIR"; [[ "$MC_ALREADY_AUTHED" == "true" ]] && return 0; hr; info "Minecraft Microsoft login"; docker run --rm -it -v "$MC_DATA_DIR:/headlessmc/HeadlessMC" "$IMAGE_NAME" login; ok "Login done."; }
run_container(){ hr; info "Starting container"; docker rm -f "$CONTAINER_NAME" >/dev/null 2>&1 || true; mkdir -p "$MC_DATA_DIR"; docker run -d --name "$CONTAINER_NAME" --restart unless-stopped -p "${HOST_PORT}:${PB_BIND_PORT}" -e "PB_PASSWORD=${PB_PASSWORD}" -e "PB_BIND_IP=${PB_BIND_IP}" -e "PB_BIND_PORT=${PB_BIND_PORT}" -e "JAVA_MEMORY=${JAVA_MEMORY}" -e "MC_VERSION=${MC_VERSION}" -v "$MC_DATA_DIR:/headlessmc/HeadlessMC" "$IMAGE_NAME" >/dev/null; ok "Container started: $CONTAINER_NAME"; }
verify_runtime(){ hr; info "$TXT_RUNTIME_CHECK"; sleep 10; if ! docker ps --format '{{.Names}}' | grep -qx "$CONTAINER_NAME"; then err "Container is not running. Recent logs:"; docker logs --tail 120 "$CONTAINER_NAME" 2>&1 || true; return 1; fi; ok "Container is running."; docker exec "$CONTAINER_NAME" test -f /root/.minecraft/mods/astera.jar; docker exec "$CONTAINER_NAME" test -f /root/.minecraft/mods/fabric-api.jar; docker exec "$CONTAINER_NAME" test -f /root/.minecraft/euclient/pingbypass.properties; ok "Mod files and config exist in container."; }
show_done(){ local ip; ip="$(public_ip)"; hr; echo -e "${GREEN}${BOLD}${TXT_DONE}${NC}"; echo; echo -e "${BOLD}${TXT_CLIENT_INFO}${NC}"; echo "  Host/IP : $ip"; echo "  Port    : $HOST_PORT"; echo "  Pass    : $PB_PASSWORD"; echo; echo "  pb.server=true"; echo "  pb.ip=${PB_BIND_IP}"; echo "  pb.port=${PB_BIND_PORT}"; echo "  pb.password=********"; echo; echo "$TXT_VIEW_LOGS_IF_FAIL"; hr; }
action_setup(){ clear || true; check_tools; collect_config || { pause; return; }; find_mod_jar; write_assets; build_image; setup_login; run_container; verify_runtime || { pause; return; }; show_done; pause; }
action_start(){ local st; st="$(server_status)"; case "$st" in running) warn "$TXT_ALREADY_RUNNING"; pause ;; none) warn "$TXT_NOT_INSTALLED2"; pause ;; stopped) info "$TXT_STARTING"; docker start "$CONTAINER_NAME" >/dev/null; ok "$TXT_RUNNING"; pause ;; esac; }
action_stop(){ local st; st="$(server_status)"; [[ "$st" == "running" ]] || { warn "$TXT_NOT_RUNNING"; pause; return; }; info "$TXT_STOPPING"; docker stop "$CONTAINER_NAME" >/dev/null; ok "$TXT_STOPPED"; pause; }
action_restart(){ local st; st="$(server_status)"; [[ "$st" != "none" ]] || { warn "$TXT_NOT_INSTALLED2"; pause; return; }; info "$TXT_RESTARTING"; docker restart "$CONTAINER_NAME" >/dev/null; ok "$TXT_RUNNING"; pause; }
action_logs(){ local st; st="$(server_status)"; [[ "$st" != "none" ]] || { warn "$TXT_NOT_INSTALLED2"; pause; return; }; clear || true; hr; echo -e "${DIM}${TXT_LOG_EXIT}${NC}"; hr; docker logs -f "$CONTAINER_NAME" 2>&1 || true; pause; }
action_info(){ local st ip masked uptime; st="$(server_status)"; ip="$(public_ip)"; uptime="$(container_uptime)"; load_config; masked="$(printf '*%.0s' $(seq 1 ${#PB_PASSWORD} 2>/dev/null || echo 0))"; clear || true; hr; echo -e "${BOLD}${TXT_CLIENT_INFO}${NC}"; trh; case "$st" in running) echo -e "  ${TXT_STATUS}     : ${GREEN}${TXT_RUNNING}${NC}" ;; stopped) echo -e "  ${TXT_STATUS}     : ${YELLOW}${TXT_STOPPED}${NC}" ;; none) echo -e "  ${TXT_STATUS}     : ${RED}${TXT_NOT_INSTALLED}${NC}" ;; esac; echo "  ${TXT_PUBLIC_IP}  : $ip"; echo "  ${TXT_PUBLIC_PORT}: ${HOST_PORT:-25565}"; echo "  Password   : ${masked:-}"; echo "  ${TXT_BIND}       : ${PB_BIND_IP}:${PB_BIND_PORT}"; echo "  ${TXT_CONTAINER}  : $CONTAINER_NAME"; echo "  ${TXT_IMAGE}      : $IMAGE_NAME"; [[ "$st" == "running" ]] && echo "  ${TXT_UPTIME}     : $uptime"; hr; pause; }
action_antibot(){ local ip user_guess; ip="$(public_ip)"; user_guess="ubuntu"; clear || true; hr; echo -e "${YELLOW}${BOLD}${TXT_ANTIBOT_TITLE}${NC}"; trh; echo "$TXT_ANTIBOT_NOTE1"; echo "$TXT_ANTIBOT_NOTE2"; echo; echo "VPS IP: $ip"; echo; echo -e "${BOLD}${TXT_WIN_HELP}${NC}"; echo "  ssh -N -D 127.0.0.1:1080 ${user_guess}@${ip}"; echo '  & "C:\Users\YOUR_USER\AppData\Local\imput\Helium\Application\chrome.exe" --user-data-dir="$env:TEMP\notbot-helium-vps-profile" --proxy-server="socks5://127.0.0.1:1080" "https://api.ipify.org" "https://notbot.es"'; echo; echo -e "${BOLD}${TXT_LINUX_HELP}${NC}"; echo "  ssh -N -D 127.0.0.1:1080 ${user_guess}@${ip}"; echo '  chromium --user-data-dir=/tmp/notbot-helium-vps-profile --proxy-server="socks5://127.0.0.1:1080" https://api.ipify.org https://notbot.es'; echo; echo "$TXT_BROWSER_HELP:"; echo '  https://api.ipify.org'; echo '  https://notbot.es'; echo; echo 'Check that api.ipify.org shows the VPS IP. Then complete the verification manually.'; hr; pause; }
draw_menu(){ local st ip port masked uptime; load_config; st="$(server_status)"; ip="$(public_ip)"; port="${HOST_PORT:-25565}"; uptime="$(container_uptime)"; masked="$(printf '*%.0s' $(seq 1 ${#PB_PASSWORD} 2>/dev/null || echo 0))"; clear || true; hr; echo -e "${BOLD}${MAGENTA}PingBypass${NC}"; echo -e "${BOLD}$TXT_TITLE${NC}"; echo -e "${DIM}$TXT_SUB${NC}"; trh; case "$st" in running) echo -e "  ${TXT_STATUS}: ${GREEN}● ${TXT_RUNNING}${NC}   ${TXT_PUBLIC_IP}: ${CYAN}$ip${NC}   ${TXT_PUBLIC_PORT}: ${CYAN}$port${NC}   ${TXT_UPTIME}: ${DIM}$uptime${NC}" ;; stopped) echo -e "  ${TXT_STATUS}: ${YELLOW}○ ${TXT_STOPPED}${NC}   ${TXT_PUBLIC_IP}: ${CYAN}$ip${NC}   ${TXT_PUBLIC_PORT}: ${CYAN}$port${NC}" ;; none) echo -e "  ${TXT_STATUS}: ${RED}✗ ${TXT_NOT_INSTALLED}${NC}   ${TXT_PUBLIC_IP}: ${CYAN}$ip${NC}" ;; esac; [[ -n "$masked" ]] && echo -e "  Password: ${YELLOW}$masked${NC}   ${TXT_BIND}: ${CYAN}${PB_BIND_IP}:${PB_BIND_PORT}${NC}"; trh; echo "  1) $TXT_MENU_SETUP"; echo "  2) $TXT_MENU_START"; echo "  3) $TXT_MENU_STOP"; echo "  4) $TXT_MENU_RESTART"; echo "  5) $TXT_MENU_LOGS"; echo "  6) $TXT_MENU_INFO"; echo "  7) $TXT_MENU_ANTIBOT"; echo "  8) $TXT_MENU_LANGUAGE"; echo "  9) $TXT_MENU_EXIT"; trh; echo -e "  ${DIM}v${VERSION}  |  ${TXT_CREDIT}${NC}"; hr; echo -ne "  ${BOLD}${TXT_MENU_CHOICE} [1-9]: ${NC}"; }
main(){ load_language; while true; do draw_menu; local choice; read -r choice; case "${choice:-}" in 1) action_setup ;; 2) action_start ;; 3) action_stop ;; 4) action_restart ;; 5) action_logs ;; 6) action_info ;; 7) action_antibot ;; 8) choose_language ;; 9) exit 0 ;; *) warn "$TXT_INVALID"; sleep 1 ;; esac; done; }
main "$@"
