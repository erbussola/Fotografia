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
