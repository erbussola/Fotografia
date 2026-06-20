# Normalizzazione Metadati Foto e Video Viaggio Cina 2026

## 1. Contesto Generale

### Obiettivo

Creare un campo unificato:

```text
XMP-xmp:CreateDate
```

su foto e video provenienti da:

* Canon PowerShot G7 X Mark III
* Samsung Galaxy Note 10 Ultra

per ottenere:

* ordinamento cronologico coerente in ExifToolGUI;
* verifica rapida di eventuali errori di data/ora;
* compatibilità futura con digiKam;
* compatibilità futura con Immich;
* archivio indipendente dalla nomenclatura dei file.

### Scenario tecnico

Durante il viaggio in Cina la Canon G7X Mark III è stata utilizzata con configurazioni di timezone errate:

* UTC+0
* UTC+2 (Roma)
* UTC+6
* UTC+8 (corretto)

Le fotografie Canon sono già state corrette.

Restava da normalizzare:

* video Canon
* foto Android
* video Android

### Vincoli

* Operare esclusivamente su copie dei file.
* Nessuna modifica ai nomi dei file.
* Utilizzare ExifTool 12.76.
* Ambiente principale: WSL Ubuntu.
* Shell: GNU Bash 5.2.21.
* Mantenere i timestamp originali quando già corretti.
* Utilizzare XMP-xmp:CreateDate come campo di ordinamento personale.

---

## 2. Architettura / Setup

### Componenti

* Windows 11
* WSL Ubuntu
* ExifTool 12.76
* ExifToolGUI
* Google Photos
* digiKam
* Immich (futuro)

### Flusso logico

1. Analisi dei metadati.
2. Individuazione della sorgente temporale affidabile.
3. Creazione di XMP-xmp:CreateDate.
4. Verifica cronologica.
5. Utilizzo di XMP-xmp:CreateDate per ordinamento e audit.

---

## 3. Stato Attuale

### Funzionante

#### Foto Canon (stato attuale)

Corretti:

* DateTimeOriginal
* CreateDate
* OffsetTime
* OffsetTimeOriginal
* OffsetTimeDigitized

Timezone Canon MakerNotes ignorato.

#### Video Canon (stato attuale)

Creato correttamente:

```text
XMP-xmp:CreateDate
```

con logica specifica per gruppo timezone.

#### Foto Android (stato attuale)

Verificato:

```text
ExifIFD:DateTimeOriginal
```

corretto.

#### Video Android (stato attuale)

Verificato:

```text
QuickTime:CreateDate
```

salvato in UTC.

### Non funzionante / Incompleto

#### Video Canon (problemi di scrittura)

Non scrivibili:

```text
ExifIFD:DateTimeOriginal
ExifIFD:CreateDate
ExifIFD:OffsetTime
ExifIFD:OffsetTimeOriginal
ExifIFD:OffsetTimeDigitized
```

#### MakerNotes Canon

Non modificabili:

```text
Canon:TimeZone
Canon:TimeZoneCity
Canon:DaylightSavings
```

---

## 4. Decisioni Tecniche

### Foto Canon - decisione

Utilizzare:

```text
ExifIFD:DateTimeOriginal
```

come sorgente.

### Video Canon - decisione

Suddivisione in gruppi:

| Gruppo | Sorgente                     |
| ------ | ---------------------------- |
| UTC+2  | QuickTime:CreateDate + 8 ore |
| UTC+0  | DateTimeOriginal             |
| UTC+6  | DateTimeOriginal             |
| UTC+8  | DateTimeOriginal             |

### Foto Android - decisione

Utilizzare:

```text
ExifIFD:DateTimeOriginal
```

### Video Android - decisione

Utilizzare:

```text
QuickTime:CreateDate + 8 ore
```

### Campo di riferimento archivio

Utilizzare:

```text
XMP-xmp:CreateDate
```

in formato:

```text
YYYY:MM:DD HH:MM:SS+08:00
```

---

## 5. Problemi Aperti

### digiKam

Da verificare:

* utilizzo di XMP-xmp:CreateDate nella timeline.

### Immich

Da verificare:

* utilizzo di XMP-xmp:CreateDate nella timeline.

### Google Photos

Utilizza una combinazione di:

