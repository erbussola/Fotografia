# Parte 5/6 - Runbook Operativo Produzione (Foto JPG)

## 7. Runbook Operativo (Espanso)

## Scope

Procedura operativa pronta all’uso per correggere e validare **foto JPG** Canon G7X Mark III.

Ambiente di riferimento:

* Linux / WSL
* shell bash
* ExifTool installato

Directory di lavoro prevista:

```bash
~/Cina
```

---

## Step 0 - Prerequisiti iniziali

## Verificare tool installati

```bash
exiftool -ver
bash --version | head -1
```

### Output atteso

```text
ExifTool version presente
GNU bash presente
```

---

## Verificare directory corretta

```bash
pwd
ls -1 | head
```

### Output atteso

Presenza file:

```text
IMG_####.JPG
lista_00.txt
lista_02.txt
lista_06.txt
```

---

## Verificare spazio disco

```bash
df -h .
```

### Output atteso

Spazio libero sufficiente per backup e modifiche.

---

## Step 1 - Backup operativo immediato

## Backup file originali

```bash
mkdir -p backup_originali
cp -a *.JPG backup_originali/
```

## Backup metadata

```bash
exiftool -json *.JPG > backup_foto_metadata.json
```

### Verifica

```bash
ls -lh backup_originali | head
ls -lh backup_foto_metadata.json
```

---

## Step 2 - Audit pre-correzione

## Conteggio file per offset

```bash
exiftool -T -OffsetTimeOriginal *.JPG | sort | uniq -c
```

### Output atteso

Valori tipo:

```text
xx +00:00
xx +02:00
xx +06:00
xx +08:00
```

---

## Spot check casuale

```bash
exiftool -DateTimeOriginal -OffsetTimeOriginal IMG_7196.JPG IMG_7719.JPG
```

---

## Step 3 - Correzione gruppo +00

## Esecuzione

```bash
exiftool -overwrite_original \
-OffsetTimeOriginal="+08:00" \
-OffsetTimeDigitized="+08:00" \
-OffsetTime="+08:00" \
-@ lista_00.txt
```

## Verifica

```bash
exiftool -DateTimeOriginal -OffsetTimeOriginal IMG_7677.JPG
```

### Output atteso

```text
DateTimeOriginal invariato
OffsetTimeOriginal : +08:00
```

---

## Fallback

Se il risultato non è corretto:

```bash
cp -a backup_originali/IMG_7677.JPG .
```

---

## Step 4 - Correzione gruppo +02

## Esecuzione

```bash
exiftool -overwrite_original \
-DateTimeOriginal+=6:0:0 \
-CreateDate+=6:0:0 \
-ModifyDate+=6:0:0 \
-OffsetTimeOriginal="+08:00" \
-OffsetTimeDigitized="+08:00" \
-OffsetTime="+08:00" \
-@ lista_02.txt
```

## Verifica

```bash
exiftool -DateTimeOriginal -OffsetTimeOriginal IMG_7196.JPG
```

### Output atteso

```text
DateTimeOriginal : 13:33:11
OffsetTimeOriginal : +08:00
```

---

## Rollback gruppo +02

```bash
while read f; do cp -a backup_originali/"$f" .; done < lista_02.txt
```

---

## Step 5 - Gestione gruppo +06

## Audit prima di modificare

```bash
head lista_06.txt
exiftool -DateTimeOriginal -OffsetTimeOriginal $(head -3 lista_06.txt)
```

## Azione

Applicare solo dopo verifica reale dei file.

Se confermato +2h:

```bash
exiftool -overwrite_original \
-DateTimeOriginal+=2:0:0 \
-CreateDate+=2:0:0 \
-ModifyDate+=2:0:0 \
-OffsetTimeOriginal="+08:00" \
-OffsetTimeDigitized="+08:00" \
-OffsetTime="+08:00" \
-@ lista_06.txt
```

---

## Step 6 - Verifica globale finale foto

## Tutti i timezone

```bash
exiftool -T -OffsetTimeOriginal *.JPG | sort | uniq -c
```

### Output atteso

```text
solo +08:00
```

---

## Ordinamento cronologico spot check

```bash
exiftool -T -FileName -DateTimeOriginal *.JPG | sort | head -20
```

---

## Step 7 - Sync filesystem JPG

```bash
exiftool -overwrite_original \
'-FileModifyDate<DateTimeOriginal' \
'-FileCreateDate<DateTimeOriginal' \
*.JPG
```

## Verifica

```bash
ls -l --time-style=long-iso IMG_7196.JPG
```

---

## Step 8 - Error handling rapido

## Se ExifTool restituisce file not found

Verificare maiuscole/minuscole:

```bash
ls IMG_7196.*
```

---

## Se lista file contiene CRLF

```bash
dos2unix lista_00.txt lista_02.txt lista_06.txt
```

---

## Se modifica errata su batch

Ripristino completo:

```bash
cp -a backup_originali/*.JPG .
```

---

## Step 9 - Chiusura foto

## Campione finale

```bash
exiftool -DateTimeOriginal -OffsetTimeOriginal \
IMG_7196.JPG IMG_7284.JPG IMG_7719.JPG
```

### Output atteso

```text
orari coerenti
timezone +08:00
```
