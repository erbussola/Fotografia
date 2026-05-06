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

```text id="q5u0ha"
lista_video.txt
```

Contenente 24 file:

```text id="zq4m2q"
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

```text id="3l2nuj"
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

```text id="nq79tk"
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

```bash id="vql9xy"
exiftool MVI_7285.MP4 | grep Date
```

---

### Esempio output reale

```text id="l0z42g"
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

```bash id="k9gwd2"
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

```text id="pt8j4w"
VIDEO: MVI_7285.MP4
VIDEO TIME: 2026:04:02 09:43:12
PREV: IMG_7284.JPG → 2026:04:02 09:40:41
DELTA (PREV): -.04h
```

```text id="5huxb0"
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

```text id="kh2s0h"
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