* EXIF
* QuickTime
* timezone

Non è stato ancora determinato con precisione quale tag abbia priorità.

---

## 6. Dati Tecnici Rilevanti

### Versioni

| Componente | Versione   |
| ---------- | ---------- |
| ExifTool   | 12.76      |
| Bash       | 5.2.21     |
| OS         | Windows 11 |
| Ambiente   | WSL Ubuntu |

### Verifica QuickTime UTC

Comando:

```bash
exiftool \
-api QuickTimeUTC=1 \
-a -G1 -s \
-QuickTime:CreateDate \
file.mp4
```

Osservazione:

* converte UTC nel timezone corrente del sistema;
* non rappresenta il timezone storico dello scatto.

### Warning Canon MP4

Warning osservato:

```text
Warning: ValueConv DOF: Use of uninitialized value $val[1] in multiplication (*)
```

Gestito con:

```bash
-m -q -q
```

Nessun impatto sulla scrittura dei metadati.

---

## 7. Runbook Operativo

### Prerequisiti

Verificare versione:

```bash
exiftool -ver
```

Verificare Bash:

```bash
bash --version
```

Lavorare esclusivamente su copie.

---

### Preparazione degli elenchi di lavoro

### Creazione elenco foto Canon

Tutte le foto Canon iniziano con:

```text
IMG_
```

Generazione elenco:

```bash
find . -type f -iname 'IMG_*.JPG' | sort > canon_photos.txt
```

Verifica:

```bash
wc -l canon_photos.txt
```

---

### Creazione elenco video Canon

Tutti i video Canon iniziano con:

```text
MVI_
```

Generazione elenco:

```bash
find . -type f -iname 'MVI_*.MP4' | sort > canon_videos.txt
```

Verifica:

```bash
wc -l canon_videos.txt
```

---

### Creazione elenco foto Android

Le foto Android del viaggio utilizzano il formato:

```text
YYYYMMDD_HHMMSS.jpg
```

Generazione elenco:

```bash
find . -type f -regextype posix-extended \
-regex '.*/[0-9]{8}_[0-9]{6}\.(jpg|JPG)' \
| sort > android_photos.txt
```

Verifica:

```bash
wc -l android_photos.txt
```

---

### Creazione elenco video Android

I video Android utilizzano il formato:

```text
YYYYMMDD_HHMMSS.mp4
```

Generazione elenco:

```bash
find . -type f -regextype posix-extended \
-regex '.*/[0-9]{8}_[0-9]{6}\.(mp4|MP4)' \
| sort > android_videos.txt
```

Verifica:

```bash
wc -l android_videos.txt
```

---

### Creazione CSV di audit dei video Canon

Comando utilizzato durante il progetto:

```bash
find . -type f -iname 'MVI_*.MP4' -print0 | \
xargs -0 exiftool \
-csv \
-FileName \
-DateTimeOriginal \
-OffsetTimeOriginal \
-CreateDate \
-OffsetTimeDigitized \
-QuickTime:CreateDate \
-TrackCreateDate \
-MediaCreateDate \
> video_audit.csv
```

---

### Creazione liste timezone Canon

Dal CSV:

```text
video_audit.csv
```

identificare i gruppi:

```text
+00:00
+02:00
+06:00
+08:00
```

e creare:

```text
lista_video_00.txt
lista_video_02.txt
lista_video_06.txt
lista_video_08.txt
```

contenenti un file per riga.

Esempio:

```text
./MVI_7285.MP4
./MVI_7315.MP4
./MVI_7403.MP4
```

---

### Verifica rapida contenuto liste

```bash
for f in lista_video_*.txt
do
    echo "$f : $(wc -l < "$f") file"
done
```

---

### Verifica metadati dei file presenti nella lista

Esempio gruppo UTC+02:

```bash
exiftool \
-p '$FileName -> ${QuickTime:CreateDate;ShiftTime("0:0:0 08:00:00")}+08:00' \
-@ lista_video_02.txt
```

Questa fase è stata fondamentale per verificare che il timestamp risultante fosse coerente prima di eseguire le scritture sui file.

---

### Audit Video Canon

Generazione CSV:

