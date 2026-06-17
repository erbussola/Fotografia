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
awk -F',' 'NR>1 {match($1, /_([0-9]+)\./, a); print a[1] "," $0}' \
report_canon.csv | sort -n | cut -d',' -f2- > report_sorted.csv
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

# Parte 2/4 - Correzione Foto Canon: Analisi Offset e Normalizzazione EXIF

# Titolo

Correzione completa metadati temporali JPG Canon G7X Mark III tramite ExifTool

---

## 1. Contesto Generale

### Obiettivo

Ripristinare la corretta cronologia delle foto `.JPG` scattate in Cina tra il 1 aprile e il 10 aprile 2026, rendendo coerenti:

* orario locale di scatto
* timezone
* ordinamento cronologico
* compatibilità cross-platform

---

### Scenario tecnico

Dall’analisi dei metadati è emersa la presenza di 4 gruppi temporali distinti:

| Offset   | Significato                       |
| -------- | --------------------------------- |
| `+08:00` | corretto Cina                     |
| `+06:00` | offset errato                     |
| `+02:00` | timezone Italia                   |
| `+00:00` | orario corretto ma timezone nullo |

---

### Vincoli

* non alterare timestamp già corretti
* modificare solo i file necessari
* evitare doppie correzioni
* preservare struttura file

---

## 2. Architettura / Setup

### Metodo di lavoro

Le correzioni sono state eseguite tramite liste file:

```text
lista_00.txt
lista_02.txt
lista_06.txt
lista_08.txt
```

Utilizzando ExifTool con input file:

```bash
-@ lista_00.txt
```

---

### Vantaggi del metodo a liste

* nessuna scansione completa directory
* maggiore velocità
* targeting preciso
* ripetibilità operativa
* zero dipendenza dal filesystem

---

## 3. Stato Attuale

### Funzionante

* tutte le foto analizzate
* liste gruppi generate
* logica di correzione definita
* test singolo file riusciti

### Non funzionante / Incompleto

* eventuale riallineamento filesystem da completare in massa
* verifica finale globale su smartphone

---

## 4. Decisioni Tecniche

### Gruppo `+00:00`

Dalle verifiche:

* orario locale corretto
* offset errato

Decisione:

```text
correggere solo timezone
```

---

### Gruppo `+02:00`

Verifica reale:

```text
07:33 +02:00  → reale 13:33 +08:00
```

Decisione:

```text
+6 ore + offset +08
```

---

### Gruppo `+06:00`

Da verifiche successive:

* da validare file per file o blocchi coerenti
* non assumere correzione automatica senza test

---

### Gruppo `+08:00`

Nessuna modifica necessaria.

---

## 5. Problemi Aperti

* verificare se tutto il blocco `+06` è omogeneo
* identificare eventuali anomalie residue
* controllare import su Google Photos

---

## 6. Dati Tecnici Rilevanti

### Correzione gruppo +00 (solo timezone)

```bash
exiftool -overwrite_original \
-OffsetTimeOriginal="+08:00" \
-OffsetTimeDigitized="+08:00" \
-OffsetTime="+08:00" \
-@ lista_00.txt
```

---

### Correzione gruppo +02 (+6h + timezone)

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

---

### Verifica singolo file dopo fix

```bash
exiftool -DateTimeOriginal -OffsetTimeOriginal IMG_7196.JPG
```

Output atteso:

```text
Date/Time Original : 2026:04:01 13:33:11
Offset Time Original : +08:00
```

---

### Controllo globale offset

```bash
exiftool -T -FileName -OffsetTimeOriginal *.JPG
```

---

## 7. Runbook Operativo

### Fase 1

Backup metadata eseguito.

### Fase 2

Generazione liste per gruppi offset.

### Fase 3

Correzione:

1. gruppo +00
2. gruppo +02
3. verifica +06
4. nessuna azione +08

### Fase 4

Verifica random campionaria con smartphone.

---

## 8. Prossimi Step

* completare gruppo +06
* chiudere parte video
* allineare filesystem dates

---

## 9. Note Operative / Best Practice

### Non usare `-if` su directory grandi

Meglio:

```bash
-@ lista_file.txt
```

---

### Test prima del batch

Correggere sempre 1 file campione.

---

### Non fidarsi solo del timezone

Il timezone camera può essere errato anche con orario corretto.

---

### Usare riferimenti esterni

Fonti affidabili:

* smartphone personale
* iPhone moglie
* Google Maps Timeline


---

# Parte 3/4 - Analisi e Correzione Video MVI_ Canon G7X Mark III

# Titolo

Gestione metadati temporali video `.MP4` Canon PowerShot G7 X Mark III con confronto automatico foto adiacenti

---

## 1. Contesto Generale

### Obiettivo

