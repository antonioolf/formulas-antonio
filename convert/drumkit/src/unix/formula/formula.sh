#!/bin/bash

# Resumo da fórmula - Cria uma pasta "megadrumkit" ao lado do zip .realdrumkit informado como FILE_PATH

runFormula() {
  echo "Starting conversion..."

  directory=$(dirname "$FILE_PATH")
  destination_folder="$directory/megadrumkit - $(date)"

  # Descompacta drumkit para nova pasta
  unzip "$FILE_PATH" -d "$destination_folder"

  # Entra na pasta
  cd "$destination_folder" || exit

  # Verifica se subdiretório esperado existe
  if [ ! -d "realdrumkit" ]; then
    echo "realdrumkit directory not found!"
    exit 1
  fi

  # Move todos arquivos para um nível acima
  mv realdrumkit/* .

  # Deleta pasta agora desnecessária
  rmdir realdrumkit/

  # Converte todos arquivos .mp3 para .wav
  find . -type f -name "*.mp3" -exec ffmpeg -i {} -ac 1 {}.wav \; -exec rm {} \;

  # Renomeando e convertendo arquivos

  # Áudios
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

  # Imagens
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
  mv "tom1.png" "tom_1.png"
  mv "tom2.png" "tom_2.png"
  mv "tom3.png" "tom_3.png"

  # Cria drumkit.json
  echo "{ \"name\": \"$DISPLAY_NAME\" }" > kit.json

  # Remove arquivos "*_reflector"
  rm "closehhl_reflector.png"
  rm "closehhr_reflector.png"
  rm "crashl_reflector.png"
  rm "crashm_reflector.png"
  rm "crashr_reflector.png"
  rm "openhhl_reflector.png"
  rm "openhhr_reflector.png"
  rm "ride_reflector.png"

  rm kit.xml

  echo -e "\n\n Conversion finished!"
}