```bash
find . -type f -iname 'MVI_*.MP4' -print0 | \
xargs -0 exiftool \
-csv \
-FileName \
-DateTimeOriginal \
-OffsetTimeOriginal \
-CreateDate \
-OffsetTimeDigitized \
-QuickTime:CreateDate \
-TrackCreateDate \
-MediaCreateDate \
> video_audit.csv
```

---

### Verifica conversione QuickTime

Test:

```bash
exiftool \
-p '${QuickTime:CreateDate;ShiftTime("0:0:0 08:00:00")}' \
MVI_7514.MP4
```

Output atteso:

```text
2026:04:04 10:37:36
```

---

### Video Canon UTC+2

File elencati in:

```text
lista_video_02.txt
```

Comando:

```bash
exiftool \
-m -q -q \
-overwrite_original \
'-XMP-xmp:CreateDate<${QuickTime:CreateDate;ShiftTime("0:0:0 08:00:00")}+08:00' \
-@ lista_video_02.txt
```

---

### Video Canon UTC+0 UTC+6 UTC+8

File elencati in:

```text
lista_video_00.txt
lista_video_06.txt
lista_video_08.txt
```

Comando:

```bash
exiftool \
-m -q -q \
-overwrite_original \
'-XMP-xmp:CreateDate<${DateTimeOriginal}+08:00' \
-@ lista_video_00.txt \
-@ lista_video_06.txt \
-@ lista_video_08.txt
```

---

### Foto Canon - XMP-xmp:CreateDate

File elencati in:

```text
canon_photos.txt
```

Comando:

```bash
exiftool \
-m -q -q \
-overwrite_original \
'-XMP-xmp:CreateDate<${ExifIFD:DateTimeOriginal}+08:00' \
-@ canon_photos.txt
```

---

### Foto Android - XMP-xmp:CreateDate

File elencati in:

```text
android_photos.txt
```

Comando:

```bash
exiftool \
-m -q -q \
-overwrite_original \
'-XMP-xmp:CreateDate<${ExifIFD:DateTimeOriginal}+08:00' \
-@ android_photos.txt
```

---

### Video Android - XMP-xmp:CreateDate

File elencati in:

```text
android_videos.txt
```

Comando:

```bash
exiftool \
-m -q -q \
-overwrite_original \
'-XMP-xmp:CreateDate<${QuickTime:CreateDate;ShiftTime("0:0:0 08:00:00")}+08:00' \
-@ android_videos.txt
```

---

### Verifica finale

Generazione report:

```bash
exiftool \
-csv \
-FileName \
-XMP-xmp:CreateDate \
-r . \
> audit_xmp_createdate.csv
```

---

### Verifica singolo file

```bash
exiftool \
-a -G1 -s \
-FileName \
-DateTimeOriginal \
-QuickTime:CreateDate \
-XMP-xmp:CreateDate \
file
```

Output atteso:

```text
XMP-xmp:CreateDate : YYYY:MM:DD HH:MM:SS+08:00
```

---

### Rollback

Ripristinare i file dalla copia di sicurezza iniziale.

Nessuna procedura automatica di rollback prevista.

---

## 8. Prossimi Step

1. Creare XMP-xmp:CreateDate per tutte le foto Android.
2. Creare XMP-xmp:CreateDate per tutti i video Android.
3. Generare audit completo dell'archivio.
4. Ordinare per XMP-xmp:CreateDate in ExifToolGUI.
5. Individuare eventuali anomalie residue.
6. Verificare comportamento di digiKam.
7. Verificare comportamento di Immich.
8. Verificare eventuale utilizzo di XMP-xmp:CreateDate da parte di Google Photos.

---

## 9. Note Operative / Best Practice

* Conservare sempre una copia originale dei file.
* Non utilizzare QuickTimeUTC=1 per determinare il timezone storico dello scatto.
* Non utilizzare Canon:TimeZone come riferimento cronologico.
* Utilizzare sempre verifiche preliminari prima di eseguire batch massivi.
* Preferire liste file statiche (`-@ file.txt`) rispetto a filtri dinamici quando il gruppo è già stato validato manualmente.
* Utilizzare XMP-xmp:CreateDate come campo unificato di ordinamento.
* Conservare sempre i timestamp QuickTime originali quando corretti.
* Documentare eventuali nuove eccezioni rilevate durante futuri viaggi o importazioni.
