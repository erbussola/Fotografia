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