Correggere in modo affidabile i timestamp dei video Canon `MVI_####.MP4`, evitando interpretazioni errate dei metadati QuickTime.

---

### Scenario tecnico

I video Canon non usano EXIF classico come le foto.

Presentano invece metadati multipli:

* `QuickTime:CreateDate`
* `QuickTime:ModifyDate`
* `Track Create Date`
* `Media Create Date`
* eventuali campi EXIF secondari

Questi campi possono contenere:

* UTC puro
* ora locale senza timezone
* timezone ricostruito da ExifTool
* valori incoerenti tra loro

---

### Vincoli

* non fidarsi ciecamente del timezone nei video
* usare un riferimento esterno coerente
* correggere solo dopo verifica puntuale
* evitare shift multipli errati

---

## 2. Architettura / Setup

### Lista video utilizzata

```text
lista_video.txt
```

Contenente 24 file:

```text
MVI_7285.MP4
MVI_7315.MP4
MVI_7403.MP4
...
MVI_8239.MP4
```

---

### Metodo scelto

Per ogni video:

1. estrarre timestamp video
2. confrontarlo con foto precedente `IMG_(n-1).JPG`
3. fallback su foto successiva `IMG_(n+1).JPG`
4. calcolare delta orario
5. classificare:

* OK
* +2h
* +6h
* UNKNOWN

---

## 3. Stato Attuale

### Funzionante

* script di confronto automatico
* calcolo delta video/foto
* classificazione preliminare

### Non funzionante / Incompleto

* correzione batch finale video
* verifica ultimi casi anomali
* uniformità metadata QuickTime completa

---

## 4. Decisioni Tecniche

### Le foto corrette sono la fonte di verità

I JPG già sistemati sono stati considerati riferimento assoluto.

---

### Ignorare timezone video

Nei `.MP4` il timezone è ambiguo.

Decisione:

```text
considerare solo l’orario reale
```

---

### Classificazione per delta

| Delta | Azione           |
| ----- | ---------------- |
| ~0h   | nessuna modifica |
| ~2h   | aggiungere 2 ore |
| ~6h   | aggiungere 6 ore |

Tolleranza ammessa:

```text
±10 minuti
```

---

## 5. Problemi Aperti

* alcuni video senza foto adiacente disponibile
* possibili casi ibridi
* necessità di controllo finale campionario

---

## 6. Dati Tecnici Rilevanti

### Verifica manuale metadati video

```bash
exiftool MVI_7285.MP4 | grep Date
```

---

### Esempio output reale

```text
Create Date         : 2026:04:02 07:43:12
Track Create Date   : 2026:04:02 01:43:12
Media Create Date   : 2026:04:02 01:43:12
Date/Time Original  : 2026:04:02 03:43:12.14+02:00
```

---

### Interpretazione

Campi differenti = nessun affidamento automatico.

---

### Script confronto automatico

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

  check_photo() {
    file=$1
    label=$2

    if [ -f "$file" ]; then
      ptime=$(exiftool -s -s -s -DateTimeOriginal "$file")
      echo "$label: $file → $ptime"

      p_epoch=$(to_epoch "$ptime")

      diff_sec=$((p_epoch - v_epoch))
      diff_hr=$(echo "scale=2; $diff_sec/3600" | bc)

      echo "DELTA ($label): ${diff_hr}h"
    fi
  }

  check_photo "$prev" "PREV"
  check_photo "$next" "NEXT"

done < lista_video.txt
```

---

### Output reale

```text
VIDEO: MVI_7285.MP4
VIDEO TIME: 2026:04:02 09:43:12
PREV: IMG_7284.JPG → 2026:04:02 09:40:41
DELTA (PREV): -.04h
```

```text
VIDEO: MVI_7315.MP4
VIDEO TIME: 2026:04:02 08:30:49
PREV: IMG_7314.JPG → 2026:04:02 10:27:43
DELTA (PREV): 1.94h
```

---

## 7. Runbook Operativo

### Fase 1

Lanciare script di confronto.

### Fase 2

Classificare:

```text
video_ok.txt
video_2h.txt
video_6h.txt
video_unknown.txt
```

### Fase 3

Applicare correzione batch per gruppo.

---

## 8. Prossimi Step

* validazione file classificati +6h
* correzione batch definitiva
* verifica riproduzione smartphone

---

## 9. Note Operative / Best Practice

### Non fidarsi di MediaCreateDate

Spesso è UTC puro.

### Non usare un solo campo metadata

QuickTime usa strutture multiple.

### La foto adiacente è il miglior riferimento

Molto più affidabile del solo metadata video.


---

# Parte 4/4 - Runbook Finale, Correzioni Batch e Best Practice Definitive

# Titolo

Chiusura operativa progetto di normalizzazione temporale foto/video Canon G7X Mark III

---

## 1. Contesto Generale

### Obiettivo

Portare l’intero dataset foto/video a uno stato finale coerente, importabile e stabile su:

* Android
* Google Photos
* NAS
* Windows / Linux
* future copie e backup

---

### Scenario tecnico finale

Dopo l’analisi completa:

* Foto JPG quasi interamente corrette
* Video MP4 da finalizzare per gruppi
* Timestamp filesystem ancora da riallineare

---

### Vincoli

* non introdurre doppie correzioni
* preservare contenuti multimediali
* evitare alterazioni di qualità
* usare solo metadata edit

---

## 2. Architettura / Setup

### File di lavoro finali

```text
lista_00.txt
lista_02.txt
lista_06.txt
lista_08.txt

