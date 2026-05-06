# Parte 1/4 - Guida Tecnica Correzione Timestamp Foto/Video Canon G7X Mark III con ExifTool

# Titolo

Guida tecnica completa per analisi, normalizzazione e correzione metadati temporali di foto e video Canon PowerShot G7 X Mark III (viaggio Cina Aprile 2026)

---

## 1. Contesto Generale

### Obiettivo

Correggere in modo preciso e verificabile i metadati temporali di foto e video prodotti da una Canon PowerShot G7 X Mark III durante un viaggio in Cina, a causa di configurazioni errate del fuso orario sulla fotocamera.

L’obiettivo finale è ottenere file perfettamente coerenti per:

* visualizzazione su smartphone Android
* sincronizzazione con Google Photos
* archiviazione su NAS
* ordinamento cronologico corretto
* ricerca immediata per data
* conservazione metadati originali coerenti

---

### Scenario tecnico

Durante il viaggio sono stati usati diversi offset orari sulla fotocamera:

* `+02:00` (Roma / Italia)
* `+06:00`
* `+08:00` (Cina corretto)
* `+00:00`

Le foto risultavano quindi in quattro gruppi distinti.

Per alcuni gruppi:

* l’orario locale era corretto ma il timezone errato
* in altri casi erano errati sia orario che offset

I video `.MP4` presentavano metadati QuickTime differenti dai JPG.

---

### Vincoli

* evitare modifiche non reversibili
* verificare prima di correggere
* procedere per gruppi
* nessun affidamento a timestamp filesystem
* usare dati EXIF reali
* massima compatibilità futura

---

## 2. Architettura / Setup

### Componenti

Sistema operativo utilizzato:

* Linux shell / WSL

Tool principali:

* ExifTool
* Bash
* awk
* grep
* sed
* bc

Dispositivi di verifica:

* smartphone Android
* iPhone 16e
* cronologia spostamenti Google Maps

---

### Configurazione

Directory di lavoro Linux:

```bash
~/Cina
```

Sorgente foto/video Canon:

```bash
/storage/emulated/0/Pictures/Canon PowerShot G7 X Mark III
```

Convenzioni file Canon:

```text
IMG_####.JPG
MVI_####.MP4
```

Range interessato:

```text
7196 → 8255
```

---

### Flussi

Workflow adottato:

1. estrazione metadati in CSV / JSON
2. ordinamento per suffisso progressivo file
3. identificazione gruppi per offset
4. correzione foto
5. verifica puntuale video
6. classificazione video per delta orario
7. correzione batch finale
8. allineamento timestamp filesystem

---

## 3. Stato Attuale

### Funzionante

* esportazione CSV completa
* backup metadata JSON
* ordinamento progressivo file
* identificazione gruppi offset
* correzione foto riuscita
* script verifica video funzionante
* calcolo delta automatico video/foto

---

### Non funzionante / Incompleto

* classificazione finale di tutti i video
* correzione batch definitiva video
* eventuale riallineamento filesystem video

---

## 4. Decisioni Tecniche

### Ordinamento per numero file e non filesystem

Il filesystem non è affidabile dopo copie/spostamenti.

Scelta:

```text
IMG_7196 → IMG_8255
MVI_7285 → ...
```

---

### Foto usate come ground truth per video

I JPG corretti sono stati usati come riferimento assoluto per i video adiacenti.

---

### Offset trattati separatamente

Gruppi distinti:

* `+00`
* `+02`
* `+06`
* `+08`

---

### Video trattati per delta orario reale

Nei `.MP4` non si è fatto affidamento al timezone interno QuickTime.

---

## 5. Problemi Aperti

* completare classificazione 24 video
* gestire eventuali file senza foto precedente/successiva
* verificare uniformità timestamp dopo import mobile
* decidere se aggiornare `FileModifyDate` dei video

---

## 6. Dati Tecnici Rilevanti

### Backup metadata completo

```bash
exiftool -r -ext jpg -ext mp4 \
-if '($FileName ge "IMG_7196.JPG" and $FileName le "IMG_8255.JPG") or ($FileName ge "MVI_7196.MP4" and $FileName le "MVI_8255.MP4")' \
-json . > backup_metadata.json
```

---

### Export CSV analisi

```bash
exiftool -r -ext jpg -ext mp4 \
-csv \
-FileName \
-DateTimeOriginal \
-CreateDate \
-ModifyDate \
-OffsetTimeOriginal \
-OffsetTime \
-QuickTime:CreateDate \
-d "%Y-%m-%d %H:%M:%S" \
. > report_canon.csv
```

---

### Ordinamento CSV per progressivo

```bash
awk -F',' 'NR>1 {
match($1, /_([0-9]+)\./, a);
print a[1] "," $0
}' report_canon.csv | sort -n | cut -d',' -f2- > report_sorted.csv
```

---

### Liste file per gruppi offset

```bash
awk -F',' '$6=="+00:00" {gsub("./","",$1); print $1}' report_sorted.csv > lista_00.txt
awk -F',' '$6=="+02:00" {gsub("./","",$1); print $1}' report_sorted.csv > lista_02.txt
awk -F',' '$6=="+06:00" {gsub("./","",$1); print $1}' report_sorted.csv > lista_06.txt
awk -F',' '$6=="+08:00" {gsub("./","",$1); print $1}' report_sorted.csv > lista_08.txt
```

---

## 7. Runbook Operativo

### Verifica singolo file foto

```bash
exiftool -DateTimeOriginal -OffsetTimeOriginal IMG_7680.JPG
```

---

### Verifica video

```bash
exiftool -QuickTime:CreateDate -QuickTime:ModifyDate MVI_7285.MP4
```

---

## 8. Prossimi Step

* chiudere classificazione video
* applicare correzione batch video
* test import finale smartphone
* sync NAS

---

## 9. Note Operative / Best Practice

* mai lavorare direttamente sugli originali senza backup
* validare sempre 1 file prima del batch
* non fidarsi dei timestamp filesystem
* usare foto come riferimento per video
* procedere per gruppi omogenei

---

Scrivi 'continua' per proseguire
