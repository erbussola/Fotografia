# Parte 6/6 - Runbook Operativo Produzione (Video MP4)

## 7. Runbook Operativo (Espanso)

## Scope

Procedura operativa pronta all’uso per analisi, classificazione e correzione **video MP4** Canon `MVI_####.MP4`.

Directory prevista:

```bash
~/Cina
```

---

## Step 10 - Prerequisiti video

## Verifica presenza lista video

```bash
wc -l lista_video.txt
head lista_video.txt
tail lista_video.txt
```

### Output atteso

```text
24 lista_video.txt
```

---

## Verifica file reali

```bash
ls MVI_* 2>/dev/null | wc -l
```

---

## Step 11 - Backup video

```bash
mkdir -p backup_video
cp -a MVI_* backup_video/
```

## Backup metadata

```bash
exiftool -json MVI_* > backup_video_metadata.json
```

---

## Step 12 - Script verifica automatica video/foto

## Creazione script

```bash
vim check_video.sh
```

Inserire contenuto:

```bash
#!/bin/bash

to_epoch() {
  ts=$(echo "$1" | sed 's/:/-/1; s/:/-/1')
  date -d "$ts" +%s 2>/dev/null
}

while read -r vid; do
  num=$(echo "$vid" | sed -E 's/.*_([0-9]+)\..*/\1/')
  prev=$(printf "IMG_%04d.JPG" $((num-1)))
  next=$(printf "IMG_%04d.JPG" $((num+1)))

  echo "========================================"
  echo "VIDEO: $vid"

  vtime=$(exiftool -s -s -s -QuickTime:CreateDate "$vid")
  echo "VIDEO TIME: $vtime"

  v_epoch=$(to_epoch "$vtime")

  for f in "$prev" "$next"; do
    if [ -f "$f" ]; then
      ptime=$(exiftool -s -s -s -DateTimeOriginal "$f")
      echo "PHOTO: $f -> $ptime"

      p_epoch=$(to_epoch "$ptime")
      diff_sec=$((p_epoch - v_epoch))
      diff_hr=$(echo "scale=2; $diff_sec/3600" | bc)

      echo "DELTA: ${diff_hr}h"
    fi
  done

done < lista_video.txt
```

---

## Permessi ed esecuzione

```bash
chmod +x check_video.sh
./check_video.sh | tee report_video.txt
```

---

## Step 13 - Classificazione manuale operativa

## Regole

| Delta rilevato      | Azione                |
| ------------------- | --------------------- |
| tra -1h e +1h       | OK                    |
| circa +2h           | gruppo `video_2h.txt` |
| circa +6h           | gruppo `video_6h.txt` |
| nessuna foto vicina | `video_unknown.txt`   |

---

## Creazione file liste

```bash
vim video_ok.txt
vim video_2h.txt
vim video_6h.txt
vim video_unknown.txt
```

Un file per riga:

```text
MVI_7315.MP4
MVI_7403.MP4
```

---

## Step 14 - Correzione batch video +2h

```bash
exiftool -overwrite_original \
-QuickTime:CreateDate+=2:0:0 \
-QuickTime:ModifyDate+=2:0:0 \
-CreateDate+=2:0:0 \
-ModifyDate+=2:0:0 \
-@ video_2h.txt
```

---

## Verifica immediata

```bash
exiftool -QuickTime:CreateDate MVI_7315.MP4
```

### Output atteso

Orario riallineato alle foto vicine.

---

## Rollback +2h

```bash
while read f; do cp -a backup_video/"$f" .; done < video_2h.txt
```

---

## Step 15 - Correzione batch video +6h

```bash
exiftool -overwrite_original \
-QuickTime:CreateDate+=6:0:0 \
-QuickTime:ModifyDate+=6:0:0 \
-CreateDate+=6:0:0 \
-ModifyDate+=6:0:0 \
-@ video_6h.txt
```

---

## Rollback +6h

```bash
while read f; do cp -a backup_video/"$f" .; done < video_6h.txt
```

---

## Step 16 - Gestione video_unknown

## Verifica singolo file

```bash
exiftool MVI_8084.MP4 | grep Date
```

## Confronto manuale con file vicini

```bash
exiftool -DateTimeOriginal IMG_8083.JPG IMG_8085.JPG
```

Decidere se:

* OK
* +2h
* +6h

Poi aggiungere il file nella lista corretta.

---

## Step 17 - Sync filesystem video

```bash
exiftool -overwrite_original \
'-FileModifyDate<QuickTime:CreateDate' \
MVI_*.MP4
```

---

## Verifica

```bash
ls -l --time-style=long-iso MVI_7285.MP4
```

---

## Step 18 - Audit finale video

## Campione casuale

```bash
exiftool -QuickTime:CreateDate \
MVI_7285.MP4 MVI_7315.MP4 MVI_8239.MP4
```

## Coerenza con foto vicine

```bash
exiftool -DateTimeOriginal \
IMG_7284.JPG IMG_7314.JPG IMG_8238.JPG
```

---

## Step 19 - Error handling rapido

## File non trovato

```bash
ls -1 MVI_* | grep 7315
```

---

## Estensione minuscola `.mp4`

```bash
ls -1 *.[mM][pP]4
```

---

## Lista con CRLF

```bash
dos2unix video_2h.txt video_6h.txt video_unknown.txt
```

---

## Step 20 - Chiusura definitiva progetto

## Report riepilogo

```bash
echo "Foto JPG:" $(ls *.JPG | wc -l)
echo "Video MP4:" $(ls *.[mM][pP]4 | wc -l)
```

## Ultimo controllo metadata

```bash
exiftool -T -FileName -QuickTime:CreateDate MVI_* | head
```

---

## Stato finale atteso

```text
Foto coerenti con timezone Cina
Video coerenti con timeline reale
Filesystem ordinabile
Import pulito su smartphone/NAS
```

---