lista_video.txt
video_ok.txt
video_2h.txt
video_6h.txt
video_unknown.txt
```

---

### Toolchain

* ExifTool
* bash
* awk
* sed
* grep
* bc

---

## 3. Stato Attuale

### Funzionante

* backup metadata
* CSV ordinato
* foto corrette per gruppi
* metodo video validato
* script di confronto disponibile

### Non funzionante / Incompleto

* batch finale video
* riallineamento timestamp filesystem video
* audit conclusivo random

---

## 4. Decisioni Tecniche

### Foto

Le foto devono avere:

```text
DateTimeOriginal coerente
OffsetTimeOriginal +08:00
```

---

### Video

I video devono avere:

```text
QuickTime:CreateDate coerente con foto vicine
```

Timezone secondario non prioritario.

---

### Filesystem

Il filesystem deve riflettere il tempo di scatto reale per agevolare ricerca e sorting.

---

## 5. Problemi Aperti

* validare eventuali file in `video_unknown.txt`
* controllare minuscole/maiuscole `.mp4` / `.MP4`
* verificare player che ignorano metadata

---

## 6. Dati Tecnici Rilevanti

### Correzione video +2h

```bash
exiftool -overwrite_original \
-QuickTime:CreateDate+=2:0:0 \
-QuickTime:ModifyDate+=2:0:0 \
-CreateDate+=2:0:0 \
-ModifyDate+=2:0:0 \
-@ video_2h.txt
```

---

### Correzione video +6h

```bash
exiftool -overwrite_original \
-QuickTime:CreateDate+=6:0:0 \
-QuickTime:ModifyDate+=6:0:0 \
-CreateDate+=6:0:0 \
-ModifyDate+=6:0:0 \
-@ video_6h.txt
```

---

### Allineamento timestamp filesystem JPG

```bash
exiftool -overwrite_original \
'-FileModifyDate<DateTimeOriginal' \
'-FileCreateDate<DateTimeOriginal' \
*.JPG
```

---

### Allineamento timestamp filesystem MP4

```bash
exiftool -overwrite_original \
'-FileModifyDate<QuickTime:CreateDate' \
*.MP4
```

---

### Verifica finale foto

```bash
exiftool -T -FileName -DateTimeOriginal -OffsetTimeOriginal *.JPG | head
```

---

### Verifica finale video

```bash
exiftool -T -FileName -QuickTime:CreateDate *.MP4 | head
```

---

## 7. Runbook Operativo

### Step 1 - Backup

Verificare presenza backup JSON / copia dataset.

---

### Step 2 - Correzione Foto

Applicare solo ai gruppi non ancora trattati.

---

### Step 3 - Correzione Video

1. eseguire batch `video_2h.txt`
2. eseguire batch `video_6h.txt`
3. controllare `video_unknown.txt`

---

### Step 4 - Filesystem Sync

Applicare riallineamento date file.

---

### Step 5 - Audit Finale

Controllo random:

* 10 JPG
* 5 MP4

Confrontare con:

* smartphone
* timeline viaggio
* Google Maps

---

## 8. Prossimi Step

### Operativi immediati

* completare batch video
* sincronizzare su smartphone
* import Google Photos

### Evolutivi

* creare script unico end-to-end
* report HTML finale
* checksum archivio definitivo

---

## 9. Note Operative / Best Practice

### Sempre lavorare su copia

Mai sugli originali unici.

---

### Non fidarsi dei player

Molti player mostrano solo filesystem date.

---

### Verificare estensioni miste

Gestire:

```text
.MP4
.mp4
.JPG
.jpg
```

---

### Preferire liste file

Meglio di:

```text
-if directory scan
```

Uso corretto:

```bash
-@ lista_file.txt
```

---

### Metodo definitivo adottato

```text
Foto corrette = fonte di verità
Video corretti per confronto adiacente
```

---

### Stato finale atteso

Dataset completamente coerente, ordinabile e portabile.

---


---

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


---

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


---

