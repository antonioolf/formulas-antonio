#!/bin/bash

set -e

# Steps da fórmula:
# - Verificar o número do último kit no index.json, e assumir que o próximo será o número + 1
# - Criar pasta com o número, outra chamada "megadrumkit" e mover o arquivo para dentro desta última
# - Extrair zip do kit e renomear pasta de realdrumkit para megadrumkit
# - Renomear e converter as imagens e sons dentro da pasta megadrumkit
# - Cortar topo do arquivo cover.png
# - Fazer cópia do arquivo cover.png para fora da pasta megadrumkit
# - Voltar para um nível acima da pasta megadrumkit
# - Compactar pasta megadrumkit em zip
# - Renomear para kit.megadrum
# - Deletar pasta megadrumkit
# - Atualizar index.json com informações da nova pasta
# - Opcional: Commit e push para github

getLastKitNumber() {
  echo $(                           \
    cat "$CURRENT_PWD"/index.json | \
    jq .[].path                   | \
    sed 's/[^0-9]*//g'            | \
    sort -nr                      | \
    head -1                         \
  )
}

# Adiciona uma nova entrada ao index.json com o número do último kit
addToIndexJson() {
  local kitNumber=$1
  local kitPath="online_kit_$kitNumber"
  local kitCoverUrl="https://oliveiralabs.github.io/megadrum-kits/$kitNumber/cover.png"
  local kitZipUrl="https://oliveiralabs.github.io/megadrum-kits/$kitNumber/kit.megadrum"

  cat "$CURRENT_PWD"/index.json | \
    jq ". += [{
      \"name\": \"$kitName\",
      \"path\": \"$kitPath\",
      \"coverUrl\": \"$kitCoverUrl\",
      \"zipUrl\": \"$kitZipUrl\"
    }]" > "$CURRENT_PWD"/index.json.tmp && \
    mv "$CURRENT_PWD"/index.json.tmp "$CURRENT_PWD"/index.json
}

runFormula() {  
  echo "Starting conversion..."
  
  # Obtém o número do próximo kit
  kitNumber=$(($(getLastKitNumber) + 1))

  # Define kitName como o mesmo nome do arquivo sem a extensão
  kitName=${FILE_NAME%%.*}
  
  # Cria pasta com o número obtido
  mkdir -p "$CURRENT_PWD/$kitNumber/megadrumkit"

  # Copia o arquivo .realdrum para dentro da pasta criada
  cp "$CURRENT_PWD/$FILE_NAME" "$CURRENT_PWD/$kitNumber/megadrumkit/$FILE_NAME"

  # Entra na pasta
  cd "$CURRENT_PWD/$kitNumber/megadrumkit" || exit

  # Extrai o arquivo .realdrum como .zip
  7z e "$FILE_NAME"

  # Deleta arquivo .realdrum
  rm "$FILE_NAME"

  # Converte todos arquivos .mp3 para .wav
  find . -type f -name "*.mp3" -exec ffmpeg -i {} -ac 1 {}.wav \; -exec rm {} \;

  # Renomeia audios
  mv "closehh.mp3.wav" "close_hh.wav"
  mv "crashl.mp3.wav" "crash_l.wav"
  mv "crashr.mp3.wav" "crash_r.wav"
  mv "crashm.mp3.wav" "splash.wav"
  mv "floor.mp3.wav" "floor.wav"
  mv "openhh.mp3.wav" "open_hh.wav"
  mv "ride.mp3.wav" "ride.wav"
  mv "snare.mp3.wav" "snare.wav"
  mv "tom1.mp3.wav" "tom_1.wav"
  mv "tom2.mp3.wav" "tom_2.wav"
  mv "tom3.mp3.wav" "tom_3.wav"

  mv "kick.mp3.wav" "kick_l.wav"
  cp "kick_l.wav" "kick_r.wav"

  # Renomeia imagens
  convert "fundo.jpg" -strip "fundo.png"
  rm "fundo.jpg"
  mv "fundo.png" "background.png"

  mv "closehhl.png" "close_hh_left_handed.png"
  mv "closehhr.png" "close_hh.png"

  mv "openhhl.png" "open_hh_left_handed.png"
  mv "openhhr.png" "open_hh.png"

  mv "crashl.png" "crash_l.png"
  mv "crashm.png" "splash.png"
  mv "crashr.png" "crash_r.png"

  mv "floorl.png" "floor.png"
  mv "floorr.png" "floor_left_handed.png"

  mv "kickl.png" "kick_l.png"
  mv "kickr.png" "kick_r.png"

  mv "thumbnail.png" "cover.png"

  # Corta topo da imagem cover.png
  convert cover.png -gravity North -chop 0x30 cover.png

  mv "tom1.png" "tom_1.png"
  mv "tom2.png" "tom_2.png"
  mv "tom3.png" "tom_3.png"

  # Cria kit.json
  echo "{ \"name\": \"$kitName\" }" > kit.json

  # Exclui arquivos "*_reflector"
  rm -f "closehhl_reflector.png"
  rm -f "closehhr_reflector.png"
  rm -f "crashl_reflector.png"
  rm -f "crashm_reflector.png"
  rm -f "crashr_reflector.png"
  rm -f "openhhl_reflector.png"
  rm -f "openhhr_reflector.png"
  rm -f "ride_reflector.png"

  # Exclui kit.xml
  rm kit.xml

  cp "$CURRENT_PWD/$kitNumber/megadrumkit/cover.png" "$CURRENT_PWD/$kitNumber/cover.png"

  # Zipa o diretório para gerar o kit.megadrum
  cd "$CURRENT_PWD/$kitNumber" || exit
  zip -r "$CURRENT_PWD/$kitNumber/kit.megadrum" "./megadrumkit"

  # Deleta pasta megadrumkit
  rm -rf "$CURRENT_PWD/$kitNumber/megadrumkit"

  addToIndexJson "$kitNumber"

  echo -e "\n\n Conversion finished!"
}
