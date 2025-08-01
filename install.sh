#!/bin/bash

set -e

REPOSITORY_OWNER="Neniel"
REPOSITORY="utilities"

ALIAS="$1"
VERSION="$2"

if [[ -z "$ALIAS" ]]; then
  echo "❌ You must specify a name for this installation."
  exit 1
fi

if [[ -z "$VERSION" ]]; then
  echo "🔍 Buscando última versión..."
  VERSION=$(curl -s https://api.github.com/repos/$REPOSITORY_OWNER/$REPOSITORY/releases/latest | grep -oP '"tag_name":\s*"\K[^"]+')
  if [[ -z "$VERSION" ]]; then
    echo "❌ No se pudo obtener la última versión."
    exit 1
  fi
  IFS='/' read -r -a VERSION_PARTS <<< "$VERSION"
  VERSION=${VERSION_PARTS[1]}
  echo "📌 Última versión encontrada: $VERSION"
fi



INSTALL_DIR="$HOME/.local/$ALIAS"
PRESERVE_DIR="$INSTALL_DIR/$REPOSITORY-$VERSION/modules/private"

ZIP_URL="https://github.com/$REPOSITORY_OWNER/$REPOSITORY/releases/download/release%2F$VERSION/$REPOSITORY-$VERSION.zip"
TMP_DIR=$(mktemp -d)

echo "📦 Descargando $VERSION desde GitHub..."
curl -L "$ZIP_URL" -o $TMP_DIR/$REPOSITORY-$VERSION.zip

# Preparar destino
echo "🛠️ Preparando instalación..."

# Preservar 'modules/private' si existe
if [[ -d "$PRESERVE_DIR" ]]; then
  echo "🛡️ Making backup of $PRESERVE_DIR..."
  mv "$PRESERVE_DIR" "$TMP_DIR/private_backup"
fi

# Make backup of previous installation
if [[ -d "$INSTALL_DIR" ]]; then
  echo "🛡️ Making backup of $INSTALL_DIR..."
  mv "$INSTALL_DIR" "$INSTALL_DIR-$(date +%d%m%Y_%H%M%S)"
fi

mkdir -p "$INSTALL_DIR"

echo "📂 Descomprimiendo..."
ZIP_FILE="$TMP_DIR/$REPOSITORY-$VERSION.zip"
unzip -q "$ZIP_FILE" -d "$INSTALL_DIR"

# Restaurar 'modules/private' si se había preservado
if [[ -d "$TMP_DIR/private_backup" ]]; then
  echo "🔁 Restaurando $PRESERVE_DIR..."
  mkdir -p "$INSTALL_DIR/modules"
  mv "$TMP_DIR/private_backup" "$PRESERVE_DIR"
fi

# Limpiar
echo "🧹 Limpiando temporales..."
rm -rf "$TMP_DIR"

USER_HOME=$(eval echo "~$USER")
BIN_PATH="$USER_HOME/.local/bin"
mkdir -p "$BIN_PATH"

CURRENT_SHELL=$(basename "$SHELL")
case "$CURRENT_SHELL" in
    bash)
        RC_FILE="$USER_HOME/.bashrc"
        # Verificar si la línea ya existe para evitar duplicados
        if ! grep -q "export PATH=\"$BIN_PATH:\$PATH\"" "$RC_FILE"; then
            echo "Adding $BIN_PATH to PATH in $RC_FILE..."
            echo "export PATH=\"$BIN_PATH:\$PATH\"" >> "$RC_FILE"
            echo "$BIN_PATH has been added to your path. Please, restart your terminal or run 'source $RC_FILE' to apply the changes."
        fi
        ;;

    zsh)
        RC_FILE="$USER_HOME/.zshrc"
        if ! grep -q "export PATH=\"$BIN_PATH:\$PATH\"" "$RC_FILE"; then
            echo "Adding $BIN_PATH to PATH in $RC_FILE..."
            echo "export PATH=\"$BIN_PATH:\$PATH\"" >> "$RC_FILE"
            echo "$BIN_PATH has been added to your path. Please, restart your terminal or run 'source $RC_FILE' to apply the changes."
        fi
        ;;

    fish)
        RC_FILE="$USER_HOME/.config/fish/config.fish"
        # Fish usa una sintaxis diferente para añadir al PATH
        if ! grep -q "set -gx PATH \"$BIN_PATH\" \$PATH" "$RC_FILE"; then
            echo "Adding $BIN_PATH to PATH in $RC_FILE..."
            echo "set -gx PATH \"$BIN_PATH\" \$PATH" >> "$RC_FILE"
            echo "$BIN_PATH has been added to your path. Please, restart your terminal or run 'source $RC_FILE' to apply the changes."
        fi
        ;;    
    *)
        # --- Lógica de fallback para shells no reconocidas ---
        echo "Shell '$CURRENT_SHELL' is not supported by this script. Using fallback to add $BIN_PATH to PATH."
        RC_FILE="$USER_HOME/.profile"
        if [ ! -f "$RC_FILE" ]; then
            echo "Creating fallback file $RC_FILE..."
            touch "$RC_FILE"
        fi

        if ! grep -q "export PATH=\"$BIN_PATH:\$PATH\"" "$RC_FILE"; then
            echo "Adding $BIN_PATH to PATH in $RC_FILE..."
            echo "export PATH=\"$BIN_PATH:\$PATH\"" >> "$RC_FILE"
            echo "$BIN_PATH has been added to your path. Please, restart your terminal or run 'source $RC_FILE' to apply the changes."
        fi
        ;;

esac

ln -sf "$INSTALL_DIR/$REPOSITORY.sh" "$BIN_PATH/$ALIAS"

ls -l "$BIN_PATH/$ALIAS"

echo "✅ Instalado en $INSTALL_DIR"
