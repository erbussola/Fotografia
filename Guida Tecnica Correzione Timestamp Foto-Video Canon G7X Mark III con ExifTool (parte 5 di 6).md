# Parte 5/6 - Runbook Operativo Produzione (Foto JPG)

## 7. Runbook Operativo (Espanso)

## Scope

Procedura operativa pronta all’uso per correggere e validare **foto JPG** Canon G7X Mark III.

Ambiente di riferimento:

* Linux / WSL
* shell bash
* ExifTool installato

Directory di lavoro prevista:

```bash id="3c4l91"
~/Cina
```

---

## Step 0 - Prerequisiti iniziali

## Verificare tool installati

```bash id="yx2g84"
exiftool -ver
bash --version | head -1
```

### Output atteso

```text id="nq1q6o"
ExifTool version presente
GNU bash presente
```

---

## Verificare directory corretta

```bash id="o5a6h0"
pwd
ls -1 | head
```

### Output atteso

Presenza file:

```text id="syj6n8"
IMG_####.JPG
lista_00.txt
lista_02.txt
lista_06.txt
```

---

## Verificare spazio disco

```bash id="p7t4u1"
df -h .
```

### Output atteso

Spazio libero sufficiente per backup e modifiche.

---

## Step 1 - Backup operativo immediato

## Backup file originali

```bash id="i0u2p6"
mkdir -p backup_originali
cp -a *.JPG backup_originali/
```

## Backup metadata

```bash id="s6q4z2"
exiftool -json *.JPG > backup_foto_metadata.json
```

### Verifica

```bash id="j5x9a1"
ls -lh backup_originali | head
ls -lh backup_foto_metadata.json
```

---

## Step 2 - Audit pre-correzione

## Conteggio file per offset

```bash id="n4v0u3"
exiftool -T -OffsetTimeOriginal *.JPG | sort | uniq -c
```

### Output atteso

Valori tipo:

```text id="l2c8w5"
xx +00:00
xx +02:00
xx +06:00
xx +08:00
```

---

## Spot check casuale

```bash id="x3r7m2"
exiftool -DateTimeOriginal -OffsetTimeOriginal IMG_7196.JPG IMG_7719.JPG
```

---

## Step 3 - Correzione gruppo +00

## Esecuzione

```bash id="k1f7d3"
exiftool -overwrite_original \
-OffsetTimeOriginal="+08:00" \
-OffsetTimeDigitized="+08:00" \
-OffsetTime="+08:00" \
-@ lista_00.txt
```

## Verifica

```bash id="q9z1n4"
exiftool -DateTimeOriginal -OffsetTimeOriginal IMG_7677.JPG
```

### Output atteso

```text id="m6a3t0"
DateTimeOriginal invariato
OffsetTimeOriginal : +08:00
```

---

## Fallback

Se il risultato non è corretto:

```bash id="r3b1k7"
cp -a backup_originali/IMG_7677.JPG .
```

---

## Step 4 - Correzione gruppo +02

## Esecuzione

```bash id="u8s0e4"
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

```bash id="g5w4h8"
exiftool -DateTimeOriginal -OffsetTimeOriginal IMG_7196.JPG
```

### Output atteso

```text id="c8v6n2"
DateTimeOriginal : 13:33:11
OffsetTimeOriginal : +08:00
```

---

## Rollback gruppo +02

```bash id="h0m3q9"
while read f; do cp -a backup_originali/"$f" .; done < lista_02.txt
```

---

## Step 5 - Gestione gruppo +06

## Audit prima di modificare

```bash id="w4j8s1"
head lista_06.txt
exiftool -DateTimeOriginal -OffsetTimeOriginal $(head -3 lista_06.txt)
```

## Azione

Applicare solo dopo verifica reale dei file.

Se confermato +2h:

```bash id="d9p2k6"
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

```bash id="t7x1f5"
exiftool -T -OffsetTimeOriginal *.JPG | sort | uniq -c
```

### Output atteso

```text id="n8r3z0"
solo +08:00
```

---

## Ordinamento cronologico spot check

```bash id="f2h7k1"
exiftool -T -FileName -DateTimeOriginal *.JPG | sort | head -20
```

---

## Step 7 - Sync filesystem JPG

```bash id="m1z6c8"
exiftool -overwrite_original \
'-FileModifyDate<DateTimeOriginal' \
'-FileCreateDate<DateTimeOriginal' \
*.JPG
```

## Verifica

```bash id="y7u5q2"
ls -l --time-style=long-iso IMG_7196.JPG
```

---

## Step 8 - Error handling rapido

## Se ExifTool restituisce file not found

Verificare maiuscole/minuscole:

```bash id="v3k0p4"
ls IMG_7196.*
```

---

## Se lista file contiene CRLF

```bash id="a9j2r6"
dos2unix lista_00.txt lista_02.txt lista_06.txt
```

---

## Se modifica errata su batch

Ripristino completo:

```bash id="z6q1m8"
cp -a backup_originali/*.JPG .
```

---

## Step 9 - Chiusura foto

## Campione finale

```bash id="b5n4t1"
exiftool -DateTimeOriginal -OffsetTimeOriginal \
IMG_7196.JPG IMG_7284.JPG IMG_7719.JPG
```

### Output atteso

```text id="p4d7c9"
orari coerenti
timezone +08:00
```
